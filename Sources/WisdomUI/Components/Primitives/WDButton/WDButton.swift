import SwiftUI

/// 按钮外观档位（SPEC §2.2）。
public enum WDButtonVariant: String, CaseIterable, Sendable, Equatable {
  /// 品牌填充：每屏最多一个主操作。
  case filled
  /// 柔色底：次级操作。
  case tonal
  /// 玻璃：浮在内容之上。
  case glass
  /// 描边：中性操作。
  case outline
  /// 纯文字：行内操作。
  case plain
  /// 破坏性动作（删除/退出）。
  case destructive
}

/// 主按钮（SPEC §2.2；M2）。
///
/// 设计口径（设计 01）：三档高度 32/44/52（`size.control.*`）、水平内距 12/16/20、胶囊圆角；
/// 六个变体；按下缩放 0.97 + 亮度 96% + 轻触觉；加载态保持容器宽度、标签留在无障碍树。
///
/// 冻结签名（8 参）不变；视觉差异（字号档、图标档、聚焦光环、玻璃模糊）登记在
/// `docs/DEV-PLAN.md` §2.3。
public struct WDButton<Label: View>: View {
  private let variant: WDButtonVariant
  private let size: WDButtonSize
  private let isLoading: Bool
  private let loadingAccessibilityText: Text?
  private let leadingIcon: WDIconName?
  private let trailingIcon: WDIconName?
  private let action: () -> Void
  private let label: Label

  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  /// 8 参构造（S2 上限；`label` 为 `@ViewBuilder`）。
  public init(
    variant: WDButtonVariant = .filled,
    size: WDButtonSize = .md,
    isLoading: Bool = false,
    loadingAccessibilityText: Text? = nil,
    leadingIcon: WDIconName? = nil,
    trailingIcon: WDIconName? = nil,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label
  ) {
    self.variant = variant
    self.size = size
    self.isLoading = isLoading
    self.loadingAccessibilityText = loadingAccessibilityText
    self.leadingIcon = leadingIcon
    self.trailingIcon = trailingIcon
    self.action = action
    self.label = label()
    #if DEBUG
      if isLoading && loadingAccessibilityText == nil {
        assertionFailure("WDButton loading requires loadingAccessibilityText")
      }
    #endif
  }

  /// 真 `Button`（pressed 的唯一来源）；加载态忽略 `action` 但不改 `isEnabled`（U6 派生②）。
  public var body: some View {
    Button {
      guard !isLoading, isEnabled else { return }
      WDHaptics.shared.play(.press, budget: budget)
      action()
    } label: {
      HStack(spacing: WDSpacing.s3) {
        if let leadingIcon {
          WDIcon(icon: leadingIcon, size: size.buttonIconSize)
        }
        label
        if let trailingIcon {
          WDIcon(icon: trailingIcon, size: size.buttonIconSize)
        }
      }
      .wdFont(size.buttonTextStyle)
      .fontWeight(.semibold)
      .lineLimit(1)
    }
    .buttonStyle(WDButtonStyle(variant: variant, size: size, isLoading: isLoading))
    .modifier(WDButtonLoadingValue(value: isLoading ? loadingAccessibilityText : nil))
  }
}

extension WDButton where Label == Text {
  /// 文案便利构造。
  public init(
    _ text: LocalizedStringKey,
    variant: WDButtonVariant = .filled,
    size: WDButtonSize = .md,
    isLoading: Bool = false,
    loadingAccessibilityText: Text? = nil,
    leadingIcon: WDIconName? = nil,
    trailingIcon: WDIconName? = nil,
    action: @escaping () -> Void
  ) {
    self.init(
      variant: variant,
      size: size,
      isLoading: isLoading,
      loadingAccessibilityText: loadingAccessibilityText,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      action: action,
      label: { Text(text) }
    )
  }

  /// 字面量便利构造（参数集合同上一条构造）。
  public init(
    verbatim text: String,
    variant: WDButtonVariant = .filled,
    size: WDButtonSize = .md,
    isLoading: Bool = false,
    loadingAccessibilityText: Text? = nil,
    leadingIcon: WDIconName? = nil,
    trailingIcon: WDIconName? = nil,
    action: @escaping () -> Void
  ) {
    self.init(
      variant: variant,
      size: size,
      isLoading: isLoading,
      loadingAccessibilityText: loadingAccessibilityText,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      action: action,
      label: { Text(verbatim: text) }
    )
  }
}

/// 按钮 chrome 的 `ButtonStyle`（SPEC §2.2；同时对外暴露给自定义按钮）。
public struct WDButtonStyle: ButtonStyle {
  private let variant: WDButtonVariant
  private let size: WDButtonSize
  private let isLoading: Bool

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造（档位 + 加载态）。
  public init(
    variant: WDButtonVariant = .filled, size: WDButtonSize = .md, isLoading: Bool = false
  ) {
    self.variant = variant
    self.size = size
    self.isLoading = isLoading
  }

  /// chrome：底/描边/阴影 + 按下缩放与亮度 + 加载指示器。
  public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
    let chrome = configuration.label
      .opacity(isLoading ? 0 : 1)
      .padding(.horizontal, size.buttonHorizontalPadding)
      .frame(minHeight: size.controlHeight)
      .foregroundStyle(foregroundColor)
      .background(background)
      .clipShape(Capsule())
      .overlay(border)
      .modifier(WDButtonShadow(variant: variant, isEnabled: isEnabled))
      .overlay { loadingIndicator }
      .opacity(isEnabled ? 1 : disabledOpacity)
      .scaleEffect(configuration.isPressed ? Self.pressedScale : 1)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
      .animation(.linear(duration: WDMotion.Duration.fast), value: isLoading)
      .padding(.vertical, size.buttonHitInset)

    if variant == .glass, #available(iOS 26.0, *) {
      chrome.glassEffect(.regular, in: Capsule())
    } else {
      chrome
    }
  }

  // MARK: - 变体视觉

  private var foregroundColor: Color {
    switch variant {
    case .filled: return colors.textOnFill
    case .tonal: return colors.textOnSoft
    case .glass, .outline: return colors.textPrimary
    case .plain: return colors.textBrand
    case .destructive: return colors.textOnDark
    }
  }

  @ViewBuilder private var background: some View {
    switch variant {
    case .filled:
      Capsule().fill(WDGradient.fill.linearGradient)
    case .destructive:
      Capsule().fill(WDGradient.destructive.linearGradient)
    case .tonal:
      Capsule().fill(colors.surfaceTint)
    case .glass:
      Capsule().fill(glassFill)
    case .outline, .plain:
      Capsule().fill(Color.clear)
    }
  }

  @ViewBuilder private var border: some View {
    if variant == .outline {
      Capsule().stroke(colors.borderHairlineStrong, lineWidth: 1)
    } else if variant == .glass {
      Capsule().stroke(colors.borderHairline, lineWidth: 1)
    }
  }

  /// 玻璃的纯色降级（`WDGlass.resolve` 唯一入口；iOS 17–25 / 预算不足 ⇒ 实底）。
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

  @ViewBuilder private var loadingIndicator: some View {
    if isLoading {
      ProgressView()
        .controlSize(.small)
        .tint(variant == .filled || variant == .destructive ? colors.textOnDark : foregroundColor)
    }
  }

  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  /// 按下缩放（设计 01：`motion.component.press-scale` = 0.97；令牌无此值）。
  private static let pressedScale: CGFloat = 0.97  // wd-structure-check:disable R7 — 设计值
  /// 禁用态整体不透明度（`state.disabled.alpha` = 40）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母
}

/// 阴影：填充/破坏性用 `elevation.brand`、玻璃用 `e1`；禁用态去掉阴影。
private struct WDButtonShadow: ViewModifier {
  let variant: WDButtonVariant
  let isEnabled: Bool

  @ViewBuilder func body(content: Content) -> some View {
    if isEnabled {
      switch variant {
      case .filled, .destructive:
        content.wdShadow(WDElevation.brand)
      case .glass:
        content.wdShadow(WDElevation.e1)
      case .tonal, .outline, .plain:
        content
      }
    } else {
      content
    }
  }
}

/// 加载态读屏值（F37：读"提交，处理中"；库内不拼文案，调用方给"处理中"）。
private struct WDButtonLoadingValue: ViewModifier {
  let value: Text?

  @ViewBuilder func body(content: Content) -> some View {
    if let value {
      content.accessibilityValue(value)
    } else {
      content
    }
  }
}

extension ButtonStyle where Self == WDButtonStyle {
  /// 填充档工厂（R13b 允许：协议扩展里的计算型工厂）。
  public static var wdFilled: WDButtonStyle {
    WDButtonStyle()
  }

  /// 指定档位的工厂。
  public static func wd(_ variant: WDButtonVariant, size: WDButtonSize = .md) -> WDButtonStyle {
    WDButtonStyle(variant: variant, size: size)
  }
}
