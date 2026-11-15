import SwiftUI

/// 卡片外观档位（SPEC §2.11 的权威签名；设计 17 的 elevated / outline / glass 三档）。
public enum WDCardStyle: String, CaseIterable, Sendable, Equatable {
  /// 主内容卡片：`surface.card` + hairline + `elevation.1`。
  case elevated
  /// 描边卡：透明底 + hairline。
  case outlined
  /// 玻璃卡：`surface.glass-strong`（iOS 26 走系统 `glassEffect`，17–25 纯色降级）。
  case glass
  /// 下沉卡（B3 增量；`surface.card-sunken`，无描边、无阴影）。
  case sunken
}

/// 卡片（SPEC §2.10-#17；M2）。
///
/// 设计口径（设计 17）：内边距 **16（固定）**、圆角 **`radius.xl` 24**；
/// 只有 `.glass` 带背景模糊；静态卡 `.accessibilityElement(children: .contain)`。
///
/// 现有四档：`elevated`/`outlined`/`glass` + **B3 的 `sunken`**（下沉底、无描边、无阴影）。
/// `media` 变体仍不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3。
///
/// 可点卡（设计 17 §5/§8）：`init(style:action:content:)` 用 `Button` 包裹整卡——
/// 按下整卡亮度 96% + `motion.duration.instant`、禁用整体 40%、整体获得 `button` 语义。
/// **卡内不要再放可点子元素**（设计 17 §10）：SwiftUI 的 `Button` 会吞掉标签内的嵌套
/// 按钮/手势，无法保证“子元素优先响应、事件不冒泡”，只能在调用方避免这种结构。
public struct WDCard<Content: View>: View {
  private let style: WDCardStyle
  private let action: (() -> Void)?
  private let content: Content

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  /// 静态卡构造（默认 `.elevated`）：不响应点击，零按下反馈。
  public init(style: WDCardStyle = .elevated, @ViewBuilder content: () -> Content) {
    self.style = style
    self.action = nil
    self.content = content()
  }

  /// 可点卡构造（设计 17 §5）：整卡是一个动作。
  ///
  /// 按下用 4% 黑色蒙层把整卡压暗到 96%——`.brightness` 是加法位移（各通道同加），
  /// 不能表达“乘 0.96”；4% 蒙层等价于对不透明像素做乘法压暗，且保留文字抗锯齿。
  /// 动画走 `motion.duration.instant`（100ms）；禁用由 `@Environment(\.isEnabled)` 整体降到 40%。
  /// 无障碍：`Button` 自带 `button` 语义，读屏文本由卡内标题合成；静态卡不变成按钮。
  public init(
    style: WDCardStyle = .elevated,
    action: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.style = style
    self.action = action
    self.content = content()
  }

  /// 是否可点（内部：body 分支与单测共用；不进入公开 API）。
  var isClickable: Bool { action != nil }

  /// 渲染：可点卡整卡包 `Button`；静态卡保持原样（`children: .contain`，不成为按钮）。
  @ViewBuilder public var body: some View {
    if isClickable, let action {
      Button(action: action) {
        surface.contentShape(shape)
      }
      .buttonStyle(WDCardButtonStyle())
      .accessibilityAddTraits(.isButton)
    } else {
      staticSurface
    }
  }

  /// 静态卡：玻璃效果在最外层，`children: .contain` 与改造前同序（零行为变化）。
  @ViewBuilder private var staticSurface: some View {
    if style == .glass, #available(iOS 26.0, *) {
      staticChrome.glassEffect(.regular, in: shape)
    } else {
      staticChrome
    }
  }

  private var staticChrome: some View {
    chrome.accessibilityElement(children: .contain)
  }

  /// 可点卡的视觉面：只有 `.glass` 在 iOS 26 上叠系统玻璃效果；其余一律实底。
  @ViewBuilder private var surface: some View {
    if style == .glass, #available(iOS 26.0, *) {
      chrome.glassEffect(.regular, in: shape)
    } else {
      chrome
    }
  }

  private var chrome: some View {
    content
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)
      .clipShape(shape)
      .overlay { borderOverlay }
      .modifier(WDCardShadow(style: style))
  }

  private var background: Color {
    switch style {
    case .elevated: return colors.surfaceCard
    case .outlined: return .clear
    case .glass: return glassFill
    case .sunken: return colors.surfaceCardSunken
    }
  }

  /// 描边：只有 `sunken` 不带描边（设计 17 §4）。
  @ViewBuilder private var borderOverlay: some View {
    if style != .sunken {
      shape.stroke(colors.borderHairline, lineWidth: 1)
    }
  }

  /// 玻璃的纯色降级色（`WDGlass.resolve` 的唯一入口：iOS 17–25 / 预算不足 ⇒ 实底）。
  private var glassFill: Color {
    switch WDGlass.resolve(
      textLevel: .primary,
      appearance: appearance,
      capabilities: WDGlassCapabilities(supportsGlass: Self.runtimeSupportsGlass()),
      budget: budget,
      level: .thick
    ) {
    case .glass: return colors.surfaceGlass
    case .glassStrong: return colors.surfaceGlassStrong
    case .opaque: return colors.surfaceCardSolid
    }
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }
}

/// 阴影：`outlined` 无阴影，其余用 `elevation.e1`。
private struct WDCardShadow: ViewModifier {
  let style: WDCardStyle

  @ViewBuilder func body(content: Content) -> some View {
    if style == .outlined || style == .sunken {
      content
    } else {
      content.wdShadow(WDElevation.e1)
    }
  }
}

/// 可点卡的按下/禁用视觉（设计 17 §5）。
///
/// 按下：整卡亮度 96%（黑色 4% 蒙层，乘法等价）；动画 `motion.duration.instant`。
/// 禁用：`state.disabled.alpha` = 40%（`@Environment(\.isEnabled)`，Button 自身也吞输入）。
struct WDCardButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  /// 构造（无参数；档位由卡片外层决定）。
  init() {}

  /// 按下压暗蒙层不透明度：亮度 96% ⇒ 黑色 4%。
  var pressedDimOpacity: CGFloat {
    (Self.percentScale - WDState.pressedBrightness) / Self.percentScale
  }

  /// 禁用态整体 40%（`state.disabled.alpha`）。
  var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 百分数换算分母。
  static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .overlay {
        RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
          .fill(Color.black)
          .opacity(configuration.isPressed ? pressedDimOpacity : 0)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      .opacity(isEnabled ? 1 : disabledOpacity)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
