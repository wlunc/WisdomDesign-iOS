# CONTRIBUTING.md · WisdomUI（iOS）

> 本文件是"怎么在这个仓里安全地改东西"的索引，**不复制规格正文**。
> 判据真源 = [docs/SPEC.md](docs/SPEC.md)（实现与验收）；顺序与出口 = [docs/DEV-PLAN.md](docs/DEV-PLAN.md)；禁止项完整清单 = [AGENTS.md](AGENTS.md) §10；冲突时按 AGENTS.md §2 的效力链。

## 0. 三条硬前提

1. **门禁 = `xcodebuild` + 模拟器**。host 侧的 SwiftPM 命令**不是**门禁，也不要拿它"本地先看一眼"——本包只声明 `.iOS(.v17)`，host 编译必然失败（218 错）。一步版：`Scripts/ci.sh pr`。
2. **不要手改生成物**：`Sources/WisdomUI/Foundation/Generated/**` 只允许 `../wisdomdesign/tools/token-build/build.js` 写（R12 校验文件头 banner）。要改令牌 → 改设计仓的 `tokens/wisdom.tokens.json`，再跑生成器。
3. **不要跨仓写**：`../android/**`、`../wisdomdesign/**` 一律只读。跨仓一致性靠**变更集**（三仓同一标识），不靠手改。

## 1. 环境

| 项 | 要求 |
| --- | --- |
| Xcode | **≥ 26**（`glassEffect` 需 SDK 26） |
| 语言模式 | Swift 6（`Package.swift` 已钉死；不要为过编译降级） |
| 脚本依赖 | **`python3`**（`Scripts/ci.sh` 解析模拟器 UDID 与结果包）；`node` 只在跑设计仓生成器时需要 |
| 平台 | 只声明 iOS，**不加 macOS** |

自检：`Scripts/ci.sh doctor`（打印工具链 / scheme / destination / 缓存落点，不编译）。

## 2. 提交信息与分支

**Conventional Commits**：`<type>(<scope>): <summary>`

- `type` ∈ {feat, fix, perf, refactor, style, test, build, ci, docs, chore}
- `scope` ∈ {foundation, tokens, typography, theme, motion, material, a11y, icons, internal, previews, ci, docs, examples, primitives/<Component>, composites/<Component>}

**三条 iOS 特有纪律**：

1. **纯移动与语义变化拆两个提交**——第一个只搬迁（`api/WisdomUI.api.json` 规范化后应零差异），第二个再做语义变化；
2. **符号快照与成因同提交**——`api/WisdomUI.api.json` 不得跨提交漂移；
3. **令牌变更集**——一次令牌改动 = 一个跨仓变更集，提交信息携带同一标识（如 `tokens: v1.0.0-rc.1`），三仓可 grep 对齐。

**分支与合并**：`main` 受保护（禁直推、禁 force-push）；用短命分支（`feat/wdbutton`、`tokens/v1.0.0-rc.1`），生命周期 ≤ 5 天；**跨层移动 / API 冻结类 PR 用 rebase-merge**（保留两个提交），其余 squash-merge（提交信息取 PR 标题）。

> 【未实现】`Scripts/check-commit.sh`（SPEC §1.4 的 E4 采纳项，用于机器校验提交信息格式）**不在 M0 的 11 项里**，当前由评审把关；补实现前不要在 CI 里引用它。

## 3. 提交前必跑

```bash
Scripts/ci.sh pr        # PR-0 规则+格式 → PR-1 模拟器编译+单测 → PR-2 API 冻结 → 覆盖率
```

- **未绿不 PR**。失败时脚本会把对应日志的尾部打到 stderr（日志全量在 `.build/logs/`）。
- 改了**文档**（本仓任一份 `.md`）另过 [docs/DEV-PLAN.md](docs/DEV-PLAN.md) §4.6 的**六个固定项 + 两条纪律**（禁止自命中 / 双跑）。
- 改了 `Package.swift`、`Scripts/**`、`.swift-format` 或 `api/**` 时，PR 需 ios-lead 评审（见下）。

## 4. 评审要求

| 触及 | 需要谁 |
| --- | --- |
| 任意改动 | ≥ 1 名 reviewer |
| `Sources/WisdomUI/Foundation/**`、公开签名、`Package.swift`、`api/*` | + `ios-lead` |
| **U 系列**（令牌名/枚举 case/槽位名/默认值/行盒语义/状态优先级/触控数值/无障碍行为/玻璃档位/动效令牌/生成物溯源） | + `android-lead` **与** `tech-lead` 确认 |
| F 系列 | 在 `contracts/README.md` 的"两端形态"表登记 |

**豁免**：检查器豁免必须**同行给理由**（`// wd-structure-check:disable R7 — 理由`）；reviewer 按"豁免必须有理由"审。**不要**通过放宽规则或改规格文本来绕过。

## 5. 不能自行决定的事（先登记，再改）

- 触及**令牌、契约、公开签名、设计口径** ⇒ 走 [docs/DEV-PLAN.md](docs/DEV-PLAN.md) §9 的真源流程 + §6 的回写清单（P 项）：**先登记"文件:行号 + owner + 时点"，再按登记范围执行**；执行者不得顺手改登记外的口径。
- 设计侧待给值按 [docs/DEV-PLAN.md](docs/DEV-PLAN.md) §7 的**默认执行项先冻结**，**不得自定值**。
- 未跑通/未实测的项只能写**【未验证】**（§8.1），**不得**在代码注释、README、CHANGELOG、PR 描述里写成"已通过"。
