import SwiftUI

/// 卡片外观档位（SPEC §2.11 的权威签名；设计 17 的 elevated / outline / glass 三档）。
public enum WDCardStyle: String, CaseIterable, Sendable, Equatable {
  /// 主内容卡片：`surface.card` + hairline + `elevation.1`。
  case elevated
  /// 描边卡：透明底 + hairline。
  case outlined
  /// 玻璃卡：`surface.glass-strong`（iOS 26 走系统 `glassEffect`，17–25 纯色降级）。
  case glass
}

/// 卡片（SPEC §2.10-#17；M2）。
///
/// 设计口径（设计 17）：内边距 **16（固定）**、圆角 **`radius.xl` 24**；
/// 只有 `.glass` 带背景模糊；静态卡 `.accessibilityElement(children: .contain)`。
///
/// 冻结签名只有三档（`elevated`/`outlined`/`glass`）⇒ 设计里的 `sunken`/`media` 与
/// "可点卡"（按下 96%）不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3。
public struct WDCard<Content: View>: View {
  private let style: WDCardStyle
  private let content: Content

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造（默认 `.elevated`）。
  public init(style: WDCardStyle = .elevated, @ViewBuilder content: () -> Content) {
    self.style = style
    self.content = content()
  }

  /// 渲染：只有 `.glass` 在 iOS 26 上叠系统玻璃效果；其余一律实底。
  @ViewBuilder public var body: some View {
    if style == .glass, #available(iOS 26.0, *) {
      base.glassEffect(.regular, in: shape)
    } else {
      base
    }
  }

  private var base: some View {
    content
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)
      .clipShape(shape)
      .overlay(shape.stroke(colors.borderHairline, lineWidth: 1))
      .modifier(WDCardShadow(style: style))
      .accessibilityElement(children: .contain)
  }

  private var background: Color {
    switch style {
    case .elevated: return colors.surfaceCard
    case .outlined: return .clear
    case .glass: return glassFill
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
    if style == .outlined {
      content
    } else {
      content.wdShadow(WDElevation.e1)
    }
  }
}
