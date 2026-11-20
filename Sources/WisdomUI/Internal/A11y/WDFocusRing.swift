import SwiftUI

/// 读屏焦点目标（内部；`WDSlider` 用它区分单值手柄与范围两端）。
enum WDFocusRingTarget: Sendable, Equatable {
  /// 单值滑杆的手柄。
  case single
  /// 范围滑杆的下端点。
  case lower
  /// 范围滑杆的上端点。
  case upper
}

/// 读屏运行状态（内部）：是否要在视图里挂 `accessibilityFocused` 绑定。
///
/// **为什么需要这道闸门（2026-11-20 实测）**：只要视图里挂了 `@AccessibilityFocusState` +
/// `accessibilityFocused`，`ImageRenderer`（快照默认渲染器）就会把**整棵子树渲染成空白**
/// （实测 8 个探针：同内容不挂绑定 = 正常，挂上 = 全透明；`accessibilityRepresentation` 包一层
/// 也只救回被表示的那一层，兄弟视图仍然消失）。B18 把光环接到 `WDButton`/`WDIconButton` 之后，
/// 所有**内嵌它们**的组合件（Banner/Toast/EmptyState/DatePicker/FAB…）快照全部变白。
///
/// 焦点绑定本来就只在读屏/辅助开关下有意义（设计 06 §5 的「聚焦光环」是读屏聚焦，不是触摸焦点），
/// 因此这里按运行状态挂载：读屏（或 Switch Control）未开启时不挂，像素与 B18 之前完全一致；
/// 开启后才挂上绑定，光环照常工作。
enum WDA11yRuntime {
  /// 读屏或辅助技术是否在运行（决定是否挂 `accessibilityFocused`）。
  ///
  /// 读 `UIAccessibility.isVoiceOverRunning` / `isSwitchControlRunning`：两者都在主线程可读，
  /// 且不像 `_UIAccessibilityIsAutomationEnabled` 那样是私有符号。
  static var isAssistiveTechRunning: Bool {
    UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
  }
}

/// 把「读屏焦点落在哪个元素上」用 Binding 交回宿主（内部）。
///
/// 为什么不用环境键：`accessibilityRepresentation` 内部写的环境不会传回 represent 的宿主视图，
/// 而焦点族里既要读「谁被聚焦」又要在**表示层内部**逐元素绑定 `accessibilityFocused`。
/// Binding 是值传递，能穿过表示层回到组件的 `@State`（也避开 R18 的「组件写环境」禁区）。
///
/// **只在读屏运行时挂绑定**：见 `WDA11yRuntime` 的口径说明（`ImageRenderer` 与焦点绑定不兼容）。
struct WDAccessibilityFocusHost<Content: View>: View {
  /// 当前被聚焦的目标（nil = 无）。
  @Binding var focused: WDFocusRingTarget?
  /// 本节点代表的目标。
  let target: WDFocusRingTarget
  /// 被表示的内容（通常是原生控件，用来提供角色与可调整手势）。
  let content: Content

  /// 读屏焦点是否落在本节点上。
  @AccessibilityFocusState private var isFocused: Bool

  /// 构造。
  init(
    focused: Binding<WDFocusRingTarget?>,
    target: WDFocusRingTarget,
    @ViewBuilder content: () -> Content
  ) {
    self._focused = focused
    self.target = target
    self.content = content()
  }

  var body: some View {
    if WDA11yRuntime.isAssistiveTechRunning {
      content
        .accessibilityFocused($isFocused)
        .onChange(of: isFocused) { _, newValue in
          if newValue {
            focused = target
          } else if focused == target {
            focused = nil
          }
        }
    } else {
      content
    }
  }
}

/// 读屏聚焦光环的统一口径（内部；设计 01 §5 / 02 §5 / 06 §5 / 08 §5）。
///
/// 为什么集中在这里：`WDSlider` / `WDButton` / `WDIconButton` / `WDToolbar` 四处的
/// 「外扩 3pt + `text.brand` 32% + 160ms」必须是同一组值；分散写会各写一份字面量。
/// 数值全部取令牌（`state.focus.ring-width` / `state.focus.ring-alpha`），不新增常量。
enum WDFocusRingStyle {
  /// 光环宽度 = `state.focus.ring-width` 3pt。
  static var width: CGFloat { WDState.focusRingWidth }

  /// 光环不透明度 = `state.focus.ring-alpha` 32%（令牌给 0–100）。
  static var alpha: CGFloat { WDState.focusRingAlpha / percentScale }

  /// 淡入时长 = `motion.duration.fast` 160ms；Reduce Motion 直出。
  static func animation(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : .easeOut(duration: WDMotion.Duration.fast)
  }

  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100
}

/// 聚焦光环覆盖层：只在「读屏焦点 + 可用」同时成立时画一圈（U6：disabled 吞掉状态视觉）。
///
/// 用 `outset` 把环推到形状外侧若干点（设计口径是「外扩 3pt」），不参与布局、不吃触摸。
struct WDFocusRingOverlay<S: Shape>: View {
  /// 被描边的形状（组件自身的容器形状）。
  let shape: S
  /// 是否呈现。
  let isPresented: Bool
  /// 外扩距离（默认 = 环宽 3pt）。
  let outset: CGFloat

  @Environment(\.wdColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @ViewBuilder var body: some View {
    if isPresented {
      shape
        .stroke(
          colors.textBrand.opacity(WDFocusRingStyle.alpha),
          style: StrokeStyle(lineWidth: WDFocusRingStyle.width, lineJoin: .round)
        )
        .padding(-outset)
        .animation(WDFocusRingStyle.animation(reduceMotion: reduceMotion), value: isPresented)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }
}

extension View {
  /// 挂一圈读屏聚焦光环（内部；组件用完即弃，调用方不需要知道）。
  ///
  /// - Parameters:
  ///   - shape: 组件容器形状（胶囊 / 圆角矩形 / 圆）。
  ///   - isPresented: 是否呈现（= 读屏焦点 && 可用）。
  ///   - outset: 外扩距离，默认 = 环宽。
  func wdFocusRing<S: Shape>(
    _ shape: S,
    isPresented: Bool,
    outset: CGFloat = WDFocusRingStyle.width
  ) -> some View {
    overlay {
      WDFocusRingOverlay(shape: shape, isPresented: isPresented, outset: outset)
    }
  }
}
extension View {
  /// 仅读屏运行时挂焦点绑定（内部；口径见 `WDA11yRuntime`）。
  ///
  /// `ImageRenderer` + `accessibilityFocused` = 整棵子树渲染成空白（2026-11-20 实测），
  /// 所以所有「为了光环/焦点归还而挂绑定」的组件都必须走这两个入口，而不是直接调用 SwiftUI 的
  /// `accessibilityFocused`。
  @ViewBuilder
  func wdAccessibilityFocused(_ binding: AccessibilityFocusState<Bool>.Binding) -> some View {
    if WDA11yRuntime.isAssistiveTechRunning {
      accessibilityFocused(binding)
    } else {
      self
    }
  }

  /// 同上，带「等于某个值才聚焦」的形态（`WDFAB` 的子操作用它）。
  @ViewBuilder
  func wdAccessibilityFocused<Value: Hashable>(
    _ binding: AccessibilityFocusState<Value?>.Binding,
    equals value: Value
  ) -> some View {
    if WDA11yRuntime.isAssistiveTechRunning {
      accessibilityFocused(binding, equals: value)
    } else {
      self
    }
  }
}
