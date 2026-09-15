# My Diary

一个以隐私和长期记录为核心的 Flutter 日记应用。UI 采用温暖纸张、深墨绿和陶土色的编辑感设计，支持手机与桌面端自适应布局。

## 当前能力

- 时间线、搜索、分类筛选和收藏
- 纯文本、Markdown 预览、Quill 富文本三种编辑方式
- 图片/文件附件入口、单篇分享、JSON 全量备份
- 日历视图、媒体库、情绪洞察、回收站恢复与永久删除
- 主题模式、全局阅读字号、默认编辑器和字数显示均可持久化
- 可选系统生物识别/设备解锁，应用切回前台时重新验证
- 原生端使用 Isar Community 3.3.2 存储，带唯一 ID、时间、分类和回收站索引
- Web 端使用同一仓储接口切换到 SharedPreferences，规避 Isar 3.x schema 的 JavaScript 64 位常量限制

## 工程结构

```text
lib/
├─ app/             应用主题、路由常量、响应式壳层
├─ application/     日记与设置用例、页面状态控制器
├─ domain/          DiaryEntry、DiarySettings 领域模型与演示数据
├─ data/            日记仓储、Isar 模型、设置存储与平台实现
├─ pages/           按功能拆分的页面：主页、日历、媒体、洞察、编辑、详情、分享、回收站、设置
└─ widgets/         导航、媒体预览、日记卡片、页面标题等可复用组件
```

页面不直接依赖数据库；所有持久化操作通过 `DiaryRepository`，原生端默认使用 Isar Community，测试可以注入内存仓储。

## 依赖策略

依赖已按当前 Flutter 3.41.4 / Dart 3.11.1 环境验证。`isar_community` 用于原生端的大量日记数据；没有实际使用的参考项目依赖不会为了“堆包”而加入。`local_auth` 用于可选隐私锁。`flutter_quill`、`share_plus` 和 `file_picker` 已选择当前依赖树可解析且测试通过的版本；Pub 显示的更高版本需要 Dart 3.12 或会与现有 Windows 依赖冲突，待升级 Flutter 后再升级。

## 参考 moodiary 后的取舍

已加入：媒体库、持久化偏好、主题与字号、系统隐私锁、回收站、日历、洞察和本地备份。这些功能与“离线优先、长期记录”目标直接相关。

暂不默认加入：AI 助手、地图轨迹、WebDAV/MinIO 云同步、录音/视频播放器和涂鸦实验室。它们会引入网络、定位、权限或较重的原生依赖，并扩大日记隐私边界；后续可以作为独立可选模块接入，而不是让核心日记启动依赖它们。

## 开发

```powershell
flutter pub get
dart run build_runner build
flutter test -j 1
flutter run
```

Isar 生成文件位于 `lib/data/isar_diary_record.g.dart`，修改 `@collection` 模型后重新运行生成命令。
