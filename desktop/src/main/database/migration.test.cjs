const test = require('node:test');
const assert = require('node:assert/strict');

const { openDatabase, closeDatabase } = require('./database.cjs');
const { initializeDatabase } = require('./migrations.cjs');
const { importLegacyData, readMigrationReport } = require('./legacy-migration.cjs');
const { listEntries, listPendingMutations } = require('./repository.cjs');

test('upgrades an installed v2 database with the mood label column', () => {
  const db = openDatabase(':memory:');
  try {
    db.exec(`
      CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
      INSERT INTO app_meta(key, value) VALUES ('schema_version', '2');
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        occurred_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        category TEXT NOT NULL DEFAULT '生活'
      );
    `);
    initializeDatabase(db);
    assert.equal(db.prepare("SELECT value FROM app_meta WHERE key = 'schema_version'").get().value, '3');
    assert.equal(db.prepare("SELECT name FROM pragma_table_info('entries') WHERE name = 'mood_label'").get().name, 'mood_label');
  } finally {
    closeDatabase(db);
  }
});

test('imports v1 entries, outbox, cursor, and settings with an auditable report', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    const report = importLegacyData(db, {
      entries: [{
        id: 'legacy-1',
        createdAt: '2026-09-15T08:00:00.000Z',
        updatedAt: '2026-09-15T08:10:00.000Z',
        title: '',
        content: '旧记录',
        contentText: '旧记录',
        category: '生活',
        tags: ['迁移'],
        imagePaths: ['C:/media/old.png'],
        audioPaths: [],
        videoPaths: [],
        mood: 0.5,
        isInTrash: false,
      }],
      outbox: [{ mutationId: 'legacy-device:legacy-1:1', entry: { id: 'legacy-1' } }],
      cursor: '42',
      deviceId: 'legacy-device',
      settings: { theme: 'dark', serverUrl: 'http://localhost:8787' },
    });
    assert.deepEqual(report, { entries: 1, mutations: 1, settings: 2, skippedEntries: 0 });
    assert.equal(listEntries(db)[0].id, 'legacy-1');
    assert.equal(listEntries(db)[0].occurredAt, '2026-09-15T08:00:00.000Z');
    assert.equal(listEntries(db)[0].imagePaths[0], 'C:/media/old.png');
    assert.equal(listPendingMutations(db).length, 1);
    assert.equal(db.prepare("SELECT value FROM sync_state WHERE key = 'cursor'").get().value, '42');
    assert.equal(db.prepare("SELECT value_json FROM settings WHERE key = 'theme'").get().value_json, '"dark"');
    assert.deepEqual(readMigrationReport(db), report);
  } finally {
    closeDatabase(db);
  }
});

test('rolls back the complete legacy import when a record is invalid', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    assert.throws(() => importLegacyData(db, {
      entries: [{ id: 'good', createdAt: '2026-09-15T08:00:00.000Z', content: '好' }, { id: 'bad', content: BigInt(1) }],
      outbox: [],
      cursor: '0',
      settings: {},
    }));
    assert.deepEqual(listEntries(db), []);
    assert.deepEqual(listPendingMutations(db), []);
    assert.equal(db.prepare("SELECT value FROM sync_state WHERE key = 'cursor'").get(), undefined);
  } finally {
    closeDatabase(db);
  }
});
