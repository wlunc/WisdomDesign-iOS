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
/// 角色 `tablist`/`tab` 与"第 n 项，共 m 项"（SwiftUI 无对应 trait）差异登记在
/// `docs/M5-EXIT-REPORT.md`。
public struct WDTabBar: View {
  private let items: [WDTabBarItem]
  @Binding private var selection: String

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

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
    .background(capsule)
    .padding(.horizontal, WDSpacing.s5)
    .padding(.bottom, WDSpacing.s3)
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
        Circle()
          .fill(isSelected ? colors.textBrand : Color.clear)
          .frame(width: Self.selectionDot, height: Self.selectionDot)
      }
      .frame(maxWidth: .infinity, minHeight: WDSize.tabbarHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
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
}
