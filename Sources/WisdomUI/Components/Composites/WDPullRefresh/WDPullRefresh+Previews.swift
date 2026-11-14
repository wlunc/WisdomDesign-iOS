#if WD_PREVIEWS
  import SwiftUI

  private struct WDPullRefreshPreviewHost: View {
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
      .wdPullRefresh(
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

  #Preview("WDPullRefresh 浅色") {
    WDPullRefreshPreviewHost()
  }

  #Preview("WDPullRefresh 深色") {
    WDPullRefreshPreviewHost()
      .preferredColorScheme(.dark)
  }

  #Preview("WDPullRefresh 环三态（进度 / 完整 / 刷新中）") {
    HStack(spacing: WDSpacing.s7) {
      WDPullRefreshRing(progress: 0.35, isRefreshing: false, isSpinning: false)
      WDPullRefreshRing(progress: 1, isRefreshing: false, isSpinning: false)
      WDPullRefreshRing(progress: 1, isRefreshing: true, isSpinning: true)
    }
    .padding(WDSpacing.s6)
  }
#endif
