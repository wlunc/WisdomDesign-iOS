import SwiftUI

/// 线性进度（SPEC §2.10-#15；设计 15）。
///
/// 设计口径（设计 15）：
/// - 轨道高 **6**、圆角 `radius.full`、最小宽 **100**、分段间距 **2**；
/// - 四个变体：确定（百分比）/ 分段（n 项完成几项）/ 不确定（35% 宽来回移动）/ 完成（成功色）；
/// - 进行中 `gradient.mid`（因对比度改为品牌色渐变，差异登记）；完成 `status.success` + 成功触觉一次；
/// - 数值变化 240ms 线性；首次出现 3200ms 缓出；不确定 1.4s 循环且**超过 1 秒才显示**；
/// - 禁用整体 **45%**；不可交互；零文案（标签/数值/单位由调用方给）。
public struct WDProgressBar: View {
  fileprivate enum Mode {
    case determinate(Double)
    case segmented(segments: Int, completed: Int)
    case indeterminate
  }

  private let mode: Mode
  private let label: Text?
  private let valueText: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdInstantMotion) private var instantMotion
  /// 播报通道（只读；B18：跨 25/50/75/100 播报一次）。
  @Environment(\.wdAnnouncerText) private var announcer

  @State private var indeterminatePhase = false
  /// 上一次播报的时刻（节流）。
  @State private var lastAnnouncement: ContinuousClock.Instant?
  @State private var showsIndeterminate = false
  @State private var hasAppeared = false
  @State private var didComplete = false

  // MARK: - 构造

  /// 确定态（value 钳制到 0...1）。
  public init(value: Double, label: Text? = nil, valueText: Text? = nil) {
    self.mode = .determinate(value)
    self.label = label
    self.valueText = valueText
  }

  /// 分段态（设计 15 §4：n 段表示「n 项里完成几项」；段数为 0 时按 1 处理）。
  public init(segments: Int, completed: Int, label: Text? = nil, valueText: Text? = nil) {
    let total = max(segments, 1)
    self.mode = .segmented(segments: total, completed: min(max(completed, 0), total))
    self.label = label
    self.valueText = valueText
  }

  /// 不确定态（不提供 valuenow，朗读「加载中」）。
  public init(label: Text? = nil, valueText: Text? = nil) {
    self.mode = .indeterminate
    self.label = label
    self.valueText = valueText
  }

  // MARK: - 渲染

  /// 头部（标签 + 数值）+ 轨道。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      if label != nil || displayValueText != nil {
        accessibilityHeader
      }
      bar
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isEnabled ? 1 : Self.disabledOpacity)
    .accessibilityRepresentation { accessibilityProgress }
    .onAppear(perform: reveal)
    // 设计 15 §10 / §2.10-#15「只跨 25/50/75/100」：向上跨阈值时播一次（节流在 `WDAnnouncementThrottle`）。
    .onChange(of: announcedProgress) { previous, current in
      announceIfCrossedThreshold(from: previous, to: current)
    }
    .onChange(of: isComplete) { _, complete in
      guard complete else {
        didComplete = false
        return
      }
      guard !didComplete else { return }
      didComplete = true
      WDHaptics.shared.play(.success, budget: budget)
    }
    .task { await revealIndeterminate() }
  }

  // MARK: - 头部

  @ViewBuilder private var accessibilityHeader: some View {
    HStack(alignment: .firstTextBaseline, spacing: WDSpacing.s3) {
      if let label {
        label
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textSecondary)
          .wdLineBox(WDType.footnote)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Spacer(minLength: 0)
      }
      if let displayValueText {
        displayValueText
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textPrimary)
          .wdLineBox(WDType.footnote)
          .monospacedDigit()
      }
    }
  }

  // MARK: - 轨道

  @ViewBuilder private var bar: some View {
    switch mode {
    case .determinate(let value):
      determinateBar(value: value)
    case .segmented(let segments, let completed):
      segmentedBar(segments: segments, completed: completed)
    case .indeterminate:
      indeterminateBar
    }
  }

  private func determinateBar(value: Double) -> some View {
    let clamped = min(max(value, 0), 1)
    let ratio = CGFloat(hasAppeared ? clamped : 0)
    return Capsule()
      .fill(colors.surfaceTint)
      .frame(height: Self.barHeight)
      .overlay(alignment: .leading) {
        Group {
          if clamped >= 1 {
            Capsule().fill(colors.statusSuccess)
          } else {
            Capsule().fill(progressFill)
          }
        }
        .frame(height: Self.barHeight)
        .scaleEffect(x: ratio, anchor: .leading)
        .animation(valueAnimation(for: clamped), value: clamped)
      }
      .clipShape(Capsule())
      .frame(minWidth: Self.minimumWidth)
  }

  /// 分段：n 段等分，完成段填品牌色（全完成换成功色、段数不增）。
  private func segmentedBar(segments: Int, completed: Int) -> some View {
    let complete = completed >= segments
    return HStack(spacing: Self.segmentGap) {
      ForEach(0..<segments, id: \.self) { index in
        Capsule()
          .fill(
            index < completed
              ? (complete ? colors.statusSuccess : colors.textBrand)
              : colors.surfaceTint
          )
          .frame(maxWidth: .infinity)
          .frame(height: Self.barHeight)
      }
    }
    .frame(minWidth: Self.minimumWidth)
    .animation(.linear(duration: WDMotion.Duration.base), value: completed)
  }

  private var indeterminateBar: some View {
    HStack(spacing: 0) {
      if showsIndeterminate {
        if indeterminatePhase && !appearance.reduceMotion {
          Spacer(minLength: 0)
        }
        Capsule()
          .fill(progressFill)
          .frame(height: Self.barHeight)
          .containerRelativeFrame(.horizontal) { length, _ in
            length * Self.indeterminateRatio
          }
        if !indeterminatePhase || appearance.reduceMotion {
          Spacer(minLength: 0)
        }
      }
    }
    .frame(height: Self.barHeight)
    .background(Capsule().fill(colors.surfaceTint))
    .clipShape(Capsule())
    .frame(minWidth: Self.minimumWidth)
    .animation(
      appearance.reduceMotion
        ? nil
        : .easeInOut(duration: Self.indeterminateCycle).repeatForever(autoreverses: true),
      value: indeterminatePhase
    )
    .onChange(of: showsIndeterminate) { _, shown in
      guard shown, !appearance.reduceMotion else { return }
      indeterminatePhase = true
    }
  }

  /// 进行中的填充：textBrand → statusInfo。设计的 gradient.mid 浅端在 surface.tint 上只有 2.02:1（< 3:1），
  /// 为满足图形对比度改用品牌色实底渐变（浅色 3.91:1 / 深色 6.71:1）；差异进 M4 出口报告。
  private var progressFill: LinearGradient {
    LinearGradient(
      colors: [colors.textBrand, colors.statusInfo],
      startPoint: .leading,
      endPoint: .trailing
    )
  }

  // MARK: - 动效

  /// 首次出现：3200ms 缓出（设计 15 §9）；Reduce Motion 直接落终态。
  private func reveal() {
    guard !hasAppeared else { return }
    if instantMotion || appearance.reduceMotion {
      hasAppeared = true
      if case .indeterminate = mode {
        showsIndeterminate = true
      }
      return
    }
    withAnimation(.easeOut(duration: Self.appearDuration)) {
      hasAppeared = true
    }
  }

  /// 不确定态超过 1 秒才显示（设计 15 §9）；Reduce Motion 立即显示静态段。
  private func revealIndeterminate() async {
    guard case .indeterminate = mode else { return }
    if !(instantMotion || appearance.reduceMotion) {
      try? await Task.sleep(for: Self.indeterminateAppearDelay)
    }
    guard !Task.isCancelled else { return }
    showsIndeterminate = true
  }

  /// 数值变化 240ms 线性；完成 300ms 过渡（设计 15 §5/§9）。
  private func valueAnimation(for value: Double) -> Animation {
    value >= 1
      ? .easeOut(duration: Self.completionDuration)
      : .linear(duration: WDMotion.Duration.base)
  }

  // MARK: - 状态与无障碍

  private var isComplete: Bool {
    switch mode {
    case .determinate(let value):
      return min(max(value, 0), 1) >= 1
    case .segmented(let segments, let completed):
      return completed >= segments
    case .indeterminate:
      return false
    }
  }

  /// 设计 15 §10：角色为 progressbar、提供当前值；不确定态不给 valuenow。
  @ViewBuilder private var accessibilityProgress: some View {
    switch mode {
    case .determinate(let value):
      ProgressView(value: min(max(value, 0), 1))
        .accessibilityLabel(labelText)
        .accessibilityValue(accessibilityValueText)
    case .segmented(let segments, let completed):
      ProgressView(value: Double(completed), total: Double(segments))
        .accessibilityLabel(labelText)
        .accessibilityValue(accessibilityValueText)
    case .indeterminate:
      ProgressView()
        .accessibilityLabel(labelText)
    }
  }

  /// 分段态即使调用方没给 valueText，也按设计 15 §7 显示「3 / 5」（纯数字，L-B 安全）。
  private var displayValueText: Text? {
    if let valueText { return valueText }
    if case .segmented(let segments, let completed) = mode {
      return Text(verbatim: "\(completed) / \(segments)")  // wd-structure-check:disable R21 — a11y
    }
    return nil
  }

  private var labelText: Text {
    label ?? Text(verbatim: "")  // wd-structure-check:disable R21 — a11y
  }

  /// 读屏当前值：确定态百分比 / 分段态「3 / 5」（设计 15 §7）；均由调用方 valueText 优先。
  var accessibilityValueText: Text {
    switch mode {
    case .determinate(let value):
      if let valueText { return valueText }
      let pct = min(max(value, 0), 1).formatted(.percent.precision(.fractionLength(0)))
      return Text(verbatim: pct)  // wd-structure-check:disable R21 — a11y
    case .segmented(let segments, let completed):
      if let valueText { return valueText }
      return Text(verbatim: "\(completed) / \(segments)")  // wd-structure-check:disable R21 — a11y
    case .indeterminate:
      return Text(verbatim: "")  // wd-structure-check:disable R21 — a11y
    }
  }

  // MARK: - 阈值播报（B18；设计 15 §10 的 25/50/75/100）

  /// 参与阈值判定的进度（确定态/分段态用 0…1；不确定态不参与）。
  private var announcedProgress: Double {
    switch mode {
    case .determinate(let value):
      return min(max(value, 0), 1)
    case .segmented(let segments, let completed):
      return Double(completed) / Double(segments)
    case .indeterminate:
      return 0
    }
  }

  /// 跨过阈值时播一次。
  ///
  /// 三条闸门：① 调用方注入了 `wdAnnouncer`；② `WDAnnouncementThrottle.shouldAnnounce` 判定
  /// 「向上跨过」某个阈值（一次跨多个也只播一次）；③ 节流器的最小间隔（连点/动画插值不刷屏）。
  /// 文案用 `accessibilityValueText`（调用方给优先），库内不拼任何单位或标点（L-B）。
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
    announcer(accessibilityValueText, .polite)
  }

  /// 阈值（设计 15 §10：只在跨过 25/50/75/100 时播，最多 4 次）。
  ///
  /// 写成逐行的「分母 4 的分数」是为了让每个字面量都能带一行豁免（结构检查器按行判定）。
  static let announcementThresholds: [Double] = [
    0.25,  // wd-structure-check:disable R7 — 设计 15 §10 的 25%
    0.5,  // wd-structure-check:disable R7 — 设计 15 §10 的 50%
    0.75,  // wd-structure-check:disable R7 — 设计 15 §10 的 75%
    1,
  ]
  // MARK: - 常量（设计 15）

  /// 轨道高度 6（设计 15 §3）。
  private static let barHeight: CGFloat = 6  // wd-structure-check:disable R7 — 设计 15 §3
  /// 分段间距 2（设计 15 §3）。
  private static let segmentGap: CGFloat = 2  // wd-structure-check:disable R7 — 设计 15 §3
  /// 最小宽度 100（设计 15 §3）。
  private static let minimumWidth: CGFloat = 100  // wd-structure-check:disable R7 — 设计 15 §3
  /// 不确定段宽 35%（设计 15 §5）。
  private static let indeterminateRatio: CGFloat = 0.35  // wd-structure-check:disable R7 — 设计15
  /// 不确定循环 1.4s（设计 15 §5）。
  private static let indeterminateCycle: TimeInterval = 1.4  // wd-structure-check:disable R7 — 设计15
  /// 不确定态出现延迟 1s（设计 15 §9）。
  private static let indeterminateAppearDelay: Duration = .seconds(1)
  /// 首次出现 3200ms 缓出（设计 15 §9；motion.component.progress-easeout）。
  private static let appearDuration: TimeInterval = 3.2  // wd-structure-check:disable R7 — 设计15
  /// 完成过渡 300ms（设计 15 §5）。
  private static let completionDuration: TimeInterval = 0.3  // wd-structure-check:disable R7 — 设计15
  /// 禁用整体 45%（设计 15 §5；组件级差异，全局 disabled 档为 40）。
  private static let disabledOpacity: CGFloat = 0.45  // wd-structure-check:disable R7 — 设计 15 §5
}
