import SwiftUI

/// 头像的值形态（WDAvatar 的载荷；SPEC §2.10-#12 / 冻结表单 §5.1-⑤）。
///
/// 两个构造入口对应两个槽位：icon(WDIconName)（无姓名时的 person 占位）与 label(Text)（调用方给的首字/姓名）。
public struct WDAvatarValue: Sendable, Equatable {
  /// 图标占位（与 label 互斥）。
  let icon: WDIconName?
  /// 文字（首字或姓名；库内不推导，由调用方给）。
  let label: Text?

  /// 图标形态。
  public init(icon: WDIconName) {
    self.icon = icon
    self.label = nil
  }

  /// 文字形态。
  public init(label: Text) {
    self.label = label
    self.icon = nil
  }
}

/// 头像尺寸档（设计 12 §3：xs 20 / sm 28 / md 32 / lg 40 / xl 56）。
public enum WDAvatarSize: String, CaseIterable, Sendable, Equatable {
  case xs
  case sm
  case md
  case lg
  case xl
}

/// 头像（SPEC §2.10-#12；M2；B2 扩五档/在线/停用）。
///
/// 设计口径（设计 12）：
/// - 五档直径 20 / 28 / 32 / 40 / 56，首字号 9 / 11 / 12 / 14 / 18；
/// - 在线点 10×10、2pt 描边；离线不显示灰点；已停用整体 50% 并去饱和；
/// - 首字号按设计固定，不随动态字体放大。
///
/// **仍未表达**（已登记）：成员四色底色（设计 token 缺 4 组色值）、照片形态、
/// 在线状态并入读屏（L-B 零文案，需调用方提供措辞）。
public struct WDAvatar: View {
  private let value: WDAvatarValue
  private let size: WDAvatarSize
  private let isOnline: Bool
  private let isDisabled: Bool

  @Environment(\.wdColors) private var colors

  /// 构造（既有；默认 md 32 档，不带状态）。
  public init(value: WDAvatarValue) {
    self.init(value: value, size: .md)
  }

  /// 构造（B2 增量；五档 + 在线点 + 已停用）。
  public init(
    value: WDAvatarValue,
    size: WDAvatarSize,
    isOnline: Bool = false,
    isDisabled: Bool = false
  ) {
    self.value = value
    self.size = size
    self.isOnline = isOnline
    self.isDisabled = isDisabled
  }

  /// 圆形底 + 首字/图标 + 可选在线点。
  public var body: some View {
    ZStack {
      Circle().fill(colors.surfaceTint)
      content
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .overlay(alignment: .bottomTrailing) {
      if isOnline {
        onlineDot
      }
    }
    .opacity(isDisabled ? WDAvatarMetrics.disabledOpacity : 1)
    .saturation(isDisabled ? 0 : 1)
    .modifier(WDAvatarAccessibility(value: value))
  }

  @ViewBuilder private var content: some View {
    if let label = value.label {
      label
        .font(initialsFont)
        .foregroundStyle(colors.textOnSoft)
        .lineLimit(1)
    } else if let icon = value.icon {
      WDIcon(icon: icon, size: iconSize)
        .foregroundStyle(colors.textOnSoft)
    }
  }

  /// 在线状态点（status.success + 2pt 宿主底色描边；设计 12 §4）。
  private var onlineDot: some View {
    Circle()
      .fill(colors.statusSuccess)
      .overlay(
        Circle().strokeBorder(
          colors.surfaceCardSolid, lineWidth: WDAvatarMetrics.onlineBorderWidth)
      )
      .frame(width: onlineDotSize, height: onlineDotSize)
      .accessibilityHidden(true)
  }

  /// 在线点边长 10（设计 12 §4）。
  private var onlineDotSize: CGFloat { WDAvatarMetrics.onlineDotSize }

  /// 直径（设计 12 §3；R9 禁 frame 绑令牌，故先落变量）。
  private var diameter: CGFloat {
    WDAvatarMetrics.diameter(size)
  }

  /// 首字号（设计 12 §3，锁定不随动态字体放大）。
  private var initialsFont: Font {
    .system(size: WDAvatarMetrics.initialsSize(size))  // wd-structure-check:disable R11 — 设计字号
  }

  /// 图标档位：xs/sm → 16，md → 20，lg/xl → 24（设计未给图标档，按直径近似）。
  private var iconSize: WDIconSize {
    switch size {
    case .xs, .sm: return .sm
    case .md: return .md
    case .lg, .xl: return .lg
    }
  }
}

/// 无障碍：文字形态读调用方给的文本；图标形态是占位（装饰，不进树）。
private struct WDAvatarAccessibility: ViewModifier {
  let value: WDAvatarValue

  @ViewBuilder func body(content: Content) -> some View {
    if let label = value.label {
      content
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    } else {
      content.accessibilityHidden(true)
    }
  }
}
