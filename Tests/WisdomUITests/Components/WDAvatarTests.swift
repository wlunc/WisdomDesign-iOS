import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDAvatar`（M2；B2 扩五档/在线/停用）的组件级断言：五档直径、固定字号（设计 12）、值类型可比较。
@MainActor
@Suite("WDAvatar（M2）")
struct WDAvatarTests {
  private static func size(
    _ value: WDAvatarValue,
    avatarSize: WDAvatarSize? = nil,
    isOnline: Bool = false,
    typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let avatar =
      avatarSize.map {
        WDAvatar(value: value, size: $0, isOnline: isOnline)
      } ?? WDAvatar(value: value)
    let controller = UIHostingController(
      rootView:
        avatar
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

  @Test("五档直径 20 / 28 / 32 / 40 / 56（±1）；rawValue 稳定")
  func fiveSizes() {
    #expect(
      WDAvatarSize.allCases.map(\.rawValue) == ["xs", "sm", "md", "lg", "xl"])
    let expected: [WDAvatarSize: CGFloat] = [
      .xs: 20, .sm: 28, .md: 32, .lg: 40, .xl: 56,
    ]
    for size in WDAvatarSize.allCases {
      let measured = Self.size(.init(label: Text(verbatim: "妈")), avatarSize: size)
      let target = expected[size] ?? 0
      #expect(abs(measured.width - target) <= 1, "\(size.rawValue) 宽 \(measured.width)")
      #expect(abs(measured.height - target) <= 1, "\(size.rawValue) 高 \(measured.height)")
    }
  }

  @Test("在线点只做 overlay，不改变头像尺寸")
  func onlineKeepsSize() {
    let plain = Self.size(.init(label: Text(verbatim: "妈")), avatarSize: .lg)
    let online = Self.size(
      .init(label: Text(verbatim: "妈")), avatarSize: .lg, isOnline: true)
    #expect(plain == online)
  }

  @Test("已停用可构造（50% + 去饱和）")
  func disabledConstructible() {
    let avatar = WDAvatar(
      value: .init(label: Text(verbatim: "妈")), size: .md, isDisabled: true)
    let controller = UIHostingController(rootView: avatar.wdTheme(.light))
    #expect(controller.sizeThatFits(in: CGSize(width: 200, height: 200)).width > 0)
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
