# 此刻 · Flutter 客户端

此刻是一款本地优先的私人日记工具。这个目录主要维护 Android 客户端，适合对话式速记、随手拍照和离线记录。独立桌面客户端位于 [`../desktop/`](../desktop/README.md)；本目录保留的 iOS、Windows、macOS、Linux 和 Web 工程需要分别验证，不能视为已经具备相同的平台能力。

当前正式安装包：[Android 1.1.0+4](https://github.com/zhongshuyi/diary/releases/tag/mobile-v1.1.0)。普通日记功能支持 Android 7.0（API 24）及以上；本地文字模型和录音识别另有系统、架构要求。版本、签名校验与后续发布步骤见[发布指南](../docs/releasing.md)。

## 已实现功能

- 对话式记录、首页速记和完整日记编辑，支持草稿保存与恢复。
- 纯文本、Markdown 编辑与预览、Quill 富文本；分类、标签、心情和收藏。
- 照片、拍照、视频、录音和文件附件，以及图片预览、音频和视频播放。
- 时间线、搜索与筛选、日历、媒体库、本地心情统计和每周回顾。
- 回收站恢复与永久删除，ZIP 完整备份和 ZIP / JSON 导入。
- 6 位应用密码和可选生物识别快捷解锁，可选每日本地提醒。
- 主题模式与配色、阅读字号、三种聊天布局、双方头像和聊天背景；布局不会改变主题背景色。
- 日记陪伴：切换 MiniMax、DeepSeek、OpenAI 兼容 API 与本地模型，自定义语气与人设，只回应单条日记。
- 离线录音转文字：下载独立识别模型后，可在保存录音时自动转写，手动重试并搜索识别文字。
- “我的”页统一列表入口，设置按记录、外观、安全、数据、地图、关于分组，支持关键词搜索与快速跳转。
- 可选自托管同步、附件传输与冲突处理；Android 高德位置消息、系统文字/图片分享接收和启动快捷方式。

## 数据与同步

Android 使用 Isar Community 保存日记、草稿、待同步记录和同步状态，附件复制到应用自己的目录并以 SHA256 标识。单个导入附件上限为 128 MB。无需启动服务器即可保存和阅读本地日记。

需要跨设备同步时，在“设置 → 同步”填写服务地址和可选 token。服务部署参见 [`../server/README.md`](../server/README.md)，协议参见 [`../docs/sync-contract.md`](../docs/sync-contract.md)。也可在构建时通过 `DIARY_SYNC_URL` 和 `DIARY_SYNC_TOKEN` 提供默认连接；设备设置优先。

“备份与恢复”可以保存包含正文、分类、标签、心情和本机附件的 ZIP，也支持分享 JSON 文本及导入 ZIP / JSON。需要迁移附件时使用 ZIP。备份格式未加密，应用密码是访问控制，不会加密日记或备份文件。

录音转写单独存入 `audioTranscripts`，可供搜索、备份与 v2 同步；跨设备保留转写需要更新同步服务器。旧服务器的正文和媒体同步仍兼容，客户端也会保留同一录音在本机已有的转写。日记陪伴回应只在本机保存，不进入正文、搜索、同步或日记备份。

## 日记陪伴与录音识别

可直接从“我的 → 日记陪伴 / 录音转文字”进入，也可在设置中搜索“模型”“API”或“转写”。

- **在线日记陪伴**：选择线上来源与服务商，填写 API 地址、模型 ID 和自己的 Key，保存并测试后开启。MiniMax 默认使用国内平台 `MiniMax-M3`；DeepSeek 和其他 Chat Completions 兼容服务也可配置。页面明确显示当前来源、模型与启用状态。Key 使用系统安全存储，不嵌入公开 APK，不随备份或同步导出。
- **本地日记陪伴**：仅 Android 10 及以上的 64 位设备，需单独下载或导入 GGUF 模型。小模型可能误解否定、时间与情绪，较大的模型也不保证准确；优先使用在线模式。切换来源保留已经下载的模型。
- **回应规则**：只针对当前日记给简短回应，不追问、不邀请继续聊，不带连续聊天历史。语气与人设只改变表达。在线图片输入默认关闭，开启后最多发送当前日记的 4 张压缩图片，需要模型支持图片。
- **离线录音识别**：Android 8.1（API 27）及以上 ARM64 设备，模型约 240 MB。支持本应用 AAC/m4a 录音及 PCM WAV；每段最多 3 分钟、50 MB。下载后可开启保存录音自动转写，也可手动重试。识别不上传录音，不使用在线模型 Key，不改写日记正文。

模型不随 APK 分发。语音原生库使用固定版本的 ASR 构建，关闭 TTS、eSpeak 和 Piper；打包前需按[原生运行库说明](native/offline-speech/README.md)准备库。Windows x64 Flutter 工程的 WAV 识别路径与正式维护的 Electron 桌面端不同，后者尚未接入这两项功能。详细配置与边界见[日记陪伴](../docs/local-assistant.md)和[录音转写](../docs/speech-transcription.md)。

## 开发准备

需要 Flutter SDK（Dart SDK 满足 `^3.11.0`）、Android SDK，以及可供 Android 构建使用的 JDK 17。以下命令均在本目录执行：

首次克隆还需准备 ASR 原生库。Windows 主机需 Python 3、Android SDK 中的 NDK `28.2.13676358`（r28c）和 CMake `3.22.1`；在仓库根目录运行 `./tools/build-speech-runtime.ps1`，或在本目录运行下方相对路径命令。脚本从固定源码构建 Android ARM64 识别库，校验输出，不包含 TTS。库保存在被忽略的 `native/offline-speech/` 产物目录，不随源码提交。Linux 主机使用 Python、CMake、C++ 编译工具与同版 NDK，命令见[原生运行库说明](native/offline-speech/README.md)。

```powershell
../tools/build-speech-runtime.ps1
flutter pub get
flutter test -j 1
flutter devices
```

Isar 生成代码已保存在仓库中。修改 `lib/data/` 下的 `@collection` 模型后，重新生成：

```powershell
dart run build_runner build
```

### Android 签名配置

当前 Gradle 配置在加载时要求 `android/key.properties` 存在，debug 构建也需要这个配置文件。准备自己的 keystore，然后创建该文件；以下仅为占位模板：

```properties
storeFile=C:/private/path/diary-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

`storeFile` 可使用绝对路径，Windows 路径建议使用 `/`。配置文件与 keystore 均已被 Git 忽略，不应提交到仓库。更新已有正式版时必须沿用原签名密钥。

## 构建与覆盖安装

debug 版包名为 `com.ling.diary.dev`，显示名为 `Diary Dev`；正式版包名为 `com.ling.diary`，显示名为“此刻”。两者分别保存应用数据。

先通过 `adb devices` 确认目标设备，再构建并覆盖安装 dev 版：

```powershell
adb devices
flutter build apk --debug
adb -s <设备序列号> install -r build/app/outputs/flutter-apk/app-debug.apk
```

正式版：

```powershell
flutter build apk --release
adb -s <设备序列号> install -r build/app/outputs/flutter-apk/app-release.apk
```

更新时保留原应用及数据，不先卸载、不清除数据，也不使用 `flutter install`。如果覆盖安装因签名或版本失败，应先处理失败原因，不能通过卸载绕过。

## 位置与更新配置

位置功能目前仅支持 Android。在“设置 → 高德 Android Key”填写与当前 APK 包名及签名 SHA1 匹配的 Key；dev 和正式版应分别配置。首次使用会请求高德隐私授权和系统定位权限，可在设置中撤回隐私授权。对话页“＋ → 位置”支持选点和发送位置消息，点击消息可查看地图。Key 仅保存在当前设备，不随日记同步。

关于页可以手动检查同步服务器提供的版本信息，并打开下载地址。需要配置默认更新服务器时，可在构建命令中追加：

```powershell
--dart-define=DIARY_UPDATE_SERVER_URL=https://your-sync-host.example
```

当前版本优先读取实际安装包信息；`DIARY_APP_VERSION` 只用于无法读取构建信息时的兜底。

## 代码结构

| 目录 | 职责 |
| --- | --- |
| `lib/app/` | 主题、路由、平台壳层和应用锁入口 |
| `lib/application/` | 用例、状态控制器、提醒与本地统计 |
| `lib/domain/` | 日记、设置、附件和同步模型 |
| `lib/data/` | 仓储、Isar 模型、备份和原生桥接 |
| `lib/sync/` | 同步客户端、待同步队列和附件传输 |
| `lib/pages/` | 对话、时间线、编辑、日历、媒体及设置页面 |
| `lib/widgets/` | 编辑、媒体展示和其他可复用组件 |
| `test/` | 单元测试与 Widget 测试 |

页面通过 `DiaryRepository` 和控制器执行持久化操作，测试可以注入内存仓储。Web 仓储有 SharedPreferences fallback；完整 Web 运行和媒体能力仍需单独验证。
