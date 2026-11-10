import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDSemantics`：只做**结构**，零默认分隔符/零语序（SPEC §2.6.2 / F24 / B2-D5）。
///
/// `Text` 无法取串 ⇒ 用**渲染结果**做等价断言：库产出的文本必须与调用方自己拼的 `Text` 渲染一致；
/// 换个分隔符必须换出不同结果（证明库里没有内置分隔符）。测试只用非中文分隔符。
@MainActor
@Suite("语义拼接（WDSemantics）")
struct WDSemanticsTests {
  private static func png(_ text: Text) -> Data? {
    let renderer = ImageRenderer(
      content:
        text
        .frame(width: 240, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    )
    renderer.scale = 2
    return renderer.uiImage?.pngData()
  }

  @Test("join（String）：按调用方分隔符拼接，空串剔除（与 Android 同口径）")
  func joinStrings() {
    #expect(WDSemantics.join(["a", "b", "c"], separator: "|") == "a|b|c")
    #expect(WDSemantics.join(["a", "", "b"], separator: "|") == "a|b")
    #expect(WDSemantics.join([], separator: "|") == "")
    #expect(WDSemantics.join(["a"], separator: "|") == "a")
    #expect(WDSemantics.join(["a", "b"], separator: "／") == "a／b")
  }

  @Test("join（Text）：渲染结果 == 调用方自己拼的 Text（库内没有默认分隔符）")
  func joinTexts() {
    let built = WDSemantics.join(
      [Text(verbatim: "a"), Text(verbatim: "b")], separator: Text(verbatim: "|"))
    #expect(Self.png(built) == Self.png(Text(verbatim: "a|b")))
  }

  @Test("positional（Text）：渲染结果 == label + separator + positionText")
  func positionalText() {
    let built = WDSemantics.positional(
      label: Text(verbatim: "收件箱"),
      positionText: Text(verbatim: "2"),
      separator: Text(verbatim: "|")
    )
    #expect(Self.png(built) == Self.png(Text(verbatim: "收件箱|2")))
  }

  @Test("无默认分隔符：换分隔符，渲染结果必须跟着变")
  func noBuiltInSeparator() {
    let pipe = WDSemantics.join(
      [Text(verbatim: "a"), Text(verbatim: "b")], separator: Text(verbatim: "|"))
    let slash = WDSemantics.join(
      [Text(verbatim: "a"), Text(verbatim: "b")], separator: Text(verbatim: "／"))
    #expect(Self.png(pipe) != Self.png(slash))
  }
}
