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

  /// 拖动回路 + 父级滚动共存的手动验收视口（设计 05 §8）。
  private struct WDSwitchDragPreviewHost: View {
    @State private var values = Array(repeating: false, count: 10)

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          ForEach(values.indices, id: \.self) { index in
            WDSwitch(
              isOn: $values[index], label: Text(verbatim: "共享给家人"),
              description: index.isMultiple(of: 2) ? nil : Text(verbatim: "关闭后不再收到推送"),
              size: index.isMultiple(of: 2) ? .standard : .compact)
          }
        }
        .padding(WDSpacing.s5)
      }
    }
  }

  #Preview("WDSwitch 浅色") {
    WDSwitchPreviewHost()
  }

  #Preview("WDSwitch 深色") {
    WDSwitchPreviewHost()
      .preferredColorScheme(.dark)
  }

  #Preview("WDSwitch 拖动与滚动") {
    WDSwitchDragPreviewHost()
  }
#endif
