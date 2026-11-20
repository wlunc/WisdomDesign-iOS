import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// B18 的代码欠账收口断言：按下/聚焦反馈、角标朗读、阈值播报、滑杆松手播报。
///
/// 口径：设计 01 §5 / 02 §5 / 06 §5 / 08 §10 / 15 §10 / 34 §10 + SPEC §2.10 的播报列。
/// 全部为**纯逻辑与常量**断言（视图级需要真机/模拟器，见 `docs/B18-EXIT-REPORT.md`）。
@MainActor
@Suite("B18 代码欠账收口")
struct WDB18DebtTests {
  // MARK: - 按下 / 悬停亮度

  @Test("按钮亮度压暗蒙层：96% → 4%、98% → 2%（令牌 state.{pressed,hover}-brightness）")
  func dimOpacity() {
    #expect(WDState.pressedBrightness == 96)
    #expect(WDState.hoverBrightness == 98)
    #expect(abs(WDButtonStyle.dimOpacity(forBrightness: WDState.pressedBrightness) - 0.04) < 0.0001)
    #expect(abs(WDButtonStyle.dimOpacity(forBrightness: WDState.hoverBrightness) - 0.02) < 0.0001)
  }

  // MARK: - 聚焦光环口径（四处共用一组值）

  @Test("聚焦光环：宽 3pt = state.focus.ring-width；透明度 32% = state.focus.ring-alpha")
  func focusRingTokens() {
    #expect(WDFocusRingStyle.width == 3)
    #expect(WDFocusRingStyle.width == WDState.focusRingWidth)
    #expect(abs(WDFocusRingStyle.alpha - 0.32) < 0.0001)
    #expect(abs(WDFocusRingStyle.alpha - WDState.focusRingAlpha / 100) < 0.0001)
  }

  @Test("聚焦光环动画：160ms（motion.duration.fast）；Reduce Motion 直出")
  func focusRingAnimation() {
    #expect(WDFocusRingStyle.animation(reduceMotion: true) == nil)
    #expect(WDFocusRingStyle.animation(reduceMotion: false) != nil)
    #expect(WDMotion.Duration.fast == 0.16)
  }

  // MARK: - 复选框按下缩放

  @Test("复选框按下缩放 0.90（设计 06 §5 checkbox-press）")
  func checkboxPressedScale() {
    #expect(WDCheckbox.Metrics.pressedScale == 0.90)
  }

  // MARK: - 阈值播报（进度条 / 进度环）

  @Test("阈值：进度条与进度环同一组 25/50/75/100")
  func thresholdsMatch() {
    #expect(WDProgressBar.announcementThresholds == [0.25, 0.5, 0.75, 1])
    #expect(WDProgressRing.announcementThresholds == WDProgressBar.announcementThresholds)
  }

  @Test("跨阈值才播：25% 播一次、同档不重复、回落不播、跨多档也只播一次")
  func thresholdCrossing() {
    let thresholds = WDProgressBar.announcementThresholds
    #expect(
      WDAnnouncementThrottle.shouldAnnounce(previous: 0, current: 0.25, thresholds: thresholds))
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.25, current: 0.3, thresholds: thresholds))
    #expect(
      !WDAnnouncementThrottle.shouldAnnounce(
        previous: 0.75, current: 0.5, thresholds: thresholds))
    #expect(
      WDAnnouncementThrottle.shouldAnnounce(previous: 0.1, current: 0.9, thresholds: thresholds))
  }

  // MARK: - 松手播报的节流口径

  @Test("松手播报节流：首次一定播，1 秒内再播被挡")
  func releaseThrottle() {
    let now = ContinuousClock.now
    #expect(WDAnnouncementThrottle.shouldAnnounceAfterRelease(now: now, last: nil))
    #expect(!WDAnnouncementThrottle.shouldAnnounceAfterRelease(now: now, last: now))
    #expect(
      !WDAnnouncementThrottle.shouldAnnounceAfterRelease(
        now: now.advanced(by: .milliseconds(500)), last: now))
    #expect(
      WDAnnouncementThrottle.shouldAnnounceAfterRelease(
        now: now.advanced(by: .seconds(2)), last: now))
  }

  // MARK: - 角标朗读

  @Test("角标并入宿主的可朗读文本：count 数字 / label 原样 / dot 与 0 为 nil")
  func badgeAccessibilityText() {
    #expect(WDBadgeValue(count: 3).accessibilityText != nil)
    #expect(WDBadgeValue(count: 0).accessibilityText == nil)
    #expect(WDBadgeValue(count: 120).accessibilityText != nil)
    #expect(WDBadgeValue.dot.accessibilityText == nil)
    #expect(WDBadgeValue(label: Text(verbatim: "共享")).accessibilityText == Text(verbatim: "共享"))
  }

  @Test("计数超过 99 显示 99+（徽标与标签栏角标同源）")
  func badgeCountText() {
    #expect(WDBadge.countText(0) == "0")
    #expect(WDBadge.countText(5) == "5")
    #expect(WDBadge.countText(99) == "99")
    #expect(WDBadge.countText(100) == "99+")
  }
}
