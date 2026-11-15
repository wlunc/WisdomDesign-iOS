import SwiftUI

/// 日期选择模式（设计 23 §4：日期 / 时间 / 日期 + 时间；范围本轮不做）。
public enum WDDatePickerMode: String, CaseIterable, Sendable, Equatable {
  /// 只选日期（自建月历）。
  case date
  /// 只选时间（系统滚轮）。
  case time
  /// 日期 + 时间（自建月历 + 系统时间滚轮）。
  case dateAndTime
}

/// 快捷日期选项（设计 23 §2/§6 的「今天 / 明天 / 下周一」Chip）。
public struct WDDatePickerQuickOption: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// Chip 文案（由调用方给）。
  public let label: Text
  /// 点选后写入的日期。
  public let date: Date

  /// 构造：身份 + 文案 + 日期。
  public init(id: String, label: Text, date: Date) {
    self.id = id
    self.label = label
    self.date = date
  }
}

/// 日期选择器（SPEC §2.10-#23；M5）。
///
/// 设计口径（设计 23）：
/// - 触发入口高 **44**；左侧标签，右侧当前值 + `calendar` 图标；未选显示占位符（`text.tertiary`）；
/// - **.date = 自建月历**（44×44 单元、今天圆点、选中实心、min/max 禁用、逐日完整朗读）；
/// - **.time = 系统滚轮**（F41：保留原生日期/时间控件）；**.dateAndTime = 自建月历 + 系统时间滚轮**；
/// - 快捷 Chip 仅在 `.date` 模式渲染（本轮实现，Q2）；范围形态本轮不做（登记差异）。
///
/// 库内零文案：标签、占位、快捷 Chip 文案由调用方给；月份/星期/日期文案全部走系统本地化格式。
public struct WDDatePicker: View {
  @Binding private var date: Date?
  @Binding private var range: ClosedRange<Date>?
  private let label: Text
  private let mode: WDDatePickerMode
  private let placeholder: Text?
  private let quickOptions: [WDDatePickerQuickOption]
  private let bounds: ClosedRange<Date>?
  private let isRange: Bool
  private let showsClearButton: Bool
  private let clearAccessibilityLabel: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled

  @State private var showsSheet = false
  @State private var visibleMonth = Date()

  private let calendar = Calendar.current

  /// 构造：受控日期 + 标签 + 模式 + 占位 + 快捷项 + 可选边界。
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,
    quickOptions: [WDDatePickerQuickOption] = [],
    in bounds: ClosedRange<Date>? = nil
  ) {
    self._date = date
    self._range = .constant(nil)
    self.label = label
    self.mode = mode
    self.placeholder = placeholder
    self.quickOptions = quickOptions
    self.bounds = bounds
    self.isRange = false
    self.showsClearButton = false
    self.clearAccessibilityLabel = nil
  }

  /// 构造（B6 增量；单日期 + 可选清除按钮）。
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,
    quickOptions: [WDDatePickerQuickOption] = [],
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool,
    clearAccessibilityLabel: Text?
  ) {
    self._date = date
    self._range = .constant(nil)
    self.label = label
    self.mode = mode
    self.placeholder = placeholder
    self.quickOptions = quickOptions
    self.bounds = bounds
    self.isRange = false
    self.showsClearButton = showsClearButton
    self.clearAccessibilityLabel = clearAccessibilityLabel
  }

  /// 构造（B6 增量；日期范围 + 可选清除按钮；仅日期模式）。
  public init(
    range: Binding<ClosedRange<Date>?>,
    label: Text,
    placeholder: Text? = nil,
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil
  ) {
    self._date = .constant(nil)
    self._range = range
    self.label = label
    self.mode = .date
    self.placeholder = placeholder
    self.quickOptions = []
    self.bounds = bounds
    self.isRange = true
    self.showsClearButton = showsClearButton
    self.clearAccessibilityLabel = clearAccessibilityLabel
  }

  /// 触发入口（+ 快捷 Chip）。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      trigger
      if !isRange, mode == .date, !quickOptions.isEmpty {
        quickChips
      }
    }
    .opacity(isEnabled ? 1 : disabledOpacity)
    .sheet(isPresented: $showsSheet) {
      sheetContent
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }
    .onChange(of: showsSheet) { _, presented in
      if presented {
        visibleMonth = date ?? range?.lowerBound ?? bounds?.lowerBound ?? Date()
      }
    }
  }

  // MARK: - 触发入口

  private var trigger: some View {
    HStack(spacing: WDSpacing.s2) {
      Button {
        guard isEnabled else { return }
        showsSheet = true
      } label: {
        HStack(spacing: WDSpacing.s3) {
          label
            .wdFont(WDType.subheadline)
            .wdLineBox(WDType.subheadline)
            .foregroundStyle(colors.textPrimary)
          Spacer(minLength: WDSpacing.s3)
          if let displayText {
            displayText
              .wdFont(WDType.subheadline)
              .wdLineBox(WDType.subheadline)
              .foregroundStyle(hasValue ? colors.textPrimary : colors.textTertiary)
              .lineLimit(1)
          }
          WDIcon(icon: isRange || mode != .time ? .calendar : .time, size: .sm)
            .foregroundStyle(colors.textTertiary)
        }
        .frame(minHeight: WDSize.controlMd)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(label)
      .accessibilityValue(displayText ?? Text(verbatim: ""))

      if showsClearButton, hasValue, let clearAccessibilityLabel {
        WDIconButton(
          icon: .close,
          accessibilityLabel: clearAccessibilityLabel,
          variant: .plain,
          size: .sm
        ) {
          clearSelection()
        }
      }
    }
  }

  /// 范围显示（同一年用“月日 – 月日”，跨年带年份；跟随系统区域格式）。
  private func rangeDisplayText(_ range: ClosedRange<Date>) -> Text {
    let sameYear =
      calendar.component(.year, from: range.lowerBound)
      == calendar.component(.year, from: range.upperBound)
    let style: Date.FormatStyle =
      sameYear
      ? .dateTime.month(.abbreviated).day()
      : .dateTime.year().month(.abbreviated).day()
    let text = range.lowerBound.formatted(style) + " – " + range.upperBound.formatted(style)
    return Text(verbatim: text)  // wd-structure-check:disable R21 — 行盒
  }

  /// 是否已有选中值（单日期 / 范围通用）。
  private var hasValue: Bool {
    isRange ? range != nil : date != nil
  }

  /// 清除当前值（清除按钮；调用方的 binding 即信号）。
  private func clearSelection() {
    date = nil
    range = nil
  }

  private var displayText: Text? {
    if isRange {
      guard let range else { return placeholder }
      return rangeDisplayText(range)
    }
    guard let date else { return placeholder }
    switch mode {
    case .date:
      return Text(date, style: .date)  // wd-structure-check:disable R21 — 加行盒
    case .time:
      return Text(date, style: .time)  // wd-structure-check:disable R21 — 加行盒
    case .dateAndTime:
      return Text(date, format: .dateTime)  // wd-structure-check:disable R21 — 加行盒
    }
  }

  // MARK: - 快捷 Chip

  private var quickChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: WDSpacing.s3) {
        ForEach(quickOptions) { option in
          WDChip(
            label: option.label,
            isSelected: Binding(
              get: { false },
              set: { selected in
                if selected {
                  applyQuickOption(option)
                }
              }
            )
          )
        }
      }
    }
  }

  private func applyQuickOption(_ option: WDDatePickerQuickOption) {
    guard isEnabled else { return }
    date = mergedDate(daySource: option.date, timeSource: date)
    showsSheet = false
  }

  // MARK: - 弹层

  @ViewBuilder private var sheetContent: some View {
    if isRange {
      calendarView
    } else {
      switch mode {
      case .date:
        calendarView
      case .time:
        timeWheel
      case .dateAndTime:
        VStack(spacing: WDSpacing.s3) {
          calendarView
          Divider().overlay(colors.borderHairline)
          timeWheel
        }
      }
    }
  }

  // MARK: - 自建月历

  private var calendarView: some View {
    VStack(spacing: WDSpacing.s2) {
      monthHeader
      weekdayHeader
      dayGrid
    }
    .padding(.horizontal, WDSpacing.s5)
    .padding(.top, WDSpacing.s4)
    .background(colors.surfaceCardSolid)
  }

  private var monthHeader: some View {
    HStack(spacing: WDSpacing.s3) {
      monthButton(offset: -1, icon: .back, month: monthDate(offset: -1))
      Spacer(minLength: WDSpacing.s3)
      Text(visibleMonth, format: .dateTime.year().month(.wide))
        .wdFont(WDType.headline)
        .wdLineBox(WDType.headline)
        .foregroundStyle(colors.textPrimary)
      Spacer(minLength: WDSpacing.s3)
      monthButton(offset: 1, icon: .disclose, month: monthDate(offset: 1))
    }
    .frame(minHeight: WDSize.touchTargetMin)
  }

  private func monthButton(offset: Int, icon: WDIconName, month: Date) -> some View {
    Button {
      guard let next = calendar.date(byAdding: .month, value: offset, to: visibleMonth) else {
        return
      }
      visibleMonth = next
    } label: {
      WDIcon(icon: icon, size: .sm)
        .foregroundStyle(colors.textBrand)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(month, format: .dateTime.year().month(.wide)))
  }

  private var weekdayHeader: some View {
    HStack(spacing: 0) {
      ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
        Text(verbatim: symbol)
          .wdFont(WDType.caption1)
          .wdLineBox(WDType.caption1)
          .foregroundStyle(colors.textTertiary)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var dayGrid: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: Self.columnCount),
      spacing: 0
    ) {
      ForEach(0..<leadingBlankCount, id: \.self) { _ in
        Color.clear.frame(height: Self.dayCellSize)
      }
      ForEach(monthDays, id: \.self) { day in
        dayCell(day)
      }
    }
    .accessibilityElement(children: .contain)
  }

  private func dayCell(_ day: Date) -> some View {
    let selected = isSelected(day)
    let inRange = isInRange(day)
    let allowed = isAllowed(day)
    let today = calendar.isDateInToday(day)
    let dayNumber = calendar.component(.day, from: day)
    return Button {
      select(day)
    } label: {
      ZStack {
        if selected {
          Circle().fill(colors.textBrand)
        } else if inRange {
          Circle().fill(colors.surfaceTint)
        }
        VStack(spacing: 1) {
          Text(verbatim: "\(dayNumber)")
            .wdFont(WDType.subheadline)
            .wdLineBox(WDType.subheadline)
            .foregroundStyle(selected ? colors.textOnDark : colors.textPrimary)
          if today && !selected {
            Circle()
              .fill(colors.textBrand)
              .frame(width: Self.todayDotSize, height: Self.todayDotSize)
          }
        }
      }
      .frame(width: Self.dayCellSize, height: Self.dayCellSize)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!allowed)
    .opacity(allowed ? 1 : Self.disabledDayOpacity)
    .accessibilityLabel(dayAccessibilityLabel(day))
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  // MARK: - 时间滚轮

  private var timeWheel: some View {
    DatePicker("", selection: timeSelection, displayedComponents: .hourAndMinute)
      .datePickerStyle(.wheel)
      .labelsHidden()
  }

  private var timeSelection: Binding<Date> {
    Binding(
      get: { date ?? Date() },
      set: { picked in date = mergedDate(daySource: date ?? picked, timeSource: picked) }
    )
  }

  // MARK: - 日历计算

  private var weekdaySymbols: [String] {
    let symbols = calendar.veryShortWeekdaySymbols
    let start = calendar.firstWeekday - 1
    return Array(symbols[start...] + symbols[..<start])
  }

  private var leadingBlankCount: Int {
    guard let first = calendar.dateInterval(of: .month, for: visibleMonth)?.start else { return 0 }
    let weekday = calendar.component(.weekday, from: first)
    return (weekday - calendar.firstWeekday + Self.weekdayCount) % Self.weekdayCount
  }

  private var monthDays: [Date] {
    guard let interval = calendar.dateInterval(of: .month, for: visibleMonth),
      let range = calendar.range(of: .day, in: .month, for: visibleMonth)
    else { return [] }
    return range.compactMap { day in
      calendar.date(byAdding: .day, value: day - 1, to: interval.start)
    }
  }

  private func monthDate(offset: Int) -> Date {
    calendar.date(byAdding: .month, value: offset, to: visibleMonth) ?? visibleMonth
  }

  /// 单日读屏标签（系统本地化；构造与布局无关）。
  private func dayAccessibilityLabel(_ day: Date) -> Text {
    let text = day.formatted(Self.dayAccessibilityFormat)
    return Text(verbatim: text)  // wd-structure-check:disable R21 — 读屏
  }

  private func isSelected(_ day: Date) -> Bool {
    if isRange {
      return isRangeEndpoint(day)
    }
    guard let date else { return false }
    return calendar.isDate(date, inSameDayAs: day)
  }

  /// 范围内部（不含端点之外的任意中间日）。
  private func isInRange(_ day: Date) -> Bool {
    guard isRange, let range else { return false }
    let target = calendar.startOfDay(for: day)
    let lower = calendar.startOfDay(for: range.lowerBound)
    let upper = calendar.startOfDay(for: range.upperBound)
    return target >= lower && target <= upper
  }

  /// 范围端点（实心圆）。
  private func isRangeEndpoint(_ day: Date) -> Bool {
    guard isRange, let range else { return false }
    let target = calendar.startOfDay(for: day)
    return target == calendar.startOfDay(for: range.lowerBound)
      || target == calendar.startOfDay(for: range.upperBound)
  }

  private func isAllowed(_ day: Date) -> Bool {
    guard let bounds else { return true }
    let start = calendar.startOfDay(for: day)
    return start >= calendar.startOfDay(for: bounds.lowerBound)
      && start <= calendar.startOfDay(for: bounds.upperBound)
  }

  private func select(_ day: Date) {
    guard isAllowed(day) else { return }
    if isRange {
      let result = WDDateRangeSelection.applying(day, to: range, calendar: calendar)
      range = result.range
      if result.completed {
        showsSheet = false
      }
      return
    }
    date = mergedDate(daySource: day, timeSource: date)
    if mode == .date {
      showsSheet = false
    }
  }

  /// 把 `daySource` 的年月日与 `timeSource` 的时分合成一个日期。
  private func mergedDate(daySource: Date, timeSource: Date?) -> Date {
    var components = calendar.dateComponents([.hour, .minute], from: timeSource ?? daySource)
    let day = calendar.dateComponents([.year, .month, .day], from: daySource)
    components.year = day.year
    components.month = day.month
    components.day = day.day
    return calendar.date(from: components) ?? daySource
  }

  // MARK: - 状态/几何

  private var sheetHeight: CGFloat {
    if isRange {
      return Self.dateSheetHeight
    }
    switch mode {
    case .date: return Self.dateSheetHeight
    case .time: return Self.timeSheetHeight
    case .dateAndTime: return Self.dateTimeSheetHeight
    }
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 单日读屏格式（系统本地化，不硬编码）。
  private static let dayAccessibilityFormat = Date.FormatStyle.dateTime.year().month(.wide).day()
    .weekday(.wide)
  /// 每周 7 天。
  private static let weekdayCount = 7  // wd-structure-check:disable R7 — 设计
  /// 日历列数 7。
  private static let columnCount = 7  // wd-structure-check:disable R7 — 设计 23 §3 的 7 列
  /// 日期单元 44（设计 23 §3）。
  private static let dayCellSize: CGFloat = 44  // wd-structure-check:disable R7 — 设计值
  /// 今天圆点 4（设计 23 §5 的标记，规格未给尺寸）。
  private static let todayDotSize: CGFloat = 4  // wd-structure-check:disable R7 — 设计未给值
  /// 不可选日期透明度 30%（设计 23 §5）。
  private static let disabledDayOpacity: CGFloat = 0.3  // wd-structure-check:disable R7 — 设计值
  /// 日期弹层高度。
  private static let dateSheetHeight: CGFloat = 420  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 时间弹层高度。
  private static let timeSheetHeight: CGFloat = 300  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 日期 + 时间弹层高度。
  private static let dateTimeSheetHeight: CGFloat = 560  // wd-structure-check:disable R7 — 设计
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}
