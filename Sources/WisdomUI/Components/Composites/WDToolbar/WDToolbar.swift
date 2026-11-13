import SwiftUI

/// 工具栏按钮（设计 35；值数组 `items`）。
public struct WDToolbarItem: Identifiable {
  /// 稳定身份。
  public let id: String
  /// 图标语义名。
  public let icon: WDIconName
  /// 读屏标签（必填；图标按钮必须有标签）。
  public let accessibilityLabel: Text
  /// 选中态（如"加粗"已启用）。
  public let isSelected: Bool
  /// 可用态（禁用按钮保持显示，不隐藏整条工具栏）。
  public let isEnabled: Bool
  /// 动作。
  public let action: () -> Void

  /// 构造：身份 + 图标 + 标签 + 状态 + 动作。
  public init(
    id: String,
    icon: WDIconName,
    accessibilityLabel: Text,
    isSelected: Bool = false,
    isEnabled: Bool = true,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.isSelected = isSelected
    self.isEnabled = isEnabled
    self.action = action
  }
}

/// 工具栏（SPEC §2.10-#35；M5）。
///
/// 设计口径（设计 35）：
/// - 容器高 **48**、内边距 6、圆角 `radius.full`；按钮视觉 36×36、图标 20、热区 ≥44；
/// - 默认 `surface.glass-strong` + hairline + `elevation.1`；选中 = `gradient.mid` + 白图标；
/// - 最多 7 个操作，超过收进「更多」菜单；无可用操作时按钮禁用、**不隐藏整条工具栏**；
/// - 整条工具栏有分组标签（`accessibilityLabel`），每个按钮独立标签。
public struct WDToolbar: View {
  private let items: [WDToolbarItem]
  private let accessibilityLabel: Text
  private let overflowAccessibilityLabel: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：项数组 + 分组标签 + 溢出菜单标签。
  public init(
    items: [WDToolbarItem],
    accessibilityLabel: Text,
    overflowAccessibilityLabel: Text? = nil
  ) {
    self.items = items
    self.accessibilityLabel = accessibilityLabel
    self.overflowAccessibilityLabel = overflowAccessibilityLabel
  }

  /// 胶囊容器 + 按钮 / 溢出菜单。
  public var body: some View {
    HStack(spacing: WDSpacing.s2) {
      ForEach(visibleItems) { item in
        itemButton(item)
      }
      if let overflowAccessibilityLabel, !overflowItems.isEmpty {
        overflowMenu(overflowAccessibilityLabel)
      }
    }
    .padding(.horizontal, Self.horizontalPadding)
    .padding(.vertical, Self.verticalPadding)
    .frame(minHeight: Self.containerHeight)
    .background(
      Capsule()
        .fill(colors.surfaceGlassStrong)
        .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
        .wdShadow(WDElevation.e1)
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel(accessibilityLabel)
  }

  // MARK: - 零件

  private func itemButton(_ item: WDToolbarItem) -> some View {
    Button {
      guard item.isEnabled else { return }
      WDHaptics.shared.play(.press, budget: budget)
      item.action()
    } label: {
      WDIcon(icon: item.icon, size: .md)
        .foregroundStyle(item.isSelected ? colors.textOnDark : colors.textPrimary)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .background(
          RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
            .fill(
              item.isSelected
                ? AnyShapeStyle(WDGradient.mid.linearGradient) : AnyShapeStyle(Color.clear))
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!item.isEnabled)
    .opacity(item.isEnabled ? 1 : disabledOpacity)
    .accessibilityLabel(item.accessibilityLabel)
    .accessibilityAddTraits(item.isSelected ? .isSelected : [])
  }

  private func overflowMenu(_ label: Text) -> some View {
    Menu {
      ForEach(overflowItems) { item in
        Button {
          guard item.isEnabled else { return }
          item.action()
        } label: {
          item.accessibilityLabel
        }
        .disabled(!item.isEnabled)
      }
    } label: {
      WDIcon(icon: .more, size: .md)
        .foregroundStyle(colors.textPrimary)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .accessibilityLabel(label)
  }

  // MARK: - 计算

  /// 视觉上最多 7 个操作（6 个按钮 + 「更多」）。
  private var visibleItems: [WDToolbarItem] {
    overflowItems.isEmpty ? items : Array(items.prefix(Self.maxVisibleItems - 1))
  }

  private var overflowItems: [WDToolbarItem] {
    items.count > Self.maxVisibleItems ? Array(items.dropFirst(Self.maxVisibleItems - 1)) : []
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 容器高 48（设计 35 §3）。
  private static let containerHeight: CGFloat = 48  // wd-structure-check:disable R7 — 设计值
  /// 容器水平内边距 6（设计 35 §3）。
  private static let horizontalPadding: CGFloat = 6  // wd-structure-check:disable R7 — 设计值
  /// 容器垂直内边距 2（44 热区 + 2×2 = 48；设计视觉按钮 36 + 6×2 = 48，热区优先）。
  private static let verticalPadding: CGFloat = 2  // wd-structure-check:disable R7 — 热区推导
  /// 最多 7 个操作（设计 35 §7）。
  private static let maxVisibleItems = 7  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}
