#if WD_PREVIEWS
  import SwiftUI

  private struct WDSearchFieldPreviewHost: View {
    @State private var standard = "储物间"
    @State private var cancellable = "任务"

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDSearchField(
          text: $standard,
          placeholder: Text(verbatim: "搜索任务或成员"),
          clearAccessibilityLabel: Text(verbatim: "清除搜索内容")
        )
        WDSearchField(
          text: $cancellable,
          placeholder: Text(verbatim: "搜索任务或成员"),
          clearAccessibilityLabel: Text(verbatim: "清除搜索内容"),
          cancelLabel: Text(verbatim: "取消")
        )
        WDSearchField(
          text: .constant(""),
          placeholder: Text(verbatim: "搜索任务或成员"),
          clearAccessibilityLabel: Text(verbatim: "清除搜索内容")
        )
        .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDSearchField 浅色") {
    WDSearchFieldPreviewHost()
  }

  #Preview("WDSearchField 深色") {
    WDSearchFieldPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
