const test = require('node:test');
const assert = require('node:assert/strict');

const { hydrateSyncData, prepareSyncBody } = require('./sync-asset-transfer.cjs');

const sha = 'b'.repeat(64);

test('uploads ready entry assets before replacing their local paths in an outgoing sync body', async () => {
  const uploaded = [];
  const body = await prepareSyncBody({
    changes: [{ mutationId: 'desktop:entry-1:1', entry: { id: 'entry-1', imagePaths: ['C:/diary/media/managed/photo.png'], audioPaths: [], videoPaths: [] } }],
  }, {
    listAssets: async (entryId) => [{ id: `asset-${sha}`, sha256: sha, localPath: 'C:/diary/media/managed/photo.png', state: 'ready', kind: 'image' }],
    uploadAsset: async (asset) => uploaded.push(asset.sha256),
  });

  assert.deepEqual(uploaded, [sha]);
  assert.equal(body.changes[0].entry.imagePaths[0], `asset://${sha}.png`);
  assert.deepEqual(body.changes[0].entry.attachmentIds, [`asset-${sha}`]);
});

test('downloads portable assets once and hydrates both changes and conflicts with local paths', async () => {
  const downloaded = [];
  const data = await hydrateSyncData({
    changes: [{ entry: { id: 'entry-1', imagePaths: [`asset://${sha}.jpg`], audioPaths: [], videoPaths: [] } }],
    conflicts: [{ serverEntry: { id: 'entry-2', imagePaths: [], audioPaths: [`asset://${sha}.jpg`], videoPaths: [] } }],
  }, {
    downloadAsset: async (asset) => {
      downloaded.push(asset);
      return `C:/diary/media/managed/${asset.sha256}${asset.extension}`;
    },
  });

  assert.equal(downloaded.length, 1);
  assert.equal(data.changes[0].entry.imagePaths[0], `C:/diary/media/managed/${sha}.jpg`);
  assert.equal(data.conflicts[0].serverEntry.audioPaths[0], `C:/diary/media/managed/${sha}.jpg`);
});
