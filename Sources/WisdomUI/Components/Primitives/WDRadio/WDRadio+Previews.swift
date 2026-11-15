#if WD_PREVIEWS
  import SwiftUI

  private struct WDRadioPreviewHost: View {
    @State private var selection = "self"
    @State private var described = "today"
    @State private var compact = "week"

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDRadio(
          selection: $selection,
          label: Text(verbatim: "可见范围"),
          options: [
            .init(id: "self", label: Text(verbatim: "仅自己可见")),
            .init(id: "family", label: Text(verbatim: "共享给全家")),
          ]
        )
        WDRadio(
          selection: $described,
          label: Text(verbatim: "提醒时间"),
          options: [
            .init(id: "today", label: Text(verbatim: "今天"), detail: Text(verbatim: "当天 09:00 提醒")),
            .init(
              id: "tomorrow", label: Text(verbatim: "明天"), detail: Text(verbatim: "次日 09:00 提醒")),
          ]
        )
        WDRadio(
          selection: $compact,
          label: Text(verbatim: "紧凑档"),
          size: .compact,
          options: [
            .init(id: "day", label: Text(verbatim: "按天")),
            .init(id: "week", label: Text(verbatim: "按周")),
          ]
        )
        WDRadio(
          selection: .constant("a"),
          label: Text(verbatim: "禁用"),
          options: [.init(id: "a", label: Text(verbatim: "不可修改"))]
        )
        .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDRadio 浅色") {
    WDRadioPreviewHost()
  }

  #Preview("WDRadio 深色") {
    WDRadioPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
