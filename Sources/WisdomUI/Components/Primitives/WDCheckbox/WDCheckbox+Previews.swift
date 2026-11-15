#if WD_PREVIEWS
  import SwiftUI

  private struct WDCheckboxPreviewHost: View {
    @State private var first = true
    @State private var second = false
    @State private var compact = false

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDCheckbox(isChecked: $first, label: Text(verbatim: "共享给家人"))
        WDCheckbox(isChecked: $second, label: Text(verbatim: "每日提醒"))
        WDCheckbox(
          isChecked: $compact, label: Text(verbatim: "紧凑：每日提醒"), size: .compact)
        WDCheckbox(
          isChecked: .constant(false), label: Text(verbatim: "紧凑半选"), size: .compact,
          isIndeterminate: true)
        WDCheckbox(isChecked: .constant(false), label: Text(verbatim: "半选"), isIndeterminate: true)
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
