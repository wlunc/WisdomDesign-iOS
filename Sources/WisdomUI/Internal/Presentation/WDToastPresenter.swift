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
    let controller = UIHostingController(rootView: rootView)
    controller.view.backgroundColor = .clear
    controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light

    top.addChild(controller)
    top.view.addSubview(controller.view)
    controller.didMove(toParent: top)

    let bounds = top.view.bounds
    let size = controller.sizeThatFits(
      in: CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
    let height = max(size.height, WDSize.fieldHeight)
    let safeBottom = top.view.safeAreaInsets.bottom
    controller.view.frame = CGRect(
      x: 0,
      y: bounds.height - safeBottom - WDToastLayout.bottomInset - height,
      width: bounds.width,
      height: height
    )
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
