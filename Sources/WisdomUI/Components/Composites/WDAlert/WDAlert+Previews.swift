#if WD_PREVIEWS
  import SwiftUI

  private struct WDAlertPreviewHost: View {
    @State private var basic = true
    @State private var input = false

    var body: some View {
      VStack(spacing: WDSpacing.s5) {
        Text(verbatim: "Alert")
          .wdFont(WDType.title2)
        WDButton(verbatim: "带输入") { input = true }
      }
      .padding(WDSpacing.s5)
      .wdAlert(
        isPresented: $basic,
        title: Text(verbatim: "删除这条任务？"),
        message: Text(verbatim: "删除后无法恢复，其他成员也看不到了。"),
        actions: [
          .init(label: Text(verbatim: "取消"), role: .cancel, action: {}),
          .init(label: Text(verbatim: "删除"), role: .destructive, action: {}),
        ]
      )
      .wdAlert(
        isPresented: $input,
        title: Text(verbatim: "重命名"),
        message: Text(verbatim: "给任务起一个新名字。"),
        actions: [
          .init(label: Text(verbatim: "取消"), role: .cancel, action: {}),
          .init(label: Text(verbatim: "保存"), action: {}),
        ]
      ) {
        Text(verbatim: "输入区域")
      }
    }
  }

  #Preview("WDAlert 浅色") {
    WDAlertPreviewHost()
  }

  #Preview("WDAlert 深色") {
    WDAlertPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
