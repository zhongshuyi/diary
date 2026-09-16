const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { buildZip, readZip } = require('./backup.cjs');
const { createDiaryStore } = require('./database/store.cjs');

test('round-trips UTF-8 files through the portable ZIP container', () => {
  const archive = buildZip([
    { name: 'manifest.json', data: Buffer.from('{"title":"此刻"}') },
    { name: '附件/截图.txt', data: Buffer.from('一段附件内容') },
  ]);
  const files = readZip(archive);
  assert.equal(files.get('manifest.json').toString('utf8'), '{"title":"此刻"}');
  assert.equal(files.get('附件/截图.txt').toString('utf8'), '一段附件内容');
});

test('rejects traversal names and truncated archives', () => {
  assert.throws(() => buildZip([{ name: '../outside.txt', data: 'x' }]), /Invalid backup path/);
  assert.throws(() => readZip(Buffer.from('not a zip')), /Backup archive is truncated/);
});

test('exports a diary package and imports it into an empty store', () => {
  const sourceRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-backup-source-'));
  const destinationRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-backup-dest-'));
  const sourceFile = path.join(sourceRoot, '截图.png');
  const archivePath = path.join(sourceRoot, 'diary-export.diary.zip');
  fs.writeFileSync(sourceFile, Buffer.from('fake-image-data'));
  const source = createDiaryStore({ userDataPath: sourceRoot });
  const destination = createDiaryStore({ userDataPath: destinationRoot });
  try {
    source.saveEntry({ id: 'backup-entry', createdAt: '2026-09-16T08:00:00.000Z', occurredAt: '2026-09-16T08:00:00.000Z', updatedAt: '2026-09-16T08:00:00.000Z', title: '备份测试', content: '需要迁移', contentText: '需要迁移', category: '工作', tags: ['迁移'], imagePaths: [sourceFile], audioPaths: [], videoPaths: [], mood: null, moodSet: false, isFavorite: true, isInTrash: false });
    const exported = source.exportBackup(archivePath);
    assert.equal(exported.entries, 1);
    assert.equal(exported.attachments, 1);
    const preview = destination.previewBackup(archivePath);
    assert.equal(preview.valid, true);
    assert.equal(preview.entries, 1);
    assert.equal(preview.attachments, 1);
    const imported = destination.importBackup(archivePath);
    assert.equal(imported.importedEntries, 1);
    assert.equal(destination.listEntries({ includeTrash: true })[0].contentText, '需要迁移');
    assert.equal(destination.attachmentHealth().ready, 1);
    const importedAgain = destination.importBackup(archivePath);
    assert.equal(importedAgain.importedEntries, 0);
    assert.equal(importedAgain.importedAttachments, 0);
    assert.equal(fs.readdirSync(path.join(destinationRoot, 'media', 'managed')).length, 1);
    assert.equal(destination.attachmentHealth().ready, 1);
  } finally {
    source.close();
    destination.close();
    fs.rmSync(sourceRoot, { recursive: true, force: true });
    fs.rmSync(destinationRoot, { recursive: true, force: true });
  }
});

test('cleans newly promoted attachment files when database import fails', () => {
  const sourceRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-backup-failing-source-'));
  const destinationRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-backup-failing-dest-'));
  const archivePath = path.join(sourceRoot, 'invalid.diary.zip');
  const data = Buffer.from('attachment-to-clean');
  const hash = require('node:crypto').createHash('sha256').update(data).digest('hex');
  const destination = createDiaryStore({ userDataPath: destinationRoot });
  try {
    const archive = buildZip([
      { name: 'manifest.json', data: Buffer.from(JSON.stringify({ format: 'diary-backup', version: 1, schemaVersion: 2 })) },
      { name: 'entries.json', data: Buffer.from(JSON.stringify([{ id: 'broken-entry', updatedAt: '2026-09-16T08:00:00.000Z', content: 42 }])) },
      { name: 'attachments.json', data: Buffer.from(JSON.stringify([{ id: 'asset-broken', sha256: hash, kind: 'image', mimeType: 'image/png', byteSize: data.length, originalName: 'broken.png', state: 'ready', archivePath: 'attachments/asset-broken.png', entries: [{ entryId: 'broken-entry', sortOrder: 0, caption: '' }] }])) },
      { name: 'attachments/asset-broken.png', data },
    ]);
    fs.writeFileSync(archivePath, archive);
    assert.throws(() => destination.importBackup(archivePath), (error) => {
      assert.match(error.message, /Expected a string value/);
      assert.equal(error.importPhase, 'database');
      assert.equal(error.importCleanup.removedFiles, 1);
      return true;
    });
    assert.equal(fs.existsSync(path.join(destinationRoot, 'media', 'managed', `${hash}.png`)), false);
    assert.equal(destination.listEntries({ includeTrash: true }).length, 0);
    assert.equal(destination.attachmentHealth().total, 0);
  } finally {
    destination.close();
    fs.rmSync(sourceRoot, { recursive: true, force: true });
    fs.rmSync(destinationRoot, { recursive: true, force: true });
  }
});
