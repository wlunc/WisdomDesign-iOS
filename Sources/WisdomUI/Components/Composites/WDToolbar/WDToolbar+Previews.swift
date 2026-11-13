#if WD_PREVIEWS
  import SwiftUI

  private struct WDToolbarPreviewHost: View {
    @State private var bold = true

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDToolbar(
          items: [
            .init(id: "undo", icon: .undo, accessibilityLabel: Text(verbatim: "撤销"), action: {}),
            .init(id: "redo", icon: .redo, accessibilityLabel: Text(verbatim: "重做"), action: {}),
            .init(
              id: "bold", icon: .edit, accessibilityLabel: Text(verbatim: "加粗"),
              isSelected: bold, action: { bold.toggle() }),
            .init(
              id: "off", icon: .delete, accessibilityLabel: Text(verbatim: "删除"),
              isEnabled: false, action: {}),
          ],
          accessibilityLabel: Text(verbatim: "编辑工具")
        )
        WDToolbar(
          items: (1...9).map { index in
            WDToolbarItem(
              id: "\(index)", icon: .task, accessibilityLabel: Text(verbatim: "工具 \(index)"),
              action: {})
          },
          accessibilityLabel: Text(verbatim: "编辑工具"),
          overflowAccessibilityLabel: Text(verbatim: "更多工具")
        )
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDToolbar 浅色") {
    WDToolbarPreviewHost()
  }

  #Preview("WDToolbar 深色") {
    WDToolbarPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
