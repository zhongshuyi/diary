import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from '../src/server.mjs';

function entry(id, updatedAt, overrides = {}) {
  return {
    schemaVersion: 2,
    id,
    createdAt: '2026-09-15T08:00:00.000Z',
    occurredAt: '2026-09-15T08:00:00.000Z',
    updatedAt,
    deletedAt: null,
    title: '测试记录',
    content: '正文',
    contentText: '正文',
    editorType: 'plain_text',
    mood: 0.7,
    category: '生活',
    tags: [],
    attachmentIds: [],
    isFavorite: false,
    revision: 1,
    deviceId: '',
    isConflict: false,
    conflictOf: null,
    conflictStatus: 'pending',
    ...overrides,
  };
}

async function withServer(run) {
  const directory = await mkdtemp(join(tmpdir(), 'diary-sync-v2-'));
  const { server } = createServer({ storeFile: join(directory, 'store.json'), authToken: 'test-token' });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  try { await run(`http://127.0.0.1:${port}`); }
  finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  }
}

async function sync(baseUrl, body) {
  const response = await fetch(`${baseUrl}/api/v2/sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer test-token' },
    body: JSON.stringify(body),
  });
  return { response, body: await response.json() };
}

test('v2 keeps a deterministic conflict copy and remains idempotent', async () => {
  await withServer(async (baseUrl) => {
    const winner = await sync(baseUrl, { protocolVersion: 2, deviceId: 'mobile-b', cursor: '0', changes: [{ mutationId: 'm-new', entry: entry('e-1', '2026-09-15T10:00:00.000Z', { contentText: '新内容' }) }] });
    assert.equal(winner.body.data.nextCursor, '1');

    const staleBody = { protocolVersion: 2, deviceId: 'desktop-a', cursor: '1', changes: [{ mutationId: 'm-old', entry: entry('e-1', '2026-09-15T09:00:00.000Z', { contentText: '旧内容' }) }] };
    const stale = await sync(baseUrl, staleBody);
    assert.deepEqual(stale.body.data.appliedMutationIds, ['m-old']);
    assert.equal(stale.body.data.conflicts[0].conflictId, 'conflict:e-1:m-old');
    assert.equal(stale.body.data.conflicts[0].entry.isConflict, true);

    const retry = await sync(baseUrl, staleBody);
    assert.deepEqual(retry.body.data.appliedMutationIds, ['m-old']);
    assert.equal(retry.body.data.changes.length, 0);

    const pull = await sync(baseUrl, { protocolVersion: 2, deviceId: 'other-c', cursor: '0', changes: [] });
    assert.equal(pull.body.data.changes.filter((change) => change.entry.isConflict).length, 1);
  });
});

test('v2 cursor only advances through the returned page', async () => {
  await withServer(async (baseUrl) => {
    const first = await sync(baseUrl, {
      protocolVersion: 2,
      deviceId: 'desktop-a',
      cursor: '0',
      limit: 1,
      changes: [
        { mutationId: 'm-1', entry: entry('e-1', '2026-09-15T09:00:00.000Z') },
        { mutationId: 'm-2', entry: entry('e-2', '2026-09-15T09:01:00.000Z') },
      ],
    });
    assert.equal(first.body.data.changes.length, 1);
    assert.equal(first.body.data.nextCursor, '1');
    const second = await sync(baseUrl, { protocolVersion: 2, deviceId: 'desktop-a', cursor: '1', limit: 1, changes: [] });
    assert.equal(second.body.data.changes[0].entry.id, 'e-2');
    assert.equal(second.body.data.nextCursor, '2');
  });
});
