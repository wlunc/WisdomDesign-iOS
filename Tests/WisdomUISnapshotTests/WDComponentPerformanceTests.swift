import SwiftUI
import Testing
import WisdomUI

/// 组件级性能探针（M2 出口：**只报不拦**，模拟器相对量；SPEC §1.5.5 的 nightly-3 口径）。
///
/// 每个组件用"快照同款渲染路径"跑 N 次（含 3 次预热丢弃），打印平均/最小毫秒数。
/// **不设阈值**：数字进 M2 出口报告；跨机器不可比，只用来看回归趋势。
@MainActor
@Suite("组件性能探针", .serialized)
struct WDComponentPerformanceTests {
  static let iterations = 15

  private static let lightState = SnapshotSupport.State(
    appearance: .light, typeSize: .default, direction: .ltr)

  private struct Case {
    let name: String
    let size: CGSize
    let hierarchy: Bool
    let view: () -> AnyView
  }

  private static func cases() -> [Case] {
    [
      Case(name: "WDIcon", size: CGSize(width: 120, height: 80), hierarchy: false) {
        AnyView(WDIcon(icon: .home, size: .lg))
      },
      Case(name: "WDBadge", size: CGSize(width: 160, height: 60), hierarchy: false) {
        AnyView(WDBadge(label: Text(verbatim: "已完成")))
      },
      Case(name: "WDDivider", size: CGSize(width: 320, height: 20), hierarchy: false) {
        AnyView(WDDivider())
      },
      Case(name: "WDAvatar", size: CGSize(width: 80, height: 80), hierarchy: false) {
        AnyView(WDAvatar(value: .init(label: Text(verbatim: "妈"))))
      },
      Case(name: "WDCheckbox", size: CGSize(width: 240, height: 60), hierarchy: false) {
        AnyView(WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "共享")))
      },
      Case(name: "WDSwitch", size: CGSize(width: 280, height: 60), hierarchy: false) {
        AnyView(WDSwitch(isOn: .constant(true), label: Text(verbatim: "共享")))
      },
      Case(name: "WDCard", size: CGSize(width: 320, height: 160), hierarchy: false) {
        AnyView(
          WDCard(style: .elevated) {
            Text(verbatim: "卡片内容").wdFont(WDType.body)
          })
      },
      Case(name: "WDListRow", size: CGSize(width: 340, height: 100), hierarchy: false) {
        AnyView(
          WDListRow(
            title: Text(verbatim: "整理储物间"),
            subtitle: Text(verbatim: "今天 18:00 前"),
            leading: .icon(.task),
            trailing: .value(Text(verbatim: "3 件")),
            action: {}
          ))
      },
      Case(name: "WDTextField", size: CGSize(width: 340, height: 120), hierarchy: true) {
        AnyView(
          WDTextField(
            text: .constant("整理储物间"),
            label: Text(verbatim: "任务名称")
          ))
      },
      Case(name: "WDIconButton", size: CGSize(width: 120, height: 80), hierarchy: true) {
        AnyView(WDIconButton(icon: .search, accessibilityLabel: Text(verbatim: "搜索")) {})
      },
      Case(name: "WDButton", size: CGSize(width: 220, height: 80), hierarchy: true) {
        AnyView(WDButton(verbatim: "提交") {})
      },
    ]
  }

  @Test("11 件组件：快照渲染耗时（只打印，不设门槛）")
  func renderTimes() {
    let values = SnapshotSupport.values(for: Self.lightState)
    for item in Self.cases() {
      var samples: [Double] = []
      let clock = ContinuousClock()
      for iteration in 0..<Self.iterations {
        let start = clock.now
        let png: Data? =
          item.hierarchy
          ? SnapshotSupport.pngHierarchy(
            item.view().wdTheme(WDTheme(colors: values)), state: Self.lightState, size: item.size)
          : SnapshotSupport.png(
            item.view().wdTheme(WDTheme(colors: values)), state: Self.lightState, size: item.size)
        let elapsed = start.duration(to: clock.now)
        if png == nil {
          Issue.record("性能探针渲染失败：\(item.name)")
          break
        }
        if iteration >= 3 {  // 前 3 次预热（首帧缓存/字体装载）
          samples.append(
            Double(elapsed.components.seconds) * 1000
              + Double(elapsed.components.attoseconds) / 1e15)
        }
      }
      guard let minimum = samples.min() else { continue }
      let average = samples.reduce(0, +) / Double(samples.count)
      print(
        String(
          format: "PERF %@ avg_ms=%.2f min_ms=%.2f n=%d", item.name, average, minimum,
          samples.count))
    }
  }
}
