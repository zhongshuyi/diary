# 安全漏洞报告

发现可能影响日记隐私、访问控制或数据安全的问题时，请通过 [GitHub 私有漏洞报告](https://github.com/zhongshuyi/diary/security/advisories/new)提交，避免在公开 Issue 或 PR 中披露可利用的细节。普通功能问题请使用缺陷报告模板。

报告中请说明受影响的平台、版本或 commit SHA、问题影响及最小复现步骤。使用虚构数据复现，日志和截图先脱敏；不要提交真实访问令牌、服务器 IP 或私人日记内容。可以附上修复建议。

后续讨论在该私有报告中进行。若私有报告入口暂时不可用，请暂缓公开披露漏洞细节。

## 验证范围

维护优先面向仓库 `main` 与当前公开版本，不承诺旧版本补丁的响应时限。日记、备份、权限和联网方式见[数据与隐私说明](PRIVACY.md)。

CodeQL 检查 JavaScript / TypeScript，Dart 仍依赖代码审查和 Flutter 测试。Dependabot 的漏洞提醒与安全更新已启用；修复 PR 需要审查和验证，不自动合并。GitHub 秘密扫描及 push protection 已启用，但不能识别所有私有配置，发布前仍需核验产物。仓库检查与依赖告警处理见[维护说明](docs/maintenance.md)。
