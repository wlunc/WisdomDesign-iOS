import SwiftUI

/// 环形进度尺寸（设计 16 §3：标准 60 / 紧凑 44；线宽 6 / 5）。
public enum WDProgressRingSize: String, CaseIterable, Sendable, Equatable {
  case standard
  case compact
}

/// 环形进度（SPEC §2.10-#16；设计 16）。
///
/// 环从 12 点方向顺时针；线帽圆头；环内显示 valueText（缺省为百分比），环外 label 为说明。
/// 完成时环色转 status.success 并触发一次成功触觉；环本身对读屏是装饰。
public struct WDProgressRing: View {
  private let value: Double
  private let size: WDProgressRingSize
  private let label: Text?
  private let valueText: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget
  /// 播报通道（只读；B18：跨 25/50/75/100 播报一次）。
  @Environment(\.wdAnnouncerText) private var announcer

  @State private var animatedValue: Double = 0
  @State private var didComplete = false
  /// 上一次播报的时刻（节流）。
  @State private var lastAnnouncement: ContinuousClock.Instant?

  /// 构造。
  public init(
    value: Double,
    size: WDProgressRingSize = .standard,
    label: Text? = nil,
    valueText: Text? = nil
  ) {
    self.value = value
    self.size = size
    self.label = label
    self.valueText = valueText
  }

  /// 渲染。
  public var body: some View {
    VStack(spacing: WDSpacing.s3) {
      ring
      if let label {
        label
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textSecondary)
          .multilineTextAlignment(.center)
          .wdLineBox(WDType.footnote)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label ?? Text(verbatim: ""))
    .accessibilityValue(
      valueText ?? Text(verbatim: clamped.formatted(.percent.precision(.fractionLength(0))))
    )
    .onAppear {
      animatedValue = clamped
      fireCompletionIfNeeded()
    }
    .onChange(of: clamped) { previous, newValue in
      animatedValue = newValue
      fireCompletionIfNeeded()
      announceIfCrossedThreshold(from: previous, to: newValue)
    }
  }

  // MARK: - 阈值播报（B18；与 `WDProgressBar` 同口径）

  /// 跨过 25/50/75/100 时播一次（设计 16 §10 与进度条一致：不逐帧播）。
  ///
  /// 文案用 `valueText`（调用方给优先）或系统百分比，库内不拼单位（L-B）。
  private func announceIfCrossedThreshold(from previous: Double, to current: Double) {
    guard let announcer else { return }
    guard
      WDAnnouncementThrottle.shouldAnnounce(
        previous: previous, current: current, thresholds: Self.announcementThresholds)
    else { return }
    let now = ContinuousClock.now
    guard WDAnnouncementThrottle.shouldAnnounceAfterRelease(now: now, last: lastAnnouncement)
    else { return }
    lastAnnouncement = now
    announcer(announcementText, .polite)
  }

  /// 播报文案（与 `accessibilityValue` 同源；调用方给了 `valueText` 就原样用）。
  private var announcementText: Text {
    if let valueText { return valueText }
    return Text(verbatim: percentText)  // wd-structure-check:disable R21 — a11y 播报串
  }

  /// 读屏百分比（与 `accessibilityValue` 同源）。
  private var percentText: String {
    clamped.formatted(.percent.precision(.fractionLength(0)))
  }

  /// 阈值（设计 15 §10 的 25/50/75/100，环形沿用同一组）。
  static let announcementThresholds: [Double] = [
    0.25,  // wd-structure-check:disable R7 — 设计 15 §10 的 25%
    0.5,  // wd-structure-check:disable R7 — 设计 15 §10 的 50%
    0.75,  // wd-structure-check:disable R7 — 设计 15 §10 的 75%
    1,
  ]
  private var clamped: Double { min(max(value, 0), 1) }
  private var isComplete: Bool { clamped >= 1 }
  private var diameter: CGFloat {
    size == .standard ? 60 : 44  // wd-structure-check:disable R7 — 设计 16 §3 的环径
  }
  private var lineWidth: CGFloat {
    size == .standard ? 6 : 5  // wd-structure-check:disable R7 — 设计 16 §3 的线宽
  }

  private var ring: some View {
    let fill: AnyShapeStyle =
      isComplete
      ? AnyShapeStyle(colors.statusSuccess) : AnyShapeStyle(WDGradient.mid.linearGradient)
    return ZStack {
      Circle()
        .stroke(colors.surfaceTint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
      Circle()
        .trim(from: 0, to: animatedValue)
        .stroke(fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))  // wd-structure-check:disable R7 — 12 点方向起点
        .animation(
          appearance.reduceMotion
            ? .linear(duration: WDMotion.Duration.reduced)
            : .easeOut(duration: 3.2),  // wd-structure-check:disable R7 — 设计 16 §9 的首次增长 3200ms
          value: animatedValue
        )
      centerText
    }
    .frame(width: diameter, height: diameter)
    .accessibilityHidden(true)
  }

  @ViewBuilder private var centerText: some View {
    if let valueText {
      valueText
        .wdFont(WDType.title2)
        .foregroundStyle(colors.textPrimary)
        .monospacedDigit()
        .wdLineBox(WDType.title2)
    } else if isComplete {
      WDIcon(icon: .done, size: .sm)
        .foregroundStyle(colors.statusSuccess)
    } else {
      Text(verbatim: clamped.formatted(.percent.precision(.fractionLength(0))))
        .wdFont(WDType.title2)
        .foregroundStyle(colors.textPrimary)
        .monospacedDigit()
        .wdLineBox(WDType.title2)
    }
  }

  private func fireCompletionIfNeeded() {
    guard clamped >= 1, !didComplete else { return }
    didComplete = true
    WDHaptics.shared.play(.success, budget: budget)
  }
}
