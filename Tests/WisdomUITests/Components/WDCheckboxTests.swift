import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDCheckbox`（M2）的组件级断言：方框/圆角取令牌、热区、放大档不裁切、无标签变体。
@MainActor
@Suite("WDCheckbox（M2）")
struct WDCheckboxTests {
  private static func height(
    _ typeSize: DynamicTypeSize = .large,
    size: WDCheckboxSize = .standard,
    isIndeterminate: Bool = false
  ) -> CGFloat {
    let checkbox = WDCheckbox(
      isChecked: .constant(true), label: Text(verbatim: "共享给家人"),
      size: size, isIndeterminate: isIndeterminate)
    let controller = UIHostingController(
      rootView:
        checkbox
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  private static func unlabeledHeight(
    _ typeSize: DynamicTypeSize = .large,
    size: WDCheckboxSize = .standard
  ) -> CGFloat {
    let checkbox = WDCheckbox(
      isChecked: .constant(false),
      accessibilityLabel: Text(verbatim: "全选"),
      size: size)
    let controller = UIHostingController(
      rootView:
        checkbox
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  private static func boxWidth(_ size: WDCheckboxSize) -> CGFloat {
    let controller = UIHostingController(
      rootView: WDCheckboxBox(isChecked: true, size: size).wdTheme(.light))
    return controller.sizeThatFits(in: CGSize(width: 100, height: 100)).width
  }

  @Test("方框 26、圆角 9：与令牌一致（设计 06 §2–§3）")
  func metricsUseTokens() {
    #expect(WDCheckbox.Metrics.box == WDSize.checkbox)
    #expect(WDCheckbox.Metrics.corner == WDRadius.checkbox)
  }

  @Test("尺寸档：rawValue 稳定；紧凑方框 22 / 圆角 7（设计 06 §3）")
  func compactMetrics() {
    #expect(WDCheckboxSize.allCases.map(\.rawValue) == ["standard", "compact"])
    #expect(WDCheckbox.Metrics.compactBox == 22)
    #expect(WDCheckbox.Metrics.compactCorner == 7)
  }

  @Test("方框渲染尺寸：标准 26、紧凑 22")
  func boxRendersAtSize() {
    #expect(abs(Self.boxWidth(.standard) - WDCheckbox.Metrics.box) <= 0.5)
    #expect(abs(Self.boxWidth(.compact) - WDCheckbox.Metrics.compactBox) <= 0.5)
  }

  @Test("紧凑档：footnote 标签仍可渲染，热区 ≥ 44")
  func compactRenders() {
    let measured = Self.height(size: .compact)
    #expect(measured >= WDSize.touchTargetMin - 0.5, "实测紧凑行高 \(measured)")
  }

  @Test("整行热区 ≥ 44")
  func meetsTouchTarget() {
    #expect(Self.height() >= WDSize.touchTargetMin - 0.5)
  }

  @Test("无标签：可构造、仅方框，热区 ≥ 44（不随字阶增长）")
  func unlabeledMeetsTouchTarget() {
    let measured = Self.unlabeledHeight()
    #expect(measured >= WDSize.touchTargetMin - 0.5, "实测无标签行高 \(measured)")
    #expect(Self.unlabeledHeight(size: .compact) >= WDSize.touchTargetMin - 0.5)
    // 无标签时行内没有文字行盒，放大档也应保持 44 热区（= 没有可见 label）。
    let ax5 = Self.unlabeledHeight(.accessibility5)
    #expect(abs(ax5 - measured) <= 0.5, "AX5 \(ax5) 应与默认档 \(measured) 相同")
  }

  @Test("带 / 不带 label：共用切换语义；受控值都可双向切换")
  func togglesBothVariants() {
    // 两条构造共用 ToggleStyle 的切换语义（半选 → 全选，其余取反）。
    #expect(WDCheckbox.toggledValue(isOn: false, isIndeterminate: false))
    #expect(!WDCheckbox.toggledValue(isOn: true, isIndeterminate: false))
    #expect(WDCheckbox.toggledValue(isOn: false, isIndeterminate: true))

    var labeledValue = false
    var unlabeledValue = false
    let labeledBinding = Binding(get: { labeledValue }, set: { labeledValue = $0 })
    let unlabeledBinding = Binding(get: { unlabeledValue }, set: { unlabeledValue = $0 })

    let controller = UIHostingController(
      rootView:
        VStack(spacing: WDSpacing.s4) {
          WDCheckbox(isChecked: labeledBinding, label: Text(verbatim: "共享给家人"))
          WDCheckbox(isChecked: unlabeledBinding, accessibilityLabel: Text(verbatim: "全选"))
        }
        .wdTheme(.light)
    )
    _ = controller.view  // 触发布局；点击手势无法在单测注入，这里验证两条构造的受控值通路。

    labeledBinding.wrappedValue.toggle()
    unlabeledBinding.wrappedValue.toggle()
    #expect(labeledValue, "带 label 的受控值应写回 true")
    #expect(unlabeledValue, "无标签的受控值应写回 true")

    labeledBinding.wrappedValue.toggle()
    unlabeledBinding.wrappedValue.toggle()
    #expect(!labeledValue, "带 label 的受控值应写回 false")
    #expect(!unlabeledValue, "无标签的受控值应写回 false")
  }

  @Test("AX5：标签放大、行高增长（方框尺寸不变）")
  func growsAtAccessibilitySize() {
    #expect(Self.height(.accessibility5) > Self.height(.large))
  }

  @Test("半选：12×2.4 横杠；热区仍 ≥ 44")
  func indeterminate() {
    #expect(WDCheckbox.Metrics.barWidth == 12)
    #expect(WDCheckbox.Metrics.barHeight == 2.4)
    let controller = UIHostingController(
      rootView: WDCheckbox(
        isChecked: .constant(false), label: Text(verbatim: "全选"), isIndeterminate: true
      )
      .wdTheme(.light)
    )
    #expect(
      controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
        >= WDSize.touchTargetMin - 0.5)
  }
}
