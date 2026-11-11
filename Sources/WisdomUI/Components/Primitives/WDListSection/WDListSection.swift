import SwiftUI

/// 分组标题右侧的**分组级动作**（设计 19 §2：最多一个，`text.brand`）。
///
/// **DRAFT**：`WDListSection` 的签名仍待 ios-lead 确认（`docs/M3-SIGNATURE-FREEZE.md`），
/// 确认前不得合并到 `main`。
public struct WDListSectionAction {
  /// 动作文案（由调用方给，库内零文案）。
  public let label: Text
  /// 点击动作。
  public let action: () -> Void

  /// 构造：文案 + 动作。
  public init(label: Text, action: @escaping () -> Void) {
    self.label = label
    self.action = action
  }
}

/// 行上下文：由 `WDListSection` 计算后传给行构建器。
///
/// 数据驱动的 `items` 让"空组隐藏"与"末行无分隔"可被机器保证：
/// - `isSelected` = `selection.contains(item.id)`；
/// - `isLast` = 该行是组内最后一行 ⇒ 行自己应传 `showsSeparator: false`。
public struct WDListSectionRowContext: Sendable, Equatable {
  /// 该行是否在 `selection` 中。
  public let isSelected: Bool
  /// 该行是否为组内最后一行。
  public let isLast: Bool

  /// 构造：选中 + 末行。
  public init(isSelected: Bool, isLast: Bool) {
    self.isSelected = isSelected
    self.isLast = isLast
  }
}

/// 列表分组（SPEC §2.10-#19；M3）。
///
/// 设计口径（设计 19）：
/// - 标题 `overline`（12 · 500 · 字距 +0.6）、`text.secondary`，左侧额外缩进 `space.1`；
/// - 标题右侧可选**一个**动作（`text.brand`）；
/// - 内容容器 = 一个卡片（`surface.card` + `radius.xl` + hairline + `elevation.1`）；
/// - 页脚 `footnote`、`text.secondary`；
/// - **空分组整组隐藏**（连标题/动作/页脚）；
/// - 组内行由调用方提供；末行由 `WDListSectionRowContext.isLast` 告知，行自己关分隔线。
///
/// **DRAFT**：签名待 ios-lead 确认（`docs/M3-SIGNATURE-FREEZE.md`），确认前不得合并到 `main`。
public struct WDListSection<Item: Identifiable, Row: View, Footer: View>: View {
  private let items: [Item]
  private let selection: Set<Item.ID>
  private let header: Text
  private let headerAction: WDListSectionAction?
  private let row: (Item, WDListSectionRowContext) -> Row
  private let footer: Footer

  @Environment(\.wdColors) private var colors

  /// 构造：数据 + 选中集合 + 标题 + 可选动作 + 行构建器 + 页脚。
  public init(
    items: [Item],
    selection: Set<Item.ID> = [],
    header: Text,
    headerAction: WDListSectionAction? = nil,
    @ViewBuilder row: @escaping (Item, WDListSectionRowContext) -> Row,
    @ViewBuilder footer: () -> Footer
  ) {
    self.items = items
    self.selection = selection
    self.header = header
    self.headerAction = headerAction
    self.row = row
    self.footer = footer()
  }

  /// 渲染：空数组 ⇒ 整组隐藏（不出现空标题/空页脚）。
  @ViewBuilder public var body: some View {
    if items.isEmpty {
      EmptyView()
    } else {
      VStack(alignment: .leading, spacing: 0) {
        headerRow
          .padding(.bottom, WDSpacing.s3)
        card
        footerRow
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .contain)
    }
  }

  // MARK: - 头部

  private var headerRow: some View {
    HStack(spacing: WDSpacing.s2) {
      header
        .wdFont(WDType.overline)
        .foregroundStyle(colors.textSecondary)
        .accessibilityAddTraits(.isHeader)
      Spacer(minLength: WDSpacing.s3)
      if let headerAction {
        Button(action: headerAction.action) {
          headerAction.label
            .wdFont(WDType.footnote)
            .foregroundStyle(colors.textBrand)
        }
        .buttonStyle(.plain)
        .frame(minHeight: WDSize.touchTargetMin)
      }
    }
    .padding(.leading, WDSpacing.s5 + WDSpacing.s1)
    .frame(minHeight: headerAction == nil ? nil : WDSize.touchTargetMin, alignment: .leading)
  }

  // MARK: - 内容卡片

  private var card: some View {
    VStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        row(
          item,
          WDListSectionRowContext(
            isSelected: selection.contains(item.id),
            isLast: index == items.count - 1
          )
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(colors.surfaceCard)
    .clipShape(shape)
    .overlay(shape.stroke(colors.borderHairline, lineWidth: 1))
    .wdShadow(WDElevation.e1)
  }

  // MARK: - 页脚

  @ViewBuilder private var footerRow: some View {
    if Footer.self == EmptyView.self {
      EmptyView()
    } else {
      footer
        .wdFont(WDType.footnote)
        .foregroundStyle(colors.textSecondary)
        .padding(.leading, WDSpacing.s5)
        .padding(.top, WDSpacing.s2)
    }
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
  }
}

extension WDListSection where Footer == EmptyView {
  /// 构造：无页脚（设计 19 的「页脚可选」）。
  public init(
    items: [Item],
    selection: Set<Item.ID> = [],
    header: Text,
    headerAction: WDListSectionAction? = nil,
    @ViewBuilder row: @escaping (Item, WDListSectionRowContext) -> Row
  ) {
    self.init(
      items: items,
      selection: selection,
      header: header,
      headerAction: headerAction,
      row: row,
      footer: { EmptyView() }
    )
  }
}
