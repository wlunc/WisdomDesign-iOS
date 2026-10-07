import SwiftUI
import UIKit

/// 对比度计算与门槛（DF-04：**4.5:1 / 3:1 + "最不利"取色**）。
///
/// 口径来自设计真源 `06-accessibility.md` §5.1/§5.2：
///   · 正文（< 18.66pt 粗体 / < 24pt）：**4.5:1**；大字号 / 图形 / 控件边界 / 焦点环：**3:1**；
///   · 禁用态**不适用**（40% 不透明度，可辨识即可）；
///   · **"最不利"**：取最不利位置的背景色测，**不是取平均**；玻璃取"最暗内容"或"最亮内容"的合成色。
public enum WDContrast {
  /// WCAG 2.x 的正文门槛。
  public static let bodyTextThreshold = 4.5  // wd-structure-check:disable R7 — DF-04 的硬门槛，非令牌值
  /// WCAG 2.x 的大字号 / 图形门槛。
  public static let graphicsThreshold = 3.0  // wd-structure-check:disable R7 — DF-04 的硬门槛，非令牌值

  /// sRGB 相对亮度。
  public static func relativeLuminance(_ color: Color) -> Double {
    let components = rgba(color)
    func channel(_ value: Double) -> Double {
      value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(components.r) + 0.7152 * channel(components.g) + 0.0722
      * channel(components.b)
  }

  /// 对比度 = (L_亮 + 0.05) / (L_暗 + 0.05)。
  public static func ratio(_ lhs: Color, _ rhs: Color) -> Double {
    let a = relativeLuminance(lhs)
    let b = relativeLuminance(rhs)
    let lighter = max(a, b)
    let darker = min(a, b)
    return (lighter + 0.05) / (darker + 0.05)  // wd-structure-check:disable R7 — WCAG 公式常数
  }

  /// 半透明色叠在不透明底上（玻璃取"最不利合成色"的输入）。
  public static func composite(_ top: Color, over bottom: Color) -> Color {
    let t = rgba(top)
    let b = rgba(bottom)
    let alpha = t.a
    return Color(
      .sRGB,
      red: t.r * alpha + b.r * (1 - alpha),
      green: t.g * alpha + b.g * (1 - alpha),
      blue: t.b * alpha + b.b * (1 - alpha),
      opacity: 1
    )
  }

  /// 正文达标？
  public static func meetsBodyText(_ ratio: Double) -> Bool { ratio >= bodyTextThreshold }
  /// 大字号 / 图形达标？
  public static func meetsGraphics(_ ratio: Double) -> Bool { ratio >= graphicsThreshold }

  /// 取 RGBA（sRGB 分量，0…1）。令牌色是显式 sRGB，不需要 trait collection。
  public static func rgba(_ color: Color) -> (r: Double, g: Double, b: Double, a: Double) {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return (0, 0, 0, 1) }
    return (Double(r), Double(g), Double(b), Double(a))
  }
}
