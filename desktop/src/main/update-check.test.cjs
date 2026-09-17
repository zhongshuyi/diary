const test = require('node:test');
const assert = require('node:assert/strict');

let updateCheck;
try {
  updateCheck = require('./update-check.cjs');
} catch {
  updateCheck = null;
}

test('compares dotted app versions numerically', () => {
  assert.ok(updateCheck, 'update checker should be available');
  assert.equal(updateCheck.compareVersions('1.10.0', '1.2.0'), 1);
  assert.equal(updateCheck.compareVersions('1.2.0', '1.2.0'), 0);
  assert.equal(updateCheck.compareVersions('1.2.0', '1.10.0'), -1);
});

test('marks a release as available only when it is newer than the current version', () => {
  assert.ok(updateCheck, 'update checker should be available');
  assert.equal(updateCheck.isUpdateAvailable('0.1.0', '0.2.0'), true);
  assert.equal(updateCheck.isUpdateAvailable('0.2.0', '0.1.0'), false);
});

test('requests update metadata from the configured sync server', async () => {
  assert.ok(updateCheck, 'update checker should be available');
  let requestedUrl;
  const result = await updateCheck.checkForUpdate({
    baseUrl: 'https://sync.example.com/api/v1/sync',
    currentVersion: '0.1.0',
    fetchImpl: async (url) => {
      requestedUrl = url;
      return {
        ok: true,
        status: 200,
        json: async () => ({ data: { platform: 'desktop', version: '0.2.0', downloadUrl: 'https://download.example.com', notes: '修复问题' } }),
      };
    },
  });
  assert.equal(requestedUrl, 'https://sync.example.com/api/v1/update?platform=desktop');
  assert.equal(result.hasUpdate, true);
  assert.equal(result.latestVersion, '0.2.0');
});

test('aborts a stalled update request', async () => {
  assert.ok(updateCheck, 'update checker should be available');
  const result = await Promise.race([
    updateCheck.checkForUpdate({
      baseUrl: 'https://sync.example.com',
      currentVersion: '0.1.0',
      timeoutMs: 10,
      fetchImpl: async (_url, options = {}) => new Promise((_resolve, reject) => {
        options.signal?.addEventListener('abort', () => reject(Object.assign(new Error('aborted'), { name: 'AbortError' })));
      }),
    }).then(() => null).catch((error) => error),
    new Promise((resolve) => setTimeout(() => resolve('sentinel'), 100)),
  ]);
  assert.notEqual(result, 'sentinel');
  assert.match(result.message, /timed out/i);
});

test('accepts only web URLs for external downloads', () => {
  assert.ok(updateCheck, 'update checker should be available');
  assert.equal(updateCheck.isSafeExternalUrl('https://download.example.com'), true);
  assert.equal(updateCheck.isSafeExternalUrl('http://127.0.0.1:8787/file'), true);
  assert.equal(updateCheck.isSafeExternalUrl('file:///etc/passwd'), false);
});
