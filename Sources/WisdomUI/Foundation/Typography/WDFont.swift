import SwiftUI

extension View {
  /// **字体唯一入口**（R11 强制：`Components/**` 禁 `.font(.system(` / `Font.system(` /
  /// `.font(WDType.`）—— 按字阶 + 当前 `dynamicTypeSize` 直算字号，并套上设计字距。
  public func wdFont(_ style: WDTextStyle) -> some View {
    modifier(WDFontModifier(style: style))
  }

  /// **行盒唯一入口**（SPEC §2.6.3）：把「盒高」变成几何事实，而不是行距的副作用。
  ///
  /// 语义 = `max(设计行高 × 缩放, natural)`：
  ///   · 多行行距 = `max(0, 行盒高 − natural)`；
  ///   · 容器 `minHeight = lines × 行盒高`（**只给下限**：CJK 的自然行高更高时，盒子随之长高而不是裁切）。
  /// - Parameter lines: 预期行数（默认 1）；小于 1 时按 1 处理。
  public func wdLineBox(_ style: WDTextStyle, lines: Int = 1) -> some View {
    modifier(WDLineBoxModifier(style: style, lines: max(1, lines)))
  }
}

/// `wdFont` 的实现：只读环境里的动态字体档，不写环境（R18 只约束写入口）。
private struct WDFontModifier: ViewModifier {
  let style: WDTextStyle

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  func body(content: Content) -> some View {
    content
      .font(
        // **按 text style 取字体**（不是 `.system(size:)`）：后者在 SwiftUI 里是"固定字号"，
        // 系统无障碍审计判它 "Dynamic Type ... unsupported"（实测：demo 的
        // performAccessibilityAudit(.dynamicType) 就是被这条拦下的），
        // 即使我们自己按 dynamicTypeSize 算过缩放 —— AX 树上仍看不到缩放能力。
        // 设计字号 == 系统同名档默认字号，由 WDFontMetricsTests 钉住（不等就红）。
        .system(style.textStyle, design: .default, weight: style.weight)
      )
      .tracking(style.letterSpacing)
  }
}

/// `wdLineBox` 的实现。**不加 padding**：CJK 文本的自然行高本就更⾼，
/// 固定 padding 会让中文盒子多出「设计余量」那一截（实测见 WDLineBoxTest 的 zh 断言）。
private struct WDLineBoxModifier: ViewModifier {
  let style: WDTextStyle
  let lines: Int

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  func body(content: Content) -> some View {
    let box = WDFontMetrics.lineBoxHeight(for: style, dynamicTypeSize: dynamicTypeSize)
    return
      content
      .lineSpacing(WDFontMetrics.lineSpacing(for: style, dynamicTypeSize: dynamicTypeSize))
      .frame(minHeight: CGFloat(lines) * box, alignment: .leading)
  }
}
