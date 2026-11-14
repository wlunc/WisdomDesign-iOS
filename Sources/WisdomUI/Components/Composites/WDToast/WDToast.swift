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
  /// 非阻塞轻提示（窗口级浮出；自动消失；不抢焦点）。
  ///
  /// 设计与实现说明（设计 28 §11）：浮层挂在窗口层（Top VC 的 view），避免被局部容器裁切；
  /// 只占 Toast 自身尺寸，页面其余区域仍可交互。计时 / 悬停 / 上滑状态在浮层内部维护，
  /// 公开签名不变。
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

  @Environment(\.wdTheme) private var theme
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.wdEffectsBudget) private var budget

  func body(content: Content) -> some View {
    content
      .onAppear {
        if isPresented { present() }
      }
      .onChange(of: isPresented) { _, presented in
        if presented {
          present()
        } else {
          WDToastPresenter.shared.dismiss()
        }
      }
      .onChange(of: variant) { _, _ in
        if isPresented { present() }
      }
      .onChange(of: message) { _, _ in
        if isPresented { present() }
      }
      .onChange(of: durationMilliseconds) { _, _ in
        if isPresented { present() }
      }
  }

  private func present() {
    WDToastPresenter.shared.present(
      theme: theme, colorScheme: colorScheme, budget: budget
    ) {
      WDToastContent(
        variant: variant,
        message: message,
        action: action,
        durationMilliseconds: durationMilliseconds,
        onDismiss: {
          isPresented = false
          onDismiss?()
        }
      )
    }
  }
}

/// 浮层内容：计时 + 悬停暂停 + 上滑关闭（窗口层宿主里的根视图）。
struct WDToastContent: View {
  let variant: WDToastVariant
  let message: Text
  let action: WDToastAction?
  let durationMilliseconds: Int
  let onDismiss: () -> Void

  /// 当前停留截止时刻（悬停时置空，恢复时重算）。
  @State private var deadline: ContinuousClock.Instant?
  /// 悬停时冻结的剩余时长。
  @State private var hoverRemaining: Duration?
  /// 指针是否悬停在 Toast 上（设计 28 §5：悬停暂停计时）。
  @State private var isHovering = false
  /// 计时运行序号（变化即取消旧 task，用它实现暂停/恢复）。
  @State private var timerRun = 0

  /// 上滑手势的启动阈值。
  private static let swipeMinimumDistance: CGFloat = 10  // wd-structure-check:disable R7 — 手势阈值
  /// 上滑关闭阈值。
  private static let swipeDismissDistance: CGFloat = 16  // wd-structure-check:disable R7 — 手势阈值

  var body: some View {
    WDToastCard(variant: variant, message: message, action: action, onAction: onDismiss)
      .onHover(perform: handleHover)
      .highPriorityGesture(swipeDismissGesture)
      .onAppear(perform: startCountdown)
      .task(id: timerRun) {
        await countdownIfNeeded()
      }
  }

  /// 实际停留时长（设计 28 §5）。
  private var countdownDuration: Duration {
    WDToastTiming.duration(requestedMilliseconds: durationMilliseconds, hasAction: action != nil)
  }

  /// 开始 / 重启倒计时。
  private func startCountdown() {
    deadline = ContinuousClock.now.advanced(by: countdownDuration)
    hoverRemaining = nil
    isHovering = false
    timerRun += 1
  }

  /// 睡到截止时刻；悬停或状态变化会取消 task。
  private func countdownIfNeeded() async {
    guard !isHovering, let deadline else { return }
    let remaining = ContinuousClock.now.duration(to: deadline)
    if remaining > .zero {
      try? await Task.sleep(for: remaining)
    }
    guard !Task.isCancelled, !isHovering else { return }
    onDismiss()
  }

  /// 悬停暂停 / 恢复剩余时间（设计 28 §5）。
  private func handleHover(_ hovering: Bool) {
    if hovering {
      guard !isHovering else { return }
      if let deadline {
        let remaining = ContinuousClock.now.duration(to: deadline)
        hoverRemaining = remaining > .zero ? remaining : .zero
      } else {
        hoverRemaining = countdownDuration
      }
      deadline = nil
      isHovering = true
    } else {
      guard isHovering else { return }
      deadline = ContinuousClock.now.advanced(by: hoverRemaining ?? countdownDuration)
      hoverRemaining = nil
      isHovering = false
    }
    timerRun += 1
  }

  /// 上滑立即关闭（设计 28 §8）。
  private var swipeDismissGesture: some Gesture {
    DragGesture(minimumDistance: Self.swipeMinimumDistance)
      .onEnded { value in
        guard value.translation.height < -Self.swipeDismissDistance else { return }
        onDismiss()
      }
  }
}

/// Toast 视觉本体（窗口浮层与快照共用）。
struct WDToastCard: View {
  let variant: WDToastVariant
  let message: Text
  let action: WDToastAction?
  let onAction: () -> Void

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  var body: some View {
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
            onAction()
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
