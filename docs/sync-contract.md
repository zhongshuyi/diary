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

客户端仍可发送 `imagePaths`、`audioPaths`、`videoPaths` 兼容字段，但新实现必须使用 `attachmentIds` 和独立附件实体。`deletedAt` 非空等价于回收站状态；`isInTrash` 仅为 v1 兼容读取字段。

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

`cursor` 是服务端单调递增字符串。`changes` 为空表示只拉取远端变更；每次最多 100 条 mutation。服务端按 `(updatedAt, deviceId, mutationId)` 决定主记录版本，并用 `mutationId` 幂等。

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

冲突副本写入 change log，重复 mutation 或重复拉取不会创建第二份。主记录仍为当前胜出版本；客户端默认不把冲突副本放入普通时间线、记录数和搜索。

解决冲突时客户端发送新的 resolution mutation，服务端将主记录和冲突副本标记为 `resolved`，并广播给其他设备。

## 5. 附件接口

- `HEAD /api/v2/assets/:sha256`：检查 SHA 是否已存在。
- `PUT /api/v2/assets/:sha256`：上传原始字节，按 SHA 幂等。
- `GET /api/v2/assets/:sha256`：鉴权后流式下载。

附件元数据必须包含 `assetId`、`sha256`、`kind`（`image/video/audio/file`）、`mimeType`、`byteSize`、`originalName`。单文件上限为 128 MB。服务器先写临时文件，校验大小和 SHA 后原子改名为 `<sha256>`；不接受客户端路径。

## 6. 重试、安全和兼容

网络错误、超时和 `5xx` 保留 outbox，指数退避 1、2、4、8 分钟，最长 15 分钟；`4xx` 错误显示修复入口，不无限重试。生产环境必须使用 HTTPS、Bearer Token、受限附件目录和不记录正文的日志策略。

`POST /api/v1/sync` 保留为兼容入口。v1 客户端只能读写主记录，不参与冲突中心和附件队列；升级后的 APP 和桌面端统一使用 v2。
