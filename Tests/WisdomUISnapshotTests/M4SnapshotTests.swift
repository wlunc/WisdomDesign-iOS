import SwiftUI
import Testing

@testable import WisdomUI

/// M4 九件的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 玻璃类（WDBottomSheet/WDActionSheet）用面板内容走 UIHostingController + drawHierarchy；
/// 其余走 ImageRenderer。弹层类用 constant(true) 呈现，快照的是呈现后的画面。
@MainActor
@Suite("M4 快照", .serialized)
struct M4SnapshotTests {
  static let canvas = CGSize(width: 360, height: 720)

  private func framed<V: View>(_ view: V, values: WDColorValues) -> some View {
    view
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
  }

  @Test("WDProgressRing：8 态")
  func progressRing() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "progressring-\(state.id)",
        view: framed(ProgressRingSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDEmptyState：8 态")
  func emptyState() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "emptystate-\(state.id)",
        view: framed(EmptyStateSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDSkeleton：8 态（静态灰块）")
  func skeleton() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "skeleton-\(state.id)",
        view: framed(SkeletonSample(), values: values).wdEffectsBudget(.minimal),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDBanner：8 态")
  func banner() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "banner-\(state.id)",
        view: framed(BannerSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDAlert：8 态（含带输入变体）")
  func alert() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "alert-\(state.id)",
        view: framed(AlertSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDToast：8 态")
  func toast() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "toast-\(state.id)",
        view: framed(ToastSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDBottomSheet：8 态（面板内容，玻璃类渲染器）")
  func bottomSheet() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verifyHierarchy(
        name: "bottomsheet-\(state.id)",
        view: framed(BottomSheetSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  @Test("WDActionSheet：8 态（面板内容，玻璃类渲染器）")
  func actionSheet() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verifyHierarchy(
        name: "actionsheet-\(state.id)",
        view: framed(ActionSheetSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }

  // MARK: - ProgressBar（放在 suite 末尾）

  // 顺序约束：hierarchy 渲染会创建 UIWindow，之后同进程的 ImageRenderer 用例（Toast）会漂移
  // 8–14%（2026-11-14 实测；resignKey / 拆 rootViewController 均无效）。本 suite 串行执行，
  // 把 hierarchy 用例放在所有 ImageRenderer 用例之后。

  @Test("WDProgressBar：8 态（hierarchy；settle 3.4s 等首次出现 3200ms 动画落终态）")
  func progressBar() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verifyHierarchy(
        name: "progressbar-\(state.id)",
        view: framed(ProgressBarSample(), values: values),
        state: state,
        size: Self.canvas,
        settle: 3.4
      )
    }
  }

  @Test("WDProgressBar 不确定态：1 秒内不出现（ImageRenderer：无 task，只有轨道）")
  func progressBarIndeterminateDelay() {
    for state in SnapshotSupport.matrix {
      let values = SnapshotSupport.values(for: state)
      SnapshotSupport.verify(
        name: "progressbar-indeterminate-\(state.id)",
        view: framed(ProgressBarIndeterminateSample(), values: values),
        state: state,
        size: Self.canvas
      )
    }
  }
}

// MARK: - 样本

private struct ProgressBarSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDProgressBar(value: 0.45, label: Text(verbatim: "上传进度"), valueText: Text(verbatim: "45%"))
      WDProgressBar(segments: 5, completed: 3, label: Text(verbatim: "家务完成度"))
      WDProgressBar(value: 1, label: Text(verbatim: "整理储物间"), valueText: Text(verbatim: "100%"))
      WDProgressBar(value: 0.6, label: Text(verbatim: "禁用"))
        .disabled(true)
    }
    // 快照注入 instant 入口：跳过 3200ms 首次出现动画（离屏窗口里 CoreAnimation 不推进，
    // 否则终态会停在 0）。
    .environment(\.wdInstantMotion, true)
  }
}

private struct ProgressBarIndeterminateSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDProgressBar(label: Text(verbatim: "加载中"))
    }
  }
}

private struct ProgressRingSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      HStack(alignment: .top, spacing: WDSpacing.s6) {
        WDProgressRing(value: 0.6, label: Text(verbatim: "本周家务"), valueText: Text(verbatim: "3/5"))
        WDProgressRing(
          value: 0.45,
          size: .compact,
          label: Text(verbatim: "紧凑"),
          valueText: Text(verbatim: "45%")
        )
      }
      WDProgressRing(value: 1, label: Text(verbatim: "完成"))
    }
  }
}

private struct EmptyStateSample: View {
  var body: some View {
    VStack(spacing: WDSpacing.s7) {
      WDEmptyState(
        icon: .task,
        title: Text(verbatim: "还没有任务"),
        message: Text(verbatim: "新建第一个任务，把要做的事记下来。"),
        action: .init(label: Text(verbatim: "新建第一个任务"), action: {})
      )
      WDEmptyState(title: Text(verbatim: "没有找到结果"))
    }
  }
}

private struct SkeletonSample: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDSkeleton(variant: .text, lineCount: 4, accessibilityLabel: Text(verbatim: "加载中"))
      WDSkeleton(variant: .list, accessibilityLabel: Text(verbatim: "加载中"))
      WDSkeleton(variant: .card, accessibilityLabel: Text(verbatim: "加载中"))
    }
  }
}

private struct BannerSample: View {
  var body: some View {
    VStack(spacing: WDSpacing.s4) {
      WDBanner(
        isVisible: .constant(true),
        variant: .info,
        message: Text(verbatim: "已同步到家庭空间"),
        action: .init(label: Text(verbatim: "查看"), action: {})
      )
      WDBanner(isVisible: .constant(true), variant: .warning, message: Text(verbatim: "试用期还剩 3 天"))
      WDBanner(
        isVisible: .constant(true),
        variant: .danger,
        message: Text(verbatim: "网络不可用，改动已暂存本地"),
        dismissAccessibilityLabel: Text(verbatim: "关闭网络提示")
      )
    }
  }
}

private struct AlertSample: View {
  var body: some View {
    Text(verbatim: "背景内容")
      .frame(maxWidth: .infinity, minHeight: 360)
      .wdAlert(
        isPresented: .constant(true),
        title: Text(verbatim: "重命名任务"),
        message: Text(verbatim: "给任务起一个新名字。"),
        actions: [
          .init(label: Text(verbatim: "取消"), role: .cancel, action: {}),
          .init(label: Text(verbatim: "保存"), action: {}),
        ]
      ) {
        Text(verbatim: "输入区域")
      }
  }
}

private struct ToastSample: View {
  var body: some View {
    ZStack(alignment: .bottom) {
      Text(verbatim: "背景内容")
        .frame(maxWidth: .infinity, minHeight: 420)
      WDToastCard(
        variant: .success,
        message: Text(verbatim: "任务已保存"),
        action: .init(label: Text(verbatim: "撤销"), action: {}),
        onAction: {}
      )
      .padding(.horizontal, WDSpacing.s9)
      .padding(.bottom, WDSpacing.s5)
    }
  }
}

private struct BottomSheetSample: View {
  var body: some View {
    WDBottomSheetPanel(
      title: Text(verbatim: "选择成员"),
      closeButtonAccessibilityLabel: Text(verbatim: "关闭成员选择"),
      onClose: {},
      content: VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDTextField(text: .constant("整理储物间"), label: Text(verbatim: "任务名称"))
        Text(verbatim: "面板内容")
          .wdFont(WDType.body)
        Text(verbatim: "第二行说明")
          .wdFont(WDType.footnote)
      }
      .padding(.vertical, WDSpacing.s5),
      footer: WDButton(verbatim: "完成") {}
    )
  }
}

private struct ActionSheetSample: View {
  var body: some View {
    WDActionSheetPanel(
      title: Text(verbatim: "任务操作"),
      message: Text(verbatim: "选择要执行的操作。"),
      items: [
        .init(id: "share", label: Text(verbatim: "分享"), icon: .share),
        .init(id: "delete", label: Text(verbatim: "删除"), role: .destructive, icon: .delete),
        .init(id: "cancel", label: Text(verbatim: "取消"), role: .cancel),
      ],
      onSelect: { _ in },
      onCancel: {}
    )
  }
}
