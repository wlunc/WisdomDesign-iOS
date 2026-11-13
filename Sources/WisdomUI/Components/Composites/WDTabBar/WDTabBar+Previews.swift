#if WD_PREVIEWS
  import SwiftUI

  private struct WDTabBarPreviewHost: View {
    @State private var selected = "today"

    var body: some View {
      VStack {
        Spacer()
        WDTabBar(
          items: [
            .init(id: "today", icon: .home, label: Text(verbatim: "今天")),
            .init(
              id: "tasks", icon: .todo, label: Text(verbatim: "任务"),
              badge: WDBadgeValue(count: 3)),
            .init(id: "family", icon: .members, label: Text(verbatim: "家庭")),
            .init(id: "me", icon: .profile, label: Text(verbatim: "我的")),
          ],
          selection: $selected
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(WDColor.bgGrouped)
    }
  }

  #Preview("WDTabBar 浅色") {
    WDTabBarPreviewHost()
  }

  #Preview("WDTabBar 深色") {
    WDTabBarPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
