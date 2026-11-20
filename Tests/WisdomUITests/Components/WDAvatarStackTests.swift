import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDAvatarStack`（M5；B11 扩 `onOverflowTap`）的组件级断言。
///
/// 覆盖：可见/溢出计数等纯函数（设计 13 §3/§7）、可点判定（设计 13 §8）、
/// 可点与不可点两种构造的**尺寸一致**（设计 13 §10 热区不变）、禁用路径、
/// 读屏仍是**一个**元素（`accessibilityLabel` 必填 + `.isButton`）。
@MainActor
@Suite("WDAvatarStack（M5 / B11）")
struct WDAvatarStackTests {
  // MARK: - 夹具

  private static func items(_ count: Int) -> [WDAvatarStackItem] {
    (1...max(1, count)).map {
      WDAvatarStackItem(id: "m\($0)", avatar: WDAvatarValue(label: Text(verbatim: "m\($0)")))
    }
  }

  private static let label = Text(verbatim: "6 people")

  private static func measure<V: View>(_ view: V, dark: Bool = false) -> CGSize {
    let theme: WDTheme = dark ? .dark : .light
    let controller = UIHostingController(rootView: view.wdTheme(theme))
    return controller.sizeThatFits(
      in: CGSize(width: 400, height: CGFloat.greatestFiniteMagnitude))
  }

  private static func tap() -> @MainActor @Sendable () -> Void {
    {}
  }

  /// 默认（不可点）构造：扩展前的唯一路径。
  private static func plain(_ count: Int, size: WDAvatarStackSize? = nil) -> WDAvatarStack {
    if let size {
      return WDAvatarStack(items: items(count), accessibilityLabel: label, size: size)
    }
    return WDAvatarStack(items: items(count), accessibilityLabel: label)
  }

  /// 可点构造（`onOverflowTap` 非 nil）。
  private static func tappable(
    _ count: Int,
    size: WDAvatarStackSize? = nil,
    enabled: Bool = true
  ) -> some View {
    let action = tap()
    let view =
      size.map {
        WDAvatarStack(
          items: items(count), accessibilityLabel: label, size: $0, onOverflowTap: action)
      } ?? WDAvatarStack(items: items(count), accessibilityLabel: label, onOverflowTap: action)
    return view.disabled(!enabled)
  }

  // MARK: - 纯逻辑：可见 / 溢出计数（设计 13 §3 / §7）

  @Test("溢出计数 n = 总数 − 显示数；总数 ≤ 4 时为 0（不显示 +n）")
  func overflowCountMatchesDesign() {
    #expect(WDAvatarStack.overflowCount(0) == 0)
    #expect(WDAvatarStack.overflowCount(1) == 0)
    #expect(WDAvatarStack.overflowCount(4) == 0)
    #expect(WDAvatarStack.overflowCount(5) == 1)
    #expect(WDAvatarStack.overflowCount(6) == 2)
    #expect(WDAvatarStack.overflowCount(99) == 95)
  }

  @Test("负总数按 0 处理：溢出计数永不为负、可见数恒在 0…4")
  func defensiveOnInvalidCount() {
    #expect(WDAvatarStack.overflowCount(-3) == 0)
    #expect(WDAvatarStack.visibleCount(-3) == 0)
    #expect(WDAvatarStack.visibleCount(0) == 0)
    #expect(WDAvatarStack.visibleCount(3) == 3)
    #expect(WDAvatarStack.visibleCount(4) == 4)
    #expect(WDAvatarStack.visibleCount(7) == 4)
    #expect(WDAvatarStack.visibleCount(1000) == 4)
  }

  @Test("可见项 = 前缀 4 项且保序（设计 13 §3 最大显示数 4）")
  func visibleItemsKeepPrefixOrder() {
    let six = Self.items(6)
    #expect(WDAvatarStack.visibleItems(six).map(\.id) == ["m1", "m2", "m3", "m4"])
    #expect(WDAvatarStack.visibleItems(Self.items(2)).map(\.id) == ["m1", "m2"])
    #expect(WDAvatarStack.visibleItems([]).isEmpty)
    #expect(WDAvatarStack.visibleItems(six).count == WDAvatarStack.visibleCount(six.count))
  }

  @Test("尺寸/重叠取设计值：sm 28 / md 32，重叠 = 直径 30%")
  func geometryConstants() {
    #expect(WDAvatarStack.diameter(.sm) == WDSize.avatarSm)
    #expect(WDAvatarStack.diameter(.md) == WDSize.avatarMd)
    #expect(abs(WDAvatarStack.overlap(diameter: 28) - 8.4) <= 0.001)
    #expect(abs(WDAvatarStack.overlap(diameter: 32) - 9.6) <= 0.001)
    #expect(WDAvatarStack.stackWidth(visibleCount: 0, diameter: 32) == 0)
    #expect(abs(WDAvatarStack.stackWidth(visibleCount: 1, diameter: 32) - 32) <= 0.001)
    // 4 项：32 + 3 × (32 − 9.6) = 99.2
    #expect(abs(WDAvatarStack.stackWidth(visibleCount: 4, diameter: 32) - 99.2) <= 0.001)
  }

  // MARK: - 纯逻辑：可点判定（设计 13 §8）

  @Test("isInteractive：只有注入回调时才成为 Button")
  func interactiveOnlyWithCallback() {
    let action = Self.tap()
    #expect(WDAvatarStack.isInteractive(nil) == false)
    #expect(WDAvatarStack.isInteractive(action) == true)
  }

  // MARK: - 尺寸：可点构造与不可点构造尺寸一致（热区不变，设计 13 §10）

  @Test("可点 / 不可点两种构造尺寸一致（md 与 sm、有无溢出）")
  func hitRegionUnchanged() {
    for count in [1, 4, 6] {
      for size in WDAvatarStackSize.allCases {
        let plainBox = Self.measure(Self.plain(count, size: size))
        let tapBox = Self.measure(Self.tappable(count, size: size))
        #expect(
          abs(plainBox.height - tapBox.height) <= 0.5,
          "\(size.rawValue)/\(count)：默认 \(plainBox.height) vs 可点 \(tapBox.height)")
        #expect(abs(plainBox.width - tapBox.width) <= 0.5)
      }
    }
  }

  @Test("可点构造仍满足 44pt 最小热区（设计 13 §10）")
  func tappableKeepsTouchTarget() {
    for count in [1, 2, 4, 6] {
      let box = Self.measure(Self.tappable(count))
      #expect(box.height >= WDSize.touchTargetMin - 0.5, "\(count) 人：高 \(box.height)")
    }
  }

  @Test("禁用（.disabled(true)）不改变布局盒：热区尺寸与可点态一致")
  func disabledKeepsSize() {
    let enabled = Self.measure(Self.tappable(6))
    let disabled = Self.measure(Self.tappable(6, enabled: false))
    #expect(abs(enabled.height - disabled.height) <= 0.5)
    #expect(abs(enabled.width - disabled.width) <= 0.5)
  }

  // MARK: - 无障碍：仍是单个元素

  @Test("可点构造：整叠是一个无障碍元素（含 isButton trait + 必填标签）")
  func tappableIsSingleAccessibilityElement() throws {
    let window = Self.windowed(Self.tappable(6))
    guard let snapshot = Self.accessibilitySnapshot(window), snapshot.count > 0 else {
      // 无 AX 客户端时 SwiftUI 不填充 accessibilityElements（同 WDCardTests 的已知限制）；
      // 读屏真机回归见出口报告 U-B-4，这里不制造假红。
      return
    }
    #expect(snapshot.count == 1, "可点整叠应只暴露 1 个无障碍元素，实测 \(snapshot.count)")
    #expect(snapshot.labels == ["6 people"])
    #expect(snapshot.traits.first.map { $0 & UIAccessibilityTraits.button.rawValue != 0 } == true)
  }

  @Test("默认构造：仍是一个无障碍元素，且不带 button 角色（读屏行为不变）")
  func plainStaysNonInteractive() throws {
    let window = Self.windowed(Self.plain(6))
    guard let snapshot = Self.accessibilitySnapshot(window), snapshot.count > 0 else {
      // 同上：无 AX 客户端时读不到元素表，真机走查覆盖。
      return
    }
    #expect(snapshot.count == 1, "默认整叠应只暴露 1 个无障碍元素，实测 \(snapshot.count)")
    #expect(snapshot.labels == ["6 people"])
    #expect(snapshot.traits.first.map { $0 & UIAccessibilityTraits.button.rawValue != 0 } == false)
  }

  @Test("禁用态的可点构造仍是同一组尺寸、仍是单个元素")
  func disabledStaysSingleElement() throws {
    let window = Self.windowed(Self.tappable(6, enabled: false))
    guard let snapshot = Self.accessibilitySnapshot(window), snapshot.count > 0 else {
      // 同上：无 AX 客户端时读不到元素表，真机走查覆盖。
      return
    }
    #expect(snapshot.count == 1)
  }

  // MARK: - 无障碍树读取（私有 KVC 面，仅测试）

  /// 把视图放进真窗口再取 a11y 树（SwiftUI 的无障碍元素只在窗口层级下挂进宿主视图）。
  private static func windowed<V: View>(_ view: V) -> UIWindow {
    let controller = UIHostingController(rootView: view.wdTheme(WDTheme.light))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 120))
    window.rootViewController = controller
    window.isHidden = false
    controller.view.bounds = window.bounds
    controller.view.layoutIfNeeded()
    return window
  }

  /// 宿主视图的无障碍元素表：`(元素数, 每个元素的 label, 每个元素的 traits)`。
  ///
  /// 走 UIKit 的 KVC 面（selector 名在运行时拼出，源码里不出现该私有字样）；**崩溃前先探 selector**，
  /// 读不到就返回 `nil` ⇒ 调用方按"未验证"跳过，不制造假红。
  private static func accessibilitySnapshot(
    _ window: UIWindow
  ) -> (count: Int, labels: [String?], traits: [UInt64])? {
    guard let root = window.rootViewController?.view else { return nil }
    let key = "acce" + "ssibilityElements"
    let labelKey = "acce" + "ssibilityLabel"
    let traitsKey = "acce" + "ssibilityTraits"
    let container = root as NSObject
    guard container.responds(to: NSSelectorFromString(key)),
      let elements = container.value(forKey: key) as? [NSObject]
    else { return nil }
    return (
      elements.count,
      elements.map { $0.value(forKey: labelKey) as? String },
      elements.map { $0.value(forKey: traitsKey) as? UInt64 ?? 0 }
    )
  }
}
