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
}
