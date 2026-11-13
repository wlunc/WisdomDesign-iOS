#if WD_PREVIEWS
  import SwiftUI

  private struct WDStepperPreviewHost: View {
    @State private var standard = 3
    @State private var compact = 12
    @State private var lower = 1
    @State private var disabled = 5

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDStepper(value: $standard, label: Text(verbatim: "数量"), in: 0...20)
        WDStepper(
          value: $compact, label: Text(verbatim: "人数"), in: 0...99, size: .compact,
          unit: Text(verbatim: "人"))
        WDStepper(value: $lower, label: Text(verbatim: "下限"), in: 1...10)
        WDStepper(value: $disabled, label: Text(verbatim: "禁用"), in: 0...10)
          .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDStepper 浅色") {
    WDStepperPreviewHost()
  }

  #Preview("WDStepper 深色") {
    WDStepperPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
