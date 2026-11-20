#if WD_PREVIEWS
  import SwiftUI

  private struct WDSliderPreviewHost: View {
    @State private var progress = 0.62
    @State private var discrete = 2.0
    @State private var disabled = 0.8
    @State private var budget = 2.0...8.0

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDSlider(value: $progress, label: Text(verbatim: "完成度"), showsValueLabel: true)
        WDSlider(value: $discrete, label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1)
        WDSlider(value: $disabled, label: Text(verbatim: "禁用"))
          .disabled(true)
        // B17 范围形态（两个手柄；区间文案含分隔符，必须由调用方给 —— L-B）。
        WDSlider(
          range: $budget,
          label: Text(verbatim: "预算区间"),
          in: 0...10,
          step: 1,
          showsValueLabel: true,
          rangeText: { Text(verbatim: "\(Int($0.lowerBound))–\(Int($0.upperBound))") },
          lowerAccessibilityLabel: Text(verbatim: "预算下限"),
          upperAccessibilityLabel: Text(verbatim: "预算上限")
        )
      }
      .padding(WDSpacing.s5)
      .frame(width: 320)
    }
  }

  #Preview("WDSlider 浅色") {
    WDSliderPreviewHost()
  }

  #Preview("WDSlider 深色") {
    WDSliderPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
