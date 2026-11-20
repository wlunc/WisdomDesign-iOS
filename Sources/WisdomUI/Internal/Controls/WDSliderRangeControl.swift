import SwiftUI
import UIKit

/// 范围滑杆的区间约束（Internal；纯函数，便于单测）。
enum WDSliderRangeMath {
  /// 最小间隔：设计 08 §4「最小间隔 = 1 步长」；连续档（step = nil）允许两端重合。
  static func minimumGap(step: Double?) -> Double {
    max(step ?? 0, 0)
  }

  /// 下端点：夹在 [bounds.lower, upper − gap]。
  static func clampedLower(
    _ proposed: Double, upper: Double, in bounds: ClosedRange<Double>, gap: Double
  ) -> Double {
    min(max(proposed, bounds.lowerBound), upper - gap)
  }

  /// 上端点：夹在 [lower + gap, bounds.upper]。
  static func clampedUpper(
    _ proposed: Double, lower: Double, in bounds: ClosedRange<Double>, gap: Double
  ) -> Double {
    max(min(proposed, bounds.upperBound), lower + gap)
  }

  /// 松手吸附：两端各自吸到步长刻度，再补一次间隔约束（吸到同一点时按活动手柄让位）。
  static func snapped(
    lower: Double, upper: Double, in bounds: ClosedRange<Double>, step: Double?, activeThumb: Int
  ) -> ClosedRange<Double> {
    let gap = minimumGap(step: step)
    var lo = WDSliderSnapping.snap(lower, in: bounds, step: step)
    var hi = WDSliderSnapping.snap(upper, in: bounds, step: step)
    if hi - lo < gap {
      if activeThumb == 0 {
        hi = min(lo + gap, bounds.upperBound)
        lo = min(lo, hi - gap)
      } else {
        lo = max(hi - gap, bounds.lowerBound)
        hi = max(hi, lo + gap)
      }
    }
    return lo...max(lo, hi)
  }
}

/// 范围滑杆的 UIKit 载体（Internal 允许 import UIKit）。
///
/// 为什么不叠两个 UISlider：两个全宽 UISlider 会互相拦截触摸，且无法表达"两端不交叉"。
/// 这里用 UIControl 的 tracking 回路（系统提供的触摸跟踪，不是自造 SwiftUI DragGesture），
/// 只负责命中判定与值换算；视觉与读屏语义分别在 WDSlider 的覆盖层与 accessibilityRepresentation。
struct WDSliderRangeControl: UIViewRepresentable {
  var lower: Double
  var upper: Double
  var bounds: ClosedRange<Double>
  var step: Double?
  var isEnabled: Bool
  var layoutDirection: LayoutDirection
  var onRangeChange: (Double, Double) -> Void
  var onTapThumb: (Int, Double) -> Void
  var onEditingChanged: (Bool, ClosedRange<Double>) -> Void
  var onActiveThumbChange: (Int?) -> Void

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeUIView(context: Context) -> WDSliderRangeUIControl {
    let control = WDSliderRangeUIControl()
    control.isAccessibilityElement = false
    control.onRangeChange = { [weak coordinator = context.coordinator] lo, hi in
      coordinator?.parent.onRangeChange(lo, hi)
    }
    control.onTapThumb = { [weak coordinator = context.coordinator] thumb, value in
      coordinator?.parent.onTapThumb(thumb, value)
    }
    control.onEditingChanged = { [weak coordinator = context.coordinator] editing, range in
      coordinator?.parent.onEditingChanged(editing, range)
    }
    control.onActiveThumbChange = { [weak coordinator = context.coordinator] thumb in
      coordinator?.parent.onActiveThumbChange(thumb)
    }
    context.coordinator.control = control
    return control
  }

  func updateUIView(_ uiView: WDSliderRangeUIControl, context: Context) {
    context.coordinator.parent = self
    uiView.apply(
      lower: lower, upper: upper, bounds: bounds, step: step, isEnabled: isEnabled,
      isRTL: layoutDirection == .rightToLeft)
  }

  final class Coordinator {
    var parent: WDSliderRangeControl
    weak var control: WDSliderRangeUIControl?

    init(_ parent: WDSliderRangeControl) {
      self.parent = parent
    }
  }
}

/// 双手柄 UIControl：命中最近手柄 → 拖动；离两个手柄都远时按"点轨道"处理（交给 SwiftUI 做 200ms 过渡）。
final class WDSliderRangeUIControl: UIControl {
  var onRangeChange: ((Double, Double) -> Void)?
  var onTapThumb: ((Int, Double) -> Void)?
  var onEditingChanged: ((Bool, ClosedRange<Double>) -> Void)?
  var onActiveThumbChange: ((Int?) -> Void)?

  private(set) var lowerValue: Double = 0
  private(set) var upperValue: Double = 1
  private var valueBounds: ClosedRange<Double> = 0...1
  private var step: Double?
  private var isRTL = false
  private var activeThumb: Int?
  /// 本次是"点轨道"而非"拖手柄"：不进入拖动，抬手只发一次结束回调。
  private var isTap = false

  /// 与 WDSlider 覆盖层一致的几何：手柄直径 26、两端各内缩 13。
  private var inset: CGFloat { WDSliderMetrics.trackInset }
  private var thumbDiameter: CGFloat { WDSliderMetrics.thumbDiameter }
  /// 手柄命中半径 = 44 热区的一半（手柄 26 之外仍可抓到）。
  private var thumbHitRadius: CGFloat { WDSize.touchTargetMin / 2 }

  func apply(
    lower: Double, upper: Double, bounds: ClosedRange<Double>, step: Double?, isEnabled: Bool,
    isRTL: Bool
  ) {
    self.isRTL = isRTL
    valueBounds = bounds
    self.step = step
    self.isEnabled = isEnabled
    // 拖动中不要被外部回写打断（只在没有活动手柄时同步）。
    guard activeThumb == nil, !isTap else { return }
    lowerValue = min(max(lower, bounds.lowerBound), bounds.upperBound)
    upperValue = max(min(upper, bounds.upperBound), lowerValue)
  }

  // MARK: - 触摸跟踪

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    guard isEnabled else { return false }
    let x = touch.location(in: self).x
    let lowerX = position(of: lowerValue)
    let upperX = position(of: upperValue)
    let distanceToLower = abs(x - lowerX)
    let distanceToUpper = abs(x - upperX)
    let nearest = distanceToLower <= distanceToUpper ? 0 : 1
    let nearestDistance = min(distanceToLower, distanceToUpper)

    if nearestDistance > thumbHitRadius {
      // 点轨道：最近的手柄跳过去（200ms 过渡由 SwiftUI 侧做）。
      isTap = true
      activeThumb = nil
      onEditingChanged?(true, currentRange)
      onTapThumb?(nearest, snapped(value(atX: x)))
      return true
    }

    isTap = false
    activeThumb = nearest
    onActiveThumbChange?(nearest)
    onEditingChanged?(true, currentRange)
    return true
  }

  override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    guard let thumb = activeThumb, !isTap else { return true }
    let raw = value(atX: touch.location(in: self).x)
    let gap = WDSliderRangeMath.minimumGap(step: step)
    if thumb == 0 {
      lowerValue = WDSliderRangeMath.clampedLower(
        raw, upper: upperValue, in: valueBounds, gap: gap)
    } else {
      upperValue = WDSliderRangeMath.clampedUpper(
        raw, lower: lowerValue, in: valueBounds, gap: gap)
    }
    onRangeChange?(lowerValue, upperValue)
    return true
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    finishTracking()
  }

  override func cancelTracking(with event: UIEvent?) {
    finishTracking()
  }

  private func finishTracking() {
    defer {
      activeThumb = nil
      isTap = false
      onActiveThumbChange?(nil)
    }
    guard !isTap else {
      onEditingChanged?(false, currentRange)
      return
    }
    guard activeThumb != nil else {
      onEditingChanged?(false, currentRange)
      return
    }
    let snappedRange = WDSliderRangeMath.snapped(
      lower: lowerValue, upper: upperValue, in: valueBounds, step: step,
      activeThumb: activeThumb ?? 0)
    lowerValue = snappedRange.lowerBound
    upperValue = snappedRange.upperBound
    onRangeChange?(lowerValue, upperValue)
    onEditingChanged?(false, snappedRange)
  }

  // MARK: - 坐标换算

  private var usableWidth: CGFloat {
    max(bounds.width - thumbDiameter, 0)
  }

  private func fraction(of value: Double) -> CGFloat {
    let span = valueBounds.upperBound - valueBounds.lowerBound
    guard span > 0 else { return 0 }
    return CGFloat(min(max((value - valueBounds.lowerBound) / span, 0), 1))
  }

  /// 手柄中心 x（UIControl 坐标）。
  private func position(of value: Double) -> CGFloat {
    let f = fraction(of: value)
    let offset = usableWidth * (isRTL ? 1 - f : f)
    return inset + offset
  }

  private func value(atX x: CGFloat) -> Double {
    guard usableWidth > 0 else { return valueBounds.lowerBound }
    var local = x - inset
    if isRTL { local = usableWidth - local }
    let f = min(max(local / usableWidth, 0), 1)
    let span = valueBounds.upperBound - valueBounds.lowerBound
    return valueBounds.lowerBound + Double(f) * span
  }

  private func snapped(_ value: Double) -> Double {
    WDSliderSnapping.snap(value, in: valueBounds, step: step)
  }

  private var currentRange: ClosedRange<Double> {
    min(lowerValue, upperValue)...max(lowerValue, upperValue)
  }
}
