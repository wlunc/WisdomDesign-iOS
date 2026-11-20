import Foundation

/// 搜索框结果数播报的判定状态（设计 04 §8/§10：`aria-live="polite"`，"结果数量变化…播报，
/// **不要播报每次按键**"）。
///
/// 纯逻辑、无副作用：判定只依赖"上一次计入的计数"与"本次是否可播"，
/// 组件把它存进 `@State` 并在 `onChange(of: initial: true)` 里逐步推进 —— 这样首帧就走
/// `onChange` 的初值回调，**不必在 `body` 里做记账**（避免每次重算 body 都改状态）。
/// 判定结果里**单独**带出"本次该播的那个数"（而不是让调用方从 `previous` 反推）：
/// 这样"该播什么"只在一个地方决定，组件侧的接线不会跟判定漂移。
///
/// 口径：
/// - **首帧不播**：`previous == nil`（此前从未计入过结果数）⇒ `announce == false`；
/// - **相等不播**：`previous == current` ⇒ `false`（这是"不要每次按键都播"的机器保证 ——
///   按键但结果数没变时调用方会重算，本件不回任何一个 `announcer`）；
/// - **增减都播**：`previous != current` ⇒ `true`，`announced = current`（0 也算一次结果）；
/// - **清空不播**：调用方传 `nil`（隐藏结果数）⇒ 不计入、不改 `previous`，只把 `announce` 记成
///   `false`，下次给同一个数时不会重播。
struct WDSearchResultAnnouncement: Equatable {
  /// 上一次"计入"的结果数（`nil` = 还没计入过 ⇒ 下一个数就是首帧）。
  var previous: Int?
  /// 本次状态推进是否应交给 `announcer`（`announcer` 为空时变化不计入，免得开关打开时补播）。
  var announce: Bool
  /// 本次应播报的数（`announce == false` 时恒为 `nil`）。
  var announced: Int?

  /// 初值：什么都没计入过（首帧据此不播）。
  static let initial = WDSearchResultAnnouncement(previous: nil, announce: false, announced: nil)

  /// 配置变了（视图 identity 不变、但 `resultCount` + `announcer` 整体不同）时该用什么记账。
  ///
  /// 返回 `.initial` ⇒ 新配置下的第一个结果数对本件仍是"未知"，按首帧处理（不播），
  /// 不会拿旧上下文的计数去比较、误播一次。判定放在这里（而不是组件里）是为了可单测：
  /// 组件侧只做「配置相等? 沿用 : 重置」。
  ///
  /// **这是实现选择，不是设计要求**（冻结稿只要求"结果数变化时回调一次、首帧不播"）：
  /// 设计 04 没有"搜索上下文"这个概念；本函数只用于让"同一个搜索框换成另一个
  /// `announcer` 引用"时不被旧计数撞出一次误播，不影响任何公开签名。
  ///
  /// - Parameter configuration: 新配置（`resultCount` + `announcer`）。重置结果与它无关 ⇒
  ///   恒为 `.initial`；参数保留是为了调用点自解释（等价于"这是另一条播报配置的起点"）。
  static func resetting(configuration: WDSearchAnnouncementConfig) -> WDSearchResultAnnouncement {
    _ = configuration
    return .initial
  }

  /// 推进一步。
  ///
  /// - Parameters:
  ///   - current: 本次传入的结果数（`nil` = 调用方隐藏结果数）。
  ///   - announcing: 本次是否有可用的播报回调（`announcer != nil`）。
  /// - Returns: 新状态；`announce == true` 时 `announced` 就是要交给 `announcer` 的那个数。
  func next(current: Int?, announcing: Bool) -> WDSearchResultAnnouncement {
    guard let current, announcing else {
      return WDSearchResultAnnouncement(previous: previous, announce: false, announced: nil)
    }
    guard let previous else {
      // 首帧：记下计数，但不播。
      return WDSearchResultAnnouncement(previous: current, announce: false, announced: nil)
    }
    guard previous != current else {
      return WDSearchResultAnnouncement(previous: previous, announce: false, announced: nil)
    }
    return WDSearchResultAnnouncement(previous: current, announce: true, announced: current)
  }
}
