import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDButton`（M2）的组件级断言：三档高度、热区、加载态宽度不变、变体齐。
@MainActor
@Suite("WDButton（M2）")
struct WDButtonTests {
  private static func size(
    _ variant: WDButtonVariant = .filled, _ size: WDButtonSize = .md, loading: Bool = false
  ) -> CGSize {
    let controller = UIHostingController(
      rootView: WDButton(
        verbatim: "提交",
        variant: variant,
        size: size,
        isLoading: loading,
        loadingAccessibilityText: Text(verbatim: "处理中")
      ) {}
      .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: 200))
  }

  @Test("三档：md 44 / lg 52；视觉高度取令牌（sm 视觉 32、热区补到 44）")
  func heights() {
    #expect(WDButtonSize.sm.controlHeight == 32)
    #expect(WDButtonSize.md.controlHeight == 44)
    #expect(WDButtonSize.lg.controlHeight == 52)
    #expect(abs(Self.size(.filled, .md).height - 44) <= 1)
    #expect(abs(Self.size(.filled, .lg).height - 52) <= 1)
  }

  @Test("热区：所有档位布局高度 ≥ 44（sm 档外补 6pt）")
  func hitArea() {
    for size in WDButtonSize.allCases {
      #expect(Self.size(.filled, size).height >= WDSize.touchTargetMin - 0.5)
    }
  }

  @Test("加载态宽度不变（标签原位保留，指示器叠在上面）")
  func loadingKeepsWidth() {
    let normal = Self.size(.filled, .md, loading: false).width
    let loading = Self.size(.filled, .md, loading: true).width
    #expect(abs(normal - loading) <= 0.5, "宽度跳变：\(normal) → \(loading)")
  }

  @Test("六个变体齐（filled / tonal / glass / outline / plain / destructive）")
  func variants() {
    #expect(
      WDButtonVariant.allCases
        == [.filled, .tonal, .glass, .outline, .plain, .destructive])
  }
}
