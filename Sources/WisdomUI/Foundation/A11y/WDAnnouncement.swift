import Accessibility
import Foundation

/// 播报优先级（SPEC §2.6.2）。
public enum WDAnnouncementPriority: Sendable, Equatable {
  /// 排在当前朗读之后（不打断）。
  case polite
  /// 打断当前朗读（错误/失败）。
  case assertive
}

/// 播报网关（★ 去 `Sendable`；口径 = §1.2.1 隔离注解表）。
///
/// 库只提供**同步网关**，不替调用方决定"何时播报"；组件/调用方通过注入本协议把播报接到
/// 自己的无障碍通道上（测试用捕获器，不真的发声）。
@MainActor public protocol WDAnnouncing {
  /// 同步播报（无 `Task`）。
  func post(_ text: String, priority: WDAnnouncementPriority)
}

/// 系统播报实现：同步调 `AccessibilityNotification`（**无 `Task`**）。
///
/// iOS 17 的播报 API 没有 priority 形参 ⇒ 本实现的映射（差异已在代码内注明）：
///   · `polite` → `AccessibilityNotification.PageScrolled`（排在当前朗读之后，不打断）；
///   · `assertive` → `AccessibilityNotification.Announcement`（打断当前朗读）。
/// 空串一律不播（避免"读一个空白"）。
@MainActor public struct WDSystemAnnouncer: WDAnnouncing {
  /// 构造（无状态）。
  public init() {}

  /// 同步播报。
  public func post(_ text: String, priority: WDAnnouncementPriority) {
    guard !text.isEmpty else { return }
    switch priority {
    case .polite:
      AccessibilityNotification.PageScrolled(text).post()
    case .assertive:
      AccessibilityNotification.Announcement(text).post()
    }
  }
}

/// 播报节流（纯逻辑，两端同源 fixtures `announcement-cases.json`）。
///
/// 设计口径（`../wisdomdesign/docs/06-accessibility.md` §3.5）：进度只在跨过 25/50/75/100 时播
/// （最多 4 次）；拖动滑块不播、松手后播一次。**绝不能每个动画帧都播**。
public enum WDAnnouncementThrottle {
  /// 是否应播报：**向上跨过**任一阈值才播。
  ///
  /// - 一次跨多个阈值也只返回一次 `true`（调用方据此只播一次）；
  /// - 相等、回落、空阈值集合 ⇒ `false`（避免"重置进度"反复播报）。
  public static func shouldAnnounce(
    previous: Double,
    current: Double,
    thresholds: [Double]
  ) -> Bool {
    guard current > previous else { return false }
    return thresholds.contains { threshold in
      threshold > previous && threshold <= current
    }
  }

  /// 释放后是否应播报（滑块口径："拖动不播报，松手后播报一次"）。
  ///
  /// 两条闸门：① 从没播报过 ⇒ 播；② 距上次播报已过最小间隔 ⇒ 播（防止连点/连拖刷屏）。
  public static func shouldAnnounceAfterRelease(
    now: ContinuousClock.Instant,
    last: ContinuousClock.Instant?
  ) -> Bool {
    guard let last else { return true }
    return now - last >= minimumReleaseInterval
  }

  /// 释放播报的最小间隔。
  ///
  /// **跨端 fixture 尚未给值**（`announcement-cases.json` 未落库）⇒ 默认 1 秒；
  /// 已登记为 `docs/DEV-PLAN.md` §7 的 **D-8**（tech-lead/设计确认后改这一处）。
  static let minimumReleaseInterval: Duration = .seconds(1)
}
