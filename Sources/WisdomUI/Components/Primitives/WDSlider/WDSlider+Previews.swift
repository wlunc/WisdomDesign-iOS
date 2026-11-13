#if WD_PREVIEWS
  import SwiftUI

  private struct WDSliderPreviewHost: View {
    @State private var progress = 0.62
    @State private var discrete = 2.0
    @State private var disabled = 0.8

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDSlider(value: $progress, label: Text(verbatim: "完成度"))
        WDSlider(value: $discrete, label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1)
        WDSlider(value: $disabled, label: Text(verbatim: "禁用"))
          .disabled(true)
      }
      .padding(WDSpacing.s5)
      .frame(width: 320)
    }
  }

  #Preview("WDSlider 浅色") {
    WDSliderPreviewHost()
  }

  #Preview("WDSlider 深色") {
    WDSliderPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
