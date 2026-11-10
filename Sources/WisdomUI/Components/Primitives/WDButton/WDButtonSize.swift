import SwiftUI

/// 控件尺寸档（SPEC §2.2；`WDButton` 与 `WDIconButton` 共用）。
public enum WDButtonSize: String, CaseIterable, Sendable, Equatable {
  /// 小（高 32）。
  case sm
  /// 中（默认，高 44）。
  case md
  /// 大（高 52）。
  case lg

  /// 控件高度（令牌 `size.control.{sm,md,lg}`；仅供实现内部使用）。
  var controlHeight: CGFloat {
    switch self {
    case .sm: return WDSize.controlSm
    case .md: return WDSize.controlMd
    case .lg: return WDSize.controlLg
    }
  }

  /// 按钮水平内距（设计 01 §3：12 / 16 / 20；取间距令牌）。
  var buttonHorizontalPadding: CGFloat {
    switch self {
    case .sm: return WDSpacing.s4
    case .md: return WDSpacing.s5
    case .lg: return WDSpacing.s6
    }
  }

  /// 按钮文字档（设计 01 §3：13 / 15 / 16；16 用 body 17 近似，差异登记）。
  var buttonTextStyle: WDTextStyle {
    switch self {
    case .sm: return WDType.footnote
    case .md: return WDType.subheadline
    case .lg: return WDType.body
    }
  }

  /// 按钮的垂直热区补量：视觉高度不足 44 的档位向外补到 44（设计 01：触控热区不小于 44）。
  var buttonHitInset: CGFloat {
    max(0, (WDSize.touchTargetMin - controlHeight) / 2)
  }

  /// 按钮图标档（设计 01 §3：14 / 16 / 20；映射到令牌四档 16 / 16 / 20）。
  var buttonIconSize: WDIconSize {
    switch self {
    case .sm: return .sm
    case .md: return .sm
    case .lg: return .md
    }
  }
}
