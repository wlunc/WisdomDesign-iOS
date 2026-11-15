import SwiftUI

/// 图标按钮的外观档位（设计 02 §4：filled / tonal / glass / outline / plain）。
///
/// F-20：新增 case 属源级 breaking（穷尽 switch 需补分支），见 CHANGELOG 的 Breaking 段。
public enum WDIconButtonVariant: String, CaseIterable, Sendable, Equatable {
  /// 行内动作：透明底 + text.brand 图标。
  case plain
  /// 强调动作：品牌实底 + 白/深色自适应图标（对比度优先，偏离设计 02 的 gradient.mid）。
  case filled
  /// 次级动作：surface.tint 底 + text.on-soft 图标。
  case tonal
  /// 浮层上：surface.glass-strong 底 + hairline 描边 + text.primary 图标。
  case glass
  /// 中性动作：透明底 + hairline-strong 描边 + text.primary 图标。
  case outline
}

/// 图标按钮的容器形态（设计 01-basic §02 §3：`radius.full` 或 `radius.sm`）。
///
/// F-20：新增 case 属源级 breaking（穷尽 switch 需补分支）。
public enum WDIconButtonShape: String, CaseIterable, Sendable, Equatable {
  /// 圆形：`radius.full`（默认；与既有 init 的行为一致）。
  case circle
  /// 圆角方形：`radius.sm`（设计 02 §3 的备选形态）。
  case roundedSquare
}

/// 图标按钮（SPEC §2.10-#02；M2；B4 扩五变体）。
///
/// 设计口径（设计 02）：sm 视觉 32、md 视觉 44、lg 52，**热区恒 44×44**；图标按档取；
/// 图标本身为装饰，**语义完全由调用方给的无障碍标签提供**。按下缩放 0.97、禁用 40%。
///
/// 对比度优先（DF-04 图形 3:1）：filled 用 text.brand 实底 + 浅色白 / 深色 text.on-light-primary
/// （设计 02 的 gradient.mid + 白在浅端仅 2.51:1，不达 3:1）。
///
/// 形态（设计 02 §3）：`circle`（`radius.full`，默认）与 `roundedSquare`（`radius.sm`）。
///
/// 仍未表达：聚焦光环、长按提示。
public struct WDIconButton: View {
  private let icon: WDIconName
  private let accessibilityLabel: Text
  private let variant: WDIconButtonVariant
  private let size: WDButtonSize
  private let shape: WDIconButtonShape
  private let isLoading: Bool
  private let action: () -> Void

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.colorScheme) private var colorScheme

  /// 构造（accessibilityLabel 必填；库内零文案）；形态固定 `circle`，与既有行为一致。
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,
    variant: WDIconButtonVariant = .plain,
    size: WDButtonSize = .md,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) {
    self.init(
      icon: icon,
      accessibilityLabel: accessibilityLabel,
      variant: variant,
      size: size,
      shape: .circle,
      isLoading: isLoading,
      action: action
    )
  }

  /// 构造（accessibilityLabel 与 shape 必填；库内零文案）。
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,
    variant: WDIconButtonVariant = .plain,
    size: WDButtonSize = .md,
    shape: WDIconButtonShape,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) {
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.variant = variant
    self.size = size
    self.shape = shape
    self.isLoading = isLoading
    self.action = action
  }

  /// 容器 + 图标；视觉尺寸内画底/描边，外层补 44 热区。
  public var body: some View {
    Button {
      guard !isLoading, isEnabled else { return }
      WDHaptics.shared.play(.press, budget: budget)
      action()
    } label: {
      ZStack {
        if isLoading {
          ProgressView().controlSize(.small)
        } else {
          WDIcon(icon: icon, size: Self.iconSize(for: size))
            .foregroundStyle(iconColor)
        }
      }
      .frame(width: Self.visualSize(for: size), height: Self.visualSize(for: size))
      .background { backgroundShape }
      .overlay { borderShape }
      .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
      .contentShape(containerShape)
    }
    .buttonStyle(WDIconButtonPressStyle())
    .accessibilityLabel(accessibilityLabel)
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  // MARK: - 变体配色（内部；单测直接核对对比度）

  private var iconColor: Color {
    Self.iconColor(for: variant, colors: colors, scheme: colorScheme)
  }

  static func iconColor(
    for variant: WDIconButtonVariant, colors: WDColorValues, scheme: ColorScheme
  ) -> Color {
    switch variant {
    case .plain: return colors.textBrand
    case .filled:
      return scheme == .dark ? colors.textOnLightPrimary : colors.textOnDark
    case .tonal: return colors.textOnSoft
    case .glass, .outline: return colors.textPrimary
    }
  }

  /// 背景色；plain / outline 透明（返回 nil）。
  static func backgroundColor(
    for variant: WDIconButtonVariant, colors: WDColorValues
  ) -> Color? {
    switch variant {
    case .plain, .outline: return nil
    case .filled: return colors.textBrand
    case .tonal: return colors.surfaceTint
    case .glass: return colors.surfaceGlassStrong
    }
  }

  /// 容器形状；背景、描边与热区形状共用（设计 02 §3 的两种圆角口径）。
  private var containerShape: some InsettableShape {
    WDIconButtonContainerShape(kind: shape)
  }

  @ViewBuilder private var backgroundShape: some View {
    switch variant {
    case .plain, .outline:
      Color.clear
    case .filled:
      containerShape.fill(colors.textBrand)
    case .tonal:
      containerShape.fill(colors.surfaceTint)
    case .glass:
      containerShape.fill(colors.surfaceGlassStrong)
    }
  }

  @ViewBuilder private var borderShape: some View {
    switch variant {
    case .glass:
      containerShape.strokeBorder(colors.borderHairline, lineWidth: 1)
    case .outline:
      containerShape.strokeBorder(colors.borderHairlineStrong, lineWidth: 1)
    case .plain, .filled, .tonal:
      EmptyView()
    }
  }

  /// 档位 → 视觉尺寸（设计 02 §3；lg 在设计里没有图标按钮档，按按钮档补 52）。
  static func visualSize(for size: WDButtonSize) -> CGFloat {
    switch size {
    case .sm: return WDSize.controlSm
    case .md: return WDSize.controlMd
    case .lg: return WDSize.controlLg
    }
  }

  /// 档位 → 图标档（设计 02：sm 16–20、md 24）。
  static func iconSize(for size: WDButtonSize) -> WDIconSize {
    switch size {
    case .sm: return .sm
    case .md: return .lg
    case .lg: return .xl
    }
  }

  /// 禁用态整体 40%（WDState.disabledAlpha = 40）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 百分数换算分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 图标按钮容器形状；`strokeBorder` 需要可内缩，故实现 `InsettableShape`。
private struct WDIconButtonContainerShape: InsettableShape {
  let kind: WDIconButtonShape
  var insetAmount: CGFloat = 0

  func path(in rect: CGRect) -> Path {
    switch kind {
    case .circle:
      return Circle().inset(by: insetAmount).path(in: rect)
    case .roundedSquare:
      return RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
        .inset(by: insetAmount).path(in: rect)
    }
  }

  func inset(by amount: CGFloat) -> Self {
    var copy = self
    copy.insetAmount += amount
    return copy
  }
}

/// 按下缩放 0.97（设计 02 §5 / 09 §9 的 instant）。
private struct WDIconButtonPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
