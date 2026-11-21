# A-11 / A-13 / A-14 独立评审报告（第 1 轮）

> 评审人：wd-reviewer-glm（t5，attempt 4，attempt_id=c9f3d7dd-98de-4d57-abab-f95289b7fd03）
> 评审对象：t1（A-11 WDAvatar）、t2（A-13 WDCard.media）、t3（A-14 WDToolbar 长按提示）
> 设计真源：../wisdomdesign/docs/14-member-tones-media-tooltip.md（定稿 v1.0，2026-11-21）
> 输入材料：三份实现源码、三份测试、契约 YAML（WDAvatar/WDCard/WDToolbar）、
> wd-verifier 报告 iOS/.review-temp/A11-A13-A14-VERIFY.md（当线索用，高风险结论已自行复核）
> 环境限制：本机 PTY 耗尽、xctest 无法连接 ⇒ 一切运行时行为记【未验证】；
> 评审口径 = 代码可编译 + 静态可指认 + 设计条文对齐（含逻辑走查）。

---

## Verdict：**needs_revision**

**1 条 blocker + 6 条 high**。A-14 的仲裁状态机（纯函数）本身写对了，
但**接线层**让「长按到 500ms 后抬手不执行 action」这条设计核心保证**不成立**（F1）；
A-13 的「加载中/失败」半边（占位与淡入）存在两处与文档、契约、自测相矛盾的缺陷（F5/F6）。
A-11 整体质量最高：数值与兼容性全部复核通过，仅契约登记有缺口（F7）。

按 verdict 规则（blocker/high ⇒ needs_revision）判定。三份实现都不是方向性错误
（回退链、四色、纯函数状态机、构造层互斥的方向都对），**不需要推翻重写，需要修接线**。

---

## 一、三个必答复核结论（captain 指定）

### 1. A-14「500ms 后抬手到底会不会误触发 action？」——**会。判断点本身写对了，但它不是唯一的执行路径。**

- **状态机内的判断点**：WDToolbarTooltip.swift:66-74，decide(.release, .pressing) 分支：
  at - since < threshold → .performAction，否则 .hideTooltip（不执行 action）。
  这个纯函数判断我逐 case 走查过，**孤立地看是对的**（含边界：恰好 500ms 走「已达到」
  吞点击，与测试注释一致，设计未规定边界，口径合理）。
- **但它被绕过了**：WDToolbar.swift:113-116 的 Button { … item.action() } 闭包是
  **第二条未仲裁的执行路径**。SwiftUI Button 配自定义 ButtonStyle（非
  PrimitiveButtonStyle）时，系统手势照常在抬手时触发 action，与按住时长无关：
  - 长按 ≥ 500ms 后抬手：**Button 自己的 action 执行** ⇒ 误触发（设计 §3.3 第 2/4 行、
    C2「达到阈值即取消点击」全部失效）；
  - 500ms 内快速点按：Button 的 action **和** 状态机 .performAction → onAction()
    **各执行一次** ⇒ action 双触发（触感只打一次，来自 Button 路径）。
- **根因**：设计 §3.3 硬要求 2 明确写「按钮本体用 Button + **自定义 PrimitiveButtonStyle**」
  ——只有 PrimitiveButtonStyle 能接管激活；实现用的是普通 ButtonStyle（只管外观），
  再用 .onChange(of: configuration.isPressed) 旁路观察，无法拦截 Button 自身的激活。
  实现注释里「按钮的 action 由仲裁状态机把关」（WDToolbar.swift:129-131）与代码事实不符。

### 2. A-11 Equatable 语义——**站得住，低风险（F8，low）。**

手写 ==（WDAvatar.swift:81-85）只比 label / icon / **是否有照片**，照片负载不参与相等。
复核判断：
- Text 是 Equatable（按内容比较），WDIconName 是 String 枚举 —— 三个操作数都合法；
- SwiftUI 的结构化视图 diff **不使用** WDAvatarValue.==，照片 A→B（回退 label 相同）时
  WDAvatar 照常重建重渲染 —— 不会漏更新；
- 唯一暴露面：调用方把值喂给 Equatable 驱动的 diff（.animation(value:)、EquatableView、
  ForEach 差分）时照片更换不触发更新。类型注释（:37-41）已写明语义并给 .id(...) 逃生门。
  「有没有图」参与相等是对的（它是回退链的唯一开关）；「图的内容」不参与相等在设计上
  与「Image 无值语义」一致。**结论：语义成立，保留；建议把 .id() 提示也写进
  init(image:) 的 doc（现只在类型注释）。**
- 注意一个连带正确性：.animation(photoFade, value: showsPhoto) 驱动的插入淡入
  （默认 .opacity transition）依赖的正是「有没有图」这个维度 —— 与 Equatable 口径自洽。

### 3. A-13 互斥口径（构造层静默丢弃 vs 运行时断言）——**静默忽略的口径可接受，测试确实锁住了它。**

- init(style:media:...) 两个重载在 style != .media 时置 media = nil（WDCard.swift:93/:108），
  行为确定（不挂载）、可被单测断言（mediaMutuallyExclusive 断言
  elevatedWithMediaParam.media == nil，与实现一致），且与库「不猜调用方意图」的哲学一致；
  库组件里用 assertion 崩溃拦截误用不可取。**互斥本身不是问题。**
- A-13 真正的问题在别处（F5/F6）：media == nil 的渲染与文档/契约/测试三方矛盾；
  占位→就绪的淡入永远不触发。见下。

---

## 二、Findings

| # | 严重度 | 组件 | 一句话 |
| --- | --- | --- | --- |
| F1 | **blocker** | A-14 | Button 自身 action 绕过仲裁：长按抬手误触发、快速点双触发 |
| F2 | high | A-14 | 500ms 后抬手提示**永不消失**（设计第 4 行「抬手后 160ms 淡出」未实现） |
| F3 | high | A-14 | .dragOut 是死代码：滑出热区 <500ms 误执行 action、阈值后滑出提示卡死 |
| F4 | high | A-14 | 气泡水平定位坐标空间混用，clampedMidX 实际算出 ≈ −42，气泡大幅偏移 |
| F5 | high | A-13 | media == nil 不渲染图片带，与同文件 doc、WDCardMedia doc、契约、两条测试矛盾 |
| F6 | high | A-13 | 占位→就绪的 160ms 淡入不触发：appeared 恒 false，就绪图 opacity 0 永不可见 |
| F7 | medium | A-11 | 契约漂移：hostColor 参数与 WDAvatarImage 公开类型未登记进 contracts/WDAvatar.yaml |
| F8 | low | A-11 | Equatable 语义复核通过；建议补 doc（见上节 2） |
| F9 | low | 流程 | 验证报告 4 处 ✅ 是「存在性」检查而非行为检查；代码注释引用了不存在的类型名 |

### F1（blocker · A-14）Button 的 action 闭包是未仲裁的第二执行路径

- **problem**：WDToolbar.swift:113-116 的 Button { guard item.isEnabled …; WDHaptics…; item.action() }
  在抬手时无条件执行（ButtonStyle 只改外观、不改激活）。状态机的 .performAction → onAction()
  是另一条路径。后果（showsTooltips=true 且按钮可用时）：
  1. 长按 ≥ 500ms 抬手：Button 的 action 执行 ⇒ **误触发**（违反设计 §3.3 第 2/4 行与 C2）；
  2. 快速点按：两条路径各执行一次 ⇒ **action 双触发**；
  3. 触感只在 Button 路径打出，行为不一致。
  设计 §3.3 硬要求 2 指定 PrimitiveButtonStyle（接管激活、单一判断点）；
  实现用 ButtonStyle + .onChange 旁路观察，不满足硬要求。
- **requiredFix**：按设计改用 Button + 自定义 PrimitiveButtonStyle，由仲裁状态机驱动
  手势与激活（单一判断点真正成立）；或最小修复：给 Button 的 action 闭包加共享
  「本轮已被仲裁吞掉」门闩（如 context 里持有 gestureConsumed 标志，状态机判
  .hideTooltip/.voidGesture/.showTooltip 时置位，action 闭包检查后直接 return），
  并去掉状态机 .performAction 与 Button action 的双路径（二选一执行）。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbar.swift :113-116（旁路）；
  判断点在 iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbarTooltip.swift :66-74。

### F2（high · A-14）500ms 后抬手，提示永不消失

- **problem**：接线里阈值 Task 在 500ms 整点**必定**喂 .thresholdFired ⇒ phase 变 .tooltipShown。
  此后抬手走 decide(.release, .tooltipShown) → (.none, .consumed)（WDToolbarTooltip.swift:81-82）
  —— 决策是 .none，onTooltipEnd **永不被调**，tooltipItemID 不清 ⇒ 气泡一直挂在屏幕上。
  设计 §3.3 第 4 行明确「提示保持到**抬手后 160ms 淡出**」——未实现。
  .hideTooltip 分支（.release, .pressing, ≥threshold）在真实接线里**不可达**
  （.pressing 期间收到 release 必然 < 500ms，因为 thresholdFired 恰在 500ms 到点）。
  测试 arbitrationTooltipShownReleaseIsNoop（M5ComponentsTests.swift:519-535）把
  .none 断言成了期望值 —— **测试把缺陷编码成了行为**。
- **requiredFix**：(.release, .tooltipShown) 应返回 .hideTooltip（收尾淡出由视图层的
  气泡 .animation(value: isVisible) 160ms 完成），onTooltipEnd 清 tooltipItemID；
  同步修正两条仲裁测试的期望。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbarTooltip.swift :81-82；
  接线 WDToolbar.swift :290-304。

### F3（high · A-14）.dragOut 死代码：滑出热区的两条行为都错

- **problem**：状态机定义并测试了 .dragOut（设计 §3.3 第 5 行「500ms 后滑出热区 → 提示消失，
  手势作废」），但视图层**从未喂过**这个事件 —— handlePressChange 只区分
  isPressed 真/假，抬手与滑出（SwiftUI Button 的 isPressed 在手指离开热区时同样变 false）
  到达的是同一个 .release。后果：
  1. 按下后 <500ms 滑出热区再抬手：decide(.release, .pressing) 判 < threshold →
     .performAction ⇒ **滑出也执行 action**（与 tooltips 关闭时的 Button 原生行为
     「滑出取消」相反，开启特性反而引入回归）；
  2. 阈值后滑出：同 F2，提示卡死。
- **requiredFix**：需要区分「抬手」与「滑出」。最小可行：在仲裁路径用自建
  .onTapGesture/.drag 手势（或 PrimitiveButtonStyle 改造时一并处理）判定触点
  是否仍在热区内，滑出喂 .dragOut；修不好至少要把 <500ms 滑出写成「不执行 action」
  （否则特性开启即引入行为回归）。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbar.swift :261-304（唯一喂入口）；
  WDToolbarTooltip.swift :84-87（.dragOut 分支）。

### F4（high · A-14）气泡水平定位的坐标空间混用

- **problem**：WDToolbarTooltipAnchor（WDToolbarTooltip.swift:186-208）在
  content.overlay(alignment: .top) 里放 GeometryReader：
  proxy.size 与 proxy.frame(in: .global) **都是按钮自身尺寸**（overlay 提议的大小），
  不是屏幕宽度。代入实数（按钮热区 44、halfMax = 200/2+8 = 108）：
  clampedMidX = min(max(22, 108), 44 − 108 + 22 = −42) = −42 —— 气泡中心被放到
  按钮左缘外约 42pt，大幅偏移；下限夹紧 max(buttonMidX, halfMax) 也是把「屏幕左缘
  内缩 8」的语义放进了按钮局部坐标，任何解读下公式都不成立。静态即可证伪，
  不依赖运行时。
- **requiredFix**：统一坐标空间：读按钮 .frame(in: .global) 的 midX 与屏幕/容器宽度
  （把 GeometryReader 放到工具栏容器层，把每个按钮的全局 frame 传下去），先在全局
  算出夹紧后的中心，再换算回 overlay 局部 .position。修正后用「首按钮靠屏幕左缘」
  用例静态复算一遍。
- **file/line**：iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbarTooltip.swift :192-205。

### F5（high · A-13）media == nil 不渲染图片带 —— 与 doc、契约、测试三方矛盾

- **problem**：hasMediaBand = style == .media && media != nil（WDCard.swift:176-178）。
  WDCard(style: .media, media: nil)（含 legacy init(style:content:) 传 .media，
  其 media 恒 nil）⇒ **图片带整个不渲染**，卡片退化成普通文字卡。但：
  - WDCard.swift:19-20（同文件 doc）：「直接用 WDCard(style: .media) 不带 media 值 =
    **纯灰底图片带**」；
  - WDCardMedia.swift:6-10：「media: nil 或 image: nil … 渲染直接落到**灰底占位档**」；
  - contracts/WDCard.yaml:9：「WDCardStyle.media 与 media == null 的组合 = **空图占位
    （surface.card-sunken 灰底）**」；
  - 测试 mediaBandGeometry / mediaPlaceholderKeepsHeight（WDCardTests.swift:92-120）
    全部用 media: nil 构造并断言带高 193/96 —— **这两条测试按当前实现必然失败**
    （实测会是纯文字卡高 82，期望 274.7/146+）。t2 出口称「5 条测试就位并编译通过」
    —— 编译确实通过，但两条与实现逻辑矛盾，属于「新增了（执行即失败的）测试」，
    必须指出。
- **requiredFix**：hasMediaBand 改为 style == .media（带载荷用 media ?? WDCardMedia(nil)，
  灰底占位由 band 内 image == nil 档兜底）—— 这与 doc、契约、测试三方一致；
  改完静态复算 mediaBandGeometry 三条断言。
- **file/line**：iOS/Sources/WisdomUI/Components/Primitives/WDCard/WDCard.swift :176-178。

### F6（high · A-13）占位→就绪的 160ms 淡入永远不触发

- **problem**：WDCardMediaBand 用 @State appeared = false + .onAppear { guard media.image != nil
  else { return }; withAnimation { appeared = true } }（WDCard.swift:292-318）。
  onAppear 只在视图首次出现时触发一次。设计 §2.3 的主数据流是「先占位（WDCardMedia(nil)
  灰底）→ 图片就绪后传入新 WDCardMedia(image)」：band 的结构身份不变（同一
  WDCardMediaBand 输入更新），onAppear 不再触发，appeared 恒 false ⇒
  **就绪图片以 opacity 0 渲染、永远不可见**。WDCardMedia 也不是 Equatable，band
  无法观察输入变化。设计 §2.3「加载完成 → 160ms 淡入」对这条主流程完全不生效。
  唯一能淡入的形态是「band 首次出现时就已带图」（调用方憋到就绪才构造），那只是
  退化路径。现有测试没有覆盖 nil→ready 转换（mediaPlaceholderKeepsHeight 只测 nil 档），
  即使能跑也发现不了。
- **requiredFix**：把淡入挂到「就绪」这个可观察变化上，如
  .onChange(of: media.image != nil) { _, ready in if ready { withAnimation(…fast) { appeared = true } } }
  + onAppear 兜底，或用 .id(media.image != nil) + .transition(.opacity)；
  补一条「先 nil 后 ready」的单测（可用两个状态驱动同一卡）。
- **file/line**：iOS/Sources/WisdomUI/Components/Primitives/WDCard/WDCard.swift :292-318
  （@State appeared :292、.onAppear :315-318、opacity 绑定 :308）。

### F7（medium · A-11）契约漂移：hostColor / WDAvatarImage 未登记

- **problem**：实现公开了 hostColor: Color? = nil（WDAvatar.swift:163-177）与公开类型
  WDAvatarImage（WDAvatar.swift:14-25），但 contracts/WDAvatar.yaml 的 params 只有
  value/size/isOnline/isDisabled/tone —— **没有 hostColor**，也没有 WDAvatarValue 的
  accessibilityLabel 参数与 WDAvatarImage 类型条目。F-14 断言（params 逐行 0 不一致）
  与 I-2（批前签名冻结）面会失配。契约在设计仓（跨仓只读），需走变更集。
- **requiredFix**：集成任务里随符号快照更新一并补契约（hostColor 参数 + WDAvatarImage
  类型 + init(image:label:icon:accessibilityLabel:) 签名），保持 F-14 对齐。
- **file/line**：wisdomdesign/contracts/WDAvatar.yaml :13-34（params 段）；实现
  iOS/Sources/WisdomUI/Components/Primitives/WDAvatar/WDAvatar.swift :163-177。

### F8（low · A-11）Equatable —— 复核结论：站得住（详见一、2）

- **problem**：照片 A→B 且回退 label 相同时两值相等；调用方若将值用于
  Equatable 驱动的 diff（.animation(value:)、EquatableView、ForEach 差分），
  照片更换不会触发更新。语义已在类型注释 :37-41 写明并给 .id(...) 逃生门；
  SwiftUI 结构化 diff 不受影响（照片照常重渲染）。
- **requiredFix**：可保留语义；建议在 init(image:label:icon:accessibilityLabel:) 的
  doc 也注明 .id() 建议（现只在类型注释）。
- **file/line**：iOS/Sources/WisdomUI/Components/Primitives/WDAvatar/WDAvatar.swift :81-85。

### F9（low · 流程）验证报告的「✅」口径与注释漂移

- **problem**：A11-A13-A14-VERIFY.md 的 #19（「唯一判断点」）、#21（单状态机）、
  #22（气泡几何/越界夹紧）是**存在性**检查（代码里有这个结构），不是行为检查；
  本轮复核在同样的行号区间发现了 F1-F4。#11/#12（令牌几何、灰底）同理漏掉 F5/F6。
  另有两处注释引用不存在的类型名：WDToolbar.swift:131 引用 WDToolbarItemTooltipStyle、
  WDToolbarTooltip.swift:8 引用 WDToolbarTooltipButtonStyle（实际类型是
  WDToolbarItemPressStyle / WDToolbarItemArbitrationContext）。
- **requiredFix**：验证报告的 17/19/21/22 读作「结构存在」；注释改指真实类型名；
  修 F1-F6 后由下一轮验证重采证据。
- **file/line**：iOS/.review-temp/A11-A13-A14-VERIFY.md :19/:21/:22；
  iOS/Sources/WisdomUI/Components/Composites/WDToolbar/WDToolbar.swift :131；
  WDToolbarTooltip.swift :8。

---

## 三、独立复核清单（对 verifier 报告的处置）

**复核过且确认成立的**（不依赖运行时、可静态证伪的项全部亲自重做）：
- FNV-1a32 五个 fixture：我用独立 JS 实现重算（0x811C9DC5 / 0x01000193 / UTF-8 /
  32 位回绕），五个 ID 的哈希值与 mod 4 **逐一对上设计 §1.3 的表**（1050025199→3、
  1066802818→2、1083580437→1、966137104→0、982914723→3）；
- 成员四色 16 个色值（8 fill + 8 ink，浅/深）：WDTokens.swift:132-148 与设计 §1.2
  两张表**逐对一致**；tone-3 浅色 ink #FFFFFF、深色 ink #0A1B24 等特例都对；
- A-11 默认路径逐像素兼容：git diff 溯源 —— 旧 Circle().fill(colors.surfaceTint) →
  新 backgroundColor（tone?.fill ?? colors.surfaceTint）、colors.textOnSoft →
  foregroundColor（tone?.ink ?? colors.textOnSoft）：tone=nil 时取值路径**完全相同**；
  新增 .animation(photoFade, value: showsPhoto) 在无照片时（showsPhoto 恒 false）不触发，
  对既有值零影响；在线点描边 hostColor ?? colors.surfaceCardSolid 默认与旧值相同。
  A-14 默认路径：showsTooltips=false ⇒ arbitration=nil ⇒ plainBody 与改造前
  makeBody 逐修饰符一致（diff 亲核）；.wdToolbarTooltip 修饰符虽常挂但
  isVisible 恒 false ⇒ 透明、不命中、不进树，不改布局（overlay）。
  A-13 既有四档：background switch 仅新增 media 分支，hasMediaBand=false 时 chrome
  与改造前同构；穷尽 switch 已补（WDCard.swift:181-187、DemoComponentCatalog.swift:694）。
- A-14 状态机纯函数：六个 case 逐行走查（含边界恰好 500ms、tooltipShown 杂音、
  consumed 后杂音、不可达 default）—— 纯函数层**无逻辑错误**；问题全在接线（F1-F4）。
- A-13 几何静态推导：ZStack + .aspectRatio(1.78, .fill) + frame(minHeight: 96) 在
  VStack 定宽不定高提案下 ⇒ 带高 = max(W/1.78, 96)（343→192.7、171→96.06、120→96 夹紧），
  与设计 §2.2 实算表一致；不带 GeometryReader 的取舍理由成立；
- 仓规：AnyView 组件内 0 命中；.font(.system( 仅 WDAvatar 首字（R11 同行豁免，
  既有先例）；WDColor.* 静态入口组件实现内 0 命中（仅 Previews，有先例）；
  组件内 .environment( 写入 0 命中；无 Timer/轮询（A-14 一次性 Task.sleep，
  抬手即 cancel，实现干净可取消）；generated/ 三文件 diff 纯为 tokens v1.1.0
  变更集（版本号+新增枚举+7 个 WDSize 常量），无手改痕迹；
- 门禁本人实跑：check-structure.sh --strict exit 0（files=196，errors=0 warnings=0）；
  check-format.sh exit 0（212 全过）；build-for-testing（任务给定的唯一编译命令）
  exit 0（TEST BUILD SUCCEEDED）。

**复核后推翻 / 需修正解读的**：#19、#21、#22（见 F1-F4）；#11、#12（见 F5/F6）；
t2 出口的「测试就位」两条与实现矛盾（见 F5）。验证报告 27 条中其余静态项我抽查了
引用行号，与代码相符。

---

## 四、正面确认（做对了的）

- A-11：FNV 常数与 fixture 全对（独立重算）；四色值与设计逐对一致；回退链
  resolved（:105-116）硬顺序 photo→label→icon 且 internal 可测；照片形态
  WDAvatarImage 只在就绪时构造的架构性解法（无占位帧/破图帧）成立；
  2pt 描边走 WDSize.avatarRing，描边色宿主传入默认 surfaceCardSolid，
  在线点共用 ringColor；照片无障碍默认装饰、给标签进树；色调淡入 160ms 走
  WDMotion.Duration.fast 且无缩放。
- A-13：WDCardMedia 值类型 + 两个重载签名与契约一致；通栏（padding 只在文字区
  WDSpacing.s5=16）+ 整卡单次 .clipShape（带内无圆角）⇒ 上圆下不圆的实现方式正确；
  灰底走 surfaceCardSunken；互斥构造层强制 + 测试锁住（口径可接受）；
  按下蒙层复用 WDCardButtonStyle 覆盖整卡；图片无障碍默认装饰/给标签进树；
  几何静态推导与设计实算表一致。
- A-14：纯函数状态机（六行仲裁表逐行走查无误，边界处理合理）；无
  .simultaneousGesture（命中均在注释/其他组件）；一次性 Task.sleep 计时可取消、
  无轮询；气泡规格全走令牌（28/200/8/radius.xs/surfaceCardSolid 实底/e2/caption2/
  单行/无箭头）；120ms 出现 + 4pt 上移 easeOut、160ms 消失、Reduce Motion 去位移；
  提示 accessibilityHidden 不进树、按钮 accessibilityLabel 必填保留；
  showsTooltips 默认 false 的兼容路径逐修饰符一致。
- 三份实现互不踩文件；Internal/ 零 public；CHANGELOG/demo 已同步。

---

## 五、【未验证】清单（本轮不写「通过」）

- 一切单测执行、快照、真机手势回归（本机 PTY 耗尽、xctest 无法连接）——与验证报告
  同口径。**注意**：F5 涉及的两条测试（mediaBandGeometry/mediaPlaceholderKeepsHeight）
  按当前实现是「执行即失败」的逻辑矛盾，修 F5 后应转绿（几何静态推导支持断言值）。
- 像素级断言（tone 底色、照片渲染）、A-11 插入淡入的实际观感（.opacity 默认
  transition 推断成立，但未渲染验证）。
- A-14 真机长按手感（设计 §4.3 D-7 需真机人审）——修完 F1-F4 后再排。

---

## 六、给下一轮的修复优先级

1. **F1**（blocker，A-14 接线：PrimitiveButtonStyle 或 action 门闩）——不修则 A-14 的
   存在意义（C2 不误触）不成立；
2. **F2 + F3**（同一根因：isPressed 无法区分 release/dragOut，随 F1 的手势改造一并解决）；
3. **F4**（气泡定位换坐标空间，静态可复算验证）；
4. **F5 + F6**（A-13 占位链路：hasMediaBand 条件 + 淡入触发点，同步修两条测试）；
5. **F7**（契约补登记，并入集成批的快照更新）；F8/F9 顺手。

修完建议：仲裁表补「release in tooltipShown → hideTooltip」「滑出热区」两条真实路径的
单测；A-13 补 nil→ready 转换测试；然后第 2 轮评审。
