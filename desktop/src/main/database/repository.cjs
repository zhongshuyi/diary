function nowIso() {
  return new Date().toISOString();
}

function withTransaction(db, operation) {
  db.exec('BEGIN IMMEDIATE;');
  try {
    const result = operation();
    db.exec('COMMIT;');
    return result;
  } catch (error) {
    try { db.exec('ROLLBACK;'); } catch { /* preserve the original write error */ }
    throw error;
  }
}

function readString(value, fallback = '') {
  if (value === undefined || value === null) return fallback;
  if (typeof value !== 'string') throw new TypeError('Expected a string value');
  return value;
}

function readList(value) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) throw new TypeError('Expected a list of strings');
  return [...new Set(value)];
}

function readDate(value, fallback) {
  const date = value ?? fallback;
  if (typeof date !== 'string' || Number.isNaN(Date.parse(date))) throw new TypeError('Expected an ISO date string');
  return date;
}

function normalizeEntry(entry) {
  if (!entry || typeof entry !== 'object') throw new TypeError('Entry is required');
  const fallbackNow = nowIso();
  const createdAt = readDate(entry.createdAt, fallbackNow);
  const occurredAt = readDate(entry.occurredAt ?? entry.createdAt, createdAt);
  const updatedAt = readDate(entry.updatedAt, createdAt);
  const id = readString(entry.id);
  if (!id) throw new TypeError('Entry id is required');
  const mood = entry.mood === null || entry.mood === undefined ? null : Number(entry.mood);
  if (mood !== null && (!Number.isFinite(mood) || mood < 0 || mood > 1)) throw new TypeError('Mood must be between 0 and 1');
  return {
    schemaVersion: Number(entry.schemaVersion) || 1,
    id,
    createdAt,
    occurredAt,
    updatedAt,
    deletedAt: entry.isInTrash ? readDate(entry.deletedAt, updatedAt) : (entry.deletedAt ?? null),
    title: readString(entry.title),
    content: readString(entry.content ?? entry.contentText),
    contentText: readString(entry.contentText ?? entry.content),
    editorType: readString(entry.editorType, 'plain_text'),
    mood,
    moodSet: entry.moodSet === true || mood !== null,
    category: readString(entry.category, '生活') || '未分类',
    tags: readList(entry.tags),
    imagePaths: readList(entry.imagePaths),
    audioPaths: readList(entry.audioPaths),
    videoPaths: readList(entry.videoPaths),
    weather: readList(entry.weather),
    positions: readList(entry.positions),
    latitude: entry.latitude === null || entry.latitude === undefined ? null : Number(entry.latitude),
    longitude: entry.longitude === null || entry.longitude === undefined ? null : Number(entry.longitude),
    colorValue: Number(entry.colorValue) || 0xffe4e0ed,
    isFavorite: entry.isFavorite === true,
    isInTrash: Boolean(entry.isInTrash || entry.deletedAt),
    revision: Math.max(1, Number(entry.revision) || 1),
  };
}

function normalizeAssetDescriptor(asset) {
  if (!asset || typeof asset !== 'object') throw new TypeError('Attachment metadata is required');
  const id = readString(asset.id).trim();
  const sha256 = readString(asset.sha256).trim().toLowerCase();
  const kind = readString(asset.kind).trim();
  const relativePath = readString(asset.relativePath).trim();
  if (!id || !/^[a-f0-9]{64}$/.test(sha256) || !['image', 'video', 'audio', 'file'].includes(kind) || !relativePath) throw new TypeError('Invalid attachment metadata');
  const byteSize = Number(asset.byteSize) || 0;
  if (!Number.isSafeInteger(byteSize) || byteSize < 0 || byteSize > 128 * 1024 * 1024) throw new TypeError('Invalid attachment size');
  return {
    id,
    sha256,
    kind,
    mimeType: readString(asset.mimeType, 'application/octet-stream'),
    byteSize,
    originalName: readString(asset.originalName),
    relativePath: relativePath.replace(/\\/g, '/').replace(/^\/+/, ''),
    state: ['ready', 'missing', 'orphaned'].includes(asset.state) ? asset.state : 'ready',
  };
}

function syncEntryAttachments(db, entryId, assets) {
  const descriptors = (Array.isArray(assets) ? assets : []).map(normalizeAssetDescriptor);
  db.prepare('DELETE FROM entry_attachments WHERE entry_id = ?').run(entryId);
  const findByHash = db.prepare('SELECT id FROM attachments WHERE sha256 = ?');
  const upsert = db.prepare(`INSERT INTO attachments(id, sha256, kind, mime_type, byte_size, original_name, relative_path, created_at, state)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET sha256 = excluded.sha256, kind = excluded.kind, mime_type = excluded.mime_type,
      byte_size = excluded.byte_size, original_name = excluded.original_name, relative_path = excluded.relative_path, state = excluded.state`);
  const relation = db.prepare('INSERT INTO entry_attachments(entry_id, attachment_id, sort_order) VALUES (?, ?, ?)');
  const attachedIds = new Set();
  descriptors.forEach((asset, index) => {
    const existing = findByHash.get(asset.sha256);
    const attachmentId = existing?.id || asset.id;
    upsert.run(attachmentId, asset.sha256, asset.kind, asset.mimeType, asset.byteSize, asset.originalName, asset.relativePath, nowIso(), asset.state);
    if (attachedIds.has(attachmentId)) return;
    attachedIds.add(attachmentId);
    relation.run(entryId, attachmentId, index);
  });
  db.exec("UPDATE attachments SET state = 'orphaned' WHERE id NOT IN (SELECT attachment_id FROM entry_attachments)");
  return descriptors;
}

function encodeEntry(entry) {
  const normalized = normalizeEntry(entry);
  return {
    ...normalized,
    isInTrash: Boolean(normalized.deletedAt),
  };
}

function writeEntryRecord(db, entry, { deviceId = 'desktop', enqueue = true, mutationId, assets } = {}) {
  const normalized = encodeEntry(entry);
  const serialized = JSON.stringify(normalized);
  const sql = `
    INSERT INTO entries (
      id, schema_version, created_at, occurred_at, updated_at, deleted_at,
      title, content, content_text, editor_type, mood, mood_set, category,
      tags_json, image_paths_json, audio_paths_json, video_paths_json,
      weather_json, positions_json, latitude, longitude, color_value,
      is_favorite, revision
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      schema_version = excluded.schema_version,
      occurred_at = excluded.occurred_at,
      updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at,
      title = excluded.title,
      content = excluded.content,
      content_text = excluded.content_text,
      editor_type = excluded.editor_type,
      mood = excluded.mood,
      mood_set = excluded.mood_set,
      category = excluded.category,
      tags_json = excluded.tags_json,
      image_paths_json = excluded.image_paths_json,
      audio_paths_json = excluded.audio_paths_json,
      video_paths_json = excluded.video_paths_json,
      weather_json = excluded.weather_json,
      positions_json = excluded.positions_json,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      color_value = excluded.color_value,
      is_favorite = excluded.is_favorite,
      revision = excluded.revision
  `;
  db.prepare(sql).run(
    normalized.id,
    normalized.schemaVersion,
    normalized.createdAt,
    normalized.occurredAt,
    normalized.updatedAt,
    normalized.deletedAt,
    normalized.title,
    normalized.content,
    normalized.contentText,
    normalized.editorType,
    normalized.mood,
    normalized.moodSet ? 1 : 0,
    normalized.category,
    JSON.stringify(normalized.tags),
    JSON.stringify(normalized.imagePaths),
    JSON.stringify(normalized.audioPaths),
    JSON.stringify(normalized.videoPaths),
    JSON.stringify(normalized.weather),
    JSON.stringify(normalized.positions),
    normalized.latitude,
    normalized.longitude,
    normalized.colorValue,
    normalized.isFavorite ? 1 : 0,
    normalized.revision,
  );
  db.prepare('DELETE FROM entry_search WHERE id = ?').run(normalized.id);
  db.prepare('INSERT INTO entry_search(id, body) VALUES (?, ?)').run(normalized.id, [normalized.title, normalized.contentText, normalized.category, ...normalized.tags].join(' '));
  if (assets !== undefined) syncEntryAttachments(db, normalized.id, assets);
  if (enqueue) {
    const id = mutationId || `${deviceId}:${normalized.id}:${normalized.updatedAt}`;
    db.prepare('DELETE FROM outbox WHERE entry_id = ?').run(normalized.id);
    db.prepare('INSERT INTO outbox(mutation_id, entry_id, payload_json, created_at) VALUES (?, ?, ?, ?)').run(id, normalized.id, JSON.stringify({ mutationId: id, entry: normalized }), nowIso());
  }
  return normalized;
}

function createOrUpdateEntry(db, entry, options = {}) {
  return withTransaction(db, () => writeEntryRecord(db, entry, options));
}

function parseList(value) {
  try {
    const parsed = JSON.parse(value || '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function rowToEntry(row) {
  return {
    schemaVersion: row.schema_version,
    id: row.id,
    createdAt: row.created_at,
    occurredAt: row.occurred_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at,
    title: row.title,
    content: row.content,
    contentText: row.content_text,
    editorType: row.editor_type,
    mood: row.mood === null ? null : Number(row.mood),
    moodSet: Boolean(row.mood_set),
    category: row.category,
    tags: parseList(row.tags_json),
    imagePaths: parseList(row.image_paths_json),
    audioPaths: parseList(row.audio_paths_json),
    videoPaths: parseList(row.video_paths_json),
    weather: parseList(row.weather_json),
    positions: parseList(row.positions_json),
    latitude: row.latitude === null ? null : Number(row.latitude),
    longitude: row.longitude === null ? null : Number(row.longitude),
    colorValue: row.color_value,
    isFavorite: Boolean(row.is_favorite),
    isInTrash: Boolean(row.deleted_at),
    revision: row.revision,
  };
}

function listEntries(db, { includeTrash = false, limit = 500, offset = 0 } = {}) {
  const safeLimit = Math.min(2000, Math.max(1, Number(limit) || 500));
  const safeOffset = Math.max(0, Number(offset) || 0);
  const sql = includeTrash
    ? 'SELECT * FROM entries ORDER BY occurred_at DESC, created_at DESC LIMIT ? OFFSET ?'
    : 'SELECT * FROM entries WHERE deleted_at IS NULL ORDER BY occurred_at DESC, created_at DESC LIMIT ? OFFSET ?';
  return db.prepare(sql).all(safeLimit, safeOffset).map(rowToEntry);
}

function listTaxonomyUsage(db, { detailed = false } = {}) {
  const categories = new Map();
  const tags = new Map();
  const rows = db.prepare('SELECT category, tags_json, occurred_at, updated_at, created_at FROM entries WHERE deleted_at IS NULL').all();
  rows.forEach((row) => {
    const latest = Date.parse(row.occurred_at || row.updated_at || row.created_at) || 0;
    const category = row.category || '生活';
    const categoryUsage = categories.get(category) || { count: 0, latest: 0 };
    categoryUsage.count += 1;
    categoryUsage.latest = Math.max(categoryUsage.latest, latest);
    categories.set(category, categoryUsage);
    parseList(row.tags_json).filter(Boolean).forEach((tag) => {
      const tagUsage = tags.get(tag) || { count: 0, latest: 0 };
      tagUsage.count += 1;
      tagUsage.latest = Math.max(tagUsage.latest, latest);
      tags.set(tag, tagUsage);
    });
  });
  const sortUsage = (usage) => [...usage.entries()].sort((left, right) => right[1].count - left[1].count || right[1].latest - left[1].latest || left[0].localeCompare(right[0], 'zh-CN'));
  const sortedCategories = sortUsage(categories);
  const sortedTags = sortUsage(tags);
  if (!detailed) return { categories: sortedCategories.map(([value]) => value), tags: sortedTags.map(([value]) => value) };
  return {
    categories: sortedCategories.map(([value]) => value),
    tags: sortedTags.map(([value]) => value),
    categoryStats: sortedCategories.map(([value, usage]) => ({ value, ...usage })),
    tagStats: sortedTags.map(([value, usage]) => ({ value, ...usage })),
  };
}

function listPendingMutations(db, { limit = 100 } = {}) {
  const rows = db.prepare('SELECT mutation_id, payload_json, retry_count, next_retry_at FROM outbox ORDER BY created_at ASC LIMIT ?').all(Math.min(500, Math.max(1, Number(limit) || 100)));
  return rows.map((row) => JSON.parse(row.payload_json));
}

function moveEntryToTrash(db, id, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  return withTransaction(db, () => {
    const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
    if (!row) throw new Error(`Entry not found: ${id}`);
    const entry = rowToEntry(row);
    return writeEntryRecord(db, { ...entry, updatedAt, deletedAt: updatedAt, isInTrash: true, revision: entry.revision + 1 }, { deviceId });
  });
}

function restoreEntry(db, id, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  return withTransaction(db, () => {
    const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
    if (!row) throw new Error(`Entry not found: ${id}`);
    const entry = rowToEntry(row);
    return writeEntryRecord(db, { ...entry, updatedAt, deletedAt: null, isInTrash: false, revision: entry.revision + 1 }, { deviceId });
  });
}

function normalizeIds(ids) {
  return [...new Set((Array.isArray(ids) ? ids : []).filter((id) => typeof id === 'string' && id.trim()).map((id) => id.trim()))];
}

function normalizeTextValues(values) {
  const list = Array.isArray(values) ? values : [values];
  return [...new Set(list.filter((value) => typeof value === 'string').map((value) => value.trim()).filter(Boolean))];
}

function batchSetFavorite(db, ids, isFavorite, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  const target = Boolean(isFavorite);
  return withTransaction(db, () => {
    const changed = [];
    normalizeIds(ids).forEach((id) => {
      const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
      if (!row || row.deleted_at || Boolean(row.is_favorite) === target) return;
      const entry = rowToEntry(row);
      writeEntryRecord(db, { ...entry, updatedAt, isFavorite: target, revision: entry.revision + 1 }, { deviceId });
      changed.push(id);
    });
    return changed;
  });
}

function batchMoveToTrash(db, ids, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  return withTransaction(db, () => {
    const changed = [];
    normalizeIds(ids).forEach((id) => {
      const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
      if (!row || row.deleted_at) return;
      const entry = rowToEntry(row);
      writeEntryRecord(db, { ...entry, updatedAt, deletedAt: updatedAt, isInTrash: true, revision: entry.revision + 1 }, { deviceId });
      changed.push(id);
    });
    return changed;
  });
}

function batchRestore(db, ids, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  return withTransaction(db, () => {
    const changed = [];
    normalizeIds(ids).forEach((id) => {
      const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
      if (!row || !row.deleted_at) return;
      const entry = rowToEntry(row);
      writeEntryRecord(db, { ...entry, updatedAt, deletedAt: null, isInTrash: false, revision: entry.revision + 1 }, { deviceId });
      changed.push(id);
    });
    return changed;
  });
}

function batchUpdateOrganization(db, ids, options = {}, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  const { category, addTags = [], removeTags = [] } = options && typeof options === 'object' ? options : {};
  const additions = normalizeTextValues(addTags);
  const removals = new Set(normalizeTextValues(removeTags));
  const nextCategory = category === undefined ? undefined : (String(category || '').trim() || '未分类');
  return withTransaction(db, () => {
    const changed = [];
    normalizeIds(ids).forEach((id) => {
      const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
      if (!row || row.deleted_at) return;
      const entry = rowToEntry(row);
      const nextTags = [...new Set([...entry.tags.filter((tag) => !removals.has(tag)), ...additions])];
      const categoryChanged = nextCategory !== undefined && nextCategory !== entry.category;
      const tagsChanged = nextTags.length !== entry.tags.length || nextTags.some((tag, index) => tag !== entry.tags[index]);
      if (!categoryChanged && !tagsChanged) return;
      writeEntryRecord(db, { ...entry, category: nextCategory === undefined ? entry.category : nextCategory, tags: nextTags, updatedAt, revision: entry.revision + 1 }, { deviceId });
      changed.push(id);
    });
    return changed;
  });
}

function normalizeTaxonomyName(value, fallback = '') {
  if (typeof value !== 'string') throw new TypeError('Taxonomy name must be a string');
  const normalized = value.trim().replace(/\s+/g, ' ');
  return normalized || fallback;
}

function updateEntriesTaxonomy(db, transform, { deviceId = 'desktop', updatedAt = nowIso() } = {}) {
  return withTransaction(db, () => {
    const changed = [];
    db.prepare('SELECT * FROM entries ORDER BY occurred_at DESC, created_at DESC').all().forEach((row) => {
      const entry = rowToEntry(row);
      const next = transform(entry);
      if (!next) return;
      writeEntryRecord(db, { ...entry, ...next, updatedAt, revision: entry.revision + 1 }, { deviceId });
      changed.push(entry.id);
    });
    return changed;
  });
}

function renameTag(db, from, to, options = {}) {
  const source = normalizeTaxonomyName(from);
  const target = normalizeTaxonomyName(to);
  if (!source || !target) throw new TypeError('标签名不能为空');
  if (source === target) return [];
  return updateEntriesTaxonomy(db, (entry) => {
    if (!(entry.tags || []).includes(source)) return null;
    return { tags: [...new Set((entry.tags || []).map((tag) => tag === source ? target : tag))] };
  }, options);
}

function deleteTag(db, value, options = {}) {
  const target = normalizeTaxonomyName(value);
  if (!target) throw new TypeError('标签名不能为空');
  return updateEntriesTaxonomy(db, (entry) => {
    if (!(entry.tags || []).includes(target)) return null;
    return { tags: (entry.tags || []).filter((tag) => tag !== target) };
  }, options);
}

function renameCategory(db, from, to, options = {}) {
  const source = normalizeTaxonomyName(from);
  const target = normalizeTaxonomyName(to, '未分类');
  if (!source || !target) throw new TypeError('分类名不能为空');
  if (source === target) return [];
  return updateEntriesTaxonomy(db, (entry) => entry.category === source ? { category: target } : null, options);
}

function deleteCategory(db, value, options = {}) {
  const target = normalizeTaxonomyName(value);
  if (!target) throw new TypeError('分类名不能为空');
  return updateEntriesTaxonomy(db, (entry) => entry.category === target ? { category: '未分类' } : null, options);
}

function deleteEntryPermanently(db, id) {
  return withTransaction(db, () => {
    const row = db.prepare('SELECT * FROM entries WHERE id = ?').get(id);
    if (!row) return false;
    if (!row.deleted_at) throw new Error('Only trashed entries can be permanently deleted');
    db.prepare('DELETE FROM entry_search WHERE id = ?').run(id);
    db.prepare('DELETE FROM entry_attachments WHERE entry_id = ?').run(id);
    db.prepare('DELETE FROM outbox WHERE entry_id = ?').run(id);
    db.prepare('DELETE FROM entries WHERE id = ?').run(id);
    db.exec("UPDATE attachments SET state = 'orphaned' WHERE id NOT IN (SELECT attachment_id FROM entry_attachments)");
    return true;
  });
}

function listAttachmentHealth(db) {
  const rows = db.prepare('SELECT state, COUNT(*) AS count FROM attachments GROUP BY state').all();
  const counts = Object.fromEntries(rows.map((row) => [row.state, Number(row.count)]));
  return { total: Object.values(counts).reduce((sum, count) => sum + count, 0), ready: counts.ready || 0, missing: counts.missing || 0, orphaned: counts.orphaned || 0 };
}

function escapeLike(value) {
  return value.replace(/[\\%_]/g, (character) => `\\${character}`);
}

function normalizeFilterDate(value) {
  if (value === undefined || value === null || value === '') return null;
  const text = String(value).trim();
  if (!/^\d{4}-\d{2}-\d{2}(?:T.*)?$/.test(text)) return null;
  return text.slice(0, 10);
}

function normalizeFilterTags(value) {
  if (value === undefined || value === null) return [];
  const values = Array.isArray(value) ? value : [value];
  return [...new Set(values.filter((tag) => typeof tag === 'string').map((tag) => tag.trim()).filter(Boolean))];
}

function appendSearchFilters(clauses, params, options = {}) {
  if (!options.includeTrash) clauses.push('e.deleted_at IS NULL');

  const dateFrom = normalizeFilterDate(options.dateFrom);
  const dateTo = normalizeFilterDate(options.dateTo);
  if (dateFrom) {
    clauses.push("substr(e.occurred_at, 1, 10) >= ?");
    params.push(dateFrom);
  }
  if (dateTo) {
    clauses.push("substr(e.occurred_at, 1, 10) <= ?");
    params.push(dateTo);
  }

  if (typeof options.category === 'string' && options.category.trim()) {
    clauses.push('e.category = ?');
    params.push(options.category.trim());
  }

  normalizeFilterTags(options.tags).forEach((tag) => {
    clauses.push("EXISTS (SELECT 1 FROM json_each(e.tags_json) WHERE json_each.value = ?)");
    params.push(tag);
  });

  if (options.favorite === true) clauses.push('e.is_favorite = 1');

  if (options.mood !== undefined && options.mood !== null && options.mood !== '') {
    const mood = Number(options.mood);
    if (Number.isFinite(mood) && mood >= 0 && mood <= 1) {
      clauses.push('e.mood_set = 1 AND e.mood = ?');
      params.push(mood);
    }
  }

  const attachmentKind = options.attachmentKind === 'any' ? 'any' : options.attachmentKind;
  const attachmentColumns = {
    image: 'e.image_paths_json',
    video: 'e.video_paths_json',
    audio: 'e.audio_paths_json',
  };
  if (attachmentKind === 'any') {
    clauses.push('(json_array_length(e.image_paths_json) > 0 OR json_array_length(e.video_paths_json) > 0 OR json_array_length(e.audio_paths_json) > 0)');
  } else if (attachmentColumns[attachmentKind]) {
    clauses.push(`json_array_length(${attachmentColumns[attachmentKind]}) > 0`);
  }
}

function searchEntries(db, query, options = {}) {
  const { includeTrash = false, limit = 100, offset = 0 } = options;
  const normalizedQuery = typeof query === 'string' ? query.trim() : '';
  const safeLimit = Math.min(500, Math.max(1, Number(limit) || 100));
  const safeOffset = Math.max(0, Number(offset) || 0);
  const clauses = [];
  const params = [];

  if (normalizedQuery && [...normalizedQuery].length < 3) {
    const like = `%${escapeLike(normalizedQuery)}%`;
    clauses.push("(e.title LIKE ? ESCAPE '\\' OR e.content_text LIKE ? ESCAPE '\\' OR e.category LIKE ? ESCAPE '\\' OR e.tags_json LIKE ? ESCAPE '\\')");
    params.push(like, like, like, like);
  }

  let from = 'entries e';
  if (normalizedQuery && [...normalizedQuery].length >= 3) {
    from = 'entry_search s JOIN entries e ON e.id = s.id';
    const match = `"${normalizedQuery.replace(/"/g, '""')}"`;
    clauses.push('s.body MATCH ?');
    params.push(match);
  }

  appendSearchFilters(clauses, params, { ...options, includeTrash });
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  params.push(safeLimit, safeOffset);
  return db.prepare(`SELECT e.* FROM ${from} ${where} ORDER BY e.occurred_at DESC, e.created_at DESC LIMIT ? OFFSET ?`).all(...params).map(rowToEntry);
}

function getSyncState(db, key, fallback = null) {
  const row = db.prepare('SELECT value FROM sync_state WHERE key = ?').get(key);
  return row ? row.value : fallback;
}

function setSyncState(db, key, value) {
  if (!key) throw new TypeError('Sync state key is required');
  return withTransaction(db, () => db.prepare('INSERT OR REPLACE INTO sync_state(key, value) VALUES (?, ?)').run(key, String(value)).changes);
}

function listSettings(db) {
  const rows = db.prepare('SELECT key, value_json FROM settings ORDER BY key').all();
  return Object.fromEntries(rows.map((row) => [row.key, JSON.parse(row.value_json)]));
}

function acknowledgeMutations(db, mutationIds) {
  const ids = [...new Set((Array.isArray(mutationIds) ? mutationIds : []).filter((id) => typeof id === 'string' && id))];
  if (!ids.length) return 0;
  return withTransaction(db, () => {
    const statement = db.prepare('DELETE FROM outbox WHERE mutation_id = ?');
    return ids.reduce((count, id) => count + statement.run(id).changes, 0);
  });
}

function applySyncResult(db, { changes = [], conflicts = [], acknowledgedMutationIds = [], cursor = null } = {}) {
  const candidates = [
    ...(Array.isArray(changes) ? changes.map((change) => change?.entry).filter(Boolean) : []),
    ...(Array.isArray(conflicts) ? conflicts.map((conflict) => conflict?.serverEntry).filter(Boolean) : []),
  ];
  return withTransaction(db, () => {
    for (const remote of candidates) {
      const normalized = normalizeEntry(remote);
      const local = db.prepare('SELECT updated_at FROM entries WHERE id = ?').get(normalized.id);
      if (!local || Date.parse(normalized.updatedAt) >= Date.parse(local.updated_at)) {
        writeEntryRecord(db, normalized, { enqueue: false });
      }
    }
    const ids = [...new Set((Array.isArray(acknowledgedMutationIds) ? acknowledgedMutationIds : []).filter((id) => typeof id === 'string' && id))];
    const deleteMutation = db.prepare('DELETE FROM outbox WHERE mutation_id = ?');
    ids.forEach((id) => deleteMutation.run(id));
    if (cursor !== null && cursor !== undefined) db.prepare("INSERT OR REPLACE INTO sync_state(key, value) VALUES ('cursor', ?)").run(String(cursor));
    return { appliedEntries: candidates.length, acknowledgedMutations: ids.length };
  });
}

function saveDraft(db, { id = 'main', entryId = null, payload }) {
  if (!id || !payload || typeof payload !== 'object') throw new TypeError('Draft id and payload are required');
  const payloadJson = JSON.stringify(payload);
  const updatedAt = nowIso();
  return withTransaction(db, () => {
    db.prepare(`INSERT INTO drafts(id, entry_id, payload_json, updated_at) VALUES (?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET entry_id = excluded.entry_id, payload_json = excluded.payload_json, updated_at = excluded.updated_at`).run(id, entryId, payloadJson, updatedAt);
    return { id, entryId, payload };
  });
}

function loadDraft(db, id = 'main') {
  const row = db.prepare('SELECT id, entry_id, payload_json FROM drafts WHERE id = ?').get(id);
  if (!row) return null;
  return { id: row.id, entryId: row.entry_id, payload: JSON.parse(row.payload_json) };
}

function clearDraft(db, id = 'main') {
  return withTransaction(db, () => db.prepare('DELETE FROM drafts WHERE id = ?').run(id).changes);
}

function writeSetting(db, key, value) {
  if (!key) throw new TypeError('Setting key is required');
  const valueJson = JSON.stringify(value);
  return withTransaction(db, () => db.prepare(`INSERT INTO settings(key, value_json, updated_at) VALUES (?, ?, ?) ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json, updated_at = excluded.updated_at`).run(key, valueJson, nowIso()).changes);
}

function readSetting(db, key, fallback = null) {
  const row = db.prepare('SELECT value_json FROM settings WHERE key = ?').get(key);
  if (!row) return fallback;
  try { return JSON.parse(row.value_json); } catch { return fallback; }
}

module.exports = {
  withTransaction,
  normalizeEntry,
  writeEntryRecord,
  createOrUpdateEntry,
  rowToEntry,
  listEntries,
  listTaxonomyUsage,
  listPendingMutations,
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
  deleteEntryPermanently,
  listAttachmentHealth,
  searchEntries,
  getSyncState,
  setSyncState,
  listSettings,
  acknowledgeMutations,
  applySyncResult,
  saveDraft,
  loadDraft,
  clearDraft,
  writeSetting,
  readSetting,
};
