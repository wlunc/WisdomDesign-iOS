import SwiftUI

/// 下拉刷新（SPEC §2.10-#32；设计 32）。
///
/// 设计口径：
/// - 自绘指示器（iOS 18+）：24pt 环 / 2pt 线宽 / 阈值 64 / 最大下拉 120 / 到阈值一次触觉；
///   下拉中环随位移画出进度，刷新中品牌弧 1s 线性旋转，完成后 160ms 收起（Reduce Motion ⇒ 静态弧）；
///   指示器覆盖在列表顶部、不改变锚点高度（设计 32 §6）；刷新中再次下拉不重复触发。
/// - 三态文案不进口袋：库内零文案（L-B / F-08）⇒ 文案由调用方经 `texts` 注入，组件只透传 `Text`；
///   不传 `texts` 时只画环（设计 32 §4 的「极简」变体），与 B12 之前逐像素一致。
/// - 失败通道（设计 32 §7/§8）：刷新动作抛错或超过 `timeout`（默认 10s）⇒ 环收起 +
///   `isRefreshing = false` + `onRefreshError(error)` 一次；库内**不弹**提示（零文案），由调用方弹。
/// - 播报（设计 32 §8）：开始 polite / 成功 polite / 失败 assertive；只在注入了播报通道且文案非 nil 时播。
/// - iOS 17 回退：系统 .refreshable（系统视觉，登记差异）；行为仍为到阈值一次、进行中不可重复，
///   失败/超时/播报走同一份实现（`WDPullRefreshRunner`）。
/// - label 非 nil 时挂「刷新」自定义无障碍操作（读屏用户不必会下拉）。
///
/// 差异登记：docs/M5-EXIT-REPORT.md（2026-11-14 自绘修正）；B12 失败通道见 CHANGELOG。
public struct WDPullRefresh: ViewModifier {
  @Binding private var isRefreshing: Bool
  private let label: Text?
  private let onRefreshError: (@MainActor @Sendable (any Error) -> Void)?
  private let timeout: Duration
  private let texts: WDPullRefreshTexts?
  /// 刷新动作（返回本次刷新的结局；旧 init 固定返回 `.succeeded`，即无超时、无失败通道）。
  private let onRefresh: @MainActor @Sendable () async -> WDPullRefreshOutcome?

  /// 构造：刷新状态 + 可选读屏标签 + 异步刷新动作。
  ///
  /// 行为与 B12 之前一致：**无超时、无失败通道、不播报**（动作不抛错）。
  public init(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefresh: @escaping @Sendable () async -> Void
  ) {
    self._isRefreshing = isRefreshing
    self.label = label
    self.onRefreshError = nil
    self.timeout = WDPullRefreshMetrics.defaultTimeout
    self.texts = nil
    self.onRefresh = {
      await onRefresh()
      return .succeeded
    }
  }

  /// 把载体分支收进私有根视图：公开 body 的签名/属性保持冻结（API 基线零 diff）。
  public func body(content: Content) -> some View {
    WDPullRefreshRoot(
      content: content,
      isRefreshing: $isRefreshing,
      label: label,
      onRefreshError: onRefreshError,
      timeout: timeout,
      texts: texts,
      onRefresh: onRefresh
    )
  }
}

// MARK: - 公开面（B12）

/// 下拉刷新的阶段（设计 32 §5/§7/§8）。
///
/// 6 档：空闲 / 下拉中 / 已过阈值（松手即刷）/ 刷新中 / 完成 / 失败。
/// 判定入口 = `WDPullRefreshMetrics.resolve(pull:isRefreshing:outcome:)`（纯函数，可单测）。
public enum WDPullRefreshPhase: String, CaseIterable, Sendable, Equatable {
  /// 空闲：指示器隐藏在列表上方（设计 32 §5）。
  case idle
  /// 下拉中：未到阈值（设计 32 §5「下拉中」）。
  case pulling
  /// 已过阈值：松手即触发刷新（设计 32 §5「到阈值」）。
  case armed
  /// 刷新中：环固定显示并旋转（设计 32 §5「刷新中」）。
  case refreshing
  /// 完成：刷新动作正常返回，环收起中（设计 32 §5「完成」）。
  case completed
  /// 失败：刷新动作抛错或超时，环收起并交回调用方弹提示（设计 32 §7/§8）。
  case failed
}

/// 三态文案 / 状态播报的 L-B 注入点（库内零文案：设计 32 §7）。
///
/// `pull` / `release` / `refreshing` 是环旁的三态文案（设计 32 §7「下拉刷新 / 松开刷新 / 正在刷新」）；
/// `completed` / `failed` 只用于播报（设计 32 §8：失败不把错误文字挤在下拉区）。
/// 组件只**透传**这些 `Text`：不拼标点、不拼语序、不截断。
public struct WDPullRefreshTexts: Sendable, Equatable {
  /// 「下拉刷新」（pulling 态的环旁文案）。
  public var pull: Text?
  /// 「松开刷新」（armed 态的环旁文案）。
  public var release: Text?
  /// 「正在刷新」（refreshing 态的环旁文案；同时是「开始」播报的措辞）。
  public var refreshing: Text?
  /// 「刷新完成」（成功播报；nil = 不播）。
  public var completed: Text?
  /// 「刷新失败」（失败播报；nil = 不播）。
  public var failed: Text?

  /// 构造（全部可选：nil = 该态不显示 / 不播）。
  public init(
    pull: Text? = nil,
    release: Text? = nil,
    refreshing: Text? = nil,
    completed: Text? = nil,
    failed: Text? = nil
  ) {
    self.pull = pull
    self.release = release
    self.refreshing = refreshing
    self.completed = completed
    self.failed = failed
  }
}

extension WDPullRefresh {
  /// 带失败通道的构造（抛错／超时 = 失败；默认 10s 超时，设计 32 §8）。
  ///
  /// - Parameters:
  ///   - isRefreshing: 刷新状态（组件会把它置 true / false）。
  ///   - label: 读屏「刷新」自定义操作的名字（nil = 不挂该操作）。
  ///   - onRefreshError: 失败回调（抛错或超时；**只调一次**）。库内不弹提示（零文案），
  ///     提示由调用方在这里自己弹。
  ///   - timeout: 刷新动作的时限；超时 = 失败。
  ///   - texts: 三态文案与播报措辞（nil = 只画环，与 B12 之前逐像素一致）。
  ///   - onRefresh: 刷新动作（可抛错；在主 actor 上运行）。
  public init(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefreshError: (@MainActor @Sendable (any Error) -> Void)? = nil,
    timeout: Duration = .seconds(10),  // wd-structure-check:disable R7 — 设计 32 §8 超时 10s
    texts: WDPullRefreshTexts? = nil,
    onRefresh: @escaping @MainActor @Sendable () async throws -> Void
  ) {
    self._isRefreshing = isRefreshing
    self.label = label
    self.onRefreshError = onRefreshError
    self.timeout = timeout
    self.texts = texts
    self.onRefresh = {
      do {
        try await onRefresh()
        return .succeeded
      } catch {
        return .failed
      }
    }
  }
}

extension View {
  /// 下拉刷新（带失败通道：抛错／超时 ⇒ 收起 + `isRefreshing = false` + `onRefreshError` 一次）。
  ///
  /// 参数语义同 `WDPullRefresh.init(isRefreshing:label:onRefreshError:timeout:texts:onRefresh:)`。
  public func wdPullRefresh(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefreshError: (@MainActor @Sendable (any Error) -> Void)? = nil,
    timeout: Duration = .seconds(10),  // wd-structure-check:disable R7 — 设计 32 §8 超时 10s
    texts: WDPullRefreshTexts? = nil,
    onRefresh: @escaping @MainActor @Sendable () async throws -> Void
  ) -> some View {
    modifier(
      WDPullRefresh(
        isRefreshing: isRefreshing,
        label: label,
        onRefreshError: onRefreshError,
        timeout: timeout,
        texts: texts,
        onRefresh: onRefresh
      )
    )
  }
}

// MARK: - 载体根（iOS 18+ 自绘 / iOS 17 回退）

/// 载体选择：iOS 18+ 自绘环；iOS 17 回退系统 refreshable。
///
/// 两条分支共用同一套「单次刷新」实现（`WDPullRefreshRunner`）：失败/超时/播报只写一遍。
private struct WDPullRefreshRoot<Content: View>: View {
  let content: Content
  @Binding var isRefreshing: Bool
  let label: Text?
  let onRefreshError: (@MainActor @Sendable (any Error) -> Void)?
  let timeout: Duration
  let texts: WDPullRefreshTexts?
  let onRefresh: @MainActor @Sendable () async -> WDPullRefreshOutcome?

  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.wdAnnouncerText) private var announcer

  @ViewBuilder var body: some View {
    if #available(iOS 18.0, *) {
      WDPullRefreshSelfDrawn(
        content: content,
        isRefreshing: $isRefreshing,
        label: label,
        onRefreshError: onRefreshError,
        timeout: timeout,
        texts: texts,
        announcer: announcer,
        onRefresh: onRefresh
      )
    } else {
      content
        .refreshable { await performSystemRefresh() }
        .modifier(
          WDPullRefreshAccessibility(
            label: label,
            isRefreshing: $isRefreshing,
            timeout: timeout,
            texts: texts,
            announcer: announcer,
            onRefresh: onRefresh,
            onRefreshError: onRefreshError,
            budget: budget
          )
        )
    }
  }

  /// iOS 17 回退：一次刷新（进行中去重；开始时一次轻触觉）；失败/超时/播报同 `WDPullRefreshRunner`。
  @MainActor private func performSystemRefresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    WDHaptics.shared.play(.press, budget: budget)
    await WDPullRefreshRunner.run(
      isRefreshing: $isRefreshing,
      timeout: timeout,
      texts: texts,
      announcer: announcer,
      onRefresh: onRefresh,
      onRefreshError: onRefreshError
    )
  }
}

// MARK: - 单次刷新（B12：失败通道 / 超时 / 播报）

/// 刷新动作抛出的错误（内部：让「可抛错的调用方闭包」与「不抛错的执行器」对上，
/// 同时把错误原样交回 `onRefreshError`）。
struct WDPullRefreshFailure: Error {
  /// 调用方闭包抛出的原始错误（**不包装、不替换**：调用方要能自己判类型）。
  let error: any Error
}

/// 刷新超时（内部错误：不新增公开类型；调用方拿到的是 `any Error`）。
enum WDPullRefreshTimeoutError: Error, Equatable {
  /// 刷新动作在 `timeout` 内没有返回。
  case timedOut
}

/// 单次刷新的执行器（两条载体分支共用：iOS 18+ 自绘 / iOS 17 系统 refreshable）。
///
/// 口径（设计 32 §8）：
/// - 刷新动作 vs 超时**竞速**（`withTaskGroup` + `Task.sleep`；不建 Timer）：谁先到谁赢，同一瞬间按超时判；
/// - 失败（抛错或超时）⇒ `isRefreshing = false` + `onRefreshError(error)` **一次**；
/// - 成功 ⇒ `isRefreshing = false`（由本执行器置，调用点不做第二次写）；
/// - 播报：开始 polite / 成功 polite / 失败 assertive，只在注入通道且文案非 nil 时播。
@MainActor
enum WDPullRefreshRunner {
  /// 从「开始一次刷新」到「收起」的全过程。
  ///
  /// 调用方负责：去重（`isRefreshing` 为 true 时不重复进入）、置 `isRefreshing = true`、起始触觉。
  ///
  /// - Parameter relay: 本次结局写进它（栈式令牌，见 `WDPullRefreshPhaseRelay`）；
  ///   旧 init 路径 = 不写（不判定、不回调、不播报，等价于 B12 之前）。
  ///
  /// `onRefresh` 显式标 `@escaping`：它会被 `race` 的 task group 捕获（默认是 non-escaping）。
  static func run(
    isRefreshing: Binding<Bool>,
    timeout: Duration,
    texts: WDPullRefreshTexts?,
    announcer: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?,
    onRefresh: @escaping @MainActor @Sendable () async -> WDPullRefreshOutcome?,
    onRefreshError: (@MainActor @Sendable (any Error) -> Void)?,
    relay: WDPullRefreshPhaseRelay? = nil
  ) async {
    let announcerInjected = announcer != nil
    post(.started, texts: texts, announcer: announcer, announcerInjected: announcerInjected)
    let result = await race(timeout: timeout, work: onRefresh)
    // 没有结局 = 旧 init 路径（不判定、不回调、不播报）。
    let isObserved = onRefreshError != nil || texts != nil
    let outcome = WDPullRefreshMetrics.outcome(for: result, isObserved: isObserved)
    if let outcome { relay?.record(outcome) }
    isRefreshing.wrappedValue = false
    guard let outcome else { return }
    post(outcome, texts: texts, announcer: announcer, announcerInjected: announcerInjected)
    if let error = WDPullRefreshMetrics.failureError(for: result) {
      onRefreshError?(error)
    }
  }

  /// 竞速：刷新动作 vs 超时。返回「动作的结局（或错误）」或「超时」。
  ///
  /// 用 `TaskGroup` 而不是自建 Timer：超时分支是 `Task.sleep(for:)`；拿到第一个结果后 `cancelAll()`，
  /// 超时后动作即使仍在跑，其返回值也不再被采用（结构化的「谁先到谁赢」）。
  private static func race(
    timeout: Duration,
    work: @escaping @MainActor @Sendable () async -> WDPullRefreshOutcome?
  ) async -> Result<WDPullRefreshOutcome?, Error> {
    let deadline = ContinuousClock.now + timeout
    return await withTaskGroup(of: Result<WDPullRefreshOutcome?, Error>.self) { group in
      group.addTask {
        let outcome = await work()
        let winner = WDPullRefreshMetrics.raceWinner(
          workFinishedAt: .now,
          deadline: deadline
        )
        guard winner == .work else { return .failure(WDPullRefreshTimeoutError.timedOut) }
        return .success(outcome)
      }
      group.addTask {
        try? await Task.sleep(for: timeout)
        return .failure(WDPullRefreshTimeoutError.timedOut)
      }
      let first = await group.next() ?? .failure(WDPullRefreshTimeoutError.timedOut)
      group.cancelAll()
      return first
    }
  }

  /// 播报（判定收敛在 `WDPullRefreshMetrics.announcement(for:texts:isAnnouncerInjected:)`）。
  private static func post(
    _ outcome: WDPullRefreshOutcome,
    texts: WDPullRefreshTexts?,
    announcer: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?,
    announcerInjected: Bool
  ) {
    guard let announcer else { return }
    guard
      let item = WDPullRefreshMetrics.announcement(
        for: outcome,
        texts: texts,
        isAnnouncerInjected: announcerInjected
      )
    else { return }
    announcer(item.text, item.priority)
  }
}

// MARK: - iOS 18+ 自绘载体

/// 自绘下拉刷新容器：读滚动几何（进度/回弹）+ 读滚动阶段（松手）+ 覆盖环。
///
/// B12：环旁文案（三态 `texts` 注入）与失败通道（抛错/超时）都在这里接进生命周期；
/// `texts` 全 nil 时不建文案容器 ⇒ 只画环，与 B12 之前逐像素一致。
@available(iOS 18.0, *)
private struct WDPullRefreshSelfDrawn<Content: View>: View {
  let content: Content
  @Binding var isRefreshing: Bool
  let label: Text?
  let onRefreshError: (@MainActor @Sendable (any Error) -> Void)?
  let timeout: Duration
  let texts: WDPullRefreshTexts?
  let announcer: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?
  let onRefresh: @MainActor @Sendable () async -> WDPullRefreshOutcome?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  /// 当前下拉距离（由滚动几何得来；刷新/收起时不参与触发）。
  @State private var pull: CGFloat = 0
  /// 刷新期间把内容保持在释放时的下拉位置（等价于系统 refreshable 的 hold；不改布局高度）。
  @State private var holdOffset: CGFloat = 0
  /// 完成后的 160ms 收起阶段（期间仍画环、只做淡出）。
  @State private var isCollapsing = false
  /// 收起后忽略回弹期的几何，直到回弹归零或新手势开始。
  @State private var suppressPull = false
  /// 阈值触觉每次下拉只触发一次（设计 32 §8）。
  @State private var didFireThresholdHaptic = false
  /// 刷新任务代次：避免旧任务结束把新一次刷新关掉。
  @State private var refreshGeneration = 0
  /// 本次刷新的结局（nil = 没有结局）：阶段判定与播报的输入。
  @State private var outcome: WDPullRefreshOutcome?
  /// 收起起点的下拉距离（移除指示器的基线；避免 `pull` 归零与淡出动画抢帧）。
  @State private var settledPull: CGFloat = 0

  var body: some View {
    content
      .onScrollPhaseChange { oldPhase, newPhase in
        handlePhaseChange(from: oldPhase, to: newPhase)
      }
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        WDPullRefreshMetrics.pullDistance(
          offsetY: geometry.contentOffset.y,
          topInset: geometry.contentInsets.top
        )
      } action: { _, newValue in
        handlePull(newValue)
      }
      .offset(y: holdOffset)
      .overlay(alignment: .top) { indicator }
      .modifier(WDPullRefreshActions(label: label, action: activateFromAccessibility))
      .onChange(of: isRefreshing) { _, newValue in
        handleRefreshingChange(newValue)
      }
      .onAppear {
        if isRefreshing { beginExternalRefresh() }
      }
  }

  // MARK: - 指示器

  /// 当前阶段（纯函数判定；结局由 `outcome` 表达）。
  private var phase: WDPullRefreshPhase {
    WDPullRefreshMetrics.resolve(pull: pull, isRefreshing: isRefreshing, outcome: outcome)
  }

  @ViewBuilder private var indicator: some View {
    if showsIndicator {
      HStack(spacing: WDPullRefreshMetrics.textsGap) {
        ring
        caption
      }
      .offset(y: WDPullRefreshMetrics.indicatorTop(pull: displayedPull))
      .opacity(isRefreshing ? 1 : WDPullRefreshMetrics.indicatorOpacity(pull: displayedPull))
      .allowsHitTesting(false)
    }
  }

  private var ring: some View {
    WDPullRefreshRing(
      progress: WDPullRefreshMetrics.progress(pull: displayedPull),
      isRefreshing: isRefreshing || isCollapsing,
      isSpinning: (isRefreshing || isCollapsing)
        && !appearance.reduceMotion && budget.animatedRings > 0
    )
  }

  /// 环旁三态文案：调用方注入的 `Text` 只透传（字体走 `wdFont` + 行盒 `wdLineBox`）；
  /// 全 nil 时不建这个容器（`showsCaptionSlot`），保持只画环的原始排版。
  @ViewBuilder private var caption: some View {
    if hasCaptionSlot, let text = captionText {
      text
        .wdFont(WDType.footnote)
        .foregroundStyle(colors.textSecondary)
        .wdLineBox(WDType.footnote)
        .fixedSize()
    }
  }

  /// 是否保留文案位（三态文案全 nil ⇒ false：只画环，排版与 B12 之前一致）。
  private var hasCaptionSlot: Bool {
    WDPullRefreshMetrics.showsCaptionSlot(texts: texts)
  }

  /// 当前应当显示的三态文案（pulling / armed / refreshing；其余阶段 nil）。
  private var captionText: Text? {
    WDPullRefreshMetrics.captionTexts(phase: phase, texts: texts)
  }

  private var displayedPull: CGFloat {
    if isRefreshing || isCollapsing { return holdOffset }
    return pull
  }

  /// 指示器是否显示：刷新/收起中；或有结局（成功/失败）后仍在收起起点的上方。
  private var showsIndicator: Bool {
    if isRefreshing || isCollapsing { return true }
    if outcome != nil { return pull > settledPull }
    return pull > 0
  }

  // MARK: - 滚动事件

  /// 下拉距离变化：更新环进度、阈值触觉、重置。
  private func handlePull(_ newValue: CGFloat) {
    let clamped = min(max(newValue, 0), WDPullRefreshMetrics.maximumPull)
    if suppressPull {
      if clamped == 0 {
        suppressPull = false
        pull = 0
        didFireThresholdHaptic = false
      }
      return
    }
    guard !isRefreshing, !isCollapsing else { return }
    let crossedThreshold =
      pull < WDPullRefreshMetrics.triggerThreshold
      && clamped >= WDPullRefreshMetrics.triggerThreshold
    if abs(clamped - pull) >= WDPullRefreshMetrics.updateTolerance
      || clamped == 0
      || clamped == WDPullRefreshMetrics.maximumPull
      || crossedThreshold
    {
      pull = clamped
    }
    if !didFireThresholdHaptic, WDPullRefreshMetrics.isPastThreshold(clamped) {
      didFireThresholdHaptic = true
      WDHaptics.shared.play(.threshold, budget: budget)
    }
  }

  /// 滚动阶段变化：离开拖拽阶段时按当前下拉距离决定是否触发。
  private func handlePhaseChange(from oldPhase: ScrollPhase, to newPhase: ScrollPhase) {
    if isActivePhase(newPhase), !isActivePhase(oldPhase) {
      // 新手势开始：阈值触觉重新计数（同一次下拉只触发一次，设计 32 §8）。
      didFireThresholdHaptic = false
    }
    if suppressPull, isActivePhase(newPhase) {
      // 新手势打断回弹/收起：恢复可下拉状态。
      suppressPull = false
      pull = 0
      didFireThresholdHaptic = false
      return
    }
    guard !isRefreshing, !isCollapsing else { return }
    guard isActivePhase(oldPhase), !isActivePhase(newPhase) else { return }
    guard WDPullRefreshMetrics.isPastThreshold(pull) else { return }
    beginRefresh(hold: pull)
  }

  private func isActivePhase(_ phase: ScrollPhase) -> Bool {
    phase == .tracking || phase == .interacting
  }

  // MARK: - 刷新生命周期

  /// 松手触发（阈值为 64；进行中不重复触发）。
  ///
  /// 失败/超时/播报都交给 `WDPullRefreshRunner`；`isRefreshing` 的归零也在那里，
  /// 所以失败时环会经由 `handleRefreshingChange(false)` 的收起路径归位（设计 32 §7）。
  private func beginRefresh(hold: CGFloat) {
    guard !isRefreshing else { return }
    // 上一次结局到此为止：重新开始一次干净的阶段判定。
    outcome = nil
    let target = min(
      max(hold, WDPullRefreshMetrics.triggerThreshold), WDPullRefreshMetrics.maximumPull)
    withAnimation(holdAnimation) { holdOffset = target }
    isRefreshing = true
    refreshGeneration += 1
    let generation = refreshGeneration
    let relay = WDPullRefreshPhaseRelay.push()
    Task { @MainActor in
      await WDPullRefreshRunner.run(
        isRefreshing: $isRefreshing,
        timeout: timeout,
        texts: texts,
        announcer: announcer,
        onRefresh: onRefresh,
        onRefreshError: onRefreshError,
        relay: relay
      )
      guard refreshGeneration == generation else { return }
      // 读走本次结局（读后即清）：成功/失败决定环收起后的阶段（completed / failed）。
      outcome = relay.takeOutcome()
    }
  }

  /// 无障碍「刷新」动作：没有下拉手势，补一次按下触觉。
  private func activateFromAccessibility() {
    guard !isRefreshing else { return }
    WDHaptics.shared.play(.press, budget: budget)
    beginRefresh(hold: WDPullRefreshMetrics.triggerThreshold)
  }

  /// 外部把 isRefreshing 置 true（例如页面上的刷新按钮）：显示环并保持内容位置。
  private func beginExternalRefresh() {
    isCollapsing = false
    suppressPull = false
    if holdOffset == 0 {
      withAnimation(holdAnimation) { holdOffset = WDPullRefreshMetrics.triggerThreshold }
    }
  }

  /// isRefreshing 变化：外部 true = 显示；false = 160ms 收起。
  private func handleRefreshingChange(_ newValue: Bool) {
    if newValue {
      beginExternalRefresh()
    } else {
      beginCollapse()
    }
  }

  /// 完成收起：环与内容保持位移一起回落；160ms 后移除指示器。
  private func beginCollapse() {
    guard !isCollapsing else { return }
    isCollapsing = true
    suppressPull = true
    settledPull = holdOffset
    withAnimation(collapseAnimation) { holdOffset = 0 }
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(WDMotion.Duration.fast))
      guard !isRefreshing, isCollapsing else { return }
      isCollapsing = false
      pull = 0
      didFireThresholdHaptic = false
    }
  }

  // MARK: - 动效（Reduce Motion 归一；组件不另设开关）

  private var holdAnimation: Animation {
    if appearance.reduceMotion {
      return .linear(duration: WDMotion.Duration.reduced)
    }
    return WDMotion.Spring.snappy
  }

  private var collapseAnimation: Animation {
    if appearance.reduceMotion {
      return .linear(duration: WDMotion.Duration.reduced)
    }
    return .easeOut(duration: WDMotion.Duration.fast)
  }
}

// MARK: - 无障碍动作

/// 自绘载体的读屏动作：label 非 nil 时挂「刷新」（不强制手势）。
private struct WDPullRefreshActions: ViewModifier {
  let label: Text?
  let action: () -> Void

  @ViewBuilder func body(content: Content) -> some View {
    if let label {
      content.accessibilityAction(named: label) { action() }
    } else {
      content
    }
  }
}

/// iOS 17 回退的读屏动作：label 非 nil 时挂「刷新」动作（不强制手势）。
///
/// B12：失败/超时/播报同样走 `WDPullRefreshRunner`（与自绘载体口径一致）。
private struct WDPullRefreshAccessibility: ViewModifier {
  let label: Text?
  let isRefreshing: Binding<Bool>
  let timeout: Duration
  let texts: WDPullRefreshTexts?
  let announcer: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?
  let onRefresh: @MainActor @Sendable () async -> WDPullRefreshOutcome?
  let onRefreshError: (@MainActor @Sendable (any Error) -> Void)?
  let budget: WDEffectsBudget

  @ViewBuilder func body(content: Content) -> some View {
    if let label {
      content.accessibilityAction(named: label) {
        Task { @MainActor in
          guard !isRefreshing.wrappedValue else { return }
          isRefreshing.wrappedValue = true
          WDHaptics.shared.play(.press, budget: budget)
          await WDPullRefreshRunner.run(
            isRefreshing: isRefreshing,
            timeout: timeout,
            texts: texts,
            announcer: announcer,
            onRefresh: onRefresh,
            onRefreshError: onRefreshError
          )
        }
      }
    } else {
      content
    }
  }
}
