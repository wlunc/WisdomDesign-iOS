import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDNavigationBar` 的 B15 增量（设计 33 §3/§4/§5/§8/§9）：
/// 大标题按 0…52pt 进度收缩、透明 → 玻璃交叉淡化、`false` 时完全沿用原口径。
@MainActor
@Suite("WDNavigationBar（B15 滚动联动）")
struct WDNavigationBarTests {
  private static func nav(mode: WDNavigationBarMode, followsScroll: Bool) -> WDNavigationBar {
    WDNavigationBar(
      title: Text(verbatim: "家庭"),
      mode: mode,
      followsScroll: followsScroll
    )
  }

  private static func measuredHeight(mode: WDNavigationBarMode, offset: CGFloat?) -> CGFloat {
    let view = nav(mode: mode, followsScroll: true)
      .wdTheme(.light)
      .wdScrollOffsetY(offset)
    let controller = UIHostingController(rootView: view)
    return controller.sizeThatFits(in: CGSize(width: 390, height: CGFloat.infinity)).height
  }

  // MARK: - 折叠进度

  @Test("进度：nil / 非联动 ⇒ 0（保持展开）")
  func progressInactive() {
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: nil, followsScroll: true) == 0)
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: 40, followsScroll: false) == 0)
  }

  @Test("进度：0 → 0、中点 0.5、52 → 1、之后封顶 1")
  func progressMapping() {
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: 0, followsScroll: true) == 0)
    #expect(
      abs(WDNavigationBar.titleProgress(scrollOffsetY: 26, followsScroll: true) - 0.5) < 0.0001)
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: 52, followsScroll: true) == 1)
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: 400, followsScroll: true) == 1)
  }

  @Test("进度：负值（下拉回弹）按 0 处理 ⇒ 不折叠也不越界")
  func progressIgnoresNegativeOffset() {
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: -40, followsScroll: true) == 0)
    #expect(WDNavigationBar.titleProgress(scrollOffsetY: -0.5, followsScroll: true) == 0)
  }

  @Test("进度：0…1 之间单调不减")
  func progressMonotonic() {
    var previous: CGFloat = -1
    for offset in stride(from: CGFloat(-10), through: 70, by: 1) {
      let current = WDNavigationBar.titleProgress(scrollOffsetY: offset, followsScroll: true)
      #expect(current >= previous)
      #expect(current >= 0 && current <= 1)
      previous = current
    }
  }

  // MARK: - 大标题行高度与整栏高度

  @Test("大标题行高度：52 → 0，收缩一半 = 26")
  func largeTitleRowHeightBands() {
    #expect(WDNavigationBar.largeTitleRowHeight(scrollOffsetY: nil, followsScroll: true) == 52)
    #expect(WDNavigationBar.largeTitleRowHeight(scrollOffsetY: 0, followsScroll: true) == 52)
    #expect(
      abs(WDNavigationBar.largeTitleRowHeight(scrollOffsetY: 26, followsScroll: true) - 26) < 0.0001
    )
    #expect(WDNavigationBar.largeTitleRowHeight(scrollOffsetY: 52, followsScroll: true) == 0)
    #expect(WDNavigationBar.largeTitleRowHeight(scrollOffsetY: 200, followsScroll: true) == 0)
  }

  @Test("整栏高度：大标题不联动 = 96（既有口径）；联动 52 → 44（= 内联行）")
  func barHeightBands() {
    #expect(
      WDNavigationBar.barHeight(mode: .largeTitle, scrollOffsetY: nil, followsScroll: true) == 96)
    #expect(
      WDNavigationBar.barHeight(mode: .largeTitle, scrollOffsetY: 0, followsScroll: true) == 96)
    #expect(
      WDNavigationBar.barHeight(mode: .largeTitle, scrollOffsetY: 52, followsScroll: true)
        == WDSize.navbarCompact)
    #expect(
      WDNavigationBar.barHeight(mode: .largeTitle, scrollOffsetY: 300, followsScroll: true)
        == WDSize.navbarCompact)
  }

  @Test("整栏高度：内联 44 / 标准 56 不受联动影响")
  func barHeightOtherModesUnchanged() {
    for offset: CGFloat? in [nil, 0, 26, 52, 999] {
      #expect(
        WDNavigationBar.barHeight(mode: .inline, scrollOffsetY: offset, followsScroll: true)
          == WDSize.navbarCompact)
      #expect(
        WDNavigationBar.barHeight(mode: .standard, scrollOffsetY: offset, followsScroll: true)
          == WDSize.navbarStandard)
    }
  }

  @Test("大标题向上吸的距离：走满时 = 内联行高度，期间线性")
  func collapseOffsetBands() {
    #expect(WDNavigationBar.largeTitleCollapseOffset(progress: 0, topRowHeight: 44) == 0)
    #expect(
      abs(WDNavigationBar.largeTitleCollapseOffset(progress: 0.5, topRowHeight: 44) - 22) < 0.0001)
    #expect(WDNavigationBar.largeTitleCollapseOffset(progress: 1, topRowHeight: 44) == 44)
    #expect(WDNavigationBar.largeTitleCollapseOffset(progress: 1.5, topRowHeight: 44) == 44)
  }

  // MARK: - 视图回归（默认路径像素不变）

  @Test("默认路径：followsScroll = false 时大标题栏高度仍为 96（offset 给什么都不变）")
  func defaultLargeTitleHeight() {
    for offset: CGFloat? in [nil, 0, 80, 999] {
      #expect(
        WDNavigationBar.barHeight(mode: .largeTitle, scrollOffsetY: offset, followsScroll: false)
          == 96)
    }
  }

  @Test("默认路径：nil offset 与显式 0 的大标题栏高度一致")
  func nilOffsetMatchesTop() {
    #expect(
      abs(
        Self.measuredHeight(mode: .largeTitle, offset: nil)
          - Self.measuredHeight(mode: .largeTitle, offset: 0)) <= 0.5)
  }

  @Test("联动：滚到 52 时大标题栏收到内联高度（44），滚得更远不再变矮")
  func largeTitleCollapsesInView() {
    let collapsed = Self.measuredHeight(mode: .largeTitle, offset: 52)
    let clamped = Self.measuredHeight(mode: .largeTitle, offset: 500)
    #expect(abs(collapsed - WDSize.navbarCompact) <= 1)
    #expect(abs(collapsed - clamped) <= 0.5)
  }
}
