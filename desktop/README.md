# 此刻 · Windows 桌面端

`desktop/` 是此刻的 Electron 桌面客户端，面向键盘输入、宽屏浏览和记录整理。React 提供工作区界面，Electron main 进程管理窗口、本地数据库、附件和系统快捷键。手机端位于 [`mobile/`](../mobile/)，两端通过同步协议交换记录，各自使用独立的界面和本地数据库。

当前安装包配置面向 **Windows x64**，使用 NSIS 安装程序；macOS 和 Linux 尚未配置发布打包入口。仓库中的 Flutter Windows 工程属于 `mobile/` 的平台目录，本文的桌面启动与打包入口均在 `desktop/`。

## 技术与代码入口

| 部分 | 当前实现 | 入口 |
| --- | --- | --- |
| 桌面运行时 | Electron 40、自绘标题栏、托盘、独立速记窗口 | [`src/main.cjs`](src/main.cjs) |
| 业务桥接 | preload 暴露业务 IPC；renderer 启用 `contextIsolation`、关闭 `nodeIntegration` | [`src/preload.cjs`](src/preload.cjs) |
| 界面与构建 | React 19、Vite 7、Motion、Lucide | [`src/renderer/main.jsx`](src/renderer/main.jsx)、[`vite.config.mjs`](vite.config.mjs) |
| 正文编辑 | 纯文本、Milkdown Markdown、Quill 富文本；富文本保存 Delta | [`src/renderer/components/`](src/renderer/components/) |
| 本地数据 | `node:sqlite`、WAL、FTS5 搜索、事务与版本化迁移 | [`src/main/database/`](src/main/database/) |
| 同步 | Sync API v2、outbox、增量 cursor、冲突副本和附件上传/下载 | [`src/main/sync-asset-transfer.cjs`](src/main/sync-asset-transfer.cjs) |
| 脚本与安装包配置 | pnpm、electron-builder、Windows x64 NSIS | [`package.json`](package.json) |

## 启动与开发

开发环境需要 Node.js 和 pnpm。Node.js 必须提供 `node:sqlite`，并满足 Vite 7 的运行要求；pnpm 版本由 `package.json` 的 `packageManager` 指定为 `11.17.0`。依赖版本记录在 `pnpm-lock.yaml`。

从仓库根目录运行：

```powershell
cd desktop
pnpm install --frozen-lockfile
pnpm start
```

`pnpm start` 和 `pnpm dev` 当前执行相同流程：先用 Vite 构建 renderer 到 `dist/`，再启动 Electron。修改代码后退出应用并重新执行命令；这两个脚本没有启动 Vite 热更新服务器。

桌面端可以离线创建和检索本地记录。要体验跨设备同步，按 [`server/README.md`](../server/README.md) 启动或部署同步服务，然后在桌面“设置”中填写连接信息。

## 构建与检查

以下命令在 `desktop/` 目录执行：

| 命令 | 用途 | 输出或范围 |
| --- | --- | --- |
| `pnpm run build` | 构建 React renderer | `dist/`；单独执行不会生成桌面安装包 |
| `pnpm start` / `pnpm dev` | 构建并启动桌面应用 | Electron 主窗口与托盘 |
| `pnpm test` | 运行 Node 内置测试 | `src/main/**/*.test.cjs` |
| `pnpm run dist:win` | 构建 renderer 并生成 Windows 安装包 | `release/`，NSIS，x64 |
| `node scripts/benchmark-database.cjs` | 比较本机数据库查询性能 | 在临时目录生成 10,000 条记录，输出列表和搜索耗时 |

`pnpm test` 覆盖数据库、迁移、同步与附件、备份、连接配置、快捷键、窗口位置、图标和更新检查等 main 进程逻辑。仓库当前没有为桌面配置 renderer 组件测试或完整 GUI 端到端测试脚本；相关验收工作见实施方案。

## 使用入口

启动后进入“今天”，可以直接快速记录；标题可选，未填写时使用正文首行作为摘要。正文支持粘贴文字、图片和视频，也支持拖入媒体文件。分类、标签和心情可以随记录保存，未提交的编辑内容会保存为本地草稿。

左侧导航提供以下入口：

| 入口 | 当前功能 |
| --- | --- |
| 今天 | 快速记录、回看当日记录、编辑、收藏、复制和移入回收站 |
| 全部记录 | 分页浏览、SQLite 全量搜索、命中高亮；日期、分类、标签、心情、收藏和附件组合筛选；批量收藏、整理和删除 |
| 日历 | 按日期回看记录，并写入选定日期 |
| 媒体 | 图片、视频、音频筛选与预览，按文件名或记录内容检索，打开所属记录 |
| 洞察 | 文字、附件和分类统计 |
| 标签 | 分类与标签使用情况、筛选、重命名和删除 |
| 冲突 | 查看同步产生的冲突副本并选择处理方式 |
| 回收 | 恢复、永久删除和清空回收站 |
| 设置 | 同步连接、连接配置导入导出、附件状态、备份、快捷键和更新检查 |

主窗口关闭后会隐藏到托盘，应用继续运行。托盘菜单可以打开主窗口、唤起速记或选择“退出此刻”结束应用。

### 快捷键

| 快捷键 | 操作 |
| --- | --- |
| `Ctrl + N` | 聚焦新记录 |
| `Ctrl + K` | 打开命令面板，搜索、跳转或执行常用操作 |
| `Ctrl + ,` | 打开设置 |
| `Ctrl + Enter` | 保存当前记录 |
| `Esc` | 关闭命令面板或编辑弹层 |
| `Ctrl + Shift + Space` | 应用运行时从其他软件唤起独立速记窗口 |

速记保存后窗口隐藏。系统级快捷键可以在“设置”中修改；注册冲突时会保留原快捷键并显示原因。

## 数据、附件与备份

正式桌面应用的数据保存在 Electron 的 `app.getPath('userData')` 目录，Windows 通常位于 `%APPDATA%` 下的应用目录：

| 相对应用数据目录的路径 | 内容 |
| --- | --- |
| `diary.sqlite` | 记录、草稿、设置、同步 outbox、cursor、冲突及附件元数据 |
| `media/managed/` | 受管附件，登记稳定 ID、SHA-256 和相对路径 |
| `backups/` | 每日滚动 `.diary.zip` 备份 |

首次迁移旧版 renderer 的 `localStorage` 数据时，会先写恢复副本再导入 SQLite。renderer 经 preload 调用数据库业务接口；直接在浏览器打开页面时使用的是预览用 `localStorage` fallback，完整数据与系统能力应通过 Electron 运行验证。

导入的媒体会复制到应用数据目录。设置页显示可用、缺失和待清理附件数量；缺失附件可在媒体查看器中重新定位原文件，哈希校验成功后恢复。列表与媒体墙按需生成图片缩略图，读取失败时显示不可用占位。

设置页可导出包含记录及附件的 `.diary.zip`。导入会先显示摘要，再按稳定 ID 合并，并保留较新的本地记录；附件先写入 staging，失败时回收本次新增文件并提示阶段。数据库完成启动初始化后会后台生成滚动备份，每个 UTC 日期最多一份，保留最近 7 份；应用启动也会按宽限期清理遗留 staging 和孤儿附件。

## 同步与更新

同步默认地址为 `http://127.0.0.1:8787`，在“设置”中可修改同步服务地址和访问令牌。桌面先写本地 SQLite，再通过 v2 协议上传 outbox、拉取增量记录，并单独传输附件。

手机与桌面需要连接同一服务并使用匹配的令牌。手机连接开发机时应填写开发机可达的局域网地址；手机自己的 `127.0.0.1` 不会指向开发机。连接配置可在自己的设备间复制与导入，其中包含访问令牌，导入后需保存设置。

“公开更新地址”与同步连接分开配置。更新检查读取 `/api/v1/update?platform=desktop`，发现新版本后可以打开下载链接；当前没有安装包自动下载、自动安装或应用内自动替换流程。

相关文档：

- [仓库总览](../README.md)
- [架构说明](../docs/architecture.md)
- [同步协议](../docs/sync-contract.md)
- [桌面实施方案与后续验收](../docs/desktop-implementation-plan.md)
- [Windows 开发机同步服务部署](../docs/sync-service-deployment.md)
- [服务器部署说明](../docs/server-sync-service-deployment.md)

实施方案中的待办代表后续目标；本文的能力说明以当前代码和脚本为准。
