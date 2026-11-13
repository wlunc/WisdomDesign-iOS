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
