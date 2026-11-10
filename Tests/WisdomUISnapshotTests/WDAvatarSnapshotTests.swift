import SwiftUI
import Testing
import WisdomUI

/// `WDAvatar` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 直径与首字号按设计固定（不随动态字体放大）⇒ AX3 态应与默认态同尺寸，快照是这条"例外"的回归网。
@MainActor
@Suite("WDAvatar 快照", .serialized)
struct WDAvatarSnapshotTests {
  static let canvas = CGSize(width: 360, height: 200)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "妈")))
          WDAvatar(value: .init(label: Text(verbatim: "明")))
          WDAvatar(value: .init(label: Text(verbatim: "A")))
          WDAvatar(value: .init(icon: .profile))
        }
        HStack(spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "林")))
          WDAvatar(value: .init(icon: .unassigned))
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDAvatar：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "avatar-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
