#if WD_PREVIEWS
  import SwiftUI

  private struct WDAvatarPreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "妈")))
          WDAvatar(value: .init(label: Text(verbatim: "明")))
          WDAvatar(value: .init(label: Text(verbatim: "A")))
          WDAvatar(value: .init(icon: .profile))
          WDAvatar(value: .init(icon: .unassigned))
        }
        HStack(spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "林")))
          WDAvatar(value: .init(label: Text(verbatim: "B")))
        }
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDAvatar 浅色") {
    WDAvatarPreviewHost()
  }

  #Preview("WDAvatar 深色") {
    WDAvatarPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
