import SwiftUI

/// 复选框（SPEC §2.10-#06；M2）。
///
/// 设计口径（设计 06）：方框 **26**、圆角 **9**（`radius.checkbox`）；未选 = 1.5pt
/// `border.hairline-strong` 描边 + `fill.field`；已选 = `gradient.mid` + 白色描边勾；
/// 标签 `subheadline`（15）；热区 ≥ 44；切换轻触觉 ×1。
///
/// 冻结签名只有 `isChecked` + `label`（无紧凑档/无标签/半选参数）⇒ 只做标准两态；
/// 紧凑档、半选三态、光晕与按下缩放不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3。
public struct WDCheckbox: View {
  @Binding private var isChecked: Bool
  private let label: Text

  @Environment(\.isEnabled) private var isEnabled

  /// 构造（受控值 `isChecked`；C-15 的唯一改名）。
  public init(isChecked: Binding<Bool>, label: Text) {
    self._isChecked = isChecked
    self.label = label
  }

  /// 标签 + 方框；整行可点（含标签）。
  public var body: some View {
    Toggle(isOn: $isChecked) {
      label
        .wdFont(WDType.subheadline)
        .wdLineBox(WDType.subheadline)
    }
    .toggleStyle(WDCheckboxToggleStyle())
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 标准档几何（设计 06 §2–§3；令牌无这些值；内部暴露给单测）。
  enum Metrics {
    /// 方框边长。
    static let box: CGFloat = 26  // wd-structure-check:disable R7 — 设计值
    /// 方框圆角（= `WDRadius.checkbox` 9）。
    static let corner: CGFloat = 9  // wd-structure-check:disable R7 — 设计值
    /// 未选态描边宽度。
    static let stroke: CGFloat = 1.5  // wd-structure-check:disable R7 — 设计值
    /// 勾的描边宽度。
    static let checkStroke: CGFloat = 2.2  // wd-structure-check:disable R7 — 设计值
    /// 勾的绘制区宽。
    static let checkWidth: CGFloat = 14  // wd-structure-check:disable R7 — 设计值
    /// 勾的绘制区高。
    static let checkHeight: CGFloat = 10  // wd-structure-check:disable R7 — 设计值
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母
}

/// 自定义复选框外观：真 `Toggle` 的样式（状态由系统朗读，库内零"选中/未选中"文案）。
private struct WDCheckboxToggleStyle: ToggleStyle {
  private typealias Metrics = WDCheckbox.Metrics

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: WDSpacing.s3) {
      box(configuration)
      configuration.label
        .foregroundStyle(colors.textPrimary)
      Spacer(minLength: 0)
    }
    .frame(minHeight: WDSize.touchTargetMin)
    .contentShape(Rectangle())
    .onTapGesture {
      guard isEnabled else { return }
      configuration.isOn.toggle()
      WDHaptics.shared.play(.toggle, budget: budget)
    }
    .accessibilityElement(children: .combine)
  }

  private func box(_ configuration: Configuration) -> some View {
    WDCheckboxBox(isChecked: configuration.isOn)
  }
}

/// 复选框的方框（内部复用：`WDListRow` 的 `.checkbox` 前导槽直接用它，保持同一套视觉）。
struct WDCheckboxBox: View {
  let isChecked: Bool

  @Environment(\.wdColors) private var colors

  private typealias Metrics = WDCheckbox.Metrics

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
    ZStack {
      if isChecked {
        shape.fill(WDGradient.mid.linearGradient)
        WDCheckmarkShape()
          .trim(from: 0, to: 1)
          .stroke(
            colors.textOnDark,
            style: StrokeStyle(
              lineWidth: Metrics.checkStroke, lineCap: .round, lineJoin: .round)
          )
          .frame(width: Metrics.checkWidth, height: Metrics.checkHeight)
          .animation(.easeOut(duration: WDMotion.Duration.base), value: isChecked)
      } else {
        shape.fill(colors.fillField)
        shape.stroke(colors.borderHairlineStrong, lineWidth: Metrics.stroke)
      }
    }
    .frame(width: Metrics.box, height: Metrics.box)
  }
}

/// 勾（描边路径；设计 06：勾是画出来的，不是图标）。
private struct WDCheckmarkShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    return path
  }
}
