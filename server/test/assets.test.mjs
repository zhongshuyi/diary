import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from '../src/server.mjs';

async function withServer(run) {
  const directory = await mkdtemp(join(tmpdir(), 'diary-assets-'));
  const { server } = createServer({ storeFile: join(directory, 'store.json'), authToken: 'test-token' });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  try { await run(`http://127.0.0.1:${port}`); }
  finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  }
}

test('asset PUT is hash checked and HEAD/GET are idempotent', async () => {
  await withServer(async (baseUrl) => {
    const bytes = Buffer.from('asset-data');
    const sha = createHash('sha256').update(bytes).digest('hex');
    const headers = { Authorization: 'Bearer test-token', 'Content-Type': 'text/plain', 'X-Asset-Kind': 'file', 'Content-Length': String(bytes.length) };
    const put = await fetch(`${baseUrl}/api/v2/assets/${sha}`, { method: 'PUT', headers, body: bytes });
    assert.equal(put.status, 201);
    const head = await fetch(`${baseUrl}/api/v2/assets/${sha}`, { method: 'HEAD', headers: { Authorization: 'Bearer test-token' } });
    assert.equal(head.status, 200);
    assert.equal(head.headers.get('content-length'), String(bytes.length));
    const get = await fetch(`${baseUrl}/api/v2/assets/${sha}`, { headers: { Authorization: 'Bearer test-token' } });
    assert.equal(Buffer.from(await get.arrayBuffer()).toString(), 'asset-data');
  });
});

test('asset PUT rejects a SHA mismatch', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/v2/assets/${'a'.repeat(64)}`, {
      method: 'PUT',
      headers: { Authorization: 'Bearer test-token', 'Content-Type': 'text/plain', 'X-Asset-Kind': 'file' },
      body: 'wrong',
    });
    assert.equal(response.status, 422);
    assert.equal((await response.json()).error.code, 'validation_error');
  });
});
