import SwiftUI

/// 下拉刷新「本次结局」的中继（B12 失败通道的状态容器；**内部**，零 public）。
///
/// 为什么需要它：组件里不能用 `static var` 记「最近一次结局」（R13a/R13b 禁静态可变状态），
/// 而结局又必须从执行器（`WDPullRefreshRunner`）交回载体视图做阶段判定/播报后清理。
/// 做法 = 栈式令牌：调用方 `push()` 一个占位 → 执行器写 `phase` → 载体 `take()` 读走并出栈。
/// 按栈序读写 ⇒ 并发的两次刷新（例如外层按钮触发的第二次）各拿各的结局，不会串。
@MainActor
final class WDPullRefreshPhaseRelay {
  /// 本次刷新的结局（成功/失败；`nil` = 还没有结局，旧 init 路径始终是 nil）。
  private(set) var outcome: WDPullRefreshOutcome?

  /// 在途令牌（栈）；`take` 之后出栈。
  private static var inFlight: [WDPullRefreshPhaseRelay] = []

  fileprivate init() {}

  /// 压入新令牌（一次刷新一个）。
  static func push() -> WDPullRefreshPhaseRelay {
    let relay = WDPullRefreshPhaseRelay()
    inFlight.append(relay)
    return relay
  }

  /// 记录本次结局（成功/失败；旧 init 路径不写 ⇒ 保持 nil）。
  func record(_ recorded: WDPullRefreshOutcome) {
    outcome = recorded
  }

  /// 读走该令牌的结局并出栈（在途表里不再保留它）。
  func takeOutcome() -> WDPullRefreshOutcome? {
    let recorded = outcome
    // 读走即清：同一令牌只交回一次结局（B12 单测「再读为 nil」；避免下次刷新复用旧结局）。
    outcome = nil
    WDPullRefreshPhaseRelay.inFlight.removeAll { $0 === self }
    return recorded
  }
}
