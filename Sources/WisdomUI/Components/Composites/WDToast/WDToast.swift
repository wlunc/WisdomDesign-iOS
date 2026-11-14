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

  /// 当前停留截止时刻（悬停时置空，恢复时重算）。
  @State private var deadline: ContinuousClock.Instant?
  /// 悬停时冻结的剩余时长。
  @State private var hoverRemaining: Duration?
  /// 指针是否悬停在 Toast 上（设计 28 §5：悬停暂停计时）。
  @State private var isHovering = false
  /// 计时运行序号（变化即取消旧 task，用它实现暂停/恢复）。
  @State private var timerRun = 0

  /// task 的 id：呈现状态或运行序号变化时重启。
  private struct TimerKey: Hashable {
    let presented: Bool
    let run: Int
  }

  /// 上滑手势的启动阈值。
  private static let swipeMinimumDistance: CGFloat = 10  // wd-structure-check:disable R7 — 手势阈值
  /// 上滑关闭阈值。
  private static let swipeDismissDistance: CGFloat = 16  // wd-structure-check:disable R7 — 手势阈值

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
      .onAppear {
        if isPresented { startCountdown() }
      }
      .onChange(of: isPresented) { _, presented in
        if presented {
          startCountdown()
        } else {
          deadline = nil
          hoverRemaining = nil
          isHovering = false
        }
      }
      .task(id: TimerKey(presented: isPresented, run: timerRun)) {
        await countdownIfNeeded()
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
    .onHover(perform: handleHover)
    .highPriorityGesture(swipeDismissGesture)
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

  /// 睡到截止时刻；悬停或呈现状态变化会取消 task。
  private func countdownIfNeeded() async {
    guard isPresented, !isHovering, let deadline else { return }
    let remaining = ContinuousClock.now.duration(to: deadline)
    if remaining > .zero {
      try? await Task.sleep(for: remaining)
    }
    guard !Task.isCancelled, isPresented, !isHovering else { return }
    isPresented = false
    onDismiss?()
  }

  /// 悬停暂停 / 恢复剩余时间（设计 28 §5）。
  private func handleHover(_ hovering: Bool) {
    guard isPresented else { return }
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
        isPresented = false
        onDismiss?()
      }
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
