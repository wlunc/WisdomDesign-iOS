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

/// 布局密度的环境键（组件只读；写入口 = 本文件的 `.wdDensity(_:)`，R18）。
private struct WDLayoutDensityKey: EnvironmentKey {
  static let defaultValue: WDLayoutDensity = .comfortable
}

extension EnvironmentValues {
  /// 当前布局密度档（组件**只读**；默认 `comfortable`，设计 09-layout §4）。
  public var wdDensity: WDLayoutDensity {
    get { self[WDLayoutDensityKey.self] }
    set { self[WDLayoutDensityKey.self] = newValue }
  }
}

private struct WDInstantMotionKey: EnvironmentKey {
  static let defaultValue = false
}

private struct WDEffectsBudgetKey: EnvironmentKey {
  static let defaultValue: WDEffectsBudget = .default
}

extension EnvironmentValues {
  /// 快照/预览专用：跳过入场动画与延迟（**内部**，不是公开 API；组件只读，测试注入）。
  var wdInstantMotion: Bool {
    get { self[WDInstantMotionKey.self] }
    set { self[WDInstantMotionKey.self] = newValue }
  }

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
  /// 注入布局密度（写入口；组件内不得调用 —— R18）。
  ///
  /// 只影响"下限"（行高一类），不改变字号（设计 09-layout §4：compact 不让文字变小）。
  public func wdDensity(_ density: WDLayoutDensity) -> some View {
    environment(\.wdDensity, density)
  }

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

// MARK: - B10–B16 接线面（播报通道 / 滚动量 / 读屏焦点）

/// 播报通道环境键（B10–B16 的 L-B 注入点：组件只读，写入口 = `.wdAnnouncer(_:)`）。
private struct WDAnnouncerKey: EnvironmentKey {
  static let defaultValue: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)? = nil
}

/// 宿主纵向滚动量环境键（组件只读；写入口 = `.wdScrollOffsetY(_:)`）。nil = 不联动。
private struct WDScrollOffsetKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

// B18：读屏焦点不再走环境键（`accessibilityRepresentation` 内部写的环境不会回传到宿主视图），
// 改为 `Internal/A11y/WDFocusRing.swift` 的 `WDAccessibilityFocusHost` 用 Binding 回写。

extension EnvironmentValues {
  /// 播报通道（组件**只读**）。nil = 不播报。
  ///
  /// 形态是 `@MainActor @Sendable` 闭包（不是 `WDTextPlayback` 这类内部类型）：
  /// 环境值要能装进 `Sendable`，且公开属性的类型必须是 public。
  public var wdAnnouncerText: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)? {
    get { self[WDAnnouncerKey.self] }
    set { self[WDAnnouncerKey.self] = newValue }
  }

  /// 宿主纵向滚动量（pt；向下滚为正）。**nil = 不联动**（默认）。
  public var wdScrollOffsetY: CGFloat? {
    get { self[WDScrollOffsetKey.self] }
    set { self[WDScrollOffsetKey.self] = newValue }
  }

}

extension View {
  /// 注入播报通道（写入口；组件内不得调用 —— R18）。nil = 不播报。
  public func wdAnnouncer(
    _ announcer: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?
  ) -> some View {
    environment(\.wdAnnouncerText, announcer)
  }

  /// 注入纵向滚动量（写入口；组件内不得调用 —— R18）。
  ///
  /// 调用方从 `ScrollView` 的 `.onScrollGeometryChange` 取 `contentOffset.y` 喂进来；
  /// `WDFAB` / `WDTabBar` / `WDNavigationBar` 只读它做滚动联动。
  public func wdScrollOffsetY(_ offset: CGFloat?) -> some View {
    environment(\.wdScrollOffsetY, offset)
  }
}
