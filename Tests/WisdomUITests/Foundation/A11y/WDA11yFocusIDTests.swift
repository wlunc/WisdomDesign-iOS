import Testing

@testable import WisdomUI

/// `WDA11yFocusID`：`@AccessibilityFocusState` 需要 `Hashable`（`Text` 不行；SPEC §2.6.2 / I40）。
@Suite("焦点身份（WDA11yFocusID）")
struct WDA11yFocusIDTests {
  @Test("值相等与哈希一致（可放进 AccessibilityFocusState 做比较）")
  func hashingAndEquality() {
    let first = WDA11yFocusID(rawValue: "wd-field")
    let same = WDA11yFocusID(rawValue: "wd-field")
    let other = WDA11yFocusID(rawValue: "wd-row")

    #expect(first == same)
    #expect(first != other)
    #expect(first.hashValue == same.hashValue)
    #expect(Set([first, same, other]).count == 2)
    #expect(first.rawValue == "wd-field")
  }
}
