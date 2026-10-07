import SwiftUI
import Testing
import WisdomUI

/// 对比度门槛（DF-04：4.5:1 / 3:1 + "最不利"口径）—— M1 三件套之三。
///
/// M1 只做**骨架**：把阈值、合成、"最不利"取色的算法钉住，并对默认主题做首轮断言。
/// 真正的账目（每套 scheme × 每槽位）由 `contracts/contrast.json` 在 M0-5 落库后接进来。
@MainActor
@Suite("对比度 DF-04")
struct WDContrastTests {
  @Test("公式自检：黑白 = 21:1；同色 = 1:1")
  func formulaSanity() {
    let white = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    #expect(abs(WDContrast.ratio(white, black) - 21) < 0.01, "黑白对比度应为 21:1")
    #expect(abs(WDContrast.ratio(white, white) - 1) < 0.001)
  }

  @Test("合成：半透明色叠在不透明底上（玻璃取合成色的输入）")
  func compositing() {
    let half = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.5)
    let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    let composited = WDContrast.rgba(WDContrast.composite(half, over: black))
    #expect(abs(composited.r - 0.5) < 0.01, "50% 白叠黑应为 0.5，实得 \(composited.r)")
    #expect(abs(composited.a - 1) < 0.001, "合成结果必须不透明")
  }

  @Test("门槛：正文 4.5:1，图形/大字号 3:1")
  func thresholds() {
    #expect(WDContrast.meetsBodyText(4.5))
    #expect(!WDContrast.meetsBodyText(4.49))
    #expect(WDContrast.meetsGraphics(3.0))
    #expect(!WDContrast.meetsGraphics(2.99))
    #expect(WDContrast.bodyTextThreshold == 4.5)
    #expect(WDContrast.graphicsThreshold == 3.0)
  }

  @Test("默认主题：canvas 上三档文字都过 4.5:1（浅/深各自一套槽位）")
  func canvasTextMeetsThreshold() {
    for (name, values) in [("light", WDColorValues.light), ("dark", WDColorValues.dark)] {
      for (level, text) in [
        ("primary", values.textPrimary),
        ("secondary", values.textSecondary),
        ("tertiary", values.textTertiary),
      ] {
        let ratio = WDContrast.ratio(text, values.bgCanvas)
        print(String(format: "CONTRAST %@ canvas/%@ = %.2f", name, level, ratio))
        #expect(
          WDContrast.meetsBodyText(ratio),
          "\(name)/\(level) 在 bg.canvas 上只有 \(ratio):1（门槛 4.5）"
        )
      }
    }
  }

  /// 玻璃上的对比度：按 DF-04 的**"最不利"口径**取色 —— 玻璃叠在**最暗（黑）与最亮（白）内容**上，
  /// 取两者中更差的那个。**不是**叠在画布上：那是最好情况，会把账目算成全绿（首版就是这么错的）。
  static func worstGlassRatio(_ glass: Color, _ text: Color) -> Double {
    let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    let white = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    return min(
      WDContrast.ratio(text, WDContrast.composite(glass, over: black)),
      WDContrast.ratio(text, WDContrast.composite(glass, over: white))
    )
  }

  @Test("玻璃账目：DF-04 §12.3 的已知不达标清单（与设计账目逐条对齐）")
  func glassLedger() {
    let light = WDColorValues.light
    let dark = WDColorValues.dark
    let rows: [(String, Double)] = [
      ("light.glass/primary", Self.worstGlassRatio(light.surfaceGlass, light.textPrimary)),
      ("light.glass/secondary", Self.worstGlassRatio(light.surfaceGlass, light.textSecondary)),
      ("light.glass/tertiary", Self.worstGlassRatio(light.surfaceGlass, light.textTertiary)),
      ("dark.glass/primary", Self.worstGlassRatio(dark.surfaceGlass, dark.textPrimary)),
      ("dark.glassStrong/primary", Self.worstGlassRatio(dark.surfaceGlassStrong, dark.textPrimary)),
      (
        "dark.glassStrong/secondary",
        Self.worstGlassRatio(dark.surfaceGlassStrong, dark.textSecondary)
      ),
      (
        "dark.glassStrong/tertiary",
        Self.worstGlassRatio(dark.surfaceGlassStrong, dark.textTertiary)
      ),
    ]
    for (label, ratio) in rows {
      print(String(format: "CONTRAST-GLASS %@ = %.2f", label, ratio))
    }
    let byLabel = Dictionary(uniqueKeysWithValues: rows)
    // 设计账目（06-accessibility.md §5.2 / 12-b22-glass.md §4）：浅色 glass 只放 primary；深色 glass 零字阶可用。
    #expect(
      WDContrast.meetsBodyText(byLabel["light.glass/primary"] ?? 0),
      "浅色 glass + primary 应达标（设计 16.3）")
    #expect(
      !WDContrast.meetsBodyText(byLabel["light.glass/secondary"] ?? 9),
      "浅色 glass + secondary 已知不达标（设计 3.6）")
    #expect(
      !WDContrast.meetsBodyText(byLabel["light.glass/tertiary"] ?? 9),
      "浅色 glass + tertiary 已知不达标（设计 3.1）")
    #expect(
      !WDContrast.meetsBodyText(byLabel["dark.glass/primary"] ?? 9),
      "深色 glass + primary 已知不达标（设计 4.1）")
    #expect(
      WDContrast.meetsBodyText(byLabel["dark.glassStrong/primary"] ?? 0),
      "深色 glass-strong + primary 应达标")
    #expect(
      !WDContrast.meetsBodyText(byLabel["dark.glassStrong/secondary"] ?? 9),
      "深色 glass-strong + secondary 已知不达标（4.2）")
    #expect(
      !WDContrast.meetsBodyText(byLabel["dark.glassStrong/tertiary"] ?? 9),
      "深色 glass-strong + tertiary 已知不达标（2.9）")
  }
}
