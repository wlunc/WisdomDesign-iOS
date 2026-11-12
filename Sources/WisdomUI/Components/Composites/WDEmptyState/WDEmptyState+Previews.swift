#if WD_PREVIEWS
  import SwiftUI

  private struct WDEmptyStatePreviewHost: View {
    var body: some View {
      VStack(spacing: WDSpacing.s7) {
        WDEmptyState(
          icon: .task,
          title: Text(verbatim: "还没有任务"),
          message: Text(verbatim: "新建第一个任务，把要做的事记下来。"),
          action: .init(label: Text(verbatim: "新建第一个任务"), action: {})
        )
        WDEmptyState(
          icon: .offline,
          title: Text(verbatim: "加载失败"),
          message: Text(verbatim: "检查网络后重试。"),
          action: .init(label: Text(verbatim: "重试"), isLoading: true, action: {})
        )
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDEmptyState 浅色") {
    WDEmptyStatePreviewHost()
  }

  #Preview("WDEmptyState 深色") {
    WDEmptyStatePreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
