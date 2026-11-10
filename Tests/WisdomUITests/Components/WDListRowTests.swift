import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDListRow`（M2）的组件级断言：行高 4 格矩阵（密度 × 槽位）。
///
/// 口径：`行高 = max(密度下限, 槽位派生)`；槽位派生 = 44（单行）/ 60（双行）/
/// 76（双行 + 尾部值/徽标/头像）。密度默认 comfortable（60），compact 44。
@MainActor
@Suite("WDListRow（M2）")
struct WDListRowTests {
  private static func height(
    subtitle: Bool = false,
    trailingValue: Bool = false,
    density: WDLayoutDensity? = nil
  ) -> CGFloat {
    var view = AnyView(
      WDListRow(
        title: Text(verbatim: "整理储物间"),
        subtitle: subtitle ? Text(verbatim: "今天 18:00 前") : nil,
        trailing: trailingValue ? .value(Text(verbatim: "3 件")) : .none
      )
    )
    if let density {
      view = AnyView(
        WDListRow(
          title: Text(verbatim: "整理储物间"),
          subtitle: subtitle ? Text(verbatim: "今天 18:00 前") : nil,
          trailing: trailingValue ? .value(Text(verbatim: "3 件")) : .none
        )
        .wdDensity(density)
      )
    }
    let controller = UIHostingController(rootView: view.frame(width: 320).wdTheme(.light))
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  @Test("comfortable（默认）：单行 60 / 双行 60 / 双行+尾部 76")
  func comfortableMatrix() {
    #expect(abs(Self.height() - 60) <= 1, "单行实测 \(Self.height())")
    #expect(abs(Self.height(subtitle: true) - 60) <= 1, "双行实测 \(Self.height(subtitle: true))")
    #expect(
      abs(Self.height(subtitle: true, trailingValue: true) - 76) <= 1,
      "三行实测 \(Self.height(subtitle: true, trailingValue: true))")
  }

  @Test("compact：单行 44 / 双行 60 / 双行+尾部 76")
  func compactMatrix() {
    #expect(
      abs(Self.height(density: .compact) - 44) <= 1,
      "单行实测 \(Self.height(density: .compact))")
    #expect(
      abs(Self.height(subtitle: true, density: .compact) - 60) <= 1,
      "双行实测 \(Self.height(subtitle: true, density: .compact))")
    #expect(
      abs(Self.height(subtitle: true, trailingValue: true, density: .compact) - 76) <= 1)
  }
}
