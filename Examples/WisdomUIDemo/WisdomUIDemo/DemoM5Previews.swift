import SwiftUI
import WisdomUI

/// M5 十五件的 demo 实时预览（每个组件一小块可交互样例）。
///
/// 目的：让 demo 的无障碍审计与手动走查覆盖 M5 的契约面；设置面板切换的枚举
/// （尺寸 / 形态 / 模式）会立即反映到这里的预览。
struct DemoM5Preview: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  var body: some View {
    switch component.id {
    case .searchField: DemoSearchFieldLivePreview(settings: settings)
    case .radio: DemoRadioLivePreview()
    case .slider: DemoSliderLivePreview(settings: settings)
    case .stepper: DemoStepperLivePreview(settings: settings)
    case .chip: DemoChipLivePreview(settings: settings)
    case .avatarStack: DemoAvatarStackLivePreview(settings: settings)
    case .segmentedControl: DemoSegmentedControlLivePreview(settings: settings)
    case .picker: DemoPickerLivePreview(settings: settings)
    case .datePicker: DemoDatePickerLivePreview(settings: settings)
    case .formRow: DemoFormRowLivePreview(settings: settings)
    case .pullToRefresh: DemoPullToRefreshLivePreview()
    case .navigationBar: DemoNavigationBarLivePreview(settings: settings)
    case .tabBar: DemoTabBarLivePreview(settings: settings)
    case .toolbar: DemoToolbarLivePreview(settings: settings)
    case .fab: DemoFABLivePreview(settings: settings)
    default: EmptyView()
    }
  }
}

private struct DemoSearchFieldLivePreview: View {
  let settings: DemoComponentSettings
  @State private var text = "储物间"

  var body: some View {
    if settings.searchFieldShowsCancel {
      WDSearchField(
        text: $text,
        placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容"),
        cancelLabel: Text(verbatim: "取消")
      )
    } else {
      WDSearchField(
        text: $text,
        placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容")
      )
    }
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
  let settings: DemoComponentSettings
  @State private var continuous = 0.62
  @State private var discrete = 2.0

  var body: some View {
    if settings.sliderUsesStep {
      WDSlider(
        value: $discrete, label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1)
    } else {
      WDSlider(value: $continuous, label: Text(verbatim: "完成度"))
    }
  }
}

private struct DemoStepperLivePreview: View {
  let settings: DemoComponentSettings
  @State private var value = 3

  var body: some View {
    WDStepper(
      value: $value, label: Text(verbatim: "数量"), in: 0...10, size: settings.stepperSize)
  }
}

private struct DemoChipLivePreview: View {
  let settings: DemoComponentSettings
  @State private var selected = true

  var body: some View {
    HStack(spacing: WDSpacing.s3) {
      WDChip(label: Text(verbatim: "全家共享"), size: settings.chipSize)
      WDChip(label: Text(verbatim: "家务"), leadingIcon: .task, size: settings.chipSize)
      WDChip(label: Text(verbatim: "已完成"), isSelected: $selected, size: settings.chipSize)
    }
  }
}

private struct DemoAvatarStackLivePreview: View {
  let settings: DemoComponentSettings
  private let items: [WDAvatarStackItem] = [
    .init(id: "me", avatar: WDAvatarValue(label: Text(verbatim: "我"))),
    .init(id: "mom", avatar: WDAvatarValue(label: Text(verbatim: "妈"))),
    .init(id: "dad", avatar: WDAvatarValue(label: Text(verbatim: "爸"))),
    .init(id: "sis", avatar: WDAvatarValue(label: Text(verbatim: "妹"))),
    .init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "甲"))),
  ]

  var body: some View {
    WDAvatarStack(
      items: items,
      accessibilityLabel: Text(verbatim: "家庭成员 5 人"),
      size: settings.avatarStackSize
    )
  }
}

private struct DemoSegmentedControlLivePreview: View {
  let settings: DemoComponentSettings
  @State private var selection = "today"

  var body: some View {
    WDSegmentedControl(
      items: [
        .init(id: "today", label: Text(verbatim: "今天")),
        .init(id: "week", label: Text(verbatim: "本周")),
        .init(id: "all", label: Text(verbatim: "全部")),
      ],
      selection: $selection,
      style: settings.segmentStyle
    )
  }
}

private struct DemoPickerLivePreview: View {
  let settings: DemoComponentSettings
  @State private var selection: String? = "chore"

  private let options: [WDPickerOption] = [
    .init(id: "chore", label: Text(verbatim: "家务")),
    .init(id: "task", label: Text(verbatim: "任务")),
    .init(id: "travel", label: Text(verbatim: "出行")),
  ]

  var body: some View {
    WDPicker(
      selection: $selection,
      label: Text(verbatim: "分类"),
      options: options,
      placeholder: Text(verbatim: "请选择"),
      style: settings.pickerStyle
    )
  }
}

private struct DemoDatePickerLivePreview: View {
  let settings: DemoComponentSettings
  @State private var date: Date? = Date()

  private var quick: [WDDatePickerQuickOption] {
    [
      .init(id: "today", label: Text(verbatim: "今天"), date: Date()),
      .init(id: "tomorrow", label: Text(verbatim: "明天"), date: Date()),
    ]
  }

  var body: some View {
    WDDatePicker(
      date: $date,
      label: Text(verbatim: settings.datePickerMode == .time ? "提醒时间" : "截止日期"),
      mode: settings.datePickerMode,
      quickOptions: settings.datePickerMode == .date ? quick : []
    )
  }
}

private struct DemoFormRowLivePreview: View {
  let settings: DemoComponentSettings
  @State private var name = "整理储物间"
  @State private var enabled = true

  var body: some View {
    WDFormRow(
      label: Text(verbatim: "任务名称"),
      layout: settings.formRowLayout
    ) {
      WDTextField(
        text: $name, label: Text(verbatim: "任务名称"),
        appearance: .init(placeholder: Text(verbatim: "输入任务名称")))
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
  let settings: DemoComponentSettings

  var body: some View {
    WDNavigationBar(
      title: Text(verbatim: "家庭"),
      mode: settings.navigationBarMode,
      style: settings.navigationBarStyle,
      backAccessibilityLabel: Text(verbatim: "返回家庭列表"),
      actions: [
        .init(id: "edit", icon: .edit, accessibilityLabel: Text(verbatim: "编辑"), action: {})
      ]
    )
  }
}

private struct DemoTabBarLivePreview: View {
  let settings: DemoComponentSettings
  @State private var selection = "today"

  var body: some View {
    VStack {
      Spacer()
      WDTabBar(
        items: [
          .init(id: "today", icon: .home, label: Text(verbatim: "今天")),
          .init(
            id: "tasks", icon: .todo, label: Text(verbatim: "任务"),
            badge: settings.tabBarShowsBadge ? WDBadgeValue(count: 3) : nil),
          .init(id: "family", icon: .members, label: Text(verbatim: "家庭")),
        ],
        selection: $selection
      )
    }
    .frame(minHeight: 200)
  }
}

private struct DemoToolbarLivePreview: View {
  let settings: DemoComponentSettings
  @State private var selected = true

  private var items: [WDToolbarItem] {
    let count = settings.toolbarShowsOverflow ? 9 : 4
    return (1...count).map { index in
      WDToolbarItem(
        id: "\(index)",
        icon: index == 1 ? .undo : (index == 2 ? .redo : .edit),
        accessibilityLabel: Text(verbatim: "工具 \(index)"),
        isSelected: index == 3 && selected,
        isEnabled: index != count,
        action: { if index == 3 { selected.toggle() } })
    }
  }

  var body: some View {
    WDToolbar(
      items: items,
      accessibilityLabel: Text(verbatim: "编辑工具"),
      overflowAccessibilityLabel: settings.toolbarShowsOverflow ? Text(verbatim: "更多工具") : nil
    )
  }
}

private struct DemoFABLivePreview: View {
  let settings: DemoComponentSettings

  var body: some View {
    HStack(alignment: .bottom, spacing: WDSpacing.s5) {
      WDFAB(
        icon: .add,
        accessibilityLabel: Text(verbatim: "新建任务"),
        size: settings.fabSize,
        shape: settings.fabShape,
        actions: settings.fabExpandable
          ? [
            .init(id: "task", icon: .task, label: Text(verbatim: "任务"), action: {}),
            .init(id: "chore", icon: .chore, label: Text(verbatim: "家务"), action: {}),
          ]
          : []
      )
    }
    .frame(minHeight: 220, alignment: .bottom)
  }
}
