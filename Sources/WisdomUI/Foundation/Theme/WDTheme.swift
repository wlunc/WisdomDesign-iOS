import SwiftUI

/// 主题值类型（I24b / F3）：组件侧取值的**唯一入口**。
///
/// 纪律：
///   · **只允许**覆盖颜色/渐变/材质三类槽位（R19）；组件不得读静态 `WDColor.*`（R10）；
///   · 取值优先级（SPEC §3.1）：① 生成常量 → ② **本类型注入** → ③ 组件参数/Style → ④ 实例级 Environment；
///   · 运行时换 scheme = 换用**已生成**的一套（`WDColorValues.wdSchemeNames`），**不重启进程**（F-05）。
public struct WDTheme: Sendable, Equatable {
  /// 当前 scheme 名（只能是已生成的那几套之一）。
  public let scheme: String
  /// 32 个语义色槽位在该 scheme 下的取值。
  public let colors: WDColorValues

  /// 用一套已生成的 scheme 名 + 槽位值构造。
  public init(scheme: String, colors: WDColorValues) {
    self.scheme = scheme
    self.colors = colors
  }

  /// 只给槽位值（预览/测试/demo 的实例级注入用）：scheme 记为默认 scheme。
  public init(colors: WDColorValues) {
    self.init(scheme: WDColorValues.wdDefaultScheme, colors: colors)
  }

  /// 默认主题 = 令牌真源里 `isDefault == true` 的那套 scheme。
  public static let `default`: WDTheme = {
    // 默认 scheme 一定在已生成清单里（生成器 --check 兜住），取不到时回退清单首项。
    named(WDColorValues.wdDefaultScheme)
      ?? WDTheme(scheme: WDColorValues.wdSchemeNames.first ?? "light", colors: .light)
  }()

  /// scheme `light`。
  public static let light = WDTheme(scheme: "light", colors: .light)
  /// scheme `dark`。
  public static let dark = WDTheme(scheme: "dark", colors: .dark)

  /// 按名字取主题；**未生成的 scheme 返回 nil**（不做隐式回退，避免"看起来换了、其实没换"）。
  public static func named(_ scheme: String) -> WDTheme? {
    switch scheme {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }
}
