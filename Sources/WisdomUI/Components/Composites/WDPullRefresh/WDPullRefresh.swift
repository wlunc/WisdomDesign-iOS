import SwiftUI

/// 下拉刷新（SPEC §2.10-#32；设计 32）。
///
/// 设计口径：
/// - 自绘指示器（iOS 18+）：24pt 环 / 2pt 线宽 / 阈值 64 / 最大下拉 120 / 到阈值一次触觉；
///   下拉中环随位移画出进度，刷新中品牌弧 1s 线性旋转，完成后 160ms 收起（Reduce Motion ⇒ 静态弧）；
///   指示器覆盖在列表顶部、不改变锚点高度（设计 32 §6）；刷新中再次下拉不重复触发。
/// - 三态文案不进口袋：库内零文案（L-B / F-08）⇒ 本组件只画环（设计 32 §4 的「极简」变体）；
///   文案由调用方在组件外自行表达（本组件不提供阈值进度的回调）。
/// - iOS 17 回退：系统 .refreshable（系统视觉，登记差异）；行为仍为到阈值一次、进行中不可重复。
/// - label 非 nil 时挂「刷新」自定义无障碍操作（读屏用户不必会下拉）。
///
/// 差异登记：docs/M5-EXIT-REPORT.md（2026-11-14 自绘修正）。
public struct WDPullRefresh: ViewModifier {
  @Binding private var isRefreshing: Bool
  private let label: Text?
  private let onRefresh: @Sendable () async -> Void

  /// 构造：刷新状态 + 可选读屏标签 + 异步刷新动作。
  public init(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefresh: @escaping @Sendable () async -> Void
  ) {
    self._isRefreshing = isRefreshing
    self.label = label
    self.onRefresh = onRefresh
  }

  /// 把载体分支收进私有根视图：公开 body 的签名/属性保持冻结（API 基线零 diff）。
  public func body(content: Content) -> some View {
    WDPullRefreshRoot(
      content: content,
      isRefreshing: $isRefreshing,
      label: label,
      onRefresh: onRefresh
    )
  }
}

/// 载体选择：iOS 18+ 自绘环；iOS 17 回退系统 refreshable。
private struct WDPullRefreshRoot<Content: View>: View {
  let content: Content
  @Binding var isRefreshing: Bool
  let label: Text?
  let onRefresh: @Sendable () async -> Void

  @Environment(\.wdEffectsBudget) private var budget

  @ViewBuilder var body: some View {
    if #available(iOS 18.0, *) {
      WDPullRefreshSelfDrawn(
        content: content,
        isRefreshing: $isRefreshing,
        label: label,
        onRefresh: onRefresh
      )
    } else {
      content
        .refreshable { await performSystemRefresh() }
        .modifier(
          WDPullRefreshAccessibility(
            label: label,
            isRefreshing: $isRefreshing,
            onRefresh: onRefresh,
            budget: budget
          )
        )
    }
  }

  /// iOS 17 回退：一次刷新（进行中去重；开始时一次轻触觉）。
  @MainActor private func performSystemRefresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    WDHaptics.shared.play(.press, budget: budget)
    await onRefresh()
    isRefreshing = false
  }
}

extension View {
  /// 下拉刷新（iOS 18+ 自绘环；isRefreshing 反映刷新状态）。
  public func wdPullRefresh(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefresh: @escaping @Sendable () async -> Void
  ) -> some View {
    modifier(
      WDPullRefresh(isRefreshing: isRefreshing, label: label, onRefresh: onRefresh)
    )
  }
}

// MARK: - iOS 18+ 自绘载体

/// 自绘下拉刷新容器：读滚动几何（进度/回弹）+ 读滚动阶段（松手）+ 覆盖环。
@available(iOS 18.0, *)
private struct WDPullRefreshSelfDrawn<Content: View>: View {
  let content: Content
  @Binding var isRefreshing: Bool
  let label: Text?
  let onRefresh: @Sendable () async -> Void

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

  @ViewBuilder private var indicator: some View {
    if showsIndicator {
      WDPullRefreshRing(
        progress: WDPullRefreshMetrics.progress(pull: displayedPull),
        isRefreshing: isRefreshing || isCollapsing,
        isSpinning: (isRefreshing || isCollapsing)
          && !appearance.reduceMotion && budget.animatedRings > 0
      )
      .offset(y: WDPullRefreshMetrics.indicatorTop(pull: displayedPull))
      .opacity(isRefreshing ? 1 : WDPullRefreshMetrics.indicatorOpacity(pull: displayedPull))
      .allowsHitTesting(false)
    }
  }

  private var displayedPull: CGFloat {
    if isRefreshing || isCollapsing { return holdOffset }
    return pull
  }

  private var showsIndicator: Bool {
    isRefreshing || isCollapsing || pull > 0
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
  private func beginRefresh(hold: CGFloat) {
    guard !isRefreshing else { return }
    let target = min(
      max(hold, WDPullRefreshMetrics.triggerThreshold), WDPullRefreshMetrics.maximumPull)
    withAnimation(holdAnimation) { holdOffset = target }
    isRefreshing = true
    refreshGeneration += 1
    let generation = refreshGeneration
    Task { @MainActor in
      await onRefresh()
      if refreshGeneration == generation {
        isRefreshing = false
      }
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
private struct WDPullRefreshAccessibility: ViewModifier {
  let label: Text?
  let isRefreshing: Binding<Bool>
  let onRefresh: @Sendable () async -> Void
  let budget: WDEffectsBudget

  @ViewBuilder func body(content: Content) -> some View {
    if let label {
      content.accessibilityAction(named: label) {
        Task { @MainActor in
          guard !isRefreshing.wrappedValue else { return }
          isRefreshing.wrappedValue = true
          WDHaptics.shared.play(.press, budget: budget)
          await onRefresh()
          isRefreshing.wrappedValue = false
        }
      }
    } else {
      content
    }
  }
}
