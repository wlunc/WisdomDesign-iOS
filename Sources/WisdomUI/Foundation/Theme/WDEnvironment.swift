import SwiftUI

/// 主题 Environment 的**唯一写入口**（I24b；R18 只允许本文件的 `View` 修饰符写它）。
///
/// `wdColors` 是 `wdTheme.colors` 的**只读派生**：不存第二份，所以"换主题"只有一条路径，
/// 不会出现两处状态不同步。

private struct WDThemeKey: EnvironmentKey {
  static let defaultValue: WDTheme = .default
}

extension EnvironmentValues {
  /// 当前主题（组件**只读**）。
  public var wdTheme: WDTheme {
    get { self[WDThemeKey.self] }
    set { self[WDThemeKey.self] = newValue }
  }

  /// 颜色槽位：`wdTheme.colors` 的**只读派生**（不存第二份）。
  public var wdColors: WDColorValues { wdTheme.colors }
}

extension View {
  /// 注入主题（写入口；组件内不得调用 —— R18）。
  public func wdTheme(_ theme: WDTheme) -> some View {
    environment(\.wdTheme, theme)
  }

  /// 按 scheme 名注入；名字不在已生成清单里时**原样返回**（不静默换成别的 scheme）。
  ///
  /// 用 `@ViewBuilder` 的条件分支而不是 `AnyView`：类型擦除被 R13a 禁（破坏 diff 与性能）。
  @ViewBuilder
  public func wdTheme(scheme: String) -> some View {
    if let theme = WDTheme.named(scheme) {
      environment(\.wdTheme, theme)
    } else {
      self
    }
  }

  /// 只给颜色槽位的实例级注入（**只允许预览/测试/demo**，SPEC §3.1 的优先级 ④）。
  public func wdColors(_ colors: WDColorValues) -> some View {
    environment(\.wdTheme, WDTheme(colors: colors))
  }
}
