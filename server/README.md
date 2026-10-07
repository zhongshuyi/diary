# 此刻 · 同步服务

为手机端和桌面端提供增量同步、冲突副本、附件上传下载和应用更新检查。当前使用同步协议 v2，保留 v1 兼容入口。服务仅依赖 Node.js 内置模块，日记与变更日志保存为 JSON 文件，附件按 SHA-256 保存到文件目录。

## 本机启动

部署文档使用 Node.js 24。以下命令从仓库根目录执行，无需安装生产依赖：

```powershell
Set-Location server
npm start
```

默认地址为 `http://127.0.0.1:8787`，健康检查为 `GET /health`。在 `server/` 中可运行 `npm run dev` 开启源码监听，或运行 `npm test` 执行测试。

## 配置

| 环境变量 | 默认值 | 用途 |
| --- | --- | --- |
| `HOST` | `127.0.0.1` | 监听地址；局域网访问可设置为 `0.0.0.0`。 |
| `PORT` | `8787` | HTTP 端口。 |
| `SYNC_AUTH_TOKEN` | 空 | 同步与附件接口的 Bearer 令牌；空值表示不要求鉴权。 |
| `SYNC_DATA_FILE` | `data/sync-store.json` | 日记、mutation 与增量变更日志。 |
| `UPDATE_MANIFEST_FILE` | `data/update-manifest.json` | 应用更新清单。 |
| `RELEASE_DIRECTORY` | `data/releases` | `/downloads/` 提供的安装包目录。 |

上述相对路径统一相对于 `server/` 解析；附件目录为 `SYNC_DATA_FILE` 所在目录下的 `assets/`。

`npm start` 不会自动读取 `.env`。[`.env.example`](.env.example) 提供配置示例；可通过启动环境设置变量，或在 `server/` 下使用以下命令加载自行创建的环境文件：

```powershell
node --env-file=.env src/server.mjs
```

## 接口

| 接口 | 用途 | 配置令牌后是否需要鉴权 |
| --- | --- | --- |
| `GET /health` | 健康检查。 | 否 |
| `POST /api/v2/sync` | v2 增量同步与冲突处理。 | 是 |
| `POST /api/v1/sync` | v1 兼容同步。 | 是 |
| `HEAD /api/v2/assets/<sha256>` | 检查附件是否存在。 | 是 |
| `PUT /api/v2/assets/<sha256>` | 上传附件原始字节并校验 SHA-256。 | 是 |
| `GET /api/v2/assets/<sha256>` | 下载附件。 | 是 |
| `GET /api/v1/update?platform=desktop` 或 `mobile` | 查询应用更新。 | 否 |
| `GET /downloads/<文件名>` | 下载已发布安装包。 | 否 |

鉴权请求头为 `Authorization: Bearer <SYNC_AUTH_TOKEN>`。同步 JSON 请求上限为 2 MiB，每次最多提交 100 条 mutation；拉取 `limit` 默认 100，上限 200。单个附件上限为 128 MiB。字段、cursor 和冲突语义详见[同步协议](../docs/sync-contract.md)。

更新清单可参考 [`update-manifest.example.json`](update-manifest.example.json)，按平台填写版本、下载地址和更新说明。清单在每次检查时读取，修改后无需重启服务。

## 部署与备份

局域网部署见[开发机同步服务部署](../docs/sync-service-deployment.md)，服务器部署与 PM2 维护见[服务器同步服务部署](../docs/server-sync-service-deployment.md)。公网部署应通过 HTTPS 提供访问并设置强随机令牌。

更新源码时保留环境文件和数据。备份日记时同时保存 `sync-store.json` 与整个 `assets/` 目录；维护更新分发时一并保存更新清单和安装包目录。JSON 存储适用于单进程服务，多个实例不能同时写入同一数据文件。
