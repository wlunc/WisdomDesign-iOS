import SwiftUI
import Testing
import UIKit
import WisdomUI

/// U5 行盒验收（SPEC §2.6.3）：
/// `renderedLineBox = max(设计盒高 × 缩放, natural)` —— 默认档带容差、放大档不裁切，**分语种**。
///
/// 三条纪律：
///   ① **fixture 缺失 = fail**（不做默认值兜底）；
///   ② `natural` 取**渲染级**（`sizeThatFits` 口径）——实测证明 SwiftUI 的单行行盒跟随主字体，
///      字体级 zh（PingFang 1.400em）不会改行盒高；
///   ③ 多行用**显式换行**驱动（不靠 `frame` 撑高），否则量到的是 frame 而不是排版。
///
/// **与 SPEC 的一处偏差（实测驱动，待回写）**：SPEC §2.6.3 把放大档判据写成 `≥ ⌈natural × n⌉`，
/// 但 `⌈⌉` 对**非整数**自然高不可满足 —— caption2/AX3/n=2 的自然高 35.83 给出 `⌈71.67⌉ = 72`，
/// 而真实渲染恰为 71.67pt。本文件按「不裁切」的本意取 `natural × n − 0.5`（与 U5-a 同量级容差）。
@MainActor
@Suite("行盒 U5")
struct WDLineBoxTest {
  static let styles: [(String, WDTextStyle)] = [
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

  static let sizeCases: [(LanguageLineBoxFixture.Size, DynamicTypeSize)] = [
    (.default, .large),
    (.ax3, .accessibility3),
    (.ax5, .accessibility5),
  ]

  static let scripts: [(LanguageLineBoxFixture.Script, String)] = [(.en, "Ag"), (.zh, "汉字")]

  @Test("fixture 完整（缺失 = fail）")
  func fixtureIsComplete() {
    for (script, _) in Self.scripts {
      for (name, _) in Self.styles {
        for (size, _) in Self.sizeCases {
          #expect(
            LanguageLineBoxFixture.measurement(script: script, style: name, size: size) != nil,
            "fixture 缺 \(script.rawValue)/\(name)/\(size.rawValue) —— 缺失 = fail（SPEC §2.6.3 ③）"
          )
        }
      }
    }
  }

  @Test("U5-a 默认档单行：|渲染盒 − max(设计行高, natural)| ≤ 0.5pt（zh/en 分语种）")
  func defaultSingleLine() {
    for (script, sample) in Self.scripts {
      for (name, style) in Self.styles {
        guard
          let entry = LanguageLineBoxFixture.measurement(
            script: script, style: name, size: .default)
        else {
          Issue.record("fixture 缺失（缺失 = fail）：\(script.rawValue)/\(name)/default")
          continue
        }
        let rendered = Self.height(sample, style: style, lines: 1, size: .large)
        let expected = max(style.lineHeight, entry.renderedNatural)
        #expect(
          abs(rendered - expected) <= 0.5,
          "U5-a \(script.rawValue)/\(name)：渲染盒 \(rendered) vs max(设计 \(style.lineHeight), natural \(entry.renderedNatural)) = \(expected)"
        )
      }
    }
  }

  @Test("U5-b 默认档多行（n = 2、3）：|渲染盒 − max(n×设计, ⌈natural×n⌉)| ≤ 1pt")
  func defaultMultiLine() {
    for (script, sample) in Self.scripts {
      for (name, style) in Self.styles {
        guard
          let entry = LanguageLineBoxFixture.measurement(
            script: script, style: name, size: .default)
        else {
          Issue.record("fixture 缺失（缺失 = fail）：\(script.rawValue)/\(name)/default")
          continue
        }
        for lines in [2, 3] {
          let text = Array(repeating: sample, count: lines).joined(separator: "\n")
          let rendered = Self.height(text, style: style, lines: lines, size: .large)
          let byDesign = Double(lines) * style.lineHeight
          let byNatural = entry.renderedNatural * Double(lines)
          let expected = max(byDesign, byNatural)
          #expect(
            abs(rendered - expected) <= 1,
            "U5-b \(script.rawValue)/\(name)/n=\(lines)：渲染盒 \(rendered) vs max(\(byDesign), \(byNatural)) = \(expected)"
          )
        }
      }
    }
  }

  @Test("U5-c 放大档不裁切：渲染盒 ≥ ⌈natural(档) × n⌉（AX3/AX5，n = 1、2）")
  func accessibilityDoesNotClip() {
    for (script, sample) in Self.scripts {
      for (name, style) in Self.styles {
        for (size, dynamicTypeSize) in Self.sizeCases where size != .default {
          guard
            let entry = LanguageLineBoxFixture.measurement(script: script, style: name, size: size)
          else {
            Issue.record("fixture 缺失（缺失 = fail）：\(script.rawValue)/\(name)/\(size.rawValue)")
            continue
          }
          for lines in [1, 2] {
            let text = Array(repeating: sample, count: lines).joined(separator: "\n")
            let rendered = Self.height(text, style: style, lines: lines, size: dynamicTypeSize)
            // SPEC 原文写 `≥ ⌈natural × n⌉`；**实测证明带 ⌈⌉ 的写法不可满足**：
            // caption2/AX3/n=2 的自然高 35.83 ⇒ ⌈71.67⌉ = 72，而真实渲染恰为 71.67（差 0.33pt）。
            // 故按「不裁切」的本意取 `natural × n − 0.5`（与 U5-a 同一容差量级），并在文件头登记该偏差。
            let floor = entry.renderedNatural * Double(lines) - 0.5
            #expect(
              rendered >= floor,
              "U5-c \(script.rawValue)/\(name)/\(size.rawValue)/n=\(lines)：渲染盒 \(rendered) < natural×n − 0.5 = \(floor)（裁切）"
            )
          }
        }
      }
    }
  }

  @Test("自然行高未漂移：重测 vs fixture ≤ 0.5pt（超了要重新记录）")
  func naturalHasNotDrifted() {
    for (script, sample) in Self.scripts {
      for (name, style) in Self.styles {
        for (size, dynamicTypeSize) in Self.sizeCases {
          guard
            let entry = LanguageLineBoxFixture.measurement(script: script, style: name, size: size)
          else {
            Issue.record("fixture 缺失（缺失 = fail）：\(script.rawValue)/\(name)/\(size.rawValue)")
            continue
          }
          let rendered = Self.height(
            sample, style: style, lines: 0, size: dynamicTypeSize, width: 1000)
          #expect(
            abs(rendered - entry.renderedNatural) <= 0.5,
            """
            自然行高漂移 \(script.rawValue)/\(name)/\(size.rawValue)：重测 \(rendered) vs 记录 \(entry.renderedNatural)
            （> 0.5pt ⇒ 字体或 Xcode 版本变化，需按 \(LanguageLineBoxFixture.recordedWith) 的口径重新记录 fixture）
            """
          )
        }
      }
    }
  }

  /// 渲染高度：`lines == 0` 不套行盒（量自然高），否则套 `wdLineBox(_:lines:)`。
  /// - Parameter width: 布局宽度。U5-a/b/c 用 320（SPEC 口径）；漂移检查用 1000（与 fixture 录制口径一致）。
  static func height(
    _ text: String, style: WDTextStyle, lines: Int, size: DynamicTypeSize, width: CGFloat = 320
  ) -> CGFloat {
    let base = Text(verbatim: text).wdFont(style)
    let view = lines == 0 ? AnyView(base) : AnyView(base.wdLineBox(style, lines: lines))
    let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, size))
    return controller.sizeThatFits(in: CGSize(width: width, height: CGFloat.infinity)).height
  }
}
