import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDAvatar`（M2）的组件级断言：直径锁死、固定字号（设计 12）、值类型可比较。
@MainActor
@Suite("WDAvatar（M2）")
struct WDAvatarTests {
  private static func size(
    _ value: WDAvatarValue, typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let controller = UIHostingController(
      rootView: WDAvatar(value: value)
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 200, height: 200))
  }

  @Test("直径锁死 32 ± 1（md 档；文字/图标两种形态一致）")
  func diameterIs32() {
    let label = Self.size(.init(label: Text(verbatim: "妈")))
    let icon = Self.size(.init(icon: .profile))
    #expect(abs(label.width - 32) <= 1, "文字头像宽度实测 \(label.width)")
    #expect(abs(label.height - 32) <= 1, "文字头像高度实测 \(label.height)")
    #expect(abs(icon.width - 32) <= 1, "图标头像宽度实测 \(icon.width)")
    #expect(abs(icon.height - 32) <= 1, "图标头像高度实测 \(icon.height)")
  }

  @Test("AX5 下不放大：直径与首字号按设计固定（例外项，R7/R11 行内豁免）")
  func fixedAtLargeType() {
    let normal = Self.size(.init(label: Text(verbatim: "妈")), typeSize: .large)
    let ax5 = Self.size(.init(label: Text(verbatim: "妈")), typeSize: .accessibility5)
    #expect(abs(normal.width - ax5.width) <= 0.5, "宽度放大了：\(normal.width) → \(ax5.width)")
    #expect(abs(normal.height - ax5.height) <= 0.5, "高度放大了：\(normal.height) → \(ax5.height)")
  }

  @Test("两个值形态可构造、可比较（送给 WDListRowLeading.avatar）")
  func valueType() {
    #expect(
      WDAvatarValue(label: Text(verbatim: "妈")) == WDAvatarValue(label: Text(verbatim: "妈")))
    #expect(WDAvatarValue(icon: .profile) == WDAvatarValue(icon: .profile))
    #expect(WDAvatarValue(icon: .profile) != WDAvatarValue(label: Text(verbatim: "妈")))
  }
}
