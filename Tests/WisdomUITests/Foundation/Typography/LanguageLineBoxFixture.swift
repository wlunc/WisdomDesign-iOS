import Foundation
import SwiftUI

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

  /// 动态字体档：**12 档全集**（U-04 的口径 = 12 档 × 12 字阶；默认档 = `.large`）。
  ///
  /// 档位名与 `DynamicTypeSize` 一一对应（`accessibility1`…`accessibility5` = AX1…AX5）。
  public enum Size: String, CaseIterable, Sendable {
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    case accessibility1
    case accessibility2
    case accessibility3
    case accessibility4
    case accessibility5

    /// 对应的 `DynamicTypeSize`（测试注入用；与档位名一一对应）。
    public var dynamicTypeSize: DynamicTypeSize {
      switch self {
      case .xSmall: return .xSmall
      case .small: return .small
      case .medium: return .medium
      case .large: return .large
      case .xLarge: return .xLarge
      case .xxLarge: return .xxLarge
      case .xxxLarge: return .xxxLarge
      case .accessibility1: return .accessibility1
      case .accessibility2: return .accessibility2
      case .accessibility3: return .accessibility3
      case .accessibility4: return .accessibility4
      case .accessibility5: return .accessibility5
      }
    }

    /// 是否放大档（AX1…AX5）——U5-c 的断言范围。
    public var isAccessibilitySize: Bool {
      switch self {
      case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
        return true
      default: return false
      }
    }
  }

  /// 一层测量结果（pt）。
  public struct Measurement: Sendable {
    /// 字体级：缩放后字体的 `lineHeight`。
    public let fontNatural: Double
    /// 渲染级：单行 `Text(verbatim:)` 的 `sizeThatFits` 高度（U5 的验收对象）。
    public let renderedNatural: Double
  }

  /// 记录时的环境（漂移提示用）。
  ///
  /// 2026-10-07 **全表重录（U-04）**：12 档 × 12 字阶 × {en, zh} × {字体级, 渲染级} = **288 条**；
  /// 触发重录的成因 = 字号来源从「手算 UIFontMetrics」改为「系统 preferred font」（放大档整体变大）。
  public static let recordedWith = "Xcode 26.6 / iOS 26.5 模拟器 / 2026-10-07（12 档全表）"

  /// 取一条记录；**返回 nil 表示 fixture 缺失 ⇒ 调用方必须 fail**。
  public static func measurement(script: Script, style: String, size: Size) -> Measurement? {
    table[script]?[style]?[size]
  }

  private static let table: [Script: [String: [Size: Measurement]]] = [
    .en: [
      "largeTitle": [
        .xSmall: Measurement(fontNatural: 36.99, renderedNatural: 37.0),
        .small: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .medium: Measurement(fontNatural: 39.38, renderedNatural: 39.67),
        .large: Measurement(fontNatural: 40.57, renderedNatural: 40.67),
        .xLarge: Measurement(fontNatural: 42.96, renderedNatural: 43.0),
        .xxLarge: Measurement(fontNatural: 45.35, renderedNatural: 45.67),
        .xxxLarge: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
        .accessibility1: Measurement(fontNatural: 52.51, renderedNatural: 52.67),
        .accessibility2: Measurement(fontNatural: 57.28, renderedNatural: 57.33),
        .accessibility3: Measurement(fontNatural: 62.05, renderedNatural: 62.33),
        .accessibility4: Measurement(fontNatural: 66.83, renderedNatural: 67.0),
        .accessibility5: Measurement(fontNatural: 71.6, renderedNatural: 71.67),
      ],
      "title1": [
        .xSmall: Measurement(fontNatural: 29.83, renderedNatural: 30.0),
        .small: Measurement(fontNatural: 31.03, renderedNatural: 31.33),
        .medium: Measurement(fontNatural: 32.22, renderedNatural: 32.33),
        .large: Measurement(fontNatural: 33.41, renderedNatural: 33.67),
        .xLarge: Measurement(fontNatural: 35.8, renderedNatural: 36.0),
        .xxLarge: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .xxxLarge: Measurement(fontNatural: 40.57, renderedNatural: 40.67),
        .accessibility1: Measurement(fontNatural: 45.35, renderedNatural: 45.67),
        .accessibility2: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
        .accessibility3: Measurement(fontNatural: 57.28, renderedNatural: 57.33),
        .accessibility4: Measurement(fontNatural: 63.25, renderedNatural: 63.33),
        .accessibility5: Measurement(fontNatural: 69.21, renderedNatural: 69.33),
      ],
      "title2": [
        .xSmall: Measurement(fontNatural: 22.67, renderedNatural: 23.0),
        .small: Measurement(fontNatural: 23.87, renderedNatural: 24.0),
        .medium: Measurement(fontNatural: 25.06, renderedNatural: 25.33),
        .large: Measurement(fontNatural: 26.25, renderedNatural: 26.33),
        .xLarge: Measurement(fontNatural: 28.64, renderedNatural: 28.67),
        .xxLarge: Measurement(fontNatural: 31.03, renderedNatural: 31.33),
        .xxxLarge: Measurement(fontNatural: 33.41, renderedNatural: 33.67),
        .accessibility1: Measurement(fontNatural: 40.57, renderedNatural: 40.67),
        .accessibility2: Measurement(fontNatural: 46.54, renderedNatural: 46.67),
        .accessibility3: Measurement(fontNatural: 52.51, renderedNatural: 52.67),
        .accessibility4: Measurement(fontNatural: 59.67, renderedNatural: 60.0),
        .accessibility5: Measurement(fontNatural: 66.83, renderedNatural: 67.0),
      ],
      "title3": [
        .xSmall: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .small: Measurement(fontNatural: 21.48, renderedNatural: 21.67),
        .medium: Measurement(fontNatural: 22.67, renderedNatural: 23.0),
        .large: Measurement(fontNatural: 23.87, renderedNatural: 24.0),
        .xLarge: Measurement(fontNatural: 26.25, renderedNatural: 26.33),
        .xxLarge: Measurement(fontNatural: 28.64, renderedNatural: 28.67),
        .xxxLarge: Measurement(fontNatural: 31.03, renderedNatural: 31.33),
        .accessibility1: Measurement(fontNatural: 36.99, renderedNatural: 37.0),
        .accessibility2: Measurement(fontNatural: 44.15, renderedNatural: 44.33),
        .accessibility3: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
        .accessibility4: Measurement(fontNatural: 58.47, renderedNatural: 58.67),
        .accessibility5: Measurement(fontNatural: 65.63, renderedNatural: 65.67),
      ],
      "headline": [
        .xSmall: Measurement(fontNatural: 16.71, renderedNatural: 17.0),
        .small: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .medium: Measurement(fontNatural: 19.09, renderedNatural: 19.33),
        .large: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .xLarge: Measurement(fontNatural: 22.67, renderedNatural: 23.0),
        .xxLarge: Measurement(fontNatural: 25.06, renderedNatural: 25.33),
        .xxxLarge: Measurement(fontNatural: 27.45, renderedNatural: 27.67),
        .accessibility1: Measurement(fontNatural: 33.41, renderedNatural: 33.67),
        .accessibility2: Measurement(fontNatural: 39.38, renderedNatural: 39.67),
        .accessibility3: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
        .accessibility4: Measurement(fontNatural: 56.09, renderedNatural: 56.33),
        .accessibility5: Measurement(fontNatural: 63.25, renderedNatural: 63.33),
      ],
      "body": [
        .xSmall: Measurement(fontNatural: 16.71, renderedNatural: 17.0),
        .small: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .medium: Measurement(fontNatural: 19.09, renderedNatural: 19.33),
        .large: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .xLarge: Measurement(fontNatural: 22.67, renderedNatural: 23.0),
        .xxLarge: Measurement(fontNatural: 25.06, renderedNatural: 25.33),
        .xxxLarge: Measurement(fontNatural: 27.45, renderedNatural: 27.67),
        .accessibility1: Measurement(fontNatural: 33.41, renderedNatural: 33.67),
        .accessibility2: Measurement(fontNatural: 39.38, renderedNatural: 39.67),
        .accessibility3: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
        .accessibility4: Measurement(fontNatural: 56.09, renderedNatural: 56.33),
        .accessibility5: Measurement(fontNatural: 63.25, renderedNatural: 63.33),
      ],
      "callout": [
        .xSmall: Measurement(fontNatural: 15.51, renderedNatural: 15.67),
        .small: Measurement(fontNatural: 16.71, renderedNatural: 17.0),
        .medium: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .large: Measurement(fontNatural: 19.09, renderedNatural: 19.33),
        .xLarge: Measurement(fontNatural: 21.48, renderedNatural: 21.67),
        .xxLarge: Measurement(fontNatural: 23.87, renderedNatural: 24.0),
        .xxxLarge: Measurement(fontNatural: 26.25, renderedNatural: 26.33),
        .accessibility1: Measurement(fontNatural: 31.03, renderedNatural: 31.33),
        .accessibility2: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .accessibility3: Measurement(fontNatural: 45.35, renderedNatural: 45.67),
        .accessibility4: Measurement(fontNatural: 52.51, renderedNatural: 52.67),
        .accessibility5: Measurement(fontNatural: 60.86, renderedNatural: 61.0),
      ],
      "subheadline": [
        .xSmall: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .small: Measurement(fontNatural: 15.51, renderedNatural: 15.67),
        .medium: Measurement(fontNatural: 16.71, renderedNatural: 17.0),
        .large: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .xLarge: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .xxLarge: Measurement(fontNatural: 22.67, renderedNatural: 23.0),
        .xxxLarge: Measurement(fontNatural: 25.06, renderedNatural: 25.33),
        .accessibility1: Measurement(fontNatural: 29.83, renderedNatural: 30.0),
        .accessibility2: Measurement(fontNatural: 35.8, renderedNatural: 36.0),
        .accessibility3: Measurement(fontNatural: 42.96, renderedNatural: 43.0),
        .accessibility4: Measurement(fontNatural: 50.12, renderedNatural: 50.33),
        .accessibility5: Measurement(fontNatural: 58.47, renderedNatural: 58.67),
      ],
      "footnote": [
        .xSmall: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .small: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .medium: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .large: Measurement(fontNatural: 15.51, renderedNatural: 15.67),
        .xLarge: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .xxLarge: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .xxxLarge: Measurement(fontNatural: 22.67, renderedNatural: 23.0),
        .accessibility1: Measurement(fontNatural: 27.45, renderedNatural: 27.67),
        .accessibility2: Measurement(fontNatural: 32.22, renderedNatural: 32.33),
        .accessibility3: Measurement(fontNatural: 39.38, renderedNatural: 39.67),
        .accessibility4: Measurement(fontNatural: 45.35, renderedNatural: 45.67),
        .accessibility5: Measurement(fontNatural: 52.51, renderedNatural: 52.67),
      ],
      "caption1": [
        .xSmall: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .small: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .medium: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .large: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .xLarge: Measurement(fontNatural: 16.71, renderedNatural: 17.0),
        .xxLarge: Measurement(fontNatural: 19.09, renderedNatural: 19.33),
        .xxxLarge: Measurement(fontNatural: 21.48, renderedNatural: 21.67),
        .accessibility1: Measurement(fontNatural: 26.25, renderedNatural: 26.33),
        .accessibility2: Measurement(fontNatural: 31.03, renderedNatural: 31.33),
        .accessibility3: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .accessibility4: Measurement(fontNatural: 44.15, renderedNatural: 44.33),
        .accessibility5: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
      ],
      "caption2": [
        .xSmall: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .small: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .medium: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .large: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .xLarge: Measurement(fontNatural: 15.51, renderedNatural: 15.67),
        .xxLarge: Measurement(fontNatural: 17.9, renderedNatural: 18.0),
        .xxxLarge: Measurement(fontNatural: 20.29, renderedNatural: 20.33),
        .accessibility1: Measurement(fontNatural: 23.87, renderedNatural: 24.0),
        .accessibility2: Measurement(fontNatural: 28.64, renderedNatural: 28.67),
        .accessibility3: Measurement(fontNatural: 34.61, renderedNatural: 34.67),
        .accessibility4: Measurement(fontNatural: 40.57, renderedNatural: 40.67),
        .accessibility5: Measurement(fontNatural: 47.73, renderedNatural: 48.0),
      ],
      "overline": [
        .xSmall: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .small: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .medium: Measurement(fontNatural: 13.13, renderedNatural: 13.33),
        .large: Measurement(fontNatural: 14.32, renderedNatural: 14.33),
        .xLarge: Measurement(fontNatural: 16.71, renderedNatural: 17.0),
        .xxLarge: Measurement(fontNatural: 19.09, renderedNatural: 19.33),
        .xxxLarge: Measurement(fontNatural: 21.48, renderedNatural: 21.67),
        .accessibility1: Measurement(fontNatural: 26.25, renderedNatural: 26.33),
        .accessibility2: Measurement(fontNatural: 31.03, renderedNatural: 31.33),
        .accessibility3: Measurement(fontNatural: 38.19, renderedNatural: 38.33),
        .accessibility4: Measurement(fontNatural: 44.15, renderedNatural: 44.33),
        .accessibility5: Measurement(fontNatural: 51.31, renderedNatural: 51.33),
      ],
    ],
    .zh: [
      "largeTitle": [
        .xSmall: Measurement(fontNatural: 43.4, renderedNatural: 37.0),
        .small: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .medium: Measurement(fontNatural: 46.2, renderedNatural: 39.67),
        .large: Measurement(fontNatural: 47.6, renderedNatural: 40.67),
        .xLarge: Measurement(fontNatural: 50.4, renderedNatural: 43.0),
        .xxLarge: Measurement(fontNatural: 53.2, renderedNatural: 45.67),
        .xxxLarge: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
        .accessibility1: Measurement(fontNatural: 61.6, renderedNatural: 52.67),
        .accessibility2: Measurement(fontNatural: 67.2, renderedNatural: 57.33),
        .accessibility3: Measurement(fontNatural: 72.8, renderedNatural: 62.33),
        .accessibility4: Measurement(fontNatural: 78.4, renderedNatural: 67.0),
        .accessibility5: Measurement(fontNatural: 84.0, renderedNatural: 71.67),
      ],
      "title1": [
        .xSmall: Measurement(fontNatural: 35.0, renderedNatural: 30.0),
        .small: Measurement(fontNatural: 36.4, renderedNatural: 31.33),
        .medium: Measurement(fontNatural: 37.8, renderedNatural: 32.33),
        .large: Measurement(fontNatural: 39.2, renderedNatural: 33.67),
        .xLarge: Measurement(fontNatural: 42.0, renderedNatural: 36.0),
        .xxLarge: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .xxxLarge: Measurement(fontNatural: 47.6, renderedNatural: 40.67),
        .accessibility1: Measurement(fontNatural: 53.2, renderedNatural: 45.67),
        .accessibility2: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
        .accessibility3: Measurement(fontNatural: 67.2, renderedNatural: 57.33),
        .accessibility4: Measurement(fontNatural: 74.2, renderedNatural: 63.33),
        .accessibility5: Measurement(fontNatural: 81.2, renderedNatural: 69.33),
      ],
      "title2": [
        .xSmall: Measurement(fontNatural: 26.6, renderedNatural: 23.0),
        .small: Measurement(fontNatural: 28.0, renderedNatural: 24.0),
        .medium: Measurement(fontNatural: 29.4, renderedNatural: 25.33),
        .large: Measurement(fontNatural: 30.8, renderedNatural: 26.33),
        .xLarge: Measurement(fontNatural: 33.6, renderedNatural: 28.67),
        .xxLarge: Measurement(fontNatural: 36.4, renderedNatural: 31.33),
        .xxxLarge: Measurement(fontNatural: 39.2, renderedNatural: 33.67),
        .accessibility1: Measurement(fontNatural: 47.6, renderedNatural: 40.67),
        .accessibility2: Measurement(fontNatural: 54.6, renderedNatural: 46.67),
        .accessibility3: Measurement(fontNatural: 61.6, renderedNatural: 52.67),
        .accessibility4: Measurement(fontNatural: 70.0, renderedNatural: 60.0),
        .accessibility5: Measurement(fontNatural: 78.4, renderedNatural: 67.0),
      ],
      "title3": [
        .xSmall: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .small: Measurement(fontNatural: 25.2, renderedNatural: 21.67),
        .medium: Measurement(fontNatural: 26.6, renderedNatural: 23.0),
        .large: Measurement(fontNatural: 28.0, renderedNatural: 24.0),
        .xLarge: Measurement(fontNatural: 30.8, renderedNatural: 26.33),
        .xxLarge: Measurement(fontNatural: 33.6, renderedNatural: 28.67),
        .xxxLarge: Measurement(fontNatural: 36.4, renderedNatural: 31.33),
        .accessibility1: Measurement(fontNatural: 43.4, renderedNatural: 37.0),
        .accessibility2: Measurement(fontNatural: 51.8, renderedNatural: 44.33),
        .accessibility3: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
        .accessibility4: Measurement(fontNatural: 68.6, renderedNatural: 58.67),
        .accessibility5: Measurement(fontNatural: 77.0, renderedNatural: 65.67),
      ],
      "headline": [
        .xSmall: Measurement(fontNatural: 19.6, renderedNatural: 17.0),
        .small: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .medium: Measurement(fontNatural: 22.4, renderedNatural: 19.33),
        .large: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .xLarge: Measurement(fontNatural: 26.6, renderedNatural: 23.0),
        .xxLarge: Measurement(fontNatural: 29.4, renderedNatural: 25.33),
        .xxxLarge: Measurement(fontNatural: 32.2, renderedNatural: 27.67),
        .accessibility1: Measurement(fontNatural: 39.2, renderedNatural: 33.67),
        .accessibility2: Measurement(fontNatural: 46.2, renderedNatural: 39.67),
        .accessibility3: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
        .accessibility4: Measurement(fontNatural: 65.8, renderedNatural: 56.33),
        .accessibility5: Measurement(fontNatural: 74.2, renderedNatural: 63.33),
      ],
      "body": [
        .xSmall: Measurement(fontNatural: 19.6, renderedNatural: 17.0),
        .small: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .medium: Measurement(fontNatural: 22.4, renderedNatural: 19.33),
        .large: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .xLarge: Measurement(fontNatural: 26.6, renderedNatural: 23.0),
        .xxLarge: Measurement(fontNatural: 29.4, renderedNatural: 25.33),
        .xxxLarge: Measurement(fontNatural: 32.2, renderedNatural: 27.67),
        .accessibility1: Measurement(fontNatural: 39.2, renderedNatural: 33.67),
        .accessibility2: Measurement(fontNatural: 46.2, renderedNatural: 39.67),
        .accessibility3: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
        .accessibility4: Measurement(fontNatural: 65.8, renderedNatural: 56.33),
        .accessibility5: Measurement(fontNatural: 74.2, renderedNatural: 63.33),
      ],
      "callout": [
        .xSmall: Measurement(fontNatural: 18.2, renderedNatural: 15.67),
        .small: Measurement(fontNatural: 19.6, renderedNatural: 17.0),
        .medium: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .large: Measurement(fontNatural: 22.4, renderedNatural: 19.33),
        .xLarge: Measurement(fontNatural: 25.2, renderedNatural: 21.67),
        .xxLarge: Measurement(fontNatural: 28.0, renderedNatural: 24.0),
        .xxxLarge: Measurement(fontNatural: 30.8, renderedNatural: 26.33),
        .accessibility1: Measurement(fontNatural: 36.4, renderedNatural: 31.33),
        .accessibility2: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .accessibility3: Measurement(fontNatural: 53.2, renderedNatural: 45.67),
        .accessibility4: Measurement(fontNatural: 61.6, renderedNatural: 52.67),
        .accessibility5: Measurement(fontNatural: 71.4, renderedNatural: 61.0),
      ],
      "subheadline": [
        .xSmall: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .small: Measurement(fontNatural: 18.2, renderedNatural: 15.67),
        .medium: Measurement(fontNatural: 19.6, renderedNatural: 17.0),
        .large: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .xLarge: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .xxLarge: Measurement(fontNatural: 26.6, renderedNatural: 23.0),
        .xxxLarge: Measurement(fontNatural: 29.4, renderedNatural: 25.33),
        .accessibility1: Measurement(fontNatural: 35.0, renderedNatural: 30.0),
        .accessibility2: Measurement(fontNatural: 42.0, renderedNatural: 36.0),
        .accessibility3: Measurement(fontNatural: 50.4, renderedNatural: 43.0),
        .accessibility4: Measurement(fontNatural: 58.8, renderedNatural: 50.33),
        .accessibility5: Measurement(fontNatural: 68.6, renderedNatural: 58.67),
      ],
      "footnote": [
        .xSmall: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .small: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .medium: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .large: Measurement(fontNatural: 18.2, renderedNatural: 15.67),
        .xLarge: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .xxLarge: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .xxxLarge: Measurement(fontNatural: 26.6, renderedNatural: 23.0),
        .accessibility1: Measurement(fontNatural: 32.2, renderedNatural: 27.67),
        .accessibility2: Measurement(fontNatural: 37.8, renderedNatural: 32.33),
        .accessibility3: Measurement(fontNatural: 46.2, renderedNatural: 39.67),
        .accessibility4: Measurement(fontNatural: 53.2, renderedNatural: 45.67),
        .accessibility5: Measurement(fontNatural: 61.6, renderedNatural: 52.67),
      ],
      "caption1": [
        .xSmall: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .small: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .medium: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .large: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .xLarge: Measurement(fontNatural: 19.6, renderedNatural: 17.0),
        .xxLarge: Measurement(fontNatural: 22.4, renderedNatural: 19.33),
        .xxxLarge: Measurement(fontNatural: 25.2, renderedNatural: 21.67),
        .accessibility1: Measurement(fontNatural: 30.8, renderedNatural: 26.33),
        .accessibility2: Measurement(fontNatural: 36.4, renderedNatural: 31.33),
        .accessibility3: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .accessibility4: Measurement(fontNatural: 51.8, renderedNatural: 44.33),
        .accessibility5: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
      ],
      "caption2": [
        .xSmall: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .small: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .medium: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .large: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .xLarge: Measurement(fontNatural: 18.2, renderedNatural: 15.67),
        .xxLarge: Measurement(fontNatural: 21.0, renderedNatural: 18.0),
        .xxxLarge: Measurement(fontNatural: 23.8, renderedNatural: 20.33),
        .accessibility1: Measurement(fontNatural: 28.0, renderedNatural: 24.0),
        .accessibility2: Measurement(fontNatural: 33.6, renderedNatural: 28.67),
        .accessibility3: Measurement(fontNatural: 40.6, renderedNatural: 34.67),
        .accessibility4: Measurement(fontNatural: 47.6, renderedNatural: 40.67),
        .accessibility5: Measurement(fontNatural: 56.0, renderedNatural: 48.0),
      ],
      "overline": [
        .xSmall: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .small: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .medium: Measurement(fontNatural: 15.4, renderedNatural: 13.33),
        .large: Measurement(fontNatural: 16.8, renderedNatural: 14.33),
        .xLarge: Measurement(fontNatural: 19.6, renderedNatural: 17.0),
        .xxLarge: Measurement(fontNatural: 22.4, renderedNatural: 19.33),
        .xxxLarge: Measurement(fontNatural: 25.2, renderedNatural: 21.67),
        .accessibility1: Measurement(fontNatural: 30.8, renderedNatural: 26.33),
        .accessibility2: Measurement(fontNatural: 36.4, renderedNatural: 31.33),
        .accessibility3: Measurement(fontNatural: 44.8, renderedNatural: 38.33),
        .accessibility4: Measurement(fontNatural: 51.8, renderedNatural: 44.33),
        .accessibility5: Measurement(fontNatural: 60.2, renderedNatural: 51.33),
      ],
    ],
  ]
}
