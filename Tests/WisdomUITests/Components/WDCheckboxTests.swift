import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDCheckbox`（M2）的组件级断言：方框/圆角取令牌、热区、放大档不裁切。
@MainActor
@Suite("WDCheckbox（M2）")
struct WDCheckboxTests {
  private static func height(_ typeSize: DynamicTypeSize = .large) -> CGFloat {
    let controller = UIHostingController(
      rootView: WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "共享给家人"))
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  @Test("方框 26、圆角 9：与令牌一致（设计 06 §2–§3）")
  func metricsUseTokens() {
    #expect(WDCheckbox.Metrics.box == WDSize.checkbox)
    #expect(WDCheckbox.Metrics.corner == WDRadius.checkbox)
  }

  @Test("整行热区 ≥ 44")
  func meetsTouchTarget() {
    #expect(Self.height() >= WDSize.touchTargetMin - 0.5)
  }

  @Test("AX5：标签放大、行高增长（方框尺寸不变）")
  func growsAtAccessibilitySize() {
    #expect(Self.height(.accessibility5) > Self.height(.large))
  }

  @Test("半选：12×2.4 横杠；热区仍 ≥ 44")
  func indeterminate() {
    #expect(WDCheckbox.Metrics.barWidth == 12)
    #expect(WDCheckbox.Metrics.barHeight == 2.4)
    let controller = UIHostingController(
      rootView: WDCheckbox(
        isChecked: .constant(false), label: Text(verbatim: "全选"), isIndeterminate: true
      )
      .wdTheme(.light)
    )
    #expect(
      controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
        >= WDSize.touchTargetMin - 0.5)
  }
}
