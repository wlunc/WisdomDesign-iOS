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
/// 滚动时缩小 / 遮罩收起 / 焦点移入第一个子操作 / 与 TabBar 的安全区避让本轮未实现，
/// 差异登记在 `docs/M5-EXIT-REPORT.md`。
public struct WDFAB: View {
  private let icon: WDIconName
  private let accessibilityLabel: Text
  private let size: WDFABSize
  private let shape: WDFABShape
  private let actions: [WDFABAction]
  private let action: (() -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  @State private var isExpanded = false
  /// 展开时把读屏焦点移到第一个子操作（设计 36 §10）。
  @AccessibilityFocusState private var focusedActionID: String?

  /// 构造：主图标 + 读屏标签 + 尺寸/形状 + 子操作/主操作。
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,
    size: WDFABSize = .standard,
    shape: WDFABShape = .roundedSquare,
    actions: [WDFABAction] = [],
    action: (() -> Void)? = nil
  ) {
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.size = size
    self.shape = shape
    self.actions = actions
    self.action = action
  }

  /// 子操作（展开时）+ 主按钮。
  public var body: some View {
    VStack(alignment: .trailing, spacing: WDSpacing.s3) {
      if isExpanded {
        ForEach(actions) { child in
          childButton(child)
        }
      }
      mainButton
    }
    .opacity(isEnabled ? 1 : disabledOpacity)
    .onAppear {
      assert(actions.count <= Self.maxActions, "WDFAB 展开态最多 4 个子操作（设计 36 §7）")
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
    .accessibilityFocused($focusedActionID, equals: child.id)
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
}

/// 按下缩放 0.95（设计 36 §5）。
private struct WDFABPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
