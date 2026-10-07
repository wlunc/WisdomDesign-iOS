import SwiftUI

/// 字段外观档位（SPEC §2.3）。
public enum WDTextFieldVariant: String, CaseIterable, Sendable, Equatable {
  case inset
  case outline
  case glass
}

/// 字段前缀槽（SPEC §2.3）。
///
/// ⚠️ **延后项**：`case icon(WDIconName)` 尚未落地 —— `WDIconName` 的生成物未产出（见 `docs/ICON-PIPELINE.md`），
/// 且**不得自造符号名**（F-07：图标名以契约为准）。落地后按 §M2-DEFERRALS 回填。
public enum WDTextFieldPrefix: Sendable, Equatable {
  case none
  case text(Text)
}

/// 字段尾部附件槽（SPEC §2.3）。
///
/// ⚠️ **延后项**：`case clear` / `case reveal` 需要图标符号（`xmark.circle.fill` / `eye` / `eye.slash`）——
/// 硬编码 SF Symbol 名等于绕开契约（F-07），故与 `WDIconName` 同批落地。
public enum WDTextFieldAccessory: Sendable, Equatable {
  case none
  case unit(Text)
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
/// 字段盒 = **46 ± 1pt**，所有变体所有状态高度一致（**状态不得改变高度**）。
public struct WDTextField: View {
  @Binding private var text: String
  private let label: Text
  private let appearance: WDTextFieldAppearance
  private let isEditable: Bool
  private let onSubmit: (() -> Void)?
  private let onEditingChanged: ((Bool) -> Void)?

  @Environment(\.wdColors) private var colors
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
      HStack(spacing: WDSpacing.s3) {
        prefixView
        inputView
        accessoryView
      }
      .frame(minHeight: WDSize.fieldHeight)
      .accessibilityIdentifier("wd-textfield-box")
      helperView
    }
    .frame(minWidth: WDSize.fieldMinWidth, alignment: .leading)
  }

  // MARK: - 零件

  /// 常驻标签（footnote；读屏第一顺位）。
  private var labelView: some View {
    label
      .wdFont(WDType.footnote)
      .wdLineBox(WDType.footnote)
      .foregroundStyle(colors.textSecondary)
  }

  @ViewBuilder private var prefixView: some View {
    switch appearance.prefix {
    case .none:
      EmptyView()
    case .text(let prefix):
      prefix
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .foregroundStyle(colors.textTertiary)
    }
  }

  @ViewBuilder private var inputView: some View {
    if isEditable {
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
    } else {
      // 只读态（**在 U6 六态之外**，SPEC §2.3 裁决 1）：用 Text + textSelection，**不是** .disabled(true)
      Text(text)
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .foregroundStyle(colors.textPrimary)
        .textSelection(.enabled)
    }
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
    case .unit(let unit):
      unit
        .wdFont(WDType.body)
        .wdLineBox(WDType.body)
        .foregroundStyle(colors.textTertiary)
    case .count(let current, let limit):
      countView(current: current, limit: limit)
    }
  }

  /// 计数附件（≥90% 换 `status.warning`；阈值来自 SPEC §2.3 的裁决，非令牌值）。
  private func countView(current: Int, limit: Int) -> some View {
    let isNearLimit = limit > 0 && Double(current) >= Double(limit) * Self.warnRatio
    return Text(verbatim: "\(current)/\(limit)")
      .wdFont(WDType.caption1)
      .wdLineBox(WDType.caption1)
      .foregroundStyle(isNearLimit ? colors.statusWarning : colors.textTertiary)
      .monospacedDigit()
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
}
