// 本文件由 wisdomdesign/tools/token-build/build.js 生成，请勿手改。
// 修改请编辑 wisdomdesign/tokens/wisdom.tokens.json 后重新生成。
// tokens v1.0.0 · sha256:e552bb87e270

import SwiftUI

/// 语义色。界面只允许引用这一层。
/// 浅深成对：明色方案 = light，暗色方案 = dark（schemes 维度）。
public enum WDColor {
    public static let bgCanvas = Color(wdLight: 0xF1F8FA, dark: 0x0A1B26)
    public static let bgGrouped = Color(wdLight: 0xE8F2F7, dark: 0x0D2331)
    public static let surfaceCard = Color(wdLight: 0xFFFFFF, lightAlpha: 0.941, dark: 0x132836, darkAlpha: 0.820)
    public static let surfaceCardSolid = Color(wdLight: 0xFFFFFF, dark: 0x0C212D)
    public static let surfaceCardSunken = Color(wdLight: 0xEDF6F9, dark: 0x0A1E2A)
    public static let surfaceTint = Color(wdLight: 0xD9E9F3, dark: 0x123348)
    public static let surfaceGlass = Color(wdLight: 0xFFFFFF, lightAlpha: 0.702, dark: 0x0C202C, darkAlpha: 0.620)
    public static let surfaceGlassStrong = Color(wdLight: 0xFFFFFF, lightAlpha: 0.859, dark: 0x0C202C, darkAlpha: 0.780)
    public static let textPrimary = Color(wdLight: 0x0A1B24, dark: 0xE6F1F6)
    public static let textSecondary = Color(wdLight: 0x3E5764, dark: 0xA4BCCB)
    public static let textTertiary = Color(wdLight: 0x4C616D, dark: 0x839EB0)
    public static let textDisabled = Color(wdLight: 0x6A7B85, dark: 0x6E8798)
    public static let textOnLightPrimary = Color(wdLight: 0x0A1B24, dark: 0x0A1B24)
    public static let textOnLightSecondary = Color(wdLight: 0x3E5764, dark: 0x3E5764)
    public static let textOnLightTertiary = Color(wdLight: 0x4C616D, dark: 0x4C616D)
    public static let textOnSoft = Color(wdLight: 0x123F5C, dark: 0xB0D5DF)
    public static let textOnFill = Color(wdLight: 0x0E3A55, dark: 0xDCEEF4)
    public static let textOnDark = Color(wdLight: 0xFFFFFF, dark: 0xFFFFFF)
    public static let textBrand = Color(wdLight: 0x1677B3, dark: 0x7EC4CF)
    public static let borderHairline = Color(wdLight: 0x0A1B24, lightAlpha: 0.078, dark: 0xFFFFFF, darkAlpha: 0.102)
    public static let borderHairlineStrong = Color(wdLight: 0x0A1B24, lightAlpha: 0.161, dark: 0xFFFFFF, darkAlpha: 0.180)
    public static let borderGlassTop = Color(wdLight: 0xFFFFFF, lightAlpha: 0.800, dark: 0xFFFFFF, darkAlpha: 0.161)
    public static let fillField = Color(wdLight: 0x0A1B24, lightAlpha: 0.051, dark: 0xFFFFFF, darkAlpha: 0.071)
    public static let fillPressed = Color(wdLight: 0x0A1B24, lightAlpha: 0.071, dark: 0xFFFFFF, darkAlpha: 0.090)
    public static let statusSuccess = Color(wdLight: 0x2A7F5C, dark: 0x7FD3B4)
    public static let statusInfo = Color(wdLight: 0x1677B3, dark: 0x8FC4E8)
    public static let statusWarning = Color(wdLight: 0x97651F, dark: 0xEFC683)
    public static let statusDanger = Color(wdLight: 0xB8564D, dark: 0xEDA79E)
    public static let statusSoftSuccess = Color(wdLight: 0xE3F5EC, dark: 0x0D2E24)
    public static let statusSoftInfo = Color(wdLight: 0xE1F0F8, dark: 0x0C2740)
    public static let statusSoftWarning = Color(wdLight: 0xFFF4DC, dark: 0x33260E)
    public static let statusSoftDanger = Color(wdLight: 0xFBE7E4, dark: 0x3A211E)

    /// 定稿色卡的十二个色，只作对照，界面不直接用。
    public enum Palette {
        public static let lake = Color(wd: 0xB0D5DF)
        public static let mist = Color(wd: 0x7EC4CF)
        public static let slate = Color(wd: 0x4C8DAE)
        public static let cyan = Color(wd: 0x1685A9)
        public static let blue = Color(wd: 0x1677B3)
        public static let indigo = Color(wd: 0x2A5CAA)
        public static let navy = Color(wd: 0x065279)
        public static let navyDeep = Color(wd: 0x1E3B7A)
        public static let abyss = Color(wd: 0x080F40)
    }

    /// 由色卡派生、经验证对比度的填充与文字色。
    public enum Derived {
        public static let fillLight1 = Color(wd: 0x8FCFDD)
        public static let fillLight2 = Color(wd: 0x63BAD2)
        public static let fillMid1 = Color(wd: 0x4FB0C8)
        public static let fillMid2 = Color(wd: 0x1685A9)
        public static let textOnSoft = Color(wd: 0x123F5C)
        public static let textOnFill = Color(wd: 0x0E3A55)
    }

    /// 中性色阶。
    public enum Neutral {
        public static let su0 = Color(wd: 0xFFFFFF)
        public static let su50 = Color(wd: 0xF1F8FA)
        public static let su100 = Color(wd: 0xE4F0F5)
        public static let su200 = Color(wd: 0xD2E4EB)
        public static let su300 = Color(wd: 0xB9D2DC)
        public static let su400 = Color(wd: 0x8FA9B5)
        public static let su500 = Color(wd: 0x6B8794)
        public static let su600 = Color(wd: 0x3E5764)
        public static let su700 = Color(wd: 0x2C4250)
        public static let su800 = Color(wd: 0x1B2E38)
        public static let su900 = Color(wd: 0x0A1B24)
        public static let su950 = Color(wd: 0x061017)
    }
}

/// 渐变。stop 本身是浅深成对的动态色，所以一条令牌即可覆盖两种外观。
/// 注：>2 套 scheme 的静态渐变色值随 M1 的主题类型扩展（M0-1 只冻结 light/dark）。
public enum WDGradient {
    public static let surface = WDGradientSpec(
        angleDegrees: 135,
        stops: [
            (color: Color(wdLight: 0xB0D5DF, dark: 0x123449), location: 0.00),
            (color: Color(wdLight: 0x7EC4CF, dark: 0x0F4055), location: 1.00)
        ]
    )
    public static let fill = WDGradientSpec(
        angleDegrees: 135,
        stops: [
            (color: Color(wdLight: 0x8FCFDD, dark: 0x1677B3), location: 0.00),
            (color: Color(wdLight: 0x63BAD2, dark: 0x2A5CAA), location: 1.00)
        ]
    )
    public static let mid = WDGradientSpec(
        angleDegrees: 135,
        stops: [
            (color: Color(wd: 0x4FB0C8), location: 0.00),
            (color: Color(wd: 0x1685A9), location: 1.00)
        ]
    )
    public static let destructive = WDGradientSpec(
        angleDegrees: 135,
        stops: [
            (color: Color(wd: 0xB8564D), location: 0.00),
            (color: Color(wd: 0xA94A42), location: 1.00)
        ]
    )
    public static let sunrise = WDGradientSpec(
        angleDegrees: 135,
        stops: [
            (color: Color(wd: 0xFFE7C2), location: 0.00),
            (color: Color(wd: 0xFFD2C4), location: 1.00)
        ]
    )
}

/// 间距，基准 4pt。
public enum WDSpacing {
    public static let s1: CGFloat = 2
    public static let s2: CGFloat = 4
    public static let s3: CGFloat = 8
    public static let s4: CGFloat = 12
    public static let s5: CGFloat = 16
    public static let s6: CGFloat = 20
    public static let s7: CGFloat = 24
    public static let s8: CGFloat = 32
    public static let s9: CGFloat = 40
    public static let s10: CGFloat = 48
}

/// 圆角阶梯。
public enum WDRadius {
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 18
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let full: CGFloat = 999
    public static let checkbox: CGFloat = 9
    public static let fab: CGFloat = 19
}

/// 组件尺寸。U8：触控只生成本端常量（iOS 44）。
public enum WDSize {
    public static let controlSm: CGFloat = 32
    public static let controlMd: CGFloat = 44
    public static let controlLg: CGFloat = 52
    public static let touchTargetMin: CGFloat = 44
    public static let rowHeightComfortable: CGFloat = 60
    public static let rowHeightCompact: CGFloat = 44
    public static let cardPaddingComfortable: CGFloat = 16
    public static let cardPaddingCompact: CGFloat = 12
    public static let fieldHeight: CGFloat = 46
    public static let fieldMinWidth: CGFloat = 190
    public static let checkbox: CGFloat = 26
    public static let iconSm: CGFloat = 16
    public static let iconMd: CGFloat = 20
    public static let iconLg: CGFloat = 24
    public static let iconXl: CGFloat = 28
    public static let avatarXs: CGFloat = 20
    public static let avatarSm: CGFloat = 28
    public static let avatarMd: CGFloat = 32
    public static let avatarLg: CGFloat = 40
    public static let avatarXl: CGFloat = 56
    public static let avatarXxl: CGFloat = 72
    public static let sheetDetentHalf: CGFloat = 0.5
    public static let sheetDetentLarge: CGFloat = 0.92
    public static let sheetMaxWidth: CGFloat = 480
    public static let sheetCornerRadius: CGFloat = 32
    public static let sheetHandleWidth: CGFloat = 36
    public static let sheetHandleHeight: CGFloat = 5
    public static let sheetHandleTopOffset: CGFloat = 8
    public static let tabbarHeight: CGFloat = 56
    public static let navbarCompact: CGFloat = 44
    public static let navbarStandard: CGFloat = 56
}

/// 字阶。size 与 lineHeight 分开给，行高比由设计决定，不交给系统默认。
/// WDTextStyle 由手写层提供（4 存储字段 + internal init，I-M0-h）；本文件只 emit 常量。
public enum WDType {
    public static let largeTitle = WDTextStyle(size: 34, lineHeight: 41, weight: .bold, letterSpacing: 0)
    public static let title1 = WDTextStyle(size: 28, lineHeight: 34, weight: .bold, letterSpacing: 0)
    public static let title2 = WDTextStyle(size: 22, lineHeight: 28, weight: .semibold, letterSpacing: 0)
    public static let title3 = WDTextStyle(size: 20, lineHeight: 25, weight: .semibold, letterSpacing: 0)
    public static let headline = WDTextStyle(size: 17, lineHeight: 22, weight: .semibold, letterSpacing: 0)
    public static let body = WDTextStyle(size: 17, lineHeight: 22, weight: .regular, letterSpacing: 0)
    public static let callout = WDTextStyle(size: 16, lineHeight: 21, weight: .regular, letterSpacing: 0)
    public static let subheadline = WDTextStyle(size: 15, lineHeight: 20, weight: .regular, letterSpacing: 0)
    public static let footnote = WDTextStyle(size: 13, lineHeight: 18, weight: .regular, letterSpacing: 0)
    public static let caption1 = WDTextStyle(size: 12, lineHeight: 16, weight: .regular, letterSpacing: 0)
    public static let caption2 = WDTextStyle(size: 11, lineHeight: 13, weight: .medium, letterSpacing: 0)
    public static let overline = WDTextStyle(size: 12, lineHeight: 16, weight: .medium, letterSpacing: 0.6)
}

/// 高度。每层阴影按顺序叠加，禁止单层重阴影。出口档位 e0/e1/e2/e3/brand。
public enum WDElevation {
    public static let e0: [WDShadowLayer] = [
    ]
    public static let e1: [WDShadowLayer] = [
        .init(x: 0, y: 1, blur: 2, color: Color(wd: 0x0A3C64, alpha: 0.039)),
        .init(x: 0, y: 6, blur: 16, color: Color(wd: 0x0A3C64, alpha: 0.059))
    ]
    public static let e2: [WDShadowLayer] = [
        .init(x: 0, y: 2, blur: 6, color: Color(wd: 0x0A3C64, alpha: 0.059)),
        .init(x: 0, y: 14, blur: 32, color: Color(wd: 0x0A3C64, alpha: 0.090))
    ]
    public static let e3: [WDShadowLayer] = [
        .init(x: 0, y: 8, blur: 20, color: Color(wd: 0x0A3C64, alpha: 0.090)),
        .init(x: 0, y: 28, blur: 56, color: Color(wd: 0x0A3C64, alpha: 0.129))
    ]
    public static let brand: [WDShadowLayer] = [
        .init(x: 0, y: 6, blur: 16, color: Color(wd: 0x1677B3, alpha: 0.180))
    ]
}

/// 动效。进场慢、出场快；位移越长时长越长。
/// 弹簧 canonical = response + dampingRatio；iOS 映射 SwiftUI 的 dampingFraction，**不生成 stiffness**。
public enum WDMotion {
    public enum Duration {
        public static let instant: Double = 0.10
        public static let fast: Double = 0.16
        public static let base: Double = 0.24
        public static let slow: Double = 0.34
        public static let slower: Double = 0.50
        public static let reduced: Double = 0.15
    }

    public enum Spring {
        public static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.85)
        public static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.82)
        public static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.68)
    }
}

/// 交互状态视觉值（U6 / F45）。百分数按 0–100 原样给，使用时除 100；ring-width 单位 pt。
public enum WDState {
    public static let hoverBrightness: CGFloat = 98
    public static let pressedBrightness: CGFloat = 96
    public static let focusRingWidth: CGFloat = 3
    public static let focusRingAlpha: CGFloat = 32
    public static let disabledAlpha: CGFloat = 40
}
