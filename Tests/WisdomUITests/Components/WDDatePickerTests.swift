import Foundation
import Testing

@testable import WisdomUI

/// `WDDatePicker`（B10）：清除回调判定、「范围 + 时间」合成与时间滚轮作用端的纯逻辑断言。
///
/// 只断言可机检的纯函数（不起视图、不依赖真实时钟）：它们是组件里唯一的状态转移入口。
struct WDDatePickerTests {
  private static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  /// 构造某日某时刻（固定时区，避免夏令时歧义）。
  private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int)
    -> Date
  {
    let calendar = Self.calendar
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components)!
  }

  private static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    date(year, month, day, 0, 0)
  }

  // MARK: - onClear 触发条件

  @Test("onClear：只有「非空 → 空」才回调（用户点清除且值确实变空）")
  func shouldReportClearOnlyWhenEmptied() {
    #expect(WDDatePicker.shouldReportClear(wasFilled: true, isFilled: false))
  }

  @Test("onClear：非空 → 非空、空 → 空都不回调（外部改写与空清除不误报）")
  func shouldReportClearSkipsNonTransitions() {
    #expect(!WDDatePicker.shouldReportClear(wasFilled: true, isFilled: true))
    #expect(!WDDatePicker.shouldReportClear(wasFilled: false, isFilled: false))
  }

  @Test("onClear 缺省：没有值时清除不产生回调（既有三个 init 的默认路径判定恒为 false）")
  func defaultInitNeverReportsClear() {
    let calendar = Self.calendar
    // 默认路径：没有值可清 ⇒ 清除前后都空。
    #expect(!WDDatePicker.shouldReportClear(wasFilled: false, isFilled: false))
    // 外部把 binding 置 nil 不经过清除按钮，也就不会走到这个判定（范围端点判定同样只认非空 → 空）。
    let tapped = WDDateRangeSelection.applying(Self.day(2026, 3, 10), to: nil, calendar: calendar)
    // Result.range 是**非可选**的 ClosedRange：第一次点选落地的是一个单点范围（起点日已定），
    // 所以此后「清除」就是非空 → 空，判定为 true。
    #expect(tapped.range.lowerBound == tapped.range.upperBound)
    #expect(WDDatePicker.shouldReportClear(wasFilled: true, isFilled: false))
  }

  // MARK: - 范围 + 时间：合成与规范化

  @Test("范围+时间：单日范围保留两端各自的时刻")
  func singleDayRangeKeepsBothTimes() {
    let composed = WDDateRangeComposition.composed(
      start: Self.day(2026, 3, 10),
      end: Self.day(2026, 3, 10),
      startTime: Self.date(2026, 3, 10, 9, 30),
      endTime: Self.date(2026, 3, 10, 18, 0),
      calendar: Self.calendar
    )
    #expect(composed.lowerBound == Self.date(2026, 3, 10, 9, 30))
    #expect(composed.upperBound == Self.date(2026, 3, 10, 18, 0))
    #expect(composed.lowerBound <= composed.upperBound)
  }

  @Test("范围+时间：跨日时终点时刻更早仍合法（当晚 20:00 → 次晨 08:00）")
  func crossDayRangeAllowsEarlierEndClock() {
    let composed = WDDateRangeComposition.normalized(
      start: Self.day(2026, 3, 10),
      end: Self.day(2026, 3, 11),
      startTime: Self.date(2026, 3, 10, 20, 0),
      endTime: Self.date(2026, 3, 11, 8, 0),
      calendar: Self.calendar
    )
    #expect(composed.lowerBound == Self.date(2026, 3, 10, 20, 0))
    #expect(composed.upperBound == Self.date(2026, 3, 11, 8, 0))
    #expect(composed.lowerBound <= composed.upperBound)
  }

  @Test("范围+时间：同日终点时刻早于起点 ⇒ 退化为起点那一刻（保证 lower <= upper）")
  func sameDayInvertedTimesCollapse() {
    let composed = WDDateRangeComposition.normalized(
      start: Self.day(2026, 3, 10),
      end: Self.day(2026, 3, 10),
      startTime: Self.date(2026, 3, 10, 18, 0),
      endTime: Self.date(2026, 3, 10, 9, 30),
      calendar: Self.calendar
    )
    #expect(composed.lowerBound == Self.date(2026, 3, 10, 18, 0))
    #expect(composed.upperBound == Self.date(2026, 3, 10, 18, 0))
    #expect(composed.lowerBound <= composed.upperBound)
  }

  @Test("范围+时间：同日不同时刻两端各自保留")
  func sameDayDistinctTimesAreKept() {
    let composed = WDDateRangeComposition.normalized(
      start: Self.day(2026, 3, 10),
      end: Self.day(2026, 3, 10),
      startTime: Self.date(2026, 3, 10, 9, 5),
      endTime: Self.date(2026, 3, 10, 9, 45),
      calendar: Self.calendar
    )
    #expect(composed.lowerBound == Self.date(2026, 3, 10, 9, 5))
    #expect(composed.upperBound == Self.date(2026, 3, 10, 9, 45))
  }

  // MARK: - mode 口径

  @Test("mode 口径：.time 在范围重载里按 .date 处理；只有 .dateAndTime 启用时刻")
  func rangeModeNormalization() {
    #expect(WDDateRangeComposition.effectiveMode(.time) == .date)
    #expect(WDDateRangeComposition.effectiveMode(.date) == .date)
    #expect(WDDateRangeComposition.effectiveMode(.dateAndTime) == .dateAndTime)
    #expect(!WDDateRangeComposition.usesTime(.date))
    #expect(!WDDateRangeComposition.usesTime(.time))
    #expect(WDDateRangeComposition.usesTime(.dateAndTime))
  }

  // MARK: - 弹层布局与高度

  @Test("弹层：.date 不受影响（单日期/范围都只有月历）；范围 + 时间 = 月历 + 时间滚轮")
  func sheetLayoutByMode() {
    #expect(WDDatePicker.sheetLayout(isRange: false, mode: .date) == .calendar)
    #expect(WDDatePicker.sheetLayout(isRange: true, mode: .date) == .calendar)
    #expect(WDDatePicker.sheetLayout(isRange: true, mode: .time) == .calendar)
    #expect(WDDatePicker.sheetLayout(isRange: false, mode: .time) == .timeWheel)
    #expect(WDDatePicker.sheetLayout(isRange: true, mode: .dateAndTime) == .calendarAndTime)
    #expect(WDDatePicker.sheetLayout(isRange: false, mode: .dateAndTime) == .calendarAndTime)
  }

  @Test("弹层高度：按内容量高；范围 + 时间与单日期 + 时间同高（同一套内容）")
  func sheetHeightByMode() {
    let available: CGFloat = 2000
    let calendarHeight = WDDatePicker.sheetHeight(
      isRange: false, mode: .date, available: available)
    let wheelHeight = WDDatePicker.sheetHeight(isRange: false, mode: .time, available: available)
    let combined = WDDatePicker.sheetHeight(
      isRange: false, mode: .dateAndTime, available: available)
    // 内容递进：时间滚轮 < 月历 < 月历 + 滚轮。
    #expect(wheelHeight < calendarHeight)
    #expect(wheelHeight < combined)
    #expect(calendarHeight < combined)
    #expect(
      WDDatePicker.sheetHeight(isRange: true, mode: .date, available: available) == calendarHeight)
    #expect(
      WDDatePicker.sheetHeight(isRange: true, mode: .time, available: available) == calendarHeight)
    #expect(
      WDDatePicker.sheetHeight(isRange: true, mode: .dateAndTime, available: available) == combined)
  }

  // MARK: - 二维方向键（A-10）

  @Test("方向键步进：←/→ 一天，↑/↓ 一周；RTL 下左右镜像、上下不镜像")
  func arrowSteps() {
    #expect(WDDatePickerGrid.step(for: .left, isRTL: false) == .previousDay)
    #expect(WDDatePickerGrid.step(for: .right, isRTL: false) == .nextDay)
    #expect(WDDatePickerGrid.step(for: .up, isRTL: false) == .previousWeek)
    #expect(WDDatePickerGrid.step(for: .down, isRTL: false) == .nextWeek)
    #expect(WDDatePickerGrid.step(for: .left, isRTL: true) == .nextDay)
    #expect(WDDatePickerGrid.step(for: .right, isRTL: true) == .previousDay)
    #expect(WDDatePickerGrid.step(for: .up, isRTL: true) == .previousWeek)
    #expect(WDDatePickerGrid.step(for: .down, isRTL: true) == .nextWeek)
    // 日偏移量：按周 = ±7 天。
    #expect(WDDatePickerGridStep.previousDay.dayOffset == -1)
    #expect(WDDatePickerGridStep.nextDay.dayOffset == 1)
    #expect(WDDatePickerGridStep.previousWeek.dayOffset == -7)
    #expect(WDDatePickerGridStep.nextWeek.dayOffset == 7)
  }

  @Test("日偏移：前后一天 / 前后一周落在正确的日期上")
  func dayOffsets() {
    let calendar = Self.calendar
    let base = Self.day(2026, 3, 10)
    #expect(
      WDDatePickerGrid.moved(from: base, by: -1, bounds: nil, calendar: calendar)
        == Self.day(2026, 3, 9))
    #expect(
      WDDatePickerGrid.moved(from: base, by: 1, bounds: nil, calendar: calendar)
        == Self.day(2026, 3, 11))
    #expect(
      WDDatePickerGrid.moved(from: base, by: -7, bounds: nil, calendar: calendar)
        == Self.day(2026, 3, 3))
    #expect(
      WDDatePickerGrid.moved(from: base, by: 7, bounds: nil, calendar: calendar)
        == Self.day(2026, 3, 17))
    // 带时刻的输入先归一到当日零点（焦点日永远是整日）。
    let withClock = Self.date(2026, 3, 10, 18, 45)
    #expect(
      WDDatePickerGrid.moved(from: withClock, by: 1, bounds: nil, calendar: calendar)
        == Self.day(2026, 3, 11))
  }

  @Test("跨月换算：月末 → 次月 1 日、月初 → 上月最后一天；目标月份随之翻页")
  func crossMonthConversion() {
    let calendar = Self.calendar
    let january31 = Self.day(2026, 1, 31)
    let forward = WDDatePickerGrid.moved(from: january31, by: 1, bounds: nil, calendar: calendar)
    #expect(forward == Self.day(2026, 2, 1))
    #expect(
      WDDatePickerGrid.monthStart(containing: forward, calendar: calendar)
        == Self.day(2026, 2, 1))

    let march1 = Self.day(2026, 3, 1)
    let backward = WDDatePickerGrid.moved(from: march1, by: -1, bounds: nil, calendar: calendar)
    #expect(backward == Self.day(2026, 2, 28))
    #expect(
      WDDatePickerGrid.monthStart(containing: backward, calendar: calendar)
        == Self.day(2026, 2, 1))

    // 跨年：12/31 → 次年 1/1，月份头也跟着翻年。
    let december31 = Self.day(2026, 12, 31)
    let nextYear = WDDatePickerGrid.moved(from: december31, by: 1, bounds: nil, calendar: calendar)
    #expect(nextYear == Self.day(2027, 1, 1))
    #expect(
      WDDatePickerGrid.monthStart(containing: nextYear, calendar: calendar)
        == Self.day(2027, 1, 1))
    // 整月翻页：从 3/31 走一周 → 4/7，落在 4 月。
    let week = WDDatePickerGrid.moved(
      from: Self.day(2026, 3, 31), by: 7, bounds: nil, calendar: calendar)
    #expect(week == Self.day(2026, 4, 7))
    #expect(
      WDDatePickerGrid.monthStart(containing: week, calendar: calendar) == Self.day(2026, 4, 1))
  }

  @Test("不可选日归一：越界取最接近的可选日，不越界不崩溃")
  func boundsNormalization() {
    let calendar = Self.calendar
    let bounds = Self.day(2026, 3, 10)...Self.day(2026, 3, 20)
    // 从下界往前一天 ⇒ 仍停在下界。
    #expect(
      WDDatePickerGrid.moved(
        from: Self.day(2026, 3, 10), by: -1, bounds: bounds, calendar: calendar)
        == Self.day(2026, 3, 10))
    // 从上界往后一周 ⇒ 仍停在上界。
    #expect(
      WDDatePickerGrid.moved(from: Self.day(2026, 3, 20), by: 7, bounds: bounds, calendar: calendar)
        == Self.day(2026, 3, 20))
    // 大幅越界（±400 天）同样归一，且不倒挂。
    #expect(
      WDDatePickerGrid.moved(
        from: Self.day(2026, 3, 15), by: -400, bounds: bounds, calendar: calendar)
        == Self.day(2026, 3, 10))
    #expect(
      WDDatePickerGrid.moved(
        from: Self.day(2026, 3, 15), by: 400, bounds: bounds, calendar: calendar)
        == Self.day(2026, 3, 20))
    // 范围内正常步进不受影响。
    #expect(
      WDDatePickerGrid.moved(from: Self.day(2026, 3, 15), by: 1, bounds: bounds, calendar: calendar)
        == Self.day(2026, 3, 16))
  }

  @Test("归一化：clamped 只做日归一与边界夹取；月初取当月第一个可选日")
  func clampedAndFirstSelectable() {
    let calendar = Self.calendar
    #expect(
      WDDatePickerGrid.clamped(Self.date(2026, 3, 10, 23, 59), in: nil, calendar: calendar)
        == Self.day(2026, 3, 10))
    let bounds = Self.day(2026, 3, 12)...Self.day(2026, 4, 5)
    #expect(
      WDDatePickerGrid.clamped(Self.day(2026, 3, 1), in: bounds, calendar: calendar)
        == Self.day(2026, 3, 12))
    #expect(
      WDDatePickerGrid.clamped(Self.day(2026, 5, 1), in: bounds, calendar: calendar)
        == Self.day(2026, 4, 5))
    // 整月都不可选（下界在月中）⇒ 退回该月最接近的可选日 = 下界。
    #expect(
      WDDatePickerGrid.firstSelectableDay(
        inMonthOf: Self.day(2026, 3, 20), bounds: bounds, calendar: calendar)
        == Self.day(2026, 3, 12))
    // 完全可选 ⇒ 就是当月 1 号。
    #expect(
      WDDatePickerGrid.firstSelectableDay(
        inMonthOf: Self.day(2026, 6, 18), bounds: nil, calendar: calendar)
        == Self.day(2026, 6, 1))
  }

  @Test("网格几何：固定 6 行（翻月不跳高度），尾随空位补满")
  func gridGeometry() {
    // 2026-02 从周日开始、28 天 ⇒ 前置 0、占 4 行 ⇒ 尾随 14 个空位（补到 6 行）。
    #expect(WDDatePickerGrid.rowCount(leadingBlanks: 0, dayCount: 28) == 4)
    #expect(WDDatePickerGrid.trailingBlanks(leadingBlanks: 0, dayCount: 28, rowCapacity: 6) == 14)
    // 前置 6 + 31 天 = 37 格 ⇒ 6 行，尾随 5。
    #expect(WDDatePickerGrid.rowCount(leadingBlanks: 6, dayCount: 31) == 6)
    #expect(WDDatePickerGrid.trailingBlanks(leadingBlanks: 6, dayCount: 31, rowCapacity: 6) == 5)
    // 已经占满（或超出）⇒ 不产生负空位。
    #expect(WDDatePickerGrid.trailingBlanks(leadingBlanks: 6, dayCount: 31, rowCapacity: 5) == 0)
    #expect(WDDatePickerGrid.trailingBlanks(leadingBlanks: 0, dayCount: 31, rowCapacity: 6) == 11)
    // 日期单元 44×44（设计 23 §3）：取令牌，不是字面量。
    #expect(WDDatePickerGrid.cellSize == 44)
    #expect(WDDatePickerGrid.cellSize == WDSize.touchTargetMin)
  }

  // MARK: - 弹层自适应高度（A-10）

  @Test("自适应高度：三种组合（无滚轮 / 有滚轮 / 范围+时间）高度各不相同")
  func adaptiveHeightsDiffer() {
    let metrics = WDDatePickerSheetHeight.Metrics(dynamicTypeSize: .large)
    let calendarOnly = WDDatePickerSheetHeight.detentHeight(
      layout: .calendar, metrics: metrics, available: 5000)
    let wheelOnly = WDDatePickerSheetHeight.detentHeight(
      layout: .timeWheel, metrics: metrics, available: 5000)
    let combined = WDDatePickerSheetHeight.detentHeight(
      layout: .calendarAndTime, metrics: metrics, available: 5000)
    #expect(calendarOnly != wheelOnly)
    #expect(wheelOnly != combined)
    #expect(calendarOnly != combined)
    #expect(wheelOnly < calendarOnly)
    #expect(calendarOnly < combined)
    // 「范围 + 时间」与「日期 + 时间」同布局 ⇒ 同高（内容一模一样）。
    #expect(
      WDDatePicker.sheetHeight(isRange: true, mode: .dateAndTime, available: 5000)
        == WDDatePicker.sheetHeight(isRange: false, mode: .dateAndTime, available: 5000))
  }

  @Test("自适应高度：可用高度不足时夹到可用高度（小屏 / 横屏不溢出）")
  func adaptiveHeightsClampToAvailable() {
    let metrics = WDDatePickerSheetHeight.Metrics(dynamicTypeSize: .large)
    let content = WDDatePickerSheetHeight.contentHeight(layout: .calendar, metrics: metrics)
    let smallScreen: CGFloat = 300
    let clamped = WDDatePickerSheetHeight.detentHeight(
      layout: .calendar, metrics: metrics, available: smallScreen)
    #expect(clamped == smallScreen)
    #expect(clamped < content)
    // 组合布局在同样的可用高度下同样被夹住（不会顶出安全区）。
    #expect(
      WDDatePickerSheetHeight.detentHeight(
        layout: .calendarAndTime, metrics: metrics, available: smallScreen) == smallScreen)
    // 极小可用高度（横屏 200）也只服从可用高度，不反过来把内容顶出去。
    #expect(
      WDDatePickerSheetHeight.detentHeight(
        layout: .calendarAndTime, metrics: metrics, available: 200) == 200)
  }

  @Test("自适应高度：夹取口径 = min(max(content, minimum), available)；未量到可用高度时不裁")
  func heightClampFormula() {
    #expect(
      WDDatePickerSheetHeight.clamped(contentHeight: 400, minimum: 300, available: 1000) == 400)
    #expect(
      WDDatePickerSheetHeight.clamped(contentHeight: 400, minimum: 300, available: 350) == 350)
    #expect(
      WDDatePickerSheetHeight.clamped(contentHeight: 400, minimum: 300, available: 200) == 200)
    #expect(
      WDDatePickerSheetHeight.clamped(contentHeight: 250, minimum: 300, available: 1000) == 300)
    // available <= 0 = 还没量到 ⇒ 返回内容自然高度（不裁）。
    #expect(WDDatePickerSheetHeight.clamped(contentHeight: 400, minimum: 300, available: 0) == 400)

    let metrics = WDDatePickerSheetHeight.Metrics(dynamicTypeSize: .large)
    for layout in [WDDatePickerSheetLayout.calendar, .timeWheel, .calendarAndTime] {
      let natural = WDDatePickerSheetHeight.contentHeight(layout: layout, metrics: metrics)
      let minimum = WDDatePickerSheetHeight.minimumHeight(layout: layout, metrics: metrics)
      #expect(minimum <= natural)
      // 可用高度恰好等于自然高度 ⇒ 不裁不缩。
      #expect(
        WDDatePickerSheetHeight.detentHeight(
          layout: layout, metrics: metrics, available: natural) == natural)
    }
  }

  @Test("自适应高度：动态字体放大后月历变高（不是固定字面量）")
  func adaptiveHeightsGrowWithDynamicType() {
    let regular = WDDatePickerSheetHeight.Metrics(dynamicTypeSize: .large)
    let accessibility = WDDatePickerSheetHeight.Metrics(dynamicTypeSize: .accessibility3)
    #expect(
      WDDatePickerSheetHeight.contentHeight(layout: .calendar, metrics: accessibility)
        > WDDatePickerSheetHeight.contentHeight(layout: .calendar, metrics: regular))
    // 时间滚轮是系统控件，高度不随字体变化（只有月历的头部行盒会长）。
    #expect(
      WDDatePickerSheetHeight.contentHeight(layout: .timeWheel, metrics: accessibility)
        == WDDatePickerSheetHeight.contentHeight(layout: .timeWheel, metrics: regular))
  }

  // MARK: - 滚轮作用端

  @Test("滚轮作用端：无范围 ⇒ 起点（预置时刻）；起点已定 ⇒ 终点；已两次成查 ⇒ 起点")
  func timeTargetBySelectionState() {
    let calendar = Self.calendar
    let fallback = Self.date(2026, 3, 9, 7, 0)

    let fresh = WDDateRangeComposition.timeTarget(
      range: nil, pendingStart: nil, fallback: fallback, calendar: calendar)
    #expect(fresh.endpoint == .start)
    #expect(fresh.date == fallback)

    let pending = WDDateRangeComposition.timeTarget(
      range: nil, pendingStart: Self.date(2026, 3, 10, 9, 0), fallback: fallback,
      calendar: calendar)
    #expect(pending.endpoint == .start)
    #expect(pending.date == Self.date(2026, 3, 10, 9, 0))

    let anchored = WDDateRangeComposition.timeTarget(
      range: Self.date(2026, 3, 10, 9, 0)...Self.date(2026, 3, 10, 9, 0),
      pendingStart: Self.day(2026, 3, 10), fallback: fallback, calendar: calendar)
    #expect(anchored.endpoint == .upper)
    #expect(anchored.date == Self.date(2026, 3, 10, 9, 0))

    let completed = WDDateRangeComposition.timeTarget(
      range: Self.date(2026, 3, 10, 9, 0)...Self.date(2026, 3, 12, 18, 0),
      pendingStart: nil, fallback: fallback, calendar: calendar)
    #expect(completed.endpoint == .start)
    #expect(completed.date == Self.date(2026, 3, 10, 9, 0))
  }

  @Test("滚轮拨动：尚无范围时只预置起点时刻（不写成范围、不成查）")
  func wheelBeforeAnyTapOnlySeeds() {
    let updated = WDDateRangeComposition.applyingTime(
      Self.date(2026, 3, 10, 7, 45),
      to: nil,
      endpoint: .start,
      pendingStart: nil,
      calendar: Self.calendar
    )
    #expect(updated.range == nil)
    #expect(updated.pendingStart == Self.date(2026, 3, 10, 7, 45))
  }

  @Test("滚轮拨动（起点）：只改起点时刻，不提前成查")
  func wheelOnStartDoesNotComplete() {
    let current = Self.date(2026, 3, 10, 9, 0)...Self.date(2026, 3, 10, 9, 0)
    let updated = WDDateRangeComposition.applyingTime(
      Self.date(2026, 3, 10, 14, 20),
      to: current,
      endpoint: .start,
      pendingStart: Self.day(2026, 3, 10),
      calendar: Self.calendar
    )
    #expect(updated.range == (Self.date(2026, 3, 10, 14, 20)...Self.date(2026, 3, 10, 14, 20)))
    #expect(updated.pendingStart == Self.day(2026, 3, 10))
  }

  @Test("滚轮拨动（终点）：只改终点时刻，起点不动；同日倒挂被规范化")
  func wheelOnUpperKeepsStart() {
    let current = Self.date(2026, 3, 10, 9, 0)...Self.date(2026, 3, 10, 9, 0)
    let later = WDDateRangeComposition.applyingTime(
      Self.date(2026, 3, 10, 17, 30),
      to: current,
      endpoint: .upper,
      pendingStart: Self.day(2026, 3, 10),
      calendar: Self.calendar
    )
    #expect(later.range == (Self.date(2026, 3, 10, 9, 0)...Self.date(2026, 3, 10, 17, 30)))

    let earlier = WDDateRangeComposition.applyingTime(
      Self.date(2026, 3, 10, 8, 0),
      to: current,
      endpoint: .upper,
      pendingStart: Self.day(2026, 3, 10),
      calendar: Self.calendar
    )
    #expect(earlier.range?.lowerBound == Self.date(2026, 3, 10, 9, 0))
    #expect(earlier.range?.upperBound == Self.date(2026, 3, 10, 9, 0))
  }

  // MARK: - 两次点选成查

  @Test("点选：第一次只记起点日（不成查），第二次成查")
  func twoTapsCompose() {
    let calendar = Self.calendar
    let first = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 10), to: nil, pendingStart: nil, calendar: calendar)
    #expect(!first.completed)
    #expect(first.pendingStart == Self.day(2026, 3, 10))
    #expect(first.range.lowerBound == Self.day(2026, 3, 10))

    let second = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 12), to: first.range, pendingStart: first.pendingStart,
      calendar: calendar)
    #expect(second.completed)
    #expect(second.pendingStart == nil)
    #expect(second.range.lowerBound == Self.day(2026, 3, 10))
    #expect(second.range.upperBound == Self.day(2026, 3, 12))
  }

  @Test("点选：同日两次点选（起点/终点同日）仍成查")
  func sameDayTwoTapsComplete() {
    let calendar = Self.calendar
    let first = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 10), to: nil, pendingStart: nil, calendar: calendar)
    let second = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 10), to: first.range, pendingStart: first.pendingStart,
      calendar: calendar)
    #expect(second.completed)
    #expect(second.range.lowerBound == Self.day(2026, 3, 10))
    #expect(second.range.upperBound == Self.day(2026, 3, 10))
  }

  @Test("点选：终点早于起点 ⇒ 以新点为起点重新开始（不提前成查）")
  func earlierSecondTapRestarts() {
    let calendar = Self.calendar
    let first = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 10), to: nil, pendingStart: nil, calendar: calendar)
    let second = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 8), to: first.range, pendingStart: first.pendingStart,
      calendar: calendar)
    #expect(!second.completed)
    #expect(second.pendingStart == Self.day(2026, 3, 8))
    #expect(second.range.lowerBound == second.range.upperBound)
    #expect(calendar.startOfDay(for: second.range.lowerBound) == Self.day(2026, 3, 8))
  }

  @Test("点选：已完成范围内再点 ⇒ 开始新一轮（不继承上一轮时刻）")
  func tapOnCompletedRangeStartsOver() {
    let calendar = Self.calendar
    let completed = Self.date(2026, 3, 10, 9, 0)...Self.date(2026, 3, 12, 18, 0)
    let next = WDDateRangeComposition.applyTap(
      Self.day(2026, 4, 1), to: completed, pendingStart: nil, calendar: calendar)
    #expect(!next.completed)
    #expect(next.pendingStart == Self.day(2026, 4, 1))
    #expect(next.range.lowerBound == Self.day(2026, 4, 1))
    #expect(next.range.upperBound == Self.day(2026, 4, 1))
  }

  @Test("点选 → 滚轮 → 再点：同日两端时刻各自保留（顺序无关）")
  func tapWheelTapKeepsBothTimes() {
    let calendar = Self.calendar
    // 先拨滚轮预置起点时刻，再点起点日。
    let seeded = WDDateRangeComposition.applyingTime(
      Self.date(2026, 3, 10, 9, 30),
      to: nil,
      endpoint: .start,
      pendingStart: nil,
      calendar: calendar
    )
    let first = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 10), to: nil, pendingStart: nil, calendar: calendar)
    let start = WDDateRangeComposition.movingDay(
      first.range.lowerBound,
      onto: seeded.pendingStart ?? Self.day(2026, 3, 10),
      calendar: calendar
    )
    #expect(start == Self.date(2026, 3, 10, 9, 30))

    // 起点已定 ⇒ 滚轮作用在终点。
    let anchor = start...start
    let target = WDDateRangeComposition.timeTarget(
      range: anchor, pendingStart: first.pendingStart,
      fallback: Self.day(2026, 3, 10), calendar: calendar)
    #expect(target.endpoint == .upper)
    let wheeled = WDDateRangeComposition.applyingTime(
      Self.date(2026, 3, 10, 18, 0),
      to: anchor,
      endpoint: target.endpoint,
      pendingStart: first.pendingStart,
      calendar: calendar
    )

    // 再点同一天 ⇒ 成查，两端时刻都在。
    let second = WDDateRangeComposition.applyTap(
      Self.day(2026, 3, 10), to: wheeled.range, pendingStart: wheeled.pendingStart,
      calendar: calendar)
    #expect(second.completed)
    let composed = WDDateRangeComposition.normalized(
      start: second.range.lowerBound,
      end: second.range.upperBound,
      startTime: wheeled.range?.lowerBound,
      endTime: wheeled.range?.upperBound,
      calendar: calendar
    )
    #expect(composed.lowerBound == Self.date(2026, 3, 10, 9, 30))
    #expect(composed.upperBound == Self.date(2026, 3, 10, 18, 0))
  }

  // MARK: - 既有口径不回归

  @Test("mergeDate 口径不变：日的年月日 + 时刻的时分")
  func mergeDateKeepsDayAndClock() {
    let merged = WDDatePicker.mergeDate(
      daySource: Self.day(2026, 5, 20),
      timeSource: Self.date(2020, 1, 2, 13, 45),
      calendar: Self.calendar
    )
    #expect(merged == Self.date(2026, 5, 20, 13, 45))
  }

  @Test("纯日期范围的日级语义不受 B10 影响（WDDateRangeSelection 仍两步成查）")
  func pureDateRangeSelectionUnchanged() {
    let calendar = Self.calendar
    let first = WDDateRangeSelection.applying(
      Self.day(2026, 3, 10), to: nil, calendar: calendar)
    #expect(!first.completed)
    let second = WDDateRangeSelection.applying(
      Self.day(2026, 3, 12), to: first.range, calendar: calendar)
    #expect(second.completed)
    #expect(second.range == Self.day(2026, 3, 10)...Self.day(2026, 3, 12))
  }

  @Test("isExpired 口径不变（B10 不加计时常量、不改过期判定）")
  func expiredLogicUnchanged() {
    let calendar = Self.calendar
    let now = Self.date(2026, 3, 10, 12, 0)
    #expect(WDDatePicker.isExpired(Self.date(2026, 3, 9, 23, 0), now: now, calendar: calendar))
    #expect(!WDDatePicker.isExpired(Self.date(2026, 3, 10, 0, 30), now: now, calendar: calendar))
  }
}
