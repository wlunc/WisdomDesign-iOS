import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDSearchField`（M5）结果数播报注入点（清单 B1）的断言。
///
/// 口径（设计 04 §8/§10）：结果数用 `aria-live="polite"` 播报、**不要每次按键都播**；
/// 库内零文案 ⇒ 本件只回传**结果数**，措辞由调用方给。判定 = `WDSearchResultAnnouncement`。
@MainActor
@Suite("WDSearchField（M5 · 结果数播报）")
struct WDSearchFieldTests {
  /// 播报计数：把 `announcer` 收到的事件按顺序攒起来（测试用捕获器，不真的发声）。
  ///
  /// 标 `@MainActor` 有两个作用：① 与 `announcer` 的签名（`@MainActor @Sendable`）同一隔离域，
  /// 捕获器可在闭包里直接改 `counts`；② 全局 actor 隔离的类隐式满足 `Sendable`，
  /// 于是 `[weak self]` 捕获不会在 Swift 6 严格并发下报 "sending 'self' risks causing data races"。
  @MainActor
  private final class AnnouncementRecorder {
    var counts: [Int] = []

    /// 转成可注入的 `announcer`（冻结签名 B14）。
    var callback: @MainActor @Sendable (Int) -> Void {
      { [weak self] count in self?.counts.append(count) }
    }
  }

  /// 按冻结签名渲染（默认走标准变体；播报回调走**组件参数** = 冻结签名 B14）。
  private static func host(
    resultCount: Int? = nil,
    announcer: (@MainActor @Sendable (Int) -> Void)? = nil
  ) -> UIHostingController<some View> {
    let field = WDSearchField(
      text: .constant("储物间"),
      placeholder: Text(verbatim: "搜索任务或成员"),
      clearAccessibilityLabel: Text(verbatim: "清除搜索内容"),
      resultCount: resultCount,
      announcer: announcer
    )
    return UIHostingController(rootView: field.wdTheme(.light))
  }

  /// 让宿主完成一次布局（触发 `onChange(of:initial:)` 与状态推进）。
  private static func layout(_ controller: UIHostingController<some View>) {
    controller.view.bounds = CGRect(x: 0, y: 0, width: 320, height: 44)
    controller.view.layoutIfNeeded()
  }

  // MARK: - 判定纯函数（首帧 / 相等 / 增减 / 清空）

  @Test("判定纯函数：首帧不播（此前没计入过结果数）")
  func firstFrameNeverAnnounces() {
    for count in [-1, 0, 1, 3, 99] {
      let next = WDSearchResultAnnouncement.initial.next(current: count, announcing: true)
      #expect(next.announce == false, "首帧 \(count) 不应播报")
      #expect(next.announced == nil, "首帧不应带出待播的数")
      #expect(next.previous == count, "首帧要把计数记下来（作为下一次的基准）")
    }
  }

  @Test("判定纯函数：相等不播（按键但结果数没变 ⇒ 不回 announcer）")
  func equalCountNeverAnnounces() {
    let pinned = WDSearchResultAnnouncement(previous: 3, announce: true, announced: 3)
    for count in [3, 3] {
      let next = pinned.next(current: count, announcing: true)
      #expect(next.announce == false, "与上次相等的 \(count) 不应播报")
      #expect(next.announced == nil)
      #expect(next.previous == 3)
    }
  }

  @Test("判定纯函数：增加播报（0 → 3），带出新的结果数")
  func increaseAnnounces() {
    let next = WDSearchResultAnnouncement.initial
      .next(current: 0, announcing: true)
      .next(current: 3, announcing: true)
    #expect(next.announce == true)
    #expect(next.announced == 3)
    #expect(next.previous == 3)
  }

  @Test("判定纯函数：减少播报（7 → 2），带出新的结果数")
  func decreaseAnnounces() {
    let next = WDSearchResultAnnouncement.initial
      .next(current: 7, announcing: true)
      .next(current: 2, announcing: true)
    #expect(next.announce == true)
    #expect(next.announced == 2)
    #expect(next.previous == 2)
  }

  @Test("判定纯函数：搜到 0 条也算一次变化（4 → 0 播报 0）")
  func zeroResultAnnounces() {
    let next = WDSearchResultAnnouncement.initial
      .next(current: 4, announcing: true)
      .next(current: 0, announcing: true)
    #expect(next.announce == true)
    #expect(next.announced == 0)
  }

  @Test("判定纯函数：清空（nil）不播、不计入；回到同一个数也不重播")
  func clearingNeverAnnouncesAndKeepsBaseline() {
    let seeded = WDSearchResultAnnouncement.initial.next(current: 3, announcing: true)
    let cleared = seeded.next(current: nil, announcing: true)
    #expect(cleared.announce == false, "清空结果数不应播报")
    #expect(cleared.announced == nil)
    #expect(cleared.previous == 3, "清空不清掉基准：否则回来时会重播")

    let restored = cleared.next(current: 3, announcing: true)
    #expect(restored.announce == false, "清空后回到同一个数 → 值没变，不播")
    #expect(restored.previous == 3)

    let changed = restored.next(current: 0, announcing: true)
    #expect(changed.announce == true, "清空后回到另一个数（3 → 0）才播")
    #expect(changed.announced == 0)
  }

  @Test("判定纯函数：没有 announcer 时变化不计入（开关打开后首帧仍不播）")
  func changesWithoutAnnouncerDoNotCount() {
    let silent = WDSearchResultAnnouncement.initial.next(current: 5, announcing: false)
    #expect(silent.announce == false)
    #expect(silent.previous == nil, "没有播报回调 ⇒ 不记基准")

    let enabled = silent.next(current: 8, announcing: true)
    #expect(enabled.announce == false, "刚接上 announcer 的第一个数仍是首帧")

    let changed = enabled.next(current: 2, announcing: true)
    #expect(changed.announce == true)
    #expect(changed.announced == 2)
  }

  @Test("判定纯函数：换了播报配置 ⇒ 新配置的第一个数按首帧（不播），不拿旧计数误播")
  func newConfigurationStartsFresh() {
    let old = AnnouncementRecorder()
    let fresh = AnnouncementRecorder()
    let seeded = WDSearchResultAnnouncement.initial.next(current: 3, announcing: true)
    let switched = WDSearchResultAnnouncement.resetting(
      configuration: WDSearchAnnouncementConfig(resultCount: 5, announcer: fresh.callback))
    let first = switched.next(current: 5, announcing: true)
    #expect(switched == .initial, "换配置后记账回到初值")
    #expect(first.announce == false, "新配置的第一个结果数不播（否则会被旧计数 3 撞出一次误播）")
    #expect(first.previous == 5)
    let next = first.next(current: 2, announcing: true)
    #expect(next.announced == 2, "之后的变化照常播")
    #expect(old.counts.isEmpty && fresh.counts.isEmpty)
    #expect(seeded.previous == 3, "旧记账不被 mutation 掉（值类型）")
  }

  // MARK: - 组件接线

  @Test("组件：首帧布局不调用 announcer（即使已有结果数）")
  func componentDoesNotAnnounceOnFirstLayout() {
    let recorder = AnnouncementRecorder()
    Self.layout(Self.host(resultCount: 3, announcer: recorder.callback))
    #expect(recorder.counts.isEmpty, "首帧不应播报，实际 \(recorder.counts)")
  }

  @Test("组件：不传 announcer / 不传 resultCount 时与既有行为一致（零播报、不崩）")
  func componentToleratesMissingInjection() {
    let recorder = AnnouncementRecorder()
    Self.layout(Self.host(resultCount: 3))
    Self.layout(Self.host(resultCount: nil, announcer: recorder.callback))
    #expect(recorder.counts.isEmpty)
  }

  @Test("组件：默认参数路径尺寸不变（46 高；0.5pt 容差）")
  func defaultPathKeepsFieldHeight() {
    let controller = Self.host()
    let size = controller.sizeThatFits(
      in: CGSize(width: 320, height: CGFloat.infinity))
    #expect(abs(size.height - WDSize.fieldHeight) <= 0.5, "实测高 \(size.height)")
  }
}
