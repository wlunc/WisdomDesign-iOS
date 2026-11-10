import SwiftUI
import Testing

@testable import WisdomUI

/// 环境层（Theme/WDEnvironment）的四个只读键与四个写入口（R18 的唯一写入口）。
@MainActor
@Suite("环境写入口（WDEnvironment）")
struct WDEnvironmentTests {
  private final class Probe {
    var theme: WDTheme?
    var colors: WDColorValues?
    var budget: WDEffectsBudget?
    var density: WDLayoutDensity?
    var appearance: WDAppearance?
  }

  private struct ProbeView: View {
    @Environment(\.wdTheme) private var theme
    @Environment(\.wdColors) private var colors
    @Environment(\.wdEffectsBudget) private var budget
    @Environment(\.wdDensity) private var density
    @Environment(\.wdAppearance) private var appearance

    let probe: Probe

    var body: some View {
      probe.theme = theme
      probe.colors = colors
      probe.budget = budget
      probe.density = density
      probe.appearance = appearance
      return Color.clear
    }
  }

  private static func read<V: View>(_ configure: (AnyView) -> V = { $0 }) -> Probe {
    let probe = Probe()
    let view = configure(AnyView(ProbeView(probe: probe)))
    let renderer = ImageRenderer(content: view.frame(width: 8, height: 8))
    _ = renderer.uiImage
    return probe
  }

  @Test("默认值：default 主题 / light 槽位 / default 预算 / comfortable 密度")
  func defaults() {
    let probe = Self.read()
    #expect(probe.theme == .default)
    #expect(probe.colors == .light)
    #expect(probe.budget == .default)
    #expect(probe.density == .comfortable)
  }

  @Test("wdTheme 注入：theme 与只读派生 colors 同步")
  func themeInjection() {
    let probe = Self.read { $0.wdTheme(.dark) }
    #expect(probe.theme == .dark)
    #expect(probe.colors == .dark)
  }

  @Test("wdTheme(scheme:)：已生成 scheme 生效；未知 scheme 原样返回（不静默换肤）")
  func themeBySchemeName() {
    let dark = Self.read { $0.wdTheme(scheme: "dark") }
    #expect(dark.theme == .dark)
    #expect(dark.colors == .dark)

    let unknown = Self.read { $0.wdTheme(scheme: "nope") }
    #expect(unknown.theme == .default)
  }

  @Test("wdColors 只注入颜色：scheme 名回落到默认 scheme")
  func colorsInjection() {
    let probe = Self.read { $0.wdColors(.dark) }
    #expect(probe.colors == .dark)
    #expect(probe.theme?.scheme == WDColorValues.wdDefaultScheme)
  }

  @Test("wdEffectsBudget 只降不升：后续给更大预算仍保持更小值")
  func budgetOnlyDowngrades() {
    let probe = Self.read {
      $0.wdEffectsBudget(.default.reduced(blurSurfaces: 0))
        .wdEffectsBudget(.default)
    }
    #expect(probe.budget?.blurSurfaces == 0)
  }

  @Test("wdDensity 写入口生效")
  func densityInjection() {
    #expect(Self.read { $0.wdDensity(.compact) }.density == .compact)
    #expect(Self.read { $0.wdDensity(.comfortable) }.density == .comfortable)
  }

  @Test("wdAppearance 从系统 colorScheme 派生（其余三个开关是系统只读，不能注入）")
  func appearanceDerivation() {
    let dark = Self.read { $0.environment(\.colorScheme, .dark) }
    #expect(dark.appearance?.colorScheme == .dark)

    let light = Self.read { $0.environment(\.colorScheme, .light) }
    #expect(light.appearance?.colorScheme == .light)
    #expect(light.appearance?.reduceMotion == false)
  }
}
