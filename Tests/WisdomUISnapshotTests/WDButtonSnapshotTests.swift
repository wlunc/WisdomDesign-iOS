import SwiftUI
import Testing
import WisdomUI

/// `WDButton` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 加载态含系统 `ProgressView` ⇒ 用 `UIHostingController` 渲染器（与 WDIconButton 同因）。
@MainActor
@Suite("WDButton 快照", .serialized)
struct WDButtonSnapshotTests {
  static let canvas = CGSize(width: 360, height: 520)

  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s3) {
          WDButton(verbatim: "提交") {}
          WDButton(verbatim: "分享", variant: .tonal, leadingIcon: .share) {}
        }
        HStack(spacing: WDSpacing.s3) {
          WDButton(verbatim: "继续", variant: .outline, trailingIcon: .disclose) {}
          WDButton(verbatim: "删除", variant: .destructive, leadingIcon: .delete) {}
        }
        HStack(spacing: WDSpacing.s3) {
          WDButton(verbatim: "小", size: .sm) {}
          WDButton(verbatim: "大按钮", size: .lg) {}
        }
        HStack(spacing: WDSpacing.s3) {
          WDButton(
            verbatim: "提交", isLoading: true,
            loadingAccessibilityText: Text(verbatim: "处理中")
          ) {}
          WDButton(verbatim: "禁用") {}
            .disabled(true)
        }
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDButton：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verifyHierarchy(
        name: "button-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
