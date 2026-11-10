#if WD_PREVIEWS
  import SwiftUI

  private struct WDCheckboxPreviewHost: View {
    @State private var first = true
    @State private var second = false

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDCheckbox(isChecked: $first, label: Text(verbatim: "共享给家人"))
        WDCheckbox(isChecked: $second, label: Text(verbatim: "每日提醒"))
        WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "已完成的选项"))
          .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDCheckbox 浅色") {
    WDCheckboxPreviewHost()
  }

  #Preview("WDCheckbox 深色") {
    WDCheckboxPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
