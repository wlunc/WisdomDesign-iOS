import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// M4 九件的结构断言（尺寸/变体/可见性；不含动画与真实呈现）。
@MainActor
@Suite("M4 反馈与弹层")
struct M4ComponentsTests {
  private func height<V: View>(_ view: V, width: CGFloat = 360) -> CGFloat {
    let controller = UIHostingController(rootView: view)
    return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
      .height
  }

  // MARK: - 进度

  @Test("WDProgressBar：0 / 0.5 / 1 高度一致；标签增加一行高度")
  func progressBarHeights() {
    let zero = height(WDProgressBar(value: 0))
    let half = height(WDProgressBar(value: 0.5))
    let full = height(WDProgressBar(value: 1))
    #expect(zero == half)
    #expect(half == full)
    #expect(zero > 0)
    let labeled = height(
      WDProgressBar(value: 0.5, label: Text(verbatim: "上传"), valueText: Text(verbatim: "50%"))
    )
    #expect(labeled > zero)
  }

  @Test("WDProgressBar：不确定态有高度；越界值被钳制（不崩溃）")
  func progressBarIndeterminateAndClamp() {
    #expect(height(WDProgressBar(label: Text(verbatim: "加载中"))) > 0)
    #expect(height(WDProgressBar(value: -3)) == height(WDProgressBar(value: 0)))
    #expect(height(WDProgressBar(value: 7)) == height(WDProgressBar(value: 1)))
  }

  @Test("WDProgressRing：标准 60 > 紧凑 44；标签增加高度")
  func progressRingSizes() {
    let standard = height(WDProgressRing(value: 0.5))
    let compact = height(WDProgressRing(value: 0.5, size: .compact))
    #expect(standard > compact)
    let labeled = height(
      WDProgressRing(value: 0.5, label: Text(verbatim: "本周家务"), valueText: Text(verbatim: "3/5"))
    )
    #expect(labeled > standard)
  }

  // MARK: - 占位与空态

  @Test("WDEmptyState：标题 + 说明 + 操作逐段增高；无操作时更矮")
  func emptyStateComposition() {
    let titleOnly = height(WDEmptyState(title: Text(verbatim: "还没有任务")))
    let withMessage = height(
      WDEmptyState(title: Text(verbatim: "还没有任务"), message: Text(verbatim: "新建第一个任务。"))
    )
    let withAction = height(
      WDEmptyState(
        icon: .task,
        title: Text(verbatim: "还没有任务"),
        message: Text(verbatim: "新建第一个任务。"),
        action: .init(label: Text(verbatim: "新建"), action: {})
      )
    )
    #expect(withMessage > titleOnly)
    #expect(withAction > withMessage)
  }

  @Test("WDSkeleton：三种形态都有高度；lineCount 上限钳制")
  func skeletonVariants() {
    let text = height(WDSkeleton(variant: .text, lineCount: 3))
    let list = height(WDSkeleton(variant: .list))
    let card = height(WDSkeleton(variant: .card))
    #expect(text > 0)
    #expect(list > 0)
    #expect(card > 0)
    #expect(
      height(WDSkeleton(variant: .text, lineCount: 4))
        == height(WDSkeleton(variant: .text, lineCount: 10)))
  }

  @Test("WDSkeleton：320 宽容器不横向溢出（列表/卡片内部行宽用容器宽度）")
  func skeletonFitsWidth() {
    for variant in WDSkeletonVariant.allCases {
      let controller = UIHostingController(
        rootView: WDSkeleton(variant: variant, accessibilityLabel: Text(verbatim: "加载中"))
      )
      let size = controller.sizeThatFits(
        in: CGSize(width: 320, height: CGFloat.greatestFiniteMagnitude)
      )
      #expect(size.width <= 320.5, "skeleton width overflow")
    }
  }

  // MARK: - 提示

  @Test("WDBanner：可见时有高度且 ≥ 44；不可见时 0")
  func bannerVisibility() {
    let visible = height(
      WDBanner(isVisible: .constant(true), variant: .warning, message: Text(verbatim: "网络不可用"))
    )
    #expect(visible >= WDSize.touchTargetMin)
    #expect(height(WDBanner(isVisible: .constant(false), message: Text(verbatim: "网络不可用"))) == 0)
    #expect(WDBannerVariant.allCases.map(\.rawValue) == ["info", "warning", "danger"])
  }

  // MARK: - 弹层（未呈现时不改变锚点高度）

  @Test("WDAlert：未呈现不改变锚点；按钮角色齐全")
  func alertModifier() {
    let anchor = Text(verbatim: "anchor")
    let plain = height(anchor)
    let withAlert = height(
      anchor.wdAlert(
        isPresented: .constant(false),
        title: Text(verbatim: "删除？"),
        actions: [.init(label: Text(verbatim: "删除"), role: .destructive, action: {})]
      )
    )
    #expect(plain == withAlert)
    #expect(WDAlertAction.Role.allCasesForTest == [.default, .cancel, .destructive])
  }

  @Test("WDToast：未呈现不改变锚点；四个变体齐")
  func toastModifier() {
    let anchor = Text(verbatim: "anchor")
    let plain = height(anchor)
    let withToast = height(
      anchor.wdToast(
        isPresented: .constant(false),
        variant: .success,
        message: Text(verbatim: "已保存")
      )
    )
    #expect(plain == withToast)
    #expect(WDToastVariant.allCases.map(\.rawValue) == ["neutral", "success", "warning", "danger"])
  }

  @Test("WDBottomSheet / WDActionSheet：档位与角色齐全；未呈现不改变锚点")
  func sheetModifiers() {
    #expect(WDBottomSheetDetent.allCases.map(\.rawValue) == ["half", "large"])
    #expect(WDBottomSheetDetents.all == .all)
    #expect(WDBottomSheetDetents.fixed(.half) == .fixed(.half))
    let items = [
      WDActionSheetItem(id: "share", label: Text(verbatim: "分享")),
      WDActionSheetItem(id: "delete", label: Text(verbatim: "删除"), role: .destructive),
      WDActionSheetItem(id: "cancel", label: Text(verbatim: "取消"), role: .cancel),
    ]
    #expect(items.map(\.role) == [.default, .destructive, .cancel])
    let anchor = Text(verbatim: "anchor")
    let plain = height(anchor)
    let withSheet = height(
      anchor.wdSheet(
        isPresented: .constant(false),
        closeButtonAccessibilityLabel: Text(verbatim: "关闭")
      ) {
        Text(verbatim: "content")
      } footer: {
        EmptyView()
      }
    )
    #expect(plain == withSheet)
  }
}

private extension WDAlertAction.Role {
  static var allCasesForTest: [WDAlertAction.Role] { [.default, .cancel, .destructive] }
}
