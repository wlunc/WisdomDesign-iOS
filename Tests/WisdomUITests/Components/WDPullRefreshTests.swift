import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// 下拉刷新（设计 32）：阈值/尺寸/进度映射 + B12 阶段/超时竞速/三态文案/播报的纯逻辑断言。
@MainActor
@Suite("WDPullRefresh")
struct WDPullRefreshTests {
  // MARK: - 既有（M5）

  @Test("触发阈值 64、最大下拉 120（设计验收：误差 ≤ 2pt）")
  func thresholdAndMaximum() {
    #expect(abs(WDPullRefreshMetrics.triggerThreshold - 64) <= 2)
    #expect(abs(WDPullRefreshMetrics.maximumPull - 120) <= 2)
  }

  @Test("指示器直径 24、环线宽 2、与首行间距 space.4")
  func ringGeometry() {
    #expect(WDPullRefreshMetrics.ringDiameter == 24)
    #expect(WDPullRefreshMetrics.ringLineWidth == 2)
    #expect(WDPullRefreshMetrics.ringGap == WDSpacing.s4)
  }

  @Test("下拉距离：到顶后继续下拉才计数；顶部 inset 要扣掉")
  func pullDistance() {
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: 0, topInset: 0) == 0)
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: -30, topInset: 0) == 30)
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: -30, topInset: 10) == 20)
    // 正 offset（内容上移）不算下拉。
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: 40, topInset: 10) == 0)
  }

  @Test("环进度：0 → 0、半程 → 0.5、阈值 → 1、超限封顶 1")
  func progressMapping() {
    #expect(WDPullRefreshMetrics.progress(pull: 0) == 0)
    #expect(abs(WDPullRefreshMetrics.progress(pull: 32) - 0.5) < 0.0001)
    #expect(WDPullRefreshMetrics.progress(pull: 64) == 1)
    #expect(WDPullRefreshMetrics.progress(pull: 120) == 1)
  }

  @Test("阈值判定：64 及以上才触发；59 不触发（容差内）")
  func thresholdDecision() {
    #expect(!WDPullRefreshMetrics.isPastThreshold(0))
    #expect(!WDPullRefreshMetrics.isPastThreshold(59))
    #expect(WDPullRefreshMetrics.isPastThreshold(64))
    #expect(WDPullRefreshMetrics.isPastThreshold(120))
  }

  @Test("指示器：贴顶不越出容器；透明度随下拉 0 → 1")
  func indicatorPresentation() {
    #expect(WDPullRefreshMetrics.indicatorTop(pull: 0) == 0)
    #expect(WDPullRefreshMetrics.indicatorTop(pull: 20) == 0)
    #expect(WDPullRefreshMetrics.indicatorOpacity(pull: 0) == 0)
    #expect(
      abs(WDPullRefreshMetrics.indicatorOpacity(pull: WDPullRefreshMetrics.fadeInDistance) - 1)
        < 0.0001)
    #expect(WDPullRefreshMetrics.indicatorOpacity(pull: 200) == 1)
  }

  @Test("自绘层不改变锚点高度（覆盖 + offset 都不参与布局）")
  func anchorHeightUnchanged() {
    let controller = UIHostingController(
      rootView: Text(verbatim: "anchor")
        .wdPullRefresh(isRefreshing: .constant(false), label: Text(verbatim: "刷新")) {}
    )
    let modified = controller.sizeThatFits(
      in: CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude))
    let plain = UIHostingController(rootView: Text(verbatim: "anchor")).sizeThatFits(
      in: CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude))
    #expect(abs(plain.height - modified.height) <= 0.5)
  }

  // MARK: - B12 · 阶段纯函数（设计 32 §5/§7/§8）

  @Test("阶段：pull 0 → idle；63.9 → pulling；64 / 120 → armed")
  func resolveByPullDistance() {
    #expect(WDPullRefreshMetrics.resolve(pull: 0, isRefreshing: false, outcome: nil) == .idle)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 63.9, isRefreshing: false, outcome: nil) == .pulling)
    #expect(WDPullRefreshMetrics.resolve(pull: 64, isRefreshing: false, outcome: nil) == .armed)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 120, isRefreshing: false, outcome: nil) == .armed)
  }

  @Test("阶段：负值 / 极小值按 idle 或 pulling，不越界")
  func resolveBoundaries() {
    #expect(WDPullRefreshMetrics.resolve(pull: -5, isRefreshing: false, outcome: nil) == .idle)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 0.0001, isRefreshing: false, outcome: nil) == .pulling)
  }

  @Test("阶段：刷新中优先于任何下拉距离与结局")
  func resolveRefreshingWins() {
    #expect(WDPullRefreshMetrics.resolve(pull: 0, isRefreshing: true, outcome: nil) == .refreshing)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 120, isRefreshing: true, outcome: nil) == .refreshing)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 120, isRefreshing: true, outcome: .failed) == .refreshing)
  }

  @Test("阶段：成功窗口 ends 与 refresh 之间 → completed（不受下拉距离影响）")
  func resolveSuccessWindow() {
    #expect(
      WDPullRefreshMetrics.resolve(pull: 64, isRefreshing: false, outcome: .succeeded)
        == .completed)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 120, isRefreshing: false, outcome: .succeeded)
        == .completed)
  }

  @Test("阶段：失败窗口 → failed（先于下拉态，避免失败被画成「松开刷新」）")
  func resolveFailureWindow() {
    #expect(
      WDPullRefreshMetrics.resolve(pull: 120, isRefreshing: false, outcome: .failed) == .failed)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 0, isRefreshing: false, outcome: .failed) == .failed)
    #expect(
      WDPullRefreshMetrics.resolve(pull: 0, isRefreshing: true, outcome: .failed) == .refreshing)
  }

  @Test("阶段：started 不是结局（由 isRefreshing 表达）")
  func resolveStartedIsNotOutcome() {
    #expect(
      WDPullRefreshMetrics.resolve(pull: 0, isRefreshing: false, outcome: .started) == .idle)
  }

  @Test("阶段枚举：6 档且 String 原始值稳定（F-20）")
  func phaseCases() {
    #expect(
      WDPullRefreshPhase.allCases
        == [.idle, .pulling, .armed, .refreshing, .completed, .failed])
    #expect(WDPullRefreshPhase.failed.rawValue == "failed")
    #expect(WDPullRefreshPhase.refreshing.rawValue == "refreshing")
  }

  // MARK: - B12 · 超时竞速（设计 32 §8：10s，不自建 Timer）

  @Test("默认超时 = 10s（设计 32 §8）")
  func defaultTimeoutIsTenSeconds() {
    #expect(WDPullRefreshMetrics.defaultTimeout == .seconds(10))
  }

  @Test("竞速：动作先于截止时刻返回 → work")
  func raceWorkWins() {
    let start = ContinuousClock.now
    let deadline = start + .seconds(10)
    #expect(
      WDPullRefreshMetrics.raceWinner(workFinishedAt: start + .seconds(1), deadline: deadline)
        == .work)
  }

  @Test("竞速：动作晚于截止时刻返回 → timedOut")
  func raceTimeoutWins() {
    let start = ContinuousClock.now
    let deadline = start + .seconds(10)
    #expect(
      WDPullRefreshMetrics.raceWinner(workFinishedAt: start + .seconds(11), deadline: deadline)
        == .timedOut)
  }

  @Test("竞速：同一瞬间到达按超时判（宁可判失败）")
  func raceTieIsTimeout() {
    let deadline = ContinuousClock.now
    #expect(
      WDPullRefreshMetrics.raceWinner(workFinishedAt: deadline, deadline: deadline) == .timedOut)
  }

  @Test("结局合成：work + 不抛错 = 成功；work + 抛错 = 失败；超时 = 失败")
  func outcomeComposition() {
    #expect(WDPullRefreshMetrics.outcome(winner: .work, threw: false) == .succeeded)
    #expect(WDPullRefreshMetrics.outcome(winner: .work, threw: true) == .failed)
    #expect(WDPullRefreshMetrics.outcome(winner: .timedOut, threw: false) == .failed)
    #expect(WDPullRefreshMetrics.outcome(winner: .timedOut, threw: true) == .failed)
  }

  @Test("Result → 结局：失败结果 = failed；成功结果沿用动作结局；旧 init = nil")
  func outcomeFromResult() {
    let failed: Result<WDPullRefreshOutcome?, Error> = .failure(WDPullRefreshTimeoutError.timedOut)
    #expect(WDPullRefreshMetrics.outcome(for: failed, isObserved: true) == .failed)
    #expect(WDPullRefreshMetrics.outcome(for: .success(.succeeded), isObserved: true) == .succeeded)
    #expect(WDPullRefreshMetrics.outcome(for: failed, isObserved: false) == nil)
  }

  @Test("失败错误：超时原样交回；动作抛错解包成原始错误（不包装）")
  func failureErrorUnwrap() {
    let timeout: Result<WDPullRefreshOutcome?, Error> = .failure(
      WDPullRefreshTimeoutError.timedOut)
    #expect(WDPullRefreshMetrics.failureError(for: timeout) as? WDPullRefreshTimeoutError != nil)
    let original = URLError(.notConnectedToInternet)
    let wrapped: Result<WDPullRefreshOutcome?, Error> = .failure(
      WDPullRefreshFailure(error: original))
    let returned = WDPullRefreshMetrics.failureError(for: wrapped) as? URLError
    #expect(returned?.code == .notConnectedToInternet)
    #expect(WDPullRefreshMetrics.failureError(for: .success(.succeeded)) == nil)
  }

  // MARK: - B12 · 三态文案（设计 32 §2/§7）

  private var texts: WDPullRefreshTexts {
    WDPullRefreshTexts(
      pull: Text(verbatim: "pull"),
      release: Text(verbatim: "release"),
      refreshing: Text(verbatim: "refreshing"),
      completed: Text(verbatim: "completed"),
      failed: Text(verbatim: "failed")
    )
  }

  @Test("三态文案：pulling → pull、armed → release、refreshing → refreshing")
  func captionPerPhase() {
    #expect(
      WDPullRefreshMetrics.captionTexts(phase: .pulling, texts: texts) == Text(verbatim: "pull"))
    #expect(
      WDPullRefreshMetrics.captionTexts(phase: .armed, texts: texts) == Text(verbatim: "release"))
    #expect(
      WDPullRefreshMetrics.captionTexts(phase: .refreshing, texts: texts)
        == Text(verbatim: "refreshing"))
  }

  @Test("三态文案：idle / completed / failed 不显示环旁文案（设计 32 §7 只有三态）")
  func captionAbsentOutsideThreeStates() {
    #expect(WDPullRefreshMetrics.captionTexts(phase: .idle, texts: texts) == nil)
    #expect(WDPullRefreshMetrics.captionTexts(phase: .completed, texts: texts) == nil)
    #expect(WDPullRefreshMetrics.captionTexts(phase: .failed, texts: texts) == nil)
  }

  @Test("三态文案：texts 为 nil 或对应字段 nil ⇒ 不显示（只画环）")
  func captionNilTexts() {
    #expect(WDPullRefreshMetrics.captionTexts(phase: .pulling, texts: nil) == nil)
    let partial = WDPullRefreshTexts(pull: Text(verbatim: "pull"))
    #expect(WDPullRefreshMetrics.captionTexts(phase: .pulling, texts: partial) != nil)
    #expect(WDPullRefreshMetrics.captionTexts(phase: .armed, texts: partial) == nil)
    #expect(WDPullRefreshMetrics.captionTexts(phase: .refreshing, texts: partial) == nil)
  }

  @Test("文案位：全 nil / texts nil ⇒ 不建容器（逐像素不变的前提）")
  func captionSlot() {
    #expect(!WDPullRefreshMetrics.showsCaptionSlot(texts: nil))
    #expect(!WDPullRefreshMetrics.showsCaptionSlot(texts: WDPullRefreshTexts()))
    #expect(
      !WDPullRefreshMetrics.showsCaptionSlot(
        texts: WDPullRefreshTexts(
          completed: Text(verbatim: "c"), failed: Text(verbatim: "f"))
      ))
    #expect(WDPullRefreshMetrics.showsCaptionSlot(texts: texts))
  }

  @Test("texts：Sendable + Equatable（值语义比较）")
  func textsEquatable() {
    #expect(texts == texts)
    #expect(WDPullRefreshTexts() != texts)
  }

  // MARK: - B12 · 播报判定（开始 polite / 成功 polite / 失败 assertive）

  @Test("播报：开始 polite、成功 polite、失败 assertive")
  func announcementPriorities() {
    let started = WDPullRefreshMetrics.announcement(
      for: .started, texts: texts, isAnnouncerInjected: true)
    #expect(started?.text == Text(verbatim: "refreshing"))
    #expect(started?.priority == .polite)
    let succeeded = WDPullRefreshMetrics.announcement(
      for: .succeeded, texts: texts, isAnnouncerInjected: true)
    #expect(succeeded?.text == Text(verbatim: "completed"))
    #expect(succeeded?.priority == .polite)
    let failed = WDPullRefreshMetrics.announcement(
      for: .failed, texts: texts, isAnnouncerInjected: true)
    #expect(failed?.text == Text(verbatim: "failed"))
    #expect(failed?.priority == .assertive)
  }

  @Test("播报：没注入通道 ⇒ 一律不播")
  func announcementRequiresChannel() {
    #expect(
      WDPullRefreshMetrics.announcement(for: .started, texts: texts, isAnnouncerInjected: false)
        == nil)
    #expect(
      WDPullRefreshMetrics.announcement(for: .succeeded, texts: texts, isAnnouncerInjected: false)
        == nil)
    #expect(
      WDPullRefreshMetrics.announcement(for: .failed, texts: texts, isAnnouncerInjected: false)
        == nil)
  }

  @Test("播报：对应文案为 nil ⇒ 不播（失败文案缺省不影响开始/成功）")
  func announcementNilTexts() {
    let partial = WDPullRefreshTexts(refreshing: Text(verbatim: "refreshing"))
    #expect(
      WDPullRefreshMetrics.announcement(for: .failed, texts: partial, isAnnouncerInjected: true)
        == nil)
    #expect(
      WDPullRefreshMetrics.announcement(for: .succeeded, texts: partial, isAnnouncerInjected: true)
        == nil)
    #expect(
      WDPullRefreshMetrics.announcement(for: .started, texts: partial, isAnnouncerInjected: true)
        != nil)
    #expect(
      WDPullRefreshMetrics.announcement(for: .failed, texts: nil, isAnnouncerInjected: true) == nil)
  }

  // MARK: - B12 · 结局中继（失败通道的状态容器）

  @Test("中继：push → record → takeOutcome 读出并出栈；再读为 nil")
  func relayRoundTrip() {
    let relay = WDPullRefreshPhaseRelay.push()
    relay.record(.failed)
    #expect(relay.takeOutcome() == .failed)
    #expect(relay.takeOutcome() == nil)
  }

  @Test("中继：多令牌按各自记录取值，互不串（并发两次刷新）")
  func relayIsolation() {
    let first = WDPullRefreshPhaseRelay.push()
    let second = WDPullRefreshPhaseRelay.push()
    first.record(.failed)
    second.record(.succeeded)
    #expect(first.takeOutcome() == .failed)
    #expect(second.takeOutcome() == .succeeded)
  }

  // MARK: - B12 · 默认路径零视觉变化

  @Test("旧 init + 无 texts：锚点高度不变；新 init 的默认值同样不变")
  func anchorHeightUnchangedWithNewInit() {
    var isRefreshing = false
    let legacy = UIHostingController(
      rootView: Text(verbatim: "anchor")
        .wdPullRefresh(isRefreshing: .init(get: { isRefreshing }, set: { isRefreshing = $0 })) {}
    )
    let modern = UIHostingController(
      rootView: Text(verbatim: "anchor")
        .wdPullRefresh(
          isRefreshing: .init(get: { isRefreshing }, set: { isRefreshing = $0 }),
          onRefresh: {}
        )
    )
    let size = CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude)
    #expect(abs(legacy.sizeThatFits(in: size).height - modern.sizeThatFits(in: size).height) <= 0.5)
  }

  @Test("推断式调用不歧义：新 init（可抛错）能直接接住非抛错闭包")
  func newInitAcceptsNonThrowingClosure() {
    var isRefreshing = false
    _ = Text(verbatim: "anchor")
      .wdPullRefresh(
        isRefreshing: .init(get: { isRefreshing }, set: { isRefreshing = $0 }),
        label: Text(verbatim: "refresh"),
        onRefreshError: { _ in },
        timeout: .seconds(1),
        texts: WDPullRefreshTexts()
      ) {}
  }
}
