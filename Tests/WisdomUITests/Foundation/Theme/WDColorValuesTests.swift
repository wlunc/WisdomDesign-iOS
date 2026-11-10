import SwiftUI
import Testing

@testable import WisdomUI

/// 颜色值类型与 32 个语义槽位（U12；M3 的 `Foundation/**` 覆盖率门槛从这里补）。
@MainActor
@Suite("颜色槽位（WDColorValues）")
struct WDColorValuesTests {
  @Test("32 个槽位（U12）、rawValue 唯一、含 text.disabled")
  func slotInventory() {
    #expect(WDColorSlot.allCases.count == 32)
    #expect(Set(WDColorSlot.allCases.map(\.rawValue)).count == 32)
    #expect(WDColorSlot.allCases.contains(.textDisabled))
    #expect(
      WDColorSlot.allCases.allSatisfy { slot in
        slot.rawValue == slot.rawValue.lowercased()
      })
  }

  @Test("默认 scheme = light；light 与 dark 是两套不同的值")
  func schemes() {
    #expect(WDColorValues.default == .light)
    #expect(WDColorValues.light != WDColorValues.dark)
    #expect(WDColorValues.wdDefaultScheme == "light")
    #expect(WDColorValues.wdSchemeNames == ["light", "dark"])
  }

  @Test("补丁构造：只覆盖给定槽位，其余取 default 基线")
  func patchOverride() {
    let patched = WDColorValues(WDColorOverrides(bgCanvas: Color.red))
    #expect(patched.bgCanvas == .red)
    #expect(patched.textPrimary == WDColorValues.default.textPrimary)
    #expect(patched.surfaceTint == WDColorValues.default.surfaceTint)
    #expect(patched != WDColorValues.default)

    let same = WDColorValues(WDColorOverrides(bgCanvas: Color.red))
    #expect(patched == same)
  }

  @Test("空补丁 = 默认基线（未覆盖槽位全取 default）")
  func emptyPatchIsDefault() {
    #expect(WDColorValues(WDColorOverrides()) == WDColorValues.default)
  }
}
