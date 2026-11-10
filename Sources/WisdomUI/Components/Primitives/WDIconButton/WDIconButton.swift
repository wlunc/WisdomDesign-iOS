import SwiftUI

/// 图标按钮的外观档位（冻结表单 §5.1-①：只钉 `.plain`；其余档等设计依据）。
public enum WDIconButtonVariant: String, CaseIterable, Sendable, Equatable {
  /// 行内动作：透明底 + `text.brand` 图标。
  case plain
}

/// 图标按钮（SPEC §2.10-#02；M2）。
///
/// 设计口径（设计 02）：`sm` 视觉 32、`md` 视觉 44，**热区恒 44×44**；图标按档取
/// （`md` = `size.icon.lg` 24）；图标本身为装饰，**语义完全由调用方给的无障碍标签提供**。
///
/// 冻结签名只有 `.plain` 档（且 `size` 复用 `WDButtonSize`）⇒ 其余四个变体与加载态的设计口径
/// 不可表达/未对标，差异登记在 `docs/DEV-PLAN.md` §2.3。
public struct WDIconButton: View {
  private let icon: WDIconName
  private let accessibilityLabel: Text
  private let variant: WDIconButtonVariant
  private let size: WDButtonSize
  private let isLoading: Bool
  private let action: () -> Void

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled

  /// 构造（`accessibilityLabel` 必填；库内零文案）。
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,
    variant: WDIconButtonVariant = .plain,
    size: WDButtonSize = .md,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) {
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.variant = variant
    self.size = size
    self.isLoading = isLoading
    self.action = action
  }

  /// 视觉尺寸 + 热区补到 44；加载态用指示器替换图标（宽度不变）。
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
        }
      }
      .foregroundStyle(colors.textBrand)
      .frame(width: Self.visualSize(for: size), height: Self.visualSize(for: size))
      .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel)
  }

  /// 档位 → 视觉尺寸（设计 02 §3；`lg` 在设计里没有图标按钮档，按按钮档补 52）。
  static func visualSize(for size: WDButtonSize) -> CGFloat {
    switch size {
    case .sm: return 32
    case .md: return 44
    case .lg: return 52
    }
  }

  /// 档位 → 图标档（设计 02：`sm` 16–20、`md` 24）。
  static func iconSize(for size: WDButtonSize) -> WDIconSize {
    switch size {
    case .sm: return .sm
    case .md: return .lg
    case .lg: return .xl
    }
  }
}
