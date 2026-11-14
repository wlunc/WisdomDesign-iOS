import SwiftUI
import UIKit

/// 菜单弹层的关闭请求通道：宿主（硬件键盘 Esc）与图层（淡出动画）共用同一个入口。
@MainActor
final class WDPickerMenuDismissChannel {
  var handler: (() -> Void)?

  func request() {
    handler?()
  }
}

/// 窗口级 Picker 菜单呈现：透明宿主 + 自绘浮层；系统 modal 过渡被禁用，动画由 layer 自己控制。
@MainActor
final class WDPickerMenuPresenter {
  static let shared = WDPickerMenuPresenter()

  private var host: UIViewController?
  private var previousFocus: Any?
  private var channel: WDPickerMenuDismissChannel?

  /// 立即呈现；content 拿到窗口尺寸、安全区与关闭通道。
  func present<V: View>(
    theme: WDTheme,
    colorScheme: ColorScheme,
    @ViewBuilder content: (CGSize, EdgeInsets, WDPickerMenuDismissChannel) -> V
  ) {
    dismiss()
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
    previousFocus = UIAccessibility.focusedElement(using: nil)
    let channel = WDPickerMenuDismissChannel()
    let insets = window.safeAreaInsets
    let safeArea = EdgeInsets(
      top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
    let themedRoot = content(window.bounds.size, safeArea, channel)
      .environment(\.wdTheme, theme)
    let controller = WDPickerMenuHostController(rootView: themedRoot)
    controller.onEscape = { [weak channel] in
      channel?.request()
    }
    controller.view.backgroundColor = .clear
    controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    controller.modalPresentationStyle = .overFullScreen
    top.present(controller, animated: false)
    host = controller
    self.channel = channel
  }

  /// 立即移除宿主（layer 的淡出动画已结束），并把焦点还给触发元素。
  func dismiss() {
    let hadHost = host != nil
    host?.dismiss(animated: false)
    host = nil
    channel = nil
    guard hadHost, let previousFocus else {
      return
    }
    self.previousFocus = nil
    DispatchQueue.main.async {
      UIAccessibility.post(notification: .layoutChanged, argument: previousFocus)
    }
  }
}

/// 宿主控制器：接住硬件键盘的 Esc（取消动作），转给图层做淡出。
private final class WDPickerMenuHostController<Content: View>: UIHostingController<Content> {
  var onEscape: (() -> Void)?

  override var keyCommands: [UIKeyCommand]? {
    [
      UIKeyCommand(
        input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleEscape))
    ]
  }

  @objc private func handleEscape() {
    onEscape?()
  }
}
