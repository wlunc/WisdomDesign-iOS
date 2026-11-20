import SwiftUI
import UIKit

/// 滑杆的尺寸与视觉常量（设计 08；Internal 层不受 R7 数值字面量限制）。
enum WDSliderMetrics {
  /// 轨道高 6（设计 08 §3）。
  static let trackHeight: CGFloat = 6
  /// 手柄直径 26（设计 08 §3）。
  static let thumbDiameter: CGFloat = 26
  /// 手柄半径；轨道两端各留 13（设计 08 §3）。
  static let trackInset: CGFloat = 13
  /// 最小宽 120（设计 08 §3）。
  static let minWidth: CGFloat = 120
  /// 拖拽时手柄放大到 1.15（设计 08 §5）。
  static let dragScale: CGFloat = 1.15
  /// 禁用态整体 45%（设计 08 §5；不同于 WDState 的通用 40%）。
  static let disabledOpacity: CGFloat = 0.45
  /// 手柄放大与数值更新 100ms（设计 08 §9）。
  static let visualDuration: TimeInterval = 0.10
  /// 点击轨道跳转 200ms（设计 08 §9）。
  static let tapDuration: TimeInterval = 0.20
  /// 端点判定容差。
  static let edgeEpsilon: Double = 0.0001
  /// 1pt hairline（设计 08 §3 的手柄描边）。
  static let hairlineWidth: CGFloat = 1
  /// 数值标签与标签行的基线对齐（设计 08 §6：两者同一行、值在右）。
  static let valueLabelSpacing: CGFloat = WDSpacing.s3
  /// 手柄聚焦光环宽度（= `state.focus.ring-width` 3pt；设计 08 §5「手柄外扩 3pt 光环」）。
  static let focusRingWidth: CGFloat = WDState.focusRingWidth
  /// 聚焦光环淡入 160ms（设计 08 §5/§9；= `motion.duration.fast`）。
  static let focusRingFadeDuration: TimeInterval = WDMotion.Duration.fast

  /// 数值标签的可读宽度（设计 08 §6：值在标签行右侧、等宽数字）。
  ///
  /// 取值 = 内容宽上限的 30%，并夹在 [96, 240]：
  ///   · 下限 96 放得下 4 位等宽数字 + 小数（AX3 下约为默认档的 1.9 倍字宽仍可容纳）；
  ///   · 上限 240 让超长 `valueText`（调用方注入的档位名一类）不把标签挤成多行。
  static func valueLabelWidth(available: CGFloat) -> CGFloat {
    min(max(available * 0.30, 96), 240)  // 设计 08 §6 未给值：按"值占标签行右侧约三成"取
  }

  /// 手柄聚焦光环的外扩半径（设计 08 §5）。
  ///
  /// 光环 = 手柄外扩 **3pt**：从可见手柄边缘再向外 3pt，所以半径 = 13 + 3 = 16。
  /// 只有「聚焦且可用」时才画（U6：disabled 吞掉一切状态视觉；设计 08 §5 禁用态无光环）。
  static func focusRingRadius(isFocused: Bool, isEnabled: Bool) -> CGFloat {
    guard isFocused, isEnabled else { return 0 }
    return thumbDiameter / 2 + focusRingWidth
  }

  /// 光环淡入动画：Reduce Motion 直出（nil = 不加动画），否则 160ms 淡入。
  static func focusRingAnimation(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : .easeOut(duration: focusRingFadeDuration)
  }

  /// 是否呈现聚焦光环（与半径同源，保证圆环与显示/隐藏同步）。
  static func showsFocusRing(isFocused: Bool, isEnabled: Bool) -> Bool {
    focusRingRadius(isFocused: isFocused, isEnabled: isEnabled) > 0
  }

  /// 聚焦光环的直径（半径 × 2；不呈现时为 0 = 不画这一层）。
  static func focusRingDiameter(isFocused: Bool, isEnabled: Bool) -> CGFloat {
    focusRingRadius(isFocused: isFocused, isEnabled: isEnabled) * 2
  }

  /// 聚焦光环左上角相对热区左上角的偏移（光环与手柄同心：中心 = 手柄中心，竖直 = 热区中线）。
  ///
  /// 不呈现时返回 `.zero`（此时直径也是 0，调用方不会画）。
  static func focusRingOrigin(
    thumbCenterX: CGFloat, hotAreaHeight: CGFloat, isFocused: Bool, isEnabled: Bool
  ) -> CGSize {
    let radius = focusRingRadius(isFocused: isFocused, isEnabled: isEnabled)
    guard radius > 0 else { return .zero }
    return CGSize(width: thumbCenterX - radius, height: hotAreaHeight / 2 - radius)
  }

  /// 焦点环颜色透明度：`state.focus.ring-alpha` 32（百分数，令牌给 0–100）。
  static var focusRingAlpha: CGFloat {
    WDState.focusRingAlpha / percentScale
  }

  /// 百分数换算的分母（令牌里的 brightness/alpha 都是 0–100）。
  static let percentScale: CGFloat = 100

  /// 没注入 `valueText` 时的值文案格式：系统 Double 本地化（**不拼单位/百分号**）。
  ///
  /// 固定成 `Double` 而不是交给泛型推导：`Int` 值（如 0…4 的档位）会保留小数位，
  /// 拖动时宽度不跳；小数位上限 4 防止浮点尾数在拖动中抖动。
  static let valueFormat = FloatingPointFormatStyle<Double>.number
    .precision(.fractionLength(0...4))
}

/// 点击轨道的位置换算（与覆盖层的 13pt 内缩、RTL 镜像保持一致）。
enum WDSliderTapMapping {
  /// 触点 x（控件坐标）→ 目标值；宽度不足时返回 nil。
  static func value(
    atX x: CGFloat, width: CGFloat, in bounds: ClosedRange<Double>, step: Double?, isRTL: Bool
  ) -> Double? {
    let usable = width - WDSliderMetrics.thumbDiameter
    guard usable > 0 else { return nil }
    var local = x - WDSliderMetrics.trackInset
    if isRTL {
      local = usable - local
    }
    let fraction = min(max(local / usable, 0), 1)
    let span = bounds.upperBound - bounds.lowerBound
    let raw = bounds.lowerBound + Double(fraction) * span
    return WDSliderSnapping.snap(raw, in: bounds, step: step)
  }
}

/// 步长吸附（设计 08 §4：离散档位松手吸附；不改变连续拖拽时的实时值）。
enum WDSliderSnapping {
  /// 把值吸附到最近的 step 刻度（step 为 nil 或非正数时原样返回）。
  static func snap(_ value: Double, in bounds: ClosedRange<Double>, step: Double?) -> Double {
    let clamped = min(max(value, bounds.lowerBound), bounds.upperBound)
    guard let step, step > 0 else { return clamped }
    let steps = ((clamped - bounds.lowerBound) / step).rounded()
    let snapped = bounds.lowerBound + steps * step
    return min(max(snapped, bounds.lowerBound), bounds.upperBound)
  }
}

/// UIKit 载体（设计 08；Internal 允许 import UIKit）。
///
/// 为什么用 UISlider 而不是自造 DragGesture：SPEC §3.4 禁止 DragGesture(minimumDistance: 0)；
/// UISlider 提供系统拖拽 / 点击跳转 / 键盘方向键 / 读屏可调整语义。视觉完全由
/// WDSlider 的 SwiftUI 覆盖层绘制，因此把轨道与手柄都设为透明，只借它的手势与命中区域。
struct WDSliderControl: UIViewRepresentable {
  /// 当前值。
  var value: Double
  /// 取值范围。
  var bounds: ClosedRange<Double>
  /// 可选步长。
  var step: Double?
  /// 是否可用。
  var isEnabled: Bool
  /// 布局方向（RTL 时反转轨道）。
  var layoutDirection: LayoutDirection
  /// 拖动中的实时回调。
  var onValueChange: (Double) -> Void
  /// 点击轨道：目标值（由 WDSlider 做 200ms 过渡）。
  var onTapValue: (Double) -> Void
  /// 开始 / 结束（带当前值，供端点触觉判断）。
  var onEditingChanged: (Bool, Double) -> Void

  /// 协调器：把 UIControl 事件转回 SwiftUI。
  final class Coordinator: NSObject {
    /// 父级快照（updateUIView 时刷新，保证闭包不陈旧）。
    var parent: WDSliderControl
    /// 弱引用宿主，便于触点结束时吸附步长。
    weak var slider: UISlider?

    init(_ parent: WDSliderControl) {
      self.parent = parent
    }

    /// 拖动中的值变化。
    @MainActor @objc func valueChanged(_ sender: UISlider) {
      parent.onValueChange(Double(sender.value))
    }

    /// 按下：进入拖拽视觉态。
    @MainActor @objc func touchDown(_ sender: UISlider) {
      parent.onEditingChanged(true, Double(sender.value))
    }

    /// 松手：离散档位吸附 + 一次有效变更回调。
    @MainActor @objc func touchUp(_ sender: UISlider) {
      let snapped = WDSliderSnapping.snap(
        Double(sender.value), in: parent.bounds, step: parent.step)
      sender.value = Float(snapped)
      parent.onValueChange(snapped)
      parent.onEditingChanged(false, snapped)
    }

    /// 点击轨道：按触点位置换算目标值（与覆盖层的 13pt 内缩一致；RTL 反向）。
    @MainActor @objc func tapped(_ recognizer: UITapGestureRecognizer) {
      guard let slider = recognizer.view as? UISlider, slider.isEnabled else { return }
      guard
        let target = WDSliderTapMapping.value(
          atX: recognizer.location(in: slider).x,
          width: slider.bounds.width,
          in: parent.bounds,
          step: parent.step,
          isRTL: slider.effectiveUserInterfaceLayoutDirection == .rightToLeft
        )
      else { return }
      parent.onEditingChanged(true, Double(slider.value))
      parent.onTapValue(target)
      parent.onEditingChanged(false, target)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider()
    slider.minimumTrackTintColor = .clear
    slider.maximumTrackTintColor = .clear
    slider.setMinimumTrackImage(Self.transparentTrackImage, for: .normal)
    slider.setMaximumTrackImage(Self.transparentTrackImage, for: .normal)
    for state: UIControl.State in [.normal, .highlighted, .disabled] {
      slider.setThumbImage(Self.transparentThumbImage, for: state)
    }
    slider.isContinuous = true
    slider.isAccessibilityElement = false
    let tap = UITapGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
    tap.cancelsTouchesInView = true
    slider.addGestureRecognizer(tap)
    slider.addTarget(
      context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
    slider.addTarget(
      context.coordinator, action: #selector(Coordinator.touchDown(_:)),
      for: [.touchDown, .touchDragEnter])
    slider.addTarget(
      context.coordinator, action: #selector(Coordinator.touchUp(_:)),
      for: [.touchUpInside, .touchUpOutside, .touchCancel])
    context.coordinator.slider = slider
    return slider
  }

  func updateUIView(_ uiView: UISlider, context: Context) {
    context.coordinator.parent = self
    context.coordinator.slider = uiView
    uiView.minimumValue = Float(bounds.lowerBound)
    uiView.maximumValue = Float(bounds.upperBound)
    uiView.isEnabled = isEnabled
    uiView.semanticContentAttribute =
      layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
    let clamped = min(max(value, bounds.lowerBound), bounds.upperBound)
    if abs(Double(uiView.value) - clamped) > Self.valueEpsilon {
      uiView.value = Float(clamped)
    }
  }

  /// 透明手柄：保留 26pt 命中区，视觉由 SwiftUI 覆盖层画。
  private static let transparentThumbImage: UIImage = {
    let size = CGSize(width: WDSliderMetrics.thumbDiameter, height: WDSliderMetrics.thumbDiameter)
    return UIGraphicsImageRenderer(size: size).image { _ in }
  }()

  /// 透明轨道：隐藏系统轨道，避免与覆盖层叠出第二层。
  private static let transparentTrackImage: UIImage = {
    let size = CGSize(width: 1, height: WDSliderMetrics.trackHeight)
    return UIGraphicsImageRenderer(size: size).image { _ in }
      .resizableImage(withCapInsets: .zero, resizingMode: .stretch)
  }()

  /// 浮点比较容差。
  private static let valueEpsilon = 0.0001
}
