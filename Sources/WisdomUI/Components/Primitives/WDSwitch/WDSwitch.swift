import SwiftUI

/// 开关尺寸档（设计 05 §3：标准 51×31 / 紧凑 40×24）。
public enum WDSwitchSize: String, CaseIterable, Sendable, Equatable {
  case standard
  case compact
}

/// 开关（SPEC §2.10-#05；M2；B5 扩紧凑档/描述位）。
///
/// 设计口径（设计 05 §3–§5）：
/// - 标准轨道 51×31、滑块 27、行程 20；紧凑 40×24、滑块 20、行程 16；
/// - 关 = border.hairline-strong 描边 + 白滑块；开 = gradient.mid；切换轻触觉 ×1；
/// - 角色 = switch（由真 Toggle 提供），状态由系统朗读（库内零"开/关"文案）；
/// - 描述位在标签下方一行 footnote / text.secondary。
///
/// 拖动（设计 05 §8/§9）：轨道可水平拖动，滑块实时跟随并按中心是否过半实时改写
/// `isOn`；松手吸附到最近一端且只触发一次轻触觉。轨道变色 260ms 线性；滑块位移
/// 300ms `cubic-bezier(.2, 1.5, .45, 1)`；拖动中滑块放大 1.06。两项时长尚未进令牌，
/// 在本文件按设计值冻结（见 `WDSwitchMotion`）。
public struct WDSwitch: View {
  @Binding private var isOn: Bool
  private let label: Text
  private let description: Text?
  private let size: WDSwitchSize

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled

  /// 构造（既有；标准档、无描述）。
  public init(isOn: Binding<Bool>, label: Text) {
    self._isOn = isOn
    self.label = label
    self.description = nil
    self.size = .standard
  }

  /// 构造（B5 增量；紧凑/标准 + 可选描述）。
  public init(
    isOn: Binding<Bool>, label: Text, description: Text?, size: WDSwitchSize
  ) {
    self._isOn = isOn
    self.label = label
    self.description = description
    self.size = size
  }

  /// 标签（+ 描述）+ 轨道；整行可点（含标签区域）。
  public var body: some View {
    Toggle(isOn: $isOn) {
      VStack(alignment: .leading, spacing: WDSpacing.s1) {
        label
          .wdFont(WDType.body)
          .wdLineBox(WDType.body)
        if let description {
          description
            .wdFont(WDType.footnote)
            .wdLineBox(WDType.footnote)
            .foregroundStyle(colors.textSecondary)
        }
      }
    }
    .toggleStyle(WDSwitchToggleStyle(size: size))
    .opacity(isEnabled ? 1 : disabledOpacity)
  }

  /// 几何（设计 05 §3；令牌无这些值；内部暴露给单测做自洽断言）。
  enum Metrics {
    /// 标准档轨道宽。
    static let trackWidth: CGFloat = 51  // wd-structure-check:disable R7 — 设计值
    /// 标准档轨道高。
    static let trackHeight: CGFloat = 31  // wd-structure-check:disable R7 — 设计值
    /// 滑块直径（轨道高 − 4）。
    static let knobDiameter: CGFloat = 27  // wd-structure-check:disable R7 — 设计值
    /// 滑块行程（轨道宽 − 滑块 − 两侧内边距）。
    static let knobTravel: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
    /// 滑块与轨道的上下左右内边距（设计「各留 2」）。
    static let knobInset: CGFloat = 2  // wd-structure-check:disable R7 — 设计值
    /// 拖动中滑块放大到 1.06（设计 05 §5）。
    static let pressedKnobScale: CGFloat = 1.06  // wd-structure-check:disable R7 — 设计 05 §5

    /// 紧凑档轨道宽 40。
    static let compactTrackWidth: CGFloat = 40  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档轨道高 24。
    static let compactTrackHeight: CGFloat = 24  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档滑块 20。
    static let compactKnobDiameter: CGFloat = 20  // wd-structure-check:disable R7 — 设计值
    /// 紧凑档行程 16。
    static let compactKnobTravel: CGFloat = 16  // wd-structure-check:disable R7 — 设计值

    /// 档位几何。
    struct SizeMetrics {
      let trackWidth: CGFloat
      let trackHeight: CGFloat
      let knobDiameter: CGFloat
      let knobTravel: CGFloat
      let knobInset: CGFloat
    }

    /// 取档位几何。
    static func metrics(for size: WDSwitchSize) -> SizeMetrics {
      switch size {
      case .standard:
        return SizeMetrics(
          trackWidth: trackWidth, trackHeight: trackHeight, knobDiameter: knobDiameter,
          knobTravel: knobTravel, knobInset: knobInset)
      case .compact:
        return SizeMetrics(
          trackWidth: compactTrackWidth, trackHeight: compactTrackHeight,
          knobDiameter: compactKnobDiameter, knobTravel: compactKnobTravel, knobInset: knobInset)
      }
    }
  }

  /// 禁用态整体不透明度（state.disabled.alpha = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母
}

/// 拖动换算与吸附（设计 05 §8：实时跟随、松手按滑块中心是否过半吸附）。
///
/// 纯逻辑、无 SwiftUI 状态，便于单测覆盖左/右/中点/两端。
enum WDSwitchDrag {
  /// 是否由开关接管本次拖动：横向分量不弱于纵向。
  ///
  /// 手势优先级：开关只把拖动挂在轨道上，并以 `simultaneousGesture` 与父级
  /// `ScrollView` 共存；纵向滚动继续交给父级，本方法过滤掉纵向位移，既不写
  /// `isOn` 也不触发触觉。点击与拖动由 `ExclusiveGesture` 互斥，避免一次操作
  /// 既切换又吸附。
  static func shouldBegin(translation: CGSize) -> Bool {
    abs(translation.width) >= abs(translation.height)
  }

  /// 拖动中的滑块偏移：起点偏移 + 水平位移，夹在 0…行程内。
  static func knobOffset(startOffset: CGFloat, translation: CGFloat, travel: CGFloat) -> CGFloat {
    guard travel > 0 else { return 0 }
    return min(max(startOffset + translation, 0), travel)
  }

  /// 滑块中心（轨道坐标）。
  static func knobCenterX(offset: CGFloat, metrics: WDSwitch.Metrics.SizeMetrics) -> CGFloat {
    metrics.knobInset + metrics.knobDiameter / 2 + offset  // wd-structure-check:disable R7 — 半径
  }

  /// 中心严格过半 = 开；恰在中点归关（松手吸附最近端）。
  static func isOn(knobCenterX: CGFloat, trackWidth: CGFloat) -> Bool {
    knobCenterX > trackWidth / 2  // wd-structure-check:disable R7 — 轨道中点
  }
}

/// WDSwitch 专用动效（设计 05 §9；两项时长尚未入令牌，按设计值本地冻结）。
private enum WDSwitchMotion {
  /// 轨道变色：260ms 线性。
  static let track: Animation = .linear(duration: trackDuration)
  /// 滑块位移：300ms cubic-bezier(.2, 1.5, .45, 1)。
  static let knob: Animation = .timingCurve(
    knobControl1X, knobControl1Y, knobControl2X, knobControl2Y, duration: knobDuration)

  /// 轨道 260ms（设计 05 §9）。
  private static let trackDuration: TimeInterval = 0.26  // wd-structure-check:disable R7 — 设计 05 §9
  /// 滑块 300ms（设计 05 §9）。
  private static let knobDuration: TimeInterval = 0.30  // wd-structure-check:disable R7 — 设计 05 §9
  /// 曲线控制点 1 x（设计 05 §9）。
  private static let knobControl1X: Double = 0.2  // wd-structure-check:disable R7 — 设计 05 §9
  /// 曲线控制点 1 y（设计 05 §9）。
  private static let knobControl1Y: Double = 1.5  // wd-structure-check:disable R7 — 设计 05 §9
  /// 曲线控制点 2 x（设计 05 §9）。
  private static let knobControl2X: Double = 0.45  // wd-structure-check:disable R7 — 设计 05 §9
  /// 曲线控制点 2 y（设计 05 §9）。
  private static let knobControl2Y: Double = 1
}

/// 自定义开关外观：真 Toggle 的样式（角色/状态由 Toggle 提供，库内不写"开/关"文案）。
private struct WDSwitchToggleStyle: ToggleStyle {
  let size: WDSwitchSize

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled

  private var metrics: WDSwitch.Metrics.SizeMetrics {
    WDSwitch.Metrics.metrics(for: size)
  }

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 0) {
      HStack(spacing: WDSpacing.s4) {
        configuration.label
          .foregroundStyle(colors.textPrimary)
        Spacer(minLength: 0)
      }
      .padding(.trailing, WDSpacing.s4)
      .frame(maxWidth: .infinity, minHeight: WDSize.touchTargetMin, alignment: .leading)
      .contentShape(Rectangle())
      .onTapGesture {
        guard isEnabled else { return }
        configuration.isOn.toggle()
        WDHaptics.shared.play(.toggle, budget: budget)
      }
      WDSwitchTrack(isOn: configuration.$isOn, metrics: metrics)
    }
    .frame(minHeight: WDSize.touchTargetMin)
    .accessibilityElement(children: .combine)
  }
}

/// 轨道 + 滑块：拖动换算、松手吸附与动效。
private struct WDSwitchTrack: View {
  /// 受控开态（拖动中实时写入，松手写入吸附结果）。
  @Binding var isOn: Bool
  /// 当前档位几何。
  let metrics: WDSwitch.Metrics.SizeMetrics

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.isEnabled) private var isEnabled

  /// 拖动起点偏移（开始拖动时冻结，避免实时 `isOn` 反向污染换算）。
  @State private var startOffset: CGFloat = 0
  /// 已接管的水平位移；nil = 未开始或纵向滚动未接管。
  @State private var translation: CGFloat?

  /// 是否正在水平拖动（控制滑块 1.06 放大）。
  private var isDragging: Bool { translation != nil }

  /// 当前滑块偏移：拖动中跟随手指，否则取开态端点。
  private var knobOffset: CGFloat {
    guard let translation else {
      return isOn ? metrics.knobTravel : 0
    }
    return WDSwitchDrag.knobOffset(
      startOffset: startOffset, translation: translation, travel: metrics.knobTravel)
  }

  var body: some View {
    let shape = Capsule()
    ZStack(alignment: .leading) {
      shape
        .fill(WDGradient.mid.linearGradient)
        .opacity(isOn ? 1 : 0)
        .animation(WDSwitchMotion.track, value: isOn)
      shape
        .stroke(colors.borderHairlineStrong, lineWidth: 1)
        .opacity(isOn ? 0 : 1)
        .animation(WDSwitchMotion.track, value: isOn)
      Circle()
        .fill(colors.textOnDark)
        .frame(width: metrics.knobDiameter, height: metrics.knobDiameter)
        .padding(.leading, metrics.knobInset)
        .scaleEffect(isDragging ? WDSwitch.Metrics.pressedKnobScale : 1)
        .offset(x: knobOffset)
        .animation(isDragging ? nil : WDSwitchMotion.knob, value: knobOffset)
        .animation(.easeOut(duration: WDMotion.Duration.instant), value: isDragging)
    }
    .frame(width: metrics.trackWidth, height: metrics.trackHeight)
    .contentShape(Rectangle())
    .simultaneousGesture(trackGesture)
  }

  /// 点击与拖动互斥：轻点切换一次；拖动只在松手时触发一次触觉。
  private var trackGesture: some Gesture {
    dragGesture.exclusively(before: TapGesture().onEnded { _ in toggle() })
  }

  /// 水平拖动；`minimumDistance: 1` 让轻点仍归 TapGesture。
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 1, coordinateSpace: .local)
      .onChanged(handleDragChanged)
      .onEnded(handleDragEnded)
  }

  /// 拖动中：实时更新滑块与 `isOn`（不触发触觉）。
  private func handleDragChanged(_ value: DragGesture.Value) {
    guard isEnabled else { return }
    guard translation != nil || WDSwitchDrag.shouldBegin(translation: value.translation) else {
      return
    }
    if translation == nil {
      startOffset = isOn ? metrics.knobTravel : 0
    }
    translation = value.translation.width
    let offset = WDSwitchDrag.knobOffset(
      startOffset: startOffset, translation: value.translation.width, travel: metrics.knobTravel)
    let center = WDSwitchDrag.knobCenterX(offset: offset, metrics: metrics)
    let nextOn = WDSwitchDrag.isOn(knobCenterX: center, trackWidth: metrics.trackWidth)
    if nextOn != isOn {
      isOn = nextOn
    }
  }

  /// 松手：按滑块中心是否过半吸附最近端，触觉只在此处触发一次。
  private func handleDragEnded(_ value: DragGesture.Value) {
    guard isEnabled, translation != nil else {
      translation = nil
      return
    }
    translation = nil
    let offset = WDSwitchDrag.knobOffset(
      startOffset: startOffset, translation: value.translation.width, travel: metrics.knobTravel)
    let center = WDSwitchDrag.knobCenterX(offset: offset, metrics: metrics)
    isOn = WDSwitchDrag.isOn(knobCenterX: center, trackWidth: metrics.trackWidth)
    WDHaptics.shared.play(.toggle, budget: budget)
  }

  /// 点击切换（与拖动互斥）。
  private func toggle() {
    guard isEnabled else { return }
    isOn.toggle()
    WDHaptics.shared.play(.toggle, budget: budget)
  }
}
