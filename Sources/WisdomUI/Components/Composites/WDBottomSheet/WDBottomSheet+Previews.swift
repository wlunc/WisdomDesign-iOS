#if WD_PREVIEWS
  import SwiftUI

  private struct WDBottomSheetPreviewHost: View {
    @State private var shown = true

    var body: some View {
      VStack(spacing: WDSpacing.s5) {
        Text(verbatim: "BottomSheet")
          .wdFont(WDType.title2)
        WDButton(verbatim: "打开面板") { shown = true }
      }
      .padding(WDSpacing.s5)
      .wdSheet(
        isPresented: $shown,
        detents: .all,
        initialDetent: .half,
        title: Text(verbatim: "选择成员"),
        closeButtonAccessibilityLabel: Text(verbatim: "关闭成员选择")
      ) {
        Text(verbatim: "面板内容")
          .wdFont(WDType.body)
          .padding(.vertical, WDSpacing.s5)
      } footer: {
        WDButton(verbatim: "完成") { shown = false }
      }
    }
  }

  #Preview("WDBottomSheet 浅色") {
    WDBottomSheetPreviewHost()
  }

  #Preview("WDBottomSheet 深色") {
    WDBottomSheetPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
