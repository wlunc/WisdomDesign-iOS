import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDSwitch`（M2）的组件级断言：几何自洽、触控下限、放大档不裁切、拖动换算与吸附。
///
/// 几何口径（设计 05 §3）：轨道 51×31、滑块 27（轨道高 − 4）、行程 20。
@MainActor
@Suite("WDSwitch（M2）")
struct WDSwitchTests {
  private static func height(
    _ typeSize: DynamicTypeSize = .large,
    description: Text? = nil,
    size: WDSwitchSize = .standard
  ) -> CGFloat {
    let toggle: WDSwitch
    if description == nil, size == .standard {
      toggle = WDSwitch(isOn: .constant(true), label: Text(verbatim: "共享给家人"))
    } else {
      toggle = WDSwitch(
        isOn: .constant(true), label: Text(verbatim: "共享给家人"),
        description: description, size: size)
    }
    let controller = UIHostingController(
      rootView:
        toggle
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

  @Test("紧凑档几何自洽（40×24 / 滑块 20 / 行程 16）；rawValue 稳定")
  func compactMetrics() {
    #expect(WDSwitchSize.allCases.map(\.rawValue) == ["standard", "compact"])
    #expect(WDSwitch.Metrics.compactKnobDiameter == WDSwitch.Metrics.compactTrackHeight - 4)
    #expect(
      WDSwitch.Metrics.compactKnobTravel
        == WDSwitch.Metrics.compactTrackWidth - WDSwitch.Metrics.compactKnobDiameter - 4)
  }

  @Test("描述位增加一行高度")
  func descriptionAddsHeight() {
    let plain = Self.height(.accessibility3)
    let described = Self.height(.accessibility3, description: Text(verbatim: "关闭后不再收到推送"))
    #expect(described > plain, "带描述 \(described) 应高于无描述 \(plain)")
    #expect(Self.height(size: .compact) >= WDSize.touchTargetMin - 0.5)
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

  @Test("拖动换算：水平位移夹在两端，已在开态时可回拖")
  func dragOffsetClampsAtEnds() {
    let travel = WDSwitch.Metrics.knobTravel
    #expect(WDSwitchDrag.knobOffset(startOffset: 0, translation: -8, travel: travel) == 0)
    #expect(
      WDSwitchDrag.knobOffset(startOffset: 0, translation: travel + 8, travel: travel) == travel)
    #expect(
      WDSwitchDrag.knobOffset(startOffset: travel, translation: -8, travel: travel) == travel - 8)
  }

  @Test("拖动吸附：左/右/中点/两端按滑块中心是否过半")
  func dragSnapsAtHalfByKnobCenter() {
    for size in WDSwitchSize.allCases {
      let metrics = WDSwitch.Metrics.metrics(for: size)
      let left = WDSwitchDrag.knobCenterX(offset: 0, metrics: metrics)
      let right = WDSwitchDrag.knobCenterX(offset: metrics.knobTravel, metrics: metrics)
      let middle = WDSwitchDrag.knobCenterX(
        offset: metrics.knobTravel / 2, metrics: metrics)
      #expect(middle == metrics.trackWidth / 2, "\(size) 中点应落在轨道中心")
      #expect(!WDSwitchDrag.isOn(knobCenterX: left, trackWidth: metrics.trackWidth))
      #expect(WDSwitchDrag.isOn(knobCenterX: right, trackWidth: metrics.trackWidth))
      #expect(
        !WDSwitchDrag.isOn(knobCenterX: middle, trackWidth: metrics.trackWidth),
        "恰在中点归关，松手吸附到左端")
      #expect(WDSwitchDrag.isOn(knobCenterX: middle + 1, trackWidth: metrics.trackWidth))
    }
  }

  @Test("拖动方向判定：纵向交给父级 ScrollView，横向由开关接管")
  func dragAxisGate() {
    #expect(WDSwitchDrag.shouldBegin(translation: CGSize(width: 6, height: 1)))
    #expect(!WDSwitchDrag.shouldBegin(translation: CGSize(width: 1, height: 6)))
    #expect(WDSwitchDrag.shouldBegin(translation: CGSize(width: 0, height: 0)))
  }
}
