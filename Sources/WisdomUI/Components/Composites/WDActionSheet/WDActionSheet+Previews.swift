#if WD_PREVIEWS
  import SwiftUI

  private struct WDActionSheetPreviewHost: View {
    @State private var shown = true

    var body: some View {
      VStack(spacing: WDSpacing.s5) {
        Text(verbatim: "ActionSheet")
          .wdFont(WDType.title2)
        WDButton(verbatim: "打开操作表") { shown = true }
      }
      .padding(WDSpacing.s5)
      .wdActionSheet(
        isPresented: $shown,
        title: Text(verbatim: "任务操作"),
        message: Text(verbatim: "选择要执行的操作。"),
        items: [
          .init(id: "share", label: Text(verbatim: "分享")),
          .init(id: "delete", label: Text(verbatim: "删除"), role: .destructive),
          .init(id: "cancel", label: Text(verbatim: "取消"), role: .cancel),
        ],
        onSelect: { _ in },
        onCancel: {}
      )
    }
  }

  #Preview("WDActionSheet 浅色") {
    WDActionSheetPreviewHost()
  }

  #Preview("WDActionSheet 深色") {
    WDActionSheetPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
