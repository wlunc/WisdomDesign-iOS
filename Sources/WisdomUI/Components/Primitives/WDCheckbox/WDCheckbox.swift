import SwiftUI

/// 复选框尺寸档（设计 06 §3：标准 26 / 圆角 9 / `subheadline`；紧凑 22 / 圆角 7 / `footnote`）。
public enum WDCheckboxSize: String, CaseIterable, Sendable, Equatable {
  case standard
  case compact
}

/// 复选框（SPEC §2.10-#06；M2）。
///
/// 设计口径（设计 06）：
/// - 标准档方框 **26**、圆角 **9**（`radius.checkbox`）；紧凑档方框 **22**、圆角 **7**；
/// - 未选 = 1.5pt `border.hairline-strong` 描边 + `fill.field`；
/// - 已选 = `gradient.mid` + 白色描边勾（**2.2pt、rotate(42°)**，与画廊 06 的 5×10 L 同形，不是图标）；
/// - 半选 = 同已选底 + **12×2.4** 白色横杠（设计 06 §5）；点半选 → 变全选（不做三态循环）；
/// - 标准档标签 `subheadline`（15）、紧凑档标签 `footnote`（13）；热区 ≥ 44；切换轻触觉 ×1。
///
/// `isIndeterminate` 是**显示态**（表头全选等由调用方维护）；半选的朗读文案属调用方
/// （L-B 零文案），需要时在外层加 `.accessibilityValue(_:)`。无标签表头/光晕/按下缩放
/// 仍不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3。
public struct WDCheckbox: View {
  @Binding private var isChecked: Bool
  private let label: Text
  private let size: WDCheckboxSize
  private let isIndeterminate: Bool

  @Environment(\.isEnabled) private var isEnabled

  /// 构造（受控值 `isChecked`；C-15 的唯一改名）。`isIndeterminate` = 半选显示态；标准档。
  public init(
    isChecked: Binding<Bool>,
    label: Text,
    isIndeterminate: Bool = false
  ) {
    self._isChecked = isChecked
    self.label = label
    self.size = .standard
    self.isIndeterminate = isIndeterminate
  }

  /// 构造（显式档位：标准/紧凑）。`size` 无默认值，避免与既有 init 的调用歧义。
  public init(
    isChecked: Binding<Bool>,
    label: Text,
    size: WDCheckboxSize,
    isIndeterminate: Bool = false
  ) {
    self._isChecked = isChecked
    self.label = label
    self.size = size
    self.isIndeterminate = isIndeterminate
  }

  /// 标签 + 方框；整行可点（含标签）。
  public var body: some View {
    Toggle(isOn: $isChecked) {
      label
        .wdFont(textStyle)
        .wdLineBox(textStyle)
    }
    .toggleStyle(WDCheckboxToggleStyle(size: size, isIndeterminate: isIndeterminate))
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 标签字阶：标准 `subheadline`、紧凑 `footnote`（设计 06 §3）。
  private var textStyle: WDTextStyle {
    size == .standard ? WDType.subheadline : WDType.footnote
  }

  /// 标准档几何（设计 06 §2–§3；令牌无这些值；内部暴露给单测）。
  enum Metrics {
    /// 方框边长。
    static let box: CGFloat = 26  // wd-structure-check:disable R7 — 设计值
    /// 方框圆角（= `WDRadius.checkbox` 9）。
    static let corner: CGFloat = 9  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档方框边长（设计 06 §3：22）。
    static let compactBox: CGFloat = 22  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档方框圆角（设计 06 §3：7）。
    static let compactCorner: CGFloat = 7  // wd-structure-check:disable R7 — 设计值
    /// 未选态描边宽度。
    static let stroke: CGFloat = 1.5  // wd-structure-check:disable R7 — 设计值
    /// 勾的描边宽度（设计 06 §2：2.2pt）。
    static let checkStroke: CGFloat = 2.2  // wd-structure-check:disable R7 — 设计值
    /// 勾的竖臂长（画廊 06 的 5×10 L）。
    static let tickWidth: CGFloat = 5  // wd-structure-check:disable R7 — 设计 06 画廊
    /// 勾的横臂长。
    static let tickHeight: CGFloat = 10  // wd-structure-check:disable R7 — 设计 06 画廊
    /// 勾的旋转角（设计 06 §2：rotate(42deg)；存弧度）。
    static let tickRotation: CGFloat = 42 * .pi / 180  // wd-structure-check:disable R7 — 设计值
    /// 半选横杠（设计 06 §5：12 × 2.4）。
    static let barWidth: CGFloat = 12  // wd-structure-check:disable R7 — 设计值
    static let barHeight: CGFloat = 2.4  // wd-structure-check:disable R7 — 设计值
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

  let size: WDCheckboxSize
  let isIndeterminate: Bool

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
      // 设计 06 §8：半选点击 → 全选（不做三态循环）。
      if isIndeterminate {
        configuration.isOn = true
      } else {
        configuration.isOn.toggle()
      }
      WDHaptics.shared.play(.toggle, budget: budget)
    }
    .accessibilityElement(children: .combine)
  }

  private func box(_ configuration: Configuration) -> some View {
    WDCheckboxBox(
      isChecked: configuration.isOn, isIndeterminate: isIndeterminate, size: size)
  }
}

/// 复选框的方框（内部复用：`WDListRow` 的 `.checkbox` 前导槽直接用它，保持同一套视觉）。
struct WDCheckboxBox: View {
  let isChecked: Bool
  var isIndeterminate: Bool = false
  var size: WDCheckboxSize = .standard

  @Environment(\.wdColors) private var colors

  private typealias Metrics = WDCheckbox.Metrics

  /// 方框边长：标准 26、紧凑 22。
  private var side: CGFloat {
    size == .standard ? Metrics.box : Metrics.compactBox
  }

  /// 方框圆角：标准 9、紧凑 7。
  private var corner: CGFloat {
    size == .standard ? Metrics.corner : Metrics.compactCorner
  }

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
    ZStack {
      if isIndeterminate || isChecked {
        shape.fill(WDGradient.mid.linearGradient)
        if isIndeterminate {
          bar
        } else {
          check
        }
      } else {
        shape.fill(colors.fillField)
        shape.stroke(colors.borderHairlineStrong, lineWidth: Metrics.stroke)
      }
    }
    .frame(width: side, height: side)
  }

  /// 已选：白色描边勾（5×10 L，rotate 42°，与画廊 06 一致）。
  private var check: some View {
    let iconSide = WDSize.iconSm
    return WDCheckmarkShape()
      .trim(from: 0, to: 1)
      .stroke(
        colors.textOnDark,
        style: StrokeStyle(
          lineWidth: Metrics.checkStroke, lineCap: .butt, lineJoin: .miter)
      )
      .frame(width: iconSide, height: iconSide)
  }

  /// 半选：12 × 2.4 白色横杠（设计 06 §5）。
  private var bar: some View {
    Rectangle()
      .fill(colors.textOnDark)
      .frame(width: Metrics.barWidth, height: Metrics.barHeight)
  }
}

/// 勾（设计 06 §2：白色描边 2.2、rotate(42°)，与画廊 06 的 5×10 L 同形）。
private struct WDCheckmarkShape: Shape {
  func path(in rect: CGRect) -> Path {
    let width = WDCheckbox.Metrics.tickWidth
    let height = WDCheckbox.Metrics.tickHeight
    let half = WDCheckbox.Metrics.checkStroke / 2  // wd-structure-check:disable R7 — 描边半宽
    var path = Path()
    // 右臂 + 下臂（对应画廊 CSS 的 border-right + border-bottom）。
    path.move(to: CGPoint(x: width - half, y: 0))
    path.addLine(to: CGPoint(x: width - half, y: height - half))
    path.addLine(to: CGPoint(x: 0, y: height - half))
    // rotate(42deg) translate(-1,-1)，围绕 5×10 中心，再居中到绘制区。
    let originX = -width / 2 - 1  // wd-structure-check:disable R7 — 居中 + 画廊 1px
    let originY = -height / 2 - 1  // wd-structure-check:disable R7 — 居中 + 画廊 1px
    let transform = CGAffineTransform(translationX: originX, y: originY)
      .concatenating(CGAffineTransform(rotationAngle: WDCheckbox.Metrics.tickRotation))
      .concatenating(CGAffineTransform(translationX: rect.midX, y: rect.midY))
    return path.applying(transform)
  }
}
