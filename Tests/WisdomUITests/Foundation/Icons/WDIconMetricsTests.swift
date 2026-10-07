import Testing

@testable import WisdomUI

/// 手写层的守卫（ICON-PIPELINE §7："手写层不得偏离令牌"）。
@MainActor
@Suite("图标尺寸映射")
struct WDIconMetricsTests {
  @Test("四档齐全，rawValue 与档位同名")
  func cases() {
    #expect(WDIconSize.allCases.map(\.rawValue) == ["sm", "md", "lg", "xl"])
  }

  @Test("逐档点径 == 令牌值（16 / 20 / 24 / 28）")
  func pointSizesMatchTokens() {
    #expect(WDIconMetrics.pointSize(for: .sm) == WDSize.iconSm)
    #expect(WDIconMetrics.pointSize(for: .md) == WDSize.iconMd)
    #expect(WDIconMetrics.pointSize(for: .lg) == WDSize.iconLg)
    #expect(WDIconMetrics.pointSize(for: .xl) == WDSize.iconXl)
    #expect(WDIconMetrics.pointSize(for: .sm) == 16)
    #expect(WDIconMetrics.pointSize(for: .xl) == 28)
  }

  @Test("线宽随档加粗（设计：放大时线宽同步 1.6/1.8/2/2.2）")
  func weightGrows() {
    #expect(WDIconMetrics.weight(for: .sm) == .regular)
    #expect(WDIconMetrics.weight(for: .md) == .regular)
    #expect(WDIconMetrics.weight(for: .lg) == .medium)
    #expect(WDIconMetrics.weight(for: .xl) == .medium)
  }
}
