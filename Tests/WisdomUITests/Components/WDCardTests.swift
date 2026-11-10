import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDCard`（M2）的组件级断言：内边距固定 16、三档齐、玻璃降级可渲染。
@MainActor
@Suite("WDCard（M2）")
struct WDCardTests {
  private static func height(_ style: WDCardStyle, typeSize: DynamicTypeSize = .large)
    -> CGFloat
  {
    let content = Rectangle()
      .fill(Color.gray)
      .frame(width: 100, height: 50)
    let controller = UIHostingController(
      rootView: WDCard(style: style) { content }
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  @Test("内边距固定 16：内容 50 高 ⇒ 卡 82 高（所有变体一致）")
  func paddingIs16() {
    for style in WDCardStyle.allCases {
      let measured = Self.height(style)
      #expect(abs(measured - 82) <= 1, "\(style.rawValue) 实测高度 \(measured)，应为 82 ± 1")
    }
  }

  @Test("三档齐：elevated（默认）/ outlined / glass")
  func styles() {
    #expect(WDCardStyle.allCases == [.elevated, .outlined, .glass])
  }
}
