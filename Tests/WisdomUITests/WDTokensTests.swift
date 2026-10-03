import Testing
import SwiftUI
@testable import WisdomUI

@Suite("令牌")
struct WDTokensTests {
    @Test("字阶的行高不小于字号")
    func typographyLineHeight() {
        let styles: [WDTextStyle] = [
            WDType.largeTitle, WDType.title1, WDType.title2, WDType.title3,
            WDType.headline, WDType.body, WDType.callout, WDType.subheadline,
            WDType.footnote, WDType.caption1, WDType.caption2,
        ]
        for style in styles {
            #expect(style.lineHeight >= style.size)
        }
    }

    @Test("间距与圆角阶梯递增")
    func scalesAreMonotonic() {
        let spacing = [
            WDSpacing.s1, WDSpacing.s2, WDSpacing.s3, WDSpacing.s4, WDSpacing.s5,
            WDSpacing.s6, WDSpacing.s7, WDSpacing.s8, WDSpacing.s9, WDSpacing.s10,
        ]
        #expect(spacing == spacing.sorted())
        #expect(WDRadius.xs < WDRadius.sm)
        #expect(WDRadius.sm < WDRadius.md)
        #expect(WDRadius.md < WDRadius.lg)
        #expect(WDRadius.lg < WDRadius.xl)
        #expect(WDRadius.xl < WDRadius.xxl)
    }

    @Test("颜色令牌可解析", arguments: [WDColor.textPrimary, WDColor.textOnFill, WDColor.Palette.blue])
    func colorsResolve(_ color: Color) {
        _ = color.resolve(in: EnvironmentValues())
    }

    @Test("渐变至少有两点，且浅深两端 stop 数量一致")
    func gradientsHaveStops() {
        #expect(WDGradient.surface.stops.count >= 2)
        #expect(WDGradient.fill.stops.count >= 2)
        #expect(WDGradient.surface.stops.count == WDGradient.fill.stops.count)
    }
}
