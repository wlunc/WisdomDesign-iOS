import SwiftUI

/// 字阶 → 系统 `Font.TextStyle` 的映射（手写层，**不进令牌**；SPEC §2.1 / §2.6.3）。
///
/// 匹配的是**整条字阶**（尺寸 + 行高 + 字重 + 字距），不是字号 —— `headline` 与 `body`
/// 同为 17pt，只有字重不同。
public enum WDTypographyMapping {
  /// 12 条映射：largeTitle→.largeTitle、title1→.title、title2→.title2、title3→.title3、headline→.headline、
  /// body→.body、callout→.callout、subheadline→.subheadline、footnote→.footnote、caption1→.caption、
  /// caption2→.caption2、overline→.caption。
  ///
  /// - Note: 调用方**自造**的字阶（不在 `WDType` 的 12 条里）回退 `.body`：
  ///   它只用于 `UIFontMetrics` 的缩放基准，不改变该字阶自己的字号/行高。
  public static func textStyle(for style: WDTextStyle) -> Font.TextStyle {
    switch style {
    case WDType.largeTitle: return .largeTitle
    case WDType.title1: return .title
    case WDType.title2: return .title2
    case WDType.title3: return .title3
    case WDType.headline: return .headline
    case WDType.body: return .body
    case WDType.callout: return .callout
    case WDType.subheadline: return .subheadline
    case WDType.footnote: return .footnote
    case WDType.caption1: return .caption
    case WDType.caption2: return .caption2
    case WDType.overline: return .caption
    default: return .body
    }
  }
}

extension WDTextStyle {
  /// 该字阶对应的系统 `Font.TextStyle`（映射表见 `WDTypographyMapping`）。
  public var textStyle: Font.TextStyle {
    WDTypographyMapping.textStyle(for: self)
  }
}
