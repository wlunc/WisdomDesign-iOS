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
        HStack(alignment: .bottom, spacing: WDSpacing.s4) {
          ForEach(WDAvatarSize.allCases, id: \.self) { size in
            WDAvatar(value: .init(label: Text(verbatim: "妈")), size: size)
          }
        }
        HStack(alignment: .bottom, spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "林")), size: .lg, isOnline: true)
          WDAvatar(value: .init(label: Text(verbatim: "B")), size: .lg, isDisabled: true)
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
