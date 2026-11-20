import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDPicker` 菜单形态的硬件键盘导航（A-9）：环形焦点推进、按键映射与初始焦点。
///
/// 口径：设计 22 §8（点击选项 = 选中 + 关闭 + 一次 `onChange`；Esc / 遮罩关闭不改值）、
/// §10（展开后焦点进入弹出层、Esc 后归还）。这里只断言可机检的纯逻辑与布局不变量，
/// 不模拟真实按键（按键注入属 XCUITest 层）。
@MainActor
@Suite("WDPicker 键盘焦点（A-9）")
struct WDPickerTests {
  private func option(_ id: String) -> WDPickerOption {
    WDPickerOption(id: id, label: Text(verbatim: id))
  }

  /// 两段分组：家庭 [chore, task] + 无标题 [travel, meal]。
  private var groupedSections: [WDPickerMenuSection] {
    [
      WDPickerMenuSection(
        id: 0, header: Text(verbatim: "家庭"), options: [option("chore"), option("task")]),
      WDPickerMenuSection(id: 1, header: nil, options: [option("travel"), option("meal")]),
    ]
  }

  // MARK: - 环形下标推进

  @Test("环形推进：末项 ↓ 回首项、首项 ↑ 去末项")
  func wrapsAround() {
    #expect(WDPickerMenuFocus.advancedIndex(3, count: 4, by: 1) == 0)
    #expect(WDPickerMenuFocus.advancedIndex(0, count: 4, by: -1) == 3)
    #expect(WDPickerMenuFocus.advancedIndex(1, count: 4, by: 1) == 2)
  }

  @Test("环形推进：空列表恒为 nil（没有可聚焦项）")
  func emptyListHasNoIndex() {
    #expect(WDPickerMenuFocus.advancedIndex(0, count: 0, by: 1) == nil)
    #expect(WDPickerMenuFocus.advancedIndex(nil, count: 0, by: -1) == nil)
  }

  @Test("环形推进：单项时 ↓/↑ 都停在 0（不回绕到空）")
  func singleItemStaysPut() {
    #expect(WDPickerMenuFocus.advancedIndex(0, count: 1, by: 1) == 0)
    #expect(WDPickerMenuFocus.advancedIndex(0, count: 1, by: -1) == 0)
  }

  @Test("环形推进：越界或缺失下标落到第一项，不崩也不越界")
  func invalidIndexFallsBackToFirst() {
    #expect(WDPickerMenuFocus.advancedIndex(nil, count: 3, by: 1) == 0)
    #expect(WDPickerMenuFocus.advancedIndex(9, count: 3, by: -1) == 0)
  }

  // MARK: - 分组跳过

  @Test("分组标题不进焦点序列：只收选项，跨组时直接落到下一组首项")
  func headersAreNotFocusable() {
    var focus = WDPickerMenuFocus(sections: groupedSections, selection: "task")
    #expect(focus.optionIDs == ["chore", "task", "travel", "meal"])
    #expect(focus.focusedID == "task")
    focus.move(.moveNext)
    #expect(focus.focusedID == "travel", "上一组末项 ↓ 落到下一组首项，不停在分组标题上")
    focus.move(.moveNext)
    focus.move(.moveNext)
    #expect(focus.focusedID == "chore", "末项 ↓ 回首项（跨分组仍环形）")
    focus.move(.movePrevious)
    #expect(focus.focusedID == "meal")
  }

  // MARK: - 初始焦点

  @Test("打开菜单：焦点落在选中项上")
  func initialFocusFollowsSelection() {
    #expect(WDPickerMenuFocus(optionIDs: ["a", "b", "c"], selection: "b").focusedID == "b")
    #expect(WDPickerMenuFocus(sections: groupedSections, selection: "meal").focusedID == "meal")
  }

  @Test("打开菜单：未选（或选中项已不在列表）时焦点落第一项")
  func initialFocusFallsBackToFirst() {
    #expect(WDPickerMenuFocus(optionIDs: ["a", "b"], selection: nil).focusedID == "a")
    #expect(WDPickerMenuFocus(optionIDs: ["a", "b"], selection: "gone").focusedID == "a")
    #expect(WDPickerMenuFocus(optionIDs: [], selection: nil).focusedID == nil)
  }

  // MARK: - 按键映射

  @Test("按键映射：方向键 / Enter / Space / Esc 各归一个动作，其余交还系统")
  func keyActionMapping() {
    #expect(WDPickerMenuKeyAction.action(for: .downArrow) == .moveNext)
    #expect(WDPickerMenuKeyAction.action(for: .upArrow) == .movePrevious)
    #expect(WDPickerMenuKeyAction.action(for: .return) == .commit)
    #expect(WDPickerMenuKeyAction.action(for: .space) == .commit)
    #expect(WDPickerMenuKeyAction.action(for: .escape) == .cancel)
    #expect(WDPickerMenuKeyAction.action(for: .tab) == nil, "未列入的按键不吞")
    #expect(WDPickerMenuKeyAction.action(for: .home) == nil)
  }

  @Test("提交/取消不改焦点：选中动作读到的仍是当前焦点项")
  func commitAndCancelKeepFocus() {
    var focus = WDPickerMenuFocus(optionIDs: ["a", "b", "c"], selection: "b")
    focus.move(.commit)
    #expect(focus.focusedID == "b")
    focus.move(.cancel)
    #expect(focus.focusedID == "b")
  }

  // MARK: - 焦点不改变布局

  private func size<V: View>(_ view: V, width: CGFloat = 180) -> CGSize {
    UIHostingController(rootView: view).sizeThatFits(
      in: CGSize(width: width, height: .greatestFiniteMagnitude))
  }

  @Test("焦点移动不改变菜单尺寸：有/无键盘焦点（含首末行）量出来一样")
  func focusDoesNotChangeSize() {
    let plain = size(WDPickerOptionList(sections: groupedSections, selection: "chore") { _ in })
    let first = size(
      WDPickerOptionList(
        sections: groupedSections, selection: "chore", focusedID: "chore"
      ) { _ in })
    let last = size(
      WDPickerOptionList(
        sections: groupedSections, selection: "chore", focusedID: "meal"
      ) { _ in })
    #expect(abs(first.width - plain.width) <= 0.5)
    #expect(abs(first.height - plain.height) <= 0.5)
    #expect(abs(last.width - plain.width) <= 0.5)
    #expect(abs(last.height - plain.height) <= 0.5)
  }

  @Test("焦点移动不改变浮层定位：placement 只由锚点与自然尺寸决定")
  func focusDoesNotChangePlacement() {
    let container = CGSize(width: 390, height: 700)
    let safeArea = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    let anchor = CGRect(x: 24, y: 300, width: 342, height: 44)
    let natural = CGSize(width: 200, height: 180)
    let before = WDPickerMenuPlacement.resolve(
      anchorRect: anchor, naturalSize: natural, containerSize: container, safeArea: safeArea)
    let after = WDPickerMenuPlacement.resolve(
      anchorRect: anchor, naturalSize: natural, containerSize: container, safeArea: safeArea)
    #expect(before == after)
    #expect(before.size == natural)
  }
}
