import Foundation

/// Toast 计时口径（设计 28 §5：纯提示停留 3 秒、带操作停留 5 秒；更长的调用方时长不缩短）。
enum WDToastTiming {
  /// 纯提示最短停留。
  static let minimum: Duration = .seconds(3)
  /// 带操作最短停留。
  static let withAction: Duration = .seconds(5)

  /// 把调用方毫秒数换算为实际停留时长（不得低于设计下限）。
  static func duration(requestedMilliseconds: Int, hasAction: Bool) -> Duration {
    let requested = Duration.milliseconds(max(requestedMilliseconds, 0))
    return hasAction ? max(requested, withAction) : max(requested, minimum)
  }
}
