import SwiftUI
import WisdomUI

/// 字阶画廊：12 条字阶 × {zh, en}，每条都用 `wdFont` + `wdLineBox` 渲染。
///
/// 它是 M1 六（八）态快照的**主体**（M1 还没有组件）：任何字阶层改动都会在这里留下可见/可测差异。
///
/// **调色板由调用方注入**：m1 尚未落地 `wdColors` 环境键（SPEC §3.1 的 I24b），
/// 而 `WDColorValues.light/.dark` 是**固定色**（不是自适应 `Color(wdLight:dark:)`），
/// 所以深色态必须显式传 `.dark` —— 快照侧由 `SnapshotSupport.values(for:)` 负责。
public struct WDTypographyGallery: View {
  /// 12 条字阶（顺序与 `WDType` 的生成顺序一致）。
  public static let styles: [(name: String, style: WDTextStyle)] = [
    ("largeTitle", WDType.largeTitle),
    ("title1", WDType.title1),
    ("title2", WDType.title2),
    ("title3", WDType.title3),
    ("headline", WDType.headline),
    ("body", WDType.body),
    ("callout", WDType.callout),
    ("subheadline", WDType.subheadline),
    ("footnote", WDType.footnote),
    ("caption1", WDType.caption1),
    ("caption2", WDType.caption2),
    ("overline", WDType.overline),
  ]

  private let values: WDColorValues

  /// - Parameter values: 该套 scheme 的 32 槽位值（默认 `.light`）。
  public init(values: WDColorValues = .light) {
    self.values = values
  }

  /// 12 条字阶的竖直画廊（每条含名称 + 中文 + 英文）。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      Text(verbatim: "Typography")
        .wdFont(WDType.title2)
        .wdLineBox(WDType.title2)
      ForEach(Array(Self.styles.enumerated()), id: \.offset) { _, item in
        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          Text(verbatim: item.name)
            .wdFont(WDType.caption1)
            .wdLineBox(WDType.caption1)
          // 中英**上下排**（并排会在大字阶上被截断成「示例文本…」，那是排版噪声而不是证据）。
          Text(verbatim: WDSampleData.zh)
            .wdFont(item.style)
            .wdLineBox(item.style)
          Text(verbatim: WDSampleData.en)
            .wdFont(item.style)
            .wdLineBox(item.style)
        }
      }
    }
    .foregroundStyle(values.textPrimary)
    .padding(WDSpacing.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(values.bgCanvas)
  }
}
