import SwiftUI
import WisdomUI

/// M6 场景组件的 demo 实时预览（可交互）。
struct DemoM6Preview: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  var body: some View {
    switch component.id {
    case .assigneePicker:
      DemoAssigneePickerLivePreview(settings: settings)
    default:
      EmptyView()
    }
  }
}

/// demo 里复用的成员名单（8 人，触发「最多直接显示 6 个」的溢出；一人已离开）。
enum DemoAssigneePickerSamples {
  static let items: [WDAssigneePickerItem] = [
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
      accessibilityLabel: Text(verbatim: "赵六"), name: Text(verbatim: "赵六"),
      isEnabled: false, unavailableReason: Text(verbatim: "已离开")),
    .init(
      id: "chen", avatar: .init(label: Text(verbatim: "陈")),
      accessibilityLabel: Text(verbatim: "陈七"), name: Text(verbatim: "陈七")),
    .init(
      id: "liu", avatar: .init(label: Text(verbatim: "刘")),
      accessibilityLabel: Text(verbatim: "刘八"), name: Text(verbatim: "刘八")),
  ]
}

private struct DemoAssigneePickerLivePreview: View {
  let settings: DemoComponentSettings

  @State private var single: String? = "mom"
  @State private var multi: Set<String> = ["mom", "dad"]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDAssigneePicker(
        selection: $single,
        label: Text(verbatim: "指派给"),
        items: DemoAssigneePickerSamples.items,
        unassigned: .init(
          label: Text(verbatim: "未指派"), accessibilityLabel: Text(verbatim: "未指派")),
        size: settings.assigneePickerSize,
        positionText: { index, total in Text(verbatim: "第 \(index) 项，共 \(total) 项") }
      )
      .accessibilityIdentifier("assignee-picker-single")
      WDAssigneePicker(
        selection: $multi,
        label: Text(verbatim: "参与人（多选）"),
        items: DemoAssigneePickerSamples.items,
        size: settings.assigneePickerSize
      )
      .accessibilityIdentifier("assignee-picker-multi")
    }
  }
}

/// M6 场景组件的「变体」一览（demo 详情页）。
struct DemoM6VariantsSection: View {
  @Binding var settings: DemoComponentSettings

  var body: some View {
    DemoSection(
      "四种变体",
      subtitle: "单选默认、点已选项不取消；多选可取消；带未指派时首位是虚线圈；紧凑档不显示名字。"
    ) {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDAssigneePicker(
          selection: .constant("mom"),
          label: Text(verbatim: "单选 + 未指派"),
          items: DemoAssigneePickerSamples.items,
          unassigned: .init(
            label: Text(verbatim: "未指派"), accessibilityLabel: Text(verbatim: "未指派"))
        )
        WDAssigneePicker(
          selection: .constant(Set(["mom", "dad"])),
          label: Text(verbatim: "多选"),
          items: DemoAssigneePickerSamples.items
        )
        WDAssigneePicker(
          selection: .constant(nil as String?),
          label: Text(verbatim: "紧凑 · 32"),
          items: DemoAssigneePickerSamples.items,
          size: .compact
        )
        WDAssigneePicker(
          selection: .constant("dad"),
          label: Text(verbatim: "整体禁用 · 40%"),
          items: DemoAssigneePickerSamples.items
        )
        .disabled(true)
      }
    }
  }
}

/// M6 场景组件的「状态」一览（demo 详情页）。
struct DemoM6StatesSection: View {
  @Binding var settings: DemoComponentSettings

  var body: some View {
    DemoSection(
      "状态",
      subtitle: "选中 = 头像 1.05 + 品牌环（200ms 弹簧）；已离开成员 40% 去饱和、可见不可选。"
    ) {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDAssigneePicker(
          selection: .constant("mom"),
          label: Text(verbatim: "选中"),
          items: Array(DemoAssigneePickerSamples.items.prefix(3)),
          size: settings.assigneePickerSize
        )
        WDAssigneePicker(
          selection: .constant(nil as String?),
          label: Text(verbatim: "未选 / 已离开"),
          items: Array(DemoAssigneePickerSamples.items.prefix(5))
            + [DemoAssigneePickerSamples.items[5]],
          size: settings.assigneePickerSize
        )
        WDAssigneePicker(
          selection: .constant("zhao"),
          label: Text(verbatim: "溢出 +n"),
          items: DemoAssigneePickerSamples.items,
          onOverflowTap: {},
          overflowAccessibilityLabel: Text(verbatim: "查看全部 8 位成员")
        )
      }
    }
  }
}
