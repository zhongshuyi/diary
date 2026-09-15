import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from '../src/server.mjs';

function entry(id, updatedAt, overrides = {}) {
  return {
    schemaVersion: 1,
    id,
    createdAt: '2026-09-15T08:00:00.000Z',
    updatedAt,
    title: '测试记录',
    content: '正文',
    contentText: '正文',
    editorType: 'plain_text',
    mood: 0.7,
    category: '生活',
    tags: [],
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

async function withServer(run) {
  const directory = await mkdtemp(join(tmpdir(), 'diary-sync-'));
  const { server } = createServer({
    storeFile: join(directory, 'store.json'),
    authToken: 'test-token',
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  }
}

async function sync(baseUrl, body, token = 'test-token') {
  const response = await fetch(`${baseUrl}/api/v1/sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  return { response, body: await response.json() };
}

test('health and bearer auth are available', async () => {
  await withServer(async (baseUrl) => {
    const health = await fetch(`${baseUrl}/health`);
    assert.equal(health.status, 200);
    assert.equal((await health.json()).data.protocolVersion, 1);

    const unauthorized = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'desktop-a',
      changes: [],
    }, 'wrong-token');
    assert.equal(unauthorized.response.status, 401);
    assert.equal(unauthorized.body.error.code, 'unauthorized');
  });
});

test('push is idempotent and pull uses a cursor', async () => {
  await withServer(async (baseUrl) => {
    const mutation = {
      mutationId: 'desktop-a:entry-1:1',
      entry: entry('entry-1', '2026-09-15T09:00:00.000Z'),
    };
    const first = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'desktop-a',
      cursor: '0',
      changes: [mutation],
    });
    assert.equal(first.response.status, 200);
    assert.deepEqual(first.body.data.appliedMutationIds, [mutation.mutationId]);
    assert.equal(first.body.data.nextCursor, '1');

    const retry = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'desktop-a',
      cursor: '1',
      changes: [mutation],
    });
    assert.equal(retry.response.status, 200);
    assert.deepEqual(retry.body.data.appliedMutationIds, [mutation.mutationId]);
    assert.equal(retry.body.data.changes.length, 0);

    const pull = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'mobile-b',
      cursor: '0',
      changes: [],
    });
    assert.equal(pull.body.data.changes.length, 1);
    assert.equal(pull.body.data.changes[0].entry.id, 'entry-1');
  });
});

test('newer updates win deterministically and stale updates return a conflict', async () => {
  await withServer(async (baseUrl) => {
    const newer = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'mobile-b',
      changes: [{
        mutationId: 'mobile-b:entry-1:newer',
        entry: entry('entry-1', '2026-09-15T10:00:00.000Z', { contentText: '新内容' }),
      }],
    });
    assert.equal(newer.body.data.nextCursor, '1');

    const stale = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'desktop-a',
      changes: [{
        mutationId: 'desktop-a:entry-1:stale',
        entry: entry('entry-1', '2026-09-15T09:00:00.000Z'),
      }],
    });
    assert.equal(stale.body.data.nextCursor, '1');
    assert.equal(stale.body.data.conflicts[0].serverEntry.contentText, '新内容');
  });
});

test('cursor advances only through the returned page', async () => {
  await withServer(async (baseUrl) => {
    const pushed = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'desktop-a',
      cursor: '0',
      limit: 1,
      changes: [
        { mutationId: 'desktop-a:entry-1:1', entry: entry('entry-1', '2026-09-15T09:00:00.000Z') },
        { mutationId: 'desktop-a:entry-2:1', entry: entry('entry-2', '2026-09-15T09:01:00.000Z') },
      ],
    });
    assert.equal(pushed.body.data.changes.length, 1);
    assert.equal(pushed.body.data.nextCursor, '1');

    const nextPage = await sync(baseUrl, {
      protocolVersion: 1,
      deviceId: 'desktop-a',
      cursor: pushed.body.data.nextCursor,
      limit: 1,
      changes: [],
    });
    assert.equal(nextPage.body.data.changes.length, 1);
    assert.equal(nextPage.body.data.changes[0].entry.id, 'entry-2');
    assert.equal(nextPage.body.data.nextCursor, '2');
  });
});
