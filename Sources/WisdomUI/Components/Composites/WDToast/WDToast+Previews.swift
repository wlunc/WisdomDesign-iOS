#if WD_PREVIEWS
  import SwiftUI

  private struct WDToastPreviewHost: View {
    @State private var shown = true

    var body: some View {
      VStack(spacing: WDSpacing.s5) {
        Text(verbatim: "Toast")
          .wdFont(WDType.title2)
        WDButton(verbatim: "再次显示") { shown = true }
      }
      .padding(WDSpacing.s5)
      .wdToast(
        isPresented: $shown,
        variant: .success,
        message: Text(verbatim: "任务已保存")
      )
    }
  }

  #Preview("WDToast 浅色") {
    WDToastPreviewHost()
  }

  #Preview("WDToast 深色") {
    WDToastPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
