import SwiftUI

/// 滑杆（SPEC §2.10-#08；M5）。
///
/// 设计口径（设计 08）：
/// - 轨道高 6、手柄 26（白 + `elevation.1` + 1pt hairline）、圆角 `radius.full`、最小宽 120；
/// - 标签在轨道上方；拖动实时更新、**松手才算一次有效变更**（`onEditingChanged(false)`）；
/// - 松手触发一次轻触觉；读屏走系统 `slider` 角色（value/min/max 由原生控件提供）。
///
/// 载体说明（`docs/M5-SIGNATURE-FREEZE.md` Q1）：本轮用**原生 `Slider`**（系统手势/读屏合规；
/// 自造 `DragGesture` 被 SPEC §3.4 禁止）。轨道 6 / 手柄 26 / 刻度标签 / 拖拽放大等自绘视觉
/// 差异登记在 `docs/M5-EXIT-REPORT.md`；签名与载体解耦，后续自绘替换不改公开面。
public struct WDSlider: View {
  @Binding private var value: Double
  private let label: Text
  private let bounds: ClosedRange<Double>
  private let step: Double?
  private let onEditingChanged: ((Bool) -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：受控值 + 标签 + 范围 + 可选步长。
  public init(
    value: Binding<Double>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil
  ) {
    self._value = value
    self.label = label
    self.bounds = bounds
    self.step = step
    self.onEditingChanged = onEditingChanged
  }

  /// 标签 + 轨道；松手时触发一次轻触觉并回调。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      label
        .wdFont(WDType.footnote)
        .wdLineBox(WDType.footnote)
        .foregroundStyle(colors.textSecondary)
      slider
    }
    .frame(minWidth: Self.minWidth, alignment: .leading)
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  @ViewBuilder private var slider: some View {
    if let step {
      Slider(value: $value, in: bounds, step: step, onEditingChanged: handleEditingChanged)
        .tint(colors.textBrand)
        .accessibilityLabel(label)
    } else {
      Slider(value: $value, in: bounds, onEditingChanged: handleEditingChanged)
        .tint(colors.textBrand)
        .accessibilityLabel(label)
    }
  }

  /// 松手（`false`）= 一次有效变更：轻触觉 ×1 + 调用方回调（设计 08 §8）。
  private func handleEditingChanged(_ isEditing: Bool) {
    guard isEnabled else { return }
    if !isEditing {
      WDHaptics.shared.play(.press, budget: budget)
    }
    onEditingChanged?(isEditing)
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 最小宽 120（设计 08 §3）。
  private static let minWidth: CGFloat = 120  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}
