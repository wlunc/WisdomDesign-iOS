import SwiftUI

/// 面板档位（0.5 / 0.92；SPEC §2.5）。
public enum WDBottomSheetDetent: String, CaseIterable, Sendable, Equatable {
  case half
  case large
}

/// 档位联合（iOS 独有 ⇒ F38；默认 .all 与 Android 默认档一致）。
public enum WDBottomSheetDetents: Sendable, Equatable {
  case all
  case fixed(WDBottomSheetDetent)
}

extension View {
  /// 底部面板（窗口级自绘；贴屏幕左右/底部，顶部 32 圆角；把手/标题/滚动内容/固定页脚）。
  public func wdSheet<Content: View, Footer: View>(
    isPresented: Binding<Bool>,
    detents: WDBottomSheetDetents = .all,
    initialDetent: WDBottomSheetDetent = .half,
    interactiveDismissDisabled: Bool = false,
    title: Text? = nil,
    closeButtonAccessibilityLabel: Text,
    onCloseButtonTap: (() -> Void)? = nil,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder footer: @escaping () -> Footer
  ) -> some View {
    modifier(
      WDSheetModifier(
        isPresented: isPresented,
        detents: detents,
        initialDetent: initialDetent,
        interactiveDismissDisabled: interactiveDismissDisabled,
        title: title,
        closeButtonAccessibilityLabel: closeButtonAccessibilityLabel,
        onCloseButtonTap: onCloseButtonTap,
        onDismiss: onDismiss,
        content: content,
        footer: footer
      )
    )
  }
}

/// 面板内容（与窗口 presenter 解耦，便于快照与组合；内部类型）。
struct WDBottomSheetPanel<Content: View, Footer: View>: View {
  let title: Text?
  let closeButtonAccessibilityLabel: Text
  let onClose: () -> Void
  let content: Content
  let footer: Footer
  let bottomInset: CGFloat
  let onScrollPull: ((CGFloat) -> Void)?
  let onScrollPullEnd: ((CGFloat, CGFloat) -> Void)?

  @Environment(\.wdColors) private var colors

  private var headerMinHeight: CGFloat { WDSpacing.s10 + WDSpacing.s3 }

  init(
    title: Text?,
    closeButtonAccessibilityLabel: Text,
    onClose: @escaping () -> Void,
    content: Content,
    footer: Footer,
    bottomInset: CGFloat = 0,
    onScrollPull: ((CGFloat) -> Void)? = nil,
    onScrollPullEnd: ((CGFloat, CGFloat) -> Void)? = nil
  ) {
    self.title = title
    self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
    self.onClose = onClose
    self.content = content
    self.footer = footer
    self.bottomInset = bottomInset
    self.onScrollPull = onScrollPull
    self.onScrollPullEnd = onScrollPullEnd
  }

  var body: some View {
    VStack(spacing: 0) {
      handle
      header
      ScrollView {
        VStack(spacing: 0) {
          WDBottomSheetScrollProbe(
            onPull: { onScrollPull?($0) },
            onEnd: { onScrollPullEnd?($0, $1) }
          )
          .frame(width: 0, height: 0)
          content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, WDSpacing.s5)
            .padding(.top, WDSpacing.s4)
        }
      }
      .scrollIndicators(.hidden)
      if Footer.self != EmptyView.self {
        Rectangle()
          .fill(colors.borderHairline)
          .frame(height: 1)
        footer
          .frame(maxWidth: .infinity, alignment: .trailing)
          .padding(.horizontal, WDSpacing.s5)
          .padding(.top, WDSpacing.s5)
          .padding(.bottom, WDSpacing.s4)
      }
    }
    .padding(.bottom, bottomInset)
    .background(colors.surfaceCardSolid)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: WDRadius.xxl,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: WDRadius.xxl,
        style: .continuous
      )
    )
    .wdShadow(WDElevation.e3)
    .frame(maxWidth: WDSize.sheetMaxWidth)
    .frame(maxWidth: .infinity, alignment: .top)
  }

  private var handle: some View {
    Capsule()
      .fill(colors.borderHairlineStrong)
      .frame(width: 36, height: 5)  // wd-structure-check:disable R7 — 设计 26 §3 把手
      .padding(.top, WDSpacing.s3)
      .padding(.bottom, WDSpacing.s3)
      .accessibilityHidden(true)
  }

  private var header: some View {
    HStack(spacing: WDSpacing.s3) {
      if let title {
        title
          .wdFont(WDType.title3)
          .foregroundStyle(colors.textPrimary)
          .wdLineBox(WDType.title3)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityAddTraits(.isHeader)
      } else {
        Spacer(minLength: 0)
      }
      WDIconButton(icon: .close, accessibilityLabel: closeButtonAccessibilityLabel, action: onClose)
    }
    .padding(.horizontal, WDSpacing.s5)
    .frame(minHeight: headerMinHeight)
  }
}

private struct WDSheetModifier<SheetContent: View, SheetFooter: View>: ViewModifier {
  @Binding var isPresented: Bool
  let detents: WDBottomSheetDetents
  let initialDetent: WDBottomSheetDetent
  let interactiveDismissDisabled: Bool
  let title: Text?
  let closeButtonAccessibilityLabel: Text
  let onCloseButtonTap: (() -> Void)?
  let onDismiss: (() -> Void)?
  let content: () -> SheetContent
  let footer: () -> SheetFooter

  func body(content anchor: Content) -> some View {
    anchor
      .accessibilityHidden(isPresented)
      .onAppear {
        if isPresented {
          present()
        }
      }
      .onChange(of: isPresented) { _, presented in
        if presented {
          present()
        } else {
          WDBottomSheetPresenter.shared.dismiss()
          onDismiss?()
        }
      }
      .onDisappear {
        WDBottomSheetPresenter.shared.dismiss()
      }
  }

  private func present() {
    let effectiveInitial: WDBottomSheetDetent
    switch detents {
    case .fixed(let detent):
      effectiveInitial = detent
    case .all:
      effectiveInitial = initialDetent
    }
    WDBottomSheetPresenter.shared.present { size, bottomInset in
      WDBottomSheetLayer(
        title: title,
        closeButtonAccessibilityLabel: closeButtonAccessibilityLabel,
        detents: detents,
        initialDetent: effectiveInitial,
        interactiveDismissDisabled: interactiveDismissDisabled,
        containerSize: size,
        bottomInset: bottomInset,
        onRequestDismiss: { isCloseButton in
          isPresented = false
          if isCloseButton {
            onCloseButtonTap?()
          }
        },
        content: content(),
        footer: footer()
      )
    }
  }
}
