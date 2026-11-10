#if WD_PREVIEWS
  import SwiftUI

  /// 预览宿主：44 条语义名 × 四档尺寸（16/20/24/28），逐条给名字便于与契约对照。
  private struct WDIconPreviewHost: View {
    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          ForEach(WDIconName.allCases, id: \.self) { name in
            HStack(spacing: WDSpacing.s4) {
              WDIcon(icon: name, size: .sm)
              WDIcon(icon: name, size: .md)
              WDIcon(icon: name, size: .lg)
              WDIcon(icon: name, size: .xl)
              Text(verbatim: name.rawValue)
                .wdFont(WDType.footnote)
                .foregroundStyle(.secondary)
              Spacer(minLength: 0)
            }
          }
        }
        .padding(WDSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  #Preview("WDIcon 44 条 × 四档") {
    WDIconPreviewHost()
  }

  #Preview("WDIcon 深色") {
    WDIconPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
