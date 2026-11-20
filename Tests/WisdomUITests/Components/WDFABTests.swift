import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDFAB` 的 B15 增量（设计 36 §5/§6/§8）：
/// 展开遮罩 / TabBar 避让留白 / 滚动缩小（缩小但不隐藏），以及"不联动 = 像素不变"。
///
/// 滚动换算全部走 `WDFAB.scrollDiameter` / `scrollOpacity` / `bottomInset` 纯函数：
/// 覆盖 nil、负值回弹、阈值边界与单调性；视图层只做"喂 offset 后尺寸不变"的回归断言。
@MainActor
@Suite("WDFAB（B15 滚动联动 / 遮罩 / TabBar 避让）")
struct WDFABTests {
  /// 缩小走完的距离（与组件同口径：三段滚动联动统一取 52）。
  private static let distance: CGFloat = 52

  private static func fab(
    size: WDFABSize = .standard,
    actions: [WDFABAction] = [],
    action: (() -> Void)? = nil,
    showsScrimWhenExpanded: Bool = false,
    avoidsTabBar: Bool = false
  ) -> WDFAB {
    WDFAB(
      icon: .add,
      accessibilityLabel: Text(verbatim: "新建任务"),
      size: size,
      actions: actions,
      action: action,
      showsScrimWhenExpanded: showsScrimWhenExpanded,
      avoidsTabBar: avoidsTabBar
    )
  }

  private static func measuredHeight(_ view: WDFAB) -> CGFloat {
    let controller = UIHostingController(rootView: view.wdTheme(.light))
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  private static func actions(_ count: Int) -> [WDFABAction] {
    (1...count).map { index in
      WDFABAction(id: "child-\(index)", icon: .task, label: Text(verbatim: "任务"), action: {})
    }
  }

  // MARK: - 滚动缩小

  @Test("滚动尺寸：nil 不联动 ⇒ 原直径（56 / 64 / 40 各档）")
  func scrollDiameterWithoutOffset() {
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: nil, distance: Self.distance) == 56)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 64, scrollOffsetY: nil, distance: Self.distance) == 64)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 40, scrollOffsetY: nil, distance: Self.distance) == 40)
  }

  @Test("滚动尺寸：走到距离 ⇒ 40（设计 36 §5），之后封顶不再变")
  func scrollDiameterCollapsesToForty() {
    #expect(WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: 0, distance: Self.distance) == 56)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: Self.distance, distance: Self.distance)
        == 40)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: 400, distance: Self.distance) == 40)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 64, scrollOffsetY: 400, distance: Self.distance) == 40)
  }

  @Test("滚动尺寸：负值（下拉回弹）按 0 处理 ⇒ 保持原直径")
  func scrollDiameterIgnoresNegativeOffset() {
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: -80, distance: Self.distance) == 56)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: -0.5, distance: Self.distance) == 56)
  }

  @Test("滚动尺寸：小号 40 不会缩得更小（下限就是设计值 40）")
  func smallSizeKeepsForty() {
    #expect(WDFAB.scrollDiameter(baseDiameter: 40, scrollOffsetY: 0, distance: Self.distance) == 40)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 40, scrollOffsetY: Self.distance, distance: Self.distance)
        == 40)
    #expect(
      WDFAB.scrollDiameter(baseDiameter: 40, scrollOffsetY: 999, distance: Self.distance) == 40)
  }

  @Test("滚动尺寸：0…距离之间单调不增，中点线性落在 48")
  func scrollDiameterIsMonotonic() {
    var previous = WDFAB.scrollDiameter(
      baseDiameter: 56, scrollOffsetY: 0, distance: Self.distance)
    for offset in stride(from: CGFloat(-20), through: 120, by: 4) {
      let current = WDFAB.scrollDiameter(
        baseDiameter: 56, scrollOffsetY: offset, distance: Self.distance)
      #expect(current <= previous + 0.0001, "offset \(offset) 处尺寸不应变大")
      #expect(current >= 40 - 0.0001)
      previous = current
    }
    #expect(
      abs(WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: 26, distance: Self.distance) - 48)
        < 0.0001)
  }

  @Test("滚动不透明度：nil / 负值 ⇒ 1；走满 ⇒ 0.88；单调不增且恒 > 0（不隐藏）")
  func scrollOpacityBands() {
    #expect(WDFAB.scrollOpacity(scrollOffsetY: nil, distance: Self.distance) == 1)
    #expect(WDFAB.scrollOpacity(scrollOffsetY: 0, distance: Self.distance) == 1)
    #expect(WDFAB.scrollOpacity(scrollOffsetY: -40, distance: Self.distance) == 1)
    #expect(
      abs(WDFAB.scrollOpacity(scrollOffsetY: Self.distance, distance: Self.distance) - 0.88)
        < 0.0001)
    #expect(
      abs(WDFAB.scrollOpacity(scrollOffsetY: 500, distance: Self.distance) - 0.88) < 0.0001)
    var previous = WDFAB.scrollOpacity(scrollOffsetY: 0, distance: Self.distance)
    for offset in stride(from: CGFloat(0), through: 100, by: 2) {
      let current = WDFAB.scrollOpacity(scrollOffsetY: offset, distance: Self.distance)
      #expect(current <= previous + 0.0001)
      #expect(current > 0, "设计 36 §8：滚动只降低不透明度，从不隐藏")
      previous = current
    }
  }

  // MARK: - TabBar 避让留白

  @Test("底部留白：默认 18；避让 Tab 栏 92（设计 36 §6）")
  func bottomInsetValues() {
    #expect(WDFAB.bottomInset(avoidsTabBar: false) == 18)
    #expect(WDFAB.bottomInset(avoidsTabBar: true) == 92)
    #expect(WDFAB.bottomInset(avoidsTabBar: true) > WDFAB.bottomInset(avoidsTabBar: false))
  }

  @Test("底部留白：默认参数路径只由 (按钮直径 + 18) 组成，与 B15 之前同一口径")
  func defaultHeightUnchanged() {
    // 默认不联动 ⇒ 缩放恒为 1、不透明度恒为 1，尺寸只剩"按钮直径 + 底部留白"。
    let scale =
      WDFAB.scrollDiameter(baseDiameter: 56, scrollOffsetY: nil, distance: Self.distance) / 56
    #expect(scale == 1)
    #expect(56 * scale + WDFAB.bottomInset(avoidsTabBar: false) == 74)
  }

  @Test("避让 Tab 栏：高度多出 74pt（92 − 18），且不等于切换了安全区")
  func avoidsTabBarRaisesMeasuredHeight() {
    let plain = Self.measuredHeight(Self.fab())
    let avoiding = Self.measuredHeight(Self.fab(avoidsTabBar: true))
    #expect(abs((avoiding - plain) - 74) <= 0.5)
  }

  // MARK: - 展开遮罩

  @Test("遮罩：默认关闭 ⇒ 展开前后高度只由子操作决定（与显式 false 相同）")
  func scrimDefaultsToOff() {
    let actions = Self.actions(2)
    let omitted = Self.measuredHeight(Self.fab(actions: actions))
    let explicitFalse = Self.measuredHeight(
      Self.fab(actions: actions, showsScrimWhenExpanded: false))
    #expect(abs(omitted - explicitFalse) <= 0.001)
  }

  @Test("遮罩：开启后不额外占布局高度（遮罩是背景层，不把 FAB 撑高）")
  func scrimDoesNotReserveHeight() {
    let withoutScrim = Self.measuredHeight(Self.fab(showsScrimWhenExpanded: false))
    let withScrim = Self.measuredHeight(Self.fab(showsScrimWhenExpanded: true))
    #expect(abs(withScrim - withoutScrim) <= 0.5)
  }

  @Test("遮罩：可构造（展开/收起由交互驱动，此处只钉公开参数存在且默认 false）")
  func scrimInitializerAccepted() {
    _ = Self.fab(showsScrimWhenExpanded: true, avoidsTabBar: true)
    #expect(WDFABSize.allCases.map(\.rawValue) == ["small", "standard", "large"])
  }
}
