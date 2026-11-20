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
/// （L-B 零文案），需要时在外层加 `.accessibilityValue(_:)`。无标签变体（设计 06 §4）走
/// `accessibilityLabel` 构造：仅渲染方框、读屏文案由调用方提供，只用于表头全选；光晕随方框
/// 统一生效，按下缩放仍不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3。
public struct WDCheckbox: View {
  @Binding private var isChecked: Bool
  /// 可见标签；nil = 无标签变体（只渲染方框）。
  private let label: Text?
  /// 无标签变体的读屏文案（有可见标签时为 nil，由标签自身朗读）。
  private let accessibilityLabel: Text?
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
    self.accessibilityLabel = nil
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
    self.accessibilityLabel = nil
    self.size = size
    self.isIndeterminate = isIndeterminate
  }

  /// 构造（无标签：仅方框；`accessibilityLabel` 必填）。
  ///
  /// 设计 06 §4 的「无标签」变体，只用于表头全选：行内不显示文字，读屏文案完全由调用方提供
  /// （库内零文案）。
  public init(
    isChecked: Binding<Bool>,
    accessibilityLabel: Text,
    size: WDCheckboxSize = .standard,
    isIndeterminate: Bool = false
  ) {
    self._isChecked = isChecked
    self.label = nil
    self.accessibilityLabel = accessibilityLabel
    self.size = size
    self.isIndeterminate = isIndeterminate
  }

  /// 标签（可选）+ 方框；整行可点。无标签时只渲染方框，读屏读 `accessibilityLabel`。
  public var body: some View {
    Toggle(isOn: $isChecked) {
      if let label {
        label
          .wdFont(textStyle)
          .wdLineBox(textStyle)
      }
    }
    .toggleStyle(
      WDCheckboxToggleStyle(
        size: size,
        isIndeterminate: isIndeterminate,
        showsLabel: label != nil,
        accessibilityLabel: accessibilityLabel)
    )
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 点击后的受控值：半选 → 全选（不做三态循环），其余取反（设计 06 §8）。
  static func toggledValue(isOn: Bool, isIndeterminate: Bool) -> Bool {
    isIndeterminate ? true : !isOn
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
    /// 按下缩放（设计 06 §5：`motion.component.checkbox-press` = 0.90）。
    static let pressedScale: CGFloat = 0.90  // wd-structure-check:disable R7 — 设计 06 §5
    /// 半选横杠（设计 06 §5：12 × 2.4）。
    static let barWidth: CGFloat = 12  // wd-structure-check:disable R7 — 设计值
    static let barHeight: CGFloat = 2.4  // wd-structure-check:disable R7 — 设计值
  }

  /// 选中光晕（设计 06 §5/§9）：仅"未选 → 已选"播放一次；纯逻辑部分可单测。
  enum Glow {
    /// 起始不透明度（设计 06 §5：`brand` 42%）。
    static let startOpacity: Double = 0.42  // wd-structure-check:disable R7 — 设计值 42%
    /// 结束不透明度（外扩到透明）。
    static let endOpacity: Double = 0
    /// 起始缩放（与方框同大）。
    static let startScale: CGFloat = 1
    /// 扩散时长（设计 06 §9：`motion.component.checkbox-glow` 400ms）。
    static let duration: Double = 0.4  // wd-structure-check:disable R7 — 设计值 400ms
    /// 扩散终点 = 44pt 热区（只做视觉外扩，不参与布局）。
    static func endScale(boxSide: CGFloat) -> CGFloat {
      WDSize.touchTargetMin / boxSide
    }
    /// 触发条件：仅启用态下由未选变已选；半选（已呈选中底）与 Reduce Motion 不播。
    static func shouldPlay(
      isChecked: Bool,
      wasChecked: Bool,
      isIndeterminate: Bool,
      isEnabled: Bool,
      reduceMotion: Bool
    ) -> Bool {
      isEnabled && !reduceMotion && !isIndeterminate && isChecked && !wasChecked
    }
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
  /// 是否有可见标签（决定是否渲染文字、是否留方框与文字的间距）。
  let showsLabel: Bool
  /// 无标签变体的读屏文案；有可见标签时为 nil。
  let accessibilityLabel: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled
  /// 按下中（设计 06 §5 的 0.90 缩放）。
  @State private var isPressing = false

  /// 按下态（设计 06 §5：缩放 **0.90**，`motion.duration.instant`）。
  ///
  /// 用 `ToggleStyle` 的 `configuration.isPressed` 不可得（`Toggle` 的 configuration 没有该值），
  /// 因此用「按下跟踪」手势包一层：`onLongPressGesture(minimumDuration: 0)` 的
  /// `onPressingChanged` 是系统提供的按下跟踪，**不是**自造 `DragGesture`（SPEC §3.4 禁的是后者）。
  /// 它不改命中判定 —— 点按仍由原地 `onTapGesture` 处理。
  func makeBody(configuration: Configuration) -> some View {
    let row =
      HStack(spacing: showsLabel ? WDSpacing.s3 : 0) {
        box(configuration)
        if showsLabel {
          configuration.label
            .foregroundStyle(colors.textPrimary)
        }
        Spacer(minLength: 0)
      }
      // 无标签时行内只有方框，仍保证 44×44 热区（设计 06 §3）。
      .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
      .contentShape(Rectangle())
      .scaleEffect(isPressing ? WDCheckbox.Metrics.pressedScale : 1)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: isPressing)
      .onTapGesture {
        guard isEnabled else { return }
        configuration.isOn = WDCheckbox.toggledValue(
          isOn: configuration.isOn, isIndeterminate: isIndeterminate)
        WDHaptics.shared.play(.toggle, budget: budget)
      }
      .onLongPressGesture(minimumDuration: .infinity) {
        // 只为拿到按下态；长按不做任何事（设计 06 §8 没有长按语义）。
      } onPressingChanged: { pressing in
        isPressing = pressing && isEnabled
      }
      .accessibilityElement(children: .combine)
    return labeled(row)
  }

  /// 无标签时把调用方给的读屏文案挂到整行（状态/半选语义仍由 `Toggle` 提供）。
  @ViewBuilder
  private func labeled(_ row: some View) -> some View {
    if let accessibilityLabel {
      row.accessibilityLabel(accessibilityLabel)
    } else {
      row
    }
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
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  /// 光晕触发计数：只在"未选 → 已选"时自增，取消选中不触发。
  @State private var glowTrigger = 0

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
      // 光晕在最底层：不遮挡勾/横杠，也不改变布局与热区。
      glow
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
    .onChange(of: isChecked) { wasChecked, isChecked in
      guard
        WDCheckbox.Glow.shouldPlay(
          isChecked: isChecked,
          wasChecked: wasChecked,
          isIndeterminate: isIndeterminate,
          isEnabled: isEnabled,
          reduceMotion: reduceMotion)
      else { return }
      glowTrigger += 1
    }
  }

  /// 选中光晕：`brand` 42% → 透明、scale 1 → 44pt 热区，400ms 只播一次。
  ///
  /// 用 `keyframeAnimator` 的 trigger 计数驱动，因此取消选中不会重启关键帧；静止态
  /// （initialValue）透明，不影响首帧/快照。`scaleEffect` 不参与布局，命中测试交给方框。
  private var glow: some View {
    Circle()
      .fill(
        RadialGradient(
          colors: [colors.textBrand, colors.textBrand.opacity(WDCheckbox.Glow.endOpacity)],
          center: .center,
          startRadius: 0,
          endRadius: side / 2  // wd-structure-check:disable R7 — 半径 = 方框边长的一半
        )
      )
      .frame(width: side, height: side)
      .keyframeAnimator(initialValue: GlowFrame(), trigger: glowTrigger) { content, frame in
        content
          .scaleEffect(frame.scale)
          .opacity(frame.opacity)
      } keyframes: { _ in
        KeyframeTrack(\.scale) {
          MoveKeyframe(WDCheckbox.Glow.startScale)
          LinearKeyframe(
            WDCheckbox.Glow.endScale(boxSide: side), duration: WDCheckbox.Glow.duration)
        }
        KeyframeTrack(\.opacity) {
          MoveKeyframe(WDCheckbox.Glow.startOpacity)
          LinearKeyframe(WDCheckbox.Glow.endOpacity, duration: WDCheckbox.Glow.duration)
        }
      }
      .allowsHitTesting(false)
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

/// 光晕的关键帧值：静止态透明（opacity 0），触发后才出现 42% → 透明的扩散。
private struct GlowFrame {
  var scale: CGFloat = WDCheckbox.Glow.startScale
  var opacity: Double = WDCheckbox.Glow.endOpacity
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
