import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDTabBar` 的 B15 增量（设计 34 §6/§9）：滚动收起标签行、向上滚立即展开；
/// 选中态与热区不变，也不新增 init。
@MainActor
@Suite("WDTabBar（B15 滚动收起）")
struct WDTabBarTests {
  private static var items: [WDTabBarItem] {
    [
      WDTabBarItem(id: "today", icon: .home, label: Text(verbatim: "今天")),
      WDTabBarItem(id: "tasks", icon: .todo, label: Text(verbatim: "任务")),
      WDTabBarItem(id: "family", icon: .members, label: Text(verbatim: "家庭")),
    ]
  }

  private static func measuredHeight(offset: CGFloat?) -> CGFloat {
    let bar = WDTabBar(items: items, selection: .constant("today"))
      .wdTheme(.light)
      .wdScrollOffsetY(offset)
    let controller = UIHostingController(rootView: bar)
    return controller.sizeThatFits(in: CGSize(width: 390, height: CGFloat.infinity)).height
  }

  // MARK: - 收起判定（纯函数）

  @Test("收起判定：nil（不联动）⇒ 展开")
  func nilOffsetStaysExpanded() {
    #expect(!WDTabBar.isCollapsed(scrollOffsetY: nil))
  }

  @Test("收起判定：顶部与向上滚/下拉回弹（≤ 0）⇒ 展开")
  func nonPositiveOffsetStaysExpanded() {
    #expect(!WDTabBar.isCollapsed(scrollOffsetY: 0))
    #expect(!WDTabBar.isCollapsed(scrollOffsetY: -12))
    #expect(!WDTabBar.isCollapsed(scrollOffsetY: -0.001))
  }

  @Test("收起判定：阈值边界（恰在阈值仍展开，越过 1pt 才收起）")
  func thresholdBoundary() {
    #expect(!WDTabBar.isCollapsed(scrollOffsetY: 17))
    #expect(WDTabBar.isCollapsed(scrollOffsetY: 17.001))
    #expect(WDTabBar.isCollapsed(scrollOffsetY: 18))
    #expect(WDTabBar.isCollapsed(scrollOffsetY: 120))
  }

  @Test("收起判定：随 offset 单调（一旦收起就不再闪回展开）")
  func monotonicCollapse() {
    var hasCollapsed = false
    for offset in stride(from: CGFloat(-10), through: 60, by: 1) {
      let collapsed = WDTabBar.isCollapsed(scrollOffsetY: offset)
      if collapsed { hasCollapsed = true }
      if hasCollapsed { #expect(collapsed, "offset \(offset) 处不应回弹成展开") }
    }
  }

  // MARK: - 视图回归

  @Test("默认路径：nil offset 的测量高度 = 显式 0 的高度（不联动不改变像素）")
  func defaultPathUnchanged() {
    #expect(abs(Self.measuredHeight(offset: nil) - Self.measuredHeight(offset: 0)) <= 0.5)
  }

  @Test("默认路径：高度仍满足令牌下限 56（B15 之前的口径）")
  func defaultHeightMeetsToken() {
    #expect(Self.measuredHeight(offset: nil) >= WDSize.tabbarHeight)
  }

  @Test("收起态判定直接喂进视图：60 收起、0 展开（同一条纯函数）")
  func collapsedFlagForView() {
    #expect(WDTabBar.isCollapsed(scrollOffsetY: 60))
    #expect(!WDTabBar.isCollapsed(scrollOffsetY: 0))
  }
}
