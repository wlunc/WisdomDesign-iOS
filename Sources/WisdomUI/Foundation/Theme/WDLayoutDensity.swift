import SwiftUI

/// 布局密度档（F44；SPEC §3.3）。
///
/// 只影响"下限"（行高、卡片内距一类），**不让文字变小**（设计 09-layout §4）。
/// 默认 = `comfortable`（设计文档：comfortable 为默认档）。
public enum WDLayoutDensity: String, CaseIterable, Sendable, Equatable {
  /// 舒适档（默认）：行高下限 60。
  case comfortable
  /// 紧凑档：行高下限 44（长列表浏览用）。
  case compact

  /// 行高下限（令牌 `size.row-height.{comfortable,compact}` = 60 / 44）。
  ///
  /// 消费方（`WDListRow`/`WDListSection`/`WDCard`）按 `max(rowMinHeight, 槽位派生)` 使用（SPEC §2.4-2）。
  public var rowMinHeight: CGFloat {
    switch self {
    case .comfortable: return WDSize.rowHeightComfortable
    case .compact: return WDSize.rowHeightCompact
    }
  }
}
