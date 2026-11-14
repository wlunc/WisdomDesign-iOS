import SwiftUI
import Testing

@testable import WisdomUI

/// M6 场景组件的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 样本把四个变体（单选 + 未指派 / 多选 / 紧凑 / 整体禁用）放进同一画布，
/// 溢出 `+n` 由 8 人名单触发（设计 37 §3：最多直接显示 6 个）。
@MainActor
@Suite("M6 快照", .serialized)
struct M6SnapshotTests {
  static let canvas = CGSize(width: 360, height: 540)

  private func framed<V: View>(_ view: V, values: WDColorValues) -> some View {
    view
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
  }

  private func snap(_ name: String, sample: some View) {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      let view = framed(sample, values: values)
      // 组件内含横向 ScrollView：ImageRenderer 会把滚动内容画成空白（同 UIKit 接管型），
      // 必须走 UIHostingController + drawHierarchy 渲染器（SPEC §1.6 的显式表口径）。
      SnapshotSupport.verifyHierarchy(
        name: "\(name)-\(state.id)", view: view, state: state, size: Self.canvas)
    }
  }

  @Test("WDAssigneePicker：8 态")
  func assigneePicker() {
    snap("assigneepicker", sample: AssigneePickerSample())
  }
}

// MARK: - 样本

private struct AssigneePickerSample: View {
  private let items: [WDAssigneePickerItem] = [
    .init(
      id: "mom", avatar: .init(label: Text(verbatim: "妈")),
      accessibilityLabel: Text(verbatim: "妈妈"), name: Text(verbatim: "妈妈")),
    .init(
      id: "dad", avatar: .init(label: Text(verbatim: "爸")),
      accessibilityLabel: Text(verbatim: "爸爸"), name: Text(verbatim: "爸爸")),
    .init(
      id: "li", avatar: .init(label: Text(verbatim: "李")),
      accessibilityLabel: Text(verbatim: "小李"), name: Text(verbatim: "小李")),
    .init(
      id: "wang", avatar: .init(label: Text(verbatim: "王")),
      accessibilityLabel: Text(verbatim: "王阿姨"), name: Text(verbatim: "王阿姨")),
    .init(
      id: "zhang", avatar: .init(label: Text(verbatim: "张")),
      accessibilityLabel: Text(verbatim: "张三"), name: Text(verbatim: "张三")),
    .init(
      id: "zhao", avatar: .init(label: Text(verbatim: "赵")),
      accessibilityLabel: Text(verbatim: "赵六"), name: Text(verbatim: "赵六"),
      isEnabled: false, unavailableReason: Text(verbatim: "已离开")),
    .init(
      id: "chen", avatar: .init(label: Text(verbatim: "陈")),
      accessibilityLabel: Text(verbatim: "陈七"), name: Text(verbatim: "陈七")),
    .init(
      id: "liu", avatar: .init(label: Text(verbatim: "刘")),
      accessibilityLabel: Text(verbatim: "刘八"), name: Text(verbatim: "刘八")),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDAssigneePicker(
        selection: .constant("mom"),
        label: Text(verbatim: "指派给"),
        items: items,
        unassigned: .init(label: Text(verbatim: "未指派"), accessibilityLabel: Text(verbatim: "未指派")),
        positionText: { index, total in Text(verbatim: "第 \(index) 项，共 \(total) 项") })
      WDAssigneePicker(
        selection: .constant(Set(["mom", "dad"])),
        label: Text(verbatim: "参与人"),
        items: items)
      WDAssigneePicker(
        selection: .constant(nil as String?),
        label: Text(verbatim: "紧凑"),
        items: items,
        size: .compact)
      WDAssigneePicker(
        selection: .constant("dad"),
        label: Text(verbatim: "整体禁用"),
        items: items
      )
      .disabled(true)
    }
  }
}
