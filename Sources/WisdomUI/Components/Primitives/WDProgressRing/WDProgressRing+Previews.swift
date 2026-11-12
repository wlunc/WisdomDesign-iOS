#if WD_PREVIEWS
  import SwiftUI

  private struct WDProgressRingPreviewHost: View {
    var body: some View {
      HStack(alignment: .top, spacing: WDSpacing.s7) {
        WDProgressRing(
          value: 0.6,
          label: Text(verbatim: "本周家务"),
          valueText: Text(verbatim: "3/5")
        )
        WDProgressRing(
          value: 0.45,
          size: .compact,
          label: Text(verbatim: "紧凑"),
          valueText: Text(verbatim: "45%")
        )
        WDProgressRing(value: 1, label: Text(verbatim: "完成"))
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDProgressRing 浅色") {
    WDProgressRingPreviewHost()
  }

  #Preview("WDProgressRing 深色") {
    WDProgressRingPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
