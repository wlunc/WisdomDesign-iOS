import SwiftUI
import Testing
import WisdomUI

/// `WDCheckbox` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
@MainActor
@Suite("WDCheckbox 快照", .serialized)
struct WDCheckboxSnapshotTests {
  static let canvas = CGSize(width: 360, height: 220)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDCheckbox(isChecked: .constant(false), label: Text(verbatim: "共享给家人"))
        WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "每日提醒"))
        WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "已完成的选项"))
          .disabled(true)
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDCheckbox：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "checkbox-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
