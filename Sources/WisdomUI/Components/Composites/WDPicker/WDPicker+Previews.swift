#if WD_PREVIEWS
  import SwiftUI

  private struct WDPickerPreviewHost: View {
    @State private var menu: String? = "chore"
    @State private var wheel: String? = nil
    private let options: [WDPickerOption] = [
      .init(id: "chore", label: Text(verbatim: "家务"), group: Text(verbatim: "家庭")),
      .init(id: "task", label: Text(verbatim: "任务"), group: Text(verbatim: "家庭")),
      .init(id: "travel", label: Text(verbatim: "出行")),
      .init(id: "meal", label: Text(verbatim: "用餐")),
    ]

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDPicker(selection: $menu, label: Text(verbatim: "分类"), options: options)
        WDPicker(
          selection: $wheel, label: Text(verbatim: "频率"), options: options,
          placeholder: Text(verbatim: "请选择"), style: .wheel)
        WDPicker(selection: .constant(nil), label: Text(verbatim: "禁用"), options: options)
          .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDPicker 浅色") {
    WDPickerPreviewHost()
  }

  #Preview("WDPicker 深色") {
    WDPickerPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
