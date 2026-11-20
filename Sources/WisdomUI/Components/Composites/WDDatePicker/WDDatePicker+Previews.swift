#if WD_PREVIEWS
  import SwiftUI

  private struct WDDatePickerPreviewHost: View {
    @State private var deadline: Date? = Date()
    @State private var noDate: Date? = nil
    @State private var time: Date? = Date()
    @State private var both: Date? = Date()
    /// 已过期的日期（用来核对 danger 色与读屏提示）。
    @State private var expired: Date? = Calendar.current.date(byAdding: .day, value: -3, to: Date())

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDDatePicker(
          date: $deadline,
          label: Text(verbatim: "截止日期"),
          quickOptions: [
            .init(id: "today", label: Text(verbatim: "今天"), date: Date()),
            .init(
              id: "tomorrow", label: Text(verbatim: "明天"),
              date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
          ]
        )
        WDDatePicker(date: $noDate, label: Text(verbatim: "提醒时间"), mode: .time)
        WDDatePicker(date: $both, label: Text(verbatim: "预约"), mode: .dateAndTime)
        WDDatePicker(date: $time, label: Text(verbatim: "禁用")).disabled(true)
        // B17-3：已过期（文字用 status.danger）+ 读屏提示（文案由调用方给 —— L-B）。
        WDDatePicker(
          date: $expired,
          label: Text(verbatim: "上次完成"),
          expiredAccessibilityHint: Text(verbatim: "已过期")
        )
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDDatePicker 浅色") {
    WDDatePickerPreviewHost()
  }

  #Preview("WDDatePicker 深色") {
    WDDatePickerPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
