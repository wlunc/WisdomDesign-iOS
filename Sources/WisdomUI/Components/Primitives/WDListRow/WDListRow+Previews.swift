#if WD_PREVIEWS
  import SwiftUI

  private struct WDListRowPreviewHost: View {
    var body: some View {
      VStack(spacing: 0) {
        WDListRow(
          title: Text(verbatim: "整理储物间"),
          subtitle: Text(verbatim: "今天 18:00 前"),
          leading: .icon(.task),
          trailing: .value(Text(verbatim: "3 件")),
          action: {}
        )
        WDListRow(
          title: Text(verbatim: "妈妈的待办"),
          subtitle: Text(verbatim: "已完成 2 项"),
          leading: .avatar(.init(label: Text(verbatim: "妈"))),
          trailing: .badge(.init(label: Text(verbatim: "进行中")))
        )
        WDListRow(
          title: Text(verbatim: "每天八杯水"),
          leading: .checkbox,
          isSelected: true,
          action: {}
        )
        WDListRow(
          title: Text(verbatim: "采购清单"),
          leading: .selectionIndicator,
          trailing: .disclosure,
          isSelected: true,
          action: {}
        )
        WDListRow(title: Text(verbatim: "只读的一行"), trailing: .value(Text(verbatim: "12:30")))
      }
      .padding(.vertical, WDSpacing.s2)
    }
  }

  #Preview("WDListRow 浅色") {
    WDListRowPreviewHost()
  }

  #Preview("WDListRow 深色") {
    WDListRowPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
