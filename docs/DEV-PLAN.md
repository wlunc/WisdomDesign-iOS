# DEV-PLAN.md · WisdomUI（iOS）详细开发计划（**自包含**）

> **本文件是 iOS 端的详细开发计划，自包含**：所需口径全部内联在本文件内，**不依赖仓库外的任何文档**。跨端规格/计划类文件（`02-ios-spec.md`、`40-contract-names.md`、`30-dev-plan.md` 等，**均已退役**）由各自的负责人维护，本文件只在"回写项"一节按**文件名 + 章节号**记录"谁该改哪里"，**不复制其正文、也不作为运行期依赖**。
> **仓内配套**：`../AGENTS.md`（agent 操作手册：入口/禁止项/升级路径）与 `ARCHITECTURE.md`（结构与数据流，含 8 张图）——本文件与它们是**分工关系**，见 §11；重叠处只给章节号指针，不重复大段内容。
> **组织方式（进程优先）**：本计划以「**顺序 + 入口判据 + 出口判据 + 门禁强度 + 依赖**」为骨架。**人日 / 周数如需出现一律标【参考信息】，既不是承诺也不是验收判据**。
> **路径写法**：本仓内相对路径（如 `Sources/...`）；本文件自身位于 `iOS/docs/`。

---

## 目录（可跳转；条目与正文标题一一对应）

- [目录（可跳转；条目与正文标题一一对应）](#目录可跳转条目与正文标题一一对应)
- [0. 30 秒速览](#0-30-秒速览)
- [1. 本端定位与范围](#1-本端定位与范围)
- [2. 里程碑 M0–M6：本端视图](#2-里程碑-m0m6本端视图)
  - [2.1 M0 — 工程基建（无组件交付）](#21-m0--工程基建无组件交付)
  - [2.2 M1 — 基础设施（无组件交付）](#22-m1--基础设施无组件交付)
  - [2.3 M2 — 首批 11 件（**关键路径 2 件串行在前**）](#23-m2--首批-11-件关键路径-2-件串行在前)
  - [2.4 M3 — 封板批次（1 件 + 公开 API 冻结）](#24-m3--封板批次1-件--公开-api-冻结)
  - [2.5 M4 — 反馈与弹层（9 件）](#25-m4--反馈与弹层9-件)
  - [2.6 M5 — 导航与表单（15 件）](#26-m5--导航与表单15-件)
  - [2.7 M6 — 场景组件与发布（1 件 + 回归）](#27-m6--场景组件与发布1-件--回归)
- [3. 批次分配（本端逐组件 + 批前冻结 / 出口）](#3-批次分配本端逐组件--批前冻结--出口)
- [4. 命令与门禁（可直接复制）](#4-命令与门禁可直接复制)
  - [4.1 PR 门禁（每次提交必过）—— `M0-6 起`](#41-pr-门禁每次提交必过-m0-6-起)
  - [4.2 nightly 门禁（每批强制；**连续 3 日绿**才算批出口）—— `M0-6 起`（demo 项 `M1 起`）](#42-nightly-门禁每批强制连续-3-日绿才算批出口-m0-6-起demo-项-m1-起)
  - [4.3 发布前门禁 —— `M6 起`](#43-发布前门禁--m6-起)
  - [4.4 M0 前唯一可跑回路 —— `现成`](#44-m0-前唯一可跑回路--现成)
  - [4.5 门禁强度与出口的对应](#45-门禁强度与出口的对应)
  - [4.6 文档类改动也要过 verify（**本仓纪律**）](#46-文档类改动也要过-verify本仓纪律)
- [5. 冻结值与本端契约](#5-冻结值与本端契约)
  - [5.1 值与口径（本端最终值）](#51-值与口径本端最终值)
  - [5.2 主题、换肤与无障碍（本端口径）](#52-主题换肤与无障碍本端口径)
  - [5.3 受控值名（C-15 内联，37 行；**本端参数名以本表为准**）](#53-受控值名c-15-内联37-行本端参数名以本表为准)
- [6. 规格回写项（本端相关；**改哪个文件哪一节 + 状态**）](#6-规格回写项本端相关改哪个文件哪一节--状态)
- [7. 设计待给值 / 待签发（**本端入口**）](#7-设计待给值--待签发本端入口)
- [8. 风险与未验证清单（**不得写成"已通过"**）](#8-风险与未验证清单不得写成已通过)
  - [8.1 未验证项（本端）](#81-未验证项本端)
  - [8.2 技术与协作风险（本端相关）](#82-技术与协作风险本端相关)
- [9. 关键路径与跨端依赖](#9-关键路径与跨端依赖)
- [10. 变更与发布](#10-变更与发布)
- [11. 与仓内另两份文档的分工](#11-与仓内另两份文档的分工)
- [12. 本文件的验证记录](#12-本文件的验证记录)
- [13. 逐组件索引（37 件 checklist）](#13-逐组件索引37-件-checklist)
  - [13.1 索引表（37 行，按批次；**列 = 可勾选 checklist**）](#131-索引表37-行按批次列--可勾选-checklist)
  - [13.2 使用方式与纪律](#132-使用方式与纪律)
- [14. 单组件作业流程（SOP：从 0 到合并）](#14-单组件作业流程sop从-0-到合并)
  - [14.1 ① 选件与读规格](#141-①-选件与读规格)
  - [14.2 ② 落点与文件清单](#142-②-落点与文件清单)
  - [14.3 ③ 骨架与关键实现要点](#143-③-骨架与关键实现要点)
  - [14.4 ④ 测试怎么写（六类必需断言）](#144-④-测试怎么写六类必需断言)
  - [14.5 ⑤ 本地跑什么（秒级回路）](#145-⑤-本地跑什么秒级回路)
  - [14.6 ⑥ PR 前跑什么（门禁）](#146-⑥-pr-前跑什么门禁)
  - [14.7 ⑦ PR 与评审要求](#147-⑦-pr-与评审要求)
  - [14.8 ⑧ 批前冻结与批出口](#148-⑧-批前冻结与批出口)
- [15. 验收手册（逐批：判据 · 命令 · 处置）](#15-验收手册逐批判据--命令--处置)
  - [15.1 M0 验收](#151-m0-验收)
  - [15.2 M1 验收](#152-m1-验收)
  - [15.3 M2–M6 验收](#153-m2m6-验收)
  - [15.4 每批一次的检查清单（可勾选）](#154-每批一次的检查清单可勾选)
- [16. 开发者指南](#16-开发者指南)
  - [16.1 环境与工具链准备](#161-环境与工具链准备)
  - [16.2 代码风格与命名](#162-代码风格与命名)
  - [16.3 提交信息与分支模型](#163-提交信息与分支模型)
  - [16.4 常见错误与排查（Troubleshooting）](#164-常见错误与排查troubleshooting)
  - [16.5 遇到阻塞找谁（升级路径）](#165-遇到阻塞找谁升级路径)
- [17. 术语表](#17-术语表)
- [18. 关键决策摘要](#18-关键决策摘要)
- [19. 设计文档与设计图查阅指南](#19-设计文档与设计图查阅指南)
  - [19.1 设计仓结构与只读纪律](#191-设计仓结构与只读纪律)
  - [19.2 每份设计文档回答什么问题](#192-每份设计文档回答什么问题)
  - [19.3 按任务查场景到章节](#193-按任务查场景到章节)
  - [19.4 检索命令复制即用](#194-检索命令复制即用)
  - [19.5 设计文档与仓内文档的关系](#195-设计文档与仓内文档的关系)
- [20. 逐组件设计溯源表](#20-逐组件设计溯源表)
  - [20.1 怎么用三步](#201-怎么用三步)
  - [20.2 溯源表 37 件](#202-溯源表-37-件)
  - [20.3 关于实测命中数与锚点](#203-关于实测命中数与锚点)
  - [20.4 视觉规格速查](#204-视觉规格速查)
- [21. 从设计规格到实现与验收](#21-从设计规格到实现与验收)
  - [21.1 设计规格 12 节到本端产出](#211-设计规格-12-节到本端产出)
  - [21.2 画廊核验六步](#212-画廊核验六步)
  - [21.3 画廊能核什么不能核什么](#213-画廊能核什么不能核什么)
  - [21.4 截图存档批出口硬要求](#214-截图存档批出口硬要求)
  - [21.5 M2 十一件「实现前自检十问」](#215-m2-十一件实现前自检十问)
  - [21.6 M3–M6 各件「实现前自检十问」（26 件）](#216-m3m6-各件实现前自检十问26-件)
- [22. 文档变更历史](#22-文档变更历史)

**目录自检（可复制；条目与标题 1:1、悬空 = 0；**GitHub slug 规则**）**：

> **slug 规则（与 GitHub 一致；R2-01 修正）**：标题 → **小写** → **去掉标点**（保留中日韩字符与数字）→ **每个空格转一个 `-`** → **不折叠连续 `-`**。
> 例：`### 2.1 M0 — 工程基建（无组件交付）` ⇒ `#21-m0--工程基建无组件交付`（`—` 两侧各一个空格 ⇒ **两个连字符**）。**旧版自检折叠了连续连字符 ⇒ 会给假绿**，这正是 R2-01 的成因；**判据以本条命令为准**。

```bash
python3 - <<'PY'
import re
p = 'iOS/docs/DEV-PLAN.md'
t = open(p, encoding='utf-8').read()
PUNCT = '（）()【】《》「」“”"\u2019\u2018\u0027·:：,，、;；!！?？|/\\+%$&*=~^`<>[]{}#.。—–'
def slug(x):
    x = x.lower()
    x = ''.join(' ' if c == ' ' else ('' if c in PUNCT else c) for c in x)
    return x.replace(' ', '-').strip('-')      # GitHub 规则：不折叠连续 '-'
h = [l[len(l) - len(l.lstrip('#')) + 1:].strip() for l in t.split('\n') if re.match(r'^#{2,3} ', l)]
a = re.findall(r'\]\(#([^)]+)\)', t)
hs = {slug(x) for x in h}
print('标题', len(h), '目录', len(a), '缺条目', [x for x in h if slug(x) not in a], '不匹配', [x for x in a if x not in hs])
PY
```

> 期望输出：`缺条目 [] 不匹配 []`（标题数 = 目录数）。**每次增删标题后必须重跑本命令**并同步本目录。
> ⚠️ **这条命令的规则必须与 GitHub 一致（不折叠 `-`）**：若改成"折叠连续连字符"，14 条含 `—`/`/`/`+` 的标题会**假绿**（详 §4.6 的固定项 ⑦）。

---

## 0. 30 秒速览

| 问题 | 答案 |
| --- | --- |
| 本端交付什么 | 一个 SwiftPM 包 `WisdomUI`（单发布 product），内含 **37 个组件**（20 primitives + 17 composites）+ Foundation 层 |
| 怎么开工 | 看 §2 的当前里程碑**入口判据**（I-1…I-5，全部满足才动手）与 §4 的**现成命令** |
| 怎么算做完 | 看该批的**出口判据**（§2/§3）＋门禁（§4）全绿；**不使用完成度百分比** |
| 什么已冻结 | §5（含 37 行受控值名内联表） |
| 什么不能自行决定 | 设计待给值（§7）按**默认执行项冻结**，不得自定值；U 系列/契约类改动走 §9 的流程 |
| 现在最容易被卡住的地方 | §9 的关键路径（令牌冻结 → 生成器 → 契约/注册表落库 → 批前签名冻结） |

**三个"不要"**（完整清单见 `../AGENTS.md` §10）：① 不要跑 `swift build` / `swift test`（本包只声明 iOS 平台，host 侧必然编译失败）；② 不要手改 `Sources/WisdomUI/Foundation/generated/**`（只允许生成器写）；③ 不要跨仓写入（`../android/**`、`../wisdomdesign/**` 只读）。

---

## 1. 本端定位与范围

**交付物**：SwiftPM 包 **`WisdomUI`**（唯一发布 product；`WisdomUIPreviews` 只供预览，**不进 products**；`wd-structure-check` 是 host 侧结构检查器，**不得依赖 `WisdomUI`**）。

**范围（37 件组件，两端各自实现同名同签名的全部 37 件）**

| 层 | 数量 | 内容 |
| --- | --- | --- |
| `Components/Primitives` | **20** | `WDButton`、`WDIconButton`、`WDTextField`、`WDSearchField`、`WDSwitch`、`WDCheckbox`、`WDRadio`、`WDSlider`、`WDStepper`、`WDChip`、`WDBadge`、`WDAvatar`、`WDAvatarStack`、`WDDivider`、`WDProgressBar`、`WDProgressRing`、`WDCard`、`WDListRow`、`WDListSection`、`WDIcon` |
| `Components/Composites` | **17** | `WDSegmentedControl`、`WDPicker`、`WDDatePicker`、`WDFormRow`、`WDAlert`、`WDBottomSheet`、`WDActionSheet`、`WDToast`、`WDBanner`、`WDEmptyState`、`WDSkeleton`、`WDPullToRefresh`、`WDNavigationBar`、`WDTabBar`、`WDToolbar`、`WDFAB`、`WDAssigneePicker` |
| `Foundation`（层 0） | — | 令牌（含生成物）、主题、排版、布局、动效、材质、无障碍、图标帮助函数 |
| `Internal` | — | 内部实现，**零 `public`** |
| 测试 | — | `WisdomUITests`（逻辑/契约/无障碍断言）＋ `WisdomUISnapshotTests`（六态快照） |

**不在本端范围**：Android 模块、设计令牌仓库（`wisdomdesign/**`，只读消费）、契约文件库（M0-5 起真源迁入设计仓的 `contracts/README.md`；本端按只读副本执行）。

**硬边界**（与 `../AGENTS.md` §1 的可写/不可写表一致）：`generated/**` 只能由生成器写；库内**零资源、零文案、零第三方依赖**；组件枚举/签名一旦进入"批前签名冻结"即按 §10 的兼容性规则管理。

---

## 2. 里程碑 M0–M6：本端视图

> **通用入口判据 I-1…I-5**（每个里程碑开工前逐条自检，详见 `../AGENTS.md` §3.1）：I-1 上一里程碑出口已判定；I-2 **批前签名冻结**通过（该批每件组件的完整签名 + 契约条目 `params`/`slots`/`default` 落库）；I-3 该批依赖的**令牌/契约已冻结**（含 `schemes` 维度、32 色槽位、C-15、U3/F 注册表）；I-4 门禁在本仓可跑且为绿；I-5 未闭合前置项均有默认执行项。
> **门禁强度三档**：`PR` = 每次提交必过（§4.1）；`PR+nightly₃` = 还要 nightly **连续 3 日绿**；`PR+nightly₃+发布前` = 再加真机/归档层。

### 2.1 M0 — 工程基建（无组件交付）

**本端任务（11 项，全部在 M0 内完成）**

| # | 任务 | 落点 | 验收命令（可复制） |
| --- | --- | --- | --- |
| I-M0-a | `Package.swift` 改造：`swiftLanguageModes: [.v6]`、去 `plugins:`、拆测试依赖、加检查器 target | `Package.swift` | `xcodebuild -list` |
| I-M0-b | 结构检查器 R1–R21（注释/字符串剥离、标识符边界、豁免语法） | `Sources/wd-structure-check/`、`Scripts/check-structure.sh` | `Scripts/test-checker.sh`（各一正一反） |
| I-M0-c | 格式门禁 | `.swift-format`、`Scripts/check-format.sh` | `Scripts/check-format.sh` |
| I-M0-d | 签名冒烟 `#if WD_API_SMOKE`（只放尚未实现的声明） | `Sources/WisdomUI/APISurface/WDAPISurface.swift` | 并入 `ci.sh pr` 的 `build-for-testing` |
| I-M0-e | API 冻结链路（规范化符号快照） | `Scripts/{dump-api.sh,canonicalize-api.swift}`、`api/WisdomUI.api.json` | `Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json` |
| I-M0-f | 门禁脚本与 workflow | `Scripts/ci.sh`、`.github/workflows/ci.yml` | `Scripts/ci.sh pr` 首次全绿 |
| I-M0-g | 契约读取与跨仓自证 | `Tests/WisdomUITests/Support/WDContracts.swift` | `sha12` 相等；manifest 缺失 = fail |
| I-M0-h | 令牌冻结的 iOS 落点（等设计仓 M0-1/M0-2 完成后同批） | `Foundation/generated/{WDTokensVersion,WDColorSlots,WDIconName}.swift`、`Foundation/Tokens/WDTokenTypes.swift` | 生成器 `--check` 绿 + `--tokens-trace` 绿 |
| I-M0-i | README/CONTRIBUTING/PR 模板/CODEOWNERS | `README.md`、`.github/**` | `git grep -nE 'swift (build\|test)' -- . \| grep -v -- '-product wd-structure-check'` 为空 |
| I-M0-j | 版本治理 | `CHANGELOG.md`、`Examples/BaselineShell/` | 发布 checklist 可勾 |
| I-M0-k | 门禁预算测量 | `Scripts/ci.sh measure` → `README.md` | 三次中位数写回；**未测不写预算** |

**M0 出口判据（6 条）**：① 结构检查器 + 自检样本绿；② 格式门禁绿，且**基线格式化提交先于** `api/WisdomUI.api.json` 入库；③ `Scripts/ci.sh pr` 首次全绿（含签名冒烟 + 单测 + 覆盖率报告）；④ `api/WisdomUI.api.json` 入库且 `git diff --exit-code` 绿；⑤ 跨仓自证 `--tokens-trace` 与生成器 manifest 的 `sha12` 相等；⑥ 库/测试侧 `swift build|test` 零命中，`Package.swift` 无 `plugins:`、无 macOS 平台、显式 Swift 6。
**门禁强度**：`PR`。

### 2.2 M1 — 基础设施（无组件交付）

**本端任务**：① `wdFont(_:)` 单入口 + 行盒度量（`WDLineBoxTest` + 字高 fixtures，含 zh/en natural 值）—— **已交付（2026-10-07，commit `9c1fa37`）**：字阶层三件（`WDTypographyMapping`/`WDFontMetrics`/`WDFont`）+ 实测 fixture（12 字阶 × {en, zh} × {默认, AX3, AX5}，两层）+ U5-a/b/c 与漂移检查，`passed=11 failed=0`；② 六态截图入库（浅/深 × 默认/AX3 × LTR/RTL）—— **已交付（2026-10-07）**：`WisdomUIPreviews`（令牌/字阶画廊）+ `WisdomUISnapshotTests`（8 态矩阵、玻璃类渲染器显式表、PNG 字节 + 逐像素差双判、manifest 含工具链与设备）+ **16 张基线入库**；快照目标单独跑 4 tests passed；矩阵计数偏差见 **P15**；③ 真机 `fontScale 2.0` / AX3 观感采样；④ **弹簧 μ=1.0 并排评审 = 设计确认关**；⑤ §5 的三件套（玻璃 × 配额 × 对比度）**首轮参数化单测骨架** —— **已交付（2026-10-07）**：`WDGlass.resolve`（U10 签名，`WDGlassLevel` 按 F47 作额外输入）+ `WDEffectsBudget`（§12.2 的 7 条上限，`downgraded(to:)` 把「只降不升」变成机器保证）+ `WDContrast`（4.5:1 / 3:1 + **最不利口径**：玻璃取叠在最暗/最亮内容上的合成色）+ 3 个测试文件共 **34 条用例**（含两条**必须红**用例）；实测账目与设计 §12.3 逐条吻合（3.64/3.09/4.14/4.16/2.93 vs 3.6/3.1/4.1/4.2/2.9）；M0-11 冒烟段里对应的 5 个声明**已按纪律删除**；⑥ demo 含**运行时 scheme 切换入口**（换已生成的另一套 scheme，主题值变更触发重组/重算且**不重启进程**）—— **已交付（2026-10-07）**：`Examples/WisdomUIDemo`（app + `WisdomUIDemoUITests` + 本地包依赖 + xcconfig 占位）+ **主题层**（`WDTheme` / `wdTheme` / `wdColors` 只读派生 / 写入口集中 `WDEnvironment.swift`）+ 4 条单元用例（派生、运行时切换、scheme 清单、主题驱动渲染取像素）。**已实跑通过（2026-10-07）**：`WisdomUIDemoUITests` = 2 tests / 0 failures（方案切换用例 + 无障碍审计四类目，**严格模式不吞 issue**）；库侧 `ci.sh pr` 全绿（`passed=17 failed=0`）。
**入口判据**：I-1（M0 出口已判定）＋ I-3（令牌含 `schemes` 维度）＋ I-4。
**出口判据**：① 行盒 fixtures（zh/en）绿；② 12 条性能预算有数（本端报告 + `.build/perf/{date}.json`）；③ demo 与 `WisdomUIDemoUITests` 可跑；④ 运行时 scheme 切换用例通过；⑤ 三件套单测骨架存在且能红/能绿。
**门禁强度**：`PR`（demo 无障碍审计项 `M1 起` 才可跑，见 §4.2）。
**出口报告（I-1 的落盘件）**：`docs/M1-EXIT-REPORT.md`（2026-10-07）—— 5 条判据 = ✅ 4 + ⚠️ 1（组件级性能预算无组件可测）；**2 项任务未完成**（真机观感采样、弹簧评审），均不在出口判据内、已在该报告 §4 按【未验证】登记。

### 2.3 M2 — 首批 11 件（**关键路径 2 件串行在前**）

> **批前签名冻结（I-2）**：表单 = `docs/M2-SIGNATURE-FREEZE.md`（2026-10-07，**待 ios-lead 签名 + 架构师确认**）。
> 其中 **3 件已冻结**（`WDButton`/`WDTextField`/`WDListRow`，誊录自 M0-11 冒烟段）、**8 件为提案待确认**；
> **2 条阻塞**：① `WDIconName` 的 44 条语义名未产出（I-M0-h）⇒ 8 件受影响 —— **名单不缺**（设计仓 `08-icons.md` §4 已给 44 条，iOS 侧实测 44/44 SF Symbol 存在），缺的是**契约层管道**，设计稿见 `docs/ICON-PIPELINE.md`；② `WDCheckbox` 的**契约名**冻结依赖 Android 侧 14 行改名（SPEC R3-d）。

**本端任务**：该批 11 件组件实现 + 六态快照 + 无障碍断言 + 该批性能数字（**只报不拦**）。
**入口判据**：I-2（**批前签名冻结**：11 件的完整签名 + 契约条目入库）。
**出口判据（6 条）**：① 迁移后 `api/WisdomUI.api.json` 无未解释差异；② 批内 11 件的契约用例名与实现一致（`params`/`slots`/`default` 与内联表 §5.3 逐行一致）；③ 六态截图入库且 `--tokens-trace` 绿；④ 无障碍断言（语义树/热区/对比度最不利取色）通过；⑤ 该批性能数字进报告（不拦）；⑥ **冒烟退役**：已落地组件从 `WD_API_SMOKE` 排除清单中删除。
**门禁强度**：`PR+nightly₃`。

### 2.4 M3 — 封板批次（1 件 + 公开 API 冻结）

**本端任务**：`WDListSection`（第 20 件 primitive 中的最后一件列入本批）＋ **公开 API 冻结**（符号快照入库）＋ 覆盖率转门槛 ＋ 体积门槛定值。
**入口判据**：I-2；另需 M2 出口全绿。
**出口判据（6 条）**：① `api/WisdomUI.api.json` 入库且 `git diff --exit-code` 绿；② 命名与枚举规则内联表 §5.3 全部对齐；③ 快照与契约用例全绿；④ 覆盖率转门槛：`Foundation/**` ≥ **80%**（排除 `generated/`）；⑤ **体积门槛值**定为"P50 + 10%（或绝对上限）"并写进 `README.md`/`CHANGELOG.md`；⑥ 封板批 12 件 primitives（M2 的 11 + 本批 1）在出口报告中占位、无缺件 —— **其余 primitives 按其所在批的"批前签名冻结"执行**，20/20 primitives 完成于 M5 出口。
**门禁强度**：`PR+nightly₃+发布前`。

### 2.5 M4 — 反馈与弹层（9 件）

**本端任务**：`WDBottomSheet`、`WDAlert`、`WDActionSheet`、`WDToast`、`WDProgressBar`、`WDProgressRing`、`WDBanner`、`WDEmptyState`、`WDSkeleton`（含 2 件 primitives：`WDProgressBar`/`WDProgressRing`）。
**入口判据**：I-2（9 件契约入库）；玻璃与效果配额相关的两项冻结已生效（§5.1 schemes、§5.2 配额）。
**出口判据（7 条）**：① 批前冻结完成（9 件契约入库）；② 玻璃档位单测（档位 × `appearance` × `textLevel` → `opaque|glass|glassStrong`，含两条"必须红"用例）绿；③ **效果配额 7 条**各自的计数/降级断言绿，且"同屏模糊面数量**可数**"；④ 对比度门槛按**最不利取色**验证（`contrast` 审计 + 每套 scheme 的对比度账目进契约）；⑤ 该批性能数字进报告；⑥ 六态快照入库（玻璃类 6 件用 `UIHostingController` + `drawHierarchy`）；⑦ 发布物冒烟（demo 构建 + 归档可产出）。
**门禁强度**：`PR+nightly₃+发布前`。

### 2.6 M5 — 导航与表单（15 件）

**本端任务**：`WDSegmentedControl`、`WDDatePicker`、`WDPullToRefresh`、`WDNavigationBar`、`WDTabBar`、`WDSearchField`、`WDRadio`、`WDSlider`、`WDStepper`、`WDChip`、`WDAvatarStack`、`WDPicker`、`WDFormRow`、`WDToolbar`、`WDFAB`（含 6 件 primitives：`WDSearchField`/`WDRadio`/`WDSlider`/`WDStepper`/`WDChip`/`WDAvatarStack`）。
**入口判据**：I-2（15 件契约入库）；U7（动态字体上界）已定值。
**出口判据（6 条）**：① **20/20 primitives 完成**（11 + 1 + 2 + 6）；② 动态字体降级矩阵（含 compact 三条规则）绿；③ RTL 六态截图（LTR/RTL 两态）入库；④ 该批性能数字进报告；⑤ 组件类型名清单与 U3/F 注册表集合相等；⑥ 无新增未登记差异（差异须进 §6 的回写/登记清单）。
**门禁强度**：`PR+nightly₃`。

### 2.7 M6 — 场景组件与发布（1 件 + 回归）

**本端任务**：`WDAssigneePicker` ＋ 无障碍回归 ＋ 截图基线封板 ＋ 发布前层 ＋ 双端同 tag。
**入口判据**：I-2（1 件契约入库）；M5 出口全绿。
**出口判据（7 条）**：① 批前冻结（1 件）；② 无障碍回归：VoiceOver 闭眼走查记录 + demo 层 `performAccessibilityAudit` 四类目；③ 截图基线封板（全部 37 件 × 浅/深 × 默认/AX3 × LTR/RTL）；④ 全量门禁：`Scripts/ci.sh pr` + nightly 连续绿；⑤ 发布前层：归档 Thinning 增量 + 真机 hitch + tag 校验；⑥ **双端同 tag `v1.0.0`**，且 tag 前确认三仓 HEAD 与版本台账一致；⑦ 发布 checklist 可勾选完成。
**门禁强度**：`PR+nightly₃+发布前`。

---

## 3. 批次分配（本端逐组件 + 批前冻结 / 出口）

> **每批的固定动作（顺序不可调）**：**① 批前签名冻结 → ② 实现 + 单测 → ③ PR 门禁 → ④ nightly（含六态快照）→ ⑤ 批出口评审**。
> **批前签名冻结的内容**：该批每件组件的完整公开签名（含枚举 case 与默认值）+ 对应契约条目的 `params`/`slots`/`default`；**未冻结不开工**。
> 组件级"批次"是唯一权威视图；下面每批的"出口判据"与 §2 对应里程碑一致。

| 批 | 件数 | 组件（本端实现） | 批前冻结要点 | 批出口要点 |
| --- | --- | --- | --- | --- |
| **M2** | **11** | `WDTextField`(C)、`WDListRow`(C)、`WDButton`、`WDIconButton`、`WDSwitch`、`WDCheckbox`、`WDBadge`、`WDAvatar`、`WDDivider`、`WDCard`、`WDIcon` | 11 件签名 + 契约入库；受控值名按 §5.3 内联表 | 六态快照 + 无障碍断言 + **行高 44 断言** + 冒烟退役 |
| **M3** | **1 + 封板** | `WDListSection` | 1 件签名 + 契约；同时冻结**公开 API 基线** | `api/*.json` 入库、覆盖率 ≥80%、体积门槛定值、12 件 primitives 占位 |
| **M4** | **9** | `WDBottomSheet`(C)、`WDAlert`(C)、`WDActionSheet`(C)、`WDToast`(C)、`WDProgressBar`、`WDProgressRing`、`WDBanner`、`WDEmptyState`、`WDSkeleton` | 9 件签名 + 契约；玻璃/配额/对比度三件套参数化 | 玻璃矩阵单测 + 配额 7 条断言 + 最不利对比度 + 发布物冒烟 |
| **M5** | **15** | `WDSegmentedControl`(C)、`WDDatePicker`(C)、`WDPullToRefresh`(C)、`WDNavigationBar`(C)、`WDTabBar`(C)、`WDSearchField`、`WDRadio`、`WDSlider`、`WDStepper`、`WDChip`、`WDAvatarStack`、`WDPicker`、`WDFormRow`、`WDToolbar`、`WDFAB` | 15 件签名 + 契约 | **20/20 primitives** 完成 + 动态字体降级矩阵 + RTL 截图 |
| **M6** | **1 + 回归** | `WDAssigneePicker` | 1 件签名 + 契约 | 无障碍回归 + 截图封板 + 发布前层 + **双端 tag `v1.0.0`** |

> **图例（放在表外 —— 插进表头与数据行之间会让 GFM 表格降级，见 §4.6 固定项 ⑥）**：组件名后的 **`(C)` = 该批内串行在前的「关键路径件」**（下游批依赖其冻结；历史标记写法）；**与层级无关** —— 层级看 §1 的 20 primitives / 17 composites 名单。
> **口径更新**：原 A/B/C **工作量档位**（人日口径）**已废止**——按用户决策 #1（不计算人力）不再使用，且其来源已随退役文档集不可取证；**现行列 = §13.1 的「关键路径件（是/否）」**，依据 = 本节的批内顺序与批间依赖。
> **⚠️ 记号同形不同义（跨端登记，勿互读）**：**本仓**组件名后的 `(C)` = **关键路径件**标记（本图例）；**Android 侧 §3.2 的同形 `（P）`/`（C）` = 层标记**（primitives / composites，依据其分组与 §3.1 的 20/17 计数一致）。⇒ **同一字形、两端不同义**：引用时**必须带端别**（写 "iOS §3 的 `(C)`" / "Android §3.2 的 `（C）`"），**不得互读**。

**计数自证**：11 + 1 + 9 + 15 + 1 = **37**；其中 primitives 20 件（M2 11 + M3 1 + M4 2 + M5 6），composites 17 件（M4 7 + M5 9 + M6 1）。**每批第 0 步都是批前签名冻结**，批内可并行但**同一角色不得同时持有两个未完成任务**。

**每批的统一验收方式**（五件套）：契约用例名对齐 + 六态截图 + 该批性能指标 + 无障碍断言 + 符号快照绿。**批出口不使用完成度百分比**，只用"判据是否全绿"。

---

## 4. 命令与门禁（可直接复制）

> **现状标注**：`现成` = 现在就能跑（M0 前有效）；`M0-6 起` = 需先完成 I-M0-b/c/e/f 产出脚本与 workflow；`M1 起` = 需先有 `Examples/WisdomUIDemo`（M1 交付物）；`M6 起` = 需真机与发布链路。
> **命名统一**：这四个状态词是本仓**唯一一套**。`../AGENTS.md` §5 的等价说法为「现状：现成 / M0 后可用 / M6 前不可跑」，一一对应：`现成` ↔ 现成、`M0-6 起` ↔ M0 后可用、`M6 起` ↔ M6 前不可跑。
> **变量准备**（只有手工执行下面的命令才需要设；`Scripts/ci.sh pr` **内部自解析**同样的两个值，不需要先 export）：

```bash
export WD_SCHEME="WisdomDesign-iOS-Package"   # 实测固化值（D-19 已回填）：包级聚合 scheme = <包名>-Package
export WD_SIM_ID="$(xcrun simctl list -j devices available | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=[(rt,x) for rt,ds in d["devices"].items() if "iOS" in rt for x in ds if x.get("isAvailable")]
c.sort(key=lambda t:(t[0], t[1]["name"]))
print(c[-1][1]["udid"])')"            # 取最新可用运行时的 UDID；禁按设备名硬编码
```

### 4.1 PR 门禁（每次提交必过）—— `M0-6 起`

```bash
# ① host 侧，秒级（不需要 Xcode）
Scripts/check-structure.sh                  # R1–R21 + 令牌溯源 + 契约清单
Scripts/check-format.sh                     # swift-format（显式文件清单，排除 generated/）

# ② 编译 + 单测 + 签名冒烟（一次模拟器会话；PR 只编模拟器一张编译图）
xcodebuild build-for-testing -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" \
  -derivedDataPath .build/dd -quiet \
  -enableCodeCoverage YES -resultBundlePath .build/dd/pr.xcresult \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'
xcodebuild test-without-building -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" \
  -derivedDataPath .build/dd -only-testing:WisdomUITests \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 60

# ③ API 冻结（复用上面的 DerivedData，不额外编译）
Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json

# ④ 覆盖率报告（只打印不拦，M3 前）
mkdir -p .build/perf && xcrun xccov view --report --json .build/dd/pr.xcresult > .build/perf/coverage.json
```

**一步版**（等价）：`Scripts/ci.sh pr`。门禁 = **`xcodebuild` + 模拟器**；`swift build`/`swift test` **不作门禁**。

### 4.2 nightly 门禁（每批强制；**连续 3 日绿**才算批出口）—— `M0-6 起`（demo 项 `M1 起`）

```bash
xcodebuild build -scheme "$WD_SCHEME" -destination 'generic/platform=iOS' -derivedDataPath .build/dd -quiet   # 设备编译只在 nightly
xcodebuild test  -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" -derivedDataPath .build/dd \
  -only-testing:WisdomUISnapshotTests        # 六态快照（普通组件 ImageRenderer；玻璃类 UIHostingController+drawHierarchy）
# demo 无障碍审计（4 类目：contrast / hitRegion / textClipped / dynamicType）—— M1 起
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination "$WD_SIM_ID" -only-testing:WisdomUIDemoUITests
```

**nightly-3 性能口径**：只测**模拟器相对量**（渲染 1 次 × N 循环的 `XCTClockMetric`/`XCTMemoryMetric` → `.build/perf/{date}.json`）；**真机 hitch、首帧、归档 Thinning 增量在"发布前"层**。

### 4.3 发布前门禁 —— `M6 起`

```bash
# 真机：hitch（scrollDecelerationMetric）、首帧（XCTApplicationLaunchMetric）；归档体积增量
xcodebuild archive -scheme "$WD_SCHEME" -destination 'generic/platform=iOS' -archivePath .build/archive.xcarchive
git describe --tags --exact-match            # 必须 == 生成物里的版本号（tag 只增不改）
```

### 4.4 M0 前唯一可跑回路 —— `现成`

> **可用性说明**：本节**两条 `xcodebuild`**（`-list` 与设备编译）的可用性见 **§8.1 U-01** —— **本仓尚无一次成功实测**；`node … --check`（令牌一致性）与 `simctl` 取 UDID **已可跑**。

```bash
xcodebuild -list                                   # 看 scheme/target
xcodebuild build -scheme "${WD_SCHEME:-WisdomDesign-iOS-Package}" -destination 'generic/platform=iOS' \
  -derivedDataPath .build/dd -quiet                 # 设备编译（不需要模拟器，也不跑测试）
node ../wisdomdesign/tools/token-build/build.js --check   # 令牌与生成物一致（需设计仓可读）
```

### 4.5 门禁强度与出口的对应

| 批 | PR | nightly 连续 3 日 | 发布前层 |
| --- | --- | --- | --- |
| M0 | ✅（③首次全绿） | — | — |
| M1 | ✅ | — | — |
| M2 | ✅ | ✅ | — |
| M3 | ✅ | ✅ | ✅ |
| M4 | ✅ | ✅ | ✅（发布物冒烟） |
| M5 | ✅ | ✅ | — |
| M6 | ✅ | ✅ | ✅（真机 + 归档 + tag） |

### 4.6 文档类改动也要过 verify（**本仓纪律**）

> 任何**文档类产出**（本计划 / 施工手册 / 架构 / 台账）在提交前跑**六个固定项**；另加两条纪律（**禁止自命中**、**双跑**）。本节是跨端文档纪律在**本仓的常驻副本**——根计划目录移除后，本节仍可独立查阅。

**① 五个固定项（文档类 verify 必含）**

```bash
grep -cE '^#{2,3} .*#{2,3} ' iOS/docs/DEV-PLAN.md   # 结构自检：防"标题粘连"，必须 == 0
grep -c '^## '      iOS/docs/DEV-PLAN.md            # 标题计数：达预期值（与改动前一致，或给出说明）
grep -c '^```mermaid' iOS/docs/ARCHITECTURE.md      # 图表围栏：张数已知且围栏成对（本文件无 Mermaid）
wc -c < iOS/AGENTS.md | tr -d ' '                   # 字节上限：AGENTS ≤ 60000 B（自动加载预算）
# ⑤ 外部引用加固：防"裸节号"绕过路径 grep 给出假绿（字符类写法，避免自命中）
grep -cE '本[端]规格|[外]部规格|见[规]格' iOS/docs/DEV-PLAN.md          # 软指代词：必须 == 0
a=$(grep -cE '\b(0[1-9]|[1-3][0-9]|40) §' iOS/docs/DEV-PLAN.md)
b=$(grep -nE '\b(0[1-9]|[1-3][0-9]|40) §' iOS/docs/DEV-PLAN.md | grep -cE '\.md|回写|台账|外部')
test "$a" = "$b"                                    # “数字代号 + 节号”引用必须带文件名或台账语境
# 跨文档节号核验（t83 · D-1）：ARCH 引用的每个 `DEV-PLAN.md` §X 必须在 DEV-PLAN 真实存在（悬空必须 == 0）
for ref in $(grep -oE 'DEV-PLAN\.md`? *\*{0,2}§[0-9]+(\.[0-9]+)?' iOS/docs/ARCHITECTURE.md | grep -oE '§[0-9]+(\.[0-9]+)?' | sort -u); do n=${ref#§}; grep -qE "^#{2,3} ${n}([. ]|$)" iOS/docs/DEV-PLAN.md || echo "悬空: $ref"; done | wc -l
# ⑥ 表格结构自检：连续 `|` 行分块 → 每块第 2 行必须是分隔行、块内 ≥2 行（必须 == 0）
awk '/^\|/{if(!b){k++;n=0;f=NR} b=1;n++; if(n==2 && $0 !~ /^\|[-: |]*-[-: |]*\|[[:space:]]*$/) print f; next} {b=0} END{}' iOS/docs/DEV-PLAN.md | wc -l
```

| # | 项 | 判据 | 不通过怎么办 |
| --- | --- | --- | --- |
| ① | **结构自检** | 上表第 1 条命令 == **0** | 说明标题被拼接到了同一行：拆回两行；**并把该项加进该次 verify** |
| ② | **标题计数**；**目录锚点核验（t92 · R2-01 并入）** | ① `##` / `###` 计数与改动前一致，**或**在提交说明里写清增减与原因；② **目录锚点自检命令（§目录 内那条）输出 `缺条目 [] 不匹配 []`** —— 规则必须与 **GitHub 一致：空格→`-`、不折叠连续 `-`**（例 `M0 — 工程` ⇒ `m0--工程`） | 缺节/多节先定位再改文本；锚点不匹配 ⇒ **按 GitHub 规则重生成该条锚点**；⚠️ **不得把规则改成"折叠连续连字符"**（那会让 14 条含 `—`/`/`/`+` 的标题**假绿**，即 R2-01 的成因） |
| ③ | **图表围栏** | Mermaid 张数 == 预期值，且围栏**成对** | 补齐围栏；成对性用 `grep -c '^```'` 取偶数复核 |
| ④ | **字节上限** | `AGENTS.md` ≤ **60000 B** | 超出就把细节**下沉到本文件或 `ARCHITECTURE.md`**，AGENTS 只留指针 |
| ⑤ | **外部引用加固** | 软指代词 == **0**；且 `a == b`（即"数字代号 + 节号"的引用**每一条**都带文件名限定或位于回写/台账语境；**数值随时间变化，不在表内固定**） | 补文件名限定，或把该句移进 §6/§7 的外部维护台账；**不要**用"加白名单"绕过。**扩档（R3-01）**：凡出现裸 `§N.M` 而 **N 不是本文件的节号** ⇒ 该处**同行必须带目标文件名**（如 `docs/SPEC.md` §2.8、`../AGENTS.md` §12.1），否则计为**不合格**；命令：`grep -nE '§[0-9]+\.[0-9]+' 本文件 | grep -vE 'SPEC\.md|AGENTS\.md|DEV-PLAN\.md|ARCHITECTURE\.md'` |
| ⑥ | **表格结构自检（t82 补）** | 上表第 ⑥ 条命令 == **0**：连续 `\|` 行成**块**后，**每块第 2 行必须是分隔行**（`\| --- \|` 形态）且**块内行数 ≥ 2** | 说明有元素被插进了表头与数据行之间（**GFM 会把该表降级**：表头成空表、数据行变段落）⇒ **把说明/图例移到表外**（表头之前或表尾之后），或补上分隔行 |

> **⑥ 为什么必要（t82）**：原有五项**没有一项检查表格完整性**——`(C)` 图例曾被插进表头与数据行之间，路径/字节/标题三项全绿，**但在 GFM 下该表已降级**（表头空、5 行数据变段落），由计划复审（t74 · D2-01）才抓到。这与"标题粘连（t58）"、"字节截断（t62）"、"裸节号（A-1）"是同一类问题：**检查项没覆盖真实的失败模式**。
> **⑤ 为什么必要**：历史教训 —— **裸节号**（只写"§x.y"、不写文件名）能**绕过路径 `grep`** 从而给出**假绿**；被测文档被移除后，这种引用会变成指向不存在章节的死引用。本项实测：软指代 = **0**，`a` = `b` = **1**。(2026-10-05)

**② 禁止自命中**

新增/修改的文本**不得携带被同一条 verify 用于 `grep` 的字面串**（否则判据会被自己触发）。两种做法：

- **描述式引用**：不复述被查串，改用指代说法（例："本计划历史评审链使用的那条路径模式"）。
- **字符类写法**：需要展示模式时，把其中某个字符写成字符类/通配形，使文本里不出现完整字面串。

**判据与文本只能改一个**：判据由验收方给出，**冲突时先改文本**。

**③ 双跑纪律**

机器判据通过后，**用同一条命令再跑一次**并贴输出，确认计数与首次一致；若发生变化，**先改文本、不改判据**。

**④ 根因实例（用任务号指代，不复述被查串）**

- **标题粘连**：**t58** 的拼接让两个标题落在同一行；当时的 verify 只查"存在性 / 计数"因而**漏检**；**t41** 与 **t59** 各自发现，**t64** 修复 ⇒ 由此把"结构自检"升级为文档类 verify 的**固定项**。
- **自命中共 6 次**：**t42 / t48 / t58 / t62 / t64 / t68** —— 均为"新增文本里复述了 verify 正在匹配的字面串"，判据被自己触发；修复方式**一律是改文本**（描述式或字符类），**不改判据**。

---

## 5. 冻结值与本端契约

> 以下值**已冻结**：改它们 = 改跨端统一项或硬约束 ⇒ 必须先改契约真源（M0-5 起在设计仓的 `contracts/README.md`）再同步本端。逐条实现细节见 `../AGENTS.md` §6 与 `ARCHITECTURE.md` §4–§6。

### 5.1 值与口径（本端最终值）

| # | 项 | 最终值 |
| --- | --- | --- |
| 1 | **行高（密度档）** | `size.row-height.{comfortable,compact}` = **60 / 44**，**单值键、两端同值**；**统一项 = 两端可见内容高度 44 ± 0.5** |
| 2 | **Android 的行布局盒（仅登记，不影响本端）** | 48 = 44 可见内容 + 上下各 2dp 内边距（热区 = 布局盒）；**行距差异 = F51（各端自由）**；**iOS 不加内边距** |
| 3 | **语义色槽位数** | **32 槽位**（含 `text.disabled`）；生成器 `--check` 计数断言 = 32；两端同步 |
| 4 | **主题 scheme 维度** | 令牌 schema 一次含 **`schemes: {light, dark, …}`**；生成器多套输出 + `--schemes`；**运行时换已生成的 scheme**（`wdTheme` 环境键）；值变更触发重组/重算、**不重启进程**；**不支持**运行时任意 `token.json` / 服务端下发 / **逐槽位任意覆盖**；**切换不得进高频路径** |
| 5 | **弹簧 canonical** | `response`(秒) + `dampingRatio`(ζ) 为真源；`stiffness = μ·(2π/response)²`，**μ = 1.0**；**禁 `massFactor`**；iOS 直接 `Animation.spring(response:dampingFraction:)`，**本端产物不生成 `stiffness`** |
| 6 | **图标** | 契约只统一 **44 条语义名 + `mirrorsInRTL`**；iOS **按名取 SF Symbols**；库内**零图标资源**；`mirrorsInRTL` 只用于契约断言（渲染靠 SF Symbols 自带镜像元数据） |
| 7 | **文案（L-B）** | 库内**零资源 + 零文案**：读屏标签由调用方传入；库只提供**结构拼接原语**（零标点、零语序）；`WDIconButton.accessibilityLabel`、`WDTextField.label` 等**必填** |
| 8 | **触控双键** | `size.touch-target-min-{ios,android}` = **44 / 48**；每端只生成本端常量；**不留过渡键** |
| 9 | **发布形态** | 单发布 product `WisdomUI`；`WisdomUIPreviews` 不进 products；`Internal/` 零 `public` |
| 10 | **其它已冻结值** | 字段盒高 `46`；字段最小宽 `190`；sheet detent `0.5`/`0.92`；sheet 最大宽 `480`；`letterSpacing` 单位 pt/sp 等价（`overline = 0.6`，其余 0）；减弱动效时长 **150ms**（备选 160ms 不采用，待设计裁决，见 §7）；面板圆角 **32**（`.continuous`） |
| 11 | **交互状态优先级（U6）** | `disabled > loading > pressed > focused > hover > default`；disabled 吞输入；loading 忽略 `action` 但系统 `isEnabled` 仍为 true 且留在无障碍树；focused/hover 是叠加维度 |
| 12 | **行盒语义（U5）** | 渲染行盒 = `max(设计盒高 × 缩放, 自然行高(script))`；默认档容差 ±0.5pt；放大档不裁切；**禁** `Mode.Fixed`/`lineHeightMultiple`/`minimumScaleFactor` |
| 13 | **枚举与命名** | 枚举 = `String` 原始值 + `CaseIterable` + `Sendable`；**新增 case = 源级 breaking**；**不加 `@frozen`**；公开类型名含 **`WDBottomSheetDetent` / `WDBottomSheetDetents`**，**不得出现 `WDSheet*`** |
| 14 | **目录大小写差异** | iOS `Components/Primitives`+`Composites` vs Android `components/…` 是**已登记差异（U2/DIR-1）**，**不得为"对齐"改名** |

### 5.2 主题、换肤与无障碍（本端口径）

- **换肤 = 层一**：支持"多套生成 scheme + 运行时选择"；**不支持**运行时任意 token / 服务端下发；成本 = 换品牌需回设计仓改 scheme 并重新生成/发版；`Q-A2` **不重开**，语义色从 31 扩到 32 **仍非 breaking**。
- **对比度硬门槛**：正文 **4.5:1**、大字号 **3:1**、图形/图标/控件边界 **3:1**、禁用态不适用（40% 不透明度）、焦点光环 **3:1（对相邻色）**；**验收取"最不利位置"背景色**（**不取平均**；玻璃取最暗/最亮内容的合成色）。
- **玻璃档位 × 文字可用**（四条硬规则）：浅色 `glass` 只放 `text.primary`；**深色端任何字阶都不上 `glass`**，深色 `glass-strong` 只放 `primary`；悬浮 Tab 栏用 `glass-strong`、**深色 Tab 栏改不透明表面**；**语义色不上玻璃**。`tinted`/`sheen` 属强调容器/装饰，**不作为文字载体**。
- **效果配额（7 条硬上限）**：① 玻璃**同屏 ≤1 个模糊面、列表项内 0**；② 色晕 `wash` 每屏 1 处且禁动画（一次绘制画 3 段 radial）；③ `sheen` 每屏 ≤1；④ 骨架微光**同屏 ≤6**；⑤ `e3` 每屏 ≤1（列表项 `e0/e1`）；⑥ 进度环/下拉环**每屏 ≤1 个动画环**；⑦ 触觉同一次操作 1 次。**违反即降级**（不透明/静态/停动画），**不是降速**。
- **iOS 17–25 玻璃降级**：**默认动作 = 纯色降级**（不做模糊、不使用系统 `Material` 模糊，保留 hairline），该区间只返回 `opaque`；**待设计裁决（时点 M0 D1）**，见 §7。

### 5.3 受控值名（C-15 内联，37 行；**本端参数名以本表为准**）

> 规则：**契约名 = canonical（不带 `is`）**；iOS 允许 `is` 前缀差异。**新增/改名**必须先改契约真源，再同步本表；`WD` 前缀为强制。
> **改名台账**：本表 = C-15 定名**之后**的最终名。**逐行比对（脚本，2026-10-05）：37 行中仅 #06 一行不同** —— 契约真源的 iOS 列仍是改名前的旧名，本表已按 C-15 结论落为 **`isChecked`**（C-15 §2：iOS 侧**仅此 1 行**改名）；其余 36 行（含 12 行"无受控值"）逐行一致。改名在四处保持自洽：本文件 §8.1 **U-07**、`../AGENTS.md` 的 **F-14** 与 **U-07**、`ARCHITECTURE.md` 的 **U-07**。

| # | 组件 | iOS 参数名 | 契约名（canonical） |
| --- | --- | --- | --- |
| 01 | `WDButton` | `isLoading` | **`loading`** |
| 02 | `WDIconButton` | `isLoading` | **`loading`** |
| 03 | `WDTextField` | `text` | **`text`** |
| 04 | `WDSearchField` | `text` | **`text`** |
| 05 | `WDSwitch` | `isOn` | **`on`** |
| 06 | `WDCheckbox` | `isChecked` | **`checked`** |
| 07 | `WDRadio` | `selection` | **`selection`** |
| 08 | `WDSlider` | `value` | **`value`** |
| 09 | `WDStepper` | `value` | **`value`** |
| 10 | `WDChip` | `isSelected` | **`selected`** |
| 11 | `WDBadge` | — | — |
| 12 | `WDAvatar` | — | — |
| 13 | `WDAvatarStack` | — | — |
| 14 | `WDDivider` | — | — |
| 15 | `WDProgressBar` | `value` | **`value`** |
| 16 | `WDProgressRing` | `value` | **`value`** |
| 17 | `WDCard` | — | — |
| 18 | `WDListRow` | `isSelected` | **`selected`** |
| 19 | `WDListSection` | `selection` | **`selection`** |
| 20 | `WDIcon` | — | — |
| 21 | `WDSegmentedControl` | `selection` | **`selection`** |
| 22 | `WDPicker` | `selection` | **`selection`** |
| 23 | `WDDatePicker` | `date` | **`date`** |
| 24 | `WDFormRow` | — | — |
| 25 | `WDAlert` | `isPresented` | **`presented`** |
| 26 | `WDBottomSheet` | `isPresented` | **`presented`** |
| 27 | `WDActionSheet` | `isPresented` | **`presented`** |
| 28 | `WDToast` | `isPresented` | **`presented`** |
| 29 | `WDBanner` | `isVisible` | **`visible`** |
| 30 | `WDEmptyState` | — | — |
| 31 | `WDSkeleton` | — | — |
| 32 | `WDPullToRefresh` | `isRefreshing` | **`refreshing`** |
| 33 | `WDNavigationBar` | — | — |
| 34 | `WDTabBar` | `selection` | **`selection`** |
| 35 | `WDToolbar` | — | — |
| 36 | `WDFAB` | — | — |
| 37 | `WDAssigneePicker` | `selection` | **`selection`** |

> 脚注：`—` = 该组件**无受控值**（与契约真源同写法，便于逐行 diff）。

**断言（可跑）**：① 契约真源的表与本端实现逐行比对 **0 不一致**（批前冻结时执行）；② 生成器"槽位计数 == 32"；③ 组件类型名集合与注册表**相等**；④ **本表 37 行 ↔ 契约真源逐行 diff = 0，但预期差异 = `{#06}`**（`#06` 是**名词改名**，**不是** `is` 前缀差异；与本节改名台账的"唯一差异 = #06"一致）；其余 **36 行 diff = 0**；**M0-5 真源落 `contracts/README.md` 之后**，口径改为"真源已按 C-15 §2 归一为最终名 ⇒ diff = 0"，在此之前以"§5.3 与 `docs/SPEC.md` §2.10 矩阵逐行一致"代替。

---

## 6. 规格回写项（本端相关；**改哪个文件哪一节 + 状态**）

> 纪律：**任何规格回写必须先在回写清单（**本仓 §6** 的 P 项）登记为"文件:行号 + owner + 时点"，再按登记范围执行**；执行者不得顺手改登记外口径。**正文里出现的裸 `§5.9`/`§5.10` 一律按本仓 §6/§7 解读**（不再指向已退役的跨端计划）。
> **退役名 → 本仓等价章节（简写纪律）**：`30-dev-plan.md` ⇒ **本文件**；`40-contract-names.md` ⇒ **§5.3**；`02-ios-spec.md` ⇒ **`docs/SPEC.md`**；`12-android-spec.md` ⇒ `android/docs/SPEC.md`；`03-perf-release.md` 配额表 ⇒ **§5.2**；iOS 组长评审链（`20`/`22`/`24`/`28`）⇒ **§5.1**（含 F51）。
> 下表只记本端相关的项；`02-ios-spec.md` / `12-android-spec.md` / `09-layout.md` / `30-dev-plan.md` 等文件由**各自负责人**维护，本节不复制其正文。

| 项 | 改哪个文件哪一节 | 改成什么（要点） | owner | 时点 | 状态 |
| --- | --- | --- | --- | --- | --- |
| **P9**（`schemes` 维度） | `02-ios-spec.md` §3.2（主题章） | 补 scheme 维度落地条目：`schemes: {light, dark, …}` + 生成器 `--schemes`；运行时换已生成的 scheme、不重启、不进高频路径；**不支持**运行时任意 token/服务端下发；`WDColorSlot` = 32 槽位 | ios-lead + 架构师 | M0-1 冻结前 | **已回写**（iOS 侧）；`12-android-spec.md` 侧由 android 侧负责 |
| **P11**（行高键形） | `02-ios-spec.md` §1.4.1 第 3 行 | 行高由"双键"改**单值键** `size.row-height.{comfortable,compact}` = 60/44（两端同值），并注明"Android 的 48 是布局盒、**不新增令牌键**" | ios-lead + 架构师 | M0-1 冻结前（最迟 M2 批前签名冻结） | **已回写** |
| **P12**（pathspec 写法） | 跨端计划（已退役）§2.2-A⑧ 与 §8.3 工作流 C | 门禁命令的 pathspec 用**仓内相对**写法（`-- .`），不用 `-- iOS/` | tech-lead | M0-1 | **已修正** |
| **P13**（生成物目录大小写） | `docs/SPEC.md`（§1.1/§1.1.2/§1.2.2/§1.3/§1.5.1/§1.5.5/§3.2/§9.2 与 I41/I15/E3/F2.4/F5.4/O-12/D-21 行）、`docs/ARCHITECTURE.md`（目录树 + 两张图）、`AGENTS.md`（§0/§1/§4.1/§5/§7/§9/§10）、`README.md`、`CONTRIBUTING.md` | 生成物目录 = `Sources/WisdomUI/Foundation/generated/`（**小写**，M0-2 生成器目标态）；格式清单排除模式写 `'/Foundation/[Gg]enerated/'`（两种拼写都覆盖——大小写不敏感文件系统上写死一种会**静默失效**） | ios-lead + 架构师 | M0（I-M0-h 同批） | **已回写（本轮）**；⚠️ **顺序与 XR-12 相反**：目录纯移动依**用户裁决**先执行、文档文本已成**事实错误**，登记紧随其后——记为本条一次性例外，**不构成先例** |
| **P15**（快照矩阵的计数词） | `docs/DEV-PLAN.md` §2.2 / §15.1-⑦ / §9（验收矩阵行）、`docs/ARCHITECTURE.md` 的验证矩阵行 | 写作「**六态**：浅/深 × 默认/AX3 × LTR/RTL」，但三个轴相乘 = **8 态**（「六态」是 U6 交互态的词，被借用到快照矩阵上） | 改成「**八态**（浅/深 × 默认/AX3 × LTR/RTL）」或直接去掉计数词，只留括号里的三轴 | ios-lead | M1 出口前 | **待回写**（本端实现已按括号里的三轴执行 8 态：`SnapshotSupport` 头注 + 矩阵计数断言 `matrix.count == 8`） |
| **P14**（行盒放大概判据的 `⌈⌉`） | `docs/SPEC.md` §2.6.3 的 U5-c 行与「U5 定稿措辞」段 | 放大档判据由「`renderedLineBox ≥ ⌈natural × n⌉`」改为「`≥ natural × n − 0.5pt`」：**`⌈⌉` 对非整数自然高不可满足**（实测 caption2/AX3/n=2：自然高 35.83 ⇒ `⌈71.67⌉ = 72`，真实渲染恰为 71.67pt）。**本意（不裁切）不变**，只去掉向上取整引入的 0.33–1pt 假红 | ios-lead + 架构师 | M1 出口前 | **待回写**（本端实现已按新形式落地并登记于 `WDLineBoxTest.swift` 头注；SPEC 文本未改） |
| **P10**（设计侧行高句） | `09-layout.md` :101 | "整行 = 48 布局盒（可见 44 + 上下各 2dp 内边距）；热区 = 该布局盒、不覆盖相邻行" | 设计 + 架构师 | M0-1 | **待回写（设计侧，不阻塞本端实现）** |
| **P7 / P8**（Android 侧） | `12-android-spec.md` §2.3/§3.1.2/§3.3.1 与 :1880 | 行高/热区与 U12 = 32 槽位 | android-lead | M0-1 冻结前 | **非本端**（登记在此仅为闭环视图） |
| **D-06**（历史项，已闭环） | `02-ios-spec.md` §6.1-7 / §9.2-I-M0-i / §9.3-6 / §5-I45 | 门禁 grep 的仓内正确 pathspec | ios-dev + ios-lead | M0-i（已完成） | **已回写**；注：曾有一次"绕过登记直接改"属**一次性授权、不构成先例** |

---

## 7. 设计待给值 / 待签发（**本端入口**）

> **默认执行项先冻结，不得自定值**：设计值未到位时按本表"默认执行项"执行；表里没有的项 = 尚未给值，**不得**用"实现方便"的值顶上。
> **唯一登记处**：**本仓 §7**（设计待给值 / 待签发；自 t82 起为唯一入口）。原跨端计划的 16 项清单随工作区退役，**正文不在本文件复制**。

| # | 待给值 / 待签发项（本端面） | **默认执行项（先冻结）** | 责任 | 时点 | **是否阻塞 M0-1** |
| --- | --- | --- | --- | --- | --- |
| D-1 | 玻璃档位 × 文字可用矩阵 | 按 §5.2 的四条硬规则编码进 `WDGlass.resolve`；`tinted`/`sheen` 不作文字载体 | 设计（签发）+ ios-lead | M0-1 | **是**（影响 M0-1 冻结的语义） |
| D-2 | 效果配额 7 条 | 按 §5.2 的 7 条硬上限 + 违反即降级；"模糊面可数"进 nightly | 设计（勾选）+ ios-lead | M0-1 冻结、M4 首次真机验证 | 否（M0-1 只冻结"存在配额"这一事实） |
| D-3 | 对比度门槛 4.5:1 / 3:1 + 最不利口径 | 按 §5.2 的 5 行门槛 + **最不利取色** | 设计 + ios-lead | M0-1 | **是** |
| D-4 | **iOS 17–25 玻璃降级口径** | **默认 = 纯色降级**（不做模糊、不用系统 `Material`；只返回 `opaque`）；**待设计裁决** | 设计（裁决）+ ios-lead | **M0 D1** | 否（默认动作可先行） |
| D-5 | 减弱动效时长（150 vs 160ms） | **默认 = 150ms**（160ms 不采用）；**待设计裁决** | 设计 | M0-1 | 否 |
| D-6 | sheet 面板圆角 32 | **默认 = 32**（iOS 用 `.continuous`） | 设计 + ios-lead | M0-1 | 否 |
| D-7 | 其余设计值项（圆角/间距/字号阶梯、同心圆角、平台补偿 `+2`、图标尺寸阶梯、状态"第二信号"…） | **不自行补**：等设计给值；实现只用已进令牌的值 | 设计 | 逐项 | 否（但 M0-1 清单不缩表） |

**纪律**：**清单不缩表**——未给值行保留"待设计给值 + 责任人 + 时点"，按默认执行项先冻结、逐行记入版本台账的 deferral 表，并在 CHANGELOG 标注。

---

## 8. 风险与未验证清单（**不得写成"已通过"**）

> 纪律：未跑通/未实测的项只能写**「未验证」**，**不得**在代码注释、README、CHANGELOG、PR 描述或出口报告里写成"已通过"。回填后才允许改成结论。

### 8.1 未验证项（本端）

| # | 未验证项 | 谁回填 | 时点 | 阻塞什么 |
| --- | --- | --- | --- | --- |
| U-01 | `xcodebuild` 全链路：scheme 名固化、PR 各阶段真实耗时、覆盖率报告 | ios-lead | **M0 出口前** | M0 出口③④；M2 起无 PR 门禁。**2026-10-07 全部回填（本项闭合）**：scheme 实测固化 = `WisdomDesign-iOS-Package`；`Scripts/ci.sh pr` 首次全绿（PR-0/1a/1b/2 + 覆盖率报告全部产出，单测 `passed=6`）；**三态耗时中位数 = warm 7.98 / clean 14.46 / cold 58.88 s**（n=3，原始数据 `.build/perf/ci-measure-20261007.json`） |
| U-02 | 签名冒烟的**首次 CI 级实跑**（编译级探针 ≠ CI 级验证）—— **2026-10-06 已回填** | ios-lead | M0 出口前 | M0 出口③；实测 = `ci.sh pr` 的 PR-1a 带 `WD_API_SMOKE` 编译通过、PR-1b `passed=6 failed=0`（2026-10-07 复核） |
| U-03 | 字体自然行高本端实测（zh/en 的 em 比值目前只来自 macOS 侧测量） | ios-dev | **M1 出口前** | M1 行盒 fixtures 与断言 |
| U-04 | 大字号档（AX3 量级）的真机/模拟器实测（12 档 × 12 字阶）—— **2026-10-07 已按模拟器口径实测（本项闭合）** | ios-dev | M1 出口前 | 动态字体验收档。**实测**：`LanguageLineBoxFixture` 全表重录为 **12 档 × 12 字阶 × {en, zh} × {字体级, 渲染级} = 288 条**；U5-c 断言随之覆盖全部 5 个放大档（AX1–AX5），漂移检查覆盖 12 档 |
| U-05 | 真机 `fontScale 2.0` 观感与缩放手感 | 两端 | M1 出口 | 动态字体上界验收 |
| U-06 | 快照渲染器/金标设备矩阵（玻璃类与普通类的渲染器已定，设备矩阵未定） | 两端 + tech-lead | M1 前 | nightly 门禁可用性 |
| U-07 | 三枚举与 `isChecked` 改名的 **CI 级编译验证** | ios-dev | M0/M2 交界 | M2 首批签名冻结 |
| U-08 | SPM `Package.resolved` pin 后"移动 tag"的失败模式 | ios-lead | M6 发布前 | 发布纪律的自证 |
| **U-10** | **系统无障碍审计把 11pt（`caption2`）文本判为 "Dynamic Type unsupported"** —— 2026-10-07 实测定位 | ios-lead + tech-lead | M2 批前（组件大量用 caption2 之前） | nightly-2 的 4 类目审计。**证据（同一视口内的字号阶梯对照）**：`.font(.caption2)`（纯 SwiftUI）／`wdFont(.caption2)`／`wdFont(.caption2)` 观测标签**全部被报**；`.font(.caption)`(12pt)／`.font(.footnote)`(13pt)／`wdFont(.footnote)`／`wdFont(.footnote)` **全部通过**；`ScrollView` 内的 caption2 未参与本轮检查。**结论**：与 `wdFont` 实现无关，是系统审计口径。**当前处置**：demo 的审计视口内不用 11pt（观测标签用 footnote），审计**保持严格**（不开例外）。**待裁决**：组件（`WDBadge`/`WDChip`/辅助文案）若必须在审计视口用 caption2 ⇒ 需要一条**带理由的窄例外**或与设计确认改档，不得全局关掉 `.dynamicType` 类别 |
| U-09 | **归档体积增量与体积门槛值**（M3 出口"体积门槛值定"目前只是待定项） | ios-lead | **M3 出口** | 发布前层的体积断言 |

### 8.2 技术与协作风险（本端相关）

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| 结构检查器误报/漏报（注释与字符串边界） | 规则形同虚设或阻塞正常提交 | 检查器自身"一正一反"样本进 PR 门禁；豁免必须**同行给理由** |
| 生成物与令牌漂移 | 两端数值分叉、快照全红 | 生成器 `--check` + 跨仓 `sha12` 自证；`generated/**` 禁手改 |
| 单值键行高被误解为"两端行距一样" | 视觉评审被判漂移 | §5.1 第 2 行 + F51 登记（行距各端自由）；实机并排只比**可见内容** |
| 玻璃在 17–25 的口径未裁决 | 实现者拿到两种口径 | **默认动作 = 纯色降级**（§7 D-4），待设计裁决后一行更新 |
| 设计给值延迟 | M0-1 冻结窗口只开一次 ⇒ 二次 breaking | **清单不缩表** + 默认执行项先冻结 + deferral 台账 |
| 快照跨机器不稳 | nightly 假红 | 金标设备固定并写进基线 manifest（U-06） |
| 运行时换肤被放进高频路径 | 整树重组、掉帧（不报错） | §5.1 第 4 行明确低频路径约束；nightly 主题注入用例 |

---

## 9. 关键路径与跨端依赖

**关键路径（任一环延迟 ⇒ 全线顺延）**

```
[设计仓] 令牌冻结（M0-1：含 schemes 维度 + 32 槽位）
   → [设计仓] 生成器支持多套输出 + --schemes
   → [本端] generated/** 落地 + 符号快照（apiDump）
   → [跨端] 契约条目 + C-15/U3/F 注册表 + 默认值表落库（M0-5；真源迁入设计仓 contracts/README.md）
   → [逐批] 批前签名冻结 → 实现 → PR 绿 → nightly ×3 绿 → 批出口
   → M2（11）→ M3（封板 + 公开 API 冻结）→ M4（玻璃/配额/对比度转门槛）→ M5（20/20 primitives）→ M6（回归 + 封板 + 双端 tag）
```

**跨端依赖（本端被谁阻塞）**

| 依赖 | 谁提供 | 本端等待什么 | 未到位时的默认动作 |
| --- | --- | --- | --- |
| 令牌冻结（含 `schemes`、32 槽位） | 设计 + 架构师 | `generated/**` 的最终值 | **不冻结值就不得进批前签名冻结**（按默认执行项先冻结、并记 deferral） |
| 生成器多套输出与 `--schemes` | 架构师 | 生成物含多套 scheme | 先用单套实现，切换用例标【未验证】 |
| 契约 `params`/`slots`/`default` | 架构师 + 两端 lead | 批前冻结的对象 | 缺失即**不开工**（I-2 判据） |
| C-15 受控值名 | 架构师 | §5.3 内联表的最终值 | 按 §5.3 执行（本文件即本端权威副本） |
| 设计待给值（§7） | 设计 | D-1/D-3 影响 M0-1 语义 | 按 §7 默认执行项冻结 |
| 图标语义名清单 | 设计 + 架构师 | 44 条名 + `mirrorsInRTL` | 缺名即不实现对应图标；不得自造名 |

**本端对外承诺（不被阻塞的部分）**：M0 的 11 项、M1 的基础设施（除真机数值结论外）、以及各批的"实现 + 单测 + 六态截图"都不依赖设计值即可推进。

---

## 10. 变更与发布

**三层版本**：① 令牌数据版本（设计仓生成物）；② 契约版本（`contracts/README.md` 及其派生）；③ **库版本**（本端 SPM）。三者不一致时必须先对齐再发版。

**SPM tag 只增不改**：打错 tag **不得移动或删除**，改为发下一个补丁版本（如 `v1.0.1`）并在 CHANGELOG 标注"废弃 vX.Y.Z"。tag 前校验：三仓 HEAD 与版本台账一致、`CHANGELOG.md` 有对应段。

**发布顺序（M6 checklist，逐条可判）**：
1. 设计仓冻结并打 tag；
2. 生成器产出生成物；本端与 Android 各在同一提交里带上生成物 + 符号快照；
3. 两端 `PR + nightly` 绿；
4. 发布前层：真机 hitch/首帧、归档 Thinning 增量、体积门槛断言（U-09）；
5. 双端**同 tag** `v1.0.0`（**平台 tag 永远在最后**）；
6. `CHANGELOG.md` 写明 Breaking 段与迁移片段（若追加/改签名）。

**兼容性判定（本端）**：追加带默认值的公开 `init` 参数 = 源码兼容但**破坏符号快照连续性**（需显式更新基线 + CHANGELOG）；改已有参数的类型/标签 = **源级 breaking**；新增枚举 case = 源级 breaking（minor + Breaking 段 + 迁移片段）；改名/删除 = major；**默认值变化不改签名 ⇒ 只能靠契约断言发现**。

**单批变更节奏**：一个批 = 一个变更集（生成物 + 实现 + 快照 + 契约同步）+ 一次批前冻结 + 一次批出口评审；跨批不得混提交。

**提交纪律**：Conventional Commits；`<scope>` 取层名或组件名（如 `primitives/wdlistrow`）；**纯移动与语义变化拆两个提交**；**符号快照与成因同提交**；令牌变更集在三仓使用同一标识。
**评审**：≥1 reviewer；触及 `Foundation/`、公开签名、`Package.swift`、`api/*` 需 ios-lead；**触及跨端统一项必须同时有 android-lead + tech-lead 确认**。

---

## 11. 与仓内另两份文档的分工

| 文档 | 回答什么问题 | 什么时候读 |
| --- | --- | --- |
| **本文件** `docs/DEV-PLAN.md` | **做什么、按什么顺序、做到什么算过、被谁阻塞**（里程碑 M0–M6、逐批组件与判据、命令与门禁、冻结值、回写项、待给值、风险、发布） | 排期/开工/结批/发布时；**本文件是进程与判据的唯一入口** |
| `../AGENTS.md`（施工手册，**有自动加载预算**） | **怎么在这个仓里安全地动手**：入口/禁止项/升级路径/可写边界/命令速查/未验证清单速查/反模式 | agent 每次动手前；细节写不下时**写进本文件或 `ARCHITECTURE.md`，不要塞进 AGENTS** |
| `ARCHITECTURE.md`（架构文档，无预算） | **系统长什么样**：分层与依赖、令牌流水线、主题/动态字体数据流、组件模型与状态机、渲染与降级、门禁拓扑、无障碍焦点、i18n/RTL、ADR、术语表、未闭合项 | 改结构/加组件/评审设计一致性时 |

**重叠处一律给章节号指针，不重复正文**：批次的组件清单与出口判据在**本文件 §2/§3**；命令的"现状"标注在**本文件 §4**；禁止事项与豁免流程在 `../AGENTS.md` §10；玻璃/配额的**规则内容**在 `../AGENTS.md` §12 与 `ARCHITECTURE.md` §6，**本文只保留口径与判据**（§5.2）。

---

## 12. 本文件的验证记录

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| 文件存在且非空 | `test -s iOS/docs/DEV-PLAN.md` | 通过 |
| **自包含**（无任何指向被移除目录的引用） | `grep -cE 'docs/(impl-plan\|structure-discussion)\|[.][.][/]([.]?[.]?docs)' iOS/docs/DEV-PLAN.md`（**字符类/通配形写法**，文本不含完整字面串；等价于本任务 verify 的第一组模式） | **0**（实测） |
| 章节完整（≥11 节） | `grep -c '^## ' iOS/docs/DEV-PLAN.md` | **见目录自检的『标题』数**（t85 起改为与目录同源核对，避免硬编码漂移） |
| 未触碰源码/测试/包清单 | `git -C iOS status --porcelain -- Sources Tests Package.swift README.md` | 空 |
| 关键条目可索引 | `grep -c 'schemes\|text.disabled\|mirrorsInRTL\|4.5:1\|配额' iOS/docs/DEV-PLAN.md` | > 0 |

> 本文件的变更按 §6 的回写纪律管理：**改口径 = 改真源 → 同步本文件**；只改本文件不得改变跨端统一项。

---

## 13. 逐组件索引（37 件 checklist）

### 13.1 索引表（37 行，按批次；**列 = 可勾选 checklist**）

> **怎么用**：① 认领一件 → ② 把该行「状态」列的 `☐` 改成 `🚧`（在途）/ `✅`（已合并）；③ 只按该行的批次、落点、锚点、验收要点作业；④ 依赖列写的件**必须先冻结**（§3 批前签名冻结）。
> **「关键路径件（是/否）」列的口径**：**依据 = §3 的批内顺序与批间依赖**（如 M2 的首批 11 件里关键路径 2 件串行在前）——**事实性、可取证**，且与"不算人力"一致。
> **为什么不是 A/B/C**：原 A/B/C 是**工作量（人日）口径**的载体，与用户决策 #1（vibe coding，不计算人力）冲突，且来源已随退役文档集不可取证 ⇒ **不回填旧数据**；无法从本仓证据判定为关键路径的件**一律写 `否`（保守）**。若日后需要工作量口径，**从工单数据重建**（见 §22）。
> **与 Android 侧对齐**：跨端同批组件在本列的取值**两端一致**（同一批、同一关键路径）。
> **判定式（船长裁决 · 跨端统一 12 件）**：**关键路径件 = 批内串行链上被点名件的并集（跨端同答案）**；M6 的 `WDAssigneePicker` 依 **Android 侧 §9.1 串行链点名**并入，**iOS 侧同批同答案** ⇒ 本表 **是 = 12 / 否 = 25**。
> **🚫 不得反推（限定句）**：**A/B/C 字母与任何聚合计数（如"12 C"）不作现行判据、不得用来反推本列**；本列只认「**本仓三处点名**（§3 批内顺序 / §9 串行链 / §2 批次描述）+ **跨端并集**」。`(C)` 仅作为"**该批内串行在前**"的**点名标记**被引用（**不是**档位口径）；两者数值相同只是巧合可作旁证，**不构成依据**。
> **数据来源**：批次 / 受控值 / 槽位 / 特例 / 行数 / 播报·触觉 = **`docs/SPEC.md` §2.10 的 37 组件矩阵**（逐行同源，不另行解释）；落点路径 = `docs/SPEC.md` §1.1 的目录约定（`Components/{Primitives,Composites}/<组件>/`，一组件一目录、组件件 + 预览件，样式件按需）；快照渲染器 = §1.6 的显式表。

| 组件 | 状态 | 批次 | 关键路径件（是/否） | 落点（本仓相对） | SPEC 锚点 | 形态要点（受控值 / 槽位 / 特例） | 验收要点（该件特有） | 依赖 / 前置 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `WDButton` | ☐ | M2 | 否 | `Components/Primitives/WDButton/`（`WDButton.swift` + `WDButton+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#01（专节 §2.2） | 受控值 `loading` / `isLoading`（值）；槽位 `label`,`leadingIcon`,`trailingIcon`；特例 `.filled`/`.md` | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：按下轻触觉 ×1 | 同批（§3 批内顺序） |
| `WDIconButton` | ☐ | M2 | 否 | `Components/Primitives/WDIconButton/`（`WDIconButton.swift` + `WDIconButton+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#02 | 受控值 `loading` / `isLoading`；槽位 `icon`,**a11y 标签（必填）**；特例 `.plain` | 快照 = `ImageRenderer`（普通类）；无障碍：×1 | 同批（§3 批内顺序） |
| `WDTextField` | ☐ | M2 | **是** | `Components/Primitives/WDTextField/`（`WDTextField.swift` + `WDTextField+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#03（专节 §2.3） | 受控值 `text` / `Binding<String>` ✓；槽位 `label`,`prefix`,`accessory`,`helper`；特例 `.inset` | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行 + 错误 1 行；无障碍：错误出现时播报（assertive，一次） | —（M2 首件） |
| `WDSearchField` | ☐ | M5 | 否 | `Components/Primitives/WDSearchField/`（`WDSearchField.swift` + `WDSearchField+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#04 | 受控值 `text` / `Binding<String>` ✓；槽位 `placeholder`,`leadingIcon`,`label`（取消）；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：**结果数变化 polite**（阈值由调用方） | 同批（§3 批内顺序） |
| `WDSwitch` | ☐ | M2 | 否 | `Components/Primitives/WDSwitch/`（`WDSwitch.swift` + `WDSwitch+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#05 | 受控值 `on` / `isOn` ✓；槽位 `label`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：切换轻 ×1 | 同批（§3 批内顺序） |
| `WDCheckbox` | ☐ | M2 | 否 | `Components/Primitives/WDCheckbox/`（`WDCheckbox.swift` + `WDCheckbox+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#06 | 受控值 `checked` / **`isChecked`** ✓；槽位 `label`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：轻 ×1 | 同批（§3 批内顺序） |
| `WDRadio` | ☐ | M5 | 否 | `Components/Primitives/WDRadio/`（`WDRadio.swift` + `WDRadio+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#07 | 受控值 `selection` ✓；槽位 `label`（组）,`options`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：2 行允许；无障碍：轻 ×1 | 同批（§3 批内顺序） |
| `WDSlider` | ☐ | M5 | 否 | `Components/Primitives/WDSlider/`（`WDSlider.swift` + `WDSlider+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#08 | 受控值 `value` ✓；槽位 `label`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：**松手后播报一次** | 同批（§3 批内顺序） |
| `WDStepper` | ☐ | M5 | 否 | `Components/Primitives/WDStepper/`（`WDStepper.swift` + `WDStepper+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#09 | 受控值 `value` ✓；槽位 `label`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：**高频不给触觉** | 同批（§3 批内顺序） |
| `WDChip` | ☐ | M5 | 否 | `Components/Primitives/WDChip/`（`WDChip.swift` + `WDChip+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#10 | 受控值 `selected` / `isSelected` ✓；槽位 `label`,`leadingIcon`；特例 删除叉独立可达 | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：— | 同批（§3 批内顺序） |
| `WDBadge` | ☐ | M2 | 否 | `Components/Primitives/WDBadge/`（`WDBadge.swift` + `WDBadge+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#11 | 受控值 —；槽位 `label`；特例 4 汉字 | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：不播报 | 同批（§3 批内顺序） |
| `WDAvatar` | ☐ | M2 | 否 | `Components/Primitives/WDAvatar/`（`WDAvatar.swift` + `WDAvatar+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#12 | 受控值 —；槽位 `icon`,`label`；特例 直径锁死 | 快照 = `ImageRenderer`（普通类）；无障碍：读成员名 | 同批（§3 批内顺序） |
| `WDAvatarStack` | ☐ | M5 | 否 | `Components/Primitives/WDAvatarStack/`（`WDAvatarStack.swift` + `WDAvatarStack+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#13 | 受控值 —；槽位 `items`；特例 `children: .combine` | 快照 = `ImageRenderer`（普通类）；无障碍：一次读完 | 同批（§3 批内顺序） |
| `WDDivider` | ☐ | M2 | 否 | `Components/Primitives/WDDivider/`（`WDDivider.swift` + `WDDivider+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#14 | 受控值 —；槽位 无；特例 装饰：`accessibilityHidden` | 快照 = `ImageRenderer`（普通类）；无障碍：不进树 | 同批（§3 批内顺序） |
| `WDProgressBar` | ☐ | M4 | 否 | `Components/Primitives/WDProgressBar/`（`WDProgressBar.swift` + `WDProgressBar+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#15 | 受控值 `value`；槽位 `label`,`valueText`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：**只跨 25/50/75/100** | 同批（§3 批内顺序） |
| `WDProgressRing` | ☐ | M4 | 否 | `Components/Primitives/WDProgressRing/`（`WDProgressRing.swift` + `WDProgressRing+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#16 | 受控值 `value`；槽位 同上；特例 环径锁死 | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：同上 | 同批（§3 批内顺序） |
| `WDCard` | ☐ | M2 | 否 | `Components/Primitives/WDCard/`（`WDCard.swift` + `WDCard+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#17 | 受控值 —；槽位 `content`；特例 `.elevated` | 快照 = `UIHostingController`+`drawHierarchy`（玻璃类 6 个之一）；无障碍：容器 `contain` | 同批（§3 批内顺序） |
| `WDListRow` | ☐ | M2 | **是** | `Components/Primitives/WDListRow/`（`WDListRow.swift` + `WDListRow+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#18（专节 §2.4） | 受控值 `selected` / `isSelected`；槽位 `title`,`subtitle`,`leading`,`trailing`；特例 44/60/76 | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行 ×2；无障碍：整行合并读；删除自定义操作 | `WDTextField`（§9 关键路径 `WDTextField → WDListRow`） |
| `WDListSection` | ☐ | M3 | 否 | `Components/Primitives/WDListSection/`（`WDListSection.swift` + `WDListSection+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#19 | 受控值 `selection` ✓；槽位 `header`,`footer`,`items`；特例 末行无分隔 | 快照 = `ImageRenderer`（普通类）；无障碍：— | 同批（§3 批内顺序） |
| `WDIcon` | ☐ | M2 | 否 | `Components/Primitives/WDIcon/`（`WDIcon.swift` + `WDIcon+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#20 | 受控值 —；槽位 `icon`；特例 装饰：不进树 | 快照 = `ImageRenderer`（普通类）；无障碍：不进树 | 同批（§3 批内顺序） |
| `WDSegmentedControl` | ☐ | M5 | **是** | `Components/Composites/WDSegmentedControl/`（`WDSegmentedControl.swift` + `WDSegmentedControl+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#21 | 受控值 `selection` ✓；槽位 `items`；特例 容器 `contain` | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：切换一次 | 关键路径件（下游批前置） |
| `WDPicker` | ☐ | M5 | 否 | `Components/Composites/WDPicker/`（`WDPicker.swift` + `WDPicker+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#22 | 受控值 `selection` ✓；槽位 `label`,`options`；特例 空数组断言 | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：— | 同批（§3 批内顺序） |
| `WDDatePicker` | ☐ | M5 | **是** | `Components/Composites/WDDatePicker/`（`WDDatePicker.swift` + `WDDatePicker+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#23 | 受控值 `date` ✓；槽位 `label`；特例 locale 由系统 | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：— | 关键路径件（下游批前置） |
| `WDFormRow` | ☐ | M5 | 否 | `Components/Composites/WDFormRow/`（`WDFormRow.swift` + `WDFormRow+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#24 | 受控值 —；槽位 `label`,`control`；特例 标签关联（Q-A11Y-2 规则 1） | 快照 = `ImageRenderer`（普通类）；行盒断言：2 行允许；无障碍：— | 同批（§3 批内顺序） |
| `WDAlert` | ☐ | M4 | **是** | `Components/Composites/WDAlert/`（`WDAlert.swift` + `WDAlert+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#25（+ §2.5） | 受控值 `presented` / `isPresented` ✓；槽位 `title`,`message`,`actions`；特例 焦点归入/归还 | 快照 = `ImageRenderer`（普通类）；无障碍：`ScreenChanged` 归入 | 关键路径件（下游批前置） |
| `WDBottomSheet` | ☐ | M4 | **是** | `Components/Composites/WDBottomSheet/`（`WDBottomSheet.swift` + `WDBottomSheet+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#26（+ §2.5） | 受控值 `presented` / `isPresented` ✓；槽位 `title`,`content`,`footer`；特例 `.all`/`.half` | 快照 = `UIHostingController`+`drawHierarchy`（玻璃类 6 个之一）；无障碍：焦点陷阱 + 归还 | 关键路径件（下游批前置） |
| `WDActionSheet` | ☐ | M4 | **是** | `Components/Composites/WDActionSheet/`（`WDActionSheet.swift` + `WDActionSheet+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#27（+ §2.5） | 受控值 `presented` / `isPresented` ✓；槽位 `title`,`message`,`items`；特例 空 items 断言 | 快照 = `UIHostingController`+`drawHierarchy`（玻璃类 6 个之一）；无障碍：同上 | 关键路径件（下游批前置） |
| `WDToast` | ☐ | M4 | **是** | `Components/Composites/WDToast/`（`WDToast.swift` + `WDToast+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#28（+ §2.5） | 受控值 `presented` / `isPresented` ✓；槽位 `message`,`actions`；特例 **`variant = .neutral`**；duration 支持 ≥5000ms | 快照 = `ImageRenderer`（普通类）；行盒断言：2 行允许；无障碍：polite；暂停=继续剩余时间 | 关键路径件（下游批前置） |
| `WDBanner` | ☐ | M4 | 否 | `Components/Composites/WDBanner/`（`WDBanner.swift` + `WDBanner+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#29 | 受控值 `visible` / `isVisible` ✓；槽位 `message`,`actions`；特例 **`variant = .info`**；软底而非玻璃 | 快照 = `ImageRenderer`（普通类）；行盒断言：2 行允许；无障碍：polite | 同批（§3 批内顺序） |
| `WDEmptyState` | ☐ | M4 | 否 | `Components/Composites/WDEmptyState/`（`WDEmptyState.swift` + `WDEmptyState+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#30 | 受控值 —；槽位 `title`,`message`,`actions`；特例 — | 快照 = `ImageRenderer`（普通类）；行盒断言：说明 2 行允许；无障碍：— | 同批（§3 批内顺序） |
| `WDSkeleton` | ☐ | M4 | 否 | `Components/Composites/WDSkeleton/`（`WDSkeleton.swift` + `WDSkeleton+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#31 | 受控值 —；槽位 无；特例 减弱动效→静态 | 快照 = `ImageRenderer`（普通类）；无障碍：**整区只播报一次** | 同批（§3 批内顺序） |
| `WDPullToRefresh` | ☐ | M5 | **是** | `Components/Composites/WDPullToRefresh/`（`WDPullToRefresh.swift` + `WDPullToRefresh+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#32 | 受控值 `refreshing` / `isRefreshing` ✓；槽位 `label`；特例 **默认 `.refreshable`（系统视觉）**（O-7 裁决） | 快照 = `ImageRenderer`（普通类）；无障碍：到阈值一次触觉 | 关键路径件（下游批前置） |
| `WDNavigationBar` | ☐ | M5 | **是** | `Components/Composites/WDNavigationBar/`（`WDNavigationBar.swift` + `WDNavigationBar+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#33 | 受控值 —；槽位 `title`,`leading`,`trailing`；特例 玻璃档由文字级别决定 | 快照 = `UIHostingController`+`drawHierarchy`（玻璃类 6 个之一）；行盒断言：标题 1 行；无障碍：— | 关键路径件（下游批前置） |
| `WDTabBar` | ☐ | M5 | **是** | `Components/Composites/WDTabBar/`（`WDTabBar.swift` + `WDTabBar+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#34 | 受控值 `selection` ✓；槽位 `items`；特例 深色不透明表面（O-13） | 快照 = `UIHostingController`+`drawHierarchy`（玻璃类 6 个之一）；行盒断言：**2 行允许**（U7）；无障碍：切换一次 | 关键路径件（下游批前置） |
| `WDToolbar` | ☐ | M5 | 否 | `Components/Composites/WDToolbar/`（`WDToolbar.swift` + `WDToolbar+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#35 | 受控值 —；槽位 `items`；特例 溢出收菜单 | 快照 = `UIHostingController`+`drawHierarchy`（玻璃类 6 个之一）；行盒断言：1 行；无障碍：— | 同批（§3 批内顺序） |
| `WDFAB` | ☐ | M5 | 否 | `Components/Composites/WDFAB/`（`WDFAB.swift` + `WDFAB+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#36 | 受控值 —；槽位 `icon`,`label`（必填）；特例 热区 ≥44 | 快照 = `ImageRenderer`（普通类）；无障碍：轻 ×1 | 同批（§3 批内顺序） |
| `WDAssigneePicker` | ☐ | M6 | **是** | `Components/Composites/WDAssigneePicker/`（`WDAssigneePicker.swift` + `WDAssigneePicker+Previews.swift`；样式件按需） | `docs/SPEC.md` §2.10-#37 | 受控值 `selection` ✓；槽位 `items`,`label`；特例 落 `Composites` | 快照 = `ImageRenderer`（普通类）；行盒断言：1 行；无障碍：选择一次 | 同批（§3 批内顺序） |

### 13.2 使用方式与纪律

- **一件一行、不用完成度**：判据只有"该行验收要点全绿 + 该批出口判据全绿"；**禁止**写"完成 80%"（§5 与 §15）。
- **两个视角同源**：§3 是**批次视角**（批前冻结 → PR → nightly → 出口），本节是**组件视角**（逐件 checklist）。同一件事的两种排布，**冲突时以 §3/§15 的批次判据为准**。
- **勾选纪律**：`☐` → `🚧`（在途）→ `✅`（已合并）。**只有**该行的"验收要点"全绿才允许改 `✅`；改状态时**不要**删掉本表的其它列。
- **每件必过四类检查**（细则见 §14.4）：① API 形状 ② 状态优先级（U6）③ 边界场景（含本行"特例"）④ 无障碍语义；**再加两类**：⑤ 六态快照 ⑥ 行盒/字体（凡"高度由文本撑开"的件）。
- **玻璃类 6 个**（`WDBottomSheet`/`WDActionSheet`/`WDTabBar`/`WDNavigationBar`/`WDToolbar`/`WDCard(.glass)`）**额外**：快照用 `UIHostingController`+`drawHierarchy`（`ImageRenderer` 不渲染 `Material`/`glassEffect`）；配额与文字可用按 §5.2 与 `AGENTS.md` §12 执行。
- **矩阵是外部真源**：批次/槽位/特例/行数/播报·触觉以 `docs/SPEC.md` §2.10 为准；**矩阵变更时先改真源、再同步本表**（§6 回写纪律），禁止只见本表就改口径。

---

## 14. 单组件作业流程（SOP：从 0 到合并）

### 14.1 ① 选件与读规格

**动作**：在 §13.1 认领一行（状态改 `🚧`），然后**按固定顺序**读这些章节（都是仓内文件，直接用章节号）：

| 顺序 | 读什么 | 为什么 |
| --- | --- | --- |
| 1 | `docs/SPEC.md` §2.10 的**该组件行**（用 §13.1 的锚点：`§2.10-#NN`） | 受控值 / 槽位 / 特例 / 行数 / 播报·触觉 —— 该件的**需求全貌** |
| 2 | 专节（若有）：`docs/SPEC.md` §2.2 / §2.3 / §2.4 / §2.5 | 首批三件与弹层的**完整形态裁决** |
| 3 | `docs/SPEC.md` §2.6（状态机 / 行盒 / 无障碍语义） | U6 优先级、`wdLineBox`、语义与播报 |
| 4 | `docs/SPEC.md` §2.7（组合与样式覆盖优先级）、§2.8（边界场景）、§2.9（类型约束/废弃）、§2.11（三枚举） | 实现细节与反例清单 |
| 5 | 本文件 §5.3（受控值名）、§5.1（冻结值）、§5.2（主题/无障碍/配额） | 名字与值一律以仓内表为准 |
| 6 | `AGENTS.md` §3.1（入口判据）、§6（冻结值）、§10（禁止项）、§12（玻璃/配额/对比度） | 开工前的硬约束 |

```bash
# 秒级检索本件在全仓文档里的所有出现（把 <C> 换成组件名）
grep -n -- '<C>' docs/SPEC.md | head -40
grep -n -- '<C>' docs/DEV-PLAN.md | head -20
grep -n -- '<C>' AGENTS.md | head -20
```

**产物**：一条 PR 描述里的"需求引用"清单（至少 3 条章节锚点）。**不做完这一步不要写代码。**

### 14.2 ② 落点与文件清单

**落点**（`docs/SPEC.md` §1.1 的目录约定）：

```text
Sources/WisdomUI/Components/<Primitives|Composites>/<C>/
  ├── <C>.swift              # 公开 API + 视图实现 + 状态机接入（public 组件）
  ├── <C>Style.swift         # 按需：样式/变体与令牌取用（同目录可 internal）
  └── <C>+Previews.swift     # 预览：整文件由 #if WD_PREVIEWS 包裹
Tests/WisdomUITests/Components/<C>Tests.swift          # 逻辑/契约/无障碍断言
Tests/WisdomUISnapshotTests/<C>SnapshotTests.swift     # 六态快照
```

```bash
# 建目录（把 <C> 换成组件名；Primitives/Composites 按 §13.1 的落点列）
mkdir -p "Sources/WisdomUI/Components/Primitives/<C>" Tests/WisdomUITests/Components Tests/WisdomUISnapshotTests
ls -1 Sources/WisdomUI/Components/Primitives/ | wc -l   # 用来自证目录数与 §13.1 一致
```

**边界**：`Internal/**` 零 `public`；`Components/**` 不得 `import UIKit`、不得写 Environment、不得出现静态令牌入口（`AGENTS.md` §10 的 R 系列禁则，检查器会拦）。

### 14.3 ③ 骨架与关键实现要点

**骨架（三分法，照抄形态）**

```swift
// Sources/WisdomUI/Components/Primitives/<C>/<C>.swift
public struct <C>: View {                      // 组件：public；签名按 §5.3 的受控值名
    public init(/* 受控值 + 槽位（@ViewBuilder）*/) { }
    public var body: some View {
        // 只读环境：@Environment(\.wdColors) / \.wdDensity / \.wdEffectsBudget
        // 令牌取用：wdFont(_:) / WDSpacing / WDRadius / WDElevation（禁字面量，R7）
    }
}
// Sources/WisdomUI/Components/Primitives/<C>/<C>+Previews.swift
#if WD_PREVIEWS
#Preview { /* 六态：浅/深 × 默认/AX3 × LTR/RTL */ }
#endif
```

**关键实现要点（逐条对照，不要跳）**

| 要点 | 怎么做 | 依据 |
| --- | --- | --- |
| 状态机 | 优先级 `disabled > loading > pressed > focused > hover > default`；disabled 吞输入；loading 忽略 `action` 但系统 `isEnabled` 仍 true 且留在无障碍树；focused/hover 是叠加维度 | `AGENTS.md` F-12；`docs/SPEC.md` §2.6.1 |
| 槽位 vs 参数 | 只有 `docs/SPEC.md` §2.10 的 **21 名槽位词表**里的名字算槽位（`@ViewBuilder`）；其余一律是参数 | `AGENTS.md` F-15 |
| 命名 | 受控值参数名以 §5.3 为准（如 `isChecked`，**不是** `isOn`）；公开类型名 `WD` 前缀 | §5.3；`AGENTS.md` F-14/F-19 |
| 行盒 | "高度由文本撑开"必须显式给令牌 `minHeight` + `wdLineBox(_:lines:)`；**禁** `.frame(height:)` 绑令牌、`Mode.Fixed`、`lineHeightMultiple`、`minimumScaleFactor` | `AGENTS.md` F-13/§10；`docs/SPEC.md` §2.6.3 |
| 无障碍 | 语义/播报按 `docs/SPEC.md` §2.6.2 与 §2.10 的"播报·触觉"列；库内零文案（读屏标签由调用方传入） | `AGENTS.md` F-08 |
| 玻璃类 | **唯一入口** `WDGlass.resolve(textLevel:appearance:capabilities:budget:)`；每屏模糊面 ≤1、列表项内 0；深色端文字规则 | §5.2；`AGENTS.md` §12.1/§12.2 |
| 动效 | 只用 `WDMotion` 包装；禁 `withAnimation` 包整 body、禁无 value 的 `.animation(_:)`、禁组件自建计时器 | `AGENTS.md` §10 |
| 主题 | 颜色/字号**只读**环境（`@Environment(\.wdColors)` / `wdFont(_:)`）；**不写** Environment、不覆写平台设置 | `AGENTS.md` §10（R10/R11/R16/R18） |

### 14.4 ④ 测试怎么写（六类必需断言）

**六类断言 = 每件的默认门槛**（缺一类即视为未完成；放 `Tests/WisdomUITests/Components/<C>Tests.swift`，快照类放 `SnapshotTests`）：

| # | 类别 | 必须断言什么 | 怎么写（示例形态） |
| --- | --- | --- | --- |
| 1 | **API 形状** | 公开签名与 §5.3/`docs/SPEC.md` §2.10 一致（参数名、默认值、枚举 case、槽位名） | 签名冒烟（`#if WD_API_SMOKE`）与该件实签名不漂移；`api/WisdomUI.api.json` 快照 diff = 0 |
| 2 | **状态优先级（U6）** | 六态顺序与三条派生（disabled 吞输入 / loading 留树 / focused·hover 叠加） | 用条件注入六态，逐态断言 `isEnabled`、是否触发 `action`、无障碍树成员 |
| 3 | **边界场景** | `docs/SPEC.md` §2.8 的边界 + **本件在 §2.10 的"特例"列**（如"删除叉独立可达""直径锁死""只跨 25/50/75/100""高频不给触觉"） | 逐条写成命名用例（用例名 = 特例原文的关键词，便于对齐） |
| 4 | **无障碍语义** | 语义角色/标签来源/播报时机与强度/触觉次数；装饰件不进树 | 断言语义树（`accessibilityLabel` 来自调用方）、播报一次、触觉 ≤1 次 |
| 5 | **六态快照** | 浅/深 × 默认/AX3 × LTR/RTL 六图入库（玻璃类 6 个换渲染器） | `-only-testing:WisdomUISnapshotTests`；基线文件与本次提交同 PR |
| 6 | **行盒/字体** | 凡"高度由文本撑开"：默认档 `abs(rendered − max(设计, natural)) ≤ 0.5pt`；放大档不裁切；中英混排（中文 1.400em） | `WDLineBoxTest` + 该件 fixture；按 `docs/SPEC.md` §2.6.3 的容差式断言 |

**测试写作纪律**：① 用例名 = 判据的关键词（便于与 §13.1/§15 对齐）；② **不测"实现细节"**（私有类型/内部函数），只测可观测行为与公开签名；③ 涉及跨端统一项（U 系列）的断言必须在 PR 描述里登记（`AGENTS.md` §9）。

```bash
# 只跑本件的逻辑测试（M0-6 起；<C> 换成组件名）
xcodebuild test-without-building -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" \
  -derivedDataPath .build/dd -only-testing:WisdomUITests/<C>Tests
```

### 14.5 ⑤ 本地跑什么（秒级回路）

**按"先便宜后昂贵"的顺序跑**（期望输出写在括号里）：

| # | 命令 | 现状 | 期望 |
| --- | --- | --- | --- |
| 1 | `Scripts/check-structure.sh` | `M0-6 起` | 退出 0，无 R1–R21 violation |
| 2 | `Scripts/check-format.sh` | `M0-6 起` | 退出 0（`generated/` 已排除） |
| 3 | `xcrun swift-format lint --strict --parallel $(git ls-files '*.swift' \| grep -vE '/Foundation/[Gg]enerated/')` | `现成` | 无输出（有输出即格式问题） |
| 4 | `xcodebuild -list` | `现成` | 列出 `WisdomDesign-iOS-Package`（首次跑通后固化） |
| 5 | `xcodebuild build -scheme "${WD_SCHEME:-WisdomDesign-iOS-Package}" -destination 'generic/platform=iOS' -derivedDataPath .build/dd -quiet` | `现成` | 设备编译通过（**不是** `swift build`） |
| 6 | 单件单测（`-only-testing:WisdomUITests/<C>Tests`） | `M0-6 起` | 全绿；失败先看断言名对应的判据 |
| 7 | 六态快照（`-only-testing:WisdomUISnapshotTests`） | `M1 起` | 基线一致；新增件须**首次入库**基线 |

**产物路径**：DerivedData = `.build/dd`；结果包 = `.build/dd/pr.xcresult`；性能 JSON = `.build/perf/{date}.json`；覆盖率 = `.build/perf/coverage.json`。

### 14.6 ⑥ PR 前跑什么（门禁）

```bash
# 一步版（等价于下面四条；M0-6 起）
Scripts/ci.sh pr

# 分步版（想定位失败点时用）
Scripts/check-structure.sh && Scripts/check-format.sh
xcodebuild build-for-testing -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" -derivedDataPath .build/dd -quiet \
  -enableCodeCoverage YES -resultBundlePath .build/dd/pr.xcresult \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'
xcodebuild test-without-building -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" -derivedDataPath .build/dd \
  -only-testing:WisdomUITests -test-timeouts-enabled YES -default-test-execution-time-allowance 60
Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json
```

**期望**：全部退出 0；符号快照与成因**同 PR**（`AGENTS.md` §9）；若本件落地了声明，**同 PR 删除签名冒烟的对应段落**（`docs/SPEC.md` §1.2.2 的删段法）。

### 14.7 ⑦ PR 与评审要求

**PR 模板必勾项**（模板本体按 `AGENTS.md` §9，逐项都要证据）：变更类型（纯移动 / 语义变化）｜跨端边界（是否触及 U 系列）｜反模式自检 3 条｜L-B 自检｜门禁自检（§14.6 的命令）｜契约与无障碍（`acceptance.yaml` + `preview-cases.yaml`）｜证据（命令输出/截图/快照 diff）。

**reviewer 关注项（按顺序看）**：① 受控值名与 §5.3 是否逐字一致；② 状态机六态与三条派生是否都有断言；③ 边界"特例"是否逐条覆盖；④ 无障碍语义/播报/触觉；⑤ 六态快照（玻璃类渲染器对不对）；⑥ 行盒断言；⑦ 是否引入 §10 的禁则。

**评审升级**：触及 `Foundation/`、公开签名、`Package.swift`、`api/*` ⇒ 需要 `ios-lead`；**触及 U 系列必须同时有 android-lead + tech-lead 确认**（`AGENTS.md` §9）。

**文档类改动**：改了任何文档，先过 `docs/DEV-PLAN.md` §4.6 的**六个固定项**与两条纪律（结构自检 / 禁止自命中 / 双跑）。

### 14.8 ⑧ 批前冻结与批出口

**① 批前签名冻结（每批第 0 步，`AGENTS.md` §3.1 的 I-2）**：该批每件组件的**完整公开签名**（含枚举 case 与默认值）+ `contracts/<component>.yaml` 的 `params`/`slots`/`default` 入库后才允许开工（`contracts/*.yaml` 库 **M0-5 才落库**；在此之前以"冻结会登记的表单"代替）。

**② 冻结后改签名**：走 U 项变更流程（先改真源，再同步两端副本），不得"顺手改"。

**③ 批出口**（判据 = §2 对应里程碑 + §15 该批的检查清单）：

```bash
# 批出口最小集合（M0-6 起；M2–M6 还要 nightly 连续 3 日绿）
Scripts/ci.sh pr
xcodebuild test-without-building -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" -derivedDataPath .build/dd \
  -only-testing:WisdomUISnapshotTests
```

**④ 出口报告的固定结构**：该批组件清单（对照 §13.1 的批次列，**无缺件**）→ 判据逐条"通过/不通过 + 证据"→ 该批性能数字（只报不拦）→ 无障碍断言结果 → 符号快照状态 → 未闭合项（带责任人 + 时点）。**不使用完成度百分比**（§5）。

---

## 15. 验收手册（逐批：判据 · 命令 · 处置）

### 15.1 M0 验收

**判据**：§2.1 的 6 条（此处不重复）。**逐条验收方式 + 处置**：

| # | 验收命令 | 现状 | 期望结果 | 不通过怎么办 |
| --- | --- | --- | --- | --- |
| ① | `Scripts/check-structure.sh && Scripts/test-checker.sh` | `M0-6 起` | 两条都退出 0 | 先用 `Scripts/Fixtures/structure/{pass,fail}/*.swift` 判断是**规则实现**错还是**样本**错；规则错改检查器，样本错改样本 |
| ② | `Scripts/check-format.sh` | `M0-6 起` | 退出 0；且**基线格式化提交早于** `api/WisdomUI.api.json` 入库（查 `git log --oneline -- api/WisdomUI.api.json` 与格式化提交的先后） | 顺序反了：重排提交（rebase）而不是重跑快照 |
| ③ | `Scripts/ci.sh pr` | `M0-6 起` | 首次全绿（含签名冒烟 + 单测 + 覆盖率报告） | 冒烟编译失败 ⇒ 先看 `#if WD_API_SMOKE` 段落是否与真实声明漂移 |
| ④ | `Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json` | `M0-6 起` | 无 diff | 有 diff ⇒ 要么补提交基线，要么撤销签名变更；**不要** `--no-verify` 绕过 |
| ⑤ | `node ../wisdomdesign/tools/token-build/build.js --check` + `--tokens-trace` | `现成` | `sha12` 相等；manifest 缺失 = fail | 不等 ⇒ 停止实现、找架构师核生成物溯源（不得手改 `generated/**`） |
| ⑥ | `git grep -nE 'swift (build\|test)' -- . \| grep -v -- '-product wd-structure-check'` | `现成` | **空**（M0-i 删掉 `README.md` 的两行后） | 有命中 ⇒ 定位到具体行删掉；**不要**改判据 |

**M0 出口额外的机器自证**：`Package.swift` 无 `plugins:`、无 macOS 平台、显式 Swift 6（人工看 3 行）。

### 15.2 M1 验收

**判据**：§2.2 的 5 条。**验收方式**：

| # | 验收命令 | 现状 | 期望结果 | 不通过怎么办 |
| --- | --- | --- | --- | --- |
| ① 行盒 fixtures | `xcodebuild test-without-building … -only-testing:WisdomUITests/WDLineBoxTest` | `M1 起` | 默认档 `\|rendered − max(设计, natural)\| ≤ 0.5pt`；放大档不裁切 | 中文/英文 fixture 分开看：中文 1.400em 情形最容易破 |
| ② 12 条预算有数 | 跑 `-only-testing:WisdomUIPerfTests`（或等价）→ `.build/perf/{date}.json` | `M1 起` | 文件产出且含 12 条指标 | 缺指标 ⇒ 先补测量点，**不要**填估算值（未测不写预算） |
| ③ demo 可跑 | `xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo …` | `M1 起` | 退出 0 | 工程打不开/Demo 未建 ⇒ M1 首件事就是建它 |
| ④ 运行时换 scheme | demo 内切换 scheme 的用例 | `M1 起` | 主题值变化触发重组/重算，**不重启进程** | 整树重组卡顿 ⇒ 检查是否把切换放进了高频路径（§5.1 第 4 行） |
| ⑤ 三件套骨架 | `-only-testing:WisdomUITests/WDGlassMatrixTests` 等 | `M1 起` | 用例存在且能红能绿 | 只写"能绿"的用例 = 无效；必须有两条"必须红"的用例（`AGENTS.md` §12.1） |

### 15.3 M2–M6 验收

**通用三件**（每批都跑）：`Scripts/ci.sh pr`（`M0-6 起`）→ 六态快照（`M1 起`）→ nightly 连续 3 日绿（`M1 起`）。
**判据全文**：M2 = §2.3（6 条）｜M3 = §2.4（6 条）｜M4 = §2.5（7 条）｜M5 = §2.6（6 条）｜M6 = §2.7（7 条）。下表**只给该批特有**的验收命令与处置。

| 批 | 特有验收（命令 → 期望） | 现状 | 不通过怎么办 |
| --- | --- | --- | --- |
| **M2** | `… -only-testing:WisdomUISnapshotTests` → 11 件六态全绿；行高断言（`WDListRow` 可见内容 44 ± 0.5）→ 绿；`WD_API_SMOKE` 已删 11 段 → `grep -c 'WDButton' Sources/WisdomUI/APISurface/WDAPISurface.swift` = 0 | `M1 起` | 快照红 ⇒ 先判断是**基线漂移**还是**实现变化**（见 §16.4-③）；冒烟段残留 ⇒ 同 PR 删除 |
| **M3** | `api/WisdomUI.api.json` 入库 + `git diff --exit-code` 绿；覆盖率 `Foundation/**` ≥ 80%（排除 `generated/`）；体积门槛值写进 `README.md`/`CHANGELOG.md` | `M0-6 起` | 覆盖率差 ⇒ 补 `Foundation/**` 单测，**不要**降低门槛；体积门槛未定 ⇒ 先测（`xcodebuild archive`）再写值 |
| **M4** | 玻璃矩阵单测（档位 × `appearance` × `textLevel`）→ 绿且含两条"必须红"用例；配额 7 条计数断言 → 绿；最不利取色对比度 → 账目入库；发布物冒烟（归档可产出） | `M1 起`/发布前层 `M6 起` | 玻璃矩阵红 ⇒ 先查 `WDGlass.resolve` 是否被旁路（组件自选档 = 违反唯一入口）；配额红 ⇒ 按 §5.2 降级而不是放宽配额 |
| **M5** | 20/20 primitives 完成（对照 §13.1 的批次列**无缺件**）；动态字体降级矩阵（含 compact 三条）→ 绿；RTL 六态 → 入库；组件类型名集合 == 注册表 | `M1 起` | 类型名不一致 ⇒ 以契约真源为准改实现（副本不得自行加名） |
| **M6** | VoiceOver 走查记录 + `performAccessibilityAudit` 四类目 → 通过；37 件截图封板；`xcodebuild archive` + Thinning 增量 + 真机 hitch；双端同 tag `v1.0.0`；tag 前 `git describe --tags --exact-match` == 生成物版本 | 发布前层 `M6 起` | tag 校验不符 ⇒ **不移动 tag**，发下一个补丁版本并标注废弃（§10） |

### 15.4 每批一次的检查清单（可勾选）

> 每批**复制一次**这份清单到该批的出口报告里，逐项勾选并附证据（命令输出/截图/diff 链接）。**缺一项就不算通过。**

- [ ] **批前签名冻结**：该批每件签名 + 契约条目已入库（I-2）；冻结后无"顺手改签名"
- [ ] **§13.1 的批次列无缺件**：该批组件逐件 `✅`，且每件的六类断言齐全（§14.4）
- [ ] **PR 门禁**：`Scripts/ci.sh pr` 绿（`M0-6 起`）；符号快照与成因同提交
- [ ] **nightly**：连续 3 日绿（`M1 起`），记录日期与运行链接
- [ ] **六态快照**：浅/深 × 默认/AX3 × LTR/RTL 入库；玻璃类 6 个用对渲染器
- [ ] **无障碍**：语义/播报/触觉断言绿；对比度按**最不利取色**（玻璃取合成色）
- [ ] **性能数字**：该批指标进报告（**只报不拦**）；有"可数"类断言（如模糊面数量）
- [ ] **差异登记**：新增/变更的跨端差异已进契约两端形态表（F 系列）；U 系列有双端确认
- [ ] **未闭合项**：逐条带责任人 + 时点；**没有"后续跟进"这种无主项**
- [ ] **文档**：改了文档的，已过 §4.6 的六个固定项 + 双跑
- [ ] **出口报告**：按 §14.8 的固定结构落盘（**无完成度百分比**）

---

## 16. 开发者指南

### 16.1 环境与工具链准备

| 项 | 版本/要求 | 怎么验 |
| --- | --- | --- |
| Xcode | **≥ 26**（`glassEffect` 需 SDK 26；`import Accessibility` 需 iOS 17 SDK） | `xcodebuild -version` |
| 部署目标 | `platforms: [.iOS(.v17)]`，**不加 macOS** | `grep -n 'platforms' Package.swift` |
| 语言模式 | `swift-tools-version: 6.1` + Swift 6 语言模式（严格并发） | `head -1 Package.swift` |
| 模拟器 | 最新可用运行时；**按 UDID** 解析，禁按设备名硬编码 | `xcrun simctl list -j devices available`（下方变量准备） |
| 运行时依赖 | 只需 `python3`（`ci.sh` 解析 UDID）；**Node 不是 iOS 依赖**（只有跨仓跑令牌生成器才要） | `python3 -V` |
| 第三方依赖 | **零**（格式/快照/测试都用工具链自带） | `grep -c 'dependencies:' Package.swift` |

```bash
export WD_SCHEME="WisdomDesign-iOS-Package"   # 首次跑通后固化进 README 与 ci.sh 常量
export WD_SIM_ID="$(xcrun simctl list -j devices available | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=[(rt,x) for rt,ds in d["devices"].items() if "iOS" in rt for x in ds if x.get("isAvailable")]
c.sort(key=lambda t:(t[0], t[1]["name"]))
print(c[-1][1]["udid"])')"
echo "$WD_SCHEME / $WD_SIM_ID"
```

> `Scripts/ci.sh pr` 内部会自解析这两个值；手工跑 `xcodebuild` 时才需要 export。

### 16.2 代码风格与命名

- **格式化**：`Scripts/check-format.sh`（`swift-format`，显式清单，排除 `generated/`）；`generated/**` 永远不手改（R12 会拦）。
- **命名**：`WD` 前缀（`AGENTS.md` F-14）；受控值参数名以 §5.3 为准（`isChecked` / `isOn` / `text` …）；枚举 = `String` 原始值 + `CaseIterable` + `Sendable`，**不加 `@frozen`**（F-20）；公开类型名 `WDBottomSheetDetent`/`WDBottomSheetDetents`，**禁 `WDSheet*`**（F-19）。
- **目录大小写**：iOS `Components/Primitives`+`Composites`（与 Android `components/…` 的大小写差异是**已登记差异**，不要"对齐"，F-21）。
- **禁则速查**（详见 `AGENTS.md` §10）：`AnyView`；存储型 `static var`；`Components/**` 里 `import UIKit`；`.frame(height:)` 绑令牌；静态令牌入口（`WDColor.*`/`WDType.*`）；`.font(.system(`；组件里写 Environment；覆写平台设置；数值字面量；库内文案/标点；`GeometryReader` 包内容、`minimumScaleFactor`、`Mode.Fixed`/`lineHeightMultiple`、无 value 的 `.animation(_:)`、组件自建计时器；手改 `Foundation/generated/**`。
- **豁免**：检查器豁免必须**同行给理由**（`// wd-structure-check:disable R1 — 理由`），reviewer 按"豁免必须有理由"审；**不得**靠放宽规则或改规格绕过。

### 16.3 提交信息与分支模型

- **提交信息 = Conventional Commits**（强制）：`<type>(<scope>): <summary>`；`type` ∈ {feat, fix, perf, refactor, style, test, build, ci, docs, chore}；`scope` 取层名或组件名（如 `primitives/wdlistrow`、`foundation/tokens`）。
- **三条 iOS 特有纪律**：① 纯移动与语义变化**拆两个提交**；② `api/WisdomUI.api.json` **与成因同提交**；③ 令牌变更集在三仓用**同一标识**（如 `tokens: v1.0.0-rc.1`）。
- **分支**：`main` 受保护（禁直推、禁 force-push）；短命分支 `feat/wdbutton`、`tokens/v1.0.0-rc.1`，生命周期 ≤5 天；**跨层移动/API 冻结类 PR 用 rebase-merge 保留两个提交**，其余 squash-merge。
- **PR 与评审**：≥1 reviewer；触及 `Foundation/`、公开签名、`Package.swift`、`api/*` 需 `ios-lead`；**触及 U 系列需 android-lead + tech-lead 确认**（细则 §14.7）。

### 16.4 常见错误与排查（Troubleshooting）

| # | 症状 | 最可能的原因 | 处置 |
| --- | --- | --- | --- |
| ① | 改了 `Foundation/generated/**` 后 `check-structure.sh` 报 R12 | 手改了生成物（banner 校验会拦） | **撤销手改**；改令牌 → 走设计仓变更集 → 跑 `node ../wisdomdesign/tools/token-build/build.js` 重新生成 |
| ② | PR 门禁红，但不知道是哪一类 | 三种类型混在一起：结构（R1–R21）/ 格式（swift-format）/ 编译测试 | 先跑**最便宜**的两条 `Scripts/check-structure.sh`、`Scripts/check-format.sh`，都绿再跑 `build-for-testing`；仍然红看 `xcodebuild` 的**第一条** error（后面的多是连带错） |
| ③ | 六态快照红 | 两类：**基线漂移**（环境/字体/渲染器变了）vs **实现变化**（真的改了像素） | 先看 diff 区域：只变字形抗锯齿 ⇒ 基线漂移（复核金标设备矩阵 U-06）；变成结构性变化 ⇒ 是实现变化，**更新基线必须与成因同 PR** |
| ④ | 行盒/字体断言红（中文特别容易） | 中文自然行高 1.400em > 设计值 ⇒ "默认档 = 设计值"不成立 | 用**带容差的 max 形式**断言（`max(设计盒高×缩放, natural)`）并给中英 fixture；**不要**改用 `Mode.Fixed`/`lineHeightMultiple`（R 系列禁则） |
| ⑤ | 改了 `Package.swift` 后行为诡异（旧脚本还在跑 / 新 target 不生效） | `.build` 缓存陈旧 | 删缓存后重跑：`rm -rf .build/dd`，必要时 `xcodebuild clean -scheme "$WD_SCHEME"`；**不要**用 `swift build` 绕过 |
| ⑥ | `xcodebuild` 报 destination/scheme 解析失败 | scheme 名未固化 / 模拟器 UDID 过期 / 用了设备名 | `xcodebuild -list` 看真实 scheme；用 §16.1 的 UDID 解析命令重新取；**禁按设备名硬编码** |
| ⑦ | 令牌溯源失败（`sha12` 不等 / manifest 缺失） | 生成物与设计仓不同批 | 停止实现，找架构师核生成器与 manifest；缺失 = fail（不是 skip） |
| ⑧ | 玻璃件在模拟器上"没效果" | `ImageRenderer` 不渲染 `Material`/`glassEffect`；或系统版本在 17–25（纯色降级是**默认动作**） | 用 `UIHostingController`+`drawHierarchy` 快照；确认是否命中 17–25 分支（§5.2 的 DF-10 口径） |

### 16.5 遇到阻塞找谁（升级路径）

**先自问三句**（`AGENTS.md` §11）：① 是否触及 **U 系列**（名字/取值/默认值/行盒/状态优先级/触控数值/无障碍行为/玻璃档位/动效令牌/生成物溯源）？→ 是：**不能自行决定**，先改契约真源再同步副本，需 android-lead + tech-lead。② 是否要**改契约或规格文本**？→ 是：本仓只读外部文档，在 PR 描述登记 + `@ios-lead`。③ 是否在**未验证清单**里（本文件 §8.1）？→ 是：按"未验证"记录并找责任人回填，**不得写成已通过**。

| 卡在哪 | 找谁 | 期望产出 |
| --- | --- | --- |
| 本仓实现细节、签名、批次开工/结批 | `ios-lead` | 裁决或改判记录 |
| 契约 / F 注册表 / U3 词表 / 生成器 / token manifest | 架构师 | 真源修订 + 生成物更新 |
| 令牌取值 / 图标语义名 / 设计待给值（§7） | 设计 | 给值或"采用默认执行项"的确认 |
| 出口验收 / 门槛值 / 发布 checklist | `tech-lead` | 出口判定 |
| 外部角色点名、跨端冲突无法收敛 | 船长 | 拍板 |

**两条硬纪律**：① 未决项必须带**默认执行项 + 责任人 + 时点**（"清单不缩表"）；② 阻塞超过一个批次的，写进本文件 §8.2 的风险表，不要口头挂着。

---

## 17. 术语表

**本仓与跨端术语**（同一件事的两种叫法；两端差异术语已标注）

| 术语 | 含义 | 出处 |
| --- | --- | --- |
| **U 系列** | 必须两端统一的项（名字/取值/可观测行为） | `AGENTS.md` §2 的代号约定 |
| **F 系列** | 各端自由的项（由平台 API 形状决定），但必须在契约登记两端形态 | 同上 |
| **C-15** | 受控值参数名唯一表（37 行）；本仓已内联 **§5.3** | §5.3 |
| **批前签名冻结** | 每批第 0 步：该批组件签名 + 契约条目入库后才允许开工 | §14.8；`AGENTS.md` §3.1（I-2） |
| **批出口** | 该批判据全绿 + nightly 连续 3 日绿 | §15 |
| **门禁三层** | PR（每次提交）→ nightly（每批，连续 3 日）→ 发布前（真机/归档/tag） | §4.5 |
| **可见内容 / 布局盒** | U = 两端可见内容高度 **44 ± 0.5**；F = 行距 **Android 布局盒 48**（44 + 上下各 2dp）**/ iOS 44**（= F51） | §5.1（第 1–2 行） |
| **glass / glassStrong**（本端） | `WDGlassResolution` 的两个玻璃输出档；`opaque` 为降级档 | §5.2 |
| **关键路径件** | 该批内**串行在前、下游批依赖其冻结**的件（**与层级 primitives/composites 无关**）；§3 表里历史上写作组件名后的 `(C)`。**A/B/C 工作量档位已废止**（用户决策 #1：不算人力） | §3；§13.1 |
| **快照渲染器**（本端差异） | 普通类 `ImageRenderer`；**玻璃类 6 个** `UIHostingController`+`drawHierarchy` | §13.1 脚注；`docs/SPEC.md` §1.6 |
| **μ（弹簧）** | 刚度折算系数：**μ = 1.0**；`response`+`dampingRatio` 为真源，禁 `massFactor` | §5.1（第 5 行） |
| **L-B** | 库内零资源 + 零文案（读屏标签由调用方传入） | §5.1（第 7 行） |
| **DF-xx / D2-xx / XR-xx** | 设计侧核对项（DF）/ 开发计划复审项（D2）/ 跨端复核项（XR）的**条目号**（不是文档代号） | §4.6 与 §22 |
| **已退役代号** | `02`=本仓 `docs/SPEC.md`；`30`=本文件；`40`=§5.3；`07`/`08`=跨端裁决与用户决策（结论已冻结在 §5/§6/§7）；`20`/`22`/`24`/`28`=iOS 组长评审链；`63`/`62`/`64`/`69`/`71`=仓内文档复核链；`12`=Android 规格 | 文首「来源与代号约定」 |
| **`(C)` / `（C）`（两端同形不同义 — 登记差异）** | **iOS 本仓**：`(C)` = **关键路径件**标记；**Android §3.2**：`（P）`/`（C）` = **层标记**（primitives / composites） | §3 图例；§13.1 |

**两端允许不同的术语对**（登记差异，不要"对齐"）：`WDBottomSheetDetent(s)`（iOS 联合类型）vs Android 档位集合；图标（iOS 按名取 SF Symbols）vs `ImageVector` 注入；`Components/Primitives` vs `components/…`（大小写）。

---

## 18. 关键决策摘要

> 每条给「**决策 + 来源**」；这里是**导航**，不是新口径 —— 与来源冲突时**以来源为准**。

| # | 决策（一句话） | 来源（章节） |
| --- | --- | --- |
| 1 | 单发布 product `WisdomUI`；`WisdomUIPreviews` 不进 products；`Internal/` 零 `public` | §5.1（第 9 行）；`AGENTS.md` F-10 |
| 2 | 行高**单值键** `size.row-height.{comfortable,compact}` = **60/44**（两端同值）；Android 的 48 是**布局盒**不是行高键 | §5.1（第 1–2 行）；`AGENTS.md` F-01–F-03 |
| 3 | **U = 可见内容 44 ± 0.5**；**F = 行距自由（Android 48 / iOS 44，= F51）**；iOS **不加**内边距 | §5.1（第 2 行）；§12.4（F51 行） |
| 4 | 语义色 **32 槽位**（含 `text.disabled`） | §5.1（第 3 行）；`AGENTS.md` F-04 |
| 5 | 主题 **`schemes` 维度**进 schema；运行时换**已生成**的 scheme、不重启、不进高频路径；**不支持**任意 `token.json`/服务端下发/**逐槽位任意覆盖** | §5.1（第 4 行）；`AGENTS.md` F-05 |
| 6 | 弹簧 canonical：`response` + `dampingRatio`（**μ = 1.0**，禁 `massFactor`） | §5.1（第 5 行）；`AGENTS.md` F-06 |
| 7 | 图标：契约只统一 **44 条语义名 + `mirrorsInRTL`**；iOS 按名取 SF Symbols；库内零图标资源 | §5.1（第 6 行）；`AGENTS.md` F-07 |
| 8 | 文案 **L-B**：库内零资源零文案；读屏标签由调用方传入 | §5.1（第 7 行）；`AGENTS.md` F-08 |
| 9 | 触控双键 **44 / 48**（每端只生成本端常量，不留过渡键） | §5.1（第 8 行）；`AGENTS.md` F-09 |
| 10 | 交互状态优先级 `disabled > loading > pressed > focused > hover > default` + 三条派生 | §5.1（第 11 行）；`AGENTS.md` F-12 |
| 11 | 行盒语义：`max(设计盒高×缩放, natural)`；禁 `Mode.Fixed`/`lineHeightMultiple` | §5.1（第 12 行）；`AGENTS.md` F-13 |
| 12 | 玻璃**六档**只作额外输入，输出语义仍是 `opaque/glass/glassStrong`；深色端文字规则 | §5.2；`AGENTS.md` §12.1（F47 为准） |
| 13 | **iOS 17–25 = 纯色降级**（不做模糊、不用系统 `Material`）；**待设计裁决（M0 D1）** | §5.2；§7（D-4） |
| 14 | 效果配额 **7 条硬上限**（模糊面 ≤1、wash 每屏 1、sheen ≤1、骨架 ≤6、e3 ≤1、动画环 ≤1、触觉 1 次） | §5.2；`AGENTS.md` §12.2 |
| 15 | 对比度门槛 **4.5:1 / 3:1** + **最不利取色**（玻璃取合成色）；禁用 40%；焦点环 3:1 | §5.2；`AGENTS.md` §12.3 |
| 16 | 门禁 = **`xcodebuild` + 模拟器**；`swift build`/`swift test` **不作门禁** | §4；`AGENTS.md` F-17 |
| 17 | 三层版本 + **SPM tag 只增不改**；发布顺序：设计仓 tag → 生成 → 两端提交 → 跑绿 → 发布前层 → 双端同 tag | §10；`AGENTS.md` F-18 |
| 18 | 设计待给值一律**先按默认执行项冻结**（清单不缩表），不自行定值 | §7；`AGENTS.md` §6.1 |
| 19 | 文档类改动必须过 §4.6 的**六个固定项** + 两条纪律（禁止自命中 / 双跑） | §4.6 |
| 20 | 未跑通/未实测的项**只写"未验证"**，不得写成"已通过" | §8.1；`AGENTS.md` §7 |

---

---

## 19. 设计文档与设计图查阅指南

> **一句话**：本文件、`../AGENTS.md`、`docs/SPEC.md` 回答"**怎么实现、怎么验收**"；外部设计仓 `../wisdomdesign/` 回答"**长什么样、为什么这样**"。本节是设计仓的**地图**——什么时候去翻、翻哪一份、怎么翻。

### 19.1 设计仓结构与只读纪律

| 位置（相对本仓） | 是什么 | 能否改 |
| --- | --- | --- |
| `../wisdomdesign/docs/` | 规范文档 **13 份**（清单见 §19.2） | ❌ **只读** |
| `../wisdomdesign/docs/specs/` | **逐组件详细规格 4 份**（01–37 + 配方 R1–R5） | ❌ 只读 |
| `../wisdomdesign/design/gallery/` | 可视化画廊 **3 份**（自包含 HTML，浏览器直接打开） | ❌ 只读 |
| `../wisdomdesign/design/preview/` | 主题预览 **1 份** | ❌ 只读 |
| `../wisdomdesign/tokens/wisdom.tokens.json` | **令牌唯一真源**（色值只在这里出现一次） | ❌ 只读（经 M0-1 冻结流程） |

**只读纪律**：本仓任何角色**不得修改** `../wisdomdesign/**`。发现设计侧需要给值/改稿 ⇒ 走 §16.5 的升级路径登记，由设计与架构师裁决后按 P 项回写。

### 19.2 每份设计文档回答什么问题

| 文档 | 行数 | 回答什么问题 | 什么时候读 |
| --- | --- | --- | --- |
| `docs/01-foundation.md` | 409 | 设计原则、Liquid Glass 基调、色彩 / 字体 / 间距 / 形状 / 高度材质 / 图标 | **动手前必读**：§3 色彩、§4 字体、§5 间距、§6 圆角、§7 高度与材质 |
| `docs/02-components.md` | 112 | 组件总清单（A–F 分类）、优先级、**编号 → 画廊**对照 | 找"有哪些组件 / 先做哪个 / 画廊在哪" |
| `docs/03-platform-mapping.md` | 314 | 令牌 → SwiftUI / Compose 映射、命名对照、平台差异、**新增组件的工作流** | 查"这个令牌在本端用什么 API"、新增组件 |
| `docs/04-architecture.md` | 152 | 仓库划分、组件分层、命名规范、版本与兼容、分发、令牌流水线 | 结构性问题（分层 / 命名 / 分发） |
| `docs/05-preview-and-theme.md` | 88 | 预览形态、规格画廊、用例清单、主题 | 写 Previews、做主题换肤 |
| `docs/06-accessibility.md` | 285 | 无障碍四条底线、屏幕阅读器、动态字体、对比度、减弱动态效果、触觉 | **验收前必读**（每条都进断言） |
| `docs/07-content.md` | 239 | 文案：三条原则、句式、时间与日期、长度上限、禁忌词、中英混排 | 组件含文字时（**注意 L-B：库内零文案，文案由调用方给**） |
| `docs/08-icons.md` | 207 | 图标：来源、尺寸与线宽、颜色、**语义对照表**、新增流程、用法与禁止用法、验收清单 | 任何用图标的地方（44 条语义名） |
| `docs/09-layout.md` | 196 | 页面骨架、边距与栅格、纵向节奏、密度、多设备、键盘与安全区、滚动、列表长度 | 布局类组件（Card / ListRow / Sheet / NavigationBar / TabBar） |
| `docs/10-review-summary.md` | 368 | v1.0 评审总览与开工决策（历史留档） | 追溯"为什么这么定" |
| `docs/11-a2-dark-canvas.md` | 279 | 深色 canvas 目标色值（提案 + 深色字阶 × 底色对比度表） | 深色主题相关 |
| `docs/12-b22-glass.md` | 174 | **玻璃唯一真源与可用边界**、三处输入更正、降级口径 | **所有玻璃组件**（六档 × 文字可用矩阵） |
| `docs/13-tint.md` | 130 | 色调（tint）口径 | 语义色 / tint 相关 |
| `docs/specs/README.md` | 109 | **规格模板（12 节）**、编写规则、编号索引、配方 R1–R5 | **每接一个组件的第一份** |
| `docs/specs/01-basic.md` | 1941 | **01–20 详细规格**（每件按 12 节写，缺一节不算完成） | 做 01–20 任一件 |
| `docs/specs/02-advanced.md` | 1642 | **21–36 详细规格** | 做 21–36 任一件 |
| `docs/specs/03-patterns.md` | 492 | **37 AssigneePicker** + 配方 R1–R5（配方按"撞边界数据"验收） | 做 37、做场景配方 |
| `design/gallery/wisdom-components.html` | 约 156 KB | **01–20 可视化画廊**（自包含） | 看视觉基线 |
| `design/gallery/wisdom-advanced.html` | 约 136 KB | **21–36 可视化画廊** | 同上 |
| `design/gallery/wisdom-patterns.html` | 约 104 KB | **37 + R1–R5 场景画廊** | 同上 |
| `design/preview/wisdom-light.html` | 约 129 KB | 主题预览（浅色） | 主题 / 换肤观感 |

> **取数口径**：画廊/预览的体积随设计仓重新生成会漂移，表内为**约值**；取数命令 = `wc -c ../wisdomdesign/design/gallery/*.html ../wisdomdesign/design/preview/*.html`（本轮实测：components 155 KB / advanced 135 KB / patterns 103 KB / preview 128 KB，四舍五入后即表内约值）。

### 19.3 按任务查场景到章节

| 我要做的事 | 按顺序读 |
| --- | --- |
| **接一个新组件** | `../wisdomdesign/docs/specs/README.md`（12 节模板与编号）→ 本文件 **§20.2** 查它的设计编号 → `../wisdomdesign/docs/specs/0X-*.md` 该件的 12 节 → `01-foundation.md` §3–§7 → 该件涉及的无障碍 / 布局 / 图标 / 文案章节 → **画廊对应编号** |
| 改主题 / 换肤 | `05-preview-and-theme.md` §4 → `13-tint.md` → `01-foundation.md` §3 色彩 → `tokens/wisdom.tokens.json` |
| 玻璃相关 | `12-b22-glass.md` 全篇 → `06-accessibility.md` §5 对比度 → 本文件 §5.2 的玻璃硬规则 |
| 写无障碍断言 | `06-accessibility.md` §2–§8 → 该件规格第 **10 节** → 本文件 §15 的对应断言 |
| 布局 / 密度 | `09-layout.md` §2–§6 → 该件规格第 **3 / 6 节** |
| 图标 | `08-icons.md` §4 语义对照表 + §6 用法 / §7 禁止用法 |
| 文案 | `07-content.md` §2 / §4 / §6（**库内零文案**，文案由调用方注入） |
| 查令牌取值 | `tokens/wisdom.tokens.json`（唯一真源）→ `03-platform-mapping.md` 查本端 API |

### 19.4 检索命令复制即用

```bash
cd ../wisdomdesign

# 某个组件在哪些设计文档里出现
grep -rln 'ListRow' docs

# 某个令牌的定义与使用
grep -rn 'size.control.md' docs tokens/wisdom.tokens.json | head

# 某条无障碍底线在规范里的位置
grep -n '对比度\|动态字体\|焦点' docs/06-accessibility.md | head

# 取某件规格的某一节（例：18 ListRow 的验收清单）
awk '/^# 18 · ListRow/,/^# 19 · /' docs/specs/01-basic.md | grep -n '验收清单'

# 组件编号 → 规格锚点（GitHub slug：连续连字符不折叠）
#   01 → docs/specs/01-basic.md#01--button
#   21 → docs/specs/02-advanced.md#21--segmentedcontrol
#   37 → docs/specs/03-patterns.md#37--assigneepicker
```

### 19.5 设计文档与仓内文档的关系

- **效力分工**：设计稿 = **视觉与规范的依据**；`docs/SPEC.md` = **实现与验收的判据**；`../AGENTS.md` = **操作与禁止项**。三者冲突时 ⇒ **库行为以 SPEC 为准、视觉以设计稿为准**，并把冲突**登记为差异项（F 号）**，不自行取舍。
- **跨端必须一致项**（改动须走契约流程）：行高 **60 / 44 单值键**、布局盒 **48 = 44 可见内容 + 上下各 2dp**、**32 槽位**、`schemes` **三条硬边界**、弹簧 canonical **μ = 1.0**、图标 **44 条语义名 + `mirrorsInRTL`**、**L-B 零文案**。
- **只读原则的例外**：只有 **M0-1 令牌冻结窗口**（只开一次）与**经裁决的 P 项回写**可以触碰设计仓，且必须由登记 owner 执行。

---

## 20. 逐组件设计溯源表

### 20.1 怎么用三步

1. 在本文件 **§13.1** 找到该件（批次 / 关键路径件 / 落点 / `SPEC.md` 锚点 / 验收要点 / 依赖）；
2. 在**本表**找到它的**设计编号**，按「设计规格」列的锚点打开该件的 **12 节规格**；
3. 按「画廊」列的**文件名 + 检索词**在浏览器里打开画廊并搜索，与实现并排比对（核验方法见 §21.2/§21.3）。

### 20.2 溯源表 37 件

| WD 组件 | 设计编号 | 设计规格（锚点） | 画廊文件 · 检索词（实测命中） | 设计优先级 | 本端批次 |
| --- | --- | --- | --- | --- | --- |
| `WDButton` | 01 | `../wisdomdesign/docs/specs/01-basic.md#01--button` | `wisdom-components.html` · `Button`（6） | P0 | M2 |
| `WDIconButton` | 02 | `../wisdomdesign/docs/specs/01-basic.md#02--iconbutton` | `wisdom-components.html` · `IconButton`（3） | P0 | M2 |
| `WDTextField` | 03 | `../wisdomdesign/docs/specs/01-basic.md#03--textfield` | `wisdom-components.html` · `TextField`（3） | P0 | M2 |
| `WDSearchField` | 04 | `../wisdomdesign/docs/specs/01-basic.md#04--searchfield` | `wisdom-components.html` · `SearchField`（3） | P0 | M5 |
| `WDSwitch` | 05 | `../wisdomdesign/docs/specs/01-basic.md#05--switch` | `wisdom-components.html` · `Switch`（3） | P0 | M2 |
| `WDCheckbox` | 06 | `../wisdomdesign/docs/specs/01-basic.md#06--checkbox` | `wisdom-components.html` · `Checkbox`（3） | P0 | M2 |
| `WDRadio` | 07 | `../wisdomdesign/docs/specs/01-basic.md#07--radio` | `wisdom-components.html` · `Radio`（3） | P1 | M5 |
| `WDSlider` | 08 | `../wisdomdesign/docs/specs/01-basic.md#08--slider` | `wisdom-components.html` · `Slider`（3） | P0 | M5 |
| `WDStepper` | 09 | `../wisdomdesign/docs/specs/01-basic.md#09--stepper` | `wisdom-components.html` · `Stepper`（3） | P1 | M5 |
| `WDChip` | 10 | `../wisdomdesign/docs/specs/01-basic.md#10--chip` | `wisdom-components.html` · `Chip`（3） | P0 | M5 |
| `WDBadge` | 11 | `../wisdomdesign/docs/specs/01-basic.md#11--badge` | `wisdom-components.html` · `Badge`（3） | P0 | M2 |
| `WDAvatar` | 12 | `../wisdomdesign/docs/specs/01-basic.md#12--avatar` | `wisdom-components.html` · `Avatar`（5） | P0 | M2 |
| `WDAvatarStack` | 13 | `../wisdomdesign/docs/specs/01-basic.md#13--avatarstack` | `wisdom-components.html` · `AvatarStack`（2） | P0 | M5 |
| `WDDivider` | 14 | `../wisdomdesign/docs/specs/01-basic.md#14--divider` | `wisdom-components.html` · `Divider`（3） | P1 | M2 |
| `WDProgressBar` | 15 | `../wisdomdesign/docs/specs/01-basic.md#15--progressbar` | `wisdom-components.html` · `ProgressBar`（2） | P0 | M4 |
| `WDProgressRing` | 16 | `../wisdomdesign/docs/specs/01-basic.md#16--progressring` | `wisdom-components.html` · `ProgressRing`（2） | P0 | M4 |
| `WDCard` | 17 | `../wisdomdesign/docs/specs/01-basic.md#17--card` | `wisdom-components.html` · `Card`（3） | P0 | M2 |
| `WDListRow` | 18 | `../wisdomdesign/docs/specs/01-basic.md#18--listrow` | `wisdom-components.html` · `ListRow`（3） | P0 | M2 |
| `WDListSection` | 19 | `../wisdomdesign/docs/specs/01-basic.md#19--listsection` | `wisdom-components.html` · `ListSection`（3） | P0 | M3 |
| `WDIcon` | 20 | `../wisdomdesign/docs/specs/01-basic.md#20--icon` | `wisdom-components.html` · `Icon`（6） | P0 | M2 |
| `WDSegmentedControl` | 21 | `../wisdomdesign/docs/specs/02-advanced.md#21--segmentedcontrol` | `wisdom-advanced.html` · `SegmentedControl`（4） | P0 | M5 |
| `WDPicker` | 22 | `../wisdomdesign/docs/specs/02-advanced.md#22--picker` | `wisdom-advanced.html` · `Picker`（10） | P1 | M5 |
| `WDDatePicker` | 23 | `../wisdomdesign/docs/specs/02-advanced.md#23--datepicker` | `wisdom-advanced.html` · `DatePicker`（3） | P1 | M5 |
| `WDFormRow` | 24 | `../wisdomdesign/docs/specs/02-advanced.md#24--formrow` | `wisdom-advanced.html` · `FormRow`（3） | P1 | M5 |
| `WDAlert` | 25 | `../wisdomdesign/docs/specs/02-advanced.md#25--alert` | `wisdom-advanced.html` · `Alert`（6） | P0 | M4 |
| `WDBottomSheet` | 26 | `../wisdomdesign/docs/specs/02-advanced.md#26--bottomsheet` | `wisdom-advanced.html` · `BottomSheet`（3） | P0 | M4 |
| `WDActionSheet` | 27 | `../wisdomdesign/docs/specs/02-advanced.md#27--actionsheet` | `wisdom-advanced.html` · `ActionSheet`（3） | P1 | M4 |
| `WDToast` | 28 | `../wisdomdesign/docs/specs/02-advanced.md#28--toast` | `wisdom-advanced.html` · `Toast`（4） | P0 | M4 |
| `WDBanner` | 29 | `../wisdomdesign/docs/specs/02-advanced.md#29--banner` | `wisdom-advanced.html` · `Banner`（3） | P0 | M4 |
| `WDEmptyState` | 30 | `../wisdomdesign/docs/specs/02-advanced.md#30--emptystate` | `wisdom-advanced.html` · `EmptyState`（3） | P1 | M4 |
| `WDSkeleton` | 31 | `../wisdomdesign/docs/specs/02-advanced.md#31--skeleton` | `wisdom-advanced.html` · `Skeleton`（3） | P1 | M4 |
| `WDPullToRefresh` | 32 | `../wisdomdesign/docs/specs/02-advanced.md#32--pulltorefresh` | `wisdom-advanced.html` · `PullToRefresh`（3） | P1 | M5 |
| `WDNavigationBar` | 33 | `../wisdomdesign/docs/specs/02-advanced.md#33--navigationbar` | `wisdom-advanced.html` · `NavigationBar`（3） | P0 | M5 |
| `WDTabBar` | 34 | `../wisdomdesign/docs/specs/02-advanced.md#34--tabbar` | `wisdom-advanced.html` · `TabBar`（4） | P0 | M5 |
| `WDToolbar` | 35 | `../wisdomdesign/docs/specs/02-advanced.md#35--toolbar` | `wisdom-advanced.html` · `Toolbar`（4） | P1 | M5 |
| `WDFAB` | 36 | `../wisdomdesign/docs/specs/02-advanced.md#36--fab` | `wisdom-advanced.html` · `FAB`（3） | P1 | M5 |
| `WDAssigneePicker` | 37 | `../wisdomdesign/docs/specs/03-patterns.md#37--assigneepicker` | `wisdom-patterns.html` · `AssigneePicker`（2） | P1 | M6 |

**合计 37 行**（与 §13.1 的 37 件一致）；设计编号 01–37 **无缺号**。

### 20.3 关于实测命中数与锚点

- 画廊是**自包含 HTML（无构建步骤）**，且**没有逐组件锚点** ⇒ 定位方式是**浏览器内搜索组件名**（⌘F / Ctrl+F）。
- 「命中数」是**本次实测值**（对画廊文件做 `grep -c`），用途是**确认搜到的是不是同一处**：命中 **0** 说明该组件在这张画廊里没有独立展示（例如 `WDDivider` 多作为其他组件的分隔出现），此时**以规格文件为准**，必要时在批出口报告里登记"画廊未独立展示"。
- 组件在设计侧的**编号**是稳定标识（`../wisdomdesign/docs/specs/` 的锚点与之一一对应）；**画廊内的滚动位置不稳定**，不要引用"第 N 屏"。

---

### 20.4 视觉规格速查

> **用途**：开工前 30 秒建立「这颗组件大概多大、有几种形态、有哪些状态、主要吃哪些令牌」的印象，然后**以设计规格原文为准**读细节。**本表是速查、不是判据**；任何数值冲突以 `../wisdomdesign/docs/specs/0X-*.md` 原文为准。**逐件溯源（设计编号 / 规格锚点 / 画廊检索词）见 §20.2。**

> **截断说明**：单元格若以 `…` 结尾，该格第二行（`<br>` 之后）即**完整值**。**尺寸列一律照抄规格的值单元格**（不截取其中的某个数字），例如 Picker 的「弹出层最小宽 **180**，最大宽 = 屏幕宽 − 32」两项都在。

> **导出的抽取口径（本轮修正）**：尺寸列 = 规格第 3 节表格的「项/档 + 值」**原文**。此前版本曾把值单元格里的**最后一个数字**当作尺寸（导致 Picker 显示 32、BottomSheet 把手显示 8、Toolbar 图标按钮显示 20）——那是抽取缺陷，已修。

**M2 首批 11 件（已到「批前签名冻结」）**

| 编号 | 组件 | 尺寸要点 | 变体 | 状态 | 关键令牌 |
| --- | --- | --- | --- | --- | --- |
| 1 | `Button` | sm size.control.sm 32 · md（默认） size.control.md 44 · lg size.control.lg 52 | filled / tonal / glass / outline / plain | 默认 / 按下 / 聚焦 / 禁用 / 加载 | size.icon.sm · space.3 · type.headline · size.control.sm |
| 2 | `IconButton` | sm 32×32 · md（默认） 44×44 | filled / tonal / glass / outline / plain | 与 Button 一致：默认 / 按下（缩放 0.97）/ 聚焦（3pt 光环）/ 禁用（40%）。 | radius.full · radius.sm · size.icon.lg · space.3 |
| 3 | `TextField` | 高度 **46**（固定，所有变体一致） · 圆角 radius.md 14 · 水平内距 12 · 前缀与输入区间距 space.3 8 · 后缀与输入区间距 space.3 8 · 标签与容器间距 space.2 4 | inset（默认） / outline / glass | 默认 / 聚焦 / 错误 / 禁用 / 只读 | type.footnote · type.body · radius.md · space.3 |
| 5 | `Switch` | 标准 51×31 · 紧凑 40×24 | 标准 / 带描述 | 关 / 开 / 按下 / 禁用 | radius.full · type.footnote · space.5 · size.touch-target-min |
| 6 | `Checkbox` | 标准 size.checkbox 26 · 紧凑 22 | 标准 / 无标签 / 任务行 | 未选 / 已选 / 半选 / 按下 / 禁用 | radius.checkbox · size.checkbox · type.subheadline · type.footnote |
| 11 | `Badge` | 状态胶囊 高 24，水平内距 10 · 圆点 7×7 · 计数 高 20，最小宽 20 | shared / schedule / pending / success / warning | 徽标本身是展示元素，没有按下态。计数为 0 时整体隐藏，不留空位。 | radius.full · space.2 |
| 12 | `Avatar` | xs size.avatar.xs 20 · sm 28 · md 32 · lg 40 · xl 56 | 文字 / 图标 / 照片 / 在线 | 在线 / 离线 / 已停用成员 | size.avatar.xs · space.4 · space.5 |
| 14 | `Divider` | 全宽 容器左边缘 · 内缩 文本区起始（16 + 34 + 12 = 62） | 全宽 / 内缩两种。列表行之间用内缩，卡片内部整体分区用全宽。 | 无状态。颜色固定 `border.hairline`，不随选中或按下变化。 | space.4 |
| 17 | `Card` | 内边距 space.5 **16（固定，所有变体一致）** · 圆角 radius.xl 24 · 卡间距 space.4 12 · 分组间距 space.7 24 · 最小宽度 不设，由父级决定 | elevated（默认） / glass / outline / sunken / media | 静态 / 可点 · 按下 / 可点 · 禁用 | space.5 · radius.xl · space.4 · space.7 |
| 18 | `ListRow` | 单行 44 · 双行 60 · 三行 76 | 单行 / 双行 / 三行 / 带选择 / 带勾选 / 禁用 | 默认 / 按下 / 选中 / 禁用 | radius.sm · type.subheadline · type.caption1 · space.4 |
| 20 | `Icon` | sm 16 · md 20 · lg 24 · xl 28 | 同一语义在两端各有一套：iOS 用 SF Symbols（优先 `.rounded` 变体），Android 用 Mat…<br>完整值：同一语义在两端各有一套：iOS 用 SF Symbols（优先 `.rounded` 变体），Android 用 Material Symbols Rounded。 | 图标本身没有状态，状态由容器承担（按钮的按下/禁用、Tab 的选中）。 | radius.sm · radius.lg · space.3 · motion.duration.fast |

**M3 封板批 1 件（公开 API 冻结）**

| 编号 | 组件 | 尺寸要点 | 变体 | 状态 | 关键令牌 |
| --- | --- | --- | --- | --- | --- |
| 19 | `ListSection` | 标题与内容间距 space.3（8） · 内容与页脚间距 space.2（4） · 分组与分组之间 space.7（24） · 页面左右边距 space.5（16） | 标准 / 带动作 / 带页脚 | 分组本身无状态。空分组整个隐藏（连标题一起），不要显示空标题。 | type.overline · type.footnote · space.3 · space.2 |

**M4 反馈与弹层 9 件**

| 编号 | 组件 | 尺寸要点 | 变体 | 状态 | 关键令牌 |
| --- | --- | --- | --- | --- | --- |
| 15 | `ProgressBar` | 高度 6 · 圆角 radius.full · 最小宽度 100 · 分段模式的段间距 2 | 确定 / 分段 / 不确定 / 完成 | 进行中 / 完成 / 不确定 / 禁用 | radius.full · space.4 · space.3 · motion.component.progress-easeout |
| 16 | `ProgressRing` | 直径 60（标准）/ 44（紧凑） · 线宽 6（标准）/ 5（紧凑） · 起点 12 点方向，顺时针 · 环内留白 直径 − 2 × 线宽 | 百分比 / 计数 / 完成 | 增长 / 完成 / 停滞 | type.title2 · space.5 · motion.component.progress-easeout · motion.spring.bouncy |
| 25 | `Alert` | 卡片宽 270（固定，不随内容变化） · 卡片圆角 radius.xl 24 · 标题区上下内距 16 / 6 · 正文区左右内距 16，下内距 14 · 按钮高 44 · 按钮字号 16（破坏性按钮用 status.danger） | 双按钮 / 单按钮 / 危险 / 带输入 | 出现 / 按钮按下 / 长文案 | radius.xl · type.headline · type.footnote · space.8 |
| 26 | `BottomSheet` | 圆角 顶部两角 radius.xxl 32 · 把手 36×5，距顶 8 · 头部高 56 · 内容左右内距 space.5（16） · 底部操作区高 72（含安全区） · detents 半屏 0.5 / 大 0.92 | 半屏 / 大 / 可拉伸 / 不可关闭 | 出现 / 拖拽中 / 松手 / 关闭 | radius.xxl · radius.full · type.title3 · space.5 |
| 27 | `ActionSheet` | 操作行高 44 · 行水平内距 16 · 列表圆角 radius.lg 18 · 取消胶囊高 48 · 与安全区间距 space.3（8） · 操作列表与取消的间距 space.3（8） | 标准 / 含破坏性 / 带图标 | 出现 / 按下 / 破坏性 / 关闭 | radius.lg · space.3 · motion.spring.gentle · space.5 |
| 28 | `Toast` | 高度 46（单行）；多行时自适应，最多 2 行 · 最小宽度 120 · 最大宽度 屏幕宽 − 2 × space.6（40） · 水平内距 18 · 圆角 radius.full · 图标 16 | 成功 / 信息 / 失败 / 带操作 | 出现 / 停留（纯提示） / 停留（带操作） / 消失 / 手指悬停 | space.5 · space.6 · radius.full · space.4 |
| 29 | `Banner` | 最小高 44（单行） · 内边距 12 · 圆角 radius.lg 18 · 图标与文案间距 space.3（8） · 文案与操作间距 space.3（8） | 成功 / 信息 / 警示 / 错误 | 常驻 / 可关闭 / 出现 | type.footnote · radius.lg · space.3 · space.5 |
| 30 | `EmptyState` | 底座 56×56 · 底座与标题间距 space.4（12） · 标题与说明间距 space.2（4） · 说明与操作间距 space.5（16） · 文本最大宽 32 个汉字宽（约 240） | 首次空 / 搜索无结果 / 权限受限 / 加载失败 | 空状态本身无状态。加载失败的变体可以重复触发"重试"，重试期间按钮进入加载态。 | type.headline · type.subheadline · space.4 · space.2 |
| 31 | `Skeleton` | 文本行 高 11，圆角 6，宽度按真实文本比例（70% / 45%） · 列表行 与 WDListRow 等高（44 / 60 / 76） · 卡片 与真实卡片同尺寸、同圆角、同内边距 · 头像 圆形，直径同真实头像 | 文本 / 列表 / 卡片 | 只有一种状态（加载中）。加载完成后骨架整块替换为真实内容，不做逐块替换。 | motion.component.skeleton-shimmer |

**M5 导航与表单 15 件**

| 编号 | 组件 | 尺寸要点 | 变体 | 状态 | 关键令牌 |
| --- | --- | --- | --- | --- | --- |
| 4 | `SearchField` | 高度 **46**（与 WDTextField 一致，同一页面里两者高度必须相同） · 圆角 radius.full · 水平内距 12 · 前导图标与输入区间距 space.3 8 · 容器与取消按钮间距 space.4 12 | 标准 / 带取消 | 空态（未聚焦） / 聚焦 / 有值 / 无结果 / 禁用 | size.icon.md · type.body · radius.full · space.3 |
| 7 | `Radio` | 标准 26 · 紧凑 22 | 标准 / 带描述 | 未选 / 已选 / 按下 / 禁用 | type.subheadline · type.footnote · space.3 · space.4 |
| 8 | `Slider` | 轨道高 6 · 手柄 26（白色 + elevation.1 + 1pt border.hairline 描边） · 圆角 radius.full · 最小宽度 120 · 手柄与轨道端点的内缩 手柄半径 13，轨道两端各留 13 | 单值 / 带刻度 / 范围 | 默认 / 拖拽 / 聚焦 / 禁用 | radius.full · space.4 |
| 9 | `Stepper` | 标准 36 · 紧凑 30 | 标准 / 紧凑 / 带单位 | 默认 / 按下 / 到下限 / 到上限 / 整体禁用 | radius.full · motion.duration.instant · space.4 |
| 10 | `Chip` | 标准 32 · 紧凑 28 | 展示 / 可选 · 未选 / 可选 · 已选 / 可删除 / 带图标 | 默认 / 按下 / 选中 / 禁用 | radius.full · space.3 · space.4 |
| 13 | `AvatarStack` | 头像档位 sm 28 或 md 32 · 重叠量 直径的 30%（28 → 8，32 → 9） · 描边 2pt，颜色取所在容器底色（卡片或画布） · 最大显示数 4 | 标准 / 无溢出 | 堆叠本身无状态。成员变动时（新增/离开）用 240ms 淡入淡出，不重排已有位置。 | space.3 · motion.component.list-stagger · motion.spring.gentle |
| 21 | `SegmentedControl` | 容器高 38（内容 32 + 上下内边距 3） · 单段最小宽 56 · 段水平内距 14 · 字号 13 · 500（选中 600） · 圆角 radius.full | 玻璃 / 实底 | 未选 / 选中 / 按下 / 禁用 | radius.full · motion.spring.snappy · space.5 · motion.duration.fast |
| 22 | `Picker` | 触发入口高 44 · 选项行高 44 · 弹出层最小宽 180，最大宽 = 屏幕宽 − 32 · 圆角 radius.md 14 · 选项水平内距 14 | 菜单 / 滚轮 / 内联 | 默认 / 未选 / 展开 / 已选 / 禁用 | radius.md · motion.spring.gentle · space.2 · type.overline |
| 23 | `DatePicker` | 触发入口高 44 · 快捷 Chip 高 32 · 日历单元 44×44 · 圆角 触发入口 radius.md，弹出层 radius.xl | 日期 / 时间 / 日期 + 时间 / 范围 | 未选 / 已选 / 今天 / 选中 / 已过期 | radius.md · radius.xl · motion.duration.fast · motion.spring.gentle |
| 24 | `FormRow` | 行最小高 44 · 标签与控件间距 space.4（12） · 行与行之间 space.5（16） · 说明 / 错误文字与控件间距 space.2（4） · 标签列宽（左右排布） 96，超出时标签换到上方排布 | 左右 / 上下 / 分组 | 默认 / 聚焦 / 错误 / 禁用 | type.subheadline · type.footnote · space.4 · space.5 |
| 32 | `PullToRefresh` | 触发阈值 64（下拉超过此距离松手才刷新） · 指示器直径 24 · 环线宽 2 · 指示器与首行间距 space.4（12） · 最大下拉距离 120（超过后阻力显著增加） | 品牌进度 / 极简 | 空闲 / 下拉中 / 刷新中 / 完成 | space.4 · motion.spring.snappy |
| 33 | `NavigationBar` | 内联（紧凑） 44 · 标准 56 · 大标题 96 | 透明 / 玻璃 / 大标题 | 未滚动 / 已滚动 / 大标题收缩 / 返回按下 | type.headline · space.3 · space.5 · motion.spring.gentle |
| 34 | `TabBar` | 高度 58 · 距左右边缘 space.5（16） · 距底部安全区 space.3（8） · 图标 22 · 标签 10 · 500（选中 600） · 圆角 radius.full | iOS 悬浮胶囊 / Android 全宽 | 未选 / 选中 / 按下 / 带角标 | space.5 · space.3 · radius.full · motion.spring.gentle |
| 35 | `Toolbar` | 容器高 48 · 图标按钮 36×36，图标 20 · 按钮间距 space.2（4） · 容器内边距 6 · 圆角 radius.full · 分割线 1pt × 24，色 border.hairline | 顶部 / 底部 / 键盘上方 | 默认 / 按钮按下 / 按钮选中 / 按钮禁用 | space.2 · radius.full · space.4 |
| 36 | `FAB` | 标准 56×56 · 大 64×64 · 小 40×40 | 圆角方（默认） / 圆形 / 可展开 | 默认 / 按下 / 滚动 / 展开 / 禁用 | radius.fab · motion.spring.gentle · space.5 · space.3 |

**M6 场景组件 1 件**

| 编号 | 组件 | 尺寸要点 | 变体 | 状态 | 关键令牌 |
| --- | --- | --- | --- | --- | --- |
| 37 | `AssigneePicker` | 头像 40 · 头像间距 space.4（12） · 选中外环 2pt 描边 + 4 间隙（外径 52） · 名字与头像间距 space.2（4） · 横向内边距 space.5（16） · 最多直接显示 6 个（含"未指派"） | 单选（默认） / 多选 / 带未指派 / 紧凑 | 未选 / 选中 / 按下 / 禁用成员（已离开家庭） / 整体禁用 | type.caption1 · space.4 · space.2 · space.5 |

**对比度速查**（设计规格里**明确给了数值**的件；其余按全局门槛 4.5:1 文字 / 3:1 图形与控件边界）

| 编号 | 组件 | 规格中给出的对比度值 |
| --- | --- | --- |
| 1 | `Button` | `6.9:1` / `4.5:1` / `3:1` / `5.4:1` |
| 2 | `IconButton` | `3:1` |
| 3 | `TextField` | `3:1` |
| 11 | `Badge` | `4.5:1` |
| 15 | `ProgressBar` | `3:1` |
| 16 | `ProgressRing` | `3:1` / `4.5:1` |
| 17 | `Card` | `4.5:1` / `3:1` |
| 19 | `ListSection` | `4.5:1` |
| 20 | `Icon` | `3:1` |
| 28 | `Toast` | `4.5:1` |
| 30 | `EmptyState` | `4.5:1` |
| 31 | `Skeleton` | `1.5:1` |

**共 12 件**在规格里给了具体对比度值；未列出的件**不等于没有要求**——一律适用全局门槛。

**读法**：① 每个值都**引令牌**，代码里不得硬编码；② 状态表同时规定**动效与触觉**（规格第 5 节第 3、4 列）；③ **触控热区不小于本端冻结值**（`size.touch-target-min-ios` = 44 / `size.touch-target-min-android` = **48 布局盒** = 44 可见内容 + 上下各 2dp；设计规格写「≥44」指的是**可见内容**）；④ 变体/状态写成散文时（无表格），**必须回规格看全**。


## 21. 从设计规格到实现与验收

> 设计规格每件都按 **12 节**写（`../wisdomdesign/docs/specs/README.md` 的模板，缺一节不算完成）。本节把它**逐节映射**到本端要产出什么、对应哪类断言，避免"读完了规格但不知道该写什么"。

### 21.1 设计规格 12 节到本端产出

| 设计规格第 N 节 | 它规定什么 | 本端落到哪里 | 对应断言 / 验收 |
| --- | --- | --- | --- |
| 1 用途 | 何时用 / 不用、替代方案 | 组件文档注释 + 评审项 | 评审：是否用错组件 |
| 2 解剖 | 由哪几段组成、每段用什么令牌 | 子视图与槽位结构（`Sources/WisdomUI/Components/{Primitives,Composites}/<组件>/`） | API 形状断言（签名冒烟） |
| 3 尺寸 | 各档高度 / 内距 / 字号 / 图标 / 圆角 | 常量**引令牌**（禁硬编码数值） | 行盒与尺寸断言 + 六态快照 |
| 4 变体 | 每个变体的背景 / 文字 / 描边 / 阴影 → 令牌 | 枚举 + 样式分支 | 变体矩阵快照 |
| 5 状态 | 默认 / 按下 / 聚焦 / 禁用 / 加载 / 选中 / 错误 的视觉·动效·触觉 | 状态机 + **状态优先级** | 状态优先级断言 + 六态快照 |
| 6 布局 | 与相邻元素关系、是否全宽、最大宽度、换行 | 容器视图与布局修饰 | 布局快照（含最大宽度） |
| 7 内容 | 字数上限、截断方式、空值、数字与单位格式 | **文案由调用方注入**（库内零文案 L-B） | L-B 检查 + 截断 / 空值用例 |
| 8 交互 | 点击 / 长按 / 滑动 / 拖拽 / 键盘 | 手势与动作回调 | 交互用例 + 无障碍动作 |
| 9 动效 | 时长与曲线（引 `motion.*` 令牌） | 动效常量 + **reduced 降级** | reduced 断言 |
| 10 无障碍 | 朗读文本、角色、触控热区、动态字体、对比度 | 语义修饰 + 热区 | 语义树 / 朗读 / 热区 / 对比度断言 |
| 11 平台差异 | iOS 与 Android 各自怎么做 | 本端实现分支 | 差异登记（F 号，见 §17 术语表） |
| 12 验收清单 | 可勾选的检查项 | 转成本端断言 + §15 的验收命令 | 逐条勾选，进批出口报告 |

### 21.2 画廊核验六步

1. **打开**：浏览器打开对应画廊 HTML（文件自包含，无需构建、无需服务器）；
2. **定位**：按 §20.2 的检索词搜索该组件（命中数用于确认位置）；
3. **逐项比对**：形态 → 尺寸 → 变体 → 状态，与实现并排；
4. **六态截图**：默认 / 按下 / 聚焦 / 禁用 / 加载 / 选中，逐一比对并存档（见 §21.4）；
5. **差异分流**：**实现错** ⇒ 改实现；**设计未覆盖 / 与 SPEC 冲突** ⇒ 登记差异项（F 号），**不自行取舍**；
6. **留痕**：核验结论写进批出口报告（§15 的出口报告结构）。

### 21.3 画廊能核什么不能核什么

| ✅ 能核（视觉基线） | ❌ 不能核（归入 §8.1 未验证清单） |
| --- | --- |
| 形态、密度、层级、玻璃档位、圆角、间距、字阶 | 真实动效时长与曲线 |
| 变体与状态的**静态**表现 | 真机字体与行盒（模拟器字面量驱动） |
| 明暗两套主题的观感 | 朗读文本、焦点顺序、触觉反馈 |
| 图标用法与底色搭配 | 动态字体放大后的布局（2.0 档 / AX3） |

### 21.4 截图存档批出口硬要求

每个组件在批出口前提供 **六态 × {light, dark}** 截图，落在 `Tests/__Snapshots__/`，命名 `<组件>-<态>-<主题>.png`；**与画廊的比对结论**一并写进批出口报告。截图是"视觉是否对齐设计稿"的唯一可复核证据——**没有截图的批不算出口**。

---

### 21.5 M2 十一件「实现前自检十问」

> **用途**：开工前 10 分钟过一遍。每问都能用「是 / 否」回答；**答不出或答「否」就先回设计规格，不要开写**。
> **数据源** = `../wisdomdesign/docs/specs/01-basic.md` 对应件的第 3 / 5 / 7 / 8 / 10 节（含**内容约束** §7）（本清单是**索引**，不替代规格）。件的落点与验收要点见 §13.1，设计锚点与画廊检索词见 §20.2。

**01 `WDButton`（设计 01）**

1. 高度档是否 `sm 32 / md 44 / lg 52`，且分别引 `size.control.{sm,md,lg}`——**没有硬编码数值**？
2. 水平内距 / 字号 / 图标是否按 `12 / 16 / 20` · `13 / 15 / 16` · `14 / 16 / 20` 落实？
3. 六个变体 `filled / tonal / glass / outline / plain / destructive` 是否齐；「`filled` **每屏最多一个**主操作」有没有写进类型/组件文档注释？
4. 按下态是否 = 缩放 **0.97**（`motion.component.press-scale`）+ 亮度 **96%** + `motion.duration.instant`（100ms）+ **轻触觉**？
5. 聚焦光环是否 **外扩 3pt**、`text.brand` **32%** 透明？
6. 禁用态是否 **40% 不透明度** + **`aria-disabled` 语义**（不移除元素，保证读屏仍能发现它）？
7. 加载态是否 **容器宽度不变**、指示器替换标签但 **保留原标签供读屏**，且朗读为「提交，处理中」而非「加载中」？
8. 文案约束是否交给调用方（库内零文案）：标签 **2–6 汉字 / ≤12 字符**、动词开头、删除场景直接写「删除」？
9. 无障碍：**标签即朗读文本**（不额外加标签）、角色为 button、图标为装饰？
10. 触控热区是否 ≥ **44×44**（`size.touch-target-min`）——**只有图标的场合尤其要查**？

**02 `WDIconButton`（设计 02）**

1. 两档是否为 `sm 32×32 / md 44×44`，且**热区恒 44×44**（视觉尺寸可以小于热区）？
2. 图标档是否按 `sm/md 16–20`、`md 24`（`size.icon.*`）取；圆角 `radius.full` 或 `radius.sm` 二选一与本端形态一致？
3. 五个变体 `filled / tonal / glass / outline / plain` 是否齐？
4. **是否确认「没有加载态」**——加载场景必须换成 `WDButton` 或骨架，而不是给图标按钮加转圈？
5. 无障碍标签是否**写动作而不是图标名**（写「搜索」不写「放大镜」）？没有标签时读屏只会读「按钮」。
6. 破坏性动作是否**没有**放进 IconButton？（没有文字说明的删除按钮是事故源头）
7. 点击是否**立即执行、不做二次确认**？
8. 图标是否标记为装饰、角色为 button？
9. 热区是否 ≥ 44×44（两档都要满足，`sm` 视觉 32 但热区仍 44）？
10. 是否已确认该件的**验收截图**要覆盖「聚焦光环 + 禁用 40%」两态？

**03 `WDTextField`（设计 03）**

1. 高度是否 **固定 46**（**所有变体一致**），没有为某个变体改高？
2. 圆角 `radius.md` **14**、水平内距 **12**、前后缀与输入区间距 `space.3` **8**、标签与辅助文案间距 `space.2` **4**、最小宽度 **190** 是否都对？
3. 三个变体 `inset`（默认）/ `outline` / `glass` 是否齐？
4. 五个状态 `默认 / 聚焦 / 错误 / 禁用 / 只读` 是否齐，且聚焦 = 描边换 `text.brand` **1.5pt** + **18% 光环** + **160ms**？
5. 错误态是否描边换 `status.danger`，且**辅助文案**也用 `status.danger`？
6. **标签是否必填**（不允许只用占位符当标签）？占位符是否写示例而不是重复标签？
7. 读屏是否**先读标签再读内容**；错误态是否读成「任务名称，错误，名称已被占用」这种**完整句**？
8. 后缀按钮（清除 / 显示密码 / 选择单位）是否**各自有标签**？
9. 与 `WDSearchField` 同页时，两者高度是否一致（同 46）？
10. 触控与焦点热区是否 ≥ 44（含后缀按钮）？

**05 `WDSwitch`（设计 05）**

1. 标准档是否 **51×31**、圆角 `radius.full`、滑块 **27**（轨道高 − 4）、行程 **20**；紧凑档 **40×24 / 20 / 16**？
2. 关闭态轨道是否 `border.hairline-strong` + 白色滑块；开启态是否 `gradient.mid` + 白色滑块？
3. 开启动效是否是**轨道 260ms、滑块 300ms** 两条不同时长，且带**轻触觉**？
4. 按下态是否**滑块临时放大到 1.06**（100ms）？
5. 无障碍角色是否 `switch`、状态读「开 / 关」，整句读成「共享给家人，开，开关」？
6. 带描述时，**描述是否并入朗读内容**（而不是只在视觉上显示）？
7. 标签是否 4–10 汉字、动词或名词短语、**不用疑问句**？
8. 描述是否 ≤ **18 汉字**，超出时换**两行说明文字**而**不是截断**？
9. 触控热区是否 ≥ 44×44（轨道 31 高，热区必须撑到 44）？
10. 状态切换是否**不触发**额外的确认或副作用（开关只表达状态，不做动作）？

**06 `WDCheckbox`（设计 06）**

1. 标准档是否 `size.checkbox` **26** / 圆角 **9** / 标签 `type.subheadline` **15**；紧凑 **22 / 7 / 13**？
2. 未选态是否描边 `border.hairline-strong` **1.5pt** + 底 `fill.field`？
3. 已选态是否渐变底 + **顶部 1pt 内高光** + `elevation.brand` 投影，且**勾 260ms、填充与投影 220ms**、轻触觉？
4. **半选态是否实现**（同已选底，勾换成 **12×2.4** 白色横杠）？
5. 三态朗读是否为「已选中 / 未选中 / **部分选中**」？
6. 任务行场景是否读成「整理储物间，未完成，复选框」这种**整句**？
7. 勾选完成时是否**既有触觉又用 `aria-live` 播报「已完成」**？
8. 标签是否 2–12 汉字、名词短语或短句、**不用问句**（写「共享给家人」不写「是否共享？」）？
9. iOS 参数名是否为 **`isChecked`**（C-15 的改名结论：`isOn` → `isChecked`）？Android 侧对应受控值名为 **`checked`**？
10. 热区是否 ≥ 44（方框 26 或 22，热区必须撑满）？

**11 `WDBadge`（设计 11）**

1. 三种形态是否齐：状态胶囊（高 **24** / 水平内距 **10** / 字号 **11 · 600**）、圆点（**7×7**）、计数（高 **20** / 最小宽 **20** / **等宽数字**）？
2. 圆角是否一律 `radius.full`？
3. 是否确认**徽标不可点**（宿主可点时点击宿主触发宿主动作，不单独触发徽标）？
4. **徽标是否不进入无障碍焦点序列**，而是作为宿主朗读内容的一部分（读「提醒，3 条未读」而不是拆成两个元素）？
5. 状态胶囊文字是否 ≤ **4 汉字**、名词短语（「已逾期」而不是一句话）？
6. 徽标文字是否**不换行、不截断**（放不下说明这一处置放的信息过多）？
7. **颜色是否不是唯一信号**——每种状态胶囊的**图标形状必须不同**（对勾 / 三角 / 实心禁止）？
8. 计数为 **0** 时是否整体隐藏、**不留空位**？
9. 字号是否为固定值（**不随动态字体放大**——需在规格/断言里明确，属"例外项"）？
10. 与宿主同屏时，徽标是否不改变宿主的布局尺寸（浮层或预留位，按规格第 6 节）？

**12 `WDAvatar`（设计 12）**

1. 五档直径是否 `xs 20 / sm 28 / md 32（默认）/ lg 40 / xl 56`，首字号 `9 / 11 / 12 / 14 / 18`？
2. **同一个人的底色是否按成员 ID 固定**（不是按出现顺序分配）——换页面后颜色是否仍然一致？
3. 在线态是否用 `status.success` 状态点；**离线态是否不加灰点**（避免与在线点混淆）？
4. 已停用成员是否整体 **50% + 去饱和**？
5. 朗读是否为成员名（「妈妈」）而**不读**「头像」或首字？
6. 在线状态是否**并入朗读**（「妈妈，在线」）？
7. 首字 / 图标是否标记为装饰？
8. 首字规则是否按规格：中文取名字第一个字符、英文取首字母大写？
9. 与 `WDAvatarStack` 的档位（32 / 重叠 30% / 描边 2pt / 最多 4）是否分工清晰、没有各自实现一套？
10. 头像加载失败/无图时是否有确定的兜底（首字），**不留空白**？

**14 `WDDivider`（设计 14）**

1. 两个变体是否齐：全宽（容器左边缘到右边缘）、内缩（**文本区起始 = 16 + 34 + 12 = 62**）？
2. 颜色是否固定 `border.hairline`、**不随选中/按下变化**？
3. 是否确认**无状态、不可交互**（不实现按下态、不做 hover）？
4. **是否不进入无障碍树**（分割语义由 `WDListSection` 标题承担）？
5. 分割线是否**不带文字**（需要标签的分隔改用 `WDListSection`）？
6. 列表行之间用内缩、卡片内部整体分区用全宽——用法约定是否写进注释？
7. 1px/1dp 线宽在两端是否为**物理像素对齐**（避免 2x/3x 下消失或变粗）？
8. 深色主题下与底色对比是否 ≥ 3:1（图形边界要求）？
9. 相邻间距是否来自列表/卡片的容器间距（不额外加 margin）？
10. 是否确认该件在画廊里**没有独立展示**（命中 0），验收以规格与本端截图为准？

**17 `WDCard`（设计 17）**

1. 内边距是否 **固定 16**（`space.5`，**所有变体一致**）、圆角 `radius.xl` **24**、卡间距 `space.4` **12**、分组间距 `space.7` **24**？
2. 五个变体 `elevated / glass / outline / sunken / media` 是否齐？
3. 三个状态是否齐：静态、可点·按下（**整卡亮度 96%** + `motion.duration.instant`）、可点·禁用（**整体 40%**）？
4. **静态卡是否不进入无障碍焦点序列**（内容逐项朗读）；**可点卡是否作为整体朗读、角色 button、朗读文本由卡内标题提供**？
5. **整卡可点时，卡内是否没有嵌套的可点区域**（这是最容易犯的错）？
6. 标题是否**一行、≤20 汉字、超出截断**？
7. 「一张卡表达一件事」是否落实（卡内两个不相关主题就应拆卡）？
8. 卡内子元素是否会因为内边距固定而错位（媒体变体的图片是否出血到边缘）？
9. 玻璃变体是否走 §5.2 的玻璃硬规则（六档 × 文字可用矩阵、配额 ≤1 个模糊面）？
10. 深色主题下 elevated/sunken 的层级是否仍可辨（`elevation.*` 与边框）？

**18 `WDListRow`（设计 18）**

1. 三档行高是否 **单行 44 / 双行 60 / 三行 76**，且**热区 = 布局盒**（= 可见内容 + 上下各 2dp，由本端 `wdTouchTarget` 机制实现）？
2. 三个状态是否齐：默认（透明底）、按下（`fill.pressed` + `motion.duration.instant` 100ms）、选中（**左侧 3pt 品牌条 + 浅底** + `motion.duration.fast` 160ms）？
3. 整行是否作为**一个**元素朗读（「整理储物间，18:00 前，未完成，按钮」）？
4. 前导图标是否标记装饰、**头像朗读成员名**、**分隔线不进入无障碍树**？
5. 标题是否 ≤ **20 汉字**、副标题 ≤ **24 汉字**，超出**截断**（不是换行撑高）？
6. 长按多选是否实现：顶部「已选 n 项」、底部换成「取消 / 删除」、行前导换成勾选框？
7. 批量删除是否**给撤销**（一次撤销恢复整批），退出多选时是否**清空选择**？
8. iOS 受控值名是否为 **`isSelected`**（这是 C-15 里明确保留的**例外**，不要改成 `selected`）？Android 侧为 **`selected`**？
9. 行高公式（44/60/76）是否与 `WDSection`/列表容器一致，没有在容器里再补 padding 导致热区重叠？
10. 是否覆盖「标题超长 + 无副标题 + 带头像 + 选中」这类**组合态**的快照？

**20 `WDIcon`（设计 20）**

1. 四档是否 `sm 16 / md 20 / lg 24 / xl 28`，用在哪是否按规格（行内 / 表单与列表 / 导航栏·Tab·工具栏 / 强调与空状态）？
2. 是否**只暴露语义名 + `mirrorsInRTL`，符号由调用方注入**（库内不绑定 SF Symbols / Material Symbols）？
3. 两端映射是否按规格表（iOS 优先 SF Symbols 的 `.rounded` 变体；Android 用 Material Symbols）？
4. **图标本身是否不可点**（可点时包进 `WDIconButton`，热区 ≥ 44×44）？
5. 装饰性图标是否**标记为隐藏、不进入无障碍树**？
6. 作为**唯一视觉信息**的图标（如状态点）是否**另有文字或无障碍标签**？
7. 图标与背景对比度是否 ≥ **3:1**（已实测的玻璃/浅色底组合要重点查）？
8. 44 条语义名是否与本端注册表一致（不多不少、命名不漂移）？
9. RTL 下是否按 `mirrorsInRTL` 正确镜像（方向类图标镜像、非方向类不镜像）？
10. 线宽与尺寸是否随档位缩放（不是把一套 24 的图形硬缩到 16 导致笔画发虚）？

---

### 21.6 M3–M6 各件「实现前自检十问」（26 件）

> **同 §21.5 的用法**：开工前 10 分钟过一遍，每问都能用「是 / 否」回答；**答不出或答「否」就先回设计规格，不要开写**。
> **数据源** = `../wisdomdesign/docs/specs/` 对应件的第 3 / 4 / 5 / 8 / 10 节（含**变体** §4）（本清单是索引，不替代规格）；件的落点与验收要点见 §13.1，设计锚点与画廊检索词见 §20.2。
> **覆盖**：M3 1 件 + M4 9 件 + M5 15 件 + M6 1 件 = **26 件 × 10 问**。

**M3 · 封板批（1 件）**

**19 `WDListSection`**（设计 19）

1. 三个变体是否齐：标准（标题 + 卡片）、带动作（标题右侧动作）、带页脚？
2. 间距是否按规格：标题与内容 `space.3`（8）、内容与页脚 `space.2`（4）、分组与分组 `space.7`（24）、页面左右边距 `space.5`（16）？
3. **空分组是否整个隐藏**（连标题一起），而不是显示一个空标题？
4. 分组标题是否用 `header` 语义（读屏用户可快速跳转到分组）？
5. 读屏顺序是否为 **标题 → 标题右侧动作 → 组内各行 → 页脚**？
6. 页脚是否作为分组的**补充说明**朗读（而不是被跳过）？
7. 分组本身是否**无状态**（不实现按下/选中态）？
8. 卡片容器是否复用 `WDCard` 的令牌与圆角（不另造一套内边距/圆角）？
9. 分组之间的间距是否只用 `space.7`（不与卡片自带外边距重复累加）？
10. 是否覆盖组合态截图：只有标题、带页脚 + 长标题、组内单行 / 多行？

**M4 · 反馈与弹层（9 件）**

**15 `WDProgressBar`**（设计 15）

1. 高度是否 `6`？
2. 变体是否齐：确定（按百分比填充）、不确定（indeterminate）？
3. 「进行中」是否填充 `gradient.mid`、数值变化 **240ms 线性**？
4. 「完成」是否填充换 `status.success`、到达 100% 时 **300ms 过渡 + 一次成功触觉**？
5. 角色是否为 `progressbar`，并提供 `valuenow` / `valuemin` / `valuemax`？
6. 朗读是否为「上传进度，45%」这种带语境与百分比的整句？
7. **不确定态是否不提供 `valuenow`**，朗读「加载中」？
8. 是否**不可交互**（需要用户操作推进时改用 `WDButton`，而不是让进度条可点）？
9. 数值更新是否只重绘填充（不因父级重组整树重画）？
10. `0%` / `100%` / 越界值（<0、>max）的钳制行为是否有断言？

**16 `WDProgressRing`**（设计 16）

1. 直径是否 `60`（标准）/ `44`（紧凑）？
2. 变体是否齐：百分比（环内显示「60%」）、以及规格列出的其他形态？
3. 「增长」是否为弧从 0 长到目标值 **3200ms 缓出**、且数字**同步递增**？
4. 「完成」是否为环色转 `status.success` + 弹一下 + 成功触觉，且**只播一次**？
5. 整体朗读是否为「本周家务，已完成 3 项，共 5 项，60%」这种**一句读完**的形态？
6. 环本身是否标记为**装饰**、信息由文字承担？
7. 旋转的进度弧是否**不触发持续播报**（只在完成时播报一次）？
8. 默认不可交互；需要点击时**整块（环 + 文字）作为热区**，而不是只让环可点？
9. 减弱动效下 3200ms 增长是否按 `motion.duration.reduced` 降级（不保留长动画）？
10. `fontScale 2.0` 下环内文字是否不溢出、不裁切？

**25 `WDAlert`**（设计 25）

1. 卡片宽是否固定 **270**（**不随内容变化**）？
2. 变体是否齐：双按钮（默认：**取消在左** + 确认）、单按钮、带输入？
3. 出现动效是否为：遮罩 **160ms** 淡入 + 卡片 **240ms** 从 **0.92** 缩放到 1 + 淡入？
4. 按钮按下是否用 `fill.pressed`？
5. 角色是否为 `alertdialog`，且**标题与正文自动朗读**？
6. 出现时**焦点是否移入卡片并被限制在内**（焦点陷阱）？
7. 关闭后**焦点是否归还触发元素**？
8. 破坏性按钮是否用危险色且文案明确（文案由调用方给；库内零文案）？
9. 长文案时是否仍**固定宽 + 换行不裁切**（不用缩小字号）？
10. 挂载形态是否为 `.wdAlert(...)` **挂在锚点视图**（而不是"什么都不渲染的 View"）；`onDismissAttempt` **不存在**（F29）？

**26 `WDBottomSheet`**（设计 26）

1. 顶部两角圆角是否 `radius.xxl` **32**？
2. detent 是否为 `Half = 0.5` / `Large = 0.92`、`max-width = 480`（按冻结值）？
3. 出现动效是否为：遮罩淡入 **160ms** + 面板从底部滑入 **340ms**（`motion.spring.gentle`）？
4. 拖拽中是否面板跟随手指、**遮罩透明度同步变化**（实时）？
5. 把手是否 `36 × 5`、offset `8`；类型名是否为 **`WDBottomSheetDetent{Half, Large}` / `WDBottomSheetDetents{All, Fixed}`**（**不得出现 `WDSheet*`**）？
6. 焦点是否进入面板并被限制在内；关闭后是否**归还触发元素**？
7. 是否提供「下滑关闭」的**自定义辅助操作**（不能只依赖手势）？
8. 状态是否用 `rememberWDBottomSheetState` + `saver(...)`（配置变更/重建后仍保持）？
9. 是否覆盖「到顶/到底阻尼、快速甩动、拖到一半松手」三种手势边界？
10. 键盘出现时是否按 V3 的结论避让（面板不被键盘遮挡、内距不变形）？

**27 `WDActionSheet`**（设计 27）

1. 操作行高是否 **44**？
2. 变体是否齐：标准、含破坏性项、带标题/说明？
3. 出现是否为从底部滑入 **340ms** `motion.spring.gentle`；按下是否该行 `fill.pressed` + **100ms**？
4. 角色是否为 `menu`（每项 `menuitem`）？
5. **破坏性项朗读是否包含后果**（由调用方文案承载）？
6. 出现时焦点是否进入列表，且**取消按钮可被独立到达**？
7. 取消按钮是否与操作列表**视觉分离**（避免误触）？
8. 项数超过一屏时是否可滚动且首项不被遮挡/不被取消键压住？
9. 是否与 `WDBottomSheet` **复用同一套遮罩与弹簧**（不出现两套动效参数）？
10. 关闭后焦点是否归还触发元素？

**28 `WDToast`**（设计 28）

1. 高度是否 **46**（单行）；多行时自适应且**最多 2 行**？
2. 变体是否齐（成功 / 信息 / 失败 / 带操作），图标与色是否按规格？
3. 出现是否为 **320ms 上移淡入**；时长是否按规格：纯提示 **3 秒**、带操作 **≥5 秒**（真源键 `durationMilliseconds`，支持 ≥5000）？
4. 无障碍：成功/信息是否 `aria-live="polite"`；失败是否 `role="alert"`（立即播报）？
5. 带操作时朗读是否为「任务已删除，撤销，按钮」？
6. 悬停/聚焦时是否**暂停计时**，移开后**继续剩余时间**（不是重新计时）？
7. 同屏多个 Toast 是否排队/合并（不叠罗汉、不互相遮挡）？
8. 调用方是否可把时长设到 ≥5000ms（上限与下限都有断言）？
9. 动效是否走 `WDMotion` 包装、**禁止 `withAnimation` 包整 body**？
10. 顶部/底部两种浮出形态是否都不遮挡关键操作（安全区/键盘避让）？

**29 `WDBanner`**（设计 29）

1. 最小高是否 **44**（单行）？
2. 四变体（info / success / warning / danger）的底色（软底渐变）、文字与图标色是否按规格？
3. 两个状态是否实现：**常驻**（直到条件解除才消失）、**可关闭**（右上角关闭键，关闭后**本次会话不再出现**）？
4. 无障碍：信息/成功是否 `role="status"`；警示/错误是否 `role="alert"`？
5. 错误态是否**图标与文字同时变化**（不依赖颜色传达）？
6. 关闭键标签是否为「关闭提示」+ 按内容补充（如「关闭网络提示」）？
7. 是否**不随列表滚动**（常驻位）且不与 `WDNavigationBar` 抢位？
8. 多行文案时是否不裁切、图标与首行对齐？
9. `WDBanner.visible` 的命名是否与 F 注册表一致（`is` 前缀例外，F1）？
10. 关闭后的"不再出现"是否由**调用方持状态**（库不偷偷记忆全局状态）？

**30 `WDEmptyState`**（设计 30）

1. 底座是否 **56×56**？
2. 四变体（首次空 / 搜索无结果 / 权限受限 / 加载失败）的标题与操作是否按规格？
3. 间距是否按规格：底座与标题 `space.4`（12）、标题与说明 `space.2`（4）、说明与操作 `space.5`（16）？
4. 是否作为**一组**朗读：标题 → 说明 → 操作？
5. 图标底座是否标记为**装饰**？
6. 读屏用户进入空页面时，**标题是否被首个朗读到**？
7. 「加载失败」变体的重试是否可重复触发，且**重试期间按钮进入加载态**？
8. 空状态本身是否**无状态**（不实现选中/按下）？
9. 长说明 / 长按钮文案是否换行不裁切（禁 `maxLines = 1`）？
10. 是否覆盖「无操作」「有主操作 + 次操作」两种组合的截图？

**31 `WDSkeleton`**（设计 31）

1. 三种形态是否齐：文本（3–4 行）、列表行（与 `WDListRow` **等高** 44 / 60 / 76）、卡片（与真实卡片**同尺寸、同圆角、同内边距**）？
2. 文本行是否高 **11**、圆角 **6**、宽度按真实文本比例（**70% / 45%**）？
3. 是否确认**只有一种状态**（加载中）；加载完成后**整块替换**为真实内容、**不逐块替换**？
4. 骨架容器是否标注 `aria-busy="true"`？
5. 整个骨架区是否**只朗读一次**「加载中」（不是每个灰块都朗读）？
6. 加载完成后是否朗读「内容已加载」，并**把焦点保持在原位置**？
7. 骨架出现时是否**禁用页面滚动**（内容高度尚未确定）？
8. 微光效果是否计入效果配额：**同屏 ≤6**，第 7 个起用**静态灰块**？
9. 减弱动效下微光是否**静态**（不是减速）？
10. 骨架是否**不可交互**、不进入焦点序列？

**M5 · 导航与表单（15 件）**

**04 `WDSearchField`**（设计 04）

1. 高度是否 **46**（与 `WDTextField` 一致；**同一页面里两者必须等高**）？
2. 圆角 `radius.full`、水平内距 12、前导图标与输入区间距 8 是否按规格？
3. 变体是否齐：标准、带取消？
4. 五态是否齐：空态（未聚焦，容器底 `surface.card` + 占位符 `text.tertiary`）、聚焦、有值、无结果、禁用？
5. 角色是否为 `searchbox`，朗读文本**包含搜索范围**？
6. 清除按钮标签是否为「清除搜索内容」；取消按钮标签是否为「取消搜索」？
7. 结果数变化是否用 **polite** 播报（阈值由调用方给，库不设阈值）？
8. 取消按钮出现/消失时是否不引起布局跳动（输入区宽度平滑变化）？
9. 文案（占位符 / 标签）是否全部由调用方注入（L-B）？
10. 大字号下清除/取消按钮热区是否仍 ≥44？

**07 `WDRadio`**（设计 07）

1. 标准档是否外圆 **26** / 内圆点 **12** / 标签 `type.subheadline` **15**？（紧凑档若规格有，取值是否一致？）
2. 未选态是否描边 `border.hairline-strong` **1.5pt** + 底 `fill.field`？
3. 选中态是否有**明确的动效与触觉**（与 `WDCheckbox` 同族但不复制其勾选动画）？
4. **整组是否用 `radiogroup` 包裹并给出组标签**（如「可见范围」）？
5. 每项角色是否为 `radio`，朗读是否为「仅自己可见，已选中，单选按钮，第 1 项，共 2 项」？
6. 键盘/遥控焦点是否在组内**单向循环**（不跳出组）？
7. 点击已选项是否不触发变更（不重复回调）？
8. 标签是否 2–12 汉字、名词短语、不用问句？
9. 热区是否 ≥44（外圆 26，必须撑满）？
10. 与 `WDCheckbox` 的**语义差异**是否在文档注释里写清（单选 vs 多选、不可取消 vs 可取消）？

**08 `WDSlider`**（设计 08）

1. 轨道高是否 **6**；手柄是否 **26**（白色 + `elevation.1` + 1pt `border.hairline` 描边）？圆角 `radius.full`、最小宽度 **120**？
2. 变体是否齐：单值 / 带刻度 / 范围？
3. 状态是否齐：默认（轨道 `border.hairline-strong`、填充 `gradient.mid`）、拖拽、聚焦、禁用？
4. 角色是否为 `slider`，并提供 `value` / `min` / `max`（可选 `step`）？
5. 朗读是否为「完成度，62%，可调整」？
6. 松手时是否**只播报一次**（拖动过程中不连续播报）？
7. 拖动是否只更新填充与手柄（不重组整个父级列表）？
8. 步进（`step`）存在时，值是否**吸附到离散刻度**且朗读值同步？
9. 范围变体是否保证**双手柄不交叉**（相等时的钳制规则明确）？
10. `minimumScaleFactor` / `Mode.Fixed` 等禁用项是否都没用上（行盒与文字不缩放）？

**09 `WDStepper`**（设计 09）

1. 标准档是否容器高 **36** / 按钮宽 **40** / 字号 **14**？
2. 容器是否 `surface.glass-strong` + `border.hairline`；按钮符号是否 `text.brand`？
3. 变体是否齐：水平 / 紧凑？
4. 角色是否为**可调整控件**（iOS `adjustable` / Android 等价），朗读「数量，3，可调整」？
5. 是否支持**直接的增减手势 / 无障碍动作**（不只靠点按钮）？
6. **高频连点是否不给触觉**（每次操作 1 次节流，超频不再震动）？
7. 到达 min/max 时按钮是否禁用且**朗读状态变化**（不是静默失效）？
8. 长按加速是否存在（若规格有）且速率上限明确？
9. 数值文本是否等宽（避免数字跳动导致宽度抖动）？
10. 热区是否 ≥44（容器 36，必须撑满）？

**10 `WDChip`**（设计 10）

1. 标准档是否高 **32** / 水平内距 **12**（带图标时左 10 右 14）/ 字号 **13** / 圆角 `radius.full`？
2. 变体是否齐：展示 / 可选 / 可删除？
3. 可选芯片角色是否为 `checkbox`（多选）或 `radio`（单选），朗读「已完成，已选中」？
4. 删除键标签是否为「移除筛选：妈妈」这种**带对象名**的形式？
5. 选中/未选的视觉差异是否**不只靠颜色**（描边或底色差异同时存在）？
6. 可删除芯片的删除区热区是否 ≥44（芯片仅 32 高）？
7. 多芯片换行规则是否按规格（行间距、与容器边距）？
8. 长标签是否截断且**不裁切文字**（截断方式按规格）？
9. 键盘焦点顺序是否按视觉顺序（删除键紧随其芯片）？
10. 展示型芯片是否**不可交互、不进焦点序列**？

**13 `WDAvatarStack`**（设计 13）

1. 头像档位是否 `sm 28` 或 `md 32`；**重叠量是否 = 直径的 30%**（28→8，32→9）？
2. 描边是否 2pt、颜色**取所在容器底色**（卡片或画布）？
3. 最大显示数是否为 **4**；超出是否显示「+N」？
4. 堆叠本身是否**无状态**？
5. 成员变动（新增/离开）是否用 **240ms 淡入淡出**且**不重排已有位置**？
6. 是否作为**一个**元素朗读：「家庭成员 6 人：我、妈妈、爸爸、妹妹，另有 2 人」？
7. 是否**不逐个朗读**每个头像（否则读屏要听 6 遍）？
8. 头像颜色是否按**成员 ID 固定**（与 `WDAvatar` 同规则，换页不换色）？
9. 溢出数字是否随语言/字号自适应宽度（不裁切）？
10. 与 `WDAvatar` 的档位映射是否一致（不各造一套尺寸）？

**21 `WDSegmentedControl`**（设计 21）

1. 容器高是否 **38**（内容 32 + 上下内边距 **3**）？
2. 变体是否齐：玻璃底 / 实底（按规格）？
3. 状态是否齐：未选（文字 `text.secondary`）、已选（选中态视觉 + 动效）、按下、禁用？
4. 选中指示器的移动是否为**弹簧动画**（用 `motion.spring.*` 令牌，不是线性）？
5. 容器角色是否为 `tablist`、每段角色为 `tab`，并标注「第 n 项，共 m 项」？
6. 选中项是否标注 `aria-selected="true"`？
7. 段数 2–5 时，每段最小宽度与文字截断策略是否明确（不靠缩小字号）？
8. 键盘方向键是否可切换段（左右移动焦点与选中）？
9. 玻璃底变体是否走 `WDGlass.resolve`（不自行选档），且计入效果配额？
10. 无障碍热区是否 ≥44（容器 38）？

**22 `WDPicker`**（设计 22）

1. 触发入口高是否 **44**？
2. 变体是否齐：菜单 / 滚轮 / 内联（按规格）？
3. 默认态是否为「值为 `text.primary`、箭头 `text.tertiary`」；按下/展开态是否有定义？
4. 触发入口角色是否为 `button`，朗读「分类，当前值：家务，展开选择」？
5. 弹出层角色是否为 `listbox`、选项角色为 `option`，当前项标注 `aria-selected`？
6. 弹出层是否由**调用方或库的弹层机制**承载（与 `WDBottomSheet`/`WDAlert` 不重复实现遮罩）？
7. 长列表是否可滚动且**当前项自动滚到可见**？
8. 无值时朗读是否明确（如「分类，未选择，展开选择」）？
9. 选项文本超长是否截断不换行（保持行高一致）？
10. 关闭后焦点是否归还触发入口？

**23 `WDDatePicker`**（设计 23）

1. 触发入口高是否 **44**？
2. 变体是否齐：日期 / 时间 / 日期范围？
3. 三态是否齐：未选（「设置日期」，色 `text.tertiary`）、已选、禁用？
4. 触发行朗读是否为「截止日期，已选，2026年10月3日，按钮」？
5. 日历网格中**每个日期**是否朗读完整信息（「10月3日，星期五，已选中」）？
6. 日期格式是否按内容规范的本地化形态（不硬编码 `yyyy-MM-dd`）？
7. min/max 边界外的日期是否禁用且**朗读中体现不可选**？
8. 键盘/读屏在网格中的移动是否为**二维方向键**（周内左右、跨周上下）？
9. 选择后是否**立即更新触发入口文本**并归还焦点？
10. 今天/选中/禁用等状态是否**不只靠颜色**（形状或加粗同时变化）？

**24 `WDFormRow`**（设计 24）

1. 行最小高是否 **44**？
2. 变体是否齐：标签在左 / 标签在上 / 带说明 / 带错误（按规格）？
3. 默认态标签是否 `text.primary`；错误态是否 `status.danger` 且**说明与错误不同时显示**？
4. 标签与控件是否**必须关联**（读屏先读标签再读控件）？
5. 出错时是否读「截止日期，错误，日期不能早于今天」这种**含错误句**的形态？
6. 标签与控件在同一行时，控件是否右对齐且**不吃掉标签的截断空间**？
7. 必填标记是否**不只靠颜色/星号**（朗读中包含「必填」）？
8. 长标签是否截断（不换行撑高），长控件值是否同样处理？
9. 行内控件（Switch/Stepper/Checkbox）整行是否可点（除控件外区域也可触发）？
10. 与 `WDTextField` 的标签语义是否一致（不出现两套"标签"概念）？

**32 `WDPullToRefresh`**（设计 32）

1. 触发阈值是否 **64**（下拉超过此距离松手才刷新）？
2. 指示器直径是否 **24**、环线宽 **2**、指示器与首行间距 `space.4`（12）？
3. 四态是否齐：空闲（指示器隐藏在列表上方）、下拉中、刷新中、完成？
4. 变体是否齐：品牌进度 / 极简？
5. 是否提供「刷新」的**自定义辅助操作**（读屏用户不需要会下拉）？
6. 刷新开始与结束是否**各播报一次**：「正在刷新」/「刷新完成」？
7. 下拉过程中的进度是否与手指位移**线性对应**（松手回弹用弹簧）？
8. 刷新中再次下拉是否**不重复触发**（去重）；
9. 列表内容不足以滚动时是否仍可下拉（或明确禁用）？
10. 是否计入效果配额：**每屏 ≤1 个动画环**（与 `WDProgressRing` 冲突时按配额降级）？

**33 `WDNavigationBar`**（设计 33）

1. 两种模式是否齐：内联（紧凑）**44**、大标题（含展开高度），大标题是否有滚动收缩？
2. 变体是否齐：透明底 / 玻璃底 / 不透明（深色端按 `../AGENTS.md` §12.1 规则 ③ 改不透明）？
3. 状态是否齐：未滚动（透明底、无分割线）、滚动后（玻璃/分割线出现）、按下？
4. 玻璃底是否走 `WDGlass.resolve` 并计入效果配额（同屏 ≤1 模糊面）？
5. 导航栏是否作为 `header` 语义、**标题作为页面标题被首个朗读**？
6. 返回按钮标签是否**包含来源页名**（「返回家庭列表」）？
7. 大标题收缩是否用 `motion.*` 令牌（不是裸时长），且减弱动效下直接跳变？
8. 两侧动作按钮是否 ≤2 个（更多则进溢出菜单）？
9. 状态栏/安全区处理是否不重复占位（与页面骨架的边距不叠加）？
10. 标题超长时是否截断并**朗读完整标题**（视觉截断 ≠ 语义截断）？

**34 `WDTabBar`**（设计 34）

1. 高度是否 **58**；距左右边缘 `space.5`（16）、距底部安全区 `space.3`（8）、图标 **22** 是否按规格？
2. 变体是否齐：iOS 悬浮胶囊 / Android 全宽（按端形态；**深色端是否改不透明**）？
3. 五态是否齐：未选（图标与标签 `text.tertiary`）、选中、按下、带角标、禁用？
4. 容器角色是否为 `tablist`、每项 `tab`，朗读「第 n 项，共 m 项」，选中项标注 `aria-selected`？
5. 悬浮形态是否用 `glass-strong`（浅色）并按 `../AGENTS.md` §12.1 规则 ③ 处理深色端？
6. 标签是否允许 2 行（按规格）；不允许时截断策略明确？
7. 切换是否**不重建页面状态**（各 Tab 状态保留）？
8. 角标是否复用 `WDBadge`（不另造一套）且**不计入无障碍焦点**？
9. 图标 `mirrorsInRTL` 在 RTL 下顺序是否整体镜像（不是单个图标翻转）？
10. 与 `WDNavigationBar` 同屏时玻璃配额是否被正确计数（合计 ≤1 模糊面）？

**35 `WDToolbar`**（设计 35）

1. 容器高是否 **48**；图标按钮 **20**、按钮间距 `space.2`（4）、容器内边距 **6** 是否按规格？
2. 三种位置是否齐：顶部 / 底部 / 键盘上方？
3. 默认态是否 `surface.glass-strong` + `border.hairline` + `elevation.1`？
4. 四个按钮态是否齐：默认 / 按下 / 选中 / 禁用？
5. 每个图标按钮是否**必须有标签**（长按提示是补充不是替代）？
6. 整条工具栏是否有**分组标签**（如「编辑工具」）？
7. 「键盘上方」形态是否跟随键盘安全区（不遮挡输入框）？
8. 按钮数超限时是否进溢出菜单（而不是压缩间距到不可点）？
9. 选中态是否**不只靠颜色**（底色或描边同时变化）？
10. 玻璃底是否计入效果配额，且与同屏其他玻璃元素一起 ≤1？

**36 `WDFAB`**（设计 36）

1. 三档是否齐：标准 **56×56**（圆角 `radius.fab` **19**、图标 **24**）、大 **64**、小 **40**？
2. 三变体是否齐：圆角方（默认）/ 圆形 / 可展开？
3. 默认态是否 `gradient.fill`（浅深两端各自取值）+ `elevation.brand`？
4. 五态是否齐：默认 / 按下 / 滚动（收起或缩小）/ 展开 / 禁用？
5. 标签是否写**动作**（「新建任务」）而不是图标名？
6. 展开态是否**作为一个组朗读**，且子操作**各自可聚焦**？
7. 展开/收起的动效是否用 `motion.spring.*`，且减弱动效下直接切换？
8. 滚动时的收起/缩回是否**不引起列表跳动**（占位/位移补偿）？
9. 是否避开 TabBar / 安全区（不被遮挡、不压住内容）？
10. 与 `WDIconButton` 的分工是否清晰（FAB 是页面级主操作，不是行内动作）？

**M6 · 场景组件与发布（1 件）**

**37 `WDAssigneePicker`**（设计 37）

1. 头像是否 **40**；头像间距 `space.4`（12）；选中外环 **2pt 描边 + 4 间隙（外径 52）**；名字与头像间距 `space.2`（4）？
2. 四变体是否齐：单选（默认）/ 多选 / 带未指派 / 紧凑？
3. 五态是否齐：未选 / 选中 / 按下 / **禁用成员（已离开家庭）** / 整体禁用？
4. 整组是否用 `radiogroup`（单选）或 `group`（多选）包裹，并给出组标签「指派给」？
5. 每项朗读是否为「妈妈，已选中，单选按钮，第 2 项，共 4 项」？
6. **已离开家庭的成员**是否朗读中体现不可选（如「已离开，不可选」），而不是静默禁用？
7. 「带未指派」变体是否保证「不指派」也是一个**可聚焦选项**（不是空白）？
8. 紧凑变体是否只缩尺寸、**不缩热区**（仍 ≥44）？
9. 头像颜色是否按成员 ID 固定（与 `WDAvatar` 同规则）？
10. 多选时是否给出「已选 n 人」的**汇总朗读**（避免逐个听）？

---

## 22. 文档变更历史

| 轮次 | 变更 | 影响面 |
| --- | --- | --- |
| `t67` | 首次落盘：13 节骨架（范围 / M0–M6 本端视图 / 批次分配 / 命令与门禁 / 冻结值与契约 / 回写项 / 设计待给值 / 风险与未验证 / 关键路径 / 变更与发布 / 三文档分工 / 验证记录）+ C-15 37 行内联 | 新建 |
| `t72` | 新增 **§4.6 文档类改动纪律**（结构自检 + 禁止自命中 + 双跑 + 根因实例） | §4.6 |
| `t73` | §5.3 改名台账（#06 = `isChecked`）、§2.3 标题与 §3 `(C)` 图例、§5.3 第 ④ 条断言、§4.4 U-01 交叉引用、§12 字符类写法 | 多处一行级 |
| `t82` | 新增固定项 **⑥ 表格结构自检**；§3 图例移到表外（修复表格降级）；§5.3 断言改为"预期差异 = {#06}"；AGENTS 指针项数对齐 | §3/§4.6/§5.3 |
| `t83` | 引用完整性：ARCH 节号换算 30 处（悬空 = 0）、退役名→本仓映射行、`schemes` 第三条硬边界、`SPEC.md` 痕迹与时点说明 | 跨 4 份文档 |
| `t85` | **开发者向详补**：新增 **目录（可跳转锚点）**、**§13 逐组件索引（37 件 checklist，逐行同源 `docs/SPEC.md` §2.10）**、**§14 单组件作业流程 SOP（8 步）**、**§15 验收手册（逐批命令 + 处置 + 勾选清单）**、**§16 开发者指南（环境/风格/提交/排障 8 条/升级）**、**§17 术语表**、**§18 关键决策摘要（20 条，带来源）**、**§22 变更历史** | 新增 8 节；**未改任何判据、冻结值与口径** |
| **本轮（船长裁决 · 档位列）** | **§13.1 的「档位（A/B/C）」列 → 「关键路径件（是/否）」**（依据 §3 批内顺序与批间依赖；无法取证的写 `否`）；§3 图例重述 `(C)` = 关键路径件并声明 A/B/C 口径废止；§2.3 标题去掉 "C 档" 标签（事实不变）；§17 术语表同步 | **去掉 A/B/C 的理由**：① A/B/C 本质是**工作量（人日）口径**（A=1.0 / B=1.75 / C=3.0 pd），与**用户决策 #1**"所有开发都是 vibe coding、不需要计算人力"冲突；② 其来源（跨端计划）已随退役文档集不可取证 ⇒ **不回填旧数据**；③ 若日后需要工作量口径，**从工单数据重建**（不再用文档里的档位字母）。与 Android 侧同一处理，跨端同批组件该列取值一致 |
| **跨端对齐（船长裁决 · 关键路径件统一 12 件）** | §13.1 的「关键路径件」列两端统一为 **`是` = 12 / `否` = 25**：在 iOS 侧 11 件基础上**并入 M6 `WDAssigneePicker`**，并在表下补**判定式**（关键路径件 = 批内串行链上被点名件的并集，跨端同答案） | **差异双向来源（留档）**：① **iOS 多 M4 三件**（`WDAlert` / `WDActionSheet` / `WDToast`）——依据本文件 §3 批次表的 `(C)` 标记（M4 玻璃族四件同批串行）；② **Android 多 M6 一件**（`WDAssigneePicker`）——依据其 §9.1 的 M6 串行链点名。**裁决 = 取两端可取证点名件的并集**（避免任一端丢信息）；M3 `WDListSection` 两端一致记 `否`（保守） |
| **目录锚点修正（t92 · R2-01/R2-02）** | ① 目录 **14 条锚点**改为 **GitHub slug 规则**（**不折叠连续 `-`**：`#21-m0-工程…` → `#21-m0--工程…`，涉 §2.1–§2.7 / §3 / §4.3 / §4.4 / §6 / §7 / §13.1 / §15）；② **内嵌自检命令本身已纠**（原含"折叠连续连字符"假定 ⇒ 会假绿，正是 R2-01 成因），改为 GitHub 一致规则并把判据词改为 `缺条目 [] 不匹配 []`；③ §4.6 固定项 ② 并入"目录锚点核验" | 证据：按 GitHub 规则重生成后 **58/58 全匹配（不匹配 = 0）**；而按旧的折叠规则**恰好 14 条不符** ⇒ 证明旧自检确实假绿。来源 = `docs/DEV-PLAN-REVIEW.md` §1 的 R2-01（14 行「现 → 应」对照表） |
| **跨端记号风险登记 + 反推限定（与 android-lead 同批）** | ① 新增 **`(C)` 同形不同义**登记（iOS = 关键路径件标记 / Android §3.2 = 层标记 primitives·composites），并规定**引用必须带端别、不得互读**；② §13.1 加**「不得反推」限定句**：A/B/C 字母与聚合计数（如"12 C"）不作现行判据，只认三处点名 + 跨端并集 | 与本文件 §3 图例、§17 术语表、§13.1 脚注配套；两端「关键路径件」列 **12/12 逐件一致**（iOS 侧核对行见本表上一行，Android 侧见其 §18） |
| **设计向详补（船长 · 本轮）** | 新增 **§19 设计文档与设计图查阅指南**、**§20 逐组件设计溯源表**（37 件 → 设计编号 + `../wisdomdesign/docs/specs/` 锚点 + 画廊检索词与实测命中数 + 设计优先级 + 本端批次）、**§21 从设计规格到实现与验收**（12 节 → 本端产出映射 / 画廊核验六步 / 能核与不能核 / 六态截图硬要求） | 实测依据：设计仓 13 份规范 + `../wisdomdesign/docs/specs/` 4 份 + 画廊 3 份 + 预览 1 份；37 件与设计编号 01–37 一一对应**无缺号**；画廊无逐组件锚点 ⇒ 用**检索词 + 实测命中数**定位（可复核） |
| **目录重建（同批）** | 目录按**标题为准**重建：**73 条 = 73 个标题**（新增 15 条新章节条目），**顺序一致**；锚点一律按 **GitHub slug 规则**（连续连字符**不折叠**，如 `#21-m0--工程…`），原有 14 条双连字符锚点保持不变 | 重建后自检：缺失 = 0、多余 = 0、顺序一致 = True；表格块 35 / 异常 0 |
| **视觉规格速查（同批）** | 新增 **§20.4 视觉规格速查（37 件）**：逐件给「尺寸要点 · 变体 · 状态」三列，数据**从设计规格第 3/4/5 节实测抽取**（脚本抽取，未人工转写）；目录随之重建为 **74 = 74** | 抽样复核 3 件（06 Checkbox / 32 PullToRefresh / 37 AssigneePicker）与 `../wisdomdesign/docs/specs/` 原文**逐值一致**；表格块 36 / 异常 0 |
| **速查表按批次重排 + 补两列（同批）** | §20.4 由单表改为**按批次 5 张小表**（M2 11 / M3 1 / M4 9 / M5 15 / M6 1 = 37），并新增 **关键令牌**列（尺寸/圆角/字阶/间距/动效，取规格内实测出现的前 4 个）与 **对比度速查**表（规格里**明确给值**的 12 件；其余适用全局门槛 4.5:1 / 3:1 / 焦点环 3:1 / 禁用 40%） | 数据仍为**脚本抽取**（未人工转写）；表格块 41 / 异常 0；目录 74 = 74 |
| **令牌落地 + 门禁闭环 + P13（本轮）** | ① 生成物目录 `Generated/` → `generated/`（I-M0-h 纯移动，用户裁决；零内容变化）；② **P13 登记** + 五份文档的路径与 scheme 文本回写；③ `--tokens-trace` 落地（I-M0-g 的跨仓半边）；④ **D-19 回填**：实测固化 scheme = `WisdomDesign-iOS-Package`；⑤ §8.1 的 U-01（部分）/U-02（全部）状态回填 | 影响 §4/§4.4/§5/§6/§8.1/§14/§15/§16 的路径与 scheme 文本；**未改任何判据、冻结值与口径** |
| **M3–M6 实现前自检十问（本轮）** | 新增 **§21.6**：M3 1 件 + M4 9 件 + M5 15 件 + M6 1 件 = **26 件 × 10 问 = 260 条**；与 §21.5 的 M2 十问同法——每问锚定该件的规格事实（尺寸档 / 变体 / 状态+动效+触觉 / 无障碍语义与朗读 / 内容与交互约束 / 平台差异） | 数据同样**脚本抽取自 `../wisdomdesign/docs/specs/`**（第 3/4/5/8/10 节），未人工转写；目录随之重建为 **76 = 76**；表格块 41 / 异常 0 |


