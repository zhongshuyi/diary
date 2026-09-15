# Diary Sync Server

这是同步协议 v1 的可运行开发服务。它使用 Node.js 内置 `http` 模块和 JSON 文件存储，不需要额外依赖即可启动，方便先把两端协议跑通。

```powershell
npm start
```

默认监听 `http://127.0.0.1:8787`。未配置 `SYNC_AUTH_TOKEN` 时适合本机开发；部署前应设置 token，并把数据存储替换为持久化数据库和 HTTPS。

接口详见 [`../docs/sync-contract.md`](../docs/sync-contract.md)。
