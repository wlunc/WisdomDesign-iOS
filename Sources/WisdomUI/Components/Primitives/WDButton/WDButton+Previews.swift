#if WD_PREVIEWS
  import SwiftUI

  private struct WDButtonPreviewHost: View {
    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          HStack(spacing: WDSpacing.s3) {
            WDButton(verbatim: "提交") {}
            WDButton(verbatim: "分享", variant: .tonal, leadingIcon: .share) {}
          }
          HStack(spacing: WDSpacing.s3) {
            WDButton(verbatim: "继续", variant: .outline, trailingIcon: .disclose) {}
            WDButton(verbatim: "删除", variant: .destructive, leadingIcon: .delete) {}
          }
          HStack(spacing: WDSpacing.s3) {
            WDButton(verbatim: "小按钮", size: .sm) {}
            WDButton(verbatim: "大按钮", size: .lg) {}
          }
          HStack(spacing: WDSpacing.s3) {
            WDButton(
              verbatim: "提交", isLoading: true,
              loadingAccessibilityText: Text(verbatim: "处理中")
            ) {}
            WDButton(verbatim: "禁用") {}
              .disabled(true)
          }
        }
        .padding(WDSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  #Preview("WDButton 浅色") {
    WDButtonPreviewHost()
  }

  #Preview("WDButton 深色") {
    WDButtonPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
