import SwiftUI

/// 结果数播报的**配置快照**（`WDSearchField.init` 的 `resultCount` + `announcer`）。
///
/// **这是实现选择，不是设计要求**（设计 04 无"搜索上下文"概念；冻结稿签发的是
/// `resultCount` + `announcer` 两个参数，本类型不改公开签名）。
///
/// 为什么需要它：`WDSearchField` 的视图 identity 与播放记账（`@State`）绑定；调用方在同一个
/// 搜索框上换成另一个搜索上下文（另一个 `announcer`、另一个结果数）时 identity 不变，
/// 记账若沿用旧值就会拿旧上下文的计数去比、**误播一次**。本类型把这两个要素合成一个
/// **可比对象**（`Equatable`）：`announcer` 只做"是不是同一个闭包引用"的比较，与当前是否已播无关。
struct WDSearchAnnouncementConfig: Equatable {
  /// 上一次计入配置时的结果数入参。
  var resultCount: Int?
  /// 上一次计入配置时的播报回调（`nil` = 不播）。
  var announcer: (@MainActor @Sendable (Int) -> Void)?

  /// 空配置（`@State` 的初值：与"从未处理过任何结果数"一致）。
  init() {
    self.resultCount = nil
    self.announcer = nil
  }

  /// 由入参构造。
  init(resultCount: Int?, announcer: @MainActor @Sendable @escaping (Int) -> Void) {
    self.resultCount = resultCount
    self.announcer = announcer
  }

  /// 两个结果数相等 **且** 播报回调是同一个引用 ⇒ 视为同一配置。
  static func == (lhs: WDSearchAnnouncementConfig, rhs: WDSearchAnnouncementConfig) -> Bool {
    lhs.resultCount == rhs.resultCount && sameClosure(lhs.announcer, rhs.announcer)
  }

  /// 闭包引用相等（`nil` 与 `nil` 相等）。
  private static func sameClosure(
    _ lhs: (@MainActor @Sendable (Int) -> Void)?,
    _ rhs: (@MainActor @Sendable (Int) -> Void)?
  ) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
      return true
    case (let lhs?, let rhs?):
      return lhs as AnyObject === rhs as AnyObject
    default:
      return false
    }
  }
}
