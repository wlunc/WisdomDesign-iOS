#if WD_PREVIEWS
  import SwiftUI

  private struct WDCardPreviewHost: View {
    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          WDCard(style: .elevated) {
            VStack(alignment: .leading, spacing: WDSpacing.s3) {
              Text(verbatim: "本周家务")
                .wdFont(WDType.headline)
              Text(verbatim: "已完成 3 项，共 5 项")
                .wdFont(WDType.footnote)
                .foregroundStyle(.secondary)
            }
          }
          WDCard(style: .outlined) {
            Text(verbatim: "描边卡")
              .wdFont(WDType.body)
          }
          WDCard(style: .glass) {
            Text(verbatim: "玻璃卡")
              .wdFont(WDType.body)
          }
        }
        .padding(WDSpacing.s5)
      }
    }
  }

  #Preview("WDCard 浅色") {
    WDCardPreviewHost()
  }

  #Preview("WDCard 深色") {
    WDCardPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
