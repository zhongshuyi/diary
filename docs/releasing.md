# 发布与版本管理

安装包通过 GitHub Releases 分发，源码、版本号和发布说明留在 Git。构建产物放在被忽略的 `artifacts/`，签名和个人部署配置保存在本机，不加入发布附件。

## 版本与渠道

两端独立递增，修复一般递增 patch，新增兼容功能递增 minor，破坏兼容性的变化递增 major。Android 还必须递增 build number，即 `versionCode`。

| 平台 | 版本来源 | tag 示例 | 当前发布渠道 |
| --- | --- | --- | --- |
| Android | `mobile/pubspec.yaml` 的 `version` | `mobile-v1.0.2`，对应 `1.0.2+3` | 正式 Release |
| Windows x64 | `desktop/package.json` 的 `version` | `desktop-v0.1.1`，对应 `0.1.1` | GitHub prerelease，公开预览 |

Windows 预览版的包内版本为 `0.1.1`，预览状态通过 GitHub Release 的 prerelease 标记表达。两种 tag 可以指向同一提交，不要求两端版本号相同。未配置发布入口的平台不附带安装包，也不声明为已发布平台。

版本号、tag 和安装包内容必须一致。已发布的 tag 与安装包不覆盖、不移动；修复后使用新版本和新 tag。仓库未指定 LICENSE，发布流程不自行添加授权条款。

发布脚本使用 Node.js 24，从仓库根目录执行：

```powershell
node scripts/release.mjs versions
node scripts/release.mjs check all
node scripts/release.mjs check mobile mobile-v1.0.2
node scripts/release.mjs check desktop desktop-v0.1.1
```

准备下一版本时，例如：

```powershell
node scripts/release.mjs bump mobile 1.0.3 4
node scripts/release.mjs bump desktop 0.1.2
```

只递增正在发布的平台。同步更新 [CHANGELOG](../CHANGELOG.md)，并为新 tag 写入 `releases/<tag>.md`，说明变化、支持的平台、安装方式和实际验证范围。不要把尚未完成的 GUI 验收或代码签名写成已完成。

## 固定源码提交

先完成必要修改与检查，再提交并推送。测试范围见[贡献指南](../CONTRIBUTING.md)，发布版本检查不能代替对应模块测试与实际交互验证。

```powershell
git status --short
git diff --check
node scripts/release.mjs check all
```

检查待提交内容，不包括 `.local/`、真实 `.env`、`key.properties`、keystore、个人数据库和附件。提交版本、发布说明及相关代码后，创建对应平台的 annotated tag，例如本次两端均发布时：

```powershell
git tag -a mobile-v1.0.2 -m "Android 1.0.2 build 3"
git tag -a desktop-v0.1.1 -m "Windows 0.1.1 preview"
git push origin main
git push origin mobile-v1.0.2 desktop-v0.1.1
```

后续发布替换为新 tag；已有 tag 时先核对其目标提交，不重复创建。构建时使用该 tag 对应源码，工作区不包含未提交的产品修改。`release.json` 的 `sourceCommit` 应与 tag 指向的提交相同。

## 在本机构建与整理安装包

### Android

准备 Flutter、Android SDK、JDK 17 和原正式版签名。当前 Gradle 在配置阶段读取 `mobile/android/key.properties`，即使 debug 构建也需要此文件；模板见[手机端签名说明](../mobile/README.md#android-签名配置)。私有签名配置留在本机，并复用现有正式签名以保留覆盖更新能力。

从仓库根目录构建，不传入真实同步地址、访问令牌或私有更新地址的 `--dart-define`：

```powershell
cd mobile
flutter pub get
flutter build apk --release
cd ..
node scripts/release.mjs prepare mobile
```

构建失败时停止，不能使用目录中遗留的旧 APK 继续发布。`prepare mobile` 使用 Android SDK 的 `aapt2` 和 Java / `apksigner` 校验 APK 的正式包名、版本、build number 和签名，并输出公开安装包及元数据。版本检查通过并不代表签名与用户已有安装一致；首次准备该签名的公开发行时，还应与可信旧正式 APK 的签名证书摘要比对。

如果需要在手机上验证更新，先确认目标设备，再使用覆盖安装：

```powershell
adb devices
adb -s <设备序列号> install -r mobile/build/app/outputs/flutter-apk/app-release.apk
```

禁止先卸载、清除数据或使用会先卸载的安装方式。签名或版本不兼容时处理失败原因，不能通过卸载绕过。

### Windows

在 Windows 上准备 Node.js 24 和 `desktop/package.json` 指定的 pnpm；使用 lockfile 固定依赖：

```powershell
cd desktop
pnpm install --frozen-lockfile
pnpm test
pnpm run dist:win
cd ..
node scripts/release.mjs prepare desktop
```

`dist:win` 显式使用 `--publish never`，只构建 Windows x64 NSIS 包。安装器名为 `diary-desktop-<version>-win-x64-setup.exe`。构建失败时停止，不复用 `desktop/release/` 的旧版本。`prepare desktop` 只在 Windows 验证 EXE 版本并整理产物，不自动安装应用。

保持 `name: diary-desktop`、`productName: Diary`、`appId: com.ling.diary.desktop`，以及代码中的 Windows AUMID。更改这些值需要单独设计升级与数据迁移，不能只为改显示名称而直接替换。GUI 验证使用隔离资料库或测试设备，不删除用户已有日记；没有完成完整 GUI 和代码签名验收的版本继续标记为预览。

### 产物目录

准备结果位于：

```text
artifacts/releases/<tag>/
  <安装包文件名>.apk 或 .exe
  SHA256SUMS
  release.json
```

`SHA256SUMS` 提供安装包 SHA-256。`release.json` 记录平台版本、Android build number（如适用）、安装包 SHA-256 和 `sourceCommit`，用于关联二进制与源码。这里不保存密码、令牌、签名私钥或个人部署信息。不要把整个项目目录、构建缓存、NSIS 调试文件或 `.local/` 当作 Release 附件上传。

## 通过 GitHub CLI 发布

先完成 `gh auth login`，并确认目标账号与仓库。以下命令均指定 `zhongshuyi/diary`，使用已推送的 tag；`--verify-tag` 防止 Release 命令在意外提交上创建 tag。[CLI 创建说明](https://cli.github.com/manual/gh_release_create)

### 1. 创建 draft

Android 正式包：

```powershell
gh release create mobile-v1.0.2 --repo zhongshuyi/diary --verify-tag --draft --latest=false --title "此刻 Android 1.0.2" --notes-file releases/mobile-v1.0.2.md
```

Windows 公开预览：

```powershell
gh release create desktop-v0.1.1 --repo zhongshuyi/diary --verify-tag --draft --prerelease --latest=false --title "此刻 Windows 0.1.1 公开预览" --notes-file releases/desktop-v0.1.1.md
```

Release 已存在时先查看其 draft 状态与附件，避免重复创建。完成核验前保持 draft。

### 2. 上传明确的三个文件

选择已准备的平台 tag，确认目录内只有一个对应安装包：

```powershell
$releaseTag = 'mobile-v1.0.2'
$releaseDirectory = Join-Path 'artifacts/releases' $releaseTag
$installers = @(Get-ChildItem -LiteralPath $releaseDirectory -File | Where-Object { $_.Extension -in '.apk', '.exe' })
if ($installers.Count -ne 1) { throw '发布目录必须包含一个对应平台的安装包' }
$installer = $installers[0]
gh release upload $releaseTag --repo zhongshuyi/diary $installer.FullName (Join-Path $releaseDirectory 'SHA256SUMS') (Join-Path $releaseDirectory 'release.json')
```

Windows 将 `$releaseTag` 改为 `desktop-v0.1.1`。不使用 `--clobber`，同名附件冲突时停止检查；正式发布后使用新版本解决问题。[CLI 上传说明](https://cli.github.com/manual/gh_release_upload)

### 3. 核验 draft 及下载内容

```powershell
gh release view $releaseTag --repo zhongshuyi/diary --json tagName,isDraft,isPrerelease,assets,targetCommitish
$downloadDirectory = Join-Path 'artifacts/download-check' $releaseTag
gh release download $releaseTag --repo zhongshuyi/diary --dir $downloadDirectory
$localHash = (Get-FileHash -LiteralPath $installer.FullName -Algorithm SHA256).Hash
$downloadHash = (Get-FileHash -LiteralPath (Join-Path $downloadDirectory $installer.Name) -Algorithm SHA256).Hash
if ($localHash -ne $downloadHash) { throw '下载安装包与本机构建 SHA-256 不一致' }
```

核对三个附件的名称和大小，比较下载包、`SHA256SUMS` 与 `release.json` 的 SHA-256，并确认 `sourceCommit` 对应 tag 提交。`targetCommitish` 可能是分支名称；最终以 Git tag 解析出的提交核对源码。Android 使用正式渠道，Windows 预览的 `isPrerelease` 应为 `true`。

### 4. 最终发布

所有附件与说明核验完成后再执行对应命令：

```powershell
gh release edit mobile-v1.0.2 --repo zhongshuyi/diary --draft=false --prerelease=false --latest=true
gh release edit desktop-v0.1.1 --repo zhongshuyi/diary --draft=false --prerelease --latest=false
```

按实际发布的平台执行，不修改另一个版本的状态。[CLI 发布状态说明](https://cli.github.com/manual/gh_release_edit)

## CI 与手动 Windows draft

CI 检查版本规则及相关模块，不代替设备验证。Windows 打包工作流仅通过 GitHub Actions 的手动运行入口触发：输入已推送的 `desktop-v<version>` tag，由工作流构建并准备 draft Release。工作流没有自动把 draft 发布成正式版本，也不上传本机私有配置。

手动工作流和本地 CLI 是两种发布入口，同一 tag 选择其中一种创建 draft。工作流完成后同样执行附件、SHA-256、版本和源码提交核验，最后再发布。Android 正式签名默认留在本机，不为自动化把私钥放进仓库。

## 下载链接与服务端更新清单

在 README、发布说明或更新服务中使用明确的平台 tag，例如：

- [Android 1.0.2](https://github.com/zhongshuyi/diary/releases/tag/mobile-v1.0.2)
- [Windows 0.1.1 公开预览](https://github.com/zhongshuyi/diary/releases/tag/desktop-v0.1.1)

直接下载地址采用 `https://github.com/zhongshuyi/diary/releases/download/<tag>/<安装包文件名>`。不要用 `releases/latest/download` 混合指向两端独立版本；示例版本发布后仍可下载，不随下一次发布变化。

需要供自托管更新服务使用时，在本机生成更新清单：

```powershell
node scripts/release.mjs manifest --output artifacts/update-manifest.json
```

核对清单中的平台版本与具体 tag 下载地址，再按[同步服务说明](../server/README.md)部署到自己的更新服务。脚本只生成文件，不部署服务、不修改真实服务器配置。上传 GitHub Release 本身不会改变已部署的更新清单；客户端当前检查更新后打开下载链接，不自动替用户安装。
