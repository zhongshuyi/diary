import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, utimesSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join, resolve } from 'node:path';
import { parseVersion, parseMobileVersion, assertVersionIncrease, assertTag, assertSourceCommit, assertPublishedRelease, releaseInfo, assertFreshArtifact, assertApkMetadata, assertDesktopMetadata, updateManifest } from './release.mjs';

function removeTestDirectory(root) {
  assert.equal(dirname(resolve(root)), resolve(tmpdir()));
  assert.ok(basename(root).startsWith('diary-release-test-'));
  rmSync(root, { recursive: true, force: true });
}

test('版本拒绝不规范格式、预览和 build 后缀', () => {
  for (const value of ['1.2', '01.2.3', '1.2.3+4', '1.2.3-beta', '1.2.3/../x', '9007199254740992.0.0']) {
    assert.throws(() => parseVersion(value));
  }
  assert.deepEqual(parseVersion('1.20.3'), [1, 20, 3]);
});

test('版本递增按数字比较，拒绝相同或降级', () => {
  assertVersionIncrease('1.9.9', '1.10.0');
  assertVersionIncrease('1.9.9', '2.0.0');
  for (const next of ['1.9.9', '1.9.8', '0.99.99']) assert.throws(() => assertVersionIncrease('1.9.9', next));
});

test('Android 必须具有有效且可安装的 versionCode', () => {
  assert.deepEqual(parseMobileVersion('name: diary\nversion: 1.0.2+3\n'), { version: '1.0.2', build: 3 });
  for (const version of ['1.0.2', '1.0.2+0', '1.0.2+03', '1.0.2+3.5', '1.0.2+2100000001', '1.0.2+3+4']) {
    assert.throws(() => parseMobileVersion(`version: ${version}\n`));
  }
});

test('两端独立 tag，跨平台与旧版本 tag 均停止', () => {
  const info = { tag: 'mobile-v1.0.2' };
  assertTag(info, 'mobile-v1.0.2');
  assert.throws(() => assertTag(info, 'desktop-v1.0.2'));
  assert.throws(() => assertTag(info, 'mobile-v1.0.1'));
});

test('同版本的 tag 已指向其他提交时不能关联新安装包', () => {
  const source = 'a'.repeat(40);
  assertSourceCommit(source, source);
  assert.throws(() => assertSourceCommit('b'.repeat(40), source));
  assert.throws(() => assertSourceCommit('main', source));
});

test('更新清单不能指向草稿、缺失资产或错误 URL，桌面公开预览可用', () => {
  const info = { platform: 'desktop', tag: 'desktop-v0.1.1', fileName: 'setup.exe', downloadUrl: 'https://example.com/setup.exe' };
  const release = { tagName: info.tag, isDraft: false, isPrerelease: true, assets: [{ name: info.fileName, state: 'uploaded', size: 100, url: info.downloadUrl }] };
  assertPublishedRelease(release, info);
  assert.throws(() => assertPublishedRelease({ ...release, isDraft: true }, info));
  assert.throws(() => assertPublishedRelease({ ...release, assets: [] }, info));
  assert.throws(() => assertPublishedRelease({ ...release, assets: [{ ...release.assets[0], url: 'https://example.com/old.exe' }] }, info));
  assert.throws(() => assertPublishedRelease({ ...release, tagName: 'desktop-v0.1.0' }, info));
  assert.throws(() => assertPublishedRelease(release, { ...info, platform: 'mobile' }));
});

test('拒绝旧 APK、dev 包和不对应源码的安装包', () => {
  const info = { appId: 'com.ling.diary', version: '1.0.2', build: 3 };
  assertApkMetadata("package: name='com.ling.diary' versionCode='3' versionName='1.0.2'", info);
  for (const output of ["package: name='com.ling.diary.dev' versionCode='3' versionName='1.0.2'", "package: name='com.ling.diary' versionCode='2' versionName='1.0.2'", "package: name='com.ling.diary' versionCode='3' versionName='1.0.1'", '']) {
    assert.throws(() => assertApkMetadata(output, info));
  }
  assertDesktopMetadata('0.1.1.0', { version: '0.1.1' });
  assert.throws(() => assertDesktopMetadata('0.1.0', { version: '0.1.1' }));
});

test('提交之前的构建和空安装包不能进入发布目录', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'diary-release-test-'));
  t.after(() => removeTestDirectory(root));
  const path = join(root, 'app.apk');
  writeFileSync(path, 'apk');
  utimesSync(path, 100, 100);
  assert.throws(() => assertFreshArtifact(path, 200000));
  assertFreshArtifact(path, 100000);
  writeFileSync(path, '');
  assert.throws(() => assertFreshArtifact(path, 0));
});

test('完整更新清单保留两端且使用精确下载地址，应用身份变更停止', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'diary-release-test-'));
  t.after(() => removeTestDirectory(root));
  for (const name of ['mobile', 'desktop', 'releases']) mkdirSync(join(root, name));
  writeFileSync(join(root, 'mobile/pubspec.yaml'), 'version: 1.0.2+3\n');
  const pkg = { name: 'diary-desktop', version: '0.1.1', build: { appId: 'com.ling.diary.desktop', productName: 'Diary' } };
  writeFileSync(join(root, 'desktop/package.json'), JSON.stringify(pkg));
  writeFileSync(join(root, 'releases/mobile-v1.0.2.md'), '# Android\n- 修复动画\n');
  writeFileSync(join(root, 'releases/desktop-v0.1.1.md'), '# Windows\n- 公开预览\n');
  const { platforms } = updateManifest(root);
  assert.equal(platforms.mobile.version, '1.0.2');
  assert.equal(platforms.desktop.version, '0.1.1');
  assert.equal(platforms.mobile.downloadUrl, 'https://github.com/zhongshuyi/diary/releases/download/mobile-v1.0.2/diary-android-1.0.2-build3.apk');
  assert.equal(platforms.desktop.downloadUrl, 'https://github.com/zhongshuyi/diary/releases/download/desktop-v0.1.1/diary-desktop-0.1.1-win-x64-setup.exe');
  pkg.name = 'renamed-diary';
  writeFileSync(join(root, 'desktop/package.json'), JSON.stringify(pkg));
  assert.throws(() => releaseInfo('desktop', root));
});
