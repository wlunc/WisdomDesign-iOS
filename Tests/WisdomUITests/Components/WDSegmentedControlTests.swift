import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// A-8：`WDSegmentedControl` 的段间拖动、方向键与位置文案（台账 A-8；设计 21 §8/§10）。
///
/// 交互换算全部走 `WDSegmentedControlInteraction` 的纯函数 ⇒ 不依赖手势注入即可断言
/// 「拖动位置 → 目标段 / 松手吸附 / 越界钳制 / 方向键端点」。
@MainActor
@Suite("分段控件交互（A-8）")
struct WDSegmentedControlTests {
  private static func png(_ text: Text) -> Data? {
    let renderer = ImageRenderer(
      content:
        text
        .frame(width: 240, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    )
    renderer.scale = 2
    return renderer.uiImage?.pngData()
  }

  private static func items(_ count: Int) -> [WDSegmentedControlItem] {
    (0..<count).map { WDSegmentedControlItem(id: "s\($0)", label: Text(verbatim: "s\($0)")) }
  }

  // MARK: - 拖动位置 → 目标段

  @Test("拖动位置 → 目标段：等分、边界左闭右开")
  func segmentIndexFromPosition() {
    // 3 段 × 120pt。
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 0, width: 360, count: 3) == 0)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 119, width: 360, count: 3) == 0)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 120, width: 360, count: 3) == 1)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 240, width: 360, count: 3) == 2)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 359, width: 360, count: 3) == 2)
    // 2 段 / 5 段同样等分。
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 200, width: 400, count: 2) == 1)
    for index in 0..<5 {
      let x = CGFloat(index) * 80 + 40
      #expect(WDSegmentedControlInteraction.segmentIndex(at: x, width: 400, count: 5) == index)
    }
  }

  @Test("拖动位置 → 目标段：越界钳制到首/末段；未量到宽时落到第 0 段")
  func segmentIndexClamps() {
    #expect(WDSegmentedControlInteraction.segmentIndex(at: -500, width: 360, count: 3) == 0)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 9999, width: 360, count: 3) == 2)
    // 首帧未量到宽（width == 0）与空段数：一律 0，调用方另有 width > 0 闸门。
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 100, width: 0, count: 3) == 0)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 100, width: 360, count: 0) == 0)
  }

  @Test("RTL：拖动换算镜像（视觉最右 = 第 0 段），与 LTR 对称")
  func segmentIndexMirrorsInRTL() {
    func index(_ x: CGFloat, _ rtl: Bool) -> Int {
      WDSegmentedControlInteraction.segmentIndex(
        at: x, width: 360, count: 3, isRTL: rtl)
    }
    // LTR：x=0 是第 0 段（视觉最左），x=359 是末段。
    #expect(index(0, false) == 0)
    #expect(index(359, false) == 2)
    // RTL：布局被系统整体镜像 ⇒ 视觉最左是末段、视觉最右是第 0 段。
    #expect(index(359, true) == 0)
    #expect(index(0, true) == 2)
    // 对称性：RTL 的 x 与 LTR 的 (width − x) 必须落在同一段。
    for x in stride(from: CGFloat(0), through: 360, by: 12) {
      #expect(index(360 - x, false) == index(x, true))
    }
  }
  @Test("松手吸附：跟手与吸附共用同一换算（跟到哪段就吸附到哪段）")
  func releaseSnapMatchesFollow() {
    // 断言对象是**换算本身的性质**，不是「同一函数同一实参比两次」（那种恒真）。
    // ① 每个落点都落在合法段内（不越界）；
    for x in stride(from: CGFloat(-20), through: 380, by: 10) {
      let follow = WDSegmentedControlInteraction.segmentIndex(at: x, width: 360, count: 3)
      #expect((0...2).contains(follow))
    }
    // ② 段边界处的换算必须可预期：360 宽 3 段 ⇒ 每段 120，边界 120/240。
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 0, width: 360, count: 3) == 0)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 119, width: 360, count: 3) == 0)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 120, width: 360, count: 3) == 1)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 239, width: 360, count: 3) == 1)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 240, width: 360, count: 3) == 2)
    #expect(WDSegmentedControlInteraction.segmentIndex(at: 359, width: 360, count: 3) == 2)
    // 中途不跳段：x 递增时段下标单调不减（不会在段之间来回跳）。
    var previous = 0
    for x in stride(from: CGFloat(0), through: 360, by: 1) {
      let index = WDSegmentedControlInteraction.segmentIndex(at: x, width: 360, count: 3)
      #expect(index >= previous)
      previous = index
    }
  }

  @Test("提交去重：拖回原段 / 点击已选项不重复提交（== nil）")
  func commitDedupe() {
    let ids = ["s0", "s1", "s2"]
    #expect(WDSegmentedControlInteraction.commitTarget(ids: ids, selected: "s0", index: 1) == "s1")
    #expect(WDSegmentedControlInteraction.commitTarget(ids: ids, selected: "s0", index: 0) == nil)
    // 越界下标不提交（不崩）。
    #expect(WDSegmentedControlInteraction.commitTarget(ids: ids, selected: "s0", index: -1) == nil)
    #expect(WDSegmentedControlInteraction.commitTarget(ids: ids, selected: "s0", index: 3) == nil)
    #expect(WDSegmentedControlInteraction.commitTarget(ids: [], selected: "s0", index: 0) == nil)
  }

  // MARK: - 方向键（设计 21 §8）

  /// 方向键的推进结果（简写：避免每行超 100 列）。
  private static func arrow(_ selected: Int, _ step: Int, rtl: Bool, count: Int = 3) -> Int {
    WDSegmentedControlInteraction.arrowIndex(
      selected: selected, visualStep: step, isRTL: rtl, count: count)
  }

  @Test("方向键：←/→ 各走一段，端点停住不环绕")
  func arrowIndexSteps() {
    #expect(Self.arrow(0, 1, rtl: false) == 1)
    #expect(Self.arrow(1, 1, rtl: false) == 2)
    // 右端继续按 → 停住（不环绕到第 0 段）。
    #expect(Self.arrow(2, 1, rtl: false) == 2)
    #expect(Self.arrow(0, -1, rtl: false) == 0)
    #expect(Self.arrow(1, -1, rtl: false) == 0)
  }

  @Test("方向键：RTL 下视觉方向反转（← = 下一段），端点同样停住")
  func arrowIndexRTL() {
    #expect(Self.arrow(0, -1, rtl: true) == 1)
    #expect(Self.arrow(2, 1, rtl: true) == 1)
    #expect(Self.arrow(2, -1, rtl: true) == 2)
    #expect(Self.arrow(0, 1, rtl: true) == 0)
  }

  @Test("方向键：段数为 0 时钳制到 0（不崩、不越界）")
  func arrowIndexEmpty() {
    #expect(Self.arrow(0, 1, rtl: false, count: 0) == 0)
    #expect(WDSegmentedControlInteraction.clampedIndex(5, count: 0) == 0)
    #expect(WDSegmentedControlInteraction.clampedIndex(-5, count: 4) == 0)
    #expect(WDSegmentedControlInteraction.clampedIndex(9, count: 4) == 3)
  }

  @Test("拖动接管：横向占优才接管（纵向留给父级滚动）")
  func dragAcceptsHorizontalOnly() {
    #expect(WDSegmentedControlInteraction.shouldBegin(translation: CGSize(width: 12, height: 3)))
    #expect(WDSegmentedControlInteraction.shouldBegin(translation: CGSize(width: 5, height: 5)))
    #expect(!WDSegmentedControlInteraction.shouldBegin(translation: CGSize(width: 3, height: 12)))
  }

  // MARK: - 位置文案（设计 21 §10）

  @Test("位置文案：拼接结果 == 调用方自己拼的 Text（分隔符由调用方给）")
  func positionLabelUsesCallerText() {
    let control = WDSegmentedControl(
      items: Self.items(3),
      selection: .constant("s1"),
      positionText: { index, total in Text(verbatim: "\(index)/\(total)") },
      positionSeparator: Text(verbatim: "|")
    )
    let first = control.positionAccessibilityLabel(index: 0) ?? Text(verbatim: "")
    let last = control.positionAccessibilityLabel(index: 2) ?? Text(verbatim: "")
    #expect(Self.png(first) == Self.png(Text(verbatim: "s0|1/3")))
    #expect(Self.png(last) == Self.png(Text(verbatim: "s2|3/3")))
  }

  @Test("位置文案：换分隔符就换结果（库内没有默认分隔符与默认措辞）")
  func positionLabelNoBuiltInSeparator() {
    let pipe = WDSegmentedControl(
      items: Self.items(2), selection: .constant("s0"),
      positionText: { index, total in Text(verbatim: "\(index)/\(total)") },
      positionSeparator: Text(verbatim: "|"))
    let slash = WDSegmentedControl(
      items: Self.items(2), selection: .constant("s0"),
      positionText: { index, total in Text(verbatim: "\(index)/\(total)") },
      positionSeparator: Text(verbatim: "／"))
    let a = Self.png(pipe.positionAccessibilityLabel(index: 0) ?? Text(verbatim: ""))
    let b = Self.png(slash.positionAccessibilityLabel(index: 0) ?? Text(verbatim: ""))
    #expect(a != b)
  }

  @Test("位置文案：未给 positionText ⇒ nil（沿用系统标签）；下标越界 ⇒ nil")
  func positionLabelOptional() {
    let plain = WDSegmentedControl(items: Self.items(2), selection: .constant("s0"))
    #expect(plain.positionAccessibilityLabel(index: 0) == nil)
    #expect(plain.positionAccessibilityLabel(index: 9) == nil)

    let withText = WDSegmentedControl(
      items: Self.items(2), selection: .constant("s0"),
      positionText: { index, total in Text(verbatim: "\(index)/\(total)") })
    #expect(withText.positionAccessibilityLabel(index: 2) == nil)
  }

  // MARK: - 既有行为不回归

  @Test("构造：位置文案参数带默认值，旧调用点源码不变")
  func defaultsKeepSourceCompatibility() {
    let control = WDSegmentedControl(items: Self.items(3), selection: .constant("s0"))
    let controller = UIHostingController(rootView: control)
    let proposal = CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude)
    let measured = controller.sizeThatFits(in: proposal)
    #expect(abs(measured.height - 38) <= 1)
    #expect(measured.width >= 3 * 56)
  }
}
