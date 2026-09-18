import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from '../src/server.mjs';

test('serves release downloads publicly without exposing files outside the release directory', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'diary-downloads-'));
  const releases = join(directory, 'releases');
  const apkName = 'diary-android-1.0.0.apk';
  await mkdir(releases);
  await writeFile(join(releases, apkName), 'apk-bytes');
  await writeFile(join(directory, 'secret.txt'), 'must-not-leak');

  const { server } = createServer({
    storeFile: join(directory, 'store.json'),
    authToken: 'test-token',
    releaseDirectory: releases,
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    const download = await fetch(`${baseUrl}/downloads/${apkName}`);
    assert.equal(download.status, 200);
    assert.equal(download.headers.get('content-type'), 'application/vnd.android.package-archive');
    assert.equal(await download.text(), 'apk-bytes');

    const traversal = await fetch(`${baseUrl}/downloads/../secret.txt`, {
      headers: { Authorization: 'Bearer test-token' },
    });
    assert.equal(traversal.status, 404);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  }
});
