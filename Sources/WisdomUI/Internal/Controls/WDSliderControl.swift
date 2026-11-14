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
  /// 1pt hairline（设计 08 §3 的手柄描边）。
  static let hairlineWidth: CGFloat = 1
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
  /// 拖动中 / 点击轨道时的实时回调。
  var onValueChange: (Double) -> Void
  /// 开始 / 结束拖拽。
  var onEditingChanged: (Bool) -> Void

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
    @objc func valueChanged(_ sender: UISlider) {
      parent.onValueChange(Double(sender.value))
    }

    /// 按下：进入拖拽视觉态。
    @objc func touchDown(_ sender: UISlider) {
      parent.onEditingChanged(true)
    }

    /// 松手：离散档位吸附 + 一次有效变更回调。
    @objc func touchUp(_ sender: UISlider) {
      let snapped = WDSliderSnapping.snap(
        Double(sender.value), in: parent.bounds, step: parent.step)
      sender.value = Float(snapped)
      parent.onValueChange(snapped)
      parent.onEditingChanged(false)
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
