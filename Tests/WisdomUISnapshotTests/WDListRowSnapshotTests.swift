import SwiftUI
import Testing
import WisdomUI

/// `WDListRow` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 覆盖：图标前导 + 值文本、头像前导 + 徽标、勾选前导（选中）、单选指示 + 箭头、只读行。
@MainActor
@Suite("WDListRow 快照", .serialized)
struct WDListRowSnapshotTests {
  static let canvas = CGSize(width: 360, height: 620)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(spacing: 0) {
        WDListRow(
          title: Text(verbatim: "整理储物间"),
          subtitle: Text(verbatim: "今天 18:00 前"),
          leading: .icon(.task),
          trailing: .value(Text(verbatim: "3 件")),
          action: {}
        )
        WDListRow(
          title: Text(verbatim: "妈妈的待办"),
          subtitle: Text(verbatim: "已完成 2 项"),
          leading: .avatar(.init(label: Text(verbatim: "妈"))),
          trailing: .badge(.init(label: Text(verbatim: "进行中")))
        )
        WDListRow(
          title: Text(verbatim: "每天八杯水"),
          leading: .checkbox,
          isSelected: true,
          action: {}
        )
        WDListRow(
          title: Text(verbatim: "采购清单"),
          leading: .selectionIndicator,
          trailing: .disclosure,
          isSelected: true,
          action: {}
        )
        WDListRow(
          title: Text(verbatim: "只读的一行"),
          trailing: .value(Text(verbatim: "12:30"))
        )
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDListRow：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "listrow-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
