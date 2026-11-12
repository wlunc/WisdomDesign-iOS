# 契约确认请求 —— M2 判据②的唯一外部输入

> 用途：M2 出口判据②「批内 11 件的契约用例名与实现一致（`params`/`slots`/`default` 与 §5.3 逐行一致）」
> 卡在 `contracts/*.yaml` 未落库。按 I-2 原文，该判据在本批**以冻结表单代替**；现在需要的是一句
> **架构师的书面确认**（或直接落库），即可闭合。
> 日期：2026-11-10｜请求方：iOS 侧（项目负责人已同意走"先确认、后回填"）｜确认人：**架构师**
> 关联：`docs/M2-SIGNATURE-FREEZE.md`、`docs/M2-EXIT-REPORT.md` §1-②、`../AGENTS.md` §3.1 的 I-2 与 `docs/DEV-PLAN.md` §3（批前冻结）。
>
> **状态：✅ 已确认（选项 B）—— 2026-11-10 架构师书面签署；`contracts/*.yaml` 已于 2026-11-12 回填（11 件 + `WDListSection` = 12 个 yaml，设计仓提交 `89779f7`）。**
> 签署记录、核对证据与回填口径见 §5（与 §3 冲突时以 §5 为准）。

## 1. 现状（可核对的证据）

- 11 件组件的公开签名与 `docs/M2-SIGNATURE-FREEZE.md` **逐字一致**（口径 = §5.1 所定的 §1.1+§5.1+§5.2；
  编译产物级自证：`api/WisdomUI.api.json` 641 符号、`dump-api` 零 diff；签名变更会同时改基线）；
- 受控值名与 C-15 逐行核对通过（含唯一改名 `WDCheckbox.isChecked`；Android 侧 `params[].name` 仍待其改名
  —— 该括号内的说法与 `android/docs/SPEC.md` §2.10 的改名结果记载不一致，回填前复核，见 §5.5）；
- 槽位名全部落在 21 名词表内（F-15）：`label/prefix/accessory/helper/title/subtitle/leading/trailing/content/icon/…`；
- `contracts/*.yaml` 库**仍未落库**（M0-5 未交付；`contracts/` 只有 `icons.json`——指 `../wisdomdesign/contracts/`，iOS 仓无此目录）。

## 2. 两个可选动作（二选一，建议 B）

| 选项 | 内容 | 代价 | 对 M2 的影响 |
| --- | --- | --- | --- |
| **A 落库** | 架构师把 11 件的 `params`/`slots`/`default` 写进 `contracts/<component>.yaml` | 需要架构师排期；本批已冻结的签名不得再动 | 最彻底，但会阻塞 M2 出口 |
| **B 书面确认（建议）** | 确认"**本批以 `docs/M2-SIGNATURE-FREEZE.md` 的冻结签名为契约副本**；`contracts/*.yaml` 的落库时点 = **M3 出口前**，届时按本条回填，不视为契约漂移" | 一句回复；M3 出口前需补落库 | 立即闭合判据②，不阻塞 M3 |

> 建议 B 的理由：签名已经冻结且被 API 基线机器钉住；`contracts/` 缺的是**登记动作**，不是**语义分歧**。
> A 会把"登记延迟"变成"M2 出口延迟"，不划算。

## 3. 可直接回复的确认文本（复制即用）

> 确认：M2 的 11 件组件（`WDTextField`、`WDListRow`、`WDButton`、`WDIconButton`、`WDSwitch`、
> `WDCheckbox`、`WDBadge`、`WDAvatar`、`WDDivider`、`WDCard`、`WDIcon`）以
> `iOS/docs/M2-SIGNATURE-FREEZE.md` 的 **§1.1（3 件）+ §5.1（8 件逐件签名）+ §5.2（两个值类型成员）**
> 为**本批 iOS 侧契约副本**（该文件 §1.2/§1.3 的「提案」表已被 §5.1/§5.2 取代，不得再作为副本）；
> `contracts/*.yaml` 于 **M3 出口前**落库回填，期间不视为契约漂移。
> 确认人：架构师｜日期：2026-11-10（签署记录、核对证据与回填口径见 §5）

## 4. 回填时的检查项（给 M3 的提醒，不要求现在做）

1. `contracts/<component>.yaml` 的 `params[].name` 与 C-15 逐行一致（0 不一致）；
2. `slots` 必须是 21 名词表子集；无槽位写"无"；
3. `default` 与冻结表单 §1.1/§5.1 的默认值逐项一致（§1.2 是已被取代的提案底稿）；
4. `WDCheckbox` 的契约名 `checked`/`isChecked` 依赖 Android 侧 14 行改名（SPEC R3-d）——若届时未完成，
   在 yaml 里标注"待 Android"，**不要**为了闭环改 iOS 侧名字。

> 以上 4 条已并入 §5.3 的判定口径，以 §5.3 为准。

---

## 5. 架构师确认记录（2026-11-10）—— **选项 B 已签署**

> 本节是 §3 回复文本的完整版；与 §3 冲突时以本节为准。签署人 = **架构师（角色签署）**；
> `../AGENTS.md` §11 记「架构师与设计尚未点名到人」，实名签署由项目负责人补记（不影响本节效力）。

### 5.1 契约副本的精确定义

- **副本范围** = `docs/M2-SIGNATURE-FREEZE.md` 的 **§1.1**（`WDButton`/`WDTextField`/`WDListRow`，誊录自规格与冒烟段）
  + **§5.1**（其余 8 件逐件签名与结论）+ **§5.2**（`WDAvatarValue`/`WDBadgeValue` 成员）+ **§5.4**（决议记录）。
- **§1.2/§1.3 的「提案」表已被取代**（2026-10-07 底稿；三处可核对的不一致：`WDBadge` 的 `_ label` → `label:`、
  `WDAvatar` 的 `_ value:size:` → `value:`（无 `size`）、`WDIcon` 的 `_ name:` → `icon:size:`）。
  `api/WisdomUI.api.json` 的实际声明与 **§5.1/§5.2** 一致。
- **「逐字一致」的口径** = 组件公开 `init` + 枚举类型与 case + 默认值。承载类型的附加公开面
  （`WDButtonStyle` 的公开 `init`/`makeBody`、`ButtonStyle.wdFilled`；`WDIconName.symbolName`/`mirrorsInRTL`）
  不进契约三键，**不构成漂移**（已核对存在，见 5.2）。
- **粒度 = iOS 侧契约条目**：`params[].name`（受控值取 C-15 canonical；其余按冻结签名形参名）、
  `slots`（⊆ 21 名词表；无则「无」）、`default`（冻结签名里的默认值）。
  **不是**两端合并后的契约真源：跨端参数集/能力集差异（例：`WDTextField.isEditable` 与 Android `readOnly`、
  F23/F48 各项）仍由 M0-5 的合并与 F 登记处理。

### 5.2 核对证据（2026-11-10，可复跑）

| 项 | 结果 | 复跑方式 |
| --- | --- | --- |
| API 基线 | **641 符号，零 diff** | `cd iOS && Scripts/dump-api.sh` → `与基线零 diff（symbols=641）` |
| 基线对应源码 | `Sources/**` 无新于该 `swiftmodule` 的文件（0 个） | `cd iOS && find Sources -newer .build/dd/Build/Products/Debug-iphonesimulator/WisdomUI.swiftmodule -type f` |
| 11 件签名 | 与 §1.1/§5.1/§5.2 **0 不一致** | 下表四列；抽取方式见本节末 |
| 槽位 | 全部 ⊆ 21 名（F-15）；`WDDivider` = 「无」 | 下表 `slots` 列 |
| C-15 | 6 个受控值 0 不一致；`#06` 是唯一改名 | 下表「受控值」列 ↔ `docs/DEV-PLAN.md` §5.3 |
| 枚举规则 | 均 `String` + `CaseIterable` + `Sendable`；`Sources/**` 无 `@frozen` | `grep -rn '@frozen' iOS/Sources`（仅 1 处注释） |
| 图标 | `WDIconName` **44 case**；`mirrorsInRTL` 存在 | 基线 `WDIconName.*` 计数 + `../wisdomdesign/contracts/icons.json` v1.0.0 |
| 附加公开面（不进契约） | `WDButtonStyle.init`/`makeBody`、`ButtonStyle.wdFilled`、`WDIconName.symbolName`/`mirrorsInRTL` 均存在 | 基线按 `path` 检索（未列入冻结表单，按 §5.1 不构成漂移） |

**逐件契约条目**（`default` 与 §1.1/§5.1 逐字相等；枚举全量 case 见括号内计数）

| 件 | 受控值（契约名 / iOS 名） | `slots` | `default` |
| --- | --- | --- | --- |
| `WDTextField` | `text` / `text` | `label`, `prefix`, `accessory`, `helper` | `appearance` `.init()`、`isEditable` `true`、`onSubmit`/`onEditingChanged` `nil`；appearance 内：`variant` `.inset`、`placeholder` `nil`、`prefix`/`accessory`/`helper` `.none`、`isSecure` `false`、`submitLabel` `.done` |
| `WDListRow` | `selected` / `isSelected` | `title`, `subtitle`, `leading`, `trailing` | `subtitle` `nil`、`leading`/`trailing` `.none`、`isSelected` `false`、`swipeAction` `.none`、`showsSeparator` `true`、`action` `nil` |
| `WDButton` | `loading` / `isLoading` | `label`, `leadingIcon`, `trailingIcon` | `variant` `.filled`、`size` `.md`、`isLoading` `false`、`loadingAccessibilityText`/`leadingIcon`/`trailingIcon` `nil`（6/3 case） |
| `WDIconButton` | `loading` / `isLoading` | `icon`（`accessibilityLabel` 是必填**参数**，不是槽位） | `variant` `.plain`、`size` `.md`、`isLoading` `false`（1 case） |
| `WDSwitch` | `on` / `isOn` | `label` | 两参必填（无默认） |
| `WDCheckbox` | `checked` / `isChecked` | `label` | 两参必填（无默认） |
| `WDBadge` | — | `label` | `label` 必填（「4 汉字」是实现约束，不进签名） |
| `WDAvatar` | — | `icon`, `label` | `value` 必填；值类型两 init：`init(icon:)` / `init(label:)` |
| `WDDivider` | — | 无 | `init()` |
| `WDCard` | — | `content` | `style` `.elevated`（3 case） |
| `WDIcon` | — | `icon` | `size` `.md`（4 case） |

**抽取方式**：`python3` 遍历 `api/WisdomUI.api.json` 的 `symbols[]`，按 `path` 前缀过滤 11 件的
`kind == 'swift.init'` / `swift.enum.case` 并打印 `decl`，与 §1.1/§5.1/§5.2 逐字比对（本次结果 0 不一致）。

**默认值也在基线里**：本仓 `api/WisdomUI.api.json` 的 `decl` 是 declarationFragments 的拼接，含默认值
（例 `size: WDButtonSize = .md`）⇒ 默认值漂移会体现为基线 diff。这与 `docs/DEV-PLAN.md` §9 与
`docs/SPEC.md` §2.9 的「默认值变化查不出、只能靠契约」表述不符（ABI 语义不变，是本仓的检出口径不同）；
本确认**不改规则**，只登记为待回写项（见 5.5）。

### 5.3 回填义务（M3 出口前）

1. **位置**：`../wisdomdesign/contracts/<Component>.yaml`（PascalCase，与 `docs/SPEC.md` §2.11 及 SPEC R3-d 的写法一致）；
   **不是** `iOS/contracts/`（该目录不存在）。11 个文件：`WDTextField`/`WDListRow`/`WDButton`/`WDIconButton`/`WDSwitch`/
   `WDCheckbox`/`WDBadge`/`WDAvatar`/`WDDivider`/`WDCard`/`WDIcon`。
2. **内容**：`params`（`name` 取 C-15 canonical）+ `slots`（21 名子集或「无」）+ `default`（§1.1/§5.1 逐字）
   + **枚举全量 case**（I-2 原文要求）。字段名与骨架以 M0-5 的 `contracts/README.md` 为准；README 落地前按三键登记，
   不另造 schema；README 与本节键名不同时以 README 为准，并在 `CHANGELOG.md` 记一次对齐。
3. **回填 = 誊录，不是重设计**：不得借回填改签名/默认值/槽位名/枚举 case；
   `docs/M2-DEVIATIONS.md` 的 14 条延后项**不得**借回填扩签名（要扩 = 走 U/契约流程）。
4. **`WDCheckbox`**：`params[].name = checked`（`isChecked` 只是 iOS 形参名）。R3-d 的 Android 前置按
   android-lead 书面确认为准；未确认时在 yaml 标「待 Android」，**不改** iOS 名。
   （注：`android/docs/SPEC.md` §2.10 已记载 14 行改名结果、含 `WDCheckbox` 保持 `checked`；若该记载为最新，
   前置已消除——回填前复核一次，见 5.5。）
5. **判定口径**：① `params[].name` ↔ `docs/DEV-PLAN.md` §5.3 逐行 0 不一致
   （预期唯一差异 = `#06` 的名词差：契约 `checked` / iOS `isChecked`，不是 `is` 前缀差异）；
   ② `slots` ⊆ 21 名，无槽位写「无」；③ `default` ↔ 表单逐字；④ 枚举 `allCases` 归一化集合相等。
6. **时点**：不晚于 **M3 出口**。逾期 ⇒ 本确认的前提不成立，M2 判据②回到未闭合（由 ios-lead 判定）。

### 5.4 本确认的边界

- **不代替 M0-5 的其余交付**：`contracts/README.md`、C-15 落库表、U3 的 37 行表、组件类型名清单、两端默认值对照表、
  `dist/*.json` 产物与读取入口（`WDContracts.previewCaseNames()` 等仍未实现）；这 11 个 yaml 只是 M2 的切片。
- **不构成 M2 出口通过**：nightly 连续 3 日绿与 ios-lead 签字仍待（`docs/M2-EXIT-REPORT.md` §4/§6）。
- **不覆盖 M3–M6 的 26 件**：各批 I-2 各自冻结、各自落库。
- **不改变** 14 条签名差异裁决（`docs/M2-DEVIATIONS.md` §5）与任何签名/默认值/槽位。
- 本质 = **「登记延迟」的书面替代**，不是「契约真源已落库」。

### 5.5 随本次确认同步修正的表述（2026-11-10）

- `docs/M2-SIGNATURE-FREEZE.md`：§1.2/§1.3 加「已被 §5.1/§5.2 取代」标注；末行「实现 2/11」更正为 **11/11**。
- `docs/M2-EXIT-REPORT.md` §1-② / §4-④ / §6-2、`docs/DEV-PLAN.md` §2.3、`docs/HANDOVER.md`、
  `docs/M3-PREP-LISTSECTION.md`、`docs/M2-DEVIATIONS.md` §4：把「确认仍待」类表述改为
  「2026-11-10 已由架构师书面确认（回填已于 2026-11-12 完成，12 个 yaml）」。
- **回填完成（2026-11-12）**：11 件 + `WDListSection` = 12 个 yaml 已落 `../wisdomdesign/contracts/`（设计仓提交 `89779f7`）；判定口径按 §5.3 复跑通过。
- **仍待他人复核（不属本确认）**：① 本请求 §1 的「Android 侧 `params[].name` 仍待其改名」与
  `android/docs/SPEC.md` §2.10 的改名结果记载不一致 ⇒ 回填前由 android-lead 确认一次；
  ② `android/docs/DEV-PLAN.md` §7-V18 仍写 `contracts/icons.json` 未落库（实际已落：
  `../wisdomdesign/contracts/icons.json` v1.0.0）⇒ Android 侧自行回写；③ 默认值检出口径的表述（见 5.2 末）
  ⇒ 由 ios-lead 按 `docs/DEV-PLAN.md` §6 流程登记 P 项后回写。

### 5.6 签署

| 项 | 值 |
| --- | --- |
| 决定 | **B**（书面确认；`contracts/*.yaml` 于 M3 出口前回填） |
| 生效条件 | 5.3 的回填与判定口径在 M3 出口前完成；未完成 ⇒ 判据②回到未闭合 |
| 确认人 | 架构师（角色签署；实名由项目负责人补记） |
| 日期 | 2026-11-10 |
| 效力 | 闭合 `docs/M2-EXIT-REPORT.md` §1-②；不改变任何签名/默认值/槽位 |
