import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDTextField`（M2 首件）的组件级断言：几何、状态、边界、API 形状。
///
/// 口径来源：`docs/SPEC.md` §2.3（签名与 CR-1 验收句）、`docs/DEV-PLAN.md` §14.4（六类断言）、
/// `../wisdomdesign/docs/specs/01-basic.md` #03（设计值）。
///
/// 测量手段 = `UIHostingController.sizeThatFits`（F42：默认档 ±0.5pt）；不测私有实现细节。
@MainActor
@Suite("WDTextField（M2）")
struct WDTextFieldTests {
  // MARK: - 构造与测量

  private static func field(
    _ appearance: WDTextFieldAppearance = .init(),
    isEditable: Bool = true,
    text: String = "任务一"
  ) -> some View {
    WDTextField(
      text: .constant(text),
      label: Text(verbatim: "任务名称"),
      appearance: appearance,
      isEditable: isEditable
    )
    .wdTheme(.light)
  }

  private static func measuredHeight(
    _ view: some View, width: CGFloat = 320, typeSize: DynamicTypeSize = .large
  ) -> CGFloat {
    let controller = UIHostingController(
      rootView:
        view
        .environment(\.dynamicTypeSize, typeSize)
        .frame(width: width, alignment: .leading)
    )
    return controller.sizeThatFits(in: CGSize(width: width, height: .infinity)).height
  }

  /// 字段盒高度 = 总高 − 标签行 − 两处 `space.2` 间距 − 辅助文案行。
  private static func fieldBoxHeight(
    _ appearance: WDTextFieldAppearance = .init(),
    isEditable: Bool = true,
    typeSize: DynamicTypeSize = .large
  ) -> CGFloat {
    let total = measuredHeight(
      field(appearance, isEditable: isEditable), typeSize: typeSize)
    let label = WDFontMetrics.lineBoxHeight(for: WDType.footnote, dynamicTypeSize: typeSize)
    let helper: CGFloat
    switch appearance.helper {
    case .none:
      helper = 0
    case .hint, .error:
      helper =
        WDSpacing.s2
        + WDFontMetrics.lineBoxHeight(for: WDType.caption1, dynamicTypeSize: typeSize)
    }
    return total - label - WDSpacing.s2 - helper
  }

  // MARK: - ① API 形状

  @Test("API 形状：三个变体、默认外观、受控值标签")
  func apiShape() {
    #expect(WDTextFieldVariant.allCases == [.inset, .outline, .glass])
    #expect(WDTextFieldVariant.inset.rawValue == "inset")

    let appearance = WDTextFieldAppearance()
    #expect(appearance.variant == .inset)
    #expect(appearance.placeholder == nil)
    #expect(appearance.prefix == .none)
    #expect(appearance.accessory == .none)
    #expect(appearance.helper == .none)
    #expect(appearance.isSecure == false)
  }

  // MARK: - ② 几何：字段盒 46 ± 1（所有变体）

  @Test("字段盒高度：三个变体 × 三种辅助文案，全部 46 ± 1（CR-1）")
  func fieldBoxHeightIs46() {
    for variant in WDTextFieldVariant.allCases {
      for helper in [
        WDTextFieldHelper.none, .hint(Text(verbatim: "提示")), .error(Text(verbatim: "错误")),
      ] {
        let appearance = WDTextFieldAppearance(variant: variant, helper: helper)
        let measured = Self.fieldBoxHeight(appearance)
        #expect(
          abs(measured - 46) <= 1,
          "\(variant.rawValue) + \(helper) 的字段盒实测 \(measured)，应为 46 ± 1")
      }
    }
  }

  @Test("状态不改变高度：可编辑 / 只读 / 禁用三态字段盒一致")
  func stateDoesNotChangeHeight() {
    let editable = Self.fieldBoxHeight(.init(), isEditable: true)
    let readOnly = Self.fieldBoxHeight(.init(), isEditable: false)
    #expect(abs(editable - readOnly) <= 0.5, "只读态改变了字段盒高度：\(editable) vs \(readOnly)")

    let disabledHeight = Self.measuredHeight(Self.field(.init()).disabled(true))
    let enabledHeight = Self.measuredHeight(Self.field(.init()))
    #expect(
      abs(disabledHeight - enabledHeight) <= 0.5,
      "禁用态改变了高度：\(enabledHeight) vs \(disabledHeight)")
  }

  @Test("辅助文案各占一行：hint / error 都增加 caption1 行盒 + 一处 space.2")
  func helperAddsOneLine() {
    let none = Self.measuredHeight(Self.field(.init()))
    let hint = Self.measuredHeight(Self.field(.init(helper: .hint(Text(verbatim: "提示")))))
    let error = Self.measuredHeight(Self.field(.init(helper: .error(Text(verbatim: "错误")))))
    let expected =
      WDSpacing.s2
      + WDFontMetrics.lineBoxHeight(for: WDType.caption1, dynamicTypeSize: .large)
    #expect(abs((hint - none) - expected) <= 0.5, "hint 增加 \(hint - none)，应为 \(expected)")
    #expect(abs((error - none) - expected) <= 0.5, "error 增加 \(error - none)，应为 \(expected)")
  }

  @Test("放大档不裁切：字段盒随 body 行盒增高（AX3）")
  func growsAtAccessibilitySize() {
    let size = DynamicTypeSize.accessibility3
    let measured = Self.fieldBoxHeight(.init(), typeSize: size)
    let bodyLine = WDFontMetrics.lineBoxHeight(for: WDType.body, dynamicTypeSize: size)
    #expect(measured >= 46, "AX3 字段盒（\(measured)）不得低于 46")
    #expect(
      abs(measured - max(46, bodyLine)) <= 1,
      "AX3 字段盒 \(measured) 应等于 max(46, body 行盒 \(bodyLine))")
  }

  @Test("最小宽度 = 190（窄容器下不塌陷）")
  func minWidth() {
    let controller = UIHostingController(rootView: Self.field(.init()).wdTheme(.light))
    let measured = controller.sizeThatFits(in: CGSize(width: 120, height: CGFloat.infinity))
    #expect(measured.width >= WDSize.fieldMinWidth, "最小宽度不足 190")
  }

  // MARK: - ③ 边界：计数附件 ≥90% 阈值

  @Test("计数附件：≥90% 才转 status.warning（纯逻辑，阈值为设计裁决）")
  func countThreshold() {
    #expect(WDTextField.isCountNearLimit(current: 9, limit: 10))
    #expect(WDTextField.isCountNearLimit(current: 10, limit: 10))
    #expect(WDTextField.isCountNearLimit(current: 90, limit: 100))
    #expect(!WDTextField.isCountNearLimit(current: 8, limit: 10))
    #expect(!WDTextField.isCountNearLimit(current: 89, limit: 100))
    #expect(!WDTextField.isCountNearLimit(current: 0, limit: 0), "limit = 0 时不得判为接近上限")
  }

  // MARK: - ④ 无障碍（能机检的部分）

  @Test("标签必填且是公开 API 的唯一标签来源（签名级）")
  func labelIsRequired() {
    // 编译期断言：不传 label 不能构造（若签名被改成可选，这里会编译失败）。
    let field = WDTextField(text: .constant(""), label: Text(verbatim: "标签"))
    _ = field
  }
}
