import SwiftUI

/// 头像的值形态（`WDAvatar` 的载荷；SPEC §2.10-#12 / 冻结表单 §5.1-⑤）。
///
/// 两个构造入口对应两个槽位：`icon(WDIconName)`（无姓名时的 `person` 占位）与 `label(Text)`（调用方给的首字/姓名）。
public struct WDAvatarValue: Sendable, Equatable {
  /// 图标占位（与 `label` 互斥）。
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

/// 头像（SPEC §2.10-#12；M2）。
///
/// 设计口径（设计 12）：圆形底 + 首字/图标；默认档 **md 32**、首字号 **12**；同一成员的配色在任何页面一致。
///
/// 冻结签名只有 `init(value:)`（**直径锁死**，无 size 参数）⇒ 本实现只做 md 32 档、中性底
/// （`surface.tint` + `text.on-soft`）。五档直径、按成员 ID 分配底色、在线点、停用态与照片形态
/// 都**不可表达**，差异登记在 `docs/DEV-PLAN.md` §2.3。首字号按设计固定（不随动态字体放大）。
public struct WDAvatar: View {
  private let value: WDAvatarValue
  private let diameter: CGFloat

  @Environment(\.wdColors) private var colors

  /// 构造（公开：md 32 档，直径锁死）。
  public init(value: WDAvatarValue) {
    self.value = value
    diameter = Self.mdDiameter
  }

  /// 内部构造：供 `WDAvatarStack` 的 sm 28 档复用同一套渲染。
  init(value: WDAvatarValue, diameter: CGFloat) {
    self.value = value
    self.diameter = diameter
  }

  /// 圆形底 + 首字/图标。
  public var body: some View {
    ZStack {
      Circle().fill(colors.surfaceTint)
      content
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .modifier(WDAvatarAccessibility(value: value))
  }

  @ViewBuilder private var content: some View {
    if let label = value.label {
      label
        .font(initialsFont)
        .foregroundStyle(colors.textOnSoft)
        .lineLimit(1)
    } else if let icon = value.icon {
      WDIcon(icon: icon, size: .md)
        .foregroundStyle(colors.textOnSoft)
    }
  }

  /// md 直径（设计 12：`size.avatar.md` = 32；R9 禁 `frame` 绑令牌，故在此落值）。
  private static let mdDiameter: CGFloat = 32  // wd-structure-check:disable R7 — 设计 md 直径
  /// 首字号 = 直径 × 0.375（md 32 → 12，sm 28 → 10.5；设计只给 md 12）。
  private var initialsSize: CGFloat {
    diameter * Self.initialsRatio
  }

  /// 首字字体（设计 12 锁定字号，不随动态字体放大）。
  private var initialsFont: Font {
    .system(size: initialsSize)  // wd-structure-check:disable R11 — 设计字号
  }
  /// 首字号与直径的比例（md 32 → 12）。
  private static let initialsRatio: CGFloat = 0.375  // wd-structure-check:disable R7 — 设计比例
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
