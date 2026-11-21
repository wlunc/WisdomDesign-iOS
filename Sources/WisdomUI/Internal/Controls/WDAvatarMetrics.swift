import CoreGraphics

/// 头像尺寸与状态点常量（设计 12 §3/§4；Internal 层不受 R7 限制）。
enum WDAvatarMetrics {
  /// 五档直径（设计 12 §3；令牌 size.avatar.*）。
  static func diameter(_ size: WDAvatarSize) -> CGFloat {
    switch size {
    case .xs: return WDSize.avatarXs
    case .sm: return WDSize.avatarSm
    case .md: return WDSize.avatarMd
    case .lg: return WDSize.avatarLg
    case .xl: return WDSize.avatarXl
    }
  }

  /// 五档首字号（设计 12 §3：9 / 11 / 12 / 14 / 18）。
  static func initialsSize(_ size: WDAvatarSize) -> CGFloat {
    switch size {
    case .xs: return 9
    case .sm: return 11
    case .md: return 12
    case .lg: return 14
    case .xl: return 18
    }
  }

  /// 在线点 10×10（设计 12 §4）。
  static let onlineDotSize: CGFloat = 10
  /// 在线点描边 2（设计 12 §4）。
  static let onlineBorderWidth: CGFloat = 2
  /// 已停用整体 50%（设计 12 §5）。
  static let disabledOpacity: CGFloat = 0.5
  /// 照片形态描边 2pt（设计 14 §1.4；令牌 size.avatar.ring）。
  static let photoRingWidth: CGFloat = WDSize.avatarRing
  /// 照片加载完成淡入 160ms（设计 14 §1.4 / 设计 12 §9；令牌 motion.duration.fast）。
  static let photoFadeDuration: Double = WDMotion.Duration.fast
}
