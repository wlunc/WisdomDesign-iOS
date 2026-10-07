# AGENTS.md · WisdomDesign-iOS 施工手册

> 面向"会在这个仓里写代码的 agent"（vibe coding）。**先读本页，再动手。** 本页只给「结构 + 命令 + 冻结值 + 禁止项」，技术细节一律跳转到规格章节，不复述规格全文。
> **效力顺序（t55 统一、t80 去死链，顺序未改）**：**用户决策**（`08`） ＞ **跨端契约 U/F 裁决**（`07`） ＞ **本端规格 `docs/SPEC.md`**（`02`） ＞ **命名表 `docs/DEV-PLAN.md` §5.3**（`40`，只管名字 / C-15） ＞ **计划与冻结值口径 `docs/DEV-PLAN.md`**（`30`）＞ 本端 AGENTS/ARCH。
> **本页口径**：已经并入用户 2026-10-04/05 的 6 条决策（见 §6 冻结值、§8 规格差异）。**口径来源统一 = `docs/DEV-PLAN.md` §5（冻结值与口径）**；本端规格 `docs/SPEC.md` 与 Android 侧规格 `android/docs/SPEC.md` 的对应条目按 `docs/DEV-PLAN.md` §6 的回写清单（P7–P12）同步。
> 路径写法：本仓内相对路径（如 `Sources/...` 与 `docs/SPEC.md`）；跨仓用 `../`（如 `../wisdomdesign/docs/06-accessibility.md`）。
> **来源与代号约定（t80）**：**跨端工作区文档集已退役**，规格已按端迁仓（**本端 = `docs/SPEC.md`**，Android 侧 = `android/docs/SPEC.md`）。本页正文里的两位代号按此解读：`02` = `docs/SPEC.md`；`30` = `docs/DEV-PLAN.md`；`40` = `docs/DEV-PLAN.md` §5.3（C-15 定名表）；`07`/`08` = 跨端裁决与用户决策（结论已冻结在 `docs/DEV-PLAN.md` §5/§6/§7 与本页 §6）；`20`/`22`/`24`/`28` = iOS 组长评审链（结论在 `docs/DEV-PLAN.md` §5.1 与本页 §6）；`01` = iOS 首轮评审（结论在本页 §5/§6.1）；`03`/`03-perf-release` = 性能与默认值讨论稿（结论在本页 §6/§12.2）；`62`/`63`/`64`/`69`/`71` = 仓内文档复核链（结论在本页 §6.1/§8/§12 与 `docs/DEV-PLAN.md` §6）；`12` = Android 规格（已迁 `android/docs/SPEC.md`）。
> **设计真源**：设计文档位于**外部设计仓 `wisdomdesign/docs/`**（该仓保留、引用有效）：在本页内相对路径为 `../wisdomdesign/docs/<名>`，在 `docs/` 下为 `../../wisdomdesign/docs/<名>`；后文以其**文件简称**引用（如 `06-accessibility.md`、`12-b22-glass.md`）。
> **本文件受 64KB 自动加载预算约束**（当前约 57 KB）：新增细节请写 `docs/ARCHITECTURE.md`，本文件只保留入口、判据与指针。核对：`wc -c iOS/AGENTS.md`。

---

## 0. 30 秒上手

> ✅ **M0 进行中（2026-10-06 快照）**：§5 的脚本（`check-structure.sh`/`check-format.sh`/`test-checker.sh`/`dump-api.sh`/`ci.sh`）、`.github/workflows/ci.yml`、`api/WisdomUI.api.json` **均已落地**；**`Scripts/ci.sh pr` 已首次全绿**（PR-0 规则+格式+令牌溯源 → PR-1a 编译+签名冒烟 → PR-1b 单测 `passed=6` → PR-2 API 零 diff → 覆盖率报告）。**M0 的 11 项任务已全部交付**（a–k）。**仍有两处外部依赖不阻塞收尾**：I-M0-g 的三个契约读取入口（等设计仓 `contracts/`，M0-5）与 I-M0-h 的 `WDIconName.swift`（生成器尚未产出 icon 产物）。**收尾动作**（由项目负责人决定）：`api/WisdomUI.api.json` 入库（M0 出口④）与 M0 出口 6 条的判定。

1. **不要跑 `swift build` / `swift test`**——本包只声明 `.iOS(.v17)`，host 侧编译必然失败（218 错）。门禁一律 `xcodebuild` + 模拟器（硬约束 7，用户决策链 `08` §2-7）。
2. **不要手改生成物**：`Sources/WisdomUI/Foundation/generated/**` 只允许 `../wisdomdesign/tools/token-build/build.js` 写入（R12 校验文件头 banner，`docs/SPEC.md` §1.1.1）。
3. **不要跨仓写**：`../android/**`、`../wisdomdesign/**` 一律只读（跨仓写入零容忍）。
4. **动手前先看两张表**：§3 进程骨架（能不能开工/能不能结批）与 §6 冻结值（哪些值已经定死）。
5. **不确定就升级**：§11 的升级路径。

```bash
# 秒级自检（host，不需要 Xcode）（脚本已由 I-M0-b/c 落地；仅在脚本缺失的历史状态下才需要 §5.0 的三条命令）
cd iOS && Scripts/check-structure.sh      # R1–R21 结构/依赖/字面量/令牌溯源
cd iOS && Scripts/check-format.sh         # swift-format（显式清单，排除 generated/）
```

---

## 1. 本仓定位与可写 / 不可写边界

**定位**：发布一个 SwiftUI 组件库（单发布 product `WisdomUI`），消费方 `import WisdomUI` 一行接入（`docs/SPEC.md` §1.2）。库内**零资源、零文案、零第三方依赖**（用户决策链 `08` §2-5；跨端裁决链 `07` **§2.2-DIR-3 / §2.3-2** 与 §1 的目录表——**注意**：`07` §1.4 是"三条反模式禁则"，不是零资源条款，t60·C7 已纠正）。

| 路径 | 可写？ | 说明 |
| --- | --- | --- |
| `Sources/WisdomUI/Foundation/**` | ✅ | 层 0：令牌、主题、排版、布局、动效、材质、无障碍、图标帮助函数（`docs/SPEC.md` §1.1） |
| `Sources/WisdomUI/Components/{Primitives,Composites}/**` | ✅ | 37 个组件，一组件一目录、三分法文件（`docs/SPEC.md` §1.1/§1.3） |
| `Sources/WisdomUI/Internal/**` | ✅ | 内部实现；**零 `public`**（R6） |
| `Sources/WisdomUIPreviews/**` | ✅ | 预览支撑；**不进 `products`**（`docs/SPEC.md` §1.2） |
| `Sources/wd-structure-check/**` | ✅ | host 检查器可执行 target；**只 import Foundation，不得依赖 `WisdomUI`**（`docs/SPEC.md` §1.1.1） |
| `Tests/**`、`api/WisdomUI.api.json` | ✅ | 测试与符号快照基线（快照必须与成因同提交，§9） |
| `Scripts/**`、`.github/**`、`Package.swift`、`README.md`、`CONTRIBUTING.md`、`CHANGELOG.md`、`Examples/**` | ✅ | 工程与文档 |
| `Sources/WisdomUI/Foundation/generated/**` | ❌ | **只允许生成器写**；人工改动会被 R12 拦（banner 校验） |
| `Sources/WisdomUI/Resources/**` | ❌ | **不得创建**（库内零资源，硬约束 5；目录存在即 error） |
| `Components/Patterns/**` | ❌ | 已删（37 = 20 + 17）；存在即 error（R4） |
| `../android/**`、`../wisdomdesign/**` | ❌ | 跨仓写入零容忍（需要改令牌 → 走设计仓变更集，§9） |
| 跨端工作区文档集（**已退役**） | ❌ | 规格已按端迁仓（本端 = `docs/SPEC.md`）；**其余结论已冻结**在 `docs/DEV-PLAN.md` §5/§6/§7 与 `docs/SPEC.md`，**不再更新、不得作为施工依据** |

> 需要"越界"时：先看 §10 的豁免流程，**不要私自放宽检查器或改规格文本**。

---

## 2. 唯一真源与阅读顺序

**按这个顺序读，不要跳**（每一步都只读，不要改）：

| 顺序 | 真源 | 读什么 | 为什么 |
| --- | --- | --- | --- |
| 1 | 用户决策（`08`，跨端工作区文档集 · **已退役**） | U1–U10 决策 + **§2 八条硬约束** | 用户已拍板；与 `07` 冲突时仅就 U1–U10 以它为准 |
| 2 | 跨端裁决（`07`，跨端工作区文档集 · **已退役**） | **§1**（U1–U14 必须统一；**F1–F20** 在 §1.3，只到 F20）、§5（目录终稿）、§6（路线图 + 三层门禁） | 跨端契约边界线：什么必须两端一致、什么允许不同。**注意（t55 · XR-06）**：**F21–F50 的真源 = iOS 组长评审链（`20`，已退役）§3 + §3-附记**；现口径已收敛到 **`docs/DEV-PLAN.md` §5.1 与本页 §6**；**F51 起**由研发 Leader 在同一附记分配（行距 = **F51**，t53 登记） |
| 3 | **`docs/SPEC.md`**（本仓规格；原跨端工作区的 iOS 规格） | §1 工程基建（含 **R1–R21** 规则表、M0-1 冻结清单、CI 门禁）、§2 组件 API、§3 主题样式交互、§4 F 登记、§8 未决与未闭合、§9 M0 开工清单与出口 | **iOS 侧收敛规格**（终审 pass）；实现细节的唯一出处。**两张 M0-1 清单的关系（t60·XR-04）**：`docs/SPEC.md` §1.4.1 = **设计给值清单（17 行）**，`android/docs/SPEC.md` §3.1.2 = **令牌 schema 冻结清单（21 行）**——粒度不同（逐键 vs 逐值+决定人）、**不冲突**；出口判据用 21 行，见 `docs/DEV-PLAN.md` §7 |
| 4 | **`docs/DEV-PLAN.md` §5.3**（C-15 定名表 37 行，已内联） | §1 **唯一表 37 行**（受控值参数名 iOS/Android/契约名） | C-15：改名与命名的唯一真源；`docs/SPEC.md` §2.10 是其只读副本 |
| 5 | **`docs/DEV-PLAN.md`**（进程骨架 / 批次 / 命令 / 冻结值 / 回写清单） | **§2** 里程碑与入口/出口判据、**§3** 批次分配、**§4** 命令与门禁、**§5** 冻结值、**§6** 回写清单、**§7** 设计待给值、**§8** 风险与未验证 | 施工顺序与"做到什么算过"；**用户 6 条决策后的最终口径** |

**冲突裁决链**（顺序未改，代号见文首约定）：`08` ＞ `07` ＞ **`02`=`docs/SPEC.md`** ＞ **`40`=`docs/DEV-PLAN.md` §5.3**（只管名字） ＞ **`30`=`docs/DEV-PLAN.md`** ＞ 本页。
**分工说明**：**用户决策/跨端裁决**（`08`/`07`）定"什么必须两端一致"；**本端规格 `docs/SPEC.md`**（`02`）定 iOS 实现形态；**命名表 `docs/DEV-PLAN.md` §5.3**（`40`）**只在命名冲突时**说话；**计划与冻结值口径 `docs/DEV-PLAN.md`**（`30`）覆盖规格旧句，但**不改规格的实现细节**。**本页与规格旧句冲突处** → 按 §8 的差异表执行（**P7–P12 已回写，截至 t55**；逐行锚点见 §8）。
**真源迁移（M0-5 起）**：契约真源迁入 `../wisdomdesign/contracts/README.md`（U/F 表 + U3 槽位词表 21 名 + 分类副表 + 组件类型名清单 37 + F 注册表 + C-15）；`docs/SPEC.md` §2.10/§4.2、`40`、`android/docs/SPEC.md` §2.10/§4.1 降为**只读副本**（先改真源，再同步副本；副本不得自行新增编号）（`docs/DEV-PLAN.md` §9）。

---

## 3. 进程骨架：入口 / 出口 / 门禁 / 关键路径（引用 `docs/DEV-PLAN.md` §0）

### 3.1 每批入口判据（I-1…I-5：全部满足才可开工）

| # | 入口判据 | 怎么验 |
| --- | --- | --- |
| **I-1** | 上一里程碑出口已判定通过（M0 → `docs/SPEC.md` §9.3 的 6 条；M1 → `docs/DEV-PLAN.md` §2.2） | 出口报告已落盘 |
| **I-2** | **批前签名冻结会通过**：该批每件组件的完整签名（含枚举 case 与默认值）+ `contracts/<component>.yaml` 的 `params`/`slots`/`default` 入库（**时点说明**：`contracts/*.yaml` 库为 **M0-5 才落库**；在此之前该判据以"批前签名冻结会登记的表单"代替） | 文件存在 + 与 C-15 逐行 0 不一致 |
| **I-3** | 该批依赖的令牌/契约已冻结（M0-1 的清单、U3 词表、C-15、F 注册表、**`schemes` 维度**） | ① **C-15**：`docs/DEV-PLAN.md` §5.3 与 `contracts/*.yaml` 的 `params[].name` **逐行比对 0 不一致**；② **U3/F 注册表**：`WDContracts.componentTypeNames()` 与 `contracts/README.md` 的类型名表集合**相等**；③ **`schemes`**：`grep -c '"schemes"' ../wisdomdesign/tokens/wisdom.tokens.json` **≥ 1**；④ 令牌溯源：`docs/SPEC.md` §9.3-5 的 `--tokens-trace` 与 `tokens.manifest.json` 的 `sha12` 相等 |
| **I-4** | 门禁在本仓可跑且为绿（`Scripts/ci.sh pr`） | 命令 exit 0 |
| **I-5** | 该批未闭合前置项都有默认执行项（无悬空项） | 台账逐行有 T/R/时点（见 `docs/DEV-PLAN.md` §8/§9） |

### 3.2 每批出口判据与门禁强度

| 批 | 出口判据 | 门禁强度 |
| --- | --- | --- |
| M2（11 件） | `docs/DEV-PLAN.md` §2.3（M2 出口）的 6 条 | PR 必过 + nightly **连续 3 日绿** |
| M3（1 件 + 封板） | `docs/DEV-PLAN.md` §2.4（M3 出口）的 6 条 | 同上 + API/ABI 基线入库 |
| M4（9 件） | `docs/DEV-PLAN.md` §2.5（M4 出口）的 7 条 | 同上 + 发布前层冒烟 |
| M5（15 件） | `docs/DEV-PLAN.md` §2.6（M5 出口）的 6 条 | PR + nightly |
| M6（1 件 + 回归发布） | `docs/DEV-PLAN.md` §2.7（M6 出口）的 7 条 | 同上 + 发布前层 + 双端 tag |

**三层门禁（跨端裁决链 `07` §6.4、`docs/SPEC.md` §1.5.2）**：**PR 必过**（≤10 min / warm ≤5 min，`Scripts/ci.sh pr`）→ **nightly**（设备编译 + 六态快照 + demo 无障碍审计 + 模拟器相对量性能）→ **发布前**（真机 hitch/首帧、归档 Thinning 增量、tag 校验）。
**批出口的统一验收方式**（跨端裁决链 `07` §6.3）：契约用例名对齐 + 六态截图 + 该批性能指标 + 无障碍断言 + `apiCheck`/符号快照绿。
**门禁日历**：每批 nightly **连续 3 日绿**才算批出口；它已计入 `docs/DEV-PLAN.md` §4 的 `+3 工作日/批`，不是"免费等待"。

### 3.3 关键路径（任一环延迟 ⇒ 全线顺延；现口径 = `docs/DEV-PLAN.md` §9）

```
M0-1 令牌冻结 → M0-2 生成器 → M0-3/4 生成物 + apiDump（apiCheck 转绿）
  → M0-5 契约 + C-15/U3/F 注册表/默认值表落库
  → [批前签名冻结] → M2（WDTextField → WDListRow）→ M3（公开 API + ABI 基线冻结）
  → M4（玻璃 + 效果配额 + E2 转门槛）→ M5（DatePicker/PullToRefresh/NavigationBar/TabBar/SegmentedControl）
  → M6（WDAssigneePicker + 无障碍回归 + 截图封板 + 发布前层 + 双端 tag v1.0.0）
```
（来源：`docs/DEV-PLAN.md` §9；批内可并行但**同一角色不得并行两个未完成任务**。）

### 3.4 人日与周数 = **参考信息**

用户决策 #1：所有开发都是 vibe coding，**不计算人力、不承诺工期**。`docs/DEV-PLAN.md` 文首的【参考信息】声明**只作参考**，**不作为排期承诺，也不作为任何出口判据**。推进只看 §3.1 入口与 §3.2 出口。

---

## 4. M0–M6 批次表与本端出口

### 4.1 M0（本端 11 条任务，`docs/SPEC.md` §9.2；出口 = §9.3 的 6 条）

| # | 任务 | 落点 | 验收命令 |
| --- | --- | --- | --- |
| I-M0-a | `Package.swift` 改造（`swiftLanguageModes: [.v6]`、去 `plugins:`、拆测试依赖、加检查器） | `Package.swift` | `xcodebuild -list`（跑通后固化 scheme） |
| I-M0-b | 结构检查器 R1–R21（注释/字符串剥离、标识符边界、豁免语法） | `Sources/wd-structure-check/`、`Scripts/check-structure.sh` | `Scripts/test-checker.sh`（各一正一反） |
| I-M0-c | 格式门禁 | `.swift-format`、`Scripts/check-format.sh` | `Scripts/check-format.sh`（排除 `generated/`） |
| I-M0-d | **M0-11 签名冒烟**（`#if WD_API_SMOKE`，只放尚未实现的声明） | `Sources/WisdomUI/APISurface/WDAPISurface.swift` | 并入 `ci.sh pr` 的 `build-for-testing` 同一次调用 |
| I-M0-e | API 冻结链路 | `Scripts/{dump-api.sh,canonicalize-api.swift}`、`api/WisdomUI.api.json` | `Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json` |
| I-M0-f | 门禁脚本与 workflow | `Scripts/ci.sh`、`.github/workflows/ci.yml` | `Scripts/ci.sh pr` 首次全绿 |
| I-M0-g | 契约读取与跨仓自证 | `Tests/WisdomUITests/Support/WDContracts.swift`、`--tokens-trace` | `sha12` 相等；manifest 缺失 = fail |
| I-M0-h | 令牌冻结的 iOS 落点（等设计仓 M0-1/M0-2 完成后同批） | `Foundation/generated/{WDTokensVersion,WDColorSlots,WDIconName}.swift`、`Foundation/Tokens/WDTokenTypes.swift` | `build.js --check` 绿 + `--tokens-trace` 绿 |
| I-M0-i | README/CONTRIBUTING/PR 模板/CODEOWNERS | `README.md`（删 `swift build/test`）、`.github/**` | **仓内正确 pathspec（t46 实测）**：`git grep -nE 'swift (build\|test)' -- . \| grep -v -- '-product wd-structure-check'` —— **实测当前命中 `README.md:51`（`swift build`）与 `:52`（`swift test`）**，M0-i 删掉这两行后应为**空**；错的写法（`-- iOS/`）实测**0 命中（假绿）** |
| I-M0-j | 版本治理 | `CHANGELOG.md`、`Examples/BaselineShell/` | 发布 checklist 可勾 |
| I-M0-k | 门禁预算测量 | `Scripts/ci.sh measure` → `README.md` + `docs/SPEC.md` §1.5.2 | 三次中位数写回；**未测不写预算** |

**M0 出口 6 条**（`docs/SPEC.md` §9.3，逐条可验）：① `check-structure.sh` + `test-checker.sh` 绿；② `check-format.sh` 绿且基线格式化提交**先于** `api/WisdomUI.api.json` 入库；③ `ci.sh pr` 首次全绿（含冒烟 + 单测 + 覆盖率报告）⇒ 闭合 `N-2/D-19/V-11`；④ `api/WisdomUI.api.json` 入库且 `git diff --exit-code` 绿；⑤ `--tokens-trace` 与跨仓 `tokens.manifest.json` 一致（`sha12` 相等）；⑥ `swift build/test` 零命中 + `Package.swift` 无 `plugins:`/无 macOS 平台/显式 `v6`。

### 4.2 M2–M6 批次（组件级唯一来源 = `docs/SPEC.md` §2.10 的"批次"列）

> **图例**：**`(C)` = 关键路径件**（历史标记写法，**原称 C 档**；**A/B/C 档位口径已废止** —— 它属**工作量/人日**口径，与用户决策 #1"不算人力"冲突，且来源已随退役文档集不可取证）。与层级 primitives/composites **无关**（**`(C)` 不是 "composites 前置"**）；**名单与完整图例见 `docs/DEV-PLAN.md` §13.1 与其 §3（`是` = 12 件）**；该批关键路径件**串行在前**（先做，**后批依赖其冻结**）。
> **⚠️ 跨端记号警告**：**本仓 `(C)` = 关键路径件**；**Android 文档 §3.2 的 `（P）`/`（C）` = 层标记**（primitives / composites）——**两端同形不同义**，引用时**必须带端别、不得互读**。

| 批 | 件数 | 组件 | 批出口要点 |
| --- | --- | --- | --- |
| **M1** | **基础设施（无组件）** | `wdFont(_:)` 单入口 + 行盒度量（`WDLineBoxTest` + 字高 fixtures）、六态截图入库（浅/深 × 默认/AX3 × LTR/RTL）、真机 `fontScale 2.0` / AX3 观感采样、**弹簧 μ=1.0 并排评审 = 设计确认关**、玻璃×配额×对比度三件套的**首轮断言**（§12 的 DF-02/03/04） | 出口 = `docs/DEV-PLAN.md` §2.2：度量 fixture 绿 + 六态基线入库 + μ 评审纪要 + §12 三件套的参数化单测骨架（**不含**真机数值结论） |
| **M2** | **11** | `WDTextField`(C)、`WDListRow`(C)、`WDButton`、`WDIconButton`、`WDSwitch`、`WDCheckbox`、`WDBadge`、`WDAvatar`、`WDDivider`、`WDCard`、`WDIcon` | 批前冻结 + PR 绿 + nightly 六态快照 + **行高 44 / Android 布局盒 48** 断言 + 冒烟退役 |
| **M3** | **1 + 封板** | `WDListSection`（第 20 件 primitive） | 公开 API 冻结（ABI/符号快照入库）+ 覆盖率转门槛 + 体积门槛值定 |
| **M4** | **9** | `WDBottomSheet`(C)、`WDAlert`(C)、`WDActionSheet`(C)、`WDToast`(C)、`WDProgressBar`、`WDProgressRing`、`WDBanner`、`WDEmptyState`、`WDSkeleton` | 玻璃档位单测 + 效果配额单测 + E2/体积转门槛 + 发布物冒烟 |
| **M5** | **15** | `WDSegmentedControl`(C)、`WDDatePicker`(C)、`WDPullToRefresh`(C)、`WDNavigationBar`(C)、`WDTabBar`(C)、`WDSearchField`、`WDRadio`、`WDSlider`、`WDStepper`、`WDChip`、`WDAvatarStack`、`WDPicker`、`WDFormRow`、`WDToolbar`、`WDFAB` | 动态字体降级（U7）+ RTL + 该批性能指标 |
| **M6** | **1 + 回归** | `WDAssigneePicker`(C) | 无障碍回归 + 截图封板 + 发布前层 + **双端 tag `v1.0.0`** |

> 计数自证：11 + 1 + 9 + 15 + 1 = **37**；与 `07` §6.3 的 3 处差异为**已批改判** G-01…G-03（`docs/DEV-PLAN.md` §3）。每批第 0 步都是**批前签名冻结**（`docs/DEV-PLAN.md` §3）。

---

## 5. 命令清单（可直接复制执行）

> 硬约束 7：门禁 = **`xcodebuild` + 模拟器**；`swift build`/`swift test` **不作门禁**（host 侧 218 错）。以下命令与 `docs/SPEC.md` §1.5.1 的 `Scripts/ci.sh` 同源；**真实耗时未回填前不得写预算**（见 §7）。

### 5.0 M0 前唯一可跑回路（**现状：现成**，不依赖任何待产出脚本）

```bash
xcodebuild -list                                   # 看 scheme/target（I-M0-a 后才有 WisdomDesign-iOS-Package）
xcodebuild build -scheme "${WD_SCHEME:-WisdomDesign-iOS-Package}" -destination 'generic/platform=iOS' \
  -derivedDataPath .build/dd -quiet                 # 设备编译（不需要模拟器，也不跑测试）
node ../wisdomdesign/tools/token-build/build.js --check   # 令牌与生成物一致（需要设计仓可读）
```

**变量准备**（**只有手工执行下面的命令才需要设**；`Scripts/ci.sh pr` **内部自解析**同样的两个值，不需要先 export）：

```bash
export WD_SCHEME="WisdomDesign-iOS-Package"   # 实测固化值（D-19 已回填）；包级聚合 scheme = <包名>-Package（`docs/SPEC.md` §1.5.1 四条纪律第 3 条）
export WD_SIM_ID="$(xcrun simctl list -j devices available | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=[(rt,x) for rt,ds in d["devices"].items() if "iOS" in rt for x in ds if x.get("isAvailable")]
c.sort(key=lambda t:(t[0], t[1]["name"]))
print(c[-1][1]["udid"])')"            # 取最新可用运行时的 UDID；禁按设备名硬编码
```

### 5.1 PR（每次提交前必跑）—— **现状：M0 后可用**（脚本由 I-M0-b/c/e/f 产出）

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

**一步版**（等价）：`Scripts/ci.sh pr`。scheme 与 destination 由脚本解析：scheme 默认 `WisdomDesign-iOS-Package`（**首次跑通后固化**，不得"取第一个 scheme"），destination **按 UDID**（`xcrun simctl list -j devices available` 取最新可用运行时），**禁止按设备名硬编码**（`docs/SPEC.md` §1.5.1 四条纪律）。

### 5.2 nightly（每批强制；连续 3 日绿才算批出口）—— **现状：M0 后可用**（`ci.sh nightly` 与快照套件由 I-M0-f/M1 交付）

```bash
xcodebuild build -scheme "$WD_SCHEME" -destination 'generic/platform=iOS' -derivedDataPath .build/dd -quiet   # 设备编译只在 nightly
xcodebuild test  -scheme "$WD_SCHEME" -destination "$WD_SIM_ID" -derivedDataPath .build/dd \
  -only-testing:WisdomUISnapshotTests        # 六态快照（普通组件 ImageRenderer；玻璃类 UIHostingController+drawHierarchy）
# demo 无障碍审计（4 类目：contrast / hitRegion / textClipped / dynamicType）—— M1 交付物，M1 前不可跑
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination "$WD_SIM_ID" -only-testing:WisdomUIDemoUITests
```

**nightly-3 性能口径**：只测**模拟器相对量**（渲染 1 次 × N 循环的 `XCTClockMetric`/`XCTMemoryMetric` → `.build/perf/{date}.json`）；**真机 hitch、首帧、归档 Thinning 增量在"发布前"层**（`docs/SPEC.md` §1.5.5）。

### 5.3 发布前—— **现状：M6 前不可跑**（要真机 + 发布链路）

```bash
# 真机：hitch（scrollDecelerationMetric）、首帧（XCTApplicationLaunchMetric）；归档体积增量
xcodebuild archive -scheme "$WD_SCHEME" -destination 'generic/platform=iOS' -archivePath .build/archive.xcarchive
git describe --tags --exact-match            # 必须 == WDTokensVersion.version（tag 只增不改）
```

### 5.4 本地开发回路（秒级，优先用）—— **现状：M0 后可用**

```bash
Scripts/check-structure.sh                  # 规则自检
Scripts/test-checker.sh                     # 检查器自身正反样本（R1–R21）
xcrun swift-format lint --strict --parallel $(git ls-files '*.swift' | grep -vE '/Foundation/[Gg]enerated/')
```

### 5.5 环境前提

| 项 | 要求 | 依据 |
| --- | --- | --- |
| Xcode | **≥ 26**（`glassEffect` 需 SDK 26；`import Accessibility` 需 iOS 17 SDK） | `docs/SPEC.md` §1.2/§1.6 |
| 部署目标 | `platforms: [.iOS(.v17)]`；**不加 macOS** | `Package.swift`、`docs/SPEC.md` §1.2 |
| 语言模式 | `swift-tools-version: 6.1` + **Swift 6 语言模式**（严格并发） | `docs/SPEC.md` §1.2.1 |
| 运行时依赖 | iOS 构建/门禁只需 `python3`（`ci.sh` 解析模拟器 UDID）；**Node 不是 iOS 依赖**——只有跨仓跑令牌生成器（`node ../wisdomdesign/tools/token-build/build.js`，设计仓工具）时才需要它 | `docs/SPEC.md` §1.5.1/§1.6 |
| 第三方依赖 | **零**（格式/快照/测试都用工具链自带：`swift-format`、`ImageRenderer`、`import Testing`） | `docs/SPEC.md` §1.2 |
| 预览 | `#Preview` + `#if WD_PREVIEWS`（SwiftPM `.define`，**不是 `#if DEBUG`**）；**`Material`/`glassEffect` 在预览里不等于真机** | `docs/SPEC.md` §1.6 |

---

## 6. 冻结值清单（**最终值**；用户 6 条决策后口径，不要再"讨论"）

> 以下值已冻结：改它们 = 改 U 项或硬约束 ⇒ 走 `docs/DEV-PLAN.md` §9 的真源流程（先改 `contracts/README.md`，再同步两端副本）。**每一行都给来源。**

| # | 项 | 最终值 | 来源 |
| --- | --- | --- | --- |
| F-01 | **行高（密度档）** | `size.row-height.{comfortable,compact}` = **60 / 44**，**单值键、两端同值**（用户决策 #2，案 B）；iOS 侧规格已按 **P11** 回写（`docs/SPEC.md` §1.4.1-#3） | `docs/DEV-PLAN.md` §5.1（行高）+ §6（回写项 P11） |
| F-02 | **Android 行布局盒** | **48 = 44 可见内容 + 上下各 2dp 透明内边距**；热区 = 布局盒 = 48；**不覆盖相邻行**；Android 纵向节奏比 iOS 疏 4dp（已接受代价） | `docs/DEV-PLAN.md` §5.1；**行距差异 = F51**（登记处 = iOS 组长评审链 `20` §3-附记，t53） |
| F-03 | **U/F 两条必须同时存在** | **U（必须统一）= 两端可见内容高度 44 ± 0.5**；**F（各端自由）= 行距 Android 48 / iOS 44（= F51）** | `docs/DEV-PLAN.md` §5.1 + §6；F51 = iOS 组长评审链 `20` §3-附记 |
| F-04 | **语义色槽位数** | **32 槽位**（新增 `text.disabled`；用户决策 #3）⇒ `WDColorSlot`/`WDColorOverrides` 与两端计数断言同步 | `docs/DEV-PLAN.md` §5.1 + §6 |
| F-05 | **主题 scheme 维度** | 令牌 schema 一次含 `schemes: {light, dark, …}`；生成器多套输出 + `--schemes`；**运行时换已生成的 scheme**（iOS `wdTheme` 环境键）；值变更触发重组/重算、**不重启进程**；**不支持**运行时任意 `token.json` / 服务端下发 / **逐槽位任意覆盖**；`staticCompositionLocalOf` 变化 = 整树重组 ⇒ **切换不得进高频路径** | `docs/DEV-PLAN.md` §5.1（用户决策 #8，层一） |
|  | ↳ **F-05 断言** | `grep -c '"schemes"' ../wisdomdesign/tokens/wisdom.tokens.json` **≥ 1** | 可跑（M0-1 变更集） |
| F-06 | **弹簧 canonical** | `response`(秒) + `dampingRatio`(ζ) 为真源；`stiffness = μ·(2π/response)²`，**μ = 1.0**；**禁 `massFactor`**；iOS 直接 `Animation.spring(response:dampingFraction:)`，**iOS 产物不生成 `stiffness`** | 用户决策链 `08` §2-3、`docs/DEV-PLAN.md` §5.1 |
| F-07 | **图标** | 契约只统一 **44 条语义名 + `mirrorsInRTL`**；iOS **按名取 SF Symbols**（自带镜像元数据）；Android 调用方注入 `ImageVector`；**库内零图标资源** | 用户决策链 `08` §2-4、`docs/DEV-PLAN.md` §5.1 |
| F-08 | **文案（L-B）** | 库内**零资源 + 零文案**：读屏标签由调用方传入；库只提供**结构拼接原语**（`WDSemantics.join/positional`，**零标点、零语序**）；`WDIconButton.accessibilityLabel` 与 `WDTextField.label` 等**必填** | 用户决策链 `08` §2-5、`docs/SPEC.md` §2.6.2 |
| F-09 | **触控双键** | `size.touch-target-min-{ios,android}` = **44 / 48**；每端只生成本端常量；**不留过渡键** | 用户决策链 `08` §2-2/U8、`docs/SPEC.md` §1.4.1-#9 |
| F-10 | **单发布 target** | `products` 只有 `WisdomUI`；`WisdomUIPreviews` **不进 products**；`Internal/` 零 `public` | `docs/SPEC.md` §1.2/§1.1 |
| F-11 | **令牌其它已冻结值** | 字段盒高 `46`（默认档）；字段最小宽 `190`；sheet detent `0.5`/`0.92`；sheet 最大宽 `480`；`letterSpacing` 单位 **pt/sp 等价**（`overline = 0.6`，其余 0）；`motion.duration.reduced` **150ms**（若设计给 160ms 以回写为准） | `docs/SPEC.md` §1.4.1 |
| F-12 | **交互状态优先级（U6）** | `disabled > loading > pressed > focused > hover > default`；三条派生：disabled 吞输入 / loading 忽略 `action` 但系统 `isEnabled` 环境值仍为 true 且留在无障碍树 / focused·hover 是叠加维度 | 跨端裁决链 `07` §1.2-U6、`docs/SPEC.md` §2.6.1 |
| F-13 | **行盒语义（U5）** | `renderedLineBox = max(设计盒高×缩放, natural(script))`；默认档 `abs(rendered − max(设计, natural)) ≤ 0.5pt`；放大档 `≥ ⌈natural×行数⌉`（不裁切）；**禁** `Mode.Fixed`/`lineHeightMultiple` | `docs/DEV-PLAN.md` §5.1、`docs/SPEC.md` §2.6.3 |
| F-14 | **组件命名与受控值名** | `WD` 前缀（唯一真源 `../wisdomdesign/docs/04-architecture.md:57`）；受控值参数名以 **C-15**（`docs/DEV-PLAN.md` §5.3）为准（例：`WDCheckbox.isChecked`、`WDSwitch.isOn`、`WDTextField.text`） | `docs/SPEC.md` §1.3、`docs/DEV-PLAN.md` §5.3 |
|  | ↳ **F-14 断言** | `40` §1 唯一表与 `contracts/*.yaml` 的 `params[].name` **逐行比对 0 不一致** | 可跑（M0-5 落库后） |
| F-15 | **37 组件槽位词表** | **21 名**（`content/header/footer/leadingIcon/trailingIcon/leading/trailing/title/message/actions/items/label/icon/prefix/accessory/helper/subtitle/valueText/options/placeholder/control`）；无槽位必须写"无" | `docs/SPEC.md` §2.10 |
|  | ↳ **F-15 断言** | `WDContracts.componentTypeNames()` 与 `contracts/README.md` 的类型名表集合**相等**（U3/F 注册表口径） | 可跑（M0-5 落库后） |
| F-16 | **弹层形态** | iOS = `.wdSheet(...)` / `.wdAlert(...)` / `.wdActionSheet(...)` / `.wdToast(...)` **修饰符挂在锚点视图**（不是"什么都不渲染的 View"）；`onDismissAttempt` **不存在**（F29） | `docs/SPEC.md` §2.5 |
| F-17 | **门禁命令** | `xcodebuild` + 模拟器；`swift build`/`swift test` 不作门禁；iOS 门禁命令与 README 一致 | 用户决策链 `08` §2-7 |
| F-18 | **分发与版本** | SPM tag **只增不改**（打错发 `v1.0.1` 并在 CHANGELOG 标注废弃版本）；三层版本（令牌 / 契约 / 库） | 用户决策链 `08` §2、`docs/DEV-PLAN.md` §10 |
| F-19 | **弹层档位类型名（t60·C11）** | 公开类型名必须写全 **`WDBottomSheetDetent` / `WDBottomSheetDetents`**（家族两件，含 `WDBottomSheet` / `WDActionSheet` 的档位参数）；**不得出现 `WDSheet*`** | `docs/SPEC.md` §1.4.1 / §2.5；`docs/DEV-PLAN.md` §5.3 |
| F-20 | **枚举 case 规则（t60·C12）** | 枚举一律 `String` 原始值 + `CaseIterable` + `Sendable`；**新增 case 属源级 breaking**（minor + Breaking 段 + 迁移片段）；**`@frozen` 一律不加**（加了就不能新增 case） | `docs/SPEC.md` §2.9/§2.11；用户决策链 `08` §2 |
| F-21 | **目录大小写差异（t60·C12）** | iOS 用 `Components/Primitives`+`Composites`、Android 用 `components/…`（大小写不同）**是已登记差异**（U2 / DIR-1），**不得为"对齐"改名** | 跨端裁决链 `07` §1-U2、`docs/DEV-PLAN.md` §9 |

### 6.1 设计侧待给值 / 待签发（**M0-1；iOS 相关入口**，t60·F-01）

> **唯一登记处 = `docs/DEV-PLAN.md` §7**（本仓计划的设计待给值节；原跨端计划的对应节随工作区退役）。**原 16 项清单正文不在本页复制**，本端相关的 7 行即下表；逐项依据见 `docs/DEV-PLAN.md` §7。本表只收**影响 iOS** 的条目，每行给「**默认执行项 + 责任 + 时点**」——**默认执行项先冻结，不得自定值**（`docs/DEV-PLAN.md` §7「清单不缩表」）。若该节尚未出现，则本表即当前唯一入口，须报船长。

| # | 待给值 / 待签发项（iOS 面） | **默认执行项（先冻结）** | 责任 | 时点 | 细则 |
| --- | --- | --- | --- | --- | --- |
| D-1 | 玻璃档位 × 文字可用（DF-02） | 按 §12.1 的矩阵与四条规则编码进 `WDGlass.resolve`；`tinted`/`sheen` 不作文字载体 | 设计（签发）+ ios-lead（实现） | **M0-1** | §12.1 |
| D-2 | 效果配额 7 条（DF-03） | 按 §12.2 的 7 条硬上限 + 违反即降级；"模糊面可数"进 nightly | 设计（勾选）+ ios-lead | **M0-1 冻结、M4 首次真机验证** | §12.2 |
| D-3 | 对比度门槛 4.5:1 / 3:1（DF-04） | 按 §12.3 的 5 行门槛 + **最不利取色**（玻璃取最暗/最亮合成色） | 设计 + ios-lead | **M0-1** | §12.3 |
| D-4 | **iOS 17–25 玻璃降级口径（DF-10）** | **默认 = 纯色降级**（**不做模糊、不用系统 `Material` 模糊**，保留 hairline）；该区间 `WDGlassResolution` **只返回 `opaque`**；**待设计裁决** | 设计（裁决）+ ios-lead（实现） | **M0 D1** | ARCH §6 |
| D-5 | `motion.duration.reduced`（DF-14） | **默认 = 设计稿 150ms**（备选 160ms 不采用，**待设计裁决**） | 设计 | **M0-1** | `docs/SPEC.md` §1.4.1-#6 |
| D-6 | sheet 面板圆角 32（DF-15） | **默认 = 32**（与 Android 同名档位；iOS 用 `.continuous`） | 设计 + ios-lead | M0-1 | `docs/SPEC.md` §1.4.1-#10 |
| D-7 | 其余设计值项（圆角/间距/字号阶梯、同心圆角、平台补偿、图标尺寸阶梯、状态第二信号…） | **不自行补**：按 `63` §4 逐项等设计给值；实现只用已进令牌的值 | 设计 | 逐项（见 `docs/DEV-PLAN.md` §7） | 设计侧核对链 `63` 的 DF-05/06/17/18 行 |

---

## 7. 【未验证】清单 —— **一律不得写成"已通过"**

> 纪律（`docs/SPEC.md` §8.2 / `docs/DEV-PLAN.md` §8）：未跑通/未实测的项，只能写**「未验证」**并进出口报告，**不得在代码注释、README、CHANGELOG、PR 描述或出口报告里写成"已通过"**。回填后才允许改成结论。

| # | 未验证项 | 谁回填 | 时点 | 阻塞什么 |
| --- | --- | --- | --- | --- |
| U-01 | **`xcodebuild` 全链路**：scheme 名、PR-0/PR-1/PR-2 真实耗时、覆盖率报告 —— **2026-10-06 部分回填** | ios-lead | **M0 出口前** | M0 出口③④；M2 起无 PR 门禁。**2026-10-07 全部回填（本项闭合）**：scheme = `WisdomDesign-iOS-Package`、`ci.sh pr` 首次全绿、覆盖率报告已产出，三态耗时中位数 = **warm 7.98 / clean 14.46 / cold 58.88 s**（n=3） |
| U-02 | **M0-11 签名冒烟的首次 CI 级实跑**（`swiftc` 级验证 ≠ CI 级验证）—— **2026-10-06 已回填** | ios-lead | M0 出口前 | M0 出口③；实测 = `ci.sh pr` 的 PR-1a 带 `WD_API_SMOKE` 编译通过、PR-1b `passed=6 failed=0`（2026-10-07 复核） |
| U-03 | **字体自然行高 iOS 侧实测**（N-7：SF 1.178em / PingFang 1.400em 是组长在 macOS 侧的测量，非 iOS 结论） | ios-dev | **M1 出口前** | M1 fixture 与行盒断言 |
| U-04 | **AX3 ≈ 175% 的真机/模拟器 `UIFontMetrics` 实测**（N-1，12 档 × 12 字阶） | ios-dev | M1 出口前 | U5 验收档与 `DynamicTypeFixture` |
| U-05 | 真机 fontScale 2.0 观感、缩放手感（V1） | 两端 | M1 出口 | U7 上界验收 |
| U-06 | 快照渲染器/金标设备矩阵、demo 无障碍审计（nightly 项） | 两端 + tech-lead | M1 前 | nightly 门禁可用性 |
| U-07 | 三枚举（`WDCardStyle`/`WDToastVariant`/`WDBannerVariant`）与 `WDCheckbox.isChecked` 改名的 **CI 级编译验证** | ios-dev | M0/M2 交界 | M2 首批签名冻结 |
| U-08 | SPM `Package.resolved` pin 后"移动 tag"的失败模式（政策无条件成立，失败模式待实测） | ios-lead | M6 发布前 | 发布纪律的自证 |
| U-09 | **归档体积增量与体积门槛值**（`docs/SPEC.md` 的 E3-iOS-a/b；M3 出口"体积门槛值定"目前只是待定项） | ios-lead | **M3 出口** | 发布前层的体积断言（`xcodebuild archive` + Thinning 增量） |

**§7 的取值纪律（t60·F-01 ②）**：设计值未到位时，**按 §6.1 的默认执行项冻结，不得自定值**；表里没有的项 = 尚未给值，**不得**用"实现方便"的值顶上。

**写"未验证"的正确句式**：`【未验证】<项>：本轮未跑通（原因），按 `docs/SPEC.md` §8.2 记未验证；回填责任 = <角色>，时点 = <里程碑>`。

---

## 8. 与规格文本的差异（**已回写，截至 t55**）

> 口径来源统一 = **`docs/DEV-PLAN.md` §5/§6**；`docs/SPEC.md` / `android/docs/SPEC.md` / 设计仓 `09-layout.md` 的对应条目按 `docs/DEV-PLAN.md` §6 的回写清单（P7–P12）同步。**本表按 t55 实测收敛为"已回写"，每行给锚点**（跨端工作区文档集的交叉复核 **XR-02** 要求）；仍开放的行**必须带时间点与责任人**，不得再出现"看起来在做、实际已完成"的状态失真。
> **用法**：**只认下表的"最终值"列**；§8.3 的 ci/结构门禁不依赖规格文字。**历史行保留**（如 D-06 的 t46 一次性授权），但一律带时间点。
> **回写纪律（`docs/DEV-PLAN.md` §6 · XR-12）**：任何规格回写必须**先在 `docs/DEV-PLAN.md` **§6** 登记为 P 项（文件:行号 + owner + 时点）再执行**，执行者不得顺手改登记外口径；本轮 P11 即按此顺序执行。

| # | 位置 | 规格现状（回写前） | **最终值（只认这个）** | 回写项（P7–P9 / P10） |
| --- | --- | --- | --- | --- |
| D-01 | `docs/SPEC.md` §1.4.1 表第 3 行（行高） | 双键 `size.row-height.{comfortable,compact}-{ios,android}`；Android 按 D1 双键（48） | **单值键** `size.row-height.{comfortable,compact}` = **60 / 44（两端同值）**；**Android 的 48 是"行布局盒"= 44 可见内容 + 上下各 2dp 透明内边距**（热区 = 布局盒，不覆盖相邻行）；**不是行高键、不是第三种尺寸** | **已回写（t55 · P11）**：`docs/SPEC.md` §1.4.1-#3 = **单值键 `size.row-height.{comfortable,compact}` = 60/44** + “Android 的 48 是布局盒、不新增令牌键”（授权 = `docs/DEV-PLAN.md` §6 **P11** `:479`，t53 登记） |
| D-02 | `docs/SPEC.md` §1.4.1 表第 17 行（disabled） | "二选一"：(1) 新增 `text.disabled` 色槽 ⇒ U12 = 32 / (2) 维持 40% opacity + 豁免 | **已定 (1)**：新增 `text.disabled` ⇒ **U12 = 32 槽位**；两端计数断言与 M0-1 清单同步 | **iOS 侧已回写（t43）**：`docs/SPEC.md` §1.4.1-#17 = 已决 (a) ⇒ **U12 = 32 槽位**（槽位计数与代码块注释同批改）；`android/docs/SPEC.md` 侧 = P8（android-lead，状态以 android 侧文档为准） |
| D-03 | 本端规格与 Android 规格全文（scheme） | **缺** `schemes` 维度条目（`grep 'schemes:'` 0 命中） | 令牌 schema 含 **`schemes: {light, dark, …}`**；生成器多套输出 + `--schemes`；**运行时换已生成的 scheme**（iOS `wdTheme` 环境键）、值变更触发重组/重算、**不重启进程**、**不进高频路径**；**不支持**运行时任意 `token.json` / 服务端下发 | **iOS 侧已回写（t43）**：`docs/SPEC.md` §3.2 的 P9 落地条目 **`:1021-1023`** + 尾部回写记录（`:1506`）；**Android 侧已回写**（`android/docs/SPEC.md:1314`、`:1320-1321`，见跨端工作区文档集的交叉复核 §P9 行）；指向 `docs/DEV-PLAN.md` §5.1/§5.2 |
| D-04 | `../wisdomdesign/docs/09-layout.md:101` | "compact 下…**行高 44 时热区就是整行**" | "**整行 = 48 布局盒（可见 44 + 上下各 2dp 透明内边距）**；热区 = 该布局盒、不覆盖相邻行；**可见内容两端一致 44**" | **P10 待回写（设计侧）**：`09-layout.md:101` 尚未改（**本轮 t55 不核，设计稿非本端范围**）；落地前以本表"最终值"列为准 |
| D-05 | `android/docs/SPEC.md` §2.3/§3.1.2/§3.3.1（`:41/:674/:678/:680/:1285/:1329/:1390/:1503/:1947/:2025`） | Android `compact = 48`；"行高即热区" | `android/docs/SPEC.md` 原 `compact = 48` → **已是"可见内容 44 + 布局盒 48"**；AR-67 断言 `(compact,1)==48±0.5`/`(compact,2)==76±0.5` **原样成立**（"行高"= 布局盒）；**新增**"可见内容高度 == 44 ± 0.5"断言 | **P7（android-lead）**：Android 侧状态以 `android/docs/SPEC.md` 为准（**t55 不核**）；iOS 侧无对应改动（`docs/SPEC.md` 的行高键形已由 **P11** 覆盖） |
| D-06 | `docs/SPEC.md` **§6.1-7** 与 **§9.3-6**（本源） | 两处写 `git grep -nE "swift (build\|test)" -- iOS/ \| grep -v wd-structure-check`（在 `iOS/` 仓内 `-- iOS/` 是错的 pathspec） | 仓内正确形式 = `git grep -nE 'swift (build\|test)' -- . \| grep -v -- 'product wd-structure-check'` | **已回写（t53 · P12；早前 t46 已改 `docs/SPEC.md` 四处）**：`docs/SPEC.md` §6.1-7、§9.2-I-M0-i、§9.3-6、I45 行均为 `-- .` + `-product wd-structure-check`（t46 实测：命中 `README.md:51-52`）。**注**：t46 直改属**船长一次性授权、不构成先例**（`docs/DEV-PLAN.md` §6 · XR-12） |

**两条登记必须同时存在**（少一条就会出现"到底统一什么"的第三种解读）：**U 系列 = 两端可见内容高度 44 ± 0.5**；**F 系列 = 行距 Android 48 / iOS 44**（`docs/DEV-PLAN.md` §6-P7）。
**发现新的旧写法**：不要自行改规格（跨仓只读）——在 PR 描述里登记并 @ios-lead，由计划侧走 `docs/DEV-PLAN.md` §9 的真源流程。

---

## 9. 提交 / 分支 / PR / 版本治理

**提交信息 = Conventional Commits（强制）**

```
<type>(<scope>): <summary>
type  ∈ {feat, fix, perf, refactor, style, test, build, ci, docs, chore}
scope ∈ {foundation, tokens, typography, theme, motion, material, a11y, icons, internal,
         previews, ci, docs, examples, primitives/<Component>, composites/<Component>}
```

**三条 iOS 特有提交纪律**（`docs/SPEC.md` §1.4）：
1. **纯移动与语义变化拆两个提交**（第一个只搬迁，`api/WisdomUI.api.json` 规范化后应零差异；第二个做语义变化）；
2. **`api/WisdomUI.api.json` 与成因同提交**（符号快照不得跨提交漂移）；
3. **令牌变更集**：一次令牌改动 = 一个跨仓变更集，提交信息携带同一标识（`tokens: v1.0.0-rc.1`），三仓可 `grep` 对齐。

**分支与合并**：`main` 受保护（禁直推、禁 force-push）；短命分支 `feat/wdbutton`、`tokens/v1.0.0-rc.1` 等，生命周期 ≤5 天；**跨层移动/API 冻结类 PR 用 rebase-merge 保留两个提交**，其余 squash-merge（提交信息取 PR 标题）。

**PR 模板自检（必须逐项勾）**：变更类型（纯移动/语义变化）/ 跨端边界（是否触及 U 系列；触及 F 系列须在 `contracts/README.md` 两端形态表登记）/ 反模式自检 3 条 / L-B 自检 / 门禁自检（§5 的命令）/ 契约与无障碍（`acceptance.yaml` + `preview-cases.yaml`）/ 证据。
**评审**：≥1 名 reviewer；触及 `Foundation/`、公开签名、`Package.swift`、`api/*` 时需 `ios-lead`；**触及 U 系列必须同时有 android-lead + tech-lead 确认**。

**版本治理**：三层版本（令牌数据 / 契约 / 库）；**SPM tag 只增不改**（打错发 `v1.0.1` 并在 `CHANGELOG.md` 标注废弃版本号）；发布顺序 = **设计仓冻结并打 tag → 生成 → 两端提交（含符号快照）→ 两端跑绿 → 发布前层 → 双端同 tag `v1.0.0`**（平台 tag 永远在最后）。
**兼容性判定**（`docs/SPEC.md` §2.9）：追加带默认值的公开 `init` 参数 = 源码兼容但**破坏符号快照连续性**（需显式基线更新 + CHANGELOG）；**改已有参数的类型/标签 = 源级 breaking**；新增枚举 case = 源级 breaking（minor 发布 + Breaking 段 + 迁移片段）；改名/删除 = major；**默认值变化不改 ABI/符号快照 ⇒ 只能靠 `contracts/*.yaml` 断言发现**。

---

## 10. 反模式与禁止事项

**三条跨端反模式禁则**（跨端裁决链 `07` §1.4）：① 不得为对称给 iOS 加 `enabled:` 参数（双真源）；② 不得为对称让 Compose 的 `Modifier` 读主题（Android 侧）；③ 不得为对称给 iOS 造 Saver 等价物、给 Android 造 `EnvironmentKey` 主题。

**本仓硬禁（检查器 R1–R21 会拦，见 `docs/SPEC.md` §1.1.2）**：

| 禁止 | 规则/理由 |
| --- | --- |
| `AnyView`（公开 API 与 `Foundation/`/`Components/` 实现） | R13a；类型擦除破坏 diff 与性能 |
| `static var` **存储型**静态可变状态 | R13a；Swift 6 下本就报错；计算型工厂（`extension ButtonStyle where Self == …`）例外（R13b） |
| `Components/**` 里 `import UIKit` | R14；UIKit 只允许出现在 `Foundation/Typography/` 与 `Internal/` |
| `.frame(height:/width:)` 绑令牌常量 | R9；动态字体必须靠 `minHeight` 增长 |
| `Components/**` 里的静态令牌入口（`WDColor.*`/`WDType.*`） | R10；必须走 `@Environment(\.wdColors)` |
| `.font(.system(` / `Font.system(` / `.font(WDType.` | R11；唯一入口 `wdFont(_:)` |
| 组件里写 Environment（`.environment(`、`\.wdDensity =`、`\.wdEffectsBudget =`） | R18；写入口只在 `Foundation/Theme/WDEnvironment.swift` 的修饰符 |
| 覆写平台设置（`.preferredColorScheme`、`.environment(\.dynamicTypeSize…)` 出现在库内） | R16；库不覆写系统无障碍设置（预览/测试/demo 例外） |
| 数值字面量（除白名单） | R7；必须可追溯到令牌（色值/字号/尺寸/时长） |
| 库内文案/标点/语序模板；`Resources/`；asset catalog；字体文件 | R15 + 硬约束 5（L-B） |
| `GeometryReader` 包内容；`minimumScaleFactor`；`Mode.Fixed`/`lineHeightMultiple`；自造 `DragGesture(minimumDistance: 0)`；`matchedGeometryEffect` 作库功能；`withAnimation` 包整 body；无 value 的 `.animation(_:)`；组件自建计时器 | `docs/SPEC.md` §2.7/§2.8/§3.4/§3.5 |
| 原地给公开 `init` 追加带默认值的参数（不经基线更新流程） | `docs/SPEC.md` §2.9 规则 1 |
| 手改 `Foundation/generated/**`；创建 `Resources/`；创建 `Components/Patterns/` | R12/R4 + 硬约束 5 |
| 跨仓写入（`../android/**`、`../wisdomdesign/**`） | 跨仓一致性靠变更集，不靠手改 |

**允许例外的方式**：检查器豁免必须**同行给理由**（`// wd-structure-check:disable R1 — 理由`），且 reviewer 按"豁免必须有理由"审；**不要**通过放宽规则或改规格文本来绕过。

> **文档类改动**：先过 `docs/DEV-PLAN.md` **§4.6** 的**六个固定项**与两条纪律（**结构自检** / **禁止自命中** / **双跑**）——命令、根因实例与两种写法都在那一节；本页只留这一行指针（AGENTS 受自动加载预算约束）。

---

## 11. 卡住时的升级路径

**先问自己三句**（`docs/DEV-PLAN.md` §9 的真源流程）：

1. 这件事是否**触及 U 系列**（名字/取值/默认值/行盒/状态优先级/触控数值/无障碍行为/玻璃档位/动效令牌/生成物溯源）？
   → 是：**不能自行决定**；先改 `contracts/README.md` 真源（M0-5 后），再同步两端副本；需要 android-lead + tech-lead 确认。
2. 是否要**改契约或规格文本**？
   → 是：本仓只读跨仓文档；在 PR 描述登记 + `@ios-lead`，由计划侧走 `docs/DEV-PLAN.md` §6 的回写清单。
3. 是否落在 **§7 的【未验证】清单**里？
   → 是：先按"未验证"记录，找对应责任角色回填，**不得写成已通过**。

**找人**：

| 事项 | 找谁 |
| --- | --- |
| 本仓实现细节、签名、批次开工/结批 | `ios-lead` |
| 契约/F 注册表/U3 词表/生成器/token manifest | 架构师（**尚未点名到人**，见下） |
| 令牌取值、图标语义名、设计确认 | 设计（**尚未点名到人**） |
| 出口验收、门槛值、发布 checklist | `tech-lead`（研发 Leader） |
| 拍板类（工期/人力已废弃；剩余为外部角色点名） | 船长 / 用户 |

> ⚠️ **唯一未决项**（`docs/DEV-PLAN.md` §9「跨端依赖」）：**架构师与设计需要点名到人**；不点名 ⇒ M0 出口 ②③④ 与 M2 批前签名冻结顺延。在此之前，涉及这两位的输入一律按规格已给的**默认执行项**推进，并在 PR 里登记。

---

## 12. 设计规则补录（**DF-02 / DF-03 / DF-04**；来源 = `63` §3，t57）

> **为什么有这一节**：设计侧仓内文档核对链（`63`，已退役）的结论是"数值全对、**条文缺席**"——玻璃档位、效果配额、对比度门槛三件在 iOS 侧只有零散指代。本节把设计侧**可核对的条文**补进来（数值不重复登记，见 `63` §5 正面清单）。
> **引用纪律**：引他文件只用**章节号 / 条目号 + `grep` 锚点**（如 `grep -n '^### 5\.2' 06-accessibility.md`），**不抄行号**（行号会漂移）。
> **冲突裁决**：与 `docs/SPEC.md` 冲突处**以 `docs/SPEC.md` 为准并在此注明**。已知一处：`docs/SPEC.md` **F47** 定 `WDGlassLevel` 六档只是 `WDGlass.resolve` 的**额外输入**，canonical 输入集合（`textLevel` + `appearance` + `capabilities` + `effectsBudget`）与输出语义 `{opaque, glass, glassStrong}` **不变** ⇒ 本节矩阵是**规则内容**，不改签名。

### 12.1 DF-02 玻璃档位体系 × "玻璃上能放什么文字"（矩阵，可核对）

**设计真源**：`wisdomdesign/docs/01-foundation.md` §7.2（六档：`ultraThin 14/.38`、`thin 22/.54`、`regular 30/.70`、`thick 44/.86`、`tinted 30+品牌染色 24–30%`、`sheen 3800ms`）+ `12-b22-glass.md` §3（两档逐位相等）+ §4（推导）+ §7（深色 Tab 栏裁定）+ `06-accessibility.md` §5.2（四条规则）。**iOS 实现面**：`docs/SPEC.md` §3.2 的 `WDGlass.resolve` / `WDAppearance` / `WDGlassResolution`。

| 设计档位（`material.*`） | 语义档 | 允许的文字级别（**最不利**口径实算） |
| --- | --- | --- |
| `ultraThin` / `thin` | 不映射到语义档（表头 / 输入浮层 / 导航·Tab·工具条的**视觉材料**） | 见下"消费层两档"——iOS 侧落到 `glass` / `glassStrong` 两个结果 |
| `regular` | **`surface.glass` ≡ `material.regular`**（生成期断言，`12-b22` §3） | **浅色：仅 `text.primary`**；**深色：零字阶都不上** |
| `thick` | **`surface.glass-strong` ≡ `material.thick`**（生成期断言） | 浅色：`primary` / `secondary` / `tertiary` 全可用；**深色：仅 `text.primary`** |
| `tinted` | **强调容器 / 选中态容器**（不是玻璃文字载体） | **不作为文字载体**（品牌染色 24–30% 会改对比度账目） |
| `sheen` | **装饰**（动态高光，3800ms） | **不作为文字载体**；每屏 ≤1（见 §12.2） |

**四条硬规则**（照抄 `06-accessibility.md` §5.2，iOS 侧必须编码进 `WDGlass.resolve`）：
1. **浅色端** `surface.glass` **只放 `text.primary`**；`secondary` / `tertiary` 必须改用 `glass-strong`，否则**不上玻璃**；
2. **深色端任何字阶都不上 `surface.glass`**；`glass-strong` **只放 `text.primary`**；
3. **悬浮 Tab 栏用 `glass-strong`**；**深色端 Tab 栏改用不透明表面**（`surface.card-solid` + 顶部高光 + 外圈细线）——`12-b22` §7 方案 A，且**顺带省一次模糊**（与 §12.2 第 1 条互相依赖）；
4. **语义色（`status.*`）不上玻璃** —— 只在软底或实底上使用。
   （附则：下方是照片或高饱和内容时，文字下垫 25% `surface.card-solid`。）

**iOS 落地与验收**：`WDGlass.resolve(textLevel:appearance:capabilities:budget:)` 的 `textLevel` 即"能放什么字"的载体（`docs/SPEC.md` §3.2）；单测矩阵 = **档位 × `appearance` × `textLevel` → 断言 `opaque` / `glass` / `glassStrong`**，其中两条**必须红**的用例：① 深色 + `glass` + **任意** `textLevel` ⇒ 不得返回 `glass`；② 浅色 + `glass` + `secondary`/`tertiary` ⇒ 不得返回 `glass`。`tinted` / `sheen` 在 iOS 侧等价于"**不参与玻璃文字**"（可作容器/装饰，但文字按实底或 `glass-strong` 处理）。

### 12.2 DF-03 效果配额 **7 条硬上限**（此前 iOS 侧只登记 1 条）

**设计/讨论真源**：跨端工作区文档集的性能讨论稿（`03-perf-release`，已退役）§1.2（7 条配额表）+ 设计仓 `06-accessibility.md` 的降级行；**iOS 载体**：`WDEffectsBudget`（`docs/SPEC.md` §2.7/R18：组件**只读** `wdEffectsBudget`，写入口只在 `Foundation/Theme/WDEnvironment.swift`）。

| # | 效果 | **硬上限** | 违反时怎么办（iOS 可执行动作） |
| --- | --- | --- | --- |
| 1 | **玻璃（模糊）** | **同屏 ≤1 个模糊面；列表项内 0**；深色 Tab 栏直接不透明（省一次模糊） | 超预算 ⇒ 渲染 `WDGlassResolution.opaque`（**不得**"多叠一层玻璃"）；`wdEffectsBudget` **只能降不能升**（R18）；nightly 断言"同屏模糊面数量**可数**" |
| 2 | **色晕 `wash`（3 段径向）** | **每屏 1 处；禁止动画**；实现必须是"**一次绘制画 3 段 radial brush**" | 不得用 3 个全屏 `Box/View` 各自 `background`；违反即改一次性绘制，否则断言失败 |
| 3 | **高光扫过 `material.sheen`** | **每屏 ≤1**，仅"强调卡片"；离屏/后台**必须停**；Reduce Motion ⇒ 静态 | 停止动画（不是降速）；`WDMotion` 包装，**禁止** `withAnimation` 包整 body（`docs/SPEC.md` §3.5） |
| 4 | **骨架微光 `skeleton-shimmer`** | **同屏 ≤6**；超出用**静态灰块**；只在加载态 | 第 7 个起静态（M4 出口已有该单测，本表把它**补齐成 7 条之一**） |
| 5 | **阴影 `elevation.*`** | 列表项 `e0`/`e1`；**`e3` 每屏 ≤1** | 降档；iOS 双层阴影 = 2 次 shadow pass，不得为了"更立体"叠 `e2/e3` |
| 6 | **进度环 / 下拉环旋转** | **每屏 ≤1 个动画环** | 其余环静态或去动画；Reduce Motion ⇒ 静态环 |
| 7 | **触觉** | **同一次操作 1 次**（节流） | 用统一节流（与 `WDAnnouncementThrottle` 同思路）；超频断言失败 |

**验收**：M4 出口"效果配额单测"从 1 条扩为**上表 7 条各自的计数/降级断言**；跨端工作区文档集的性能讨论稿 §1.2 末尾要求"**同屏模糊面数量可数**"⇒ iOS 侧以 `wdEffectsBudget` + 计数器实现（**不得**只在文档里承诺）。

### 12.3 DF-04 无障碍**硬门槛**：4.5:1 / 3:1 + "最不利"口径

**设计真源**：`wisdomdesign/docs/06-accessibility.md` §5.1（验收表）+ §5.2 规则 6（最不利）+ `12-b22-glass.md` §4（玻璃实算）；**iOS 条款**：`docs/SPEC.md` §3.2（高对比度 ⇒ 玻璃不透明）+ §3.6（无障碍）+ O-9 裁决。

| 内容 | **下限（硬）** | 备注 |
| --- | --- | --- |
| 正文（< 18.66pt 粗体 / < 24pt） | **4.5:1** | 浅色 canvas 上 `text.primary` 16.3:1 / `secondary` 7.1:1 / `tertiary` 6.0:1（色晕最暗处 5.5:1） |
| 大字号（≥ 18.66pt 粗体） | **3:1** | — |
| 图形、图标、控件边界 | **3:1** | 填充与轨道 |
| 禁用态 | **不适用**（可辨识即可） | **40% 不透明度**（`docs/SPEC.md` §2.6.1 的 `state.disabled.alpha`） |
| 焦点光环 | **3:1（对相邻色）** | `state.focus.ring`（`docs/SPEC.md` §1.4.1-#7） |

**"最不利"口径（验收必须按这个取色）**：取**最不利位置的背景色**测对比度，**不是取平均**；**玻璃一律取"最暗内容"或"最亮内容"的合成色**（`06` §5.2 规则 6）。
**玻璃上的已知不达标值（不得实现成"可以商量"）**：浅色 `glass` 上 `secondary` **3.6 ❌** / `tertiary` **3.1 ❌**；**深色 `glass` 连 `primary` 只有 4.1 ❌**；深色 `glass-strong` 上 `secondary` **4.2 ❌** / `tertiary` **2.9 ❌**。⇒ 与 §12.1 的四条规则是同一件事的两种表述。
**iOS 验收方式（4 条）**：① `contracts/contrast.json` 的**每套 scheme 对比度账目**（`docs/DEV-PLAN.md` §5.1/§5.2 出口判据）；② nightly 的 demo 无障碍审计 4 类目之 **`contrast`** 必须用**最不利取色**（平均取色会全绿、失去意义）；③ §12.1 的玻璃矩阵单测；④ `contrast == .increased` ⇒ 玻璃**不透明**（O-9 第 1 条；第 2/3 条排 M4 且需设计签发）。

### 12.4 指针对齐（**设计侧待给值不抄正文**）

- **设计侧待给值 / 待签发清单的唯一登记处 = `docs/DEV-PLAN.md` §7**（本仓计划的设计待给值节）。原 16 项清单随跨端工作区退役，**本页不复制其正文**；本端相关 7 行见 §6.1。
- **本节的条目号索引**：`63` §3 的 **DF-02**（玻璃档位 × 文字矩阵）/ **DF-03**（效果配额 7 条）/ **DF-04**（对比度 4.5:1 / 3:1 + 最不利口径）。
- **iOS 17–25 玻璃降级（DF-10，t60·F-02）**：**默认动作 = 纯色降级**——**不做模糊、不使用系统 `Material` 模糊**，保留 hairline 边框；该区间 `WDGlassResolution` **只返回 `opaque`**（不返回 `glass`/`glassStrong`）。理由：设计稿明确"不做模糊"，系统 `Material` 是"真模糊"，冲突时**以设计稿为准**（U 系列以设计为真源）。**待设计裁决（时点 M0 D1）**——**不写"已定稿"**；裁决入口 = `docs/DEV-PLAN.md` §7 的 DF-10 行。**快照渲染器不变**：iOS 26+ 仍按 `docs/SPEC.md` §4.2 的清单（玻璃类 6 个用 `UIHostingController`+`drawHierarchy`，`ImageRenderer` 不渲染 `Material`/`glassEffect`）。
- **`motion.duration.reduced`（DF-14）**：**默认 = 设计稿 150ms**（备选 160ms 不采用，**待设计裁决**，同为 `docs/DEV-PLAN.md` §7 的行）。
- **行距差异（F51）**：列表行**行距各端自由**——iOS **44**、Android **布局盒 48**（44 可见 + 上下各 2dp 内边距）；**统一项 = 两端可见内容高度 44 ± 0.5**。**不得给 iOS 加 4pt 内边距**、**不得把 Android 压回 44**；登记处 = iOS 组长评审链（`20`，已退役）§3-附记「第 3 批补记 · **F51**」；**现口径 = `docs/DEV-PLAN.md` §5.1 的 F51 行与本页 §6 的 F-01–F-03**。

---

> 本页是 `t34` 的产物，**只读参考 + 施工指引**；与仓内另三份文档冲突时按 §2 的裁决链执行（**用户决策 ＞ 跨端裁决 ＞ 本端规格 `docs/SPEC.md` ＞ 命名表 `docs/DEV-PLAN.md` §5.3 ＞ 计划与冻结值 `docs/DEV-PLAN.md` ＞ 本页**）。架构细节见 `docs/ARCHITECTURE.md`；进程与冻结值见 `docs/DEV-PLAN.md`；实现细节见 `docs/SPEC.md`。
