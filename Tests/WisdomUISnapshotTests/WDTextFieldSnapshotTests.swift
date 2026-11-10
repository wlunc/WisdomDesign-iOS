import SwiftUI
import Testing
import WisdomUI

/// `WDTextField` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 渲染器 = `UIHostingController` + `drawHierarchy`（`ImageRenderer` 不渲染 `TextField` 的 UIKit 内容）。
/// 覆盖：三变体、前缀/附件、错误态、只读、禁用 —— 一屏看全五状态与三档变体。
@MainActor
@Suite("WDTextField 快照", .serialized)
struct WDTextFieldSnapshotTests {
  private struct Sample: View {
    let values: WDColorValues
    @State private var text = "整理储物间"

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDTextField(
          text: $text,
          label: Text(verbatim: "任务名称"),
          appearance: .init(placeholder: Text(verbatim: "例如 打扫阳台"))
        )

        WDTextField(
          text: $text,
          label: Text(verbatim: "日期"),
          appearance: .init(
            variant: .outline,
            prefix: .icon(.calendar),
            accessory: .clear(accessibilityLabel: Text(verbatim: "清除内容"))
          )
        )

        WDTextField(
          text: $text,
          label: Text(verbatim: "预算"),
          appearance: .init(
            variant: .glass,
            prefix: .text(Text(verbatim: "USD")),
            accessory: .unit(Text(verbatim: "100"))
          )
        )

        WDTextField(
          text: $text,
          label: Text(verbatim: "任务名称"),
          appearance: .init(
            accessory: .count(current: 9, limit: 10),
            helper: .error(Text(verbatim: "名称已被占用"))
          )
        )

        WDTextField(
          text: .constant("只读内容"),
          label: Text(verbatim: "只读"),
          appearance: .init(variant: .outline),
          isEditable: false
        )

        WDTextField(text: $text, label: Text(verbatim: "禁用"))
          .disabled(true)
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(values.textPrimary)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDTextField：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      // AX3 的内容更高（字段盒随行盒撑开）：画布按档位分两档，避免把禁用态裁掉。
      let canvas = CGSize(width: 360, height: state.typeSize == .ax3 ? 760 : 520)
      SnapshotSupport.verifyHierarchy(
        name: "textfield-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: canvas
      )
    }
  }
}
