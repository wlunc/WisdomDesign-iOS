import SwiftUI

/// 字段外观档位（SPEC §2.3）。
public enum WDTextFieldVariant: String, CaseIterable, Sendable, Equatable {
  case inset
  case outline
  case glass
}

/// 字段前缀槽（SPEC §2.3）。
///
/// 语义名由契约承载（`WDIconName`，生成物）；iOS 按名取 SF Symbols（F-07）。
public enum WDTextFieldPrefix: Sendable, Equatable {
  case none
  case icon(WDIconName)
  case text(Text)
}

/// 字段尾部附件槽（SPEC §2.3）。
///
/// 附件按钮独立可达、**不合并不可达**（SPEC §2.3）；图标符号取自契约（`WDIconName.clear` / `.showPassword` / `.hidePassword`）。
public enum WDTextFieldAccessory: Sendable, Equatable {
  case none
  case unit(Text)
  case clear(accessibilityLabel: Text)
  case reveal(hiddenAccessibilityLabel: Text, shownAccessibilityLabel: Text)
  case count(current: Int, limit: Int)
}

/// 字段辅助文案槽（SPEC §2.3；错误态文案由调用方给，N6）。
public enum WDTextFieldHelper: Sendable, Equatable {
  case none
  case hint(Text)
  case error(Text)
}

/// 字段外观对象（★ 只 `Sendable`：`SubmitLabel` 不 `Equatable`；SPEC §2.3）。
///
/// README 口径：**外观对象是不可变语义，请在构造时给全**（值类型 + 可变副本）。
public struct WDTextFieldAppearance: Sendable {
  /// 档位。
  public var variant: WDTextFieldVariant = .inset
  /// 占位串（由调用方给）。
  public var placeholder: Text? = nil
  /// 前缀。
  public var prefix: WDTextFieldPrefix = .none
  /// 尾部附件。
  public var accessory: WDTextFieldAccessory = .none
  /// 辅助文案。
  public var helper: WDTextFieldHelper = .none
  /// 是否密文。
  public var isSecure: Bool = false
  /// 回车键类型。
  public var submitLabel: SubmitLabel = .done

  /// 全参数构造（每个参数都有默认值）。
  public init(
    variant: WDTextFieldVariant = .inset,
    placeholder: Text? = nil,
    prefix: WDTextFieldPrefix = .none,
    accessory: WDTextFieldAccessory = .none,
    helper: WDTextFieldHelper = .none,
    isSecure: Bool = false,
    submitLabel: SubmitLabel = .done
  ) {
    self.variant = variant
    self.placeholder = placeholder
    self.prefix = prefix
    self.accessory = accessory
    self.helper = helper
    self.isSecure = isSecure
    self.submitLabel = submitLabel
  }
}

/// 输入字段（SPEC §2.3；M2 首件）。
///
/// 结构（验收锚点）：`labelView` / 输入行（`frame(minHeight: WDSize.fieldHeight)` + `accessibilityIdentifier("wd-textfield-box")`）/ `helperView`。
/// 字段盒 = **46 ± 1pt**，所有变体所有状态高度一致（**状态不得改变高度**）；放大档由输入行的行盒撑开。
///
/// 视觉口径（设计 03 §3–§5，全部取已生成令牌）：
///   · 圆角 `WDRadius.md` 14、水平内距 `WDSpacing.s4` 12、槽间距 `WDSpacing.s3` 8；
///   · `inset` = `fill.field`；`outline` = 透明 + `border.hairline-strong`；`glass` 走 `WDGlass.resolve`（iOS 17–25 纯色降级）；
///   · 聚焦 = `text.brand` 1.5pt 描边 + 18% 光环（`motion.duration.fast` 160ms）；错误 = `status.danger` 描边；
///   · 禁用 = `@Environment(\.isEnabled)` ⇒ 整体 40%；只读 = `surface.card-sunken` + `text.secondary`（在 U6 之外）。
///
/// 无障碍（SPEC §2.6.2 / F22）：常驻标签从无障碍树隐藏并挂到输入区（读屏先读标签再读内容）；
/// 错误文案走 `accessibilityHint`（库内零文案，文案与分隔符全部由调用方给）。
public struct WDTextField: View {
  @Binding private var text: String
  private let label: Text
  private let appearance: WDTextFieldAppearance
  private let isEditable: Bool
  private let onSubmit: (() -> Void)?
  private let onEditingChanged: ((Bool) -> Void)?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var wdAppearance
  @Environment(\.wdEffectsBudget) private var effectsBudget
  @Environment(\.isEnabled) private var isEnabled
  @FocusState private var isFocused: Bool
  @State private var isRevealed = false

  /// 构造（SPEC §2.3 冻结签名）。
  public init(
    text: Binding<String>,
    label: Text,
    appearance: WDTextFieldAppearance = .init(),
    isEditable: Bool = true,
    onSubmit: (() -> Void)? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil
  ) {
    self._text = text
    self.label = label
    self.appearance = appearance
    self.isEditable = isEditable
    self.onSubmit = onSubmit
    self.onEditingChanged = onEditingChanged
  }

  /// 字段结构：标签 → 输入行（46 字段盒，`wd-textfield-box`）→ 辅助文案。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      labelView
      fieldRow
      helperView
    }
    .frame(minWidth: WDSize.fieldMinWidth, alignment: .leading)
    .opacity(isEnabled ? 1 : disabledOpacity)
    .animation(.linear(duration: WDMotion.Duration.fast), value: helperKind)
    .animation(.linear(duration: WDMotion.Duration.fast), value: showsFocus)
  }

  // MARK: - 零件

  /// 常驻标签（footnote；从树里隐藏，标签语义挂到输入区 —— 读屏先读标签再读内容）。
  private var labelView: some View {
    label
      .wdFont(WDType.footnote)
      .wdLineBox(WDType.footnote)
      .foregroundStyle(colors.textSecondary)
      .accessibilityHidden(true)
  }

  /// 字段容器：变体底色 + 状态描边 + 聚焦光环；点任意位置聚焦输入区。
  private var fieldRow: some View {
    HStack(spacing: WDSpacing.s3) {
      prefixView
      inputView
      accessoryView
    }
    .padding(.horizontal, WDSpacing.s4)
    .frame(minHeight: WDSize.fieldHeight)
    .background(fieldBackground)
    .overlay(fieldBorder)
    .overlay(focusHalo)
    .contentShape(RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous))
    .onTapGesture { requestFocus() }
    .accessibilityIdentifier("wd-textfield-box")
  }

  @ViewBuilder private var prefixView: some View {
    switch appearance.prefix {
    case .none:
      EmptyView()
    case .icon(let icon):
      WDIcon(icon: icon, size: .md)
        .foregroundStyle(colors.textTertiary)
    case .text(let prefix):
      prefix
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .foregroundStyle(colors.textTertiary)
    }
  }

  @ViewBuilder private var inputView: some View {
    if isEditable {
      fieldEntry
    } else {
      readOnlyText
    }
  }

  /// 可编辑态：真 `TextField` / `SecureField`（pressed/focused 的唯一来源是系统控件本身）。
  private var fieldEntry: some View {
    Group {
      if appearance.isSecure && !isRevealed {
        SecureField(text: $text) { placeholderView }
      } else {
        TextField(text: $text) { placeholderView }
      }
    }
    .wdFont(WDType.body)
    .wdLineBox(WDType.body)
    .foregroundStyle(colors.textPrimary)
    .textFieldStyle(.plain)
    .submitLabel(appearance.submitLabel)
    .focused($isFocused)
    .onSubmit { onSubmit?() }
    .onChange(of: isFocused) { _, focused in onEditingChanged?(focused) }
    .accessibilityLabel(label)
    .modifier(WDFieldHint(hint: errorText))
  }

  /// 只读态（**在 U6 六态之外**，SPEC §2.3 裁决 1）：用 `Text` + `textSelection`，**不是** `.disabled(true)`。
  private var readOnlyText: some View {
    Text(text)
      .wdFont(WDType.body)
      .wdLineBox(WDType.body)
      .foregroundStyle(colors.textSecondary)
      .textSelection(.enabled)
      .accessibilityLabel(label)
      .modifier(WDFieldHint(hint: errorText))
  }

  @ViewBuilder private var placeholderView: some View {
    if let placeholder = appearance.placeholder {
      placeholder.foregroundStyle(colors.textTertiary)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder private var accessoryView: some View {
    switch appearance.accessory {
    case .none:
      EmptyView()
    case .clear(let accessibilityLabel):
      accessoryButton(accessibilityLabel: accessibilityLabel) {
        WDIcon(icon: .clear, size: .md)
      } action: {
        text = ""
        requestFocus()
      }
    case .reveal(let hiddenAccessibilityLabel, let shownAccessibilityLabel):
      accessoryButton(
        accessibilityLabel: isRevealed ? shownAccessibilityLabel : hiddenAccessibilityLabel
      ) {
        WDIcon(icon: isRevealed ? .hidePassword : .showPassword, size: .md)
      } action: {
        isRevealed.toggle()
        // 显隐切换替换了控件类型（SecureField ⇄ TextField）。iOS 17 没有
        // `TextField(text:selection:)`（SPEC §2.3 裁决 2 的单实例方案不可用）⇒ 按该条的降级路径：
        // **焦点回填**（光标位置由系统落在末尾），并把差异登记在 M2 出口报告里。
        requestFocus()
      }
    case .unit(let unit):
      unit
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .foregroundStyle(colors.textTertiary)
    case .count(let current, let limit):
      countView(current: current, limit: limit)
    }
  }

  /// 尾部附件按钮（独立可达、独立标签；热区 = 触控下限令牌）。
  private func accessoryButton<Icon: View>(
    accessibilityLabel: Text,
    @ViewBuilder icon: () -> Icon,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      icon()
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel)
  }

  /// 计数附件（≥90% 换 `status.warning`；阈值来自 SPEC §2.3 的裁决，非令牌值）。
  private func countView(current: Int, limit: Int) -> some View {
    Text(verbatim: "\(current)/\(limit)")
      .wdFont(WDType.caption1)
      .wdLineBox(WDType.caption1)
      .foregroundStyle(
        Self.isCountNearLimit(current: current, limit: limit)
          ? colors.statusWarning : colors.textTertiary
      )
      .monospacedDigit()
  }

  /// 计数是否接近上限（`count` 附件的唯一规则）：`limit > 0 && current/limit ≥ 90%`。
  ///
  /// 这个判定是纯逻辑，单测直接钉它（渲染像素取色会漂移，不适合做判据）。
  static func isCountNearLimit(current: Int, limit: Int) -> Bool {
    limit > 0 && Double(current) >= Double(limit) * warnRatio
  }

  /// ≥90% 的阈值（SPEC §2.3 的 `count` 裁决）。
  private static let warnRatio = 0.9  // wd-structure-check:disable R7 — SPEC §2.3 的计数阈值，非令牌值

  @ViewBuilder private var helperView: some View {
    switch appearance.helper {
    case .none:
      EmptyView()
    case .hint(let hint):
      hint
        .wdFont(WDType.caption1)
        .wdLineBox(WDType.caption1)
        .foregroundStyle(colors.textTertiary)
    case .error(let error):
      error
        .wdFont(WDType.caption1)
        .wdLineBox(WDType.caption1)
        .foregroundStyle(colors.statusDanger)
    }
  }

  // MARK: - 状态与视觉

  /// 变体底色（`glass` 走唯一入口 `WDGlass.resolve`：iOS 17–25 自动纯色降级）。
  private var fieldFill: Color {
    if !isEditable { return colors.surfaceCardSunken }
    switch appearance.variant {
    case .inset: return colors.fillField
    case .outline: return .clear
    case .glass: return glassFill
    }
  }

  private var fieldBackground: some View {
    RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous)
      .fill(fieldFill)
  }

  private var glassFill: Color {
    switch WDGlass.resolve(
      textLevel: .primary,
      appearance: wdAppearance,
      capabilities: WDGlassCapabilities(supportsGlass: Self.runtimeSupportsGlass()),
      budget: effectsBudget,
      level: .thick
    ) {
    case .glass: return colors.surfaceGlass
    case .glassStrong: return colors.surfaceGlassStrong
    case .opaque: return colors.surfaceCardSolid
    }
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 的默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  /// 状态描边：错误 ＞ 聚焦 ＞ 变体默认（只读态无描边）。
  private var fieldBorderColor: Color? {
    if !isEditable { return nil }
    if hasError { return colors.statusDanger }
    if showsFocus { return colors.textBrand }
    switch appearance.variant {
    case .inset: return nil
    case .outline: return colors.borderHairlineStrong
    case .glass: return colors.borderHairline
    }
  }

  private var fieldBorderWidth: CGFloat {
    (hasError || showsFocus) ? Self.emphasizedBorderWidth : 1
  }

  @ViewBuilder private var fieldBorder: some View {
    if let color = fieldBorderColor {
      RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous)
        .stroke(color, lineWidth: fieldBorderWidth)
    }
  }

  /// 聚焦光环（设计 03 §5：`text.brand` 18%；宽度用 `state.focus.ring-width` 3pt）。
  @ViewBuilder private var focusHalo: some View {
    if showsFocus {
      RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous)
        .stroke(colors.textBrand.opacity(Self.focusHaloAlpha), lineWidth: WDState.focusRingWidth)
        .allowsHitTesting(false)
    }
  }

  /// 可聚焦 = 可编辑且未被禁用；只读态不可聚焦。
  private var canFocus: Bool {
    isEditable && isEnabled
  }

  private var showsFocus: Bool {
    isFocused && canFocus
  }

  private func requestFocus() {
    guard canFocus else { return }
    isFocused = true
  }

  /// 错误文案（`accessibilityHint` 的输入；库内不拼任何文案与分隔符）。
  private var errorText: Text? {
    if case .error(let error) = appearance.helper { return error }
    return nil
  }

  private var hasError: Bool {
    errorText != nil
  }

  /// 辅助文案的形态（动画的 value：只有形态变化才触发 160ms 过渡）。
  private enum HelperKind: Int {
    case none
    case hint
    case error
  }

  private var helperKind: HelperKind {
    switch appearance.helper {
    case .none: return .none
    case .hint: return .hint
    case .error: return .error
    }
  }

  /// 聚焦/错误描边宽度（设计 03 §5 的 1.5pt；令牌层没有这个值）。
  private static let emphasizedBorderWidth: CGFloat = 1.5  // wd-structure-check:disable R7 — 设计值
  /// 字段聚焦光环透明度（设计 03 §5 的 18%；`state.focus.ring-alpha` 是通用值 32%，字段档按设计）。
  private static let focusHaloAlpha: CGFloat = 0.18  // wd-structure-check:disable R7 — 设计值
  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 错误态读屏（F22）：无 error trait ⇒ `accessibilityHint`（文案由调用方给）。
private struct WDFieldHint: ViewModifier {
  let hint: Text?

  @ViewBuilder func body(content: Content) -> some View {
    if let hint {
      content.accessibilityHint(hint)
    } else {
      content
    }
  }
}
