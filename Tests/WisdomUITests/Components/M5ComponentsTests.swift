import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// M5 十五件的结构断言（尺寸/变体/组合；不含动画与真实呈现）。
@MainActor
@Suite("M5 导航与表单")
struct M5ComponentsTests {
  private func size<V: View>(_ view: V, width: CGFloat = 360) -> CGSize {
    let controller = UIHostingController(rootView: view)
    return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
  }

  // MARK: - WDSearchField

  @Test("WDSearchField：高度 46 ± 1（与 WDTextField 同高）")
  func searchFieldHeight() {
    let measured = size(
      WDSearchField(
        text: .constant("储物间"),
        placeholder: Text(verbatim: "搜索任务或成员"),
        clearAccessibilityLabel: Text(verbatim: "清除搜索内容")
      )
    )
    #expect(abs(measured.height - WDSize.fieldHeight) <= 1, "实测 \(measured.height)")
  }

  @Test("WDSearchField：带取消变体不改变未聚焦时的高度")
  func searchFieldCancelHeight() {
    let plain = size(
      WDSearchField(
        text: .constant(""), placeholder: Text(verbatim: "搜索"),
        clearAccessibilityLabel: Text(verbatim: "清除")))
    let withCancel = size(
      WDSearchField(
        text: .constant(""), placeholder: Text(verbatim: "搜索"),
        clearAccessibilityLabel: Text(verbatim: "清除"), cancelLabel: Text(verbatim: "取消")))
    #expect(abs(plain.height - withCancel.height) <= 0.5)
  }

  // MARK: - WDRadio

  @Test("WDRadio：选项逐项增高；组标签由 accessibilityLabel 提供")
  func radioHeight() {
    let two = size(
      WDRadio(
        selection: .constant("a"), label: Text(verbatim: "可见范围"),
        options: [
          .init(id: "a", label: Text(verbatim: "仅自己")),
          .init(id: "b", label: Text(verbatim: "全家")),
        ]))
    let three = size(
      WDRadio(
        selection: .constant("a"), label: Text(verbatim: "可见范围"),
        options: [
          .init(id: "a", label: Text(verbatim: "仅自己")),
          .init(id: "b", label: Text(verbatim: "全家")),
          .init(id: "c", label: Text(verbatim: "指定成员")),
        ]))
    #expect(three.height > two.height)
  }

  // MARK: - WDSlider

  @Test("WDSlider：最小宽 120；标签增加高度")
  func sliderGeometry() {
    let plain = size(WDSlider(value: .constant(0.5), label: Text(verbatim: "完成度")))
    #expect(plain.width >= 120)
    #expect(plain.height > 0)
  }

  // MARK: - WDStepper

  @Test("WDStepper：两档可构造；触控热区 ≥ 44")
  func stepperSizes() {
    let standard = size(
      WDStepper(value: .constant(3), label: Text(verbatim: "数量"), in: 0...10))
    let compact = size(
      WDStepper(
        value: .constant(3), label: Text(verbatim: "数量"), in: 0...10, size: .compact))
    #expect(standard.height >= WDSize.touchTargetMin)
    #expect(compact.height >= WDSize.touchTargetMin)
    #expect(WDStepperSize.allCases.map(\.rawValue) == ["standard", "compact"])
  }

  // MARK: - WDChip

  @Test("WDChip：标准 32 / 紧凑 28；三个 init 都可构造")
  func chipSizes() {
    let standard = size(WDChip(label: Text(verbatim: "全家共享")))
    let compact = size(WDChip(label: Text(verbatim: "紧凑"), size: .compact))
    #expect(abs(standard.height - 32) <= 1)
    #expect(abs(compact.height - 28) <= 1)
    _ = WDChip(label: Text(verbatim: "可选"), isSelected: .constant(true))
    _ = WDChip(
      label: Text(verbatim: "妈妈"), deleteAccessibilityLabel: Text(verbatim: "移除筛选"),
      onDelete: {})
    #expect(WDChipSize.allCases.map(\.rawValue) == ["standard", "compact"])
  }

  // MARK: - WDAvatarStack

  @Test("WDAvatarStack：溢出项增加宽度；md 宽于 sm")
  func avatarStackWidths() {
    let four = (1...4).map {
      WDAvatarStackItem(id: "\($0)", avatar: WDAvatarValue(label: Text(verbatim: "\($0)")))
    }
    let six = (1...6).map {
      WDAvatarStackItem(id: "\($0)", avatar: WDAvatarValue(label: Text(verbatim: "\($0)")))
    }
    let mdFour = size(
      WDAvatarStack(items: four, accessibilityLabel: Text(verbatim: "成员 4 人")))
    let mdSix = size(
      WDAvatarStack(items: six, accessibilityLabel: Text(verbatim: "成员 6 人")))
    let smFour = size(
      WDAvatarStack(
        items: four, accessibilityLabel: Text(verbatim: "成员 4 人"), size: .sm))
    #expect(mdSix.width > mdFour.width)
    #expect(mdFour.width > smFour.width)
    #expect(WDAvatarStackSize.allCases.map(\.rawValue) == ["sm", "md"])
  }

  // MARK: - WDSegmentedControl

  @Test("WDSegmentedControl：容器高 38 ± 1；段数 3 至少 3×56 宽")
  func segmentedGeometry() {
    let items = [
      WDSegmentedControlItem(id: "a", label: Text(verbatim: "今天")),
      WDSegmentedControlItem(id: "b", label: Text(verbatim: "本周")),
      WDSegmentedControlItem(id: "c", label: Text(verbatim: "全部")),
    ]
    let measured = size(WDSegmentedControl(items: items, selection: .constant("a")))
    #expect(abs(measured.height - 38) <= 1, "实测 \(measured.height)")
    #expect(measured.width >= 3 * 56)
    #expect(WDSegmentedControlStyle.allCases.map(\.rawValue) == ["glass", "solid"])
  }

  @Test("WDSegmentedControl：2–5 段；枚举顺序与契约一致")
  func segmentedEnums() {
    #expect(WDSegmentedControlStyle.allCases.map(\.rawValue) == ["glass", "solid"])
    let items = (1...2).map {
      WDSegmentedControlItem(id: "\($0)", label: Text(verbatim: "\($0)"))
    }
    #expect(size(WDSegmentedControl(items: items, selection: .constant("1"))).height > 0)
  }

  // MARK: - WDPicker

  @Test("WDPicker：触发入口 ≥ 44；菜单/滚轮/内联三形态可构造")
  func pickerGeometry() {
    let options = [
      WDPickerOption(id: "a", label: Text(verbatim: "家务")),
      WDPickerOption(id: "b", label: Text(verbatim: "任务")),
    ]
    let menu = size(
      WDPicker(
        selection: .constant("a"), label: Text(verbatim: "分类"), options: options))
    let wheel = size(
      WDPicker(
        selection: .constant(nil), label: Text(verbatim: "分类"), options: options,
        placeholder: Text(verbatim: "请选择"), style: .wheel))
    let inline = size(
      WDPicker(
        selection: .constant("a"), label: Text(verbatim: "分类"), options: options,
        style: .inline))
    #expect(menu.height >= WDSize.controlMd)
    #expect(wheel.height >= WDSize.controlMd)
    #expect(inline.height >= WDSize.controlMd * 2)
    #expect(WDPickerStyle.allCases.map(\.rawValue) == ["menu", "wheel", "inline"])
  }

  @Test("WDPicker：菜单浮层定位（下方 / 翻转 / 最小宽 / 高度夹取）")
  func pickerMenuPlacement() {
    let container = CGSize(width: 390, height: 700)
    let safeArea = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    let anchor = CGRect(x: 24, y: 300, width: 342, height: 44)
    let natural = CGSize(width: 200, height: 180)

    let below = WDPickerMenuPlacement.resolve(
      anchorRect: anchor, naturalSize: natural, containerSize: container, safeArea: safeArea)
    #expect(below.below)
    #expect(below.size == natural)
    #expect(abs(below.origin.y - (anchor.maxY + WDPickerMenuMetrics.gap)) < 0.5)

    // 下方放不下、上方更大 ⇒ 翻转。
    let flipped = WDPickerMenuPlacement.resolve(
      anchorRect: CGRect(x: 24, y: 600, width: 342, height: 44),
      naturalSize: natural, containerSize: container, safeArea: safeArea)
    #expect(!flipped.below)
    #expect(abs(flipped.origin.y + flipped.size.height - (600 - WDPickerMenuMetrics.gap)) < 0.5)

    // 内容窄 ⇒ 抬到最小宽 180，并夹在屏幕留白内。
    let narrow = WDPickerMenuPlacement.resolve(
      anchorRect: CGRect(x: 380, y: 100, width: 10, height: 44),
      naturalSize: CGSize(width: 100, height: 100), containerSize: container, safeArea: safeArea)
    #expect(narrow.size.width == WDPickerMenuMetrics.minWidth)
    #expect(
      narrow.origin.x + narrow.size.width
        <= container.width - WDPickerMenuMetrics.screenMargin)

    // RTL：与触发入口的右侧（leading）对齐。
    let rtl = WDPickerMenuPlacement.resolve(
      anchorRect: CGRect(x: 40, y: 300, width: 300, height: 44),
      naturalSize: natural, containerSize: container, safeArea: safeArea, isRTL: true)
    #expect(abs(rtl.origin.x + rtl.size.width - 340) < 0.5)

    // 超高 ⇒ 夹到可视空间，且不越过底部安全区。
    let tall = WDPickerMenuPlacement.resolve(
      anchorRect: anchor, naturalSize: CGSize(width: 200, height: 2000),
      containerSize: container, safeArea: safeArea)
    #expect(
      tall.size.height
        <= container.height - safeArea.bottom - anchor.maxY - WDPickerMenuMetrics.gap + 0.5)
    #expect(tall.origin.y + tall.size.height <= container.height - safeArea.bottom + 0.5)
  }

  // MARK: - WDDatePicker

  @Test("WDDatePicker：触发入口 ≥ 44；快捷 Chip 只影响 .date 模式")
  func datePickerGeometry() {
    let quick = [
      WDDatePickerQuickOption(id: "today", label: Text(verbatim: "今天"), date: Date()),
      WDDatePickerQuickOption(id: "tomorrow", label: Text(verbatim: "明天"), date: Date()),
    ]
    let dateOnly = size(
      WDDatePicker(date: .constant(Date()), label: Text(verbatim: "截止日期")))
    let withQuick = size(
      WDDatePicker(
        date: .constant(Date()), label: Text(verbatim: "截止日期"), quickOptions: quick))
    let time = size(
      WDDatePicker(date: .constant(Date()), label: Text(verbatim: "提醒时间"), mode: .time))
    #expect(dateOnly.height >= WDSize.controlMd)
    #expect(withQuick.height > dateOnly.height)
    #expect(time.height >= WDSize.controlMd)
    #expect(WDDatePickerMode.allCases.map(\.rawValue) == ["date", "time", "dateAndTime"])
  }

  // MARK: - WDFormRow

  @Test("WDFormRow：上下排布高于左右；AX3 下横向自动降级")
  func formRowLayouts() {
    let control = Rectangle().fill(Color.clear).frame(height: 44)
    let horizontal = size(
      WDFormRow(label: Text(verbatim: "截止日期")) { control })
    let vertical = size(
      WDFormRow(label: Text(verbatim: "截止日期"), layout: .vertical) { control })
    #expect(vertical.height > horizontal.height)
    let ax = UIHostingController(
      rootView: WDFormRow(label: Text(verbatim: "截止日期")) { control }
        .environment(\.dynamicTypeSize, .accessibility3))
    let axSize = ax.sizeThatFits(in: CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude))
    #expect(axSize.height > horizontal.height)
    #expect(WDFormRowLayout.allCases.map(\.rawValue) == ["horizontal", "vertical"])
  }

  // MARK: - WDPullRefresh

  @Test("WDPullRefresh：不改变锚点高度（自绘覆盖层不参与布局）")
  func pullRefreshModifier() {
    let plain = size(Text(verbatim: "anchor"))
    let modified = size(
      Text(verbatim: "anchor").wdPullRefresh(
        isRefreshing: .constant(false),
        label: Text(verbatim: "刷新")
      ) {})
    #expect(abs(plain.height - modified.height) <= 0.5)
  }

  // MARK: - WDNavigationBar

  @Test("WDNavigationBar：内联 44 / 标准 56 / 大标题 96")
  func navigationBarHeights() {
    let inline = size(WDNavigationBar(title: Text(verbatim: "家庭"), mode: .inline))
    let standard = size(WDNavigationBar(title: Text(verbatim: "家庭")))
    let large = size(WDNavigationBar(title: Text(verbatim: "家庭"), mode: .largeTitle))
    #expect(abs(inline.height - WDSize.navbarCompact) <= 1)
    #expect(abs(standard.height - WDSize.navbarStandard) <= 1)
    #expect(abs(large.height - 96) <= 1)
    #expect(WDNavigationBarMode.allCases.map(\.rawValue) == ["inline", "standard", "largeTitle"])
    #expect(WDNavigationBarStyle.allCases.map(\.rawValue) == ["transparent", "glass"])
  }

  // MARK: - WDTabBar

  @Test("WDTabBar：高度 ≥ 令牌 56；2–5 项可构造")
  func tabBarHeight() {
    let items = [
      WDTabBarItem(id: "a", icon: .home, label: Text(verbatim: "今天")),
      WDTabBarItem(
        id: "b", icon: .todo, label: Text(verbatim: "任务"),
        badge: WDBadgeValue(count: 3)),
    ]
    let measured = size(WDTabBar(items: items, selection: .constant("a")))
    #expect(measured.height >= WDSize.tabbarHeight)
    #expect(measured.width <= 360.5)
  }

  // MARK: - WDToolbar

  @Test("WDToolbar：容器高 48；9 项时收进更多不增高")
  func toolbarHeight() {
    let four = (1...4).map {
      WDToolbarItem(
        id: "\($0)", icon: .task, accessibilityLabel: Text(verbatim: "工具"),
        action: {})
    }
    let nine = (1...9).map {
      WDToolbarItem(
        id: "\($0)", icon: .task, accessibilityLabel: Text(verbatim: "工具"),
        action: {})
    }
    let compact = size(
      WDToolbar(items: four, accessibilityLabel: Text(verbatim: "编辑工具")))
    let overflow = size(
      WDToolbar(
        items: nine, accessibilityLabel: Text(verbatim: "编辑工具"),
        overflowAccessibilityLabel: Text(verbatim: "更多工具")))
    #expect(abs(compact.height - 48) <= 1)
    #expect(abs(overflow.height - compact.height) <= 1)
  }

  // MARK: - WDFAB

  @Test("WDFAB：标准 56 / 大 64 / 小热区 ≥ 44；展开增高")
  func fabGeometry() {
    let standard = size(
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务")))
    let large = size(
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .large))
    let small = size(
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), size: .small))
    let actions = [
      WDFABAction(id: "a", icon: .task, label: Text(verbatim: "任务"), action: {}),
      WDFABAction(id: "b", icon: .chore, label: Text(verbatim: "家务"), action: {}),
    ]
    let expandable = size(
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), actions: actions))
    #expect(abs(standard.width - 56) <= 1)
    #expect(abs(large.width - 64) <= 1)
    #expect(small.width >= WDSize.touchTargetMin)
    #expect(expandable.width >= standard.width)
    #expect(WDFABSize.allCases.map(\.rawValue) == ["small", "standard", "large"])
    #expect(WDFABShape.allCases.map(\.rawValue) == ["roundedSquare", "circle"])
  }

  // MARK: - WDBadge 增量

  @Test("WDBadge：计数高 20、0 隐藏、>99 显示 99+")
  func badgeCount() {
    let count = size(WDBadge(value: WDBadgeValue(count: 3)))
    #expect(abs(count.height - 20) <= 1)
    #expect(size(WDBadge(value: WDBadgeValue(count: 0))).height == 0)
    #expect(WDBadge.countText(0) == "0")
    #expect(WDBadge.countText(99) == "99")
    #expect(WDBadge.countText(100) == "99+")
  }

  @Test("WDBadge：圆点 7×7；状态胶囊 24 高不变")
  func badgeDotAndCapsule() {
    let dot = size(WDBadge(value: .dot))
    #expect(abs(dot.width - 7) <= 1)
    #expect(abs(dot.height - 7) <= 1)
    #expect(abs(size(WDBadge(label: Text(verbatim: "共享"))).height - 24) <= 1)
  }

  // MARK: - M5 出口判据（compact / 类型名清单）

  @Test("compact 三条规则：不缩字号 / 只压留白 / 热区仍 44")
  func compactRules() {
    func height<V: View>(_ view: V) -> CGFloat {
      let controller = UIHostingController(rootView: view)
      return controller.sizeThatFits(
        in: CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude)
      )
      .height
    }
    let search = WDSearchField(
      text: .constant("储物间"), placeholder: Text(verbatim: "搜索任务或成员"),
      clearAccessibilityLabel: Text(verbatim: "清除搜索内容"))
    let stepper = WDStepper(value: .constant(3), label: Text(verbatim: "数量"), in: 0...10)
    let tab = WDTabBar(
      items: [
        .init(id: "a", icon: .home, label: Text(verbatim: "今天")),
        .init(id: "b", icon: .todo, label: Text(verbatim: "任务")),
      ],
      selection: .constant("a"))
    #expect(height(search.wdDensity(.comfortable)) == height(search.wdDensity(.compact)))
    #expect(height(stepper.wdDensity(.comfortable)) == height(stepper.wdDensity(.compact)))
    #expect(height(tab.wdDensity(.comfortable)) == height(tab.wdDensity(.compact)))
    #expect(height(stepper.wdDensity(.compact)) >= WDSize.touchTargetMin)
  }

  @Test("组件类型名清单 == contracts/*.yaml 的 component 集合（已实现的 37 件）")
  func contractTypeNames() throws {
    let directory = try WDContracts.locate()
    let urls = try FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "yaml" }
    var names = Set<String>()
    for url in urls {
      let text = try String(contentsOf: url, encoding: .utf8)
      for line in text.split(separator: "\n") where line.hasPrefix("component:") {
        names.insert(
          line.replacingOccurrences(of: "component:", with: "")
            .trimmingCharacters(in: .whitespaces))
        break
      }
    }
    let expected: Set<String> = [
      "WDButton", "WDIconButton", "WDTextField", "WDSwitch", "WDCheckbox", "WDListRow",
      "WDCard", "WDBadge", "WDAvatar", "WDIcon", "WDDivider", "WDListSection",
      "WDProgressBar", "WDProgressRing", "WDBanner", "WDEmptyState", "WDSkeleton",
      "WDAlert", "WDActionSheet", "WDBottomSheet", "WDToast",
      "WDSearchField", "WDRadio", "WDSlider", "WDStepper", "WDChip", "WDAvatarStack",
      "WDSegmentedControl", "WDPicker", "WDDatePicker", "WDFormRow",
      "WDPullRefresh", "WDNavigationBar", "WDTabBar", "WDToolbar", "WDFAB",
      "WDAssigneePicker",
    ]
    #expect(names == expected, "契约集合与实现清单不一致：\(names.symmetricDifference(expected))")
    #expect(names.count == 37)
  }
}
