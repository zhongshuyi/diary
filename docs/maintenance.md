# 仓库维护

本仓库由 [zhongshuyi](https://github.com/zhongshuyi) 维护。`.github/CODEOWNERS` 将变更审查指向维护者；贡献者遵循[贡献指南](../CONTRIBUTING.md)和[社区行为规范](../CODE_OF_CONDUCT.md)。

## 合并前

- 查看 CI 与 CodeQL 的结果，并核对实际改动。CI 通过不能代替手机或桌面交互验收。
- 涉及记录、附件、删除和同步时检查两端兼容；涉及应用身份、签名和数据目录时检查覆盖升级。
- 不移动已经发布的 tag、不覆盖已发布安装包；版本与构建说明见[发布指南](releasing.md)。
- 新增依赖或资源时更新[第三方声明](../THIRD_PARTY_NOTICES.md)，数据与权限变化更新[隐私说明](../PRIVACY.md)。

合并后自动清理已合并的来源分支。依赖更新仍需维护者审查，不自动合并。

## 自动检查的范围

| 检查 | 范围 |
| --- | --- |
| CI | Flutter 测试、桌面 main 测试和 renderer 构建、服务端测试、版本与发布工具 |
| 仓库维护检查 | Git 跟踪的私有配置、签名、个人数据与构建输出路径；维护文件和 action 的固定提交 |
| CodeQL | JavaScript / TypeScript 源码，包括桌面、服务端和 Node 工具；不覆盖 Dart |
| Dependabot 版本更新 | 每周检查桌面 npm 与 GitHub Actions，按兼容版本分组 |
| Dependabot 安全提醒与更新 | 报告依赖漏洞，并为可修复问题准备更新 PR |

仓库已启用 GitHub 秘密扫描和 push protection；它们不保证识别所有私人 IP、自定义令牌或二进制中的配置。真实部署材料继续保存在被忽略的 `.local/`；配置示例只使用占位值。安全漏洞反馈入口见 [SECURITY.md](../SECURITY.md)。

本地可以运行：

```powershell
node --test scripts/check-repository.test.mjs
node scripts/check-repository.mjs
node --test scripts/release.test.mjs
node scripts/release.mjs check all
```

## 处理依赖告警

启用提醒后的首次核查见[依赖安全快照](dependency-security.md)。快照记录当时的版本和待处理告警，实时状态以上游公告和 GitHub 为准；当前桌面依赖修复优先于下方的展示与签名建设。

在 [Dependabot alerts](https://github.com/zhongshuyi/diary/security/dependabot) 查看受影响的包、调用位置、范围和修复版本。区分生产运行时与构建工具，并评估触发条件；构建工具也可能处理来自贡献者的输入。

优先采用兼容的修复版本，保留 lockfile，检查变更与授权后运行对应模块测试和构建。需要 major 升级的修改单独验证；不因为 PR 标为依赖更新就跳过审查。已发布的安装包不会随着 lockfile 更新而变化，需要新版本、新 tag 和重新构建。

## 后续建设

- 增加使用虚构日记数据的 Android、Windows 截图和操作演示。
- 手机端提供开源许可证入口，桌面端提供可访问的第三方声明。
- 为 Windows 配置代码签名，在发布流程中核验实际签名状态。
- 在隔离数据目录完善 GUI 验收与跨端同步升级测试。

这些事项尚未完成，不列为现有发布能力。分支保护可在贡献流程稳定后设置必需检查；增加保护前先确认本机发布和维护流程仍可执行。
