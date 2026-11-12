import SwiftUI

/// 页面级提示变体（C-15/U2：3 个；设计 29 §4 的 success 不在本端冻结面内）。
public enum WDBannerVariant: String, CaseIterable, Sendable, Equatable {
  case info
  case warning
  case danger
}

/// 提示上的操作（最多一个）。
public struct WDBannerAction {
  /// 文案（调用方给）。
  public let label: Text
  /// 点击动作。
  public let action: () -> Void

  /// 构造。
  public init(label: Text, action: @escaping () -> Void) {
    self.label = label
    self.action = action
  }
}

/// 常驻页面提示（SPEC §2.10-#29；设计 29）。
///
/// 软底渐变而非玻璃；最多 2 行文案；可选的文字操作与关闭键（关闭键需要调用方给无障碍标签）。
/// 可见性由调用方的 isVisible 持有；库不记忆「本次会话不再出现」。
public struct WDBanner: View {
  @Binding private var isVisible: Bool
  private let variant: WDBannerVariant
  private let message: Text
  private let action: WDBannerAction?
  private let dismissAccessibilityLabel: Text?

  @Environment(\.wdColors) private var colors

  /// 构造。
  public init(
    isVisible: Binding<Bool>,
    variant: WDBannerVariant = .info,
    message: Text,
    action: WDBannerAction? = nil,
    dismissAccessibilityLabel: Text? = nil
  ) {
    self._isVisible = isVisible
    self.variant = variant
    self.message = message
    self.action = action
    self.dismissAccessibilityLabel = dismissAccessibilityLabel
  }

  /// 渲染（不可见时不占位）。
  @ViewBuilder public var body: some View {
    if isVisible {
      banner
    }
  }

  private var banner: some View {
    HStack(alignment: .center, spacing: WDSpacing.s3) {
      WDIcon(icon: icon, size: .md)
        .foregroundStyle(accent)
        .accessibilityHidden(true)
      message
        .wdFont(WDType.footnote)
        .foregroundStyle(colors.textPrimary)
        .fontWeight(variant == .danger ? .semibold : .regular)
        .lineLimit(2)
        .wdLineBox(WDType.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let action {
        WDButton(variant: .plain, size: .sm, action: action.action, label: { action.label })
      }
      if let dismissAccessibilityLabel {
        WDIconButton(icon: .close, accessibilityLabel: dismissAccessibilityLabel, size: .sm) {
          isVisible = false
        }
      }
    }
    .padding(WDSpacing.s4)
    .frame(minHeight: WDSize.touchTargetMin)
    .background(background)
    .clipShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
    .accessibilityElement(children: .contain)
  }

  private var background: some ShapeStyle {
    LinearGradient(
      colors: [soft, soft.opacity(0.68)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var soft: Color {
    switch variant {
    case .info: return colors.statusSoftInfo
    case .warning: return colors.statusSoftWarning
    case .danger: return colors.statusSoftDanger
    }
  }

  private var accent: Color {
    switch variant {
    case .info: return colors.statusInfo
    case .warning: return colors.statusWarning
    case .danger: return colors.statusDanger
    }
  }

  private var icon: WDIconName {
    switch variant {
    case .info: return .inProgress
    case .warning: return .overdue
    case .danger: return .offline
    }
  }
}
