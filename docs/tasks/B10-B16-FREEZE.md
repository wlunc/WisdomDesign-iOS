# B10–B16 冻结稿（agent 工作区副本）

> 本文件与 `iOS/docs/B10-B16-SIGNATURE-FREEZE.md` 同源，供各实现 agent 在工作区内阅读。

> **依据**：项目负责人 2026-11-15 下发「B. 纯代码可继续（不需要设计值）」清单；本批把 **B1（需扩公开）** 与 **B2（不改公开 API 的行为补齐）** 一次做完。
> **授权口径**：与 B7/B8 同口径 —— 项目负责人 2026-11-14「允许扩公开」继续有效；**只增不改**（既有 init / 既有默认值 / 既有类型一律保留）。
> **口径来源**：设计规格 `../wisdomdesign/docs/specs/`（各件给章节号）＋ `docs/SPEC.md` §2.10 矩阵里各件的处理档。
> **前置**：B1–B9 已完成；M2/M5 已判定通过。
> **编号**：B10 `WDDatePicker` / B11 `WDAvatarStack` / B12 `WDPullRefresh` / B13 `WDSlider` / B14 `WDSearchField`（**清单 B1 段**）＋ B15 `WDFAB`/`WDTabBar`/`WDNavigationBar` / B16 `WDSwitch`（**清单 B2 段**）。**B3 段（平台限制）= `docs/B3-PLATFORM-LIMITS.md`，只记录不实现。**

---

## 0. 两条贯穿全批的硬约束（先读）

### 0.1 L-B 零文案（F-08 / R15）

- 本批新增的**全部用户可见文字、播报措辞、按钮标签**都经 **L-B 注入点**进入：调用方传 `Text` 或 `@MainActor @Sendable` 闭包；库内**一个中文字符串字面量都不新增**（R15 判定面 = 字符串字面量）。
- `Text` 在组件里只做**透传**（`.accessibilityLabel(text)` / `.accessibilityValue(text)` / 交给已有的行盒），**不得** `.lineLimit` / `.truncationMode` / 拼标点 / 拼语序。
- **禁** `String(describing:)`（在 `Text` 上拿到的是 "Text(verbatim: …)" 调试串）。

### 0.2 不写 Environment（R18：写入口只在 `Foundation/Theme/WDEnvironment.swift`）

组件**只读**环境键，不得调用 `.environment(…)`。本批因此引入的接线件全部落在 Foundation/Internal（签名见 `docs/tasks/B10-B16-WIRING.md`）：

| 环境键 | 读它的组件 | 写入口 |
| --- | --- | --- |
| `wdAnnouncerText: WDTextPlayback?` | `WDPullRefresh` | `View.wdAnnouncer(_:)` |
| `wdScrollOffsetY: CGFloat?` | `WDFAB` / `WDTabBar` / `WDNavigationBar` | `View.wdScrollOffsetY(_:)` |
| `wdFocusRingFocused: Bool` | `WDSlider` | 派生（`.onChange(of:)` 挂在 `WDEnvironment.swift` 内部） |

---

## 1. 公开签名增量（汇总；只增不改）

```swift
// ── B10 WDDatePicker（Composites）────────────────────────────────────────────
extension WDDatePicker {
  /// 单日期 + 清除回调（设计 23 §8「清除 → 触发一次 onChange(nil)」）。
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,
    quickOptions: [WDDatePickerQuickOption] = [],
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil,
    onClear: (@MainActor @Sendable () -> Void)? = nil
  )

  /// 范围 + 时间（设计 23 §4「范围」与「日期 + 时间」组合：两段式，先日期后时间）。
  public init(
    range: Binding<ClosedRange<Date>?>,
    label: Text,
    placeholder: Text? = nil,
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil,
    onClear: (@MainActor @Sendable () -> Void)? = nil,
    mode: WDDatePickerMode = .date
  )
}

// ── B11 WDAvatarStack（Primitives）──────────────────────────────────────────
extension WDAvatarStack {
  /// 整叠点击（设计 13 §8「点击堆叠 / 点击 +n → 同点击堆叠」）。
  public init(
    items: [WDAvatarStackItem],
    accessibilityLabel: Text,
    size: WDAvatarStackSize = .md,
    onOverflowTap: (@MainActor @Sendable () -> Void)? = nil
  )
}

// ── B12 WDPullRefresh（Composites）──────────────────────────────────────────
/// 下拉刷新的阶段（设计 32 §5/§7/§8）。
public enum WDPullRefreshPhase: String, CaseIterable, Sendable, Equatable {
  case idle, pulling, armed, refreshing, completed, failed
}

/// 三态文案 / 状态播报的 L-B 注入点（库内零文案）。
public struct WDPullRefreshTexts: Sendable, Equatable {
  public var pull: Text?        // 「下拉刷新」
  public var release: Text?     // 「松开刷新」
  public var refreshing: Text?  // 「正在刷新」
  public var completed: Text?   // 「刷新完成」（成功播报；nil = 不播）
  public var failed: Text?      // 「刷新失败」（失败播报；nil = 不播）
  public init(pull: Text? = nil, release: Text? = nil, refreshing: Text? = nil,
              completed: Text? = nil, failed: Text? = nil)
}

extension WDPullRefresh {
  /// 带失败通道的构造（抛错／超时 = 失败；默认 10s 超时）。
  public init(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefreshError: (@MainActor @Sendable (any Error) -> Void)? = nil,
    timeout: Duration = .seconds(10),
    texts: WDPullRefreshTexts? = nil,
    onRefresh: @escaping @MainActor @Sendable () async throws -> Void
  )
}

extension View {
  public func wdPullRefresh(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefreshError: (@MainActor @Sendable (any Error) -> Void)? = nil,
    timeout: Duration = .seconds(10),
    texts: WDPullRefreshTexts? = nil,
    onRefresh: @escaping @MainActor @Sendable () async throws -> Void
  ) -> some View
}

// ── B13 WDSlider（Primitives）──────────────────────────────────────────────
extension WDSlider {
  /// 数值标签 + 焦点光环（设计 08 §2/§5/§6）。
  public init(
    value: Binding<Double>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil,
    showsValueLabel: Bool = false,
    valueText: ((Double) -> Text)? = nil
  )
}

// ── B14 WDSearchField（Primitives）──────────────────────────────────────────
extension WDSearchField {
  /// 标准变体 + 结果数播报注入点（设计 04 §8「结果更新通过 aria-live 播报」）。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    onSubmit: (() -> Void)? = nil,
    resultCount: Int? = nil,
    announcer: (@MainActor @Sendable (Int) -> Void)? = nil
  )

  /// 带取消变体 + 结果数播报注入点。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    cancelLabel: Text,
    onCancel: (() -> Void)? = nil,
    onSubmit: (() -> Void)? = nil,
    resultCount: Int? = nil,
    announcer: (@MainActor @Sendable (Int) -> Void)? = nil
  )
}

// ── B15 WDFAB / WDNavigationBar（Composites）───────────────────────────────
extension WDFAB {
  /// 展开遮罩 + TabBar 避让（设计 36 §5/§6/§8）；滚动缩小走环境键 `wdScrollOffsetY`。
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,
    size: WDFABSize = .standard,
    shape: WDFABShape = .roundedSquare,
    actions: [WDFABAction] = [],
    action: (() -> Void)? = nil,
    showsScrimWhenExpanded: Bool = false,
    avoidsTabBar: Bool = false
  )
}

extension WDNavigationBar {
  /// 滚动联动开关（设计 33 §4/§5/§8：大标题收缩 + 透明→玻璃）；滚动量走环境键 `wdScrollOffsetY`。
  public init(
    title: Text,
    mode: WDNavigationBarMode = .standard,
    style: WDNavigationBarStyle = .transparent,
    backAccessibilityLabel: Text? = nil,
    onBack: (() -> Void)? = nil,
    actions: [WDNavigationBarAction] = [],
    followsScroll: Bool = false
  )
}

// ── B16 WDSwitch（Primitives）──────────────────────────────────────────────
extension WDSwitch {
  /// 写入失败回弹（设计 05 §8「写入失败 → 轨道回弹 + 说明，不做静默失败」）。
  public init(
    isOn: Binding<Bool>, label: Text,
    onWriteFailure: (@MainActor @Sendable (_ attempted: Bool) -> Void)? = nil
  )
  public init(
    isOn: Binding<Bool>, label: Text, description: Text?, size: WDSwitchSize,
    onWriteFailure: (@MainActor @Sendable (_ attempted: Bool) -> Void)? = nil
  )
}
```

> **B14 定稿说明**：`announcer` 取 `(Int) -> Void`（传**结果数**，措辞由调用方格式化）而不是 `(Text) -> Void`：iOS 18 之前没有稳定的 `Text` → `String` 通道，用 `Text` 会造成"写得进、播不出"。

**兼容性判读（SPEC §2.9）**：全部是「新增带默认值的公开 init 参数」或「新增重载」⇒ **源码兼容、二进制兼容**；按 §2.9 规则 1 它们**会**改变符号快照连续性 ⇒ API 基线按 `Scripts/dump-api.sh --update` 显式更新并在 CHANGELOG 写明。新增类型（`WDPullRefreshPhase` / `WDPullRefreshTexts`）属新增，兼容。**符号计数以 `dump-api.sh` 实测为准，不手写。**

---

## 2. 逐件行为口径

### B10 · WDDatePicker（设计 23 §4/§8）

| 项 | 口径 |
| --- | --- |
| `onClear` | 用户点清除按钮、且值确实从非空变空时调**一次**；程序把 binding 置 nil（外部清空）不回调。 |
| 范围 + 时间 | `mode: .dateAndTime` 时弹层 = 月历 + 分隔线 + 时间滚轮；范围语义不变（两次点选成查）；时间只作用于当前正在选的那一端，整理后 `lower <= upper`。`.time` 在范围重载里按 `.date` 处理（debug 断言）。 |
| 兼容 | 既有三个 init 行为与签名一字不动。 |
| 快捷 Chip | 仍只在单日期 `.date` 渲染。 |

### B11 · WDAvatarStack（设计 13 §8/§10）

| 项 | 口径 |
| --- | --- |
| `onOverflowTap` | 非 nil 时**整叠**成为真 `Button`（不自造手势），点击即触发；读屏仍只读**一个**元素（`accessibilityLabel` 必填），角色为 button。 |
| 热区 | 不变（`minHeight: WDSize.touchTargetMin`），点击区域 = 整叠 bounds。 |
| 禁用 | 跟随 `.disabled(true)`。 |
| nil | 与 B 之前完全一致。 |

### B12 · WDPullRefresh（设计 32 §5/§7/§8/§10）

| 项 | 口径 |
| --- | --- |
| 阶段枚举 | 纯函数 `WDPullRefreshPhase.resolve(pull:isRefreshing:outcome:)`，必须可单测。 |
| 超时 | 默认 10s（设计 32 §8）：任务超时判失败；**不自建 Timer**（`Task.sleep` / `withThrowingTaskGroup` 竞速）。 |
| 失败通道 | 抛错或超时 ⇒ 环收起 + `isRefreshing = false` + `onRefreshError(error)` 一次 + （`texts.failed` 非 nil 且注入播报时）assertive 播报。**库内不弹 Toast**（零文案；调用方在 `onRefreshError` 里弹）。 |
| 三态文案 | `pulling` ⇒ `texts.pull`、`armed` ⇒ `texts.release`、`refreshing` ⇒ `texts.refreshing`；全 nil ⇒ 只画环（**逐像素不变**）。 |
| 播报 | 开始 polite / 成功 polite / 失败 assertive；**只在注入 `wdAnnouncer` 且文案非 nil 时播**。 |
| 旧 init | `init(isRefreshing:label:onRefresh:)` 行为不变（无超时、无失败通道）；内部可复用到同一实现。 |
| iOS 17 回退 | 同样走失败/超时/播报（不要求像素一致）。 |

### B13 · WDSlider（设计 08 §2/§5/§6/§7）

| 项 | 口径 |
| --- | --- |
| `showsValueLabel` | 标签行右侧显示数值（`valueText` 给文案；nil 时用系统 Double 本地化，**不拼单位/百分号**）；`.monospacedDigit()`；拖动实时更新；`accessibilityHidden(true)`。 |
| 焦点光环 | `wdFocusRingFocused` 为 true（读屏焦点落在本滑杆）时手柄外扩 **3pt** 光环（`state.focus.ring` 槽位 + `WDState.focusRingWidth`），160ms 淡入；Reduce Motion 直出。 |
| 零默认影响 | `showsValueLabel = false`（默认）前景象逐像素不变。 |

### B14 · WDSearchField（设计 04 §8/§10）

| 项 | 口径 |
| --- | --- |
| `announcer` + `resultCount` | 同时非 nil 且结果数**变化**（首帧不播）时调一次 `announcer(count)`；判定为内部纯函数，必须可单测。 |
| 旧 init | 行为不变（不传 = 不播）。 |

### B15 · WDFAB / WDTabBar / WDNavigationBar（设计 36 §5/§6/§8、设计 34 §6/§9、设计 33 §3/§4/§5/§8/§9）

| 组件 | 口径 |
| --- | --- |
| `WDFAB(showsScrimWhenExpanded:)` | 展开时同层级遮罩（`accessibilityHidden(true)`；点它 / 读屏 `.escape` 动作都收起，不执行主操作）。`false` ⇒ 与 B 之前一致。 |
| `WDFAB` 滚动缩小 | 读 `wdScrollOffsetY`：向下滚 ⇒ 缩到 **40** + 降不透明度（`motion.spring.gentle`）；向上/到顶恢复；**不隐藏**。 |
| `WDFAB(avoidsTabBar:)` | 底部留白 18 → **92**（设计 36 §6：58 + 8 + 留白）；**不动安全区**（F36）。 |
| `WDTabBar` | 读 `wdScrollOffsetY`：向下滚超阈值 ⇒ 收起标签行（无标签胶囊），向上滚**立即**展开；`selection`/热区不变；**不新增 init**。 |
| `WDNavigationBar(followsScroll:)` | ① 大标题按 0…52pt 进度收缩（大标题行压到 0、标题交叉淡化进内联行）；② `.transparent` 档在 offset > 0 时 **240ms** 交叉淡化到玻璃（`WDGlass.resolve` 口径同 `.glass`，计入预算）；③ 读屏不重复朗读标题；`false` ⇒ 完全沿用 `style`/高度。 |
| 无 offset | `wdScrollOffsetY == nil` ⇒ 三者都**不联动**，默认路径像素不变。 |

### B16 · WDSwitch（设计 05 §8/§12）

| 项 | 口径 |
| --- | --- |
| 写入失败判定 | 记录用户刚发起的意图值；写入 binding 后**一次** `Task { @MainActor in await Task.yield() }` 检查 binding 是否等于意图；不等 ⇒ 回弹到 binding 当前值 + `onWriteFailure(intent)` 一次。 |
| 不误伤 | 外部正常改写 binding（非本组件发起）不触发回弹。 |
| nil | 不传 ⇒ 与 B 之前一致（不回弹、不回调）。 |

---

## 3. 设计值落点（**全部有出处**；无出处一律写「设计未给值」）

| 项 | 值 | 出处 |
| --- | --- | --- |
| DatePicker 清除回调 | 清空后回调一次 | 设计 23 §8 |
| DatePicker 范围+时间 | 两段式先日期后时间 | 设计 23 §4 / §11 |
| AvatarStack 整叠点击 | 热区 = 整叠 | 设计 13 §8 / §10 |
| PullRefresh 超时 | **10s** | 设计 32 §8 |
| PullRefresh 三态文案位 | 环旁 | 设计 32 §2/§7 |
| Slider 数值标签 | 标签行右侧、等宽数字 | 设计 08 §6 |
| Slider 焦点光环 | 外扩 **3pt**、160ms | 设计 08 §5 |
| SearchField 结果播报 | 结果数变化时播报一次 | 设计 04 §8 / §10 |
| FAB 滚动尺寸 | 缩到 **40** + 降不透明度 | 设计 36 §5 |
| FAB 避让 TabBar | 底部 **92** | 设计 36 §6 |
| FAB 展开遮罩 | 点遮罩收起 | 设计 36 §8 |
| NavBar 大标题收缩 | 跟随滚动进度（0…52pt） | 设计 33 §3/§5/§9 |
| NavBar 玻璃切换 | **240ms** 交叉淡化 | 设计 33 §5/§9 |
| TabBar 滚动收缩 | 向下收缩 / 向上立即展开 | 设计 34 §6/§9 |
| Switch 写入失败 | 回弹 + 说明（说明由调用方弹 Banner） | 设计 05 §8 |

---

## 4. 未纳入本批（见 `docs/B3-PLATFORM-LIMITS.md` 与下文）

- **平台限制（B3 段，只记录）**：`WDRadio`/`WDPicker`/`WDSegmentedControl` 的 radio / listbox / option 角色；`WDPicker` 滚轮形态的系统 `.wheel` 即时提交。
- **Slider 键盘焦点光环**：UISlider 的"键盘聚焦"在 iOS 上没有可观测的公开事件（无法与触摸聚焦区分）⇒ 光环只接读屏焦点，键盘路径按平台限制登记。
- **Slider 范围双手柄**：需要新的受控值形态（`Binding<ClosedRange<Double>>`，C-15 级），留独立批。
- **DatePicker 跨午夜过期翻转 / 读屏「已过期」状态**：仓规禁组件自建计时器（B8 仍开放）。
- **FAB 焦点移入后回收 / 关闭时焦点归还**：B7 已做"移入"，归还属新语义，留后续。

---

## 5. 验收（每件）

1. 单测（`Tests/WisdomUITests/Components/`）：新参数的新行为各 ≥ 2 条（正向 + 缺省不变）；纯逻辑（阶段枚举/超时竞速/写入失败判定/收缩进度/播报判定/范围+时间合成）全部走纯函数；
2. `Scripts/ci.sh pr`：`check-structure.sh --strict`（R1–R21 全绿、**零新增豁免**）＋ `check-format.sh` ＋ 编译 ＋ `dump-api.sh`（基线有意变更同提交）；
3. 快照：**默认参数路径不得产生任何基线漂移**；新 UI 通过单测/预览验证，**不扩快照矩阵**（不改 snapshot 套件、不改 `+Previews.swift`）；
4. 契约：`contracts/*.yaml` 增量按 `docs/B10-B15-CONTRACT-CHANGE-REQUEST.md` 由架构师/设计侧落库（跨仓只读）。
