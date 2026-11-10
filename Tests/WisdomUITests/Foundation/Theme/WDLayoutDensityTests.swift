import SwiftUI
import Testing
import UIKit

import WisdomUI

/// 布局密度（F44）：默认档、令牌值与写入口（`wdDensity`）的机器保证。
@MainActor
@Suite("布局密度（WDLayoutDensity）")
struct WDLayoutDensityTests {
  private final class Probe {
    var seen: WDLayoutDensity?
  }

  private struct ProbeView: View {
    @Environment(\.wdDensity) private var density
    let probe: Probe

    var body: some View {
      probe.seen = density
      return Color.clear
    }
  }

  private static func read(density: WDLayoutDensity? = nil) -> WDLayoutDensity? {
    let probe = Probe()
    var view = AnyView(ProbeView(probe: probe))
    if let density {
      view = AnyView(ProbeView(probe: probe).wdDensity(density))
    }
    let renderer = ImageRenderer(content: view.frame(width: 8, height: 8))
    _ = renderer.uiImage
    return probe.seen
  }

  @Test("默认档 = comfortable（设计 09-layout §4）")
  func defaultDensity() {
    #expect(Self.read() == .comfortable)
  }

  @Test("行高下限取令牌：comfortable 60 / compact 44")
  func rowMinHeightUsesTokens() {
    #expect(WDLayoutDensity.comfortable.rowMinHeight == WDSize.rowHeightComfortable)
    #expect(WDLayoutDensity.compact.rowMinHeight == WDSize.rowHeightCompact)
    #expect(WDLayoutDensity.comfortable.rowMinHeight == 60)
    #expect(WDLayoutDensity.compact.rowMinHeight == 44)
  }

  @Test("写入口 .wdDensity(_:) 生效（组件只读，写入口唯一）")
  func modifierWrites() {
    #expect(Self.read(density: .compact) == .compact)
    #expect(Self.read(density: .comfortable) == .comfortable)
  }
}
