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
  /// 底部面板（锚点视图 + 系统 sheet；焦点陷阱/键盘避让由系统接管）。
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

  @State private var selectedDetent: PresentationDetent
  @Environment(\.wdColors) private var colors

  init(
    isPresented: Binding<Bool>,
    detents: WDBottomSheetDetents,
    initialDetent: WDBottomSheetDetent,
    interactiveDismissDisabled: Bool,
    title: Text?,
    closeButtonAccessibilityLabel: Text,
    onCloseButtonTap: (() -> Void)?,
    onDismiss: (() -> Void)?,
    content: @escaping () -> SheetContent,
    footer: @escaping () -> SheetFooter
  ) {
    self._isPresented = isPresented
    self.detents = detents
    self.initialDetent = initialDetent
    self.interactiveDismissDisabled = interactiveDismissDisabled
    self.title = title
    self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
    self.onCloseButtonTap = onCloseButtonTap
    self.onDismiss = onDismiss
    self.content = content
    self.footer = footer
    self._selectedDetent = State(initialValue: Self.presentationDetent(for: initialDetent))
  }

  func body(content anchor: Content) -> some View {
    anchor.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
      VStack(spacing: 0) {
        header
        content()
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, WDSpacing.s5)
        if SheetFooter.self != EmptyView.self {
          footer()
            .padding(.horizontal, WDSpacing.s5)
            .padding(.top, WDSpacing.s4)
            .padding(.bottom, WDSpacing.s5)
        }
      }
      .frame(maxWidth: .infinity, alignment: .top)
      .presentationDetents(detentSet, selection: $selectedDetent)
      .presentationDragIndicator(.visible)
      .interactiveDismissDisabled(interactiveDismissDisabled)
      .presentationCornerRadius(WDRadius.xxl)
      .presentationBackground(colors.surfaceCardSolid)
    }
  }

  private var header: some View {
    HStack(spacing: WDSpacing.s3) {
      if let title {
        title
          .wdFont(WDType.headline)
          .foregroundStyle(colors.textPrimary)
          .wdLineBox(WDType.headline)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityAddTraits(.isHeader)
      } else {
        Spacer(minLength: 0)
      }
      WDIconButton(icon: .close, accessibilityLabel: closeButtonAccessibilityLabel) {
        isPresented = false
        onCloseButtonTap?()
      }
    }
    .padding(.horizontal, WDSpacing.s5)
    .padding(.top, WDSpacing.s4)
    .padding(.bottom, WDSpacing.s3)
  }

  private var detentSet: Set<PresentationDetent> {
    switch detents {
    case .all:
      return [Self.presentationDetent(for: .half), Self.presentationDetent(for: .large)]
    case .fixed(let detent):
      return [Self.presentationDetent(for: detent)]
    }
  }

  private static func presentationDetent(for detent: WDBottomSheetDetent) -> PresentationDetent {
    switch detent {
    case .half: return .fraction(WDSize.sheetDetentHalf)
    case .large: return .fraction(WDSize.sheetDetentLarge)
    }
  }
}
