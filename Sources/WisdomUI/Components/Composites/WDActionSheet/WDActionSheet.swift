import SwiftUI

/// 操作表选项（不是 Hashable：含 Text）。
public struct WDActionSheetItem: Identifiable, Sendable, Equatable {
  /// 选项角色。
  public enum Role: Sendable, Equatable {
    case `default`
    case destructive
    case cancel
  }

  /// 稳定身份。
  public let id: String
  /// 标签文案（调用方给）。
  public let label: Text
  /// 角色。
  public let role: Role

  /// 构造。
  public init(id: String, label: Text, role: Role = .default) {
    self.id = id
    self.label = label
    self.role = role
  }
}

extension View {
  /// 操作表（底部浮层；取消为独立胶囊；空 items 在 debug 下断言）。
  public func wdActionSheet(
    isPresented: Binding<Bool>,
    title: Text? = nil,
    message: Text? = nil,
    items: [WDActionSheetItem],
    onSelect: @escaping (WDActionSheetItem.ID) -> Void,
    onCancel: (() -> Void)? = nil
  ) -> some View {
    modifier(
      WDActionSheetModifier(
        isPresented: isPresented,
        title: title,
        message: message,
        items: items,
        onSelect: onSelect,
        onCancel: onCancel
      )
    )
  }
}

/// 操作表内容（与系统 sheet 解耦，便于快照与组合；内部类型）。
struct WDActionSheetPanel: View {
  let title: Text?
  let message: Text?
  let items: [WDActionSheetItem]
  let onSelect: (WDActionSheetItem.ID) -> Void
  let onCancel: (() -> Void)?

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(spacing: 0) {
      if title != nil || message != nil {
        header
      }
      listCard
      if let cancelItem {
        Button {
          onCancel?()
        } label: {
          cancelItem.label
            .wdFont(WDType.body)
            .foregroundStyle(colors.textBrand)
            .frame(maxWidth: .infinity, minHeight: WDSpacing.s10)
            .wdLineBox(WDType.body)
            .contentShape(Capsule())
        }
        .buttonStyle(WDActionSheetRowStyle(pressedFill: colors.fillPressed))
        .background(Capsule().fill(colors.surfaceCardSolid))
        .clipShape(Capsule())
        .padding(.top, WDSpacing.s3)
      }
    }
    .padding(.horizontal, WDSpacing.s5)
    .padding(.top, WDSpacing.s5)
    .padding(.bottom, WDSpacing.s3)
    .onAppear {
      assert(!items.isEmpty, "WDActionSheet items 不能为空（设计 27 §4）")
    }
  }

  private var header: some View {
    VStack(spacing: WDSpacing.s2) {
      if let title {
        title
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textSecondary)
          .multilineTextAlignment(.center)
          .wdLineBox(WDType.footnote)
      }
      if let message {
        message
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
          .multilineTextAlignment(.center)
          .wdLineBox(WDType.caption1)
      }
    }
    .padding(.bottom, WDSpacing.s4)
  }

  private var listCard: some View {
    VStack(spacing: 0) {
      ForEach(regularItems) { item in
        row(item)
        if item.id != regularItems.last?.id {
          Divider()
            .overlay(colors.borderHairline)
            .padding(.leading, WDSpacing.s5)
        }
      }
    }
    .background(colors.surfaceCardSolid)
    .clipShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
  }

  private func row(_ item: WDActionSheetItem) -> some View {
    Button {
      onSelect(item.id)
    } label: {
      item.label
        .wdFont(WDType.body)
        .foregroundStyle(color(for: item.role))
        .frame(maxWidth: .infinity, minHeight: WDSize.controlMd)
        .padding(.horizontal, WDSpacing.s5)
        .wdLineBox(WDType.body)
        .contentShape(Rectangle())
    }
    .buttonStyle(WDActionSheetRowStyle(pressedFill: colors.fillPressed))
  }

  private func color(for role: WDActionSheetItem.Role) -> Color {
    switch role {
    case .`default`: return colors.textPrimary
    case .destructive: return colors.statusDanger
    case .cancel: return colors.textBrand
    }
  }

  private var regularItems: [WDActionSheetItem] {
    Self.regularItems(from: items)
  }

  private var cancelItem: WDActionSheetItem? {
    Self.cancelItem(from: items)
  }

  static func regularItems(from items: [WDActionSheetItem]) -> [WDActionSheetItem] {
    items.enumerated()
      .filter { $0.element.role != .cancel }
      .sorted { lhs, rhs in
        let left = lhs.element.role == .destructive ? 1 : 0
        let right = rhs.element.role == .destructive ? 1 : 0
        if left != right { return left < right }
        return lhs.offset < rhs.offset
      }
      .map(\.element)
  }

  static func cancelItem(from items: [WDActionSheetItem]) -> WDActionSheetItem? {
    items.first { $0.role == .cancel }
  }

  /// sheet 高度估算：面板内距 + 标题/说明 + 操作列表 + 取消胶囊。
  static func estimatedHeight(
    title: Text?,
    message: Text?,
    items: [WDActionSheetItem],
    dynamicTypeSize: DynamicTypeSize
  ) -> CGFloat {
    var height = WDSpacing.s5 + WDSpacing.s3
    if title != nil || message != nil {
      if title != nil {
        height += WDFontMetrics.lineBoxHeight(
          for: WDType.footnote, dynamicTypeSize: dynamicTypeSize)
      }
      if message != nil {
        height +=
          WDSpacing.s2
          + WDFontMetrics.lineBoxHeight(for: WDType.caption1, dynamicTypeSize: dynamicTypeSize)
      }
      height += WDSpacing.s4
    }
    let rows = regularItems(from: items).count
    height += CGFloat(rows) * WDSize.controlMd
    height += CGFloat(max(0, rows - 1)) * 1
    if cancelItem(from: items) != nil {
      height += WDSpacing.s3 + WDSpacing.s10
    }
    return height
  }
}

private struct WDActionSheetModifier: ViewModifier {
  @Binding var isPresented: Bool
  let title: Text?
  let message: Text?
  let items: [WDActionSheetItem]
  let onSelect: (WDActionSheetItem.ID) -> Void
  let onCancel: (() -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  func body(content anchor: Content) -> some View {
    anchor.sheet(isPresented: $isPresented) {
      WDActionSheetPanel(
        title: title,
        message: message,
        items: items,
        onSelect: { id in
          isPresented = false
          onSelect(id)
        },
        onCancel: {
          isPresented = false
          onCancel?()
        }
      )
      .presentationDetents([.height(contentHeight)])
      .presentationDragIndicator(.hidden)
      .presentationCornerRadius(WDRadius.xxl)
      .presentationBackground(colors.bgGrouped)
    }
  }

  private var contentHeight: CGFloat {
    WDActionSheetPanel.estimatedHeight(
      title: title,
      message: message,
      items: items,
      dynamicTypeSize: dynamicTypeSize
    )
  }
}

private struct WDActionSheetRowStyle: ButtonStyle {
  let pressedFill: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? pressedFill : .clear)
  }
}
