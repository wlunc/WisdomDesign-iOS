import Foundation

/// 范围形态里时间滚轮此刻作用的那一端。
enum WDDateRangeEndpoint: Equatable {
  case start
  case upper
}

/// 日期范围 + 时刻的合成与规范化（设计 23 §4 / §8 / §11；B10 增量）。
///
/// 纯逻辑、零视图依赖：日选取口径由 WDDateRangeSelection 负责，本类型负责把**日**与**时刻**
/// 合成 ClosedRange<Date>、决定时间滚轮作用于哪一端，并保证 lower <= upper。
enum WDDateRangeComposition {
  /// 一次点选的纯结果（组件把其中的值写回 @State / binding）。
  struct Tap: Equatable {
    /// 点选后的范围（第一次点选 = 起点日单点范围）。
    let range: ClosedRange<Date>
    /// 第一次点选后暂存的起点日；nil = 没有待完成的起点。
    let pendingStart: Date?
    /// 两次点选成查（组件据此收起弹层）。
    let completed: Bool
  }

  /// 滚轮作用端的判定结果。
  struct Target: Equatable {
    /// 当前作用的那一端。
    let endpoint: WDDateRangeEndpoint
    /// 滚轮受控值（带当前那一端的时刻）。
    let date: Date
  }

  /// 拨动滚轮的结果：范围与暂存起点（两者都可写回 @State）。
  struct TimeUpdate: Equatable {
    let range: ClosedRange<Date>?
    let pendingStart: Date?
  }

  // MARK: - 模式

  /// 范围形态是否启用时刻（.dateAndTime）；.time 在范围重载里按 .date 处理（B10 口径）。
  static func usesTime(_ mode: WDDatePickerMode) -> Bool {
    mode == .dateAndTime
  }

  /// 范围重载的有效模式：.time 在范围里不成立（没有日期可挂时刻）⇒ 降级为 .date。
  static func effectiveMode(_ mode: WDDatePickerMode) -> WDDatePickerMode {
    mode == .time ? .date : mode
  }

  // MARK: - 日与时刻

  /// 把某一天写到 base 的日上（保留 base 的时分）。
  static func movingDay(_ day: Date, onto base: Date, calendar: Calendar) -> Date {
    WDDatePicker.mergeDate(daySource: day, timeSource: base, calendar: calendar)
  }

  /// 把一组「起止日 + 起止时刻」合成范围。
  ///
  /// **不交换两端**：调用方要「规范化」时用 normalized（就地换序或退化为单点）。
  /// 但这里仍然要挡住倒挂 —— 合成出 lower > upper 会让 ClosedRange 直接崩
  /// （库内崩一次就带走整个进程，不能寄希望于调用方守约）。
  static func composed(
    start: Date,
    end: Date,
    startTime: Date?,
    endTime: Date?,
    calendar: Calendar
  ) -> ClosedRange<Date> {
    let lower = WDDatePicker.mergeDate(daySource: start, timeSource: startTime, calendar: calendar)
    let upper = WDDatePicker.mergeDate(daySource: end, timeSource: endTime, calendar: calendar)
    guard lower <= upper else { return lower...lower }
    return lower...upper
  }

  /// 规范化：合成后倒挂 ⇒ 退化为**起点那一刻**的单点范围。
  ///
  /// 跨日的「终点时刻更早」是合法语义（当晚 20:00 → 次晨 08:00）：时刻已被合成到各自的日上，
  /// 跨日时 upper 必然更晚，因此无需交换；只有合成把它们压到同一时刻（夏令时丢小时一类）
  /// 才会倒挂，此时取起点那一刻。
  static func normalized(
    start: Date,
    end: Date,
    startTime: Date?,
    endTime: Date?,
    calendar: Calendar
  ) -> ClosedRange<Date> {
    let lower = WDDatePicker.mergeDate(daySource: start, timeSource: startTime, calendar: calendar)
    let upper = WDDatePicker.mergeDate(daySource: end, timeSource: endTime, calendar: calendar)
    guard lower <= upper else { return lower...lower }
    return lower...upper
  }

  /// 起点已定、终点未定（两端同日；再次点选才会成查）。
  static func isPendingUpper(_ range: ClosedRange<Date>, calendar: Calendar) -> Bool {
    calendar.isDate(range.lowerBound, inSameDayAs: range.upperBound)
  }

  // MARK: - 滚轮作用端

  /// 时间滚轮此刻作用的那一端。
  ///
  /// - 起点已定、终点未定 ⇒ **终点**。
  /// - 其余（无范围 / 已两次成查）⇒ **起点**：没有范围时作用在暂存起点；暂存也为空则作用在 fallback
  ///   （即将来点选的那一天，滚轮只给起点预置时刻）。
  static func timeTarget(
    range: ClosedRange<Date>?,
    pendingStart: Date?,
    fallback: Date,
    calendar: Calendar
  ) -> Target {
    if let range {
      if isPendingUpper(range, calendar: calendar) {
        return Target(endpoint: .upper, date: range.upperBound)
      }
      return Target(endpoint: .start, date: range.lowerBound)
    }
    return Target(endpoint: .start, date: pendingStart ?? fallback)
  }

  /// 拨动滚轮：只改**当前那一端**的时刻，不提前成查（终点日仍由第二次点选决定）。
  ///
  /// - 作用在起点且暂无范围 ⇒ 只更新暂存起点（把时刻并进暂存日；没有暂存则用拨出的那一天）。
  /// - 作用在起点且有范围 ⇒ 只改 lowerBound 的时刻；upperBound 若因此倒挂则抬到 lowerBound。
  /// - 作用在终点 ⇒ 只改 upperBound 的时刻并规范化（含终点时刻早于起点的同日倒挂）。
  static func applyingTime(
    _ picked: Date,
    to range: ClosedRange<Date>?,
    endpoint: WDDateRangeEndpoint,
    pendingStart: Date?,
    calendar: Calendar
  ) -> TimeUpdate {
    switch endpoint {
    case .start:
      guard let range else {
        let merged = WDDatePicker.mergeDate(
          daySource: pendingStart ?? picked, timeSource: picked, calendar: calendar)
        return TimeUpdate(range: nil, pendingStart: merged)
      }
      let lower = WDDatePicker.mergeDate(
        daySource: range.lowerBound, timeSource: picked, calendar: calendar)
      let upper = max(lower, range.upperBound)
      return TimeUpdate(range: lower...upper, pendingStart: pendingStart)
    case .upper:
      guard let range else { return TimeUpdate(range: nil, pendingStart: pendingStart) }
      let normalizedRange = normalized(
        start: range.lowerBound,
        end: range.upperBound,
        startTime: range.lowerBound,
        endTime: picked,
        calendar: calendar
      )
      return TimeUpdate(range: normalizedRange, pendingStart: pendingStart)
    }
  }

  // MARK: - 两次点选

  /// 一次点选（纯日级口径，与 WDDateRangeSelection.applying 逐条对齐）。
  ///
  /// - 起点未定 ⇒ 起点日 = 点选日（单点范围），等待第二次点选。
  /// - 起点已定且终点不早于起点 ⇒ 成查。
  /// - 终点早于起点 ⇒ 以新点为起点重新开始（不成查）。
  ///
  /// 这里**不**接收时刻：时刻由 applyingTime 写到对应端点上，避免上一次残留的时刻混入新一轮。
  /// 两次点选同日时按 pendingStart 判（范围端点带着时刻，不能直接比大小），否则同日不同时刻永远成不了查。
  static func applyTap(
    _ day: Date,
    to range: ClosedRange<Date>?,
    pendingStart: Date?,
    calendar: Calendar
  ) -> Tap {
    // 只有本轮暂存的起点才可能成查：已完成的范围（两端不同日）再点 ⇒ 直接开新一轮。
    guard let pendingStart else {
      return Tap(range: day...day, pendingStart: day, completed: false)
    }
    guard calendar.startOfDay(for: day) >= calendar.startOfDay(for: pendingStart) else {
      // 终点早于起点 ⇒ 以这次点选重开。
      return Tap(range: day...day, pendingStart: day, completed: false)
    }
    // 成查：起点沿用本轮写入的起点（含它的时刻），终点 = 点选日（时刻由调用方合回）。
    //
    // 同日成查时 day 是当日**零点**，而起点可能带着时刻（如 9:30）：直接写 anchor...day
    // 就是 lower > upper，ClosedRange 的前置条件会 **崩**（Swift 6 下是 fatalError，
    // 不是可捕获错误）。这里按「上界不早于下界」取：倒挂时收缩为起点那一刻，
    // 终点时刻随后由滚轮 / normalized 写回（与 normalized 的退化口径一致）。
    let anchor = range?.lowerBound ?? pendingStart
    return Tap(range: anchor...max(anchor, day), pendingStart: nil, completed: true)
  }
}
