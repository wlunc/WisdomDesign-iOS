import Combine
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

/// 弹层布局（纯逻辑取值；单日期与范围共用同一套三选一）。
enum WDDatePickerSheetLayout: Sendable, Equatable {
  /// 只有月历（`.date` / 纯日期范围）。
  case calendar
  /// 只有时间滚轮（`.time`）。
  case timeWheel
  /// 月历 + 分隔线 + 时间滚轮（`.dateAndTime` / 范围 + 时间）。
  case calendarAndTime
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
  private let onClear: (@MainActor @Sendable () -> Void)?
  /// 已过期时附加的读屏提示（B17；L-B 注入点：文案由调用方给，库只决定“何时读”）。
  private let expiredAccessibilityHint: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.scenePhase) private var scenePhase

  /// 排版方向（RTL 下 ←/→ 的语义要镜像，见 `navigationStep(for:isRTL:)`）。
  @Environment(\.layoutDirection) private var layoutDirection
  /// 播报通道（L-B 注入点：文案由调用方给；本组件只播系统本地化格式的日期）。
  @Environment(\.wdAnnouncerText) private var announcer
  /// 过期判定的“今天”（B17：由系统「日变更」通知/回到前台刷新，**不自建计时器**）。
  @State private var now = Date()

  @State private var showsSheet = false
  @State private var visibleMonth = Date()
  /// 月历里的焦点日（方向键的起点；nil = 打开弹层时按当前值/边界初始化）。
  @State private var focusedDay: Date?
  /// 网格是否吃硬件键盘（方向键导航的前提）。
  @FocusState private var isGridFocused: Bool
  /// 读屏焦点跟随的日期（跨月翻页后把焦点交接给新单元格）。
  @AccessibilityFocusState private var a11yFocusedDay: Date?
  /// 范围 + 时间：第一次点选后暂存的起点日（终点未定；每次打开弹层 / 清除时清空）。
  @State private var pendingRangeStart: Date?
  /// 范围 + 时间：第一次点选**之前**滚轮拨出的时刻（点选日尚未定，先存着给起点用）。
  @State private var pendingRangeWheelTime: Date?

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
    self.onClear = nil
    self.expiredAccessibilityHint = nil
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
    self.onClear = nil
    self.expiredAccessibilityHint = nil
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
    self.onClear = nil
    self.expiredAccessibilityHint = nil
  }

  /// 构造（B10 增量；单日期 + 清除回调）。
  ///
  /// 设计 23 §8「清除 → 触发一次 onChange(nil)」：`onClear` **只在**用户点清除按钮、
  /// 且值确实从非空变空时调用**一次**；调用方自己把 binding 置 nil（外部清空）**不**回调。
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,
    quickOptions: [WDDatePickerQuickOption] = [],
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil,
    onClear: (@MainActor @Sendable () -> Void)? = nil,
    expiredAccessibilityHint: Text? = nil
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
    self.onClear = onClear
    self.expiredAccessibilityHint = expiredAccessibilityHint
  }

  /// 构造（B10 增量；范围 + 时间：设计 23 §4「范围」与「日期 + 时间」组合，两段式，先日期后时间）。
  ///
  /// `mode` 只区分「要不要带时刻」：`.date` = 纯日期范围（与既有范围构造同形）；
  /// `.dateAndTime` = 弹层为「月历 + 分隔线 + 时间滚轮」，两次点选成查后把**起点日 + 起点时刻**、
  /// **终点日 + 终点时刻**合成 `ClosedRange<Date>` 且保证 `lower <= upper`；
  /// `.time` 在范围里不成立 ⇒ 按 `.date` 处理（Debug 断言）。
  public init(
    range: Binding<ClosedRange<Date>?>,
    label: Text,
    placeholder: Text? = nil,
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil,
    onClear: (@MainActor @Sendable () -> Void)? = nil,
    mode: WDDatePickerMode = .date
  ) {
    assert(mode != .time, Self.rangeTimeModeAssertionMessage)
    self._date = .constant(nil)
    self._range = range
    self.label = label
    self.mode = WDDateRangeComposition.effectiveMode(mode)
    self.placeholder = placeholder
    self.quickOptions = []
    self.bounds = bounds
    self.isRange = true
    self.showsClearButton = showsClearButton
    self.clearAccessibilityLabel = clearAccessibilityLabel
    self.onClear = onClear
    self.expiredAccessibilityHint = nil
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
      sheetBody
    }
    .onChange(of: showsSheet) { _, presented in
      if presented {
        visibleMonth = date ?? range?.lowerBound ?? bounds?.lowerBound ?? Date()
        pendingRangeStart = nil
        pendingRangeWheelTime = nil
        focusedDay = initialFocusedDay
      } else {
        focusedDay = nil
      }
    }
    // 跨午夜过期翻转（B17）：系统「日变更」通知是唯一的日历信号，**不自建计时器**；
    // 回到前台再刷一次（覆盖时区/手动改时间等没有通知的场景）。
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
      now = Date()
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { now = Date() }
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
              .foregroundStyle(displayTextColor)
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
      .modifier(
        WDDatePickerExpiredHint(hint: isExpiredSelection ? expiredAccessibilityHint : nil))

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
  ///
  /// `onClear` 只在「用户点清除按钮」且「值确实从非空变空」时调一次；
  /// 外部把 binding 置 nil 走不到这里 ⇒ 不回调（纯判定见 `WDDatePicker.shouldReportClear`）。
  private func clearSelection() {
    let hadValue = hasValue
    date = nil
    range = nil
    pendingRangeStart = nil
    pendingRangeWheelTime = nil
    if Self.shouldReportClear(wasFilled: hadValue, isFilled: hasValue) {
      onClear?()
    }
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

  /// 触发入口文字色：已过期（仅单日期 .date / .dateAndTime）→ danger；否则按有无值。
  private var displayTextColor: Color {
    if isExpiredSelection { return colors.statusDanger }
    return hasValue ? colors.textPrimary : colors.textTertiary
  }

  /// 单日期已过期（范围不适用；.time 不参与）。
  private var isExpiredSelection: Bool {
    guard !isRange, mode != .time, let date else { return false }
    return Self.isExpired(date, now: now, calendar: calendar)
  }

  /// 纯逻辑：日期是否早于 now 所在日（按 startOfDay 比较；仅单日期语义）。
  nonisolated static func isExpired(_ date: Date, now: Date, calendar: Calendar) -> Bool {
    calendar.startOfDay(for: date) < calendar.startOfDay(for: now)
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

  /// 弹层容器：高度按内容自适应，并夹在系统给该弹层的可用高度里（`maxDetentValue`）。
  ///
  /// 三个分支各自挂一个**不同静态类型**的自适应档位（`CustomPresentationDetent` 的
  /// `height(in:)` 是静态方法，只能用类型传布局）；内容再包一层 `ScrollView`：
  /// 可用高度比内容小时（小屏 / 横屏 / 超大字号）滚动兜住 ⇒ **不裁切、不溢出安全区**。
  @ViewBuilder private var sheetBody: some View {
    switch Self.sheetLayout(isRange: isRange, mode: mode) {
    case .calendar:
      sheetScroll { calendarView }
        .presentationDetents([.custom(WDDatePickerCalendarOnlyDetent.self)])
        .presentationDragIndicator(.visible)
    case .timeWheel:
      sheetScroll { timeWheel }
        .presentationDetents([.custom(WDDatePickerTimeOnlyDetent.self)])
        .presentationDragIndicator(.visible)
    case .calendarAndTime:
      sheetScroll {
        VStack(spacing: WDDatePickerSheetHeight.sectionSpacing) {
          calendarView
          Divider().overlay(colors.borderHairline)
          timeWheel
        }
      }
      .presentationDetents([.custom(WDDatePickerCalendarAndTimeDetent.self)])
      .presentationDragIndicator(.visible)
    }
  }

  /// 弹层内容（可滚动；内容高度 == 档位高度时完全不滚动）。
  private func sheetScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ScrollView(.vertical) {
      content()
        .frame(maxWidth: .infinity)
    }
    .scrollBounceBehavior(.basedOnSize)
    .background(colors.surfaceCardSolid)
  }

  // MARK: - 自建月历

  private var calendarView: some View {
    VStack(spacing: WDDatePickerSheetHeight.calendarSpacing) {
      monthHeader
      weekdayHeader
      dayGrid
    }
    .padding(.horizontal, WDSpacing.s5)
    .padding(.top, WDDatePickerSheetHeight.calendarTopPadding)
    .padding(.bottom, WDDatePickerSheetHeight.calendarBottomPadding)
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
      // 方向键的起点跟着翻月走：焦点落到新月份里最接近的可选日（整月不可选时退回边界日）。
      focusedDay = WDDatePickerGrid.firstSelectableDay(
        inMonthOf: next, bounds: bounds, calendar: calendar)
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
      // 尾随空位补满固定行数：翻月时网格高度不变（弹层高度也就不会跟着跳）。
      // 与 dayCell 同款定高（R9）：补位格必须与日期单元等高，改令牌时两处一起跟随。
      // wd-structure-check:disable R9 — 补位格必须与日期单元等高（常量由 dayCellSize 单点给）
      ForEach(0..<trailingBlankCount, id: \.self) { _ in
        Color.clear.frame(height: Self.dayCellSize)
      }
    }
    .accessibilityElement(children: .contain)
    // 硬件键盘：网格可聚焦后接管方向键（←/→ 一天，↑/↓ 一周）。
    .focusable()
    .focusEffectDisabled()
    .focused($isGridFocused)
    .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
      handleArrowKey(press.key)
    }
    .onAppear {
      // 弹层刚出现就把键盘焦点给网格：外接键盘用户不必先 Tab 一圈才能用方向键。
      isGridFocused = true
    }
  }

  /// 方向键 → 箭头语义（`KeyEquivalent` 只在这里出现，其余逻辑走纯函数）。
  private func arrowKey(for key: KeyEquivalent) -> WDDatePickerArrowKey? {
    switch key {
    case .leftArrow: return .left
    case .rightArrow: return .right
    case .upArrow: return .up
    case .downArrow: return .down
    default: return nil
    }
  }

  private func handleArrowKey(_ key: KeyEquivalent) -> KeyPress.Result {
    guard let arrow = arrowKey(for: key) else { return .ignored }
    let step = WDDatePickerGrid.step(for: arrow, isRTL: layoutDirection == .rightToLeft)
    moveFocus(by: step)
    // 只监听 .down / .repeat（`onKeyPress(keys:)` 的默认相位）⇒ 命中即消费，弹层不滚动。
    return .handled
  }

  /// 焦点按步进移动：跨月时翻页，焦点跟到目标日，并把新日期读/聚焦出来。
  private func moveFocus(by step: WDDatePickerGridStep) {
    let base = focusedDay ?? initialFocusedDay
    let target = WDDatePickerGrid.moved(
      from: base,
      by: step.dayOffset,
      bounds: bounds,
      calendar: calendar
    )
    focusedDay = target
    if !calendar.isDate(target, equalTo: visibleMonth, toGranularity: .month) {
      visibleMonth = WDDatePickerGrid.monthStart(containing: target, calendar: calendar)
    }
    // 读屏：跨月后网格被重建，焦点要交接给目标日；同时在读屏下补一次完整日期朗读。
    if WDA11yRuntime.isAssistiveTechRunning {
      a11yFocusedDay = target
      announceDay(target, priority: .polite)
    }
  }

  /// 打开弹层时的焦点日：当前值 → 范围起点 → 边界下界 → 今天（全部归一到可选范围与当日零点）。
  private var initialFocusedDay: Date {
    let seed = date ?? range?.lowerBound ?? bounds?.lowerBound ?? now
    return WDDatePickerGrid.clamped(seed, in: bounds, calendar: calendar)
  }

  /// 网格尾随空位数（补满固定 6 行）。
  private var trailingBlankCount: Int {
    WDDatePickerGrid.trailingBlanks(
      leadingBlanks: leadingBlankCount,
      dayCount: monthDays.count,
      rowCapacity: WDDatePickerGrid.rowCapacity
    )
  }

  /// 朗读完整日期（系统本地化格式；库内零文案）。
  private func announceDay(_ day: Date, priority: WDAnnouncementPriority) {
    guard let announcer else { return }
    let text = day.formatted(Self.dayAccessibilityFormat)
    announcer(Text(verbatim: text), priority)  // wd-structure-check:disable R21 — 读屏
  }

  private func dayCell(_ day: Date) -> some View {
    let selected = isSelected(day)
    let inRange = isInRange(day)
    let allowed = isAllowed(day)
    let today = calendar.isDateInToday(day)
    let isFocusedDay = isKeyboardFocusedDay(day)
    let dayNumber = calendar.component(.day, from: day)
    return Button {
      focusedDay = day
      select(day)
    } label: {
      ZStack {
        if selected {
          Circle().fill(colors.textBrand)
        } else if inRange {
          Circle().fill(colors.surfaceTint)
        } else if isFocusedDay {
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
    // 读屏焦点跟随：跨月翻页 / 方向键移动后把焦点交接给目标日（只在读屏运行时挂，见 WDA11yRuntime）。
    .wdAccessibilityFocused($a11yFocusedDay, equals: calendar.startOfDay(for: day))
  }

  /// 方向键焦点是否落在本单元格（用高亮圈提示「下一步会选中谁」）。
  private func isKeyboardFocusedDay(_ day: Date) -> Bool {
    guard let focusedDay else { return false }
    return calendar.isDate(focusedDay, inSameDayAs: day)
  }

  // MARK: - 时间滚轮

  /// 系统时间滚轮。
  ///
  /// 上下内距由 `WDDatePickerSheetHeight.wheelVerticalPadding` 给，与高度公式**同源**：
  /// 公式按「固有高 + 上下内距」算，视图这里就必须真的把它加上，否则弹层会比内容高出一截
  /// （B20 评审 F4：此前视图零内距、公式加了两遍，实测时间形态多出 24pt）。
  private var timeWheel: some View {
    DatePicker("", selection: timeSelection, displayedComponents: .hourAndMinute)
      .datePickerStyle(.wheel)
      .labelsHidden()
      .padding(.vertical, WDDatePickerSheetHeight.wheelVerticalPadding)
  }

  /// 时间滚轮的受控值。
  ///
  /// - 单日期：沿用既有口径（年月日取 `date`，时分取滚轮）。
  /// - 范围（`.dateAndTime`）：时间**只作用于当前正在选的那一端**（起点已定、终点未定 ⇒ 终点，否则起点）；
  ///   改时间**不会**提前成查 —— 终点日仍由第二次点选决定。
  private var timeSelection: Binding<Date> {
    Binding(
      get: { rangeSelectionBase?.date ?? date ?? Date() },
      set: { picked in
        if let selection = rangeSelectionBase {
          applyRangeTime(picked, selection: selection)
        } else {
          date = mergedDate(daySource: date ?? picked, timeSource: picked)
        }
      }
    )
  }

  /// 范围形态下时间滚轮此刻作用的那一端（nil = 范围形态下还没开始选）。
  private var rangeSelectionBase: WDDateRangeComposition.Target? {
    guard isRange, WDDateRangeComposition.usesTime(mode) else { return nil }
    return WDDateRangeComposition.timeTarget(
      range: range,
      pendingStart: pendingRangeStart,
      fallback: pendingRangeWheelTime ?? Date(),
      calendar: calendar
    )
  }

  /// 滚轮被拨动：只改**当前那一端**的时刻，不会提前成查（终点日仍由第二次点选决定）。
  private func applyRangeTime(_ picked: Date, selection: WDDateRangeComposition.Target) {
    let updated = WDDateRangeComposition.applyingTime(
      picked,
      to: range,
      endpoint: selection.endpoint,
      pendingStart: pendingRangeStart,
      calendar: calendar
    )
    range = updated.range
    pendingRangeStart = updated.pendingStart
    pendingRangeWheelTime = updated.range == nil ? updated.pendingStart : nil
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
      applyRangeTap(day)
      return
    }
    date = mergedDate(daySource: day, timeSource: date)
    if mode == .date {
      showsSheet = false
    }
  }

  /// 范围形态的一次点选（纯日期与「范围 + 时间」共用日级口径，差别只在时刻归宿）。
  ///
  /// - 纯日期：`WDDateRangeSelection` 的日级结果原样写入（行为与此前一致）。
  /// - `.dateAndTime`：选日口径同样两步（起点日 → 终点日）；成查时把两端各自的时刻合回去 ——
  ///   起点时刻取本轮写入的起点（含滚轮预置），终点时刻优先取滚轮预置值、其次取已写进单点范围的终点时刻，
  ///   再交给 `normalized` 保证 `lower <= upper`。
  private func applyRangeTap(_ day: Date) {
    guard WDDateRangeComposition.usesTime(mode) else {
      let result = WDDateRangeSelection.applying(day, to: range, calendar: calendar)
      range = result.range
      if result.completed {
        showsSheet = false
      }
      pendingRangeStart = nil
      pendingRangeWheelTime = nil
      return
    }

    let isSameDay = { (lhs: Date, rhs: Date) in calendar.isDate(lhs, inSameDayAs: rhs) }
    let dayOnly = calendar.startOfDay(for: day)
    let tap = WDDateRangeComposition.applyTap(
      dayOnly, to: range, pendingStart: pendingRangeStart, calendar: calendar)
    if tap.completed {
      // 起点：本轮起点（单点范围）保留它的时刻。
      // 终点：第一次点选时滚轮给的预置时刻；若滚轮已写进范围的终点，就直接取它。
      let startTime = range?.lowerBound ?? pendingRangeWheelTime ?? dayOnly
      let endTime =
        pendingRangeWheelTime
        ?? range.map { isSameDay($0.lowerBound, $0.upperBound) ? $0.upperBound : $0.lowerBound }
        ?? dayOnly
      range = WDDateRangeComposition.normalized(
        start: tap.range.lowerBound,
        end: tap.range.upperBound,
        startTime: startTime,
        endTime: endTime,
        calendar: calendar
      )
    } else {
      // 起点日已定：把滚轮预置的时刻并在起点上，随后滚轮编辑的就是这条单点范围的起点。
      let startTime = pendingRangeWheelTime ?? dayOnly
      let start = WDDateRangeComposition.movingDay(
        tap.range.lowerBound, onto: startTime, calendar: calendar)
      range = WDDateRangeComposition.composed(
        start: start,
        end: start,
        startTime: start,
        endTime: start,
        calendar: calendar
      )
    }
    pendingRangeStart = tap.pendingStart
    if !tap.completed {
      pendingRangeWheelTime = nil
    }
    if tap.completed {
      showsSheet = false
    }
  }

  /// 弹层布局（纯逻辑）：范围 + `.dateAndTime` = 月历 + 分隔线 + 时间滚轮。
  nonisolated static func sheetLayout(
    isRange: Bool, mode: WDDatePickerMode
  ) -> WDDatePickerSheetLayout {
    if isRange {
      return WDDateRangeComposition.usesTime(mode) ? .calendarAndTime : .calendar
    }
    switch mode {
    case .date: return .calendar
    case .time: return .timeWheel
    case .dateAndTime: return .calendarAndTime
    }
  }

  /// 弹层高度（纯逻辑）：按内容量高后夹进可用高度（A-10：不再有固定三档）。
  ///
  /// - Parameters:
  ///   - available: 系统给该弹层的最大可用高度（`PresentationDetent.Context.maxDetentValue`）；
  ///     `<= 0`（未量到）时返回内容高度，不做裁切。
  ///   - dynamicTypeSize: 当前动态字体档（月份头 / 星期头的行盒随之增长）。
  ///     **仅测试入口**：真实弹层走 `CustomPresentationDetent.height(in:)`，那是 `static` 方法、
  ///     拿不到环境 ⇒ 运行时一律按 `.large` 计算。放大的字体档下标题行盒会变高，
  ///     内容可能略超出档位，由弹层内 `ScrollView` 兜住（不裁切）。这是**已登记限制**，
  ///     不是遗漏 —— 见 `docs/B20-EXIT-REPORT.md` §6-F6。
  nonisolated static func sheetHeight(
    isRange: Bool,
    mode: WDDatePickerMode,
    available: CGFloat,
    dynamicTypeSize: DynamicTypeSize = .large
  ) -> CGFloat {
    WDDatePickerSheetHeight.detentHeight(
      layout: sheetLayout(isRange: isRange, mode: mode),
      metrics: WDDatePickerSheetHeight.Metrics(dynamicTypeSize: dynamicTypeSize),
      available: available
    )
  }

  /// `onClear` 的触发条件（纯逻辑）：清除前是否有值、清除后是否为空。
  ///
  /// 设计 23 §8：只有「用户点清除按钮」且「值确实从非空变空」才回调一次。
  nonisolated static func shouldReportClear(wasFilled: Bool, isFilled: Bool) -> Bool {
    wasFilled && !isFilled
  }

  /// 把 `daySource` 的年月日与 `timeSource` 的时分合成一个日期（纯逻辑；Internal 侧复用同一口径）。
  nonisolated static func mergeDate(
    daySource: Date,
    timeSource: Date?,
    calendar: Calendar
  ) -> Date {
    var components = calendar.dateComponents([.hour, .minute], from: timeSource ?? daySource)
    let day = calendar.dateComponents([.year, .month, .day], from: daySource)
    components.year = day.year
    components.month = day.month
    components.day = day.day
    return calendar.date(from: components) ?? daySource
  }

  /// 把 `daySource` 的年月日与 `timeSource` 的时分合成一个日期。
  private func mergedDate(daySource: Date, timeSource: Date?) -> Date {
    Self.mergeDate(daySource: daySource, timeSource: timeSource, calendar: calendar)
  }

  // MARK: - 状态/几何

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 单日读屏格式（系统本地化，不硬编码）。
  private static let dayAccessibilityFormat = Date.FormatStyle.dateTime.year().month(.wide).day()
    .weekday(.wide)
  /// 每周 7 天。
  private static let weekdayCount = WDDatePickerGrid.weekLength
  /// 日历列数 7。
  private static let columnCount = 7  // wd-structure-check:disable R7 — 设计 23 §3 的 7 列
  /// 日期单元 44×44（设计 23 §3；取触控下限令牌，不写字面量）。
  private static let dayCellSize = WDDatePickerGrid.cellSize
  /// 今天圆点 4（设计 23 §5 的标记，规格未给尺寸）。
  private static let todayDotSize: CGFloat = 4  // wd-structure-check:disable R7 — 设计未给值
  /// 不可选日期透明度 30%（设计 23 §5）。
  private static let disabledDayOpacity: CGFloat = 0.3  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
  /// 范围重载收到 `.time` 时的 Debug 断言串（仅开发者可见，不渲染、不朗读）。
  private static let rangeTimeModeAssertionMessage =  // wd-structure-check:disable R15 — Debug 断言文本
    "datePicker range initializer does not support time mode"
}

/// 已过期时的读屏提示：只有调用方给了文案、且当前确实过期时才挂 hint。
/// 文案由调用方给（L-B）；库只决定“何时读”（颜色以外还有一条非视觉信号）。
private struct WDDatePickerExpiredHint: ViewModifier {
  let hint: Text?

  @ViewBuilder func body(content: Content) -> some View {
    if let hint {
      content.accessibilityHint(hint)
    } else {
      content
    }
  }
}
