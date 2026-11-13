import SwiftUI

/// 搜索框（SPEC §2.10-#04；M5）。
///
/// 设计口径（设计 04）：
/// - 高度 **46**（`WDSize.fieldHeight`，与 `WDTextField` 同高）、圆角 `radius.full`、水平内距 12；
/// - 前导搜索图标 `size.icon.md`（`text.tertiary`），位置固定；
/// - 有值时出现清除按钮（保持聚焦）；带取消变体在聚焦时展开取消按钮，容器宽度收窄、列表不位移；
/// - 聚焦描边 `text.brand` 1.5pt + 18% 光环（`motion.duration.fast` 160ms）。
///
/// 库内零文案：占位符、清除按钮标签、取消按钮标签全部由调用方以 `Text` 传入；
/// 结果数变化的 polite 播报与 300ms 防抖属调用方（设计 04 §8/§10）。
public struct WDSearchField: View {
  @Binding private var text: String
  private let placeholder: Text
  private let leadingIcon: WDIconName
  private let clearAccessibilityLabel: Text
  private let cancelLabel: Text?
  private let onCancel: (() -> Void)?
  private let onSubmit: (() -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @FocusState private var isFocused: Bool

  /// 标准变体（无取消按钮）。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    onSubmit: (() -> Void)? = nil
  ) {
    self._text = text
    self.placeholder = placeholder
    self.leadingIcon = leadingIcon
    self.clearAccessibilityLabel = clearAccessibilityLabel
    cancelLabel = nil
    onCancel = nil
    self.onSubmit = onSubmit
  }

  /// 带取消变体：聚焦时展开取消按钮；取消时清空内容、收起键盘。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    cancelLabel: Text,
    onCancel: (() -> Void)? = nil,
    onSubmit: (() -> Void)? = nil
  ) {
    self._text = text
    self.placeholder = placeholder
    self.leadingIcon = leadingIcon
    self.clearAccessibilityLabel = clearAccessibilityLabel
    self.cancelLabel = cancelLabel
    self.onCancel = onCancel
    self.onSubmit = onSubmit
  }

  /// 搜索框 +（聚焦时）取消按钮。
  public var body: some View {
    HStack(spacing: WDSpacing.s4) {
      field
      if let cancelLabel, showsCancelButton {
        cancelButton(cancelLabel)
          .transition(.opacity)
      }
    }
    .frame(minHeight: WDSize.fieldHeight)
    .opacity(isEnabled ? 1 : disabledOpacity)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: isFocused)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: text.isEmpty)
  }

  // MARK: - 搜索框本体

  private var field: some View {
    HStack(spacing: WDSpacing.s3) {
      WDIcon(icon: leadingIcon, size: .md)
        .foregroundStyle(colors.textTertiary)
        .accessibilityHidden(true)
      input
      if !text.isEmpty {
        clearButton
      }
    }
    .padding(.horizontal, WDSpacing.s4)
    .frame(minHeight: WDSize.fieldHeight)
    .background(Capsule().fill(colors.surfaceCard))
    .overlay(Capsule().stroke(borderColor, lineWidth: borderWidth))
    .overlay(focusHalo)
    .contentShape(Capsule())
    .onTapGesture { requestFocus() }
    .accessibilityIdentifier("wd-searchfield-box")
  }

  private var input: some View {
    TextField(text: $text) {
      placeholder.foregroundStyle(colors.textTertiary)
    }
    .wdFont(WDType.body)
    .wdLineBox(WDType.body)
    .foregroundStyle(colors.textPrimary)
    .textFieldStyle(.plain)
    .submitLabel(.search)
    .focused($isFocused)
    .onSubmit {
      isFocused = false
      onSubmit?()
    }
    .accessibilityLabel(placeholder)
    .accessibilityAddTraits(.isSearchField)
  }

  private var clearButton: some View {
    Button {
      guard isEnabled else { return }
      text = ""
      requestFocus()
    } label: {
      WDIcon(icon: .clear, size: .md)
        .foregroundStyle(colors.textTertiary)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(clearAccessibilityLabel)
  }

  private func cancelButton(_ label: Text) -> some View {
    Button {
      guard isEnabled else { return }
      text = ""
      isFocused = false
      onCancel?()
    } label: {
      label
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .foregroundStyle(colors.textBrand)
        .frame(minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  // MARK: - 状态与视觉

  private var showsCancelButton: Bool {
    isFocused && isEnabled
  }

  private var borderColor: Color {
    showsFocus ? colors.textBrand : .clear
  }

  private var borderWidth: CGFloat {
    showsFocus ? Self.focusedBorderWidth : 0
  }

  @ViewBuilder private var focusHalo: some View {
    if showsFocus {
      Capsule()
        .stroke(colors.textBrand.opacity(Self.focusHaloAlpha), lineWidth: WDState.focusRingWidth)
        .allowsHitTesting(false)
    }
  }

  private var showsFocus: Bool {
    isFocused && isEnabled
  }

  private func requestFocus() {
    guard isEnabled else { return }
    isFocused = true
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 聚焦描边宽 1.5（设计 04 §5；令牌无该值）。
  private static let focusedBorderWidth: CGFloat = 1.5  // wd-structure-check:disable R7 — 设计值
  /// 聚焦光环透明度 18%（设计 04 §5）。
  private static let focusHaloAlpha: CGFloat = 0.18  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}
