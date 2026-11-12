#if WD_PREVIEWS
  import SwiftUI

  private struct WDSkeletonPreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDSkeleton(variant: .text, lineCount: 4, accessibilityLabel: Text(verbatim: "加载中"))
        WDSkeleton(variant: .list, accessibilityLabel: Text(verbatim: "加载中"))
        WDSkeleton(variant: .card, accessibilityLabel: Text(verbatim: "加载中"))
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDSkeleton 浅色") {
    WDSkeletonPreviewHost()
  }

  #Preview("WDSkeleton 深色") {
    WDSkeletonPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
