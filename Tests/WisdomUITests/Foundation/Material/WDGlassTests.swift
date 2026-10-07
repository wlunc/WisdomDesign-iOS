import SwiftUI
import Testing
import WisdomUI

/// 玻璃档位解析（U10 / DF-02 / O-9 / DF-10）—— M1 的"三件套"首轮参数化骨架。
///
/// 两条**必须红**的用例（AGENTS §12.1 的四条硬规则）：
///   ① 深色 + `glass` + **任意**文字级别 ⇒ 不得返回 `glass`；
///   ② 浅色 + `glass` + `secondary`/`tertiary` ⇒ 不得返回 `glass`。
@MainActor
@Suite("玻璃档位解析 U10")
struct WDGlassTests {
  static let capable = WDGlassCapabilities(supportsGlass: true)
  static let legacy = WDGlassCapabilities(supportsGlass: false)

  static func appearance(
    _ scheme: ColorScheme,
    contrast: ColorSchemeContrast = .standard,
    reduceTransparency: Bool = false
  ) -> WDAppearance {
    WDAppearance(
      colorScheme: scheme,
      contrast: contrast,
      reduceTransparency: reduceTransparency,
      differentiateWithoutColor: false,
      reduceMotion: false
    )
  }

  static let schemes: [ColorScheme] = [.light, .dark]

  @Test("浅色：primary 上 glass，secondary/tertiary 升到 glassStrong")
  func lightMatrix() {
    for textLevel in WDTextLevel.allCases {
      let result = WDGlass.resolve(
        textLevel: textLevel,
        appearance: Self.appearance(.light),
        capabilities: Self.capable,
        budget: .default
      )
      let expected: WDGlassResolution = textLevel == .primary ? .glass : .glassStrong
      #expect(result == expected, "浅色/\(textLevel.rawValue)：\(result) ≠ \(expected)")
    }
  }

  @Test("【必须红】深色 + 任意文字级别 ⇒ 不得返回 glass")
  func darkNeverReturnsGlass() {
    for textLevel in WDTextLevel.allCases {
      let result = WDGlass.resolve(
        textLevel: textLevel,
        appearance: Self.appearance(.dark),
        capabilities: Self.capable,
        budget: .default
      )
      #expect(
        result != .glass, "深色/\(textLevel.rawValue) 返回了 glass —— 规则 2 破了（深色端零字阶不上 surface.glass）")
      #expect(
        result == (textLevel == .primary ? .glassStrong : .opaque),
        "深色/\(textLevel.rawValue)：\(result)")
    }
  }

  @Test("【必须红】浅色 + glass 语义 + secondary/tertiary ⇒ 不得返回 glass")
  func lightGlassOnlyCarriesPrimary() {
    for textLevel in [WDTextLevel.secondary, .tertiary] {
      let result = WDGlass.resolve(
        textLevel: textLevel,
        appearance: Self.appearance(.light),
        capabilities: Self.capable,
        budget: .default,
        level: .regular
      )
      #expect(result != .glass, "浅色 + regular + \(textLevel.rawValue) 返回了 glass —— 规则 1 破了")
    }
  }

  @Test("系统无障碍设置优先：reduceTransparency / increased ⇒ opaque（O-9 第 1 条）")
  func accessibilityOverrides() {
    for scheme in Self.schemes {
      for textLevel in WDTextLevel.allCases {
        let reduced = WDGlass.resolve(
          textLevel: textLevel,
          appearance: Self.appearance(scheme, reduceTransparency: true),
          capabilities: Self.capable,
          budget: .default
        )
        #expect(reduced == .opaque, "降低透明度未生效：\(scheme)/\(textLevel.rawValue)")
        let high = WDGlass.resolve(
          textLevel: textLevel,
          appearance: Self.appearance(scheme, contrast: .increased),
          capabilities: Self.capable,
          budget: .default
        )
        #expect(high == .opaque, "高对比度未生效：\(scheme)/\(textLevel.rawValue)")
      }
    }
  }

  @Test("平台能力：iOS 17–25（supportsGlass = false）⇒ 一律 opaque（DF-10）")
  func legacyPlatformDegradesToOpaque() {
    for scheme in Self.schemes {
      for textLevel in WDTextLevel.allCases {
        let result = WDGlass.resolve(
          textLevel: textLevel,
          appearance: Self.appearance(scheme),
          capabilities: Self.legacy,
          budget: .default
        )
        #expect(result == .opaque, "\(scheme)/\(textLevel.rawValue) 在 17–25 上没降级")
      }
    }
  }

  @Test("效果预算：模糊面数为 0 ⇒ opaque（DF-03 第 1 条）")
  func budgetExhaustedDegradesToOpaque() {
    for scheme in Self.schemes {
      for textLevel in WDTextLevel.allCases {
        let result = WDGlass.resolve(
          textLevel: textLevel,
          appearance: Self.appearance(scheme),
          capabilities: Self.capable,
          budget: .minimal
        )
        #expect(result == .opaque, "\(scheme)/\(textLevel.rawValue)：预算为 0 仍返回 \(result)")
      }
    }
  }

  @Test("额外档位（F47）：ultraThin/thin/tinted/sheen 不作文字载体 ⇒ opaque；thick ⇒ glassStrong")
  func extraLevelIsFiltered() {
    for level in [WDGlassLevel.ultraThin, .thin, .tinted, .sheen] {
      for scheme in Self.schemes {
        let result = WDGlass.resolve(
          textLevel: .primary,
          appearance: Self.appearance(scheme),
          capabilities: Self.capable,
          budget: .default,
          level: level
        )
        #expect(result == .opaque, "\(level.rawValue)/\(scheme) 不该承载文字，却返回 \(result)")
      }
    }
    for scheme in Self.schemes {
      let thick = WDGlass.resolve(
        textLevel: .primary,
        appearance: Self.appearance(scheme),
        capabilities: Self.capable,
        budget: .default,
        level: .thick
      )
      #expect(thick == .glassStrong, "thick/\(scheme)：\(thick)")
    }
    // regular ≡ surface.glass：深色端一律不可承载文字
    let darkRegular = WDGlass.resolve(
      textLevel: .primary,
      appearance: Self.appearance(.dark),
      capabilities: Self.capable,
      budget: .default,
      level: .regular
    )
    #expect(darkRegular == .opaque, "深色 + regular 应降级为 opaque，实得 \(darkRegular)")
  }

  @Test("输出集合只有三个（U10 的 Output 是不变量）")
  func outputSetIsFixed() {
    #expect(WDGlassResolution.allCases.count == 3)
    #expect(Set(WDGlassResolution.allCases.map(\.rawValue)) == ["opaque", "glass", "glassStrong"])
  }
}
