import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDDivider`（M2）的组件级断言：线宽、颜色、不进无障碍树（渲染层能机检的部分）。
@MainActor
@Suite("WDDivider（M2）")
struct WDDividerTests {
  @Test("线宽 1pt、宽度吃满容器（全宽档）")
  func geometry() {
    let controller = UIHostingController(
      rootView: WDDivider().frame(width: 300).wdTheme(.light))
    let size = controller.sizeThatFits(in: CGSize(width: 300, height: 100))
    #expect(abs(size.height - 1) <= 0.5, "实测高度 \(size.height)，应为 1pt")
    #expect(abs(size.width - 300) <= 0.5, "实测宽度 \(size.width)，应为 300")
  }

  @Test("颜色 = border.hairline（叠在白底上的合成色，浅色档）")
  func color() {
    let renderer = ImageRenderer(
      content: WDDivider()
        .frame(width: 100)
        .background(Color.white)
        .wdTheme(.light)
    )
    renderer.scale = 1
    guard let image = renderer.uiImage, let cgImage = image.cgImage else {
      Issue.record("分割线渲染失败")
      return
    }
    var pixel = [UInt8](repeating: 0, count: 4)
    guard
      let context = CGContext(
        data: &pixel,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      Issue.record("像素上下文创建失败")
      return
    }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))

    // border.hairline 浅色 = 0x0A1B24 @ 7.8% 叠在纯白上 ⇒ ≈ (236, 237, 238)。
    #expect(abs(Int(pixel[0]) - 236) <= 3, "R 通道实测 \(pixel[0])")
    #expect(abs(Int(pixel[1]) - 237) <= 3, "G 通道实测 \(pixel[1])")
    #expect(abs(Int(pixel[2]) - 238) <= 3, "B 通道实测 \(pixel[2])")
  }
}
