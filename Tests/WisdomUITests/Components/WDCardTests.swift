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

  @Test("内边距固定 16：内容 50 高 ⇒ 卡 82 高（文字区变体一致；media 是图片带+文字区，另测）")
  func paddingIs16() {
    for style in WDCardStyle.allCases where style != .media {
      let measured = Self.height(style)
      #expect(abs(measured - 82) <= 1, "\(style.rawValue) 实测高度 \(measured)，应为 82 ± 1")
    }
  }

  @Test("五档齐：elevated（默认）/ outlined / glass / sunken / media（A-13）")
  func styles() {
    #expect(WDCardStyle.allCases == [.elevated, .outlined, .glass, .sunken, .media])
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

  // MARK: - A-13 · media 图片带（设计 14 §2）

  /// 媒体卡的实测高度（给定卡宽；content 高度固定 50）。
  private static func mediaHeight(width: CGFloat) -> CGFloat {
    let content = Rectangle()
      .fill(Color.clear)
      .frame(width: 100, height: 50)
    let controller = UIHostingController(
      rootView: WDCard(style: .media, media: nil) { content }
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: width, height: CGFloat.infinity)).height
  }

  @Test("media 几何：343 宽 ⇒ 带高 ≈193；171 宽 ⇒ 带高 = 96（最小高夹紧）")
  func mediaBandGeometry() {
    // 343 / 1.78 ≈ 192.7 → 卡高 = 带 192.7 + 文字区（16 + 50 + 16）= 274.7（±1 容差）
    let wide = Self.mediaHeight(width: 343)
    #expect(abs(wide - (343 / WDSize.cardMediaAspectRatio + 82)) <= 1, "343 宽卡高实测 \(wide)")
    // 171 / 1.78 ≈ 96.06 → 触发最小高：带高 = 96（171 宽在夹紧边界上，容差放宽到 2）
    let narrow = Self.mediaHeight(width: 171)
    #expect(abs(narrow - (96 + 82)) <= 2, "171 宽应触发最小高 96，卡高实测 \(narrow)")
    // 更窄（120）：带高仍 = 96（居中裁切），不小于 96
    let narrower = Self.mediaHeight(width: 120)
    #expect(abs(narrower - (96 + 82)) <= 2, "120 宽带高应仍为 96，卡高实测 \(narrower)")
  }

  @Test("media 占位：image nil 时卡高 = 最小带高 + 文字区（灰底档不塌）")
  func mediaPlaceholderKeepsHeight() {
    let withNil = Self.mediaHeight(width: 343)
    #expect(withNil > 96 + 50, "灰底占位档不应塌成 0 高，实测 \(withNil)")
  }

  @Test("media 就绪：先 nil 后 ready —— 灰底档也能挂载就绪图（F6 主数据流）")
  func mediaReadyAfterPlaceholderConstructs() throws {
    // 主数据流（设计 §2.3）：先占位（WDCardMedia(nil) 灰底），图片就绪后传入新值。
    // band 是同一结构身份（WDCardMediaBand 输入更新）⇒ 淡入只能由 onChange 驱动，
    // 构造必须可用且卡高不塌（几何与占位档一致 = 灰底兜底 + 就绪图同框）。
    let nilCard = WDCard(style: .media, media: WDCardMedia(nil)) {
      Text(verbatim: "占位")
    }
    let readyCard = WDCard(style: .media, media: WDCardMedia(Image(systemName: "photo"))) {
      Text(verbatim: "就绪")
    }
    #expect(nilCard.isClickable == false)
    #expect(readyCard.isClickable == false)
    // 载荷更新前后都是 .media 档：结构身份不变，只是输入从 nil 换成就绪图。
    let controller = UIHostingController(
      rootView: readyCard.wdTheme(.light)
    )
    let measured = controller.sizeThatFits(in: CGSize(width: 343, height: CGFloat.infinity)).height
    #expect(
      abs(measured - (343 / WDSize.cardMediaAspectRatio + 82)) <= 1,
      "就绪图档带高应仍按 16:9，实测 \(measured)")
  }

  @Test("media 可点卡可构造；isClickable 语义不变")
  func mediaClickableConstructs() {
    let card = WDCard(style: .media, media: WDCardMedia(nil), action: {}) {
      Text(verbatim: "可点媒体卡")
    }
    #expect(card.isClickable)
    let staticCard = WDCard(style: .media, media: WDCardMedia(nil)) {
      Text(verbatim: "静态媒体卡")
    }
    #expect(!staticCard.isClickable)
  }

  @Test("media 与 glass/sunken 互斥：非 media 构造不产生图片带（media == nil 路径）")
  func mediaMutuallyExclusive() {
    // 设计 §2.6：media 与 glass 互斥（图片带不做模糊）、与 sunken 不组合。
    // 实现口径：只有 init(style:media:...) 且 style == .media 才挂载荷；
    // 其余构造的 media 恒 nil（internal 只读属性，@testable 可见）。
    let glass = WDCard(style: .glass) { Text(verbatim: "玻璃卡") }
    #expect(glass.style != .media)
    let elevatedWithMediaParam = WDCard(style: .elevated, media: WDCardMedia(nil)) {
      Text(verbatim: "误用 media 参数")
    }
    #expect(elevatedWithMediaParam.style == .elevated)
    #expect(elevatedWithMediaParam.media == nil, "非 media 档即使传了 media 参数也不得挂载图片带")
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
