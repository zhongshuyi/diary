import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeV2Request, normalizeEntryV2, validateAssetMetadata } from '../src/protocol-v2.mjs';

test('v2 request normalizes cursor and mutation entry', () => {
  const result = normalizeV2Request({
    protocolVersion: 2,
    deviceId: 'phone-a',
    cursor: '7',
    changes: [{ mutationId: 'm-1', entry: { id: 'e-1', createdAt: '2026-09-16T08:00:00.000Z', updatedAt: '2026-09-16T08:01:00.000Z', title: '一句话', content: '正文' } }],
  });
  assert.equal(result.cursor, '7');
  assert.equal(result.mutations[0].entry.occurredAt, '2026-09-16T08:00:00.000Z');
  assert.equal(result.mutations[0].entry.revision, 1);
});

test('v2 entry preserves conflict, tombstone and attachment fields', () => {
  const entry = normalizeEntryV2({ id: 'conflict:e-1:m-2', isConflict: true, isDeleted: true, conflictOf: 'e-1', attachmentIds: ['asset-a', 'asset-a'] });
  assert.equal(entry.isConflict, true);
  assert.equal(entry.isDeleted, true);
  assert.equal(entry.conflictOf, 'e-1');
  assert.deepEqual(entry.attachmentIds, ['asset-a']);
});

test('v2 rejects invalid protocol and asset metadata', () => {
  assert.throws(() => normalizeV2Request({ protocolVersion: 1, deviceId: 'phone-a', changes: [] }), /protocolVersion/);
  const result = validateAssetMetadata({ sha256: 'bad', kind: 'unknown', byteSize: 128 * 1024 * 1024 + 1 });
  assert.equal(result.valid, false);
  assert.deepEqual(result.details.map((item) => item.field), ['sha256', 'kind', 'byteSize']);
});
