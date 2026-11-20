import SwiftUI

/// 弹层自适应高度（纯逻辑；设计 23 §8「弹层不与键盘同时出现」+ §10 的 44 触控口径）。
///
/// 口径：
/// - **按内容量高**：月历（月份头 + 星期头 + 固定 6 行日期单元）/ 时间滚轮 / 两者的组合，
///   高度由内容逐段累加，不再用固定三档字面量；
/// - **夹在可用安全区内**：可用高度由 `PresentationDetent.Context.maxDetentValue` 给出
///   （= 系统为该弹层留出的最大高度，已扣掉顶部安全区），超出的部分由弹层内滚动兜住 ⇒ 不裁切、不溢出；
/// - 高度里出现的每个数都来自令牌或显式登记的「设计未给值」常量，可逐行追溯（R7）。
enum WDDatePickerSheetHeight {
  /// 量高所需的输入（与视图解耦，便于纯函数断言）。
  struct Metrics: Sendable, Equatable {
    /// 当前动态字体档（月份头 / 星期头行盒随之增长）。
    var dynamicTypeSize: DynamicTypeSize

    /// 构造（默认系统当前档由调用方传入）。
    init(dynamicTypeSize: DynamicTypeSize) {
      self.dynamicTypeSize = dynamicTypeSize
    }
  }

  /// 月历的上内距（与 `calendarView` 的 `.padding(.top,)` 同源）。
  static let calendarTopPadding = WDSpacing.s4
  /// 月历的下内距（同上，保证最后一行不贴边）。
  static let calendarBottomPadding = WDSpacing.s3
  /// 月历内部的行间距（月份头 / 星期头 / 网格之间）。
  static let calendarSpacing = WDSpacing.s2
  /// 月历与时间滚轮之间的间距（`sheetContent` 的 `VStack(spacing:)`）。
  static let sectionSpacing = WDSpacing.s3
  /// 时间滚轮的上下内距。
  static let wheelVerticalPadding = WDSpacing.s4
  /// 系统时间滚轮的固有高度。
  ///
  /// 设计 23 未给该值（表里只有触发入口 / Chip / 日历单元），取系统 `DatePicker` 滚轮的固有高度；
  /// 该值不随动态字体变化（滚轮是系统控件，字号由系统决定）。
  static let timeWheelHeight: CGFloat = 216  // wd-structure-check:disable R7 — 设计未给值，取系统滚轮固有高度
  /// 分割线高度（`WDDivider` 的 hairline）。
  static let dividerHeight: CGFloat = 1  // wd-structure-check:disable R7 — 1pt hairline

  /// 最小可用高度要保住的行数（再小就连「翻月」都做不了）。
  static let minimumRows = 3  // wd-structure-check:disable R7 — 设计未给值，取仍可翻月的三行

  /// 系统档位上下文 → 最终高度（`CustomPresentationDetent` 的唯一入口）。
  static func resolvedHeight(
    layout: WDDatePickerSheetLayout,
    context: PresentationDetent.Context
  ) -> CGFloat {
    detentHeight(
      layout: layout,
      metrics: Metrics(dynamicTypeSize: context.dynamicTypeSize),
      available: context.maxDetentValue
    )
  }

  /// 内容自然高度（未夹取）。
  static func contentHeight(layout: WDDatePickerSheetLayout, metrics: Metrics) -> CGFloat {
    switch layout {
    case .calendar:
      return calendarHeight(metrics: metrics)
    case .timeWheel:
      return wheelHeight()
    case .calendarAndTime:
      return calendarHeight(metrics: metrics) + sectionSpacing + dividerHeight + sectionSpacing
        + wheelHeight()
    }
  }

  /// 最小可用高度（月份头 + 星期头 + 三行日期单元）。
  static func minimumHeight(layout: WDDatePickerSheetLayout, metrics: Metrics) -> CGFloat {
    switch layout {
    case .calendar:
      return headerBlockHeight(metrics: metrics) + gridHeight(rows: minimumRows)
        + calendarTopPadding + calendarBottomPadding
    case .timeWheel:
      return wheelHeight()
    case .calendarAndTime:
      return headerBlockHeight(metrics: metrics) + gridHeight(rows: minimumRows)
        + calendarTopPadding + calendarBottomPadding + sectionSpacing + dividerHeight
        + sectionSpacing + wheelHeight()
    }
  }

  /// 把内容高度夹进 `[minimum, available]`。
  ///
  /// - `available <= 0`（还没量到可用高度）⇒ 返回内容高度（不裁）；
  /// - 可用高度比下限还小（横屏 / 小屏）⇒ **服从可用高度**（宁可滚动也不溢出安全区）；
  /// - 其余情况 = `min(max(content, minimum), available)`。
  static func clamped(contentHeight: CGFloat, minimum: CGFloat, available: CGFloat) -> CGFloat {
    guard available > 0 else { return max(contentHeight, minimum) }
    return min(max(contentHeight, minimum), available)
  }

  /// 便捷入口：按布局 + 动态字体档算「夹到可用高度」的最终档位高度。
  static func detentHeight(
    layout: WDDatePickerSheetLayout,
    metrics: Metrics,
    available: CGFloat
  ) -> CGFloat {
    clamped(
      contentHeight: contentHeight(layout: layout, metrics: metrics),
      minimum: minimumHeight(layout: layout, metrics: metrics),
      available: available
    )
  }

  // MARK: - 分段

  /// 月历高度 = 上下内距 + 月份头 + 星期头 + 固定行数的日期网格。
  static func calendarHeight(metrics: Metrics) -> CGFloat {
    headerBlockHeight(metrics: metrics) + gridHeight(rows: WDDatePickerGrid.rowCapacity)
      + calendarTopPadding + calendarBottomPadding
  }

  /// 时间滚轮高度 = 固有高度 + 上下内距（上下各一，与视图的 `.padding(.vertical,:)` 同源）。
  /// 写成两个加数而不是 `× 2`：R7 会把裸字面量 `2` 判为不可追溯（本例是数量而非尺寸）。
  static func wheelHeight() -> CGFloat {
    timeWheelHeight + wheelVerticalPadding + wheelVerticalPadding
  }

  /// 标题区高度 = 月份头 + 行间距 + 星期头（两段共用同一个月历列宽）。
  private static func headerBlockHeight(metrics: Metrics) -> CGFloat {
    let monthHeader = max(
      WDSize.touchTargetMin,
      WDFontMetrics.lineBoxHeight(for: WDType.headline, dynamicTypeSize: metrics.dynamicTypeSize)
    )
    let weekdayHeader = WDFontMetrics.lineBoxHeight(
      for: WDType.caption1, dynamicTypeSize: metrics.dynamicTypeSize)
    return monthHeader + calendarSpacing + weekdayHeader + calendarSpacing
  }

  /// 日期网格高度 = 行数 × 日期单元高（单元固定 44，设计 23 §3）。
  private static func gridHeight(rows: Int) -> CGFloat {
    CGFloat(max(0, rows)) * WDDatePickerGrid.cellSize
  }
}

/// 弹层自适应档位：把内容高度夹进系统给该弹层的可用高度（`context.maxDetentValue`）。
///
/// 为什么要 `CustomPresentationDetent` 而不是在 `body` 里算：只有 `Context` 才拿得到
/// **可用高度**（最大档位值，已扣顶部安全区）。`height(in:)` 是静态方法，`PresentationDetent.custom`
/// 只接受**类型** ⇒ 每种布局一个空结构体（不引入静态可变状态，R13a）。
struct WDDatePickerCalendarOnlyDetent: CustomPresentationDetent {
  /// 按可用高度夹取后的弹层高度。
  static func height(in context: Context) -> CGFloat? {
    WDDatePickerSheetHeight.resolvedHeight(layout: .calendar, context: context)
  }
}

/// 只有时间滚轮的弹层档位。
struct WDDatePickerTimeOnlyDetent: CustomPresentationDetent {
  /// 按可用高度夹取后的弹层高度。
  static func height(in context: Context) -> CGFloat? {
    WDDatePickerSheetHeight.resolvedHeight(layout: .timeWheel, context: context)
  }
}

/// 月历 + 时间滚轮的弹层档位。
struct WDDatePickerCalendarAndTimeDetent: CustomPresentationDetent {
  /// 按可用高度夹取后的弹层高度。
  static func height(in context: Context) -> CGFloat? {
    WDDatePickerSheetHeight.resolvedHeight(layout: .calendarAndTime, context: context)
  }
}
