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
  /// 操作表（底部滑入；取消键与操作列表视觉分离；空 items 在 debug 下断言）。
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

private struct WDActionSheetModifier: ViewModifier {
  @Binding var isPresented: Bool
  let title: Text?
  let message: Text?
  let items: [WDActionSheetItem]
  let onSelect: (WDActionSheetItem.ID) -> Void
  let onCancel: (() -> Void)?

  @Environment(\.wdColors) private var colors

  func body(content anchor: Content) -> some View {
    anchor.sheet(isPresented: $isPresented) {
      actionSheet
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(WDRadius.xxl)
        .presentationBackground(colors.surfaceCardSolid)
    }
  }

  private var actionSheet: some View {
    VStack(spacing: 0) {
      header
      VStack(spacing: 0) {
        ForEach(regularItems) { item in
          row(item)
          if item.id != regularItems.last?.id {
            Divider().overlay(colors.borderHairline)
          }
        }
      }
      if let cancelItem {
        Divider().overlay(colors.borderHairline).padding(.top, WDSpacing.s3)
        row(cancelItem)
      }
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .onAppear {
      assert(!items.isEmpty, "WDActionSheet items 不能为空（设计 27 §4）")
    }
  }

  @ViewBuilder private var header: some View {
    if title != nil || message != nil {
      VStack(spacing: WDSpacing.s2) {
        if let title {
          title
            .wdFont(WDType.headline)
            .foregroundStyle(colors.textPrimary)
            .multilineTextAlignment(.center)
            .wdLineBox(WDType.headline)
        }
        if let message {
          message
            .wdFont(WDType.footnote)
            .foregroundStyle(colors.textSecondary)
            .multilineTextAlignment(.center)
            .wdLineBox(WDType.footnote)
        }
      }
      .padding(.horizontal, WDSpacing.s5)
      .padding(.top, WDSpacing.s5)
      .padding(.bottom, WDSpacing.s4)
    }
  }

  private func row(_ item: WDActionSheetItem) -> some View {
    Button {
      if item.role == .cancel {
        isPresented = false
        onCancel?()
      } else {
        isPresented = false
        onSelect(item.id)
      }
    } label: {
      item.label
        .wdFont(WDType.body)
        .foregroundStyle(color(for: item.role))
        .frame(maxWidth: .infinity, minHeight: WDSize.controlMd)
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
    items.filter { $0.role != .cancel }
  }

  private var cancelItem: WDActionSheetItem? {
    items.first { $0.role == .cancel }
  }
}

private struct WDActionSheetRowStyle: ButtonStyle {
  let pressedFill: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? pressedFill : .clear)
  }
}
