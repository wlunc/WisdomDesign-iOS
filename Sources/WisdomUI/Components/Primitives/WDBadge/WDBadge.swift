import SwiftUI

/// 状态胶囊的六种语义变体（设计 11 §4；新增公开类型，不改既有枚举）。
public enum WDBadgeVariant: String, CaseIterable, Sendable, Equatable {
  case shared
  case schedule
  case pending
  case success
  case warning
  case danger
}

/// 徽标的值形态（`WDListRowTrailing.badge(_:)` 的载荷；SPEC §2.4 / 冻结表单 §5.2）。
///
/// M5 增量（`docs/M5-SIGNATURE-FREEZE.md` §2.3）：新增 `count` 与 `dot` 两种值形态；
/// 既有 `init(label:)` 与状态胶囊渲染不变（只增不改）。
public struct WDBadgeValue: Sendable, Equatable {
  /// 渲染形态（内部；公开面只有三个构造入口）。
  enum Content: Sendable, Equatable {
    case label(Text)
    case count(Int)
    case dot
  }

  /// 形态。
  let content: Content

  /// 状态胶囊：要显示的文字（库内零文案，由调用方给）。
  public init(label: Text) {
    content = .label(label)
  }

  /// 计数胶囊：0 ⇒ 不渲染；>99 ⇒ 显示 `99+`（设计 11 §5）。
  public init(count: Int) {
    content = .count(count)
  }

  /// 圆点（7×7；品牌色，设计 11 §3）。
  public static let dot = WDBadgeValue(content: .dot)

  /// 内部构造（`dot` 用）。
  private init(content: Content) {
    self.content = content
  }

  /// 可朗读文本（内部；徽标不独立进焦点，由宿主并入整行朗读，设计 11 §10）。
  ///
  /// - `label`：原样回传调用方的 `Text`（库内零文案，`Text` 也无法取串）；
  /// - `count`：复用计数文案（0 ⇒ 不渲染 ⇒ `nil`；>99 ⇒ `99+`）；
  /// - `dot`：纯装饰 ⇒ `nil`。
  ///
  /// 拼接位置与分隔符由宿主决定（本属性不产出任何标点/词序）。
  var accessibilityText: Text? {
    switch content {
    case .label(let label):
      return label
    case .count(let count):
      guard count > 0 else { return nil }
      return Text(verbatim: WDBadge.countText(count))  // wd-structure-check:disable R21 — 读屏
    case .dot:
      return nil
    }
  }
}

/// 徽标（SPEC §2.10-#11；M2；M5 扩计数/圆点）。
///
/// 设计口径（设计 11 §3–§5）：
/// - 状态胶囊高 **24**、水平内距 **10**、字号 **11 · 600**、`radius.full`；
/// - 圆点 **7×7**；计数高 **20**、最小宽 **20**、等宽数字，0 隐藏、>99 显示 `99+`；
/// - 徽标**不可点**、**不进入无障碍焦点序列**（作为宿主朗读内容的一部分）。
///
/// 配色：`init(label:variant:)` 覆盖设计 11 §4 的六种状态变体；**对比度优先**（DF-04）：
/// soft 变体文字统一 `text.on-soft`、schedule 背景用 `status.info` 实底（原 `gradient.mid` 上白字仅
/// 2.5–4.2:1），详见 `docs/B1-SIGNATURE-FREEZE.md`。计数仍用品牌破坏色渐变（白字，≥4.5:1）。
public struct WDBadge: View {
  private let value: WDBadgeValue
  private let variant: WDBadgeVariant?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance

  /// 构造（既有；SPEC §2.10-#11，文字由调用方给）。
  public init(label: Text) {
    value = WDBadgeValue(label: label)
    variant = nil
  }

  /// 构造（B1 增量；状态胶囊的六种语义变体，设计 11 §4）。
  public init(label: Text, variant: WDBadgeVariant) {
    value = WDBadgeValue(label: label)
    self.variant = variant
  }

  /// 构造（M5 增量；状态胶囊 / 计数 / 圆点三种值形态）。
  public init(value: WDBadgeValue) {
    self.value = value
    variant = nil
  }

  /// 按值形态渲染。
  @ViewBuilder public var body: some View {
    switch value.content {
    case .label(let label):
      statusCapsule(label)
    case .count(let count):
      if count > 0 {
        countCapsule(count)
      }
    case .dot:
      dot
    }
  }

  // MARK: - 状态胶囊

  private func statusCapsule(_ label: Text) -> some View {
    label
      .font(statusFont)
      .foregroundStyle(statusTextColor)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.horizontal, Self.statusHorizontalPadding)
      .frame(minHeight: Self.statusHeight)
      .background { statusBackground }
      .accessibilityHidden(true)
  }

  /// 当前变体（`init(value:)` 的 label 形态保持旧行为 = shared）。
  private var resolvedVariant: WDBadgeVariant {
    variant ?? .shared
  }

  /// 状态胶囊文字色（**对比度优先**：soft 变体统一 `text.on-soft`，见 B1 签名冻结）。
  private var statusTextColor: Color {
    Self.statusTextColor(
      for: resolvedVariant, colors: colors, scheme: appearance.colorScheme)
  }

  /// 状态胶囊背景（**对比度优先**：schedule 用 `status.info` 实底，见 B1 签名冻结）。
  private var statusBackground: some View {
    Capsule().fill(
      Self.statusBackgroundColor(for: resolvedVariant, colors: colors))
  }

  // MARK: - 变体配色（内部；单测直接核对对比度）

  /// 文字色：soft 变体用 `text.on-soft`（status 原色在浅色 soft 底上 3.9–4.3:1，不达 4.5）。
  static func statusTextColor(
    for variant: WDBadgeVariant, colors: WDColorValues, scheme: ColorScheme
  ) -> Color {
    switch variant {
    case .shared, .success, .warning, .danger: return colors.textOnSoft
    case .pending: return colors.textBrand
    case .schedule: return scheme == .dark ? colors.textOnLightPrimary : colors.textOnDark
    }
  }

  /// 背景色：soft 变体用 soft 槽位；pending 用 glass-strong；schedule 用 status.info。
  static func statusBackgroundColor(
    for variant: WDBadgeVariant, colors: WDColorValues
  ) -> Color {
    switch variant {
    case .shared: return colors.surfaceTint
    case .schedule: return colors.statusInfo
    case .pending: return colors.surfaceGlassStrong
    case .success: return colors.statusSoftSuccess
    case .warning: return colors.statusSoftWarning
    case .danger: return colors.statusSoftDanger
    }
  }

  // MARK: - 计数胶囊

  private func countCapsule(_ count: Int) -> some View {
    Text(verbatim: Self.countText(count))
      .font(countFont)
      .monospacedDigit()
      .foregroundStyle(colors.textOnDark)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.horizontal, Self.countHorizontalPadding)
      .frame(minWidth: Self.countMinWidth, minHeight: Self.countHeight)
      .background(Capsule().fill(WDGradient.destructive.linearGradient))
      .overlay(Capsule().stroke(colors.textOnDark, lineWidth: Self.countStroke))
      .accessibilityHidden(true)
  }

  /// 计数文案：>99 显示 `99+`（设计 11 §5；库内只做结构，不含本地化文案）。
  nonisolated static func countText(_ count: Int) -> String {
    let limit = Self.maxCount
    return count > limit ? "\(limit)+" : "\(count)"
  }

  // MARK: - 圆点

  private var dot: some View {
    Circle()
      .fill(colors.textBrand)
      .frame(width: Self.dotSize, height: Self.dotSize)
      .accessibilityHidden(true)
  }

  /// 状态胶囊字体（设计锁定字号，R11 豁免集中在此）。
  private var statusFont: Font {
    .system(size: Self.statusFontSize, weight: .semibold)  // wd-structure-check:disable R11 — 设计
  }

  /// 计数胶囊字体（设计锁定字号）。
  private var countFont: Font {
    .system(size: Self.countFontSize, weight: .semibold)  // wd-structure-check:disable R11 — 设计
  }

  // MARK: - 设计值（令牌无对应键；逐条绑定理由）

  /// 状态胶囊字号 11（设计 11 §3）。
  private static let statusFontSize: CGFloat = 11  // wd-structure-check:disable R7 — 设计值
  /// 状态胶囊水平内距 10（设计 11 §3）。
  private static let statusHorizontalPadding: CGFloat = 10  // wd-structure-check:disable R7 — 设计值
  /// 状态胶囊高 24（设计 11 §3）。
  private static let statusHeight: CGFloat = 24  // wd-structure-check:disable R7 — 设计值
  /// 计数胶囊字号 11（设计 11 §3）。
  private static let countFontSize: CGFloat = 11  // wd-structure-check:disable R7 — 设计值
  /// 计数胶囊水平内距 6（画廊 `.wd-count` 的 `padding: 0 6px`）。
  private static let countHorizontalPadding: CGFloat = 6  // wd-structure-check:disable R7 — 设计值
  /// 计数胶囊最小宽 20（设计 11 §3）。
  private static let countMinWidth: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
  /// 计数胶囊高 20（设计 11 §3）。
  private static let countHeight: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
  /// 计数胶囊白色描边宽 2（设计 11 §3）。
  private static let countStroke: CGFloat = 2  // wd-structure-check:disable R7 — 设计值
  /// 圆点直径 7（设计 11 §3）。
  private static let dotSize: CGFloat = 7  // wd-structure-check:disable R7 — 设计值
  /// 计数上限：超过显示 `99+`（设计 11 §5）。
  ///
  /// `nonisolated`：`countText(_:)` 是纯函数、也不在当前 actor 上，读这个常量不能跨隔离域。
  nonisolated private static let maxCount = 99  // wd-structure-check:disable R7 — 设计 11 §5 的上限
}
