import test from 'node:test';
import assert from 'node:assert/strict';
import {
  checkTrackedPaths,
  checkWorkflowActions,
  checkMetadata,
} from './check-repository.mjs';

const workflowPath = '.github/workflows/check.yml';
const commit = '0123456789abcdef0123456789abcdef01234567';
const digest = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const requiredFiles = ['LICENSE', 'PRIVACY.md', 'THIRD_PARTY_NOTICES.md'];
const mitPackages = {
  'desktop/package.json': { license: 'MIT' },
  'server/package.json': { license: 'MIT' },
};

function assertReported(violations, context) {
  assert.ok(violations.length > 0, `应拒绝 ${context}`);
  for (const violation of violations) {
    assert.equal(typeof violation.path, 'string', context);
    assert.ok(violation.path.length > 0, context);
    assert.equal(typeof violation.rule, 'string', context);
    assert.ok(violation.rule.length > 0, context);
  }
}

test('个人工作目录和依赖缓存在任意层级均不能提交', () => {
  for (const path of [
    '.local/audit/report.json',
    'docs/.local/report.json',
    'docs/.LOCAL/report.json',
    'node_modules/package/index.js',
    'desktop/node_modules/package/index.js',
    'desktop/NODE_MODULES/package/index.js',
    '.dart_tool/package_config.json',
    'mobile/.dart_tool/package_config.json',
    'mobile/.DART_TOOL/package_config.json',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
});

test('两端构建目录和服务端数据仅允许指定的直接占位文件', () => {
  for (const path of [
    'mobile/build/generated/source.dart',
    'Mobile/Build/generated/source.dart',
    'desktop/dist/assets/index.js',
    'desktop/release/latest.yml',
    'desktop/release-final/latest.yml',
    'server/data/state.json',
    'server/data/assets/metadata.json',
    'server/data/nested/.gitkeep',
    'server/data/.gitkeep.backup',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
  assert.deepEqual(checkTrackedPaths(['server/data/.gitkeep']), []);
});

test('签名文件、真实环境配置及其大小写变体均不能提交', () => {
  for (const path of [
    'key.properties',
    'mobile/android/key.properties',
    'mobile/android/KEY.PROPERTIES',
    'private/release.jks',
    'private/release.JKS',
    'private/release.keystore',
    'private/client.p12',
    'private/client.pfx',
    '.env',
    'server/.env.production',
    'server/.ENV.local',
    'server/.env.example.local',
    'server/.env.examples',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
});

test('环境配置模板合法，但模板名称不能豁免禁止目录', () => {
  assert.deepEqual(checkTrackedPaths([
    '.env.example',
    'server/.env.example',
    'desktop/.ENV.EXAMPLE',
    'docs/env.example.md',
  ]), []);
  for (const path of ['.local/.env.example', 'node_modules/.env.example', 'server/data/.env.example']) {
    assertReported(checkTrackedPaths([path]), path);
  }
});

test('数据库及 WAL、SHM sidecar 不能进入源码历史', () => {
  for (const path of [
    'desktop/diary.db',
    'desktop/diary.db-wal',
    'desktop/diary.db-shm',
    'fixtures/backup.sqlite',
    'fixtures/backup.sqlite-wal',
    'fixtures/backup.sqlite-shm',
    'fixtures/backup.sqlite3',
    'fixtures/backup.sqlite3-wal',
    'fixtures/backup.sqlite3-shm',
    'mobile/diary.isar',
    'mobile/diary.isar-wal',
    'mobile/diary.isar-shm',
    'fixtures/DIARY.DB-WAL',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
});

test('安装包和打包后的应用不能进入源码历史', () => {
  for (const path of [
    'artifacts/app.apk',
    'artifacts/app.aab',
    'artifacts/setup.exe',
    'artifacts/setup.msi',
    'artifacts/application.dmg',
    'artifacts/app.asar',
    'artifacts/APP.APK',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
});

test('Windows 分隔符与普通分隔符具有相同的规则结果', () => {
  for (const path of [
    'mobile\\build\\generated\\source.dart',
    'desktop\\dist\\assets\\index.js',
    'server\\data\\state.json',
    'mobile\\android\\key.properties',
    'docs\\.local\\report.json',
    'desktop/node_modules\\package/index.js',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
  assert.deepEqual(checkTrackedPaths(['docs\\guide.md', 'server\\data\\.gitkeep']), []);
});

test('绝对路径、盘符、路径穿越和 NUL 路径均无效', () => {
  for (const path of [
    '/tmp/README.md',
    'C:/repo/README.md',
    'C:\\repo\\README.md',
    'C:README.md',
    '\\\\server\\share\\README.md',
    '../README.md',
    'docs/../../README.md',
    'docs/../README.md',
    'docs\\..\\README.md',
    'docs/guide\u0000.md',
  ]) {
    assertReported(checkTrackedPaths([path]), path);
  }
});

test('源码、构建配置和合法二进制依赖不会因名称相似而误报', () => {
  assert.deepEqual(checkTrackedPaths([
    'mobile/windows/CMakeLists.txt',
    'mobile/linux/CMakeLists.txt',
    'mobile/android/gradle/wrapper/gradle-wrapper.jar',
    'mobile/android/build.gradle.kts',
    'docs/build/guide.md',
    'packages/mobile/build/config.json',
    'docs/dist/architecture.md',
    'docs/release/checklist.md',
    'docs/release-final/checklist.md',
    'fixtures/sample.zip',
    'vendor/library.so',
    'vendor/library.dll',
    'src/database.ts',
    'src/sqlite_adapter.dart',
    'docs/node_modules-guide.md',
    'docs/.local-guide.md',
    'server/data-schema.json',
  ]), []);
});

test('混合路径清单只报告实际禁止的项目', () => {
  const violations = checkTrackedPaths([
    'README.md',
    'server/.env.example',
    'mobile/android/key.properties',
    'mobile/windows/CMakeLists.txt',
    'server/data/state.json',
  ]);
  assertReported(violations, '混合路径清单');
  assert.deepEqual(new Set(violations.map(({ path }) => path)), new Set([
    'mobile/android/key.properties',
    'server/data/state.json',
  ]));
});

test('远程 action 和可复用工作流接受完整提交 ID、引号和行末注释', () => {
  const source = [
    'name: Repository checks',
    'jobs:',
    '  check:',
    '    steps:',
    `      - uses: actions/checkout@${commit}`,
    `      - uses: 'actions/setup-node@${commit}' # fixed revision`,
    `      - uses: "owner/repo/sub-action@${commit.toUpperCase()}"`,
    '  reusable:',
    `    uses: owner/repo/.github/workflows/build.yml@${commit} # fixed revision`,
  ].join('\n');
  assert.deepEqual(checkWorkflowActions(workflowPath, source), []);
});

test('工作流接受仓库内 action 和固定 SHA-256 的 Docker image', () => {
  const source = [
    'jobs:',
    '  check:',
    '    steps:',
    '      - uses: ./.github/actions/setup',
    '      - uses: "./actions/check" # local action',
    `      - uses: docker://ghcr.io/owner/image@sha256:${digest}`,
    '  reusable:',
    '    uses: ./.github/workflows/build.yml',
  ].join('\n');
  assert.deepEqual(checkWorkflowActions(workflowPath, source), []);
});

test('远程 action 拒绝 tag、branch、短提交和无效完整提交', () => {
  for (const reference of [
    'actions/checkout@v4',
    'actions/checkout@main',
    'actions/checkout@0123456',
    `actions/checkout@${commit.slice(0, -1)}`,
    `actions/checkout@${commit}0`,
    `actions/checkout@${commit.slice(0, -1)}g`,
    'owner/repo/sub-action@v1',
    'owner/repo/.github/workflows/build.yml@main',
    'actions/checkout',
    'actions/checkout@${{ inputs.revision }}',
  ]) {
    const violations = checkWorkflowActions(workflowPath, `steps:\n  - uses: ${reference}\n`);
    assertReported(violations, reference);
    for (const violation of violations) {
      assert.equal(violation.path, workflowPath, reference);
      assert.equal(violation.line, 2, reference);
    }
  }
});

test('本地 action 路径不能借由父目录跳出仓库', () => {
  for (const reference of ['./../actions/setup', './actions/../../setup', './actions/../setup']) {
    const violations = checkWorkflowActions(workflowPath, `steps:\n  - uses: '${reference}'\n`);
    assertReported(violations, reference);
    assert.ok(violations.every(({ line }) => line === 2), reference);
  }
});

test('Docker action 只能使用完整 SHA-256 digest', () => {
  for (const reference of [
    'docker://alpine:latest',
    'docker://alpine:3.20',
    'docker://alpine',
    `docker://alpine@sha256:${digest.slice(0, -1)}`,
    `docker://alpine@sha256:${digest}0`,
    `docker://alpine@sha256:${digest.slice(0, -1)}g`,
    `docker://alpine@sha512:${digest}`,
  ]) {
    assertReported(checkWorkflowActions(workflowPath, `steps:\n  - uses: ${reference}\n`), reference);
  }
});

test('注释和普通 run 内容不被当作 action，错误行号包含空行', () => {
  const source = [
    '# uses: actions/checkout@v4',
    '',
    'steps:',
    '  - run: echo "uses: actions/checkout@v4"',
    `  - uses: actions/checkout@${commit} # uses: owner/repo@main`,
    '',
    '  - uses: "actions/setup-node@v4" # must pin',
  ].join('\r\n');
  const violations = checkWorkflowActions(workflowPath, source);
  assert.equal(violations.length, 1);
  assert.equal(violations[0].path, workflowPath);
  assert.equal(violations[0].line, 7);
  assertReported(violations, '未固定的 action');
});

test('仓库必需法律文件与两端 MIT 元数据齐全时通过', () => {
  assert.deepEqual(checkMetadata({ files: requiredFiles, packages: mitPackages }), []);
});

test('每份缺失的法律文件分别报告其路径', () => {
  for (const missing of requiredFiles) {
    const violations = checkMetadata({
      files: requiredFiles.filter((path) => path !== missing),
      packages: mitPackages,
    });
    assertReported(violations, missing);
    assert.deepEqual(new Set(violations.map(({ path }) => path)), new Set([missing]));
  }
});

test('仅在子目录存在的同名法律文件不满足根目录要求', () => {
  const violations = checkMetadata({
    files: ['docs/LICENSE', 'docs/PRIVACY.md', 'docs/THIRD_PARTY_NOTICES.md'],
    packages: mitPackages,
  });
  assertReported(violations, '根目录法律文件');
  assert.deepEqual(new Set(violations.map(({ path }) => path)), new Set(requiredFiles));
});

test('两端 package 缺失或许可证不是 MIT 时分别报告', () => {
  for (const path of Object.keys(mitPackages)) {
    const absent = { ...mitPackages };
    delete absent[path];
    const absentViolations = checkMetadata({ files: requiredFiles, packages: absent });
    assertReported(absentViolations, path);
    assert.deepEqual(new Set(absentViolations.map((violation) => violation.path)), new Set([path]));

    for (const license of [undefined, '', 'UNLICENSED', 'Apache-2.0', '(MIT OR Apache-2.0)']) {
      const violations = checkMetadata({
        files: requiredFiles,
        packages: { ...mitPackages, [path]: { license } },
      });
      assertReported(violations, `${path}: ${String(license)}`);
      assert.deepEqual(new Set(violations.map((violation) => violation.path)), new Set([path]));
    }
  }
});
