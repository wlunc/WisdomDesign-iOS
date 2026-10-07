import SwiftUI

/// 图标尺寸档（SPEC §2.10-#20；四档来自设计仓 `08-icons.md` §2 的阶梯 16/20/24/28）。
public enum WDIconSize: String, CaseIterable, Sendable, Hashable {
  case sm
  case md
  case lg
  case xl
}

/// 图标档 → 平台量的**手写映射**（与 `WDTypographyMapping` 同构：生成物给值、本层给平台语义）。
///
/// 为什么需要这一层：设计给的是"阶梯 + 线宽"（16/20/24/28 / 1.6–2.2），
/// 而 SF Symbols 没有 stroke width 旋钮，对应物 = **pointSize + 符号 weight/scale**。
/// 把映射收在一处，组件只喊档位，测试钉住"本层不得偏离令牌"。
enum WDIconMetrics {
  /// 档位对应的点径（**必须逐档等于令牌** `WDSize.icon*`；测试钉住）。
  static func pointSize(for size: WDIconSize) -> CGFloat {
    switch size {
    case .sm: WDSize.iconSm
    case .md: WDSize.iconMd
    case .lg: WDSize.iconLg
    case .xl: WDSize.iconXl
    }
  }

  /// 档位对应的字体（供 `Image(systemName:)` 取尺寸；**不随动态字体放大**——设计：图标尺寸锁死）。
  static func font(for size: WDIconSize) -> Font {
    .system(size: pointSize(for: size), weight: weight(for: size))
  }

  /// 线宽 → SF Symbols 的 weight 近似（设计：放大图标时线宽同步加粗 1.6/1.8/2/2.2）。
  static func weight(for size: WDIconSize) -> Font.Weight {
    switch size {
    case .sm: .regular
    case .md: .regular
    case .lg: .medium
    case .xl: .medium
    }
  }
}
