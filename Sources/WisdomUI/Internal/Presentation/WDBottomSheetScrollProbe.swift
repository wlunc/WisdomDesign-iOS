import SwiftUI
import UIKit

/// 观察 SwiftUI ScrollView 底层 UIScrollView 的 pan：
/// 内容可滚动时只观察原有 pan（不新增手势，避免抢占内部滚动）；
/// 内容不可滚动时补一个并行 pan，让短内容也能从内容区下拉关闭面板。
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

/// 零尺寸探针；可滚动时观察，不可滚动时才安装手势。
@MainActor
final class WDBottomSheetScrollProbeView: UIView, UIGestureRecognizerDelegate {
  var onPull: ((CGFloat) -> Void)?
  var onEnd: ((CGFloat, CGFloat) -> Void)?

  private weak var scrollView: UIScrollView?
  private var pan: UIPanGestureRecognizer?
  private var observing = false

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
    guard let scrollView = enclosingScrollView() else {
      return
    }
    if self.scrollView !== scrollView {
      uninstall()
      self.scrollView = scrollView
    }
    scrollView.bounces = false
    let scrollable = scrollView.contentSize.height > scrollView.bounds.height + 1
    if scrollable {
      removeSeparatePan()
      if !observing {
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
        observing = true
      }
    } else {
      if observing {
        scrollView.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
        observing = false
      }
      installSeparatePanIfNeeded(on: scrollView)
    }
  }

  private func installSeparatePanIfNeeded(on scrollView: UIScrollView) {
    guard pan == nil else {
      return
    }
    let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    recognizer.delegate = self
    recognizer.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(recognizer)
    pan = recognizer
  }

  private func removeSeparatePan() {
    guard let pan, let scrollView else {
      return
    }
    scrollView.removeGestureRecognizer(pan)
    self.pan = nil
  }

  func uninstall() {
    if observing, let scrollView {
      scrollView.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
    }
    removeSeparatePan()
    observing = false
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
