# A-11 / A-13 / A-14 独立评审报告（第 2 轮 · repair-round-2 复审）

> 评审人：wd-reviewer-glm（t8，attempt 5，attempt_id=91c7ab79-f5d0-4417-89b4-217a3fdb1b03）
> 评审对象：t7 repair-round-2（对 R1 九条 findings F1–F9 的修复）
> 设计真源：../wisdomdesign/docs/14-member-tones-media-tooltip.md（定稿 v1.0）
> 输入：修复后源码（WDToolbar.swift 363 行 / WDToolbarTooltip.swift 229 行 /
> WDCard.swift 348 行 / WDAvatar.swift doc 增补）、三份测试、R1 报告、t7 出口报告
> 环境限制：PTY 耗尽、xctest 无法连接 ⇒ 运行时行为一律【未验证】；
> 口径 = 代码可编译 + 静态可指认 + 逻辑走查（本轮新增：门禁本人复跑 + 静态数值复算）。

---

## Verdict：**pass**（无 blocker / 无 high）

R1 的 9 条 findings：**7 条完全修复、1 条按计划转交 t6（F7 契约）、1 条修复正确但测试同步漏一行（F2 残留，medium）**。
另有 5 条 low（防御性闩的窄窗口、位移启发式的不对称、UIScreen.main、伴生测试强度、格式门禁环境污染）。
按 verdict 规则（pass = 无 blocker / high）判定 **pass**；两处 medium（F2 残留测试行、F7 契约）
均可并入 t6 集成批收口，不阻塞下游。

---

## 一、三个必答复核结论（逐条静态走查 + 数值复算）

### 1. A-14「500ms 后抬手到底会不会误触发 action？」——**不会。单一执行路径已成立。**

**判断点 / 吞点击点（两处，分工明确）：**
- **状态机判定点**：`WDToolbarTooltip.swift:66-74`，`decide(.release, .pressing)` ——
  `at - since < threshold → .performAction`，否则 `.hideTooltip`（不执行）。
- **实际吞点击点**：`WDToolbar.swift:127-131`，Button 原生闭包开头的门闩检查 ——
  `latch?.isConsumed == true → 复位闩 → return`（action 不执行）。

**门闩生命周期（WDToolbarArbitrationLatch，引用类型，Button 闭包 ⇄ 样式状态机共享）：**

| 轮次阶段 | 闩状态 | 代码位置 | 抬手后 action 是否执行 |
| --- | --- | --- | --- |
| 按下（isPressed=true） | **复位 false** | WDToolbar.swift:324 | —（新一轮） |
| 500ms 阈值到点（thresholdFired） | **置 true** | :338 | **否**（Button 闭包读到闩 → 吞掉 + 复位） |
| <500ms 抬手（.performAction） | 保持 false | :351-352（break，不执行） | **是，恰好一次**（唯一路径 = Button 闭包） |
| 滑出热区（.dragOut → .voidGesture） | **置 true** | :297 | **否**（防御性吞掉） |
| .tooltipShown 抬手（.hideTooltip） | 保持 true（阈值已置） | :353-354 | **否** |

**逐场景走查（showsTooltips=true 且按钮可用）：**
1. **长按 ≥500ms 抬手**：500ms 整点 Task 喂 `.thresholdFired` → 闩置 true + 提示显示；
   抬手 → Button 原生闭包触发（SwiftUI Button 无论按多久都在抬手触发）→ **读到闩 → 吞掉** →
   不执行 action ✓（设计 §3.3 第 2/4 行、C2 成立）；同时 `.release` 事件走
   `decide(.release, .tooltipShown) → (.hideTooltip, .consumed)` → `onTooltipEnd` 清
   `tooltipItemID` → 气泡 160ms 淡出（视图层 `.animation(value: isVisible)`）✓。
2. **500ms 内快速点按**：按下复位闩；状态机判 `.performAction` 但**只判定不执行**（:351 break）；
   Button 闭包闩为 false → 执行**恰好一次** ✓（R1 的双触发已消除——状态机的 `onAction`
   回调已从 context 删除，结构上不可能双路径）。
3. **<500ms 滑出热区**：DragGesture 喂 `.dragOut` → `.voidGesture` → 闩置 true →
   Button 闭包（若仍触发）吞掉 ✓（R1 的滑出回归已消除）。
4. **阈值后滑出**：`.dragOut` 在 `.tooltipShown` 也 → `.voidGesture` → `onTooltipEnd` 收尾提示 ✓。
5. **杂音**（consumed 后的重复事件）：`(.none, .consumed)`，闩已在上一轮被 Button 闭包复位或保持，
   无累积效应 ✓。

**结构保证**：状态机的 `onAction` 回调已删除（WDToolbarTooltip.swift:114-124 的 context 只有
onTooltip/onTooltipEnd）——**action 只可能从 Button 闭包执行**，「唯一判断点」从「声称」变成
「结构上成立」。R1 F1 的 requiredFix 原文明确允许「ButtonStyle + 门闩」最小变体
（PrimitiveButtonStyle 是建议项），本轮采用的正是该变体。✓

**一个防御性窄窗口（low，不阻塞）**：滑出作废后若 Button 因手势取消而**未触发闭包**，
闩停留在 true；下一次**非触摸激活**（VoiceOver 双击 / 键盘）会在闩检查处被吞一次
（触摸路径不受影响——下一次按下在 :324 复位）。见 R2-F3。

### 2. A-11 Equatable 语义——**站得住（与 R1 结论一致）。**

手写 `==`（WDAvatar.swift:86-90）只比 `label` / `icon` / **是否有照片**：
- `Text` 按内容比较、`WDIconName` 是 String 枚举 —— 操作数合法；
- SwiftUI 结构化 diff 不使用 `WDAvatarValue.==`，照片 A→B 照常重渲染，不漏更新；
- 暴露面仅调用方 Equatable 驱动 diff；F8 的 doc 增补已落盘（WDAvatar.swift:70-73，
  明确给出 `.id(memberID + photoVersion)` 式逃生门）✓。

### 3. A-13 互斥 + 占位链路——**口径不变且正确；F5/F6 均已修复。**

- 互斥（构造层静默丢弃）：`mediaMutuallyExclusive` 测试与实现一致，未被 t7 破坏 ✓；
- **F5**：`hasMediaBand = style == .media`（WDCard.swift:180-182，带 doc 引契约）——
  `media == nil` 渲染灰底带（`media ?? WDCardMedia(nil)`，:157），与 doc/契约/三条几何测试
  一致；静态复算：带高 = max(W/1.78, 96)，343→192.7、171/120→96，与断言值匹配 ✓；
- **F6**：淡入挂 `.onChange(of: media.image != nil)`（:326-329）+ `onAppear` 兜底首帧带图 ——
  nil→ready 转换可观察，主数据流成立 ✓（伴生测试强度见 R2-F6）。

---

## 二、R1 findings 处置表

| R1# | 严重度 | 修复判定 | 复核证据（本人静态走查） |
| --- | --- | --- | --- |
| F1 | blocker | **已修复**（门闩变体，R1 requiredFix 明确允许） | 见一、1 全表；onAction 回调已删，双路径结构上不可能 |
| F2 | high | **已修复**（行为层）；测试同步漏 1 行 → R2-F1 | `(.release,.tooltipShown)→(.hideTooltip,.consumed)`（WDToolbarTooltip.swift:82-83）+ onTooltipEnd（WDToolbar.swift:353-354）；M5:491 期望值未同步 |
| F3 | high | **已修复** | `.dragOut` 由 DragGesture(minimumDistance:1) 喂入（WDToolbar.swift:281-302）；minimumDistance ≥1 合仓规（SPEC §3.4 禁的是 0）；位移启发式裁量见 R2-F2 |
| F4 | high | **已修复** | 全局坐标夹紧（WDToolbarTooltip.swift:202-218）；数值复算见下节 |
| F5 | high | **已修复** | hasMediaBand = style == .media（WDCard.swift:180-182）|
| F6 | high | **已修复** | onChange 驱动淡入（WDCard.swift:326-329）+ onAppear 兜底（:322-325）|
| F7 | medium | **按计划转 t6**（未修，符合 R1 排期：契约随快照更新一并补） | contracts/WDAvatar.yaml grep hostColor 仍 0 命中 |
| F8 | low | **已修复** | WDAvatar.swift:70-73 doc 增补 |
| F9 | low | **已修复** | WDToolbar.swift:149 引 WDToolbarArbitrationLatch、WDToolbarTooltip.swift:8 引 WDToolbarItemPressStyle，均为真实类型 |

**F4 数值复算（本人重做）**：全局坐标夹紧 `clamped = min(max(buttonMidX, halfMax), screenWidth − halfMax)`，
halfMax = 200/2 + 8 = 108。代入 393pt 屏：首按钮（热区 44 贴左缘，midX=22）→ 夹紧到 108
（局部 x = 108−0 = 108，气泡完整在屏内 ✓）；中间按钮（midX≈196）→ 不夹，居中 ✓；
尾按钮（midX≈371）→ 夹到 285（局部 x = −64，向左平移 ✓）。R1 的 −42 偏移已消除。

---

## 三、本轮新 findings（advisory；无 blocker/high）

| # | 严重度 | 一句话 |
| --- | --- | --- |
| R2-F1 | medium | F2 残留：M5:491 测试期望 `.none` 未随状态机改为 `.hideTooltip`（执行即失败） |
| R2-F2 | low | F3 位移启发式右缘不对称：出界仅查负向坐标，10–44pt 小滑出窗口漏判 |
| R2-F3 | low | 作废轮后闩可能滞留 true：首次非触摸激活（VoiceOver/键盘）被吞一次 |
| R2-F4 | low | UIScreen.main.bounds 取屏宽：多窗口/分屏下非容器宽，且属弃用轨迹 API |
| R2-F5 | low | 伴生测试 mediaReadyAfterPlaceholderConstructs 未驱动真实 nil→ready 转换 |
| R2-F6 | low | check-format.sh 现红：未跟踪的 AIStarter/ 与 ai/ 模板目录污染（非 t7 产物） |

### R2-F1（medium · A-14）F2 的测试同步漏一行

- **problem**：状态机 `(.release, .tooltipShown)` 已改为 `(.hideTooltip, .consumed)`
  （WDToolbarTooltip.swift:82-83），但 `M5ComponentsTests.swift:491`
  `#expect(d2 == .none)` 期望的还是旧值 `.none` —— 该用例构造正是
  thresholdFired → .tooltipShown → release 序列，实际返回 `.hideTooltip`，
  **测试一旦执行必失败**。这正是 R1 F2 requiredFix 里「同步修正两条仲裁测试的期望」
  的未完成部分（另一条 arbitrationTooltipShownReleaseIsNoop 的断言恰好仍通过，
  但测试名「IsNoop」已与行为不符——它现在是 hideTooltip 收尾，不再是 noop）。
  t7 出口未提及测试同步，属修复完整性缺口（仅测试层，行为层正确）。
- **requiredFix**：`M5ComponentsTests.swift:491` 改为 `#expect(d2 == .hideTooltip)`；
  测试名 arbitrationTooltipShownReleaseIsNoop 改为 …HidesTooltip；可并入 t6 或单独一行提交。
- **file/line**：iOS/Tests/WisdomUITests/Components/M5ComponentsTests.swift :491（名称 :519）。

### R2-F2（low · A-14）位移启发式的右缘不对称

- **problem**：dragOut 判定 = `!inBounds || |translation| > 44`（WDToolbar.swift:284-291），
  其中 inBounds 只查 `location/startLocation ≥ 0`（左/上出界），**不查右/下出界**
  （局部坐标上限未知）。窄窗口：从热区右缘起滑出 10–44pt（translation < 44 且
  location ≥ 0）不触发 dragOut → Button 抬手 → 判 `.performAction` → action 执行。
  该窗口内行为与「tooltips 关闭时 Button 原生滑出取消」不一致（R1 F3 修复的回归只剩
  这个窄缝）。captain 已声明该启发式取舍并请裁量：**判定 = 可接受**——44pt 热区里
  「右缘 10–44pt 小滑」是罕见路径，精确 hit-test 在 ButtonStyle label 内拿不到
  边界；阈值走 `WDSize.touchTargetMin` 令牌（非自造数）合仓规。
- **requiredFix**（可选增强）：DragGesture 的 onChanged 里用 GeometryReader 包 label
  拿局部尺寸做完整四边判定；或接受现状并在注释里登记该窄窗口。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbar.swift :284-291。

### R2-F3（low · A-14）作废轮后闩滞留：首次非触摸激活被吞一次

- **problem**：滑出作废路径置闩（:297）是**防御性**的（大幅滑动后 SwiftUI Button
  通常本就不再触发闭包，闩只是兜底版本差异）。当 Button 确实未触发时，闩无人复位
  （复位点只有两处：Button 闭包吞掉时 :129、下一次按下 :324）。后果：作废轮之后
  首次 **VoiceOver 双击 / 键盘激活**（不经 isPressed 周期）会被闩吞一次。
  触摸路径不受影响；提示本就不进无障碍树，读屏用户主路径（label）不受影响 ——
  影响面极窄，且该防御闩换来的鲁棒性（跨 iOS 版本滑动后 Button 仍触发的情形）
  大于代价。
- **requiredFix**（可选）：作废收尾（voidGesture 后 isPressed 变 false 的 release 路径）
  延迟一拍复位闩；或登记已知窄窗口。不建议直接去掉防御闩（会重新暴露版本差异回归）。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbar.swift :297。

### R2-F4（low · A-14）UIScreen.main 取屏宽

- **problem**：气泡夹紧用 `UIScreen.main.bounds.width`（WDToolbarTooltip.swift:211）。
  iPad 分屏 / 多窗口下「屏幕宽」≠ 容器宽（设计语义是「平移进安全区」，以呈现环境为准）；
  UIScreen.main 在新版 SDK 处于弃用轨迹。单窗口 iPhone（本组件的主场景）下正确。
- **requiredFix**（可选）：改读宿主 scene 的窗口宽度，或把容器几何下传。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbarTooltip.swift :211。

### R2-F5（low · A-13）伴生测试未驱动真实转换

- **problem**：`mediaReadyAfterPlaceholderConstructs`（WDCardTests.swift:122-143）构造了
  nil 卡与 ready 卡**各一张**，断言构造可用 + ready 卡几何 —— 但 F6 修复的核心
  （同一视图实例上 nil→ready 的 onChange 淡入）没有被驱动：两张独立卡不经过
  `.onChange` 路径。测试无害且方向对，但名为「F6 主数据流」实际只覆盖半边。
- **requiredFix**（可选，等测试可跑时）：用 `@State` 驱动同一 `WDCard` 从 `WDCardMedia(nil)`
  切到 `WDCardMedia(image)` 的有状态 harness，断言切换后 appeared 置位/图片可见。
- **file/line**：iOS/Tests/WisdomUITests/Components/WDCardTests.swift :122-143。

### R2-F6（low · 环境/流程）check-format.sh 现红 —— 非 t7 产物

- **problem**：本人 22:00 复跑 `check-format.sh` = **exit 1**（files=220，比 t7 时的 212
  多 8 个）—— 新增失败项**全部**位于未跟踪目录 `iOS/AIStarter/`（Generated/TaskListView、
  AIStarter/TaskListView、Generated/Copied 等）与 `iOS/ai/skill-provider/templates/`，
  目录时间戳 18:26–18:46（晚于 t7 的门禁实跑）。t7 的 5 个改动文件 + 3 个测试文件
  本人逐个 `swift-format lint --strict` **全过（exit 0）**——t7 的「format 212 全过」
  声明对其自身范围成立。风险在下游：**t6 集成批会撞红门禁**。
- **requiredFix**：清走或 .gitignore 掉 `AIStarter/`、`ai/`（与组件库无关的模板产物），
  恢复 format 门禁绿；t6 开工前处理。
- **file/line**：iOS/AIStarter/、iOS/ai/（目录）。

---

## 四、门禁与复核声明（本人本轮实跑）

- `check-structure.sh --strict`：**exit 0**（files=196, errors=0, warnings=0, suppressed=259）——
  F3 的两个 44 字面量确实改为 `WDSize.touchTargetMin`、media band 的 R21 触发确实拆成
  `WDCardMediaBandLabel` 独立 modifier，结构检查零豁免新增。
- `check-format.sh`：exit 1 —— **全部失败项在未跟踪的 AIStarter/ 与 ai/ 模板目录**
  （18:26 后出现，非本批产物）；t7 的 8 个相关文件（5 改动 + 3 测试）逐个 lint **全过**。
  判定：t7 的 format 声明成立；环境需在 t6 前清理（R2-F6）。
- `build-for-testing`（任务给定的唯一编译命令，本人复跑）：**exit 0，TEST BUILD SUCCEEDED**。
- F4 数值复算 / 门闩生命周期走查 / FNV fixture 与四色值：R1 已独立重算，本轮 diff 未触及
  WDMemberTone+Assign.swift 与 WDTokens.swift（git status 确认），R1 结论继续有效。
- 运行时（单测执行 / 快照 / 真机长按回归）：一律【未验证】（PTY 耗尽）；按口径不作为
  通过证据、也不作为否决理由。

**对 verifier 报告的处置**：round-2 无新验证报告；R1 的 VERIFY 报告中被我 R1 推翻的
#19/#21/#22/#11/#12，本轮在修复后的代码上**逐条重走**（判断点接线、坐标空间、
hasMediaBand、淡入触发）——全部与修复后行为相符。R2-F1（测试期望未同步）是
verifier/repair 均未覆盖的缝隙，已列为 finding。

---

## 五、给 t6（集成批）的移交清单

1. **R2-F1**：M5:491 期望值改 `.hideTooltip` + 测试名更正（一行提交，务必在测试可执行前完成）；
2. **F7**：contracts/WDAvatar.yaml 补 hostColor 参数、WDAvatarImage 类型、
   init(image:label:icon:accessibilityLabel:) 签名（随 dump-api --update 同批）；
3. **R2-F6**：清理 / ignore AIStarter/ 与 ai/，恢复 format 门禁绿（t6 会撞红）；
4. R2-F2/F3/F4/F5 为可选增强，不阻塞。

---

## 六、结论

A-11 / A-13 / A-14 三份实现经 repair-round-2 后满足设计 14 的条文、兼容性、仓规与
无障碍要求（在「代码可编译 + 静态可指认」口径下）：R1 blocker F1 与全部 high 已修复
且本人逐条静态复核成立；遗留两处 medium（测试期望一行、契约登记）与五处 low 均
已登记并有明确去处。**verdict = pass。**

---

## 七、round-3 delta 复核（t9；只绑定 R2 之后的两个 delta）

> 复核人：wd-reviewer（t9，attempt 4，attempt_id=025a13f7-2d72-4317-9fdb-803da66a090c）
> 范围：**只**复核 t6 阶段对 R2-F1 的测试行修正与 `.gitignore` 两条新增；不重开 round-1/2 已确认项。
> 环境：PTY 耗尽未变 ⇒ 单测**执行**仍【未验证】；本轮门禁为本人实跑（见七.4）。

### 7.1 R2-F1 修正 vs 状态机：**一致**

| 项 | 磁盘现值（本轮绑定字节） | 判定 |
| --- | --- | --- |
| `decide(.release, .tooltipShown)` 实际返回 | `WDToolbarTooltip.swift:82-83` → `(.hideTooltip, .consumed)`（本 delta **未改动**该文件：mtime 2026-11-21 17:59:42，早于 R2 报告 22:12:28） | ✅ 基准正确 |
| M5:491 期望值 | `#expect(d2 == .hideTooltip, "tooltipShown 后抬手应收尾提示（R2-F1：与状态机修复同步）")` | ✅ 与 :82-83 一致 |
| 用例序列 | M5:476-493：`.press` → `.thresholdFired`（断言 `.showTooltip` / 相位 `.tooltipShown`）→ `.release(at: t0+0.8)` ⇒ 命中 `(.release, .tooltipShown)` 分支 | ✅ 确实走到被测分支，非旁路 |
| 测试名 | `arbitrationTooltipShownReleaseHidesTooltip`（:520）+ `@Test` 描述同步为「→ hideTooltip 收尾，不执行 action」（:519） | ✅ 名实相符（原 `IsNoop` 已不成立） |
| 其它残留旧期望 | 全仓 `Tests/` 内 `== .none` 只剩 :533（`consumed` 后再抬手 → `(_, .consumed) → .none`，正确）；无第二处旧 `.none` 期望 | ✅ 无遗漏 |
| 编译 | `build-for-testing` **exit 0**（本轮在**当前字节**上重跑，含测试 target 编译） | ✅ 测试可编译 |

**结论**：R2-F1（medium）**已闭合**——测试期望、测试名、被测分支三者对齐，且未引入新的编译问题。

### 7.2 gitignore 两条：**不影响任何已评审实现**

| 检查 | 结果 |
| --- | --- |
| 新增行 | `.gitignore:14-16`：`# 本地工具/模板产物（非库源码；2026-11-21 出现，污染 format 门禁 —— R2-F6）` + `/AIStarter/` + `/ai/`（**根锚定**，同行/上行为理由，可追溯 R2-F6） |
| 被忽略目录是否被跟踪 | `git ls-files -- AIStarter ai` = **0 条**；`git ls-files -ci --exclude-standard` = **空** ⇒ 无「已跟踪文件被静默忽略」 |
| 是否误伤仓内路径 | `git check-ignore -v Sources/WisdomUI/ai/z` **未命中**（根锚定生效）；被评审的 8 个实现/测试文件 `git check-ignore` 全部未命中（exit 1），且仍在 `check-format.sh --list` 的 212 文件清单内 |
| 是否被工程引用 | `.github/`、`Scripts/`、`Examples/WisdomUIDemo/*.pbxproj` 对 `AIStarter`/`ai/` 的引用 **0 命中** ⇒ 非构建输入 |
| 门禁影响 | structure `files=196`（与 R2 时一致，未被 ignore 改变）；format `files=212` **全过**（R2-F6 的红已消除）；build **exit 0** |
| 目录是否被删 | **未删**（仍在盘上，符合「不删用户产物」） |

**结论**：R2-F6（low）**已闭合**，且 delta 对 A-11/A-13/A-14 已评审代码 **零字节影响**。

### 7.3 已评审实现本体的字节绑定（本轮未重开）

t6 只动了测试行与 .gitignore；实现文件 mtime 全部早于 R2 报告（22:12:28），本轮以 hash 绑定：

```
WDToolbar.swift        742c3e91844e3c55c31777bdddc5a0f7344682ed337653b3e41710ffe1e2a711   (mtime 11-21 18:01:32)
WDToolbarTooltip.swift bfb396addf290bf5598e2f82acd55c1c7f2a64ef35678edff913de1407719ed1   (mtime 11-21 17:59:42)
WDAvatar.swift         56f73e6f958b57ac9c821f29ef8b8a618bfe01fad589160fb444c2b33bae2380   (mtime 11-21 18:00:01)
WDCard.swift           c57f28aa6d1225d9303d4635b0d76e560e9581ad803dbb3b4d451b10605c7839   (mtime 11-21 18:01:26)
WDCardMedia.swift      496bc914fd401d1a1993975542c7cf7cd2587673d2176eee55e415ac82f7f443
WDMemberTone+Assign.swift d9869c12bf9ccebc48d1c16802eb6da516481202b6c8121fee74a9caf8de3326
M5ComponentsTests.swift  cd644f9bee0e5b45f89bceb18945e8d08b55be797faefc7b0eeb8f826a2eac62   (唯一在 R2 之后变化的被测文件)
.gitignore               7078a4d9f6d2b1e425dbee1c7c220f47c4e906de9d8fd91000031ed9b754eca5
```

本轮**复核过（独立重走，不采信 R2 原文）**的两条高风险结论，在绑定字节上仍成立：
- **A-14「500ms 后抬手不执行 action」**：状态机判定点 `WDToolbarTooltip.swift:66-74`（`at - since < threshold` ⇒ `.performAction`，否则 `.hideTooltip`）；实际吞点 `WDToolbar.swift:124-131`（Button 原生闭包门闩 `latch?.isConsumed == true → 复位 → return`，唯一执行路径）。:82-83 的 `.tooltipShown` 分支同样返回 `.hideTooltip`（不执行）⇒ **不会误触发**。
- **A-11 Equatable 语义**：`WDAvatar.swift:86-90` 手写 `==` 只比 `label`/`icon`/`photo == nil`，照片负载不参与相等；F8 的 `.id()` 逃生门 doc 在 :70-73。**站得住**。

### 7.4 本轮门禁（本人实跑，当前字节）

| 命令 | 结果 |
| --- | --- |
| `./Scripts/check-structure.sh --strict` | **exit 0** — `files=196 rules=22 errors=0 warnings=0 suppressed=259` |
| `./Scripts/check-format.sh` | **exit 0** — `files=212`，`212 个文件全部通过 --strict` |
| `xcodebuild build-for-testing …（任务给定唯一命令）` | **exit 0**（`-quiet`，无 error；两条 `var phase` 未变异的既有 warning 不影响编译） |
| 单测**执行** / 快照 / 真机长按 | **【未验证】**（PTY 耗尽、无真机；本轮不写成通过，也不作为否决理由） |

### 7.5 round-3 findings（均为 low，不阻塞）

| # | 严重度 | problem | requiredFix | file:line |
| --- | --- | --- | --- | --- |
| R3-F1 | low | 同分支的第二条用例 `arbitrationTooltipShownReleaseHidesTooltip` 只断言 `d != .performAction` 与相位 `.consumed`，**未断言 `d == .hideTooltip`**；若将来该分支退化为 `.none`，此用例仍会通过（覆盖强度弱于 :49x 那条） | （可选）补一行 `#expect(d == .hideTooltip)`，或直接删掉与 :476-493 重复的这条用例 | iOS/Tests/WisdomUITests/Components/M5ComponentsTests.swift:526-529 |
| R3-F2 | low | `/ai/` 是根锚定的**泛用名**：当前无跟踪引用、无误伤（已验证），但未来若在仓根新增合法 `ai/` 目录会被静默忽略 | （可选）改为更具体的 `/ai/skill-provider/`，或在新增合法目录时同步加 `!/ai/<路径>/` 反忽略 | iOS/.gitignore:15-16 |
| R3-F3 | low | 新增两条 ignore 的注释行（:14）引用 `R2-F6`，属评审编号；评审报告后续若归档/改名，注释会失去可追溯性 | （可选）补一句"外来模板目录（AIStarter 模板工程 / skill-provider 产物）"的自含说明 | iOS/.gitignore:14 |

历史记录说明（非 finding）：`A11-A13-A14-REVIEW-R1.md:111` 与 `A11-A13-A14-REVIEW-R2.md:124-128` 仍出现旧测试名 `…IsNoop`——那是两轮评审留痕，**不回改**（回改会篡改历史证据）。

### 7.6 round-3 verdict

**verdict = pass。** 两个 delta 均无回归：R2-F1 的测试期望/名称与状态机 `.hideTooltip` 实际返回一致且可编译；`.gitignore` 两条根锚定忽略未触及任何已评审实现（无跟踪文件被忽略、无构建引用、三门禁绿）。三条 low 为可选增强，不阻塞 t6 之后的发布流程。

