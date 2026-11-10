import Testing

@testable import WisdomUI

/// `WDAnnouncementThrottle`：纯逻辑节流（设计口径 = `06-accessibility.md` §3.5）。
///
/// 规则：进度只在**向上跨过** 25/50/75/100 时播（最多 4 次）；滑块拖动不播、松手后播一次。
@Suite("播报节流（WDAnnouncementThrottle）")
struct WDAnnouncementThrottleTests {
  private static let progressThresholds: [Double] = [0.25, 0.5, 0.75, 1]

  @Test("向上跨阈值才播：一次跨多个阈值也只返回一次 true")
  func crossingUpwards() {
    #expect(
      WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.1, current: 0.3, thresholds: Self.progressThresholds))
    #expect(
      WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.1, current: 0.9, thresholds: Self.progressThresholds),
      "0.1 → 0.9 跨了 25/50/75 三个阈值，调用方只播一次")
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.3, current: 0.45, thresholds: Self.progressThresholds),
      "0.3 → 0.45 没跨任何阈值")
  }

  @Test("边界：恰好等于阈值算跨过；等于上一值不重复播；回落不播")
  func boundaries() {
    #expect(
      WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.1, current: 0.25, thresholds: Self.progressThresholds),
      "恰好到 25% 应播")
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.25, current: 0.3, thresholds: Self.progressThresholds),
      "已播过的阈值不得重复播")
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.5, current: 0.5, thresholds: Self.progressThresholds),
      "值没变不播")
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.6, current: 0.4, thresholds: Self.progressThresholds),
      "回落不播（避免重置进度时刷屏）")
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(previous: 0.1, current: 0.9, thresholds: []),
      "空阈值集合不播")
  }

  @Test("阈值集合顺序无关（实现内部不做排序假设）")
  func thresholdsOrderIndependent() {
    #expect(
      WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.1, current: 0.6, thresholds: [1, 0.75, 0.25, 0.5]))
  }

  @Test("释放节流：首次必播；1s 内不播；到 1s / 更久播")
  func afterRelease() {
    let clock = ContinuousClock()
    let start = clock.now
    #expect(WDAnnouncementThrottle.shouldAnnounceAfterRelease(now: start, last: nil))
    #expect(
      !WDAnnouncementThrottle.shouldAnnounceAfterRelease(
        now: start.advanced(by: .milliseconds(500)), last: start))
    #expect(
      WDAnnouncementThrottle.shouldAnnounceAfterRelease(
        now: start.advanced(by: .seconds(1)), last: start))
    #expect(
      WDAnnouncementThrottle.shouldAnnounceAfterRelease(
        now: start.advanced(by: .seconds(5)), last: start))
  }
}
