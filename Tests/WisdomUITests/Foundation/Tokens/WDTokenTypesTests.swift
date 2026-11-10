import SwiftUI
import Testing

@testable import WisdomUI

/// 令牌基础类型：`WDTextStyle` / `WDShadowLayer` / `WDGradientSpec`（M3 覆盖率缺口）。
@MainActor
@Suite("令牌基础类型")
struct WDTokenTypesTests {
  @Test("WDTextStyle：行高比 / 行间距 / 字体派生")
  func textStyleDerivations() {
    let style = WDTextStyle(size: 16, lineHeight: 20, weight: .semibold, letterSpacing: 0.5)
    #expect(style.size == 16)
    #expect(style.lineHeight == 20)
    #expect(style.weight == .semibold)
    #expect(style.letterSpacing == 0.5)
    #expect(style.lineHeightRatio == 1.25)
    #expect(style.lineSpacing == 4)
    #expect(style == WDTextStyle(size: 16, lineHeight: 20, weight: .semibold, letterSpacing: 0.5))
  }

  @Test("行间距不为负（行高小于字号时取 0）")
  func lineSpacingClampsAtZero() {
    let tight = WDTextStyle(size: 20, lineHeight: 18, weight: .regular, letterSpacing: 0)
    #expect(tight.lineSpacing == 0)
  }

  @Test("WDTextStyle.font 与 text(_:) 可取值（渲染入口存在）")
  func textStyleRenderingEntry() {
    let style = WDTextStyle(size: 15, lineHeight: 20, weight: .regular, letterSpacing: 0)
    _ = style.font
    _ = style.text("示例")
  }

  @Test("WDShadowLayer：四字段原样保存")
  func shadowLayer() {
    let layer = WDShadowLayer(x: 1, y: 2, blur: 4, color: .black)
    #expect(layer.x == 1)
    #expect(layer.y == 2)
    #expect(layer.blur == 4)
    _ = layer.color
  }

  @Test("WDGradientSpec：角度 + 色标 + 线性渐变派生")
  func gradientSpec() {
    let spec = WDGradientSpec(
      angleDegrees: 90, stops: [(color: Color.red, location: 0), (color: .blue, location: 1)])
    #expect(spec.angleDegrees == 90)
    #expect(spec.stops.count == 2)
    #expect(spec.stops.first?.location == 0)
    #expect(spec.stops.last?.location == 1)
    _ = spec.linearGradient
  }
}
