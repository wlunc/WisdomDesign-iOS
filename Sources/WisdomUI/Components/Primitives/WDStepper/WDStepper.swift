import SwiftUI

/// 步进器尺寸档（设计 09 §3）。
public enum WDStepperSize: String, CaseIterable, Sendable, Equatable {
  /// 标准档：容器高 36、按钮宽 40、字号 14（token 取 subheadline 15，差 1pt 登记）。
  case standard
  /// 紧凑档：容器高 30、按钮宽 32、字号 13。
  case compact
}

/// 步进器（SPEC §2.10-#09；M5）。
///
/// 设计口径（设计 09）：
/// - 标准 36 / 紧凑 30；按钮宽 40 / 32；圆角 `radius.full`；
/// - 容器 `surface.glass-strong` + `border.hairline`，符号 `text.brand`；
/// - 到下限减号禁用、到上限加号禁用，另一个仍可用；整体禁用 40%；
/// - 可调整控件（一个焦点，不是两个按钮）；长按连续步进先慢后快；**高频不给触觉**（只按下一次）。
///
/// 冻结签名只有 `value` + `label` + 范围/步长/档位/单位（无自定义格式化、无读屏模板）。
public struct WDStepper: View {
  @Binding private var value: Int
  private let label: Text
  private let bounds: ClosedRange<Int>
  private let step: Int
  private let size: WDStepperSize
  private let unit: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：受控值 + 读屏标签 + 范围 + 步长/档位/单位。
  public init(
    value: Binding<Int>,
    label: Text,
    in bounds: ClosedRange<Int>,
    step: Int = 1,
    size: WDStepperSize = .standard,
    unit: Text? = nil
  ) {
    self._value = value
    self.label = label
    self.bounds =
      bounds.lowerBound <= bounds.upperBound ? bounds : bounds.upperBound...bounds.upperBound
    self.step = max(1, step)
    self.size = size
    self.unit = unit
  }

  /// 减号 + 数值（+ 单位）+ 加号；整体是一个可调整控件（热区 ≥44）。
  public var body: some View {
    HStack(spacing: 0) {
      button(.decrement)
      valueView
      button(.increment)
    }
    .frame(minHeight: WDSize.touchTargetMin)
    .background(
      Capsule()
        .fill(colors.surfaceGlassStrong)
        .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
        .frame(height: visualHeight)
    )
    .opacity(isEnabled ? 1 : disabledOpacity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(Text(verbatim: "\(value)"))
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: adjust(by: step)
      case .decrement: adjust(by: -step)
      @unknown default: break
      }
    }
    .onAppear {
      assert(step >= 1, "WDStepper step 必须 ≥ 1")
    }
  }

  // MARK: - 零件

  private var valueView: some View {
    HStack(spacing: WDSpacing.s1) {
      Text(verbatim: "\(value)")
        .monospacedDigit()
        .foregroundStyle(colors.textPrimary)
      if let unit {
        unit
          .monospacedDigit()
          .foregroundStyle(colors.textSecondary)
      }
    }
    .wdFont(fontStyle)
    .wdLineBox(fontStyle)
    .frame(minWidth: Self.valueMinWidth)
    .animation(.easeOut(duration: WDMotion.Duration.instant), value: value)
  }

  private func button(_ direction: Direction) -> some View {
    StepButton(
      direction: direction,
      isEnabled: isEnabled && canAdjust(direction),
      fontStyle: fontStyle,
      visualWidth: buttonWidth,
      action: { adjust(by: direction.delta * step) }
    )
    .accessibilityHidden(true)
  }

  // MARK: - 状态

  enum Direction: Sendable, Equatable {
    case decrement
    case increment

    var delta: Int {
      switch self {
      case .decrement: return -1
      case .increment: return 1
      }
    }
  }

  private func canAdjust(_ direction: Direction) -> Bool {
    guard isEnabled else { return false }
    switch direction {
    case .decrement: return value > bounds.lowerBound
    case .increment: return value < bounds.upperBound
    }
  }

  private func adjust(by delta: Int) {
    guard isEnabled else { return }
    let next = min(max(value + delta, bounds.lowerBound), bounds.upperBound)
    guard next != value else { return }
    value = next
    WDHaptics.shared.play(.press, budget: budget)
  }

  // MARK: - 几何

  private var visualHeight: CGFloat {
    switch size {
    case .standard: return Self.standardHeight
    case .compact: return Self.compactHeight
    }
  }

  private var buttonWidth: CGFloat {
    switch size {
    case .standard: return Self.standardButtonWidth
    case .compact: return Self.compactButtonWidth
    }
  }

  private var fontStyle: WDTextStyle {
    switch size {
    case .standard: return WDType.subheadline  // 设计 14；令牌最近档 15（差 1pt，已登记）
    case .compact: return WDType.footnote  // 设计 13
    }
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 标准容器高 36（设计 09 §3）。
  private static let standardHeight: CGFloat = 36  // wd-structure-check:disable R7 — 设计值
  /// 紧凑容器高 30（设计 09 §3）。
  private static let compactHeight: CGFloat = 30  // wd-structure-check:disable R7 — 设计值
  /// 标准按钮宽 40（设计 09 §3）。
  private static let standardButtonWidth: CGFloat = 40  // wd-structure-check:disable R7 — 设计值
  /// 紧凑按钮宽 32（设计 09 §3）。
  private static let compactButtonWidth: CGFloat = 32  // wd-structure-check:disable R7 — 设计值
  /// 数值区最小宽 26（设计 09 §3）。
  private static let valueMinWidth: CGFloat = 26  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 步进按钮：按压外观 + 长按连续步进（先慢后快）；视觉宽 40/32、热区 44。
private struct StepButton: View {
  let direction: WDStepper.Direction
  let isEnabled: Bool
  let fontStyle: WDTextStyle
  let visualWidth: CGFloat
  let action: () -> Void

  @Environment(\.wdColors) private var colors
  @State private var isPressing = false

  var body: some View {
    Text(verbatim: direction == .decrement ? "−" : "+")
      .wdFont(fontStyle)
      .wdLineBox(fontStyle)
      .foregroundStyle(isEnabled ? colors.textBrand : colors.textDisabled)
      .frame(minWidth: max(visualWidth, WDSize.touchTargetMin), minHeight: WDSize.touchTargetMin)
      .background(
        Capsule()
          .fill(isPressing && isEnabled ? colors.fillPressed : Color.clear)
          .frame(width: visualWidth)
      )
      .contentShape(Rectangle())
      .onLongPressGesture(
        minimumDuration: Self.longPressDelay, maximumDistance: Self.maximumDistance
      ) {
        // 长按由 task 连续步进；perform 仅保持手势识别。
      } onPressingChanged: { pressing in
        guard isEnabled else { return }
        isPressing = pressing
        if pressing {
          action()  // 按下立即步进一次
        }
      }
      .task(id: isPressing) {
        guard isPressing, isEnabled else { return }
        try? await Task.sleep(for: .seconds(Self.longPressDelay))
        guard !Task.isCancelled else { return }
        var interval = Self.initialRepeatInterval
        while !Task.isCancelled && isPressing {
          action()
          try? await Task.sleep(for: .seconds(interval))
          interval = max(interval * Self.repeatAcceleration, Self.minimumRepeatInterval)
        }
      }
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: isPressing)
  }

  /// 长按触发时长 0.45s（设计「先慢后快」，具体节奏未给值，取可感知默认）。
  static let longPressDelay: Double = 0.45  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 首次连发间隔 0.2s。
  static let initialRepeatInterval: Double = 0.2  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 连发加速倍率。
  static let repeatAcceleration: Double = 0.75  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 最短连发间隔 0.06s。
  static let minimumRepeatInterval: Double = 0.06  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 长按手势允许的最大移动距离。
  static let maximumDistance: CGFloat = 12  // wd-structure-check:disable R7 — 手势容差
}
