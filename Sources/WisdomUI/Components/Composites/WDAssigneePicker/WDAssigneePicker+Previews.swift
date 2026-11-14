#if WD_PREVIEWS
  import SwiftUI

  private struct WDAssigneePickerPreviewHost: View {
    @State private var single: String? = "mom"
    @State private var multi: Set<String> = ["mom", "dad"]
    @State private var noOne: String? = nil

    private var items: [WDAssigneePickerItem] {
      [
        .init(
          id: "mom", avatar: .init(label: Text(verbatim: "妈")),
          accessibilityLabel: Text(verbatim: "妈妈"), name: Text(verbatim: "妈妈")),
        .init(
          id: "dad", avatar: .init(label: Text(verbatim: "爸")),
          accessibilityLabel: Text(verbatim: "爸爸"), name: Text(verbatim: "爸爸")),
        .init(
          id: "li", avatar: .init(label: Text(verbatim: "李")),
          accessibilityLabel: Text(verbatim: "小李"), name: Text(verbatim: "小李")),
        .init(
          id: "wang", avatar: .init(label: Text(verbatim: "王")),
          accessibilityLabel: Text(verbatim: "王阿姨"), name: Text(verbatim: "王阿姨")),
        .init(
          id: "zhang", avatar: .init(label: Text(verbatim: "张")),
          accessibilityLabel: Text(verbatim: "张三"), name: Text(verbatim: "张三")),
        .init(
          id: "zhao", avatar: .init(label: Text(verbatim: "赵")),
          accessibilityLabel: Text(verbatim: "赵六"), name: Text(verbatim: "赵六")),
        .init(
          id: "chen", avatar: .init(label: Text(verbatim: "陈")),
          accessibilityLabel: Text(verbatim: "陈七"), name: Text(verbatim: "陈七"),
          isEnabled: false, unavailableReason: Text(verbatim: "已离开")),
        .init(
          id: "liu", avatar: .init(label: Text(verbatim: "刘")),
          accessibilityLabel: Text(verbatim: "刘八"), name: Text(verbatim: "刘八")),
      ]
    }

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDAssigneePicker(
          selection: $single,
          label: Text(verbatim: "指派给"),
          items: items,
          unassigned: .init(
            label: Text(verbatim: "未指派"), accessibilityLabel: Text(verbatim: "未指派")),
          positionText: { index, total in Text(verbatim: "第 \(index) 项，共 \(total) 项") }
        )
        WDAssigneePicker(
          selection: $multi,
          label: Text(verbatim: "参与人"),
          items: items
        )
        WDAssigneePicker(
          selection: $noOne,
          label: Text(verbatim: "紧凑"),
          items: items,
          size: .compact
        )
        WDAssigneePicker(
          selection: $single,
          label: Text(verbatim: "整体禁用"),
          items: items
        )
        .disabled(true)
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDAssigneePicker 浅色") {
    WDAssigneePickerPreviewHost()
  }

  #Preview("WDAssigneePicker 深色") {
    WDAssigneePickerPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
