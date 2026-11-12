import SwiftUI

/// 线性进度（SPEC §2.10-#15；设计 15）。
///
/// 设计口径：轨道高 **6**、圆角 radius.full、最小宽 100；确定态按百分比填充
/// （gradient.mid），到达 100% 换 status.success；不确定态为 35% 宽的一段来回移动。
/// 不可交互；没有明确总量时用不确定态，未知加载用 WDSkeleton。
public struct WDProgressBar: View {
  fileprivate enum Mode {
    case determinate(Double)
    case indeterminate
  }

  private let mode: Mode
  private let label: Text?
  private let valueText: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  @State private var indeterminatePhase = false
  @State private var didComplete = false

  /// 轨道高度（设计 15 §3：6）。
  private static let barHeight: CGFloat = 6  // wd-structure-check:disable R7 — 设计 15 §3 的进度条高度
  private static let indeterminateWidthRatio: CGFloat = 0.35  // wd-structure-check:disable R7 — 设计
  private static let indeterminateCycle: TimeInterval = 1.4  // wd-structure-check:disable R7 — 设计

  /// 确定态（value 钳制到 0...1）。
  public init(value: Double, label: Text? = nil, valueText: Text? = nil) {
    self.mode = .determinate(value)
    self.label = label
    self.valueText = valueText
  }

  /// 不确定态（不提供 valuenow）。
  public init(label: Text? = nil, valueText: Text? = nil) {
    self.mode = .indeterminate
    self.label = label
    self.valueText = valueText
  }

  /// 渲染。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      if label != nil || valueText != nil {
        accessibilityHeader
      }
      bar
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .modifier(WDProgressBarAccessibility(label: label, valueText: valueText, mode: mode))
    .onChange(of: determinateValue) { _, newValue in
      guard let newValue, newValue >= 1 else { return }
      guard !didComplete else { return }
      didComplete = true
      WDHaptics.shared.play(.success, budget: budget)
    }
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
      if let valueText {
        valueText
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textPrimary)
          .monospacedDigit()
          .wdLineBox(WDType.footnote)
      }
    }
  }

  // MARK: - 轨道

  @ViewBuilder private var bar: some View {
    switch mode {
    case .determinate(let value):
      determinateBar(value: value)
    case .indeterminate:
      indeterminateBar
    }
  }

  private func determinateBar(value: Double) -> some View {
    let clamped = min(max(value, 0), 1)
    return Capsule()
      .fill(colors.surfaceTint)
      .frame(minHeight: Self.barHeight)
      .overlay(alignment: .leading) {
        Group {
          if clamped >= 1 {
            Capsule().fill(colors.statusSuccess)
          } else {
            Capsule().fill(progressFill)
          }
        }
        .frame(height: Self.barHeight)
        .scaleEffect(x: CGFloat(clamped), anchor: .leading)
        .animation(.linear(duration: WDMotion.Duration.base), value: clamped)
      }
      .clipShape(Capsule())
      .frame(minWidth: 100)  // wd-structure-check:disable R7 — 设计 15 §3 的最小宽
  }

  private var indeterminateBar: some View {
    HStack(spacing: 0) {
      if indeterminatePhase { Spacer(minLength: 0) }
      Capsule()
        .fill(progressFill)
        .frame(height: Self.barHeight)
        .containerRelativeFrame(.horizontal) { length, _ in length * Self.indeterminateWidthRatio }
      if !indeterminatePhase { Spacer(minLength: 0) }
    }
    .frame(minHeight: Self.barHeight)
    .background(Capsule().fill(colors.surfaceTint))
    .clipShape(Capsule())
    .animation(
      .easeInOut(duration: Self.indeterminateCycle).repeatForever(autoreverses: true),
      value: indeterminatePhase
    )
    .onAppear { indeterminatePhase = true }
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

  private var determinateValue: Double? {
    if case .determinate(let value) = mode { return value }
    return nil
  }
}

/// 进度条的无障碍值（确定态给百分比；不确定态不给 valuenow）。
private struct WDProgressBarAccessibility: ViewModifier {
  let label: Text?
  let valueText: Text?
  let mode: WDProgressBar.Mode

  func body(content: Content) -> some View {
    switch mode {
    case .determinate(let value):
      let pct = min(max(value, 0), 1).formatted(.percent.precision(.fractionLength(0)))
      let resolved = valueText ?? Text(verbatim: pct)  // wd-structure-check:disable R21 — a11y
      return
        content
        .accessibilityLabel(label ?? Text(verbatim: ""))  // wd-structure-check:disable R21 — a11y
        .accessibilityValue(resolved)
    case .indeterminate:
      return
        content
        .accessibilityLabel(label ?? Text(verbatim: ""))  // wd-structure-check:disable R21 — a11y
    }
  }
}
