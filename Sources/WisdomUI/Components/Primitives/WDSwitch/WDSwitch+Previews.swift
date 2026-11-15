#if WD_PREVIEWS
  import SwiftUI

  private struct WDSwitchPreviewHost: View {
    @State private var enabled = true
    @State private var disabled = false

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDSwitch(isOn: $enabled, label: Text(verbatim: "共享给家人"))
        WDSwitch(isOn: .constant(false), label: Text(verbatim: "每日提醒"))
        WDSwitch(isOn: $disabled, label: Text(verbatim: "免打扰"))
          .disabled(true)
        WDSwitch(
          isOn: $enabled, label: Text(verbatim: "共享给家人"),
          description: Text(verbatim: "关闭后不再收到推送"), size: .standard)
        WDSwitch(isOn: $enabled, label: Text(verbatim: "紧凑档"), description: nil, size: .compact)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDSwitch 浅色") {
    WDSwitchPreviewHost()
  }

  #Preview("WDSwitch 深色") {
    WDSwitchPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
