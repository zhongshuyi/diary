const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const { openDatabase, closeDatabase } = require('./database.cjs');
const { initializeDatabase } = require('./migrations.cjs');
const { importLegacyData } = require('./legacy-migration.cjs');
const { writeZipFile, readZipFile } = require('../backup.cjs');
const {
  withTransaction,
  writeEntryRecord,
  rowToEntry,
  listEntries,
  listTaxonomyUsage,
  listPendingMutations,
  getSyncState,
  listSettings,
  loadDraft,
  createOrUpdateEntry,
  saveDraft,
  clearDraft,
  writeSetting,
  applySyncResult,
  listConflicts,
  resolveConflict,
  setSyncState,
  moveEntryToTrash,
  restoreEntry,
  batchSetFavorite,
  batchMoveToTrash,
  batchRestore,
  batchUpdateOrganization,
  renameTag,
  deleteTag,
  renameCategory,
  deleteCategory,
  listAttachmentHealth,
  deleteEntryPermanently,
  searchEntries,
} = require('./repository.cjs');

function createDiaryStore({ userDataPath }) {
  if (!userDataPath || typeof userDataPath !== 'string') throw new TypeError('userDataPath is required');
  fs.mkdirSync(userDataPath, { recursive: true });
  const dbPath = path.join(userDataPath, 'diary.sqlite');
  const mediaRoot = path.join(userDataPath, 'media');
  const db = openDatabase(dbPath);
  initializeDatabase(db);
  if (!getSyncState(db, 'device_id', null)) setSyncState(db, 'device_id', `desktop-${crypto.randomUUID()}`);

  function safeAssetName(value) {
    const cleaned = path.basename(String(value || 'attachment')).replace(/[<>:"/\\|?*\x00-\x1F]/g, '-').trim();
    return cleaned || 'attachment';
  }

  function assetExtension(value) {
    const extension = path.extname(String(value || '')).toLowerCase();
    return /^\.[a-z0-9]{1,16}$/.test(extension) ? extension : '.bin';
  }

  function assetKind(filePath) {
    const extension = path.extname(filePath).toLowerCase();
    if (['.mp4', '.webm', '.mov', '.mkv', '.avi', '.ogv'].includes(extension)) return 'video';
    if (['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac', '.opus'].includes(extension)) return 'audio';
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].includes(extension) ? 'image' : 'file';
  }

  function assetMime(kind, filePath) {
    const extension = path.extname(filePath).toLowerCase();
    const mime = {
      '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.gif': 'image/gif', '.webp': 'image/webp', '.bmp': 'image/bmp',
      '.mp4': 'video/mp4', '.webm': 'video/webm', '.mov': 'video/quicktime', '.mkv': 'video/x-matroska', '.avi': 'video/x-msvideo',
      '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.m4a': 'audio/mp4', '.aac': 'audio/aac', '.ogg': 'audio/ogg', '.flac': 'audio/flac', '.opus': 'audio/opus',
    }[extension];
    return mime || (kind === 'file' ? 'application/octet-stream' : `${kind}/*`);
  }

  function isWithin(root, candidate) {
    const relative = path.relative(root, candidate);
    return relative === '' || (relative && !relative.startsWith('..') && !path.isAbsolute(relative));
  }

  function prepareEntryAssets(entry) {
    const descriptors = [];
    const descriptorByHash = new Map();
    const nextEntry = { ...entry };
    for (const field of ['imagePaths', 'videoPaths', 'audioPaths']) {
      const paths = Array.isArray(entry?.[field]) ? entry[field] : [];
      nextEntry[field] = paths.map((value) => {
        if (typeof value !== 'string' || !value.trim() || value.startsWith('data:')) return value;
        const source = path.resolve(value);
        const kind = assetKind(source);
        const originalName = safeAssetName(source);
        let hash;
        let byteSize = 0;
        let state = 'ready';
        let destination = source;
        try {
          const stats = fs.statSync(source);
          if (!stats.isFile() || stats.size > 128 * 1024 * 1024) throw new Error('attachment_invalid');
          const bytes = fs.readFileSync(source);
          hash = crypto.createHash('sha256').update(bytes).digest('hex');
          byteSize = stats.size;
          if (!isWithin(mediaRoot, source)) {
            const managedRoot = path.join(mediaRoot, 'managed');
            fs.mkdirSync(managedRoot, { recursive: true });
            const extension = assetExtension(originalName);
            destination = path.join(managedRoot, `${hash}${extension}`);
            if (!fs.existsSync(destination)) fs.copyFileSync(source, destination);
          }
        } catch {
          hash = crypto.createHash('sha256').update(`missing:${source}`).digest('hex');
          state = 'missing';
        }
        const relativePath = isWithin(userDataPath, destination)
          ? path.relative(userDataPath, destination).replace(/\\/g, '/')
          : `external/${hash}-${originalName}`;
        const descriptor = { id: `asset-${hash}`, sha256: hash, kind, mimeType: assetMime(kind, source), byteSize, originalName, relativePath, state };
        if (!descriptorByHash.has(hash)) {
          descriptorByHash.set(hash, descriptor);
          descriptors.push(descriptor);
        }
        return destination;
      });
    }
    return { entry: nextEntry, assets: descriptors };
  }

  function snapshot() {
    return {
      entries: listEntries(db, { includeTrash: true }),
      entryCount: db.prepare("SELECT COUNT(*) AS count FROM entries WHERE id NOT LIKE 'conflict:%'").get().count,
      outbox: listPendingMutations(db),
      cursor: getSyncState(db, 'cursor', '0'),
      deviceId: getSyncState(db, 'device_id', null),
      conflicts: listConflicts(db),
      settings: listSettings(db),
      draft: loadDraft(db, 'main'),
    };
  }

  function bootstrap(legacyState = null) {
    const marker = db.prepare("SELECT value FROM app_meta WHERE key = 'legacy_migration'").get();
    if (marker?.value === 'completed') return { migrated: false, reason: 'already_completed', dbPath, snapshot: snapshot() };
    if (!legacyState || typeof legacyState !== 'object') return { migrated: false, reason: 'no_legacy_data', dbPath, snapshot: snapshot() };

    const backupRoot = path.join(userDataPath, 'backups');
    fs.mkdirSync(backupRoot, { recursive: true });
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const legacyBackupPath = path.join(backupRoot, `localstorage-migration-${timestamp}.json`);
    fs.writeFileSync(legacyBackupPath, JSON.stringify(legacyState, null, 2), 'utf8');
    const report = importLegacyData(db, { ...legacyState, deviceId: legacyState.deviceId || getSyncState(db, 'device_id') }, { prepareEntryAssets });
    return { migrated: true, dbPath, legacyBackupPath, report, snapshot: snapshot() };
  }

  function saveEntry(entry) {
    const prepared = prepareEntryAssets(entry);
    const saved = createOrUpdateEntry(db, prepared.entry, { deviceId: getSyncState(db, 'device_id', 'desktop'), assets: prepared.assets });
    return { entry: saved, snapshot: snapshot() };
  }

  function saveDraftValue(draft) {
    saveDraft(db, draft);
    return snapshot();
  }

  function clearDraftValue(id = 'main') {
    clearDraft(db, id);
    return snapshot();
  }

  function saveSetting(key, value) {
    writeSetting(db, key, value);
    return snapshot();
  }

  function listEntryAssets(entryId) {
    if (typeof entryId !== 'string' || !entryId.trim()) return [];
    const rows = db.prepare(`SELECT a.id, a.sha256, a.kind, a.mime_type, a.byte_size, a.original_name, a.relative_path, a.state
      FROM attachments a JOIN entry_attachments ea ON ea.attachment_id = a.id
      WHERE ea.entry_id = ? ORDER BY ea.sort_order ASC`).all(entryId);
    return rows.map((row) => ({
      id: row.id,
      sha256: row.sha256,
      kind: row.kind,
      mimeType: row.mime_type,
      byteSize: Number(row.byte_size),
      originalName: row.original_name,
      relativePath: row.relative_path,
      state: row.state,
      localPath: path.resolve(userDataPath, row.relative_path),
    })).filter((asset) => isWithin(userDataPath, asset.localPath));
  }

  function storeDownloadedAsset({ sha256, extension = '', bytes } = {}) {
    const normalizedHash = String(sha256 || '').toLowerCase();
    if (!/^[a-f0-9]{64}$/.test(normalizedHash)) throw new TypeError('附件哈希无效');
    if (!Buffer.isBuffer(bytes) || bytes.byteLength > 128 * 1024 * 1024) throw new TypeError('附件内容无效');
    const actualHash = crypto.createHash('sha256').update(bytes).digest('hex');
    if (actualHash !== normalizedHash) throw new Error('附件校验失败');
    const normalizedExtension = /^\.[a-z0-9]{1,16}$/i.test(String(extension || '')) ? String(extension).toLowerCase() : '.bin';
    const destination = path.join(mediaRoot, 'managed', `${normalizedHash}${normalizedExtension}`);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    if (fs.existsSync(destination)) {
      const existingHash = crypto.createHash('sha256').update(fs.readFileSync(destination)).digest('hex');
      if (existingHash !== normalizedHash) throw new Error('附件校验失败');
      return destination;
    }
    const temporary = `${destination}.${process.pid}.${Date.now()}.tmp`;
    try {
      fs.writeFileSync(temporary, bytes, { flag: 'wx' });
      fs.renameSync(temporary, destination);
      return destination;
    } catch (error) {
      try { fs.unlinkSync(temporary); } catch { /* keep the original write failure */ }
      throw error;
    }
  }

  function applySync(payload) {
    const prepareChange = (change) => {
      if (!change?.entry || typeof change.entry !== 'object') return change;
      const prepared = prepareEntryAssets(change.entry);
      return { ...change, entry: prepared.entry, assets: prepared.assets };
    };
    const prepareConflict = (conflict) => {
      if (!conflict || typeof conflict !== 'object') return conflict;
      const serverPrepared = conflict.serverEntry && typeof conflict.serverEntry === 'object' ? prepareEntryAssets(conflict.serverEntry) : null;
      const entryPrepared = conflict.entry && typeof conflict.entry === 'object' ? prepareEntryAssets(conflict.entry) : null;
      return {
        ...conflict,
        ...(serverPrepared ? { serverEntry: serverPrepared.entry, serverAssets: serverPrepared.assets } : {}),
        ...(entryPrepared ? { entry: entryPrepared.entry } : {}),
      };
    };
    applySyncResult(db, {
      ...payload,
      changes: (Array.isArray(payload?.changes) ? payload.changes : []).map(prepareChange),
      conflicts: (Array.isArray(payload?.conflicts) ? payload.conflicts : []).map(prepareConflict),
    });
    return snapshot();
  }

  function trashEntry(id) {
    moveEntryToTrash(db, id, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function restoreTrashedEntry(id) {
    restoreEntry(db, id, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function batchFavorite(ids, isFavorite) {
    batchSetFavorite(db, ids, isFavorite, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function batchTrash(ids) {
    batchMoveToTrash(db, ids, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function batchRestoreEntries(ids) {
    batchRestore(db, ids, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function batchOrganizeEntries(ids, options) {
    batchUpdateOrganization(db, ids, options, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function renameTagValue(from, to) {
    renameTag(db, from, to, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function deleteTagValue(value) {
    deleteTag(db, value, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function renameCategoryValue(from, to) {
    renameCategory(db, from, to, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function deleteCategoryValue(value) {
    deleteCategory(db, value, { deviceId: getSyncState(db, 'device_id', 'desktop') });
    return snapshot();
  }

  function permanentlyDeleteEntry(id) {
    deleteEntryPermanently(db, id);
    return snapshot();
  }

  function search(query, options) {
    return searchEntries(db, query, options);
  }

  function refreshAttachmentHealth() {
    const rows = db.prepare(`SELECT a.id, a.relative_path, EXISTS(SELECT 1 FROM entry_attachments ea WHERE ea.attachment_id = a.id) AS referenced
      FROM attachments a`).all();
    db.exec('BEGIN IMMEDIATE;');
    try {
      const update = db.prepare('UPDATE attachments SET state = ? WHERE id = ?');
      rows.forEach((row) => {
        const resolved = path.resolve(userDataPath, row.relative_path);
        let available = false;
        try { available = Boolean(isWithin(userDataPath, resolved) && fs.statSync(resolved).isFile()); } catch { available = false; }
        const state = row.referenced ? (available ? 'ready' : 'missing') : 'orphaned';
        update.run(state, row.id);
      });
      db.exec('COMMIT;');
    } catch (error) {
      try { db.exec('ROLLBACK;'); } catch { /* preserve the original health check error */ }
      throw error;
    }
    return listAttachmentHealth(db);
  }

  function findAttachmentByPath(assetPath) {
    if (typeof assetPath !== 'string' || !assetPath.trim()) return null;
    const candidate = path.isAbsolute(assetPath) ? path.resolve(assetPath) : path.resolve(userDataPath, assetPath);
    const candidateRelative = path.relative(userDataPath, candidate).replace(/\\/g, '/');
    const direct = db.prepare('SELECT * FROM attachments WHERE relative_path = ?').get(candidateRelative)
      || db.prepare('SELECT * FROM attachments WHERE relative_path = ?').get(assetPath.replace(/\\/g, '/').replace(/^\/+/, ''));
    if (direct) return direct;
    const legacyMatches = db.prepare("SELECT * FROM attachments WHERE state = 'missing' AND relative_path LIKE 'external/%' AND original_name = ?").all(safeAssetName(assetPath));
    return legacyMatches.length === 1 ? legacyMatches[0] : null;
  }

  function relocateAttachment(assetPath, sourcePath) {
    const attachment = findAttachmentByPath(assetPath);
    if (!attachment) throw new Error('没有找到对应的附件记录');
    if (typeof sourcePath !== 'string' || !sourcePath.trim()) throw new TypeError('附件路径不能为空');
    const source = path.resolve(sourcePath);
    let stats;
    try { stats = fs.statSync(source); } catch { throw new Error('附件不存在或无法读取'); }
    if (!stats.isFile() || stats.size > 128 * 1024 * 1024) throw new Error('附件不存在或超过 128 MB 限制');
    const bytes = fs.readFileSync(source);
    const hash = crypto.createHash('sha256').update(bytes).digest('hex');
    const isLegacyMissing = attachment.relative_path.startsWith('external/');
    if (!isLegacyMissing && attachment.sha256 !== hash) throw new Error('文件内容与原附件不一致，请选择同一个文件');
    const kind = assetKind(source);
    if (attachment.kind !== kind && attachment.kind !== 'file') throw new Error('文件类型与原附件不一致');
    const originalName = safeAssetName(source);
    const extension = assetExtension(originalName);
    const destination = path.join(mediaRoot, 'managed', `${hash}${extension}`);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    const destinationExisted = fs.existsSync(destination);
    if (!destinationExisted) {
      const temporary = `${destination}.${process.pid}.${Date.now()}.tmp`;
      try {
        fs.writeFileSync(temporary, bytes);
        fs.renameSync(temporary, destination);
      } catch (error) {
        try { fs.unlinkSync(temporary); } catch { /* preserve the original copy error */ }
        throw error;
      }
    }
    const relativePath = path.relative(userDataPath, destination).replace(/\\/g, '/');
    const nextPath = path.resolve(userDataPath, relativePath);
    let merged = false;
    try {
      withTransaction(db, () => {
        const relations = db.prepare('SELECT e.* FROM entries e JOIN entry_attachments ea ON ea.entry_id = e.id WHERE ea.attachment_id = ?').all(attachment.id);
        const oldResolved = path.isAbsolute(assetPath) ? path.resolve(assetPath) : path.resolve(userDataPath, assetPath);
        relations.forEach((row) => {
          const entry = rowToEntry(row);
          const replacePath = (value) => {
            if (typeof value !== 'string' || !value.trim()) return value;
            const resolved = path.isAbsolute(value) ? path.resolve(value) : path.resolve(userDataPath, value);
            return resolved === oldResolved || (isLegacyMissing && safeAssetName(value) === attachment.original_name) ? nextPath : value;
          };
          const nextEntry = {
            ...entry,
            imagePaths: entry.imagePaths.map(replacePath),
            videoPaths: entry.videoPaths.map(replacePath),
            audioPaths: entry.audioPaths.map(replacePath),
            updatedAt: new Date().toISOString(),
            revision: entry.revision + 1,
          };
          if (JSON.stringify(nextEntry.imagePaths) !== JSON.stringify(entry.imagePaths) || JSON.stringify(nextEntry.videoPaths) !== JSON.stringify(entry.videoPaths) || JSON.stringify(nextEntry.audioPaths) !== JSON.stringify(entry.audioPaths)) {
            writeEntryRecord(db, nextEntry, { deviceId: getSyncState(db, 'device_id', 'desktop') });
          }
        });
        const existing = db.prepare('SELECT id FROM attachments WHERE sha256 = ? AND id <> ?').get(hash, attachment.id);
        if (existing) {
          merged = true;
          const attachmentRelations = db.prepare('SELECT entry_id, sort_order, caption FROM entry_attachments WHERE attachment_id = ?').all(attachment.id);
          const addRelation = db.prepare('INSERT OR IGNORE INTO entry_attachments(entry_id, attachment_id, sort_order, caption) VALUES (?, ?, ?, ?)');
          attachmentRelations.forEach((relation) => addRelation.run(relation.entry_id, existing.id, relation.sort_order, relation.caption || ''));
          db.prepare('DELETE FROM entry_attachments WHERE attachment_id = ?').run(attachment.id);
          db.prepare('DELETE FROM attachments WHERE id = ?').run(attachment.id);
        } else {
          db.prepare('UPDATE attachments SET sha256 = ?, kind = ?, mime_type = ?, byte_size = ?, original_name = ?, relative_path = ?, state = \'ready\' WHERE id = ?')
            .run(hash, kind, assetMime(kind, source), stats.size, originalName, relativePath, attachment.id);
        }
      });
    } catch (error) {
      if (!destinationExisted) { try { fs.unlinkSync(destination); } catch { /* retain a file only if cleanup is interrupted */ } }
      throw error;
    }
    refreshAttachmentHealth();
    return { oldPath: assetPath, path: nextPath, merged, snapshot: snapshot() };
  }

  function listAllEntries() {
    const all = [];
    for (let offset = 0; ; offset += 500) {
      const page = listEntries(db, { includeTrash: true, limit: 500, offset });
      all.push(...page);
      if (page.length < 500) return all;
    }
  }

  function backupPayload() {
    refreshAttachmentHealth();
    const entries = listAllEntries();
    const rows = db.prepare(`SELECT a.id, a.sha256, a.kind, a.mime_type, a.byte_size, a.original_name, a.relative_path, a.created_at, a.state,
      ea.entry_id, ea.sort_order, ea.caption
      FROM attachments a LEFT JOIN entry_attachments ea ON ea.attachment_id = a.id ORDER BY a.id, ea.sort_order`).all();
    const attachmentMap = new Map();
    rows.forEach((row) => {
      let item = attachmentMap.get(row.id);
      if (!item) {
        item = { id: row.id, sha256: row.sha256, kind: row.kind, mimeType: row.mime_type, byteSize: row.byte_size, originalName: row.original_name, relativePath: row.relative_path, createdAt: row.created_at, state: row.state, entries: [], archivePath: null };
        attachmentMap.set(row.id, item);
      }
      if (row.entry_id) item.entries.push({ entryId: row.entry_id, sortOrder: row.sort_order, caption: row.caption || '' });
    });
    const attachments = [...attachmentMap.values()];
    const binaryFiles = [];
    attachments.forEach((attachment) => {
      const resolved = path.resolve(userDataPath, attachment.relativePath);
      try {
        if (attachment.state === 'ready' && isWithin(userDataPath, resolved) && fs.statSync(resolved).isFile()) {
          const stem = attachment.id.replace(/[^a-zA-Z0-9_-]/g, '_');
          const extension = assetExtension(safeAssetName(attachment.originalName));
          attachment.archivePath = `attachments/${stem}${extension}`;
          binaryFiles.push({ name: attachment.archivePath, data: fs.readFileSync(resolved) });
        }
      } catch {
        attachment.state = 'missing';
      }
    });
    const manifest = {
      format: 'diary-backup',
      version: 1,
      createdAt: new Date().toISOString(),
      schemaVersion: 2,
      entries: entries.length,
      attachments: attachments.length,
      missingAttachments: attachments.filter((attachment) => attachment.state === 'missing' || !attachment.archivePath).length,
      files: ['manifest.json', 'entries.json', 'attachments.json', 'settings.json', ...binaryFiles.map((file) => file.name)],
    };
    return {
      files: [
        { name: 'manifest.json', data: Buffer.from(JSON.stringify(manifest, null, 2), 'utf8') },
        { name: 'entries.json', data: Buffer.from(JSON.stringify(entries), 'utf8') },
        { name: 'attachments.json', data: Buffer.from(JSON.stringify(attachments), 'utf8') },
        { name: 'settings.json', data: Buffer.from(JSON.stringify(listSettings(db)), 'utf8') },
        ...binaryFiles,
      ],
      summary: { entries: entries.length, attachments: attachments.length, missingAttachments: manifest.missingAttachments },
    };
  }

  function exportBackup(targetPath) {
    if (!targetPath || typeof targetPath !== 'string') throw new TypeError('Backup path is required');
    fs.mkdirSync(path.dirname(targetPath), { recursive: true });
    const payload = backupPayload();
    const result = writeZipFile(targetPath, payload.files);
    return { ...payload.summary, path: result.path, bytes: result.bytes };
  }

  function readBackupPackage(sourcePath) {
    if (!sourcePath || typeof sourcePath !== 'string') throw new TypeError('Backup path is required');
    const files = readZipFile(sourcePath);
    const readJson = (name, fallback) => {
      const file = files.get(name);
      if (!file) return fallback;
      try { return JSON.parse(file.toString('utf8')); } catch { throw new Error('备份文件内容损坏'); }
    };
    const manifest = readJson('manifest.json', null);
    const entries = readJson('entries.json', null);
    const attachments = readJson('attachments.json', null);
    if (!manifest || manifest.format !== 'diary-backup' || manifest.version !== 1 || !Array.isArray(entries) || !Array.isArray(attachments)) throw new Error('不支持的备份格式');
    return { files, manifest, entries, attachments };
  }

  function previewBackup(sourcePath) {
    const backup = readBackupPackage(sourcePath);
    return { valid: true, version: backup.manifest.version, createdAt: backup.manifest.createdAt, entries: backup.entries.length, attachments: backup.attachments.length, missingAttachments: backup.attachments.filter((attachment) => attachment.state === 'missing' || !attachment.archivePath).length };
  }

  function importBackup(sourcePath, { mode = 'merge' } = {}) {
    if (mode !== 'merge') throw new Error('仅支持合并导入');
    let phase = 'validate';
    let stagingRoot = null;
    const stagedFiles = [];
    const promotedFiles = [];
    const cleanup = { stagedFiles: 0, promotedFiles: 0, removedFiles: 0, removedStagingDirs: 0 };
    const removeStagingArtifacts = () => {
      if (!stagingRoot) return;
      try {
        fs.rmSync(stagingRoot, { recursive: true, force: true });
        cleanup.removedStagingDirs += 1;
      } catch { /* preserve the original import failure */ }
    };
    const cleanupImportArtifacts = () => {
      cleanup.stagedFiles = stagedFiles.length;
      cleanup.promotedFiles = promotedFiles.length;
      for (const filePath of promotedFiles.reverse()) {
        try {
          if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
            fs.unlinkSync(filePath);
            cleanup.removedFiles += 1;
          }
        } catch { /* preserve the original import failure */ }
      }
      removeStagingArtifacts();
    };

    try {
      const backup = readBackupPackage(sourcePath);
      const deviceId = getSyncState(db, 'device_id', 'desktop');
      const descriptorById = new Map();
      const importedBinary = [];
      stagingRoot = path.join(mediaRoot, '.staging', crypto.randomUUID());
      fs.mkdirSync(stagingRoot, { recursive: true });

      // Validate every descriptor and stage valid bytes before changing managed storage.
      backup.attachments.forEach((attachment, index) => {
        const sha256 = String(attachment.sha256 || '').toLowerCase();
        if (!/^[a-f0-9]{64}$/.test(sha256) || !['image', 'video', 'audio', 'file'].includes(attachment.kind)) throw new Error('备份包含无效附件元数据');
        const safeName = safeAssetName(attachment.originalName);
        const extension = assetExtension(safeName);
        const destination = path.join(mediaRoot, 'managed', `${sha256}${extension}`);
        let state = 'missing';
        const data = attachment.archivePath ? backup.files.get(attachment.archivePath) : null;
        if (data) {
          const actualHash = crypto.createHash('sha256').update(data).digest('hex');
          if (actualHash === sha256 && data.byteLength <= 128 * 1024 * 1024) {
            const stagedPath = path.join(stagingRoot, `${index}-${sha256}${extension}`);
            fs.writeFileSync(stagedPath, data);
            stagedFiles.push({ stagedPath, destination, attachmentId: attachment.id });
            state = 'ready';
          }
        }
        const relativePath = path.relative(userDataPath, destination).replace(/\\/g, '/');
        descriptorById.set(attachment.id, { id: `asset-${sha256}`, sha256, kind: attachment.kind, mimeType: String(attachment.mimeType || 'application/octet-stream'), byteSize: data?.byteLength || Number(attachment.byteSize) || 0, originalName: safeName, relativePath, state });
      });
      cleanup.stagedFiles = stagedFiles.length;

      phase = 'file';
      for (const staged of stagedFiles) {
        fs.mkdirSync(path.dirname(staged.destination), { recursive: true });
        if (fs.existsSync(staged.destination)) {
          const destinationStats = fs.lstatSync(staged.destination);
          if (destinationStats.isSymbolicLink() || !destinationStats.isFile()) throw new Error('备份附件目标路径不是文件');
          continue;
        }
        fs.renameSync(staged.stagedPath, staged.destination);
        promotedFiles.push(staged.destination);
        importedBinary.push(staged.attachmentId);
      }
      cleanup.promotedFiles = promotedFiles.length;
      phase = 'database';
      const relationsByEntry = new Map();
      backup.attachments.forEach((attachment) => (attachment.entries || []).forEach((relation) => {
        const list = relationsByEntry.get(relation.entryId) || [];
        list.push({ ...relation, descriptor: descriptorById.get(attachment.id) });
        relationsByEntry.set(relation.entryId, list);
      }));
      let importedEntries = 0;
      let skippedEntries = 0;
      withTransaction(db, () => {
        backup.entries.forEach((entry) => {
          if (!entry || typeof entry.id !== 'string' || !entry.id) throw new Error('备份包含无效记录');
          const local = db.prepare('SELECT updated_at FROM entries WHERE id = ?').get(entry.id);
          if (local && (Date.parse(local.updated_at) || 0) >= (Date.parse(entry.updatedAt) || 0)) { skippedEntries += 1; return; }
          const descriptors = (relationsByEntry.get(entry.id) || []).filter((relation) => relation.descriptor).sort((left, right) => Number(left.sortOrder || 0) - Number(right.sortOrder || 0)).map((relation) => relation.descriptor);
          const importedEntry = { ...entry,
            imagePaths: descriptors.filter((descriptor) => descriptor.kind === 'image').map((descriptor) => path.resolve(userDataPath, descriptor.relativePath)),
            videoPaths: descriptors.filter((descriptor) => descriptor.kind === 'video').map((descriptor) => path.resolve(userDataPath, descriptor.relativePath)),
            audioPaths: descriptors.filter((descriptor) => descriptor.kind === 'audio').map((descriptor) => path.resolve(userDataPath, descriptor.relativePath)),
          };
          writeEntryRecord(db, importedEntry, { deviceId, enqueue: false, assets: descriptors });
          importedEntries += 1;
        });
      });
      removeStagingArtifacts();
      return { importedEntries, skippedEntries, importedAttachments: importedBinary.length, snapshot: snapshot() };
    } catch (error) {
      cleanupImportArtifacts();
      const failure = error instanceof Error ? error : new Error(String(error));
      failure.importPhase = phase;
      failure.importCleanup = { ...cleanup };
      throw failure;
    }
  }

  function cleanupOrphanedAttachments({ graceMs = 24 * 60 * 60 * 1000, now = Date.now() } = {}) {
    const grace = Number(graceMs);
    const nowMs = Number(now);
    if (!Number.isFinite(grace) || grace < 0 || !Number.isFinite(nowMs)) throw new TypeError('清理参数无效');
    const managedRoot = path.join(mediaRoot, 'managed');
    const referenced = new Set(db.prepare('SELECT DISTINCT a.relative_path FROM attachments a JOIN entry_attachments ea ON ea.attachment_id = a.id').all()
      .map((row) => path.resolve(userDataPath, row.relative_path))
      .filter((candidate) => isWithin(managedRoot, candidate)));
    let removedFiles = 0;
    const visit = (directory) => {
      if (!fs.existsSync(directory)) return;
      let children;
      try { children = fs.readdirSync(directory, { withFileTypes: true }); } catch { return; }
      children.forEach((child) => {
        const candidate = path.join(directory, child.name);
        if (!isWithin(managedRoot, candidate)) return;
        let stats;
        try { stats = fs.lstatSync(candidate); } catch { return; }
        if (stats.isSymbolicLink()) return;
        if (stats.isDirectory()) { visit(candidate); return; }
        if (!stats.isFile() || referenced.has(path.resolve(candidate)) || nowMs - stats.mtimeMs < grace) return;
        try { fs.unlinkSync(candidate); removedFiles += 1; } catch { /* retain files that cannot be removed */ }
      });
    };
    visit(managedRoot);
    let removedStagingDirs = 0;
    const stagingRoot = path.join(mediaRoot, '.staging');
    let stagingStats = null;
    try { stagingStats = fs.lstatSync(stagingRoot); } catch { stagingStats = null; }
    if (stagingStats?.isDirectory() && !stagingStats.isSymbolicLink()) {
      let children = [];
      try { children = fs.readdirSync(stagingRoot, { withFileTypes: true }); } catch { children = []; }
      children.forEach((child) => {
        if (!child.isDirectory()) return;
        const candidate = path.join(stagingRoot, child.name);
        let stats;
        try { stats = fs.lstatSync(candidate); } catch { return; }
        if (stats.isSymbolicLink() || nowMs - stats.mtimeMs < grace) return;
        try { fs.rmSync(candidate, { recursive: true, force: true }); removedStagingDirs += 1; } catch { /* retain a staging directory if cleanup is interrupted */ }
      });
    }
    return { removedFiles, removedStagingDirs };
  }

  function createRollingBackup(now = new Date()) {
    const date = new Date(now);
    if (Number.isNaN(date.getTime())) throw new TypeError('Backup date is invalid');
    const day = date.toISOString().slice(0, 10);
    const backupRoot = path.join(userDataPath, 'backups');
    const targetPath = path.join(backupRoot, `daily-${day}.diary.zip`);
    const previous = listSettings(db).lastRollingBackupAt;
    if (typeof previous === 'string' && previous.slice(0, 10) === day && fs.existsSync(targetPath)) return { skipped: true, path: targetPath };
    fs.mkdirSync(backupRoot, { recursive: true });
    const result = exportBackup(targetPath);
    writeSetting(db, 'lastRollingBackupAt', date.toISOString());
    const dailyFiles = fs.readdirSync(backupRoot).filter((name) => /^daily-\d{4}-\d{2}-\d{2}\.diary\.zip$/.test(name)).sort().reverse();
    dailyFiles.slice(7).forEach((name) => { try { fs.unlinkSync(path.join(backupRoot, name)); } catch { /* retain a backup if cleanup is interrupted */ } });
    return { created: true, ...result };
  }

  return {
    db,
    dbPath,
    bootstrap,
    snapshot,
    listEntries: (options) => listEntries(db, options),
    taxonomyUsage: () => listTaxonomyUsage(db, { detailed: true }),
    attachmentHealth: refreshAttachmentHealth,
    relocateAttachment,
    exportBackup,
    previewBackup,
    importBackup,
    cleanupOrphanedAttachments,
    createRollingBackup,
    listEntryAssets,
    storeDownloadedAsset,
    saveEntry,
    saveDraft: saveDraftValue,
    loadDraft: (id = 'main') => loadDraft(db, id),
    clearDraft: clearDraftValue,
    saveSetting,
    applySync,
    listConflicts: (options) => listConflicts(db, options),
    resolveConflict: ({ conflictId, resolution }) => {
      const deviceId = getSyncState(db, 'device_id', 'desktop');
      resolveConflict(db, { conflictId, resolution, deviceId });
      return snapshot();
    },
    trashEntry,
    restoreEntry: restoreTrashedEntry,
    batchFavorite,
    batchTrash,
    batchRestore: batchRestoreEntries,
    batchOrganize: batchOrganizeEntries,
    renameTag: renameTagValue,
    deleteTag: deleteTagValue,
    renameCategory: renameCategoryValue,
    deleteCategory: deleteCategoryValue,
    permanentlyDeleteEntry,
    search,
    close: () => closeDatabase(db),
  };
}

module.exports = { createDiaryStore };
