import SwiftUI

/// 开关尺寸档（设计 05 §3：标准 51×31 / 紧凑 40×24）。
public enum WDSwitchSize: String, CaseIterable, Sendable, Equatable {
  case standard
  case compact
}

/// 开关（SPEC §2.10-#05；M2；B5 扩紧凑档/描述位）。
///
/// 设计口径（设计 05 §3–§5）：
/// - 标准轨道 51×31、滑块 27、行程 20；紧凑 40×24、滑块 20、行程 16；
/// - 关 = border.hairline-strong 描边 + 白滑块；开 = gradient.mid；切换轻触觉 ×1；
/// - 角色 = switch（由真 Toggle 提供），状态由系统朗读（库内零"开/关"文案）；
/// - 描述位在标签下方一行 footnote / text.secondary。
public struct WDSwitch: View {
  @Binding private var isOn: Bool
  private let label: Text
  private let description: Text?
  private let size: WDSwitchSize

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled

  /// 构造（既有；标准档、无描述）。
  public init(isOn: Binding<Bool>, label: Text) {
    self._isOn = isOn
    self.label = label
    self.description = nil
    self.size = .standard
  }

  /// 构造（B5 增量；紧凑/标准 + 可选描述）。
  public init(
    isOn: Binding<Bool>, label: Text, description: Text?, size: WDSwitchSize
  ) {
    self._isOn = isOn
    self.label = label
    self.description = description
    self.size = size
  }

  /// 标签（+ 描述）+ 轨道；整行可点（含标签区域）。
  public var body: some View {
    Toggle(isOn: $isOn) {
      VStack(alignment: .leading, spacing: WDSpacing.s1) {
        label
          .wdFont(WDType.body)
          .wdLineBox(WDType.body)
        if let description {
          description
            .wdFont(WDType.footnote)
            .wdLineBox(WDType.footnote)
            .foregroundStyle(colors.textSecondary)
        }
      }
    }
    .toggleStyle(WDSwitchToggleStyle(size: size))
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 几何（设计 05 §3；令牌无这些值；内部暴露给单测做自洽断言）。
  enum Metrics {
    /// 标准档轨道宽。
    static let trackWidth: CGFloat = 51  // wd-structure-check:disable R7 — 设计值
    /// 标准档轨道高。
    static let trackHeight: CGFloat = 31  // wd-structure-check:disable R7 — 设计值
    /// 滑块直径（轨道高 − 4）。
    static let knobDiameter: CGFloat = 27  // wd-structure-check:disable R7 — 设计值
    /// 滑块行程（轨道宽 − 滑块 − 两侧内边距）。
    static let knobTravel: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
    /// 滑块与轨道的上下左右内边距（设计「各留 2」）。
    static let knobInset: CGFloat = 2  // wd-structure-check:disable R7 — 设计值

    /// 紧凑档轨道宽 40。
    static let compactTrackWidth: CGFloat = 40  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档轨道高 24。
    static let compactTrackHeight: CGFloat = 24  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档滑块 20。
    static let compactKnobDiameter: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档行程 16。
    static let compactKnobTravel: CGFloat = 16  // wd-structure-check:disable R7 — 设计值

    /// 档位几何。
    struct SizeMetrics {
      let trackWidth: CGFloat
      let trackHeight: CGFloat
      let knobDiameter: CGFloat
      let knobTravel: CGFloat
      let knobInset: CGFloat
    }

    /// 取档位几何。
    static func metrics(for size: WDSwitchSize) -> SizeMetrics {
      switch size {
      case .standard:
        return SizeMetrics(
          trackWidth: trackWidth, trackHeight: trackHeight, knobDiameter: knobDiameter,
          knobTravel: knobTravel, knobInset: knobInset)
      case .compact:
        return SizeMetrics(
          trackWidth: compactTrackWidth, trackHeight: compactTrackHeight,
          knobDiameter: compactKnobDiameter, knobTravel: compactKnobTravel, knobInset: knobInset)
      }
    }
  }

  /// 禁用态整体不透明度（state.disabled.alpha = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母
}

/// 自定义开关外观：真 Toggle 的样式（角色/状态由 Toggle 提供，库内不写"开/关"文案）。
private struct WDSwitchToggleStyle: ToggleStyle {
  let size: WDSwitchSize

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled

  private var metrics: WDSwitch.Metrics.SizeMetrics {
    WDSwitch.Metrics.metrics(for: size)
  }

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: WDSpacing.s4) {
      configuration.label
        .foregroundStyle(colors.textPrimary)
      Spacer(minLength: 0)
      track(configuration)
    }
    .frame(minHeight: WDSize.touchTargetMin)
    .contentShape(Rectangle())
    .onTapGesture {
      guard isEnabled else { return }
      configuration.isOn.toggle()
      WDHaptics.shared.play(.toggle, budget: budget)
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder private func track(_ configuration: Configuration) -> some View {
    let shape = Capsule()
    ZStack(alignment: .leading) {
      if configuration.isOn {
        shape
          .fill(WDGradient.mid.linearGradient)
          .animation(.linear(duration: WDMotion.Duration.base), value: configuration.isOn)
      } else {
        shape
          .fill(Color.clear)
          .overlay(shape.stroke(colors.borderHairlineStrong, lineWidth: 1))
      }
      Circle()
        .fill(colors.textOnDark)
        .frame(width: metrics.knobDiameter, height: metrics.knobDiameter)
        .padding(.leading, metrics.knobInset)
        .offset(x: configuration.isOn ? metrics.knobTravel : 0)
        .animation(WDMotion.Spring.gentle, value: configuration.isOn)
    }
    .frame(width: metrics.trackWidth, height: metrics.trackHeight)
  }
}
