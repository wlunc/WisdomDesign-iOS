import Foundation

/// 月历网格的方向键步进（设计 23 §8/§10：←/→ 前后一天，↑/↓ 前后一周）。
enum WDDatePickerGridStep: Sendable, Equatable {
  /// ← 前一天。
  case previousDay
  /// → 后一天。
  case nextDay
  /// ↑ 前一周（同一星期的上一行）。
  case previousWeek
  /// ↓ 后一周（同一星期的下一行）。
  case nextWeek

  /// 本步进对应的日偏移量（负 = 往前；按周 = ±7 天）。
  var dayOffset: Int {
    switch self {
    case .previousDay: return -1
    case .nextDay: return 1
    case .previousWeek: return -WDDatePickerGrid.weekLength
    case .nextWeek: return WDDatePickerGrid.weekLength
    }
  }
}

/// 方向键（与 SwiftUI 的 `KeyEquivalent` 解耦，便于纯逻辑断言）。
enum WDDatePickerArrowKey: Sendable, Equatable {
  /// ←。
  case left
  /// →。
  case right
  /// ↑。
  case up
  /// ↓。
  case down
}

/// 月历的纯逻辑（二维导航 / 跨月换算 / 不可选日归一 / 网格几何）。
///
/// 全部是不依赖视图与真实时钟的纯函数：组件里的方向键导航、跨月翻页、网格补位与
/// 弹层高度计算都只读这里的结果，因此可以直接断言（见 `WDDatePickerTests`）。
enum WDDatePickerGrid {
  /// 一周七天（设计 23 §3 的 7 列）。
  static let weekLength = 7  // wd-structure-check:disable R7 — 设计 23 §3 的 7 列
  /// 网格行数上限：最长月份占 6 行（翻月时弹层高度不跳动）。
  static let rowCapacity = 6  // wd-structure-check:disable R7 — 最长月份的行数
  /// 日期单元边长（设计 23 §3：44×44；取触控下限令牌，不写字面量）。
  static let cellSize = WDSize.controlMd

  /// 焦点日按步进移动，并归一到可选范围内。
  ///
  /// 越界**不失败也不崩溃**：落到 bounds 之外时归一为**最接近的可选日**
  /// （早于下界 → 下界；晚于上界 → 上界），返回值一律先归一为当日零点。
  static func moved(
    from day: Date,
    by offset: Int,
    bounds: ClosedRange<Date>?,
    calendar: Calendar
  ) -> Date {
    let base = calendar.startOfDay(for: day)
    let target = calendar.date(byAdding: .day, value: offset, to: base) ?? base
    return clamped(target, in: bounds, calendar: calendar)
  }

  /// 方向键 → 步进（RTL 下 ←/→ 镜像：视觉上的「左」永远是后退一天；↑/↓ 不镜像）。
  static func step(for arrow: WDDatePickerArrowKey, isRTL: Bool) -> WDDatePickerGridStep {
    switch arrow {
    case .left: return isRTL ? .nextDay : .previousDay
    case .right: return isRTL ? .previousDay : .nextDay
    case .up: return .previousWeek
    case .down: return .nextWeek
    }
  }

  /// 把某日归一到可选范围（并归一为当日零点；`bounds` 为 nil 时只做日归一）。
  static func clamped(_ day: Date, in bounds: ClosedRange<Date>?, calendar: Calendar) -> Date {
    let start = calendar.startOfDay(for: day)
    guard let bounds else { return start }
    let lower = calendar.startOfDay(for: bounds.lowerBound)
    let upper = calendar.startOfDay(for: bounds.upperBound)
    if start < lower { return lower }
    if start > upper { return upper }
    return start
  }

  /// 目标日所在月份的零点（跨月自动翻页用：焦点跟随到哪里，月历就翻到哪个月）。
  static func monthStart(containing day: Date, calendar: Calendar) -> Date {
    calendar.dateInterval(of: .month, for: day)?.start ?? calendar.startOfDay(for: day)
  }

  /// 某月的第一个可选日（该月整天都不可选时退回最接近的可选日）。
  static func firstSelectableDay(
    inMonthOf day: Date,
    bounds: ClosedRange<Date>?,
    calendar: Calendar
  ) -> Date {
    clamped(monthStart(containing: day, calendar: calendar), in: bounds, calendar: calendar)
  }

  /// 该月要占几行（前置空位 + 当月天数，向上取整到整周）。
  static func rowCount(leadingBlanks: Int, dayCount: Int) -> Int {
    let slots = max(0, leadingBlanks) + max(0, dayCount)
    return (slots + weekLength - 1) / weekLength
  }

  /// 补齐到固定行数所需的尾随空位数（0 = 已经占满）。
  ///
  /// 固定行数让「翻月」不再改变弹层高度（设计 23 §8 的月份切换只做横向位移，不抖高度）。
  static func trailingBlanks(leadingBlanks: Int, dayCount: Int, rowCapacity: Int) -> Int {
    let slots = max(0, leadingBlanks) + max(0, dayCount)
    return max(0, max(0, rowCapacity) * weekLength - slots)
  }
}
