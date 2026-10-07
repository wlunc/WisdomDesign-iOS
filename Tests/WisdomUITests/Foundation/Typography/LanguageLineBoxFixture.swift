import Foundation

/// zh/en 两层的自然行高 fixture（**实测记录**；SPEC §2.6.3 的「两步测量」）。
///
/// 记录环境：Xcode 26.6 / iOS 26.5 模拟器 / 2026-10-07。
/// 采样口径：
///   · `fontNatural` = `UIFontMetrics(forTextStyle:).scaledFont(for:compatibleWith:)` 之后的 `lineHeight`
///     （en = SF Pro，zh = PingFang SC）——**字体级**；
///   · `renderedNatural` = `UIHostingController` + `Text(verbatim:)`（"Ag" / "汉字"）+
///     `sizeThatFits(in: 1000 × ∞)` —— **渲染级，这才是 U5 的验收对象**。
///
/// **实测发现（2026-10-07，须如实记录）**：字体级 zh（PingFang SC）在 12 条字阶上**全部大于**设计行高
/// （1.400em：body 23.8 vs 设计 22），而**渲染级 zh 与 en 逐条相同**（body 均 20.33）——
/// SwiftUI 的单行行盒跟随**主字体**度量，CJK 回退字体不改行盒高（字形仍在盒内，不裁切）。
/// ⇒ U5-a/b/c 的 `natural` 取**渲染级**；字体级只作记录与漂移对照。
///
/// 纪律（SPEC §2.6.3 ③）：**fixture 缺失 = fail**（不做默认值兜底）；重测漂移超 ±0.5pt 即红并提示重新记录。
public enum LanguageLineBoxFixture {
  /// 语种（由**字面量**驱动字体回退，不依赖进程语言）。
  public enum Script: String, CaseIterable, Sendable {
    case en
    case zh
  }

  /// 动态字体档（U5-c 覆盖 AX3/AX5；默认档 = `.large`）。
  public enum Size: String, CaseIterable, Sendable {
    case `default`
    case ax3
    case ax5
  }

  /// 一层测量结果（pt）。
  public struct Measurement: Sendable {
    /// 字体级：缩放后字体的 `lineHeight`。
    public let fontNatural: Double
    /// 渲染级：单行 `Text(verbatim:)` 的 `sizeThatFits` 高度（U5 的验收对象）。
    public let renderedNatural: Double
  }

  /// 记录时的环境（漂移提示用）。
  public static let recordedWith = "Xcode 26.6 / iOS 26.5 模拟器 / 2026-10-07"

  /// 取一条记录；**返回 nil 表示 fixture 缺失 ⇒ 调用方必须 fail**。
  public static func measurement(script: Script, style: String, size: Size) -> Measurement? {
    table[script]?[style]?[size]
  }

  private static let table: [Script: [String: [Size: Measurement]]] = [
    .en: [
      "largeTitle": [
        .default: Measurement(fontNatural: 40.57, renderedNatural: 40.67),
        .ax3: Measurement(fontNatural: 62.05, renderedNatural: 62.33),
        .ax5: Measurement(fontNatural: 71.6, renderedNatural: 71.67),
      ],
      "title1": [
        .default: Measurement(fontNatural: 33.41, renderedNatural: 33.67),
        .ax3: Measurement(fontNatural: 57.28, renderedNatural: 57.33),
        .ax5: Measurement(fontNatural: 69.21, renderedNatural: 69.33),
      ],
      "title2": [
        .default: Measurement(fontNatural: 26.25, renderedNatural: 26.33),
        .ax3: Measurement(fontNatural: 52.51, renderedNatural: 52.67),
        .ax5: Measurement(fontNatural: 66.83, renderedNatural: 67.0),
      ],
      "title3": [
        .default: Measurement(fontNatural: 23.87, renderedNatural: 24.0),
        .ax3: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
        .ax5: Measurement(fontNatural: 65.63, renderedNatural: 65.67),
      ],
      "headline": [
        .default: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .ax3: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
        .ax5: Measurement(fontNatural: 63.25, renderedNatural: 63.33),
      ],
      "body": [
        .default: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .ax3: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
        .ax5: Measurement(fontNatural: 63.25, renderedNatural: 63.33),
      ],
      "callout": [
        .default: Measurement(fontNatural: 19.09, renderedNatural: 19.33),
        .ax3: Measurement(fontNatural: 45.35, renderedNatural: 45.67),
        .ax5: Measurement(fontNatural: 60.86, renderedNatural: 61.0),
      ],
      "subheadline": [
        .default: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .ax3: Measurement(fontNatural: 42.96, renderedNatural: 43.0),
        .ax5: Measurement(fontNatural: 58.47, renderedNatural: 58.67),
      ],
      "footnote": [
        .default: Measurement(fontNatural: 15.51, renderedNatural: 15.67),
        .ax3: Measurement(fontNatural: 39.38, renderedNatural: 39.67),
        .ax5: Measurement(fontNatural: 52.51, renderedNatural: 52.67),
      ],
      "caption1": [
        .default: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .ax3: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .ax5: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
      ],
      "caption2": [
        .default: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .ax3: Measurement(fontNatural: 34.61, renderedNatural: 34.67),
        .ax5: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
      ],
      "overline": [
        .default: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .ax3: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .ax5: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
      ],
    ],
    .zh: [
      "largeTitle": [
        .default: Measurement(fontNatural: 47.6, renderedNatural: 40.67),
        .ax3: Measurement(fontNatural: 72.8, renderedNatural: 62.33),
        .ax5: Measurement(fontNatural: 84.0, renderedNatural: 71.67),
      ],
      "title1": [
        .default: Measurement(fontNatural: 39.2, renderedNatural: 33.67),
        .ax3: Measurement(fontNatural: 67.2, renderedNatural: 57.33),
        .ax5: Measurement(fontNatural: 81.2, renderedNatural: 69.33),
      ],
      "title2": [
        .default: Measurement(fontNatural: 30.8, renderedNatural: 26.33),
        .ax3: Measurement(fontNatural: 61.6, renderedNatural: 52.67),
        .ax5: Measurement(fontNatural: 78.4, renderedNatural: 67.0),
      ],
      "title3": [
        .default: Measurement(fontNatural: 28.0, renderedNatural: 24.0),
        .ax3: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
        .ax5: Measurement(fontNatural: 77.0, renderedNatural: 65.67),
      ],
      "headline": [
        .default: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .ax3: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
        .ax5: Measurement(fontNatural: 74.2, renderedNatural: 63.33),
      ],
      "body": [
        .default: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .ax3: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
        .ax5: Measurement(fontNatural: 74.2, renderedNatural: 63.33),
      ],
      "callout": [
        .default: Measurement(fontNatural: 22.4, renderedNatural: 19.33),
        .ax3: Measurement(fontNatural: 53.2, renderedNatural: 45.67),
        .ax5: Measurement(fontNatural: 71.4, renderedNatural: 61.0),
      ],
      "subheadline": [
        .default: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .ax3: Measurement(fontNatural: 50.4, renderedNatural: 43.0),
        .ax5: Measurement(fontNatural: 68.6, renderedNatural: 58.67),
      ],
      "footnote": [
        .default: Measurement(fontNatural: 18.2, renderedNatural: 15.67),
        .ax3: Measurement(fontNatural: 46.2, renderedNatural: 39.67),
        .ax5: Measurement(fontNatural: 61.6, renderedNatural: 52.67),
      ],
      "caption1": [
        .default: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .ax3: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .ax5: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
      ],
      "caption2": [
        .default: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .ax3: Measurement(fontNatural: 40.6, renderedNatural: 34.67),
        .ax5: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
      ],
      "overline": [
        .default: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .ax3: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .ax5: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
      ],
    ],
  ]
}
