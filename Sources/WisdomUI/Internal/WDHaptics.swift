import SwiftUI
import UIKit

/// 触觉种类（内部；SPEC §2.6.3 / F39）。
enum WDHapticKind: Sendable, Equatable {
  /// 按下（按钮/行）。
  case press
  /// 切换（开关/勾选）。
  case toggle
  /// 完成（进度到 100% 等，设计 15 §5）。
  case success
}

/// 可注入的触觉 sink（测试用捕获器；组件一律经 `WDHaptics` 调用，不直接碰 UIKit）。
@MainActor protocol WDHapticSink: AnyObject {
  /// 触发一次触觉。
  func play(_ kind: WDHapticKind)
}

/// 系统实现（`UIImpactFeedbackGenerator(.light)`；设计：轻触觉）。
@MainActor final class WDSystemHapticSink: WDHapticSink {
  private let generator = UIImpactFeedbackGenerator(style: .light)
  private let notification = UINotificationFeedbackGenerator()

  func play(_ kind: WDHapticKind) {
    switch kind {
    case .press, .toggle:
      // 两种语义在 iOS 上都用 light impact（设计只要求"轻"；差异归 F39）。
      generator.impactOccurred()
    case .success:
      notification.notificationOccurred(.success)
    }
  }
}

/// 触觉网关：**一次操作最多一次**（`WDEffectsBudget.hapticsPerAction`；DF-03 第 7 条）。
///
/// - 组件读取 `@Environment(\.wdEffectsBudget)` 后调用 `WDHaptics.shared.play(_:budget:)`；
/// - 测试把 `sink` 换成捕获器即可断言次数（不需要真的震动）。
@MainActor final class WDHaptics {
  /// 进程内单例（`static let`，不是可变静态状态）。
  static let shared = WDHaptics()

  /// 可注入 sink；`nil` = 用系统实现。
  var sink: (any WDHapticSink)?

  private let system = WDSystemHapticSink()

  private init() {}

  /// 触发一次（预算为 0 时不触发）。
  func play(_ kind: WDHapticKind, budget: WDEffectsBudget) {
    guard budget.hapticsPerAction > 0 else { return }
    (sink ?? system).play(kind)
  }
}
