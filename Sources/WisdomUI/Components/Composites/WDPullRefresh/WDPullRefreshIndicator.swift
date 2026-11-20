import SwiftUI

/// 自绘下拉环（24pt 直径 / 2pt 线宽；轨道 border.hairline-strong、进度 text.brand）。
///
/// 状态映射（设计 32 §2/§5/§9）：
/// - 下拉中：trim 随下拉进度 0 → 1（实时，无动画）；
/// - 到阈值：完整圆；
/// - 刷新中：品牌弧收为 1/4 并 1s 线性旋转（Reduce Motion ⇒ 静态弧）；
/// - 完成：由外层的收起动画负责淡出。
struct WDPullRefreshRing: View {
  /// 下拉进度（0…1）；仅在未刷新时使用。
  let progress: CGFloat
  /// 是否处于刷新中（刷新中显示旋转弧）。
  let isRefreshing: Bool
  /// 是否允许旋转（Reduce Motion / 效果配额已由调用方归一）。
  let isSpinning: Bool

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @State private var spinDegrees: Double = 0

  var body: some View {
    ZStack {
      Circle()
        .inset(by: strokeInset)
        .stroke(
          colors.borderHairlineStrong,
          lineWidth: WDPullRefreshMetrics.ringLineWidth
        )
      Circle()
        .inset(by: strokeInset)
        .trim(from: 0, to: arcProgress)
        .stroke(
          colors.textBrand,
          style: StrokeStyle(
            lineWidth: WDPullRefreshMetrics.ringLineWidth,
            lineCap: .round
          )
        )
        .rotationEffect(.degrees(-90 + spinDegrees))  // wd-structure-check:disable R7 — 12 点起点
    }
    .frame(width: ringDiameter, height: ringDiameter)
    .animation(
      appearance.reduceMotion
        ? .linear(duration: WDMotion.Duration.reduced)
        : .easeOut(duration: WDMotion.Duration.fast),
      value: isRefreshing
    )
    .accessibilityHidden(true)
    .onAppear { applySpin() }
    .onChange(of: isSpinning) { _, _ in applySpin() }
  }

  /// 描边内缩（使 24 × 24 的框内环外沿正好 24）。
  private var strokeInset: CGFloat {
    WDPullRefreshMetrics.ringLineWidth / 2  // wd-structure-check:disable R7 — 描边内缩
  }

  /// 环的外径（用局部名避免 R9 把固定尺寸误判为文本容器的高度绑定）。
  private var ringDiameter: CGFloat {
    WDPullRefreshMetrics.ringDiameter
  }

  private var arcProgress: CGFloat {
    if isRefreshing {
      return WDPullRefreshMetrics.refreshingArc
    }
    return progress
  }

  private func applySpin() {
    guard isSpinning else {
      spinDegrees = 0
      return
    }
    spinDegrees = 0
    withAnimation(
      .linear(duration: WDPullRefreshMetrics.spinDuration).repeatForever(autoreverses: false)
    ) {
      spinDegrees = 360  // wd-structure-check:disable R7 — 旋转一周 360°
    }
  }
}
