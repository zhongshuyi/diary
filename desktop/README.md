# Diary Desktop

这是独立于 Flutter 手机端的 Electron + React Windows 桌面应用。Electron 负责原生窗口和 IPC，React 负责桌面工作区、页面入口与记录交互。它使用自绘标题栏和桌面工作区布局，入口直接是时间线与快速记录，不通过“我的”进入设置。

```powershell
npm install
npm start
```

桌面端当前已实现：

- 无原生边框窗口、最小化/最大化/关闭和可拖动标题栏。
- 左侧工作区导航，设置是一级入口。
- 快速记录支持一天多次写入、可选标题、分类和心情；正文区域可直接粘贴文字、图片、视频，也支持拖入媒体文件。
- 图片和视频会复制到 Electron 应用数据目录后再保存，列表和媒体库会实际读取并预览附件。
- 本地优先保存到 Electron renderer 的 localStorage，网络可用时批量同步。
- `Ctrl + N` 聚焦新记录，`Ctrl + Enter` 保存。

同步服务地址默认是 `http://127.0.0.1:8787`，可以在“应用设置”中修改。
