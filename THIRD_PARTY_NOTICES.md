# 第三方组件与授权说明

本项目原创代码采用根目录 [MIT License](LICENSE)。仓库中的“此刻”品牌图标及各平台派生图标由维护者确认属于原创或 AI 生成资源，可随项目按照相同条款公开使用。

第三方依赖、字体、运行时和 SDK 保留各自的许可证与版权声明。根 MIT 不重新授权这些材料。下面是主要组件索引；实际使用版本以 `mobile/pubspec.lock` 和 `desktop/pnpm-lock.yaml` 为准，完整声明还需保留相应分发包中的 LICENSE、NOTICE 和运行时声明。

| 组件 | 许可与说明 | 来源 |
| --- | --- | --- |
| Flutter / Dart | 各自的 BSD 许可证及随 SDK 提供的第三方声明 | [Flutter](https://github.com/flutter/flutter/blob/stable/LICENSE)、[Dart](https://github.com/dart-lang/sdk/blob/main/LICENSE) |
| Electron / Chromium / Node.js | Electron 为 MIT；Chromium、Node.js 及其内置组件有独立声明 | [Electron](https://github.com/electron/electron/blob/main/LICENSE)、[Node.js](https://github.com/nodejs/node/blob/main/LICENSE) |
| React、Milkdown、Motion | MIT，保留各组件原始版权与许可证 | [React](https://github.com/facebook/react/blob/main/LICENSE)、[Milkdown](https://github.com/Milkdown/milkdown/blob/main/LICENSE)、[Motion](https://github.com/motiondivision/motion/blob/main/LICENSE.md) |
| Quill 2.0.3 | BSD-3-Clause | [本地声明](third_party/quill.LICENSE.txt)、[上游](https://github.com/slab/quill/blob/v2.0.3/LICENSE) |
| Lucide React 1.46.0 | ISC，完整文件另含 Feather 来源的 MIT 声明 | [本地声明](third_party/lucide.LICENSE.txt)、[上游](https://lucide.dev/license) |
| Inter / Fontsource Inter 5.3.0 | SIL Open Font License 1.1；字体沿用 OFL | [本地声明](third_party/inter.OFL.txt)、[上游](https://github.com/rsms/inter/blob/master/LICENSE.txt) |
| DOMPurify 3.4.15 | 上游提供 MPL-2.0 或 Apache-2.0；本项目分发采用 Apache-2.0 选项 | [上游声明](https://github.com/cure53/DOMPurify/blob/3.4.15/LICENSE) |
| remark-math 6.0.0 | MIT；发布包 README 有授权说明，但缺少独立 LICENSE，补充保留上游全文 | [本地声明](third_party/remark-math.LICENSE.txt)、[上游](https://github.com/remarkjs/remark-math/blob/main/license) |
| 高德 Android SDK | `com.amap.api:3dmap-location-search:10.1.200_loc6.4.9_sea9.7.4`，依高德 SDK 与服务条款使用；不属于项目 MIT 授权 | [服务协议](https://lbs.amap.com/pages/terms/)、[隐私政策](https://lbs.amap.com/pages/privacy/) |

## 安装包中的声明

Windows 分发需要保留 Electron 的 `LICENSE.electron.txt`、`LICENSES.chromium.html`，以及打包依赖的许可文件。字体即使被构建工具复制到 `dist/assets/`，也应同时保留 OFL 与原始版权声明。`third_party/` 提供上述特殊组件的完整声明副本；桌面打包配置已将根 LICENSE、这份索引和声明副本加入 `resources/`，下一次构建后仍需实际核验。

Flutter 构建会收集 Dart 包的许可证；当前手机端没有独立的“开源许可证”页面。原生高德 SDK 的条款还需要单独提供，不能假设 Dart 包的自动收集覆盖了原生 SDK。

增加仓库声明不会自动修改已发布安装包。下一次发布时，应把根 LICENSE、这份索引及所需声明副本随安装包分发，并检查打包后的内容；具体流程见[发布指南](docs/releasing.md)。依赖新增或升级时重新核对锁定版本的许可，不能仅按组件名称推断。
