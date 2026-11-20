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
/// 300ms 防抖属调用方（设计 04 §8）。
///
/// 结果数播报（设计 04 §8/§10：`aria-live="polite"`，**不要每次按键都播**）：
/// 调用方传 `resultCount` + `announcer`，本件只在**结果数相对上次变化**时回调一次（传结果数，
/// 措辞由调用方给）；首帧不播、相等不播、清空（nil）不播 —— 判定见 `WDSearchResultAnnouncement`。
public struct WDSearchField: View {
  @Binding private var text: String
  private let placeholder: Text
  private let leadingIcon: WDIconName
  private let clearAccessibilityLabel: Text
  private let cancelLabel: Text?
  private let onCancel: (() -> Void)?
  private let onSubmit: (() -> Void)?
  /// 结果数（`nil` = 调用方不提供结果数 ⇒ 本件不播报）。
  private let resultCount: Int?
  /// 结果数变化的播报回调（传**结果数**；措辞由调用方给 —— L-B 零文案）。
  private let announcer: (@MainActor @Sendable (Int) -> Void)?
  /// 结果数播报的判定记账（上一次计入的计数 + 本次该播什么），推进逻辑见 `WDSearchResultAnnouncement`。
  @State private var announced: WDSearchResultAnnouncement = .initial
  /// 记账对应的配置快照：`resultCount` + `announcer` 整体变化时重置记账（见 `resetting`）。
  @State private var announcementConfig: WDSearchAnnouncementConfig = .init()

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @FocusState private var isFocused: Bool

  /// 标准变体（无取消按钮）。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    onSubmit: (() -> Void)? = nil,
    resultCount: Int? = nil,
    announcer: (@MainActor @Sendable (Int) -> Void)? = nil
  ) {
    self._text = text
    self.placeholder = placeholder
    self.leadingIcon = leadingIcon
    self.clearAccessibilityLabel = clearAccessibilityLabel
    cancelLabel = nil
    onCancel = nil
    self.onSubmit = onSubmit
    self.resultCount = resultCount
    self.announcer = announcer
  }

  /// 带取消变体：聚焦时展开取消按钮；取消时清空内容、收起键盘。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    cancelLabel: Text,
    onCancel: (() -> Void)? = nil,
    onSubmit: (() -> Void)? = nil,
    resultCount: Int? = nil,
    announcer: (@MainActor @Sendable (Int) -> Void)? = nil
  ) {
    self._text = text
    self.placeholder = placeholder
    self.leadingIcon = leadingIcon
    self.clearAccessibilityLabel = clearAccessibilityLabel
    self.cancelLabel = cancelLabel
    self.onCancel = onCancel
    self.onSubmit = onSubmit
    self.resultCount = resultCount
    self.announcer = announcer
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
    .onChange(of: resultCount, initial: true) { _, count in handleResultCount(count) }
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

  // MARK: - 结果数播报（设计 04 §8/§10）

  /// 结果数变化入口：同一份判定既驱动播报，也把判定结果存进 `announced`。
  ///
  /// - `resultCount == nil`：本次**不计入**（保留上次计数）—— 调用方隐藏结果数（如收起搜索）
  ///   不等于"结果变 0"，回来时不该重播（设计 04 §10：值与上次相比**没变**就不播）；
  /// - `announcer == nil`：什么都不做，`announced` 保持原值（播报开关打开后首帧仍不播）；
  /// - 配置整体换了（另一个搜索上下文）：先重置记账，再按首帧处理新配置的第一个数。
  private func handleResultCount(_ count: Int?) {
    guard let announcer, let count else { return }
    let config = WDSearchAnnouncementConfig(resultCount: resultCount, announcer: announcer)
    if config != announcementConfig {
      announcementConfig = config
      announced = WDSearchResultAnnouncement.resetting(configuration: config)
    }
    let next = announced.next(current: count, announcing: true)
    announced = next
    guard next.announce, let changedTo = next.announced else { return }
    announcer(changedTo)
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
