import SwiftUI
import UIKit

/// Toast 窗口层布局常量（设计 28 §6/§9）。
enum WDToastLayout {
  /// 距安全区底部 16（space.5）。
  static let bottomInset: CGFloat = 16
  /// 出现时上移 12pt。
  static let enterOffset: CGFloat = 12
  /// 出现 320ms。
  static let enterDuration: TimeInterval = 0.32
  /// 消失 160ms。
  static let exitDuration: TimeInterval = 0.16

  /// 浮层在宿主容器坐标系里的 frame：满宽、水平居中、贴安全区底部。
  ///
  /// 旋转 / 分屏 / 安全区变化后由 `WDToastHostingController` 重算；抽成纯函数便于单测。
  ///
  /// - Parameters:
  ///   - bounds: 宿主容器（Top VC 的 view）当前 bounds；浮层与它同宽 ⇒ 水平天然居中。
  ///   - safeAreaBottom: 宿主容器当前的安全区底部（Home Indicator / 分屏等）。
  ///   - contentHeight: `sizeThatFits` 量出的内容高；低于最小字段高时按 `WDSize.fieldHeight` 取。
  static func frame(
    in bounds: CGRect,
    safeAreaBottom: CGFloat,
    contentHeight: CGFloat
  ) -> CGRect {
    let height = max(contentHeight, WDSize.fieldHeight)
    return CGRect(
      x: bounds.minX,
      y: bounds.maxY - safeAreaBottom - bottomInset - height,
      width: bounds.width,
      height: height
    )
  }
}

/// 窗口层 Toast 的宿主控制器：父容器尺寸 / 安全区变化时重新计算自身 frame。
///
/// 只改自己的 bounds + center（不碰 alpha / transform），因此入场与退场动画、
/// 点击穿透都不受影响；也不重复 addSubview / 注册观察者，避免泄漏。
final class WDToastHostingController<Content: View>: UIHostingController<Content> {
  /// 按当前父容器重排（父容器不存在或尚未有宽度时无操作）。
  func layoutInParent() {
    guard let container = parent?.view else { return }
    let bounds = container.bounds
    guard bounds.width > 0 else { return }
    let size = sizeThatFits(in: CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
    let target = WDToastLayout.frame(
      in: bounds,
      safeAreaBottom: container.safeAreaInsets.bottom,
      contentHeight: size.height
    )
    let center = CGPoint(x: target.midX, y: target.midY)
    // 幂等：frame 没变就不写回，避免 layout 回环。
    guard view.bounds.size != target.size || view.center != center else { return }
    view.bounds = CGRect(origin: .zero, size: target.size)
    view.center = center
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layoutInParent()
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    layoutInParent()
  }

  override func viewWillTransition(
    to size: CGSize,
    with coordinator: any UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    // 旋转 / 分屏的 bounds 变化可能晚于本回调，动画结束后再兜一次最终几何。
    coordinator.animate(alongsideTransition: nil) { _ in
      self.layoutInParent()
    }
  }
}

/// 窗口层 Toast 呈现：把浮层挂到当前 Top VC 的 view 上，只占 Toast 自身尺寸。
///
/// 为什么不铺满全屏：非阻塞提示不应拦截页面其余区域的触摸。挂 Top VC 还避免了
/// ScrollView / 容器的裁切（设计 28 §11）。
@MainActor
final class WDToastPresenter {
  static let shared = WDToastPresenter()

  private var host: UIViewController?

  /// 呈现（已有实例先立即移除；连续触发由调用方重新 present 即完成替换与重置计时）。
  func present<V: View>(
    theme: WDTheme, colorScheme: ColorScheme, budget: WDEffectsBudget,
    @ViewBuilder content: () -> V
  ) {
    removeImmediately()
    guard
      let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }),
      let window = scene.windows.first(where: \.isKeyWindow),
      let root = window.rootViewController
    else {
      return
    }
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }

    let rootView = content()
      .environment(\.wdTheme, theme)
      .environment(\.wdEffectsBudget, budget)
      .padding(.horizontal, WDSpacing.s9)
    let controller = WDToastHostingController(rootView: rootView)
    controller.view.backgroundColor = .clear
    controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    // 宽度跟随容器 ⇒ 父容器 bounds 变化会触达宿主的 layout，从而重排（y / 高度在重排里算）。
    controller.view.autoresizingMask = [.flexibleWidth]

    top.addChild(controller)
    top.view.addSubview(controller.view)
    controller.didMove(toParent: top)
    controller.layoutInParent()

    controller.view.alpha = 0
    controller.view.transform = CGAffineTransform(translationX: 0, y: WDToastLayout.enterOffset)
    host = controller

    UIView.animate(
      withDuration: WDToastLayout.enterDuration,
      delay: 0,
      usingSpringWithDamping: 0.85,
      initialSpringVelocity: 0,
      options: [.allowUserInteraction]
    ) {
      controller.view.alpha = 1
      controller.view.transform = .identity
    }
  }

  /// 淡出 160ms 后移除。
  func dismiss() {
    guard let controller = host else { return }
    host = nil
    controller.view.isUserInteractionEnabled = false
    UIView.animate(withDuration: WDToastLayout.exitDuration) {
      controller.view.alpha = 0
    } completion: { _ in
      Self.remove(controller)
    }
  }

  /// 立即移除（不再播退场动画）。
  private func removeImmediately() {
    guard let controller = host else { return }
    host = nil
    Self.remove(controller)
  }

  private static func remove(_ controller: UIViewController) {
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
  }
}
