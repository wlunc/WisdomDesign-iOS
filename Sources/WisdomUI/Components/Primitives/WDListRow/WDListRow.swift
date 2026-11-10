import SwiftUI

/// 列表行行首槽（SPEC §2.4）。
public enum WDListRowLeading: Sendable, Equatable {
  /// 无前导。
  case none
  /// 图标底座（34×34）。
  case icon(WDIconName)
  /// 头像。
  case avatar(WDAvatarValue)
  /// 勾选框（按行的选中态显示，用于任务行）。
  case checkbox
  /// 单选指示圆点。
  case selectionIndicator
}

/// 列表行行尾槽（SPEC §2.4；最多一个）。
public enum WDListRowTrailing: Sendable, Equatable {
  /// 无尾部。
  case none
  /// 值文本（右对齐）。
  case value(Text)
  /// 徽标。
  case badge(WDBadgeValue)
  /// 头像。
  case avatar(WDAvatarValue)
  /// 进入下一级的箭头。
  case disclosure
}

/// 滑动动作（含闭包 ⇒ `@MainActor`，不声明 `Equatable`；SPEC §2.4）。
@MainActor public enum WDListRowSwipeAction {
  /// 无滑动动作。
  case none
  /// 左滑删除（在 `List`/`ForEach` 内生效；`ScrollView` 里会被系统忽略）。
  case delete(title: Text, onDelete: () -> Void)
}

/// 列表行（SPEC §2.4；M2）。
///
/// 设计口径（设计 18）：行高 **44 / 60 / 76**（`max(密度下限, 槽位派生)`；密度取
/// `size.row-height.{comfortable,compact}` = 60/44）；水平内距 16、槽间距 12；分隔线从文本区
/// 起始内缩（62 = 16 + 34 + 12）；选中 = 左侧 3pt 品牌条 + `brand` 8% 底；整行合并读。
///
/// 冻结签名（7 参）不变；`action == nil` 时**不加按钮语义、不设热区、不可聚焦**。
public struct WDListRow: View {
  private let title: Text
  private let subtitle: Text?
  private let leading: WDListRowLeading
  private let trailing: WDListRowTrailing
  private let isSelected: Bool
  private let swipeAction: WDListRowSwipeAction
  private let showsSeparator: Bool
  private let action: (() -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdDensity) private var density
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造（7 参；已删除 `tertiary`）。
  public init(
    title: Text,
    subtitle: Text? = nil,
    leading: WDListRowLeading = .none,
    trailing: WDListRowTrailing = .none,
    isSelected: Bool = false,
    swipeAction: WDListRowSwipeAction = .none,
    showsSeparator: Bool = true,
    action: (() -> Void)? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.leading = leading
    self.trailing = trailing
    self.isSelected = isSelected
    self.swipeAction = swipeAction
    self.showsSeparator = showsSeparator
    self.action = action
  }

  /// 行内容；可点时包真 `Button`（pressed 唯一来源），否则纯内容。
  public var body: some View {
    Group {
      if let action {
        Button {
          WDHaptics.shared.play(.press, budget: budget)
          action()
        } label: {
          rowContent.contentShape(Rectangle())
        }
        .buttonStyle(WDListRowButtonStyle())
      } else {
        rowContent
      }
    }
    .modifier(WDListRowSwipe(swipe: swipeAction))
    .modifier(WDListRowCustomAction(swipe: swipeAction))
  }

  // MARK: - 内容

  private var rowContent: some View {
    HStack(spacing: WDSpacing.s4) {
      leadingView
      VStack(alignment: .leading, spacing: WDSpacing.s1) {
        titleView
        if let subtitle {
          subtitleView(subtitle)
        }
      }
      Spacer(minLength: 0)
      trailingView
    }
    .padding(.horizontal, WDSpacing.s5)
    .frame(minHeight: rowHeight, alignment: .leading)
    .background(rowBackground)
    .overlay(alignment: .leading) { selectionBar }
    .overlay(alignment: .bottom) { separatorView }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder private var leadingView: some View {
    switch leading {
    case .none:
      EmptyView()
    case .icon(let icon):
      RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
        .fill(colors.surfaceTint)
        .frame(width: Self.leadingBase, height: Self.leadingBase)
        .overlay {
          WDIcon(icon: icon, size: .md)
            .foregroundStyle(colors.textOnSoft)
        }
    case .avatar(let value):
      WDAvatar(value: value)
    case .checkbox:
      WDCheckboxBox(isChecked: isSelected)
    case .selectionIndicator:
      selectionIndicatorView
    }
  }

  private var selectionIndicatorView: some View {
    Circle()
      .stroke(colors.borderHairlineStrong, lineWidth: 1)
      .frame(width: Self.indicatorSize, height: Self.indicatorSize)
      .overlay {
        if isSelected {
          Circle()
            .fill(colors.textBrand)
            .frame(width: Self.indicatorInner, height: Self.indicatorInner)
        }
      }
  }

  private var titleView: some View {
    title
      .wdFont(WDType.subheadline)
      .wdLineBox(WDType.subheadline)
      .foregroundStyle(colors.textPrimary)
      .lineLimit(1)
  }

  private func subtitleView(_ subtitle: Text) -> some View {
    subtitle
      .wdFont(WDType.caption1)
      .wdLineBox(WDType.caption1)
      .foregroundStyle(colors.textSecondary)
      .lineLimit(1)
  }

  @ViewBuilder private var trailingView: some View {
    switch trailing {
    case .none:
      EmptyView()
    case .value(let value):
      value
        .wdFont(WDType.footnote)
        .wdLineBox(WDType.footnote)
        .foregroundStyle(colors.textSecondary)
        .monospacedDigit()
        .lineLimit(1)
    case .badge(let value):
      WDBadge(label: value.label)
    case .avatar(let value):
      WDAvatar(value: value)
    case .disclosure:
      WDIcon(icon: .disclose, size: .sm)
        .foregroundStyle(colors.textTertiary)
    }
  }

  // MARK: - 行高 / 状态

  /// 行高 = `max(密度下限, 槽位派生)`（SPEC §2.4-2）。
  private var rowHeight: CGFloat {
    let slots: CGFloat
    if subtitle == nil {
      slots = WDSize.rowHeightCompact
    } else if hasTrailingValue {
      slots = Self.tripleRowHeight
    } else {
      slots = WDSize.rowHeightComfortable
    }
    return max(density.rowMinHeight, slots)
  }

  /// 76 档的触发条件 = "有副标题且有尾部文本/徽标/头像"（SPEC §2.4-1）。
  private var hasTrailingValue: Bool {
    switch trailing {
    case .value, .badge, .avatar: return true
    case .none, .disclosure: return false
    }
  }

  private var rowBackground: Color {
    isSelected ? colors.textBrand.opacity(Self.selectedTintAlpha) : Color.clear
  }

  @ViewBuilder private var selectionBar: some View {
    if isSelected {
      Rectangle()
        .fill(colors.textBrand)
        .frame(width: Self.selectionBarWidth)
    }
  }

  @ViewBuilder private var separatorView: some View {
    if showsSeparator {
      Rectangle()
        .fill(colors.borderHairline)
        .frame(height: 1)
        .padding(.leading, separatorInset)
    }
  }

  /// 分隔线左内缩：有前导 = 16 + 34 + 12；无前导 = 16。
  private var separatorInset: CGFloat {
    switch leading {
    case .none: return WDSpacing.s5
    default: return WDSpacing.s5 + Self.leadingBase + WDSpacing.s4
    }
  }

  /// 76 三行档（设计 18；无令牌）。
  private static let tripleRowHeight: CGFloat = 76  // wd-structure-check:disable R7 — 设计值
  /// 图标底座边长（设计 18；无令牌）。
  private static let leadingBase: CGFloat = 34  // wd-structure-check:disable R7 — 设计值
  /// 单选指示圆点直径。
  private static let indicatorSize: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
  /// 单选指示内点直径。
  private static let indicatorInner: CGFloat = 10  // wd-structure-check:disable R7 — 设计值
  /// 选中态左侧品牌条宽（设计 18：3pt）。
  private static let selectionBarWidth: CGFloat = 3  // wd-structure-check:disable R7 — 设计值
  /// 选中态品牌底透明度（设计 18：8%）。
  private static let selectedTintAlpha: CGFloat = 0.08  // wd-structure-check:disable R7 — 设计值
}

/// 按下反馈：整行 `fill.pressed`（100ms）；用 `ButtonStyle` 拿 pressed。
private struct WDListRowButtonStyle: ButtonStyle {
  @Environment(\.wdColors) private var colors

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? colors.fillPressed : Color.clear)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}

/// 左滑删除（只在 `List`/`ForEach` 内生效；`ScrollView`+`VStack` 里系统会静默忽略）。
private struct WDListRowSwipe: ViewModifier {
  let swipe: WDListRowSwipeAction

  @ViewBuilder func body(content: Content) -> some View {
    if case .delete(let title, let onDelete) = swipe {
      content.swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive, action: onDelete) { title }
      }
    } else {
      content
    }
  }
}

/// 左滑只是快捷方式：另给一条"删除"自定义无障碍操作（设计 18 的无障碍要求）。
private struct WDListRowCustomAction: ViewModifier {
  let swipe: WDListRowSwipeAction

  @ViewBuilder func body(content: Content) -> some View {
    if case .delete(let title, let onDelete) = swipe {
      content.accessibilityAction(named: title) { onDelete() }
    } else {
      content
    }
  }
}
