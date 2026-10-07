# 依赖安全快照

日期：2026-10-07。依据本仓库 GitHub Dependabot API、`desktop/package.json`、`desktop/pnpm-lock.yaml`、已安装依赖元数据和上游公告进行只读审查。本文件记录待处理风险，未升级依赖、合并 PR、执行漏洞复现或验证修复效果。

当前共有 **19 条 open 告警：12 high、3 medium、4 low、0 critical**，全部来自桌面端 npm 依赖，涉及 **7 个包、13 个独立 advisory**。Electron 的 6 个 advisory 同时出现在 package.json 与锁文件，因此各计两条；19 条告警不代表 19 个不同漏洞。

Dependabot 将 5 条标为 `runtime`、14 条标为 `development`。其中 Electron 虽写在 devDependencies，仍作为已发布应用的运行时分发，必须按生产风险处理。其余开发工具依赖也会影响构建机和 CI，不能据 scope 判定安全。没有移动端或服务端告警不代表这两个部分已完成安全审计。

## 告警明细

下表的“修复版本”是本次 API 返回的 `first_patched_version`，不是已经安装的版本；`—` 表示公告未登记修复版本。Electron 行对应的第一个编号在 `desktop/package.json`，第二个在 `desktop/pnpm-lock.yaml`；其余均在锁文件。Electron、http-cache-semantics、sprintf-js 的 API scope 为 development，其余为 runtime。

| 告警编号 | 包与锁定版本 | 级别 | 本条受影响区间 | 修复版本 | GHSA / CVE |
| --- | --- | --- | --- | --- | --- |
| #1、#8 | electron 40.10.6 | high | `>=40.0.0-alpha.1, <41.10.3` | 41.10.3 | [GHSA-9f4c-93c8-jc8g](https://github.com/electron/electron/security/advisories/GHSA-9f4c-93c8-jc8g) / CVE-2026-70608 |
| #2、#9 | electron 40.10.6 | high | `<41.10.6` | 41.10.6 | [GHSA-9qh4-3jw8-366w](https://github.com/electron/electron/security/advisories/GHSA-9qh4-3jw8-366w) / CVE-2026-102676 |
| #3、#10 | electron 40.10.6 | high | `<41.10.6` | 41.10.6 | [GHSA-j84w-jfhq-vhvj](https://github.com/electron/electron/security/advisories/GHSA-j84w-jfhq-vhvj) / CVE-2026-102675 |
| #4、#11 | electron 40.10.6 | high | `<41.10.6` | 41.10.6 | [GHSA-gr2m-v5gq-v685](https://github.com/electron/electron/security/advisories/GHSA-gr2m-v5gq-v685) / CVE-2026-102674 |
| #5、#12 | electron 40.10.6 | high | `<41.10.4` | 41.10.4 | [GHSA-hq2x-r82h-9wj4](https://github.com/electron/electron/security/advisories/GHSA-hq2x-r82h-9wj4) / CVE-2026-102673 |
| #6、#13 | electron 40.10.6 | medium | `>=40.0.0-alpha.1, <41.10.5` | 41.10.5 | [GHSA-vv43-5jgx-7qv8](https://github.com/electron/electron/security/advisories/GHSA-vv43-5jgx-7qv8) / CVE-2026-102672 |
| #7 | quill 2.0.3 | low | `=2.0.3` | — | [GHSA-v3m3-f69x-jf25](https://github.com/advisories/GHSA-v3m3-f69x-jf25) / CVE-2025-15056 |
| #14 | dompurify 3.4.15 | low | `>=3.4.13, <=3.4.15` | 3.4.16 | [GHSA-p98j-92pf-mc4p](https://github.com/cure53/DOMPurify/security/advisories/GHSA-p98j-92pf-mc4p) / 未分配 CVE |
| #15 | http-cache-semantics 4.2.0 | high | `<=4.2.0` | — | [GHSA-ch52-4w7c-c8xp](https://github.com/advisories/GHSA-ch52-4w7c-c8xp) / CVE-2026-93748 |
| #16 | source-map-js 1.2.1 | high | `>=1.0.0, <1.2.2` | 1.2.2 | [GHSA-68fv-2mgg-jv7q](https://github.com/advisories/GHSA-68fv-2mgg-jv7q) / CVE-2026-93749 |
| #17 | katex 0.16.47、0.18.7 | low | `>=0.11.0, <0.18.2` | 0.18.2 | [GHSA-238p-pmpm-9mq7](https://github.com/KaTeX/KaTeX/security/advisories/GHSA-238p-pmpm-9mq7) / CVE-2026-103923 |
| #18 | dompurify 3.4.15 | low | `<=3.4.15` | 3.4.16 | [GHSA-6688-9rhm-gjv2](https://github.com/cure53/DOMPurify/security/advisories/GHSA-6688-9rhm-gjv2) / 未分配 CVE |
| #19 | sprintf-js 1.1.3 | medium | `<=1.1.3` | — | [GHSA-hp3w-g68c-fv3c](https://github.com/advisories/GHSA-hp3w-g68c-fv3c) / CVE-2026-97058 |

## 最小升级路径与范围

- **兼容补丁可处理 3 条告警**：DOMPurify 3.4.15 → 3.4.16 处理 #14、#18，其父包 @milkdown/components、@milkdown/crepe 的范围为 `^3.2.5`；source-map-js 1.2.1 → 1.2.2 处理 #16，其父包 @vue/compiler-core、@vue/compiler-sfc、postcss 的范围为 `^1.2.1`。应检查锁文件中所有副本，并验证编辑器、粘贴及生产构建；source-map-js 的[上游 1.2.2 发布记录](https://github.com/7rulnik/source-map-js/releases/tag/v1.2.2)给出了修复依据。
- **Electron 的 12 条需要主版本升级**：覆盖本次 6 个 advisory 的最小共同目标为 41.10.6，超出当前 `^40.0.0`。公告没有列出修复全部问题的 40.x 版本。应单独审查 Electron 41 的行为变化，验证窗口、IPC、存储、编辑器、同步及安装更新后再发布。
- **KaTeX 的 1 条超出父包兼容范围**：@milkdown/crepe 使用的 0.18.7 已超出受影响区间；告警来自 micromark-extension-math 3.1.0 → katex 0.16.47。后者的依赖范围为 `^0.16.0`，无法通过普通锁文件刷新取得 0.18.2。应等待或评估父包升级；若采用 override，必须验证公式语法、渲染与编辑器兼容性，不能只保留另一个新副本。
- **Quill、sprintf-js 共 2 条暂无公告修复版**：本次 registry 检查的最新版本仍为 2.0.3、1.1.3。分别跟踪 HTML 导出与格式化字符串的实际输入路径，评估移除、替换或受控补丁；不要降级到公告没有列出的旧版本就认定已修复。
- **http-cache-semantics 的 1 条存在上游争议**：父包 cacheable-request 使用 `^4.0.0`，可兼容升级到已发布的 4.3.0，但 GHSA 仍登记修复版为空。维护者在[官方 issue #56 的回复](https://github.com/kornelski/http-cache-semantics/issues/56#issuecomment-5975759591)中反对该报告的缓存语义解释；4.3.0 包含的是[另一项 Vary 匹配修复](https://github.com/kornelski/http-cache-semantics/commit/9fb520be70eff3ff502fe965d9c3265ca2c64e26)。不能仅因 4.3.0 移出告警区间就宣称本条漏洞已修复，也不能仅据争议关闭告警。

## 已检查的调用边界

- 桌面主窗口和快速记录窗口设置了 `contextIsolation: true`、`nodeIntegration: false`。应用源码未发现 webview、Web Worker Node integration、自定义 File/HTTP protocol handler、`window.open` 或 sandbox iframe 的使用。这限制了当前可见的 Electron 公告触发路径，但没有证明所有导入、粘贴及渲染内容都无法触发问题。macOS Squirrel 更新竞争条件公告与目前发布的 Windows 安装包平台不同，仍保留依赖升级事项。
- Quill 编辑器保存和读取 Delta，当前应用源码未发现 `getSemanticHTML` 或 HTML 导出调用，因此未识别到公告所述导出触发路径；这不是对全部编辑器输入的安全保证。
- 应用源码未发现 DOMPurify 的直接调用或 `IN_PLACE` 配置；它由 Milkdown 引入，仍需检查第三方调用与输入来源。KaTeX 公告要求既有原型污染或可控 options 原型等前提，当前只做依赖和调用检索，未验证这些前提是否可达。
- http-cache-semantics 由 cacheable-request 引入，sprintf-js 由 roarr 引入，均属于开发依赖图。构建下载、缓存和日志输入仍应纳入后续审查。

## 后续验收

修复应先提交独立、可审查的依赖变更，运行现有测试与构建，再完成 Windows 窗口、输入、编辑、同步、数据保留和覆盖安装验收。不要自动合并 Dependabot PR，也不要仅为降低告警数量关闭未解决项。

锁文件更新不会修复已经下载的安装包。完成验证后使用新的桌面版本和 tag 重新构建、核对 SHA-256 并发布；保留已发布版本的原资产。此快照不会自动随 GitHub 公告或依赖版本变化更新。

## 首次 CodeQL 扫描

2026-10-07 对提交 `8b4c224` 的 JavaScript / TypeScript 扫描成功完成，并产生 [CodeQL 告警 #1](https://github.com/zhongshuyi/diary/security/code-scanning/1)：`js/clear-text-storage-of-sensitive-data`，级别 high，位置为 `desktop/src/renderer/main.jsx:145`。它提示经纬度随日记写入明文 `localStorage`，不是依赖告警，也不是对数据已泄露的确认。

此路径位于 `previewDb.saveEntry`；`db()` 在缺少 Electron preload 提供的 `diaryAPI.db` 时使用该预览数据库。打包桌面应用通常通过 IPC 使用 SQLite。预览分支仍可能承载实际输入，不能只因名称包含 preview 就忽略提示；演示使用虚构数据，并单独评估预览入口、敏感字段和持久化策略。当前未修改存储机制，也未关闭告警。本地数据未进行应用层加密的事实同时在[隐私说明](../PRIVACY.md)中记录。
