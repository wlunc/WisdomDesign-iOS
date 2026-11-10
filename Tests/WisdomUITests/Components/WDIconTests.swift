import SwiftUI
import Testing
import UIKit

import WisdomUI

/// `WDIcon`（M2）的组件级断言：渲染几何、动态字体不变性（设计：图标尺寸锁死）。
///
/// 名称与 SF Symbols 的映射由 `Foundation/Icons` 的两个测试覆盖（44 条计数、逐条存在性、四档点径）；
/// 这里只补"组件层"的两条：档位单调递增、**AX5 下不放大**（`docs/ICON-PIPELINE.md` §5/§7）。
@MainActor
@Suite("WDIcon（M2）")
struct WDIconTests {
  private static func renderedSize(
    _ size: WDIconSize, typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let controller = UIHostingController(
      rootView: WDIcon(icon: .home, size: size)
        .environment(\.dynamicTypeSize, typeSize)
        .fixedSize()
    )
    return controller.sizeThatFits(in: CGSize(width: 200, height: 200))
  }

  @Test("四档渲染尺寸单调递增（16 / 20 / 24 / 28）")
  func sizesAreMonotonic() {
    let sizes = WDIconSize.allCases.map { Self.renderedSize($0) }
    for index in 1..<sizes.count {
      #expect(
        sizes[index].width > sizes[index - 1].width
          || sizes[index].height > sizes[index - 1].height,
        "档位 \(WDIconSize.allCases[index].rawValue) 没有比上一档大：\(sizes[index - 1]) → \(sizes[index])"
      )
    }
  }

  @Test("AX5 下渲染尺寸不放大（图标尺寸锁死，不走动态字体）")
  func doesNotScaleWithDynamicType() {
    for size in WDIconSize.allCases {
      let normal = Self.renderedSize(size, typeSize: .large)
      let ax5 = Self.renderedSize(size, typeSize: .accessibility5)
      #expect(
        abs(normal.width - ax5.width) <= 0.5 && abs(normal.height - ax5.height) <= 0.5,
        "档位 \(size.rawValue) 在 AX5 下放大了：\(normal) → \(ax5)"
      )
    }
  }
}
