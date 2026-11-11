import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDListSection`（M3 草案）的结构断言：空组隐藏、末行/选中传递、密度与间距。
@MainActor
@Suite("列表分组（WDListSection）")
struct WDListSectionTests {
  private struct Item: Identifiable, Equatable {
    let id: Int
    let title: String
  }

  private let items = [
    Item(id: 1, title: "一"),
    Item(id: 2, title: "二"),
    Item(id: 3, title: "三"),
  ]

  /// 用宿主控制器量高度（不依赖渲染器；空视图应得 0）。
  private func height<V: View>(_ view: V, width: CGFloat = 375) -> CGFloat {
    let controller = UIHostingController(rootView: view)
    return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
      .height
  }

  @Test("空 items：整组隐藏（高度 0，不出现空标题）")
  func emptySectionIsHidden() {
    let section = WDListSection(
      items: [Item](), selection: [], header: Text(verbatim: "空组")
    ) { _, _ in EmptyView() }
    #expect(height(section) == 0)
  }

  @Test("行上下文：末行 isLast = true，其余 false")
  func rowContextLastFlag() {
    var lastFlags: [Int: Bool] = [:]
    let section = WDListSection(
      items: items, selection: [], header: Text(verbatim: "今天")
    ) { item, context in
      lastFlags[item.id] = context.isLast
      return EmptyView()
    }
    _ = height(section)
    #expect(lastFlags == [1: false, 2: false, 3: true])
  }

  @Test("行上下文：选中状态来自 selection 集合")
  func rowContextSelection() {
    var selected: [Int: Bool] = [:]
    let section = WDListSection(
      items: items, selection: [2], header: Text(verbatim: "今天")
    ) { item, context in
      selected[item.id] = context.isSelected
      return EmptyView()
    }
    _ = height(section)
    #expect(selected == [1: false, 2: true, 3: false])
  }

  @Test("有行时高度为正；3 行高于 1 行")
  func heightGrowsWithRows() {
    let one = WDListSection(items: [items[0]], header: Text(verbatim: "一")) { item, context in
      WDListRow(title: Text(verbatim: item.title), showsSeparator: !context.isLast)
    }
    let three = WDListSection(items: items, header: Text(verbatim: "三")) { item, context in
      WDListRow(title: Text(verbatim: item.title), showsSeparator: !context.isLast)
    }
    #expect(height(one) > 0)
    #expect(height(three) > height(one))
  }

  @Test("页脚增加高度（4pt 间距 + 页脚行盒）")
  func footerAddsHeight() {
    let without = WDListSection(items: items, header: Text(verbatim: "今天")) { _, _ in EmptyView() }
    let with = WDListSection(items: items, header: Text(verbatim: "今天")) { _, _ in
      EmptyView()
    } footer: {
      Text(verbatim: "共 3 项")
    }
    #expect(height(with) > height(without))
  }

  @Test("标题动作：头行达到 44 的最小热区（a11y）")
  func headerActionHasTapTarget() {
    let section = WDListSection(
      items: [items[0]],
      header: Text(verbatim: "今天"),
      headerAction: .init(label: Text(verbatim: "编辑"), action: {})
    ) { _, _ in EmptyView() }
    #expect(height(section) >= WDSize.touchTargetMin)
  }

  @Test("密度：compact 下同组行更矮")
  func densityPassesThrough() {
    let section = WDListSection(items: items, header: Text(verbatim: "今天")) { item, context in
      WDListRow(title: Text(verbatim: item.title), showsSeparator: !context.isLast)
    }
    let comfortable = height(section.wdDensity(.comfortable))
    let compact = height(section.wdDensity(.compact))
    #expect(compact < comfortable)
  }
}
