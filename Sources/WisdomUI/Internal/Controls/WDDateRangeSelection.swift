import Foundation

/// 日期范围的两步选择（设计 23 §8：点第一次设起始、第二次设结束；起始不得晚于结束）。
enum WDDateRangeSelection {
  /// 下一次点击后的结果。
  struct Result: Equatable {
    let range: ClosedRange<Date>
    let completed: Bool
  }

  /// 应用一次点击：nil / 已完成范围 ⇒ 重新开始；单点范围 ⇒ 尝试完成或重开。
  static func applying(
    _ day: Date, to current: ClosedRange<Date>?, calendar: Calendar
  ) -> Result {
    let start = calendar.startOfDay(for: day)
    guard let current else {
      return Result(range: start...start, completed: false)
    }
    let lower = calendar.startOfDay(for: current.lowerBound)
    let upper = calendar.startOfDay(for: current.upperBound)
    if lower == upper {
      if start >= lower {
        return Result(range: lower...start, completed: true)
      }
      return Result(range: start...start, completed: false)
    }
    return Result(range: start...start, completed: false)
  }
}
