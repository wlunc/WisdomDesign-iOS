#if WD_PREVIEWS
  import SwiftUI

  private struct WDChipPreviewHost: View {
    @State private var selected = true
    @State private var another = false

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s3) {
          WDChip(label: Text(verbatim: "全家共享"))
          WDChip(label: Text(verbatim: "家务"), leadingIcon: .task)
          WDChip(label: Text(verbatim: "已完成"), isSelected: $selected)
          WDChip(label: Text(verbatim: "待整理"), isSelected: $another)
        }
        HStack(spacing: WDSpacing.s3) {
          WDChip(label: Text(verbatim: "妈妈"), deleteAccessibilityLabel: Text(verbatim: "移除筛选")) {}
          WDChip(label: Text(verbatim: "紧凑"), size: .compact)
        }
        WDChip(label: Text(verbatim: "禁用"), isSelected: .constant(true))
          .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDChip 浅色") {
    WDChipPreviewHost()
  }

  #Preview("WDChip 深色") {
    WDChipPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
