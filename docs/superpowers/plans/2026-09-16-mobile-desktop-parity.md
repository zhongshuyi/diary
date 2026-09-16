# APP 与桌面端功能对齐 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Flutter APP 在数据、速记、检索、分类标签、媒体、回收站、备份和同步语义上达到桌面端基线，同时保留移动端导航和单手交互。

**Architecture:** 两端继续使用各自的本地存储（APP 使用 Isar，桌面端使用 SQLite），通过版本化的 Sync API v2、outbox、cursor、冲突副本和附件 SHA 建立同一资料库语义。服务端先维持 JSON 文件存储并增加 change log 与资产目录；客户端在本地事务中保存正文、队列和状态，网络只负责最终收敛。

**Tech Stack:** Flutter/Dart 3.11、Isar Community、`http`、`crypto`、`archive`、Electron 40、React 19、Node.js ESM、SQLite、Node test runner。

**Spec:** `docs/superpowers/specs/2026-09-16-mobile-desktop-sync-design.md`

## 实施状态（2026-09-16）

- 已完成：Sync v2 协议、服务端增量游标/幂等/冲突副本、附件 API、桌面端冲突中心与 SQLite 持久化。
- 已完成：APP Isar/SharedPreferences 数据模型、outbox、草稿、批量操作、同步引擎、附件本地存储、ZIP 备份、同步设置与冲突入口。
- 已完成：APP 与桌面共用的字段语义、删除/恢复、按频率与最近使用排序的平铺分类/标签筛选。
- 待增强：附件后台上传队列的断点续传、系统通知提醒、跨平台真机回归与发布签名。

## Global Constraints

- APP 与桌面端共用同一个同步资料库，但不共享本地数据库实现。
- 两端离线可写；启动、回到前台立即同步，前台定时同步间隔为 30–60 秒。
- 不采用端到端加密；服务器可以读取明文；生产请求必须使用 HTTPS 和 Bearer Token。
- 冲突必须保留双方内容，冲突副本使用 `conflict:<entryId>:<mutationId>`，默认不进入普通时间线和搜索。
- 附件单文件上限为 128 MB；以 SHA-256 去重；上传和下载均使用临时文件校验后原子移动。
- 分类和标签必须平铺单击选择，按使用频率降序、最近使用时间降序、中文名称升序排列。
- 备份格式统一为 `.diary.zip`，导入默认按稳定 ID 合并，不覆盖本地较新记录，并支持暂存和失败回滚。
- 每个任务都先写失败测试，再实现最小行为，最后运行任务级测试并单独提交。

## 文件责任映射

- `mobile/lib/domain/diary_entry.dart`：跨端记录字段、版本化 JSON 和兼容读取。
- `mobile/lib/domain/diary_query.dart`：全部记录的分页、组合筛选和排序值对象。
- `mobile/lib/domain/attachment.dart`、`outbox_mutation.dart`、`sync_state.dart`、`conflict.dart`：同步相关领域实体。
- `mobile/lib/data/isar_*`：Isar collections、迁移和事务实现；`diary_repository.dart` 暴露平台无关接口。
- `mobile/lib/sync/`：HTTP v2 客户端、同步编排、退避和附件队列。
- `mobile/lib/pages/`、`mobile/lib/widgets/`：移动端交互；只消费 controller/repository 的统一语义。
- `server/src/protocol-v2.mjs`：请求/响应及附件元数据校验。
- `server/src/store.mjs`、`server/src/asset-store.mjs`：服务端 change log、幂等、冲突副本和资产原子写入。
- `desktop/src/main/database/`、`desktop/src/main.cjs`：桌面端 v2 IPC、SQLite 应用和资产上传下载。
- `desktop/src/renderer/`：桌面端冲突中心、同步状态和与 APP 相同的筛选语义。

---

### Task 1: 固化 Sync v2 协议和跨端 fixtures

**Files:**
- Create: `server/src/protocol-v2.mjs`
- Create: `server/test/protocol-v2.test.mjs`
- Create: `server/test/fixtures/parity-fixture.json`
- Modify: `docs/sync-contract.md`

**Interfaces:**
- Produces `normalizeV2Request(body) -> { deviceId, cursor, limit, mutations }`。
- Produces `normalizeEntryV2(value) -> entry`，补齐 `occurredAt`、`deletedAt`、`revision`、`deviceId`、`isConflict` 和 `attachmentIds`。
- Produces `validateAssetMetadata(value) -> { valid, details }`。
- Fixture 至少包含一条普通记录、一条回收站记录、一条多标签记录、一条冲突副本和两个共享同一 SHA 的附件引用。

- [ ] **Step 1: 写协议失败测试**

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeV2Request, normalizeEntryV2 } from '../src/protocol-v2.mjs';

test('v2 request normalizes cursor and mutation entry', () => {
  const result = normalizeV2Request({
    protocolVersion: 2,
    deviceId: 'phone-a',
    cursor: '7',
    changes: [{ mutationId: 'm-1', entry: { id: 'e-1', createdAt: '2026-09-16T08:00:00.000Z', updatedAt: '2026-09-16T08:01:00.000Z', title: '一句话', content: '正文' } }],
  });
  assert.equal(result.cursor, '7');
  assert.equal(result.mutations[0].entry.occurredAt, '2026-09-16T08:00:00.000Z');
  assert.equal(result.mutations[0].entry.revision, 1);
});

test('v2 entry preserves conflict and attachment fields', () => {
  const entry = normalizeEntryV2({ id: 'conflict:e-1:m-2', isConflict: true, conflictOf: 'e-1', attachmentIds: ['asset-a'] });
  assert.equal(entry.isConflict, true);
  assert.equal(entry.conflictOf, 'e-1');
  assert.deepEqual(entry.attachmentIds, ['asset-a']);
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `node --test server/test/protocol-v2.test.mjs`
Expected: FAIL because `protocol-v2.mjs` and its exports do not exist.

- [ ] **Step 3: 实现规范化和校验**

```js
export function normalizeEntryV2(value = {}) {
  const entry = { ...value };
  const createdAt = String(entry.createdAt || entry.occurredAt || new Date().toISOString());
  return {
    schemaVersion: 2,
    id: String(entry.id || ''),
    createdAt,
    occurredAt: String(entry.occurredAt || createdAt),
    updatedAt: String(entry.updatedAt || createdAt),
    deletedAt: entry.deletedAt == null ? null : String(entry.deletedAt),
    title: String(entry.title || ''),
    content: String(entry.content || ''),
    contentText: String(entry.contentText ?? entry.content ?? ''),
    editorType: ['plain_text', 'markdown', 'rich_text'].includes(entry.editorType) ? entry.editorType : 'plain_text',
    mood: entry.mood == null ? null : Math.min(1, Math.max(0, Number(entry.mood))),
    category: String(entry.category || '生活'),
    tags: Array.isArray(entry.tags) ? [...new Set(entry.tags.filter((item) => typeof item === 'string').map((item) => item.trim()).filter(Boolean))] : [],
    attachmentIds: Array.isArray(entry.attachmentIds) ? [...new Set(entry.attachmentIds.filter((item) => typeof item === 'string' && item.trim()))] : [],
    imagePaths: Array.isArray(entry.imagePaths) ? entry.imagePaths : [],
    audioPaths: Array.isArray(entry.audioPaths) ? entry.audioPaths : [],
    videoPaths: Array.isArray(entry.videoPaths) ? entry.videoPaths : [],
    weather: Array.isArray(entry.weather) ? entry.weather : [],
    positions: Array.isArray(entry.positions) ? entry.positions : [],
    latitude: entry.latitude == null ? null : Number(entry.latitude),
    longitude: entry.longitude == null ? null : Number(entry.longitude),
    colorValue: Number(entry.colorValue ?? 0xffe4e0ed),
    isFavorite: entry.isFavorite === true,
    revision: Math.max(1, Number(entry.revision) || 1),
    deviceId: String(entry.deviceId || ''),
    isConflict: entry.isConflict === true,
    conflictOf: entry.conflictOf == null ? null : String(entry.conflictOf),
    conflictStatus: entry.conflictStatus === 'resolved' ? 'resolved' : 'pending',
  };
}

export function normalizeV2Request(body = {}) {
  if (body.protocolVersion !== 2) throw new Error('protocolVersion must be 2');
  if (typeof body.deviceId !== 'string' || body.deviceId.trim().length < 3) throw new Error('deviceId is required');
  const changes = Array.isArray(body.changes) ? body.changes : [];
  if (changes.length > 100) throw new Error('at most 100 changes are allowed');
  return { deviceId: body.deviceId.trim(), cursor: String(body.cursor ?? '0'), limit: Math.min(200, Math.max(1, Number(body.limit) || 100)), mutations: changes.map((change) => ({ mutationId: String(change.mutationId), entry: normalizeEntryV2(change.entry) })) };
}

export function validateAssetMetadata(value = {}) {
  const details = [];
  if (!/^[a-f0-9]{64}$/.test(String(value.sha256 || '').toLowerCase())) details.push('sha256');
  if (!['image', 'video', 'audio', 'file'].includes(value.kind)) details.push('kind');
  if (!Number.isSafeInteger(value.byteSize) || value.byteSize < 0 || value.byteSize > 128 * 1024 * 1024) details.push('byteSize');
  return { valid: details.length === 0, details };
}
```

- [ ] **Step 4: 写 fixture 和 v2 合同文档**

在 `parity-fixture.json` 中固定 ISO 时间、ID、标签顺序和 SHA；在 `docs/sync-contract.md` 写出请求字段、响应字段、cursor 推进条件、冲突事件结构和资产接口，并明确 v1 只作兼容入口。

- [ ] **Step 5: 运行测试并提交**

Run: `node --test server/test/protocol-v2.test.mjs`
Expected: PASS.

```bash
git add server/src/protocol-v2.mjs server/test/protocol-v2.test.mjs server/test/fixtures/parity-fixture.json docs/sync-contract.md
git commit -m "feat: define sync protocol v2"
```

### Task 2: 服务端 v2 change log、冲突副本和附件 API

**Files:**
- Create: `server/src/asset-store.mjs`
- Modify: `server/src/store.mjs`
- Modify: `server/src/server.mjs`
- Create: `server/test/sync-v2.test.mjs`
- Create: `server/test/assets.test.mjs`

**Interfaces:**
- `SyncStore.applyV2({ deviceId, cursor, limit, mutations }) -> { nextCursor, changes, appliedMutationIds, conflicts }`。
- `AssetStore.head(sha256) -> { exists, byteSize, mimeType }`。
- `AssetStore.put({ sha256, mimeType, byteSize, body }) -> descriptor`。
- `AssetStore.open(sha256) -> { stream, byteSize, mimeType }`。

- [ ] **Step 1: 写失败测试覆盖幂等、分页和冲突副本**

测试步骤固定为：先写入 `e-1/m-1`，再提交时间更早的 `e-1/m-2`，断言响应包含 `conflict:e-1:m-2`；重复提交 `m-2` 不增加第二个冲突；`cursor=0, limit=1` 只返回一条 change，下一次 cursor 返回剩余 change。

- [ ] **Step 2: 写失败测试覆盖资产安全**

使用临时目录验证：`PUT` 成功后 `HEAD` 为存在；错误 SHA、超过 128 MB、路径穿越文件名返回 422；写入中断不会留下正式 SHA 文件；`GET` 返回正确字节和 MIME。

- [ ] **Step 3: 扩展 `SyncStore` 状态和 applyV2**

将状态版本升级为 2，给每个 mutation 保存 `accepted`、`sequence` 和 `conflictId`。拒绝旧版本时仍写入冲突副本和 change log，并用 `conflict:<entryId>:<mutationId>` 做幂等键。`nextCursor` 只能取实际返回页的最后 sequence 或当前 sequence，客户端提交事务成功前不得被客户端使用。

- [ ] **Step 4: 实现 `AssetStore` 原子写入**

在 `data/assets` 下创建临时文件，流式计数和 SHA 校验通过后 `rename` 为 `<sha256>`；`head` 只读取受管目录内的目标；`open` 对不存在文件返回 `ENOENT`，不接受用户传入路径。

- [ ] **Step 5: 增加 HTTP 路由和错误映射**

增加 `POST /api/v2/sync`、`HEAD /api/v2/assets/:sha256`、`PUT /api/v2/assets/:sha256`、`GET /api/v2/assets/:sha256`。所有 v2 路由复用 Bearer Token；JSON 请求限制 2 MB，资产流限制 128 MB；响应 `meta.protocolVersion` 为 2。保留 `/api/v1/sync` 不变。

- [ ] **Step 6: 运行服务端全量测试并提交**

Run: `npm test --prefix server`
Expected: existing v1 tests and new v2/asset tests all PASS.

```bash
git add server/src/asset-store.mjs server/src/store.mjs server/src/server.mjs server/test/sync-v2.test.mjs server/test/assets.test.mjs
git commit -m "feat: add sync v2 conflicts and asset api"
```

### Task 3: APP 领域模型、Isar collections 和迁移

**Files:**
- Modify: `mobile/lib/domain/diary_entry.dart`
- Create: `mobile/lib/domain/diary_query.dart`
- Create: `mobile/lib/domain/attachment.dart`
- Create: `mobile/lib/domain/outbox_mutation.dart`
- Create: `mobile/lib/domain/sync_state.dart`
- Create: `mobile/lib/domain/conflict.dart`
- Modify: `mobile/lib/data/isar_diary_record.dart`
- Create: `mobile/lib/data/isar_attachment_record.dart`
- Create: `mobile/lib/data/isar_outbox_record.dart`
- Create: `mobile/lib/data/isar_sync_state_record.dart`
- Create: `mobile/lib/data/isar_conflict_record.dart`
- Regenerate: `mobile/lib/data/isar_diary_record.g.dart`
- Create: `mobile/test/diary_entry_v2_test.dart`
- Create: `mobile/test/isar_migration_v2_test.dart`

**Interfaces:**
- `DiaryEntry` 新增 `occurredAt`, `deletedAt`, `revision`, `deviceId`, `isConflict`, `conflictOf`, `conflictStatus`, `attachmentIds`，并保留旧路径数组。
- `DiaryQuery` 字段：`query`, `dateFrom`, `dateTo`, `category`, `tags`, `mood`, `favoriteOnly`, `attachmentKind`, `includeTrash`, `includeConflicts`, `limit`, `offset`。
- `Attachment.remoteState` 取 `localOnly/uploading/uploaded/downloading/ready/missing/failed`。
- Isar record 的 `uuid`、`sha256`、`mutationId`、`conflictId` 必须有唯一索引。

- [ ] **Step 1: 写兼容 JSON 和字段默认值的失败测试**

```dart
test('v1 json upgrades without losing old media paths', () {
  final entry = DiaryEntry.fromJson({'id': 'legacy', 'createdAt': '2026-09-16T08:00:00Z', 'updatedAt': '2026-09-16T08:00:00Z', 'content': 'old', 'imagePaths': ['/tmp/a.png']});
  expect(entry.occurredAt, entry.createdAt);
  expect(entry.revision, 1);
  expect(entry.deletedAt, isNull);
  expect(entry.imagePaths, ['/tmp/a.png']);
});
```

- [ ] **Step 2: 写 Isar 迁移对账失败测试**

使用临时 Isar 目录写入一条旧 `DiaryRecord` 和一条带路径的媒体记录，运行迁移后断言记录数、`revision`、附件 `missing/ready` 状态、outbox 数和恢复副本报告都存在。

- [ ] **Step 3: 扩展领域实体和 JSON schemaVersion=2**

`toJson()` 输出 ISO 时间、软删除时间、设备 ID、冲突字段和 `attachmentIds`；`fromJson()` 对缺失字段使用 `occurredAt=createdAt`、`revision=1`、`conflictStatus=pending`，对旧 `isInTrash=true` 映射为 `deletedAt=updatedAt`。

- [ ] **Step 4: 增加 Isar collections 和关系字段**

让 `DiaryRecord` 存新字段；新增附件、outbox、sync state、conflict 四个 collection。每个 `fromEntity/toEntity` 都执行列表复制，避免 UI 修改实体列表后绕过事务。

- [ ] **Step 5: 生成 Isar adapter 并运行测试**

Run from `mobile`: `flutter pub get`; `dart run build_runner build --delete-conflicting-outputs`; `flutter test test/diary_entry_v2_test.dart test/isar_migration_v2_test.dart`
Expected: PASS.

```bash
git add mobile/lib/domain mobile/lib/data mobile/test/diary_entry_v2_test.dart mobile/test/isar_migration_v2_test.dart
git commit -m "feat: extend mobile diary schema for sync v2"
```

### Task 4: APP repository 事务、查询、taxonomy 和草稿

**Files:**
- Modify: `mobile/lib/data/diary_repository.dart`
- Modify: `mobile/lib/data/isar_diary_repository_native.dart`
- Modify: `mobile/lib/data/isar_diary_repository_web.dart`
- Modify: `mobile/lib/application/diary_controller.dart`
- Create: `mobile/test/diary_repository_v2_test.dart`
- Create: `mobile/test/diary_controller_parity_test.dart`

**Interfaces:**
- `Future<List<DiaryEntry>> listEntries({DiaryQuery query = const DiaryQuery()})`
- `Future<void> save(DiaryEntry entry, {bool enqueueMutation = true})`
- `Future<void> batchSetFavorite(Iterable<String> ids, bool value)`
- `Future<void> batchMoveToTrash(Iterable<String> ids)` / `batchRestore(Iterable<String> ids)`
- `Future<void> batchUpdateOrganization(Iterable<String> ids, {String? category, Iterable<String> addTags = const [], Iterable<String> removeTags = const []})`
- `Future<TaxonomyUsage> taxonomyUsage()`，其中 category/tag 每项含 `value`, `count`, `latestUsedAt`。
- `Future<void> saveDraft(DraftPayload draft)`、`Future<DraftPayload?> loadDraft(String id)`、`Future<void> clearDraft(String id)`。
- `Future<ImportResult> mergeImport(ImportPackage package, {ImportPolicy policy = ImportPolicy.merge})`、`Future<DeletePreview> previewDelete(String id)`。
- `Future<List<OutboxMutation>> listPendingMutations({int limit = 100})`、`Future<void> applySyncResult(SyncResult result)`。

- [ ] **Step 1: 为 Memory repository 写失败测试**

测试完整筛选组合、分页稳定排序、批量收藏/回收站、分类标签 usage 排序、草稿恢复和 `applySyncResult` 的 cursor/outbox 原子行为；导入合并测试必须证明不会清空未在导入包中的本地记录。

- [ ] **Step 2: 扩展接口和值对象**

新增 `DiaryQuery` 和 `TaxonomyUsage`，让旧的 `load/search/replaceAll` 继续存在但标记为迁移兼容；新增接口方法返回不可变列表。

- [ ] **Step 3: 实现 Memory 和 SharedPreferences 语义**

Memory 使用列表和 Map 模拟事务；SharedPreferences 使用 `diary.entries.v2`、`diary.outbox.v1`、`diary.sync.v1`、`diary.drafts.v1` 四个 key。`replaceAll` 改为 `mergeImport`，按 ID 比较 `updatedAt/revision/deviceId`，不做覆盖式清空。

- [ ] **Step 4: 实现 Isar 查询和事务**

查询先按 `occurredAt DESC, createdAt DESC, uuid ASC` 排序，再应用日期、分类、标签全匹配、心情区间、收藏、附件类型和回收站过滤；保存记录、附件关系和 outbox 在同一个 `writeTxn` 中完成；应用同步结果时同一事务写入远端记录、冲突、已确认 mutation 和 cursor。

- [ ] **Step 5: 扩展 controller 状态**

增加 `tags`、`taxonomyUsage`、`syncState`、`conflictCount`、`pendingAttachmentCount` getter；提供分页查询、批量操作、草稿和同步刷新方法，所有 mutation 后只刷新受影响的数据集。

- [ ] **Step 6: 运行 APP 数据测试并提交**

Run from `mobile`: `flutter test test/diary_repository_v2_test.dart test/diary_controller_parity_test.dart`
Expected: PASS.

```bash
git add mobile/lib/data mobile/lib/application mobile/test/diary_repository_v2_test.dart mobile/test/diary_controller_parity_test.dart
git commit -m "feat: add mobile parity repository operations"
```

### Task 5: 桌面端接入 v2 和冲突中心

**Files:**
- Modify: `desktop/src/main.cjs`
- Modify: `desktop/src/main/database/migrations.cjs`
- Modify: `desktop/src/main/database/repository.cjs`
- Modify: `desktop/src/main/database/store.cjs`
- Create: `desktop/src/main/database/conflict.test.cjs`
- Modify: `desktop/src/renderer/main.jsx`
- Create: `desktop/src/renderer/components/ConflictView.jsx`
- Modify: `desktop/src/renderer/components/SidebarRail.jsx`
- Modify: `desktop/src/renderer/components/SettingsView.jsx`

**Interfaces:**
- IPC `sync:request` 接受 `{ baseUrl, token, body }` 并请求 `/api/v2/sync`。
- 数据库新增 `conflicts` 表和 `conflict_status` 索引；`applySyncResult` 将冲突副本写入记录并保持 cursor 原子推进。
- `listConflicts({ status = 'pending', limit = 100, offset = 0 })`、`resolveConflict({ conflictId, resolution })`。

- [ ] **Step 1: 写桌面 v2 失败测试**

验证 `applySyncResult` 写入冲突副本、重复冲突 ID 不重复；验证 cursor 更新失败时 outbox 保留；验证 `resolveConflict` 生成 resolution mutation；验证 HTTP URL 和 token 来自 payload 而非固定环境变量。

- [ ] **Step 2: 写 migration 和 repository 实现**

在 SQLite 迁移中创建 `conflicts`、`conflict_id`、`conflict_status`，实现 `listConflicts/resolveConflict`，并让正文、组织字段和附件关系复用现有 `writeEntryRecord`。

- [ ] **Step 3: 切换 IPC 和 renderer 状态**

`sync:request` 选择 v2 路径；renderer 的同步状态增加 `conflict`、`pending`、`failed`、`synced`。在侧栏显示未处理冲突数量，设置页显示最近同步时间和待同步数量。

- [ ] **Step 4: 增加 ConflictView**

显示主记录与冲突副本的标题、正文、标签、附件、来源设备和时间；提供“保留主记录”“保留冲突副本”“手动合并”，手动合并结果通过 resolution mutation 保存。

- [ ] **Step 5: 运行桌面测试和构建并提交**

Run: `pnpm --dir desktop test`; `pnpm --dir desktop run build`
Expected: PASS and Vite build succeeds.

```bash
git add desktop/src/main.cjs desktop/src/main/database desktop/src/renderer
git commit -m "feat: upgrade desktop sync to v2 conflicts"
```

### Task 6: APP SyncClient、同步引擎和附件队列

**Files:**
- Modify: `mobile/pubspec.yaml`
- Create: `mobile/lib/sync/sync_client.dart`
- Create: `mobile/lib/sync/sync_engine.dart`
- Create: `mobile/lib/sync/sync_models.dart`
- Create: `mobile/lib/data/mobile_attachment_store.dart`
- Create: `mobile/test/sync_engine_test.dart`
- Create: `mobile/test/sync_client_test.dart`

**Interfaces:**
- `SyncClient.sync(SyncRequest request) -> Future<SyncResponse>`。
- `SyncClient.headAsset(String sha256) -> Future<bool>`、`uploadAsset(Attachment attachment) -> Future<void>`、`downloadAsset(String sha256) -> Future<Uint8List>`。
- `SyncEngine.syncNow() -> Future<SyncRunResult>`、`start()`、`stop()`；状态流提供 `idle/syncing/pending/synced/failed/conflict`。
- `MobileAttachmentStore.importFile(path) -> Future<Attachment>` 将文件复制到应用目录并计算 SHA-256。

- [ ] **Step 1: 增加依赖并写 HTTP mock 失败测试**

在 `pubspec.yaml` 加入 `http`、`crypto`、`archive`；用 fake `BaseClient` 断言请求路径、Bearer Token、protocolVersion=2 和错误状态映射。

- [ ] **Step 2: 实现 SyncClient**

使用 `package:http` 构建 v2 JSON 请求；2xx 才解析 `data`，401/413/422 转为可展示的 `SyncFailure`；资产上传使用流式 body，下载先写临时文件并由 attachment store 校验 SHA。

- [ ] **Step 3: 实现同步事务循环**

每轮最多读取 100 条 outbox，发送 cursor；收到响应后调用 repository 的 `applySyncResult`，成功提交后才移除已确认 mutation 和推进 cursor；失败保留原队列。退避为 1、2、4、8 分钟，最长 15 分钟。

- [ ] **Step 4: 实现附件队列**

正文同步成功后处理附件：先 `HEAD`，不存在再上传；远端记录缺少本地文件时入下载队列；状态变更为 `uploading/downloading/ready/missing/failed`，正文失败不回滚附件，附件失败不回滚正文。

- [ ] **Step 5: 运行同步测试并提交**

Run from `mobile`: `flutter test test/sync_client_test.dart test/sync_engine_test.dart`
Expected: PASS.

```bash
git add mobile/pubspec.yaml mobile/lib/sync mobile/lib/data/mobile_attachment_store.dart mobile/test/sync_client_test.dart mobile/test/sync_engine_test.dart
git commit -m "feat: add mobile sync engine and asset queue"
```

### Task 7: APP 速记、编辑器、草稿和附件交互对齐

**Files:**
- Modify: `mobile/lib/app/diary_shell.dart`
- Modify: `mobile/lib/app/mobile_diary_shell.dart`
- Modify: `mobile/lib/pages/entry/entry_editor_page.dart`
- Modify: `mobile/lib/widgets/entry_card.dart`
- Create: `mobile/lib/widgets/taxonomy_chips.dart`
- Create: `mobile/test/entry_editor_parity_test.dart`

**Interfaces:**
- `DiaryShellActions.saveQuickCapture(QuickCapturePayload payload)` 支持正文、标题、心情、分类、标签和附件路径。
- `EntryEditorPage` 接受 `tags`, `attachments`, `onDraftChanged`, `onClearDraft`，保存回调仍返回完整 `DiaryEntry`。
- `TaxonomyChips` 接受 `values`, `selected`, `onToggle`, `onCreate`，不使用 Dropdown。

- [ ] **Step 1: 写编辑器和草稿失败测试**

Widget test 输入正文后等待 debounce，断言 `onDraftChanged` 被调用；重新打开同一 draft 能恢复标题、正文、分类、标签和附件；保存后调用 `onClearDraft`。

- [ ] **Step 2: 将标签文本框替换为平铺 chips**

保留“新建标签”小输入框，但已存在标签始终以 `FilterChip` 平铺显示；标签选择直接更新集合；排序使用 controller 的 taxonomy usage 结果。

- [ ] **Step 3: 接入移动速记附件入口**

速记按钮打开底部面板，提供文字、相册、文件和系统分享四种入口；选择文件立即导入受管目录，UI 显示本地路径对应的附件状态而不是保存外部绝对路径。

- [ ] **Step 4: 加入自动草稿和恢复提示**

编辑器每 500 ms 无输入后保存 draft；页面关闭且存在非空 draft 时显示“恢复草稿/丢弃草稿”；成功保存后清理 draft。

- [ ] **Step 5: 运行 widget 测试并提交**

Run from `mobile`: `flutter test test/entry_editor_parity_test.dart`
Expected: PASS.

```bash
git add mobile/lib/app mobile/lib/pages/entry mobile/lib/widgets mobile/test/entry_editor_parity_test.dart
git commit -m "feat: align mobile capture editor and drafts"
```

### Task 8: APP 全部记录、组合筛选、批量操作和 taxonomy 管理

**Files:**
- Create: `mobile/lib/pages/records/all_records_page.dart`
- Create: `mobile/lib/widgets/record_filter_sheet.dart`
- Modify: `mobile/lib/pages/home/home_page.dart`
- Modify: `mobile/lib/app/mobile_diary_shell.dart`
- Modify: `mobile/lib/application/diary_controller.dart`
- Modify: `mobile/lib/pages/settings/category_page.dart`
- Modify: `mobile/lib/pages/recycle/recycle_page.dart`
- Create: `mobile/test/all_records_page_test.dart`
- Create: `mobile/test/taxonomy_management_test.dart`

**Interfaces:**
- `AllRecordsPage` 接受 `DiaryQuery initialQuery`、分页 loader、批量回调和 `onOpenEntry`。
- `RecordFilterSheet` 返回 `DiaryQuery`，标签支持多选且全部值均为平铺 chips。
- controller 提供 `loadNextPage(DiaryQuery query)`、`batchFavorite`、`batchTrash`、`batchOrganize` 和 `undoLastTrash`。

- [ ] **Step 1: 写筛选和批量失败测试**

断言日期范围、多个标签、心情、收藏、附件类型和回收站组合筛选；选择三条记录后批量收藏和批量移入回收站；撤销后记录恢复原状态。

- [ ] **Step 2: 新增一级可达的全部记录页面**

在今天页顶部和我的页增加入口；页面使用 `ListView.builder` 分页，每页 50 条，滚动距离接近底部时调用 `loadNextPage`，不一次性复制全部记录。

- [ ] **Step 3: 实现筛选面板和命中上下文**

关键字匹配标题、正文、分类、标签；结果卡片显示命中的短上下文；筛选状态保留在页面返回栈中，清空按钮一次清除全部条件。

- [ ] **Step 4: 实现多选工具栏和撤销 Snackbar**

长按进入多选，工具栏提供收藏、移入回收站、分类、添加标签、移除标签；移入回收站后 5 秒内可撤销，撤销调用 `batchRestore`。

- [ ] **Step 5: 持久化分类/标签管理**

分类页和标签页显示 usage 统计；重命名、删除、合并都通过 repository 批量更新记录并生成 outbox；删除分类归入“未分类”，删除标签从所有记录移除。

- [ ] **Step 6: 运行页面测试并提交**

Run from `mobile`: `flutter test test/all_records_page_test.dart test/taxonomy_management_test.dart`
Expected: PASS.

```bash
git add mobile/lib/pages mobile/lib/widgets mobile/lib/application mobile/test/all_records_page_test.dart mobile/test/taxonomy_management_test.dart
git commit -m "feat: add mobile records filters and taxonomy parity"
```

### Task 9: APP 媒体库、回收站和状态反馈对齐

**Files:**
- Modify: `mobile/lib/pages/media/media_page.dart`
- Modify: `mobile/lib/pages/recycle/recycle_page.dart`
- Modify: `mobile/lib/widgets/local_media_preview_io.dart`
- Modify: `mobile/lib/widgets/local_media_preview_stub.dart`
- Modify: `mobile/lib/pages/profile/profile_page.dart`
- Create: `mobile/lib/widgets/sync_status_banner.dart`
- Create: `mobile/test/media_page_parity_test.dart`
- Create: `mobile/test/recycle_page_parity_test.dart`

**Interfaces:**
- `MediaPage` 支持 `query`, `kind`, `remoteState`、关键词和父记录回链。
- `SyncStatusBanner` 接受 `SyncState`、`pendingCount`、`conflictCount` 和 `onRetry`。
- 回收站永久删除前调用 `repository.previewDelete(id)`，返回记录数、独占附件数和共享附件数。

- [ ] **Step 1: 写媒体和回收站失败测试**

测试媒体关键字、类型、缺失状态筛选和回链；测试永久删除确认文案包含附件影响；测试批量恢复/删除后列表和计数更新。

- [ ] **Step 2: 增加附件状态和重试入口**

媒体卡片显示待上传、下载中、缺失、失败和就绪状态；失败项提供重新上传/下载；缺失项提供重新定位文件并重新计算 SHA。

- [ ] **Step 3: 增加同步状态 Banner 和入口徽标**

今天页顶部显示“已保存到本机/待同步/同步失败/有冲突”；我的页显示待同步、附件队列和冲突数量，点击进入对应页面。

- [ ] **Step 4: 运行测试并提交**

Run from `mobile`: `flutter test test/media_page_parity_test.dart test/recycle_page_parity_test.dart`
Expected: PASS.

```bash
git add mobile/lib/pages/media mobile/lib/pages/recycle mobile/lib/pages/profile mobile/lib/widgets mobile/test/media_page_parity_test.dart mobile/test/recycle_page_parity_test.dart
git commit -m "feat: align mobile media recycle and sync status"
```

### Task 10: APP `.diary.zip` 备份、预览、合并和回滚

**Files:**
- Create: `mobile/lib/data/diary_backup_service.dart`
- Modify: `mobile/lib/pages/settings/backup_page.dart`
- Modify: `mobile/lib/app/diary_shell.dart`
- Create: `mobile/test/diary_backup_service_test.dart`
- Create: `mobile/test/backup_page_test.dart`

**Interfaces:**
- `DiaryBackupService.exportTo(File target) -> Future<BackupSummary>`。
- `DiaryBackupService.preview(File source) -> Future<BackupPreview>`。
- `DiaryBackupService.importAndMerge(File source, ImportPolicy policy) -> Future<ImportResult>`。
- `ImportPolicy` 值为 `merge`, `skipLocalNewer`, `replaceLocal`；默认使用 `merge`，其中 `replaceLocal` 只在用户明确选择后可用。

- [ ] **Step 1: 写 ZIP round-trip 失败测试**

导出包含 `manifest.json`、`entries.json`、`attachments.json`、`settings.json` 和附件二进制；重新读取后记录字段、标签顺序、附件 SHA 和关系完全一致。

- [ ] **Step 2: 实现 manifest 和安全路径校验**

使用 `archive` 生成 ZIP；拒绝绝对路径、`..`、超过 128 MB 的单文件和 SHA 不匹配的附件；导入先读取到 staging 目录，不直接写受管目录。

- [ ] **Step 3: 实现预览和按 ID 合并**

预览显示记录数、附件数、时间范围、缺失附件数和预计冲突数；导入时比较 ID、`updatedAt`、`revision`，本地较新记录保留并生成可追踪的导入冲突信息。

- [ ] **Step 4: 实现事务回滚和 UI**

附件全部校验成功后再执行 repository 合并；数据库失败只删除本次 staging 文件；页面显示预览、策略选择、进度、成功数量和失败报告，不再调用 `replaceAll`。

- [ ] **Step 5: 运行备份测试并提交**

Run from `mobile`: `flutter test test/diary_backup_service_test.dart test/backup_page_test.dart`
Expected: PASS.

```bash
git add mobile/lib/data/diary_backup_service.dart mobile/lib/pages/settings/backup_page.dart mobile/lib/app/diary_shell.dart mobile/test/diary_backup_service_test.dart mobile/test/backup_page_test.dart
git commit -m "feat: add mobile diary zip backup merge"
```

### Task 11: 日历/洞察复用统一筛选、设置页和生命周期集成

**Files:**
- Modify: `mobile/lib/pages/calendar/calendar_page.dart`
- Modify: `mobile/lib/pages/insights/insights_page.dart`
- Modify: `mobile/lib/pages/settings/settings_page.dart`
- Modify: `mobile/lib/app/diary_shell.dart`
- Modify: `mobile/lib/app/mobile_diary_shell.dart`
- Modify: `mobile/lib/pages/profile/profile_page.dart`
- Create: `mobile/test/calendar_insights_filter_test.dart`
- Create: `mobile/test/mobile_sync_lifecycle_test.dart`

**Interfaces:**
- 日历和洞察输出 `DiaryQuery`，通过 `onOpenFilteredRecords(DiaryQuery query)` 进入全部记录。
- 设置页保存 `serverUrl`、`syncToken`、`syncIntervalSeconds`，并提供立即同步、清理缓存和查看错误报告。
- `DiaryShell` 在 `AppLifecycleState.resumed` 调用 `syncNow`，前台 timer 使用 30–60 秒配置值。

- [ ] **Step 1: 写 drill-down 失败测试**

点击某天、某月或洞察图表的分类柱后，断言打开的全部记录页面收到对应日期/分类 `DiaryQuery`，结果和桌面查询语义一致。

- [ ] **Step 2: 接入设置和生命周期**

启动后先加载本地数据再异步同步；回到前台立即同步；timer 在 dispose 时取消；同步失败不阻塞记录保存。

- [ ] **Step 3: 统一状态文案和错误入口**

将网络错误、鉴权错误、校验错误、附件错误和冲突分别映射到可操作的中文提示；错误详情不展示正文、Token 或附件内容。

- [ ] **Step 4: 运行测试并提交**

Run from `mobile`: `flutter test test/calendar_insights_filter_test.dart test/mobile_sync_lifecycle_test.dart`
Expected: PASS.

```bash
git add mobile/lib/pages mobile/lib/app mobile/test/calendar_insights_filter_test.dart mobile/test/mobile_sync_lifecycle_test.dart
git commit -m "feat: integrate mobile sync lifecycle and drilldown"
```

### Task 12: 跨端验收、迁移报告和发布门禁

**Files:**
- Create: `server/test/cross-client-fixture.test.mjs`
- Create: `desktop/src/main/database/cross-client-fixture.test.cjs`
- Create: `mobile/test/cross_client_fixture_test.dart`
- Create: `mobile/test/fixtures/parity-fixture.json` (由服务端 canonical fixture 同步生成并在测试中校验摘要)
- Modify: `docs/architecture.md`
- Modify: `docs/desktop-implementation-plan.md`
- Modify: `README.md`

**Interfaces:**
- 三端都读取 `server/test/fixtures/parity-fixture.json` 的同一字段和附件 SHA。
- 验收脚本输出 `entries`, `conflicts`, `attachments`, `outbox`, `cursor` 五项摘要。

- [ ] **Step 1: 写 1,000 条离线记录收敛测试**

在 APP 和桌面端各生成 1,000 条唯一 ID 记录，分别断网写入，恢复网络后循环同步直到 cursor 追平；断言两端记录集合、字段和标签顺序完全一致。

- [ ] **Step 2: 写冲突和重复请求测试**

离线修改同一 ID，发送两个 mutation，断言主记录加一份稳定冲突副本；重复发送任一 mutation 不产生第二份记录；重启客户端后 outbox 和 cursor 可继续。

- [ ] **Step 3: 写附件中断恢复测试**

上传 10 MB 图片时中断连接，下一轮继续上传；另一端下载后重新计算 SHA；删除服务器资产时客户端显示 `missing` 并提供重试。

- [ ] **Step 4: 写备份往返和迁移对账测试**

从旧 SharedPreferences/旧媒体路径迁移到 Isar，导出 ZIP，再导入空库和已有库；断言正文、软删除、分类、标签、附件关系和 SHA 一致，失败导入不改变原库。

- [ ] **Step 5: 更新文档并运行发布门禁**

Run: `npm test --prefix server`; `pnpm --dir desktop test`; `pnpm --dir desktop run build`; `Set-Location mobile; flutter test`; `git diff --check`
Expected: all commands PASS and no diff whitespace errors. Update docs to record v2 as default, v1 as compatibility, and list migration recovery steps.

```bash
git add server/test desktop/src/main/database docs/architecture.md docs/desktop-implementation-plan.md README.md mobile/test/cross_client_fixture_test.dart
git commit -m "test: add cross-client parity acceptance"
```

## 自检清单

### Spec coverage

- 协议 v2、cursor、幂等和错误：Task 1–2。
- Entry/Attachment/Outbox/SyncState/Conflict 和迁移：Task 3–4。
- 冲突中心和 resolution mutation：Task 2、5、6、9。
- 平铺 taxonomy、频率/最近使用排序、批量操作和撤销：Task 4、7、8。
- 媒体 SHA、上传下载队列、缺失/重试/迁移：Task 2、3、6、9。
- `.diary.zip` 预览、合并、staging、回滚：Task 10。
- 日历/洞察 drill-down、同步状态、安全错误文案：Task 11。
- 1,000 条记录、冲突、附件中断、备份往返和跨端 fixtures：Task 12。

### Placeholder scan

对计划正文执行占位词扫描并排除本小节本身，预期没有未决占位内容。

### Type consistency

- `DiaryQuery` 由 repository、controller、`RecordFilterSheet` 和日历/洞察 drill-down 共用。
- `SyncRequest/SyncResponse` 由 `SyncClient`、`SyncEngine`、服务端 `normalizeV2Request` 和桌面 IPC 使用同一字段名。
- `Attachment.remoteState` 的七个值与服务端资产响应、媒体页状态和测试 fixture 一致。
- `ImportPolicy` 的三种值与备份 UI、repository merge 方法和备份测试一致。
