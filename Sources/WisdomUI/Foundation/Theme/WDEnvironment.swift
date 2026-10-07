import SwiftUI

/// 效果预算修饰符：把"只降不升"变成**结构性事实**（取字段级下界）。
private struct WDEffectsBudgetModifier: ViewModifier {
  let budget: WDEffectsBudget

  @Environment(\.wdEffectsBudget) private var current

  func body(content: Content) -> some View {
    content.environment(\.wdEffectsBudget, current.downgraded(to: budget))
  }
}

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

private struct WDEffectsBudgetKey: EnvironmentKey {
  static let defaultValue: WDEffectsBudget = .default
}

extension EnvironmentValues {
  /// 效果预算（组件**只读**；写入口只有本文件的修饰符，且只降不升 —— R18/DF-03）。
  public var wdEffectsBudget: WDEffectsBudget {
    get { self[WDEffectsBudgetKey.self] }
    set { self[WDEffectsBudgetKey.self] = newValue }
  }

  /// 外观输入的**只读派生**：从系统的 colorScheme / 高对比度 / 三个无障碍开关拼出来（不存第二份）。
  public var wdAppearance: WDAppearance {
    WDAppearance(
      colorScheme: colorScheme,
      contrast: colorSchemeContrast,
      reduceTransparency: accessibilityReduceTransparency,
      differentiateWithoutColor: accessibilityDifferentiateWithoutColor,
      reduceMotion: accessibilityReduceMotion
    )
  }
}

extension View {
  /// 调低效果预算（写入口；组件内不得调用 —— R18）。
  /// **只降不升**：与当前环境取字段级下界，想升会得到原值（机器保证，不靠自觉）。
  public func wdEffectsBudget(_ budget: WDEffectsBudget) -> some View {
    modifier(WDEffectsBudgetModifier(budget: budget))
  }

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
