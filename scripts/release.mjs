import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync, copyFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const REPO = 'https://github.com/zhongshuyi/diary';
const VERSION = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

export function parseVersion(value) {
  const match = VERSION.exec(value);
  if (!match || match.slice(1).some((part) => !Number.isSafeInteger(Number(part)))) {
    throw new Error(`必须使用 major.minor.patch 版本号：${value}`);
  }
  return match.slice(1).map(Number);
}

export function assertVersionIncrease(current, next) {
  const before = parseVersion(current);
  const after = parseVersion(next);
  const difference = after.findIndex((part, index) => part !== before[index]);
  if (difference < 0 || after[difference] < before[difference]) {
    throw new Error(`新版本必须高于 ${current}`);
  }
}

export function parseMobileVersion(source) {
  const match = /^version:\s*(\S+)\s*$/m.exec(source);
  if (!match) throw new Error('pubspec.yaml 缺少 version');
  const parts = match[1].split('+');
  if (parts.length !== 2) throw new Error('Android 版本必须包含 build number');
  parseVersion(parts[0]);
  const build = Number(parts[1]);
  if (!/^[1-9]\d*$/.test(parts[1]) || !Number.isSafeInteger(build) || build > 2100000000) {
    throw new Error('Android build number 必须为 1 至 2100000000 的整数');
  }
  return { version: parts[0], build };
}

export function releaseInfo(platform, root = ROOT) {
  let info;
  if (platform === 'mobile') {
    info = { ...parseMobileVersion(readFileSync(join(root, 'mobile/pubspec.yaml'), 'utf8')), appId: 'com.ling.diary' };
  } else if (platform === 'desktop') {
    const pkg = JSON.parse(readFileSync(join(root, 'desktop/package.json'), 'utf8'));
    parseVersion(pkg.version);
    if (pkg.name !== 'diary-desktop' || pkg.build?.appId !== 'com.ling.diary.desktop' || pkg.build?.productName !== 'Diary') {
      throw new Error('桌面应用身份已变化，发布前必须确认升级与数据迁移方案');
    }
    info = { version: pkg.version, appId: pkg.build.appId, architecture: 'x64' };
  } else {
    throw new Error(`未知平台：${platform}`);
  }
  const tag = `${platform}-v${info.version}`;
  const fileName = platform === 'mobile'
    ? `diary-android-${info.version}-build${info.build}.apk`
    : `diary-desktop-${info.version}-win-x64-setup.exe`;
  return { platform, ...info, tag, fileName, downloadUrl: `${REPO}/releases/download/${tag}/${fileName}` };
}

export function assertTag(info, tag) {
  if (tag !== info.tag) throw new Error(`tag ${tag} 与源码版本不一致，应为 ${info.tag}`);
}

export function assertSourceCommit(tagCommit, sourceCommit) {
  if (!/^[a-f0-9]{40}$/.test(tagCommit) || tagCommit !== sourceCommit) {
    throw new Error('发布 tag 与构建源码提交不一致；不要移动已有发布 tag，请递增版本');
  }
}

export function assertPublishedRelease(release, info) {
  if (release.tagName !== info.tag || release.isDraft !== false || (info.platform === 'mobile' && release.isPrerelease !== false)) {
    throw new Error(`${info.tag} 尚未公开发布到对应渠道`);
  }
  const asset = release.assets?.find((item) => item.name === info.fileName);
  if (!asset || asset.state !== 'uploaded' || asset.size <= 0 || asset.url !== info.downloadUrl) {
    throw new Error(`${info.tag} 缺少可下载的对应安装包`);
  }
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { cwd: ROOT, encoding: 'utf8', windowsHide: true, ...options });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${command} 执行失败：${result.stderr || result.stdout}`);
  return result.stdout.trim();
}

function check(platform, tag, root = ROOT) {
  const info = releaseInfo(platform, root);
  if (tag) assertTag(info, tag);
  if (!existsSync(join(root, `releases/${info.tag}.md`))) throw new Error(`缺少发布说明 releases/${info.tag}.md`);
  return info;
}

export function assertFreshArtifact(path, commitTimeMs) {
  const stats = statSync(path);
  if (!stats.isFile() || stats.size === 0) throw new Error('安装包不存在或为空');
  if (stats.mtimeMs + 1000 < commitTimeMs) throw new Error('安装包早于源码提交，请重新构建');
}

export function assertApkMetadata(badging, info) {
  const match = /^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'/m.exec(badging);
  if (!match || match[1] !== info.appId || match[2] !== String(info.build) || match[3] !== info.version) {
    throw new Error('APK 包名、versionCode 或 versionName 与源码不一致');
  }
}

export function assertDesktopMetadata(productVersion, info) {
  if (productVersion !== info.version && productVersion !== `${info.version}.0`) {
    throw new Error(`安装器版本 ${productVersion} 与源码 ${info.version} 不一致`);
  }
}

function androidTools() {
  const sdk = process.env.ANDROID_SDK_ROOT || process.env.ANDROID_HOME
    || (process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'Android/Sdk'));
  if (!sdk || !existsSync(join(sdk, 'build-tools'))) throw new Error('找不到 Android SDK，请设置 ANDROID_SDK_ROOT');
  const versions = readdirSync(join(sdk, 'build-tools'))
    .filter((value) => VERSION.test(value)).sort((a, b) => {
      const aa = parseVersion(a), bb = parseVersion(b);
      return bb[0] - aa[0] || bb[1] - aa[1] || bb[2] - aa[2];
    });
  const directory = versions.map((version) => join(sdk, 'build-tools', version))
    .find((path) => existsSync(join(path, 'lib/apksigner.jar')) && existsSync(join(path, process.platform === 'win32' ? 'aapt2.exe' : 'aapt2')));
  if (!directory) throw new Error('Android build-tools 缺少 aapt2 或 apksigner');
  return { aapt: join(directory, process.platform === 'win32' ? 'aapt2.exe' : 'aapt2'), signer: join(directory, 'lib/apksigner.jar') };
}

function prepare(platform) {
  const info = check(platform);
  if (run('git', ['status', '--porcelain'])) throw new Error('工作区有未提交修改，先固定发布源码');
  const sourceCommit = run('git', ['rev-parse', 'HEAD']);
  const tagCommit = run('git', ['rev-parse', '--verify', `refs/tags/${info.tag}^{commit}`]);
  assertSourceCommit(tagCommit, sourceCommit);
  const commitTimeMs = Number(run('git', ['show', '-s', '--format=%ct', 'HEAD'])) * 1000;
  const source = platform === 'mobile'
    ? join(ROOT, 'mobile/build/app/outputs/flutter-apk/app-release.apk')
    : join(ROOT, 'desktop/release', info.fileName);
  assertFreshArtifact(source, commitTimeMs);
  let signature = {};
  if (platform === 'mobile') {
    const tools = androidTools();
    assertApkMetadata(run(tools.aapt, ['dump', 'badging', source]), info);
    const certs = run('java', ['-jar', tools.signer, 'verify', '--print-certs', source]);
    const hashes = [...certs.matchAll(/Signer #\d+ certificate SHA-256 digest: ([a-fA-F0-9]{64})/g)].map((match) => match[1].toLowerCase());
    if (!hashes.length) throw new Error('APK 缺少可验证的签名证书');
    signature = { signingCertificateSha256: hashes };
  } else {
    if (process.platform !== 'win32') throw new Error('Windows 安装器必须在 Windows 上验证');
    const version = run('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', '(Get-Item -LiteralPath $env:DIARY_RELEASE_ARTIFACT).VersionInfo.ProductVersion'], { env: { ...process.env, DIARY_RELEASE_ARTIFACT: source } });
    assertDesktopMetadata(version, info);
  }
  const directory = join(ROOT, 'artifacts/releases', info.tag);
  if (existsSync(directory)) throw new Error(`发布目录已存在：${directory}，请先核验现有产物，不覆盖`);
  mkdirSync(directory, { recursive: true });
  const target = join(directory, info.fileName);
  copyFileSync(source, target);
  const sha256 = createHash('sha256').update(readFileSync(target)).digest('hex');
  const metadata = { ...info, sourceCommit, sha256, size: statSync(target).size, ...signature };
  writeFileSync(join(directory, 'SHA256SUMS'), `${sha256}  ${info.fileName}\n`);
  writeFileSync(join(directory, 'release.json'), `${JSON.stringify(metadata, null, 2)}\n`);
  console.log(JSON.stringify(metadata, null, 2));
}

function bump(platform, version, build) {
  const current = releaseInfo(platform);
  assertVersionIncrease(current.version, version);
  if (platform === 'mobile') {
    const next = parseMobileVersion(`version: ${version}+${build}`);
    if (next.build <= current.build) throw new Error(`Android build number 必须高于 ${current.build}`);
    const path = join(ROOT, 'mobile/pubspec.yaml');
    writeFileSync(path, readFileSync(path, 'utf8').replace(/^version:.*$/m, `version: ${version}+${next.build}`));
  } else {
    const path = join(ROOT, 'desktop/package.json');
    const pkg = JSON.parse(readFileSync(path, 'utf8'));
    pkg.version = version;
    writeFileSync(path, `${JSON.stringify(pkg, null, 2)}\n`);
  }
  console.log(`已递增 ${platform}，请同步更新 CHANGELOG 和 releases/<tag>.md`);
}

export function updateManifest(root = ROOT) {
  const platforms = {};
  for (const platform of ['mobile', 'desktop']) {
    const info = check(platform, undefined, root);
    const notes = readFileSync(join(root, `releases/${info.tag}.md`), 'utf8')
      .split(/\r?\n/).filter((line) => line.startsWith('- ')).map((line) => line.slice(2)).join('\n');
    platforms[platform] = { version: info.version, downloadUrl: info.downloadUrl, notes };
  }
  return { platforms };
}

function verifyPublishedPlatforms() {
  const windowsGh = process.env.ProgramFiles && join(process.env.ProgramFiles, 'GitHub CLI/gh.exe');
  const gh = process.platform === 'win32' && windowsGh && existsSync(windowsGh) ? windowsGh : 'gh';
  for (const platform of ['mobile', 'desktop']) {
    const info = releaseInfo(platform);
    const release = JSON.parse(run(gh, ['release', 'view', info.tag, '--repo', 'zhongshuyi/diary', '--json', 'tagName,isDraft,isPrerelease,assets']));
    assertPublishedRelease(release, info);
  }
}

export function main(args) {
  const [command, platform, value, build] = args;
  if (command === 'versions' && args.length === 1) {
    console.log(JSON.stringify(['mobile', 'desktop'].map((p) => releaseInfo(p)), null, 2));
  } else if (command === 'check' && (args.length === 2 || args.length === 3)) {
    if (platform === 'all') {
      if (value) throw new Error('check all 不接受 tag');
      ['mobile', 'desktop'].forEach((p) => check(p));
    } else check(platform, value);
    console.log('版本与发布说明检查通过');
  } else if (command === 'bump' && ((platform === 'mobile' && args.length === 4) || (platform === 'desktop' && args.length === 3))) {
    bump(platform, value, build);
  } else if (command === 'prepare' && args.length === 2) {
    prepare(platform);
  } else if (command === 'manifest') {
    let outputPath = 'artifacts/update-manifest.json';
    let offline = false;
    for (let index = 1; index < args.length; index++) {
      if (args[index] === '--offline' && !offline) offline = true;
      else if (args[index] === '--output' && args[index + 1] && !args[index + 1].startsWith('--')) outputPath = args[++index];
      else throw new Error('manifest 只接受 --output <file> 和 --offline');
    }
    if (!offline) verifyPublishedPlatforms();
    const output = resolve(ROOT, outputPath);
    const manifest = updateManifest();
    mkdirSync(dirname(output), { recursive: true });
    writeFileSync(output, `${JSON.stringify(manifest, null, 2)}\n`);
    console.log(`${offline ? '离线草稿（尚未校验公开安装包）' : '公开安装包校验通过，更新清单已生成'}：${output}`);
  } else {
    throw new Error('用法：versions | check all | check <mobile|desktop> [tag] | bump mobile <version> <build> | bump desktop <version> | prepare <mobile|desktop> | manifest [--output <file>] [--offline]');
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); } catch (error) { console.error(error.message); process.exitCode = 1; }
}
