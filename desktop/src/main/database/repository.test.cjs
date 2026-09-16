const test = require('node:test');
const assert = require('node:assert/strict');

const { openDatabase, closeDatabase } = require('./database.cjs');
const { initializeDatabase } = require('./migrations.cjs');
const {
  createOrUpdateEntry,
  listEntries,
  listPendingMutations,
  saveDraft,
  loadDraft,
  clearDraft,
  applySyncResult,
  moveEntryToTrash,
  restoreEntry,
  deleteEntryPermanently,
  searchEntries,
  listTaxonomyUsage,
  batchSetFavorite,
  batchMoveToTrash,
  batchUpdateOrganization,
  renameTag,
  deleteTag,
  renameCategory,
  deleteCategory,
  listAttachmentHealth,
} = require('./repository.cjs');

function sampleEntry(overrides = {}) {
  return {
    schemaVersion: 1,
    id: 'entry-1',
    createdAt: '2026-09-16T08:00:00.000Z',
    occurredAt: '2026-09-16T08:00:00.000Z',
    updatedAt: '2026-09-16T08:01:00.000Z',
    title: '',
    content: '在电脑前记下一句话',
    contentText: '在电脑前记下一句话',
    editorType: 'plain_text',
    mood: 0.6,
    moodSet: true,
    category: '工作',
    tags: ['灵感'],
    imagePaths: [],
    audioPaths: [],
    videoPaths: [],
    weather: [],
    positions: [],
    latitude: null,
    longitude: null,
    colorValue: 0xffe4e0ed,
    isFavorite: false,
    isInTrash: false,
    ...overrides,
  };
}

test('initializes the v2 schema and starts empty', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    assert.equal(db.prepare("SELECT value FROM app_meta WHERE key = 'schema_version'").get().value, '2');
    assert.equal(db.prepare("SELECT name FROM sqlite_master WHERE name = 'attachments'").get().name, 'attachments');
    assert.deepEqual(listEntries(db), []);
  } finally {
    closeDatabase(db);
  }
});

test('commits an entry and its outbox mutation atomically', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry(), { deviceId: 'desktop-1' });
    assert.equal(listEntries(db).length, 1);
    const mutations = listPendingMutations(db);
    assert.equal(mutations.length, 1);
    assert.equal(mutations[0].entry.id, 'entry-1');
    assert.match(mutations[0].mutationId, /^desktop-1:entry-1:/);
  } finally {
    closeDatabase(db);
  }
});

test('rolls back the entry when the outbox payload cannot be serialized', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    assert.throws(() => createOrUpdateEntry(db, sampleEntry({ content: BigInt(1) }), { deviceId: 'desktop-1' }));
    assert.deepEqual(listEntries(db), []);
    assert.deepEqual(listPendingMutations(db), []);
  } finally {
    closeDatabase(db);
  }
});

test('saves, loads, and clears a draft independently of entries', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    const draft = { id: 'main', entryId: null, payload: { content: '未提交草稿', title: '' } };
    saveDraft(db, draft);
    assert.deepEqual(loadDraft(db, 'main'), draft);
    assert.deepEqual(listEntries(db), []);
    clearDraft(db, 'main');
    assert.equal(loadDraft(db, 'main'), null);
  } finally {
    closeDatabase(db);
  }
});

test('applies newer remote changes, keeps stale local data, and acknowledges mutations atomically', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ updatedAt: '2026-09-16T09:00:00.000Z', content: '本地较新', contentText: '本地较新' }), { deviceId: 'desktop-1' });
    applySyncResult(db, {
      changes: [{ entry: sampleEntry({ updatedAt: '2026-09-16T08:30:00.000Z', content: '服务端较旧', contentText: '服务端较旧' }) }],
      conflicts: [{ mutationId: 'desktop-1:entry-1:local', serverEntry: sampleEntry({ updatedAt: '2026-09-16T10:00:00.000Z', content: '服务端较新', contentText: '服务端较新' }) }],
      acknowledgedMutationIds: ['desktop-1:entry-1:2026-09-16T09:00:00.000Z'],
      cursor: '9',
    });
    assert.equal(listEntries(db)[0].contentText, '服务端较新');
    assert.equal(listPendingMutations(db).length, 0);
    assert.equal(db.prepare("SELECT value FROM sync_state WHERE key = 'cursor'").get().value, '9');
  } finally {
    closeDatabase(db);
  }
});

test('moves an entry to trash and restores it through the same outbox transaction', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry(), { deviceId: 'desktop-1' });
    moveEntryToTrash(db, 'entry-1', { deviceId: 'desktop-1', updatedAt: '2026-09-16T09:00:00.000Z' });
    assert.equal(listEntries(db).length, 0);
    assert.equal(listEntries(db, { includeTrash: true })[0].isInTrash, true);
    restoreEntry(db, 'entry-1', { deviceId: 'desktop-1', updatedAt: '2026-09-16T10:00:00.000Z' });
    assert.equal(listEntries(db)[0].isInTrash, false);
    assert.equal(listPendingMutations(db).length, 1);
  } finally {
    closeDatabase(db);
  }
});

test('permanently deletes a trashed entry and its search and outbox records atomically', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry(), { deviceId: 'desktop-1' });
    moveEntryToTrash(db, 'entry-1', { deviceId: 'desktop-1' });
    assert.equal(deleteEntryPermanently(db, 'entry-1'), true);
    assert.deepEqual(listEntries(db, { includeTrash: true }), []);
    assert.deepEqual(listPendingMutations(db), []);
    assert.equal(db.prepare('SELECT COUNT(*) AS count FROM entry_search WHERE id = ?').get('entry-1').count, 0);
    assert.equal(deleteEntryPermanently(db, 'missing'), false);
  } finally {
    closeDatabase(db);
  }
});

test('searches Chinese text through trigram FTS and excludes trashed entries by default', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ id: 'one', content: '今天看到了很好的句子', contentText: '今天看到了很好的句子' }), { deviceId: 'desktop-1' });
    createOrUpdateEntry(db, sampleEntry({ id: 'two', content: '工作会议记录', contentText: '工作会议记录', isInTrash: true }), { deviceId: 'desktop-1' });
    assert.deepEqual(searchEntries(db, '好的').map((entry) => entry.id), ['one']);
    assert.deepEqual(searchEntries(db, '会议'), []);
    assert.deepEqual(searchEntries(db, '会议', { includeTrash: true }).map((entry) => entry.id), ['two']);
  } finally {
    closeDatabase(db);
  }
});

test('search filters by date, category, tags, mood, favorite, and attachment kind', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({
      id: 'work-image',
      occurredAt: '2026-09-15T08:00:00.000Z',
      category: '工作',
      tags: ['项目', '灵感'],
      mood: 0.7,
      moodSet: true,
      isFavorite: true,
      imagePaths: ['capture.png'],
    }));
    createOrUpdateEntry(db, sampleEntry({
      id: 'life-audio',
      occurredAt: '2026-09-16T08:00:00.000Z',
      category: '生活',
      tags: ['灵感'],
      mood: 0.3,
      moodSet: true,
      audioPaths: ['voice.mp3'],
    }));

    assert.deepEqual(searchEntries(db, '', {
      dateFrom: '2026-09-16',
      category: '生活',
      tags: ['灵感'],
      mood: 0.3,
      favorite: false,
      attachmentKind: 'audio',
    }).map((entry) => entry.id), ['life-audio']);
    assert.deepEqual(searchEntries(db, '', { tags: ['项目', '灵感'], favorite: true }).map((entry) => entry.id), ['work-image']);
    assert.deepEqual(searchEntries(db, '', { attachmentKind: 'image' }).map((entry) => entry.id), ['work-image']);
  } finally {
    closeDatabase(db);
  }
});

test('search pagination returns stable pages for filtered results', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    for (let index = 0; index < 3; index += 1) {
      createOrUpdateEntry(db, sampleEntry({
        id: `entry-${index}`,
        occurredAt: `2026-09-${String(16 - index).padStart(2, '0')}T08:00:00.000Z`,
        content: `分页记录 ${index}`,
        contentText: `分页记录 ${index}`,
      }));
    }
    assert.deepEqual(searchEntries(db, '分页', { limit: 2, offset: 0 }).map((entry) => entry.id), ['entry-0', 'entry-1']);
    assert.deepEqual(searchEntries(db, '分页', { limit: 2, offset: 2 }).map((entry) => entry.id), ['entry-2']);
  } finally {
    closeDatabase(db);
  }
});

test('calculates taxonomy usage across the full local database', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ id: 'older', occurredAt: '2026-09-10T08:00:00.000Z', category: '工作', tags: ['项目', '常用'] }));
    createOrUpdateEntry(db, sampleEntry({ id: 'newer', occurredAt: '2026-09-16T08:00:00.000Z', category: '生活', tags: ['常用'] }));
    createOrUpdateEntry(db, sampleEntry({ id: 'trash', occurredAt: '2026-09-17T08:00:00.000Z', category: '工作', tags: ['常用', '不应出现'], isInTrash: true }));
    assert.deepEqual(listTaxonomyUsage(db), { categories: ['生活', '工作'], tags: ['常用', '项目'] });
    const detailed = listTaxonomyUsage(db, { detailed: true });
    assert.equal(detailed.tagStats.find((item) => item.value === '常用').count, 2);
    assert.equal(detailed.categoryStats.find((item) => item.value === '生活').count, 1);
  } finally {
    closeDatabase(db);
  }
});

test('updates favorites for multiple entries atomically', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ id: 'one' }), { deviceId: 'desktop-1' });
    createOrUpdateEntry(db, sampleEntry({ id: 'two' }), { deviceId: 'desktop-1' });
    const changed = batchSetFavorite(db, ['one', 'two', 'missing'], true, { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:00:00.000Z' });
    assert.equal(changed.length, 2);
    assert.equal(listEntries(db).every((entry) => entry.isFavorite), true);
    assert.equal(listPendingMutations(db).length, 2);
  } finally {
    closeDatabase(db);
  }
});

test('moves multiple entries to trash in one transaction and skips already trashed entries', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ id: 'one' }), { deviceId: 'desktop-1' });
    createOrUpdateEntry(db, sampleEntry({ id: 'two' }), { deviceId: 'desktop-1' });
    createOrUpdateEntry(db, sampleEntry({ id: 'trash', isInTrash: true }), { deviceId: 'desktop-1' });
    const changed = batchMoveToTrash(db, ['one', 'two', 'trash'], { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:00:00.000Z' });
    assert.deepEqual(changed.sort(), ['one', 'two']);
    assert.equal(listEntries(db).length, 0);
    assert.equal(listEntries(db, { includeTrash: true }).length, 3);
    assert.equal(listPendingMutations(db).length, 3);
  } finally {
    closeDatabase(db);
  }
});

test('updates category and toggles tags for multiple entries atomically', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ id: 'one', tags: ['旧标签'] }), { deviceId: 'desktop-1' });
    createOrUpdateEntry(db, sampleEntry({ id: 'two', tags: [] }), { deviceId: 'desktop-1' });
    const changed = batchUpdateOrganization(db, ['one', 'two'], { category: '工作', addTags: ['项目'] }, { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:00:00.000Z' });
    assert.deepEqual(changed.sort(), ['one', 'two']);
    assert.equal(listEntries(db).every((entry) => entry.category === '工作'), true);
    assert.deepEqual(listEntries(db).find((entry) => entry.id === 'one').tags, ['旧标签', '项目']);
    batchUpdateOrganization(db, ['one', 'two'], { removeTags: ['项目'] }, { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:01:00.000Z' });
    assert.equal(listEntries(db).some((entry) => entry.tags.includes('项目')), false);
  } finally {
    closeDatabase(db);
  }
});

test('renames and removes taxonomy values across active and trashed entries', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ id: 'active', category: '工作', tags: ['项目', '旧标签'] }), { deviceId: 'desktop-1' });
    createOrUpdateEntry(db, sampleEntry({ id: 'trashed', category: '工作', tags: ['项目'], isInTrash: true }), { deviceId: 'desktop-1' });
    assert.deepEqual(renameTag(db, '旧标签', '项目', { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:00:00.000Z' }).sort(), ['active']);
    assert.deepEqual(listEntries(db, { includeTrash: true }).find((entry) => entry.id === 'active').tags, ['项目']);
    assert.deepEqual(renameCategory(db, '工作', '项目日志', { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:01:00.000Z' }).sort(), ['active', 'trashed']);
    assert.equal(listEntries(db, { includeTrash: true }).every((entry) => entry.category === '项目日志'), true);
    assert.deepEqual(deleteTag(db, '项目', { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:02:00.000Z' }).sort(), ['active', 'trashed']);
    assert.equal(listEntries(db, { includeTrash: true }).every((entry) => entry.tags.length === 0), true);
    assert.deepEqual(deleteCategory(db, '项目日志', { deviceId: 'desktop-1', updatedAt: '2026-09-16T12:03:00.000Z' }).sort(), ['active', 'trashed']);
    assert.equal(listEntries(db, { includeTrash: true }).every((entry) => entry.category === '未分类'), true);
  } finally {
    closeDatabase(db);
  }
});

test('stores stable attachment metadata and entry references in the same transaction', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    createOrUpdateEntry(db, sampleEntry({ imagePaths: ['media/photo.png', 'media/photo.png'] }), {
      deviceId: 'desktop-1',
      assets: [{ id: 'asset-hash-1', sha256: 'a'.repeat(64), kind: 'image', mimeType: 'image/png', byteSize: 1234, originalName: 'photo.png', relativePath: 'media/photo.png', state: 'ready' }],
    });
    assert.deepEqual(db.prepare('SELECT attachment_id FROM entry_attachments WHERE entry_id = ?').all('entry-1').map((row) => row.attachment_id), ['asset-hash-1']);
    const attachment = db.prepare('SELECT id, sha256, relative_path, state FROM attachments').get();
    assert.equal(attachment.id, 'asset-hash-1');
    assert.equal(attachment.sha256, 'a'.repeat(64));
    assert.equal(attachment.relative_path, 'media/photo.png');
    assert.equal(attachment.state, 'ready');
    assert.deepEqual(listAttachmentHealth(db), { total: 1, ready: 1, missing: 0, orphaned: 0 });
    createOrUpdateEntry(db, sampleEntry({ imagePaths: [], updatedAt: '2026-09-16T08:02:00.000Z' }), { assets: [] });
    assert.equal(db.prepare('SELECT COUNT(*) AS count FROM entry_attachments WHERE entry_id = ?').get('entry-1').count, 0);
    assert.deepEqual(listAttachmentHealth(db), { total: 1, ready: 0, missing: 0, orphaned: 1 });
  } finally {
    closeDatabase(db);
  }
});
