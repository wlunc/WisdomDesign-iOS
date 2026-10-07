import SwiftUI
import UIKit

/// 字体度量与动态字体缩放（**唯一允许 `import UIKit` 的字体文件**；SPEC §2.6.3 / §3.6，R14）。
///
/// 口径（SPEC §3.6）：
///   · 用 `dynamicTypeSize` + `UIFontMetrics` **逐 style 直算**（不用 `@ScaledMetric`，
///     后者只作对照测试）；
///   · **库不设默认上限**，允许调用方自己封顶；
///   · `natural` = **缩放后字体**的 `lineHeight`（先 `scaledFont(for:)` 再读）。
public enum WDFontMetrics {
  /// 该字阶在该动态字体档下的 `UIFont`。
  ///
  /// **字号来源 = 系统的 preferred font**（`UIFont.preferredFont(forTextStyle:compatibleWith:)`），
  /// **不是**"拿设计字号再 `UIFontMetrics.scaledFont` 手算" —— 两者不相等（实测 AX3：body 手算 37pt
  /// vs 系统 40pt、callout 35 vs 38、title1 47 vs 48），系统对每个 text style 有各自的放大曲线；
  /// 手算会让放大档整体偏小 2–3pt（M1 首版即如此，被 `WDFontMetricsTests` 抓到）。
  /// **字重仍取设计值**（系统 headline 默认 semibold、caption2 默认 regular，而设计要 medium）。
  public static func uiFont(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> UIFont {
    let traits = UITraitCollection(
      preferredContentSizeCategory: category(for: dynamicTypeSize)
    )
    let system = UIFont.preferredFont(
      forTextStyle: uiTextStyle(WDTypographyMapping.textStyle(for: style)),
      compatibleWith: traits
    )
    return UIFont.systemFont(ofSize: system.pointSize, weight: uiWeight(style.weight))
  }

  /// 缩放后的字号（pt）。
  public static func scaledSize(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat
  {
    uiFont(for: style, dynamicTypeSize: dynamicTypeSize).pointSize
  }

  /// 缩放后**主字体**的自然行高（pt）—— 公式里的 `natural`。
  ///
  /// 拉丁侧 = SF Pro 的自然行高；**CJK 的回退字体更高**（PingFang SC ≈ 1.400em），
  /// 那一部分由 `wdLineBox` 的 `minHeight`（不裁切）兜住，不在本函数里假装知道脚本。
  public static func naturalLineHeight(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize)
    -> CGFloat
  {
    uiFont(for: style, dynamicTypeSize: dynamicTypeSize).lineHeight
  }

  /// 渲染行盒高（pt）= `max(设计行高 × 缩放比, natural)`（SPEC §2.6.3 的定稿公式）。
  public static func lineBoxHeight(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize)
    -> CGFloat
  {
    max(
      style.lineHeight * scaleRatio(for: style, dynamicTypeSize: dynamicTypeSize),
      naturalLineHeight(for: style, dynamicTypeSize: dynamicTypeSize)
    )
  }

  /// 多行行距（pt）= `max(0, 行盒高 − natural)`。
  /// **单行高度不由它决定**：`.lineSpacing` 走 `environment(\.lineSpacing)`，只影响行间（SPEC §2.6.3）。
  public static func lineSpacing(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize)
    -> CGFloat
  {
    max(
      0,
      lineBoxHeight(for: style, dynamicTypeSize: dynamicTypeSize)
        - naturalLineHeight(for: style, dynamicTypeSize: dynamicTypeSize)
    )
  }

  /// 缩放比 = 缩放后字号 ÷ 设计字号（设计行高按同一比例缩放）。
  public static func scaleRatio(for style: WDTextStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat
  {
    guard style.size > 0 else { return 1 }
    return scaledSize(for: style, dynamicTypeSize: dynamicTypeSize) / style.size
  }

  // MARK: - 内部映射

  /// SwiftUI 的 `Font.TextStyle` → UIKit 的 `UIFont.TextStyle`（`UIFontMetrics` 只认后者）。
  /// 注意 **`.title` ↔ `.title1`** 这一对：两端命名不同名同义。
  static func uiTextStyle(_ textStyle: Font.TextStyle) -> UIFont.TextStyle {
    switch textStyle {
    case .largeTitle: return .largeTitle
    case .title: return .title1
    case .title2: return .title2
    case .title3: return .title3
    case .headline: return .headline
    case .subheadline: return .subheadline
    case .callout: return .callout
    case .footnote: return .footnote
    case .caption: return .caption1
    case .caption2: return .caption2
    case .body: return .body
    @unknown default: return .body
    }
  }

  /// `Font.Weight` → `UIFont.Weight`（设计字阶只用到 regular/medium/semibold/bold）。
  static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
    switch weight {
    case .ultraLight: return .ultraLight
    case .thin: return .thin
    case .light: return .light
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    case .heavy: return .heavy
    case .black: return .black
    default: return .regular
    }
  }

  /// `DynamicTypeSize` → `UIContentSizeCategory`（用于按档直算，而不是读进程当前档）。
  static func category(for dynamicTypeSize: DynamicTypeSize) -> UIContentSizeCategory {
    switch dynamicTypeSize {
    case .xSmall: return .extraSmall
    case .small: return .small
    case .medium: return .medium
    case .large: return .large
    case .xLarge: return .extraLarge
    case .xxLarge: return .extraExtraLarge
    case .xxxLarge: return .extraExtraExtraLarge
    case .accessibility1: return .accessibilityMedium
    case .accessibility2: return .accessibilityLarge
    case .accessibility3: return .accessibilityExtraLarge
    case .accessibility4: return .accessibilityExtraExtraLarge
    case .accessibility5: return .accessibilityExtraExtraExtraLarge
    @unknown default: return .large
    }
  }
}
