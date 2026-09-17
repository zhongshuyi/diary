import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from '../src/server.mjs';

async function withUpdateServer(manifest, run) {
  const directory = await mkdtemp(join(tmpdir(), 'diary-update-'));
  const manifestPath = join(directory, 'update-manifest.json');
  await writeFile(manifestPath, JSON.stringify(manifest));
  const { server } = createServer({
    storeFile: join(directory, 'store.json'),
    authToken: 'test-token',
    updateManifestFile: manifestPath,
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

test('serves platform-specific update metadata without sync bearer auth', async () => {
  await withUpdateServer({
    platforms: {
      desktop: {
        version: '0.2.0',
        downloadUrl: 'https://download.example.com/diary-desktop',
        notes: '桌面端更新',
      },
      mobile: {
        version: '1.1.0',
        downloadUrl: 'https://download.example.com/diary-mobile',
        notes: '手机端更新',
      },
    },
  }, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/v1/update?platform=mobile`);
    assert.equal(response.status, 200);
    assert.deepEqual((await response.json()).data, {
      platform: 'mobile',
      version: '1.1.0',
      downloadUrl: 'https://download.example.com/diary-mobile',
      notes: '手机端更新',
    });
  });
});

test('returns a not-found response when the requested platform has no update metadata', async () => {
  await withUpdateServer({ platforms: {} }, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/v1/update?platform=desktop`);
    assert.equal(response.status, 404);
    assert.equal((await response.json()).error.code, 'update_not_found');
  });
});

test('requires a platform and rejects malformed update metadata', async () => {
  await withUpdateServer({
    platforms: {
      desktop: {
        version: 'not-a-version',
        downloadUrl: 'file:///unsafe',
      },
    },
  }, async (baseUrl) => {
    const missingPlatform = await fetch(`${baseUrl}/api/v1/update`);
    assert.equal(missingPlatform.status, 400);
    assert.equal((await missingPlatform.json()).error.code, 'platform_required');

    const malformed = await fetch(`${baseUrl}/api/v1/update?platform=desktop`);
    assert.equal(malformed.status, 500);
    assert.equal((await malformed.json()).error.code, 'update_unavailable');
  });
});
