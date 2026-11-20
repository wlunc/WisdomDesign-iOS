import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDSwitch`（M2）的组件级断言：几何自洽、触控下限、放大档不裁切、拖动换算与吸附。
///
/// 几何口径（设计 05 §3）：轨道 51×31、滑块 27（轨道高 − 4）、行程 20。
@MainActor
@Suite("WDSwitch（M2）")
struct WDSwitchTests {
  private static func height(
    _ typeSize: DynamicTypeSize = .large,
    description: Text? = nil,
    size: WDSwitchSize = .standard
  ) -> CGFloat {
    let toggle: WDSwitch
    if description == nil, size == .standard {
      toggle = WDSwitch(isOn: .constant(true), label: Text(verbatim: "共享给家人"))
    } else {
      toggle = WDSwitch(
        isOn: .constant(true), label: Text(verbatim: "共享给家人"),
        description: description, size: size)
    }
    let controller = UIHostingController(
      rootView:
        toggle
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
  }

  @Test("几何自洽：滑块 = 轨道高 − 4；行程 = 宽 − 滑块 − 两侧内边距")
  func metrics() {
    #expect(WDSwitch.Metrics.knobDiameter == WDSwitch.Metrics.trackHeight - 4)
    #expect(
      WDSwitch.Metrics.knobTravel == WDSwitch.Metrics.trackWidth - WDSwitch.Metrics.knobDiameter - 4
    )
  }

  @Test("紧凑档几何自洽（40×24 / 滑块 20 / 行程 16）；rawValue 稳定")
  func compactMetrics() {
    #expect(WDSwitchSize.allCases.map(\.rawValue) == ["standard", "compact"])
    #expect(WDSwitch.Metrics.compactKnobDiameter == WDSwitch.Metrics.compactTrackHeight - 4)
    #expect(
      WDSwitch.Metrics.compactKnobTravel
        == WDSwitch.Metrics.compactTrackWidth - WDSwitch.Metrics.compactKnobDiameter - 4)
  }

  @Test("描述位增加一行高度")
  func descriptionAddsHeight() {
    let plain = Self.height(.accessibility3)
    let described = Self.height(.accessibility3, description: Text(verbatim: "关闭后不再收到推送"))
    #expect(described > plain, "带描述 \(described) 应高于无描述 \(plain)")
    #expect(Self.height(size: .compact) >= WDSize.touchTargetMin - 0.5)
  }

  @Test("整行触控下限 ≥ 44（标签 + 轨道）")
  func meetsTouchTarget() {
    let measured = Self.height()
    #expect(measured >= WDSize.touchTargetMin - 0.5, "实测行高 \(measured)，应 ≥ 44")
  }

  @Test("AX5：行高随标签行盒增长（不裁切）")
  func growsAtAccessibilitySize() {
    let normal = Self.height(.large)
    let ax5 = Self.height(.accessibility5)
    #expect(ax5 > normal, "AX5 行高 \(ax5) 应大于默认档 \(normal)")
  }

  @Test("拖动换算：水平位移夹在两端，已在开态时可回拖")
  func dragOffsetClampsAtEnds() {
    let travel = WDSwitch.Metrics.knobTravel
    #expect(WDSwitchDrag.knobOffset(startOffset: 0, translation: -8, travel: travel) == 0)
    #expect(
      WDSwitchDrag.knobOffset(startOffset: 0, translation: travel + 8, travel: travel) == travel)
    #expect(
      WDSwitchDrag.knobOffset(startOffset: travel, translation: -8, travel: travel) == travel - 8)
  }

  @Test("拖动吸附：左/右/中点/两端按滑块中心是否过半")
  func dragSnapsAtHalfByKnobCenter() {
    for size in WDSwitchSize.allCases {
      let metrics = WDSwitch.Metrics.metrics(for: size)
      let left = WDSwitchDrag.knobCenterX(offset: 0, metrics: metrics)
      let right = WDSwitchDrag.knobCenterX(offset: metrics.knobTravel, metrics: metrics)
      let middle = WDSwitchDrag.knobCenterX(
        offset: metrics.knobTravel / 2, metrics: metrics)
      #expect(middle == metrics.trackWidth / 2, "\(size) 中点应落在轨道中心")
      #expect(!WDSwitchDrag.isOn(knobCenterX: left, trackWidth: metrics.trackWidth))
      #expect(WDSwitchDrag.isOn(knobCenterX: right, trackWidth: metrics.trackWidth))
      #expect(
        !WDSwitchDrag.isOn(knobCenterX: middle, trackWidth: metrics.trackWidth),
        "恰在中点归关，松手吸附到左端")
      #expect(WDSwitchDrag.isOn(knobCenterX: middle + 1, trackWidth: metrics.trackWidth))
    }
  }

  @Test("拖动方向判定：纵向交给父级 ScrollView，横向由开关接管")
  func dragAxisGate() {
    #expect(WDSwitchDrag.shouldBegin(translation: CGSize(width: 6, height: 1)))
    #expect(!WDSwitchDrag.shouldBegin(translation: CGSize(width: 1, height: 6)))
    #expect(WDSwitchDrag.shouldBegin(translation: CGSize(width: 0, height: 0)))
  }

  // MARK: - B16 写入失败回弹（纯判定）

  @Test("采纳：宿主写回意图值 ⇒ 不判定失败")
  func writebackAcceptedIsNotFailure() {
    #expect(WDSwitchWriteback.outcome(intent: true, current: true) == nil)
    #expect(WDSwitchWriteback.outcome(intent: false, current: false) == nil)
    #expect(!WDSwitchWriteback.needsCheck(binding: true, intent: true))
  }

  @Test("回滚：宿主未采纳（binding 仍是旧值）⇒ 回弹到 binding 当前值")
  func writebackRejectedRollsBack() {
    let keptOff = WDSwitchWriteback.outcome(intent: true, current: false)
    #expect(keptOff == WDSwitchWriteback.Failure(intent: true, restore: false))
    let keptOn = WDSwitchWriteback.outcome(intent: false, current: true)
    #expect(keptOn == WDSwitchWriteback.Failure(intent: false, restore: true))
    #expect(WDSwitchWriteback.needsCheck(binding: false, intent: true))
  }

  @Test("回弹目标 = binding 当前值（不是把意图取反）")
  func writebackRestoresToCurrentBinding() {
    // 关 → 用户开；宿主没采纳，binding 仍是关 ⇒ 回弹到关。
    #expect(WDSwitchWriteback.outcome(intent: true, current: false)?.restore == false)
    // 开 → 用户关；宿主没采纳，binding 仍是开 ⇒ 回弹到开。
    let failure = WDSwitchWriteback.outcome(intent: false, current: true)
    #expect(failure?.restore == true)
    #expect(failure?.intent == false)
  }

  @Test("连点两次：只认最后一个意图（旧意图不参与判定）")
  func lastIntentWins() {
    // 用户 关 → 开（意图 true）→ 关（意图 false）；核对时 binding 仍是 false = 最后一次被采纳。
    #expect(WDSwitchWriteback.outcome(intent: false, current: false) == nil)
    // 若最后一次也没落盘（binding 仍 true），失败意图是"最后那次"，回弹到 true。
    let failure = WDSwitchWriteback.outcome(intent: false, current: true)
    #expect(failure?.intent == false)
    #expect(failure?.restore == true)
  }

  @Test("无意图（nil）：外部改写 binding 不触发判定")
  func noIntentNeverFails() {
    #expect(WDSwitchWriteback.outcome(intent: nil, current: true) == nil)
    #expect(WDSwitchWriteback.outcome(intent: nil, current: false) == nil)
    #expect(!WDSwitchWriteback.needsCheck(binding: true, intent: nil))
    #expect(!WDSwitchWriteback.needsCheck(binding: false, intent: nil))
  }

  @Test("拖动中反复切换：同一意图 + 同一 binding 的失败只回调一次（去重键）")
  func repeatedFailureDeduplicates() {
    let first = WDSwitchWriteback.Failure(intent: true, restore: false)
    // 拖动中第 2、3 次落到同一意图、binding 仍未被采纳 ⇒ 判定结果与首次相等 ⇒ 被去重。
    for _ in 0..<3 {
      #expect(WDSwitchWriteback.outcome(intent: true, current: false) == first)
    }
    #expect(WDSwitchWriteback.Failure(intent: false, restore: false) != first, "意图不同不合并")
  }

  @Test("纯判定不依赖视图：needsCheck 与 outcome 口径一致")
  func outcomeMatchesNeedsCheck() {
    for intent in [nil, true, false] as [Bool?] {
      for current in [true, false] {
        let needs = WDSwitchWriteback.needsCheck(binding: current, intent: intent)
        #expect((WDSwitchWriteback.outcome(intent: intent, current: current) != nil) == needs)
      }
    }
  }

  // MARK: - B16 写入失败回弹（视图层：默认参数与新重载的几何一致）

  @Test("是否带 onWriteFailure 不影响布局尺寸（默认参数路径零视觉变化）")
  func writeFailureClosureDoesNotChangeLayout() {
    let size = CGSize(width: 320, height: CGFloat.infinity)
    let legacy = UIHostingController(
      rootView: WDSwitch(isOn: .constant(true), label: Text(verbatim: "共享给家人")).wdTheme(.light)
    ).sizeThatFits(in: size)
    let withFailure = UIHostingController(
      rootView:
        WDSwitch(
          isOn: .constant(true), label: Text(verbatim: "共享给家人"), onWriteFailure: { _ in }
        ).wdTheme(.light)
    ).sizeThatFits(in: size)
    let compact = UIHostingController(
      rootView:
        WDSwitch(
          isOn: .constant(false), label: Text(verbatim: "共享给家人"),
          description: Text(verbatim: "关闭后不再收到推送"), size: .compact,
          onWriteFailure: { _ in }
        ).wdTheme(.light)
    ).sizeThatFits(in: size)
    #expect(abs(withFailure.height - legacy.height) <= 0.5)
    #expect(compact.height >= WDSize.touchTargetMin - 0.5, "紧凑档行高 \(compact.height)，应 ≥ 44")
  }

  @Test("写入失败回路（注入式）：未采纳 ⇒ 回弹到 binding 当前值并回调一次；再落同一失败不重复回调")
  func rejectedWriteRollsBackAndReportsOnce() async {
    let store = WritebackStore(value: true)
    var calls: [Bool] = []
    // 第一轮：用户意图 = 关，宿主不采纳。
    var failure = await settle(
      store: store, intent: false, reported: nil, accepts: false, calls: &calls)
    #expect(store.value == true, "宿主没采纳，binding 必须还是 true（已回弹到当前值）")
    #expect(calls == [false], "失败回调一次，参数 = 用户意图")
    // 第二轮：拖动中又落到同一失败（同 binding + 同意图）⇒ 去重，不再回调。
    failure = await settle(
      store: store, intent: false, reported: failure, accepts: false, calls: &calls)
    #expect(calls.count == 1, "拖动中反复切换只回调一次")
    #expect(failure != nil)
  }

  @Test("写入失败回路（注入式）：宿主采纳时不回弹、不回调")
  func acceptedWriteNeverCallsBack() async {
    let store = WritebackStore(value: false)
    var calls: [Bool] = []
    let failure = await settle(
      store: store, intent: true, reported: nil, accepts: true, calls: &calls)
    #expect(store.value == true)
    #expect(failure == nil)
    #expect(calls.isEmpty)
  }

  @Test("写入失败回路（注入式）：外部改写 binding 不产生意图，不回调也不回弹")
  func externalWriteHasNoIntent() async {
    let store = WritebackStore(value: false)
    var calls: [Bool] = []
    // 外部（非本组件）直接把 binding 写成 true：没有意图。
    store.value = true
    let failure = await settle(
      store: store, intent: nil, reported: nil, accepts: false, calls: &calls)
    #expect(failure == nil)
    #expect(calls.isEmpty)
    #expect(store.value == true, "外部写入不被回弹")
  }
}

/// 可注入的受控值（模拟宿主 binding；测试内不依赖 SwiftUI）。
@MainActor
private final class WritebackStore {
  var value: Bool
  init(value: Bool) { self.value = value }
}

@MainActor
private func settle(
  store: WritebackStore, intent: Bool?, reported: WDSwitchWriteback.Failure?, accepts: Bool,
  calls: inout [Bool]
) async -> WDSwitchWriteback.Failure? {
  // 走一遍「写 → 让出 → 判定 → 回弹 → 回调」：与组件内 `settlePendingWrite` 同一口径。
  // accepts = 宿主是否采纳（false = 写回失败，binding 保持原样）。
  WritebackDriver.write(store: store, intent: intent, accepts: accepts)
  await Task.yield()
  guard let failure = WDSwitchWriteback.outcome(intent: intent, current: store.value) else {
    return nil
  }
  guard failure != reported else { return failure }
  store.value = failure.restore
  calls.append(failure.intent)
  return failure
}

/// 模拟内层写回视图：先记意图，再写宿主；写不进去时宿主值保持原样。
@MainActor
private enum WritebackDriver {
  /// 写入宿主：nil 意图 = 没有用户写入（外部改写），什么都不做。
  static func write(store: WritebackStore, intent: Bool?, accepts: Bool) {
    guard let intent, accepts, store.value != intent else { return }
    store.value = intent
  }
}
