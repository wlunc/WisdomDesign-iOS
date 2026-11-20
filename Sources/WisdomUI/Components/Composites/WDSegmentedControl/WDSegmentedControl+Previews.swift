#if WD_PREVIEWS
  import SwiftUI

  private struct WDSegmentedControlPreviewHost: View {
    @State private var solid = "today"
    @State private var glass = "week"

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDSegmentedControl(
          items: [
            .init(id: "today", label: Text(verbatim: "今天")),
            .init(id: "week", label: Text(verbatim: "本周")),
            .init(id: "all", label: Text(verbatim: "全部")),
          ],
          selection: $solid
        )
        WDSegmentedControl(
          items: [
            .init(id: "today", label: Text(verbatim: "今天")),
            .init(id: "week", label: Text(verbatim: "本周")),
          ],
          selection: $glass,
          style: .glass
        )
        WDSegmentedControl(
          items: [
            .init(id: "a", label: Text(verbatim: "甲")),
            .init(id: "b", label: Text(verbatim: "乙")),
          ],
          selection: .constant("a")
        )
        .disabled(true)
        // 位置文案（L-B 注入点）：措辞与分隔符都由调用方给，库内不拼任何字。
        // 评审 F7：本项此前在预览/demo 里零调用点 ⇒ 读屏位置文案从未被目视核对过。
        WDSegmentedControl(
          items: [
            .init(id: "today", label: Text(verbatim: "今天")),
            .init(id: "week", label: Text(verbatim: "本周")),
            .init(id: "all", label: Text(verbatim: "全部")),
          ],
          selection: $solid,
          positionText: { index, total in Text(verbatim: "\(index)/\(total)") },
          positionSeparator: Text(verbatim: "，")
        )
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDSegmentedControl 浅色") {
    WDSegmentedControlPreviewHost()
  }

  #Preview("WDSegmentedControl 深色") {
    WDSegmentedControlPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
