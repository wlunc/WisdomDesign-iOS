import SwiftUI
import Testing
import WisdomUI

/// `WDIconButton` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 加载态含系统 `ProgressView`（UIKit 接管）⇒ 用 `UIHostingController` 渲染器（ImageRenderer 会出占位图）。
@MainActor
@Suite("WDIconButton 快照", .serialized)
struct WDIconButtonSnapshotTests {
  static let canvas = CGSize(width: 360, height: 200)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s4) {
          WDIconButton(icon: .add, accessibilityLabel: Text(verbatim: "新增"), size: .sm) {}
          WDIconButton(icon: .search, accessibilityLabel: Text(verbatim: "搜索")) {}
          WDIconButton(icon: .more, accessibilityLabel: Text(verbatim: "更多"), size: .lg) {}
        }
        HStack(spacing: WDSpacing.s4) {
          WDIconButton(
            icon: .share, accessibilityLabel: Text(verbatim: "分享"), isLoading: true
          ) {}
          WDIconButton(icon: .delete, accessibilityLabel: Text(verbatim: "删除")) {}
            .disabled(true)
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDIconButton：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verifyHierarchy(
        name: "iconbutton-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
