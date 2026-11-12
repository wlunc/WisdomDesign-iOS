import Combine
import SwiftUI
import UIKit

/// 窗口级 BottomSheet 呈现：全宽贴边面板，系统 modal 过渡被禁用，动画由 layer 自己控制。
@MainActor
final class WDBottomSheetPresenter {
  static let shared = WDBottomSheetPresenter()

  private var host: UIViewController?

  /// 立即呈现；content 拿到窗口尺寸与底部安全区。
  func present<V: View>(@ViewBuilder content: (CGSize, CGFloat) -> V) {
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
    let controller = UIHostingController(
      rootView: content(window.bounds.size, window.safeAreaInsets.bottom))
    controller.view.backgroundColor = .clear
    controller.modalPresentationStyle = .overFullScreen
    top.present(controller, animated: false)
    host = controller
  }

  /// 立即移除宿主（layer 的滑出动画已结束）。
  func dismiss() {
    host?.dismiss(animated: false)
    host = nil
  }
}

/// 贴边面板 + 遮罩 + 把手拖拽/档位/键盘避让。
struct WDBottomSheetLayer<Content: View, Footer: View>: View {
  let title: Text?
  let closeButtonAccessibilityLabel: Text
  let detents: WDBottomSheetDetents
  let initialDetent: WDBottomSheetDetent
  let interactiveDismissDisabled: Bool
  let containerSize: CGSize
  let bottomInset: CGFloat
  let onRequestDismiss: (Bool) -> Void
  let content: Content
  let footer: Footer

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @State private var appeared = false
  @State private var closing = false
  @State private var detent: WDBottomSheetDetent
  @State private var dragOffset: CGFloat = 0
  @State private var keyboardInset: CGFloat = 0
  @State private var isDismissing = false

  init(
    title: Text?,
    closeButtonAccessibilityLabel: Text,
    detents: WDBottomSheetDetents,
    initialDetent: WDBottomSheetDetent,
    interactiveDismissDisabled: Bool,
    containerSize: CGSize,
    bottomInset: CGFloat,
    onRequestDismiss: @escaping (Bool) -> Void,
    content: Content,
    footer: Footer
  ) {
    self.title = title
    self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
    self.detents = detents
    self.initialDetent = initialDetent
    self.interactiveDismissDisabled = interactiveDismissDisabled
    self.containerSize = containerSize
    self.bottomInset = bottomInset
    self.onRequestDismiss = onRequestDismiss
    self.content = content
    self.footer = footer
    self._detent = State(initialValue: initialDetent)
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      scrim
      panel
        .frame(width: panelWidth, height: panelHeight, alignment: .top)
        .offset(y: panelOffset)
        .animation(
          closing ? .easeOut(duration: WDMotion.Duration.base) : WDMotion.Spring.gentle,
          value: appeared
        )
        .animation(WDMotion.Spring.snappy, value: detent)
        .animation(.easeOut(duration: WDMotion.Duration.base), value: keyboardInset)
        .accessibilityAddTraits(.isModal)
        .overlay(alignment: .top) {
          dragArea
        }
    }
    .ignoresSafeArea()
    .onAppear {
      WDA11yFocus.screenChanged()
      appeared = true
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
    ) {
      note in
      guard
        let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
      else {
        return
      }
      keyboardInset = max(0, containerSize.height - frame.minY)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
    { _ in
      keyboardInset = 0
    }
  }

  private var panel: some View {
    WDBottomSheetPanel(
      title: title,
      closeButtonAccessibilityLabel: closeButtonAccessibilityLabel,
      onClose: {
        dismiss(isCloseButton: true)
      },
      content: content,
      footer: footer,
      bottomInset: bottomInset
    )
  }

  private var scrim: some View {
    Color.black.opacity(
      appearance.colorScheme == .dark ? scrimOpacityDark : scrimOpacityLight
    )
    .ignoresSafeArea()
    .contentShape(Rectangle())
    .onTapGesture {
      if !interactiveDismissDisabled {
        dismiss(isCloseButton: false)
      }
    }
    .opacity(appeared ? 1 : 0)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: appeared)
    .accessibilityHidden(true)
  }

  private var dragArea: some View {
    Color.clear
      .frame(height: WDSpacing.s7)
      .contentShape(Rectangle())
      .gesture(dragGesture)
      .onTapGesture {
        toggleDetent()
      }
      .accessibilityHidden(true)
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: WDSpacing.s3)
      .onChanged { value in
        let translation = value.translation.height
        if translation >= 0 {
          dragOffset = translation
        } else if detent == .large {
          dragOffset = translation
        }
      }
      .onEnded { value in
        let translation = value.translation.height
        if !interactiveDismissDisabled,
          translation > panelHeight * dismissRatio
            || value.predictedEndTranslation.height > dismissVelocity
        {
          dismiss(isCloseButton: false)
          return
        }
        withAnimation(WDMotion.Spring.snappy) {
          if detents == .all {
            if translation < -detentSwitchThreshold {
              detent = .large
            } else if translation > detentSwitchThreshold, detent == .large {
              detent = .half
            }
          }
          dragOffset = 0
        }
      }
  }

  private var panelHeight: CGFloat {
    let fraction = detent == .half ? WDSize.sheetDetentHalf : WDSize.sheetDetentLarge
    return containerSize.height * fraction
  }

  private var panelWidth: CGFloat {
    min(containerSize.width, WDSize.sheetMaxWidth)
  }

  private var panelOffset: CGFloat {
    let base = appeared ? dragOffset : panelHeight + dragOffset
    return base - keyboardInset
  }

  private func toggleDetent() {
    guard detents == .all else {
      return
    }
    withAnimation(WDMotion.Spring.snappy) {
      detent = detent == .half ? .large : .half
    }
  }

  private func dismiss(isCloseButton: Bool) {
    guard !isDismissing else {
      return
    }
    isDismissing = true
    closing = true
    withAnimation(.easeOut(duration: WDMotion.Duration.base)) {
      appeared = false
    } completion: {
      onRequestDismiss(isCloseButton)
    }
  }

  private var scrimOpacityLight: CGFloat { 0.28 }  // wd-structure-check:disable R7 — 设计 26
  private var scrimOpacityDark: CGFloat { 0.50 }  // wd-structure-check:disable R7 — 设计 26
  private var dismissRatio: CGFloat { 0.4 }  // wd-structure-check:disable R7 — 设计 26
  private var dismissVelocity: CGFloat { 500 }  // wd-structure-check:disable R7 — 设计 26
  private var detentSwitchThreshold: CGFloat { 40 }  // wd-structure-check:disable R7 — 设计 26
}
