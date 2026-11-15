import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDIconButton`（M2）的组件级断言：档位映射、热区恒 ≥44、标签必填。
@MainActor
@Suite("WDIconButton（M2）")
struct WDIconButtonTests {
  private static func size(_ size: WDButtonSize) -> CGSize {
    let controller = UIHostingController(
      rootView: WDIconButton(
        icon: .search, accessibilityLabel: Text(verbatim: "搜索"), size: size
      ) {}
      .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 200, height: 200))
  }

  @Test("档位映射：视觉 sm 32 / md 44 / lg 52；图标 sm 16 / md 24 / lg 28")
  func mapping() {
    #expect(WDIconButton.visualSize(for: .sm) == 32)
    #expect(WDIconButton.visualSize(for: .md) == 44)
    #expect(WDIconButton.visualSize(for: .lg) == 52)
    #expect(WDIconButton.iconSize(for: .sm) == .sm)
    #expect(WDIconButton.iconSize(for: .md) == .lg)
    #expect(WDIconButton.iconSize(for: .lg) == .xl)
  }

  @Test("热区恒 ≥ 44×44（sm 视觉 32 也要补到 44）")
  func hitArea() {
    for size in WDButtonSize.allCases {
      let measured = Self.size(size)
      #expect(measured.width >= WDSize.touchTargetMin - 0.5, "\(size.rawValue) 宽 \(measured.width)")
      #expect(
        measured.height >= WDSize.touchTargetMin - 0.5, "\(size.rawValue) 高 \(measured.height)")
    }
  }

  @Test("五变体齐、rawValue 稳定")
  func variants() {
    #expect(
      WDIconButtonVariant.allCases.map(\.rawValue)
        == ["plain", "filled", "tonal", "glass", "outline"])
  }

  @Test("五变体图标/背景对比度 ≥ 3:1（DF-04 图形门槛，浅深两套）")
  func contrast() {
    let schemes: [(WDColorValues, ColorScheme)] = [(.light, .light), (.dark, .dark)]
    for (colors, scheme) in schemes {
      for variant in WDIconButtonVariant.allCases {
        let icon = WDIconButton.iconColor(for: variant, colors: colors, scheme: scheme)
        let raw = WDIconButton.backgroundColor(for: variant, colors: colors)
        let background =
          raw.map { WDContrast.composite($0, over: colors.bgCanvas) }
          ?? colors.bgCanvas
        let ratio = WDContrast.ratio(icon, background)
        #expect(
          WDContrast.meetsGraphics(ratio),
          "\(variant.rawValue)/\(scheme) 对比度 \(ratio)")
      }
    }
  }
}
