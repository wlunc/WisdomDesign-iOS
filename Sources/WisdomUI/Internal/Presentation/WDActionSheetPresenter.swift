import SwiftUI
import UIKit

/// ActionSheet 的窗口级呈现：遮罩直接出现，只有面板从底部滑入/滑出。
@MainActor
final class WDActionSheetPresenter {
  static let shared = WDActionSheetPresenter()

  private var host: UIViewController?

  /// 立即呈现（无系统 modal 过渡；面板自己动画）。
  func present<V: View>(_ content: V) {
    dismiss()
    guard let presenter = topViewController() else {
      return
    }
    let controller = UIHostingController(rootView: content)
    controller.view.backgroundColor = .clear
    controller.modalPresentationStyle = .overFullScreen
    presenter.present(controller, animated: false)
    host = controller
  }

  /// 立即移除宿主（面板的滑出动画已由 WDActionSheetLayer 完成）。
  func dismiss() {
    host?.dismiss(animated: false)
    host = nil
  }

  private func topViewController() -> UIViewController? {
    guard
      let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }),
      let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
    else {
      return nil
    }
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}

/// 透明遮罩 + 底部面板；遮罩静态出现，面板单独滑入。
struct WDActionSheetLayer: View {
  let title: Text?
  let message: Text?
  let items: [WDActionSheetItem]
  let onSelect: (WDActionSheetItem.ID) -> Void
  let onCancel: (() -> Void)?

  @Environment(\.wdAppearance) private var appearance
  @State private var appeared = false

  private static let hiddenOffset: CGFloat = 800  // wd-structure-check:disable R7 — 面板初始在屏外

  var body: some View {
    ZStack(alignment: .bottom) {
      scrim
      WDActionSheetPanel(
        title: title,
        message: message,
        items: items,
        onSelect: { id in
          dismiss { onSelect(id) }
        },
        onCancel: {
          dismiss { onCancel?() }
        }
      )
      .frame(maxWidth: .infinity)
      .offset(y: appeared ? 0 : Self.hiddenOffset)
      .accessibilityAddTraits(.isModal)
    }
    .onAppear {
      WDA11yFocus.screenChanged()
      withAnimation(WDMotion.Spring.gentle) {
        appeared = true
      }
    }
  }

  /// 遮罩从第一帧就存在，不参与面板的滑入/滑出。
  private var scrim: some View {
    Color.black.opacity(
      appearance.colorScheme == .dark ? Self.scrimOpacityDark : Self.scrimOpacityLight
    )
    .ignoresSafeArea()
    .contentShape(Rectangle())
    .onTapGesture {
      dismiss { onCancel?() }
    }
  }

  private func dismiss(_ action: @escaping () -> Void) {
    withAnimation(.easeOut(duration: WDMotion.Duration.base)) {
      appeared = false
    } completion: {
      action()
    }
  }

  private static let scrimOpacityLight: CGFloat = 0.28  // wd-structure-check:disable R7 — 设计 27
  private static let scrimOpacityDark: CGFloat = 0.50  // wd-structure-check:disable R7 — 设计 27
}
