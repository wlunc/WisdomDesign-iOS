import SwiftUI

/// 分段控件的一项（设计 21；值数组 `items`）。
public struct WDSegmentedControlItem: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 段文字。
  public let label: Text

  /// 构造：身份 + 文字。
  public init(id: String, label: Text) {
    self.id = id
    self.label = label
  }
}

/// 分段控件外观档（设计 21 §4：玻璃 / 实底）。
public enum WDSegmentedControlStyle: String, CaseIterable, Sendable, Equatable {
  /// `surface.glass` + hairline（经 `WDGlass.resolve` 降级）。
  case glass
  /// `fill.field`（页面内常规位置）。
  case solid
}

/// 分段控件（SPEC §2.10-#21；M5；台账 A-8 补交互与位置文案）。
///
/// 设计口径（设计 21）：
/// - 容器高 **38**（内容 32 + 上下内边距 3）、单段最小宽 **56**、段水平内距 14、字号 13（medium/选中 600）；
/// - 指示块 = 圆角胶囊、`surface.card-solid` + `elevation.1`，弹簧滑动（`motion.spring.snappy`）；
/// - 2–5 段等分，不按文字长度分配；点击已选项不重复回调；
/// - 交互（设计 21 §8）：点击即时切换；**段间横向拖动**——指示块跟手、松手吸附该段并提交；
///   **方向键 ←/→** 在段之间即时切换，到端点停住（不环绕、不越界）；
/// - 无障碍（设计 21 §10）：每段的位置措辞「第 n 项，共 m 项」由调用方经
///   `positionText` / `positionSeparator` 注入（`WDSemantics.positional` 结构拼接，库内零文案）；
/// - 玻璃档走 `WDGlass.resolve`（文字级别 secondary），计入效果配额；深色端自动降级为不透明。
///
/// 角色 `tablist`/`tab` 属已登记平台限制（`docs/B3-PLATFORM-LIMITS.md` L-3：SwiftUI 无对应 trait），
/// 本件只补位置文案，不改角色；段宽用 `Layout` 直接定位（不包内容）。
///
/// 键盘验证边界：硬件键盘的按键投递需要完全键盘访问（full keyboard access），单测层无法注入按键
/// 事件 ⇒ 本件只以纯逻辑单测覆盖「下标推进/端点钳制」，真机键盘行为记【未验证】
///（`docs/SPEC.md` §8.2 口径，待验证层补）。
public struct WDSegmentedControl: View {
  private let items: [WDSegmentedControlItem]
  @Binding private var selection: String
  private let style: WDSegmentedControlStyle
  /// 位置措辞（第 n 项，共 m 项）的 L-B 注入点；`nil` = 不朗读位置。
  private let positionText: ((Int, Int) -> Text)?
  /// 位置措辞与段文字之间的分隔符（由调用方给；默认空 ⇒ 库内不加任何标点）。
  private let positionSeparator: Text

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.layoutDirection) private var layoutDirection

  /// 拖动中手指所在段（`nil` = 未拖动）：指示块跟随它，松手提交该段。
  @State private var dragSegmentIndex: Int?
  /// 段区宽度（由 `onGeometryChange` 量得；首帧为 0 ⇒ 不换算拖动位置，避免跳段）。
  @State private var segmentAreaWidth: CGFloat = 0

  /// 构造：项数组 + 受控选中 id + 外观档。
  ///
  /// - `positionText`：位置措辞（入参 = 第几项 1 起、共几项），措辞**全部由调用方给**；
  /// - `positionSeparator`：位置措辞与段文字之间的分隔符（**由调用方给**；默认空串，库内零标点）。
  public init(
    items: [WDSegmentedControlItem],
    selection: Binding<String>,
    style: WDSegmentedControlStyle = .solid,
    positionText: ((Int, Int) -> Text)? = nil,
    // 默认空串 = 库内零标点（L-B）：分隔符只在调用方显式给时才出现。
    positionSeparator: Text = Text(verbatim: "")  // wd-structure-check:disable R21 — 默认空串（不是文本容器）
  ) {
    self.items = items
    self._selection = selection
    self.style = style
    self.positionText = positionText
    self.positionSeparator = positionSeparator
  }

  /// 指示块 + 等分段落（用 `Layout` 直接定位，避免量测在首帧/快照/真机首屏取不到宽度）。
  public var body: some View {
    WDSegmentedControlLayout(
      count: max(items.count, 1),
      selectedIndex: indicatorIndex,
      contentHeight: Self.contentHeight,
      minSegmentWidth: Self.minSegmentWidth
    ) {
      indicator
      ForEach(items) { item in
        segment(item)
      }
    }
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { width in
      segmentAreaWidth = width
    }
    .simultaneousGesture(dragGesture)
    .padding(Self.containerPadding)
    .background(Capsule().fill(containerFill))
    .overlay(Capsule().stroke(containerStroke, lineWidth: 1))
    .opacity(isEnabled ? 1 : disabledOpacity)
    .animation(WDMotion.Spring.snappy, value: selection)
    // 方向键（设计 21 §8）：按键从获得键盘焦点的段向上冒泡到这里；返回 .handled 即拦下，
    // 不再落到系统的「方向键移动焦点」。容器本身不额外声明 focusable —— 那会给读屏/键盘
    // 引入一个新的焦点目标（段是唯一可见焦点）。【未验证】真机硬件键盘（完全键盘访问）下的
    // 实按键行为待验证层补；单测只覆盖 arrowIndex 的推进与端点钳制。
    .onKeyPress(.leftArrow) { handleArrow(visualStep: -1) }
    .onKeyPress(.rightArrow) { handleArrow(visualStep: 1) }
    .accessibilityElement(children: .contain)
    .onAppear {
      assert(
        (Self.minSegments...Self.maxSegments).contains(items.count),
        "WDSegmentedControl 段数须为 2–5（设计 21 §4）"
      )
    }
  }

  // MARK: - 零件

  @ViewBuilder private func segment(_ item: WDSegmentedControlItem) -> some View {
    let index = items.firstIndex { $0.id == item.id } ?? 0
    let isSelected = item.id == selection
    if let positionLabel = positionAccessibilityLabel(index: index) {
      segmentButton(item, isSelected: isSelected)
        .accessibilityLabel(positionLabel)
    } else {
      segmentButton(item, isSelected: isSelected)
    }
  }

  private func segmentButton(_ item: WDSegmentedControlItem, isSelected: Bool) -> some View {
    Button {
      commit(id: item.id)
    } label: {
      item.label
        .wdFont(WDType.footnote)
        .wdLineBox(WDType.footnote)
        .fontWeight(isSelected ? .semibold : .medium)
        .foregroundStyle(isSelected ? colors.textPrimary : colors.textSecondary)
        .frame(maxWidth: .infinity, minHeight: Self.contentHeight)
        .contentShape(Rectangle())
    }
    .buttonStyle(WDSegmentedPressStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder private var indicator: some View {
    if items.count > 1 {
      Capsule()
        .fill(colors.surfaceCardSolid)
        .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
        .wdShadow(WDElevation.e1)
        .accessibilityHidden(true)
    }
  }

  // MARK: - 交互（设计 21 §8）

  /// 段间横向拖动。
  ///
  /// **不属于 SPEC §3.4 的禁则**：该条禁的是 `DragGesture(minimumDistance: 0)` 伪造「按下态」
  /// （按下只能来自 `ButtonStyleConfiguration.isPressed`）。这里 `minimumDistance: 1`，
  /// 轻点（零位移）永不进入拖动分支 ⇒ 点击路径逐字不变；与 `WDSwitch` 的轨道拖动同形
  /// （`simultaneousGesture` + 横向占优判定，纵向位移留给父级 `ScrollView`）。
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 1, coordinateSpace: .local)
      .onChanged(handleDragChanged)
      .onEnded(handleDragEnded)
  }

  /// 本次拖动是否接管：可用 + 已量到宽 + （已在拖动中或横向占优）。
  ///
  /// 未量到宽（首帧/快照）时不换算位置，避免把一切拖动都算成第 0 段（"跳段"）。
  private func acceptsDrag(_ value: DragGesture.Value) -> Bool {
    guard isEnabled, segmentAreaWidth > 0 else { return false }
    if dragSegmentIndex != nil { return true }
    return WDSegmentedControlInteraction.shouldBegin(translation: value.translation)
  }

  /// 手指 x → 目标段下标（跟手与吸附共用一个换算）。
  private func segmentIndex(at x: CGFloat) -> Int {
    WDSegmentedControlInteraction.segmentIndex(
      at: x, width: segmentAreaWidth, count: items.count)
  }

  /// 拖动中：指示块跟随手指所在段（只改跟手状态，不写 `selection`）。
  private func handleDragChanged(_ value: DragGesture.Value) {
    guard acceptsDrag(value) else { return }
    dragSegmentIndex = segmentIndex(at: value.location.x)
  }

  /// 松手：吸附手指所在段并提交（与跟手用同一换算 ⇒ 跟到哪段就吸附到哪段）。
  private func handleDragEnded(_ value: DragGesture.Value) {
    guard acceptsDrag(value) else {
      dragSegmentIndex = nil
      return
    }
    dragSegmentIndex = nil
    commit(index: segmentIndex(at: value.location.x))
  }

  /// 方向键：←/→ 在段之间即时切换（设计 21 §8）；到端点停住，不环绕、不越界。
  ///
  /// RTL 下段序沿 leading→trailing 排布，方向按视觉方向映射（← = 下一段）。
  /// 与点击、拖动走**同一条**提交路径（`commit(index:)`），不为键盘另开分叉。
  private func handleArrow(visualStep: Int) -> KeyPress.Result {
    guard isEnabled else { return .ignored }
    let target = WDSegmentedControlInteraction.arrowIndex(
      selected: selectedIndex,
      visualStep: visualStep,
      isRTL: layoutDirection == .rightToLeft,
      count: items.count
    )
    commit(index: target)
    return .handled
  }

  /// 唯一的提交路径：点击 / 拖动松手 / 方向键都走这里（同一条写入 + 同一处触觉）。
  ///
  /// 点击已选中项、拖动回原段、方向键在端点 ⇒ `commitTarget` 返回 nil，不重复回调（设计 21 §8）。
  private func commit(index: Int) {
    guard
      let id = WDSegmentedControlInteraction.commitTarget(
        ids: items.map(\.id), selected: selection, index: index)
    else { return }
    selection = id
    WDHaptics.shared.play(.toggle, budget: budget)
  }

  /// 按 id 提交（点击路径）：换算成下标后与拖动/键盘共用同一个提交判定。
  private func commit(id: String) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    commit(index: index)
  }

  /// 段的位置朗读标签（internal：供单测断言，不是公开 API）。
  ///
  /// 结构 = `WDSemantics.positional(label:positionText:separator:)`：**措辞与分隔符都由调用方给**，
  /// 库内不新增任何字面量（L-B）；`positionText == nil` ⇒ nil（沿用系统从 `item.label` 派生的标签）。
  func positionAccessibilityLabel(index: Int) -> Text? {
    guard let positionText, items.indices.contains(index) else { return nil }
    return WDSemantics.positional(
      label: items[index].label,
      positionText: positionText(index + 1, items.count),
      separator: positionSeparator
    )
  }

  // MARK: - 计算

  /// 指示块下标：拖动中跟手，否则跟选中项。
  private var indicatorIndex: Int {
    dragSegmentIndex ?? selectedIndex
  }

  private var selectedIndex: Int {
    items.firstIndex { $0.id == selection } ?? 0
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 容器底色：玻璃档走唯一入口；实底档 `fill.field`。
  private var containerFill: Color {
    switch style {
    case .solid:
      return colors.fillField
    case .glass:
      switch WDGlass.resolve(
        textLevel: .secondary,
        appearance: appearance,
        capabilities: WDGlassCapabilities(supportsGlass: Self.runtimeSupportsGlass()),
        budget: budget,
        level: .thick
      ) {
      case .glass: return colors.surfaceGlass
      case .glassStrong: return colors.surfaceGlassStrong
      case .opaque: return colors.surfaceCardSolid
      }
    }
  }

  private var containerStroke: Color {
    switch style {
    case .solid: return .clear
    case .glass: return colors.borderHairline
    }
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  /// 段数下限 2（设计 21 §4）。
  private static let minSegments = 2  // wd-structure-check:disable R7 — 设计
  /// 段数上限 5（设计 21 §4）。
  private static let maxSegments = 5  // wd-structure-check:disable R7 — 设计
  /// 上下内边距 3（设计 21 §3）。
  private static let containerPadding: CGFloat = 3  // wd-structure-check:disable R7 — 设计值
  /// 内容高 32（设计 21 §3）。
  private static let contentHeight: CGFloat = 32  // wd-structure-check:disable R7 — 设计值
  /// 单段最小宽 56（设计 21 §3）。
  private static let minSegmentWidth: CGFloat = 56  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 分段控件布局：第 0 个子视图 = 指示块，其余 = 等分段。
///
/// 用 `Layout` 直接按容器宽度等分并放置指示块，避免 `GeometryReader` 量测在首帧/快照/真机首屏
/// 取不到宽度（表现为"选中态没有指示块"）。
private struct WDSegmentedControlLayout: Layout {
  let count: Int
  let selectedIndex: Int
  let contentHeight: CGFloat
  let minSegmentWidth: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let minimum = minSegmentWidth * CGFloat(count)
    let width = max(proposal.width ?? minimum, minimum)
    // 高度恒为内容高 32：忽略父级提出的高度（否则放进 VStack/详情页会被拉成整屏高）。
    return CGSize(width: width, height: contentHeight)
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    guard subviews.count > count, count > 0 else { return }
    let segmentWidth = bounds.width / CGFloat(count)
    for index in 0...count {
      let x = bounds.minX + segmentWidth * CGFloat(max(index - 1, 0))
      let isIndicator = index == 0
      if isIndicator, selectedIndex < 0 || selectedIndex >= count { continue }
      subviews[index].place(
        at: CGPoint(
          x: isIndicator ? bounds.minX + segmentWidth * CGFloat(selectedIndex) : x, y: bounds.minY),
        proposal: ProposedViewSize(width: segmentWidth, height: bounds.height)
      )
    }
  }
}

/// 分段控件的交互换算（纯逻辑；internal：供单测断言，不是公开 API）。
///
/// 拖动位置 → 目标段、越界钳制、提交去重、键盘推进都收在这里；视图层只负责把手指/按键事件
/// 喂进这些纯函数（与 `WDSwitchDrag` 同形）。
enum WDSegmentedControlInteraction {
  /// 是否接管本次拖动：横向分量不弱于纵向（纵向留给父级 `ScrollView`，与 `WDSwitchDrag` 同口径）。
  static func shouldBegin(translation: CGSize) -> Bool {
    abs(translation.width) >= abs(translation.height)
  }

  /// 手指 x → 目标段下标：等分、段边界左闭右开、越界钳制到首/末段。
  ///
  /// 拖动中（指示块跟手）与松手（吸附并提交）**用同一函数**，所以"跟到哪段就吸附到哪段"。
  /// `count == 0` 或 `width <= 0`（首帧未量到宽）⇒ 0（调用方另有 `width > 0` 闸门）。
  static func segmentIndex(at x: CGFloat, width: CGFloat, count: Int) -> Int {
    guard count > 0, width > 0 else { return 0 }
    let raw = Int((x / (width / CGFloat(count))).rounded(.down))
    return clampedIndex(raw, count: count)
  }

  /// 下标钳制：端点停住，不越界、不环绕到不存在的位置（键盘推进与拖动共用）。
  static func clampedIndex(_ index: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(index, 0), count - 1)
  }

  /// 方向键的推进结果（设计 21 §8）：视觉上 ←/→ 各走一段，端点钳制。
  ///
  /// RTL 下段序沿 leading→trailing 排布，视觉方向与下标方向相反 ⇒ 先按 `isRTL` 反转步进，
  /// 再钳制；不做环绕（"不环绕到不存在的位置"）。
  static func arrowIndex(selected: Int, visualStep: Int, isRTL: Bool, count: Int) -> Int {
    let step = isRTL ? -visualStep : visualStep
    return clampedIndex(selected + step, count: count)
  }

  /// 提交目标：下标越界或与当前选中相同 ⇒ nil（点击已选项 / 拖回原段不重复回调）。
  static func commitTarget(ids: [String], selected: String, index: Int) -> String? {
    guard ids.indices.contains(index) else { return nil }
    let id = ids[index]
    return id == selected ? nil : id
  }
}

/// 按下时文字降到 70% 不透明度（设计 21 §5）。
private struct WDSegmentedPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.7 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
