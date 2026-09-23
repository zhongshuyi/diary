# 仓库 AI 操作要求

## Android dev 版安装

- 安装或更新手机上的 dev 版时，必须保留应用现有数据。禁止先卸载应用、清除应用数据，或使用会先卸载旧版的 `flutter install`。
- 先用 `flutter build apk --debug` 构建，再对已确认的目标设备执行覆盖安装：`adb -s <设备序列号> install -r mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- 如果覆盖安装因签名、版本或其他原因失败，停止安装并向用户说明原因；不得通过卸载旧版来绕过失败。
