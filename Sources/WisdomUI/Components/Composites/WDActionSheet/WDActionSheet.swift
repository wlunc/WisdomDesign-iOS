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
  /// 可选前置图标（设计 27 §4 的「带图标」变体，20pt）。
  public let icon: WDIconName?

  /// 构造。
  public init(id: String, label: Text, role: Role = .default, icon: WDIconName? = nil) {
    self.id = id
    self.label = label
    self.role = role
    self.icon = icon
  }
}

extension View {
  /// 操作表（底部浮层；取消为独立圆角卡片；空 items 在 debug 下断言）。
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
      listCard
      if let cancelItem {
        Button {
          onCancel?()
        } label: {
          cancelItem.label
            .wdFont(WDType.callout)
            .fontWeight(.semibold)
            .foregroundStyle(colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: WDSpacing.s10)
            .wdLineBox(WDType.callout)
            .contentShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
        }
        .buttonStyle(WDActionSheetRowStyle(pressedFill: colors.fillPressed))
        .background(
          RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
            .fill(colors.surfaceCardSolid)
        )
        .overlay(
          RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
            .stroke(colors.borderHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
        .wdShadow(WDElevation.e2)
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

  private var listCard: some View {
    VStack(spacing: 0) {
      if title != nil || message != nil {
        header
      }
      ForEach(regularItems) { item in
        row(item)
        if item.id != regularItems.last?.id {
          Divider().overlay(colors.borderHairline)
        }
      }
    }
    .background(colors.surfaceCardSolid)
    .clipShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
        .stroke(colors.borderHairline, lineWidth: 1)
    )
    .wdShadow(WDElevation.e3)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s1) {
      if let title {
        title
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
          .wdLineBox(WDType.caption1)
      }
      if let message {
        message
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
          .wdLineBox(WDType.caption1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, WDSpacing.s5)
    .padding(.top, WDSpacing.s4)
    .padding(.bottom, WDSpacing.s3)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(colors.borderHairline)
        .frame(height: 1)
    }
  }

  private func row(_ item: WDActionSheetItem) -> some View {
    Button {
      onSelect(item.id)
    } label: {
      HStack(spacing: WDSpacing.s3 + WDSpacing.s1) {
        if let icon = item.icon {
          WDIcon(icon: icon, size: .md)
            .foregroundStyle(iconColor(for: item.role))
            .accessibilityHidden(true)
        }
        item.label
          .wdFont(WDType.callout)
          .foregroundStyle(color(for: item.role))
          .wdLineBox(WDType.callout)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, WDSpacing.s5)
      .frame(maxWidth: .infinity, minHeight: WDSize.controlMd)
      .contentShape(Rectangle())
    }
    .buttonStyle(WDActionSheetRowStyle(pressedFill: colors.fillPressed))
  }

  private func color(for role: WDActionSheetItem.Role) -> Color {
    switch role {
    case .`default`: return colors.textPrimary
    case .destructive: return colors.statusDanger
    case .cancel: return colors.textPrimary
    }
  }

  private func iconColor(for role: WDActionSheetItem.Role) -> Color {
    role == .destructive ? colors.statusDanger : colors.textTertiary
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

}

private struct WDActionSheetModifier: ViewModifier {
  @Binding var isPresented: Bool
  let title: Text?
  let message: Text?
  let items: [WDActionSheetItem]
  let onSelect: (WDActionSheetItem.ID) -> Void
  let onCancel: (() -> Void)?

  func body(content anchor: Content) -> some View {
    anchor
      .onAppear {
        if isPresented {
          present()
        }
      }
      .onChange(of: isPresented) { _, presented in
        if presented {
          present()
        } else {
          WDActionSheetPresenter.shared.dismiss()
        }
      }
      .onDisappear {
        WDActionSheetPresenter.shared.dismiss()
      }
  }

  private func present() {
    WDActionSheetPresenter.shared.present(
      WDActionSheetLayer(
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
