import SwiftUI
import UIKit

/// 在 SwiftUI ScrollView 的底层 UIScrollView 上挂一个并行 pan：
/// 内容已在顶部且向下拖时，把位移交给 BottomSheet 面板；否则不干预滚动。
struct WDBottomSheetScrollProbe: UIViewRepresentable {
  let onPull: (CGFloat) -> Void
  let onEnd: (CGFloat, CGFloat) -> Void

  func makeUIView(context: Context) -> WDBottomSheetScrollProbeView {
    let view = WDBottomSheetScrollProbeView()
    view.onPull = onPull
    view.onEnd = onEnd
    return view
  }

  func updateUIView(_ uiView: WDBottomSheetScrollProbeView, context: Context) {
    uiView.onPull = onPull
    uiView.onEnd = onEnd
  }

  static func dismantleUIView(_ uiView: WDBottomSheetScrollProbeView, coordinator: ()) {
    uiView.uninstall()
  }
}

/// 零尺寸探针视图；在进入窗口后找到父级 UIScrollView 并安装手势。
@MainActor
final class WDBottomSheetScrollProbeView: UIView, UIGestureRecognizerDelegate {
  var onPull: ((CGFloat) -> Void)?
  var onEnd: ((CGFloat, CGFloat) -> Void)?

  private weak var scrollView: UIScrollView?
  private var pan: UIPanGestureRecognizer?

  override func didMoveToWindow() {
    super.didMoveToWindow()
    installIfNeeded()
    DispatchQueue.main.async { [weak self] in
      self?.installIfNeeded()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    installIfNeeded()
  }

  private func installIfNeeded() {
    guard pan == nil, let scrollView = enclosingScrollView() else {
      return
    }
    let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    recognizer.delegate = self
    recognizer.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(recognizer)
    scrollView.bounces = false
    self.scrollView = scrollView
    self.pan = recognizer
  }

  func uninstall() {
    if let pan, let scrollView {
      scrollView.removeGestureRecognizer(pan)
    }
    pan = nil
    scrollView = nil
  }

  private func enclosingScrollView() -> UIScrollView? {
    var view = superview
    while let current = view {
      if let scrollView = current as? UIScrollView {
        return scrollView
      }
      view = current.superview
    }
    return nil
  }

  @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
    guard let scrollView else {
      return
    }
    let translation = recognizer.translation(in: scrollView).y
    let top = -scrollView.adjustedContentInset.top
    let atTop = scrollView.contentOffset.y <= top + 1
    switch recognizer.state {
    case .changed:
      if atTop, translation > 0 {
        onPull?(translation)
      }
    case .ended, .cancelled:
      if atTop, translation > 0 {
        onEnd?(translation, recognizer.velocity(in: scrollView).y)
      }
    default:
      break
    }
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}
