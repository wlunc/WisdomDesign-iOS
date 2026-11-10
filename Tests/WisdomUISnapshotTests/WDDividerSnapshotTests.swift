import SwiftUI
import Testing
import WisdomUI

/// `WDDivider` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 分割线本身极简（1pt hairline），快照的价值在于：颜色是否跟主题、宽度是否吃满、RTL 下是否稳定。
@MainActor
@Suite("WDDivider 快照", .serialized)
struct WDDividerSnapshotTests {
  static let canvas = CGSize(width: 360, height: 320)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        Text(verbatim: "全宽档")
          .wdFont(WDType.caption1)
          .foregroundStyle(values.textSecondary)
        WDDivider()
        Text(verbatim: "列表行之间")
          .wdFont(WDType.body)
          .foregroundStyle(values.textPrimary)
        WDDivider()
        Text(verbatim: "卡片内分区")
          .wdFont(WDType.body)
          .foregroundStyle(values.textPrimary)
        WDDivider()
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDDivider：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "divider-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
