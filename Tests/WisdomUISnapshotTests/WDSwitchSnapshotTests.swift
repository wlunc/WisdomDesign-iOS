import SwiftUI
import Testing
import WisdomUI

/// `WDSwitch` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 覆盖：开（渐变轨道）/ 关（描边轨道 + 白滑块）/ 禁用（40%）。
@MainActor
@Suite("WDSwitch 快照", .serialized)
struct WDSwitchSnapshotTests {
  static let canvas = CGSize(width: 360, height: 240)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDSwitch(isOn: .constant(true), label: Text(verbatim: "共享给家人"))
        WDSwitch(isOn: .constant(false), label: Text(verbatim: "每日提醒"))
        WDSwitch(isOn: .constant(false), label: Text(verbatim: "免打扰"))
          .disabled(true)
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDSwitch：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "switch-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
