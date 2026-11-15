import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDCard`（M2；B3 扩 sunken；可点卡）的组件级断言：内边距固定 16、四档齐、
/// 可点卡 action 可构造、静态卡不是按钮、按下样式存在（不做像素断言）。
@MainActor
@Suite("WDCard（M2）")
struct WDCardTests {
  private static func height(_ style: WDCardStyle, typeSize: DynamicTypeSize = .large)
    -> CGFloat
  {
    let content = Rectangle()
      .fill(Color.gray)
      .frame(width: 100, height: 50)
    let controller = UIHostingController(
      rootView: WDCard(style: style) { content }
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  /// 可点卡的实测高度（用于证明 Button 包裹没有改变内边距/布局）。
  private static func clickableHeight(disabled: Bool = false) -> CGFloat {
    let content = Rectangle()
      .fill(Color.gray)
      .frame(width: 100, height: 50)
    let controller = UIHostingController(
      rootView: WDCard(style: .elevated, action: {}) { content }
        .disabled(disabled)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  /// 统计 UIKit 无障碍树里带 `button` 特征的节点数。
  ///
  /// SwiftUI 在无 AX 客户端时可能不填充 `accessibilityElements`；本断言只证明
  /// “静态卡不会出现 button 特征”，不代表完整读屏回归（读屏回归走 demo 审计）。
  private static func buttonTraitCount(in root: UIView) -> Int {
    func count(_ object: Any) -> Int {
      var total = 0
      if let element = object as? NSObject, element.accessibilityTraits.contains(.button) {
        total += 1
      }
      if let view = object as? UIView {
        for subview in view.subviews {
          total += count(subview)
        }
        for element in view.accessibilityElements ?? [] {
          total += count(element)
        }
      }
      return total
    }
    return count(root)
  }

  @Test("内边距固定 16：内容 50 高 ⇒ 卡 82 高（所有变体一致）")
  func paddingIs16() {
    for style in WDCardStyle.allCases {
      let measured = Self.height(style)
      #expect(abs(measured - 82) <= 1, "\(style.rawValue) 实测高度 \(measured)，应为 82 ± 1")
    }
  }

  @Test("四档齐：elevated（默认）/ outlined / glass / sunken")
  func styles() {
    #expect(WDCardStyle.allCases == [.elevated, .outlined, .glass, .sunken])
  }

  @Test("可点卡：action 可构造，内边距仍 16（内容 50 高 ⇒ 卡 82 高）")
  func clickableConstructs() {
    #expect(abs(Self.clickableHeight() - 82) <= 1, "可点卡实测 \(Self.clickableHeight())")
    #expect(abs(Self.clickableHeight(disabled: true) - 82) <= 1, "禁用只降不透明度，不改布局")
  }

  @Test("语义分支：静态卡走 children .contain，可点卡走 Button")
  func clickableBranch() {
    let staticCard = WDCard(style: .elevated) { Text(verbatim: "静态卡") }
    let clickableCard = WDCard(style: .elevated, action: {}) { Text(verbatim: "可点卡") }
    #expect(!staticCard.isClickable)
    #expect(clickableCard.isClickable)
  }

  @Test("静态卡不是按钮：无障碍树中无 button 特征")
  func staticCardIsNotButton() {
    let controller = UIHostingController(
      rootView: WDCard(style: .elevated) {
        VStack(alignment: .leading, spacing: WDSpacing.s3) {
          Text(verbatim: "本周家务")
          Text(verbatim: "已完成 3 项，共 5 项")
        }
      }
      .wdTheme(.light)
    )
    controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: 400)
    controller.view.layoutIfNeeded()
    #expect(Self.buttonTraitCount(in: controller.view) == 0)
  }

  @Test("按下样式存在：亮度 96% 蒙层 + instant + 禁用 40%（不做像素断言）")
  func pressedStyleExists() {
    let style = WDCardButtonStyle()
    #expect(abs(style.pressedDimOpacity - 0.04) <= 0.0001)
    #expect(abs(style.disabledOpacity - 0.4) <= 0.0001)
    #expect(WDState.pressedBrightness == 96)
    #expect(WDMotion.Duration.instant == 0.10)
  }
}
