import SwiftUI

/// Toast 变体（设计 28 §4：成功 / 信息 / 失败；带操作是组合态）。
public enum WDToastVariant: String, CaseIterable, Sendable, Equatable {
  case neutral
  case success
  case warning
  case danger
}

/// Toast 上的操作（最多一个；带操作时停留时间至少 5 秒）。
public struct WDToastAction {
  /// 文案（调用方给）。
  public let label: Text
  /// 点击动作。
  public let action: () -> Void

  /// 构造。
  public init(label: Text, action: @escaping () -> Void) {
    self.label = label
    self.action = action
  }
}

extension View {
  /// 非阻塞轻提示（底部浮出；自动消失；不抢焦点）。
  public func wdToast(
    isPresented: Binding<Bool>,
    variant: WDToastVariant = .neutral,
    message: Text,
    action: WDToastAction? = nil,
    durationMilliseconds: Int = 3000,  // wd-structure-check:disable R7 — 设计 28 §5 的默认 3 秒
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    modifier(
      WDToastModifier(
        isPresented: isPresented,
        variant: variant,
        message: message,
        action: action,
        durationMilliseconds: durationMilliseconds,
        onDismiss: onDismiss
      )
    )
  }
}

private struct WDToastModifier: ViewModifier {
  @Binding var isPresented: Bool
  let variant: WDToastVariant
  let message: Text
  let action: WDToastAction?
  let durationMilliseconds: Int
  let onDismiss: (() -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  private static let minimumDuration = 3000  // wd-structure-check:disable R7 — 设计 28 §5 的纯提示 3 秒
  private static let actionDuration = 5000  // wd-structure-check:disable R7 — 设计 28 §5 的带操作 5 秒

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .bottom) {
        if isPresented {
          toast
            .padding(.horizontal, WDSpacing.s9)
            .padding(.bottom, WDSpacing.s5)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.easeOut(duration: WDMotion.Duration.base), value: isPresented)
      .task(id: isPresented) {
        guard isPresented else { return }
        let milliseconds = max(
          Self.minimumDuration,
          action == nil ? durationMilliseconds : max(durationMilliseconds, Self.actionDuration)
        )
        try? await Task.sleep(for: .milliseconds(milliseconds))
        guard !Task.isCancelled else { return }
        isPresented = false
        onDismiss?()
      }
  }

  private var toast: some View {
    HStack(spacing: WDSpacing.s3) {
      WDIcon(icon: icon, size: .sm)
        .foregroundStyle(accent)
        .accessibilityHidden(true)
      message
        .wdFont(WDType.footnote)
        .foregroundStyle(colors.textPrimary)
        .lineLimit(2)
        .wdLineBox(WDType.footnote, lines: 2)  // wd-structure-check:disable R7 — 设计 28 §3 的最多 2 行
        .frame(maxWidth: .infinity, alignment: .leading)
      if let action {
        WDButton(
          variant: .plain, size: .sm,
          action: {
            action.action()
            isPresented = false
            onDismiss?()
          }, label: { action.label })
      }
    }
    .padding(.horizontal, 18)  // wd-structure-check:disable R7 — 设计 28 §3 的水平内距
    .padding(.vertical, WDSpacing.s3)
    .frame(minHeight: WDSize.fieldHeight)
    .background(background)
    .clipShape(Capsule())
    .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
    .accessibilityElement(children: .contain)
  }

  @ViewBuilder private var background: some View {
    if #available(iOS 26.0, *), glassResolution != .opaque {
      Capsule().fill(fillColor).glassEffect(.regular, in: Capsule())
    } else {
      Capsule().fill(fillColor)
    }
  }

  private var fillColor: Color {
    switch glassResolution {
    case .glass: return colors.surfaceGlass
    case .glassStrong: return colors.surfaceGlassStrong
    case .opaque: return colors.surfaceCardSolid
    }
  }

  private var glassResolution: WDGlassResolution {
    WDGlass.resolve(
      textLevel: .primary,
      appearance: appearance,
      capabilities: WDGlassCapabilities(supportsGlass: runtimeSupportsGlass()),
      budget: budget,
      level: .thick
    )
  }

  private func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  private var accent: Color {
    switch variant {
    case .neutral: return colors.textBrand
    case .success: return colors.statusSuccess
    case .warning: return colors.statusWarning
    case .danger: return colors.statusDanger
    }
  }

  private var icon: WDIconName {
    switch variant {
    case .neutral: return .inProgress
    case .success: return .done
    case .warning: return .overdue
    case .danger: return .offline
    }
  }
}
