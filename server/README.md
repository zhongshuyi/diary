# Diary Sync Server

这是同步协议 v1 的可运行开发服务。它使用 Node.js 内置 `http` 模块和 JSON 文件存储，不需要额外依赖即可启动，方便先把两端协议跑通。

```powershell
npm start
```

默认监听 `http://127.0.0.1:8787`。未配置 `SYNC_AUTH_TOKEN` 时适合本机开发；部署前应设置 token，并把数据存储替换为持久化数据库和 HTTPS。

更新检查接口为 `GET /api/v1/update?platform=desktop` 或 `GET /api/v1/update?platform=mobile`，不需要同步 Token。更新信息从 `UPDATE_MANIFEST_FILE` 指定的 JSON 文件读取，默认是 `data/update-manifest.json`；可参考 [`update-manifest.example.json`](update-manifest.example.json) 创建并部署该文件。修改 manifest 后无需重启服务，客户端下次检查即可拿到新版本。

接口详见 [`../docs/sync-contract.md`](../docs/sync-contract.md)。
