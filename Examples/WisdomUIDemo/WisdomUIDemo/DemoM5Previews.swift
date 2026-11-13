import SwiftUI
import WisdomUI

/// M5 十五件的 demo 实时预览（每个组件一小块可交互样例）。
///
/// 目的：让 demo 的无障碍审计与手动走查覆盖 M5 的契约面；不追求展示全部变体
/// （变体与差异见组件详情页的"实现细节"）。
struct DemoM5Preview: View {
  let component: DemoComponentEntry

  var body: some View {
    switch component.id {
    case .searchField: DemoSearchFieldLivePreview()
    case .radio: DemoRadioLivePreview()
    case .slider: DemoSliderLivePreview()
    case .stepper: DemoStepperLivePreview()
    case .chip: DemoChipLivePreview()
    case .avatarStack: DemoAvatarStackLivePreview()
    case .segmentedControl: DemoSegmentedControlLivePreview()
    case .picker: DemoPickerLivePreview()
    case .datePicker: DemoDatePickerLivePreview()
    case .formRow: DemoFormRowLivePreview()
    case .pullToRefresh: DemoPullToRefreshLivePreview()
    case .navigationBar: DemoNavigationBarLivePreview()
    case .tabBar: DemoTabBarLivePreview()
    case .toolbar: DemoToolbarLivePreview()
    case .fab: DemoFABLivePreview()
    default: EmptyView()
    }
  }
}

private struct DemoSearchFieldLivePreview: View {
  @State private var text = "储物间"

  var body: some View {
    WDSearchField(
      text: $text,
      placeholder: Text(verbatim: "搜索任务或成员"),
      clearAccessibilityLabel: Text(verbatim: "清除搜索内容"),
      cancelLabel: Text(verbatim: "取消")
    )
  }
}

private struct DemoRadioLivePreview: View {
  @State private var selection = "self"

  var body: some View {
    WDRadio(
      selection: $selection,
      label: Text(verbatim: "可见范围"),
      options: [
        .init(id: "self", label: Text(verbatim: "仅自己可见")),
        .init(id: "family", label: Text(verbatim: "共享给全家")),
      ]
    )
  }
}

private struct DemoSliderLivePreview: View {
  @State private var value = 0.62

  var body: some View {
    WDSlider(value: $value, label: Text(verbatim: "完成度"))
  }
}

private struct DemoStepperLivePreview: View {
  @State private var value = 3

  var body: some View {
    WDStepper(value: $value, label: Text(verbatim: "数量"), in: 0...10)
  }
}

private struct DemoChipLivePreview: View {
  @State private var selected = true

  var body: some View {
    HStack(spacing: WDSpacing.s3) {
      WDChip(label: Text(verbatim: "全家共享"))
      WDChip(label: Text(verbatim: "家务"), leadingIcon: .task)
      WDChip(label: Text(verbatim: "已完成"), isSelected: $selected)
    }
  }
}

private struct DemoAvatarStackLivePreview: View {
  private let items: [WDAvatarStackItem] = [
    .init(id: "me", avatar: WDAvatarValue(label: Text(verbatim: "我"))),
    .init(id: "mom", avatar: WDAvatarValue(label: Text(verbatim: "妈"))),
    .init(id: "dad", avatar: WDAvatarValue(label: Text(verbatim: "爸"))),
    .init(id: "sis", avatar: WDAvatarValue(label: Text(verbatim: "妹"))),
    .init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "甲"))),
  ]

  var body: some View {
    WDAvatarStack(items: items, accessibilityLabel: Text(verbatim: "家庭成员 5 人"))
  }
}

private struct DemoSegmentedControlLivePreview: View {
  @State private var selection = "today"

  var body: some View {
    WDSegmentedControl(
      items: [
        .init(id: "today", label: Text(verbatim: "今天")),
        .init(id: "week", label: Text(verbatim: "本周")),
        .init(id: "all", label: Text(verbatim: "全部")),
      ],
      selection: $selection
    )
  }
}

private struct DemoPickerLivePreview: View {
  @State private var selection: String? = "chore"

  private let options: [WDPickerOption] = [
    .init(id: "chore", label: Text(verbatim: "家务")),
    .init(id: "task", label: Text(verbatim: "任务")),
    .init(id: "travel", label: Text(verbatim: "出行")),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      WDPicker(selection: $selection, label: Text(verbatim: "分类"), options: options)
      WDPicker(
        selection: $selection, label: Text(verbatim: "滚轮"), options: options,
        style: .wheel)
    }
  }
}

private struct DemoDatePickerLivePreview: View {
  @State private var date: Date? = Date()

  private var quick: [WDDatePickerQuickOption] {
    [
      .init(id: "today", label: Text(verbatim: "今天"), date: Date()),
      .init(id: "tomorrow", label: Text(verbatim: "明天"), date: Date()),
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      WDDatePicker(date: $date, label: Text(verbatim: "截止日期"), quickOptions: quick)
      WDDatePicker(date: $date, label: Text(verbatim: "提醒时间"), mode: .time)
    }
  }
}

private struct DemoFormRowLivePreview: View {
  @State private var name = "整理储物间"
  @State private var enabled = true

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      WDFormRow(label: Text(verbatim: "任务名称")) {
        WDTextField(
          text: $name, label: Text(verbatim: "任务名称"),
          appearance: .init(placeholder: Text(verbatim: "输入任务名称")))
      }
      WDFormRow(
        label: Text(verbatim: "截止日期"),
        helper: Text(verbatim: "最晚今天 18:00"),
        requiredLabel: Text(verbatim: "必填")
      ) {
        Text(verbatim: "明天").wdFont(WDType.subheadline)
      }
      WDFormRow(label: Text(verbatim: "提醒")) {
        WDSwitch(isOn: $enabled, label: Text(verbatim: "开启提醒"))
      }
    }
  }
}

private struct DemoPullToRefreshLivePreview: View {
  @State private var isRefreshing = false

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(1...5, id: \.self) { row in
          Text(verbatim: "第 \(row) 条动态")
            .wdFont(WDType.body)
            .wdLineBox(WDType.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WDSpacing.s4)
        }
      }
    }
    .frame(minHeight: 220)
    .wdPullToRefresh(
      isRefreshing: $isRefreshing,
      label: Text(verbatim: "刷新")
    ) {
      try? await Task.sleep(for: .milliseconds(300))
    }
  }
}

private struct DemoNavigationBarLivePreview: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      WDNavigationBar(
        title: Text(verbatim: "家庭"),
        backAccessibilityLabel: Text(verbatim: "返回家庭列表"),
        actions: [
          .init(
            id: "edit", icon: .edit, accessibilityLabel: Text(verbatim: "编辑"), action: {})
        ])
      WDNavigationBar(title: Text(verbatim: "任务"), style: .glass)
    }
  }
}

private struct DemoTabBarLivePreview: View {
  @State private var selection = "today"

  var body: some View {
    VStack {
      Spacer()
      WDTabBar(
        items: [
          .init(id: "today", icon: .home, label: Text(verbatim: "今天")),
          .init(
            id: "tasks", icon: .todo, label: Text(verbatim: "任务"),
            badge: WDBadgeValue(count: 3)),
          .init(id: "family", icon: .members, label: Text(verbatim: "家庭")),
        ],
        selection: $selection
      )
    }
    .frame(minHeight: 200)
  }
}

private struct DemoToolbarLivePreview: View {
  @State private var selected = true

  var body: some View {
    WDToolbar(
      items: [
        .init(id: "undo", icon: .undo, accessibilityLabel: Text(verbatim: "撤销"), action: {}),
        .init(id: "redo", icon: .redo, accessibilityLabel: Text(verbatim: "重做"), action: {}),
        .init(
          id: "bold", icon: .edit, accessibilityLabel: Text(verbatim: "加粗"),
          isSelected: selected, action: { selected.toggle() }),
      ],
      accessibilityLabel: Text(verbatim: "编辑工具")
    )
  }
}

private struct DemoFABLivePreview: View {
  var body: some View {
    HStack(alignment: .bottom, spacing: WDSpacing.s5) {
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"))
      WDFAB(
        icon: .add, accessibilityLabel: Text(verbatim: "新建任务"),
        actions: [
          .init(id: "task", icon: .task, label: Text(verbatim: "任务"), action: {}),
          .init(id: "chore", icon: .chore, label: Text(verbatim: "家务"), action: {}),
        ])
    }
    .frame(minHeight: 220, alignment: .bottom)
  }
}
