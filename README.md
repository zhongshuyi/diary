# 此刻 · Diary Workspace

这是一个本地优先的日记应用工作区，包含两个独立客户端和一个同步服务：

- `mobile/`：Flutter 手机端，面向单手操作、快速碎碎念和离线记录。
- `desktop/`：Electron Windows 桌面端，面向键盘、宽屏、多栏浏览和持续编辑。
- `server/`：Node.js 同步服务，提供版本化增量同步 API。
- `docs/`：跨端数据格式、同步协议和架构约定。

桌面端的记录器支持直接把文字粘贴到正文，把剪贴板中的图片/视频或资源管理器中的媒体文件粘贴、拖入编辑器；媒体会先复制到 Electron 的应用数据目录，再写入日记，避免原文件移动后预览失效。标题是可选的，不写标题时桌面端会用正文首行作为列表摘要。

## 本地开发

```powershell
# 手机端
cd mobile
flutter pub get
flutter test

# 桌面端（先启动同步服务更完整）
cd ..\server
npm start

# 另开终端
cd ..\desktop
pnpm install
pnpm start
```

Flutter 工程的原有说明和平台配置保留在 [`mobile/README.md`](mobile/README.md)。

## 目录边界

两端不共享页面壳层，只共享稳定的数据格式和同步协议。这样手机端可以持续优化“打开即写”，桌面端可以独立发展为真正的桌面工作台，不会再被移动端的页面入口和交互逻辑牵制。

详细约定见 [`docs/architecture.md`](docs/architecture.md) 和 [`docs/sync-contract.md`](docs/sync-contract.md)。
桌面端需求与 Phase 0–5（当前切片）实施进度见 [`docs/desktop-implementation-plan.md`](docs/desktop-implementation-plan.md)。
开发机局域网同步服务的启动、路径、IP 与排障说明见 [`docs/sync-service-deployment.md`](docs/sync-service-deployment.md)。
