import SwiftUI

/// 卡片外观档位（SPEC §2.11 的权威签名；设计 17 的 elevated / outline / glass 三档）。
///
/// A-13（设计 14 §2）：新增 `media` —— 顶部通栏图片带 + 文字区。**源级 breaking**：
/// 新增枚举 case 破穷尽 switch（F-20 ⇒ minor + Breaking 段 + 迁移片段）。
public enum WDCardStyle: String, CaseIterable, Sendable, Equatable {
  /// 主内容卡片：`surface.card` + hairline + `elevation.1`。
  case elevated
  /// 描边卡：透明底 + hairline。
  case outlined
  /// 玻璃卡：`surface.glass-strong`（iOS 26 走系统 `glassEffect`，17–25 纯色降级）。
  case glass
  /// 下沉卡（B3 增量；`surface.card-sunken`，无描边、无阴影）。
  case sunken
  /// 媒体卡（A-13；设计 14 §2）：顶部**通栏**图片带（16:9、最小高 96、上圆下不圆）+ 16 内边距文字区。
  ///
  /// 互斥规则（设计 §2.1-C6 / §2.6）：`media` 与 `glass` **互斥**（图片带不做模糊）、
  /// 与 `sunken` 不组合（`sunken` 是卡内嵌块语义）。构造 `init(style:media:...)` 是唯一合法入口，
  /// 直接用 `WDCard(style: .media)` 不带 media 值 = 纯灰底图片带（`surface.card-sunken`）。
  case media
}

/// 卡片（SPEC §2.10-#17；M2）。
///
/// 设计口径（设计 17）：内边距 **16（固定）**、圆角 **`radius.xl` 24**；
/// 只有 `.glass` 带背景模糊；静态卡 `.accessibilityElement(children: .contain)`。
///
/// 现有四档：`elevated`/`outlined`/`glass` + **B3 的 `sunken`**（下沉底、无描边、无阴影）。
/// A-13 新增 `media`（顶部通栏图片带；设计 14 §2），见 `WDCardStyle.media` 的互斥规则。
///
/// 可点卡（设计 17 §5/§8）：`init(style:action:content:)` 用 `Button` 包裹整卡——
/// 按下整卡亮度 96% + `motion.duration.instant`、禁用整体 40%、整体获得 `button` 语义。
/// **卡内不要再放可点子元素**（设计 17 §10）：SwiftUI 的 `Button` 会吞掉标签内的嵌套
/// 按钮/手势，无法保证“子元素优先响应、事件不冒泡”，只能在调用方避免这种结构。
public struct WDCard<Content: View>: View {
  /// 档位。internal 而非 private：互斥规则（`.media` 才挂图片带）必须能被单测断言，
  /// 同 `isClickable` / `media` 的先例。
  let style: WDCardStyle
  private let action: (() -> Void)?
  private let content: Content
  /// 顶部图片带载荷（仅 `.media` 使用；其他档位恒 `nil`）。
  ///
  /// internal 而非 private：`media` 与 `.media` 互斥规则必须能被单测断言
  ///（"非 media 档即使传了 media 参数也不得挂载图片带"），同 `isClickable` 的先例。
  let media: WDCardMedia?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  /// 静态卡构造（默认 `.elevated`）：不响应点击，零按下反馈。
  ///
  /// `.media` 不从本构造进（图片带是它的必要载荷）——用 `init(style:media:content:)`。
  /// 若确以 `.media` 调用本构造，图片带按纯灰底占位渲染（设计 §2.3 的失败/无图档）。
  public init(style: WDCardStyle = .elevated, @ViewBuilder content: () -> Content) {
    self.style = style
    self.action = nil
    self.content = content()
    self.media = nil
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
    self.media = nil
  }

  /// 媒体卡构造（A-13；设计 14 §2.6）：顶部图片带 + 文字区，不可点。
  ///
  /// - Parameters:
  ///   - style: 传 `.media`；传其他档位则忽略 `media`（走原档渲染）。
  ///   - media: 图片带载荷；`image == nil` = 灰底占位（加载中 / 失败 / 无图共用）。
  public init(
    style: WDCardStyle,
    media: WDCardMedia?,
    @ViewBuilder content: () -> Content
  ) {
    self.style = style == .media ? .media : style
    self.action = nil
    self.content = content()
    self.media = self.style == .media ? media : nil
  }

  /// 可点媒体卡构造（A-13；设计 §2.3「可点卡按下整卡亮度 96%，图片一起压暗」）。
  ///
  /// 整卡是一个动作，图片带含在内；无障碍仍走 `Button` 的 `button` 语义。
  public init(
    style: WDCardStyle,
    media: WDCardMedia?,
    action: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.style = style == .media ? .media : style
    self.action = action
    self.content = content()
    self.media = self.style == .media ? media : nil
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

  /// 卡面：`.media` = 图片带在上（通栏）+ 文字区在下（16 内边距）；其余 = 纯文字区。
  ///
  /// 圆角只由整卡 `.clipShape(shape)` 裁**一次**（设计 §2.2：图片带上圆下不圆 =
  /// 上边随卡片圆角、下边被文字区接住）；不给图片带单独加圆角，交界处不会出重影。
  private var chrome: some View {
    Group {
      if hasMediaBand {
        VStack(alignment: .leading, spacing: WDCardMediaBand.stackSpacing) {
          WDCardMediaBand(media: media ?? WDCardMedia(nil))
          content
            .padding(WDSpacing.s5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      } else {
        content
          .padding(WDSpacing.s5)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(background)
    .clipShape(shape)
    .overlay { borderOverlay }
    .modifier(WDCardShadow(style: style))
  }

  /// 是否渲染图片带（仅 `.media` 且带载荷时 true；宽度由父级给定，高度按设计 §2.2 几何）。
  private var hasMediaBand: Bool {
    style == .media && media != nil
  }

  private var background: Color {
    switch style {
    case .elevated: return colors.surfaceCard
    case .outlined: return .clear
    case .glass: return glassFill
    case .sunken: return colors.surfaceCardSunken
    case .media: return colors.surfaceCard  // 图片带之外仍是标准卡面（设计 §2.2：文字区对 surface.card）
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

/// 顶部图片带（A-13；设计 14 §2.2/§2.3）。
///
/// 几何（全部走令牌）：宽高比 `WDSize.cardMediaAspectRatio`（1.78 = 16:9）、
/// 最小高 `WDSize.cardMediaMinHeight`（96；低于按 96 渲染并居中裁切）。
/// 通栏：不叠卡片 16 内边距（左右与上边贴到卡片边缘），上边圆角由整卡
/// `.clipShape` 裁出、下边不圆 —— 本视图不做任何圆角。
///
/// 状态（设计 §2.3）：
/// - 图片就绪 → `scaledToFill` 铺满 + 裁切；
/// - `image == nil`（加载中 / 失败 / 无图共用）→ `surface.card-sunken` 灰底，无骨架、无微光、不出破图、不留白；
/// - 就绪后 160ms 淡入（`motion.duration.fast`），不用缩放。
///
/// 无障碍（设计 §2.5）：默认装饰（`accessibilityHidden(true)`）；
/// 调用方给了 `accessibilityLabel` 时图片进树并带该标签（例外：图片本身是内容）。
struct WDCardMediaBand: View {
  let media: WDCardMedia

  @Environment(\.wdColors) private var colors
  /// 图片是否就绪（淡入动画的驱动值；nil = 灰底占位）。
  @State private var appeared = false

  /// VStack 的段间距 = 0（图片带与文字区之间不留白；设计 §2.2 通栏语义）。
  /// 显式命名常量而非字面量，避免 R7；语义由注释承载。
  static let stackSpacing: CGFloat = 0

  var body: some View {
    // 带高：按宽度走 16:9（.aspectRatio 由布局系统按可用宽算），
    // 并夹到最小高 96 以上（设计 §2.1-C5：宽 < 171 时按 96 渲染并居中裁切）。
    // 不用 GeometryReader：它在 VStack 里不占高，卡片高度也会因此塌掉。
    ZStack {
      Color(colors.surfaceCardSunken)  // 占位底：加载中/失败/无图与图片层同框，淡入盖住它
      if let image = media.image {
        image
          .resizable()
          .scaledToFill()
          .opacity(appeared ? 1 : 0)
      }
    }
    .aspectRatio(WDSize.cardMediaAspectRatio, contentMode: .fill)
    .frame(minHeight: WDSize.cardMediaMinHeight)
    .frame(maxWidth: .infinity)
    .clipped()
    .onAppear {
      guard media.image != nil else { return }
      withAnimation(.easeOut(duration: WDMotion.Duration.fast)) { appeared = true }
    }
    .accessibilityHidden(media.accessibilityLabel == nil)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(media.accessibilityLabel ?? Text(verbatim: ""))
  }
}
