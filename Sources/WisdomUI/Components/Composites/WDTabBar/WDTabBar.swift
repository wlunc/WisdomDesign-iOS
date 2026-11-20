import SwiftUI

/// 标签栏一项（设计 34；值数组 `items`）。
public struct WDTabBarItem: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 图标语义名。
  public let icon: WDIconName
  /// 标签文案（设计：≤4 个汉字）。
  public let label: Text
  /// 角标（M5 增量：`WDBadgeValue` 的 label/count/dot 三种值形态）；nil = 无角标。
  public let badge: WDBadgeValue?

  /// 构造：身份 + 图标 + 标签 + 可选角标。
  public init(id: String, icon: WDIconName, label: Text, badge: WDBadgeValue? = nil) {
    self.id = id
    self.icon = icon
    self.label = label
    self.badge = badge
  }
}

/// 标签栏（SPEC §2.10-#34；M5）。
///
/// 设计口径（设计 34）：
/// - iOS 悬浮玻璃胶囊：高 **58**（令牌 `size.tab-bar` = **56**，Q3 采用令牌并登记 2pt 差）；
/// - 距左右 16、距底部安全区 8；图标 22（token 最近档 20，差 2pt 登记）；标签 10（token caption2 11）；
/// - 2–5 项等分；未选 `text.tertiary`、选中 `text.brand` + 加粗 + 4pt 圆点；
/// - **浅色悬浮 = `glass-strong`；深色端改不透明表面**（O-13：`WDGlass.resolve` + `surface.card-solid`）；
/// - 角标复用 `WDBadge` 值形态（Q7），不计入无障碍焦点。
///
/// B15 增量（设计 34 §6/§9）：只读 `wdScrollOffsetY`（nil = 不联动，默认路径像素不变）。
/// 向下滚动超过阈值 ⇒ 收起标签行（**无标签胶囊**），向上滚立即展开；选中态与热区不变，
/// 也不新增 init 参数。胶囊高度靠动态字体行盒撑开，标签行只用 `maxHeight` 压到 0，
/// 不使用固定高度、也不裁切（U7/F13）。
///
/// 角色 `tablist`/`tab` 与"第 n 项，共 m 项"（SwiftUI 无对应 trait）差异登记在
/// `docs/M5-EXIT-REPORT.md`。
public struct WDTabBar: View {
  private let items: [WDTabBarItem]
  @Binding private var selection: String

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget
  /// 滚动 offset（B15 接线件；nil = 不联动）。
  @Environment(\.wdScrollOffsetY) private var scrollOffsetY

  /// 构造：项数组 + 受控选中 id。
  public init(items: [WDTabBarItem], selection: Binding<String>) {
    self.items = items
    self._selection = selection
  }

  /// 悬浮胶囊 + 等分项目。
  public var body: some View {
    HStack(spacing: 0) {
      ForEach(items) { item in
        tabButton(item)
      }
    }
    .padding(.horizontal, WDSpacing.s3)
    .frame(minHeight: WDSize.tabbarHeight)
    // 滚动收起 = 只让标签行（图标下方那一条）逐项压到 0：胶囊高度与选中标记都不变，
    // 不会把图标一起切掉；不联动时标签行高度恒为原值 ⇒ 像素不变（U7/F13）。
    //
    // **不在这里 `.clipped()`**（B19 修复）：胶囊的 `elevation.2` 阴影画在视图边界之外，
    // 一旦裁切就整条消失（2026-11-20 快照：底边一圈阴影被吃掉，像素差 0.7%）。
    // 收起的裁切已由标签行自己的 `.frame(maxHeight: 0) + .clipped()` 完成。
    .frame(
      maxHeight: Self.isCollapsed(scrollOffsetY: scrollOffsetY) ? Self.collapsedCapsuleLimit : nil
    )
    .background(capsule)
    .padding(.horizontal, WDSpacing.s5)
    .padding(.bottom, WDSpacing.s3)
    .animation(WDMotion.Spring.gentle, value: isCollapsed)
    .accessibilityElement(children: .contain)
    .onAppear {
      assert(
        (Self.minItems...Self.maxItems).contains(items.count),
        "WDTabBar 项目数须为 2–5（设计 34 §5）"
      )
    }
  }

  // MARK: - 项目

  private func tabButton(_ item: WDTabBarItem) -> some View {
    let isSelected = item.id == selection
    let badgeText = item.badge?.accessibilityText
    return Button {
      guard !isSelected else { return }
      selection = item.id
      WDHaptics.shared.play(.toggle, budget: budget)
    } label: {
      VStack(spacing: WDSpacing.s1) {
        ZStack(alignment: .topTrailing) {
          WDIcon(icon: item.icon, size: .md)
            .foregroundStyle(isSelected ? colors.textBrand : colors.textTertiary)
          if let badge = item.badge {
            WDBadge(value: badge)
              .offset(x: Self.badgeOffsetX, y: -Self.badgeOffsetY)
          }
        }
        item.label
          .wdFont(WDType.caption2)
          .wdLineBox(WDType.caption2)
          .fontWeight(isSelected ? .semibold : .medium)
          .foregroundStyle(isSelected ? colors.textBrand : colors.textTertiary)
          .lineLimit(Self.labelLineLimit)
          // 收起时标签行压到 0：只压高度（maxHeight），宽度不动 ⇒ 标签位仍然占位、不裁字（U7）。
          .frame(maxHeight: isCollapsed ? 0 : nil)
          .clipped()
        Circle()
          .fill(isSelected ? colors.textBrand : Color.clear)
          .frame(width: Self.selectionDot, height: Self.selectionDot)
      }
      .frame(maxWidth: .infinity, minHeight: WDSize.tabbarHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    // B17：显式挂标签。此前只靠子视图合成，收起态标签被压到 0 时读屏拿不到稳定名称；
    // 标签文案由调用方给（L-B），库内不拼任何字。
    .accessibilityLabel(item.label)
    // B18：角标并入宿主朗读（设计 34 §10；`WDBadge` 自身 `accessibilityHidden`，不独立进焦点）。
    // 值文案原样透传调用方的 `Text`/计数数字，库内不拼分隔符（与 `WDListRow` 同口径）。
    .modifier(WDTabBarBadgeValue(value: badgeText))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  // MARK: - 背景

  private var capsule: some View {
    Capsule()
      .fill(containerFill)
      .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
      .overlay(topHighlight)
      .wdShadow(WDElevation.e2)
  }

  /// 浅色玻璃强档；深色端由 `WDGlass.resolve` 返回 `opaque`，改用实底（O-13）。
  private var containerFill: Color {
    switch WDGlass.resolve(
      textLevel: .secondary,
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

  @ViewBuilder private var topHighlight: some View {
    if appearance.colorScheme == .dark {
      LinearGradient(
        colors: [colors.borderGlassTop, Color.clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .clipShape(Capsule())
      .allowsHitTesting(false)
    }
  }

  // MARK: - 滚动联动（B15，纯函数便于单测）

  /// 是否收起标签行：向下滚动 offset 超过阈值 ⇒ 收起；回到阈值以内（含负值回弹）⇒ 展开。
  ///
  /// 阈值取一条标签行的安全占用（行盒 13 + 选中圆点 4）。
  static func isCollapsed(scrollOffsetY: CGFloat?) -> Bool {
    guard let scrollOffsetY else { return false }
    return scrollOffsetY > collapseThreshold
  }

  private var isCollapsed: Bool {
    Self.isCollapsed(scrollOffsetY: scrollOffsetY)
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  /// 项目数下限 2（设计 34 §5）。
  private static let minItems = 2  // wd-structure-check:disable R7 — 设计
  /// 项目数上限 5（设计 34 §5）。
  private static let maxItems = 5  // wd-structure-check:disable R7 — 设计
  /// 标签允许 2 行（U7；§2.10 矩阵的文本策略）。
  private static let labelLineLimit = 2  // wd-structure-check:disable R7 — 设计 34 §6 的两行上限
  /// 选中圆点 4pt（设计 34 §5）。
  private static let selectionDot: CGFloat = 4  // wd-structure-check:disable R7 — 设计值
  /// 角标横向偏移 10（设计未给值，取默认）。
  private static let badgeOffsetX: CGFloat = 10  // wd-structure-check:disable R7 — 设计未给值
  /// 角标纵向偏移 6（设计未给值，取默认）。
  private static let badgeOffsetY: CGFloat = 6  // wd-structure-check:disable R7 — 设计未给值
  /// 收起阈值 = 一条标签行的安全占用 17（caption2 行盒 13 + 选中圆点 4），
  /// 设计 34 §6 只写「滚动时可收缩」，未给阈值 ⇒ 取"滚过一行文字就不碍事"的档。
  private static let collapseThreshold: CGFloat = 17  // wd-structure-check:disable R7 — 设计未给值
  /// 收起态胶囊的高度上限 = 令牌 56（只挡标签行，图标与圆点在 56 内的上部，不被切）。
  private static let collapsedCapsuleLimit: CGFloat = WDSize.tabbarHeight
}

/// 角标并入宿主朗读（设计 34 §10）：有角标时给整项挂 `accessibilityValue`。
///
/// 没有角标（或角标是纯装饰圆点）⇒ 什么都不加，读屏行为与 B18 之前逐字一致。
private struct WDTabBarBadgeValue: ViewModifier {
  let value: Text?

  @ViewBuilder func body(content: Content) -> some View {
    if let value {
      content.accessibilityValue(value)
    } else {
      content
    }
  }
}
