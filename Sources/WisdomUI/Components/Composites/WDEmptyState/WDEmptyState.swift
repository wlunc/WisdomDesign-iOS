import SwiftUI

/// 空状态的主操作（最多一个；重试期间可进入加载态）。
public struct WDEmptyStateAction {
  /// 按钮文案（调用方给）。
  public let label: Text
  /// 是否处于加载态（重试中）。
  public let isLoading: Bool
  /// 点击动作。
  public let action: () -> Void

  /// 构造。
  public init(label: Text, isLoading: Bool = false, action: @escaping () -> Void) {
    self.label = label
    self.isLoading = isLoading
    self.action = action
  }
}

/// 空状态（SPEC §2.10-#30；设计 30）。
///
/// 圆形图标底座 56 + 标题 + 说明（最多 2 行）+ 最多一个主操作；在内容区内垂直居中由调用方负责。
/// 图标底座是装饰；整组按 标题 → 说明 → 操作 的顺序朗读。
public struct WDEmptyState: View {
  private let icon: WDIconName?
  private let title: Text
  private let message: Text?
  private let action: WDEmptyStateAction?

  @Environment(\.wdColors) private var colors

  /// 构造。
  public init(
    icon: WDIconName? = nil,
    title: Text,
    message: Text? = nil,
    action: WDEmptyStateAction? = nil
  ) {
    self.icon = icon
    self.title = title
    self.message = message
    self.action = action
  }

  /// 渲染。
  public var body: some View {
    VStack(spacing: 0) {
      if let icon {
        iconBase(icon)
          .padding(.bottom, WDSpacing.s4)
      }
      title
        .wdFont(WDType.headline)
        .foregroundStyle(colors.textPrimary)
        .multilineTextAlignment(.center)
        .wdLineBox(WDType.headline)
        .frame(maxWidth: 240)  // wd-structure-check:disable R7 — 设计 30 §3 的文本最大宽
      if let message {
        message
          .wdFont(WDType.subheadline)
          .foregroundStyle(colors.textSecondary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .wdLineBox(WDType.subheadline, lines: 2)  // wd-structure-check:disable R7 — 设计
          .frame(maxWidth: 240)  // wd-structure-check:disable R7 — 设计 30 §3 的文本最大宽
          .padding(.top, WDSpacing.s2)
      }
      if let action {
        WDButton(
          isLoading: action.isLoading,
          loadingAccessibilityText: action.label,
          action: action.action,
          label: { action.label }
        )
        .padding(.top, WDSpacing.s5)
      }
    }
    .padding(.horizontal, WDSpacing.s8)
    .padding(.top, WDSpacing.s9)
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .contain)
  }

  private func iconBase(_ icon: WDIconName) -> some View {
    ZStack {
      Circle()
        .fill(WDGradient.surface.linearGradient)
        .frame(width: 56, height: 56)  // wd-structure-check:disable R7 — 设计 30 §3 的图标底座
      WDIcon(icon: icon, size: .lg)
        .foregroundStyle(colors.textOnSoft)
    }
    .accessibilityHidden(true)
  }
}
