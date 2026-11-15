import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDBadge`（M2）的组件级断言：胶囊几何、固定字号（设计例外）、宽度不截断。
///
/// 口径：设计 11 §3（高 24 / 内距 10 / 11 · 600 / `radius.full`）；
/// 冻结签名只有 `label` ⇒ 只实现状态胶囊的中性配色，差异登记在 `DEV-PLAN.md` §2.3。
@MainActor
@Suite("WDBadge（M2）")
struct WDBadgeTests {
  private static func size(
    _ text: String, variant: WDBadgeVariant? = nil, typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let badge =
      variant.map { WDBadge(label: Text(verbatim: text), variant: $0) }
      ?? WDBadge(label: Text(verbatim: text))
    let controller = UIHostingController(
      rootView:
        badge
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 300, height: 100))
  }

  @Test("胶囊高度 24 ± 1（单行）")
  func heightIs24() {
    let measured = Self.size("已完成").height
    #expect(abs(measured - 24) <= 1, "实测高度 \(measured)，应为 24 ± 1")
  }

  @Test("AX5 下不放大：字号按设计固定 11pt（例外项，R11 行内豁免）")
  func fixedFontSize() {
    let normal = Self.size("已完成", typeSize: .large)
    let ax5 = Self.size("已完成", typeSize: .accessibility5)
    #expect(abs(normal.height - ax5.height) <= 0.5, "高度放大了：\(normal.height) → \(ax5.height)")
    #expect(abs(normal.width - ax5.width) <= 0.5, "宽度放大了：\(normal.width) → \(ax5.width)")
  }

  @Test("宽度随文字增长：不换行、不截断（内容上限由调用方负责）")
  func growsWithText() {
    #expect(Self.size("99").width > Self.size("9").width)
    #expect(Self.size("已逾期").width > Self.size("3").width)
  }

  @Test("WDBadge：六变体齐、rawValue 稳定、高度 24 ± 1")
  func variants() {
    #expect(
      WDBadgeVariant.allCases.map(\.rawValue)
        == ["shared", "schedule", "pending", "success", "warning", "danger"])
    for variant in WDBadgeVariant.allCases {
      let measured = Self.size("已完成", variant: variant).height
      #expect(abs(measured - 24) <= 1, "\(variant.rawValue) 高度 \(measured)")
    }
  }

  @Test("WDBadge：六变体文字/背景对比度 ≥ 4.5:1（浅深两套）")
  func variantContrast() {
    let schemes: [(WDColorValues, ColorScheme)] = [(.light, .light), (.dark, .dark)]
    for (colors, scheme) in schemes {
      for variant in WDBadgeVariant.allCases {
        let text = WDBadge.statusTextColor(for: variant, colors: colors, scheme: scheme)
        let raw = WDBadge.statusBackgroundColor(for: variant, colors: colors)
        let background =
          variant == .pending ? WDContrast.composite(raw, over: colors.bgCanvas) : raw
        let ratio = WDContrast.ratio(text, background)
        #expect(
          WDContrast.meetsBodyText(ratio),
          "\(variant.rawValue)/\(scheme) 对比度 \(ratio)")
      }
    }
  }

  @Test("WDBadgeValue 可构造、可比较（值形态送给 WDListRowTrailing.badge）")
  func valueType() {
    let first = WDBadgeValue(label: Text(verbatim: "3"))
    let second = WDBadgeValue(label: Text(verbatim: "3"))
    #expect(first == second)
  }

  @Test("可朗读文本：label 用原 Text / count 数字与 99+ / 0 与 dot 无文本")
  func readableText() {
    let label = Text(verbatim: "已逾期")
    #expect(WDBadgeValue(label: label).accessibilityText == label)
    #expect(WDBadgeValue(count: 1).accessibilityText == Text(verbatim: "1"))
    #expect(WDBadgeValue(count: 99).accessibilityText == Text(verbatim: "99"))
    #expect(WDBadgeValue(count: 100).accessibilityText == Text(verbatim: "99+"))
    #expect(WDBadgeValue(count: 0).accessibilityText == nil)
    #expect(WDBadgeValue.dot.accessibilityText == nil)
  }
}
