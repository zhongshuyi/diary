# 此刻 Windows 0.1.1 公开预览

Windows x64 NSIS 安装包；这是 GitHub prerelease。

- 公开预览：提供独立桌面版本与安装包，包含速记、Markdown / 富文本编辑、检索、媒体浏览和托盘功能。
- 本地 SQLite、附件、滚动备份、Sync API v2 与冲突处理随预览包分发。
- 收紧打包范围，排除项目测试、开发配置和私有文件。
- 保持应用身份与数据目录兼容，构建命令关闭自动上传。

下载 `diary-desktop-0.1.1-win-x64-setup.exe` 后运行安装器。更新前可使用应用内备份保存独立副本。此安装包未进行 Windows 代码签名，系统可能提示未知发布者。

验证：64 项主进程测试通过，renderer 和 NSIS 安装包构建通过。尚未完成完整 GUI 验收，继续作为公开预览发布。附件 `SHA256SUMS` 和 `release.json` 提供文件校验值与源码提交。
