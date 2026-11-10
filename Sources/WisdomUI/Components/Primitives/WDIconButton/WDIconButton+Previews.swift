#if WD_PREVIEWS
  import SwiftUI

  private struct WDIconButtonPreviewHost: View {
    var body: some View {
      HStack(spacing: WDSpacing.s4) {
        WDIconButton(icon: .add, accessibilityLabel: Text(verbatim: "新增"), size: .sm) {}
        WDIconButton(icon: .search, accessibilityLabel: Text(verbatim: "搜索")) {}
        WDIconButton(icon: .more, accessibilityLabel: Text(verbatim: "更多"), size: .lg) {}
        WDIconButton(
          icon: .share, accessibilityLabel: Text(verbatim: "分享"), isLoading: true
        ) {}
        WDIconButton(icon: .delete, accessibilityLabel: Text(verbatim: "删除")) {}
          .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDIconButton 浅色") {
    WDIconButtonPreviewHost()
  }

  #Preview("WDIconButton 深色") {
    WDIconButtonPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
