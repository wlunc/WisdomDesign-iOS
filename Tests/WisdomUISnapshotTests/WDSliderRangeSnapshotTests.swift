import SwiftUI
import Testing

@testable import WisdomUI

/// `WDSlider` 范围形态（B17 的双手柄）的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// **为什么单开一个用例**（B20 / A-15）：既有 360 张基线里的 `slider-*` 只覆盖单值形态，
/// B17 落地的范围形态（两个手柄 + 区间填充 + 区间文案）从未进过快照 —— 视觉与真实布局
/// 因此一直没有被截图核对过（B18 只补了预览与 demo 场景）。本用例把范围形态纳入六态口径：
///
/// - 命名沿用既有约定 `<component>-<appearance>-<typesize>-<dir>.png`，
///   组件名取 `slider-range`（与 `badge-forms` 同属"组件 + 形态"的多段写法），
///   因此**不与既有 `slider-*` 基线冲突、也不覆盖它们**；
/// - 渲染器与单值同源：范围轨道的手势载体是 `WDSliderRangeControl`（UIViewRepresentable，
///   内部 `UIControl`）⇒ 必须走 `UIHostingController` + `drawHierarchy`（SPEC §1.6 的 E6 显式表），
///   `ImageRenderer` 拿不到 UIControl 层；
/// - 画布与 `M5SnapshotTests` 的单值滑杆一致（360 × 540 @2x = 720 × 1080），便于与
///   `slider-*` 逐像素对照"双手柄 vs 单手柄"的差异（acceptance 的最后一条）。
///
/// 基线成因：8 张新基线是本用例首次入库的**范围形态**记录；既有 360 张基线不因本用例改动。
@MainActor
@Suite("WDSlider 范围快照", .serialized)
struct WDSliderRangeSnapshotTests {
  static let canvas = CGSize(width: 360, height: 540)

  /// 范围样本：三行分别覆盖"离散档 + 区间文案"、"连续档"、"禁用"。
  ///
  /// 两个手柄都刻意放在轨道中段（20% / 80% 与 30% / 70%），让双手柄形态在四种字号/方向
  /// 组合下都能一眼分辨 —— 若被渲染成单值滑杆，只会出现一个手柄，比对时立刻可见。
  private struct Sample: View {
    let values: WDColorValues

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        WDSlider(
          range: .constant(2...8),
          label: Text(verbatim: "预算区间"),
          in: 0...10,
          step: 1,
          showsValueLabel: true,
          rangeText: { Text(verbatim: "\(Int($0.lowerBound))–\(Int($0.upperBound))") },
          lowerAccessibilityLabel: Text(verbatim: "预算下限"),
          upperAccessibilityLabel: Text(verbatim: "预算上限")
        )
        WDSlider(
          range: .constant(0.3...0.7),
          label: Text(verbatim: "静音时段"),
          lowerAccessibilityLabel: Text(verbatim: "开始"),
          upperAccessibilityLabel: Text(verbatim: "结束")
        )
        WDSlider(
          range: .constant(4...6),
          label: Text(verbatim: "禁用"),
          in: 0...10,
          step: 1,
          showsValueLabel: true,
          rangeText: { Text(verbatim: "\(Int($0.lowerBound))–\(Int($0.upperBound))") }
        )
        .disabled(true)
      }
      .padding(WDSpacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(values.bgCanvas)
      .wdTheme(WDTheme(colors: values))
    }
  }

  @Test("WDSlider 范围：8 态基线一致（缺失 = fail）")
  func snapshots() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verifyHierarchy(
        name: "slider-range-\(state.id)",
        view: Sample(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.canvas
      )
    }
  }
}
