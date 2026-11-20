import SwiftUI

/// 下拉刷新自绘指示器的几何、阈值与失败通道（设计 32 §2/§3/§5/§8/§9）。
///
/// 设计值均自带出处；R7 的数值字面量豁免按仓规同行给理由（令牌里没有下拉环尺寸键）。
///
/// **纯逻辑归口**：阶段判定、超时竞速的结果选择、播报判定、三态文案选择都写成这里的静态函数
/// （无状态、无 UIKit、无 Task），组件层只负责把它们接进 SwiftUI 生命周期 ⇒ 可单测。
enum WDPullRefreshMetrics {
  /// 触发阈值（设计 32 §3：下拉超过此距离松手才刷新）。
  static let triggerThreshold: CGFloat = 64  // wd-structure-check:disable R7 — 设计 32 §3 触发阈值 64
  /// 最大下拉距离（设计 32 §3：超过后阻力显著增加；指示器按此封顶）。
  static let maximumPull: CGFloat = 120  // wd-structure-check:disable R7 — 设计 32 §3 最大下拉 120
  /// 指示器直径（设计 32 §3：24）。
  static let ringDiameter: CGFloat = 24  // wd-structure-check:disable R7 — 设计 32 §3 指示器直径 24
  /// 环线宽（设计 32 §3：2）。
  static let ringLineWidth: CGFloat = 2  // wd-structure-check:disable R7 — 设计 32 §3 环线宽 2
  /// 指示器与首行间距（设计 32 §3：space.4 = 12）。
  static let ringGap: CGFloat = WDSpacing.s4
  /// 环与文案的横向间距（设计 32 §6「指示器水平居中」；设计未给值 ⇒ 取最近间距令牌 space.2 = 8）。
  static let textsGap: CGFloat = WDSpacing.s2
  /// 刷新中旋转弧长（画廊 32「正在刷新」的环约顶部 1/4 品牌色；完整圆旋转不可见）。
  static let refreshingArc: CGFloat = 0.25  // wd-structure-check:disable R7 — 画廊 32 刷新环品牌弧约 1/4
  /// 刷新环旋转一周的时长（画廊 32 CSS：1s linear infinite）。
  static let spinDuration: Double = 1  // wd-structure-check:disable R7 — 画廊 32 环旋转 1s
  /// 渲染更新粒度（非设计值：0.25pt 内不触发重绘，降低逐帧 State 写入）。
  static let updateTolerance: CGFloat = 0.25  // wd-structure-check:disable R7 — 渲染更新粒度（实现常量）
  /// 默认刷新超时（设计 32 §8「刷新超时 10 秒后收起，按失败处理」）。
  static let defaultTimeout: Duration = .seconds(10)  // wd-structure-check:disable R7 — 设计 32 §8 超时
  /// 指示器从 0 到完全显出的距离（环直径 + 间距；不引入第三个魔数）。
  static let fadeInDistance: CGFloat = ringDiameter + ringGap

  /// 由滚动几何算下拉距离：到顶后继续下拉的位移（负 offset 减去顶部 inset）。
  static func pullDistance(offsetY: CGFloat, topInset: CGFloat) -> CGFloat {
    max(0, -(offsetY + topInset))
  }

  /// 下拉进度（0…1；到阈值即满）。
  static func progress(pull: CGFloat) -> CGFloat {
    min(max(pull / triggerThreshold, 0), 1)
  }

  /// 是否到达触发阈值（设计验收：误差 ≤ 2pt；这里按精确 64 判定，界面上环在 64 处闭合）。
  static func isPastThreshold(_ pull: CGFloat) -> Bool {
    pull >= triggerThreshold
  }

  /// 指示器在滚动视图顶部的纵向位置（随下拉跟随；贴顶时不越出容器）。
  static func indicatorTop(pull: CGFloat) -> CGFloat {
    max(0, pull - fadeInDistance)
  }

  /// 指示器透明度（下拉前段 0 → 1；设计 32 §5）。
  static func indicatorOpacity(pull: CGFloat) -> CGFloat {
    min(max(pull / fadeInDistance, 0), 1)
  }

  // MARK: - 阶段（B12：设计 32 §2/§5/§7/§8）

  /// 阶段判定：刷新中优先；其次看**本次**刷新的结局；没有结局时按下拉距离分「已过阈值 / 未过阈值」。
  ///
  /// - Parameters:
  ///   - pull: 当前下拉距离（pt；未下拉 = 0）。
  ///   - isRefreshing: 是否正在刷新（含外部把 binding 置 true 的情形）。
  ///   - outcome: 本次刷新的结局；`nil` = 本次没有结局（还没刷新 / 已回到空闲）。
  /// - Returns: `refreshing` > `failed` > `completed` > `armed`（pull ≥ 64）> `pulling`（pull > 0）> `idle`。
  ///
  /// 失败窗口 = 「抛错/超时 ⇒ 环收起、isRefreshing 归 false」的那一段（先判失败：此时下拉距离不可信）；
  /// 成功窗口 = 「动作正常返回 ⇒ 收起完成」的那一段（先判完成，同理）。
  static func resolve(
    pull: CGFloat,
    isRefreshing: Bool,
    outcome: WDPullRefreshOutcome?
  ) -> WDPullRefreshPhase {
    if isRefreshing { return .refreshing }
    if outcome == .failed { return .failed }
    if outcome == .succeeded { return .completed }
    if isPastThreshold(pull) { return .armed }
    if pull > 0 { return .pulling }
    return .idle
  }

  // MARK: - 竞速结果（B12：设计 32 §8 超时）

  /// 竞速（刷新动作 vs 超时）的赢家。
  enum RaceWinner: Equatable, Sendable {
    /// 刷新动作先返回（动作抛错 = 失败，由调用点记录）。
    case work
    /// 超时先到（判失败）。
    case timedOut
  }

  /// 竞速结果选择：谁先到谁赢；同一瞬间到达按「超时」判
  /// （宁可判失败，也不让已拖到上限的动作继续占着刷新态）。
  static func raceWinner(
    workFinishedAt: ContinuousClock.Instant,
    deadline: ContinuousClock.Instant
  ) -> RaceWinner {
    workFinishedAt < deadline ? .work : .timedOut
  }

  /// 由「谁赢 + 动作是否抛错」得到本次刷新的结局（**必有一个**：成功或失败）。
  static func outcome(
    winner: RaceWinner,
    threw: Bool
  ) -> WDPullRefreshOutcome {
    switch winner {
    case .timedOut: return .failed
    case .work: return threw ? .failed : .succeeded
    }
  }

  /// 把竞速结果（`Result`）翻成阶段判定用的结局。
  ///
  /// - `isObserved`: 是否走失败通道（注入了 `onRefreshError` / `texts`）。**false = 旧 init 路径**：
  ///   不判定结局（等价于 B12 之前的行为：不回调、不播报、阶段只看下拉与刷新态）。
  static func outcome(
    for result: Result<WDPullRefreshOutcome?, Error>,
    isObserved: Bool
  ) -> WDPullRefreshOutcome? {
    guard isObserved else { return nil }
    switch result {
    case .failure: return .failed
    case .success(let outcome): return outcome
    }
  }

  /// 失败通道要交给调用方弹提示的错误（成功 / 旧 init ⇒ nil）。
  ///
  /// 超时 ⇒ `WDPullRefreshTimeoutError.timedOut`；动作抛错 ⇒ **原始错误**（不包装成库内类型）。
  static func failureError(
    for result: Result<WDPullRefreshOutcome?, Error>
  ) -> (any Error)? {
    guard case let .failure(error) = result else { return nil }
    if let failure = error as? WDPullRefreshFailure { return failure.error }
    return error
  }

  // MARK: - 三态文案与播报（B12：设计 32 §2/§7/§8）

  /// 环旁文案：只在 pulling / armed / refreshing 三态显示（设计 32 §7 的固定三态）。
  ///
  /// 文案由调用方注入（L-B 零文案）；对应字段为 nil、或 texts 整个为 nil ⇒ 不显示（只画环）。
  static func captionTexts(
    phase: WDPullRefreshPhase,
    texts: WDPullRefreshTexts?
  ) -> Text? {
    guard let texts else { return nil }
    switch phase {
    case .pulling: return texts.pull
    case .armed: return texts.release
    case .refreshing: return texts.refreshing
    case .idle, .completed, .failed: return nil
    }
  }

  /// 是否保留文案位：三态文案里**任意一个非 nil** ⇒ 环旁保留文案位（各态之间左右不跳）；
  /// 全 nil ⇒ 不建容器 ⇒ 与 B12 之前逐像素一致（只画环，原有圆环居中方式不变）。
  static func showsCaptionSlot(texts: WDPullRefreshTexts?) -> Bool {
    guard let texts else { return false }
    return texts.pull != nil || texts.release != nil || texts.refreshing != nil
  }

  /// 播报判定（设计 32 §8 + 设计 06 §3）：开始 polite / 成功 polite / 失败 assertive。
  ///
  /// - 没有注入播报通道、或对应文案为 nil ⇒ 不播（返回 nil）。
  /// - 三态视觉文案里只有 `refreshing` 兼作「开始」播报；`pull` / `release` 逐帧变，播会刷屏 ⇒ 一律不播。
  static func announcement(
    for outcome: WDPullRefreshOutcome,
    texts: WDPullRefreshTexts?,
    isAnnouncerInjected: Bool
  ) -> (text: Text, priority: WDAnnouncementPriority)? {
    guard isAnnouncerInjected, let texts else { return nil }
    switch outcome {
    case .started:
      guard let text = texts.refreshing else { return nil }
      return (text, .polite)
    case .succeeded:
      guard let text = texts.completed else { return nil }
      return (text, .polite)
    case .failed:
      guard let text = texts.failed else { return nil }
      return (text, .assertive)
    }
  }
}

/// 一次下拉刷新的结局（内部状态：阶段判定与播报判定的输入）。
///
/// `started` 是本次刷新的起点而不是结局；把它放进同一枚举，是为了让「开始 ⇒ 成功/失败」的
/// 播报判定都收敛在 `WDPullRefreshMetrics.announcement(for:texts:isAnnouncerInjected:)` 一处。
enum WDPullRefreshOutcome: Equatable, Sendable {
  /// 刷新已开始（只用于播报；`resolve` 不把它当结局 ⇒ 由 `isRefreshing` 表达）。
  case started
  /// 刷新动作正常返回。
  case succeeded
  /// 刷新动作抛错，或超过超时（设计 32 §8）。
  case failed
}
