import SwiftUI

/// 导航栏模式（设计 33 §3：内联 44 / 标准 56 / 大标题 96）。
public enum WDNavigationBarMode: String, CaseIterable, Sendable, Equatable {
  /// 内联（紧凑）44。
  case inline
  /// 标准 56。
  case standard
  /// 大标题 96（内联行 44 + 大标题区 52）。
  case largeTitle
}

/// 导航栏底色档（设计 33 §4：透明 / 玻璃）。
public enum WDNavigationBarStyle: String, CaseIterable, Sendable, Equatable {
  /// 透明底（内容未滚动）。
  case transparent
  /// 玻璃底（经 `WDGlass.resolve`）。
  case glass
}

/// 导航栏右侧动作（≤2 个；每个必须有读屏标签）。
public struct WDNavigationBarAction: Identifiable {
  /// 稳定身份。
  public let id: String
  /// 图标语义名。
  public let icon: WDIconName
  /// 读屏标签。
  public let accessibilityLabel: Text
  /// 动作。
  public let action: () -> Void

  /// 构造：身份 + 图标 + 标签 + 动作。
  public init(
    id: String,
    icon: WDIconName,
    accessibilityLabel: Text,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.action = action
  }
}

/// 导航栏（SPEC §2.10-#33；M5）。
///
/// 设计口径（设计 33）：
/// - 内联 44 / 标准 56 / 大标题 96；左右边距 16；图标按钮视觉 32、热区 44；
/// - 透明 / 玻璃两档；玻璃走 `WDGlass.resolve`（文字级别 primary）并计入效果配额；
/// - 返回按钮标签由调用方给（如「返回家庭列表」）；右侧 ≤2 个动作；
/// - 标题作为页面标题（header trait）被首个朗读。
///
/// B15 增量（设计 33 §4/§5/§8/§9）：`followsScroll` 打开后只读 `wdScrollOffsetY`
/// （nil = 不联动）：
/// - **大标题折叠**：按 0…52pt 进度收缩 —— 大标题行压到 0、行内容上收吸到内联行，内联标题
///   随进度交叉淡入（视觉上"缩到内联标题的位置并降字号"，设计 33 §5）；
/// - **透明 → 玻璃**：`.transparent` 档在 offset > 0 时 240ms 交叉淡化到玻璃，
///   口径与 `.glass` 相同（`WDGlass.resolve` + 计入效果预算）；
/// - **读屏不重复朗读**：透明那一处标题离开可访问树（避免焦点落在看不见的字上），折叠完成后
///   只由内联位上的页面标题节点（header trait）朗读一次；
/// - **读屏态恒定**：隐藏判据只由 scroll offset 决定，不含"是否正在显示"一类变量，
///   节点不会因为读写屏焦点而反复进出可访问树；
/// - `false` ⇒ 完全沿用 `style` 与既有高度，像素不变。
///
/// 安全区由调用方安装（`.safeAreaInset`）。
public struct WDNavigationBar: View {
  private let title: Text
  private let mode: WDNavigationBarMode
  private let style: WDNavigationBarStyle
  private let backAccessibilityLabel: Text?
  private let onBack: (() -> Void)?
  private let actions: [WDNavigationBarAction]
  private let followsScroll: Bool

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget
  /// 滚动 offset（B15 接线件；nil = 不联动）。
  @Environment(\.wdScrollOffsetY) private var scrollOffsetY

  /// 构造：标题 + 模式/底色 + 返回 + 右侧动作 + 滚动联动。
  public init(
    title: Text,
    mode: WDNavigationBarMode = .standard,
    style: WDNavigationBarStyle = .transparent,
    backAccessibilityLabel: Text? = nil,
    onBack: (() -> Void)? = nil,
    actions: [WDNavigationBarAction] = [],
    followsScroll: Bool = false
  ) {
    self.title = title
    self.mode = mode
    self.style = style
    self.backAccessibilityLabel = backAccessibilityLabel
    self.onBack = onBack
    self.actions = actions
    self.followsScroll = followsScroll
  }

  /// 顶栏（+ 大标题行）。
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      topRow
      if mode == .largeTitle {
        largeTitleRow
      }
    }
    .frame(minHeight: barHeight, alignment: .top)
    .background(barBackground)
    .overlay(alignment: .bottom) { bottomHairline }
    .accessibilityElement(children: .contain)
    .onAppear {
      assert(actions.count <= Self.maxActions, "WDNavigationBar 右侧最多 2 个动作（设计 33 §6）")
    }
  }

  // MARK: - 零件

  private var topRow: some View {
    ZStack {
      HStack(spacing: WDSpacing.s3) {
        if let backAccessibilityLabel {
          backButton(backAccessibilityLabel)
        }
        Spacer(minLength: 0)
        ForEach(actions) { action in
          actionButton(action)
        }
      }
      if mode != .largeTitle {
        inlineTitle
      }
    }
    .padding(.horizontal, WDSpacing.s5)
    .frame(minHeight: topRowHeight)
  }

  /// 内联标题（折叠期淡入；不折叠时恒为 1 —— 原有视觉不变）。
  ///
  /// **折叠只属于大标题模式**（B19 修复）：`.inline` / `.standard` 本来就只有这一处标题，
  /// 若也乘折叠进度（该模式进度恒为 0）会把标题整条画成透明 —— 2026-11-20 的 8 态快照实测到该回归。
  private var inlineTitle: some View {
    title
      .wdFont(WDType.headline)
      .wdLineBox(WDType.headline)
      .foregroundStyle(colors.textPrimary)
      .lineLimit(1)
      .opacity(inlineTitleOpacity)
      // 读屏态在同一 offset 下恒定（不随"是否正在显示"变），避免节点进出树导致焦点抖动；
      // 折叠完成后由它单独承担朗读，大标题那处改挂 .invisible（设计 33 §10 只读一次）。
      .accessibilityAddTraits(.isHeader)
      .accessibilityHidden(!isInlineTitleShowing || scrollLinkedFolded)
      .padding(.horizontal, Self.titleHorizontalInset)
  }

  /// 大标题行：行本身按进度压到 0，行内容上收吸到内联行（设计 33 §5/§8/§9）。
  private var largeTitleRow: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 横向与内联标题同边距，两处标题交叉淡化时左边缘对齐。
      title
        .wdFont(WDType.largeTitle)
        .wdLineBox(WDType.largeTitle)
        .foregroundStyle(colors.textPrimary)
        .lineLimit(1)
        .opacity(1 - progress)
        .accessibilityAddTraits(.isHeader)
        .accessibilityHidden(!isLargeTitleShowing)
        .modifier(WDNavTitleAccessibilityInvisible(isInvisible: scrollLinkedFolded))
    }
    .padding(.horizontal, WDSpacing.s5)
    // 行高：不联动时用 minHeight（保持 U7 的「只增不裁」原口径，像素与 B15 之前一致）；
    // 联动时必须用**定高**，否则 frame(minHeight: 0) 只会放下限、不会把行压到 0（行仍占内容高），
    // 整栏也就收不到 44。定高只作用于联动路径，标题靠 offset 上移并淡出，不裁字。
    .modifier(
      WDNavLargeTitleRowSizing(isScrollLinked: isScrollLinked, height: largeRowHeight)
    )
    // 折到 0 时保住行内容高度（否则标题本身被压没），展开态走 else 分支 ⇒ 像素与原来一致。
    .modifier(WDNavCollapsedRowKeepSize(active: isFolded))
    .offset(y: -largeTitleCollapseOffset)
  }

  private func backButton(_ label: Text) -> some View {
    Button {
      onBack?()
    } label: {
      WDIcon(icon: .back, size: .md)
        .foregroundStyle(colors.textBrand)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private func actionButton(_ action: WDNavigationBarAction) -> some View {
    Button {
      action.action()
    } label: {
      WDIcon(icon: action.icon, size: .md)
        .foregroundStyle(colors.textBrand)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(action.accessibilityLabel)
  }

  // MARK: - 滚动联动（B15，纯函数便于单测）

  /// 折叠进度：offset 0 → 0，走完 52（大标题区高度）→ 1，之后封顶。
  /// 不联动（`followsScroll == false`）⇒ 0（保持展开）。
  static func titleProgress(scrollOffsetY: CGFloat?, followsScroll: Bool) -> CGFloat {
    guard followsScroll else { return 0 }
    return WDScrollLink.progress(scrollOffsetY: scrollOffsetY, distance: collapseDistance)
  }

  /// 大标题行当前高度：52 → 0（按折叠进度线性收缩）。
  static func largeTitleRowHeight(scrollOffsetY: CGFloat?, followsScroll: Bool) -> CGFloat {
    scrollLinkedLargeTitleRowHeight(
      progress: titleProgress(scrollOffsetY: scrollOffsetY, followsScroll: followsScroll))
  }

  /// 由进度直接算大标题行高度（视图侧与标题透明度共用同一个进度）。
  static func scrollLinkedLargeTitleRowHeight(progress: CGFloat) -> CGFloat {
    largeTitleRowHeightFull * (1 - min(1, max(0, progress)))
  }

  /// 大标题行向上吸的距离：进度走满时位移 = 内联行高度（标题落到内联行里），期间线性跟随。
  static func largeTitleCollapseOffset(progress: CGFloat, topRowHeight: CGFloat) -> CGFloat {
    topRowHeight * min(1, max(0, progress))
  }

  /// 整栏最小高度：不联动 = 既有口径（内联 44 / 标准 56 / 大标题 96）；
  /// 联动时大标题栏随折叠从 96 收到 44（设计 33 §3/§5）。
  static func barHeight(
    mode: WDNavigationBarMode,
    scrollOffsetY: CGFloat?,
    followsScroll: Bool
  ) -> CGFloat {
    switch mode {
    case .inline: return WDSize.navbarCompact
    case .standard: return WDSize.navbarStandard
    case .largeTitle:
      guard followsScroll else { return WDSize.navbarCompact + largeTitleRowHeightFull }
      return WDSize.navbarCompact
        + scrollLinkedLargeTitleRowHeight(
          progress: titleProgress(scrollOffsetY: scrollOffsetY, followsScroll: followsScroll))
    }
  }

  /// 滚动联动是否生效（`followsScroll` 且宿主给了 offset）。
  private var isScrollLinked: Bool {
    followsScroll && scrollOffsetY != nil
  }

  /// 折叠到接近完成即视为"视觉上已折叠"（阈值与 1 的间隙不足半像素；只管视觉）。
  private var isFolded: Bool {
    progress >= Self.foldedThreshold
  }

  /// 读屏去重生效：联动 + 已折叠（与上面同一判据，语义独立命名便于阅读）。
  private var scrollLinkedFolded: Bool {
    isScrollLinked && isFolded
  }

  /// 大标题是否"正在显示"（透明度 > 0）。为 false 时该标题不该被读到，也不该承接焦点。
  private var isLargeTitleShowing: Bool {
    progress < Self.foldedThreshold
  }

  /// 内联标题是否"正在显示"（透明度 > 0）。
  ///
  /// 非大标题模式恒显示（该模式没有第二处标题）；大标题模式随折叠进度淡入。
  private var isInlineTitleShowing: Bool {
    mode != .largeTitle || progress > 0
  }

  /// 内联标题的不透明度：非大标题模式恒 1，大标题模式随折叠进度淡入。
  private var inlineTitleOpacity: CGFloat {
    mode == .largeTitle ? progress : 1
  }

  private var progress: CGFloat {
    Self.titleProgress(scrollOffsetY: scrollOffsetY, followsScroll: followsScroll)
  }

  /// 玻璃淡入：`.glass` 全程 1；`.transparent` 联动时离开顶部（offset > 0）即到 1，
  /// 交叉淡化由视图侧的 240ms 动画完成（设计 33 §5）。
  private var glassProgress: CGFloat {
    guard followsScroll else { return style == .glass ? 1 : 0 }
    switch style {
    case .glass: return 1
    case .transparent: return WDScrollLink.ramp(scrollOffsetY: scrollOffsetY, start: 0, end: 1)
    }
  }

  private var largeRowHeight: CGFloat {
    Self.scrollLinkedLargeTitleRowHeight(progress: progress)
  }

  /// 大标题行"向上吸"的位移：走完进度时正好顶到内联行顶部（= 内联行高度）。
  private var largeTitleCollapseOffset: CGFloat {
    Self.largeTitleCollapseOffset(progress: progress, topRowHeight: topRowHeight)
  }

  private var barHeight: CGFloat {
    Self.barHeight(mode: mode, scrollOffsetY: scrollOffsetY, followsScroll: followsScroll)
  }

  // MARK: - 视觉

  /// 底色：不联动时直接取 `style` 对应的那一层（像素与 B 之前一致）；联动时两层按进度交叉淡化，
  /// 时长走 `WDMotion.Duration.base`（240ms，设计 33 §5/§9）。
  @ViewBuilder private var barBackground: some View {
    if isScrollLinked {
      ZStack {
        switch style {
        case .transparent:
          Color.clear
          glassFill.opacity(glassProgress)
        case .glass:
          glassFill
        }
      }
      .animation(.linear(duration: WDMotion.Duration.base), value: glassProgress)
    } else {
      switch style {
      case .transparent: Color.clear
      case .glass: glassFill
      }
    }
  }

  /// 玻璃层：`WDGlass.resolve` 口径与 `.glass` 档完全一致（设计 33 §4，计入效果预算）。
  private var glassFill: Color {
    switch WDGlass.resolve(
      textLevel: .primary,
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

  @ViewBuilder private var bottomHairline: some View {
    if style == .glass {
      Rectangle()
        .fill(colors.borderHairline)
        .frame(height: 1)
    } else if isScrollLinked {
      // 玻璃底出现时才带底部 hairline，并随同一进度淡入（设计 33 §4/§5）。
      Rectangle()
        .fill(colors.borderHairline)
        .frame(height: 1)
        .opacity(glassProgress)
    }
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  private var topRowHeight: CGFloat {
    switch mode {
    case .inline, .largeTitle: return WDSize.navbarCompact
    case .standard: return WDSize.navbarStandard
    }
  }

  /// 右侧动作上限 2（设计 33 §6）。
  private static let maxActions = 2  // wd-structure-check:disable R7 — 设计
  /// 大标题行高 52（设计 33 §3：96 = 44 + 52）。
  private static let largeTitleRowHeight: CGFloat = 52  // wd-structure-check:disable R7 — 设计值
  /// 标题水平留白，避免与返回/动作重叠（设计 33 §6）。
  private static let titleHorizontalInset: CGFloat = 48  // wd-structure-check:disable R7 — 设计

  // MARK: - B15 滚动联动注入值（设计 33 §3/§5/§9）

  /// 大标题区高度 52（设计 33 §3：96 = 内联 44 + 大标题区 52）。
  static let largeTitleRowHeightFull: CGFloat = 52  // wd-structure-check:disable R7 — 设计 33 §3
  /// 折叠走完所需滚动距离 = 52（设计 33 §3/§9「0…52pt 进度」）。
  private static let collapseDistance: CGFloat = 52  // wd-structure-check:disable R7 — 设计 33 §3
  /// 判定已折叠的进度阈值 0.98（与 1 的间隙不足半像素；用于读屏去重）。
  private static let foldedThreshold: CGFloat = 0.98  // wd-structure-check:disable R7 — 读屏去重阈值
}

/// 折叠到 0 时保住大标题行内容高度的容器修饰：展开态原样返回（不介入布局）。
private struct WDNavCollapsedRowKeepSize: ViewModifier {
  let active: Bool

  @ViewBuilder func body(content: Content) -> some View {
    if active {
      content
        .fixedSize(horizontal: true, vertical: false)
        .clipped()
    } else {
      content
    }
  }
}

/// 大标题行的尺寸策略：不联动时保持 `minHeight` 的"只增不裁"口径（U7/F13，像素与 B15 之前一致）；
/// 联动时改用定高——`minHeight` 只是下限，压不到 0，整栏就收不到内联高度（44）。
private struct WDNavLargeTitleRowSizing: ViewModifier {
  let isScrollLinked: Bool
  let height: CGFloat

  @ViewBuilder func body(content: Content) -> some View {
    if isScrollLinked {
      content.frame(height: height, alignment: .leading)
    } else {
      content.frame(minHeight: height, alignment: .leading)
    }
  }
}

/// 折叠后让大标题对读屏"不可见但仍占位"：`.accessibilityHidden` 会把节点移出可访问树，
/// 与"视觉上仍在、只是缩小"不一致；`.invisible` 只切特质，标签文字仍可被读到。
private struct WDNavTitleAccessibilityInvisible: ViewModifier {
  let isInvisible: Bool

  @ViewBuilder func body(content: Content) -> some View {
    if isInvisible {
      content.accessibilityHidden(true)
    } else {
      content
    }
  }
}
