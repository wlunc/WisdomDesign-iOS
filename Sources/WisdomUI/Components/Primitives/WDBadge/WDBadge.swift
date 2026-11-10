import SwiftUI

/// 徽标的值形态（`WDListRowTrailing.badge(_:)` 的载荷；SPEC §2.4 / 冻结表单 §5.2）。
///
/// 只承载"要显示的文字"；不进入无障碍焦点序列（由宿主决定怎么并入朗读）。
public struct WDBadgeValue: Sendable, Equatable {
  /// 徽标文字（库内零文案：由调用方给）。
  let label: Text

  /// 构造。
  public init(label: Text) {
    self.label = label
  }
}

/// 徽标（SPEC §2.10-#11；M2）。
///
/// 设计口径（设计 11 §3–§5）：状态胶囊高 **24**、水平内距 **10**、字号 **11 · 600**、`radius.full`；
/// 徽标**不可点**、**不进入无障碍焦点序列**（作为宿主朗读内容的一部分）。
///
/// 冻结签名只有 `label`（没有 variant/计数/圆点参数）⇒ 本实现只做**状态胶囊**，用中性的
/// `shared` 配色（`surface.tint` + `text.on-soft`）；六种变体与计数/圆点形态不可表达，
/// 差异登记在 `docs/DEV-PLAN.md` §2.3。字号按设计固定 11pt（**不随动态字体放大**，属设计例外）。
public struct WDBadge: View {
  private let label: Text

  @Environment(\.wdColors) private var colors

  /// 构造（SPEC §2.10-#11；文字由调用方给）。
  public init(label: Text) {
    self.label = label
  }

  /// 胶囊底 + 单行文字。
  public var body: some View {
    label
      .font(.system(size: 11, weight: .semibold))  // wd-structure-check:disable R7 R11 — 设计固定字号
      .foregroundStyle(colors.textOnSoft)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.horizontal, 10)  // wd-structure-check:disable R7 — 设计 11 §3 的水平内距 10（令牌无此值）
      .frame(minHeight: 24)  // wd-structure-check:disable R7 — 设计 11 §3 的胶囊高 24（令牌无此值）
      .background(Capsule().fill(colors.surfaceTint))
      .accessibilityHidden(true)
  }
}
