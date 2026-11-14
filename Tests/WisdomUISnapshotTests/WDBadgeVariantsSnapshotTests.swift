import SwiftUI
import Testing
import WisdomUI

/// `WDBadge` 六变体的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 变体只影响状态胶囊配色；计数/圆点形态放在同一张图里做回归对照。
@MainActor
@Suite("WDBadge 六变体快照", .serialized)
struct WDBadgeVariantsSnapshotTests {
  static let canvas = CGSize(width: 360, height: 240)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "共享"), variant: .shared)
          WDBadge(label: Text(verbatim: "提醒"), variant: .schedule)
          WDBadge(label: Text(verbatim: "进行中"), variant: .pending)
        }
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "已完成"), variant: .success)
          WDBadge(label: Text(verbatim: "快到期"), variant: .warning)
          WDBadge(label: Text(verbatim: "已逾期"), variant: .danger)
        }
        HStack(spacing: WDSpacing.s3) {
          WDBadge(value: WDBadgeValue(count: 3))
          WDBadge(value: .dot)
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDBadge 六变体：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "badge-variants-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
