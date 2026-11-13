import SwiftUI

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
}

/// 徽标（SPEC §2.10-#11；M2；M5 扩计数/圆点）。
///
/// 设计口径（设计 11 §3–§5）：
/// - 状态胶囊高 **24**、水平内距 **10**、字号 **11 · 600**、`radius.full`；
/// - 圆点 **7×7**；计数高 **20**、最小宽 **20**、等宽数字，0 隐藏、>99 显示 `99+`；
/// - 徽标**不可点**、**不进入无障碍焦点序列**（作为宿主朗读内容的一部分）。
///
/// 配色：状态胶囊用中性 `shared`（`surface.tint` + `text.on-soft`）；计数用品牌破坏色渐变
/// （`WDGradient.destructive`，白字，浅深两端均 ≥4.5:1）——设计 11 的六种状态变体仍未表达，
/// 差异登记在 `docs/M5-EXIT-REPORT.md`。
public struct WDBadge: View {
  private let value: WDBadgeValue

  @Environment(\.wdColors) private var colors

  /// 构造（既有；SPEC §2.10-#11，文字由调用方给）。
  public init(label: Text) {
    value = WDBadgeValue(label: label)
  }

  /// 构造（M5 增量；状态胶囊 / 计数 / 圆点三种值形态）。
  public init(value: WDBadgeValue) {
    self.value = value
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
      .foregroundStyle(colors.textOnSoft)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.horizontal, Self.statusHorizontalPadding)
      .frame(minHeight: Self.statusHeight)
      .background(Capsule().fill(colors.surfaceTint))
      .accessibilityHidden(true)
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
  static func countText(_ count: Int) -> String {
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
  private static let maxCount = 99  // wd-structure-check:disable R7 — 设计 11 §5 的上限
}
