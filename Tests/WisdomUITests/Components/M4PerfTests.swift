import Foundation
import SwiftUI
import Testing

@testable import WisdomUI

/// M4 九件的渲染耗时（只报不拦；口径 = ImageRenderer 一次 PNG 的墙钟时间）。
@MainActor
@Suite("M4 性能（只报）")
struct M4PerfTests {
  private static let canvas = CGSize(width: 360, height: 720)

  @Test("M4 九件渲染耗时")
  func renderTimes() {
    let samples: [(String, AnyView)] = [
      ("WDProgressBar", AnyView(PerfProgressBar())),
      ("WDProgressRing", AnyView(PerfProgressRing())),
      ("WDEmptyState", AnyView(PerfEmptyState())),
      ("WDSkeleton", AnyView(PerfSkeleton())),
      ("WDBanner", AnyView(PerfBanner())),
      ("WDAlert", AnyView(PerfAlert())),
      ("WDToast", AnyView(PerfToast())),
      ("WDBottomSheet", AnyView(PerfBottomSheet())),
      ("WDActionSheet", AnyView(PerfActionSheet())),
    ]
    for (name, view) in samples {
      var durations: [Double] = []
      for index in 0..<15 {
        let start = Date()
        let renderer = ImageRenderer(
          content: view.frame(width: Self.canvas.width, alignment: .topLeading))
        renderer.scale = 1
        _ = renderer.uiImage
        let elapsed = Date().timeIntervalSince(start) * 1000
        if index >= 3 { durations.append(elapsed) }
      }
      let avg = durations.reduce(0, +) / Double(durations.count)
      let minValue = durations.min() ?? 0
      print(
        String(format: "M4PERF %@ avg=%.2f min=%.2f n=%d", name, avg, minValue, durations.count))
    }
  }
}

private struct PerfProgressBar: View {
  var body: some View {
    VStack(spacing: WDSpacing.s6) {
      WDProgressBar(value: 0.45, label: Text(verbatim: "上传进度"), valueText: Text(verbatim: "45%"))
      WDProgressBar(label: Text(verbatim: "加载中"))
      WDProgressBar(value: 1, label: Text(verbatim: "完成"), valueText: Text(verbatim: "100%"))
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfProgressRing: View {
  var body: some View {
    HStack {
      WDProgressRing(value: 0.6, label: Text(verbatim: "本周"), valueText: Text(verbatim: "3/5"))
      WDProgressRing(value: 0.45, size: .compact, label: Text(verbatim: "紧凑"))
      WDProgressRing(value: 1, label: Text(verbatim: "完成"))
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfEmptyState: View {
  var body: some View {
    WDEmptyState(
      icon: .task,
      title: Text(verbatim: "还没有任务"),
      message: Text(verbatim: "新建第一个任务。"),
      action: .init(label: Text(verbatim: "新建"), action: {})
    )
    .padding(WDSpacing.s5)
  }
}

private struct PerfSkeleton: View {
  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s6) {
      WDSkeleton(variant: .text, lineCount: 3)
      WDSkeleton(variant: .list)
      WDSkeleton(variant: .card)
    }
    .padding(WDSpacing.s5)
    .wdEffectsBudget(.minimal)
  }
}

private struct PerfBanner: View {
  var body: some View {
    VStack(spacing: WDSpacing.s4) {
      WDBanner(isVisible: .constant(true), variant: .info, message: Text(verbatim: "已同步"))
      WDBanner(isVisible: .constant(true), variant: .warning, message: Text(verbatim: "试用期还剩 3 天"))
      WDBanner(isVisible: .constant(true), variant: .danger, message: Text(verbatim: "网络不可用"))
    }
    .padding(WDSpacing.s5)
  }
}

private struct PerfAlert: View {
  var body: some View {
    Text(verbatim: "背景")
      .frame(maxWidth: .infinity, minHeight: 360)
      .wdAlert(
        isPresented: .constant(true),
        title: Text(verbatim: "删除？"),
        message: Text(verbatim: "删除后无法恢复。"),
        actions: [
          .init(label: Text(verbatim: "取消"), role: .cancel, action: {}),
          .init(label: Text(verbatim: "删除"), role: .destructive, action: {}),
        ]
      )
  }
}

private struct PerfToast: View {
  var body: some View {
    Text(verbatim: "背景")
      .frame(maxWidth: .infinity, minHeight: 420)
      .wdToast(
        isPresented: .constant(true),
        variant: .success,
        message: Text(verbatim: "任务已保存"),
        action: .init(label: Text(verbatim: "撤销"), action: {})
      )
  }
}

private struct PerfBottomSheet: View {
  var body: some View {
    WDBottomSheetPanel(
      title: Text(verbatim: "选择成员"),
      closeButtonAccessibilityLabel: Text(verbatim: "关闭"),
      onClose: {},
      content: Text(verbatim: "面板内容").wdFont(WDType.body).padding(.vertical, WDSpacing.s5),
      footer: WDButton(verbatim: "完成") {}
    )
  }
}

private struct PerfActionSheet: View {
  var body: some View {
    WDActionSheetPanel(
      title: Text(verbatim: "任务操作"),
      message: Text(verbatim: "选择要执行的操作。"),
      items: [
        .init(id: "share", label: Text(verbatim: "分享")),
        .init(id: "delete", label: Text(verbatim: "删除"), role: .destructive),
        .init(id: "cancel", label: Text(verbatim: "取消"), role: .cancel),
      ],
      onSelect: { _ in },
      onCancel: {}
    )
  }
}
