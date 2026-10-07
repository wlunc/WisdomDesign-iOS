import SwiftUI
import Testing
import UIKit
import WisdomUI

/// 主题层与**运行时 scheme 切换**（M1 出口④；F-05）。
///
/// 三条要证的事：
///   ① `wdColors` 是 `wdTheme.colors` 的只读派生（注入主题 ⇒ 读到的槽位值跟着变）；
///   ② 运行时换 scheme **不重启进程**：同一进程内先后注入两套 scheme，读到两套值；
///   ③ 主题真的驱动渲染：把 `bg.canvas` 画出来，取像素验证是深色而不是浅色。
@MainActor
@Suite("主题与运行时 scheme 切换")
struct WDThemeTests {
  /// 探针：读出环境里的 `wdColors`（测试专用）。
  final class Probe {
    var seen: WDColorValues?
  }

  private struct ProbeView: View {
    @Environment(\.wdColors) private var colors
    let probe: Probe

    var body: some View {
      probe.seen = colors
      return Color.clear
    }
  }

  /// 渲染一次探针视图，返回它读到的槽位值。
  static func read(theme: WDTheme) -> WDColorValues? {
    let probe = Probe()
    let renderer = ImageRenderer(
      content: ProbeView(probe: probe).wdTheme(theme).frame(width: 8, height: 8))
    _ = renderer.uiImage
    return probe.seen
  }

  @Test("wdColors 是 wdTheme.colors 的只读派生")
  func colorsDeriveFromTheme() {
    #expect(Self.read(theme: .light) == WDColorValues.light)
    #expect(Self.read(theme: .dark) == WDColorValues.dark)
  }

  @Test("运行时换 scheme：同一进程内两套值都取得到（不重启）")
  func switchingSchemeAtRuntime() {
    let first = Self.read(theme: .light)
    let second = Self.read(theme: .dark)
    #expect(first != second, "两套 scheme 的槽位值必须不同，否则'换肤'是假的")
    #expect(first == WDColorValues.light)
    #expect(second == WDColorValues.dark)
    // 换回来仍拿得到第一套：状态没有被"烧死"在某一套上。
    #expect(Self.read(theme: .light) == WDColorValues.light)
  }

  @Test("scheme 清单与生成物一致，未知 scheme 不静默回退")
  func schemeList() {
    #expect(WDColorValues.wdSchemeNames == ["light", "dark"])
    #expect(WDTheme.named("light") == .light)
    #expect(WDTheme.named("dark") == .dark)
    #expect(WDTheme.named("nope") == nil)
    #expect(WDTheme.default.scheme == WDColorValues.wdDefaultScheme)
  }

  @Test("主题驱动渲染：bg.canvas 画出来的像素就是该 scheme 的画布色")
  func themeDrivesRendering() {
    let light = Self.canvasPixel(theme: .light)
    let dark = Self.canvasPixel(theme: .dark)
    #expect(light != dark, "浅/深画布像素必须不同")
    #expect(Self.isClose(light, red: 0xF1, green: 0xF8, blue: 0xFA), "浅色画布应为 0xF1F8FA，实测 \(light)")
    #expect(Self.isClose(dark, red: 0x0A, green: 0x1B, blue: 0x26), "深色画布应为 0x0A1B26，实测 \(dark)")
  }

  // MARK: - 像素取样

  private struct CanvasView: View {
    @Environment(\.wdColors) private var colors

    var body: some View {
      Rectangle().fill(colors.bgCanvas)
    }
  }

  static func canvasPixel(theme: WDTheme) -> (r: Int, g: Int, b: Int) {
    let renderer = ImageRenderer(content: CanvasView().wdTheme(theme).frame(width: 4, height: 4))
    renderer.scale = 1
    guard let image = renderer.uiImage, let cgImage = image.cgImage else { return (-1, -1, -1) }
    var pixel = [UInt8](repeating: 0, count: 4)
    guard
      let context = CGContext(
        data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return (-1, -1, -1) }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
  }

  static func isClose(_ pixel: (r: Int, g: Int, b: Int), red: Int, green: Int, blue: Int) -> Bool {
    abs(pixel.r - red) <= 2 && abs(pixel.g - green) <= 2 && abs(pixel.b - blue) <= 2
  }
}
