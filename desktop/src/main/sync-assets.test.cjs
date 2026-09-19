const test = require('node:test');
const assert = require('node:assert/strict');

const { buildPortableSyncEntry, hydratePortableEntry, parsePortableAssetPath } = require('./sync-assets.cjs');

const sha = 'a'.repeat(64);

test('replaces a managed local attachment with a portable asset reference before sync', () => {
  const entry = { id: 'entry-1', imagePaths: ['C:\\diary\\media\\managed\\photo.jpg'], audioPaths: [], videoPaths: [], attachmentIds: [] };
  const assets = [{ id: `asset-${sha}`, sha256: sha, localPath: 'C:\\diary\\media\\managed\\photo.jpg' }];

  assert.deepEqual(buildPortableSyncEntry(entry, assets), {
    ...entry,
    imagePaths: [`asset://${sha}.jpg`],
    attachmentIds: [`asset-${sha}`],
  });
});

test('hydrates portable attachment references using the downloaded managed paths', () => {
  const entry = { id: 'entry-1', imagePaths: [`asset://${sha}.jpg`], audioPaths: [], videoPaths: [] };

  assert.deepEqual(
    hydratePortableEntry(entry, (asset) => `C:\\diary\\media\\managed\\${asset.sha256}.jpg`),
    { ...entry, imagePaths: [`C:\\diary\\media\\managed\\${sha}.jpg`] },
  );
  assert.deepEqual(parsePortableAssetPath(`asset://${sha}.jpg`), { sha256: sha, extension: '.jpg' });
});
