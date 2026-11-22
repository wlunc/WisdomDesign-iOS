# A-11 / A-13 / A-14 验证报告（round-2 · 当前字节重采）

> 验证者：wd-verifier（t10，attempt 1，attempt_id=17668747-f31f-4280-99d8-28c8f19b09d5）
> 性质：**证据层重采**（不是评审、不重开评审判断）。t4 的 VERIFY 采于 repair 之前，本报告绑定**当前磁盘字节**。
> 设计真源：`../wisdomdesign/docs/14-member-tones-media-tooltip.md`（定稿 v1.0，2026-11-21），逐条对照 §1 / §2 / §3 / §4.4。
> 环境：本机 PTY 耗尽（实测证据见 §六.1），**单测执行 / 快照一律【无法验证】**；本报告不把任何一项写成"测试通过"。
> 图例：✅ 通过（带 file:line 证据）｜ ❌ 不通过（指明违反的设计条目）｜ ⚪ 无法验证（需运行时/真机）

## 零、绑定字节与门禁（本人实跑）

| 项 | 现值 |
| --- | --- |
| 绑定文件（mtime / 行数） | WDAvatar.swift 323 行 · 18:00:01｜WDAvatarMetrics.swift 37 行｜WDMemberTone+Assign.swift 43 行｜WDCard.swift 348 行 · 18:01:26｜WDCardMedia.swift 26 行 · 15:24:41｜WDToolbar.swift 363 行 · 18:01:32｜WDToolbarTooltip.swift 229 行 · 17:59:42｜M5ComponentsTests.swift 652 行 · 22:16:31（t6 只改测试行 + .gitignore） |
| `check-structure.sh --strict` | **exit 0** — `files=196 rules=22 errors=0 warnings=0 suppressed=259` |
| `check-format.sh` | **exit 0** — `files=212`，`212 个文件全部通过 --strict` |
| `build-for-testing`（任务给定命令，warm） | **exit 0**（`-quiet`，无 error） |
| `build-for-testing`（本人另跑冷编，`-derivedDataPath .build/dd-r2verify`） | **exit 0**（仅 2 条既有 warning：`M5ComponentsTests.swift:498/:507` `var phase` 未变异） |
| 令牌生成物一致性 | `node ../wisdomdesign/tools/token-build/build.js --check` **exit 0**（tokens v1.1.0 / 8 条成员色对比度全过）⇒ generated/ 为生成器产物，无手改 |

---

## 一、A-11 · WDAvatar（设计 14 §1）

**1. ✅ 默认 tone=nil 回落 surfaceTint**
`WDAvatar.swift:263-265` `backgroundColor = tone?.fill ?? colors.surfaceTint`；`:268-270` `foregroundColor = tone?.ink ?? colors.textOnSoft`；旧构造 `:157-159` 仍委托 `init(value:size:)`（`:168-182` 新参数全带默认值）。⇒ §1.1-C7 之前的观感不变（像素证据仅测试内，执行⚪）。

**2. ✅ tone 非 nil 走 fill / ink；组件零硬编码十六进制**
`:263-265`（fill）/ `:268-270`（ink）。`grep -nE '0x[0-9A-Fa-f]{6}'` 对 WDAvatar.swift / WDCard.swift / WDToolbar*.swift = **0 命中（exit 1）**。令牌值 `WDTokens.swift:134-147`（fill/ink 逐档，含深色另一组）与设计 §1.2 表逐值一致（浅色 #B0D5DF/#7EC4CF/#1A7BA3/#065279）。

**3. ✅ 回退链严格 照片 → 文字 → 图标**
`WDAvatar.swift:110-121` `resolved`：三个 `if let` 的**书写顺序**即设计 §1.4 的硬顺序（photo → label → icon → empty）；`:211-226` `content` 按 `resolved` 分支渲染；`:204-208` 照片档不铺底色（无"底色圆先露出来"的中间帧）。

**4. ✅ 照片 2pt 描边（WDSize.avatarRing）、描边色可传入默认 surfaceCardSolid**
`WDAvatarMetrics.swift:34` `photoRingWidth = WDSize.avatarRing` → `WDTokens.swift:203` = **2**；`WDAvatar.swift:273-275` `ringColor = hostColor ?? colors.surfaceCardSolid`；照片描边 `:234-236`（`strokeBorder(ringColor, lineWidth: photoRingWidth)`）；在线点同用 `ringColor` `:240-248`（`:244`）。⇒ 满足 §1.4「2pt」+ §1.5「描边色由宿主传入，默认 surface.card-solid」。

**5. ✅ 不占位 / 不骨架 / 失败空图回退且无破图（静态可证；渲染未执行）**
- 无占位/无骨架代码：`grep -rn 'Skeleton|skeleton|shimmer|AsyncImage|placeholder'` 对 WDAvatar/ 目录 = **0 命中**；
- 空图**在值构造处**即无照片：`:82` `photo = image.map { … }`（`image == nil` ⇒ `photo == nil`）⇒ `:110-121` 直接落文字/图标档，中间不存在 image 框；`:203-208` 照片档才免底色；
- 类型注释 `:3-13` 写明"库内不做异步加载"的分工。
⚪ 真实解码失败 / 渲染异常未验证（需运行）。

**6. ✅ 淡入 160ms（motion.duration.fast）且无缩放**
`WDAvatarMetrics.swift:36` `photoFadeDuration = WDMotion.Duration.fast` → `WDTokens.swift:265` = **0.16**；`:252-254` `.easeOut(duration: photoFadeDuration)`；`:199` `.animation(photoFade, value: showsPhoto)`；WDAvatar.swift 内 `grep scaleEffect` = **0 命中**（仅 `:197` 的 `opacity` 用于停用态）。

**7. ✅ FNV1a32 参数与五 fixture（本人独立复算）**
`WDMemberTone+Assign.swift:36-42`：初值 `:37` `0x811C_9DC5`、乘子 `:39` `&* 0x0100_0193`、`:38` `for byte in value.utf8`（UTF-8 逐字节）、`&*` = 32 位回绕；输入 `:20` `assign(memberID:)`（成员 ID，非显示名）；`:21` `% allCases.count`（当前 4）+ `:22-27` 显式 switch。
**独立复算（python，非抄测试）**：u_1001→1050025199→mod3→tone-4；u_1002→1066802818→2→tone-3；u_1003→1083580437→1→tone-2；u_1004→966137104→0→tone-1；u_1005→982914723→3→tone-4 —— 与设计 §1.3「取样结果」表**逐格相同**，含撞色（1001/1005）。
测试侧同表：`WDAvatarTests.swift:98-104`（档位）+ `:111-117`（32 位中间量）。⚪ 断言**执行**未验证。

**8. ✅ Equatable 保留、照片负载不参与相等、语义写清、无 AnyView**
`:42` 仍 `Sendable, Equatable`；`:86-90` 手写 `==` 只比 `label` / `icon` / `(lhs.photo == nil) == (rhs.photo == nil)`；语义注释 `:37-41` + 逃生门（`.id(memberID + photoVersion)`）`:70-73`。`grep AnyView` 对三目录 = **0 命中**。测试 `WDAvatarTests.swift:238-250` 锁定该语义。⇒ 未偷删 Equatable、未用 AnyView。

---

## 二、A-13 · WDCard.media（设计 14 §2）

**9. ✅ 图片带通栏（左右+上贴边、不叠 16）；文字区仍 16**
`WDCard.swift:153-173`：`.media` 分支 = `VStack(spacing: WDCardMediaBand.stackSpacing /* =0, :300 */)` 内先 `WDCardMediaBand`（带内**无 padding**，`:291-334`），再 `content.padding(WDSpacing.s5)`（`:159`；s5 = 16，`WDTokens.swift:158`）。整卡只在外层 `:168` `.frame(maxWidth:.infinity)`，无内缩。

**10. ✅ 上圆 24 / 下不圆 = 整卡单次 clipShape**
`:170` `.clipShape(shape)`；`:216-218` `shape = RoundedRectangle(cornerRadius: WDRadius.xl /*24*/, style: .continuous)`（`WDTokens.swift:172`）。带内无任何圆角：`grep cornerRadius` 仅 `:217`（shape）与 `:266`（按下蒙层，属 WDCardButtonStyle）⇒ 不给图片带单独加圆角，交界不出重影。

**11. ✅ 1.78 / 最小高 96 走令牌；343→193、171→96 实算成立**
`:315` `.aspectRatio(WDSize.cardMediaAspectRatio, .fill)` → `WDTokens.swift:204` = **1.78**；`:316` `.frame(minHeight: WDSize.cardMediaMinHeight)` → `:205` = **96**。实算：343 / 1.78 = **192.70 → 193**（卡高 193+82=274.7）；171 / 1.78 = **96.07 → 触发 96 下限**（卡高 96+82=178）；120 宽 = 67.4 < 96 ⇒ 夹到 96。测试 `WDCardTests.swift:104-114` 断言同三档。

**12. ✅ 加载中/失败/无图 = surface.card-sunken 灰底，无骨架无微光无破图（静态）**
`:307` `Color(colors.surfaceCardSunken)` 恒在 ZStack 底层；`:308-313` 只有 `media.image` 非空才建 image 层（`scaledToFill` + `:318` `.clipped()`）。`grep Skeleton/shimmer/AsyncImage/placeholder` 对 WDCard/ = **0 命中**。⇒ 无骨架、无微光、无 image 框 ⇒ 无破图路径。⚪ 渲染未执行。

**13. ✅ 互斥/不组合=构造层**静默降级**（非断言、非 doc-only）**
实际行为：`init(style:media:content:)` `:90/:93` 与 `init(style:media:action:content:)` `:105/:108` 均 `self.style = style == .media ? .media : style` + `self.media = self.style == .media ? media : nil`；旧两个构造 `:60`/`:77` 恒 `media = nil`。⇒ 传 `.glass`/`.sunken` + media 参数 = **载荷被静默丢弃**（无 precondition / 无 assert）。`style` 是单值，`.media` 与 `.glass` 结构上不能同时成立。测试 `WDCardTests.swift:157-169` 断言 `elevatedWithMediaParam.media == nil`。**口径需明示给评审**：设计 §2.6 只说"互斥/不组合"，未规定强制手段；本实现 = 静默降级（与 R1/R2 结论一致）。

**14. ✅ 图片默认 accessibilityHidden；给 label 才进树**
`:330` `.accessibilityHidden(media.accessibilityLabel == nil)`；`:331` `.accessibilityElement(children: .ignore)`；`:332` + `:338-347` `WDCardMediaBandLabel`：label 非 nil 才挂 `.accessibilityLabel`。⇒ §2.5 两档成立。⚪ AX 树实际内容未验证。

**15. ✅ 可点卡 96% 蒙层覆盖整卡（含图片带）**
`:115-125` `Button(action:)` 的 label = `surface` → `:153-173` `chrome`（含图片带）`.contentShape(shape)`；蒙层在 `WDCardButtonStyle` `:263-274`，作用于 `configuration.label`（= 整卡）并以 `:266` 圆角矩形铺满。⇒ 图片一起压暗（§2.3）。

**16. ✅ 既有四档零行为变化（逐分支比对）**
- `background` `:184-192`：elevated/outlined/glass/sunken 四行原样，仅**新增** `case .media`；
- `borderOverlay` `:195-199`（sunken 不描边）未改；`WDCardShadow` `:228-238` 未改（⇒ media 走 e1，outlined/sunken 无阴影）；
- 非 media 构造 `media == nil` ⇒ `hasMediaBand` `:180-182` false ⇒ `chrome` 走 `:162-166` 的 else 分支，与改造前语句**逐行相同**（`git diff HEAD~1 HEAD` 可见只多出 `Group{}` 包裹，Group 不参与布局）；
- `staticSurface`/`surface`（玻璃分支 `:128-147`）未动。测试 `WDCardTests.swift:62-68` 断言四档仍 82±1（media 除外）。

---

## 三、A-14 · WDToolbar 长按提示（设计 14 §3）

**17. ✅ showsTooltips 默认 false，既有调用点零变化**
`WDToolbar.swift:66-76`（`:70` `showsTooltips: Bool = false`）；`:150-161` `arbitration = showsTooltips && item.isEnabled ? … : nil`；`:238-244` `arbitration == nil ⇒ plainBody`；`:247-257` `plainBody` 与改造前逐行相同（`git diff` 显示该函数零改动）。仓内既有调用点（`WDToolbar+Previews.swift:9/:22`、`DemoM5Variants.swift:166-167/:316/:351`、`DemoM5Previews.swift:371`、`DemoThemeView.swift:325`、`M5PerfTests/M5SnapshotTests`）全部未传该参数 ⇒ 行为不变。

**18. ✅ 阈值 500ms 读 WDSize.tooltipPressDuration**
`:155` `threshold: WDSize.tooltipPressDuration` → `WDTokens.swift:209` = **0.500**；`:331-332` `Task.sleep(for: .seconds(arbitration.threshold))`。

**19. ✅ 六行仲裁逐行成立；「500ms 后抬手不执行 action」的唯一判断点 + 唯一执行路径**
判断点（**只判定，不执行**）：`WDToolbarTooltip.swift:66-74` `(.release, .pressing)` — `at - since < threshold` ⇒ `.performAction`，否则 `.hideTooltip/.consumed`；`:82-83` `(.release, .tooltipShown)` ⇒ `.hideTooltip/.consumed`（永不为 performAction）。
执行路径（**唯一**）：`WDToolbar.swift:124-135` Button 原生闭包；门闩检查 `:127-131`：
```
let latch = arbitrationLatches[item.id]
if showsTooltips && item.isEnabled, latch?.isConsumed == true { latch?.isConsumed = false; return }
guard item.isEnabled else { return }
… item.action()   // :134
```
state 机侧不再有 `onAction`：`WDToolbarTooltip.swift:114-124` 的 context 只有 `latch/onTooltip/onTooltipEnd`；`grep -rn 'onAction'` 在 WDToolbar 目录 = **0 命中**（另两处 `item.action()` 在 `:184` 溢出菜单，无仲裁、无提示，设计 §3.1-C5 明确不给菜单项加提示）。

逐行核对（§3.3 六行）：
| 设计行 | 实现 | 判定 |
| --- | --- | --- |
| 按下 0ms → 按下态（0.94 + fill.pressed），与原行为一致 | `:267-277`（`isPressedVisually` 由 phase 推导：`pressing` ⇒ 0.94 + fillPressed） | ✅ |
| 按住到 500ms → 显示提示 + 取消按下态 + 吞点击 | `:331-341`：`thresholdFired` ⇒ phase=`.tooltipShown`（⇒ isPressedVisually=false 回默认视觉）+ `:338` 置闩 + `:339` onTooltip | ✅ |
| 500ms 内抬手 → 执行 action、不显示提示 | `WDToolbarTooltip.swift:66-69` ⇒ `.performAction`；`:351-352` 只 `break`（闩保持 false）⇒ `:134` 执行一次 | ✅ |
| 500ms 后抬手 → 不执行 action；提示 160ms 后淡出 | `WDToolbarTooltip.swift:82-83` ⇒ `.hideTooltip`；`:353-354` `onTooltipEnd` 清 `tooltipItemID` ⇒ `:163-166` isVisible=false ⇒ 气泡 `WDToolbarTooltip.swift:172-177` 用 `disappearDuration=0.16` 淡出 | ✅ |
| 500ms 后滑出热区 → 提示消失、手势作废 | `:281-302` DragGesture 喂 `.dragOut`（`:292-294`）⇒ `WDToolbarTooltip.swift:86-87` `.voidGesture`；`:296-299` 置闩 + onTooltipEnd | ✅ |
| isEnabled == false → 不显示提示 | `:128` 门闩分支与 `:152` context 创建都以 `item.isEnabled` 为前提；`:172` `.disabled(!item.isEnabled)` ⇒ isPressed 不会变 true | ✅ |

**action 只可能执行一次（行为论证）**：`item.action()` 在工具栏按钮路径上只有 `:134` 一处；该行只在「闩为 false」时可达。闩只有三个写入者（`:129` 吞掉后复位、`:297` 作废置位、`:324` 按下复位、`:338` 阈值置位）——**抬手分支（`:342-358`）本身不写闩**，因此「先 onChange 还是先 Button 闭包」的时序不影响结论：快抬手时闩必为 false（`:324` 下一轮复位），超阈值时闩必已 true（`:338`）。⇒ 无双执行、无漏执行。

**20. ✅ 无 .simultaneousGesture；按下态与计时由一个状态机驱动**
`grep -rn simultaneousGesture Sources/WisdomUI` 命中仅 `WDSegmentedControl.swift:100` 与 `WDSwitch.swift:402`（别的组件），WDToolbar 目录里唯一命中是**注释** `:149`（说明禁用原因）。状态机 = `WDToolbarTooltip.swift:59-98` 纯函数 `decide`；视图层只在 `:304-306`（`onChange(of: configuration.isPressed)`）与 `:281-302`（DragGesture）喂事件，`:267-270` 的按下视觉由同一 `phase` 推导。⇒ §3.3 硬要求 1 成立、硬要求 2 的"同源"成立（另见 §六.5 的两条运行时风险）。

**21. ✅ thresholdTask 只由 onChange(of: isPressed) 一处喂入**
写入点仅 `WDToolbar.swift:321-322`（进入 handlePressChange 先 cancel/nil）与 `:331`（`Task { @MainActor in … }`）；`handlePressChange` 只有一个调用点 `:305`（`onChange(of: configuration.isPressed)`，`:304-306`）。全仓 `grep 'Task {'` 在 WDToolbar 目录只有 `:331` 一处 ⇒ 无第二计时器、无轮询（合 SPEC「组件不自建计时器」的例外形态：一次性延时 + cancel）。

**22. ❌ 气泡几何：28/200/圆角 8/caption2/单行/无箭头/越界夹紧均成立，但「距按钮 8」不成立（实测推导 −6pt 重叠）**
成立部分：
- 高 28：`:158` `frame(minHeight: WDSize.tooltipHeight)` → `WDTokens.swift:206`=28；
- 最大宽 200：`:159` → `:207`=200；
- 圆角 8：`:161/:164` `WDRadius.xs` → `WDTokens.swift:172`=8；
- 文字 caption2 单行：`:154` `wdFont(WDType.caption2)`（`WDTokens.swift:235` 11/13）+ `:156` `.lineLimit(1)`；
- 实底 + hairline + e2：`:160-168`（surfaceCardSolid / borderHairline / `WDToolbarTooltipShadow` e2）、无箭头（全文无叉形/三角绘制）；
- 左右内距 8：`:157` `.padding(.horizontal, WDSpacing.s3)`（=8）；
- 越界夹紧（本人按 393pt 屏重算）：`halfMax = 200/2 + 8 = 108`；夹紧公式 `:211-215` `min(max(buttonMidX,108), 393−108=285)`，再 `:215` 换算回 overlay 局部。代入实际工具栏布局（按钮 44 热区、间距 4、容器内距 6、HStack 居中）：
  - 6 按钮（容器 296，minX 48.5）：首按钮 midX=76.5 ⇒ 夹到 **108**（局部 +53.5，气泡横向 [8,208] 屏内）；中按钮 #2…#5 midX=124.5/172.5/220.5/268.5 ⇒ **不夹**（局部 +22，居中）；尾按钮 midX=316.5 ⇒ 夹到 **285**（局部 **−9.5**，向左平移，横向 [185,385] 屏内）；
  - 1/2/4 按钮：全部不夹（局部 +22），横向均在 [0,393] 内。
  ⇒ 「平移进安全区、内侧留 8、不做箭头」成立。
**不成立部分（违反设计 14 §3.2 表「距按钮热区上边 8」+ §4.4 清单「提示高 28、最大宽 200、距按钮 8、圆角 8」）**：
`WDToolbarTooltip.swift:218` `.position(x: localMidX, y: -WDToolbarTooltip.gapAboveButton)`。`.position(x:y:)` 定位的是**视图中心**，而 `gapAboveButton = WDSize.tooltipOffset = 8`（`:148`）；气泡高 28 ⇒ 中心必须在 `-(8 + 28/2) = -22` 才能让下边缘距按钮上边 8pt。现值 `y = -8` ⇒ 气泡占 `y ∈ [-22, +6]`，**下边缘越进按钮热区 6pt**；叠加出现时的 `-4pt` 位移（`:171`）后中心到 −12 ⇒ 仍占 `y ∈ [-26, +2]`，**仍重叠 2pt**。两种取值都不是设计要的 8pt 间隙。设计 §3.2 末尾的说明（"加箭头总高 36 = 按钮高会粘连，无箭头 + 8pt 间距更干净"）证明该 8 是**边到边间距**，不是中心距。
**必须修**（`offset(y:)` 在可见态是**常驻** −4，所以稳态中心 = `position.y − 4`）：要稳态间隙 8pt 需稳态中心 = −22 ⇒ `position.y = −18`，即 `y: -(WDSize.tooltipOffset + WDSize.tooltipHeight / 2 - WDToolbarTooltip.appearOffset)`；或把 4pt 位移改成 `offset(y: isVisible ? 0 : 4)`（未显示时下移 4，显示时归零）并保留 `y: −22`。当前形态（稳态重叠 2pt）与 §4.4 该勾选项不符。
（其余几何项 ✅，本条整体判 ❌，仅此一处偏差。）

**23. ✅ 出现 120ms easeOut + 上移 4pt；消失 160ms；Reduce Motion 无位移**
`:142` `appearDuration = 0.12`（R7 行内豁免，注明设计 §4.2-Q2 默认执行项）；`:144` `disappearDuration = WDMotion.Duration.fast`（0.16）；`:146` `appearOffset = 4`；`:170-171` `opacity(isVisible ? 1 : 0)` + `offset(y: isVisible ? (reduceMotion ? 0 : -4) : 0)`；`:172-177` `isVisible ? .easeOut(0.12) : .easeOut(0.16)`（不用 spring）⇒ §3.4 三行全中。

**24. ✅ 提示不进无障碍树；按钮仍保留必填 accessibilityLabel**
气泡 `:178` `.accessibilityHidden(true)`（+ `:179` `.allowsHitTesting(false)`）；按钮 `WDToolbar.swift:10` `public let accessibilityLabel: Text`（**非可选**，构造 `:19-33` 必传）+ `:174` `.accessibilityLabel(item.accessibilityLabel)` 未被改动；提示文案 `:164` 直接复用 `item.accessibilityLabel`（§3.5 同源，零新字段）。

---

## 四、跨切面

**25. ✅ 三份实现互不踩文件（write scope 无重叠）**
A-11：WDAvatar/{WDAvatar.swift, WDAvatar+Previews.swift}、Foundation/Tokens/WDMemberTone+Assign.swift、Internal/Controls/WDAvatarMetrics.swift、Tests/…/WDAvatarTests.swift；
A-13：WDCard/{WDCard.swift, WDCardMedia.swift}、Tests/…/WDCardTests.swift（+ `DemoComponentCatalog.swift:694` 一行穷尽 switch）；
A-14：WDToolbar/{WDToolbar.swift, WDToolbarTooltip.swift}、Tests/…/M5ComponentsTests.swift。
四组文件集合**两两不相交**；`WDToolbar+Previews.swift`（11-13）、`WDCard+Previews.swift`（11-15）未被本批改动。t6 的 delta 仅 `M5ComponentsTests.swift`（R2-F1 测试行）与 `.gitignore`（R2-F6），均在已登记范围。

**26. ✅ generated/ 未手改；无跨仓**跟踪文件**写入**
- `node ../wisdomdesign/tools/token-build/build.js --check` **exit 0** ⇒ 三个 generated 文件与生成器输出逐字节一致（`WDTokens.swift`/`WDTokensVersion.swift`/`WDColorSlots.swift` 的改动随令牌 v1.1.0 变更集，mtime 11-21 11:38，早于本批实现 17:56–18:01 且与生成结果一致）；
- `git status`（iOS 仓）无 `Foundation/generated` 条目（`grep -c` = 0）；
- `../android`：**跟踪文件改动 0**（`git status --porcelain | grep -v '^??'` 空）；`../wisdomdesign`：**跟踪文件改动 0**。
**观察项（不判失败，也无法归因）**：两仓各有**未跟踪**的 `ai/` 产物（`android/ai/skill-provider/api/cards/*.json` mtime 11-21 18:48、`wisdomdesign/ai/skill/**` 11-21 18:17–18:26），与 iOS 侧 `ai/`、`AIStarter/` 同族模板产物；无跟踪引用、非本批实现产物（本批最后的实现文件 mtime 18:01:32），不能从 mtime 判定写入者。登记给 t6/船长处置，不构成本次实现越界。

**27. ✅ 三条门禁 exit code（本人实跑，未抄实现者）**
| 命令 | exit | 实测输出 |
| --- | --- | --- |
| `cd iOS && ./Scripts/check-structure.sh --strict` | **0** | `wd-structure-check: root=. files=196 rules=22 errors=0 warnings=0 suppressed=259` |
| `cd iOS && ./Scripts/check-format.sh` | **0** | `check-format: files=212` … `OK（212 个文件全部通过 --strict）` |
| `cd iOS && CFFIXED_USER_HOME=… xcodebuild build-for-testing -scheme WisdomDesign-iOS-Package -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/dd OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox' -quiet` | **0** | `-quiet` 无输出；`EXIT_CODE=0`（另跑 `.build/dd-r2verify` 冷编同样 exit 0，仅 2 条既有 `var phase` warning） |

---

## 五、repair 后四项重点复核（任务点名）

| # | 项 | 结论 | 证据 |
| --- | --- | --- | --- |
| 1 | A-14 门闩单一执行路径（Button 闭包 = 唯一 action 路径） | ✅ | `WDToolbar.swift:124-135`（闩检查 `:127-131`、`item.action()` `:134`）；context 无 `onAction`（`WDToolbarTooltip.swift:114-124`，全目录 grep 0 命中）；抬手分支 `:342-358` 只判定不执行 |
| 2 | `.dragOut` 是否由 DragGesture 喂入 | ✅ | `WDToolbar.swift:281-302` `DragGesture(minimumDistance: 1, coordinateSpace: .local)` → `:292-294` `decide(.dragOut(at: systemUptime), …)` 是仓内唯一 `.dragOut` 事件源（另一处是测试）；`minimumDistance: 1 ≥ 1` 合 SPEC §3.4（禁的是 0） |
| 3 | A-13 `hasMediaBand = style == .media` | ✅ | `WDCard.swift:180-182`（不再看 `media != nil`）；配套 `:157` `media ?? WDCardMedia(nil)` ⇒ `.media` + nil 载荷 = 灰底带（与 `contracts/WDCard.yaml`、doc、测试三方一致） |
| 4 | A-13 淡入是否由 onChange 驱动 | ✅ | `WDCard.swift:326-329` `.onChange(of: media.image != nil) { _, isReady in guard isReady … appeared = true }`；`:322-325` `onAppear` 仅兜底"首帧已带图"；⇒ nil→ready 可观察，不依赖 onAppear 重入 |

---

## 六、【无法验证】清单（不写成"通过"，也不作为否决理由）

1. **单测执行**（WDAvatarTests / WDCardTests / M5ComponentsTests 的 A-11/A-13/A-14 用例）：本机 PTY 耗尽。**本轮实测证据**：`xcodebuild test-without-building … -only-testing:WisdomUITests/WDAvatarTests` ⇒ **exit 65**，报错 `Pseudo Terminal Setup Error … Underlying Error: The operation couldn't be completed. Operation not permitted`（41.8s 后失败）。测试**代码**随 `build-for-testing` 编译通过（test bundle `.build/dd/Build/Products/Debug-iphonesimulator/WisdomUITests.xctest`）。
2. **8 态快照**：无法录制/比对；本批也未新增 A-11/A-13/A-14 快照（`WDAvatarSnapshotTests.swift:41`、`WDCardSnapshotTests.swift:57`、`M5SnapshotTests.swift:107` 仍只覆盖既有 8 态，零新基线）⇒ 照片/四色/media 带/tooltip 的视觉证据 = **欠账**。
3. **真机长按手势回归**（§4.3 D-7：500ms 内点按 vs 超时抬手）：无真机，未做。
4. **像素探针**（tone 底色 / 照片圆心 / 回退档底色）：探针代码就位（`WDAvatarTests.swift:263-283`），**执行⚪**。
5. **两条运行时风险（静态可指出，但只能运行验证）**——列给评审，不单独判失败：
   - `WDToolbar.swift:260-261` 的 `phase` / `thresholdTask` 是 **`ButtonStyle` 内的 `@State`**。仓库已有同型先例（`WDButton.swift:157` `@State isHovering`）且本轮 `build` 通过，但"ButtonStyle 非 View、@State 是否有持久存储"只能运行时确认；若失效，§3.3 的仲裁会退化（提示不出现 / 计时不取消）。
   - `WDToolbar.swift:104-109` `latchFor` 在 **body 求值期间**写 `@State arbitrationLatches`，运行时有 "Modifying state during view update" 警告风险；同样只能运行时确认。
6. **AX 树实际内容**（图片默认 hidden、给 label 进树、提示不进树）：静态条件已具备，树内容未实测。
7. **观察（不判失败）**：气泡高用 `.frame(minHeight: 28)`（`WDToolbarTooltip.swift:158`）而非固定高，`wdFont(WDType.caption2)` 会随动态字体放大（`WDFont.swift:27-36` 走 `.system(textStyle)`）⇒ 大字号下气泡会长于 28。这是库规 R9（禁 `frame(height:)` 绑令牌）与无障碍放大的必然结果，设计 §3.2「高 28」只能作为**默认档**理解；如需严格 28 请设计裁决，本轮不判违反。

---

## 七、结论（证据层，非评审 verdict）

- **27 条：26 条 ✅（带 file:line）、1 条 ❌（#22 气泡「距按钮 8」稳态重叠 2pt）、0 条整条无法验证**（运行时子项按 §六 逐项标 ⚪）。
- 唯一 ❌ 是**静态可复算的几何偏差**，不是架构问题：`WDToolbarTooltip.swift:218` `.position(y: -8)` 定位的是**中心**，叠加常驻的 −4 位移后稳态中心 = −12，气泡高 28 ⇒ 下边缘到 +2，**侵入按钮热区 2pt**；设计 §3.2 表与 §4.4 清单要求**边到边 8pt**。修法见 #22 行（`y: −18`，或把 4pt 位移改成 `isVisible ? 0 : 4` 并保留 `y: −22`）。
- 其余高度关注项在**当前字节**上成立：FNV 五 fixture（本人独立复算）、回退链顺序、2pt 描边 + 宿主底色、四色零硬编码、单次 clipShape 四档零变化、hasMediaBand=style==.media、淡入 onChange 驱动、.dragOut 由 DragGesture 喂入、门闩单一执行路径（action 只可能一次）、thresholdTask 单入口、120/160ms + Reduce Motion。
- **不得写成"测试通过"**：单测执行、8 态快照、真机长按、像素探针一律【无法验证】（§六，附实测 exit 65 证据）。

> **⚠ 本节 #22 结论已被 §八 取代**：captain 按方案①修复后，普通动效分支已达标（稳态中心 −22 / 下边缘 −8 / 8pt），但 **Reduce Motion 分支仍只有 4pt ⇒ §八判定不成立并要求补修**。§一–§七 其余 26 条结论不变。

---

## 八、#22 修复复核（round-3 · 窄域）

> 复核人：wd-verifier（t11，attempt 1，attempt_id=313856bb-7a1e-48e6-ae8d-ebb89b458ab2）
> 绑定字节：`WDToolbarTooltip.swift` **mtime 2026-11-22 09:03:29**（其余 8 个被测文件 mtime 未变，diff 仅本文件 +6/−1 行）。
> 范围：只复核 #22 的纵向几何修复；不重开 §一–§七 其它条目。

### 8.1 修复内容（当前字节）

| 位置 | 现值 |
| --- | --- |
| `WDToolbarTooltip.swift:156` | `static let verticalCenterY: CGFloat = -(gapAboveButton + tooltipHalfHeight - appearOffset)` = **−18** |
| `:159` | `static let tooltipHalfHeight: CGFloat = 14`（R7 行内豁免，注明 28/2） |
| `:148` | `gapAboveButton = WDSize.tooltipOffset` = **8**（`WDTokens.swift:208`） |
| `:146` | `appearOffset = 4`（R7 行内豁免，设计 §3.4 出现位移） |
| `:182` | `.offset(y: isVisible ? (reduceMotion ? 0 : -appearOffset) : 0)` |
| `:229` | `.position(x: localMidX, y: WDToolbarTooltip.verticalCenterY)` —— 旧写法 `-gapAboveButton` 已不存在 |

**纵向合成规则（本人从代码读出，不是抄注释）**：`.offset` 是渲染期变换，`.position` 定的是布局中心 ⇒ **视觉中心 = position.y + offset（可见时）**。

### 8.2 普通动效分支：✅ 成立（#22 原缺陷已修）

| 状态 | position.y | offset | 视觉中心 | 气泡 y 区间（高 28） | 下边缘到按钮顶边 | 侵入热区 |
| --- | --- | --- | --- | --- | --- | --- |
| 可见态稳态 | −18 | −4 | **−22** | [−36, −8] | **8pt** ✅ | 0 |
| 入场首帧（isVisible 刚变 true） | −18 | 0→−4 的动画起点 0 | −18 | [−32, −4] | 4pt（**瞬时**，120ms 内回到 8） | 0 |

⇒ 稳态满足设计 14 **§3.2 表「距按钮热区上边 8」**（`:238`）与 **§4.4 清单「提示高 28、最大宽 200、距按钮 8、圆角 8」**（`:353`）；原实现（`y=−8`，稳态中心 −12、下边缘 +2、**侵入 2pt**）的缺陷已消除。入场首帧 4pt 是设计 §3.4「上移 4pt」动画的**起点**，不是稳态，不构成违反。

### 8.3 Reduce Motion 分支：❌ **不成立 —— 稳态间距只有 4pt（违反 §3.2 / §4.4）**

RM 下 `:182` 的 offset 恒为 **0**（可见与不可见都是 0），而 `verticalCenterY` 是**编译期常量**、不含 RM 感知 ⇒

| 状态 | position.y | offset | 视觉中心 | 气泡 y 区间 | 下边缘到按钮顶边 | 判定 |
| --- | --- | --- | --- | --- | --- | --- |
| RM 可见态 | −18 | 0 | **−18** | **[−32, −4]** | **4pt** | ❌ 设计要求 8 |

差额 = `appearOffset` = 4pt。原因：`verticalCenterY` 用「减掉 4」把动画位移**预支**进了常量，这一预支只在 offset 真的施加时成立；RM 把位移去掉后，预支无处偿还 ⇒ 永久少 4pt。

**是否违反设计？—— 是。** 设计 §3.4 的「减弱动态 ⇒ 只淡入淡出、无位移」约束的是**动效**，没有授权改**静态间距**；§3.2 的「距按钮热区上边 8」是几何定稿值（§4.4 清单逐项可勾）。RM 用户拿到的仍是「28 高、距 8」的气泡，只是不位移。4pt 间距 = 未达验收清单。

**requiredFix（二选一，推荐 B）**

- **A（最小改）**：让中心随 RM 取值 —— `WDToolbarTooltipAnchor` 读 `@Environment(.accessibilityReduceMotion)`，`y = reduceMotion ? -(gapAboveButton + tooltipHalfHeight) : verticalCenterY`（即 RM 用 **−22**、普通用 **−18**）。两分支稳态都是下边缘 −8。
- **B（推荐，顺带修掉 8.4）**：**改下边锚定**，不再用中心定位：
  ```swift
  // overlay(alignment: .top) 内
  tooltip
    .alignmentGuide(.top) { d in d[.bottom] + WDToolbarTooltip.gapAboveButton }
    .offset(y: isVisible ? 0 : WDToolbarTooltip.appearOffset)   // 从下 4pt 归零
  ```
  这样间距由**气泡真实高度**决定，普通 / RM / 大字号三种情况恒为 8pt；4pt 位移改成「起点在下、终点归零」，不再需要把位移预支进几何常量（`verticalCenterY` 与 `tooltipHalfHeight` 可一并删除）。

### 8.4 附带发现（low · 同一根因）：中心定位 + 固定 14 半高，在**大字号**下会二次压缩间距

气泡高是 `.frame(minHeight: 28)`（`:169`）而非定高，`wdFont(WDType.caption2)` 随动态字体放大（`WDFont.swift:27-36` 走 `.system(textStyle)`）。中心固定 ⇒ 高度增长全部向下吃掉间距：

| 气泡实际高 | 普通稳态下边缘间距 | RM 下边缘间距 |
| --- | --- | --- |
| 28（默认档） | 8.0pt ✅ | **4.0pt** ❌ |
| 32（约 AX1） | 6.0pt ⚠ | **2.0pt** ❌ |
| 36（约 AX2–3） | 4.0pt ⚠ | **0pt（贴边）** ❌ |
| 40 | 2.0pt ⚠ | **−2pt（侵入 2pt）** ❌ |

⇒ 设计 §3.2 的「高 28」只能作默认档理解（R9 禁 `frame(height:)` 绑令牌，放大是必然的）；但**间距**不该随字号变化。方案 B（下边锚定）一次覆盖 8.3 与 8.4；只做方案 A 则 8.4 仍在（普通档大字号会压到 2–4pt）。**建议直接采用 B。**
（另注：`tooltipHalfHeight = 14` 是手写常量而非 `WDSize.tooltipHeight / 2`，令牌若改值会静默失同步 —— 采用 B 后可整条删除，此项随之消失。）

### 8.5 第二处 `-gapAboveButton` 作为中心？—— 无

`grep -rn 'gapAboveButton'`（全仓 Sources/Tests/Examples，排除 .build）= 4 处命中，全部在本文件内：`:148` 定义、`:155` 缺陷说明注释、`:156` `verticalCenterY` 组成项；**没有任何地方再把 `-gapAboveButton` 直接当中心用**。
`grep -rn '\.position('`（Sources/WisdomUI）= **1 处**（`:229`），纵向只有一个定位入口。
`grep -rn 'offset('` WDToolbar 目录 = **1 处**（`:182`），纵向只有一处位移。
⇒ 纵向几何只有「`:229` 中心 + `:182` 位移」这一条链路，无第二处错误点。

### 8.6 三处常量与设计 §3.2 的对应

| 常量 | 值 | 设计出处 | 判定 |
| --- | --- | --- | --- |
| `gapAboveButton` | 8（`WDSize.tooltipOffset`，`WDTokens.swift:208`） | §3.2 `:238`「距按钮热区上边 **8**（`size.tooltip.offset`）」 | ✅ 令牌直取，零硬编码 |
| `tooltipHalfHeight` | 14（手写，R7 豁免） | 由 `size.tooltip.height` = **28**（`WDTokens.swift:206`）取半 | ⚠ 值对，但应写 `WDSize.tooltipHeight / 2`（见 8.4 末注） |
| `appearOffset` | 4 | §3.4 `:273`「出现 120ms 淡入 + **上移 4pt**」 | ✅ 值对；**用法错**（预支进静态几何 ⇒ 8.3） |

### 8.7 门禁（本人实跑，当前字节）

| 命令 | exit | 输出 |
| --- | --- | --- |
| `./Scripts/check-structure.sh --strict` | **0** | `files=196 rules=22 errors=0 warnings=0 suppressed=260`（较上轮 +1：新增 `tooltipHalfHeight` 的 R7 行内豁免） |
| `./Scripts/check-format.sh` | **0** | `files=212` … `OK（212 个文件全部通过 --strict）` |
| `xcodebuild build-for-testing …（任务命令）` | **0** | `-quiet` 无 error（`BUILD_EXIT=0`） |
| 单测执行 / 快照 / 真机长按 | — | **【无法验证】**（PTY 耗尽，未变；见 §六） |

### 8.8 §8 结论

- **#22 在普通动效分支：已修复 ✅**（稳态中心 −22、下边缘 −8、8pt、不侵入）。
- **#22 在 Reduce Motion 分支：仍不成立 ❌**（中心 −18、下边缘 −4、仅 **4pt**），违反设计 14 §3.2 表 `:238` 与 §4.4 清单 `:353`。requiredFix 见 8.3（推荐方案 B：下边锚定 + 位移改为「起点在下、归零」）。
- **无第二处纵向几何错误**（8.5）；`tooltipHalfHeight` 建议改令牌推导或随 B 删除（8.4/8.6）。
- 本次修复未触碰仲裁、无障碍、横向夹紧与其它 26 条结论；门禁三门全绿。
---

## 九、#22 下边锚定重构复核（round-4 · 窄域，含像素探针实测）

> 复核人：wd-verifier（t12，attempt 1，attempt_id=41e041c6-d018-4d3f-97c3-3e1adecafc22）
> 绑定字节：`WDToolbarTooltip.swift` **sha256 `386301ee…855db`，mtime 2026-11-22 09:07:59**（`WDToolbar.swift` 未动：`742c3e91…a711`）。
> 方法：**不再只做静态推导** —— 本轮用 macOS host 的 `ImageRenderer` + 逐像素求白块 bbox，
> 复刻当前定位结构（44×44 按钮 + 真实 `Text`/`caption2`/`padding`/`minHeight`/`fixedSize` 气泡），
> 直接量「气泡下边缘到按钮顶边的像素距离」与「气泡中心 x 相对按钮中心的偏移」。
> 探针放在仓外 `/tmp/wdprobe/`（**不入仓**，不污染 format 门禁；首次误放 `.review-temp/` 已删除并复跑门禁确认恢复绿）。
> 环境：仍无模拟器/真机，**iOS 运行时未验证**；探针 = 同一 SwiftUI 布局引擎的 macOS host 渲染，用于判定**布局语义**（不是外观验收）。

### 9.1 结论先行

| 验收项 | 判定 |
| --- | --- |
| ① 稳态下边缘恒 −8（普通 / RM / 大字号） | **❌ 全部不成立** —— 实测气泡**整块压在按钮上**（重叠 28/36/44pt），三种高度都错 |
| ② 横向居中（`.leading` guide 替代 `.position(x:)`） | **❌ 不成立** —— 实测 Δ中心x = **−4.0pt** |
| ③ `alignmentGuide` 用法是否正确 | **❌ 用法错误**：两条 guide 挂在 **`GeometryReader` 的直接内容**上，**布局期被完全忽略** |
| ④ 三条门禁 | ✅ structure / format / build 全 exit 0（**门禁抓不到此缺陷**：它是布局语义，不是编译/风格问题） |

⇒ **round-4 重构是回归**：`#22` 从 §8 的「普通分支已达标（8pt）」退化为「气泡完全覆盖按钮」。

### 9.2 根因（`alignmentGuide` 的作用域）

`WDToolbarTooltip.swift:212-233`：两条 `.alignmentGuide` 直接挂在 **`GeometryReader` 的内容**上。

`alignmentGuide` 不是「给视图设偏移量」，而是**向父容器声明**「我的这条对齐边在哪」，只有当**父容器是消费该对齐维度的栈/覆盖容器**（`ZStack` / `overlay(alignment:)` / `VStack` / `HStack`）时才生效。
`GeometryReader` 把内容放在自己的 **topLeading** 且**不消费自定义对齐导引** ⇒ 两条 guide 成为**死代码**，气泡退化为「贴按钮左上角」。

实测（画布 260×260，按钮 44×44 居中 ⇒ 按钮 x[108,151] y[108,151]）：

| 实现 | 气泡 bbox | 下边缘到按钮顶边 | Δ中心x | 判定 |
| --- | --- | --- | --- | --- |
| **现状（GR 内两轴 guide）h=28** | y[108…135] | **−28（重叠 28pt）** | **−4.0** | ❌ |
| 现状 h=36 | y[108…143] | **−36（重叠 36pt）** | −4.0 | ❌ |
| 现状 h=44 | y[108…151] | **−44（重叠 44pt）** | −4.0 | ❌ |
| 现状 h=28 + Reduce Motion | y[108…135] | **−28（重叠 28pt）** | −4.0 | ❌ |
| 对照：§8 的 `.position(x:22, y:−22)`（上轮形态） | y[72…99] | **8** | 0.0 | ✅ |

⇒ 气泡左上角正好落在按钮左上角 (108,108)，即典型「guide 未被消费、内容按 topLeading 摆放」。
**这也解释了 §8 的 `.position` 形态为什么对：`.position` 是渲染期几何变换，不依赖父容器消费 guide。**

### 9.3 requiredFix（最小改，已用探针验证 8pt 恒成立）

保留 `GeometryReader`（横向夹紧要 `buttonFrame`），但**在 GR 内插入一个真正消费 guide 的容器**：

```swift
GeometryReader { proxy in
  let buttonFrame = proxy.frame(in: .global)
  let buttonMidX = buttonFrame.midX
  let halfMax = WDSize.tooltipMaxWidth / 2 + WDToolbarTooltip.screenEdgeInset
  let screenWidth = UIScreen.main.bounds.width
  let clampedGlobalMidX = min(max(buttonMidX, halfMax), screenWidth - halfMax)
  let localMidX = clampedGlobalMidX - buttonFrame.minX

  // ← 新增这一层：Color.clear 撑满 GR，用 overlay(alignment: .topLeading) 消费两条 guide
  Color.clear.overlay(alignment: .topLeading) {
    WDToolbarTooltip(text: text, isVisible: isVisible)
      .fixedSize(horizontal: true, vertical: true)
      .alignmentGuide(.top) { $0[.bottom] + WDToolbarTooltip.gapAboveButton }
      .alignmentGuide(.leading) { $0[.trailing] / 2 - localMidX }
  }
}
```

**探针实测（同一夹具，逐项）：**

| 场景 | 气泡 bbox | 下边缘间距 | Δ中心x | 判定 |
| --- | --- | --- | --- | --- |
| h=28 可见 | y[72…99] | **8pt** | 0.0 | ✅ |
| h=36 可见（模拟动态字体放大） | y[64…99] | **8pt** | 0.0 | ✅ |
| h=44 可见 | y[56…99] | **8pt** | 0.0 | ✅ |
| h=28 **Reduce Motion** 可见 | y[72…99] | **8pt** | 0.0 | ✅ ← **§8.3 的 RM 缺陷一并解决** |
| h=28 入场态（`isVisible=false`，offset +4） | y[76…103] | 4pt（**瞬态**，120ms 内归 8） | 0.0 | ✅ 设计 §3.4 位移语义 |
| h=28 越界夹紧 `localMidX=2`（左移 20） | y[72…99] | 8pt | **−20.0**（按夹紧量平移） | ✅ |
| h=44 + 夹紧 `localMidX=2` | y[56…99] | **8pt**（高度变了间距不变） | −20.0 | ✅ |

⇒ 三项验收（① 恒 8pt、② 横向居中/夹紧、③ guide 生效）**全部由该修法满足**，且**不需要** `verticalCenterY`/`tooltipHalfHeight`（已按 §8 建议删除；本轮 `grep verticalCenterY|tooltipHalfHeight` = **0 命中**）。

### 9.4 逐项回答 captain 的三问

**① 稳态下边缘是否恒 −8？—— 现状不成立，修后成立。**

| 高度 | 现状实测 | 修法实测 |
| --- | --- | --- |
| 28（默认） | 重叠 28pt | **8pt** |
| 36（AX 放大） | 重叠 36pt | **8pt** |
| 44 | 重叠 44pt | **8pt** |
| 28 + Reduce Motion | 重叠 28pt | **8pt** |

**② 横向居中在 `.leading` guide 下是否仍对齐？—— 现状不成立（Δ=−4），修后成立（Δ=0），夹紧也正确。**

公式本身是对的：`leading = halfWidth − localMidX` ⇒ 左边缘 = `localMidX − halfWidth` ⇒ 中心 = `localMidX`（探针在 h=28/36/44 三种情形下 Δ 均为 0.0）。
问题**不在公式，在 guide 没被消费**：气泡退到按钮左缘后 Δ 恰好 = `(buttonWidth − bubbleWidth)/2 = (44−36)/2 = 4` —— **看起来像「取半错了」，实际是根本没定位**。这点特别容易误判，请注意。

**③ `alignmentGuide` 用法是否有错？—— 有，见 9.2。** 补充两点：
- `overlay(alignment: .top)` 的**横向**维度是 `.center`，所以挂在内容上的 `.leading` guide **即使被消费也可能与 .top 的横向语义打架**；`Color.clear.overlay(alignment: .topLeading)` 把**两个维度都显式指定**（top + leading），正好对应要的两条 guide。探针已验证。
- 最外层 `content.overlay(alignment: .top)` **保留不动**是对的（那是「气泡挂在按钮上方」的容器）；错的只是 GR 内部少了消费 guide 的那一层。

### 9.5 附：`offset` 语义本轮已正确（无需再改）

`:177` `.offset(y: reduceMotion ? 0 : (isVisible ? 0 : Self.appearOffset))` —— 稳态恒 0、入场从 +4 上移、RM 恒 0，**不再把位移预支进静态几何**。§8.3 的根因确已消除（只要 9.3 的定位修好，RM 就是 8pt）。这部分改法是对的。

### 9.6 门禁（本人实跑，当前字节）

| 命令 | exit | 输出 |
| --- | --- | --- |
| `./Scripts/check-structure.sh --strict` | **0** | `files=196 rules=22 errors=0 warnings=0 suppressed=260` |
| `./Scripts/check-format.sh` | **0** | `files=212` … `OK（212 个文件全部通过 --strict）` |
| `xcodebuild build-for-testing …（任务命令）` | **0** | `-quiet` 无 error（`BUILD_EXIT=0`） |
| 单测执行 / 快照 / 真机长按 | — | **【无法验证】**（PTY 耗尽，未变） |

**警示（流程）**：三条门禁**全绿**，但 §9.1 的缺陷是**布局语义**问题，门禁在结构上抓不到 —— 这正是本轮改用像素探针的原因；「门禁绿」不能替代「几何正确」。
**另注**：本人首次把探针写进 `.review-temp/`（`.swift` 在 format 清单内）导致 `check-format` 一度 exit 1；**已删除并复跑**，上表是清理后的结果（`ls .review-temp/*.swift` = 不存在）。

### 9.7 §9 结论

- **round-4 重构不成立 ❌（回归）**：`alignmentGuide` 挂在 `GeometryReader` 直接内容上**不被消费**，气泡退化为贴按钮左上角 ⇒ 稳态重叠 28/36/44pt、横向偏 −4pt；`#22` 相比 §8 反而更差。
- **requiredFix = 9.3 的 `Color.clear.overlay(alignment: .topLeading) { … guide … }`**，探针实测 h=28/36/44 + RM 全部 **8pt**、横向 Δ=0、夹紧按量平移。改动是**插入一层容器**，不动 `offset`/`animation`/仲裁/无障碍。
- 若不愿引入 `Color.clear` 容器，**回退 §8 的 `.position(x: localMidX, y: …)` 形态也可**（探针实测 8pt）——但那要重新处理 RM 的中心取值（§8.3 方案 A）。**推荐 9.3**：一次同时满足 8pt 恒定、RM、大字号三件事。
- 复核范围仅限纵向/横向定位；仲裁（§三）、无障碍（#24）、A-11/A-13 各条**不受本次重构影响**，结论仍按 §一–§七。
---

## 十、终验：V4-F1 修复后（round-5 · 窄域，同一像素探针复测）

> 复核人：wd-verifier（t13，attempt 1，attempt_id=5da0395f-4c2d-4419-9b6f-a2908d25b935）
> 绑定字节：`WDToolbarTooltip.swift` **sha256 `4497fd37…be670`，mtime 2026-11-22 09:14:57**（上一轮 §9 绑定的是 `386301ee…855db` / 09:07:59，已失效）。
> 方法：**沿用 §9 的同一像素探针**（macOS host `ImageRenderer` + 逐像素白块 bbox，44×44 按钮 + 真实 `Text`/`caption2`/`padding`/`minHeight`/`fixedSize`），探针在仓外 `/tmp/wdprobe/`，**未入仓**。
> 环境：仍无模拟器/真机 ⇒ **iOS 运行时未验证**；探针用于判定布局语义，不是外观验收。

### 10.1 结论：**pass** —— V4-F1 / V4-F2 / V4-F3 全部闭合

| 验收项 | 判定 | 实测 |
| --- | --- | --- |
| ① h=28 / h=36 / h=44 / Reduce Motion 四种下边缘距按钮顶边 = 8pt（±1） | **✅ 全通过** | 8 / 8 / 8 / 8 pt |
| ② 横向 Δ中心x = 0；越界夹紧按量平移且间距不变 | **✅ 全通过** | Δ=0.0；夹紧 −20.0 时纵向仍 8pt |
| ③ V4-F3（`overlay(.top)` 与 `.leading` 维度冲突）已消除 | **✅** | 中间层改 `.overlay(alignment: .topLeading)`（:228），两维显式指定 |
| ④ 无回归：round-4 旧结构仍复现缺陷、§8 形态仍通过 | **✅** | 旧结构 −28pt / Δ−4.0；§8 `.position` 8pt / Δ0.0 |
| ⑤ 点击路径未被中间层吞掉（§3.6 长按非唯一入口） | **✅** | 中心/左右边缘命中、按钮外与气泡区不命中，与基线一致 |

### 10.2 修复后实测（同一夹具，画布 260×260，按钮 44×44 居中 ⇒ x[108,151] y[108,151]）

| # | 场景 | 气泡 bbox | 下边缘距按钮顶边 | 容差 ±1 | Δ中心x |
| --- | --- | --- | --- | --- | --- |
| 1 | h=28 可见·普通动效 | y[72…99] | **8pt** | ✅ | **0.0** |
| 2 | h=36 可见·普通动效（模拟动态字体放大） | y[64…99] | **8pt** | ✅ | **0.0** |
| 3 | h=44 可见·普通动效 | y[56…99] | **8pt** | ✅ | **0.0** |
| 4 | h=28 可见·**Reduce Motion** | y[72…99] | **8pt** | ✅ | **0.0** |
| 5 | h=36 可见·Reduce Motion | y[64…99] | **8pt** | ✅ | **0.0** |

⇒ **§8.3 的 RM 缺陷与 §8.4 的大字号压缩一并闭合**：气泡高度从 28 变到 44（+57%），下边缘**纹丝不动**停在 −8 —— 这正是「下边锚定」相对「中心 − 固定半高」的意义。

### 10.3 横向居中与越界夹紧

| localMidX | 语义 | 气泡 bbox | 纵向间距 | Δ中心x |
| --- | --- | --- | --- | --- |
| 22 | 无越界（按钮中心） | y[72…99] | **8pt** | **0.0** |
| 12 | 轻微左移 | y[72…99] | **8pt** | −10.0（按量） |
| 2 | 大幅左移 20（模拟贴屏缘夹紧） | y[72…99] | **8pt** | **−20.0**（按量） |
| −8 | 极端左移 30 | y[72…99] | **8pt** | −30.0（按量） |
| 2（h=44） | 夹紧 + 大字号 | y[56…99] | **8pt** | −20.0 |

⇒ 横向位移量**严格等于** `localMidX − 22`（即夹紧量），纵向完全不受影响。`leading = halfWidth − localMidX` 公式在 guide 真正被消费后按预期工作（§9.4② 里那个「Δ=−4 像是取半错」的假象确已消失）。

### 10.4 入场瞬态（设计 §3.4）

| 状态 | 气泡 y | 间距 |
| --- | --- | --- |
| 稳态（offset 0） | y[72…99] | **8pt** |
| 入场首帧（offset +4） | y[76…103] | 4pt（**瞬态**，120ms 内归 8） |
| Reduce Motion 稳态（offset 恒 0） | y[72…99] | **8pt** |

⇒ 入场从「下方 4pt」上移到稳态 8pt 间距，符合 §3.4「120ms 淡入 + 上移 4pt」，且**不再预支进静态几何**（`:177` 稳态恒 0）。RM 下无位移、间距不变，符合 §3.4「只淡入淡出」。

### 10.5 无回归对照（用同一探针复跑旧结构，确认我上一轮的判定可复现）

| 结构 | 气泡 bbox | 纵向 | Δ中心x | 判定 |
| --- | --- | --- | --- | --- |
| round-4 旧结构（GR 内直接挂 guide） | y[108…135] | **−28（重叠）** | −4.0 | ❌ 与 §9.2 完全一致 |
| §8 形态（`.position(x:22, y:−22)`） | y[72…99] | 8pt | 0.0 | ✅ |
| **round-5 修复（当前字节）** | y[72…99] | **8pt** | **0.0** | ✅ |

⇒ 探针本身稳定（同输入同输出），说明 §9 的 blocker 判定与 §10 的通过判定是**同一把尺子**量出来的。

### 10.6 附带核查：中间层是否影响点击路径（设计 §3.6「长按不是唯一入口」）

`Color.clear` 中间层 + `overlay(alignment:)` 有挡点击的理论风险，故补一个真 `NSWindow` 合成鼠标事件探针（`/tmp/wdprobe/hittest*.swift`，仓外）：

| 点击位置 | 基线（无 overlay） | round-5 修复结构 | 一致？ |
| --- | --- | --- | --- |
| 按钮中心 (60,60) | 命中 | 命中 | ✅ |
| 按钮左边缘 (40,40) | 命中 | 命中 | ✅ |
| 按钮右边缘 (80,80) | 命中 | 命中 | ✅ |
| 按钮外 (20,20) | 不命中 | 不命中 | ✅ |
| 按钮上方气泡区 (60,105) | 不命中 | 不命中 | ✅ |

⇒ 中间层不吞点击、不扩大命中区（气泡自身 `allowsHitTesting(false)` `:185` 仍生效）。**§3.6 的点击路径保持可达。**

### 10.7 当前字节的代码形状（与 §9.3 requiredFix 逐项对齐）

| 项 | 现值 | 判定 |
| --- | --- | --- |
| 中间层 | `:228` `Color.clear.overlay(alignment: .topLeading) { … }` | ✅ 与 requiredFix 一致 |
| 纵向 guide | `:231-234` `.alignmentGuide(.top) { $0[.bottom] + gapAboveButton }` | ✅ |
| 横向 guide | `:235-240` `.alignmentGuide(.leading) { $0[.trailing]/2 - localMidX }` | ✅ |
| 外层容器 | `:205` `content.overlay(alignment: .top)` 保留 | ✅ 未动（按 §9.4③ 建议） |
| 位移 | `:177` `.offset(y: reduceMotion ? 0 : (isVisible ? 0 : appearOffset))` | ✅ 稳态 0 / 入场 +4 / RM 恒 0 |
| 已删常量 | `grep verticalCenterY|tooltipHalfHeight` = **0 命中** | ✅ |
| 已无 `.position` | `grep '\.position('` = **0 命中** | ✅ 中心定位路径彻底退出 |

### 10.8 门禁（本人实跑，当前字节）

| 命令 | exit | 输出 |
| --- | --- | --- |
| `./Scripts/check-structure.sh --strict` | **0** | `wd-structure-check: root=. files=196 rules=22 errors=0 warnings=0 suppressed=260` |
| `./Scripts/check-format.sh` | **0** | `check-format: files=212` … `OK（212 个文件全部通过 --strict）` |
| `xcodebuild build-for-testing …（任务命令）` | **0** | `-quiet` 无 error（`BUILD_EXIT=0`） |
| 单测执行 / 快照 / 真机长按 | — | **【无法验证】**（PTY 耗尽，未变） |

**探针洁净性**：`ls .review-temp/*.swift` = 不存在；全部探针在 `/tmp/wdprobe/`（仓外）。format 的 212 文件清单未含任何探针（§9 那次污染已彻底清除，本轮自检确认）。

### 10.9 §10 结论

- **V4-F1（blocker）已闭合** ✅：h=28/36/44 与 Reduce Motion 四种情形下边缘**均为 8pt**（±0，容差 ±1 富余）。
- **V4-F2（high）已闭合** ✅：Δ中心x = 0.0；越界夹紧按量平移（−10/−20/−30 精确对应），纵向间距不变。
- **V4-F3（medium）已闭合** ✅：`.overlay(alignment: .topLeading)` 双维显式指定，取代 `.top` + `.leading` 的语义冲突。
- **无回归**：点击路径（§3.6）、入场瞬态（§3.4）、RM（§3.4）、仲裁与无障碍（§三）均未受影响。
- **#22 至此在设计 §3.2 的「距按钮热区上边 8」上闭环**（默认 / 大字号 / Reduce Motion 三态一致），并顺带闭合 §8.3、§8.4 两条遗留。
- 仍需保留的**无法验证**项不变：单测执行、8 态快照、真机长按回归（PTY 耗尽 / 无真机）。
