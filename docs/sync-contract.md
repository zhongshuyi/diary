# 跨端数据格式与同步协议 v2

## 1. 记录格式

记录使用 camelCase，时间统一为 ISO-8601（推荐 UTC）。v2 在 v1 字段上增加软删除、发生时间、版本、设备、冲突和附件关系：

```json
{
  "schemaVersion": 2,
  "id": "entry-uuid",
  "createdAt": "2026-09-16T08:00:00.000Z",
  "occurredAt": "2026-09-16T07:55:00.000Z",
  "updatedAt": "2026-09-16T08:01:00.000Z",
  "deletedAt": null,
  "isDeleted": false,
  "title": "一句话",
  "content": "客户端原始内容",
  "contentText": "用于搜索和预览的纯文本",
  "editorType": "plain_text",
  "mood": 0.8,
  "category": "生活",
  "tags": ["摘录"],
  "attachmentIds": ["asset-<sha256>"],
  "isFavorite": false,
  "revision": 1,
  "deviceId": "desktop-uuid",
  "isConflict": false,
  "conflictOf": null,
  "conflictStatus": "pending"
}
```

客户端维护 `attachmentIds` 和本地附件实体；当前跨端传输还使用 `imagePaths`、`audioPaths`、`videoPaths` 以及正文中的 `asset://<sha256><扩展名>` 引用，由接收端还原为本机受管路径。不要发送仅在源设备可用的绝对路径。`deletedAt` 非空表示回收站状态；`isInTrash` 为兼容读取字段。永久删除使用 `isDeleted: true` 的 tombstone，服务端保留删除状态，防止同 ID 的普通记录被旧设备重新上传后复活。

## 2. 同步请求

`POST /api/v2/sync`

请求头：

```text
Content-Type: application/json
Authorization: Bearer <SYNC_AUTH_TOKEN>
```

请求体：

```json
{
  "protocolVersion": 2,
  "deviceId": "desktop-uuid",
  "cursor": "42",
  "limit": 100,
  "client": { "platform": "desktop", "appVersion": "0.2.0" },
  "changes": [
    {
      "mutationId": "desktop-uuid:entry-uuid:revision-2",
      "entry": { "schemaVersion": 2, "id": "entry-uuid", "revision": 2 }
    }
  ]
}
```

`cursor` 是服务端单调递增字符串。`changes` 为空表示只拉取远端变更；每次最多 100 条 mutation。服务端按 `(updatedAt, deviceId, mutationId)` 比较普通记录版本，并用 `mutationId` 幂等。永久删除的 tombstone 优先于普通记录；已永久删除的主记录不接受同 ID 的普通记录覆盖。示例中的 `entry` 省略了字段，实际提交应使用完整记录。

## 3. 同步响应与 cursor

```json
{
  "data": {
    "nextCursor": "45",
    "changes": [
      {
        "sequence": 45,
        "mutationId": "mobile-uuid:entry-uuid:revision-2",
        "deviceId": "mobile-uuid",
        "entry": { "schemaVersion": 2, "id": "entry-uuid" }
      }
    ],
    "appliedMutationIds": ["desktop-uuid:entry-uuid:revision-2"],
    "conflicts": []
  },
  "meta": { "protocolVersion": 2 }
}
```

客户端只有在本地事务成功应用 `changes`、冲突副本并确认 `appliedMutationIds` 后，才能保存 `nextCursor`。页面未追平时继续请求；失败则保留原 cursor 和 outbox。

错误状态为 `400` JSON 格式错误、`401` token 错误、`413` 请求过大、`422` 语义校验错误、`500` 服务端错误，统一返回 `{ error: { code, message, details } }`。

## 4. 冲突

被版本比较拒绝的 mutation 不丢弃。服务端创建：

```text
conflictId = conflict:<entryId>:<mutationId>
entry.id = conflictId
entry.isConflict = true
entry.conflictOf = entryId
entry.conflictStatus = pending
```

冲突副本写入 change log，重复 mutation 或重复拉取不会创建第二份。主记录仍为当前胜出版本，冲突副本保留被拒绝的修改内容，客户端可在冲突中心查看与处理。

解决冲突时客户端保存新的主记录修改、生成 mutation，并将本地冲突状态标记为 `resolved`。当前没有单独的 resolution 接口；服务端按普通 mutation 规则处理新记录，不会自动将对应冲突副本在所有设备上标记为已处理。

## 5. 附件接口

- `HEAD /api/v2/assets/:sha256`：检查 SHA 是否已存在。
- `PUT /api/v2/assets/:sha256`：上传原始字节，按 SHA 幂等。
- `GET /api/v2/assets/:sha256`：鉴权后流式下载。

客户端附件元数据包括 `assetId`、`sha256`、`kind`（`image/video/audio/file`）、`mimeType`、`byteSize`、`originalName`，由各自的本地附件仓储维护。当前服务端没有独立的附件元数据 CRUD 接口，二进制接口以 SHA-256 为键。单文件上限为 128 MiB。服务器先写临时文件，校验大小和 SHA 后原子改名为 `<sha256>`；不接受客户端文件路径作为存储目标。

## 6. 重试、安全和兼容

同步失败保留尚未确认的 outbox 和已有 cursor，并向用户显示同步状态。当前 Android 自动队列默认在交互停顿约 2 秒后执行，单轮上传和拉取各最多 20 条；失败或仍有工作时约 10 秒后继续调度，手动同步可立即执行。重试间隔属于客户端实现，并非协议要求；当前移动端没有按 HTTP 状态区分的指数退避策略。鉴权或请求校验失败需要修正连接配置或数据后重试。

公网部署应使用 HTTPS、Bearer Token 和受限附件目录，不在日志中记录正文或令牌。当前服务没有端到端加密，应用锁也不会加密日记与备份。

`POST /api/v1/sync` 保留为兼容入口。v1 客户端只能读写主记录，不参与冲突中心和附件队列；升级后的 APP 和桌面端统一使用 v2。
