import SwiftUI

/// FAB 尺寸档（设计 36 §3：标准 56 / 大 64 / 小 40）。
public enum WDFABSize: String, CaseIterable, Sendable, Equatable {
  /// 40×40。
  case small
  /// 56×56（默认）。
  case standard
  /// 64×64。
  case large
}

/// FAB 形状（设计 36 §4：圆角方 / 圆形）。
public enum WDFABShape: String, CaseIterable, Sendable, Equatable {
  /// 圆角方（默认；与卡片体系协调）。
  case roundedSquare
  /// 圆形。
  case circle
}

/// FAB 子操作（展开态；图标 + 文字）。
public struct WDFABAction: Identifiable {
  /// 稳定身份。
  public let id: String
  /// 图标语义名。
  public let icon: WDIconName
  /// 文字（展开态子操作必须带文字）。
  public let label: Text
  /// 动作。
  public let action: () -> Void

  /// 构造：身份 + 图标 + 文字 + 动作。
  public init(id: String, icon: WDIconName, label: Text, action: @escaping () -> Void) {
    self.id = id
    self.icon = icon
    self.label = label
    self.action = action
  }
}

/// 悬浮主操作（SPEC §2.10-#36；M5）。
///
/// 设计口径（设计 36）：
/// - 标准 56×56 / 大 64×64 / 小 40×40；圆角 `radius.fab` 19 / 22 / 14，或圆形；
/// - `gradient.fill` + `elevation.brand`；按下缩放 0.95；禁用 40%；
/// - 可展开：点击展开 2–4 个子操作（图标 + 文字，向上排列、间距 8），主图标旋转 45°；
/// - 小号 40 的触控热区补到 ≥44；一个页面最多一个 FAB（调用方保证）。
///
/// B15 增量（设计 36 §5/§6/§8）：
/// - **展开遮罩**（`showsScrimWhenExpanded`）：展开时在 FAB 同层铺遮罩，点它只收起
///   （不触发主操作）；遮罩层本身 `accessibilityHidden`，读屏用 `escape` 动作收起
///   （双指画 Z）。收起依赖命中测试，不另加手势。
/// - **TabBar 避让**（`avoidsTabBar`）：底部留白 18 → 92（设计 36 §6：Tab 栏高 58 + 间距 8 + 留白），
///   不动安全区（F36：安全区由调用方装）。
/// - **滚动联动**：只读 `wdScrollOffsetY`（nil = 不联动，默认路径像素不变）。向下滚动缩到 40 并降低
///   不透明度（`spring.gentle`），向上/回顶立即恢复，**从不隐藏**（设计 36 §8）。
/// - 读屏焦点移入第一个子操作、与 Tab 栏的层级关系仍由调用方保证（见 `docs/M5-EXIT-REPORT.md`）。
public struct WDFAB: View {
  private let icon: WDIconName
  private let accessibilityLabel: Text
  private let size: WDFABSize
  private let shape: WDFABShape
  private let actions: [WDFABAction]
  private let action: (() -> Void)?
  private let showsScrimWhenExpanded: Bool
  private let avoidsTabBar: Bool

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget
  /// 滚动 offset（B15 接线件；nil = 不联动）。
  @Environment(\.wdScrollOffsetY) private var scrollOffsetY

  @State private var isExpanded = false
  /// 展开时把读屏焦点移到第一个子操作（设计 36 §10）。
  @AccessibilityFocusState private var focusedActionID: String?
  /// 收起后把读屏焦点还给主按钮（B17；子操作随收起移出可访问树，否则焦点会掉到页面顶部）。
  @AccessibilityFocusState private var isMainFocused: Bool

  /// 构造：主图标 + 读屏标签 + 尺寸/形状 + 子操作/主操作 + 展开遮罩/TabBar 避让。
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,
    size: WDFABSize = .standard,
    shape: WDFABShape = .roundedSquare,
    actions: [WDFABAction] = [],
    action: (() -> Void)? = nil,
    showsScrimWhenExpanded: Bool = false,
    avoidsTabBar: Bool = false
  ) {
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.size = size
    self.shape = shape
    self.actions = actions
    self.action = action
    self.showsScrimWhenExpanded = showsScrimWhenExpanded
    self.avoidsTabBar = avoidsTabBar
  }

  /// 子操作（展开时）+ 主按钮（+ 可选遮罩层）。
  public var body: some View {
    fabStack
      .opacity((isEnabled ? 1 : disabledOpacity) * scrollOpacity)
      .padding(.bottom, bottomInset)
      // 遮罩与 FAB 同层：子视图（子操作 + 主按钮）命中区在上，遮罩只吃剩下的空白处；
      // 放大的留白让遮罩盖住 FAB 到 Tab 栏那一带，点它同样收起。
      .background(alignment: .center) {
        if isExpanded, showsScrimWhenExpanded {
          expandedScrim
        }
      }
      // 读屏：展开后 escape（双指画 Z）等价于点遮罩收起（不执行主操作）。
      // 收起态下回调内的 `isExpanded` 为 false，重复触发不会有任何副作用。
      .accessibilityAction(.escape) {
        if isExpanded, showsScrimWhenExpanded, !actions.isEmpty {
          collapseWithoutAction()
        }
      }
      // 滚动缩放/降透明度用 spring.gentle（设计 36 §5）；带 value ⇒ 只在联动量变化时动。
      .animation(Self.scrollAnimation, value: scrollScale)
      .animation(Self.scrollAnimation, value: scrollOpacity)
      .onAppear {
        assert(actions.count <= Self.maxActions, "WDFAB 展开态最多 4 个子操作（设计 36 §7）")
      }
  }

  private var fabStack: some View {
    VStack(alignment: .trailing, spacing: WDSpacing.s3) {
      if isExpanded {
        ForEach(actions) { child in
          childButton(child)
        }
      }
      mainButton
        // B15 滚动联动：缩小但不隐藏（设计 36 §5/§8）。
        .scaleEffect(scrollScale)
    }
  }

  // MARK: - 展开遮罩（B15）

  /// 展开态遮罩：40% 黑（与 Alert 同口径），只收起、不触发主操作，读屏不可见。
  private var expandedScrim: some View {
    Color.black.opacity(Self.scrimOpacity)
      .accessibilityHidden(true)
      .contentShape(Rectangle())
      .onTapGesture { collapseWithoutAction() }
      .transition(.opacity.animation(.easeOut(duration: WDMotion.Duration.base)))
  }

  /// 收起（点遮罩 / escape）：不发触觉、不调用任何 action。
  private func collapseWithoutAction() {
    guard isExpanded else { return }
    withAnimation(WDMotion.Spring.gentle) {
      isExpanded = false
    }
    focusedActionID = nil
    returnAccessibilityFocusToMain()
  }

  /// 收起后把读屏焦点还给主按钮（等一帧让子操作先离开可访问树）。
  private func returnAccessibilityFocusToMain() {
    Task { @MainActor in
      await Task.yield()
      isMainFocused = true
    }
  }

  // MARK: - 主按钮

  private var mainButton: some View {
    Button {
      guard isEnabled else { return }
      WDHaptics.shared.play(.press, budget: budget)
      if actions.isEmpty {
        action?()
      } else {
        withAnimation(WDMotion.Spring.gentle) {
          isExpanded.toggle()
        }
        if isExpanded {
          Task { @MainActor in
            await Task.yield()
            focusedActionID = actions.first?.id
          }
        } else {
          focusedActionID = nil
          returnAccessibilityFocusToMain()
        }
      }
    } label: {
      ZStack {
        mainShape
          .fill(WDGradient.fill.linearGradient)
          .wdShadow(WDElevation.brand)
        WDIcon(icon: icon, size: iconSize)
          .foregroundStyle(colors.textOnDark)
          .rotationEffect(.degrees(isExpanded ? Self.expandedRotation : 0))
      }
      .frame(
        width: max(diameter, WDSize.touchTargetMin),
        height: max(diameter, WDSize.touchTargetMin)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(WDFABPressStyle())
    .accessibilityLabel(accessibilityLabel)
    .wdAccessibilityFocused($isMainFocused)
  }

  private var mainShape: AnyShape {
    switch shape {
    case .circle:
      return AnyShape(Circle())
    case .roundedSquare:
      return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
  }

  // MARK: - 子操作

  private func childButton(_ child: WDFABAction) -> some View {
    Button {
      guard isEnabled else { return }
      child.action()
      withAnimation(WDMotion.Spring.gentle) {
        isExpanded = false
      }
      focusedActionID = nil
      returnAccessibilityFocusToMain()
    } label: {
      HStack(spacing: WDSpacing.s2) {
        WDIcon(icon: child.icon, size: .sm)
          .foregroundStyle(colors.textPrimary)
        child.label
          .wdFont(WDType.subheadline)
          .wdLineBox(WDType.subheadline)
          .foregroundStyle(colors.textPrimary)
          .lineLimit(1)
      }
      .padding(.horizontal, WDSpacing.s4)
      .frame(minHeight: WDSize.touchTargetMin)
      .background(
        Capsule()
          .fill(colors.surfaceGlassStrong)
          .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
          .wdShadow(WDElevation.e1)
      )
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .wdAccessibilityFocused($focusedActionID, equals: child.id)
  }

  // MARK: - 滚动联动（B15，纯函数便于单测）

  /// 滚动后的视觉尺寸：向下滚动从圆钮直径缩到 40（设计 36 §5），向上/回顶立即恢复。
  ///
  /// 不联动（`scrollOffsetY == nil`）⇒ 原直径；小号本来 ≤ 40 ⇒ 恒为 40（不额外缩小）。
  static func scrollDiameter(
    baseDiameter: CGFloat,
    scrollOffsetY: CGFloat?,
    distance: CGFloat
  ) -> CGFloat {
    guard scrollOffsetY != nil else { return baseDiameter }
    let full = max(baseDiameter, collapsedDiameter)
    return WDScrollLink.interpolate(
      scrollOffsetY: scrollOffsetY,
      start: 0,
      end: distance,
      from: full,
      to: min(baseDiameter, collapsedDiameter)
    )
  }

  /// 滚动后的不透明度：1 → 0.88（设计只说"降低不透明度"，幅度取可辨识又可点的保守值）。
  static func scrollOpacity(scrollOffsetY: CGFloat?, distance: CGFloat) -> CGFloat {
    WDScrollLink.interpolate(
      scrollOffsetY: scrollOffsetY,
      start: 0,
      end: distance,
      from: 1,
      to: scrolledOpacity
    )
  }

  /// 底部留白：18；避让 Tab 栏时 92（设计 36 §6）。**改的是留白，不是安全区**（F36）。
  static func bottomInset(avoidsTabBar: Bool) -> CGFloat {
    avoidsTabBar ? tabBarAvoidanceInset : restInset
  }

  /// `.scaleEffect` 的入参（已含"不联动 = 1"）。
  private var scrollScale: CGFloat {
    guard scrollOffsetY != nil else { return 1 }
    return Self.scrollDiameter(
      baseDiameter: diameter,
      scrollOffsetY: scrollOffsetY,
      distance: Self.scrollDistance
    ) / diameter
  }

  private var scrollOpacity: CGFloat {
    Self.scrollOpacity(scrollOffsetY: scrollOffsetY, distance: Self.scrollDistance)
  }

  private var bottomInset: CGFloat {
    Self.bottomInset(avoidsTabBar: avoidsTabBar)
  }

  // MARK: - 几何

  private var diameter: CGFloat {
    switch size {
    case .small: return Self.smallDiameter
    case .standard: return Self.standardDiameter
    case .large: return Self.largeDiameter
    }
  }

  private var cornerRadius: CGFloat {
    switch size {
    case .small: return Self.smallCornerRadius
    case .standard: return WDRadius.fab
    case .large: return Self.largeCornerRadius
    }
  }

  private var iconSize: WDIconSize {
    switch size {
    case .small: return .md
    case .standard: return .lg
    case .large: return .xl
    }
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 展开态子操作上限 4（设计 36 §7）。
  private static let maxActions = 4  // wd-structure-check:disable R7 — 设计
  /// 小号直径 40（设计 36 §3）。
  private static let smallDiameter: CGFloat = 40  // wd-structure-check:disable R7 — 设计值
  /// 标准直径 56（设计 36 §3）。
  private static let standardDiameter: CGFloat = 56  // wd-structure-check:disable R7 — 设计值
  /// 大号直径 64（设计 36 §3）。
  private static let largeDiameter: CGFloat = 64  // wd-structure-check:disable R7 — 设计值
  /// 小号圆角 14（设计 36 §3）。
  private static let smallCornerRadius: CGFloat = 14  // wd-structure-check:disable R7 — 设计值
  /// 大号圆角 22（设计 36 §3）。
  private static let largeCornerRadius: CGFloat = 22  // wd-structure-check:disable R7 — 设计值
  /// 展开时图标旋转 45°（设计 36 §5）。
  private static let expandedRotation: Double = 45  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数

  // MARK: - B15 注入值（设计 36 §5/§6/§8）

  /// 滚动缩小后的直径 40（设计 36 §5「向下滚动时缩小到 40」）。
  private static let collapsedDiameter: CGFloat = 40  // wd-structure-check:disable R7 — 设计 36 §5
  /// 缩小走完所需的滚动距离：与导航栏大标题折叠距离同区间，三段滚动联动同口径。
  private static let scrollDistance: CGFloat = 52  // wd-structure-check:disable R7 — 三段滚动联动同口径
  /// 滚动后的不透明度（设计只说降低，未给值 ⇒ 取可辨识又不藏起来的档）。
  private static let scrolledOpacity: CGFloat = 0.88  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 非 Tab 栏场景的底部留白 18（设计 36 §6）。
  private static let restInset: CGFloat = 18  // wd-structure-check:disable R7 — 设计 36 §6
  /// 避让 Tab 栏时的底部留白 92（设计 36 §6）。
  private static let tabBarAvoidanceInset: CGFloat = 92  // wd-structure-check:disable R7 — 设计 36 §6
  /// 展开遮罩不透明度 40%（与 Alert 遮罩同口径）。
  private static let scrimOpacity: CGFloat = 0.4  // wd-structure-check:disable R7 — 与 Alert 遮罩同口径
  /// 滚动联动动画 = spring.gentle（设计 36 §9）。
  private static let scrollAnimation = WDMotion.Spring.gentle
}

/// 按下缩放 0.95（设计 36 §5）。
private struct WDFABPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
