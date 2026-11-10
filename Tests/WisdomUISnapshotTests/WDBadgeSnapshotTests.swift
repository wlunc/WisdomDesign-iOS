import SwiftUI
import Testing
import WisdomUI

/// `WDBadge` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 徽标字号固定（设计例外）⇒ AX3 态应与默认态同尺寸，快照是这条"例外"的目视回归网。
@MainActor
@Suite("WDBadge 快照", .serialized)
struct WDBadgeSnapshotTests {
  static let canvas = CGSize(width: 360, height: 240)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "已完成"))
          WDBadge(label: Text(verbatim: "已逾期"))
          WDBadge(label: Text(verbatim: "进行中"))
        }
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "3"))
          WDBadge(label: Text(verbatim: "12"))
          WDBadge(label: Text(verbatim: "99"))
        }
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "最大四个汉字"))
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDBadge：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "badge-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
