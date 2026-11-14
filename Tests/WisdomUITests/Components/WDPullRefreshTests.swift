import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// 下拉刷新（设计 32）：阈值/尺寸/进度映射的纯逻辑断言。
@MainActor
@Suite("WDPullRefresh")
struct WDPullRefreshTests {
  @Test("触发阈值 64、最大下拉 120（设计验收：误差 ≤ 2pt）")
  func thresholdAndMaximum() {
    #expect(abs(WDPullRefreshMetrics.triggerThreshold - 64) <= 2)
    #expect(abs(WDPullRefreshMetrics.maximumPull - 120) <= 2)
  }

  @Test("指示器直径 24、环线宽 2、与首行间距 space.4")
  func ringGeometry() {
    #expect(WDPullRefreshMetrics.ringDiameter == 24)
    #expect(WDPullRefreshMetrics.ringLineWidth == 2)
    #expect(WDPullRefreshMetrics.ringGap == WDSpacing.s4)
  }

  @Test("下拉距离：到顶后继续下拉才计数；顶部 inset 要扣掉")
  func pullDistance() {
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: 0, topInset: 0) == 0)
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: -30, topInset: 0) == 30)
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: -30, topInset: 10) == 20)
    // 正 offset（内容上移）不算下拉。
    #expect(WDPullRefreshMetrics.pullDistance(offsetY: 40, topInset: 10) == 0)
  }

  @Test("环进度：0 → 0、半程 → 0.5、阈值 → 1、超限封顶 1")
  func progressMapping() {
    #expect(WDPullRefreshMetrics.progress(pull: 0) == 0)
    #expect(abs(WDPullRefreshMetrics.progress(pull: 32) - 0.5) < 0.0001)
    #expect(WDPullRefreshMetrics.progress(pull: 64) == 1)
    #expect(WDPullRefreshMetrics.progress(pull: 120) == 1)
  }

  @Test("阈值判定：64 及以上才触发；59 不触发（容差内）")
  func thresholdDecision() {
    #expect(!WDPullRefreshMetrics.isPastThreshold(0))
    #expect(!WDPullRefreshMetrics.isPastThreshold(59))
    #expect(WDPullRefreshMetrics.isPastThreshold(64))
    #expect(WDPullRefreshMetrics.isPastThreshold(120))
  }

  @Test("指示器：贴顶不越出容器；透明度随下拉 0 → 1")
  func indicatorPresentation() {
    #expect(WDPullRefreshMetrics.indicatorTop(pull: 0) == 0)
    #expect(WDPullRefreshMetrics.indicatorTop(pull: 20) == 0)
    #expect(WDPullRefreshMetrics.indicatorOpacity(pull: 0) == 0)
    #expect(
      abs(WDPullRefreshMetrics.indicatorOpacity(pull: WDPullRefreshMetrics.fadeInDistance) - 1)
        < 0.0001)
    #expect(WDPullRefreshMetrics.indicatorOpacity(pull: 200) == 1)
  }

  @Test("自绘层不改变锚点高度（覆盖 + offset 都不参与布局）")
  func anchorHeightUnchanged() {
    let controller = UIHostingController(
      rootView: Text(verbatim: "anchor")
        .wdPullRefresh(isRefreshing: .constant(false), label: Text(verbatim: "刷新")) {}
    )
    let modified = controller.sizeThatFits(
      in: CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude))
    let plain = UIHostingController(rootView: Text(verbatim: "anchor")).sizeThatFits(
      in: CGSize(width: 360, height: CGFloat.greatestFiniteMagnitude))
    #expect(abs(plain.height - modified.height) <= 0.5)
  }
}
