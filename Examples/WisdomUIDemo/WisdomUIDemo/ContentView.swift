import SwiftUI
import WisdomUI

/// demo 根视图：组件目录为入口，主题/令牌与审计视口放到二级页面。
///
/// 主题仍然使用运行时 scheme（M1 交付物 / F-05）：切换的是已经生成的那几套，
/// 值变化触发依赖该值的视图重算，不重启进程。
struct DemoRootView: View {
  @State private var scheme = WDColorValues.wdDefaultScheme

  private var theme: WDTheme {
    WDTheme.named(scheme) ?? .default
  }

  var body: some View {
    NavigationStack {
      DemoComponentListView(scheme: $scheme)
        .navigationDestination(for: DemoComponentEntry.self) { component in
          DemoComponentDetailView(component: component)
        }
    }
    .wdTheme(theme)
    .tint(theme.colors.textBrand)
    .preferredColorScheme(scheme == "dark" ? .dark : .light)
  }
}
