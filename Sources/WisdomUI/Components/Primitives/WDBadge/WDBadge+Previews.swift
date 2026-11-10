#if WD_PREVIEWS
  import SwiftUI

  private struct WDBadgePreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "已完成"))
          WDBadge(label: Text(verbatim: "已逾期"))
          WDBadge(label: Text(verbatim: "进行中"))
        }
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "3"))
          WDBadge(label: Text(verbatim: "12"))
          WDBadge(label: Text(verbatim: "99"))
        }
        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "最大四个汉字"))
        }
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDBadge 浅色") {
    WDBadgePreviewHost()
  }

  #Preview("WDBadge 深色") {
    WDBadgePreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
