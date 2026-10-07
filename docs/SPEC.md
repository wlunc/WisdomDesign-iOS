# 02 · iOS 实现规格（收敛稿）：工程基建、组件 API 与实现细节、主题样式与交互

---

**迁移说明与外部引用映射（t78 加；本段是新增内容，正文一字未改，仅清理了指向已退役目录的路径字面量）**

> **来源**：本文件原为**跨端工作区文档集（已退役）**中的 iOS 规格 `02-ios-spec.md`（1,510 行 / 约 171 KB）。该工作区文档集在规格定稿后整体退役，内容按端迁入各自仓库：**本端 = 本文件**，Android 侧 = 同批迁移的 `android/docs/SPEC.md`。
> **为什么原目录字面量不在此出现**：本文件的验收判据之一是"指向已退役目录的路径引用 = 0"。若在本段复写原路径，会让判据被自身文本触发（**自命中**）——因此按描述式引用处理，详见本仓 `DEV-PLAN.md` §4.6 的两条纪律。
> **导航（t83 补）**：以上是迁移说明（保留不动）；**正文起点 = 紧随其后的 `> 任务：` 元信息与 `## 0. 收敛摘要`**，正文未重排、未改写。
> **退役计划简写对照（t83 补）**：正文历史记录里的"开发计划 §5.9 / §5.10""`30-dev-plan.md` §5.8"等简写 ⇒ 本仓等价物 = **`DEV-PLAN.md` §6（回写项）/ §7（设计待给值）/ §5.1（口径）**；`30-dev-plan.md` 即本仓 `DEV-PLAN.md` 的前身。
> **迁移原则**：① **正文逐字保留**（含当时的证据标记 `[实测]` / `[组长实测]` / `[SDK]` 与"待实测/待回填"表述）；② 只做两件事 —— **清理指向已退役目录的路径字面量**（两处目录前缀被去除、文件名保留；原字面量**不在此复写**，以免判据自命中）、**登记外部数字代号**（下表）；③ **源文件只读、未被改动**。
> **过时内容声明（重要）**：正文引用的 `40 §1`（受控值名唯一表）中，**#06 `WDCheckbox` 的 iOS 参数名是改名前的旧名**；**本仓最终名以 `DEV-PLAN.md` §5.3 为准 = `isChecked`**（C-15 结论：iOS 侧仅此 1 行改名）。凡"正文旧、结论新"的差异，**一律以本仓 `DEV-PLAN.md` 与 `AGENTS.md` 为准**；本文件不就地改写旧句，以免制造第二份真源。

**外部数字代号对照表**（正文里的 `NN` 一律按本表解读；"本仓等价物"一律给章节号，不给行号）

| 代号 | 原来是什么（跨端工作区，**除注明外均已退役**） | 可执行结论现在在本仓的哪里 |
| --- | --- | --- |
| `00` | iOS 实现草案（初稿） | 结论已被本文与本仓 `DEV-PLAN.md` §1–§3 吸收；草案本身不再维护 |
| `01` | ① iOS 组长首轮质询/裁决（`01-ios-review.md`，已退役）；② **设计真源** `01-foundation.md`（**未退役**） | ① → 本仓 `AGENTS.md` §5 冻结值、§6.1 待给值；② → 设计仓 `../wisdomdesign/docs/01-foundation.md`（其玻璃六档结论已内联本仓 `AGENTS.md` §12.1） |
| `02` | ① **本文件**（iOS 规格）；② **设计真源** `02-components.md`（**未退役**） | ① → 本文件；② → `../wisdomdesign/docs/02-components.md` |
| `03` | ① iOS 默认值表（`03-ios-defaults-table.md`，已退役）；② 设计真源 `03-platform-mapping.md`（**未退役**） | ① → 本仓 `DEV-PLAN.md` §5（冻结值与口径）；② → `../wisdomdesign/docs/03-platform-mapping.md` |
| `04` | 设计真源 `04-architecture.md`（**未退役**，`WD` 前缀与分层出处） | `../wisdomdesign/docs/04-architecture.md`；本端分层与依赖见 `ARCHITECTURE.md` §1 |
| `05` | 设计真源 `05-preview-and-theme.md`（**未退役**，预览与主题） | `../wisdomdesign/docs/05-preview-and-theme.md`；本端主题数据流见 `ARCHITECTURE.md` §3–§4 |
| `06` | 设计真源 `06-accessibility.md`（**未退役**，无障碍与对比度门槛） | `../wisdomdesign/docs/06-accessibility.md`；**已内联**本仓 `AGENTS.md` §12.3（4.5:1 / 3:1 + "最不利"取色）与 `DEV-PLAN.md` §5.2 |
| `07` | 跨端裁决摘要（U1–U14 / F1–F20 / 目录终稿 / 路线图与门禁；**已退役**）。注：设计仓另有一份同号 `07-content.md`（未退役） | 跨端结论 → 本仓 `DEV-PLAN.md` §1、§5 与 `AGENTS.md` §2/§3.2；设计侧 → `../wisdomdesign/docs/07-content.md` |
| `08` | 用户决策（U1–U10 + 八条硬约束；**已退役**）。注：设计仓另有同号 `08-icons.md`（未退役） | 决策口径 → 本仓 `AGENTS.md` §2（效力链）、§10（反模式），`DEV-PLAN.md` §1/§10；设计侧 → `../wisdomdesign/docs/08-icons.md`（图标语义名 44 条见 `AGENTS.md` F-07） |
| `09` | 设计真源 `09-layout.md`（**未退役**，行高与热区） | `../wisdomdesign/docs/09-layout.md`；本端口径（iOS 44 / Android 布局盒 48 / 可见内容 44 ± 0.5）见 `DEV-PLAN.md` §5.1 与 `AGENTS.md` F-01–F-03 |
| `12` | ① Android 规格（已迁 `android/docs/SPEC.md`）；② 设计真源 `12-b22-glass.md`（**未退役**，玻璃两档等式与深色 Tab 栏裁定） | ① → `android/docs/SPEC.md`（Android 侧）；② → `../wisdomdesign/docs/12-b22-glass.md`；玻璃规则已内联 `AGENTS.md` §12.1 |
| `13` | 设计真源 `13-tint.md`（**未退役**，品牌染色） | `../wisdomdesign/docs/13-tint.md`；`tinted` 档"不作文字载体"见 `AGENTS.md` §12.1 |
| `20` | **iOS 组长评审（F21–F50 的唯一真源；F51 登记在 §3-附记）**，已退役 | 冻结值口径 → 本仓 `DEV-PLAN.md` §5.1（**F51 行距/可见内容 44±0.5**）、`AGENTS.md` §6（F-01…F-21）与 §12.4（F51 注记） |
| `21`/`23`/`25`/`27` | Android 组长评审（各轮） | Android 侧等价物：`android/docs/DEV-PLAN.md` §5/§6 |
| `22`/`24`/`26`/`28` | iOS 组长复评（r2/r3/r4/r4b；`24 §7.2` 的槽位与命名结论、`28 §5` 的真机观感项） | 结论 → 本仓 `DEV-PLAN.md` §5.3（槽位/受控值名）、§8.1（U-05 真机 `fontScale 2.0` 观感）与 `AGENTS.md` §6 |
| `30` | 跨端开发总计划（里程碑/批次/命令/冻结值/回写清单/待给值） | **整体等价物 = 本仓 `DEV-PLAN.md`**（§2 里程碑、§3 批次、§4 命令与门禁、§5 冻结值、§6 回写项、§7 设计待给值、§8 风险与未验证） |
| `31`/`32`/`33`/`34` | 计划评审（各轮） | 结论已并入 `DEV-PLAN.md` §2–§4；本表不再逐条追溯 |
| `40` | **C-15 受控值名唯一表（37 行）** | **已内联 = 本仓 `DEV-PLAN.md` §5.3**（含改名台账：#06 = `isChecked` 为准）；命名规则见 `AGENTS.md` F-14/F-19/F-20 |
| `60`/`61`/`62` | 仓内文档复核（首轮/跨端交叉复核，含 XR-xx） | 处置结果 → `AGENTS.md` §8（差异表 D-01…D-06）、`DEV-PLAN.md` §6 |
| `63` | 设计侧仓内文档核对（DF-01…DF-18） | **已落地** → `AGENTS.md` §6.1（设计待给值入口）与 §12（DF-02/03/04 条文） |
| `64`/`65`/`69`/`70` | 仓内文档终审（各端 r2 复核） | 处置结果 → `AGENTS.md` §8/§12、`DEV-PLAN.md` §6 |
| `66`/`67`/`68` | 规格回写审计 / M3 出口修复评审 | 回写纪律 → `DEV-PLAN.md` §6 与 §4.6（文档改动纪律） |
| `71`/`73`/`72` | 开发计划评审（iOS/Android，各轮） | 修复结果 → `DEV-PLAN.md` §5.3 改名台账、§4.4 可用性说明、§12 验证记录 |
| `76` | **不是文档代号**（正文里是 `WDListRow` 的"三行 76"高度） | 尺寸口径见 `DEV-PLAN.md` §5.1（行高档位） |

**非文档代号（勿与本表混用）**：正文中的 2 位数还大量用于**尺寸与计数** —— 高度 `44`/`46`/`60`/`76`、色槽 `32`、组件数 `37`、清单行数 `21`、令牌档位与条目号（`F16`/`F47`/`R18`/`U5`/`AR-67`/`N-7`/`V-11` 等）。**这些不是文档代号**，不需要映射；其权威口径分别在本仓 `DEV-PLAN.md` §5、`AGENTS.md` §6/§7、`ARCHITECTURE.md` §12。

**本文件与仓内另三份文档的分工**：本文件 = **实现细节的唯一出处**（工程基建 / 组件 API / 主题样式交互）；`DEV-PLAN.md` = 进程与冻结值（做什么、什么顺序、什么算过）；`AGENTS.md` = agent 施工手册（入口/禁止项/升级路径）；`ARCHITECTURE.md` = 结构与数据流（8 张图 + ADR）。四者冲突时按 `AGENTS.md` §2 的裁决链。

---


> 任务：`t5 [ios-spec]` ｜ 作者：**ios-dev**（iOS 技术开发）｜ attempt：`218cdf8d-31d6-480b-b9c0-a8974c93918b`
> 上位法顺序：`08-decisions.md`（U1–U10 + §2 的 8 条硬约束）＞ `07-summary.md`（§1 U/F 边界线、§5 目录终稿、§6 路线图）＞ `01-ios-review.md`（iOS 组长质询的 7+1 blocker / 14 high / §5 裁决）＞ `00-ios-draft.md`（初稿）＞ `06-cross-review-ios.md` ＞ `01-ios.md`。
> 本文性质：**可直接开工的最终规格**。凡与 `00-ios-draft.md` 冲突，以本文为准；凡本文未改的草案结论，**表示已被 `01-ios-review.md` ratify 或接受**。
> 证据口径：`[实测]` = 我在 t1 亲自跑过并贴了输出（见 `00-ios-draft.md` §8.1 与本文 §9）；`[组长实测]` = `01-ios-review.md` §7 的证据（含 `swiftc` 类型检查、`simctl list`、`swift-format dump-configuration`、字体自然行高复算）；`[SDK]` = SDK `*.swiftinterface`/`*.h` 声明行（含 `01-ios-review.md` §7-9 已修正的**框架归属**）；`[读取]` = 仓内字面值；**【待实测】** = 尚未跑通，不得在下游写成结论。
> **验证声明**：本轮我**无法运行 `xcodebuild`**（沙箱不允许写 `~/Library`；`01-ios-review.md` §7-5 已把真实失败点定位到 SwiftPM manifest 缓存）。因此本文所有命令是**可执行形态**，其真实耗时/通过状态标 **【待实测】**，并按 `01-ios-review.md` §2.2 的要求**未测之前不写成"预算"**。
> **范围纪律**：本轮只写本文件；`iOS/`、`android/`、`wisdomdesign/` 与跨端工作区文档集（**已退役**）零改动（§9 给证据）。

---

## 0. 收敛摘要：blocker 处置与本轮相对草案的变更

### 0.1 7 个 blocker + 1 条命名的处置（全部采纳，落点下节）

| # | blocker | 处置 | 落点 |
| --- | --- | --- | --- |
| **B1** | 6 处公开类型声明不可合成的 `Hashable`/`Equatable`（`Text` 非 `Hashable`、`SubmitLabel` 连 `Equatable` 都没有） | **采纳**：槽位/辅助枚举一律 `Sendable, Equatable`；`WDTextFieldAppearance` 只 `Sendable`；`WDActionSheetItem` 用 `Identifiable, Sendable, Equatable`；新增 **R17** 机器规则 | §2.2、§2.3、§2.7 |
| **B2** | L-B 违规两处：`WDSemantics.label/contextual` 内置全角逗号与语序；`closeButtonAccessibilityLabel` 缺省推导"关闭{标题}" | **采纳**：`WDSemantics` 只留 `join(_:separator:)`/`positional(label:positionText:separator:)` + `[String]` 纯逻辑重载；关闭标签**必填**；新增 **R15**（标点/词序字面量 error） | §2.6、§3.6、§5.5 |
| **B3** | `onDismissAttempt`（"意图"）在 iOS 不可实现（`.sheet` 无遮罩回调） | **采纳**：改 `interactiveDismissDisabled: Bool` + `onCloseButtonTap` + `onDismiss`；"意图"不可达登记为 **F29** | §2.5、§4 |
| **B4** | M0 令牌/契约一次性冻结清单不全（46 / 把手几何 / detent / max-width / `motion.duration.reduced` / `state.*` / `letterSpacing` 单位） | **采纳**：给出**完整冻结清单**，并逐条标注"落令牌"还是"落 F 系列两端同值表"（二选一，不悬空） | §1.4、§6.1 |
| **B5** | 契约读取与跨仓自证机制缺失（YAML / 路径 / 同批证明） | **采纳**：`contracts/dist/*.json` 镜像 + `WDContracts.locate()` + `tokens.manifest.json` 跨仓自证 | §1.5.4、§9.1 |
| **B6** | 门禁 destination/scheme 不可执行（`iPhone 16` 不存在；取"第一个 scheme"是错的） | **采纳**：`ci.sh` 按 UDID 解析 destination、scheme 固化、**PR 只编模拟器一张图**、设备构建移到 nightly、覆盖率补 `-resultBundlePath` | §1.5 |
| **B7** | 行盒不可达（`.lineSpacing` 只影响行间）+ 中文下"默认档 = 设计值 ±0.5pt"12 条字阶全不成立 | **采纳**：新增 `wdLineBox(_:lines:)` 让盒高成为几何事实；U5 断言改为**带容差的 `max` 形式** + 分语种 fixture；新增 **R21** | §2.6.3、§6.1-2、§8 |
| **B7b** | `WDSheet` vs `WDBottomSheet` 的 U1 命名冲突（Android 草案已实际使用 `WDSheet`） | **采纳**：`WDBottomSheet` 为唯一真源，**不得出现 `WDSheet`（含 typealias）**；类型名清单进 contracts + 两端集合断言 | §2.5、§6.2、§7-CR4 |

### 0.2 本轮相对 `00-ios-draft.md` 的**变更清单**（只列会改签名/命令/契约的）

| 类别 | 变更 | 章节 |
| --- | --- | --- |
| 签名 | `WDTextStyle` 存储字段收敛为 4 个（`textStyle`/`lineHeightRatio` 改为手写计算属性，`init` 改 `internal`） | §2.1 |
| 签名 | `WDSemantics` 重写（零标点/零语序），`WDAnnouncing` 改 `@MainActor`，新增 `WDA11yFocusID` | §2.6、§3.6 |
| 签名 | `WDBottomSheet` → `.wdSheet(...)` **修饰符 + 锚点**形态 + 可实现回调；`WDActionSheet` 保留数据配置类型 | §2.5 |
| 签名 | `WDListRow` 删 `tertiary`（8 参 → 7 参）；行高 = `max(密度下限, 槽位派生)` | §2.3 |
| 签名 | 互斥槽位枚举的 conformance 修正（去 `Hashable`）；`WDTextFieldAppearance` 只 `Sendable` | §2.2、§2.3 |
| 命令 | `Scripts/ci.sh` 全量重写（destination 按 UDID、scheme 固化、单编译图、`-resultBundlePath`） | §1.5 |
| 命令 | `Scripts/check-structure.sh` 成为**唯一**结构检查入口（插件 M0 不 attach）；新增自检样本库 | §1.1.3 |
| 命令 | `Scripts/dump-api.sh` 改为**规范化**输出 `api/WisdomUI.api.json`（丢弃 USR/location） | §1.5.3 |
| 规则 | R1 加标识符边界；R6/R7/R13/R14 先剥离注释与字符串；R13 拆 R13a/R13b；新增 R15–R21 | §1.1.3 |
| 契约 | 新增"槽位词表""组件类型名清单""JSON 镜像""token manifest""默认值对照表" | §1.4、§6.2、§9.1 |
| 验收 | U5 断言改带容差 `max` + 分语种 fixture；容器高度与文本行盒**分两张表**；性能预算按**可测性**分层 | §2.6.3、§1.5.5、§8 |
| 差异 | **F21–F50 按唯一分配表落库**（IOS-05；iOS 号不变、F23 的密度项拆为 F44；F46–F50 按 `20` §3-附记两批补记同步）；新增 F36（安全区）/F45（状态视觉机制）；D-i1 改走 U10；D-i2 降级；D-i3 移出 contracts；D-i4 并入 F27 | §4 |
| 定名（R3-01/02/03 + C-15） | 补 `WDCardStyle`/`WDToastVariant`/`WDBannerVariant` 三个枚举（**R3-01**，含默认值与归一化断言）；`WDSearchField` 补 `leadingIcon`（**R3-02**）；21 名词表加**分类副表**并指向 **F48**（**R3-03**）；`WDCheckbox` 的 `isOn` → **`isChecked`**（**C-15 #06**，iOS 侧唯一改名）；§2.10 的“受控值”列改为“**契约名 / 本端形态**” | §2.10、§2.11、§8.3 |

---

## 1. 议题一：工程基建与协作规范（最终形态）

### 1.1 模块划分与依赖方向

**层次与依赖方向（不变，`01-ios-review.md` §1.1.1-E2 已认可方向，仅修规则实现）**

| 层/目录 | 允许依赖 | 可见性 |
| --- | --- | --- |
| `Sources/WisdomUI/Foundation/`（`generated/`、`Tokens/`、`Typography/`、`Theme/`、`Layout/`、`Motion/`、`Material/`、`Accessibility/`、`Icons/`） | 仅系统框架：`SwiftUI` / `UIKit`（**限 R15 白名单目录**）/ `Accessibility` | `public` |
| `Sources/WisdomUI/Components/Primitives/`（20 个，一组件一目录、三分法文件） | `Foundation` + `Internal` | 组件 `public`，同目录内部件 `internal` |
| `Sources/WisdomUI/Components/Composites/`（17 个） | `Foundation` + `Primitives` + `Internal` | 同上 |
| `Sources/WisdomUI/Internal/` | `Foundation`，不得依赖 `Composites` | **零 `public`** |
| `Sources/WisdomUIPreviews/` | `WisdomUI` | `public`，**不进 `products`** |
| `Sources/wd-structure-check/`（host 工具） | **只 `Foundation`，不得依赖 `WisdomUI`** | — |

`Components/Patterns/` **不建**（存在即 error，R4）；`Sources/WisdomUI/Resources/` **不创建**（库内零资源，硬约束 5）。

#### 1.1.1 结构检查器：唯一入口 + 三种驱动（回答 `01-ios-review.md` §1.1.2-I01）

**唯一入口 = `iOS/Scripts/check-structure.sh`**（本地与 CI 都只认它；草案里"§1.1 用可执行 target、§1.5/PR 模板用 `swift Scripts/check-structure.swift`"的两套命令**已作废**）：

```bash
#!/usr/bin/env bash
# iOS/Scripts/check-structure.sh —— R1–R21 + 令牌溯源 + 契约清单断言
set -euo pipefail
cd "$(dirname "$0")/.."
swift build --package-path . --product wd-structure-check     # 只构建该 product，不触发 WisdomUI 的 218 错
.build/debug/wd-structure-check --root . "$@"
```

```swift
// Sources/wd-structure-check/main.swift —— 只 import Foundation（host triple = arm64-apple-macosx10.13）
// 实测约束（t1 §8.1-4）：Swift Regex（macOS 13+）不可用 ⇒ 一律 NSRegularExpression
struct Rule { let id: String; let message: String; let run: (SourceFile, LayerMap) -> [Violation] }
let rules: [Rule] = [r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13a, r13b, r14, r15, r16, r17, r18, r19, r20, r21]
```

**驱动方式（采纳 E1 的裁决）**：

| 驱动 | 何时 | 说明 |
| --- | --- | --- |
| ① `Scripts/check-structure.sh` | **M0 唯一强制入口**（PR-0，秒级） | 规则的全部实现 |
| ② `Plugins/WDStructureCheck`（build tool plugin） | **M0 不 attach 到 `WisdomUI`** | 采纳 E1：attach 会让每个消费方的构建图编译 `wd-structure-check`，而"默认静默"又使它在 Xcode GUI/消费者/`ci.sh` 中**永不触发**（成本换零生效）。`Package.swift` 不写 `plugins:`；若架构师坚持 attach，必须在 `iOS/Schemes/*.xcscheme` 的 build/test 环境变量里设 `WD_STRUCTURE_CHECK=1` 并在 README 写明"消费者构建不触发" |
| ③ 检查器自检 | `Scripts/test-checker.sh`（PR-0） | 新增：固定样本 `Scripts/Fixtures/structure/{pass,fail}/*.swift`，**R1–R21 每条至少一正例一反例**；样本仅被检查器读取，不参与包编译 |

> **连带回写（`01-ios-review.md` §1.4-I48 补的第 7 条）**：`07-summary.md:271` 树注释的"（编译期报错）"须由架构师改写为"**CI 脚本报错（插件 M0 不启用）**"，否则 M0 出口项会按"编译期"验收而落空。

#### 1.1.2 规则表 R1–R21（最终形态）

**通用实现纪律（`01-ios-review.md` §1.1.2-I02 的采纳）**：
1. **先剥离注释与字符串字面量**（`//`、`/*…*/`、`"…"`、`"""…"""`，约 40 行最小扫描器）再做 R6/R7/R13/R14/R15/R17 的匹配——否则注释里的词会被当代码；
2. **标识符边界匹配**：如 R1 的 `(?<![A-Za-z0-9_])WDIcon(?![A-Za-z0-9_])`；
3. **行内豁免语法**：`// wd-structure-check:disable <RULE> — <理由>`（理由非空才生效，reviewer 按"豁免必须同行给理由"审）。

| # | 规则 | iOS 判定（文本级 + 评论/字符串剥离） | 违反处置 |
| --- | --- | --- | --- |
| R1 | `Foundation/**` 不得出现组件类型名 | 组件名集合来自 `Components/**/<X>/` 目录名；**标识符边界**匹配（修 `WDIcon`/`WDIconName` 误报） | error |
| R2 | `Primitives/**` 只依赖 `Foundation` + `Internal` | 出现 `Composites` 目录名即 violation | error |
| R3 | `Composites/**` 只依赖 `Foundation` + `Primitives` + `Internal` | — | error |
| R4 | 不得存在 `Components/Patterns/` | 目录存在即 violation（`07-summary.md:164` 已删） | error |
| R5 | `Internal/**` 不得依赖 `Composites` | — | error |
| R6 | `Internal/**` 不得出现 `public` | 剥离注释后 `\bpublic\b` | error |
| R7 | **数值字面量必须可追溯到令牌**（扩围，I04） | `Components/**` + `Foundation/**`（白名单 `generated/`/`Tokens/`/`Internal/`/`Tests/`/`*+Previews.swift`）出现 `\b\d+(\.\d+)?\b`（豁免 `0/1/-1`、`.opacity(`、`zIndex`、`lineLimit`、数组索引、`#available` 版本号） | warning → **M3 起 error** |
| R8 | `Tests/**` 镜像被测层 | 目录形状 + `@testable import` 引用层 | error |
| R9 | 组件禁 `.frame(height:`/`.frame(width:` 绑令牌常量 | `\.frame\((height\|width):\s*WD` | error |
| R10 | `Components/**` 禁静态令牌入口 `WDColor.`/`WDType.` | 正则 + 白名单 | error |
| R11 | `Components/**` 禁 `.font(.system(`/`Font.system(`/`.font(WDType.` | 正则（必须走 `wdFont`/`wdLineBox`） | error |
| R12 | `generated/` 只允许生成器写入 | 首 2 行 banner 固定串 | error |
| **R13a** | 禁**带初始化器的** `static var`（存储型静态可变状态）与 `AnyView` | `\bstatic var\b\s*\w+\s*=`、`\bAnyView\b` | error |
| **R13b** | `static var` 仅允许出现在 `extension (ButtonStyle\|ToggleStyle\|ViewModifier) where Self == …` 的**计算型工厂**（无 `=`） | 反例：`extension ButtonStyle where Self == WDButtonStyle` 内的 `static var wdFilled { .init(...) }` **合法** | error（其余位置） |
| **R14** | `Components/**` 禁 `import UIKit` | `^import UIKit` | error |
| **R15** | **L-B 机器化**：`Sources/WisdomUI/**`（白名单 `generated/`/`Tests/`/`*+Previews.swift`/`Internal/` 的日志）出现标点字符（`，。、；：！？,.;:!?`）或词序模板（`第`/`共`/`关闭`/` of `）即 violation | 采纳 §5.1/§5.5-1 | error |
| **R16** | 库不覆写平台设置：`Sources/WisdomUI/**` 禁 `.preferredColorScheme(`、`.environment(\.colorScheme`、`.environment(\.dynamicTypeSize` | 预览/测试/demo 白名单 | error |
| **R17** | 公开类型若含 `Text`/`Label`/`SubmitLabel` 存储字段，**不得声明 `Hashable`** | B1 的防复发（`Hashable` 亦可软提示 `Equatable` 冗余） | error |
| **R18** | `Components/**` 禁写 Environment：`.environment(`、`\.wdDensity =`、`\.wdEffectsBudget =` | 写入口只允许 `Foundation/Theme/WDEnvironment.swift` 的 `View` 修饰符 | error |
| **R19** | 只允许 `WDColorOverrides`/`WDGradientOverrides`/`WDMaterialOverrides` 三类 `*Overrides` 类型 | 防"槽位覆盖"扩大成"万主题" | error |
| **R20** | 公开协议不得既 `Sendable` 又要求 `@MainActor` 实现 | 检查器只能软提示（`warning`），主靠 §1.2 的**隔离注解表** + 单测 | warning |
| **R21** | **文本容器必须有令牌 `minHeight`**：`Components/**` 里出现 `Text` 的最近容器缺少 `minHeight:` 令牌或 `.wdLineBox(...)` | §2.6.3/F3.4 的连带硬约束 | warning → **M3 起 error** |
| R1–R21 通用 | 白名单目录：`generated/`、`Tokens/`、`Internal/`、`Tests/`、`*+Previews.swift` | — | — |

> **R7 的服务对象**：它把草案里会"静默变成 iOS 专属魔数"的 5 类值挡在门外，并强制它们进令牌或进 F 系列登记表（见 §1.4 的冻结清单）：`WDBottomSheet` 的 `.fraction(0.5)/.fraction(0.92)`、密度行高 60/44、状态视觉值 98%/96%/32%/40%、Reduce Motion 的 150ms、`maxWidth: 480`。
> **R15/R21/R7 的升级路径**：M0–M2 为 `warning`（打印但不拦），**M3 起转 `error`**（与 §1.5.5 的覆盖率转门槛同一时点）。

### 1.2 构建与包管理

**`Package.swift` 终态（签名级；采纳 I06/I07/I08）**

```swift
// swift-tools-version: 6.1
let package = Package(
    name: "WisdomDesign-iOS",
    platforms: [.iOS(.v17)],                                     // 不加 macOS（01-ios.md §8.2）
    products: [.library(name: "WisdomUI", targets: ["WisdomUI"])],// 发布面只有 1 个
    targets: [
        .target(name: "WisdomUI", path: "Sources/WisdomUI",
                swiftSettings: [
                    .define("WD_PREVIEWS", .when(configuration: .debug)),
                    .swiftLanguageMode(.v6),                     // I06：显式钉死 Swift 6 语言模式
                ]),                                              // 不写 plugins:（E1）
        .target(name: "WisdomUIPreviews", dependencies: ["WisdomUI"], path: "Sources/WisdomUIPreviews"),
        .executableTarget(name: "wd-structure-check", path: "Sources/wd-structure-check"),   // 不依赖 WisdomUI（I19）
        .plugin(name: "WDStructureCheck", capability: .buildTool(), dependencies: ["wd-structure-check"]),
        .testTarget(name: "WisdomUITests", dependencies: ["WisdomUI"], path: "Tests/WisdomUITests"),
        .testTarget(name: "WisdomUISnapshotTests", dependencies: ["WisdomUI", "WisdomUIPreviews"],
                    path: "Tests/WisdomUISnapshotTests", resources: [.copy("Baselines")]),
    ],
    swiftLanguageModes: [.v6]                                    // 双保险：语言模式在包级也显式声明
)
```

**三条纪律**：
1. **测试 target 依赖分离**（I08）：`WisdomUITests` 只依赖 `WisdomUI`（逻辑/度量/语义/契约），`WisdomUISnapshotTests` 才依赖 `WisdomUIPreviews`——避免"快照测试顺带编译 37 个预览"的成本；
2. **host 工具不得依赖 `WisdomUI`**（I19）：机器检查 = `swift package show-dependencies` 的输出里 `wd-structure-check` 的下游不含 `WisdomUI`；
3. `resources:` 只出现在**测试 target**（快照基线），**主 target 永远 `resources: []`**（硬约束 5）。

#### 1.2.1 Swift 6 语言模式下的公开 API 隔离注解表（M0 冻结项，回答 I06/F1.2）

`swift-tools-version: 6.1` ⇒ 默认 Swift 6 语言模式。`[组长实测]` 的两条后果直接决定公开签名：

- `public protocol WDAnnouncing: Sendable` + `@MainActor` 实现 ⇒ **编译错误**（`#ConformanceIsolation`）；
- 协议扩展里的 `static let` ⇒ **语法错误**；非 `Sendable` 类型的静态存储属性 ⇒ 并发错误。

**隔离注解表（M0 冻结，逐条落进签名；新增公开类型必须补行）**

| 公开面 | 注解 | 理由 |
| --- | --- | --- |
| `WDAnnouncing`（播报网关） | `@MainActor public protocol WDAnnouncing { func post(_:priority:) }`（**去掉 `Sendable`**） | I40/[组长实测]；跨线程调用由调用方 `await MainActor.run` |
| `WDGlass.resolve`、`WDFontMetrics`、`WDSemantics`、`WDAnnouncementThrottle`、`WDMotion` | `public enum`/`static func`，**`Sendable` 值语义、`nonisolated`** | 纯逻辑，两端共享 fixtures |
| 组件类型（`WDButton` 等 37 个）与所有 `ViewModifier` | 隐式 `@MainActor`（`View` 协议本身） | 不额外标注 |
| 槽位/外观枚举（`WDButtonVariant`…） | `public enum X: String, CaseIterable, Sendable, Equatable`（**含 `Text` 的只到 `Equatable`**） | B1/R17 |
| 含闭包的枚举（`WDListRowSwipeAction`） | `@MainActor public enum`（闭包不进 `Equatable`） | A3 |
| `WDColorValues`/`WDTheme`/`WDAppearance`/`WDEffectsBudget` | `Sendable, Equatable`（`Hashable` 仅当**无 `Text`/闭包**且在 Environment 里需要比较时） | 主题是值类型 |
| 注入型 Environment 键 | `EnvironmentKey` + `@Entry` 风格默认值；`wdColors` **只读派生** | I24b |

#### 1.2.2 M0-11 签名冒烟（新增 M0 出口项；IOS-01 + IOS-10 采纳）

草案的四组签名在 M0 从未编译过，而 M3 才冻结公开 API ⇒ 有 2–3 个月窗口让错误签名躺在契约里（B1 即实例）。

**落地**：`Sources/WisdomUI/APISurface/WDAPISurface.swift`，整文件由 `#if WD_API_SMOKE` 包裹，**只放"当前尚未实现"的公开声明**（函数体 `fatalError()`）。**不得重复声明 M0 已存在的类型**——否则一旦开启 `WD_API_SMOKE` 就是"重复声明"编译错误（IOS-01 blocker，M0 出口③不可能达成）。

**显式排除清单（这些声明不得出现在 smoke 文件里）**：

| 已存在的声明 | 位置（`[实测]` IOS-01） |
| --- | --- |
| `public struct WDTextStyle` | `Sources/WisdomUI/Foundation/WDTokenTypes.swift:6` |
| `public struct WDShadowLayer` | 同上 `:37` |
| `public struct WDGradientSpec` | 同上 `:68` |
| `public extension View { func wdShadow(_:) }` | 同上 `:53` |
| `generated/**` 的**全部**类型（`WDColor`/`WDType`/`WDSpacing`/`WDRadius`/`WDSize`/`WDGradient`/`WDElevation`/`WDMotion` 及各 `WDTextStyle` 常量） | `Sources/WisdomUI/Foundation/generated/WDTokens.swift`（`public enum WDElevation` 在 `:186`、`public enum WDMotion` 在 `:207`） |

⇒ smoke 文件只写 **§2.2–§2.5 的组件/弹层公开声明 + §2.6.2/§3.2/§3.5 中尚未存在的主题与无障碍公开声明**（`WDButton`/`WDTextField`/`WDListRow`/`.wdSheet`/`.wdActionSheet`/`WDSemantics`/`WDAnnouncing`/`WDAppearance`/`WDGlass`/`WDMotion.Spring`），文本与本文逐字一致。

**退役规则（两条并存，M2 起逐批执行）**：
1. **删段法（默认，M2–M6）**：某组件的真实声明落地（`Sources/WisdomUI/Components/**` 编进模块）时，**在同一 PR 里删除 smoke 文件中该组件的对应段落**；PR 模板加复选框"若本 PR 落地了组件声明，已同步删除 `WDAPISurface.swift` 的对应段落，且 `WD_API_SMOKE` 仍编译通过"；
2. **升级法（可选，M3 起）**：改为对**真实模块**跑 `swift-frontend -typecheck` 的**公共面快照对比**（与 §1.5.3 的规范化符号快照合流）⇒ smoke 文件整体删除，并在 CHANGELOG 记录"签名冒烟退役"。触发条件 = §1.5.3 的 `api/WisdomUI.api.json` 已连续两批发版稳定。

**与 IOS-10 合并成同一次编译（不再单独 `xcodebuild build`）**：

```bash
# iOS/Scripts/ci.sh 的 pr 分支：一次 build-for-testing 同时产出测试 host 与签名冒烟
xcodebuild build-for-testing -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" -quiet \
  -enableCodeCoverage YES -resultBundlePath "$DD/pr.xcresult" \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'    # ← 同一次调用，IOS-10
```
纪律：`SWIFT_ACTIVE_COMPILATION_CONDITIONS` 在 **PR 分支只注入这一次**（PR-1 不再有第二次 `xcodebuild build`），§1.5.1 第 1 条纪律"PR 只编模拟器**一张**编译图"因此成立；本地/GUI 构建不带该标志，`WD_API_SMOKE` 不进 release（与 `WD_PREVIEWS` 同类纪律）。
验收：**任何签名级错误在 M0 就是编译错误**（PR-1 的一次调用里同时验证）。

#### 1.2.3 包体积口径（不变，补一条 I10）

沿用 `00-ios-draft.md` §1.2：**E3-iOS-a**（归档 Thinning 增量，相对"不引入 `WisdomUI` 的同构空壳 app"）、**E3-iOS-b**（每组件边际增量），**只报不拦 → M4 起门槛**，数值 **【待实测】**。补：**空壳基线入库** `Examples/BaselineShell/`，否则每次比较的是不同空壳。

**门槛值口径（IOS-13）**：**门槛值 = M1–M3 三次报告的 P50 + 10%（或绝对上限），由 tech-lead + 架构师在 M3 出口定并写进 `docs/versions.md`（或各仓 README）**；门槛未定之前维持"只报不拦"，**不得用【待实测】当作无门槛**。

### 1.3 代码规范

**lint/格式化选型（E3 裁决采纳）**：引入 `xcrun swift-format`（工具链自带，零第三方依赖）；**不引入 SwiftLint**（语义规则 R1–R21 它表达不了，仍要自研，两套配置无收益）。

`iOS/.swift-format`（**只显式写我们改动的键**）：

```jsonc
{
  "version": 1,
  "lineLength": 100,
  "indentation": { "spaces": 2 },
  "orderedImports": { "includeConditionalImports": true },   // I11：顶层对象，且覆盖 #if 块内的 import
  "rules": {
    "AllPublicDeclarationsHaveDocumentation": true           // 唯一需要显式开启的键（默认 false，I03）
  }
}
```

**纪律（I11 采纳）**：
1. 其余规则**沿用工具默认**；**Xcode 升级时把默认变化视作漂移**，单独一个 PR（与 REL-7 同纪律）；
2. 配置文件**没有 `exclude` 键**（`[组长实测]`）⇒ `generated/` 靠**显式文件清单**排除：

```bash
# iOS/Scripts/check-format.sh
FILES=$(git ls-files '*.swift' | grep -vE '/Foundation/[Gg]enerated/' || true)
[ -z "$FILES" ] && { echo "no swift files"; exit 0; }
xcrun swift-format lint --strict --parallel $FILES
```
3. **基线格式化提交必须早于 `api/WisdomUI.api.json` 首次入库**，否则两个巨大 diff 缠在一起不可审（E3 的建议③）。

**命名 / 文件组织 / 导入顺序 / 注释纪律**：沿用 `00-ios-draft.md` §1.3（已被 ratify），补两条：
- `AllPublicDeclarationsHaveDocumentation` 开启后 `generated/` 会大面积红 ⇒ 二选一：**生成器为每个 `public` 成员 emit `///`**（首选，与 R12 banner 同批）或用上面的显式清单排除（M0 采用后者，M1 生成器改造后切前者）；
- **`@inlinable` 视为签名级变更**（I09）：会扩大 ABI 面并让符号快照对实现细节敏感 ⇒ 只允许出现在 `Foundation/` 的纯计算属性（如 `WDTextStyle.lineHeightRatio`），PR 里逐条点名。

### 1.4 提交、分支、PR 与 Review

**提交信息 / 分支模型**：沿用 `00-ios-draft.md` §1.4（Conventional Commits + trunk-based + tag 只增不改），补两条（I13/I15）：
- **squash-merge 会压掉"纯移动 / 语义变化"两个提交的区分** ⇒ 对这两类改动要求 **rebase-merge（保留两个 commit）**，PR 模板加复选框"本 PR 需要保留提交历史（跨层移动 / API 冻结）"；
- 新增 `iOS/.github/CODEOWNERS`：`Sources/WisdomUI/Foundation/generated/**` 只能由生成器 PR 触碰（owner = `tools/token-build` 的维护者），人工改动一律拒。

**机器化的提交纪律**（E4 采纳）：`Scripts/check-commit.sh` 校验 `^[a-z]+(\([a-z0-9/-]+\))?: `；`main` 禁 force-push 由仓库分支保护 + CODEOWNERS 保证。

**PR 模板（最终版，命令与 §1.5 统一；新增 L-B 自检段）**

```markdown
## 变更类型
- [ ] feat / fix / perf / refactor / style / test / build / ci / docs / chore
- [ ] 纯移动（无语义变化）｜ [ ] 语义变化（描述里给出 public API 前后对照）
- [ ] 本 PR 需要保留提交历史（跨层移动 / API 冻结）→ 用 rebase-merge

## 跨端边界（07-summary §1）
- [ ] 未触及 U 系列（令牌名/枚举名与 case/槽位名/默认值/行盒语义/状态优先级/触控数值/无障碍行为/玻璃档位/动效令牌/生成物溯源）
- [ ] 触及 U 系列 → 已在 contracts/** 更新，附 Android 侧同步 PR/commit 链接：______
- [ ] 触及 F 系列 → 已在 contracts/README.md 的"两端形态"表登记：______

## 反模式自检（07-summary §1.4）
- [ ] 未给 iOS 组件加 `enabled:` 参数（可用性只走 `.disabled(_:)`）
- [ ] 未自造 `DragGesture` 按下态（按下只来自 `ButtonStyleConfiguration.isPressed`）
- [ ] 未造 Saver 等价物；`Components/**` 未引入静态 `WDColor.*`（R10）

## L-B 自检（08 §2.5）
- [ ] 未在库内引入任何分隔符/语序模板/状态文案（`WDSemantics` 只做结构拼接）
- [ ] 新增读屏标签参数：必填，或 `requiredWhen` 已登记

## 门禁自检（xcodebuild + 模拟器，不是 swift build/test）
- [ ] `Scripts/check-structure.sh`（R1–R21）绿
- [ ] `Scripts/check-format.sh` 绿
- [ ] `xcodebuild build-for-testing -scheme "$WD_SCHEME" -destination "$WD_SIM_ID"` 绿（含 `WD_API_SMOKE`）
- [ ] `xcodebuild test-without-building -only-testing:WisdomUITests` 绿；覆盖率报告已生成
- [ ] `Scripts/dump-api.sh` 后 `git diff --exit-code -- api/WisdomUI.api.json` 绿
- [ ] `CHANGELOG.md` 已更新（Breaking 段含迁移片段）

## 契约与无障碍
- [ ] 新组件已写 `contracts/acceptance.yaml` 条目 + `preview-cases.yaml` 用例名
- [ ] 语义槽位按 `docs/06-accessibility.md §3.3` 全表（label/value/traits/隐藏/合并/错误态）
- [ ] 播报/触觉已登记（无 / 一次 / 频控阈值），走 `announcement-cases.json`
- [ ] 容器高度/文本行盒的断言对象已写清（字段盒 / 行盒 / 组件容器是**三张表**）

## 证据
- 截图/日志/命令输出：______
```

**当前包的 SPM 形态的版本纪律**：沿用 `03-perf-release.md:262` 的令牌变更集（三仓同一标识）+ `06 DIR-4` 的"纯移动与语义变化拆两个提交"。

#### 1.4.1 M0 一次性冻结清单（B4 的完整答案）

> 规则（IOS-08 采纳；**措辞按 t38 审计 XR-04 统一（t55）**）：本表是 **本端 M0-1 清单（`02` 侧 17 行）**（iOS 侧 6 项 + 两端键形 2 项（行高**单值**、触控**双键**）+ Android 侧 3 项 + F/契约类 5 项 + **已决项 1 项**（第 17 行 `text.disabled`，用户决策 #3））；**三仓合并视图见 `30-dev-plan.md` §5.5 / §5.1**（本表与 `12` §3.1.2 的 **21 行**是**粒度不同**的两份视图——本表逐"键"，`12` 逐"值 + 决定人"，**不冲突**，真源仍只有令牌仓一处）。每行给 **旧键 → 新键 → 值 → 决定人**；每个值必须二选一——**(a) 进令牌**（`wisdomdesign/tokens/wisdom.tokens.json`，M0-1 变更集内落完）或 **(b) 进 `contracts/README.md` 的 F 系列两端同值表**。**不允许悬空**。Android 侧的 5 项（`size.row-height.{comfortable,compact}`、`touch-target-min-{ios,android}`、`motion.component.press-overlay-alpha`、`layout-break-font-scale`、`WDElevation` 出口）与其取值/决定人由 **t11** 同批供给，本表已预留行位。
> **授权来源（t55 执行）**：第 3 行的行高键形改动依据 `30-dev-plan.md` **§5.9 的 P11**（`:479`，t53 · 架构师 XR-03 登记；owner = ios-lead + 架构师；时点 = M0-1 冻结前、最迟 M2 批前签名冻结）。按 §5.9 的**回写纪律（XR-12）**：先登记 P 项、再按登记范围执行。

| # | 项 | 旧键 → 新键 | 值 | 落点（(a) 令牌 / (b) F 同值表） | 决定人 |
| --- | --- | --- | --- | --- | --- |
| 1 | 字段盒高（`WDTextField`） | （无）→ `size.field-height` | **46**（默认档；放大档 = 行盒高） | (a) | 设计 + 架构师 |
| 2 | 字段最小宽（IOS-08 补） | （无）→ `size.field-min-width` | **190**（`specs/01-basic.md:246`） | (a) | 设计 + 架构师 |
| 3 | 行高档（密度，**单值键**；t55 · P11 回写） | （无）→ `size.row-height.{comfortable,compact}` | **60 / 44（两端同值）**；**Android 的 48 是布局盒**（`Modifier.wdTouchTarget()` 的上下各 2dp 内边距，热区 = 布局盒 = 48、不覆盖相邻行），**不新增令牌键** | (a) **单值键** | 设计 + 架构师（行距差异登记 **F51**，唯一登记处 `20-ios-leader-review.md` §3-附记） |
| 4 | Sheet detent | （无）→ `size.sheet.detent.{half,large}` | **0.5 / 0.92** | (a) | 设计 + 架构师 |
| 5 | Sheet 最大宽 | （无）→ `size.sheet.max-width` | **480** | (a) | 设计 + 架构师 |
| 6 | Reduce Motion 时长 | （无）→ `motion.duration.reduced` | **150ms**（或设计确认 160ms） | (a) 新增键（I34） | 设计 + 架构师 |
| 7 | 状态视觉值（iOS） | （无）→ `state.{hover,pressed}.brightness`、`state.focus.ring-{width,alpha}`、`state.disabled.alpha` | 98% / 96% / 3pt+32% / 40%（`specs/01-basic.md:60-67`） | (a)；设计拒绝则 (b) | 设计 + 架构师 |
| 8 | Android 状态叠加（Android 项） | （无）→ `motion.component.press-overlay-alpha` | 由 **t11** 给出 | (a) 或 (b)（t11 定） | android-lead + 设计 |
| 9 | 触控 target（双键） | `size.touch-target-min`（单键）→ `size.touch-target-min-{ios,android}` | **44 / 48** | (a) 双键 | 已裁（U8） |
| 10 | 断点字号（Android 项） | （无）→ `layout-break-font-scale` | 由 **t11** 给出（1.3 中间档） | (a) 或 (b)（t11 定） | android-lead + 设计 |
| 11 | 阴影出口（Android 项） | （无）→ `WDElevation` 出口 | 与 iOS 同名档位（e0–e3） | (a) | 设计 + 架构师 |
| 12 | 把手几何 36×5、距顶 8 | （无）→ 契约项 | 36×5、距顶 8 | (b) F 系列同值表（iOS 用系统把手、几何不可定制） | 设计（登记 F27） |
| 13 | 关闭阈值 40% / 500pt/s | （无）→ 契约项 | 40% / 500pt/s | (b) F 系列（iOS 无阈值 API） | 设计（登记 F27） |
| 14 | `letterSpacing` 单位 | 值不变，**契约注单位** | `overline = 0.6`（**pt/sp 等价、不随字号缩放**） | (b) 契约注释 + 原值不动 | 设计（O-3 已判定 pt） |
| 15 | Toast 停留上限 | （无）→ 契约项 | **≥ 5000ms** | (b) 契约（`acceptance.yaml`） | tech-lead（CR-3 已裁） |
| 16 | 弹层系统转场 | （无）→ 平台差异 | 340ms/240ms **在 iOS 不适用** | (b) F21/F27 + U11 排除清单 | 设计（CR-2 加注） |
| 17 | **disabled 对比度（IOS-06，**已决**）** | （无）→ `text.disabled`（新增色槽） | **新增色槽 ⇒ U12 = 32 槽位**，两端计数断言同步（用户决策 #3） | (a) | 设计 + 架构师（**M0-1 内冻结**；色值由设计给） |

### 1.5 CI 门禁（可执行形态，回答 B6/B5）

**硬约束 7 不变**：门禁 = `xcodebuild` + 模拟器；`swift build`/`swift test` 不作门禁。

#### 1.5.1 `Scripts/ci.sh`（替换草案；真实耗时待首次跑通回填）

```bash
#!/usr/bin/env bash
# iOS/Scripts/ci.sh  —— pr / nightly / measure
set -euo pipefail
cd "$(dirname "$0")/.."
DD=.build/dd
SCHEME="${WD_SCHEME:-WisdomDesign-iOS-Package}"        # 首次跑通后固化进 README 与脚本常量，不再运行时猜（B6）
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"   # I12：glassEffect 需 Xcode ≥26

resolve_sim() {  # 按 UDID + 运行时解析，禁止按设备名硬编码（B6）；依赖 python3（见 §1.6 的运行时依赖行）
  xcrun simctl list -j devices available | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=[(rt,x) for rt,ds in d["devices"].items() if "iOS" in rt for x in ds if x.get("isAvailable")]
c.sort(key=lambda t:(t[0], t[1]["name"]))
print(c[-1][1]["udid"])'
}
DEST="${WD_SIM_ID:-platform=iOS Simulator,id=$(resolve_sim)}"
echo "scheme=$SCHEME destination=$DEST xcode=$(xcodebuild -version | head -1)"

case "${1:-pr}" in
pr)
  Scripts/check-structure.sh                      # R1–R21 + 令牌溯源 + 契约清单（host，秒级）
  Scripts/check-format.sh                         # 显式文件清单，排除 generated/
  # ★ 一次编译同时产出测试 host 与 M0-11 签名冒烟（IOS-10：不再有第二次 xcodebuild build）
  xcodebuild build-for-testing -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" -quiet \
    -enableCodeCoverage YES -resultBundlePath "$DD/pr.xcresult" \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'
  xcodebuild test-without-building -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" \
    -only-testing:WisdomUITests -test-timeouts-enabled YES -default-test-execution-time-allowance 60
  Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json
  mkdir -p .build/perf && xcrun xccov view --report --json "$DD/pr.xcresult" > .build/perf/coverage.json
  ;;
nightly)
  xcodebuild build -scheme "$SCHEME" -destination 'generic/platform=iOS' -derivedDataPath "$DD" -quiet  # 设备编译只在 nightly
  xcodebuild test  -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" -only-testing:WisdomUISnapshotTests
  ;;
measure)
  # IOS-09：零依赖时间戳（macOS 无 moreutils 的 ts；[实测] which ts 无输出）
  for i in 1 2 3; do
    Scripts/ci.sh pr | while IFS= read -r l; do printf '%s %s\n' "$(date +%H:%M:%S)" "$l"; done
  done
  # 备选（更精确）：xcodebuild -resultBundlePath + `xcrun xcresulttool get --format json` 取各阶段耗时
  ;;
esac
```

**四条纪律（I16/F2.1 采纳）**：
1. **PR 只编模拟器一张编译图**——草案的 `generic/platform=iOS`（PR-1）+ 模拟器（PR-2）是两张图，`≤90s+≤120s` 实际要乘 ~1.5–2；设备构建移到 nightly；
2. destination **按 UDID**；**金标设备**（快照/审计）另行固定并写进 `Baselines/manifest.json`；
3. scheme 名**首次跑通后固化**（候选 `WisdomDesign-iOS-Package`；不采用"取第一个 scheme"，那可能取到 `wd-structure-check`）；
4. **`-enableCodeCoverage YES -resultBundlePath`** 必须有，否则 `xccov` 没有输入（I17）。

#### 1.5.2 门禁强度表（最终）

| 层 | 内容 | 命令 | 预算 |
| --- | --- | --- | --- |
| **PR-0**（host，秒级） | R1–R21 + 令牌溯源 + 契约清单 + 格式 + 预览守卫文本检查 | `Scripts/check-structure.sh`、`Scripts/check-format.sh` | **实测（2026-10-07，n=3 中位数）：warm 1.49 s / clean 1.48 s / cold 2.16 s** |
| **PR-1**（模拟器） | **一次 `build-for-testing`**（含 `WD_API_SMOKE` 签名冒烟，IOS-10）+ 逻辑单测（`WisdomUITests`）+ 覆盖率报告 | 见 ci.sh `pr` | **实测（2026-10-07，n=3 中位数）：PR-1a 1.39 / 7.79 / 7.48 s；PR-1b 2.88 / 2.82 / 2.90 s（warm/clean/cold）**；**口径 = 单次模拟器会话**（`build-for-testing` + `test-without-building` + 冒烟），不含 nightly |
| **PR-2** | API 冻结：规范化符号快照 diff | `Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json` | 复用 PR-1 的 DerivedData；**实测：warm 1.61 / clean 1.78 / cold 45.51 s** —— cold 那 45 s 是 `swift Scripts/canonicalize-api.swift` 的**宿主模块缓存被清后重编译**（每轮都付），不是 API 逻辑变慢 |
| **nightly-1** | 设备编译（`generic/platform=iOS`）+ 六态快照 | ci.sh `nightly` | — |
| **nightly-2** | demo 无障碍审计（4 类目，`XCUITest`） | `-only-testing:WisdomUIDemoUITests` | — |
| **nightly-3**（**改口径**） | **模拟器相对量**：渲染 1 次 × N 循环的 `XCTClockMetric`/`XCTMemoryMetric`，写 `.build/perf/{date}.json` | — | §1.5.5 |
| **发布前** | **真机** hitch（`scrollDecelerationMetric`）、首帧（`XCTApplicationLaunchMetric`）、归档 Thinning 增量、tag 校验 | 真机 + `xcodebuild archive` | — |
| **过程成本** | `ci.sh measure` 各阶段耗时（PR-0/PR-1/PR-2 分别计时） | 报告，**不做质量门槛**（P-4 已裁） | `Scripts/ci.sh measure` |
| **预算回填责任（IOS-16）** | PR-0/PR-1/PR-2 各跑 3 次取中位数（cold/warm/clean 三态） | `Scripts/ci.sh measure 3 --states=warm,clean,cold` → 本表 + `iOS/README.md` | **回填责任 = ios-lead** —— **2026-10-07 已回填**（原始数据 `.build/perf/ci-measure-20261007.json`）。**合计中位数：warm 7.98 s / clean 14.46 s / cold 58.88 s**，与 AGENTS §3.2 的"PR ≤10 min / warm ≤5 min"预算比**余量充足** |

#### 1.5.3 API 冻结（B5/F1.1：规范化后入库）

原始 `swift-symbolgraph-extract` 输出**不可直接入库**：含 USR（随编译器变）、`location`（绝对路径）、`docComment`、`relationships` ⇒ Xcode 升级即全量红、PR 不可比、还会泄漏本机路径。

```bash
# iOS/Scripts/dump-api.sh
set -euo pipefail
DD=.build/dd
MOD=$(find "$DD/Build/Products" -name "WisdomUI.swiftmodule" -maxdepth 3 | head -1)
xcrun swift-symbolgraph-extract \
  -module-name WisdomUI -I "$(dirname "$MOD")" \
  -target arm64-apple-ios17.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -minimum-access-level public -output-dir .build/api-raw -pretty-print
swift Scripts/canonicalize-api.swift .build/api-raw/WisdomUI.symbols.json > api/WisdomUI.api.json
git diff --exit-code -- api/WisdomUI.api.json
```

```swift
// iOS/Scripts/canonicalize-api.swift（host 工具，只 import Foundation）
// 输出条目：{kind, path, decl, access}；按 path 排序；丢弃 usr/location/docComment/mixins/relationships/accessibility/spi
// 文件头记录 {xcodeVersion, sdkVersion, swiftVersion, target}
```
规则：**规范化器本身的变更 = API 基线重生成 = 单独一个 PR**（与 REL-7 同纪律）；基线文件名 `api/WisdomUI.api.json`（取代草案的 `api/WisdomUI.symbols.json`）。

#### 1.5.4 契约读取与跨仓自证（B5：三条机制）

1. **JSON 镜像**（零依赖下不写 YAML 解析器）：`wisdomdesign/tools/token-build/build.js` 增 `--emit-contracts-json`，把 `contracts/*.yaml` 转成 `contracts/dist/*.json`，`--check` 时校验"镜像与 YAML 一致"；iOS 侧只读 JSON（`JSONDecoder`）。M0-5 交付物清单必须含 `contracts/dist/*.json`。
2. **路径定位**（`xcodebuild test` 的 CWD 不是仓根）：

```swift
// Tests/WisdomUITests/Support/WDContracts.swift
public enum WDContractsError: Error { case notFound(searched: [String]); case decodeFailed(URL, Error); case missingTokenManifest }
public enum WDContracts {
    public static func locate() throws -> URL                     // ① env WD_CONTRACTS_DIR ② #filePath 上溯（Tests→iOS→workspace）③ 抛 notFound
    public static func previewCaseNames() throws -> [String]
    public static func acceptanceComponents() throws -> [String]
    public static func componentTypeNames() throws -> [String]     // §6.2 的类型名清单
    public static func tokenManifest() throws -> WDTokenManifest   // {version, sha256, sha12, artifacts[]}
}
```
CI 侧导出 `WD_CONTRACTS_DIR=$GITHUB_WORKSPACE/wisdomdesign/contracts`；**解析失败必须 fail，不得 skip**（U14/REL-8 同一纪律）。
3. **跨仓同批自证**：`build.js --emit-manifest` 产出 `wisdomdesign/dist/tokens.manifest.json`（随设计仓 tag 冻结）；PR-0 读 manifest 断言 `sha12 == WDTokensVersion.hash`，**manifest 缺失 = fail**。`WDTokensVersion` 只证明"iOS 内部自洽"，不能单独证明"与设计仓同批"（B5 的核心）。

#### 1.5.5 性能与覆盖率口径（§2.4 采纳 + I17/I18 采纳）

| 指标类别 | 指标 | 可测环境 | 层 |
| --- | --- | --- | --- |
| 帧时长 / hitch / 卡顿率 | `scrollDecelerationMetric`、hitch 比例 | **真机（固定机型+系统）** | 发布前 |
| 首帧 / 冷启动 | `XCTApplicationLaunchMetric` | 真机（相对基线） | 发布前（M4 起门槛） |
| 分配 / CPU（组件级） | `XCTMemoryMetric`、`XCTClockMetric` | **模拟器**（相对量） | nightly-3 |
| 组件增量（体积） | E3-iOS-a/b；**门槛值 = M1–M3 三次报告的 P50 + 10%（或绝对上限），tech-lead + 架构师在 M3 出口定并写进 `versions.md`/README**（IOS-13） | 归档（Mac） | 发布前 |
| 过程成本 | ci.sh 各阶段耗时 | CI | 报告，不做门槛 |

报告格式固定：`.build/perf/{date}.json` + `docs/perf-ios.md` 一张表（否则 M4 转门槛时没有可比基线）。

**覆盖率**：`Foundation/**` ≥ 80%（**排除 `generated/`**，否则被生成物稀释成假达标），M3 起转门槛；`Components/**` 不设行覆盖率，改**契约覆盖率**（每组件有名用例 + acceptance 条目 + 基线文件）。

**构建产物校验（I18 采纳，替换草案的 `-dry-run`）**：
1. **文本级**（PR-0，秒级）：每个 `*+Previews.swift` 首行 `#if WD_PREVIEWS`、末行 `#endif`；
2. **符号级**：Release 构建后对该产物跑 `swift-symbolgraph-extract`，断言符号名不含 `*Preview*`；
3. `Internal/` 零符号的 `nm -gU` 检查**降级为趋势**（Swift 里 `internal` 已内联/消除，容易给出假绿）。

### 1.6 开发环境（E6/I20 采纳）

| 场景 | 形态 | 说明 |
| --- | --- | --- |
| 本地编译回路 | `xcodebuild build-for-testing -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" -derivedDataPath .build/dd` | 固定 DerivedData（`.build/` 已在 `iOS/.gitignore:2`） |
| 纯规则回路 | `Scripts/check-structure.sh`（秒级，不需要 Xcode） | R1–R21 + 自检样本 |
| 预览 | `#Preview` 矩阵（`WD_PREVIEWS` 守卫）+ `Sources/WisdomUIPreviews/` 共享矩阵 | 三条限制写进 `iOS/README.md`：需要宿主 app target；release 不编译；材质/玻璃在预览里与真机不一致 |
| **快照渲染器清单**（E6 补充，**写进 `Tests/WisdomUISnapshotTests/SnapshotSupport.swift` 的显式表**，不靠实现者临时判断） | `UIHostingController` + `drawHierarchy`：**玻璃类 6 个** `WDBottomSheet`/`WDActionSheet`/`WDTabBar`/`WDNavigationBar`/`WDToolbar`/`WDCard(.glass)`；其余用 `ImageRenderer` | `ImageRenderer` 不渲染 `Material`/`glassEffect` |
| 真机调试 | `Examples/WisdomUIDemo`（Xcode 工程，`package(path: "../..")` 依赖本地包） | ① `pbxproj` 检入时 `DEVELOPMENT_TEAM` 用占位 + `xcconfig` 覆盖（**不检入 team/bundle id**）；② **M1 交付物补 demo 的 UITest target `WisdomUIDemoUITests`**（`performAccessibilityAudit` 只能跑在 XCUITest 里）；③ `Examples/README.md` 写明"demo 不参与 `dump-api`、不发布" |
| 热重载 | **iOS 无热重载**（Xcode Previews ≠ Live Edit） | 属 DX 事实，写 README/CONTRIBUTING，**不进 contracts**（D-i3 移出） |
| Mock 数据 | `Sources/WisdomUIPreviews/WDSampleData.swift`（零业务语义） | 库内不定义业务模型 |
| **CI 运行时依赖（IOS-14）** | `Scripts/ci.sh` 需要 **`python3`**（`resolve_sim` 解析 `xcrun simctl list -j`）+ `xcrun`/`xcodebuild`；**不得**依赖 `node`/`moreutils`（`ts` 不存在，IOS-09） | 写进 `iOS/README.md`：**GitHub macOS runner 自带 `python3`**；若要把依赖收敛到工具链内，可选改 `Scripts/resolve-sim.swift`（等价实现，**保持工具链内自洽**，非强制） |

## 2. 议题二：组件 API 与实现细节（最终形态）

### 2.1 `WDTextStyle` 定稿（A1 采纳：4 存储字段 + 2 手写派生）

```swift
// Sources/WisdomUI/Foundation/generated/WDTokens.swift（生成物）
public struct WDTextStyle: Sendable, Equatable {
    public let size: CGFloat            // 令牌 fontSize
    public let lineHeight: CGFloat      // 令牌 lineHeight（总行盒高，绝对值）
    public let weight: Font.Weight      // 令牌 fontWeight
    public let letterSpacing: CGFloat   // 令牌 letterSpacing（缺字段 emit 0）
    internal init(size: CGFloat, lineHeight: CGFloat, weight: Font.Weight, letterSpacing: CGFloat)
    // ↑ O-10：构造器 internal；WDType.* 常量仍 public
}

// Sources/WisdomUI/Foundation/Typography/WDTypographyMapping.swift（手写层，不进令牌）
extension WDTextStyle {
    public var lineHeightRatio: CGFloat { lineHeight / size }                    // 派生只读
    public var textStyle: Font.TextStyle { WDTypographyMapping.textStyle(for: self) }  // 手写 12 条映射
}
public enum WDTypographyMapping {
    public static func textStyle(for style: WDTextStyle) -> Font.TextStyle        // largeTitle→.largeTitle … overline→.caption
}
```

- **`textStyle` 绝不进令牌**（U6 + `08-decisions.md:18`）；`lineHeightRatio` 也不进令牌字段（07/06 的 TYP-1 裁决：**真源保留绝对值**，生成物派生 ratio——此处按 A1 收敛为**手写 extension 的计算属性**，生成器只 emit 4 个存储字段）；
- 单测：**12 条字阶 × `Font.TextStyle` 全覆盖**（新增字阶时单测红）+ `lineHeightRatio` 与 `lineHeight/size` 一致；
- `wdFont`/`wdLineBox` 是组件侧唯一入口（R11 强制）。

### 2.2 `WDButton`（Primitives，M2 首件）

```swift
// Sources/WisdomUI/Components/Primitives/WDButton/WDButton.swift
public struct WDButton<Label: View>: View {
    public init(variant: WDButtonVariant = .filled,
                size: WDButtonSize = .md,
                isLoading: Bool = false,
                loadingAccessibilityText: Text? = nil,
                leadingIcon: WDIconName? = nil,
                trailingIcon: WDIconName? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: () -> Label)                       // 8 参（S2 上限）

    public var body: some View { Button(action: action, label: label) }   // ★ 必须是真 Button
}
extension WDButton where Label == Text {
    public init(_ text: LocalizedStringKey, variant: WDButtonVariant = .filled, size: WDButtonSize = .md,
                isLoading: Bool = false, loadingAccessibilityText: Text? = nil,
                leadingIcon: WDIconName? = nil, trailingIcon: WDIconName? = nil,
                action: @escaping () -> Void)
    public init(verbatim text: String, /* 同上 */ action: @escaping () -> Void)
}

// Sources/WisdomUI/Components/Primitives/WDButton/WDButtonStyle.swift
public enum WDButtonVariant: String, CaseIterable, Sendable, Equatable { case filled, tonal, glass, outline, plain, destructive }
public enum WDButtonSize: String, CaseIterable, Sendable, Equatable { case sm, md, lg }

public struct WDButtonStyle: ButtonStyle {
    public init(variant: WDButtonVariant = .filled, size: WDButtonSize = .md, isLoading: Bool = false)
    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        _WDButtonChrome(configuration: configuration, variant: variant, size: size, isLoading: isLoading)
    }
}
private struct _WDButtonChrome: View {   // 内部件：读 @Environment(\.isEnabled/\.wdColors)
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.wdColors) private var colors
    let configuration: ButtonStyleConfiguration; let variant: WDButtonVariant; let size: WDButtonSize; let isLoading: Bool
    var body: some View { /* chrome */ }
}
extension ButtonStyle where Self == WDButtonStyle {
    public static var wdFilled: WDButtonStyle { .init(variant: .filled) }       // R13b 允许：协议扩展里的计算型工厂
    public static func wd(_ variant: WDButtonVariant, size: WDButtonSize = .md) -> WDButtonStyle
}
```

**四条实现纪律（I19 采纳）**：
1. `body` **必须是真 `Button`**：pressed 唯一来源（U6/INT-1）、键盘/开关控制/焦点/`.disabled` 传播、`accessibilityAction` 都依赖它；**禁止** `.onTapGesture` + 自绘按下态；
2. **禁用态只能读 `@Environment(\.isEnabled)`**——`ButtonStyleConfiguration` 只有 `role`/`label`/`isPressed`（`[SDK]` `SwiftUI:9946-9956`，无 `isEnabled`）；`makeBody` 转交给内部 `View`（`_WDButtonChrome`）是**安全形态**（在 `ButtonStyle` 里直接 `@Environment` 能否被注入**仍【待实测】**）；
3. **加载态宽度不变用 `.overlay` 式**（spinner 不参与尺寸），`ZStack` 会把容器撑到 `max(label, spinner)`；判据：外层容器 `sizeThatFits(in: .unspecified).width` 两态差 ≤ 0.5pt（默认档）；
4. `loadingAccessibilityText` 三件套（A6）：`assertionFailure`（开发期）+ 契约 `requiredWhen: loading` + M2 单测（断言"处理中"这一读屏串非空/变更）。

### 2.3 `WDTextField`（Primitives，M2）

```swift
// Sources/WisdomUI/Components/Primitives/WDTextField/WDTextField.swift
public enum WDTextFieldVariant: String, CaseIterable, Sendable, Equatable { case inset, outline, glass }
public enum WDTextFieldPrefix: Sendable, Equatable { case none, icon(WDIconName), text(Text) }
public enum WDTextFieldAccessory: Sendable, Equatable {
    case none
    case unit(Text)
    case clear(accessibilityLabel: Text)                          // 独立可达，不合并
    case reveal(hiddenAccessibilityLabel: Text, shownAccessibilityLabel: Text)
    case count(current: Int, limit: Int)                          // ≥90% 换 status.warning
}
public enum WDTextFieldHelper: Sendable, Equatable { case none, hint(Text), error(Text) }

public struct WDTextFieldAppearance: Sendable {                    // ★ 只 Sendable（SubmitLabel 不 Equatable）
    public var variant: WDTextFieldVariant = .inset
    public var placeholder: Text? = nil
    public var prefix: WDTextFieldPrefix = .none
    public var accessory: WDTextFieldAccessory = .none
    public var helper: WDTextFieldHelper = .none
    public var isSecure: Bool = false
    public var submitLabel: SubmitLabel = .done
    public init(variant: WDTextFieldVariant = .inset, placeholder: Text? = nil, prefix: WDTextFieldPrefix = .none,
                accessory: WDTextFieldAccessory = .none, helper: WDTextFieldHelper = .none,
                isSecure: Bool = false, submitLabel: SubmitLabel = .done)
}
public struct WDTextField: View {
    public init(text: Binding<String>, label: Text, appearance: WDTextFieldAppearance = .init(),
                isEditable: Bool = true, onSubmit: (() -> Void)? = nil,
                onEditingChanged: ((Bool) -> Void)? = nil)
}
```

**结构（验收锚点，CR-1 采纳）**

```swift
VStack(alignment: .leading) {
    labelView                                       // footnote，常驻
    HStack { prefixView; inputField; accessoryView }
        .frame(minHeight: WDSize.fieldHeight)        // 46 加在**输入行**上，不是整个 VStack
        .accessibilityIdentifier("wd-textfield-box") // 测试测量该子树
    helperView                                      // 错误/提示文案（fail-soft，由调用方给）
}
```

**CR-1 的最终验收句（照抄进契约）**：

> `WDTextField` 的**字段盒**（不含标签与辅助文案）在**默认档**下：所有变体、所有状态高度 = **46 ± 1pt**；**状态不得改变高度**。放大档（AX1–AX5）下：字段盒高度 = 行盒高（≥46），文字不裁切。标签与辅助行的存在不改变 46 的定义。

**其余四条裁决（I20 采纳）**：
1. `isEditable == false`（只读态）**在 U6 六态之外**，必须显式登记进 `contracts/acceptance.yaml` 的 U6 段：读屏结果与视觉（`specs/01-basic.md` §5）与 Android 的 `readOnly` 对齐；实现用 `Text` + `.textSelection(.enabled)`（`[SDK]` `SwiftUI:1703`），**不是** `.disabled(true)`；
2. 显隐切换：**默认执行项 = `TextField(text:selection:)` 单实例 + 自绘密文替换**，附 1 条单测"切换前后 `selection` 与焦点不变"；若实测不可行，降级为"焦点回填原位置、光标置末尾"并在 acceptance 标注；
3. `WDTextFieldAppearance` 的 `public var` 保留，但 README 明说"**外观对象是不可变语义，请在构造时给全**"（值类型 + 可变副本，实际安全）；
4. 错误展示归调用方（N6）；错误态**读屏结果**按 F22（iOS 无 error trait，用 `accessibilityValue`/`hint` 组合，文案由调用方给）。

### 2.4 `WDListRow`（Primitives，M2）

```swift
// Sources/WisdomUI/Components/Primitives/WDListRow/WDListRow.swift
public enum WDListRowLeading: Sendable, Equatable { case none, icon(WDIconName), avatar(WDAvatarValue), checkbox, selectionIndicator }
public enum WDListRowTrailing: Sendable, Equatable { case none, value(Text), badge(WDBadgeValue), avatar(WDAvatarValue), disclosure }
@MainActor public enum WDListRowSwipeAction {           // 含闭包：@MainActor，不声明 Equatable
    case none
    case delete(title: Text, onDelete: () -> Void)
}
public struct WDListRow: View {
    public init(title: Text,
                subtitle: Text? = nil,                  // ★ 删除 tertiary（8 参 → 7 参）
                leading: WDListRowLeading = .none,
                trailing: WDListRowTrailing = .none,
                isSelected: Bool = false,
                swipeAction: WDListRowSwipeAction = .none,
                showsSeparator: Bool = true,
                action: (() -> Void)? = nil)
}
```

**四条裁决（I21 采纳）**：
1. **删 `tertiary`**：规格解剖表只有"标题 + 副标题"两槽（`specs/01-basic.md:1652-1653`），Android 侧也只有 `title/subtitle/trailingText` ⇒ 判定 **"三行 76" = 标题 + 副标题 + 尾部值文本**；`76` 的触发条件 = "**有副标题且有尾部文本/徽标**"。`Q-i1` 保留为设计确认项，但**默认按此实现**（不作 M2 阻塞）；
2. **行高裁决规则**：`行高 = max(密度档最小行高, 槽位派生行高)`（密度只抬/压下限，不压缩内容）；契约写 `WDListRow.height = max(density.rowMinHeight, slots.rowHeight)`，4 格矩阵 {comfortable,compact} × {1 槽, 2 槽} 逐格固化为单测；两端注入形态（iOS `@Environment(\.wdDensity)` / Android `density: WDLayoutDensity? = null`）登记为 **F44**（IOS-05：从 F23 拆出；行高公式本身属 U 系列）；
3. **`.swipeActions` 只在 `List`/`ForEach` 内生效** —— 必须写进组件文档（"在 `ScrollView`+`VStack` 里静默失效"），否则 M2 会收到"滑动没反应"的 bug；`allowsFullSwipe` 用系统默认 `true`（与规格"≥阈值直接删除"等价，`[SDK]` `SwiftUI:15527`）；
4. `action == nil` 时**必须**同时：不加 `.isButton`、不设 `contentShape`、`focusable(false)`；`action == nil` + `isSelected` 的组合明确"选中态由父容器表达"（避免无热区的选中视觉）。

### 2.5 弹层：`.wdSheet(...)` / `.wdAlert(...)` 修饰符形态（F21/B3/I22 采纳）

**形态决策**：配置类型保留 `WDBottomSheet` 名字（U1 不破），**呈现入口给 `View` 修饰符**——`.alert`/`.sheet`/`.confirmationDialog` 都需要一个**在屏、稳定**的锚点视图；一个"什么都不渲染"的 `View` 作锚点会出现位置随机/被列表回收的问题。Android 侧是"可组合项自呈现" ⇒ 形态差异登记 **F21**。

```swift
// Sources/WisdomUI/Components/Composites/WDBottomSheet/WDBottomSheet.swift
// 前缀统一为 WDBottomSheet*（IOS-03；U1 + B7b 的执行）；两端都不得出现 WDSheet*
public enum WDBottomSheetDetent: String, CaseIterable, Sendable, Equatable { case half, large }  // 0.5 / 0.92
public enum WDBottomSheetDetents: Sendable, Equatable {           // iOS 独有的联合类型 ⇒ 登记 F38
    case all                                                      // 默认 {half, large}，与 Android 默认档一致
    case fixed(WDBottomSheetDetent)
}

extension View {
    public func wdSheet<Content: View, Footer: View>(
        isPresented: Binding<Bool>,
        detents: WDBottomSheetDetents = .all,
        initialDetent: WDBottomSheetDetent = .half,
        interactiveDismissDisabled: Bool = false,          // 平台原语（取代草案的 dismissPolicy）
        title: Text? = nil,
        closeButtonAccessibilityLabel: Text,               // ★ 必填（L-B：库不推导"关闭"）
        onCloseButtonTap: (() -> Void)? = nil,             // 用户点了关闭按钮
        onDismiss: (() -> Void)? = nil,                    // 系统已完成关闭
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View
}

// Sources/WisdomUI/Components/Composites/WDActionSheet/WDActionSheet.swift
public struct WDActionSheetItem: Identifiable, Sendable, Equatable {   // ★ 不是 Hashable
    public enum Role: Sendable, Equatable { case `default`, destructive, cancel }
    public let id: String
    public let label: Text
    public let role: Role
}
extension View {
    public func wdActionSheet(isPresented: Binding<Bool>, title: Text? = nil, message: Text? = nil,
                              items: [WDActionSheetItem], onSelect: @escaping (WDActionSheetItem.ID) -> Void,
                              onCancel: (() -> Void)? = nil) -> some View
}
```

**三条裁决**：
1. **`onDismissAttempt` 删除**（B3）：`.sheet` **没有遮罩点击回调**，`interactiveDismissDisabled(Bool)` 会把"下拉 + 遮罩点击"一起关掉；系统关闭后只能观察 `isPresented == false` ⇒ **"意图"在 iOS 不可达**，登记 **F29**（Android 的 `onDismissRequest` 能交付意图）。契约写"**可见性唯一真源在调用方**"；
2. **detents 默认值两端一致**（I22）：改 `.all`（= `{half, large}`，与 Android 的 `{PartiallyExpanded, Expanded}` 对齐），`initialDetent = .half`；数值 0.5/0.92 落令牌（§1.4-3）；
3. **CR-2 处置（扩围）**：`specs/02-advanced.md:639,641` 的两条验收（"顶部圆角 32、把手 36×5 ± 1pt"、"速度 ≥500pt/s 或位移 >40% 关闭"）**加注"iOS：不适用（系统控制）"**；补 iOS 专属验收：内容层圆角/内边距按令牌、提供"下滑关闭"自定义辅助操作、`interactiveDismissDisabled` 生效。**不推荐自绘面板**（手势/焦点/键盘/无障碍全自管）。

### 2.6 状态机、行盒与无障碍语义

#### 2.6.1 状态机（U6）

`WDInteractionState`（`Internal/`，**零 `public`**）：`default/hover/pressed/focused/disabled/loading`；优先级 `disabled > loading > pressed > focused > hover > default`；三条派生：disabled 最高且吞输入；**loading 期间忽略 `action` 但 `.isEnabled` 仍为 `true`**（U6 派生②，补断言）、留在无障碍树；focused/hover 是叠加维度。

| 状态 | iOS 唯一来源 | 视觉值真源 | 验收 |
| --- | --- | --- | --- |
| `hover` | `.onHover`（指针设备专属） | `state.hover.brightness`（令牌，#6） | 预览 + 人审；**禁止用 hover 承载信息** |
| `pressed` | `ButtonStyleConfiguration.isPressed` | `motion.component.press-scale`（已有）+ `state.pressed.brightness` | 快照 + 触觉计数 |
| `focused` | `@Environment(\.isFocused)` | `state.focus.ring-width` / `ring-alpha` | Tab 键 + 快照 |
| `disabled` | `.disabled(_:)` + `@Environment(\.isEnabled)` | `state.disabled.alpha` | 单测：仍在无障碍树 |
| `loading` | 调用方受控 | —（指示器） | 宽度两态差 ≤0.5pt |

**disabled 的对比度（I24c + IOS-06，**M0-1 已决**）**：`state.disabled.alpha = 40%` 在浅底上很容易低于 3:1 ⇒ 用户决策 #3 采纳方案 ①（不留悬空）：

1. **已决：新增 disabled 专用颜色槽 `text.disabled`** ⇒ **U12 = 32 槽位**（`WDColorSlot`/`WDColorOverrides` 各加一，**槽位计数断言与两端计数断言同步为 32**）；`contracts/contrast.json` 作为**不豁免**的达标项，M2 起进验收；**该槽位的色值由设计在 M0-1 内给**（未给则按默认执行项先冻结，不缩表）；
2. ~~维持 40% opacity ⇒ 在 `contracts/contrast.json` 写显式豁免~~（**已否决**，保留备查）。

> 两条路都必须与 **F45**（两端禁用/状态视觉实现机制）配套：iOS 是 `state.*` 令牌读取，Android 是 `press-overlay-alpha` 叠加 + 自绘 ⇒ **视觉语义（U6）一致、机制自由**。

#### 2.6.2 错误态与只读态（U9/F22）

| 语义 | iOS 实现 | 备注 |
| --- | --- | --- |
| 错误态读屏 | **无 error trait** ⇒ `.accessibilityValue(值 + 分隔符 + 错误文案)` 或 `.accessibilityHint`（**分隔符与文案由调用方给**） | 登记 **F22**；两端"读屏结果顺序与含错误这一点"必须一致 |
| 只读态 | `Text` + `.textSelection(.enabled)` | 在 U6 六态之外，登记进 acceptance |
| 卡片/装饰 | `.accessibilityHidden(true)` | 装饰不进树 |
| 焦点身份 | `public struct WDA11yFocusID: Hashable, Sendable { public let rawValue: String }` | `@AccessibilityFocusState` 需要 `Value: Hashable`（`[SDK]` `SwiftUI:20262`），**用 `Text` 编译不过**（I40） |

```swift
// Sources/WisdomUI/Foundation/Accessibility/WDSemantics.swift —— 只做结构：零标点、零语序、零状态文案（B2/D5）
public enum WDSemantics {
    public static func join(_ parts: [Text], separator: Text) -> Text
    public static func positional(label: Text, positionText: Text, separator: Text) -> Text
    public static func join(_ parts: [String], separator: String) -> String      // 纯逻辑重载，供两端 fixtures
}
// Sources/WisdomUI/Foundation/Accessibility/WDAnnouncement.swift
public enum WDAnnouncementPriority: Sendable, Equatable { case polite, assertive }
@MainActor public protocol WDAnnouncing { func post(_ text: String, priority: WDAnnouncementPriority) }   // ★ 去 Sendable
@MainActor public struct WDSystemAnnouncer: WDAnnouncing { /* 同步调 AccessibilityNotification.Announcement(_:).post()，无 Task */ }
public enum WDAnnouncementThrottle {   // 纯逻辑，两端同源 fixtures（announcement-cases.json）
    public static func shouldAnnounce(previous: Double, current: Double, thresholds: [Double]) -> Bool
    public static func shouldAnnounceAfterRelease(now: ContinuousClock.Instant, last: ContinuousClock.Instant?) -> Bool
}
```

> **契约一句话（进 `contracts/README.md`）**：库提供的是**拼接结构**，不是**拼接结果**——分隔符、位置措辞、语序模板、状态短语一律由调用方从自己的本地化资源传入；库内不得出现任何标点字符、词序模板或状态文案（含"关闭""第 n 项，共 m 项""处理中"）。测试用**非中文分隔符**（`"|"`、`"／"`）断言，从测试侧证明"库内没有默认分隔符"。

#### 2.6.3 行盒：`wdLineBox` 与 U5 验收（B7/D2 采纳）

`[组长实测]`：`.lineSpacing` 的实现是 `environment(\.lineSpacing, …)`（`SwiftUICore:8505-8506`），**只影响行间** ⇒ 单行高度**不由它决定**；草案的 `max(0, target − natural)` 在 `n=1` 时追加量为 0（body 17pt ≈ 20.3pt < 22pt），在 `n≥2` 时恒缺 `target − natural`。

```swift
// Sources/WisdomUI/Foundation/Typography/WDFontMetrics.swift（唯一可 import UIKit 的字体文件）
public enum WDFontMetrics {
    public static func scaledSize(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat
    public static func lineBoxHeight(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat   // max(设计值×缩放, natural)
    public static func lineSpacing(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat     // 仅多行行间
    public static func uiFont(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> UIFont
}
extension View {
    /// 行盒唯一入口：把"盒高"变成几何事实（而不是行距的副作用）
    public func wdLineBox(_ style: WDTextStyle, lines: Int = 1) -> some View
}
// 实现：.lineSpacing(...) + .padding(.vertical, max(0, box - natural)/2) + .frame(minHeight: lines * box, alignment: .leading)
```

**U5 验收（替换草案的两个自造阈值，写进 `contracts/acceptance.yaml` 的 U5 段）**

| # | 测量对象 | 断言 | 环境 |
| --- | --- | --- | --- |
| U5-a | 单行 `Text("Ag").wdFont(.body)` `sizeThatFits(in: CGSize(width: 320, height: .infinity))` | `= 22 ± 0.5pt`（en）/ `= max(22, natural_zh) ± 0.5pt` | 默认档 |
| U5-b | 同上，`n = 2, 3` | `|高度 − max(n×22, ⌈natural×n⌉)| ≤ 1pt` | 默认档 |
| U5-c | AX1/AX3/AX5 | `高度 ≥ ⌈natural(档) × n⌉`（不裁切） | 各档 |
| U5-d | **容器**：`WDButton` 44 / `WDTextField` 字段盒 46 / `WDListRow` 44/60/76 | 分别断言（**与文本行盒是两张表，禁止混用同一个 ±0.5pt**） | 默认档 + 放大档 |

**U5 定稿措辞（D2 采纳）**：

> 两端一律按公式实现 `renderedLineBox = max(designLineBox × 缩放, natural(script, style, 档))`；**默认档断言** `|renderedLineBox − max(designLineBox, natural(script))| ≤ 0.5pt`；**放大档断言** `renderedLineBox ≥ ⌈natural × 行数⌉`（不裁切）；**禁止**"两端行高一致（22pt）"的表述与跨端绝对值比较。

**分语种 fixture（两步测量，缺失 = fail 不得 skip）**：

| 层 | 方法 | 产物 |
| --- | --- | --- |
| ① 字体级 | `UIFont.systemFont(ofSize:).lineHeight`（拉丁）/ `UIFont(name: "PingFangSC-Regular", size:)?.lineHeight`（中文）；**缩放档必须先 `UIFontMetrics(forTextStyle:).scaledFont(for:)` 再读 `lineHeight`** | `Tests/WisdomUITests/Foundation/Typography/LanguageLineBoxFixture.swift` 的 `fontNatural[script][style][dts]` |
| ② 渲染级（真正的验收对象） | `UIHostingController` + `Text(verbatim: "Ag")` / `Text(verbatim: "汉字")`，`sizeThatFits(in: CGSize(width: 1000, height: .infinity))`；**用字面量驱动字体回退**（不依赖进程语言） | 同 fixture 的 `renderedNatural[script][style][dts]`，覆盖 12 字阶 × {en, zh-Hans} × {默认, AX3, AX5} |
| ③ 失败语义 | fixture 缺失 = fail；`natural` 变化超 ±0.5pt 时红并提示"字体或 Xcode 版本变化，需重新记录" | 同上 |

> `[组长实测]` 的字体基准：SF Pro = **1.178em**（全部 ≤ 设计值，最小余量 `caption2` **+0.04pt**）；PingFang SC = **1.400em**（12 条字阶**全部 > 设计值**，+0.20…+6.60pt）。⇒ 中文下"默认档 = 设计值"不成立，上面的带容差 `max` 形式是唯一对两种语种都成立且可机器断言的形式。
> **连带硬约束**：凡"高度由文本撑开"的组件必须显式给令牌 `minHeight`（`WDButton` 32/44/52、`WDTextField` 46、`WDListRow` 44/60/76、`WDBadge`/`WDChip`/`WDSearchField`…），由 **R21** 机器检查；否则中英混排会出现 1–6.6pt 高度差，污染六态截图矩阵。
> **跨端对称要求（请 Leader 一并裁）**：Android 用 `Mode.Minimum` 时 CJK 同样取自然行高 ⇒ 请 android-lead 提供 zh/en 的自然行高实测，两端各记一份 fixture、同一套公式，**都不得把绝对值写进共同断言**。

### 2.7 组合方式与样式覆盖优先级

| 组合需求 | iOS 机制 | 备注 |
| --- | --- | --- |
| 任意内容区域 | `@ViewBuilder` 泛型槽 | 槽位名必须在 §6.2 的**冻结词表**内 |
| 互斥可选槽位 | 枚举 + 关联值（`.none` 必写） | conformance 按 §0.2 修正 |
| 列表项 | 泛型 `ID: Hashable` 或调用方 `Identifiable` 值 | 禁 offset 身份（R11） |
| 复用系统控件外观 | `ButtonStyle`/`ToggleStyle` | 不是 `ViewModifier`（Style 能拿到 `isPressed`） |
| 给外来内容套外观 | `ViewModifier`（`.wdCardStyle`/`.wdGlass`） | 不得改变被注入内容的交互行为 |
| 复杂布局 | `Layout` 协议自定义 `WDFlowLayout`（`Internal/`） | 需自测 3 例：单行/换行/极窄不崩（I24a） |

**优先级（从低到高）**：① 生成常量 → ② `WDTheme` 注入（**只能覆盖颜色/渐变/材质**，R19） → ③ 组件参数 / Style → ④ 实例级 Environment（`wdColors`/`dynamicTypeSize`，**只允许预览/测试/demo**）。

**Environment 写入口（I24b 采纳）**：`wdColors` 是 `wdTheme.colors` 的**只读派生**（不存第二份）；组件**只读** `wdDensity`/`wdEffectsBudget`，写入口只允许 `Foundation/Theme/WDEnvironment.swift` 的 `View` 修饰符（`.wdDensity(_:)`/`.wdEffectsBudget(_:)`），由 **R18** 机器检查。

### 2.8 边界场景与内部实现（沿用草案 + I24d/I24e 补充）

| 场景 | 策略 |
| --- | --- |
| 超长文本 | 只做规格规定的那一种截断；按钮标签 `lineLimit(1)` 不换行、容器外扩；`WDListRow` 标题/副标题各 1 行；**禁 `minimumScaleFactor`** |
| **1 行截断 vs 允许 2 行（I24d 新增）** | 逐组件决定并写进 §2.10 矩阵的"文本策略"列：**允许 2 行** = `WDTabBar` 标签、`WDBanner`、`WDEmptyState` 说明；**强制 1 行** = `WDButton`/`WDListRow` 标题与副标题/`WDBadge`/`WDChip`（U7 降级顺序的 iOS 落点） |
| 空数据 | 列表类组件不渲染空态（调用方组合 `WDEmptyState`）；`WDActionSheet(items: [])`/`WDPicker(options: [])` ⇒ debug 断言 |
| 极端尺寸 | 只声明自身内边距与 `minWidth`（`WDTextField` 190）；宽 0 不崩、无 `NaN` |
| 快速点击 / 重复提交 | `Button` action 包装 `guard !isLoading`；**不做时间节流**；幂等归调用方 |
| 测量 | `onGeometryChange`（`[SDK]` `SwiftUICore:6070`）优先，**不用 `GeometryReader` 包内容** |
| 复用/虚拟化 | 库不提供列表容器；`WDListRow` 依赖调用方给稳定身份 |
| 缓存 | **M1 不做 `WDLineMetrics` 缓存**（V-7 无数据；避免 Swift 6 并发坑，I24e）；将来若加，用 `final class + NSLock`（`@unchecked Sendable`）并把命中率作为依据 |
| 动画驱动 | `.wdAnimation(token, value:)` 唯一入口；常驻动画只允许 4 类（shimmer/sheen/进度环/下拉环），经 `WDMotion` 读 Reduce Motion |
| 触觉/播报 | 全部经 `Internal/WDHaptics.swift`（可注入 sink）与 `WDAnnouncing`（`@MainActor`，同步、无 Task） |

### 2.9 类型约束、废弃与迁移

| 想挡住 | 手段 |
| --- | --- |
| 尾部/后缀多槽并存 | 单值枚举（编译期） |
| 前后置图标同现 | 契约已锁两参数名（D-6）⇒ debug 断言 + 单测 |
| index 当列表身份 | `Identifiable` + 稳定 id；R11 + reviewer |
| 纯展示行被当可点 | `action: (() -> Void)? = nil`（+ 三条连带：无 `.isButton`/无 `contentShape`/不可聚焦） |
| "禁用态传 action" | **结构上不存在**（无 `isEnabled` 参数；禁用只走 `.disabled(_:)`，F2 + 反模式 1） |
| `WDIconButton` 忘传标签 | `accessibilityLabel: Text` **无默认值** |
| 加载态丢播报 | `Text?` + 三件套（A6） |
| 含 `Text` 的类型误声明 `Hashable` | **R17** |

**兼容性规则（理由按 I24f 改写）**：
1. **追加带默认值的公开 `init` 参数 = 源码兼容，但破坏符号快照连续性** ⇒ 需要一次**显式基线更新** + CHANGELOG 记录；**改变已有参数的类型/标签 = 源级 breaking**；
2. 新增枚举 case = 源级 breaking（两端一致，API-4）：minor 发布 + CHANGELOG Breaking 段 + 迁移片段；改名/删除 = major；
3. **默认值变化不改 ABI、不改符号快照** ⇒ 只能靠 `contracts/*.yaml` 断言发现（API-5）；
4. 生成常量增删：新增 = minor；删除 = 源级 breaking；
5. 每处语义变更在 `wisdomdesign/docs/versions.md` 记一行。

**废弃与迁移（pre-1.0 一次性）**：删 `WDTextStyle.lineSpacing`/`.font`/`.text(_:)`（现状 `WDTokenTypes.swift:18-24,29-33`）；`wdShadow` 内部改用链式 `.shadow`（公开签名不变，去掉 `AnyView`，`WDTokenTypes.swift:53-64`）；`WDButton(_ title:)` → `_ text:`（调用点无标签 ⇒ 源码零影响）。

### 2.10 37 组件矩阵（含槽位词表约束、播报/触觉列、默认值对照）

**槽位 vs 参数的边界（I23a；IOS-02 采纳：词表扩到 21 名）**：只有下面的**冻结词表**里的名字算"槽位"（进 U3，两端逐字相同）；其余一律是"参数"，不计入 U3：

```
槽位词表（M0 冻结，21 名）：content / header / footer / leadingIcon / trailingIcon / leading / trailing /
                          title / message / actions / items / label / icon / prefix / accessory / helper /
                          subtitle / valueText / options / placeholder / control
```
- **IOS-02 的 5 个补入名**（**以本节 21 名为准**；原 16 名版本漏了矩阵实际用到的这 5 个名字）：`subtitle`（#18）、`valueText`（#15/#16）、`options`（#7/#22）、`placeholder`（#4）、`control`（#24）⇒ 16 + 5 = **21 名**，必须在同一份词表里，否则 M0-5 按旧口径冻结即错；
- **两端共用同一份词表**（Android 侧由 t11 引用同一份，不得各自扩名）；冻结后新增名字 = 改 U3（需 android-lead + 架构师）；
- 无槽位的组件必须在契约里**显式写"无"**；
- **M0-5 产出**：`contracts/README.md` 的"槽位词表（21 名）"表 + **`{组件 → 槽位名 ∈ 21 名词表 | 无}` 的 37 行表（必须由同一份词表生成）** + **21 名的「分类」副表**（槽位/值参数/值数组，见下）+ "组件类型名清单"（37 条 + `WDBottomSheetDetent`/`WDBottomSheetDetents` 家族，**不得出现 `WDSheet*`**）。

**21 名的「分类」副表（R3-03；分类值域 = 槽位 / 值参数 / 值数组）**

> 目的：**分类差异统一归 F48**（§4.2 副本同步 F46–F50），避免每轮把 D02/D05/D06/D09/D18 重新当成"槽位集合不一致"来吵。**U3 只统一"名字 + 同一名字承载的语义与读屏结果"；API 形态（`@ViewBuilder` 槽 / `@Composable` 槽 / 值载荷 / 值数组）各端自由**（`24-ios-leader-review-r3.md` §7.2 的 S-3 裁定）。本表 iOS 形态列以本规格的签名为准；Android 形态列以 `12-android-spec.md` §2.4 为准，**全量逐行核对归 t19**。

| 名称 | 分类 | iOS 形态（本规格） | Android 形态 | 依据 |
| --- | --- | --- | --- | --- |
| `content` | **槽位** | `@ViewBuilder`（`.wdSheet(content:)`/`WDCard(content:)`） | `@Composable` 槽 | 24 §7.2② |
| `header` | **槽位** | `@ViewBuilder`（`WDListSection`） | `@Composable` 槽 | 24 §7.2② |
| `footer` | **槽位** | `@ViewBuilder`（`.wdSheet(footer:)`） | `@Composable` 槽 | 24 §7.2② |
| `leadingIcon` | **槽位** | **值参数** `WDIconName? = nil`（R3-02；形态差异归 F48） | `@Composable` 槽 | 24 D04/R3-02 |
| `trailingIcon` | **槽位** | **值参数** `WDIconName? = nil` | `@Composable` 槽 | 24 §7.2② + F48 |
| `leading` | **槽位** | **值参数** `WDListRowLeading`（枚举） | `@Composable` 槽 | 03 §2-E07 |
| `trailing` | **槽位** | **值参数** `WDListRowTrailing`（枚举） | `@Composable` 槽 | 03 §2-E08 |
| `title` | **槽位** | **值参数** `Text?`（按组件而定） | 槽 / 值参数（按组件而定） | 24 §7.2②"由各组件形态决定" |
| `message` | **槽位** | **值参数** `Text` | 槽 / 值参数 | 同上 |
| `actions` | **槽位** | **值数组** `[WD…Action]` | `@Composable` 槽 | 同上 |
| `items` | **槽位** | **值数组** `[Identifiable]`（`WDSegmentedControl`/`WDPicker`/`WDTabBar`/`WDToolbar`） | 值数组 / 槽（按组件而定） | 同上 |
| `label` | **槽位** | `Text` 或 `@ViewBuilder`（`WDButton<Label>`） | `String` / 槽 | 同上 |
| `icon` | **槽位** | **值参数** `WDIconName` | **值参数** `ImageVector` | F14 |
| `prefix` | **槽位** | **值参数** `WDTextFieldPrefix`（枚举） | 值参数 / 槽 | 03 §2-E04 |
| `accessory` | **槽位** | **值参数** `WDTextFieldAccessory`（枚举） | 值参数 / 槽 | 03 §2-E05 |
| `helper` | **槽位** | **值参数** `WDTextFieldHelper`（枚举） | 值参数（`supportingText`/`errorText`） | 03 §2-E06 |
| `control` | **槽位** | `@ViewBuilder`（`WDFormRow`） | `@Composable` 槽 | 24 §7.2② |
| `subtitle` | **值参数** | **值参数** `Text?`（**不是** `@ViewBuilder` 槽） | 值参数 `String?` | 24 D06/§7.2③ |
| `valueText` | **值参数** | **值参数** `Text` | 值参数（Android 原 `helper` → 改名 `valueText`） | 24 D05 |
| `placeholder` | **值参数** | **值参数** `Text?` | 值参数 | 24 §7.2③ |
| `options` | **值数组** | **值数组** `[WDRadioItem<ID>]` / `[WDPickerItem]` | **`@Composable` lambda 槽** | 24 D02/§7.2③ |

- 计数自证：**17 槽位 + 3 值参数 + 1 值数组 = 21 名**（与上方词表逐字同集合）；
- **分类不是"槽位集合"**：同名在不同组件可有不同形态（如 `title` 在 `.wdSheet` 是 `Text?`、在 `WDButton` 是 `Label` 槽）⇒ 逐组件形态以 §2.10 矩阵 + 各端签名为准，差异归 **F48**；
- 冻结后**改分类**（如把某名从"槽位"改为"值参数"）= 改 U3/F48，走"先改真源再同步副本"流程。

**矩阵（在草案 §2.3 基础上加两列："文本策略"与"播报/触觉"，并逐行对齐 Android 默认值）**

| # | 组件 | 受控值（**契约名** / 本端形态；C-15 `40-contract-names.md`） | 槽位（∈21 名词表；分类见上方副表） | 关键默认 | **文本策略** | **播报/触觉** | 批次 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | `WDButton` | `loading` / `isLoading`（值） | `label`,`leadingIcon`,`trailingIcon` | `.filled`/`.md` | 1 行 | 按下轻触觉 ×1 | M2 |
| 02 | `WDIconButton` | `loading` / `isLoading` | `icon`,**a11y 标签（必填）** | `.plain` | — | ×1 | M2 |
| 03 | `WDTextField` | `text` / `Binding<String>` ✓ | `label`,`prefix`,`accessory`,`helper` | `.inset` | 1 行 + 错误 1 行 | 错误出现时播报（assertive，一次） | M2 |
| 04 | `WDSearchField` | `text` / `Binding<String>` ✓ | `placeholder`,`leadingIcon`,`label`（取消） | — | 1 行 | **结果数变化 polite**（阈值由调用方） | M5 |
| 05 | `WDSwitch` | `on` / `isOn` ✓ | `label` | — | 1 行 | 切换轻 ×1 | M2 |
| 06 | `WDCheckbox` | `checked` / **`isChecked`** ✓ | `label` | — | 1 行 | 轻 ×1 | M2 |
| 07 | `WDRadio` | `selection` ✓ | `label`（组）,`options` | — | 2 行允许 | 轻 ×1 | M5 |
| 08 | `WDSlider` | `value` ✓ | `label` | — | 1 行 | **松手后播报一次** | M5 |
| 09 | `WDStepper` | `value` ✓ | `label` | — | 1 行 | **高频不给触觉** | M5 |
| 10 | `WDChip` | `selected` / `isSelected` ✓ | `label`,`leadingIcon` | 删除叉独立可达 | 1 行 | — | M5 |
| 11 | `WDBadge` | — | `label` | 4 汉字 | 1 行 | 不播报 | M2 |
| 12 | `WDAvatar` | — | `icon`,`label` | 直径锁死 | — | 读成员名 | M2 |
| 13 | `WDAvatarStack` | — | `items` | `children: .combine` | — | 一次读完 | M5 |
| 14 | `WDDivider` | — | 无 | 装饰：`accessibilityHidden` | — | 不进树 | M2 |
| 15 | `WDProgressBar` | `value` | `label`,`valueText` | — | 1 行 | **只跨 25/50/75/100** | M4 |
| 16 | `WDProgressRing` | `value` | 同上 | 环径锁死 | 1 行 | 同上 | M4 |
| 17 | `WDCard` | — | `content` | `.elevated` | — | 容器 `contain` | M2 |
| 18 | `WDListRow` | `selected` / `isSelected` | `title`,`subtitle`,`leading`,`trailing` | 44/60/76 | 1 行 ×2 | 整行合并读；删除自定义操作 | M2 |
| 19 | `WDListSection` | `selection` ✓ | `header`,`footer`,`items` | 末行无分隔 | — | — | M3 |
| 20 | `WDIcon` | — | `icon` | 装饰：不进树 | — | 不进树 | M2 |
| 21 | `WDSegmentedControl` | `selection` ✓ | `items` | 容器 `contain` | 1 行 | 切换一次 | M5 |
| 22 | `WDPicker` | `selection` ✓ | `label`,`options` | 空数组断言 | 1 行 | — | M5 |
| 23 | `WDDatePicker` | `date` ✓ | `label` | locale 由系统 | 1 行 | — | M5 |
| 24 | `WDFormRow` | — | `label`,`control` | 标签关联（Q-A11Y-2 规则 1） | 2 行允许 | — | M5 |
| 25 | `WDAlert` | `presented` / `isPresented` ✓ | `title`,`message`,`actions` | 焦点归入/归还 | — | `ScreenChanged` 归入 | M4 |
| 26 | `WDBottomSheet` | `presented` / `isPresented` ✓ | `title`,`content`,`footer` | `.all`/`.half` | — | 焦点陷阱 + 归还 | M4 |
| 27 | `WDActionSheet` | `presented` / `isPresented` ✓ | `title`,`message`,`items` | 空 items 断言 | — | 同上 | M4 |
| 28 | `WDToast` | `presented` / `isPresented` ✓ | `message`,`actions` | **`variant = .neutral`**；duration 支持 ≥5000ms | 2 行允许 | polite；暂停=继续剩余时间 | M4 |
| 29 | `WDBanner` | `visible` / `isVisible` ✓ | `message`,`actions` | **`variant = .info`**；软底而非玻璃 | 2 行允许 | polite | M4 |
| 30 | `WDEmptyState` | — | `title`,`message`,`actions` | — | 说明 2 行允许 | — | M4 |
| 31 | `WDSkeleton` | — | 无 | 减弱动效→静态 | — | **整区只播报一次** | M4 |
| 32 | `WDPullToRefresh` | `refreshing` / `isRefreshing` ✓ | `label` | **默认 `.refreshable`（系统视觉）**（O-7 裁决） | — | 到阈值一次触觉 | M5 |
| 33 | `WDNavigationBar` | — | `title`,`leading`,`trailing` | 玻璃档由文字级别决定 | 标题 1 行 | — | M5 |
| 34 | `WDTabBar` | `selection` ✓ | `items` | 深色不透明表面（O-13） | **2 行允许**（U7） | 切换一次 | M5 |
| 35 | `WDToolbar` | — | `items` | 溢出收菜单 | 1 行 | — | M5 |
| 36 | `WDFAB` | — | `icon`,`label`（必填） | 热区 ≥44 | — | 轻 ×1 | M5 |
| 37 | `WDAssigneePicker` | `selection` ✓ | `items`,`label` | 落 `Composites` | 1 行 | 选择一次 | M6 |

**M0-5 追加交付**（I23b/I23c；IOS-15 采纳 = 按 `20-ios-leader-review.md` §5.1 的三步可执行化）：

① 每行的"播报/触觉"进 `contracts/announcement-cases.json`（纯逻辑 fixtures，两端同源）。

② **两端默认值对照表**（37 行 × {参数, 类型, 默认值, 枚举全量 case}）的**三步执行项**——当前 iOS 侧只有"关键默认"列、Android 侧只枚举了 4 个组件 ⇒ **对照表现状不可生成**：

| 步骤 | 谁 | 产物 / 落点 | 验收命令 |
| --- | --- | --- | --- |
| ① iOS 默认值 + case 表（37 行） | **ios-lead** | 本节**新增附表 A**（参数 / 类型 / 默认值 / 枚举全量 case）→ 供架构师抄进 `contracts/<component>.yaml: params[].default` | `Scripts/ci.sh pr` 内的契约单测（`WDContracts` 读 `dist/*.json` 对照 `allCases.map(\.rawValue)`） |
| ② Android 同形表 | **android-dev（t11）** | `12-android-spec.md` §2.3 增表 | `./gradlew wisdomGate`（含契约用例） |
| ③ 合并与差异裁决 | **架构师 + tech-lead** | `contracts/<component>.yaml` 一份；差异逐条进 F 注册表（§4.2） | tech-lead 人工复核（M0-5 出口项） |

**两处已判定的不一致（归属 = t11，不在 iOS 侧"待对齐"）**：

| # | 不一致 | iOS 现状 | Android 现状 | 归属与判法 |
| --- | --- | --- | --- | --- |
| 1 | `WDListRow` 分隔线**默认值** | `showsSeparator: Bool = **true**` | `divider: Boolean = **false**` | **判 Android 稿问题 → t11**：设计未规定"默认不显示"（规格语义 = 默认显示分隔线、末行无分隔）⇒ Android 改默认 `true` 并把参数名统一进契约 |
| 2 | **行高公式** | `max(密度档下限, 槽位派生)`（含 76 三行档，§2.4-2） | 固定 `rowHeightComfortable/Compact = 60/48` | **判 Android 稿问题 → t11**：采用同一公式；密度下限 = **可见内容 44（两端同值，单值键）**，Android 另加**布局盒 48**（+上下各 2dp 内边距）——**行距差异登记 F51**。**本项升级为 U 条目**（统一项 = 两端**可见内容高度 44 ± 0.5**，否则"同槽位组合两端行高不同"），iOS 侧无需改动 |

③ **附表 A（37 行默认值 + 枚举 case）** 与 §1.4.1 的冻结清单同批交付：每行的"默认值"必须与 `contracts/<component>.yaml` 逐字一致，枚举 case 用 `allCases.map(\.rawValue)` 断言（U2）。

### 2.11 三个枚举的类型声明（R3-01 补全；M2 的 `WDCard` 依赖第一项）

> 背景：§2.10 矩阵 #17/#28/#29 引用了 `.elevated`/`.neutral`/`.info`，但**三个类型此前从未声明**（`03-ios-defaults-table.md` §6-04/05/06；`24-ios-leader-review-r3.md` 的 R3-01），而 Android §2.10 已列 case ⇒ U2 的“枚举类型名 + case + 默认值”两端无法比较，**M2 批前签名冻结必卡住**。

```swift
// Sources/WisdomUI/Components/Primitives/WDCard/WDCard.swift            ← M2 首批
public enum WDCardStyle: String, CaseIterable, Sendable, Equatable {
    case elevated, outlined, glass     // 契约名（canonical，小写）＝ elevated / outlined / glass
    // Android 声明 = WDCardStyle{Elevated, Outlined, Glass}（大小写差异属 DIR-1，D01）
}
// Sources/WisdomUI/Components/Composites/WDToast/WDToast.swift          ← M4
public enum WDToastVariant: String, CaseIterable, Sendable, Equatable {
    case neutral, success, warning, danger
    // Android = WDToastVariant{Neutral, Success, Warning, Danger}
}
// Sources/WisdomUI/Components/Composites/WDBanner/WDBanner.swift        ← M4
public enum WDBannerVariant: String, CaseIterable, Sendable, Equatable {
    case info, warning, danger
    // Android = WDBannerVariant{Info, Warning, Danger}
}
```

| 枚举 | iOS 声明（case，小写 rawValue） | 契约名（比较键） | Android 声明 | 默认值 | 批次 | 参数连接 | M0-5 落点 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `WDCardStyle` | `elevated`/`outlined`/`glass` | 同左 | `{Elevated, Outlined, Glass}` | **`.elevated`** | **M2**（#17） | `WDCard(style: WDCardStyle = .elevated, …)` | `contracts/WDCard.yaml` |
| `WDToastVariant` | `neutral`/`success`/`warning`/`danger` | 同左 | `{Neutral, Success, Warning, Danger}` | **`.neutral`** | M4（#28） | `WDToast(variant: WDToastVariant = .neutral, …)` | `contracts/WDToast.yaml` |
| `WDBannerVariant` | `info`/`warning`/`danger` | 同左 | `{Info, Warning, Danger}` | **`.info`** | M4（#29） | `WDBanner(variant: WDBannerVariant = .info, …)` | `contracts/WDBanner.yaml` |

- **U2 单测（各 1 条，归一化后集合相等）**：`WDCardStyle.allCases.map(\.rawValue) == ["elevated","outlined","glass"]`；`WDToastVariant` = `["neutral","success","warning","danger"]`；`WDBannerVariant` = `["info","warning","danger"]`；默认值分别断言 `.elevated` / `.neutral` / `.info`（与 `contracts/<component>.yaml: params[].default` 逐字一致）。
- **大小写（D01）**：iOS 小写 rawValue、Android PascalCase **都合法**；契约键取小写、两端断言用 `name.lowercase()` 归一化比较；**任一端不得改名形**（改名 = 改 U2）。
- **落点纪律**：`WDCardStyle` 必须在 **M2 首批**（`WDCard` 是 M2 组件）；`WDToastVariant`/`WDBannerVariant` 的**类型声明与 case 在 M0-5 契约冻结时就进 `contracts/<component>.yaml`**（U2 靠契约锁默认值，API-5）。
- **与 `03-ios-defaults-table.md` 的同步**：§2 的 E13/E14/E15 已列 case 与默认值，本轮把其“iOS 侧未声明类型”的备注改为**已声明（落点 = 本节）**；三个枚举的 `allCases` 断言进 M0-5 契约单测。

## 3. 议题三：主题、样式与交互（最终形态）

### 3.1 Token：编译期常量 + 运行期槽位覆盖（I30/I35 采纳）

**分层不变**：编译期生成常量为唯一真源；运行期**只允许颜色/渐变/材质三类槽位覆盖**（R19）；字号/间距/尺寸/时长**不可主题化**。

```swift
// Sources/WisdomUI/Foundation/Theme/WDColorValues.swift
public struct WDColorValues: Sendable, Equatable {
    public let textPrimary: Color                 // 32 槽位（含 text.disabled）= semantic.{light,dark} 的**叶子路径**（text.primary → textPrimary）
    // … 其余 31 个
    public static let `default`: WDColorValues    // 由 generated/WDColorSlots.swift 提供
    public init(_ patch: WDColorOverrides)
}
public struct WDColorOverrides: Sendable { public var textPrimary: Color? /* … 32 个可选 */ }
public enum WDColorSlot: String, CaseIterable, Sendable { case textPrimary /* … 32 个 */ }
```

- **映射口径（I35① + IOS-06，**已决 = 32**）**：槽位 = `semantic.{light,dark}` 的叶子路径；**计数断言放进生成器的 `--check` = 32 槽位（含新增 `text.disabled`；用户决策 #3）**，两端同步；iOS 侧做"`WDColorOverrides` 与 `WDColorSlot.allCases` 数量一致（== 32）"的一致性单测（新槽位漏生成时立刻红）；
- **性能纪律可测（I35②）**：nightly 增加"主题注入"用例——注入一次后滚动 200 帧断言无重算（`Self._printChanges` 或 `os_signpost` 计数），列入 M1 预算表；禁止在渲染热路径构造 `WDTheme`（R13a 的 `static var` 禁令 + code review）。

### 3.2 亮/暗、品牌换肤、高对比度（I31/I36 采纳）

```swift
public struct WDAppearance: Sendable, Equatable {
    public let colorScheme: ColorScheme            // .light/.dark
    public let contrast: ColorSchemeContrast       // .standard/.increased（[SDK] SwiftUICore:18393）
    public let reduceTransparency: Bool            // [SDK] SwiftUICore:18006
    public let differentiateWithoutColor: Bool     // [SDK] SwiftUICore:17999
    public let reduceMotion: Bool                  // [SDK] SwiftUICore:18013
}
public enum WDGlassResolution: Sendable, Equatable { case opaque, glass, glassStrong }
// ⇒ IOS-11：WDTextLevel 与 WDAppearance 的字段名及 WDGlassResolution 即 U10 的契约真源（两端同列同名）
public enum WDTextLevel: Sendable, Equatable { case primary, secondary, tertiary }
public enum WDGlass {
    public static func resolve(textLevel: WDTextLevel, appearance: WDAppearance,
                               capabilities: WDGlassCapabilities, budget: WDEffectsBudget) -> WDGlassResolution
}
```

- **优先级**：系统无障碍设置（`contrast`/`reduceTransparency`/`differentiateWithoutColor`/`reduceMotion`）＞ 调用方显式注入 ＞ 生成常量；**库不覆写平台设置**（R16）；
- **`contrast` 进 U10 输入集合（I31，blocker 级改判请求）**：`[组长实测]` Android 侧有 `AccessibilityManager.isHighContrastTextEnabled()`（API 34+）⇒ 两端同列；**这是唯一的"改 U 项"诉求**，需 Leader + 架构师批（见 §7-CR6）；
- **高对比度补偿（O-9 裁决）**：M0–M3 **只做第 1 条**（玻璃 → `opaque`）；第 2/3 条（hairline-strong + 1.5pt、`textSecondary`→`textPrimary`）**排 M4 并需设计签发**（会改对比度账目与视觉档）；
- **换肤责任边界**：库只保证**默认主题**满足 `contracts/contrast.json`；换肤主题由调用方自测（库提供 `.increased` 解析 + `#Preview` 矩阵作为工具）。
- **P9 落地条目（scheme 维度；口径来源 = `30-dev-plan.md` §5.8，用户决策 #8 = 层一）**：
  - **支持**：**多套生成 scheme + 运行时选择**——设计侧在令牌真源里给多套 scheme（`schemes: {light, dark, …}`），生成器**一次产出多套**；iOS 侧用 **`wdTheme` 环境键**在运行时选择其中一套（`EnvironmentValues.wdTheme` / `.wdTheme(_:)`，§2.7）。**换皮肤 = 换用"已生成"的一套 scheme**：主题值变更触发依赖该值的视图**重算/重组**，**不重启进程**；换肤动作属低频路径（见下"性能纪律"）。
  - **不支持（硬边界，不得实现）**：运行时加载任意 `token.json`、服务端下发皮肤、逐槽位任意覆盖——这三件事都等于"运行时可自由构造主题"，与本条相反；契约与实现都按"只能选已生成的 scheme"写。
  - **生成器侧要求（M0-1 一次性冻结，与 §1.4.1 的 17 行清单同批；不新增行号）**：① `../wisdomdesign/tokens/wisdom.tokens.json` 增 **`schemes: {light, dark, …}`** 维度；② `build.js` 支持 **`--schemes` 开关 + 多套输出**（产物仍只落 `Sources/WisdomUI/Foundation/generated/**`，R12 不变）；③ **`WDColorSlot` = 32 槽位**（含新增 `text.disabled`，已决，见 §1.4.1-#17/§3.1）；④ 冻结窗口只开一次——scheme 维度与 32 槽位**一次落完**，二次变更 = breaking。
  - **不变量**：`Q-A2` **不重开**；语义色从 31 扩容到 32（新增槽位）**仍非 breaking**（`WDColorSlot` 是 `CaseIterable` 非 `@frozen` 枚举，新增 case 不影响消费方已写代码，§2.9）。
  - **代价（写进 README 与 CHANGELOG）**：换品牌必须先回设计仓库改 scheme → 重新生成 → 发版；**调用方不能自助加品牌**（这是"层一"的明确取舍，不是缺陷）。
  - **性能纪律（与 Android 侧 `staticCompositionLocalOf` 值变化 = 整树重组同源）**：主题值变更会让所有读主题的视图失效与重算 ⇒ **切换动作不得放进高频路径**（滚动 / 动画 / 输入回调里禁止切换主题）；§3.1 的 nightly"主题注入"用例（注入一次后滚动 200 帧断言无重算）即该纪律的回归网。

### 3.3 密度、安全区域、多窗口、横竖屏、软键盘

| 项 | 决策 |
| --- | --- |
| 密度 | `@Environment(\.wdDensity)`（comfortable 60 / compact 44，令牌）；与 `WDListRow` 行高的冲突按 §2.4-2 的 `max` 规则解；消费方 = `WDListRow`/`WDListSection`/`WDCard` |
| 安全区域 | **组件不消费安全区**（N7）；四类浮层例外（见 §4.2-F36，与 Android 的 6 组件白名单并列）：`WDBottomSheet` 底部操作区 `.safeAreaInset(edge: .bottom)`；`WDToast` 由调用方挂在安全区内；`WDNavigationBar`/`WDTabBar` 由调用方 `.safeAreaInset` 安装；`WDAlert`/`WDActionSheet` 由系统呈现接管。**一条契约（IOS-12）**：**安全区只留一次；由谁施加（系统 `safeAreaInset` vs 组件自身）属平台惯例，两端都不得重复留白** |
| 折叠屏 | iOS 无对应概念 ⇒ 等价场景 = iPad 多窗口/Stage Manager/分栏，用 `horizontalSizeClass` + `containerRelativeFrame`（`[SDK]` `SwiftUI:1425`）响应，**不读屏宽**；登记为平台惯例 |
| 横竖屏 | 组件不做竖/横分支；`ViewThatFits` + sizeClass；验收 = `WDSizeClassMatrix`（compact/regular × 竖/横）四态预览 + nightly 截图 |
| 软键盘避让 | **库不做键盘避让**（N8）：调用方用 `ScrollView` + `.scrollDismissesKeyboard(_:)`（`[SDK]` `SwiftUI:11856`）；**例外** `WDBottomSheet` 必须"键盘弹出不遮挡字段"，验收 = iPad/iPhone 各一次"聚焦最底部字段 → 断言字段 frame 在键盘 frame 之上"（XCUITest）；**"库不做键盘避让"写进 `contracts/acceptance.yaml`**（否则 M5 会有人要求组件兜底） |

### 3.4 手势（I33 采纳）

- **唯一允许的边缘手势：`.swipeActions(edge: .trailing)`**（`[SDK]` `SwiftUI:15527`）；`leading` 边缘**留给系统返回手势**（v1.0 不允许 leading swipe，即使行不在 `NavigationStack` 内，也保持单一路径）；"右滑标记完成"由调用方实现并自担与返回手势的竞争；
- **禁止自造 `DragGesture(minimumDistance: 0)`**（按下态只来自 `ButtonStyleConfiguration.isPressed`）；
- 长按多选 vs `.contextMenu`：同一条 row 不得同时挂；多选由列表容器统一（`editMode`），**验收放 demo 层**（组件不实现，I38）；
- 嵌套滚动交给系统：`.presentationContentInteraction(.scrolls)`（`[SDK]` `SwiftUI:20896`）；
- **方向契约一句话（CR-5，进 `acceptance.yaml` 手势段）**：

> 手势方向与按钮边缘是两件事：手势 = 手指向 `leading` 方向移动（LTR 下为"左滑"，RTL 下为"右滑"，系统按 `layoutDirection` 自动镜像）；操作按钮挂在 `trailing` 边缘。v1.0 只允许 `trailing` 边缘的滑动动作，`leading` 边缘留给系统返回手势。

- **验收（M2）**：① LTR 全滑→删除、未达阈值→回弹且不删除；② RTL（`ar`）同一手势物理方向相反、语义相同（截图 + XCUITest 各一次）；③ 提供"删除"自定义操作（`accessibilityAction(named:)`）。

### 3.5 动画（I34/I39 采纳）

```swift
public struct WDMotion {                    // 公开类型字段名必须与 canonical 同名（I39）
    public struct Spring: Sendable, Equatable { public let response: Double; public let dampingRatio: Double }
    public enum Duration { public static let instant: Double; /* fast/base/slow/slower */ public static let reduced: Double }
}
extension View {
    public func wdAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View
    public func wdAnimation<M: WDMotionToken, V: Equatable>(_ token: M, value: V) -> some View
}
```

| 项 | 决策 |
| --- | --- |
| 弹簧 | canonical = `response` + `dampingRatio`；iOS 直接 `Animation.spring(response:dampingFraction:)`（`WDTokens.swift:217-219` 已是此形态）；**`dampingFraction` 只出现在映射调用点**，字段名一律 `dampingRatio`；iOS 产物不生成 `stiffness` |
| **Reduce Motion 的唯一入口** | `wdAnimation` 内读 `accessibilityReduceMotion` 归一，**不给组件留开关** |
| **Reduce Motion 适用面（I34 收窄）** | 库内可归一的**四类**：① 属性动画（弹簧 → 线性 `motion.duration.reduced`）；② 位移/缩放转场（→ 交叉淡入淡出）；③ 常驻动画（shimmer/sheen/进度环 → 静态）；④ Toast/Banner 进出（→ 淡入淡出）。**页面转场标"宿主 App 负责"**（超出库能力） |
| `motion.duration.reduced` | **M0-1 新增键**（150ms 或设计确认的 160ms）；理由：Reduce Motion 的时长语义 ≠ `fast`（U11 要求时长以令牌为真源，B4/I34） |
| **U11 断言排除清单（CR-2）** | 系统转场（sheet/alert/navigation/confirmationDialog）**不由令牌驱动**，明确排除在"动效令牌一致性"断言之外 |
| 共享元素 | 不入库（`matchedGeometryEffect`/`NavigationTransition.zoom` 属页面级，调用方使用） |
| 手势驱动动画 | 库内只有系统 sheet 拖拽；自绘手势动画一律不做 |

### 3.6 无障碍（I40 采纳，U9）

- **语义**：`WDSemantics.join(_:separator:)` / `positional(label:positionText:separator:)`（**零标点/零语序**，§2.6.2）；容器角色只追求"读屏行为一致"，不与 ARIA 一一对应（容器近似表沿用 `06-cross-review-ios.md:534-551`）；
- **焦点顺序**：视图顺序 + `.accessibilitySortPriority`（`[SDK]` `SwiftUI:6632`）；弹层用 `@AccessibilityFocusState<WDA11yFocusID?>`（`:20262`）+ **`.accessibilityFocused($focus, equals: id)`**（`:20303`）。**写法纪律（IOS-04，[实测] `swiftc -typecheck`）**：**值形态必须带 `equals:`**（`@AccessibilityFocusState<Value: Hashable>` 配 `.accessibilityFocused(_:equals:)`）；**只有 `Bool` 形态才可省略 `equals:`**（`.accessibilityFocused($focus)` 对 `WDA11yFocusID?` 报 `cannot convert … to expected type 'AccessibilityFocusState<Bool>'`）；
- **焦点归还验收（F29）**：弹层关闭时把 `focus` 置回**触发元素**的 `WDA11yFocusID`（`.accessibilityFocused($focus, equals: triggerID)`），关闭后 `AccessibilityNotification.ScreenChanged`（`[SDK]` `Accessibility.framework:224`）；验收 = 弹层关闭后断言焦点落在触发元素；
- **可点击区域**：`WDSize.touchTargetMin`（iOS 产物只有 44）+ `.wdMinTouchTarget()`（`.contentShape` + `.frame(minWidth:minHeight:)`）；
- **动态字体**：唯一入口 `wdFont`；`WDFontMetrics` 用 `dynamicTypeSize` + `UIFontMetrics` **逐 style 直算**；`@ScaledMetric` 只作**对照测试**（同一档下 `@ScaledMetric(relativeTo: .body) var x = 17` 与 `scaledSize(for: .body)` 差 ≤0.5pt）；AX3 硬门禁 / AX5 定义行为；库不设默认上限、允许调用方封顶；
- **减弱动效/降低透明**：§3.2/§3.5；`differentiateWithoutColor` → 状态图标强制出现；
- **播报**：`@MainActor protocol WDAnnouncing`（同步、无 Task）+ `WDAnnouncementThrottle` 纯逻辑 + 两端同源 `announcement-cases.json`；
- **验收（TEST-1）**：`UIHostingController` 渲染一次、多类断言（语义/尺寸/快照）；`XCUIApplication` 只用于跨页面行为与 `performAccessibilityAudit`（`[SDK]` `XCUIApplication.h:143-149`，iOS 17+）；**Swift Testing 的并行注意（F2.3）**：`WisdomUISnapshotTests` 的 suite 加 `.serialized` + `@MainActor`（`UIHostingController`/`sizeThatFits`/快照必须主线程串行），逻辑用例保持并行。

### 3.7 国际化（I41 采纳）

| 项 | 决策 |
| --- | --- |
| 文案外置 | L-B；`Text`/`LocalizedStringKey` 双入口；`Package.swift` 不加 `resources:`；库只提供 §2.6.2 的拼接原语 |
| 复数/性别 | 由调用方在 `.xcstrings`/`.stringsdict` 定义；库不做复数逻辑；需要复数的读屏句式**整句由调用方传入** |
| 日期/数字 | 尊重系统 locale；库不做格式化（R14）；`WDListRow` 尾部值文本 `.monospacedDigit()`（`[SDK]` `SwiftUI:16727`） |
| 相对日期 | 不用 `RelativeDateTimeFormatter` 默认相对量（会输出"1 天后"）；调用方用绝对/半绝对模板；`l10n-fixtures.json` 共享 |
| RTL | 只用 `leading`/`trailing`；图标镜像依赖 SF Symbols 自带元数据（`mirrorsInRTL` 仅契约断言用）；**品牌渐变与色晕不镜像**；验收含 LTR/RTL 两态 |
| **字符串字面量白名单（I41）** | 白名单目录 `generated/`、`Tests/`、`*+Previews.swift`、`Internal/`（日志）；其余只允许"标识符/键名"；与 R15 同批实现 |

---

## 4. 与 Android 的差异登记（F1–F50；F21 起按唯一分配表，IOS-05）

### 4.1 F1–F20（既有，逐行与 `07-summary.md` §1.3 一致）

| # | 项 | iOS | Android | 判据 |
| --- | --- | --- | --- | --- |
| F1 | 布尔参数名 | `isLoading`/`isEnabled` | `loading`/`enabled` | 平台惯例 |
| F2 | 可用性表达 | `.disabled(_:)` + `\.isEnabled` | `enabled` 参数 → `clickable(enabled=)` | 平台惯例 + 反模式禁则 |
| F3 | 主题取值面 | 静态 `WDColor.*`（组件禁用，R10）+ Environment | `WDTheme.colors` 唯一 | 规则统一 |
| F4 | 主题注入 | `EnvironmentKey` + `.wdTheme(_:)` | `CompositionLocalProvider` + `WDTheme { }` | 平台惯例 |
| F5 | 组件内部状态与恢复 | `@State`；可保存状态**由调用方持有** | `remember` + `rememberSaveable(Saver)` | 能力不对称（写进契约） |
| F6 | pressed 来源 | `ButtonStyleConfiguration.isPressed` | 单一 `MutableInteractionSource` + 自定义 `Indication` | **必须统一**：唯一来源 = 平台原语 |
| F7 | 字号/行距实现 | `UIFontMetrics` 逐 style + `wdLineBox` | `sp` + `TextStyle.lineHeight` + `Mode.Minimum` | **必须统一（U5 行盒语义）**；实现自由 |
| **F8** | 动态字体验收档 | **AX3 硬门禁 / AX5 定义行为** | **fontScale 2.0**（1.3 中间档） | **验收档对齐（AX3 vs 2.0）**；**禁止写成百分比**、禁止"系数×设计字号"对照表（**措辞已按 I42 修正**，删除草案的"各自系统最大可达档"） |
| F9 | 触控热区 API | `.contentShape` / `.frame(minWidth:minHeight:)` | `Modifier.wdTouchTarget()` | 数值统一（U8）、API 自由 |
| F10 | 预览隔离 | `#if WD_PREVIEWS`（SwiftPM `.define`） | `src/debug` 源集 | 目标统一（release 零预览代码） |
| F11 | API 冻结工具 | 规范化符号快照 `api/WisdomUI.api.json`（源码兼容） | BCV `apiDump`（二进制兼容） | 分发形态决定的必然差异 |
| F12 | 分发与版本 | SPM tag（不可变） | Maven + `libs.versions.toml` | 平台惯例 |
| F13 | 测试金字塔形状 | 渲染一次多类断言 + 快照 + nightly UI | 逐条 Compose 单测 + instrumentation | 行为统一、手段自由 |
| F14 | 资源与字体 | 无资源；SF Symbols；`Font.Design` | 无资源；调用方注入 `ImageVector` | 平台能力不同 |
| F15 | RTL 图标镜像 | SF Symbols 自带镜像元数据 | `autoMirrored` 变体 | 语义表统一、机制自由 |
| F16 | 降低透明度 | 系统开关 | **无系统等价物** → `WDEffectsBudget` | 平台惯例（细化见 F28） |
| F17 | 播报/触觉执行 | `AccessibilityNotification` + `UIFeedbackGenerator` | `liveRegion` / `performHapticFeedback` | "何时播报/何时给一次"必须统一 |
| F18 | 玻璃实现路径 | iOS 26 `glassEffect`；17–25 材质降级 | 默认降级；可选窗口模糊（API 31+） | 平台惯例 |
| F19 | 主题桥接 | 无需（`Color` 自带浅深） | M3 `ColorScheme` 桥接（`internal`） | 平台惯例 |
| F20 | 效果预算注入 | `EnvironmentValues.wdEffectsBudget` | `LocalWDEffectsBudget` | 字段与默认值统一 |

### 4.2 F21–F50（**唯一分配表**，采纳 `20-ios-leader-review.md` §3 + §3-附记；IOS-05）

> **治理规则（写进 `contracts/README.md` 表头，M0-5）**：⓪ **F21 起唯一登记处 = `20-ios-leader-review.md` §3（+附记）；本节表格是它的副本**（M0-5 起真源迁至 `contracts/README.md`）——副本只读、不得在此新增或改写编号，登记先改真源再同步副本；① **F21 起只有一处分配权**（研发 Leader / 架构师），两端修复任务按本表引用，**不得自行取名/取号**；② 新增差异 → 先在该表登记"下一个空号"再实现，一行必须是"两端形态两列"；③ 已分配号**只增不改**，条目内容变更走 CHANGELOG；④ 机械映射：**iOS 稿 F21–F29 号不变、条目不变**（仅把 F23 的密度附属项拆出为 **F44**）；Android 稿 F21→F30、F22→F31、F23→F32、F24+F31→F33、F25→F34、F26→F35、F27→F37、F28→F38、F29→F39、F30→F40、F32→F41、F33→F42、F34→（并入 F24）、F35→F43（Android 侧引用同步 = t11）。

| 编号 | 项 | iOS 形态 | Android 形态 | 必须统一的部分 |
| --- | --- | --- | --- | --- |
| **F21** | 弹层/presenter 形态 | `.wdSheet(...)`/`.wdActionSheet(...)` **修饰符挂在锚点视图**（系统 `.sheet`/`.confirmationDialog`） | 可组合项自呈现（`Dialog`/`ModalBottomSheet`） | 可见性真源在调用方、焦点陷阱与归还、遮罩语义、`requiredWhen` 文案、`detents` 默认档集合一致 |
| **F22** | 错误态读屏 | 无 error trait ⇒ `.accessibilityValue`/`.accessibilityHint` 组合（**文案与分隔符由调用方给**） | `semantics { error(text) }` | 读屏**结果**："标签，值，错误"（顺序与"含错误"两端一致） |
| **F23** | 文本字段能力集（**不含密度** —— 密度见 F44） | `WDTextFieldAppearance`（variant/placeholder/prefix/accessory/helper/isSecure/submitLabel）+ `isEditable` | `characterLimit`/`keyboardOptions`/`visualTransformation`/`supportingText`/`errorText` | 三件事两端都能表达：**计数/清除/显隐**；**标签必填两端一致**（Android `label` 需从可选改必填，见 §7-CR9） |
| **F24** | 语义帮助函数形态（含返回类型 `String` vs `Text`、参数顺序、iOS 的 `[String]` 纯逻辑重载） | `WDSemantics.join(_ parts: [Text], separator: Text) -> Text`（+ `join(_ parts: [String], separator: String) -> String`） | `WDSemantics.join(separator: String, vararg parts: String): String` | 语义等价 + 分隔符/位置措辞/语序**全部由调用方传入** + 库内零标点 |
| **F25** | 契约文件读取与跨仓自证机制 | 读 `contracts/dist/*.json`（`JSONDecoder`，零依赖）+ `tokens.manifest.json` | 读 YAML 或同一 JSON | 同一源 + **解析失败必须 fail** |
| **F26** | 快照基线与金标设备（细化 F13） | 自研像素/感知哈希；玻璃类 `UIHostingController`+`drawHierarchy`、普通类 `ImageRenderer`；基线含 `{xcode,sdk,deviceType,runtime}` | 官方 screenshot 插件 + Robolectric 语义树 | 六态矩阵的**态定义**一致；**禁止两端并排比截图**（D-4） |
| **F27** | 系统控制的手势与几何（原 D-i4 扩围） | `.swipeActions` 无阈值 API；系统把手 36×5 与圆角 32 **不可定制**；关闭阈值 40%/500pt/s **不可断言** | `SwipeToDismissBox` 自实现吸附与阈值；把手 `dragHandle` 可定制 | **行为**："未达阈值不删除 + 提供自定义无障碍操作"；方向契约见 §3.4；iOS 的几何/阈值验收标"不适用（系统控制）" |
| **F28** | 系统级无障碍开关可得性（细化 F16） | `reduceTransparency`/`reduceMotion`/`differentiateWithoutColor`/`colorSchemeContrast` 齐全 | 无 reduceTransparency 等价物；**有** `AccessibilityManager.isHighContrastTextEnabled()`（API 34+，`<34` 恒 false） | U10 的**输入集合**与输出语义一致；Android 用常量 `false` 兜底（**修正 D-i1 的事实错误**） |
| **F29** | "关闭意图"回调可达性 | 只能交付"点了关闭按钮"（`onCloseButtonTap`）与"系统已完成关闭"（`onDismiss`） | `onDismissRequest` 可交付**意图** | "可见性唯一真源在调用方" + **"关闭后焦点归还触发元素"**（写法与验收见 §3.6 的 `.accessibilityFocused($focus, equals: triggerID)`） |
| **F30** | 动效降级入口 | `accessibilityReduceMotion`（`wdAnimation` 内归一） | `MotionDurationScale` | 降级的**行为**四类一致（§3.5）；入口自由 |
| **F31** | 时长/弹簧数值类型 | `Double`（秒） | `Int`（毫秒） | 令牌真源以毫秒计、两端换算；**禁止把换算系数写进组件** |
| **F32** | 默认参数与 ABI 兼容判定 | 默认值**不进**符号快照 ⇒ 靠契约断言（API-5） | Kotlin `$default` 合成方法进 ABI（加参数也是 breaking） | 语义一致：默认值变化 = 语义变更 + CHANGELOG；判定工具自由 |
| **F33** | 类型构造能力与可见性 | 生成物构造器 `internal`（`WDTextStyle`） | 生成类 `internal constructor`；**`WDGradientSpec` 例外保留公开构造器**；手写类同 | 消费方不得构造令牌值 |
| **F34** | 容器语义近似 | 无容器 trait ⇒ `children:.contain` + `.isSelected` 近似 | `Role` 无容器角色 ⇒ `isTraversalGroup` + `collectionInfo` | 只追求"读屏行为一致"，不与 ARIA 一一对应 |
| **F35** | 软键盘避让责任 | 库不做；调用方 `.scrollDismissesKeyboard`；`WDBottomSheet` 例外 | `ime.union` 白名单 | **"库不做键盘避让"进 acceptance**；浮层例外两端各自登记 |
| **F36** | **安全区责任划分**（IOS-12） | 组件不消费；调用方 `.safeAreaInset` 安装；四类浮层例外 = `WDBottomSheet`（`.safeAreaInset(edge:.bottom)`）/`WDToast`（调用方挂安全区内）/`WDNavigationBar`/`WDTabBar`；`WDAlert`/`WDActionSheet` 由系统呈现接管 | **6 组件白名单**，组件自身承担 | **一句契约**：**安全区只留一次；由谁施加（系统 `safeAreaInset` vs 组件自身）属平台惯例，两端都不得重复留白** |
| **F37** | 状态文案类型 | `Text?`（`loadingAccessibilityText`） | `String?`（`loadingLabel`） | `requiredWhen: loading` 语义一致；nil → debug 断言 |
| **F38** | sheet/detent 表达与默认档 | `WDBottomSheetDetents`（`all`/`fixed`：**iOS 独有的联合类型**）+ `initialDetent` 形参 | 档位集合 + 属性（`initialDetent` 位置差异） | **默认档集合一致**（`{half, large}`）；单档类型 `WDBottomSheetDetent` 与 case `half`/`large` 两端同名 |
| **F39** | 触觉常量与执行 | `UIFeedbackGenerator` | `performHapticFeedback`（无 VIBRATE 权限） | "同一次操作只给一次" + 频控 fixtures |
| **F40** | 渐变几何与 RTL 不镜像 | 令牌物理角度 | 同 | 品牌渐变与色晕**不随 RTL 镜像** |
| **F41** | 日期/时间选择载体 | 系统 `DatePicker` | 系统 `DatePicker`/`DatePickerDialog` | 尊重 locale；库不格式化（Q-I18N-3） |
| **F42** | 行盒/尺寸断言的测量手段与容差单位 | `UIHostingController.sizeThatFits`，默认档 ±0.5pt（多行 ≤1pt） | Robolectric ±1px | **容差语义同值**；±0.5pt 与 ±1px 是各自的物理换算，**不做跨端数值比较** |
| **F43** | 阴影精度 | 双层精确（`WDElevation` 两个 `WDShadowLayer`） | 近似映射 | 视觉档位名一致；实现自由 |
| **F44** | **密度注入与行高下限机制**（从 F23 拆出，IOS-05） | `@Environment(\.wdDensity)`（组件只读；写入口 = `View` 修饰符，R18） | `density: WDLayoutDensity? = null` 形参 | **行高公式 `max(密度下限, 槽位派生)` 属 U 系列**（§2.4-2），两端同公式；注入形态自由 |
| **F45** | **状态视觉值实现机制**（新增，IOS-06） | `state.*` 令牌（hover/pressed 亮度、focus 环宽+alpha、disabled alpha）由 chrome 读取 | `press-overlay-alpha` 叠加 + 自绘（提高不透明度 + 形状/字重差异） | **同一状态在同一串输入下视觉语义一致**（U6）；实现机制自由；禁用文字对比度 = **已决：新增 `text.disabled` 色槽、不豁免**（U12 = 32；§7.1 / §8.1-D-13） |
| **F46** | **角色/动作标签形参的能力不对称**（来源：`22-ios-leader-review-r2.md` §6 预备裁定 S-1 = `20-ios-leader-review.md` §3-附记；**已核对（t17）**） | 真 `Button` 自带角色与动作标签：无 `role`/`onClickLabel` 形参（需要时由调用方用 `.accessibilityAddTraits` / `.accessibilityAction(named:)` 施加） | 暴露 `role` / `onClickLabel` 两个形参 | 读屏**结果**一致（角色语义 + 动作标签文案由调用方给）；形参面自由（**不得**为对称给 iOS 加这两个形参） |
| **F47** | **玻璃档位作为额外输入**（来源：`22-ios-leader-review-r2.md` §6 预备裁定 S-2 = `20-ios-leader-review.md` §3-附记；**已核对（t17）**） | `WDGlass.resolve` 只接**文字级别** `WDTextLevel`（无档位形参） | `WDGlassLevel` 六档作为**额外输入** | U10 的 canonical 输入集合（`textLevel` + `appearance` + `capabilities` + `effectsBudget`）与输出 `{opaque, glass, glassStrong}` **不变**；额外档位不得改变输出语义 |
| **F48**（第 2 批补记 · t17 裁定） | **槽位 / 内容参数的实现分类**（来源：t15 §8.1 的 D09/D18 + android-dev 的 S-3；与 D02/D04/D05/D06 同批裁定） | 同一内容名可为 `@ViewBuilder` 泛型槽、值参数（`subtitle: Text?`、`valueText: Text?`、`placeholder: Text?`）或值数组（`options: [WDOption]`、`items: [WDSegment<ID>]`） | 同一内容名可为 `@Composable` content lambda 槽位或平铺参数 | **U3 统一的是「名字 + 同一组件的语义（同一名字 = 同一内容 + 同一读屏结果）」；API 形态（槽位/参数/值数组）各端自由**。判据：`contracts/README.md` 的 U3 段只锁 21 名清单 + `{组件 → 名称\|无}` 37 行表（名字逐字相同）；分类差异登记本行 |
| **F49**（第 2 批补记 · t17 裁定） | **`WDToolbar` 的 leading/trailing 表达**（来源：t15 §8.1 D14） | 走系统 `ToolbarItem` 语义表达 leading/trailing（无显式形参） | 显式 `leading`/`trailing` 槽位 | 名称集合按 U3 对齐（`items` + `leading` + `trailing`）；形态自由 |
| **F50**（第 2 批补记 · t17 裁定） | **`WDPullToRefresh` 的刷新动作与视觉载体**（来源：t15 §8.1 D17；已由 O-7 裁决覆盖） | `.refreshable` + `onRefresh: () async -> Void`（系统视觉） | 自实现下拉指示器（无 async 动作） | 行为一致："到阈值触发一次 + 进行中不可重复触发 + 到阈值一次触觉"；视觉载体自由（O-7） |

> **iOS 副本的同步状态（t25）**：本副本 = **F21–F50 连续 30 行**（F46/F47 = 第 1 批补记，**已核对（t17）**；F48/F49/F50 = 第 2 批补记，t17 裁定），与唯一登记处 `20-ios-leader-review.md` §3 + §3-附记**逐行一致**；F21–F45 的编号与条目一字未动。

### 4.3 §4.2 四条 iOS 专属差异的核定（采纳 `01-ios-review.md` §5.4）

| 原编号 | 核定 | 处置 |
| --- | --- | --- |
| D-i1 | **反驳（事实错误）→ 改走 U10** | `contrast` 作为 U10 输入项**两端同列**（Android API 34+ 取系统开关，<34 恒 `false`）；不再作为 iOS 专属差异（见 §7-CR6） |
| D-i2 | **降级：不新增 contracts 条目** | 它是 F5 + INT-2 的重述；要落的是**验收句**"不得要求 iOS 侧恢复状态"（进 `acceptance.yaml` 通用行为段） |
| D-i3 | **移出 contracts** | "iOS 无热重载 / 预览在 Debug 参与编译"属 DX 事实 → `iOS/README.md`/`CONTRIBUTING.md`；契约只保留 F10 的一句 |
| D-i4 | **成立，已扩围并入 F27** | 与 CR-2 的两条验收（圆角/把手几何、关闭阈值）合并登记 |

### 4.4 三条反模式禁则（照抄 `07-summary.md:81-83`）

1. 不得为对称给 iOS 加 `enabled:` 参数（可用性只走 `.disabled(_:)`）；
2. 不得为对称让 Compose 的 `Modifier` 读主题；
3. 不得为对称给 iOS 造 Saver 等价物 / 给 Android 造 `EnvironmentKey` 主题。

---

## 5. 对 `01-ios-review.md` 的逐条回应（采纳 / 部分采纳 / 反驳）

> 口径：**采纳** = 已按建议改（写明改动）；**部分采纳** = 采纳方向但换实现或推迟，附理由与替代方案；**反驳** = 不采纳，附替代方案。**本轮零"不采纳"**——所有反驳项（B1/B3/B7/B7b/D-i1/E1/I02/I04/I22/I31/I40）我都采纳了 review 给的替代方案；**只有 3 条标"部分采纳"**（E3/I04/I18，均为"方向采纳 + 实现时机或形式微调"，已写明理由），另有两个子项带 **【待实测】**（I11 的 `orderedImports` 对 `#if` 块行为、F2.2 的预算须先测再写），不构成偏差。

### 5.1 工程基建（§1.1）

| ID | 裁决 | 改动 / 理由 | 落点 |
| --- | --- | --- | --- |
| E1 插件 attach | **采纳** | `Package.swift` 不写 `plugins:`；插件保留但 M0 不启用；唯一强制入口 = `Scripts/check-structure.sh`；`07:271` 的"编译期报错"注释列入待回写 | §1.1.1、§1.2 |
| E2 四层 + 规则 | **采纳（含 I01–I03 的实现修正）** | 见下三行 | §1.1 |
| E3 swift-format | **部分采纳** | ① 措辞改为"键存在，默认 false，我们显式置 true"（已改）；② `generated/` 的 `public` 文档告警：**M0 用显式文件清单排除，M1 生成器 emit `///` 后切换**——理由：生成器改造属 M0-2 范围，避免 M0 出口项膨胀；③ `--parallel` 已加；④ 基线格式化提交**先于** `api/WisdomUI.api.json` 首次入库（已写为纪律） | §1.3 |
| E4 提交/PR | **采纳** | 新增 `Scripts/check-commit.sh`、`CODEOWNERS`、branch protection；PR 模板命令统一为 `Scripts/*.sh` + `$WD_SCHEME`/`$WD_SIM_ID`；新增 L-B 自检段；新增 rebase-merge 复选框 | §1.4 |
| E5 门禁 | **采纳** | 整套 `ci.sh` 重写（B6） | §1.5 |
| E6 快照渲染器 | **采纳** | 6 个玻璃类组件清单写进 `SnapshotSupport.swift` 的显式表 | §1.6 |
| I01 检查器入口 | **采纳** | 唯一入口 `Scripts/check-structure.sh`（内部 `swift build --product wd-structure-check` + 运行）；`--disable-sandbox` 是本机沙箱产物，CI 必须验证**不带该参数**；新增 `Scripts/Fixtures/{pass,fail}/*.swift` + `Scripts/test-checker.sh`（R1–R21 各一正一反） | §1.1.1 |
| I02 规则冲突 | **采纳** | R1 标识符边界；R6/R7/R13/R14/R15/R17 前**剥离注释与字符串**；R13 拆 **R13a**（带初始化器的 `static var` + `AnyView`）/ **R13b**（`extension ButtonStyle|ToggleStyle|ViewModifier where Self == …` 的计算型工厂合法）；行内豁免语法 `// wd-structure-check:disable <RULE> — <理由>` | §1.1.1–1.1.2 |
| I03 R4 | **采纳** | 保留"`Components/Patterns/` 存在即 error"，并进 `contracts/README.md` 的"已删除项"清单 | §1.1.2 |
| I04 R7 扩围 | **部分采纳** | R7 改为"**数值字面量必须可追溯到令牌**"（采纳）；**偏差**：豁免清单需扩充（`0/1/-1`、`.opacity`、`zIndex`、`lineLimit`、索引、`#available` 版本号、容差常量），且 M0–M2 只 `warning`、**M3 起 error**——理由：M0 就转 error 会与"令牌冻结窗口"互相卡住。配套：5 类值进令牌或进 F 系列同值表（§1.4.1 已逐条裁定） | §1.1.2、§1.4.1 |
| I05 R15/R16 | **采纳** | 新增 **R15**（Foundation 内 `import UIKit` 仅限 `Typography/`+`Accessibility/`）与 **R16**（禁 `.preferredColorScheme`/`.environment(\.colorScheme`/`.environment(\.dynamicTypeSize`，预览/测试/demo 白名单） | §1.1.2 |
| I06 语言模式 | **采纳** | `swiftLanguageModes: [.v6]` + `swiftSettings: [.swiftLanguageMode(.v6)]` 双写；新增**公开 API 隔离注解表**（M0 冻结项） | §1.2、§1.2.1 |
| I07 `.define` | **采纳** | 保留 `WD_PREVIEWS`；`plugins:` 按 E1 处理 | §1.2 |
| I08 测试 target 依赖 | **采纳** | `WisdomUITests` 只依赖 `WisdomUI`；`WisdomUISnapshotTests` 依赖两者；`Baselines` 用 `.copy` 且文件名/manifest 含设备与运行时 | §1.2 |
| I09 `@inlinable` | **采纳** | 补"`@inlinable` 视为签名级变更，PR 逐条点名" | §1.3 |
| I10 空壳基线 | **采纳** | `Examples/BaselineShell/` 入库 | §1.2.3 |
| I11 swift-format | **采纳** | 补 `orderedImports.includeConditionalImports: true`；只显式开 `AllPublicDeclarationsHaveDocumentation`；`Scripts/check-format.sh` 用 `git ls-files` 显式清单（配置无 `exclude`）。**【待实测小项】**：`orderedImports` 对 `#if` 块内 import 的实际行为 | §1.3 |
| I12 版本钉死 | **采纳** | `ci.sh` 导出 `DEVELOPER_DIR`；README 写明 `glassEffect` 需 Xcode ≥26（SDK 26） | §1.5.1 |
| I13 squash vs 历史 | **采纳** | 跨层移动/API 冻结类 PR 要求 **rebase-merge** + 模板复选框 | §1.4 |
| I14 PR 模板 | **采纳** | 命令统一、`-destination "$WD_SIM_ID"`、新增"L-B 自检"段 | §1.4 |
| I15 CODEOWNERS | **采纳** | `generated/**` 只允许生成器 PR 触碰 | §1.4 |
| I16 单编译图 | **采纳** | PR 只编模拟器；设备构建移 nightly；destination 按 UDID；scheme 首次跑通后固化（候选 `WisdomDesign-iOS-Package`） | §1.5.1 |
| I17 覆盖率/契约路径 | **采纳** | `-enableCodeCoverage YES -resultBundlePath`；`WDContracts.locate()`；契约读 JSON 镜像 | §1.5.2、§1.5.4 |
| I18 产物校验 | **部分采纳** | 采纳两条替换（文本级 `#if WD_PREVIEWS` 检查 + Release symbolgraph 断言不含 `*Preview*`）；**偏差**：第二条标 **【待实测】**（依赖 PR-3 的工具链复用），`nm` 检查**降级为趋势**（已按建议） | §1.5.5 |
| I19 host 工具闭包 | **采纳** | 断言 `wd-structure-check` 的依赖闭包不含 `WisdomUI`（`swift package show-dependencies`） | §1.2 |
| I20 demo 工程 | **采纳** | `DEVELOPMENT_TEAM` 占位 + `xcconfig`；**M1 交付物补 `WisdomUIDemoUITests`**；`Examples/README.md` 写明不参与 `dump-api`、不发布 | §1.6 |

### 5.2 组件 API（§1.2）

| ID | 裁决 | 改动 / 理由 | 落点 |
| --- | --- | --- | --- |
| A1 `WDTextStyle` | **采纳** | 4 存储字段（`size`/`lineHeight`/`weight`/`letterSpacing`）+ `init` internal；`lineHeightRatio`/`textStyle` 改**手写 extension 的计算属性**；`textStyle` 绝不进令牌（消解与 U6 的自相矛盾）；12 条映射全覆盖单测 | §2.1 |
| A2 四个签名 | **采纳** | 按 B1/B3 修正后定稿 | §2.2–§2.5 |
| A3 互斥槽位枚举 | **采纳** | 含 `Text` 的枚举只 `Sendable, Equatable`；含闭包的枚举 `@MainActor`；统一"必须有 `.none`" | §2.3、§2.4 |
| A4 状态机 | **采纳** | 同一串输入表驱动两端 fixtures（disabled×loading、loading×pressed、focused×disabled…） | §2.6.1 |
| A5 `action == nil` | **采纳** | 补三条连带（无 `.isButton`/无 `contentShape`/`focusable(false)`）+ `action==nil && isSelected` 的归属规则 | §2.4 |
| A6 加载态播报 | **采纳** | 三件套齐上（断言 + `requiredWhen` + M2 单测） | §2.2 |
| I14/B1 Hashable | **采纳** | 6 处按替代签名修正；新增 **R17** 防复发 | §2.2、§2.3、§0.2 |
| I19 WDButton | **采纳** | ① `body` = 真 `Button`（写死）；② `WDButtonStyle` 经内部 `_WDButtonChrome`（`ButtonStyleConfiguration` 无 `isEnabled`，`[组长实测]`；`ButtonStyle` 内直接 `@Environment` 的注入行为**【待实测】**）；③ spinner 改 `.overlay` 式；④ 宽度判据 = 外层容器 `sizeThatFits(in: .unspecified).width` 两态差 ≤0.5pt | §2.2 |
| I20 WDTextField | **采纳** | 46 加在 **`HStack` 输入行** + `.accessibilityIdentifier("wd-textfield-box")`；只读态登记 U6 之外；显隐切换默认"单实例 + 自绘密文" + 单测；appearance `var` 保留但 README 声明不可变语义 | §2.3 |
| I21 WDListRow | **采纳** | 删 `tertiary`（7 参）；行高 = `max(密度下限, 槽位派生)` + 4 格矩阵单测；`.swipeActions` 仅 `List` 内生效写进文档；`allowsFullSwipe` 默认 `true` | §2.4 |
| I22 弹层 | **采纳** | `onDismissAttempt` 删除 → `interactiveDismissDisabled` + `onCloseButtonTap` + `onDismiss`；detents 默认 `.all`（两端一致）；关闭标签**必填**；改 `.wdSheet(...)` 修饰符形态（F21）；iPad popover 形态登记 | §2.5 |
| I23a 槽位词表（blocker） | **采纳** | `contracts/README.md` 新增**冻结词表（21 个名，IOS-02 扩表）** + `{组件 → 槽位名 | 无}` 表；套用全 37 行 | §2.10 |
| I23b 播报/触觉列 | **采纳** | 矩阵加"播报/触觉"列，逐组件给"无/一次/频控阈值"；频控 = 纯逻辑 + `announcement-cases.json` | §2.10、§2.6.2 |
| I23c 默认值对照 | **采纳（IOS-15 收口）** | M0-5 产出"两端默认值对照表"，**按三步执行项**（iOS 出表→Android 出表(t11)→架构师合并，验收命令给出）；两处不一致（分隔线默认值、行高公式）**归属均 t11** | §2.10 |
| I23d 批次 | **采纳** | 保留 | §2.10 |
| I24a WDFlowLayout | **采纳** | 3 例单测（单行/换行/极窄不崩） | §2.7 |
| I24b Environment | **采纳** | `wdColors` 只读派生；写入口只允许 `View` 修饰符；新增 **R18** | §2.7 |
| I24c 状态视觉值 | **采纳** | 4 个值进 `state.*`（或 F 系列同值表）；`loading` 期间 `.isEnabled` 仍为 `true` 的单测；**disabled 对比度不豁免**（**已决 = 新增 `text.disabled` 色槽，U12 = 32**；用户决策 #3） | §2.6.1、§1.4.1 |
| I24d 1 行 vs 2 行 | **采纳** | 矩阵加"文本策略"列，逐组件决定 | §2.8、§2.10 |
| I24e 缓存 | **采纳** | **M1 不做缓存**（V-7 无数据；避免 Swift 6 并发坑）；将来加用 `final class + NSLock` | §2.8 |
| I24f 兼容性理由 | **采纳** | 改写为"追加默认参数 = 源码兼容但破坏符号快照连续性 ⇒ 显式基线更新 + CHANGELOG" | §2.9 |

### 5.3 主题、样式与交互（§1.3）

| ID | 裁决 | 改动 / 理由 | 落点 |
| --- | --- | --- | --- |
| I30 T1 | **采纳** | 补 **R19**（只允许 `WDColor/Gradient/MaterialOverrides` 三类覆盖类型） | §1.1.2、§3.1 |
| I31 `contrast` 进 U10 | **采纳（blocker 级改判请求）** | `WDGlass.resolve` 输入集合加 `contrast`，两端同列；Android `SDK_INT ≥ 34 ? isHighContrastTextEnabled() : false` | §3.2、§7-CR6 |
| I32 T3 优先级 | **采纳** | 落 **R16** 机器检查 | §1.1.2、§3.2 |
| I33 T4 手势 | **采纳** | v1.0 **只允许 trailing**；`leading` 即使不在 `NavigationStack` 内也不允许（保持单一路径）；方向契约进 acceptance | §3.4 |
| I34 T5 动效 | **采纳** | 新增令牌 `motion.duration.reduced`；Reduce Motion 适用面收窄为**库内四类**，页面转场标"宿主 App 负责" | §3.5、§1.4.1 |
| I35 令牌/槽位覆盖 | **采纳** | 槽位 = `semantic.{light,dark}` **叶子路径**；计数断言进生成器 `--check`；nightly 增"主题注入后滚动 200 帧无重算"断言 | §3.1 |
| I36 高对比 | **采纳** | O-9 默认执行 = 只做第 1 条（玻璃→不透明）；第 2/3 条排 M4 + 设计签发 | §3.2 |
| I37 密度/安全区/键盘 | **采纳** | 键盘避让验收 = iPad/iPhone 各一次 XCUITest"字段 frame 在键盘 frame 之上"；"库不做键盘避让"进 acceptance | §3.3 |
| I38 手势验收层 | **采纳** | 多选/长按验收放 demo 层（组件不实现），与 O-8 同批 | §3.4、§8 |
| I39 动画 | **采纳** | `WDMotion.Spring` 字段名 = `response`/`dampingRatio`（`dampingFraction` 只在映射调用点）；"转场由系统控制"白名单进 U11 断言排除清单 | §3.5 |
| I40 无障碍 | **采纳** | `WDSemantics` 重写（零标点/零语序）；`@MainActor protocol WDAnnouncing`（去 `Sendable`）；错误态走 F22；新增 `WDA11yFocusID`（`AccessibilityFocusState` 需要 `Hashable`，`Text` 不行） | §2.6.2、§3.6 |
| I41 i18n | **采纳** | 字符串字面量白名单 = `generated/`/`Tests/`/`*+Previews.swift`/`Internal/`（日志）；其余只允许标识符/键名；与 R15 同批 | §3.7、§1.1.2 |

### 5.4 差异、改判项、未决项（§1.4）

| ID | 裁决 | 改动 / 理由 | 落点 |
| --- | --- | --- | --- |
| I42 F8 措辞 | **采纳** | 删除"各自系统最大可达档"，改为"**验收档对齐（iOS AX3 硬门禁 + AX5 定义行为 / Android fontScale 2.0，1.3 中间档）+ 禁百分比 + 禁跨端系数对照表**" | §4.1-F8 |
| I43 §4.2 四条 | **采纳** | D-i1 → U10；D-i2 降级为验收句；D-i3 移出 contracts；D-i4 扩围并入 **F27** | §4.3 |
| I44 反模式 | **采纳** | 照抄 | §4.4 |
| I45 硬约束对齐 | **采纳** | ① 冻结清单补全（§1.4.1）；② 行盒阈值改带容差 `max` + 分语种 fixture；③ L-B 落点已改（不再违规）；④ `grep` 目标扩到全仓 `git grep -nE "swift (build\|test)" -- .`（含 CONTRIBUTING/Examples/.github；路径主语是**仓内** `.`，不是 `iOS/`） | §6.1 |
| I46 U1–U14 三处补 | **采纳** | U3 槽位词表冻结（§2.10）；U9 错误态（F22）；U13/U14 读取与跨仓自证（§1.5.4） | §6.2 |
| I47 CR-1/2/3 | **采纳（含 CR-3 否决选项②）** | 见 §7 的 CR-1/CR-2/CR-3 定稿 | §7 |
| I48 待回写 6 条 | **采纳 + 补第 7 条** | 第 7 条 = `07 §5.1` 树注释"（编译期报错）"回写 | §6.1-7 |
| I49 Q-i1/Q-i2 | **采纳** | Q-i1 默认删 `tertiary`（不等设计答复）；Q-i2 默认**不引 `presentationSizing`**（iOS 18+ 会抬高最低系统要求），接受系统宽度 + 内容层 `maxWidth: 480`，iPad 宽度差异并入 F21 | §2.4、§2.5、§4.2 |
| I50 未闭合项 | **采纳** | V-1 降级为"接线验证"；N-2 补真实失败点（SwiftPM manifest 缓存）；V-4 改写；V-7 默认不缓存；V-8 升级为"归属已核，剩检查器单测" | §8.1 |
| I51 O-1…O-13 | **采纳（逐条给默认执行项）** | 见 §5.5 的裁决表 | §5.5、§8 |

### 5.5 三条追加路由（§5.5）与 O-1…O-13 的最终执行项

| 项 | 最终执行项（"先按此执行"） | 落点 |
| --- | --- | --- |
| **D5 `WDSemantics`** | 两端同批改；iOS 定稿 = `join(_:separator:)` / `positional(label:positionText:separator:)` / `join([String], separator:)`；`closeButtonAccessibilityLabel` **必填**；新增 **R15**；测试用非中文分隔符 | §2.6.2、§5.1 |
| **D2 U5 断言** | `|renderedLineBox − max(designLineBox, natural(script))| ≤ 0.5pt`（默认档）/ `renderedLineBox ≥ ⌈natural × 行数⌉`（放大档）；分语种 fixture（en/zh-Hans × 默认/AX3/AX5），缺失 = fail；**修正 `07:190` 的"+2 余量"口径**（那是 `lineHeight − fontSize`，按 U5 公式拉丁侧最小余量是 `caption2` 的 **+0.04pt**）；连带 R21 | §2.6.3 |
| **命名真源** | `WDBottomSheet`/`WDActionSheet` 为唯一真源，**不得出现 `WDSheet`（含 typealias/别名）**；`contracts/README.md` 增"组件类型名清单"（37 条）+ 两端集合断言；Android 改名按 DIR-4 拆两个提交 | §2.10、§6.2、§7-CR4 |
| O-1 插件 attach | M0 不 attach；`07 §5.1` 注释回写 | §1.1.1 |
| O-2 映射进令牌 | 手写表（U6 已裁）+ 全覆盖单测 | §2.1 |
| O-3 `letterSpacing` 单位 | **判定 pt**（`.tracking(0.6)`；Android `0.6.sp`）；契约写"字距单位 = pt/sp 等价、不随字号缩放" | §1.4.1-#10 |
| O-4 符号快照进 PR | 进，但**必须走规范化**（原始 symbolgraph 不入库） | §1.5.3 |
| O-5 审计进 CI | nightly 报警不拦；4 类目固定（可选 `contracts/audit.yaml`） | §1.5.2 |
| O-6 demo 进 CI | nightly + 补 UITest target | §1.6 |
| O-7 `WDPullToRefresh` | **默认 `.refreshable`（系统视觉）+ 登记差异**；设计若坚持自绘，M4 前给结论 | §2.10-#32 |
| O-8 拖拽排序 | 不入库；多选验收放 demo | §3.4 |
| O-9 高对比补偿 | 只做第 1 条；第 2/3 排 M4 + 设计签发 | §3.2 |
| O-10 `WDTextStyle` 构造器 | internal；`WDType.*` 仍 public | §2.1 |
| O-11 契约落库 | 四文件只读 + **JSON 镜像** + 槽位词表 + 类型名清单 | §1.5.4、§2.10 |
| O-12 覆盖率转门槛 | M3；`Foundation/**` ≥80% **排除 `generated/`**；`Components/**` 走契约覆盖率 | §1.5.5 |
| O-13 深色 Tab 栏 | 不透明表面；由 `WDGlass.resolve` 实现 + 单测 | §2.10-#34 |

### 5.6 §2 深挖五类返工陷阱（全部采纳）

| 项 | 裁决 | 落点 |
| --- | --- | --- |
| F1.1 symbolgraph 规范化 | **采纳** | `Scripts/dump-api.sh` + `Scripts/canonicalize-api.swift` → `api/WisdomUI.api.json`（丢弃 usr/location/docComment/mixins/relationships；按 path 排序；头记录工具链） | §1.5.3 |
| F1.2 语言模式 + 隔离注解 | **采纳** | `swiftLanguageModes: [.v6]` + 隔离注解表 + R20（软提示） | §1.2、§1.2.1 |
| F1.3 M0-11 签名冒烟 | **采纳** | `WD_API_SMOKE` 条件编译 + PR-1 编译；整文件逐字复制公开声明 | §1.2.2 |
| F2.1 destination/scheme | **采纳** | 按 UDID 解析；scheme 固化；PR 单编译图 | §1.5.1 |
| F2.2 预算先测再写 | **采纳** | `ci.sh measure` 三次取中位数回填；**未测不写预算**（§1.5.2 的预算列保持【待实测】） | §1.5.1、§1.5.2 |
| F2.3 Swift Testing | **采纳（V-1 降级）** | `Testing.framework` 已在模拟器平台；剩余 = scheme test action 接线 + 一次真跑；快照 suite `.serialized` + `@MainActor`，逻辑用例并行 | §3.6、§8.1 |
| F2.4 覆盖率/结果包 | **采纳** | `-enableCodeCoverage YES -resultBundlePath`；`generated/` 排除 | §1.5.5 |
| F3.1 机制事实 | **采纳** | `.lineSpacing` 只影响行间 ⇒ 单行盒高不由它决定 | §2.6.3 |
| F3.2 `wdLineBox` + U5-a…d | **采纳** | 行盒唯一入口；四张验收断言；**删除**草案的两个自造阈值（`1.15 ≤ ratio ≤ 1.40` 移入生成器 `--check`；`0 ≤ lineSpacing ≤ 0.35×scaledSize` 删除） | §2.6.3 |
| F3.3 `WDFontMetrics` 约束 | **采纳** | `natural` 取缩放后字体；M1 不缓存；`@ScaledMetric` 只作对照测试 | §2.6.3 |
| F3.4 D2 中文行盒 | **采纳（blocker 同源）** | 带容差 `max` 断言 + 分语种 fixture + R21 + 跨端对称要求（请 android-lead 给 zh/en 自然行高） | §2.6.3 |
| §2.4 性能分层 | **采纳** | nightly-3 改"模拟器相对量"；真机 hitch/首帧移"发布前"；报告格式固定；demo UITest = M1 交付物 | §1.5.5 |
| F5.1 YAML → JSON 镜像 | **采纳** | `--emit-contracts-json` → `contracts/dist/*.json`；M0-5 交付物清单加该项 | §1.5.4 |
| F5.2 `WDContracts.locate()` | **采纳** | env → `#filePath` 上溯 → 抛错；CI 导出 `WD_CONTRACTS_DIR` | §1.5.4 |
| F5.3 token manifest | **采纳** | `tokens.manifest.json` + `sha12 == WDTokensVersion.hash`；缺失 = fail | §1.5.4 |
| F5.4 swift-format 排除 | **采纳** | `git ls-files | grep -vE '/Foundation/[Gg]enerated/'` | §1.3 |

---

## 6. 与 8 条硬约束、U 系列的最终对齐

### 6.1 八条硬约束（逐条给落点、验收与**本轮修正**）

| # | 条款 | iOS 落点 | 验收 | 修正 |
| --- | --- | --- | --- | --- |
| 1 | 令牌 schema 冻结窗口只有一次（M0 D1） | **§1.4.1 的 M0-1 清单（17 行）**（`size.field-height`/`size.field-min-width`/`size.row-height.*`/`size.sheet.*`/`motion.duration.reduced`/`state.*`/触控双键/`letterSpacing` 单位…），每行二选一：进令牌 or 进 F 系列同值表 | M0-1 变更集一次落完；`build.js --check` 绿 | 补全清单（B4）；`size.row-height.*` 已在 M0-1 ✓ |
| 2 | 行高：真源保留绝对值 + `letterSpacing` 槽位；行盒 = `max(设计值×缩放, 自然行高)`；两端各自实现 | `WDTextStyle` 4 字段（§2.1）+ `wdLineBox`/`WDFontMetrics`（§2.6.3） | **带容差 `max` 断言** + 分语种 fixture（U5-a…d）；**禁止**"两端行高一致（22pt）" | ① 断言改形式（B7/D2）；② 删两个自造阈值；③ 修正 `07:190` 的"+2 余量"口径（拉丁侧最小余量 = `caption2` +0.04pt） |
| 3 | 弹簧 canonical = `response` + `dampingRatio`；`stiffness` 由生成器推导；禁 `massFactor` | `WDMotion.Spring{response,dampingRatio}`；iOS 直接 `Animation.spring(response:dampingFraction:)`；**iOS 产物不生成 `stiffness`/`stiffnessMultiplier`** | 字段名与 canonical 同名；单测断言两值与令牌一致 | 补"`dampingFraction` 只出现在映射调用点"（I39） |
| 4 | 图标：只统一语义名 + `mirrorsInRTL`；Android 不新增库内资源 | `generated/WDIconName.swift`（44 条 `String` rawValue，值 = SF Symbols 名）+ `mirrorsInRTL` **仅契约断言**；不建 asset catalog | `icons.json` 语义名集合 = `WDIconName.allCases`；检查器断言 `Sources/WisdomUI/Resources/` 不存在 | — |
| 5 | 文案：库内零资源 + 零文案（L-B） | `WDSemantics` 只做结构（§2.6.2）；`closeButtonAccessibilityLabel` 必填；`Package.swift` 不加 `resources:` | **R15**（标点/词序字面量 error）+ `WDSemanticsTests` 用非中文分隔符 | **修正草案的两处违规**（B2/D5） |
| 6 | Android 玻璃降级为默认；`Modifier.blur` 不是背景模糊 | iOS：`WDGlass.resolve(textLevel:appearance:capabilities:budget:)`（§3.2），iOS 26 `glassEffect` / 17–25 材质 + hairline | 单测：`reduceTransparency == true → opaque`；`contrast == .increased → opaque`（第 1 条）；**两端玻璃截图不放同一次并排比较** | `contrast` 进输入集合（**走 U10 改判**，§7-CR6）；另登记（Android 侧）：`android/README.md:22` 的"Android 12+ 走背景模糊"与 P-1 矛盾，M0 改写 |
| 7 | iOS 门禁 = `xcodebuild` + 模拟器；`swift build/test` 不作门禁 | `Scripts/ci.sh`（§1.5.1）；`iOS/README.md` 的 `swift build/test` 必须删除；`Package.swift` 不加 macOS 平台 | `xcodebuild build-for-testing/test-without-building` 绿；**禁止的是"库/测试的门禁命令"**：`git grep -nE 'swift (build\|test)' -- . \| grep -v -- '-product wd-structure-check'` 零命中（**t46 实测**：修前写法 `-- iOS/` 在本仓**假绿 0 命中**；正确写法当前命中 `README.md:51-52`，M0-i 删除后应为空）；`check-structure.sh` 里 host 工具的 `swift build --package-path . --product wd-structure-check` 为**显式白名单**；范围含 `README.md`/`CONTRIBUTING.md`/`Examples/**`/`.github/**` | IOS-07 统一口径（原"全仓零命中"与 §1.1.1 自相矛盾 ⇒ 门禁恒红） |
| 8 | `apiCheck` 由红转绿（**Android 出口项**） | iOS **对等出口项**：① 规范化 `api/WisdomUI.api.json` 入库（同提交）+ ② banner 与 `WDTokensVersion` 一致 + ③ **跨仓 manifest 自证** | `Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json`；`WDContracts.tokenManifest()` 断言 `sha12` 相等（缺失 = fail） | 补 ③（B5/F5.3） |

**第 7 条的"回写指针"（7 条，`01-ios-review.md` §1.4-I48 采纳 + 补 1）**：① `03:99` 体积并列；② `03:45`/`04:493` 的 `@ScaledMetric`；③ `03:49,112`/`04:505` 的 `#if DEBUG`；④ `docs/06-accessibility.md:196` 的不存在 API；⑤ `docs/04-architecture.md:51-52` 的 `Patterns`；⑥ `docs/specs/01-basic.md:11,118` 的 `Wd*` 命名；⑦ **`07-summary.md:271` 的树注释"（编译期报错）"**。

### 6.2 U 系列（必须统一）在 iOS 侧的最终落点

| U | iOS 落点 | 机器检查 | 本轮修正 |
| --- | --- | --- | --- |
| U1 名称 | 目录树（§1.1）+ **组件类型名清单**（37 条 + `WDBottomSheetDetent`/`WDBottomSheetDetents` 家族，含 `WDBottomSheet`/`WDActionSheet`，**不得出现 `WDSheet*`**） | `WDContracts.componentTypeNames()` 与 `WDComponentRegistry.all` 集合相等 | B7b：清单进 contracts（§5.5） |
| U2 枚举名 + case + 默认值 | §2.2–§2.5 的枚举；默认值进 `contracts/<component>.yaml` | 单测断言 `allCases.map(\.rawValue)` 与契约相等；默认值靠契约（API-5） | detents 默认两端一致（`.all`） |
| U3 槽位语义名 | **冻结词表 21 名** + `{组件 → 槽位名 | 无}` 表（§2.10） | 契约文件 + 人审 + `WdSlotVocabulary` 断言 | I23a：词表冻结（blocker） |
| U4 令牌名与取值 | 只读生成物（§3.1） | `build.js --check` + `--tokens-trace` | `letterSpacing` 单位判定 pt（O-3） |
| U5 行盒语义 | `wdLineBox` + `WDFontMetrics.lineBoxHeight`（§2.6.3） | U5-a…d（带容差 `max` + 分语种 fixture） | B7/D2：实现与断言双改 |
| U6 状态优先级 | `WDInteractionState`（internal）+ 视觉值令牌（§2.6.1） | 同串输入 → 同可见状态；`loading` 期间 `.isEnabled == true` | 补状态视觉值真源、只读态定位、disabled 对比度 |
| U7 降级顺序 | `ViewThatFits` + 五条降级 | 截图 + 单测；**逐组件"1 行 vs 2 行"在 §2.10 矩阵** | I24d |
| U8 触控数值 | `WDSize.touchTargetMin`（iOS 只有 44） | 令牌 `--check` + 热区实测 | — |
| U9 无障碍行为 | `WDSemantics`（零标点）+ `@MainActor` 播报 + 错误态 F22 + 播报/触觉矩阵 | 语义树断言（两端）；`announcement-cases.json` | 错误态读屏（F22）、播报矩阵（I23b）、隔离注解（I40） |
| U10 玻璃输入输出 | `WDGlass.resolve(textLevel: WDTextLevel, appearance: WDAppearance, capabilities: WDGlassCapabilities, budget: WDEffectsBudget) -> WDGlassResolution`；**`WDTextLevel` 与 `WDAppearance` 的字段名及 `WDGlassResolution` 即契约真源**（IOS-11）。**Inputs 句**：`Inputs = {textLevel, appearance{colorScheme, contrast, reduceTransparency, differentiateWithoutColor, reduceMotion}, capabilities, effectsBudget}` → `Output = {opaque, glass, glassStrong}` | 单测（reduceTransparency / increased → opaque） | `contrast` 为 U10 改判项（§7-CR6，Leader 已批）；Android 侧 `WDGlassLevel`→`WDTextLevel`、`WDGlassEffective`→`WDGlassResolution`、并把"玻璃档位"降为**额外输入** = **t11**（t8-LR-09 相邻项） |
| U11 动效令牌 + 弹簧 | `WDMotion`（§3.5） | 令牌值一致性；**系统转场进排除清单** | `motion.duration.reduced` 新增；CR-2 排除清单 |
| U12 语义色 **32 槽位（已决 = 32）** | `WDColorValues`/`WDColorOverrides`/`WDColorSlot`（§3.1） | 生成器 `--check` 计数 **32**（含 `text.disabled`；两端计数断言同步）+ 槽位计数一致性单测 | 叶子路径映射口径（I35①）；**IOS-06 已决（用户决策 #3）= 新增 `text.disabled` ⇒ 32** |
| U13 契约断言项 | 四文件 + JSON 镜像（§1.5.4） | PR 三类必过（用例名/图标表/令牌 hash） | 读取机制（B5） |
| U14 生成物溯源 | banner 正则 + `WDTokensVersion` + **跨仓 manifest** | `--tokens-trace`；解析失败 = fail | 跨仓自证（F5.3） |

### 6.3 F 系列的措辞修正与唯一分配（I42 + IOS-05）

仅 F8 的判据措辞需改（已改，见 §4.1）；其余 F1–F20 逐行与 `07-summary.md` §1.3 一致。**F21–F50 按 `20-ios-leader-review.md` §3 + §3-附记的唯一分配表落库**（§4.2），待架构师落 `contracts/README.md`（M0-5）；**两端修复任务按表引用，不得自行取名/取号**（治理规则见 §4.2 表头）。

---

## 7. 需改判项（集中，含影响面）

> 口径：凡与 `08-decisions.md` 的 8 条硬约束、`07-summary.md` §1 的 U/F 边界线冲突，或规格内部自相矛盾的，全部列在此处，**每一项都给"默认执行项"**——没有任何一项会让 M0 停摆。**"阻塞 M0"= 必须在 M0 令牌/契约冻结窗口（一次性）内定，否则二次 breaking。**

### 7.1 触及 U 系列 / 硬约束的改判请求（需 Leader + 架构师批）

| # | 改判请求 | 冲突双方 | 影响面 | 默认执行项 |
| --- | --- | --- | --- | --- |
| **CR-6** | **U10 的输入集合新增 `contrast`** | `07-summary.md:48` 的 U10 输入为 `{文字级别, 外观, 系统能力, reduceTransparency, 效果预算}`；`01-ios-review.md` §5.4 实测 Android **有** `AccessibilityManager.isHighContrastTextEnabled()`（API 34+） | 若不加：iOS 的高对比度补偿只能是"单端行为"，与 U10"组件不得自己选档"冲突；Android 侧的高对比用户拿到不同档位 | **先按"含 `contrast`"实现**：iOS 读 `colorSchemeContrast`，Android 读系统开关（<34 恒 `false`）；契约冻结时由架构师正式扩一项 |
| **CR-7** | **U3 新增"槽位词表"冻结流程** | U3 只规定"槽位语义名逐字相同 + 无槽位必须写'无'"，但 37 行矩阵里除 U3 已有的 5 名（`content`/`header`/`footer`/`leadingIcon`/`trailingIcon`）外还出现 **16 个新名字（5 + 16 = 21）**：`leading`/`trailing`/`title`/`message`/`actions`/`items`/`label`/`icon`/`prefix`/`accessory`/`helper`（IOS-02 的 11 名）+ `subtitle`/`valueText`/`options`/`placeholder`/`control`（IOS-02 补入的 5 名） | 不冻结：两端对"什么算槽位"理解不同，M2 起逐个组件讨价还价；冻结后新增名字 = 改 U 项 | **先按 §2.10 的 21 名词表**实现；M0-5 落 `contracts/README.md` 的表；新增名字走"改 U3"流程 |
| **CR-8** | **U5 的验收表述改为"带容差的 `max` 形式 + 分语种 fixture"** | `07-summary.md:43` 的 U5 写"默认档精确等于设计值（±0.5pt）"；`01-ios-review.md` §2.3/F3.4 实测 **PingFang SC 自然行高 = 1.400em > 全部 12 条设计比值**（+0.20…+6.60pt）⇒ 中文下该断言 12 档全不成立 | 不改：中文界面所有文本行盒"违约"，M1 出口项（`wdFont` + 行盒度量）无法验收 | **先按带容差形式实现与断言**：`\|renderedLineBox − max(designLineBox, natural(script))\| ≤ 0.5pt`；fixture 缺失 = fail |
| **CR-9** | **硬约束 5 的落点修正已执行，但需跨端连带修正** | Android 草案 `WDTextField(label: String? = null)`（可选）与 `07:170`"L-B 让标签必填成为编译期约束"不一致；iOS 侧已按必填 | 不改：同一验收项（`01-basic.md:318`"标签常驻"）两端强度不同，跨端验收无法共用 | **Android 侧改 `label: String` 必填**（或至少 `requiredWhen: label` 的 debug 断言）；iOS 侧保持必填 |
| **CR-10** | **硬约束 1 的冻结清单扩项**（`size.field-height`/`size.sheet.*`/`motion.duration.reduced`/`state.*`）与 **`07:190` 的余量口径勘误** | 令牌 schema 冻结窗口只有一次；漏项 → M1/M2 二次 breaking。`07:190` 的"+2 余量"是 `lineHeight − fontSize` 算法；按 U5 公式拉丁侧最小余量是 `caption2` **+0.04pt** | 不改：M1 会有 5 类"iOS 专属魔数"（R7 拦不住）或行盒容差在 `caption2` 上被推到边缘 | **先按 §1.4.1 的 M0-1 清单（17 行）**（每行二选一：进令牌 or 进 F 系列同值表）；`07:190` 由 tech-lead 在下版勘误 |

### 7.2 规格内部矛盾（需设计确认 / 改写验收句；不阻塞 M0）

| # | 矛盾 | 冲突原文 | 影响面 | 默认执行项（已写进本规格） |
| --- | --- | --- | --- | --- |
| **CR-1** | TextField「高度固定 46」 vs 行盒语义 U5 | `specs/01-basic.md:239`（"46（固定，所有变体一致）"）+ `:316`（验收"所有状态都是 46"）**vs** `docs/06-accessibility.md:122-131`（"容器高度同步增高，不裁切"） | 不改：两条验收互相否定（裁切违反 U5，增长违反 46 验收）；**阻塞 M2** 的字段盒几何 | 46 = **默认档设计值**（加在 `HStack` 输入行上）；**状态不得改变高度**；放大档 = 行盒高（≥46）不裁切（验收句见 §2.3） |
| **CR-2** | Sheet 的把手几何/圆角/关闭阈值在 iOS 不可断言 | `specs/02-advanced.md:639`（圆角 32、把手 36×5 ±1pt）、`:586`（≥500pt/s 或 >40% 关闭）**vs** iOS 系统 sheet 不可定制（`[SDK]` `interactiveDismissDisabled(Bool)`、`presentationDragIndicator` 只有可见性） | 不改：§12 验收清单有 2 条对 iOS 永远红；**阻塞 M4** | 两条加注"**iOS：不适用（系统控制）**"；补 iOS 专属验收（内容层圆角/内边距按令牌、提供"下滑关闭"辅助操作、`interactiveDismissDisabled` 生效）；**不推荐自绘面板**；登记 **F27** |
| **CR-3** | 「删除后 5 秒撤销条」无归属组件 | `specs/01-basic.md:1690,1739`（撤销条 5 秒可恢复）**vs** U1 的 37 组件清单（无撤销条；`07:164` 已删 `Patterns/`） | 不改：验收项 `:1739` 无载体，或有人私自新增组件造成 37→38 | **否决"新增组件"**（采纳 review §5.3）：① 撤销条 = `WDToast` + 单 action 的组合用法（配方 Rx，`specs/03-patterns.md`）；② 规格句改写为"删除后由 `WDToast` + 单个 action 组合成撤销条，停留由 `duration` 控制"；③ **组件侧唯一硬要求：`WDToast` 的 duration 支持 ≥5000ms**；④ 验收移到 demo/配方层（M6） |
| **CR-5** | 「左滑」是物理方向 vs RTL 语义统一 | `specs/01-basic.md:1688,1715,1729`（左滑/右滑）与 `04-a11y-i18n-dx.md:247`（把"左滑"映射为"leading 边缘"） | 不改：按 04 字面实现会把删除按钮挂 `leading`，与 `NavigationStack` 返回手势竞争 | 用 §3.4 的**一句契约**统一（手指向 leading 移动 / 按钮挂 trailing 边缘 / v1.0 只允许 trailing）；**改文档不改代码** |
| **Q-i1** | `WDListRow` 的"三行 76"缺第三文本槽 | `specs/01-basic.md:1652-1653`（只有标题+副标题）vs `:1660-1662`（三行 76） | 不改：`76` 不可达或实现者自造槽位 | **删 `tertiary`**；判定"三行 = 标题 + 副标题 + 尾部值文本"；触发条件 = "有副标题且有尾部文本/徽标"（§2.4） |
| **Q-i2** | iPad 宽屏下 sheet 的最大宽 480 居中 | `specs/02-advanced.md:591`（≥600 时最大宽 480 居中）vs iOS sheet 宽度由系统 formSheet 决定 | 若引 `presentationSizing`（iOS 18+）会抬高最低系统要求（与 deployment target 17 冲突） | **不引 `presentationSizing`**：内容层 `frame(maxWidth: 480)`；"iPad 面板宽度由系统决定"并入 **F21** 登记 |
| **O-7** | `WDPullToRefresh` 的自绘下拉环 | 规格要求自绘环 + Reduce Motion 静态环 | 自绘需接管滚动手势（与系统冲突、焦点/键盘自管） | **默认 `.refreshable`（系统视觉）+ 登记差异**；设计若坚持自绘，**M4 前**给结论（不阻塞 M0–M4） |
| **O-9** | 高对比度的第 2/3 条补偿 | §3.2 的三条（玻璃不透明 / 描边加粗 / 次要文字提质） | 第 2/3 条会改对比度账目与视觉档 | 只做第 1 条（玻璃→不透明）；第 2/3 条排 **M4 + 设计签发** |
| **disabled 对比度（IOS-06，**已决**）** | `state.disabled.alpha = 40%` 是否豁免对比度 | `contracts/contrast.json` 的达标要求 vs 40% 透明在浅底上易低于 3:1 | **阻塞 M0-1**：M0-1 是唯一一次 schema 冻结窗口，推到 M2 = 二次 breaking | **已决（用户决策 #3）**：**新增 `text.disabled` 色槽 ⇒ U12 = 32 槽位、两端计数断言同步**（M0-1 内冻结；色值由设计给）；~~方案 ② 维持 40% opacity + `contrast.json` 豁免~~ 已否决。配套 **F45** 登记两端机制差异 |

### 7.3 本轮**已判定、不再征求**的三项（避免"待定"式结论）

1. **`letterSpacing` 单位 = pt/sp 等价、不随字号缩放**（O-3）：iOS `.tracking(0.6)`、Android `0.6.sp`，契约写同一句；
2. **Q-i1/Q-i2 的默认执行项**（删 `tertiary`、不引 `presentationSizing`）：**不等设计答复**，按默认实现，设计如有异议走变更；
3. **CR-3 不做新组件**：撤销条走配方，`WDToast` 只需支持 ≥5000ms。

---

## 8. 未决项与未闭合验证项（归属角色 + 是否阻塞 M0）

### 8.1 未决项（需要他人拍板，但**每项都有默认执行项**，因此不阻塞开工）

| # | 未决项 | 归属角色 | **是否阻塞 M0** | 默认执行项 |
| --- | --- | --- | --- | --- |
| D-1 | U10 输入集合加 `contrast`（CR-6） | 架构师 + android-lead | **是**（契约冻结窗口只有一次） | 先按含 `contrast` 实现（iOS 读 `colorSchemeContrast`，Android 读系统开关，<34 恒 false） |
| D-2 | U3 槽位词表冻结（CR-7） | 架构师 + android-lead | **是** | 先按 §2.10 的 **21 名**词表 + `{组件 → 槽位名 \| 无}` 表 |
| D-3 | U5 验收表述改带容差 `max` + 分语种 fixture（CR-8） | tech-lead + 架构师 + android-lead | **是** | 先按 §2.6.3 的 U5-a…d 与定稿措辞 |
| D-4 | 类型名清单进 contracts + Android `WDSheet` 改名（CR-4/B7b/IOS-03） | tech-lead + android-lead | **是** | 先按 `WDBottomSheet`/`WDActionSheet` + `WDBottomSheetDetent(s)`；清单随 M0-5 落库（声明层不得出现 `WDSheet*`，含 typealias） |
| D-5 | 令牌冻结清单扩项（CR-10；§1.4.1 的 M0-1 清单 17 行） | 设计 + 架构师 + 技术负责人 | **是** | 先按 §1.4.1 的 M0-1 清单（17 行）逐行二选一执行 |
| D-6 | `07:190` 的"+2 余量"口径勘误 | tech-lead | 否（文档） | 下版勘误为"按 U5 公式拉丁侧最小余量 `caption2` +0.04pt" |
| D-7 | 37 组件默认值两端对照与差异裁决（I23c） | android-lead + 架构师 | **是**（同一冻结窗口） | 先按 §2.10 矩阵的 iOS 默认值；差异进 `contracts/<component>.yaml` |
| D-8 | `letterSpacing` 单位的设计确认（O-3，已判定 pt） | 设计 | **是** | 先按 pt/sp 等价实现，契约同句 |
| D-9 | CR-1 TextField 46 的验收句改写 | tech-lead + 设计 | 否（**阻塞 M2**） | 先按 §2.3 的定稿验收句 |
| D-10 | CR-2 Sheet 两条验收标"iOS 不适用" | 设计 | 否（阻塞 M4） | 先按 §2.5-3 加注 + 补 iOS 专属验收 |
| D-11 | CR-3 撤销条的规格改写 + `WDToast` duration ≥5000ms | 设计 | 否（阻塞 M4 的 Toast） | 先按 §7.2-CR-3 执行 |
| D-12 | CR-5 方向契约回写 3 处文档 | 设计 + 架构师 | 否 | 先按 §3.4 的一句契约；iOS 实现已正确 |
| D-13 | `text.disabled` 的**色值**（IOS-06；**槽位数已决 = 32**） | 设计 + 架构师 | **是（阻塞 M0-1，不是 M2）** | **已决（用户决策 #3）：新增 `text.disabled` 色槽 ⇒ U12 = 32 槽位**，两端计数断言同步、**不豁免**对比度；设计需给**该槽位的色值**，未给按默认执行项先冻结；两端机制差异登记 **F45** |
| D-14 | O-9 高对比第 2/3 条 | 设计 | 否（M4） | 先只做第 1 条 |
| D-15 | O-7 `WDPullToRefresh` 是否自绘 | 设计 + iOS | 否（M5；M4 前给结论） | 先按 `.refreshable` + 登记差异 |
| D-16 | Q-i1/Q-i2 的设计复核 | 设计 | 否（默认已执行） | 见 §7.3 |
| D-17 | 金标设备选型（快照/审计固定机型与运行时） | tech-lead | 否（nightly 前） | 先按 `resolve_sim` 取最新可用设备跑 PR；金标另写 `Baselines/manifest.json` |
| D-18 | D-i2 验收句"不得要求 iOS 侧恢复状态"进 acceptance | 架构师 | 否（但 M0-5 同批最省） | 随 M0-5 一起落 |
| **D-19** | **门禁命令首次跑通后固化 scheme 名** | iOS + tech-lead | **是**（M0 出口项⑧"门禁生效"依赖它） | **2026-10-06 已回填**：实测固化 = `WisdomDesign-iOS-Package`（包级聚合 scheme = <包名>-Package；原候选名 `WisdomUI-Package` **不存在**）；已写进 README 的「三个已固化的值」与 `Scripts/ci.sh` 常量 |
| D-20 | Android 侧 `label` 改必填（CR-9） | android-lead | 否（跨端一致，M0-5 前） | iOS 保持必填；Android 侧同批改 |
| D-21 | 覆盖率转门槛时点与 `generated/` 排除 | tech-lead | 否（M3） | M3 起门槛；`Foundation/**` ≥80%（排除 `generated/`） |
| D-22 | `verification-metadata`/供应链（仅 Android 相关） | android-lead | 否 | 与 iOS 无关，本文不展开 |

### 8.2 未闭合验证项（跑不了、只能推导；**不得在下游写成结论**）

| # | 项 | 归属角色 | **是否阻塞 M0** | 验证动作 |
| --- | --- | --- | --- | --- |
| N-1 | `docs/06-accessibility.md:118` 的"AX3 ≈ 175%" | iOS | 否（阻塞 M1 的 fixture） | 真机/模拟器用 `UIFontMetrics` 实测 12 档 × 12 字阶系数表，固化 `DynamicTypeFixture.swift`；**禁止写死百分比** |
| N-2 | `xcodebuild` 门禁从未跑通 —— **2026-10-06 已跑通（本项闭合）** | iOS | **是**（M0 出口项⑧） | 实测：`Scripts/ci.sh pr` EXIT=0（PR-1b `passed=4 failed=0`）；**根因与修法已固化进脚本**（SwiftPM manifest 缓存写在家目录、受限环境不可写 ⇒ `CFFIXED_USER_HOME` 钉进 `.build/home/`，见 `Scripts/ci.sh` 文件头差异①）。历史定位：`01-ios-review.md` §7-5 已定位失败点 = SwiftPM manifest 缓存（`~/Library/Caches/org.swift.swiftpm/manifests/ManifestLoading/ios.dia`）⇒ 脚本显式固化缓存/派生目录 |
| N-6 | SPM tag 移动的失败模式（REL-5） | iOS | 否（发布前） | 政策无条件成立；失败模式（解析失败 vs 静默换版）需一次实验 |
| N-7 | **iOS 侧**字体自然行高实测（review §7-14 是 macOS 侧，同一字体文件但以 iOS fixture 为准） | iOS | 否（**阻塞 M1** 的 U5 fixture） | `LanguageLineBoxFixture.swift` 的字体级 + 渲染级两步测量（§2.6.3） |
| N-8 | `swift-format` 规则集跨 Xcode 版本漂移 | iOS | 否 | 记录工具链版本；升级时格式漂移单独 PR |
| V-1 | Swift Testing 在 `xcodebuild test` 下的发现（**已降级**） | iOS | 否 | `Testing.framework` 已在模拟器平台（`[组长实测]`）；剩余 = scheme test action 接线 + 一次真跑；快照 suite `.serialized` + `@MainActor` |
| V-2 | 密文/明文切换保持焦点与光标 | iOS | 否（阻塞 M2） | 默认"单实例 + 自绘密文 + `TextField(text:selection:)`"+ 1 条单测；不可行则降级并标注 |
| V-3 | Sheet 键盘避让 + iPad 宽度 | iOS | 否（阻塞 M4） | iPad/iPhone 各一次 XCUITest（字段 frame 在键盘 frame 之上）；宽度按 F21 登记 |
| V-4 | Release 零预览代码的**符号级**断言 | iOS | 否 | 复用 PR-3 工具链对 Release 产物 `swift-symbolgraph-extract`，断言无 `*Preview*` |
| V-5 | `WDStructureCheck` 插件可用性（**M0 不 attach 后降级为可选**） | iOS | 否 | M0 后任一时间验证；失败则保持"仅脚本" |
| V-6 | Xcode Previews 对 `WD_PREVIEWS` 的实际行为 | iOS | 否 | 首次打开 `WDButton+Previews.swift` 时确认 |
| V-7 | 行盒缓存收益 | iOS | 否 | **M1 不做缓存**；将来若加，需命中率数据 |
| V-8 | 检查器实现的边界行为（macOS 10.13 API 约束、正则、注释剥离） | iOS | 否（随 PR-0 交付） | `Scripts/Fixtures/{pass,fail}/*.swift` + `Scripts/test-checker.sh`：R1–R21 各一正一反；归属已核（`onGeometryChange`/`phaseAnimator`/`Layout` 在 SwiftUICore；`containerRelativeFrame` 在 SwiftUI） |
| V-9 | `ButtonStyle` 内直接 `@Environment` 的注入行为（I19） | iOS | 否 | 已用 `_WDButtonChrome` 安全形态兜住；验证只影响能否简化 |
| V-10 | `orderedImports` 对 `#if` 块内 import 的实际行为（I11） | iOS | 否 | 首次 `check-format.sh` 跑通时确认 |
| V-11 | 真实耗时（`ci.sh measure` 三次中位数）—— **2026-10-07 已跑通（本项闭合）** | iOS | **是**（M0 出口项的门禁预算表） | 实测：`Scripts/ci.sh measure 3 --states=warm,clean,cold`，三态各自 n=3 中位数 = **7.98 / 14.46 / 58.88 s**，已写进 `iOS/README.md` 与 §1.5.2；原始数据 `.build/perf/ci-measure-20261007.json` |

> **未闭合项的处理纪律**：以上任一项在 M0 出口验收时若仍无法跑通，**按"未验证"记入 M0 出口报告**（不隐瞒、不用"待定"掩盖），并按 §8.1 的默认执行项继续推进后续里程碑——**唯一例外是 N-2/D-19/V-11（门禁首次跑通）**，它们是 M0 出口项⑧的直接依赖，必须先解决。

### 8.3 本轮（R3-01/R3-02/R3-03 + C-15 定名对齐）的新增未决项与未闭合验证项

| # | 项 | 归属 | **是否阻塞 M0** | 验证动作 / 默认执行项 |
| --- | --- | --- | --- | --- |
| R3-a | `WDCardStyle`/`WDToastVariant`/`WDBannerVariant` 的**归一化集合断言**尚未实测（本轮只补声明与断言文本） | ios-dev（实现）+ 架构师（契约） | 否（阻塞 **M2** 的 `WDCard` 签名冻结） | M0-5 落 `contracts/{WDCard,WDToast,WDBanner}.yaml` 时用 `allCases.map(\.rawValue)` 对照契约；默认值 `.elevated`/`.neutral`/`.info` 逐字一致（§2.11） |
| R3-b | `WDSearchField` 的 `leadingIcon`（R3-02）**两端形态不同**（iOS 值参数 `WDIconName?` / Android `@Composable` 槽） | 架构师（F48 登记）+ t19（Android 复核） | 否 | 名称已两端同名（U3）；**形态差异归 F48**（§2.10 分类副表已列该行），不再开新 U 项 |
| R3-c | 21 名**分类副表**（R3-03）需与 Android `12-android-spec.md` §2.4 的形态列**逐行核对** | t19（Android 副本）+ 架构师 | 否（阻塞 **M0-5** 契约冻结） | 本表 iOS 形态列以本规格签名为准；Android 形态列由 t19 按 `12` §2.4 复核后并入 `contracts/README.md` 的“槽位词表 + 分类”节 |
| R3-d | C-15 的 iOS 改名仅 **1 行**（`WDCheckbox.isOn` → `isChecked`）；Android 侧 **14 行**改名进度 | android-dev（t19 复核）+ 架构师 | 否（阻塞 **M2** 的 `WDCheckbox`） | iOS 已改（§2.10-#06 + `03-ios-defaults-table.md` §3.06/§5.1）；Android 改完前 `contracts/WDCheckbox.yaml` 的 `params[].name` 不得冻结 |
| R3-e | **存疑项 = 0 项**（`40-contract-names.md` §3 已声明“每行都有设计口径锚点”） | — | — | 若设计对 `presented` vs `visible`、`on` vs `checked` 的用词另有偏好，走“改 U 项”流程（§6.6 治理），**默认按 C-15 表执行** |
| R3-f | `xcodebuild` 全链路仍未跑通（scheme 名、PR-0/1/2 真实耗时、覆盖率报告） | ios-lead | **是**（见 §8.2 的 N-2/D-19/V-11） | 与既有未闭合项同一路径，不重复登记；三个枚举与 `isChecked` 改名的**编译级**验证随 M0-11 冒烟与 M2 首批一并完成 |

> **（t25 追加）** 本轮（§4.2 的 F 副本同步 F48–F50 + F46/F47 状态句）**只改** `02-ios-spec.md` 一个文件；`12-android-spec.md`、`40-contract-names.md`、`20-ios-leader-review.md` 与三仓（`iOS/`/`android/`/`wisdomdesign/`）均未改动。
> **三仓与只读文件声明（t21 本轮）**：本轮**只改** `02-ios-spec.md` 与 `03-ios-defaults-table.md`；`iOS/`、`android/`、`wisdomdesign/` 三仓 `git status --porcelain` 均为空；``、`12-android-spec.md`、`40-contract-names.md` 只读未改（`40-contract-names.md` 是 C-15 唯一真源，本规格 §2.10 是其**只读副本**：先改真源再同步副本）。

---

## 9. 验证记录与 M0 可开工清单

### 9.1 本轮验证记录（`[实测]`）

| # | 命令 | 结果 |
| --- | --- | --- |
| 1 | `test -s 02-ios-spec.md` | ✅ 通过（1329 行 / 129 KB） |
| 2 | `grep -c '^## ' 02-ios-spec.md` | ✅ = 22（契约要求 ≥8；其中 9 个是本文的编号章节，其余 8 个在 PR 模板代码块内） |
| 3 | `test -z "$(git -C iOS status --porcelain)"` | ✅ 通过（iOS 仓零改动） |
| 4 | `git -C android status --porcelain` / `git -C wisdomdesign status --porcelain` | ✅ 均为空 |
| 5 | `find <跨端工作区文档集（已退役）> -type f -newer 01-ios-review.md` | ✅ 空输出 ⇒ 该工作区下无任何入库文件被触碰（原路径字面量按迁移纪律不复写） |
| 6 | 表格列一致性 `awk` + 占位符 `grep` | ✅ 无残留 `<!-- Sn -->`；GFM 转义竖线处的列数告警为预期（`\|`、`|高度−…|` 写法） |
| 7 | 引用行号抽查（`specs/01-basic.md:239,316,1652-1653,1660-1662,1688,1690,1715,1739`、`specs/02-advanced.md:555,565,569,584,586,587,594,600,639,640,822`、`docs/06-accessibility.md:118,122-131,183-191,196`、`tokens/wisdom.tokens.json:183-194,231,292-295`） | ✅ 逐条与文件实际行内容一致（t1 复核 + 本轮沿用；未改数据源） |

**跑不了、只能推导的（不得默认成立）**：`xcodebuild build/test`（沙箱 + SwiftPM manifest 缓存）、模拟器渲染与 `sizeThatFits` 真实数值、`ButtonStyle` 内 `@Environment` 注入行为、Swift Testing 在 scheme 下的发现、真机 hitch/归档体积、iOS 侧字体自然行高（t2 §7-14 是 macOS 侧）。全部已登记为 §8.2 的未闭合项。

### 9.2 M0 可开工清单（iOS 侧；对齐 `07-summary.md` §6.1 的 M0-1…M0-10 + 新增 M0-11）

| # | 任务 | 落点 | 依赖 | 验收命令 |
| --- | --- | --- | --- | --- |
| **I-M0-a** | `Package.swift` 改造：`swiftLanguageModes: [.v6]` + `swiftSettings`、**去掉 `plugins:`**、拆测试 target 依赖、加 `wd-structure-check` | `iOS/Package.swift` | — | `xcodebuild -list`（首次跑通后固化 scheme） |
| **I-M0-b** | 结构检查器实现：R1–R21 + 注释/字符串剥离 + 标识符边界 + 豁免语法 | `iOS/Sources/wd-structure-check/main.swift`、`iOS/Scripts/check-structure.sh` | I-M0-a | `Scripts/test-checker.sh`（`Scripts/Fixtures/{pass,fail}` 各一正一反） |
| **I-M0-c** | 格式门禁 | `iOS/.swift-format`、`iOS/Scripts/check-format.sh` | — | `Scripts/check-format.sh`（显式清单排除 `generated/`） |
| **I-M0-d** | 签名冒烟（**M0-11**，IOS-01/IOS-10） | `iOS/Sources/WisdomUI/APISurface/WDAPISurface.swift`（`#if WD_API_SMOKE`，**只放尚未实现的声明**，排除 `WDTextStyle`/`WDShadowLayer`/`WDGradientSpec`/`generated/**` 全部类型，见 §1.2.2 排除清单） | 本文 §2–§3 | **并入 PR-1 的 `build-for-testing` 同一次调用**（`SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'`），不新增编译；退役规则见 §1.2.2 |
| **I-M0-e** | API 冻结链路 | `iOS/Scripts/{dump-api.sh,canonicalize-api.swift}`、`iOS/api/WisdomUI.api.json` | I-M0-a | `Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json` |
| **I-M0-f** | 门禁脚本与 workflow | `iOS/Scripts/ci.sh`、`iOS/.github/workflows/ci.yml` | I-M0-b/c/e | `Scripts/ci.sh pr`（首次跑通 = N-2/D-19/V-11 闭合） |
| **I-M0-g** | 契约读取与跨仓自证 | `iOS/Tests/WisdomUITests/Support/WDContracts.swift`、`Scripts/check-structure.sh` 的 `--tokens-trace` | 架构师的 `contracts/dist/*.json` + `tokens.manifest.json` | `WDContracts.tokenManifest()` 断言 `sha12` 相等；缺失 = fail |
| **I-M0-h** | 令牌冻结的 iOS 落点（等 M0-1/M0-2 完成后同批） | `Foundation/generated/{WDTokensVersion.swift, WDColorSlots.swift, WDIconName.swift}`、`Foundation/Tokens/WDTokenTypes.swift`（`WDTextStyle` 4 字段） | 设计仓 M0-1/M0-2 | `build.js --check` 绿 + `--tokens-trace` 绿 |
| **I-M0-i** | README/CONTRIBUTING/PR 模板/CODEOWNERS | `iOS/README.md`（删 `swift build/test`、写门禁与预览限制）、`iOS/.github/{pull_request_template.md,CODEOWNERS}` | — | `git grep -nE 'swift (build\|test)' -- . \| grep -v -- '-product wd-structure-check'` 为空（**t46 实测**：当时命中 `README.md:51-52`；**本轮已删** ⇒ 本条判据的范围 = `README.md`/`CONTRIBUTING.md`/`Examples/**`/`.github/**`，实测 **0 命中**）。**判据范围注**：写成 `-- .` 会把 `AGENTS.md`/`docs/**` 的**正文**命中（"不要跑 X"这类说明文字）一并算入，该写法**恒非空**；按 §6.1-7 给的范围执行才是本条 |
| **I-M0-j** | 版本治理 | `iOS/CHANGELOG.md`（Keep a Changelog + Breaking 段）、`Examples/BaselineShell/`（空壳基线） | — | 发布 checklist 可勾 |
| **I-M0-k** | 门禁预算测量 | `Scripts/ci.sh measure` → `iOS/README.md` + 本文 §1.5.2 | I-M0-f | 三次中位数写回；**未测不写预算** |

### 9.3 iOS 侧 M0 出口判定（**6 条，逐条可验**）

1. `Scripts/check-structure.sh` 绿（R1–R21）+ `Scripts/test-checker.sh` 绿（R1–R21 各一正一反）；
2. `Scripts/check-format.sh` 绿；基线格式化提交**先于** `api/WisdomUI.api.json` 首次入库；
3. `Scripts/ci.sh pr` 首次全绿（含 `WD_API_SMOKE` 签名冒烟 + `WisdomUITests` + 覆盖率报告）⇒ **N-2/D-19/V-11 闭合**；
4. `api/WisdomUI.api.json` 入库且与当次编译一致（`git diff --exit-code` 绿）；
5. `--tokens-trace` 与跨仓 `tokens.manifest.json` 断言绿（`sha12` 相等，缺失 = fail）；
6. 库/测试侧 `swift build/test` 零命中：`git grep -nE 'swift (build\|test)' -- . | grep -v -- '-product wd-structure-check'` 为空（host 工具白名单见 §1.1.1；**路径主语必须是仓内 `.`——原 `-- iOS/` 在 `iOS/` 仓内是错的，会假绿**；**t46 实测**：当前命中 `README.md:51-52`）；`Package.swift` 不含 `plugins:`、不含 macOS 平台、显式 `v6`。

> 本文是 `t5` 的交付物，是 iOS 侧的**收敛规格**（不是讨论稿）：§1–§3 是最终形态，§5 是对 `01-ios-review.md` 的逐条回应，§7 是需改判项，§8 是未决与未闭合项。凡与 `08-decisions.md`/`07-summary.md` 冲突的，已在 §7 集中列出并给默认执行项，**没有静默偏离**。下一阶段（开发计划）可直接引用 §9.2 的 11 条任务排期。
>
> **回写记录（`t43`，开发计划 §5.9 的 P9 落地 —— iOS 侧）**：① §3.2 新增 **P9 scheme 维度落地条目**（多套生成 scheme + 运行时选择；`schemes: {light,dark,…}` + `--schemes`；`WDColorSlot` **32 槽位**；不支持运行时任意 `token.json`/服务端下发/逐槽位覆盖；`Q-A2` 不重开；切换不重启进程 + 高频路径禁令；口径来源 = `30-dev-plan.md` §5.8）；② **32 槽位口径收敛**：§1.4.1-#17、§2.6.1、§3.1、§3.2 的 F45 行、§6.2-U12、§7.1、§8.1-D-13 共七处从两态表述统一为"**已决 = 32 槽位（含 `text.disabled`）**"，并把 §1.4.1 规则行的清单构成标签统一为"**已决项 1 项**"（第 17 行）。
> **本轮只改本文件**；`iOS/`、`android/`、`wisdomdesign/`、跨端工作区文档集（**已退役**）与其余 `**`（含 `12-android-spec.md`、`30-dev-plan.md`、`40-contract-names.md`）均未改动（**注**：这几份退役文件的现等价物 = 本仓 `DEV-PLAN.md` 与 `android/docs/SPEC.md`）。
>
> **回写记录（`t46`，F-03 授权的命令修正）**：把 `-- iOS/` 的错误 pathspec 改为仓内 `-- .`（形如 `git grep -nE 'swift (build\|test)' -- . | grep -v -- '-product wd-structure-check'`），共 4 处：**§6.1-7**（硬约束 7 验收句）、**§9.2 的 I-M0-i**、**§9.3-6**（M0 出口第 6 条）、**§5 §I45 行**（grep 目标扩到全仓）。实测：**正确写法当前命中 `README.md:51`（`swift build`）/`:52`（`swift test`）**，M0-i 删掉这两行后应为空；**原 `-- iOS/` 写法在本仓 0 命中（假绿）**——这正是 F-03 的成因。本轮仅动本文件的上述 4 行。
