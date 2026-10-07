<div align="center">
  <img src="mobile/assets/brand/diary_logo.png" width="96" height="96" alt="此刻图标">
  <h1>此刻 · Diary</h1>
  <p>随手记下当下，慢慢整理生活。</p>
  <p>本地优先的日记应用 · Android 手机端 · Windows 桌面端 · 可选自托管同步</p>
  <p>
    <a href="mobile/README.md">Android 开发</a> ·
    <a href="desktop/README.md">Windows 开发</a> ·
    <a href="server/README.md">同步服务</a> ·
    <a href="CONTRIBUTING.md">参与贡献</a>
  </p>
</div>

此刻把快速记录和日后回看放在一起：手机上像发消息一样写下一个瞬间，电脑上用键盘和宽屏继续编辑、检索和整理。记录先保存到自己的设备，离线也能使用；需要在设备之间接续时，再连接自己的同步服务。

## 可以做什么

- **随手记录**：Android 提供对话式速记、首页速记和完整编辑器；Windows 提供工作区、独立速记窗口和全局快捷键。
- **认真写作**：支持纯文本、Markdown 和 Quill 富文本，保存草稿，按分类、标签、心情和收藏组织记录。
- **留下更多细节**：手机可拍照、录音并添加媒体；桌面可粘贴或拖入图片、视频，导入的媒体复制到应用目录。
- **回看和整理**：时间线、搜索与筛选、日历、媒体库和本地统计；回收站支持恢复和永久删除。
- **自己掌握数据**：本地保存、ZIP 备份与恢复，可选同步正文和附件；同步冲突保留副本供处理。

Android 还提供应用密码、可选生物识别解锁、本地提醒、位置记录、系统分享接收以及主题和聊天背景设置。Windows 提供命令面板、组合筛选、批量整理、托盘和每日滚动备份。两端的具体能力见各自的 README。

## 平台与项目结构

| 模块 | 当前维护方向 | 技术与入口 |
| --- | --- | --- |
| [`mobile/`](mobile/README.md) | Android 手机客户端 | Flutter / Dart、Isar Community |
| [`desktop/`](desktop/README.md) | Windows x64 桌面客户端 | Electron、React、SQLite；NSIS 安装包 |
| [`server/`](server/README.md) | 可选自托管同步与更新服务 | Node.js 内置模块、JSON 数据存储、附件文件目录 |
| [`docs/`](docs/architecture.md) | 架构、协议与部署说明 | 两端共享数据语义，各自维护界面和本地数据库 |

Flutter 工程保留了 iOS、macOS、Linux、Web 和 Windows 平台目录，这些平台的运行、媒体和发布能力仍需分别验证。当前 Windows 桌面客户端的开发入口是 `desktop/`。

## 本地保存与跨设备同步

无需账号或同步服务即可记录和阅读本地日记。Android 使用 Isar，Windows 使用应用数据目录中的 SQLite；媒体保存在各自设备的应用目录。

启用同步后，客户端先保存本地记录和待同步队列，再通过 v2 协议批量上传、按游标拉取增量变更。附件按 SHA-256 单独传输，不放进同步 JSON。Android 自动同步会等待交互停顿后分批处理，手动同步可以立即执行。

手机与电脑需要连接同一个服务，并填写匹配的访问令牌。手机连接开发机时，应使用开发机可达的局域网地址；`127.0.0.1` 只指向当前设备。公网服务的 HTTPS 和令牌配置见[服务器部署说明](docs/server-sync-service-deployment.md)。

备份是独立的数据副本，同步会传播修改和删除。需要保留正文及本机附件时，使用客户端的 ZIP 备份；服务端备份需同时保存记录文件和附件目录。当前日记与备份未加密，Android 应用密码用于限制进入应用。

## 从源码运行

先克隆仓库：

```powershell
git clone https://github.com/zhongshuyi/diary.git
cd diary
```

以下每组命令均从仓库根目录开始，按需要选择模块。

### Android

准备 Flutter SDK（Dart 满足 `^3.11.0`）、Android SDK 和 JDK 17。当前 Gradle 配置需要先准备 `mobile/android/key.properties`；签名模板和构建说明见[手机端 README](mobile/README.md#android-签名配置)。

```powershell
cd mobile
flutter pub get
flutter test -j 1
flutter build apk --debug
```

确认设备序列号后，在 `mobile/` 下覆盖安装，保留原有数据：

```powershell
adb devices
adb -s <设备序列号> install -r build/app/outputs/flutter-apk/app-debug.apk
```

dev 版和正式版使用不同包名。更新同一版本类型时需保持签名一致；覆盖安装失败时先处理失败原因，不能通过卸载绕过。

### Windows

准备 Node.js 24 和 pnpm `11.17.0`，详细环境和脚本说明见[桌面端 README](desktop/README.md)。

```powershell
cd desktop
pnpm install --frozen-lockfile
pnpm start
```

`pnpm start` 会构建界面并启动 Electron。生成 Windows x64 安装包：

```powershell
pnpm run dist:win
```

输出位于 `desktop/release/`。

### 可选同步服务

使用 Node.js 24，无需安装生产依赖：

```powershell
cd server
npm start
```

默认监听 `http://127.0.0.1:8787`，健康检查为 `/health`。配置变量、令牌、局域网访问和更新分发见[同步服务 README](server/README.md)。`npm start` 不会自动加载 `.env`，使用环境文件时按该文档启动。

## 文档与贡献

| 文档 | 内容 |
| --- | --- |
| [手机端说明](mobile/README.md) | 功能、开发环境、签名、覆盖安装、位置配置 |
| [桌面端说明](desktop/README.md) | 工作区、快捷键、数据目录、构建与检查 |
| [同步服务说明](server/README.md) | 配置、接口、运行限制、更新分发 |
| [应用架构](docs/architecture.md) | 模块边界、本地数据、同步与附件流程 |
| [同步协议 v2](docs/sync-contract.md) | 记录格式、游标、冲突、删除与附件接口 |
| [开发机部署](docs/sync-service-deployment.md) | Windows 与手机局域网连接、排障 |
| [服务器部署](docs/server-sync-service-deployment.md) | HTTPS、PM2、数据备份、更新与回退 |
| [贡献指南](CONTRIBUTING.md) | 问题反馈、修改范围和验证命令 |

欢迎通过 [Issues](https://github.com/zhongshuyi/diary/issues) 反馈问题或提出建议，也欢迎提交 Pull Request。提交前请阅读贡献指南；功能路线与待验收项另见[桌面实施方案](docs/desktop-implementation-plan.md)。
