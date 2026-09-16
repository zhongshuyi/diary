const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { createDiaryStore } = require('./store.cjs');

function legacyEntry(id, content) {
  return { id, createdAt: '2026-09-16T08:00:00.000Z', updatedAt: '2026-09-16T08:00:00.000Z', title: '', content, contentText: content, category: '生活', tags: [], imagePaths: [], audioPaths: [], videoPaths: [], mood: 0.5, isInTrash: false };
}

test('creates a user-data database and migrates legacy JSON exactly once', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-'));
  const legacy = { entries: [legacyEntry('one', '第一条')], outbox: [], cursor: '7', deviceId: 'desktop-1', settings: { theme: 'dark' } };
  const first = createDiaryStore({ userDataPath });
  try {
    const result = first.bootstrap(legacy);
    assert.equal(result.migrated, true);
    assert.equal(result.report.entries, 1);
    assert.equal(fs.existsSync(result.legacyBackupPath), true);
    assert.match(result.dbPath, /diary\.sqlite$/);
  } finally {
    first.close();
  }

  const second = createDiaryStore({ userDataPath });
  try {
    const result = second.bootstrap({ entries: [legacyEntry('two', '不应重复导入')], outbox: [], cursor: '99', settings: {} });
    assert.equal(result.migrated, false);
    assert.equal(result.reason, 'already_completed');
    assert.equal(result.snapshot.entries.length, 1);
    assert.equal(result.snapshot.entries[0].id, 'one');
    assert.equal(result.snapshot.cursor, '7');
  } finally {
    second.close();
  }
});

test('loads drafts by id so quick capture can recover independently of the main editor', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-draft-'));
  const store = createDiaryStore({ userDataPath });
  try {
    store.saveDraft({ id: 'quick-capture', payload: { content: '从系统级速记恢复', attachments: [] } });
    assert.deepEqual(store.loadDraft('quick-capture'), { id: 'quick-capture', entryId: null, payload: { content: '从系统级速记恢复', attachments: [] } });
    assert.equal(store.loadDraft('missing'), null);
  } finally {
    store.close();
  }
});

test('registers legacy attachments during the one-time migration', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-migration-asset-'));
  const sourcePath = path.join(userDataPath, '..', `legacy-migration-${Date.now()}.png`);
  fs.writeFileSync(sourcePath, Buffer.from('legacy-attachment'));
  const store = createDiaryStore({ userDataPath });
  try {
    const result = store.bootstrap({ entries: [{ ...legacyEntry('legacy-asset', '迁移附件'), imagePaths: [sourcePath] }], outbox: [], cursor: '0', deviceId: 'legacy-device', settings: {} });
    assert.equal(result.migrated, true);
    assert.match(result.snapshot.entries[0].imagePaths[0], /media[\\/]managed[\\/]/);
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 1, missing: 0, orphaned: 0 });
  } finally {
    store.close();
    try { fs.unlinkSync(sourcePath); } catch {}
    fs.rmSync(userDataPath, { recursive: true, force: true });
  }
});

test('lists database entries in bounded pages for the desktop library', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-page-'));
  const store = createDiaryStore({ userDataPath });
  try {
    store.saveEntry(legacyEntry('one', '第一条'));
    store.saveEntry({ ...legacyEntry('two', '第二条'), createdAt: '2026-09-16T07:00:00.000Z', occurredAt: '2026-09-16T07:00:00.000Z', updatedAt: '2026-09-16T07:00:00.000Z' });
    assert.equal(store.listEntries({ limit: 1, offset: 0 }).length, 1);
    assert.equal(store.listEntries({ limit: 1, offset: 1 })[0].id, 'two');
  } finally {
    store.close();
  }
});

test('registers external attachments into managed storage with hash metadata', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-asset-'));
  const sourcePath = path.join(userDataPath, '..', `diary-source-${Date.now()}.png`);
  fs.writeFileSync(sourcePath, Buffer.from('fake-png-content'));
  const store = createDiaryStore({ userDataPath });
  try {
    const result = store.saveEntry({ ...legacyEntry('asset-entry', '带附件'), imagePaths: [sourcePath] });
    const savedPath = result.entry.imagePaths[0];
    assert.match(savedPath, /media[\\/]managed[\\/]/);
    assert.equal(fs.existsSync(savedPath), true);
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 1, missing: 0, orphaned: 0 });
    assert.equal(store.db.prepare('SELECT COUNT(*) AS count FROM entry_attachments WHERE entry_id = ?').get('asset-entry').count, 1);
    fs.unlinkSync(savedPath);
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 0, missing: 1, orphaned: 0 });
  } finally {
    store.close();
    try { fs.unlinkSync(sourcePath); } catch {}
  }
});

test('relocates a missing attachment after validating its hash', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-relocate-'));
  const sourcePath = path.join(userDataPath, '..', `diary-relocate-source-${Date.now()}.png`);
  const replacementPath = path.join(userDataPath, '..', `diary-relocate-replacement-${Date.now()}.jpg`);
  const bytes = Buffer.from('relocate-me');
  fs.writeFileSync(sourcePath, bytes);
  fs.writeFileSync(replacementPath, bytes);
  const store = createDiaryStore({ userDataPath });
  try {
    const saved = store.saveEntry({ ...legacyEntry('relocate-entry', '缺失附件'), imagePaths: [sourcePath] });
    const managedPath = saved.entry.imagePaths[0];
    fs.unlinkSync(managedPath);
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 0, missing: 1, orphaned: 0 });
    assert.throws(() => store.relocateAttachment(managedPath, path.join(userDataPath, 'does-not-exist.png')), /附件不存在/);
    const relocated = store.relocateAttachment(managedPath, replacementPath);
    assert.equal(relocated.merged, false);
    assert.notEqual(relocated.path, managedPath);
    assert.equal(store.snapshot().entries.find((entry) => entry.id === 'relocate-entry').imagePaths[0], relocated.path);
    assert.equal(fs.existsSync(relocated.path), true);
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 1, missing: 0, orphaned: 0 });
  } finally {
    store.close();
    try { fs.unlinkSync(sourcePath); } catch {}
    try { fs.unlinkSync(replacementPath); } catch {}
    fs.rmSync(userDataPath, { recursive: true, force: true });
  }
});

test('cleans stale unreferenced managed files without touching referenced attachments', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-cleanup-'));
  const sourcePath = path.join(userDataPath, '..', `diary-cleanup-source-${Date.now()}.png`);
  const stalePath = path.join(userDataPath, 'media', 'managed', 'stale-orphan.bin');
  const staleStagingPath = path.join(userDataPath, 'media', '.staging', 'old-import', 'partial.bin');
  fs.writeFileSync(sourcePath, Buffer.from('referenced-attachment'));
  fs.mkdirSync(path.dirname(stalePath), { recursive: true });
  fs.writeFileSync(stalePath, Buffer.from('orphan-attachment'));
  fs.mkdirSync(path.dirname(staleStagingPath), { recursive: true });
  fs.writeFileSync(staleStagingPath, Buffer.from('partial-import'));
  const oldTime = new Date(Date.now() - 10 * 60 * 1000);
  fs.utimesSync(stalePath, oldTime, oldTime);
  fs.utimesSync(path.dirname(staleStagingPath), oldTime, oldTime);
  const store = createDiaryStore({ userDataPath });
  try {
    const saved = store.saveEntry({ ...legacyEntry('cleanup-entry', '保留引用'), imagePaths: [sourcePath] });
    const referencedPath = saved.entry.imagePaths[0];
    fs.utimesSync(referencedPath, oldTime, oldTime);
    const result = store.cleanupOrphanedAttachments({ now: Date.now(), graceMs: 60 * 1000 });
    assert.equal(result.removedFiles, 1);
    assert.equal(result.removedStagingDirs, 1);
    assert.equal(fs.existsSync(stalePath), false);
    assert.equal(fs.existsSync(path.dirname(staleStagingPath)), false);
    assert.equal(fs.existsSync(referencedPath), true);
  } finally {
    store.close();
    try { fs.unlinkSync(sourcePath); } catch {}
    fs.rmSync(userDataPath, { recursive: true, force: true });
  }
});

test('can recover a legacy missing attachment by matching its original name', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-legacy-missing-'));
  const missingPath = path.join(userDataPath, '..', `legacy-missing-${Date.now()}.png`);
  const replacementPath = path.join(userDataPath, '..', `legacy-recovered-${Date.now()}.png`);
  fs.writeFileSync(replacementPath, Buffer.from('legacy-recovered'));
  const store = createDiaryStore({ userDataPath });
  try {
    const saved = store.saveEntry({ ...legacyEntry('legacy-missing-entry', '旧附件'), imagePaths: [missingPath] });
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 0, missing: 1, orphaned: 0 });
    const relocated = store.relocateAttachment(missingPath, replacementPath);
    assert.equal(relocated.merged, false);
    assert.equal(store.snapshot().entries.find((entry) => entry.id === 'legacy-missing-entry').imagePaths[0], relocated.path);
    assert.deepEqual(store.attachmentHealth(), { total: 1, ready: 1, missing: 0, orphaned: 0 });
    assert.notEqual(saved.entry.imagePaths[0], relocated.path);
  } finally {
    store.close();
    try { fs.unlinkSync(replacementPath); } catch {}
    fs.rmSync(userDataPath, { recursive: true, force: true });
  }
});

test('creates one rolling backup per day and keeps it idempotent', () => {
  const userDataPath = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-store-rolling-'));
  const store = createDiaryStore({ userDataPath });
  try {
    store.saveEntry(legacyEntry('rolling-entry', '每日备份'));
    const first = store.createRollingBackup(new Date('2026-09-16T08:00:00.000Z'));
    assert.equal(first.created, true);
    assert.equal(fs.existsSync(first.path), true);
    const second = store.createRollingBackup(new Date('2026-09-16T20:00:00.000Z'));
    assert.equal(second.skipped, true);
  } finally {
    store.close();
    fs.rmSync(userDataPath, { recursive: true, force: true });
  }
});
