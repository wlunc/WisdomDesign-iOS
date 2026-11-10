import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDSwitch`（M2）的组件级断言：几何自洽、触控下限、放大档不裁切。
///
/// 几何口径（设计 05 §3）：轨道 51×31、滑块 27（轨道高 − 4）、行程 20。
@MainActor
@Suite("WDSwitch（M2）")
struct WDSwitchTests {
  private static func height(_ typeSize: DynamicTypeSize = .large) -> CGFloat {
    let controller = UIHostingController(
      rootView: WDSwitch(isOn: .constant(true), label: Text(verbatim: "共享给家人"))
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  @Test("几何自洽：滑块 = 轨道高 − 4；行程 = 宽 − 滑块 − 两侧内边距")
  func metrics() {
    #expect(WDSwitch.Metrics.knobDiameter == WDSwitch.Metrics.trackHeight - 4)
    #expect(
      WDSwitch.Metrics.knobTravel == WDSwitch.Metrics.trackWidth - WDSwitch.Metrics.knobDiameter - 4
    )
  }

  @Test("整行触控下限 ≥ 44（标签 + 轨道）")
  func meetsTouchTarget() {
    let measured = Self.height()
    #expect(measured >= WDSize.touchTargetMin - 0.5, "实测行高 \(measured)，应 ≥ 44")
  }

  @Test("AX5：行高随标签行盒增长（不裁切）")
  func growsAtAccessibilitySize() {
    let normal = Self.height(.large)
    let ax5 = Self.height(.accessibility5)
    #expect(ax5 > normal, "AX5 行高 \(ax5) 应大于默认档 \(normal)")
  }
}
