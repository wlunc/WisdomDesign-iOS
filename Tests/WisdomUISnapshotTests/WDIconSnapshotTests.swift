import SwiftUI
import Testing
import WisdomUI

/// `WDIcon` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 取 12 条代表性语义名 × 四档尺寸：足以暴露"符号缺失/尺寸映射错位/颜色没跟主题"三类回归，
/// 又不会把基线做成 44 行的大图。完整 44 条的存在性由 `WDIconNameTests` 钉住。
@MainActor
@Suite("WDIcon 快照", .serialized)
struct WDIconSnapshotTests {
  static let canvas = CGSize(width: 360, height: 560)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        ForEach(Array(WDIconName.allCases.prefix(12)), id: \.self) { name in
          HStack(spacing: WDSpacing.s5) {
            WDIcon(icon: name, size: .sm)
            WDIcon(icon: name, size: .md)
            WDIcon(icon: name, size: .lg)
            WDIcon(icon: name, size: .xl)
            Text(verbatim: name.rawValue)
              .wdFont(WDType.footnote)
              .wdLineBox(WDType.footnote)
              .foregroundStyle(.secondary)
            Spacer(minLength: 0)
          }
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(values.textPrimary)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDIcon：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "icon-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
