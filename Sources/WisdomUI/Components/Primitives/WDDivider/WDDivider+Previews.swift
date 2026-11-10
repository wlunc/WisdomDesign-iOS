#if WD_PREVIEWS
  import SwiftUI

  private struct WDDividerPreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        Text(verbatim: "全宽")
          .wdFont(WDType.caption1)
          .foregroundStyle(.secondary)
        WDDivider()
        Text(verbatim: "上下留 space.4")
          .wdFont(WDType.caption1)
          .foregroundStyle(.secondary)
        WDDivider()
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDDivider 浅色") {
    WDDividerPreviewHost()
  }

  #Preview("WDDivider 深色") {
    WDDividerPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
