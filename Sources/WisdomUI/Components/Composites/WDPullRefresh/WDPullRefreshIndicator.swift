import SwiftUI

/// 下拉刷新自绘指示器的几何与阈值（设计 32 §2/§3/§5/§9）。
///
/// 设计值均自带出处；R7 的数值字面量豁免按仓规同行给理由（令牌里没有下拉环尺寸键）。
enum WDPullRefreshMetrics {
  /// 触发阈值（设计 32 §3：下拉超过此距离松手才刷新）。
  static let triggerThreshold: CGFloat = 64  // wd-structure-check:disable R7 — 设计 32 §3 触发阈值 64
  /// 最大下拉距离（设计 32 §3：超过后阻力显著增加；指示器按此封顶）。
  static let maximumPull: CGFloat = 120  // wd-structure-check:disable R7 — 设计 32 §3 最大下拉 120
  /// 指示器直径（设计 32 §3：24）。
  static let ringDiameter: CGFloat = 24  // wd-structure-check:disable R7 — 设计 32 §3 指示器直径 24
  /// 环线宽（设计 32 §3：2）。
  static let ringLineWidth: CGFloat = 2  // wd-structure-check:disable R7 — 设计 32 §3 环线宽 2
  /// 指示器与首行间距（设计 32 §3：space.4 = 12）。
  static let ringGap: CGFloat = WDSpacing.s4
  /// 刷新中旋转弧长（画廊 32「正在刷新」的环约顶部 1/4 品牌色；完整圆旋转不可见）。
  static let refreshingArc: CGFloat = 0.25  // wd-structure-check:disable R7 — 画廊 32 刷新环品牌弧约 1/4
  /// 刷新环旋转一周的时长（画廊 32 CSS：1s linear infinite）。
  static let spinDuration: Double = 1  // wd-structure-check:disable R7 — 画廊 32 环旋转 1s
  /// 渲染更新粒度（非设计值：0.25pt 内不触发重绘，降低逐帧 State 写入）。
  static let updateTolerance: CGFloat = 0.25  // wd-structure-check:disable R7 — 渲染更新粒度（实现常量）
  /// 指示器从 0 到完全显出的距离（环直径 + 间距；不引入第三个魔数）。
  static let fadeInDistance: CGFloat = ringDiameter + ringGap

  /// 由滚动几何算下拉距离：到顶后继续下拉的位移（负 offset 减去顶部 inset）。
  static func pullDistance(offsetY: CGFloat, topInset: CGFloat) -> CGFloat {
    max(0, -(offsetY + topInset))
  }

  /// 下拉进度（0…1；到阈值即满）。
  static func progress(pull: CGFloat) -> CGFloat {
    min(max(pull / triggerThreshold, 0), 1)
  }

  /// 是否到达触发阈值（设计验收：误差 ≤ 2pt；这里按精确 64 判定，界面上环在 64 处闭合）。
  static func isPastThreshold(_ pull: CGFloat) -> Bool {
    pull >= triggerThreshold
  }

  /// 指示器在滚动视图顶部的纵向位置（随下拉跟随；贴顶时不越出容器）。
  static func indicatorTop(pull: CGFloat) -> CGFloat {
    max(0, pull - fadeInDistance)
  }

  /// 指示器透明度（下拉前段 0 → 1；设计 32 §5）。
  static func indicatorOpacity(pull: CGFloat) -> CGFloat {
    min(max(pull / fadeInDistance, 0), 1)
  }
}

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
