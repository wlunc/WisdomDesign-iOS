import SwiftUI

/// 滑杆（SPEC §2.10-#08；M5）。
///
/// 设计口径（设计 08）：
/// - 轨道高 6、手柄 26（白 + elevation.1 + 1pt hairline）、圆角 radius.full、最小宽 120；
/// - 标签在轨道上方；拖动实时更新、松手才算一次有效变更（onEditingChanged(false)）；
/// - 离散档位松手吸附；松手触发一次轻触觉；读屏走系统 slider 角色。
///
/// 载体说明（docs/M5-SIGNATURE-FREEZE.md Q1 的原决议 + 2026-11-14 自绘落地）：
/// 手势与读屏由 Internal 的 UISlider 载体提供（自造 DragGesture 被 SPEC §3.4 禁止），
/// 轨道 / 填充 / 手柄由本文件的 SwiftUI 覆盖层按设计 08 绘制；公开签名不变。
public struct WDSlider: View {
  @Binding private var value: Double
  private let label: Text
  private let bounds: ClosedRange<Double>
  private let step: Double?
  private let onEditingChanged: ((Bool) -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.layoutDirection) private var layoutDirection

  /// 轨道可用宽度（由 onGeometryChange 量得；首帧为 0）。
  @State private var trackWidth: CGFloat = 0
  /// 是否正在拖拽（手柄放大 1.15）。
  @State private var isEditing = false

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
      track
    }
    .frame(minWidth: WDSliderMetrics.minWidth, alignment: .leading)
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 轨道：透明 UISlider 负责手势，SwiftUI 覆盖层负责视觉。
  private var track: some View {
    ZStack(alignment: .leading) {
      WDSliderControl(
        value: value,
        bounds: bounds,
        step: step,
        isEnabled: isEnabled,
        layoutDirection: layoutDirection,
        onValueChange: { newValue in value = newValue },
        onEditingChanged: handleEditingChanged
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      trackBackground
      trackFill
      thumb
    }
    .frame(height: hotAreaHeight)
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { width in
      trackWidth = width
    }
    .accessibilityRepresentation { accessibilitySlider }
  }

  /// 未填充轨道（border.hairline-strong，6pt）。
  private var trackBackground: some View {
    Capsule()
      .fill(colors.borderHairlineStrong)
      .frame(width: usableWidth, height: WDSliderMetrics.trackHeight)
      .offset(x: WDSliderMetrics.trackInset)
      .allowsHitTesting(false)
  }

  /// 已填充段（gradient.mid，6pt）。
  private var trackFill: some View {
    Capsule()
      .fill(WDGradient.mid.linearGradient)
      .frame(width: usableWidth * fraction, height: WDSliderMetrics.trackHeight)
      .offset(x: fillOffset)
      .allowsHitTesting(false)
  }

  /// 手柄（白 + hairline + elevation.1；拖拽 1.15）。
  private var thumb: some View {
    Circle()
      .fill(.white)
      .overlay(
        Circle().strokeBorder(colors.borderHairline, lineWidth: WDSliderMetrics.hairlineWidth)
      )
      .frame(width: thumbDiameter, height: thumbDiameter)
      .wdShadow(WDElevation.e1)
      .scaleEffect(isEditing ? WDSliderMetrics.dragScale : 1)
      .offset(x: usableWidth * fraction)
      .animation(.easeOut(duration: WDSliderMetrics.visualDuration), value: isEditing)
      .allowsHitTesting(false)
  }

  /// 读屏语义：借原生 Slider 提供 slider 角色、当前值、可调整手势（同 WDProgressBar 口径）。
  @ViewBuilder private var accessibilitySlider: some View {
    if let step {
      Slider(value: $value, in: bounds, step: step)
        .accessibilityLabel(label)
    } else {
      Slider(value: $value, in: bounds)
        .accessibilityLabel(label)
    }
  }

  /// 松手（false）= 一次有效变更：轻触觉 x1 + 调用方回调（设计 08 §8）。
  private func handleEditingChanged(_ editing: Bool) {
    isEditing = editing
    guard isEnabled else { return }
    if !editing {
      WDHaptics.shared.play(.press, budget: budget)
    }
    onEditingChanged?(editing)
  }

  /// 轨道可用宽度（两端各内缩手柄半径）。
  private var usableWidth: CGFloat {
    max(trackWidth - WDSliderMetrics.thumbDiameter, 0)
  }

  /// 当前值在轨道上的比例（0…1）。
  private var fraction: CGFloat {
    let span = bounds.upperBound - bounds.lowerBound
    guard span > 0 else { return 0 }
    let raw = (value - bounds.lowerBound) / span
    return CGFloat(min(max(raw, 0), 1))
  }

  /// 填充段起点：轨道左端（RTL 由 SwiftUI 的 leading 对齐自动镜像）。
  private var fillOffset: CGFloat { WDSliderMetrics.trackInset }

  /// 热区高度 = WDSize.touchTargetMin（44；轨道视觉 6，上下各扩 19）。
  private var hotAreaHeight: CGFloat { WDSize.touchTargetMin }

  /// 手柄直径 26。
  private var thumbDiameter: CGFloat { WDSliderMetrics.thumbDiameter }

  /// 禁用态整体不透明度（设计 08 §5 的 45%，不是 WDState 的通用 40%）。
  private var disabledOpacity: CGFloat { WDSliderMetrics.disabledOpacity }
}
