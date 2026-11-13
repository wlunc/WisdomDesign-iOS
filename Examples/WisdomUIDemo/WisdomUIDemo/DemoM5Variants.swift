import SwiftUI
import WisdomUI

/// M5 十五件的「档位/形态」一览（demo 详情页）。
struct DemoM5VariantsSection: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    switch component.id {
    case .searchField:
      DemoSection("两种形态", subtitle: "标准只在有值时出现清除键；带取消在聚焦时展开取消按钮。") {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          WDSearchField(
            text: .constant("储物间"),
            placeholder: Text(verbatim: "搜索任务或成员"),
            clearAccessibilityLabel: Text(verbatim: "清除搜索内容"))
          WDSearchField(
            text: .constant("任务"),
            placeholder: Text(verbatim: "搜索任务或成员"),
            clearAccessibilityLabel: Text(verbatim: "清除搜索内容"),
            cancelLabel: Text(verbatim: "取消"))
        }
      }
    case .radio:
      DemoSection("标准 / 带描述", subtitle: "互斥、点击已选项不取消；组标签由 label 提供。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDRadio(
            selection: .constant("a"),
            label: Text(verbatim: "可见范围"),
            options: [
              .init(id: "a", label: Text(verbatim: "仅自己可见")),
              .init(id: "b", label: Text(verbatim: "共享给全家")),
            ])
          WDRadio(
            selection: .constant("today"),
            label: Text(verbatim: "提醒时间"),
            options: [
              .init(id: "today", label: Text(verbatim: "今天"), detail: Text(verbatim: "当天 09:00")),
              .init(
                id: "tomorrow", label: Text(verbatim: "明天"), detail: Text(verbatim: "次日 09:00")),
            ])
        }
      }
    case .slider:
      DemoSection("单值 / 带刻度", subtitle: "step 有值时吸附离散档；松手才触发一次回调。") {
        VStack(alignment: .leading, spacing: WDSpacing.s6) {
          WDSlider(value: .constant(0.62), label: Text(verbatim: "完成度"))
          WDSlider(value: .constant(2), label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1)
        }
      }
    case .stepper:
      DemoSection("标准 / 紧凑 / 带单位", subtitle: "到边界禁用对应键；整体是一个可调整控件。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDStepper(value: .constant(3), label: Text(verbatim: "数量"), in: 0...10)
          WDStepper(
            value: .constant(12), label: Text(verbatim: "人数"), in: 0...99, size: .compact)
          WDStepper(
            value: .constant(2), label: Text(verbatim: "时长"), in: 0...24,
            unit: Text(verbatim: "小时"))
        }
      }
    case .chip:
      DemoSection("展示 / 可选 / 可删除", subtitle: "三种语义用三个 init 分离；删除键独立可达。") {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          HStack(spacing: WDSpacing.s3) {
            WDChip(label: Text(verbatim: "全家共享"))
            WDChip(label: Text(verbatim: "家务"), leadingIcon: .task)
            WDChip(label: Text(verbatim: "已完成"), isSelected: .constant(true))
          }
          HStack(spacing: WDSpacing.s3) {
            WDChip(
              label: Text(verbatim: "妈妈"),
              deleteAccessibilityLabel: Text(verbatim: "移除筛选：妈妈"),
              onDelete: {})
            WDChip(label: Text(verbatim: "紧凑"), size: .compact)
          }
        }
      }
    case .avatarStack:
      DemoSection("md / sm / 溢出", subtitle: "最多 4 个 + 溢出计数；重叠 = 直径 30%。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDAvatarStack(items: Self.members, accessibilityLabel: Text(verbatim: "家庭成员 6 人"))
          WDAvatarStack(
            items: Self.members, accessibilityLabel: Text(verbatim: "家庭成员 6 人"), size: .sm)
          WDAvatarStack(
            items: Array(Self.members.prefix(2)), accessibilityLabel: Text(verbatim: "家庭成员 2 人"))
        }
      }
    case .segmentedControl:
      DemoSection("实底 / 玻璃", subtitle: "容器 38、段最小 56；指示块弹簧滑动。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDSegmentedControl(
            items: Self.segments, selection: .constant("week"), style: .solid)
          WDSegmentedControl(
            items: Self.segments, selection: .constant("today"), style: .glass)
        }
      }
    case .picker:
      DemoSection("菜单 / 滚轮", subtitle: "触发入口 44；未选显示占位符。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDPicker(
            selection: .constant("chore"), label: Text(verbatim: "分类"),
            options: Self.pickerOptions)
          WDPicker(
            selection: .constant(nil), label: Text(verbatim: "频率"),
            options: Self.pickerOptions, placeholder: Text(verbatim: "请选择"), style: .wheel)
        }
      }
    case .datePicker:
      DemoSection("日期 / 时间 / 日期 + 时间", subtitle: "日期用自建月历；时间用系统滚轮。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDDatePicker(date: .constant(Date()), label: Text(verbatim: "截止日期"))
          WDDatePicker(date: .constant(Date()), label: Text(verbatim: "提醒时间"), mode: .time)
          WDDatePicker(date: .constant(Date()), label: Text(verbatim: "预约"), mode: .dateAndTime)
        }
      }
    case .formRow:
      DemoSection("左右 / 上下", subtitle: "AX 字号下横向会自动降级为上下。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDFormRow(label: Text(verbatim: "截止日期")) {
            Text(verbatim: "明天").wdFont(WDType.subheadline)
          }
          WDFormRow(label: Text(verbatim: "任务名称"), layout: .vertical) {
            Text(verbatim: "整理储物间").wdFont(WDType.subheadline)
          }
        }
      }
    case .pullToRefresh:
      DemoSection("系统刷新载体", subtitle: "在列表上下拉即可触发；进行中不会重复触发。") {
        Text(verbatim: "在「实时预览」里下拉列表试试。")
          .wdFont(WDType.subheadline)
          .foregroundStyle(colors.textSecondary)
      }
    case .navigationBar:
      DemoSection("内联 / 标准 / 大标题", subtitle: "透明与玻璃两档；返回与右侧动作由调用方给。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDNavigationBar(
            title: Text(verbatim: "家庭"), mode: .inline,
            backAccessibilityLabel: Text(verbatim: "返回家庭列表"))
          WDNavigationBar(
            title: Text(verbatim: "家庭"), style: .glass,
            backAccessibilityLabel: Text(verbatim: "返回家庭列表"),
            actions: [
              .init(id: "edit", icon: .edit, accessibilityLabel: Text(verbatim: "编辑"), action: {})
            ])
          WDNavigationBar(title: Text(verbatim: "本周家务"), mode: .largeTitle)
        }
      }
    case .tabBar:
      DemoSection("3 项 / 带角标", subtitle: "浅色玻璃强档；深色由组件自动改不透明表面。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDTabBar(items: Self.tabItems, selection: .constant("today"))
          WDTabBar(items: Self.tabItems, selection: .constant("tasks"))
            .environment(\.colorScheme, .dark)
        }
      }
    case .toolbar:
      DemoSection("4 项 / 9 项（更多）", subtitle: "超过 7 项收进「更多」；按钮禁用不隐藏整条。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDToolbar(items: Self.toolbarItems(4), accessibilityLabel: Text(verbatim: "编辑工具"))
          WDToolbar(
            items: Self.toolbarItems(9),
            accessibilityLabel: Text(verbatim: "编辑工具"),
            overflowAccessibilityLabel: Text(verbatim: "更多工具"))
        }
      }
    case .fab:
      DemoSection("三档 / 圆角方 / 圆形 / 可展开", subtitle: "小号 40 的热区补到 44。") {
        HStack(alignment: .bottom, spacing: WDSpacing.s5) {
          WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .small)
          WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"))
          WDFAB(
            icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .large,
            shape: .circle)
          WDFAB(
            icon: .add, accessibilityLabel: Text(verbatim: "新建任务"),
            actions: Self.fabActions)
        }
        .frame(minHeight: 220, alignment: .bottom)
      }
    default:
      EmptyView()
    }
  }

  // MARK: - 样本数据

  private static let members: [WDAvatarStackItem] = [
    .init(id: "me", avatar: WDAvatarValue(label: Text(verbatim: "我"))),
    .init(id: "mom", avatar: WDAvatarValue(label: Text(verbatim: "妈"))),
    .init(id: "dad", avatar: WDAvatarValue(label: Text(verbatim: "爸"))),
    .init(id: "sis", avatar: WDAvatarValue(label: Text(verbatim: "妹"))),
    .init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "甲"))),
    .init(id: "b", avatar: WDAvatarValue(label: Text(verbatim: "乙"))),
  ]
  private static let segments = [
    WDSegmentedControlItem(id: "today", label: Text(verbatim: "今天")),
    WDSegmentedControlItem(id: "week", label: Text(verbatim: "本周")),
    WDSegmentedControlItem(id: "all", label: Text(verbatim: "全部")),
  ]
  private static let pickerOptions = [
    WDPickerOption(id: "chore", label: Text(verbatim: "家务")),
    WDPickerOption(id: "task", label: Text(verbatim: "任务")),
    WDPickerOption(id: "travel", label: Text(verbatim: "出行")),
  ]
  private static let tabItems = [
    WDTabBarItem(id: "today", icon: .home, label: Text(verbatim: "今天")),
    WDTabBarItem(
      id: "tasks", icon: .todo, label: Text(verbatim: "任务"), badge: WDBadgeValue(count: 3)),
    WDTabBarItem(id: "family", icon: .members, label: Text(verbatim: "家庭")),
  ]
  private static func toolbarItems(_ count: Int) -> [WDToolbarItem] {
    (1...count).map { index in
      WDToolbarItem(
        id: "\(index)",
        icon: index == 1 ? .undo : (index == 2 ? .redo : .task),
        accessibilityLabel: Text(verbatim: "工具 \(index)"),
        isSelected: index == 3,
        isEnabled: index != count,
        action: {})
    }
  }
  private static let fabActions = [
    WDFABAction(id: "task", icon: .task, label: Text(verbatim: "任务"), action: {}),
    WDFABAction(id: "chore", icon: .chore, label: Text(verbatim: "家务"), action: {}),
  ]
}

/// M5 十五件的「状态」一览（demo 详情页）。
struct DemoM5StatesSection: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    switch component.id {
    case .searchField, .radio, .slider, .stepper, .chip, .avatarStack,
      .segmentedControl, .picker, .datePicker, .formRow,
      .pullToRefresh, .navigationBar, .tabBar, .toolbar, .fab:
      DemoSection("禁用 / 选中", subtitle: "禁用态统一 40% 不透明度；选中态不只靠颜色。") {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          disabledSample
          selectedSample
        }
      }
    default:
      EmptyView()
    }
  }

  @ViewBuilder private var disabledSample: some View {
    switch component.id {
    case .searchField:
      WDSearchField(
        text: .constant(""), placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容")
      ).disabled(true)
    case .radio:
      WDRadio(
        selection: .constant("a"), label: Text(verbatim: "分组"),
        options: [.init(id: "a", label: Text(verbatim: "不可修改"))]
      ).disabled(true)
    case .slider:
      WDSlider(value: .constant(0.8), label: Text(verbatim: "完成度")).disabled(true)
    case .stepper:
      WDStepper(value: .constant(5), label: Text(verbatim: "数量"), in: 0...10).disabled(true)
    case .chip:
      WDChip(label: Text(verbatim: "禁用"), isSelected: .constant(true)).disabled(true)
    case .avatarStack:
      WDAvatarStack(
        items: [.init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "我")))],
        accessibilityLabel: Text(verbatim: "家庭成员 1 人")
      ).disabled(true)
    case .segmentedControl:
      WDSegmentedControl(
        items: [
          .init(id: "a", label: Text(verbatim: "甲")),
          .init(id: "b", label: Text(verbatim: "乙")),
        ],
        selection: .constant("a")
      ).disabled(true)
    case .picker:
      WDPicker(
        selection: .constant("a"), label: Text(verbatim: "分类"),
        options: [.init(id: "a", label: Text(verbatim: "家务"))]
      ).disabled(true)
    case .datePicker:
      WDDatePicker(date: .constant(nil), label: Text(verbatim: "截止日期")).disabled(true)
    case .formRow:
      WDFormRow(label: Text(verbatim: "截止日期")) {
        Text(verbatim: "明天").wdFont(WDType.subheadline)
      }
      .disabled(true)
    case .pullToRefresh:
      Text(verbatim: "刷新由系统载体负责，无独立禁用态。")
        .wdFont(WDType.subheadline)
        .foregroundStyle(colors.textSecondary)
    case .navigationBar:
      WDNavigationBar(title: Text(verbatim: "家庭")).disabled(true)
    case .tabBar:
      WDTabBar(
        items: [
          .init(id: "a", icon: .home, label: Text(verbatim: "今天")),
          .init(id: "b", icon: .todo, label: Text(verbatim: "任务")),
        ],
        selection: .constant("a")
      ).disabled(true)
    case .toolbar:
      WDToolbar(
        items: [
          .init(
            id: "a", icon: .undo, accessibilityLabel: Text(verbatim: "撤销"),
            isEnabled: false, action: {})
        ],
        accessibilityLabel: Text(verbatim: "编辑工具"))
    case .fab:
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务")).disabled(true)
    default:
      EmptyView()
    }
  }

  @ViewBuilder private var selectedSample: some View {
    switch component.id {
    case .segmentedControl:
      WDSegmentedControl(
        items: [
          .init(id: "a", label: Text(verbatim: "今天")),
          .init(id: "b", label: Text(verbatim: "本周")),
        ],
        selection: .constant("b")
      )
    case .tabBar:
      WDTabBar(
        items: [
          .init(id: "a", icon: .home, label: Text(verbatim: "今天")),
          .init(
            id: "b", icon: .todo, label: Text(verbatim: "任务"),
            badge: WDBadgeValue(count: 12)),
        ],
        selection: .constant("b")
      )
    case .toolbar:
      WDToolbar(
        items: [
          .init(
            id: "bold", icon: .edit, accessibilityLabel: Text(verbatim: "加粗"),
            isSelected: true, action: {})
        ],
        accessibilityLabel: Text(verbatim: "编辑工具"))
    case .chip:
      HStack(spacing: WDSpacing.s3) {
        WDChip(label: Text(verbatim: "未选"), isSelected: .constant(false))
        WDChip(label: Text(verbatim: "已选"), isSelected: .constant(true))
      }
    case .radio:
      WDRadio(
        selection: .constant("b"), label: Text(verbatim: "可见范围"),
        options: [
          .init(id: "a", label: Text(verbatim: "仅自己可见")),
          .init(id: "b", label: Text(verbatim: "共享给全家")),
        ])
    default:
      EmptyView()
    }
  }
}
