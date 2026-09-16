# 跨端数据格式与同步协议 v1

## 1. 日记记录 `DiaryEntry`

记录使用 camelCase，与当前 Flutter `DiaryEntry.toJson()` 保持兼容。时间统一使用 ISO-8601 字符串，推荐发送 UTC（末尾 `Z`）。

```json
{
  "schemaVersion": 1,
  "id": "entry-uuid",
  "createdAt": "2026-09-15T08:40:00.000Z",
  "updatedAt": "2026-09-15T08:40:00.000Z",
  "title": "慢下来，生活会发光",
  "content": "一段客户端原始内容；富文本客户端可以放 Delta JSON 字符串。",
  "contentText": "用于搜索和预览的纯文本",
  "editorType": "plain_text",
  "mood": 0.8,
  "category": "生活",
  "tags": ["慢生活"],
  "imagePaths": [],
  "audioPaths": [],
  "videoPaths": [],
  "weather": [],
  "positions": [],
  "latitude": null,
  "longitude": null,
  "colorValue": 14869485,
  "isFavorite": false,
  "isInTrash": false
}
```

必填字段：`schemaVersion`、`id`、`createdAt`、`updatedAt`、`title`、`content`、`contentText`、`editorType`、`mood`、`category`、`tags`、媒体数组和 `isInTrash`。服务端会拒绝缺少身份和版本字段的记录。未知字段会被保留，以便客户端渐进升级。

`editorType` 当前允许 `plain_text`、`markdown`、`rich_text`。`mood` 范围是 `0..1`。`title` 可以为空；桌面端列表会用正文首行展示无标题记录。`imagePaths` 等数组保存本地路径或未来的附件引用，不代表服务端已经拥有文件。

桌面端本地数据库已经使用独立 schema 保存 `occurredAt` 和可选心情；附件实体与引用关系将在后续 Phase 5 完成。在协议 v1 仍运行期间，客户端通过兼容映射发送上述字段。协议 v1 不应被误认为桌面本地数据库的最终结构。

## 2. 同步请求

`POST /api/v1/sync`

请求头：

```text
Content-Type: application/json
Authorization: Bearer <SYNC_AUTH_TOKEN>  # 配置 token 后必填
```

请求体：

```json
{
  "protocolVersion": 1,
  "deviceId": "desktop-uuid",
  "cursor": "42",
  "limit": 100,
  "client": {
    "platform": "desktop",
    "appVersion": "0.1.0"
  },
  "changes": [
    {
      "mutationId": "desktop-uuid:entry-uuid:updatedAt",
      "entry": { "...": "DiaryEntry" }
    }
  ]
}
```

`cursor` 是服务端单调递增的 opaque-ish 字符串游标；客户端只保存服务端返回的 `nextCursor`，不要自行推断游标含义。`changes` 可以为空，空变更请求用于只拉取其他设备的更新。

## 3. 同步响应

成功响应为 `200`：

```json
{
  "data": {
    "nextCursor": "45",
    "changes": [
      {
        "sequence": 45,
        "mutationId": "mobile-uuid:entry-uuid:updatedAt",
        "deviceId": "mobile-uuid",
        "entry": { "...": "DiaryEntry" }
      }
    ],
    "appliedMutationIds": ["desktop-uuid:entry-uuid:updatedAt"],
    "conflicts": []
  },
  "meta": { "protocolVersion": 1 }
}
```

服务端使用 `400` 表示 JSON 或基本格式错误，`401` 表示 token 缺失或错误，`413` 表示请求过大，`422` 表示记录语义校验失败，`500` 表示服务端内部错误。错误格式统一为：

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [{ "field": "deviceId", "message": "Required" }]
  }
}
```

## 4. 冲突和重试

同一个 `mutationId` 重试不会重复写入。多个设备修改同一条记录时，比较 `(updatedAt, deviceId, mutationId)` 的字典序，较大者胜出；失败的一方会在 `conflicts` 收到服务端当前记录。客户端应保留本地草稿或将冲突内容复制到冲突箱，当前桌面 MVP 先以服务端胜出记录刷新列表。

网络超时、断网和服务端 `5xx` 都应保留 outbox，稍后指数退避重试；客户端不能因为同步失败而丢掉本地记录。

## 5. 未来附件协议

附件同步将新增独立的 `POST /api/v1/assets`（上传）和 `GET /api/v1/assets/:id`（下载）。日记同步只携带 `assetId`、`kind`、`mimeType`、`byteSize`、`sha256`，避免文本同步被图片大小拖慢。当前两端仍保留 `imagePaths`/`audioPaths`/`videoPaths` 兼容字段。
