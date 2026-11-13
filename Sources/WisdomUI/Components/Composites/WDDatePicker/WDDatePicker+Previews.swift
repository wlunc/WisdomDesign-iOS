#if WD_PREVIEWS
  import SwiftUI

  private struct WDDatePickerPreviewHost: View {
    @State private var deadline: Date? = Date()
    @State private var noDate: Date? = nil
    @State private var time: Date? = Date()
    @State private var both: Date? = Date()

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
