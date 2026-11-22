# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 的结构；版本号遵循语义化版本。
**三层版本台账**（`docs/DEV-PLAN.md` §10）：① 令牌数据（设计仓生成物）② 契约（`contracts/`）
③ **库**（本文件）。三者不一致时**先对齐再发版**。

## [Unreleased]

### Added

- **A-11 / A-13 / A-14 三条欠账收口（2026-11-21；来源 = 设计仓 `docs/14-member-tones-media-tooltip.md` 定稿 v1.0）**：成员四色 + `WDCard.media` 图片带 + `WDToolbar` 长按提示落地。
  **API 1394 → 1404 符号（+12 / −2，见下）**，`Scripts/dump-api.sh --update` 显式更新，复跑零 diff。
  执行过程：agent 团队并行实现，遭遇上游 429 限流与 MAX_TOKENS 多轮中断；reviewer-glm round-1 给出 needs_revision（1 blocker + 5 high），repair round-2 全修后 round-2 复审 **pass**（报告 = `docs/.review-temp/` 误记 → 实为 `iOS/.review-temp/A11-A13-A14-REVIEW-R1/R2.md`）。
  - **A-11 `WDAvatar`**：新增 `tone: WDMemberTone?`（nil 回落 surfaceTint，既有观感逐像素不变）、`hostColor: Color?`（照片/在线点描边色，默认 surfaceCardSolid）；照片形态 `WDAvatarImage` + `WDAvatarValue.init(image:label:icon:accessibilityLabel:)`；回退链硬顺序 照片→文字→图标（设计 §1.4）；`WDMemberTone.assign(memberID:)` FNV1a32（五 fixture 对拍设计 §1.3）。
  - **A-13 `WDCard`**：`WDCardStyle` 新增 **`.media`** —— **源级 breaking**（穷尽 switch 破，F-20：minor + Breaking 段）。迁移片段：既有 `switch style` 补 `case .media:`。新增 `WDCardMedia` 值类型与 `init(style:media:content:)` / `init(style:media:action:content:)`；图片带通栏 + 16:9 + 最小高 96 + 灰底占位（`surface.card-sunken`）+ 160ms 淡入；与 glass 互斥（构造层强制）。
  - **A-14 `WDToolbar`**：`showsTooltips: Bool = false`（默认关，既有行为不变）；开启时长按 500ms（`WDSize.tooltipPressDuration`）显示提示气泡（28 高/200 宽/距 8/圆角 8/e2 阴影），**门闩仲裁保证长按抬手不执行 action**（Button 原生闭包 = 唯一执行路径，`WDToolbarArbitrationLatch` 共享判定），滑出热区作废。
  - **符号 −2 说明**：`WDAvatar.init(value:size:isOnline:isDisabled:)` 与 `WDToolbar.init(items:accessibilityLabel:overflowAccessibilityLabel:)` 因追加带默认值参数而升级为新签名（`…tone:hostColor:` / `…showsTooltips:`）——Swift 符号路径变化，**非功能删除**：既有调用点全部照常编译（新参数全带默认值）。
  - **契约增量（待设计仓落库）**：`contracts/WDAvatar.yaml` 需补 `hostColor` 参数、`WDAvatarImage` 类型与照片 init 签名（round-1 finding F7；跨仓只读，待设计侧处理）。
  - **验证**：结构 0/0（196 文件）、格式 212 全过、build-for-testing SUCCEEDED；评审 round-2 pass（R2-F1 测试期望已修）+ round-3 pass（窄域字节绑定）。验证 round-2 重采 27 条：26 ✅ / 1 ❌（#22 气泡纵向几何）——**已修**：`position(y:)` 定位的是中心，原实现用 `-gapAboveButton`(8) 导致气泡下边缘侵入按钮热区 2pt；改为**下边锚定**——`alignmentGuide(.top)` 读气泡自身 bottom + 8，并**必须外包一层 `Color.clear.overlay(alignment: .topLeading)`**（`alignmentGuide` 只有被父容器消费才生效；直接挂在 `GeometryReader` 内容上是死代码，会把气泡压回按钮左上角）；位移改为「起点偏低、稳态归零」（稳态 0 / 入场 +4 / RM 恒 0）。实测 h=28/36/44 × 普通/RM 五种情形下边缘**恒为 8pt**（像素探针，误差 0），大字号压缩隐患（R2 §8.4）一并闭合。**单测执行 / 8 态快照 / 真机长按回归**：本机 PTY 耗尽 + 无真机，全部**【未验证】**。

- **令牌 v1.0.0 → v1.1.0 的公开符号入基线（2026-11-21）**：设计仓交付 `docs/14-member-tones-media-tooltip.md`（A-11 / A-13 / A-14 三条约数），生成器随之产出新的公开面；
  本轮按 `docs/SPEC.md` §1.5.3 用 `Scripts/dump-api.sh --update` **显式更新符号快照**。
  **API 1380 → 1394 符号（+14，零删除）**，`dump-api.sh` 复跑零 diff。
  - **新增 `WDMemberTone`（1 枚举 + 4 case + 2 属性）**：成员头像四色（`tone1`…`tone4`）的 `fill` 与 `ink` 成对，随外观解析（浅/深各一套）。
    组件私有调色板，**不进 `WDColor` 的 32 槽位**（U12 冻结不变，F-04 口径不受影响）。
  - **`WDSize` 新增 7 个尺寸/时长常量**：`avatarRing`(2)、`cardMediaAspectRatio`(1.78)、`cardMediaMinHeight`(96)、
    `tooltipHeight`(28)、`tooltipMaxWidth`(200)、`tooltipOffset`(8)、`tooltipPressDuration`(0.500，`Double`/秒)。
  - **兼容性**：**纯追加**（无改名、无删符号、无默认值变更）⇒ 源码兼容；但**破坏符号快照连续性**，故按 §2.9 规则 1 走一次显式基线更新。
  - **跨仓自证**：`check-structure.sh --tokens-trace` 全绿（`version=1.1.0`、`sha12=953044a85a8e`、manifest 覆盖 iOS 3 条产物）。
  - **范围说明**：本提交**只**更新符号快照（§1.5.3 要求基线变更与成因同提交）；`WDMemberTone` / `WDCard.media` / `WDToolbar` tooltip 的**组件侧实现**（A-11 / A-13 / A-14）仍开放，见 `docs/DEBT-LEDGER.md` §1.2/§1.4。

### Fixed

- **B18 代码欠账收口（2026-11-20；承接 `docs/DEBT-LEDGER.md` 的 A 类）**：签名冻结 = `docs/B18-SIGNATURE-FREEZE.md`、出口报告 = `docs/B18-EXIT-REPORT.md`、契约增量（待落库）= `docs/B18-CONTRACT-CHANGE-REQUEST.md`。
  **API 符号仍 1380**（只给既有 init 追加带默认值的参数）；`Scripts/dump-api.sh` 零 diff。
  - **A-1 `WDSlider` 焦点光环此前是死代码**（`WDSlider` 读 `wdFocusRingFocused`，但全仓 `.wdFocusRing()` 零调用点）⇒ 改为**焦点经 `WDAccessibilityFocusHost` 从表示层回写**；单值手柄与范围两端都挂光环（外扩 3pt / 32% / 160ms）。
  - **A-2 `WDSlider` 松手后不播报**（SPEC §2.10-#08 要求「松手后播报一次」）⇒ 新增 `announcementText` / `rangeAnnouncementText` 注入点，松手播一次 polite，经 `WDAnnouncementThrottle` 节流。
  - **A-3 `WDButton`**：补**按下亮度 96%**（黑蒙层乘法压暗）、**悬停 98%**（仅指针设备）与**聚焦光环**。
  - **A-4 `WDIconButton`**：补聚焦光环（圆 / 圆角方，跟容器形状）。
  - **A-5 `WDCheckbox`**：补按下缩放 0.90（`onPressingChanged` 的按下跟踪，不是自造 `DragGesture`）。
  - **A-6 `WDToolbar`**：补按下 0.94 + `fill.pressed`（`.plain` 拿不到按下态 ⇒ 新增私有 `ButtonStyle`）与聚焦光环。
  - **A-7 `WDTabBar`**：角标并入宿主朗读（有角标时挂 `accessibilityValue`；dot/0 不挂）。
  - **A-12 播报**：`WDProgressBar` / `WDProgressRing` 跨 25/50/75/100 播一次；`WDToast` / `WDBanner` 出现各 polite 一次。
  - **A-15～A-17 覆盖**：范围滑杆、滚动联动、日期过期提示各补预览与 demo 场景（此前 demo 里**零使用**，没有任何端到端证据）。
  - **验证（2026-11-20 B19 补跑，本条已回填）**：结构 `errors=0 warnings=0`；格式 `204 文件全过`；`build-for-testing` 与 demo app 编译均 0 error；**单测 344 / 快照 45 条 360 张 / demo 审计 18 条在 B19 全部实跑通过**（见 `docs/B19-EXIT-REPORT.md`）。

- **B19 验证层跑通 + 三处回归修复（2026-11-20；承接 `docs/DEBT-LEDGER.md` C 类）**：出口报告 = `docs/B19-EXIT-REPORT.md`、签名冻结 = `docs/B19-SIGNATURE-FREEZE.md`。**API 仍 1380（零 diff，本批无任何 public 变化）**。
  - **C-1 单测首次完整复跑**：`344 passed / 0 failed`（45 suites，17.6 s）。此前自 M2 起一律记【未验证】，根因是沙箱禁 PTY（`openpty: Operation not permitted`），`danger-full-access` 下 PTY 可用。
  - **C-2 8 态快照首次全量跑通**：`45 tests / 18 suites` 全过、360 张基线零漂移（修完下面三处回归之后）。
  - **C-3 demo 无障碍审计首次跑通**：`18 tests / 0 failures`（262.3 s，含 contrast / hitRegion / textClipped / dynamicType 四类目）。
  - **回归① 读屏焦点绑定 × `ImageRenderer` = 整棵子树渲染空白**：B18 给 `WDButton` / `WDIconButton` 挂 `.accessibilityFocused` 后，凡内嵌它们的组合件（Banner/Toast/EmptyState/DatePicker）快照**全白**（8 个对照探针定位：不挂正常、挂上全透明；`accessibilityRepresentation` 也救不回兄弟视图）。⇒ 新增 `WDA11yRuntime.isAssistiveTechRunning` 闸门，只在读屏/辅助开关运行时挂绑定（读屏关闭时像素与 B18 之前一致）。
  - **回归② `WDNavigationBar` 的 `.inline` / `.standard` 模式标题整条透明**（B15 引入）：内联标题乘了折叠进度，而这两个模式没有大标题、进度恒 0 ⇒ 标题 0 透明。折叠改为只在大标题模式生效。
  - **回归③ `WDTabBar` 胶囊 `elevation.2` 阴影被 `.clipped()` 裁掉**（B15 引入）：容器级 `.clipped()` 把边界外的阴影一并裁掉；收起裁切已由标签行自己完成，去掉容器裁切。
  - **基线**：`WDFAB` 8 张重录（B15 的 18pt 底部留白 ⇒ 内容上移 36px，旧基线滞后，非漂移）；`manifest.json` 补 8 张 `progressbar-indeterminate-*` 并刷新 16 处 sha256。其余全部基线**零改动即绿**。

### Added

- **B20 台账剩余可纯代码项收口（2026-11-20）**：出口报告 = `docs/B20-EXIT-REPORT.md`。**API 符号数仍 1380**；但 A-8 给 `WDSegmentedControl.init` **追加两个带默认值参数**（`positionText` / `positionSeparator`，位置文案的 L-B 注入点）⇒ 源码兼容、符号数不变、**符号快照连续性被破坏**，基线已按 `dump-api.sh --update` 显式更新（SPEC §2.9 规则 1）。
  - **A-8 `WDSegmentedControl`**：补**段间横向拖动**（`DragGesture(minimumDistance: 1)` + 横向占优判定；拖动只改视觉 `dragSegmentIndex`，松手吸附并走与点击同一条 `commit`）、**位置文案**（`WDSemantics.positional`，措辞与分隔符由调用方注入）、**方向键 ←/→ 即时切换**（设计 21 §8，端点不环绕、RTL 镜像）。
  - **A-9 `WDPicker` 菜单**：补**硬件键盘环形焦点**（`WDPickerMenuFocus`：首尾回绕、分组标题跳过、初始落选中项；↓/↑ 移动并滚动、Enter/Space 提交一次、Esc 关闭不改值）。滚轮形态的即时提交仍为平台限制 L-4。
  - **A-10 `WDDatePicker`**：补**二维方向键网格导航**（`WDDatePickerGrid`：±1 天 / ±7 天、跨月自动翻页、越界归一为最近可选日、RTL 镜像）与**弹层自适应高度**（`WDDatePickerSheetHeight` + `CustomPresentationDetent`：按内容量高并夹在可用高度内，三种组合各自高度）。
  - **A-15 范围滑杆快照闭合**：新增 `WDSliderRangeSnapshotTests`（`verifyHierarchy`）+ 8 张 `slider-range-*` 基线，总基线 360 → **368**；既有 360 张零改动、manifest 纯追加 8 条。
  - **验证**：单测 **377 passed / 0 failed**（+33）、快照 **46 tests / 368 张零漂移**、结构与格式门禁全绿、`dump-api` 零 diff。
  - **过程说明**：本批由 agent 团队并行执行，中途全体遭遇上游 429 限流，4 个成员在任务中途终止；captain 逐项核查已落盘工作（编译 / 单测 / 接线 / 独立探针 / 全量快照）后据实补记，详见出口报告 §0。**真机硬件键盘行为与独立评审 verdict 仍【未验证】**。

- **B17 遗留收口（2026-11-20；延续 B7/B8/B10 的「允许扩公开」口径）**：
  承接 `docs/B10-B16-EXIT-REPORT.md` §7 与 `docs/M5-EXIT-REPORT.md` §4 的遗留项。
  签名冻结 = `docs/B17-SIGNATURE-FREEZE.md`；出口报告 = `docs/B17-EXIT-REPORT.md`；
  契约增量（待落库）= `docs/B17-CONTRACT-CHANGE-REQUEST.md`。
  **API 1290 → 1380 符号（+90）**：其中 B10–B16 为 **+89**（该批当时以手工方式追加基线、计 1378；
  本轮在完整环境用 `Scripts/dump-api.sh --update` 重新规范化 ⇒ **实测 1379**，闭合 U-B-3），本批 **+1**。
  - **B17-1 `WDTabBar`**：`item.label` 显式挂 `accessibilityLabel`。此前只靠子视图合成，
    滚动收起把标签行压到 0 时读屏拿不到稳定名称（U-B-9 闭合）。**零 API 变化**。
  - **B17-2 `WDFAB`**：收起后读屏焦点归还主按钮（展开时子操作会移出可访问树，
    此前焦点会掉到页面顶部）。**零 API 变化**。
  - **B17-3 `WDDatePicker`**：过期色改为按系统 `NSCalendarDayChanged` 通知 + 回到前台刷新，
    **不自建计时器**（仓规）⇒ 跨午夜/跨时区后颜色会自己翻转；新增 `expiredAccessibilityHint`
    （L-B 注入点：文案由调用方给，库只决定“何时读”）——颜色之外多一条非视觉信号。
  - **B17-4 `WDSlider` 范围双手柄**（设计 08 §4）：新增 `init(range:label:in:step:onEditingChanged:showsValueLabel:valueText:lowerAccessibilityLabel:upperAccessibilityLabel:)`；
    两端不交叉、最小间隔 = 1 步长，松手吸附、点轨道 200ms 过渡、端点 rigid 触觉；
    读屏为两个可调整元素（下端 / 上端）。区间文案含分隔符 ⇒ **必须由调用方给**（L-B，库内零标点）。
  - **修复 B10–B16 完整环境首跑红灯 3 处**：`WDPullRefreshPhaseRelay.takeOutcome()` 读出后未清值；
    `WDNavigationBar` 折叠态用 `minHeight` 压不到 0（改联动路径定高）；`WDAvatarStack` 的无障碍断言
    在无 AX 客户端的单测宿主里读不到元素表（改为不制造假红，真机走查覆盖）。
  - **本批不纳入（逐条登记，不自行发明口径）**：`WDCard` media（设计 17 未给图片几何 + F-15 槽位词表无 `media`）、
    `WDToolbar` 长按 tooltip（`Button` 与长按手势仲裁需真机回归）、`WDSlider` 键盘光环（平台限制 L-5）。
  - **验证**：结构与格式门禁全绿；`xcodebuild build-for-testing`（模拟器 / Swift 6）0 error；
    `dump-api.sh` 重跑零 diff。**单测执行与 8 态快照零漂移在本机受限沙箱内仍【未验证】**（见出口报告 §4）。

- **B10–B16 纯代码可继续项（2026-11-15；清单 B1「需扩公开」+ B2「行为补齐」；授权口径同 B7/B8）**：
  **API 1290 → 1378 符号（+89；新增 126 条、改动 37 条既有 decl，无删除）**。签名冻结 = `docs/B10-B16-SIGNATURE-FREEZE.md`；
  - **快照形态说明**：那 37 条「移除 + 重加」不是删 API，而是 4 个既有 `init`（`WDFAB` / `WDNavigationBar` /
    `WDSearchField` ×2）与 33 条 `wdPullRefresh` 展开**追加了带默认值的参数**（SPEC §2.9 规则 1：源码 / 二进制兼容，
    但破坏符号快照连续性）⇒ 基线按 `Scripts/dump-api.sh --update` 显式更新（实测 symbols=1379）。
  契约增量（待设计仓落库）= `docs/B10-B15-CONTRACT-CHANGE-REQUEST.md`；平台限制（只记录）= `docs/B3-PLATFORM-LIMITS.md`。
  - **B10 `WDDatePicker`**：新增 `onClear`（设计 23 §8：清除 → 回调一次；外部置 nil 不回调）与
    **范围 + 时间组合模式**（`mode: .dateAndTime` 的范围重载 = 月历 + 时间滚轮两段式，先日期后时间，
    整理后 `lower <= upper`）；既有三个 init 行为不变。
  - **B11 `WDAvatarStack`**：新增 `onOverflowTap`（设计 13 §8：点堆叠 / 点 `+n` 同一动作；整叠成为一个 button，
    读屏仍只读一个元素）；`nil` 时像素不变。
  - **B12 `WDPullRefresh`**：新增失败通道 `onRefreshError` + `timeout`（默认 **10s**，设计 32 §8；抛错或超时 ⇒
    收起 + 回调一次，库内不弹提示——零文案）+ 三态文案与播报注入点 `WDPullRefreshTexts` + 阶段枚举
    `WDPullRefreshPhase`（idle/pulling/armed/refreshing/completed/failed）；播报 polite/polite/assertive，
    只在注入 `wdAnnouncer` 且文案非 nil 时播。旧 init 行为不变（无超时、无失败通道）。
  - **B13 `WDSlider`**：新增 `showsValueLabel` + `valueText`（设计 08 §6：标签行右侧等宽数字，拖动实时，
    不产生独立读屏焦点）与**读屏焦点光环**（设计 08 §5：手柄外扩 3pt、160ms，Reduce Motion 直出）。
  - **B14 `WDSearchField`**：新增 `resultCount` + `announcer`（设计 04 §8/§10：结果数**变化**时回调一次，
    首帧不播、不随每次按键播；传数字，措辞由调用方给）。
  - **B15 `WDFAB` / `WDTabBar` / `WDNavigationBar`**：`WDFAB` 新增 `showsScrimWhenExpanded`（展开遮罩，点遮罩 /
    读屏 `.escape` 收起）与 `avoidsTabBar`（底部避让 92，设计 36 §6）＋**滚动缩小**（设计 36 §5：向下缩到 40、
    不隐藏）；`WDTabBar` **滚动收缩为无标签胶囊**（向上滚立即展开，设计 34 §6/§9）；`WDNavigationBar` 新增
    `followsScroll`（设计 33 §4/§5/§8：大标题随进度折叠 0…52pt + 透明→玻璃 240ms 交叉淡化，读屏不重复朗读）。
    三者的滚动量统一走**新环境键** `View.wdScrollOffsetY(_:)` / `EnvironmentValues.wdScrollOffsetY`（`nil` = 不联动，
    默认路径像素不变；R18 写入口仍在 `Foundation/Theme/WDEnvironment.swift`）。
  - **B16 `WDSwitch`**：新增 `onWriteFailure`（设计 05 §8：用户发起的切换未被 binding 采纳 ⇒ 回弹到 binding
    当前值 + 回调一次；外部改写不误判）。
  - **接线面（新增公开）**：`EnvironmentValues.wdAnnouncerText` 与写入口 `View.wdAnnouncer(_:)`（L-B 播报通道）。
  - **验证**：`typecheck`（库全量，模拟器 + 设备）+ `check-structure.sh --strict`（0 error / 0 warning）+
    `check-format.sh`（201 文件）全绿；测试目标与 demo 源码编译核验通过；**单测与快照本机未执行（沙箱禁
    `xcodebuild test`）—— 见 `docs/B10-B16-EXIT-REPORT.md` §3 的【未验证】台账**。

- **B9 行为欠账（2026-11-15；API 零变化）**：`WDCheckbox` 选中光晕（`brand` 42% → 透明，
  400ms 一次，Reduce Motion / 禁用 / 半选不播）；`WDSwitch` 支持拖动滑块实时跟随、松手吸附、
  按下 1.06、轨道 260ms 线性 / 滑块 300ms 精确曲线；`WDToast` 旋转/分屏后按新 bounds 与安全区
  重排；`WDListRow` 尾部徽标文本并入整行朗读（徽标仍不独立进焦点）。**API 1290 零变化**；
  206 tests / 360 张快照零漂移；demo 18 条 UITest 全绿。**残留**：Checkbox 光晕观感与
  Switch 拖动/ScrollView 竞争需真机确认；Toast 悬停仍待真机；ListRow 朗读需 VoiceOver 实测。

- **B8 实现欠账（2026-11-15；授权扩公开）**：`WDIconButton` 新增 `WDIconButtonShape`
  （circle / roundedSquare，radius.sm）与 shape 重载；`WDCheckbox` 新增无标签重载（仅方框 +
  必填 accessibilityLabel，用于表头全选）；`WDDatePicker` 单日期早于今天时文字改用
  `status.danger`（范围 / `.time` 不套用）。**API 1285 → 1290（+5）**；`iconbutton-*`、
  `checkbox-*`、`datepicker-*` 各 8 张重录。契约已同步 IconButton/Checkbox 两个 yaml。
  **残留**：IconButton lg 方形视觉复核、Checkbox 光晕/无标签朗读实测、DatePicker 跨午夜不自动翻转、
  读屏未播报“已过期”。

- **B7 实现欠账（2026-11-15；授权扩公开）**：`WDCard` 新增可点卡（按下亮度 96%、instant、
  禁用 40%、button 语义）；`WDCheckbox` / `WDRadio` 新增紧凑档（22px 方框/外圆，标签 footnote）；
  `WDFAB` 展开时读屏焦点移入第一个子操作。**API 1276 → 1285（+9）**；`checkbox-*`、`card-*`、
  `radio-*` 各 8 张扩展重录。契约已同步 Checkbox/Radio/Card 三个 yaml。**残留**：Card media、
  Checkbox 光晕/无标签、Radio 角色、FAB 遮罩/滚动/安全区、可点卡嵌套子元素约束。

- **`WDDatePicker` 范围 + 清除（2026-11-15，B6；授权扩公开）**：新增范围重载
  `init(range:label:placeholder:in:showsClearButton:clearAccessibilityLabel:)`（仅日期模式）与
  单日期清除重载；范围两步选择（起点→终点，往前点重开），同年“月日 – 月日”、跨年带年份，
  跟随系统区域格式；清除仅在提供标签时渲染。**API 1274 → 1276（+2）**；`datepicker-*`
  8 张扩展重录。**残留**：范围+时间、范围中点视觉、清除回调、过期色。契约增量见
  `docs/B6-CONTRACT-CHANGE-REQUEST.md`；已落库设计仓（2026-11-15）。

- **`WDSwitch` 紧凑档 + 描述位（2026-11-15，B5；授权扩公开）**：新增公开 `WDSwitchSize`
  （standard 51×31 / compact 40×24，滑块 27/20、行程 20/16）与
  `init(isOn:label:description:size:)`；既有 `init(isOn:label:)` 保留。描述位在标签下方一行
  footnote / text.secondary。**API 1270 → 1274（+4）**；`switch-*` 8 张扩展重录。
  **残留**：拖动滑块/松手吸附、写入失败回弹、聚焦光环、精确 260/300ms 曲线。
  契约增量见 `docs/B5-CONTRACT-CHANGE-REQUEST.md`；已落库设计仓（2026-11-15）。

- **`WDIconButton` 五变体（2026-11-15，B4；授权扩公开）**：`WDIconButtonVariant` 新增
  filled / tonal / glass / outline（既有 plain 不变），按下缩放 0.97、禁用 40%。**对比度优先**：
  filled 用 `text.brand` 实底 + 浅色白 / 深色 `text.on-light-primary`（设计 `gradient.mid` + 白
  仅 2.51:1，不达图形 3:1）。**API 1266 → 1270（+4）**；`iconbutton-*` 8 张扩展重录。
  **残留**：圆角方形形态、聚焦光环、长按提示、加载态语义。契约增量见
  `docs/B4-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDCard` sunken + `WDDivider` 内缩（2026-11-15，B3；授权扩公开）**：`WDCardStyle` 新增
  `.sunken`（`surface.card-sunken`、无描边、无阴影）；`WDDivider` 新增 `WDDividerStyle`
  （full / inset，内缩起点 62）与 `init(style:)`，既有 `init()` 保留。**API 1261 → 1266（+5）**。
  `card-*`、`divider-*` 各 8 张扩展重录（总 **360**）。**残留**：Card 的 media 变体与可点卡。
  契约增量见 `docs/B3-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDAvatar` 五档 / 在线 / 停用（2026-11-15，B2；授权扩公开）**：新增公开 `WDAvatarSize`
  （xs 20 / sm 28 / md 32 / lg 40 / xl 56，首字号 9/11/12/14/18）与
  `init(value:size:isOnline:isDisabled:)`；既有 `init(value:)`（md 32）不变。在线点 10×10 +
  2pt 描边，停用整体 50% 去饱和；图标档按直径近似（xs/sm 16、md 20、lg/xl 24，已登记）。
  **API 1254 → 1261（+7）**。`avatar-*` 8 张扩展重录，受字号/图标档影响的 `avatarstack-*`、
  `assigneepicker-*` 各 8 张同步重录（总 **360**）。**残留**：成员四色底色（缺 token）、照片形态、
  在线状态读屏措辞（L-B）。契约增量见 `docs/B2-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDBadge` 六种状态变体（2026-11-14，B1；项目负责人授权扩公开）**：新增公开 `WDBadgeVariant`
  （shared / schedule / pending / success / warning / danger）与 `init(label:variant:)`；既有
  `init(label:)` / `init(value:)`、计数/圆点形态不变，**API 1246 → 1254（+8）**。**对比度优先**（DF-04）：
  soft 变体文字统一 `text.on-soft`（原 status 色 success 4.32 / danger 3.94 不达 4.5）；schedule 改
  `status.info` 实底（原 `gradient.mid` 白字仅 2.51–4.23），浅色白 / 深色 `text.on-light-primary`。
  新增 8 张 `badge-variants-*` 基线（总 **360**）+ 2 条单测（六态/高度、6×2 对比度）。契约增量见
  `docs/B1-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDSlider` 自绘载体 + 交互补齐（2026-11-14，B 类遗留）**：手势/读屏改由 Internal `UISlider` 承载
  （系统拖拽、键盘方向键、读屏可调整语义；避免自造 `DragGesture`），视觉改 SwiftUI 覆盖层——轨道 6pt
  （`border.hairline-strong`）、填充 `gradient.mid`、手柄 26（白 + 1pt hairline + `elevation.1`）、两端内缩
  13、拖拽 1.15（100ms）、禁用 45%、RTL 自动镜像；热区 44、最小宽 120 不变。**交互**：点击轨道按触点
  换算目标值并做 200ms 过渡（Reduce Motion 瞬移）；松手按 `step` 吸附；拖到端点改 `rigid` 触觉
  （同一次操作仍只抖一次）。**公开签名零变化**（API 1246 符号零 diff）；`slider-*` **8 张快照基线重录**、
  manifest 哈希同步；新增 2 条结构断言（吸附/热区 + 点击换算 LTR/RTL；PR **166 tests**）。
  **残留**：聚焦光环、数值标签跟随、范围双手柄（后两者需签名扩展）；带刻度 = `step` 吸附（画廊无可见刻度点）。
  demo 新增 `testSliderTapJumps`（点 15% 位置后值必须变化）；完整 demo 套件 **15 条 / 220.88 s** 全绿。

- **`WDAlert` 焦点归还（2026-11-14，B 类遗留）**：出现前用 `UIAccessibility.focusedElement` 捕获当前读屏
  焦点元素，关闭后用 `.layoutChanged` 归还；不改公开签名（无需公开 `WDA11yFocusID` 构造器）。
  真机 VoiceOver 人审仍【未验证】。

- **`WDToast` 窗口层 + 悬停暂停 + 上滑关闭（2026-11-14，B 类遗留）**：浮层改挂 Top VC 的 view（只占
  自身尺寸，不拦截页面其余触摸；解决局部容器裁切，设计 28 §11）。指针悬停时冻结倒计时、移出后按
  剩余时间恢复（`ContinuousClock` 截止时刻 + task 重启，不新增自建计时器）；上滑（最小 10 / 阈值
  16）立即关闭；停留下限仍为纯提示 3s / 带操作 5s。公开签名零变化。demo 新增上滑 / 自动消失 /
  非阻塞 3 条用例，完整套件 **18 条 / 265.44 s** 全绿。**未验证**：模拟器无指针悬停，暂停未人审；
  旋转期间不重排浮层 frame（生命周期短，未处理）。

- **`WDAssigneePicker` 视觉对齐设计 37 画廊（2026-11-14，用户复核）**：未指派改 **52 虚线圈 +
  `person.fill.xmark`**（图标契约 `icons.json` 的 iOS 映射由 `person.crop.circle.badge.xmark` 修正；
  Android 仍 `person_off`）；选中环按 **52 槽 2pt**、头像**静止 1.0**（选中只做 200ms 弹到 1.05 后回弹，
  原 1.05 常驻是错误），圈内间隙 **4**；项槽间距 **12**；选中名字品牌色 + 600。
  重录 AssigneePicker **8 张** + WDAvatar **8 张**基线（未指派图标变更）。

- **`WDProgressBar` 补齐设计 15（2026-11-14，用户指出缺口）**：新增**分段变体**
  `init(segments:completed:label:valueText:)`（n 段表示 n 项完成几项，段间距 2，全完成换成功色）；
  并补齐此前登记/未实现的设计项——**不确定态超过 1 秒才出现**、**禁用整体 45%**、
  **完成 300ms 过渡**、**首次出现 3200ms 缓出**、以及 **progressbar 无障碍语义**
  （`accessibilityRepresentation` 借 `ProgressView` 提供角色/当前值；不确定态不给 valuenow）。
  新增 1 条结构断言；API 基线 1245 → **1246 符号（+1，无移除）**；契约 `contracts/WDProgressBar.yaml` 补
  `segments`/`completed`。分段填充用品牌色（沿用 M4 的对比度改判）。

- **M6 场景组件 `WDAssigneePicker`（指派选择）**（2026-11-14）：头像横排 **40**（紧凑 **32**）、
  选中外环外径 **52**（紧凑 44）、最多直接显示 **6** 个 + `+n`；**单选**
  `selection: Binding<String?>` 与 **多选** `selection: Binding<Set<String>>` 两个 init
  （编译期分离，同 `WDChip` 口径）；「未指派」内置虚拟项（`WDAssigneePickerUnassigned`，
  点它清空选择）；已离开成员 `isEnabled: false` + `unavailableReason`（40% 去饱和、仍进无障碍树）；
  `positionText: ((Int, Int) -> Text)?` 给「第 n 项，共 m 项」措辞（L-B 零文案）；
  溢出展开由 `onOverflowTap` 交给调用方（库不自弹面板）。签名冻结 =
  `docs/M6-SIGNATURE-FREEZE.md`；契约 `contracts/WDAssigneePicker.yaml`；API 基线
  **1212 → 1245 符号（+33）**无移除。
- **M6 快照与 demo**：`WDAssigneePicker` **8 张新基线**（总 **344**）；demo 组件目录扩到
  **37 件**（新增 M6 详情页：单选 + 未指派 / 多选 / 紧凑 / 溢出 / 整体禁用），审计视口加入
  AssigneePicker 代表实例。

- **`WDCheckbox` 半选态**（2026-11-14，用户裁决；设计 06 §5）：新增 `isIndeterminate: Bool = false`
  （additive、源码兼容；不改受控值类型）。视觉 = 同已选底 + **12×2.4 白色横杠**；点半选 → 变全选
  （不做三态循环）；demo（静态 + 可交互两例）/previews/快照均补半选；API 基线 `WDCheckbox.init` 更新。
  半选朗读文案仍属调用方（L-B 零文案，需要时外层加 `.accessibilityValue(_:)`）。
  契约 `contracts/WDCheckbox.yaml` 已补 `indeterminate`（2026-11-14）；Android 侧 C-15 副本同步
  （新增默认参数 = 二进制不兼容 ⇒ 走重载/major）。

- **M5 十五件落地（导航与表单）**：`WDSearchField`、`WDRadio`、`WDSlider`（原生 Slider 载体）、
  `WDStepper`、`WDChip`（展示/可选/可删除三个 init）、`WDAvatarStack`（max 4 + 溢出计数）、
  `WDSegmentedControl`（38 高 + 弹簧指示块）、`WDPicker`（系统 Menu + wheel）、
  `WDDatePicker`（自建月历 + 系统时间滚轮 + 快捷 Chip + min/max）、`WDFormRow`（AX 自动上下排布）、
  `WDPullRefresh`（系统 .refreshable + 读屏刷新操作）、`WDNavigationBar`、`WDTabBar`（深色自动不透明）、
  `WDToolbar`（>7 项收进更多）、`WDFAB`（可展开）。同一批把 `WDBadge` 扩了 `count`/`dot` 两种值形态
  （只增不改，闭合 M2 延后项⑤）。
- **M5 快照与 demo**：15 件 × 8 态 + Badge 计数/圆点 = **128 张新基线**（总 **336**）；
  demo 组件目录扩到 **36 件**（M5 详情页含档位/状态/设置，13 件可切枚举），审计视口加入 M5 代表实例。
- **M5 契约回填（设计仓 `contracts/`，15 个 yaml）**：params / slots / default + 枚举全量 case；
  `WDBadge.yaml` 增量记录 count/dot 值形态。
- **M4 九件落地（反馈与弹层）**：`WDBottomSheet`（窗口级自绘贴边面板 + half/large 档位）、`WDActionSheet`、
  `WDAlert`（270 卡片 + 带输入重载 + screenChanged 焦点移入）、`WDToast`（组件内 .task 计时）、
  `WDBanner`（3 变体 + 软底渐变）、`WDEmptyState`、`WDSkeleton`（text/list/card + 2200ms 微光）、
  `WDProgressBar`、`WDProgressRing`。冒烟段的 sheet/actionSheet 声明同 PR 退役；
  `WDHaptics` 增加 success 种类（进度 100%）。
- **M4 快照与 demo**：9 件 × 8 态 = **72 张新基线**（总 **208**）；demo 组件目录扩到 **21 件**，
  弹层从详情页触发，审计视口加入进度条/环、Banner、EmptyState、Skeleton；3 条 UITest 全过。
- **M4 对比度账目**：设计仓 `contracts/contrast.json`（light/dark 34 对 + 玻璃禁止对）；
  ProgressBar 填充因 `gradient.mid` 浅端仅 2.02:1 改为品牌色渐变（3.91:1 / 6.71:1）。
- **`WDListSection` 六类断言收尾（M3）**：清掉 `DRAFT` 注释；新增 `WDListSectionSnapshotTests`——
  **4 变体（标准 / 标题动作 / 带页脚 / 空组）× 8 态 = 32 张基线**（空组应只有空白）；
  demo 组件目录新增 `WDListSection` 条目与实时预览，审计视口扩到 **12 件**（M2 11 + M3 1）。
- **M3 公开 API 封板**：`api/WisdomUI.api.json` 入库且 `dump-api` **零 diff（661 符号）**；
  记录 = `docs/M3-API-FREEZE.md`（SHA-256、工具链、复跑命令与封板口径）。
- **M3 契约回填（设计仓 `contracts/`，12 个 yaml）**：M2 的 11 件 + `WDListSection`；
  `params`（受控值取 C-15 canonical）/ `slots`（21 名词表子集或「无」）/ `default` + 枚举全量 case。
  回填 = 誊录，不改签名/默认值/槽位/枚举（设计仓提交 `feat(contracts): M2/M3 契约条目回填`）。
- **M3 覆盖率门槛**：`Scripts/ci.sh pr` 的覆盖率阶段由「只打印」改为**硬门槛**——
  `Foundation/**`（排除 `generated/`）**≥ 80%** 才绿；本次实测 **97.73%（603/617）**。
- **API 基线随 M4 九件更新**：`api/WisdomUI.api.json` **661 → 860 符号（+199）**；无移除。
- **M3 结构门禁转严格（`--strict`）**：按 SPEC §1.1.2/§1.5.5，M3 起 R7/R15/R21 的 warning 转拦；
  PR-0 改为 `check-structure.sh --strict`。清理：`WDIconButton` 三档视觉尺寸改用
  `WDSize.controlSm/Md/Lg` 令牌；其余 10 处数值字面量（WCAG 公式、十六进制解码、DF-03 配额、
  热区补量）与 2 处文本容器按规则**同行带理由豁免**；结果 **0 warning / 51 suppressed**。
- **M3 归档体积门槛（E3-iOS-a）**：同构消费方与分母各归档 3 次，3 次完全相同
  （BaselineShell 86,016 B / 消费方 581,632 B）——增量 P50 = **495,616 B（≈484 KB）**，
  门槛 = `P50 × 1.10` = **545,178 B（≈532 KB）**，
  按增量表达；写入 `README.md` / `docs/U09-SIZE-BASELINE.md` §6。Thinning 增量仍【未验证】（M6 发布前层）。
- **令牌流水线落地**：`Sources/WisdomUI/Foundation/generated/{WDTokens,WDTokensVersion,WDColorSlots}.swift`
  （设计仓 `tools/token-build/build.js` 生成；`tokens v1.0.0 · sha256:e552bb87e270`；
  **32 个语义色槽位**（含 `text.disabled`）；`schemes = [light, dark]`）。
- **主题手写层** `Foundation/Theme/WDColorValues.swift`：`WDColorValues`（32 槽位 + 补丁式
  `init(_:)`）、`WDColorOverrides`、`WDColorSlot`（`String` 原始值 +
  `CaseIterable` + `Sendable`，不加 `@frozen`）。
- **结构检查器** R1–R21（`Sources/wd-structure-check/`，host 侧、只依赖 Foundation）+
  固定样本自检（`Scripts/test-checker.sh`，各一正一反）+ 行内豁免语法。
- **跨仓同批自证**：`Scripts/check-structure.sh --tokens-trace`（读设计仓
  `dist/tokens.manifest.json`，断言 `sha12` 与生成物一致；**缺失 = fail**）；
  测试侧入口 `Tests/WisdomUITests/Support/WDContracts.swift`。
- **门禁入口** `Scripts/ci.sh`（`pr` / `nightly` / `measure` / `doctor`）与
  `.github/workflows/ci.yml`；API 冻结链路（`Scripts/dump-api.sh` + `api/WisdomUI.api.json`，
  规范化器丢弃 USR/绝对路径等易漂移字段）。
- **归档体积基线** `Examples/BaselineShell/`（E3-iOS-a 的分母：同构、不引入本库）。
- 协作文件：`CONTRIBUTING.md`、`.github/pull_request_template.md`、`.github/CODEOWNERS`。
- **`WDListSection`（M3）**：数据驱动的列表分组（`items`/`selection`/`header`/
  `headerAction`/`footer`）；空集合自动隐藏整组、末行通过 `WDListSectionRowContext.isLast`
  交给行自己关分隔线；7 条单测（空组/末行/选中/密度/页脚/动作热区）+ 2 个预览。
  签名冻结 = `docs/M3-SIGNATURE-FREEZE.md`（2026-11-12 按建议确认；7 条单测 + 2 预览）。
- **E3-iOS-a 同构消费方壳**（2026-11-11）：新增
  `Examples/BaselineShellWithLibrary`（与 `BaselineShell` 同构、行改用 `WDListRow`）；
  首次成对归档（未 Thinning，Release）：baseline 86,016 B / 本壳 561,152 B，增量 **475,136 B ≈ 464 KB**。
- **demo 组件目录改版**（2026-11-10）：主入口从"所有组件堆在一个页签"改为按用途分组的组件目录
  （操作 / 输入与选择 / 内容展示 / 布局与结构，覆盖 11 件 primitives）；点击进入详情页，
  提供实时预览、档位/状态与实现细节；带枚举的 6 件组件在详情右上角提供"设置"切换，
  关闭设置后预览显示新配置。主题与令牌、无障碍审计视口迁到目录右上角的调色板入口；
  UITest 增加目录导航 + 枚举切换断言，审计例外补"已完成 2 项"（列表行单行截断，设计 18 §7）。
- **demo 组件审计视口**（2026-11-10）：`Examples/WisdomUIDemo` 增加"组件"页签（11 件代表性实例）；
  页签用**分段控件**而非 `TabView`——iOS 26 的浮动玻璃 Tab 栏会压住滚动内容，令对比度审计误判。
  demo UITest 对两个页签分别跑 contrast / hitRegion / textClipped / dynamicType；6 条窄例外
  （头像首字/徽标固定字号 ×3、列表行单行截断 ×3）在测试里**逐条点名并打印理由**，其余仍严格失败。
- **M2 组件（收尾）**：`WDButton`（6 变体 × 3 尺寸；按下 0.97 + 轻触觉；加载态宽度不变、
  标签留在无障碍树且 `loadingAccessibilityText` 必填；公开 `WDButtonStyle` + `.wdFilled` / `.wd(_:size:)`；
  `filled`/`destructive` 用渐变 + brand 阴影，`glass` 走 `WDGlass.resolve` + iOS 26 `glassEffect`）
  与 `WDListRow`（行高 44/60/76 = `max(密度下限, 槽位派生)`；前导 5 种 / 尾部 5 种；选中 3pt 品牌条 +
  8% 底；分隔线按 62 内缩；可点行走真 `Button` + pressed 底；左滑删除 + 自定义无障碍删除操作）。
  冻结签名差异（按钮字号档/聚焦光环、行的徽标朗读合并/selectionIndicator 语义）登记
  `docs/DEV-PLAN.md` §2.3；组件测试 6 条 + 两件 8 态快照（16 张基线）。**M2 11/11 代码全部落地**。
- **M2 组件（续四）**：`WDCheckbox`（方框 26 / 圆角 9 / 勾用描边路径；两态；切换轻触觉 ×1）、
  `WDCard`（elevated / outlined / glass 三档；内距 16 固定、圆角 24；玻璃走 `WDGlass.resolve` +
  iOS 26 `glassEffect`、17–25 纯色降级）、`WDIconButton`（plain 档；sm 32 / md 44 / lg 52 视觉、
  **热区恒 44**；无障碍标签必填）。冻结签名差异（Checkbox 半选/紧凑档、Card sunken/media/可点卡、
  IconButton 其余四变体）登记 `docs/DEV-PLAN.md` §2.3；组件测试 8 条 + 三件 8 态快照（24 张基线）。
- **Foundation 覆盖率补齐**（2026-11-10）：新增 16 条单测覆盖颜色槽位（32 槽位/补丁构造/
  light↔dark 差异）、令牌基础类型（`WDTextStyle` 四项派生、`WDShadowLayer`、`WGradientSpec`）
  与环境写入口（`wdTheme`/`wdTheme(scheme:)`/`wdColors`/`wdEffectsBudget` 只降不升/`wdDensity`/
  `wdAppearance` 派生）；`Foundation/**`（排除 generated）**67.3% → 97.69%**，M3 的 80% 门槛预达标。
- **基础设施补齐**（2026-11-10；P2 的依赖项）：`WDLayoutDensity` + `wdDensity`（环境只读 +
  唯一写入口；默认 `comfortable`，行高下限 60/44，F44）；`Internal/WDHaptics.swift`
  （可注入 sink + `WDEffectsBudget` 的"一次操作最多一次"闸门；测试用捕获器断言次数，不真的震动）。
- **M2 组件（续三）**：`WDSwitch`（标准档轨道 51×31、滑块 27、行程 20；开 `gradient.mid`、
  关 hairline 描边；整行可点、切换轻触觉 ×1；角色由真 `Toggle` 提供，库内零"开/关"文案）。
  冻结签名无紧凑档/描述位 ⇒ 差异登记 `docs/DEV-PLAN.md` §2.3；组件测试 3 条 + 8 态快照（8 张基线）。
- **M2 组件（续二）**：`WDAvatar` + `WDAvatarValue`（圆底 + 首字/图标；默认 md 32、首字号 12 固定；
  文字形态把 `label` 作为无障碍标签，图标形态是装饰）。冻结签名无 size/ID/在线态/照片参数 ⇒
  五档直径、按成员 ID 固定配色、在线点、停用态不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3；
  组件测试 3 条 + 组件级 8 态快照（8 张基线）。
- **M2 组件（续）**：`WDDivider`（全宽 1pt `border.hairline`、无状态、不进树）与
  `WDBadge` + `WDBadgeValue`（状态胶囊高 24 / 内距 10 / 固定 11pt·600；中性 shared 配色；
  不进入焦点序列）。冻结签名无 variant/计数参数 ⇒ 只实现状态胶囊与全宽档，差异登记在
  `docs/DEV-PLAN.md` §2.3；组件测试 7 条 + 组件级 8 态快照 ×2（16 张基线）。
- **无障碍层落地**（2026-11-10）：`WDSemantics`（`join` / `positional`，零标点、零语序，
  `[String]` 纯逻辑重载按 Android 同口径剔除空串）；`WDAnnouncementPriority` / `WDAnnouncing` /
  `WDSystemAnnouncer`（同步、无 `Task`；`polite` → `PageScrolled`、`assertive` → `Announcement`）；
  `WDAnnouncementThrottle`（进度只向上跨阈值；释放后 1s 节流，数值登记 D-8）；
  `WDA11yFocusID`（`Hashable` 焦点身份）。M0-11 冒烟段的对应声明**同提交退役**；
  测试 9 条（语义渲染等价 / 阈值与节流 / 焦点身份）。
- **M1 基础设施**（2026-10-07 交付）：`wdFont(_:)` 单入口 + 行盒度量（12 档 × 12 字阶 × {en, zh} ×
  {字体级, 渲染级} = **288 条 fixture**）；`WDTheme` / `wdTheme` / `wdColors` 运行时换肤（换已生成的
  scheme，值变更触发重组、**不重启进程**）；三件套 `WDGlass` / `WDEffectsBudget` / `WDContrast` +
  **34 条参数化用例**（含两条"必须红"用例）；`WisdomUIPreviews` 画廊 + `WisdomUISnapshotTests`
  （8 态矩阵、**16 张基线**）；`Examples/WisdomUIDemo`（app + 无障碍审计 UITests）。
- **M2 首批（2/11 组件完成六类断言；2 条登记未闭合）**：`WDTextField`（46pt 字段盒、三变体、
  聚焦/错误/禁用/只读、label/prefix/accessory/helper 四槽位、附件按钮独立可达、密文/计数）与
  `WDIcon` + `WDIconMetrics`（四档 16/20/24/28，**不随动态字体放大**、装饰件不进树）；
  `WDIconName` 生成物（44 条语义名 + SF Symbols 映射，`contracts v1.0.0 · sha256:aab3bb93f508`）；
  组件测试 **10 条**（字段盒 46±1、三态等高、辅助行、最小宽、AX3 生长、计数阈值、AX5 不缩放）、
  `+Previews.swift` ×2、组件级 **8 态快照 ×2（16 张基线）**。未闭合：错误态 assertive 播报（依赖
  `WDAnnouncing` 层）、显隐切换的 selection 位置（iOS 17 走降级路径；见 `docs/DEV-PLAN.md` §2.3）。

### Changed

- **`WDButton` 填充/柔色对齐画廊 01**（2026-11-14，用户裁决）：`tonal` 底由 `surface.tint`
  改为 **`gradient.surface`**（与画廊 `.wd-btn.tonal` 的 `--g-surface` 一致）；`filled` / `tonal`
  补 **1px 顶部内高光**（画廊 `inset 0 1px 0`；令牌 `border.glass-top` 全值，浅色 .8 更接近真机可见度）；
  按钮 8 态快照基线重录。设计仓已同步（2026-11-14）：`design/preview` 的 tonal 改渐变、
  `docs/specs/01-basic.md` / `contracts/WDButton.yaml` / `contrast.json` 回填；
  `Chip 已选` / `Badge shared` 仍走 `surface.tint`（Button 单点例外）。

- **勾的绘制按设计稿重做**（2026-11-14，用户裁决）：`WDCheckbox` 的勾改为**2.2pt、rotate(42°) 的 5×10 L**
  （与画廊 06 的 `border-right + border-bottom` 同形，butt 端、miter 角），`WDPicker` 菜单勾改为
  画廊 22 的 **lucide check**（16pt / 24 viewBox / round cap+join，线宽 2 × 16/24）；
  对应快照基线重录：`checkbox` 8 态 + `listrow` 8 态（后者含 `.checkbox` 前导槽）。

- **`WDPicker` 按设计 22 全量对齐**（2026-11-14，用户裁决「完全按照设计稿」）：菜单形态从系统 `Menu`
  改为**窗口级自绘浮层**——圆角 14 / 选项行 44 / 最小宽 180 / 最大宽 = 屏宽 − 32 / 与入口间距 4 /
  空间不足自动翻转 / 当前项打勾并滚到可视区中间、选中行 = brand 10% 底 + brand 字 + 600（画廊 22 `.sel`）/
  遮罩与硬件键盘 Esc 关闭且不提交 /
  `motion.spring.gentle` 入场 + 160ms 淡出；分组标题 `type.overline`、组内选项缩进 `space.5`；
  滚轮形态保持系统 `Picker(.wheel)`（设计 22 §11 的平台差异条款）；新增 `.inline` 内联形态
  （≤ 8 项直接平铺）；触发入口箭头由 `chevron.right` 改为 **`chevron.down`**（设计 22 §2）。
  同步：picker 8 态快照基线重录、API 基线 +1 case、demo/previews 补内联样例。

- **BottomSheet 长内容滚动冲突**：内容可滚动时只观察 `UIScrollView` 既有 pan，不再叠加第二套手势；
  不可滚动时才补并行 pan，保证短内容也能从内容区下拉关闭。新增长内容 UI 测试
  （内部滚动到列表末项、关闭键位置不变）。
- **ActionSheet / BottomSheet 跟随宿主题**：窗口级 presenter 继承调用方的 `wdTheme` 与 `colorScheme`
  （hosting controller 注入主题 + `overrideUserInterfaceStyle`）；dark scheme 下遮罩、列表卡、取消卡、
  面板、文字都切到深色。新增 dark scheme UI 测试。
- **demo 组合场景**：新增「组合场景」入口——卡片容器（`WDCard` + Avatar/Badge/Progress/Switch/ListSection/Button）
  与底部面板容器（`WDBottomSheet` + TextField/Card/Switch/Checkbox/Progress/固定页脚）；
  目录页展示 21 件组件 + 2 个场景，新增组合场景 UI 测试与截图。
- **`WDBottomSheet` 按设计 26 补齐并改自绘贴边**：标题 `title3`、头部 56；内容 `ScrollView` + 12
  顶距；底部操作区固定、1pt 分割线、高 72、右对齐；面板左右/底部贴屏幕、顶部 32 圆角、把手 36×5；
  half/large 档位、把手拖拽/点击切换、下滑关闭、点遮罩关闭、键盘上移；焦点归还（layoutChanged）
  与 VoiceOver `.escape` 动作；键盘避让有 UI 测试（字段在键盘上方）；内容滚到顶后下拉经
  UIScrollView 桥接拖动面板（有 UI 测试）。8 态基线重录。
- **`WDActionSheet` 按设计 27 参考重排**：左右 16 内距；标题/说明移入列表卡片顶部（caption1 /
  text.secondary + 底部分隔线）；行左对齐、可选 20pt 前置图标；取消为独立 48pt **圆角卡片**
  （18 圆角、semibold、e2 阴影）；破坏性项置底。呈现改为 **窗口级 presenter + 自绘遮罩**：
  透明背景、无系统 sheet 半透明边框；**遮罩静态出现，面板单独滑入/滑出**；点遮罩 = 取消。8 态基线重录。
- **`WDSkeleton` 微光与宽度修复**：微光由旋转色带改为水平 `sourceAtop` 扫光（只落在灰块上，不再出现斜方块）；
  行宽改 `maxWidth` + 固定短行留白，避免 `containerRelativeFrame` 在嵌套 HStack 里把 demo 撑出屏幕；8 态基线重录。
- **`WDBanner` 对齐修复**：HStack 由 top 改 center（图标/文案/操作/关闭键同一垂直中心）；
  文案行盒改 1 行下限（多行自然长高，不再为单行预留两行）；关闭键改 `sm`（视觉 16）。
  8 态 banner 基线重录。
- 生成物目录 `Foundation/Generated/` → `Foundation/generated/`（**纯移动，零内容变化**；
  M0-2 生成器的目标态）。格式清单的排除模式随之写成 `/Foundation/[Gg]enerated/`。
- `Foundation/WDTokenTypes.swift` → `Foundation/Tokens/WDTokenTypes.swift`（纯移动）。
- `WDTextStyle` 改为 **4 存储字段**（新增 `letterSpacing`）、加 `Equatable`、
  构造器按 O-10 转 `internal`；新增派生 `lineHeightRatio`。
- README 的"开发"段改为门禁口径（`Scripts/ci.sh`）+ 预览三限制；补齐 `Examples/` 说明。
- **`WDTextField` 视觉与状态补齐**（2026-11-10）：三变体（`inset`/`outline`/`glass`，玻璃走
  `WDGlass.resolve` 且 iOS 17–25 纯色降级）、聚焦描边+光环、错误描边、禁用 40%、只读下沉底、
  点容器聚焦、错误态 `accessibilityHint`（F22）；组件级 8 态快照改用 `UIHostingController` 渲染器
  （`ImageRenderer` 对 `TextField` 输出全透明，登记 **P17**）。
- **API 基线随 M2 两件回填**：`api/WisdomUI.api.json` **+18 符号**（`WDIcon` 全家、`WDIconSize` 四档、
  `WDTextFieldPrefix.icon`、`WDTextFieldAccessory.clear/reveal`）。按 SPEC §1.5.3，基线变更单独提交
  （`chore(api): …`），**不得**与实现提交混在一次提交里。
- **API 基线随无障碍层更新**：`api/WisdomUI.api.json` **+16 符号**（`WDSemantics`、`WDAnnouncementPriority`、
  `WDAnnouncing`、`WDSystemAnnouncer`、`WDAnnouncementThrottle`、`WDA11yFocusID`）——这些声明原先只在
  冒烟段（被规范化器排除），随实现落地首次进入公开面；无移除。
- **API 基线随 WDBadge/WDDivider 更新**：`api/WisdomUI.api.json` **+22 符号**（`WDBadge`、
  `WDDivider`、`WDBadgeValue` 及其 View 扩展入口）——两件从冒烟段/提案落地后首次进入公开面；
  无移除。
- **API 基线随 WDAvatar 更新**：`api/WisdomUI.api.json` **+13 符号**（`WDAvatar`、`WDAvatarValue`
  及其 View 扩展入口）——从冒烟段落地后首次进入公开面；无移除。
- **API 基线随布局密度/WDSwitch 更新**：`api/WisdomUI.api.json` **+22 符号**（`WDLayoutDensity`、
  `wdDensity` 读写入口、`WDSwitch` 及其 View 扩展入口）；无移除。
- **API 基线随 WDCheckbox/WDCard/WDIconButton 更新**：`api/WisdomUI.api.json` **+43 符号**
  （`WDCheckbox`、`WDCard`/`WDCardStyle`、`WDIconButton`/`WDIconButtonVariant`、`WDButtonSize`
  及其 View 扩展入口）；无移除。
- **`WDListRow` 选中底**：设计 18 的 8% 半透明品牌底会令系统对比度审计按**未合成**背景色计算
  （实测 `text.primary` 不达标）⇒ 改为不透明 `surface.tint`；8 态基线同步重录。
- **API 基线随 WDButton/WDListRow 更新**：`api/WisdomUI.api.json` **+53 符号**（`WDButton` 全家、
  `WDButtonStyle`、`ButtonStyle` 工厂、`WDListRow` 全家及其 View 扩展入口）；无移除 ⇒
  **M2 的 11 件公开面全部进入基线**。

### Breaking

- **`WDIconButtonVariant` 新增 4 个 case**（pre-1.0 源级 breaking，2026-11-15；设计 02 §4）：
  按 F-20，新增枚举 case 属源级 breaking（minor + 本段 + 迁移片段）。迁移 = 一般无需改代码；
  仅当调用方对该枚举做**穷举 `switch`** 时补 filled/tonal/glass/outline 分支。
  契约 `contracts/WDIconButton.yaml` 的 enums 需同步为 `[plain, filled, tonal, glass, outline]`
  （见 `docs/B4-CONTRACT-CHANGE-REQUEST.md`）。

- **`WDCardStyle` 新增 `.sunken`**（pre-1.0 源级 breaking，2026-11-15；设计 17 §4 的第四档）：
  按 F-20，新增枚举 case 属源级 breaking（minor + 本段 + 迁移片段）。迁移 = 一般无需改代码；
  仅当调用方对 `WDCardStyle` 做**穷举 `switch`** 时补一个 `.sunken` 分支。
  契约 `contracts/WDCard.yaml` 的 `enums.WDCardStyle` 需同步为 `[elevated, outlined, glass, sunken]`
  （见 `docs/B3-CONTRACT-CHANGE-REQUEST.md`）。

- **`WDPickerStyle` 新增 `.inline`**（pre-1.0 源级 breaking，2026-11-14；设计 22 §4 的三形态要求）：
  按 F-20，新增枚举 case 属源级 breaking（minor + 本段 + 迁移片段）。迁移 = 一般无需改代码；
  仅当调用方对 `WDPickerStyle` 做**穷举 `switch`** 时补一个 `.inline` 分支。
  契约 `contracts/WDPicker.yaml` 的 `enums.WDPickerStyle` 已同步为 `[menu, wheel, inline]`（2026-11-14）；
  Android 侧 C-15 副本同步为 `WDPickerStyle{Menu, Wheel, Inline}`。

- **`WDPullToRefresh` → `WDPullRefresh`**（pre-1.0 源级 breaking，2026-11-13；用户裁决）：
  公开类型与修饰符 `.wdPullToRefresh` → `.wdPullRefresh`；契约 yaml 同名更新；
  **Android 侧契约名待同步**（C-15 #32，android-lead）。迁移 = 全局替换两个标识符。
- `WDTextStyle.init(size:lineHeight:weight:)` **移除**（改为 `internal` 的 4 参数构造器）。
  本仓尚无消费方；迁移 = **不要自行构造字阶**，改用 `WDType.*` 常量。
- 其余无公开签名移除。本轮 API 基线变化：**+136 / −1**（`api/WisdomUI.api.json` 必须与成因**同一提交**）。

### Fixed

- **快照稳定性与 demo 对比度审计误判**（2026-11-14 复核）：`WDDatePicker` 快照改用固定 `Date`
  （UTC / `zh_CN`），消除跨日与 RTL 漂移；`WDButton` 的 1pt 顶部高光从独立 overlay 移入
  `background` 层，视觉不变，但不再被 `performAccessibilityAudit(.contrast)` 当成按钮背景
  （`提交` 的深色对比度曾被误判；移入背景层后 demo 13 条 UITest 全绿）。

- **`WDPullRefresh` 指示器与设计 32 不符**（2026-11-14，用户裁决）：原系统 `.refreshable` 的
  旋转 spinner 与设计稿的 24pt 品牌环不一致。iOS 18+ 改为自绘：24pt 环 / 2pt 线宽 /
  阈值 64 / 最大下拉 120 / 下拉随位移画进度 / 刷新中品牌弧 1s 线性旋转 / 完成后 160ms 收起 /
  到阈值一次 `.medium` 触觉 / Reduce Motion 静态弧；指示器覆盖在列表顶部、保持释放位置且不改变
  锚点高度；iOS 17 回退系统 `.refreshable`（登记差异）。三态文案不进库（L-B 零文案），
  组件实现设计 32 §4 的「极简」变体（只有环）；公开签名与 `api/WisdomUI.api.json` **零 diff**。
  新增单测 7 条 + demo XCUITest 1 条（下拉→计数 +1，含刷新中/完成截图）。契约 yaml 的载体注释
  已同步（`../wisdomdesign/contracts/WDPullRefresh.yaml`，2026-11-14）。

- **`WDSegmentedControl` 选中指示块不显示 / 详情页被拉满高度**（2026-11-13）：原用
  `GeometryReader` 背景量测段宽，首帧/快照/真机首屏可能拿到 0 宽 ⇒ 只剩字重差异；改为自定义
  `Layout` 直接等分并定位指示块（高度恒为内容高 32，忽略父级提出的高度，避免 demo 详情页被拉满），
  同时补上禁用态 40% 不透明度。8 张基线同步重录。
- **`WDTabBar` 图标整体偏上**（2026-11-13）：单行标签此前用 `wdLineBox(..., lines: 2)` 预留了两行行盒，
  图标/标签/圆点被顶到容器顶部；改为单行行盒 + `lineLimit(2)`，单行时垂直居中、两行时自然增高。
- **demo 审计夹具**（2026-11-12）：为 theme 页 `launch-count` 的 iOS 26 "Contrast nearly passed"
  告警加一条**点名窄例外**（13pt 文本；实测 text.primary on surface.card 约 16:1，**非 WCAG 失败**；
  同代码复跑 3/3 绿）。`Contrast failed` 仍严格失败，且不扩大到其他元素。

- **R15 对契约键名的假红**：原实现只要字面量含 L-B 标点就报错，而键名（如 `text.primary`）天然含
  `.` ⇒ 与 SPEC §3.7 的 I41"其余只允许标识符/键名"冲突。加键名形态白名单 + 正例样本
  （`R15_key_name_literal.swift`），反例（`、` 与词序模板）仍必须命中。

### 版本台账（发布时填）

| 层 | 值 | 来源 |
| --- | --- | --- |
| 令牌数据 | `1.0.0`（sha12 `e552bb87e270`） | `../wisdomdesign/dist/tokens.manifest.json` |
| 契约 | 未落库（M0-5 交付） | `../wisdomdesign/contracts/` |
| 库 | 未发布（无 tag） | 本仓 SPM tag |

## 发布 checklist（逐条可勾；口径 = `docs/DEV-PLAN.md` §10）

- [ ] **1. 设计仓冻结并打 tag**；生成器 `--check` 全绿（本端只读消费，不跨仓写）
- [ ] **2. 生成物 + 符号快照与成因同一提交**（`api/WisdomUI.api.json` 不得跨提交漂移）
- [ ] **3. 两端门禁绿**：`Scripts/ci.sh pr` + nightly **连续 3 日绿**
- [ ] **4. 发布前层**：真机 hitch（`scrollDecelerationMetric`）、首帧；归档 Thinning 增量
      （分母 = `Examples/BaselineShell/`）与体积门槛断言（U-09）
- [ ] **5. 双端同 tag** `v1.0.0`（**平台 tag 永远在最后**；tag 前核对三仓 HEAD 与版本台账）
- [ ] **6. 本文件写明 Breaking 段与迁移片段**（若追加/改签名）
- [ ] **7. 打错 tag 不移动不删除** ⇒ 发下一个补丁版本，并在本文件标注"废弃 vX.Y.Z"