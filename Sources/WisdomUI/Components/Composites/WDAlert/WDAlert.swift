import SwiftUI

/// 弹窗按钮（最多 2 个；取消在左，确认/危险在右）。
public struct WDAlertAction {
  /// 按钮角色。
  public enum Role: Sendable, Equatable {
    case `default`
    case cancel
    case destructive
  }

  /// 文案（调用方给）。
  public let label: Text
  /// 角色。
  public let role: Role
  /// 点击动作。
  public let action: () -> Void

  /// 构造。
  public init(label: Text, role: Role = .default, action: @escaping () -> Void) {
    self.label = label
    self.role = role
    self.action = action
  }
}

extension View {
  /// 阻断式弹窗（双按钮 / 单按钮 / 危险按钮）。
  public func wdAlert(
    isPresented: Binding<Bool>,
    title: Text,
    message: Text? = nil,
    actions: [WDAlertAction],
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    modifier(
      WDAlertModifier(
        isPresented: isPresented,
        title: title,
        message: message,
        actions: actions,
        onDismiss: onDismiss,
        content: { EmptyView() }
      )
    )
  }

  /// 阻断式弹窗 + 自定义内容（设计 25 的「带输入」变体）。
  public func wdAlert<Content: View>(
    isPresented: Binding<Bool>,
    title: Text,
    message: Text? = nil,
    actions: [WDAlertAction],
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    modifier(
      WDAlertModifier(
        isPresented: isPresented,
        title: title,
        message: message,
        actions: actions,
        onDismiss: onDismiss,
        content: content
      )
    )
  }
}

/// 弹窗修饰符：遮罩 + 270pt 卡片；遮罩点击不关闭；焦点先进入标题。
private struct WDAlertModifier<AlertContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let title: Text
  let message: Text?
  let actions: [WDAlertAction]
  let onDismiss: (() -> Void)?
  let content: () -> AlertContent

  @Environment(\.wdColors) private var colors
  @AccessibilityFocusState private var focusedTitle: WDA11yFocusID?
  @State private var isSubmitting = false

  private var titleFocusID: WDA11yFocusID { WDAlertFocus.title }

  func body(content anchor: Content) -> some View {
    anchor
      .overlay {
        if isPresented {
          layer
            .transition(.opacity)
            .zIndex(1)
        }
      }
      .animation(.easeOut(duration: WDMotion.Duration.base), value: isPresented)
      .onChange(of: isPresented) { _, presented in
        if presented {
          isSubmitting = false
          focusedTitle = titleFocusID
        }
      }
  }

  private var layer: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { /* Alert 前提是必须做出选择：遮罩点击不关闭 */  }
      card
    }
  }

  private var card: some View {
    VStack(spacing: 0) {
      title
        .wdFont(WDType.headline)
        .foregroundStyle(colors.textPrimary)
        .multilineTextAlignment(.center)
        .wdLineBox(WDType.headline)
        .padding(.top, WDSpacing.s5)
        .padding(.bottom, WDSpacing.s1)
        .padding(.horizontal, WDSpacing.s5)
        .accessibilityAddTraits(.isHeader)
        .accessibilityFocused($focusedTitle, equals: WDAlertFocus.title)
      if let message {
        message
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textSecondary)
          .multilineTextAlignment(.center)
          .lineLimit(3)
          .wdLineBox(WDType.footnote, lines: 3)  // wd-structure-check:disable R7 — 设计
          .padding(.horizontal, WDSpacing.s5)
          .padding(.bottom, WDSpacing.s4)
      }
      content()
        .padding(.horizontal, WDSpacing.s5)
        .padding(.bottom, WDSpacing.s4)
      Divider().overlay(colors.borderHairline)
      actionBar
    }
    .frame(width: 270)  // wd-structure-check:disable R7 — 设计 25 §3 的固定卡片宽
    .background(colors.surfaceCardSolid)
    .clipShape(RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous))
    .wdShadow(WDElevation.e3)
    .accessibilityElement(children: .contain)
    .accessibilityAddTraits(.isModal)
  }

  @ViewBuilder private var actionBar: some View {
    let ordered = orderedActions
    if ordered.count == 1, let action = ordered.first {
      actionButton(action)
    } else {
      HStack(spacing: 0) {
        ForEach(Array(ordered.enumerated()), id: \.offset) { index, action in
          actionButton(action)
          if index < ordered.count - 1 {
            Rectangle().fill(colors.borderHairline).frame(width: 1, height: WDSize.controlMd)
          }
        }
      }
    }
  }

  private var orderedActions: [WDAlertAction] {
    actions.sorted { lhs, rhs in
      rank(lhs.role) < rank(rhs.role)
    }
  }

  private func rank(_ role: WDAlertAction.Role) -> Int {
    switch role {
    case .cancel: return 0
    case .`default`: return 1
    case .destructive: return 2  // wd-structure-check:disable R7 — 按钮排序的秩
    }
  }

  private func actionButton(_ action: WDAlertAction) -> some View {
    Button {
      guard !isSubmitting else { return }
      isSubmitting = true
      action.action()
      isPresented = false
      onDismiss?()
    } label: {
      action.label
        .wdFont(WDType.body)
        .foregroundStyle(color(for: action.role))
        .frame(maxWidth: .infinity, minHeight: WDSize.controlMd)
        .wdLineBox(WDType.body)
        .contentShape(Rectangle())
    }
    .buttonStyle(WDAlertButtonStyle(pressedFill: colors.fillPressed))
    .disabled(isSubmitting)
    .opacity(isSubmitting ? 0.4 : 1)  // wd-structure-check:disable R7 — 设计 25 §5 的禁用态 40%
  }

  private func color(for role: WDAlertAction.Role) -> Color {
    switch role {
    case .cancel: return colors.textSecondary
    case .`default`: return colors.textBrand
    case .destructive: return colors.statusDanger
    }
  }
}

/// 弹窗焦点身份（不再放进泛型类型：Swift 不允许泛型类型里的 static stored property）。
private enum WDAlertFocus {
  static let title = WDA11yFocusID(rawValue: "wd-alert-title")
}

/// 弹窗按钮的按下底色。
private struct WDAlertButtonStyle: ButtonStyle {
  let pressedFill: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? pressedFill : .clear)
  }
}
