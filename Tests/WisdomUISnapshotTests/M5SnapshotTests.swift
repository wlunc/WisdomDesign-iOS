import SwiftUI
import Testing

@testable import WisdomUI

/// M5 十五件的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 渲染器按 SPEC §1.6 的显式表：玻璃类（NavigationBar/TabBar/Toolbar）用
/// `UIHostingController` + `drawHierarchy`；TextField/Slider 等 UIKit 接管类同样走 hierarchy；
/// 其余走 `ImageRenderer`。
@MainActor
@Suite("M5 快照", .serialized)
struct M5SnapshotTests {
  static let canvas = CGSize(width: 360, height: 540)

  private func framed<V: View>(_ view: V, values: WDColorValues) -> some View {
    view
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
  }

  private func snap(
    _ name: String, sample: some View, hierarchy: Bool = false, size: CGSize? = nil
  ) {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      let view = framed(sample, values: values)
      if hierarchy {
        SnapshotSupport.verifyHierarchy(
          name: "\(name)-\(state.id)", view: view, state: state,
          size: size ?? Self.canvas)
      } else {
        SnapshotSupport.verify(
          name: "\(name)-\(state.id)", view: view, state: state,
          size: size ?? Self.canvas)
      }
    }
  }

  @Test("WDSearchField：8 态")
  func searchField() {
    snap("searchfield", sample: SearchFieldSample(), hierarchy: true)
  }

  @Test("WDRadio：8 态")
  func radio() {
    snap("radio", sample: RadioSample())
  }

  @Test("WDSlider：8 态")
  func slider() {
    snap("slider", sample: SliderSample(), hierarchy: true)
  }

  @Test("WDStepper：8 态")
  func stepper() {
    snap("stepper", sample: StepperSample())
  }

  @Test("WDChip：8 态")
  func chip() {
    snap("chip", sample: ChipSample())
  }

  @Test("WDAvatarStack：8 态")
  func avatarStack() {
    snap("avatarstack", sample: AvatarStackSample())
  }

  @Test("WDSegmentedControl：8 态")
  func segmentedControl() {
    snap("segmentedcontrol", sample: SegmentedControlSample())
  }

  @Test("WDPicker：8 态")
  func picker() {
    snap("picker", sample: PickerSample())
  }

  @Test("WDDatePicker：8 态")
  func datePicker() {
    snap("datepicker", sample: DatePickerSample())
  }

  @Test("WDFormRow：8 态")
  func formRow() {
    snap("formrow", sample: FormRowSample())
  }

  @Test("WDPullRefresh：8 态")
  func pullRefresh() {
    snap("pullrefresh", sample: PullToRefreshSample())
  }

  @Test("WDNavigationBar：8 态（玻璃类渲染器）")
  func navigationBar() {
    snap("navigationbar", sample: NavigationBarSample(), hierarchy: true)
  }

  @Test("WDTabBar：8 态（玻璃类渲染器）")
  func tabBar() {
    snap("tabbar", sample: TabBarSample(), hierarchy: true)
  }

  @Test("WDToolbar：8 态（玻璃类渲染器）")
  func toolbar() {
    snap("toolbar", sample: ToolbarSample(), hierarchy: true)
  }

  @Test("WDFAB：8 态")
  func fab() {
    snap("fab", sample: FABSample())
  }

  @Test("WDBadge 计数/圆点：8 态")
  func badgeForms() {
    snap("badge-forms", sample: BadgeFormsSample())
  }
}

// MARK: - 样本

private struct SearchFieldSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDSearchField(
        text: .constant("储物间"),
        placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容"))
      WDSearchField(
        text: .constant("任务"),
        placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容"),
        cancelLabel: Text(verbatim: "取消"))
      WDSearchField(
        text: .constant(""), placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容")
      )
      .disabled(true)
    }
  }
}

private struct RadioSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDRadio(
        selection: .constant("self"),
        label: Text(verbatim: "可见范围"),
        options: [
          .init(id: "self", label: Text(verbatim: "仅自己可见")),
          .init(id: "family", label: Text(verbatim: "共享给全家")),
          .init(
            id: "custom", label: Text(verbatim: "指定成员"),
            detail: Text(verbatim: "选择可以查看的成员")),
        ])
      WDRadio(
        selection: .constant("a"), label: Text(verbatim: "禁用"),
        options: [.init(id: "a", label: Text(verbatim: "不可修改"))]
      )
      .disabled(true)
      WDRadio(
        selection: .constant("self"), label: Text(verbatim: "紧凑组"), size: .compact,
        options: [
          .init(id: "self", label: Text(verbatim: "仅自己可见")),
          .init(id: "family", label: Text(verbatim: "共享给全家")),
        ])
    }
  }
}

private struct SliderSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDSlider(value: .constant(0.62), label: Text(verbatim: "完成度"))
      WDSlider(value: .constant(2), label: Text(verbatim: "提醒提前量"), in: 0...4, step: 1)
      WDSlider(value: .constant(0.8), label: Text(verbatim: "禁用"))
        .disabled(true)
    }
  }
}

private struct StepperSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDStepper(value: .constant(3), label: Text(verbatim: "数量"), in: 0...10)
      WDStepper(
        value: .constant(12), label: Text(verbatim: "人数"), in: 0...99, size: .compact,
        unit: Text(verbatim: "人"))
      WDStepper(value: .constant(1), label: Text(verbatim: "下限"), in: 1...10)
      WDStepper(value: .constant(5), label: Text(verbatim: "禁用"), in: 0...10)
        .disabled(true)
    }
  }
}

private struct ChipSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      HStack(spacing: WDSpacing.s3) {
        WDChip(label: Text(verbatim: "全家共享"))
        WDChip(label: Text(verbatim: "家务"), leadingIcon: .task)
      }
      HStack(spacing: WDSpacing.s3) {
        WDChip(label: Text(verbatim: "已完成"), isSelected: .constant(true))
        WDChip(label: Text(verbatim: "待整理"), isSelected: .constant(false))
      }
      HStack(spacing: WDSpacing.s3) {
        WDChip(
          label: Text(verbatim: "妈妈"), deleteAccessibilityLabel: Text(verbatim: "移除筛选"),
          onDelete: {})
        WDChip(label: Text(verbatim: "紧凑"), size: .compact)
        WDChip(label: Text(verbatim: "禁用"), isSelected: .constant(true))
          .disabled(true)
      }
    }
  }
}

private struct AvatarStackSample: View {
  private let six: [WDAvatarStackItem] = [
    .init(id: "me", avatar: WDAvatarValue(label: Text(verbatim: "我"))),
    .init(id: "mom", avatar: WDAvatarValue(label: Text(verbatim: "妈"))),
    .init(id: "dad", avatar: WDAvatarValue(label: Text(verbatim: "爸"))),
    .init(id: "sis", avatar: WDAvatarValue(label: Text(verbatim: "妹"))),
    .init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "甲"))),
    .init(id: "b", avatar: WDAvatarValue(label: Text(verbatim: "乙"))),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDAvatarStack(items: six, accessibilityLabel: Text(verbatim: "家庭成员 6 人"))
      WDAvatarStack(
        items: six, accessibilityLabel: Text(verbatim: "家庭成员 6 人"), size: .sm)
      WDAvatarStack(
        items: Array(six.prefix(2)), accessibilityLabel: Text(verbatim: "家庭成员 2 人"))
    }
  }
}

private struct SegmentedControlSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDSegmentedControl(
        items: [
          .init(id: "today", label: Text(verbatim: "今天")),
          .init(id: "week", label: Text(verbatim: "本周")),
          .init(id: "all", label: Text(verbatim: "全部")),
        ],
        selection: .constant("week"))
      WDSegmentedControl(
        items: [
          .init(id: "a", label: Text(verbatim: "甲")),
          .init(id: "b", label: Text(verbatim: "乙")),
        ],
        selection: .constant("a"),
        style: .glass)
      WDSegmentedControl(
        items: [
          .init(id: "a", label: Text(verbatim: "甲")),
          .init(id: "b", label: Text(verbatim: "乙")),
        ],
        selection: .constant("a")
      )
      .disabled(true)
    }
  }
}

private struct PickerSample: View {
  private let options: [WDPickerOption] = [
    .init(id: "chore", label: Text(verbatim: "家务"), group: Text(verbatim: "家庭")),
    .init(id: "task", label: Text(verbatim: "任务"), group: Text(verbatim: "家庭")),
    .init(id: "travel", label: Text(verbatim: "出行")),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDPicker(selection: .constant("chore"), label: Text(verbatim: "分类"), options: options)
      WDPicker(
        selection: .constant(nil), label: Text(verbatim: "频率"), options: options,
        placeholder: Text(verbatim: "请选择"), style: .wheel)
      WDPicker(selection: .constant(nil), label: Text(verbatim: "禁用"), options: options)
        .disabled(true)
    }
  }
}

private struct DatePickerSample: View {
  /// 固定锚点：`Date()` 会让日历快照随日期漂移（2026-11-14 实测 RTL 两张过期）。
  private let anchor = Date(timeIntervalSince1970: 1_800_000_000)

  private var quick: [WDDatePickerQuickOption] {
    [
      .init(id: "today", label: Text(verbatim: "今天"), date: anchor),
      .init(id: "tomorrow", label: Text(verbatim: "明天"), date: anchor.addingTimeInterval(86_400)),
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDDatePicker(
        date: .constant(anchor), label: Text(verbatim: "截止日期"), quickOptions: quick)
      WDDatePicker(date: .constant(nil), label: Text(verbatim: "提醒时间"), mode: .time)
      WDDatePicker(date: .constant(nil), label: Text(verbatim: "无截止日期"))
        .disabled(true)
      WDDatePicker(
        range: .constant(anchor...anchor.addingTimeInterval(4 * 86_400)),
        label: Text(verbatim: "日期范围"))
      WDDatePicker(
        date: .constant(anchor), label: Text(verbatim: "可清除"),
        showsClearButton: true, clearAccessibilityLabel: Text(verbatim: "清除截止日期"))
    }
    .environment(\.timeZone, TimeZone(secondsFromGMT: 0) ?? .current)
    .environment(\.locale, Locale(identifier: "zh_CN"))
  }
}

private struct FormRowSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDFormRow(label: Text(verbatim: "任务名称")) {
        WDTextField(
          text: .constant("整理储物间"), label: Text(verbatim: "任务名称"),
          appearance: .init(placeholder: Text(verbatim: "输入任务名称")))
      }
      WDFormRow(
        label: Text(verbatim: "截止日期"),
        helper: Text(verbatim: "最晚今天 18:00"),
        requiredLabel: Text(verbatim: "必填")
      ) {
        Text(verbatim: "明天").wdFont(WDType.subheadline)
      }
      WDFormRow(
        label: Text(verbatim: "成员"), error: Text(verbatim: "成员不能为空")
      ) {
        Text(verbatim: "妈妈").wdFont(WDType.subheadline)
      }
      WDFormRow(label: Text(verbatim: "提醒"), layout: .vertical) {
        WDSwitch(isOn: .constant(true), label: Text(verbatim: "开启提醒"))
      }
    }
  }
}

private struct PullToRefreshSample: View {
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(1...6, id: \.self) { row in
          Text(verbatim: "第 \(row) 条动态")
            .wdFont(WDType.body)
            .wdLineBox(WDType.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WDSpacing.s5)
        }
      }
    }
    .frame(minHeight: 320)
    .wdPullRefresh(isRefreshing: .constant(false), label: Text(verbatim: "刷新")) {}
  }
}

private struct NavigationBarSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDNavigationBar(
        title: Text(verbatim: "家庭"),
        backAccessibilityLabel: Text(verbatim: "返回家庭列表"),
        actions: [
          .init(
            id: "edit", icon: .edit, accessibilityLabel: Text(verbatim: "编辑"),
            action: {})
        ])
      WDNavigationBar(title: Text(verbatim: "任务"), style: .glass)
      WDNavigationBar(title: Text(verbatim: "本周家务"), mode: .largeTitle)
    }
  }
}

private struct TabBarSample: View {
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
          .init(id: "me", icon: .profile, label: Text(verbatim: "我的")),
        ],
        selection: .constant("tasks"))
    }
    .frame(minHeight: 200)
  }
}

private struct ToolbarSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDToolbar(
        items: [
          .init(id: "undo", icon: .undo, accessibilityLabel: Text(verbatim: "撤销"), action: {}),
          .init(id: "redo", icon: .redo, accessibilityLabel: Text(verbatim: "重做"), action: {}),
          .init(
            id: "bold", icon: .edit, accessibilityLabel: Text(verbatim: "加粗"),
            isSelected: true, action: {}),
          .init(
            id: "off", icon: .delete, accessibilityLabel: Text(verbatim: "删除"),
            isEnabled: false, action: {}),
        ],
        accessibilityLabel: Text(verbatim: "编辑工具"))
      WDToolbar(
        items: (1...9).map {
          WDToolbarItem(
            id: "\($0)", icon: .task, accessibilityLabel: Text(verbatim: "工具"), action: {})
        },
        accessibilityLabel: Text(verbatim: "编辑工具"),
        overflowAccessibilityLabel: Text(verbatim: "更多工具"))
    }
  }
}

private struct FABSample: View {
  var body: some View {
    HStack(alignment: .bottom, spacing: WDSpacing.s5) {
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .small)
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"))
      WDFAB(
        icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .large,
        shape: .circle)
      WDFAB(
        icon: .add, accessibilityLabel: Text(verbatim: "新建任务"),
        actions: [
          .init(id: "task", icon: .task, label: Text(verbatim: "任务"), action: {}),
          .init(id: "chore", icon: .chore, label: Text(verbatim: "家务"), action: {}),
        ])
    }
    .frame(minHeight: 240, alignment: .bottom)
  }
}

private struct BadgeFormsSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      HStack(spacing: WDSpacing.s3) {
        WDBadge(value: WDBadgeValue(count: 3))
        WDBadge(value: WDBadgeValue(count: 12))
        WDBadge(value: WDBadgeValue(count: 120))
        WDBadge(value: .dot)
      }
      HStack(spacing: WDSpacing.s3) {
        WDBadge(label: Text(verbatim: "共享"))
        WDBadge(label: Text(verbatim: "已逾期"))
        WDBadge(value: WDBadgeValue(count: 0))
      }
    }
  }
}
