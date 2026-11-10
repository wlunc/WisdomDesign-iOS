import SwiftUI

/// 开关（SPEC §2.10-#05；M2）。
///
/// 设计口径（设计 05 §3–§5）：轨道 **51×31**、滑块 **27**（轨道高 − 4）、行程 **20**；
/// 关 = `border.hairline-strong` 描边 + 白滑块；开 = `gradient.mid`；切换轻触觉 ×1；
/// 角色 = switch（由真 `Toggle` 提供），状态由系统朗读（库内零"开/关"文案）。
///
/// 冻结签名只有 `isOn` + `label`（无紧凑档/描述位/受控尺寸参数）⇒ 只做标准档；
/// 紧凑档 40×24 与"带描述"形态不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3。
public struct WDSwitch: View {
  @Binding private var isOn: Bool
  private let label: Text

  @Environment(\.isEnabled) private var isEnabled

  /// 构造（受控值 `isOn`；槽位 `label`）。
  public init(isOn: Binding<Bool>, label: Text) {
    self._isOn = isOn
    self.label = label
  }

  /// 标签 + 轨道；整行可点（含标签区域）。
  public var body: some View {
    Toggle(isOn: $isOn) {
      label
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
    }
    .toggleStyle(WDSwitchToggleStyle())
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 标准档几何（设计 05 §3；令牌无这些值；内部暴露给单测做自洽断言）。
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
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母
}

/// 自定义开关外观：真 `Toggle` 的样式（角色/状态由 Toggle 提供，库内不写"开/关"文案）。
private struct WDSwitchToggleStyle: ToggleStyle {
  private typealias Metrics = WDSwitch.Metrics

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled

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
        .frame(width: Metrics.knobDiameter, height: Metrics.knobDiameter)
        .padding(.leading, Metrics.knobInset)
        .offset(x: configuration.isOn ? Metrics.knobTravel : 0)
        .animation(WDMotion.Spring.gentle, value: configuration.isOn)
    }
    .frame(width: Metrics.trackWidth, height: Metrics.trackHeight)
  }
}
