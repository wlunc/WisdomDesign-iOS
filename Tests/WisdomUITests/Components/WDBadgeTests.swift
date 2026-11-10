import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDBadge`（M2）的组件级断言：胶囊几何、固定字号（设计例外）、宽度不截断。
///
/// 口径：设计 11 §3（高 24 / 内距 10 / 11 · 600 / `radius.full`）；
/// 冻结签名只有 `label` ⇒ 只实现状态胶囊的中性配色，差异登记在 `DEV-PLAN.md` §2.3。
@MainActor
@Suite("WDBadge（M2）")
struct WDBadgeTests {
  private static func size(
    _ text: String, typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let controller = UIHostingController(
      rootView: WDBadge(label: Text(verbatim: text))
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

  @Test("WDBadgeValue 可构造、可比较（值形态送给 WDListRowTrailing.badge）")
  func valueType() {
    let first = WDBadgeValue(label: Text(verbatim: "3"))
    let second = WDBadgeValue(label: Text(verbatim: "3"))
    #expect(first == second)
  }
}
