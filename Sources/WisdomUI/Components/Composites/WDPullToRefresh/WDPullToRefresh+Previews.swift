#if WD_PREVIEWS
  import SwiftUI

  private struct WDPullToRefreshPreviewHost: View {
    @State private var isRefreshing = false
    @State private var rows = Array(1...8)

    var body: some View {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(rows, id: \.self) { row in
            WDTagRow(title: Text(verbatim: "第 \(row) 条动态"))
          }
        }
      }
      .wdPullToRefresh(
        isRefreshing: $isRefreshing,
        label: Text(verbatim: "刷新")
      ) {
        try? await Task.sleep(for: .seconds(1))
        rows = Array(1...8).shuffled()
      }
    }
  }

  private struct WDTagRow: View {
    let title: Text

    var body: some View {
      title
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WDSpacing.s5)
    }
  }

  #Preview("WDPullToRefresh 浅色") {
    WDPullToRefreshPreviewHost()
  }

  #Preview("WDPullToRefresh 深色") {
    WDPullToRefreshPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
