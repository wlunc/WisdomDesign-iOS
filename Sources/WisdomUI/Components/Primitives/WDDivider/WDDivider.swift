import SwiftUI

/// 分割线档位（设计 14 §4：全宽 / 内缩）。
public enum WDDividerStyle: String, CaseIterable, Sendable, Equatable {
  /// 全宽（卡片内整体分区）。
  case full
  /// 内缩到文本区起点 62（列表行之间）。
  case inset
}

/// 分割线（SPEC §2.10-#14；M2；B3 扩内缩档）。
///
/// 设计口径（设计 14）：1pt 高、border.hairline、无圆角、无状态、**不进无障碍树**；
/// 内缩档起点 **62**（16 + 34 + 12，与列表行文本区对齐）。
public struct WDDivider: View {
  private let style: WDDividerStyle

  @Environment(\.wdColors) private var colors

  /// 构造（既有；全宽档）。
  public init() {
    style = .full
  }

  /// 构造（B3 增量；全宽 / 内缩）。
  public init(style: WDDividerStyle) {
    self.style = style
  }

  /// 渲染：一条 hairline；内缩档左侧留 62。
  public var body: some View {
    Rectangle()
      .fill(colors.borderHairline)
      .frame(height: 1)
      .frame(maxWidth: .infinity)
      .padding(.leading, style == .inset ? insetLeading : 0)
      .accessibilityHidden(true)
  }

  /// 内缩起点 62（设计 14 §3）。
  private var insetLeading: CGFloat {
    WDDividerMetrics.insetLeading
  }
}
