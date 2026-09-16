const test = require('node:test');
const assert = require('node:assert/strict');
const { openDatabase, closeDatabase } = require('./database.cjs');
const { initializeDatabase, } = require('./migrations.cjs');
const { applySyncResult, listConflicts, resolveConflict, listEntries, listPendingMutations } = require('./repository.cjs');

function entry(id, content) {
  return { schemaVersion: 2, id, createdAt: '2026-09-16T08:00:00.000Z', occurredAt: '2026-09-16T08:00:00.000Z', updatedAt: '2026-09-16T08:01:00.000Z', title: id, content, contentText: content, editorType: 'plain_text', mood: 0.5, category: '生活', tags: [], imagePaths: [], audioPaths: [], videoPaths: [], isFavorite: false, isInTrash: false };
}

test('stores conflict copies separately and resolves them with a mutation', () => {
  const db = openDatabase(':memory:');
  try {
    initializeDatabase(db);
    applySyncResult(db, {
      changes: [{ entry: entry('entry-1', '主版本') }],
      conflicts: [{ conflictId: 'conflict:entry-1:m-2', entryId: 'entry-1', entry: { ...entry('conflict:entry-1:m-2', '冲突版本'), isConflict: true, conflictOf: 'entry-1' }, serverEntry: entry('entry-1', '主版本'), mutationId: 'm-2', sourceDeviceId: 'phone-a' }],
      acknowledgedMutationIds: ['m-2'],
      cursor: '3',
    });
    assert.equal(listEntries(db).map((item) => item.id).includes('conflict:entry-1:m-2'), false);
    assert.equal(listConflicts(db).length, 1);
    resolveConflict(db, { conflictId: 'conflict:entry-1:m-2', resolution: entry('entry-1', '合并结果'), deviceId: 'desktop-a' });
    assert.equal(listConflicts(db, { status: 'pending' }).length, 0);
    assert.equal(listEntries(db)[0].contentText, '合并结果');
    assert.equal(listPendingMutations(db).length, 1);
  } finally {
    closeDatabase(db);
  }
});
