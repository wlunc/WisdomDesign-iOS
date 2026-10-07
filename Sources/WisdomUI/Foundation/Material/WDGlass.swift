import SwiftUI

/// 外观输入（U10 契约真源之一：字段名即契约；IOS-11）。
///
/// 优先级（SPEC §3.2）：**系统无障碍设置 ＞ 调用方显式注入 ＞ 生成常量**；库不覆写平台设置（R16）。
public struct WDAppearance: Sendable, Equatable {
  /// `.light` / `.dark`。
  public let colorScheme: ColorScheme
  /// `.standard` / `.increased`（高对比度）。
  public let contrast: ColorSchemeContrast
  /// 降低透明度。
  public let reduceTransparency: Bool
  /// 无需依赖颜色区分。
  public let differentiateWithoutColor: Bool
  /// 减弱动效。
  public let reduceMotion: Bool

  /// 逐字段构造（五个输入都来自系统无障碍设置，调用方通常不用手填 —— 见 `EnvironmentValues.wdAppearance`）。
  public init(
    colorScheme: ColorScheme,
    contrast: ColorSchemeContrast,
    reduceTransparency: Bool,
    differentiateWithoutColor: Bool,
    reduceMotion: Bool
  ) {
    self.colorScheme = colorScheme
    self.contrast = contrast
    self.reduceTransparency = reduceTransparency
    self.differentiateWithoutColor = differentiateWithoutColor
    self.reduceMotion = reduceMotion
  }
}

/// 文字级别（U10 契约真源之一：与 Android 同列同名）。
public enum WDTextLevel: String, CaseIterable, Sendable {
  case primary
  case secondary
  case tertiary
}

/// 玻璃解析结果（U10 的输出集合 —— **只有这三个**）。
public enum WDGlassResolution: String, CaseIterable, Sendable {
  case opaque
  case glass
  case glassStrong
}

/// 设计侧的六个玻璃档位（**额外输入**，F47）：它们不改变输出集合，只影响"这份材料能不能承载文字"。
public enum WDGlassLevel: String, CaseIterable, Sendable {
  case ultraThin
  case thin
  case regular
  case thick
  case tinted
  case sheen
}

/// 平台能力（U10 的 `capabilities` 输入）。
public struct WDGlassCapabilities: Sendable, Equatable {
  /// 运行时是否支持玻璃（iOS 26+）。**iOS 17–25 一律 `false`** ⇒ 只返回 `opaque`（DF-10 默认执行项）。
  public let supportsGlass: Bool

  /// - Parameter supportsGlass: 运行时是否支持玻璃（iOS 26+ 为 `true`；17–25 传 `false`）。
  public init(supportsGlass: Bool) {
    self.supportsGlass = supportsGlass
  }
}

/// 玻璃档位解析（U10 / DF-02 / O-9）。
///
/// 规则（AGENTS §12.1 的四条硬规则 + O-9 第 1 条 + DF-10）：
///   1. `reduceTransparency` ⇒ `opaque`；
///   2. `contrast == .increased` ⇒ `opaque`（O-9：M0–M3 只做这一条）；
///   3. 平台不支持玻璃（iOS 17–25）⇒ `opaque`（DF-10）；
///   4. 效果预算不允许模糊面 ⇒ `opaque`（DF-03 第 1 条）；
///   5. **深色端任何字阶都不上 `surface.glass`** ⇒ 深色 + `primary` 最高到 `glassStrong`，
///      深色 + `secondary`/`tertiary` ⇒ `opaque`；
///   6. **浅色端 `surface.glass` 只放 `primary`** ⇒ `secondary`/`tertiary` 升到 `glassStrong`。
///
/// `level` 是**额外输入**（F47）：`ultraThin`/`thin` 不映射到语义档、`tinted`/`sheen` 是容器/装饰，
/// 三者都**不作为文字载体**（AGENTS §12.1）⇒ 一律 `opaque`。
public enum WDGlass {
  /// 解析"这份文字能不能放在玻璃上、放哪一档"。
  ///
  /// - Parameters:
  ///   - textLevel: 文字级别（U10 契约真源）。
  ///   - appearance: 外观输入（U10 契约真源）。
  ///   - capabilities: 平台能力（iOS 17–25 传 `supportsGlass: false`）。
  ///   - budget: 效果预算（模糊面数为 0 ⇒ 一律 `opaque`）。
  ///   - level: **额外输入**（F47）：不传 = 按文字级别与外观取最弱可行档；传了则先按档位语义过滤。
  public static func resolve(
    textLevel: WDTextLevel,
    appearance: WDAppearance,
    capabilities: WDGlassCapabilities,
    budget: WDEffectsBudget,
    level: WDGlassLevel? = nil
  ) -> WDGlassResolution {
    // ① 系统无障碍设置优先
    if appearance.reduceTransparency { return .opaque }
    if appearance.contrast == .increased { return .opaque }
    // ② 平台能力（iOS 17–25：纯色降级，不做模糊）
    if !capabilities.supportsGlass { return .opaque }
    // ③ 效果预算（同屏模糊面数上限）
    if budget.blurSurfaces <= 0 { return .opaque }
    // ④ 档位语义（额外输入）
    switch level {
    case .ultraThin, .thin, .tinted, .sheen:
      return .opaque
    case .regular:
      // regular ≡ surface.glass：深色端一律不可承载文字
      guard appearance.colorScheme == .light else { return .opaque }
    case .thick:
      break
    case .none:
      break
    }
    // ⑤ 文字级别 × 外观
    switch (appearance.colorScheme, textLevel) {
    case (.light, .primary):
      return level == .thick ? .glassStrong : .glass
    case (.light, .secondary), (.light, .tertiary):
      return .glassStrong
    case (.dark, .primary):
      return .glassStrong
    case (.dark, .secondary), (.dark, .tertiary):
      return .opaque
    @unknown default:
      return .opaque
    }
  }
}
