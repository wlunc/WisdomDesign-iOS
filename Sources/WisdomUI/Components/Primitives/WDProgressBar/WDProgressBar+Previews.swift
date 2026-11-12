#if WD_PREVIEWS
  import SwiftUI

  private struct WDProgressBarPreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDProgressBar(
          value: 0.45,
          label: Text(verbatim: "上传进度"),
          valueText: Text(verbatim: "45%")
        )
        WDProgressBar(
          value: 1,
          label: Text(verbatim: "整理储物间"),
          valueText: Text(verbatim: "100%")
        )
        WDProgressBar(label: Text(verbatim: "加载中"))
        WDProgressBar(value: 0, label: Text(verbatim: "0%"))
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDProgressBar 浅色") {
    WDProgressBarPreviewHost()
  }

  #Preview("WDProgressBar 深色") {
    WDProgressBarPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
