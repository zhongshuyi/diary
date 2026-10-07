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

手机端本地助手新增 `llamadart 0.10.0`（MIT）及其打包的 llama.cpp 原生 CPU 运行时（MIT，随运行时的第三方组件仍遵循各自声明）。可下载的 Qwen3-0.6B、Qwen3-1.7B 与 Qwen3-4B-Instruct-2507 权重采用 Apache-2.0，独立于项目 MIT；模型不嵌入 APK。来源和使用边界见[本地助手说明](docs/local-assistant.md)。导入其他模型时需遵循其来源许可。

离线录音转写使用 `sherpa_onnx 1.13.8` 的 Dart API 和关闭 TTS 的原生识别运行时。Android arm64 库由固定版本源码构建，Windows x64 使用上游 `no-tts` 分发包；这两个平台不打包 eSpeak NG 或 Piper。Sherpa、kaldi-native-fbank、OpenFst、simple-sentencepiece 采用 Apache-2.0，ONNX Runtime 及其内置组件保留原始声明；未修改的 Eigen 3.4.0 文件遵循 MPL-2.0，来源链接和完整条款随应用提供。可下载的 SenseVoiceSmall int8 权重遵循 FunASR 模型许可证，模型不嵌入安装包。完整声明见 [offline-speech.txt](mobile/assets/licenses/offline-speech.txt)，构建及模型说明见[录音转写说明](docs/speech-transcription.md)。

Windows 分发需要保留 Electron 的 `LICENSE.electron.txt`、`LICENSES.chromium.html`，以及打包依赖的许可文件。字体即使被构建工具复制到 `dist/assets/`，也应同时保留 OFL 与原始版权声明。`third_party/` 提供上述特殊组件的完整声明副本；桌面打包配置已将根 LICENSE、这份索引和声明副本加入 `resources/`，下一次构建后仍需实际核验。

Flutter 构建会收集 Dart 包的许可证。本地助手的原生许可及其内置组件声明随 APK 的 `assets/licenses/local-llm.txt` 分发，并注册到 Flutter 许可证列表，可从“关于 → 开源许可证”查看。原生高德 SDK 的条款还需要单独提供，不能假设 Dart 包的自动收集覆盖了原生 SDK。

录音转写的原生组件、依赖和模型条款随应用的 `assets/licenses/offline-speech.txt` 分发，并注册到同一个许可证列表。模型下载目录另外保存完整 `MODEL_LICENSE.txt`。

增加仓库声明不会自动修改已发布安装包。下一次发布时，应把根 LICENSE、这份索引及所需声明副本随安装包分发，并检查打包后的内容；具体流程见[发布指南](docs/releasing.md)。依赖新增或升级时重新核对锁定版本的许可，不能仅按组件名称推断。
