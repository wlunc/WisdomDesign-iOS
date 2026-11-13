import Foundation
import SwiftUI
import Testing

@testable import WisdomUI

/// M5 十五件的渲染耗时（只报不拦；口径 = ImageRenderer 一次 PNG 的墙钟时间）。
@MainActor
@Suite("M5 性能（只报）")
struct M5PerfTests {
  private static let canvas = CGSize(width: 360, height: 640)

  @Test("M5 十五件渲染耗时")
  func renderTimes() {
    let samples: [(String, AnyView)] = [
      ("WDSearchField", AnyView(PerfSearchField())),
      ("WDRadio", AnyView(PerfRadio())),
      ("WDSlider", AnyView(PerfSlider())),
      ("WDStepper", AnyView(PerfStepper())),
      ("WDChip", AnyView(PerfChip())),
      ("WDAvatarStack", AnyView(PerfAvatarStack())),
      ("WDSegmentedControl", AnyView(PerfSegmentedControl())),
      ("WDPicker", AnyView(PerfPicker())),
      ("WDDatePicker", AnyView(PerfDatePicker())),
      ("WDFormRow", AnyView(PerfFormRow())),
      ("WDPullToRefresh", AnyView(PerfPullToRefresh())),
      ("WDNavigationBar", AnyView(PerfNavigationBar())),
      ("WDTabBar", AnyView(PerfTabBar())),
      ("WDToolbar", AnyView(PerfToolbar())),
      ("WDFAB", AnyView(PerfFAB())),
    ]
    for (name, view) in samples {
      var durations: [Double] = []
      for index in 0..<15 {
        let start = Date()
        let renderer = ImageRenderer(
          content: view.frame(width: Self.canvas.width, alignment: .topLeading))
        renderer.scale = 1
        _ = renderer.uiImage
        let elapsed = Date().timeIntervalSince(start) * 1000
        if index >= 3 { durations.append(elapsed) }
      }
      let avg = durations.reduce(0, +) / Double(durations.count)
      let minValue = durations.min() ?? 0
      print(
        String(format: "M5PERF %@ avg=%.2f min=%.2f n=%d", name, avg, minValue, durations.count))
    }
  }
}

private struct PerfSearchField: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDSearchField(
        text: .constant("储物间"), placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容"))
      WDSearchField(
        text: .constant("任务"), placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容"), cancelLabel: Text(verbatim: "取消"))
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfRadio: View {
  var body: some View {
    WDRadio(
      selection: .constant("self"), label: Text(verbatim: "可见范围"),
      options: [
        .init(id: "self", label: Text(verbatim: "仅自己可见")),
        .init(id: "family", label: Text(verbatim: "共享给全家")),
      ]
    )
    .padding(WDSpacing.s5)
  }
}

private struct PerfSlider: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDSlider(value: .constant(0.62), label: Text(verbatim: "完成度"))
      WDSlider(value: .constant(2), label: Text(verbatim: "提前量"), in: 0...4, step: 1)
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfStepper: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDStepper(value: .constant(3), label: Text(verbatim: "数量"), in: 0...10)
      WDStepper(value: .constant(12), label: Text(verbatim: "人数"), in: 0...99, size: .compact)
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfChip: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      HStack(spacing: WDSpacing.s3) {
        WDChip(label: Text(verbatim: "全家共享"))
        WDChip(label: Text(verbatim: "家务"), leadingIcon: .task)
        WDChip(label: Text(verbatim: "已完成"), isSelected: .constant(true))
      }
      HStack(spacing: WDSpacing.s3) {
        WDChip(
          label: Text(verbatim: "妈妈"), deleteAccessibilityLabel: Text(verbatim: "移除筛选"),
          onDelete: {})
        WDChip(label: Text(verbatim: "紧凑"), size: .compact)
      }
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfAvatarStack: View {
  private let items: [WDAvatarStackItem] = [
    .init(id: "me", avatar: WDAvatarValue(label: Text(verbatim: "我"))),
    .init(id: "mom", avatar: WDAvatarValue(label: Text(verbatim: "妈"))),
    .init(id: "dad", avatar: WDAvatarValue(label: Text(verbatim: "爸"))),
    .init(id: "sis", avatar: WDAvatarValue(label: Text(verbatim: "妹"))),
    .init(id: "a", avatar: WDAvatarValue(label: Text(verbatim: "甲"))),
  ]

  var body: some View {
    WDAvatarStack(items: items, accessibilityLabel: Text(verbatim: "家庭成员 5 人"))
      .padding(WDSpacing.s5)
  }
}

private struct PerfSegmentedControl: View {
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
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfPicker: View {
  private let options: [WDPickerOption] = [
    .init(id: "a", label: Text(verbatim: "家务")),
    .init(id: "b", label: Text(verbatim: "任务")),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDPicker(selection: .constant("a"), label: Text(verbatim: "分类"), options: options)
      WDPicker(selection: .constant(nil), label: Text(verbatim: "频率"), options: options)
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfDatePicker: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDDatePicker(date: .constant(Date()), label: Text(verbatim: "截止日期"))
      WDDatePicker(date: .constant(Date()), label: Text(verbatim: "提醒时间"), mode: .time)
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfFormRow: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDFormRow(label: Text(verbatim: "截止日期"), helper: Text(verbatim: "最晚今天 18:00")) {
        Text(verbatim: "明天").wdFont(WDType.subheadline)
      }
      WDFormRow(label: Text(verbatim: "成员"), error: Text(verbatim: "成员不能为空")) {
        Text(verbatim: "妈妈").wdFont(WDType.subheadline)
      }
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfPullToRefresh: View {
  var body: some View {
    ScrollView {
      ForEach(1...5, id: \.self) { row in
        Text(verbatim: "第 \(row) 条动态")
          .wdFont(WDType.body)
          .wdLineBox(WDType.body)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(WDSpacing.s4)
      }
    }
    .frame(minHeight: 240)
    .wdPullToRefresh(isRefreshing: .constant(false), label: Text(verbatim: "刷新")) {}
  }
}

private struct PerfNavigationBar: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s5) {
      WDNavigationBar(title: Text(verbatim: "家庭"), style: .glass)
      WDNavigationBar(title: Text(verbatim: "本周家务"), mode: .largeTitle)
    }
  }
}

private struct PerfTabBar: View {
  var body: some View {
    WDTabBar(
      items: [
        .init(id: "today", icon: .home, label: Text(verbatim: "今天")),
        .init(
          id: "tasks", icon: .todo, label: Text(verbatim: "任务"),
          badge: WDBadgeValue(count: 3)),
        .init(id: "family", icon: .members, label: Text(verbatim: "家庭")),
      ],
      selection: .constant("tasks")
    )
    .padding(WDSpacing.s5)
  }
}

private struct PerfToolbar: View {
  var body: some View {
    WDToolbar(
      items: [
        .init(id: "undo", icon: .undo, accessibilityLabel: Text(verbatim: "撤销"), action: {}),
        .init(id: "redo", icon: .redo, accessibilityLabel: Text(verbatim: "重做"), action: {}),
        .init(
          id: "bold", icon: .edit, accessibilityLabel: Text(verbatim: "加粗"), isSelected: true,
          action: {}),
      ],
      accessibilityLabel: Text(verbatim: "编辑工具")
    )
    .padding(WDSpacing.s5)
  }
}

private struct PerfFAB: View {
  var body: some View {
    HStack(spacing: WDSpacing.s5) {
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"))
      WDFAB(
        icon: .add, accessibilityLabel: Text(verbatim: "新建任务"),
        actions: [
          .init(id: "task", icon: .task, label: Text(verbatim: "任务"), action: {}),
          .init(id: "chore", icon: .chore, label: Text(verbatim: "家务"), action: {}),
        ])
    }
    .padding(WDSpacing.s5)
  }
}
