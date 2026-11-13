#if WD_PREVIEWS
  import SwiftUI

  private struct WDNavigationBarPreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDNavigationBar(
          title: Text(verbatim: "家庭"),
          backAccessibilityLabel: Text(verbatim: "返回家庭列表"),
          actions: [
            .init(
              id: "edit", icon: .edit, accessibilityLabel: Text(verbatim: "编辑"),
              action: {})
          ]
        )
        WDNavigationBar(title: Text(verbatim: "任务"), style: .glass)
        WDNavigationBar(title: Text(verbatim: "本周家务"), mode: .largeTitle)
      }
      .padding(WDSpacing.s5)
      .background(WDColor.bgGrouped)
    }
  }

  #Preview("WDNavigationBar 浅色") {
    WDNavigationBarPreviewHost()
  }

  #Preview("WDNavigationBar 深色") {
    WDNavigationBarPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
