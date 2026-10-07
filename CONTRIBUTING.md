# 贡献指南

感谢你帮助改进此刻。功能建议和问题反馈可以提交到 [Issues](https://github.com/zhongshuyi/diary/issues)，代码或文档修改可以提交 Pull Request。

## 反馈问题

请说明使用的是 Android 手机端还是 Windows 桌面端，并提供应用版本、系统版本、复现步骤、预期行为和实际表现。键盘、动画或同步问题还应说明是否启用了同步，以及问题发生前的操作顺序。

尽量使用临时示例记录复现。提交日志和截图前，移除私人日记、访问令牌、签名密码和其他个人信息。

## 开发入口

| 修改范围 | 开发与配置说明 |
| --- | --- |
| 手机端 | [mobile/README.md](mobile/README.md) |
| 桌面端 | [desktop/README.md](desktop/README.md) |
| 同步服务 | [server/README.md](server/README.md) |
| 跨端字段与同步 | [架构](docs/architecture.md)、[协议](docs/sync-contract.md) |

两端各自维护界面和本地数据库。修改记录、附件、删除或同步字段时，需要检查另一端的兼容行为以及服务端处理。

## 验证修改

按改动范围运行必要检查。以下命令分别在对应模块目录执行：

```powershell
# mobile/
flutter test -j 1

# desktop/
pnpm test
pnpm run build

# server/
npm test
```

只修改文档时，检查命令、相对链接及 `git diff --check` 即可。涉及交互时还需在对应平台验证实际行为；涉及同步时应检查离线保存、失败重试、跨端增量、附件和删除传播。

在手机上验证更新时先确认设备序列号，构建后使用 `adb -s <设备序列号> install -r <APK路径>` 覆盖安装。保留原有应用与数据；签名或版本不兼容导致失败时先处理原因，不通过卸载绕过。

## 提交说明

让一次修改围绕一个清晰问题，说明触发条件、修改后的行为以及验证方式。新增或改变用户可见能力时，同步更新对应 README；协议或部署行为变化时更新 `docs/`。

不要提交真实 `.env`、`key.properties`、keystore、访问令牌、个人数据库、附件或构建输出。配置示例使用占位值，避免把某一台开发机的路径或地址写成通用步骤。
