import SwiftUI
import Testing
import UIKit
import WisdomUI

/// `wdFont` 的取字体口径守卫（M1）。
///
/// `wdFont` 用 `.font(.system(<textStyle>, weight:))` 而不是 `.system(size:)`：
/// 前者是 SwiftUI 里唯一**原生支持动态字体**的写法（后者被系统无障碍审计判为不支持 —— 实测
/// demo 的 `performAccessibilityAudit(.dynamicType)` 报 "Dynamic Type font sizes are partially unsupported"）。
///
/// 代价是"字号由 text style 决定"，所以这里钉死一件事：**12 条字阶的设计字号 == 系统同名档的默认字号**。
/// 将来设计改字号（例如 caption2 从 11 改成 11.5）⇒ 本用例红 ⇒ 必须改回按 size 取字体并另找可访问性方案。
@MainActor
@Suite("wdFont 取字体口径")
struct WDFontMetricsTests {
  /// (字阶名, 设计字号, UIKit text style)。表与 `WDTypographyMapping` 一一对应。
  static let table: [(String, CGFloat, UIFont.TextStyle)] = [
    ("largeTitle", WDType.largeTitle.size, .largeTitle),
    ("title1", WDType.title1.size, .title1),
    ("title2", WDType.title2.size, .title2),
    ("title3", WDType.title3.size, .title3),
    ("headline", WDType.headline.size, .headline),
    ("body", WDType.body.size, .body),
    ("callout", WDType.callout.size, .callout),
    ("subheadline", WDType.subheadline.size, .subheadline),
    ("footnote", WDType.footnote.size, .footnote),
    ("caption1", WDType.caption1.size, .caption1),
    ("caption2", WDType.caption2.size, .caption2),
    ("overline", WDType.overline.size, .caption1),
  ]

  @Test("12 条字阶：设计字号 == 系统同名档默认字号（否则 .system(textStyle) 会悄悄换字号）")
  func designSizesMatchSystemStyles() {
    let traits = UITraitCollection(preferredContentSizeCategory: .large)
    for (name, size, uiStyle) in Self.table {
      let system = UIFont.preferredFont(forTextStyle: uiStyle, compatibleWith: traits).pointSize
      #expect(
        size == system,
        "\(name)：设计字号 \(size) ≠ 系统 \(uiStyle) 默认字号 \(system) —— 要么改回按 size 取字体，要么改映射"
      )
    }
  }

  @Test("WDFontMetrics 的字号 == 系统的 preferred font（默认 / AX3 / AX5 三档）")
  func scaledSizesMatchSystem() {
    let categories: [UIContentSizeCategory] = [
      .large, .accessibilityExtraLarge, .accessibilityExtraExtraExtraLarge,
    ]
    for (name, _, uiStyle) in Self.table {
      for category in categories {
        let traits = UITraitCollection(preferredContentSizeCategory: category)
        let system = UIFont.preferredFont(forTextStyle: uiStyle, compatibleWith: traits).pointSize
        let style = Self.style(named: name)
        let mine = WDFontMetrics.scaledSize(
          for: style,
          dynamicTypeSize: Self.dynamicTypeSize(for: category)
        )
        #expect(
          abs(mine - system) <= 0.5,
          "\(name)/\(category.rawValue)：库 \(mine) vs 系统 \(system)（差 > 0.5pt = 缩放口径不一致）"
        )
      }
    }
  }

  /// 名字 → 字阶（表驱动，避免在断言里写 12 次 switch）。
  static func style(named name: String) -> WDTextStyle {
    switch name {
    case "largeTitle": return WDType.largeTitle
    case "title1": return WDType.title1
    case "title2": return WDType.title2
    case "title3": return WDType.title3
    case "headline": return WDType.headline
    case "body": return WDType.body
    case "callout": return WDType.callout
    case "subheadline": return WDType.subheadline
    case "footnote": return WDType.footnote
    case "caption1": return WDType.caption1
    case "caption2": return WDType.caption2
    default: return WDType.overline
    }
  }

  /// UIContentSizeCategory → DynamicTypeSize（只覆盖本条用例用到的三档）。
  static func dynamicTypeSize(for category: UIContentSizeCategory) -> DynamicTypeSize {
    switch category {
    case .large: return .large
    case .accessibilityExtraLarge: return .accessibility3
    default: return .accessibility5
    }
  }
}
