#if WD_PREVIEWS
  import SwiftUI

  private struct WDAvatarStackPreviewHost: View {
    private let six: [WDAvatarStackItem] = [
      .init(id: "me", avatar: WDAvatarValue(label: Text(verbatim: "我"))),
      .init(id: "mom", avatar: WDAvatarValue(label: Text(verbatim: "妈"))),
      .init(id: "dad", avatar: WDAvatarValue(label: Text(verbatim: "爸"))),
      .init(id: "sis", avatar: WDAvatarValue(label: Text(verbatim: "妹"))),
      .init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "甲"))),
      .init(id: "b", avatar: WDAvatarValue(label: Text(verbatim: "乙"))),
    ]

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDAvatarStack(items: six, accessibilityLabel: Text(verbatim: "家庭成员 6 人"))
        WDAvatarStack(items: six, accessibilityLabel: Text(verbatim: "家庭成员 6 人"), size: .sm)
        WDAvatarStack(items: Array(six.prefix(2)), accessibilityLabel: Text(verbatim: "家庭成员 2 人"))
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDAvatarStack 浅色") {
    WDAvatarStackPreviewHost()
  }

  #Preview("WDAvatarStack 深色") {
    WDAvatarStackPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
