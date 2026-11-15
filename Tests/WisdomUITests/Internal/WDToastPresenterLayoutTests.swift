import CoreGraphics
import Testing

@testable import WisdomUI

/// 窗口层 Toast 的重排几何：旋转 / 分屏 / 安全区变化后由宿主按新 bounds 重算 frame。
@Suite("Toast 窗口层重排")
struct WDToastPresenterLayoutTests {
  private let portrait = CGRect(x: 0, y: 0, width: 393, height: 852)
  private let landscape = CGRect(x: 0, y: 0, width: 852, height: 393)

  @Test("竖屏：满宽、水平居中、贴安全区底部")
  func portraitGeometry() {
    let frame = WDToastLayout.frame(in: portrait, safeAreaBottom: 34, contentHeight: 50)
    #expect(frame.width == portrait.width)
    #expect(frame.height == 50)
    #expect(frame.midX == portrait.midX)
    #expect(frame.minX == portrait.minX)
    #expect(frame.maxY == portrait.maxY - 34 - WDToastLayout.bottomInset)
    #expect(frame.minY == 752)
  }

  @Test("横屏：宽度跟新 bounds，y 按新高度重算")
  func landscapeGeometry() {
    let frame = WDToastLayout.frame(in: landscape, safeAreaBottom: 21, contentHeight: 50)
    #expect(frame.width == landscape.width)
    #expect(frame.height == 50)
    #expect(frame.midX == landscape.midX)
    #expect(frame.maxY == landscape.maxY - 21 - WDToastLayout.bottomInset)
    #expect(frame.minY == 306)
  }

  @Test("安全区变化只抬高浮层，宽度与高度不变")
  func safeAreaChangesYOnly() {
    let flush = WDToastLayout.frame(in: portrait, safeAreaBottom: 0, contentHeight: 50)
    let homeIndicator = WDToastLayout.frame(in: portrait, safeAreaBottom: 34, contentHeight: 50)
    #expect(flush.width == homeIndicator.width)
    #expect(flush.height == homeIndicator.height)
    #expect(flush.minY - homeIndicator.minY == 34)
  }

  @Test("内容高低于最小字段高时按 WDSize.fieldHeight 取")
  func minHeightClamp() {
    let frame = WDToastLayout.frame(in: portrait, safeAreaBottom: 34, contentHeight: 10)
    #expect(frame.height == WDSize.fieldHeight)
    #expect(frame.minY == 852 - 34 - WDToastLayout.bottomInset - WDSize.fieldHeight)
  }

  @Test("内容变高时浮层整体上移，底边（安全区位置）不变")
  func tallerContentMovesUp() {
    let short = WDToastLayout.frame(
      in: portrait, safeAreaBottom: 34, contentHeight: WDSize.fieldHeight)
    let tall = WDToastLayout.frame(
      in: portrait, safeAreaBottom: 34, contentHeight: WDSize.fieldHeight + 20)
    #expect(short.maxY == tall.maxY)
    #expect(short.minY - tall.minY == 20)
    #expect(tall.height == WDSize.fieldHeight + 20)
  }
}
