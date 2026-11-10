import SwiftUI
import Testing
import WisdomUI

/// `WDCard` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 玻璃卡属于"玻璃类 6 个"之一 ⇒ 必须走 `UIHostingController` 渲染器（E6 显式表；
/// `ImageRenderer` 不渲染 `glassEffect`/`Material`）。
@MainActor
@Suite("WDCard 快照", .serialized)
struct WDCardSnapshotTests {
  static let canvas = CGSize(width: 360, height: 520)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDCard(style: .elevated) {
          VStack(alignment: .leading, spacing: WDSpacing.s3) {
            Text(verbatim: "本周家务")
              .wdFont(WDType.headline)
              .foregroundStyle(values.textPrimary)
            Text(verbatim: "已完成 3 项，共 5 项")
              .wdFont(WDType.footnote)
              .foregroundStyle(values.textSecondary)
          }
        }
        WDCard(style: .outlined) {
          Text(verbatim: "描边卡")
            .wdFont(WDType.body)
            .foregroundStyle(values.textPrimary)
        }
        WDCard(style: .glass) {
          Text(verbatim: "玻璃卡")
            .wdFont(WDType.body)
            .foregroundStyle(values.textPrimary)
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDCard：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verifyHierarchy(
        name: "card-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
