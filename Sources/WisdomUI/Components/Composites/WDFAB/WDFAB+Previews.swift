#if WD_PREVIEWS
  import SwiftUI

  private struct WDFABPreviewHost: View {
    var body: some View {
      HStack(alignment: .bottom, spacing: WDSpacing.s5) {
        WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .small)
        WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"))
        WDFAB(
          icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .large,
          shape: .circle)
        WDFAB(
          icon: .add, accessibilityLabel: Text(verbatim: "新建任务"),
          actions: [
            .init(id: "task", icon: .task, label: Text(verbatim: "任务"), action: {}),
            .init(id: "chore", icon: .chore, label: Text(verbatim: "家务"), action: {}),
          ]
        )
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDFAB 浅色") {
    WDFABPreviewHost()
  }

  #Preview("WDFAB 深色") {
    WDFABPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
