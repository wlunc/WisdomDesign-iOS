import SwiftUI

/// 下拉刷新（SPEC §2.10-#32；M5）。
///
/// 设计口径（设计 32）+ O-7/F50 裁决：
/// - **载体 = 系统 `.refreshable`**（系统视觉）；行为 = 到阈值触发一次、进行中不可重复触发；
/// - `isRefreshing` 反映刷新状态（开始置 true、结束置 false）；
/// - 提供 `label` 时同时挂一个「刷新」自定义无障碍操作（读屏用户不必会下拉）；
/// - 系统视觉下自绘阈值 64 / 环 24 / 环线宽 2 / 三态文案 / 阈值触觉**未实现**，差异登记在
///   `docs/M5-EXIT-REPORT.md`。
public struct WDPullRefresh: ViewModifier {
  @Binding private var isRefreshing: Bool
  private let label: Text?
  private let onRefresh: @Sendable () async -> Void

  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：刷新状态 + 可选读屏标签 + 异步刷新动作。
  public init(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefresh: @escaping @Sendable () async -> Void
  ) {
    self._isRefreshing = isRefreshing
    self.label = label
    self.onRefresh = onRefresh
  }

  /// 系统 refreshable + 可选的无障碍辅助操作。
  public func body(content: Content) -> some View {
    content
      .refreshable { await performRefresh() }
      .modifier(
        WDPullRefreshAccessibility(
          label: label,
          isRefreshing: $isRefreshing,
          onRefresh: onRefresh
        )
      )
  }

  /// 一次刷新：进行中去重；开始时一次轻触觉。
  @MainActor private func performRefresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    WDHaptics.shared.play(.press, budget: budget)
    await onRefresh()
    isRefreshing = false
  }
}

extension View {
  /// 下拉刷新（系统 `.refreshable` 载体；`isRefreshing` 反映刷新状态）。
  public func wdPullRefresh(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefresh: @escaping @Sendable () async -> Void
  ) -> some View {
    modifier(
      WDPullRefresh(isRefreshing: isRefreshing, label: label, onRefresh: onRefresh)
    )
  }
}

/// 读屏辅助操作：`label` 非 nil 时挂「刷新」动作（不强制手势）。
private struct WDPullRefreshAccessibility: ViewModifier {
  let label: Text?
  let isRefreshing: Binding<Bool>
  let onRefresh: @Sendable () async -> Void

  @ViewBuilder func body(content: Content) -> some View {
    if let label {
      content.accessibilityAction(named: label) {
        Task { @MainActor in
          guard !isRefreshing.wrappedValue else { return }
          isRefreshing.wrappedValue = true
          await onRefresh()
          isRefreshing.wrappedValue = false
        }
      }
    } else {
      content
    }
  }
}
