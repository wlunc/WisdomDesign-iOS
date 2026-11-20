import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDSlider`（B13 + B17 范围 + B18 播报）的断言：数值标签、手柄焦点光环、区间约束与松手播报。
///
/// 口径：设计 08 §5（聚焦：手柄外扩 3pt、160ms）、§6（标签行右侧放值、等宽数字）、
/// `state.focus.ring-{width,alpha}`（3pt / 32%）。默认参数路径必须零视觉变化。
@MainActor
@Suite("WDSlider（B13）")
struct WDSliderTests {
  /// 量一个宽度下的高度（AX3 也量一遍：值标签不能撑高整个滑杆）。
  private func size<V: View>(
    _ view: V, width: CGFloat = 320, typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let controller = UIHostingController(
      rootView:
        view
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
  }

  // MARK: - 数值标签（showsValueLabel / valueText）

  @Test("showsValueLabel = true 时高度不变：值在标签行右侧，不额外占一行")
  func valueLabelKeepsHeight() {
    let plain = size(WDSlider(value: .constant(0.62), label: Text(verbatim: "完成度")))
    let withValue = size(
      WDSlider(
        value: .constant(0.62), label: Text(verbatim: "完成度"), showsValueLabel: true))
    #expect(
      abs(withValue.height - plain.height) <= 0.5, "带值 \(withValue.height) vs 不带 \(plain.height)")
    #expect(withValue.height >= WDSize.touchTargetMin)
  }

  @Test("AX3 下显示值也不撑高滑杆（值不换行到标签下方）")
  func valueLabelKeepsHeightAtAX3() {
    let plain = size(
      WDSlider(value: .constant(0.62), label: Text(verbatim: "完成度")), typeSize: .accessibility3)
    let withValue = size(
      WDSlider(
        value: .constant(0.62), label: Text(verbatim: "完成度"), showsValueLabel: true),
      typeSize: .accessibility3)
    #expect(abs(withValue.height - plain.height) <= 0.5)
  }

  @Test("注入 valueText 与使用系统本地化都只多值、不改变宽度下限")
  func valueLabelKeepsMinWidth() {
    let injected = size(
      WDSlider(
        value: .constant(2), label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1,
        showsValueLabel: true,
        valueText: { Text(verbatim: "档位 \(Int($0))") }))
    let localized = size(
      WDSlider(
        value: .constant(2), label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1,
        showsValueLabel: true))
    #expect(injected.width >= WDSliderMetrics.minWidth)
    #expect(localized.width >= WDSliderMetrics.minWidth)
    #expect(abs(injected.height - localized.height) <= 0.5)
  }

  @Test("值标签宽度：窄容器取下限、宽容器取上限、中间按比例；与手柄/轨道几何无关")
  func valueLabelWidthBounds() {
    // 容器越窄，留给值的宽度越接近下限（标签仍可读，值不挤占标签）。
    #expect(WDSliderMetrics.valueLabelWidth(available: 120) == 96)
    #expect(WDSliderMetrics.valueLabelWidth(available: 320) == 96)
    // 320 × 0.30 = 96（正好压下限）；再宽就按三成增长。
    // 1000 × 0.30 = 300 > 240 ⇒ 压上限。
    //
    // 上限先落到局部常量再比较：`#expect` 在「右侧是算式」且两侧类型不同（CGFloat vs Int）时
    // 会退化成跨类型取值比较、恒判 false —— 实测同一个算式写成 `let` 后即通过。
    let cappedWidth: CGFloat = 300 - 60
    #expect(WDSliderMetrics.valueLabelWidth(available: 1000) == cappedWidth)
    #expect(WDSliderMetrics.valueLabelWidth(available: 2000) == 240)
    // 宽度恒 > 0：避免在首帧（trackWidth = 0）量出负宽。
    #expect(WDSliderMetrics.valueLabelWidth(available: 0) > 0)
  }

  @Test("值标签宽度单调不减（容器变宽不会把值挤小）")
  func valueLabelWidthMonotonic() {
    let widths = [0, 120, 320, 480, 800, 1200].map {
      WDSliderMetrics.valueLabelWidth(available: $0)
    }
    for (lhs, rhs) in zip(widths, widths.dropFirst()) {
      #expect(rhs >= lhs)
    }
  }

  // MARK: - 焦点光环（B18：焦点由 WDAccessibilityFocusHost 回写）

  @Test("光环外扩 3pt：半径 = 手柄半径 13 + state.focus.ring-width 3")
  func focusRingRadius() {
    #expect(WDSliderMetrics.focusRingWidth == WDState.focusRingWidth)
    #expect(WDSliderMetrics.focusRingWidth == 3)
    #expect(
      WDSliderMetrics.focusRingRadius(isFocused: true, isEnabled: true)
        == WDSliderMetrics.thumbDiameter / 2 + 3)
    #expect(WDSliderMetrics.focusRingRadius(isFocused: true, isEnabled: true) == 16)
    #expect(WDSliderMetrics.focusRingDiameter(isFocused: true, isEnabled: true) == 32)
  }

  @Test("不聚焦或禁用时无光环（半径 0 = 不画这一层）")
  func focusRingAbsent() {
    #expect(WDSliderMetrics.focusRingRadius(isFocused: false, isEnabled: true) == 0)
    #expect(WDSliderMetrics.focusRingRadius(isFocused: true, isEnabled: false) == 0)
    #expect(WDSliderMetrics.focusRingDiameter(isFocused: false, isEnabled: true) == 0)
    #expect(WDSliderMetrics.focusRingDiameter(isFocused: true, isEnabled: false) == 0)
    #expect(!WDSliderMetrics.showsFocusRing(isFocused: false, isEnabled: true))
    #expect(!WDSliderMetrics.showsFocusRing(isFocused: true, isEnabled: false))
    #expect(WDSliderMetrics.showsFocusRing(isFocused: true, isEnabled: true))
  }

  @Test("光环与手柄同心：中心 = 手柄中心，竖直方向 = 热区中线")
  func focusRingOrigin() {
    let origin = WDSliderMetrics.focusRingOrigin(
      thumbCenterX: 50, hotAreaHeight: WDSize.touchTargetMin, isFocused: true, isEnabled: true)
    let radius = WDSliderMetrics.focusRingRadius(isFocused: true, isEnabled: true)
    #expect(origin.width == 50 - radius)
    #expect(origin.height == WDSize.touchTargetMin / 2 - radius)
    // 不呈现时返回 .zero（调用方靠直径 0 判断不画）。
    let hidden = WDSliderMetrics.focusRingOrigin(
      thumbCenterX: 50, hotAreaHeight: WDSize.touchTargetMin, isFocused: false, isEnabled: true)
    #expect(hidden == .zero)
  }

  @Test("光环落点与手柄在轨道上的位置一致（两端与中点）")
  func focusRingFollowsThumb() {
    // 热区宽 226 ⇒ 可用宽 200，手柄中心 = 13 + 200 × fraction。
    func center(fraction: CGFloat) -> CGFloat { 13 + 200 * fraction }
    for fraction: CGFloat in [0, 0.5, 1] {
      let origin = WDSliderMetrics.focusRingOrigin(
        thumbCenterX: center(fraction: fraction), hotAreaHeight: WDSize.touchTargetMin,
        isFocused: true, isEnabled: true)
      let ringCenter =
        origin.width
        + WDSliderMetrics.focusRingRadius(
          isFocused: true, isEnabled: true)
      #expect(ringCenter == center(fraction: fraction))
    }
  }

  @Test("光环淡入 160ms；Reduce Motion 直出（无动画）")
  func focusRingAnimation() {
    #expect(WDSliderMetrics.focusRingFadeDuration == 0.16)
    #expect(WDSliderMetrics.focusRingAnimation(reduceMotion: true) == nil)
    #expect(WDSliderMetrics.focusRingAnimation(reduceMotion: false) != nil)
  }

  @Test("光环颜色透明度 = state.focus.ring-alpha 32%（令牌给 0–100）")
  func focusRingAlpha() {
    #expect(WDState.focusRingAlpha == 32)
    #expect(abs(WDSliderMetrics.focusRingAlpha - 0.32) < 0.0001)
  }

  // MARK: - 默认路径不变

  @Test("默认构造（不传值标签）与显式 showsValueLabel = false 尺寸一致，且与加值前后同高")
  func defaultPathUnchanged() {
    let legacy = WDSlider(value: .constant(0.5), label: Text(verbatim: "完成度"))
    let explicit = WDSlider(
      value: .constant(0.5), label: Text(verbatim: "完成度"), showsValueLabel: false,
      valueText: { _ in Text(verbatim: "x") })
    let a = size(legacy)
    let b = size(explicit)
    #expect(a == b, "默认与显式 false 的尺寸应一致：\(a) vs \(b)")
    #expect(a.height >= WDSize.touchTargetMin)
    #expect(a.width >= WDSliderMetrics.minWidth)
  }

  @Test("禁用态尺寸不变（值标签 + 禁用仍不低于触控下限）")
  func disabledWithValueLabel() {
    let plain = size(
      WDSlider(value: .constant(0.8), label: Text(verbatim: "禁用"), showsValueLabel: true))
    let disabled = size(
      WDSlider(value: .constant(0.8), label: Text(verbatim: "禁用"), showsValueLabel: true)
        .disabled(true))
    #expect(disabled.height >= WDSize.touchTargetMin)
    #expect(abs(disabled.height - plain.height) <= 0.5)
  }

  // MARK: - 范围（B17）

  @Test("范围最小间隔 = 1 步长；step 为 nil 时允许重合")
  func rangeMinimumGap() {
    #expect(WDSliderRangeMath.minimumGap(step: nil) == 0)
    #expect(WDSliderRangeMath.minimumGap(step: 1) == 1)
    #expect(WDSliderRangeMath.minimumGap(step: -2) == 0)
  }

  @Test("范围两端不交叉：下端点 ≤ 上端点 − 间隔，且都在 bounds 内")
  func rangeNeverCrosses() {
    let bounds = 0.0...10.0
    #expect(WDSliderRangeMath.clampedLower(12, upper: 8, in: bounds, gap: 1) == 7)
    #expect(WDSliderRangeMath.clampedLower(-3, upper: 8, in: bounds, gap: 1) == 0)
    #expect(WDSliderRangeMath.clampedUpper(2, lower: 4, in: bounds, gap: 1) == 5)
    #expect(WDSliderRangeMath.clampedUpper(99, lower: 4, in: bounds, gap: 1) == 10)
  }

  @Test("范围松手吸附后仍满足间隔：吸到同一点时按活动手柄让位")
  func rangeSnapKeepsGap() {
    let bounds = 0.0...10.0
    let draggedLower = WDSliderRangeMath.snapped(
      lower: 3.4, upper: 3.6, in: bounds, step: 1, activeThumb: 0)
    #expect(draggedLower.lowerBound == 3)
    #expect(draggedLower.upperBound >= 4)
    let draggedUpper = WDSliderRangeMath.snapped(
      lower: 3.4, upper: 3.6, in: bounds, step: 1, activeThumb: 1)
    #expect(draggedUpper.upperBound == 4)
    #expect(draggedUpper.lowerBound <= 3)
  }

  @Test("范围构造尺寸与单值一致（同一标签行 + 同一条 44 热区）")
  func rangeKeepsSize() {
    let single = size(WDSlider(value: .constant(5), label: Text(verbatim: "预算")))
    let range = size(WDSlider(range: .constant(2...8), label: Text(verbatim: "预算")))
    #expect(abs(range.height - single.height) <= 0.5)
    #expect(range.width >= WDSliderMetrics.minWidth)
    #expect(range.height >= WDSize.touchTargetMin)
  }

  @Test("范围值文案由调用方给分隔符；没给就不显示值（高度不增）")
  func rangeValueLabelInjected() {
    let plain = size(WDSlider(range: .constant(2...8), label: Text(verbatim: "预算")))
    let noText = size(
      WDSlider(range: .constant(2...8), label: Text(verbatim: "预算"), showsValueLabel: true))
    let injected = size(
      WDSlider(
        range: .constant(2...8), label: Text(verbatim: "预算"), showsValueLabel: true,
        rangeText: { range in Text(verbatim: "\(range.lowerBound)–\(range.upperBound)") }))
    #expect(abs(noText.height - plain.height) <= 0.5)
    #expect(abs(injected.height - plain.height) <= 0.5)
  }
}
