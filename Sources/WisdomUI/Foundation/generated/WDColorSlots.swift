// 本文件由 wisdomdesign/tools/token-build/build.js 生成，请勿手改。
// 修改请编辑 wisdomdesign/tokens/wisdom.tokens.json 后重新生成。
// tokens v1.0.0 · sha256:e552bb87e270

import SwiftUI

/// 语义色槽位（U12 = 32 个，含 `text.disabled`）· 每套 scheme 一组值（M0-1 `schemes` 维度）。
///
/// 手写层契约（I-M0-h，`Foundation/Theme/WDColorValues.swift`）：
///   ① `WDColorValues` 提供 `internal init(<以下命名参数，顺序与本文件一致>)`；
///   ② `WDColorSlot.allCases` 的 case 顺序与本文件槽位顺序一致（计数断言 = 生成器 `--check`）；
///   ③ `public init(_ patch: WDColorOverrides)` 的缺省值取 `WDColorValues.default`。
extension WDColorValues {
    /// 已生成的 scheme 清单（M0-1 schemes 维度；运行时只能在这些 scheme 之间切换）。
    public static let wdSchemeNames: [String] = ["light", "dark"]
    /// 默认 scheme（schemes.<name>.isDefault == true）。
    public static let wdDefaultScheme: String = "light"

    /// scheme `light`（appearance = light）的 32 个槽位值。
    public static let light: WDColorValues = WDColorValues(
        bgCanvas: Color(wd: 0xF1F8FA),
        bgGrouped: Color(wd: 0xE8F2F7),
        surfaceCard: Color(wd: 0xFFFFFF, alpha: 0.941),
        surfaceCardSolid: Color(wd: 0xFFFFFF),
        surfaceCardSunken: Color(wd: 0xEDF6F9),
        surfaceTint: Color(wd: 0xD9E9F3),
        surfaceGlass: Color(wd: 0xFFFFFF, alpha: 0.702),
        surfaceGlassStrong: Color(wd: 0xFFFFFF, alpha: 0.859),
        textPrimary: Color(wd: 0x0A1B24),
        textSecondary: Color(wd: 0x3E5764),
        textTertiary: Color(wd: 0x4C616D),
        textDisabled: Color(wd: 0x6A7B85),
        textOnLightPrimary: Color(wd: 0x0A1B24),
        textOnLightSecondary: Color(wd: 0x3E5764),
        textOnLightTertiary: Color(wd: 0x4C616D),
        textOnSoft: Color(wd: 0x123F5C),
        textOnFill: Color(wd: 0x0E3A55),
        textOnDark: Color(wd: 0xFFFFFF),
        textBrand: Color(wd: 0x1677B3),
        borderHairline: Color(wd: 0x0A1B24, alpha: 0.078),
        borderHairlineStrong: Color(wd: 0x0A1B24, alpha: 0.161),
        borderGlassTop: Color(wd: 0xFFFFFF, alpha: 0.800),
        fillField: Color(wd: 0x0A1B24, alpha: 0.051),
        fillPressed: Color(wd: 0x0A1B24, alpha: 0.071),
        statusSuccess: Color(wd: 0x2A7F5C),
        statusInfo: Color(wd: 0x1677B3),
        statusWarning: Color(wd: 0x97651F),
        statusDanger: Color(wd: 0xB8564D),
        statusSoftSuccess: Color(wd: 0xE3F5EC),
        statusSoftInfo: Color(wd: 0xE1F0F8),
        statusSoftWarning: Color(wd: 0xFFF4DC),
        statusSoftDanger: Color(wd: 0xFBE7E4)
    )

    /// scheme `dark`（appearance = dark）的 32 个槽位值。
    public static let dark: WDColorValues = WDColorValues(
        bgCanvas: Color(wd: 0x0A1B26),
        bgGrouped: Color(wd: 0x0D2331),
        surfaceCard: Color(wd: 0x132836, alpha: 0.820),
        surfaceCardSolid: Color(wd: 0x0C212D),
        surfaceCardSunken: Color(wd: 0x0A1E2A),
        surfaceTint: Color(wd: 0x123348),
        surfaceGlass: Color(wd: 0x0C202C, alpha: 0.620),
        surfaceGlassStrong: Color(wd: 0x0C202C, alpha: 0.780),
        textPrimary: Color(wd: 0xE6F1F6),
        textSecondary: Color(wd: 0xA4BCCB),
        textTertiary: Color(wd: 0x839EB0),
        textDisabled: Color(wd: 0x6E8798),
        textOnLightPrimary: Color(wd: 0x0A1B24),
        textOnLightSecondary: Color(wd: 0x3E5764),
        textOnLightTertiary: Color(wd: 0x4C616D),
        textOnSoft: Color(wd: 0xB0D5DF),
        textOnFill: Color(wd: 0xDCEEF4),
        textOnDark: Color(wd: 0xFFFFFF),
        textBrand: Color(wd: 0x7EC4CF),
        borderHairline: Color(wd: 0xFFFFFF, alpha: 0.102),
        borderHairlineStrong: Color(wd: 0xFFFFFF, alpha: 0.180),
        borderGlassTop: Color(wd: 0xFFFFFF, alpha: 0.161),
        fillField: Color(wd: 0xFFFFFF, alpha: 0.071),
        fillPressed: Color(wd: 0xFFFFFF, alpha: 0.090),
        statusSuccess: Color(wd: 0x7FD3B4),
        statusInfo: Color(wd: 0x8FC4E8),
        statusWarning: Color(wd: 0xEFC683),
        statusDanger: Color(wd: 0xEDA79E),
        statusSoftSuccess: Color(wd: 0x0D2E24),
        statusSoftInfo: Color(wd: 0x0C2740),
        statusSoftWarning: Color(wd: 0x33260E),
        statusSoftDanger: Color(wd: 0x3A211E)
    )

    /// 默认主题槽位值（= `light`）。
    public static let `default`: WDColorValues = light
}
