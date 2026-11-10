import Testing

@testable import WisdomUI

/// 触觉网关（SPEC §2.6.3 / DF-03 第 7 条）：可注入 sink + "一次操作最多一次"的预算闸门。
@MainActor
@Suite("触觉网关（WDHaptics）")
struct WDHapticsTests {
  private final class SpySink: WDHapticSink {
    var kinds: [WDHapticKind] = []
    func play(_ kind: WDHapticKind) {
      kinds.append(kind)
    }
  }

  @Test("可注入 sink：调用被捕获（不真的震动）")
  func sinkIsInjectable() {
    let spy = SpySink()
    WDHaptics.shared.sink = spy
    defer { WDHaptics.shared.sink = nil }

    WDHaptics.shared.play(.press, budget: .default)
    WDHaptics.shared.play(.toggle, budget: .default)
    #expect(spy.kinds == [.press, .toggle])
  }

  @Test("预算闸门：hapticsPerAction = 0 时不触发")
  func budgetGates() {
    let spy = SpySink()
    WDHaptics.shared.sink = spy
    defer { WDHaptics.shared.sink = nil }

    WDHaptics.shared.play(.press, budget: .default.reduced(hapticsPerAction: 0))
    #expect(spy.kinds.isEmpty)

    WDHaptics.shared.play(.press, budget: .default)
    #expect(spy.kinds.count == 1)
  }
}
