import SwiftUI

/// 滑杆（SPEC §2.10-#08；M5）。
///
/// 设计口径（设计 08）：
/// - 轨道高 6、手柄 26（白 + elevation.1 + 1pt hairline）、圆角 radius.full、最小宽 120；
/// - 标签在轨道上方；拖动实时更新、松手才算一次有效变更（onEditingChanged(false)）；
/// - 离散档位松手吸附；松手触发一次轻触觉；读屏走系统 slider 角色。
///
/// 载体说明（docs/M5-SIGNATURE-FREEZE.md Q1 的原决议 + 2026-11-14 自绘落地）：
/// 手势与读屏由 Internal 的 UISlider 载体提供（自造 DragGesture 被 SPEC §3.4 禁止），
/// 轨道 / 填充 / 手柄由本文件的 SwiftUI 覆盖层按设计 08 绘制；公开签名不变。
///
/// 禁用不透明度施加位置（自绘两层），与 B13 之前的整体 opacity 像素等价、语义更正确
///（父级 opacity 会给 `accessibilityRepresentation` 生成的 UIKit 层挂 alpha，读屏焦点落到隐藏元素、
/// 可调整手势会失效）。
public struct WDSlider: View {
  @Binding private var value: Double
  private let label: Text
  private let bounds: ClosedRange<Double>
  private let step: Double?
  private let onEditingChanged: ((Bool) -> Void)?
  /// 显示数值标签（设计 08 §6：标签行右侧放当前值）。默认 false = 不带值，逐像素不变。
  private let showsValueLabel: Bool
  /// 数值文案的 L-B 注入点（nil = 系统 Double 本地化；库内不拼单位/百分号）。
  private let valueText: ((Double) -> Text)?
  /// 松手播报文案（B18；设计 08 §10「只在松手后播报一次」）。nil = 不播报。
  private let announcementText: ((Double) -> Text)?

  // MARK: - B17 范围（双手柄）

  /// 范围受控值（仅范围构造使用；单值构造为常量）。
  @Binding private var range: ClosedRange<Double>
  /// 是否为范围形态（body 分派；单值路径逐像素不变）。
  private let isRange: Bool
  /// 范围值文案的 L-B 注入点（区间格式含分隔符，必须由调用方给；nil = 不显示值）。
  private let rangeText: ((ClosedRange<Double>) -> Text)?
  /// 范围松手播报文案（B18）。nil = 不播报。
  private let rangeAnnouncementText: ((ClosedRange<Double>) -> Text)?
  /// 范围两端的读屏标签（nil ⇒ 复用 `label`）。
  private let lowerAccessibilityLabel: Text?
  private let upperAccessibilityLabel: Text?
  /// 正在拖动的手柄（0 = 下端，1 = 上端；仅范围形态）。
  @State private var activeThumb: Int?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.layoutDirection) private var layoutDirection
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  /// 播报通道（只读；L-B：措辞由调用方给，见 `View.wdAnnouncer(_:)`）。
  @Environment(\.wdAnnouncerText) private var announcer
  /// 读屏焦点落在哪个元素上（B18-1：由 `WDAccessibilityFocusHost` 回写，光环据此显示）。
  @State private var focusTarget: WDFocusRingTarget?
  /// 上次「松手播报」的时刻（节流用；避免连拖刷屏）。
  @State private var lastAnnouncement: ContinuousClock.Instant?

  /// 轨道可用宽度（由 onGeometryChange 量得；首帧为 0）。
  @State private var trackWidth: CGFloat = 0
  /// 手柄中心在热区里的横向位置（由 onGeometryChange 量得；光环据此画在热区外）。
  @State private var thumbCenterX: CGFloat = 0
  /// 是否正在拖拽（手柄放大 1.15）。
  @State private var isEditing = false

  /// 构造：受控值 + 标签 + 范围 + 可选步长。
  public init(
    value: Binding<Double>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil
  ) {
    self.init(
      value: value, label: label, in: bounds, step: step, onEditingChanged: onEditingChanged,
      showsValueLabel: false, valueText: nil, announcementText: nil)
  }

  /// 数值标签 + 焦点光环（设计 08 §2/§5/§6）。
  ///
  /// - `showsValueLabel`：标签行右侧显示当前值；拖动时实时更新、松手吸附；对读屏隐藏
  ///   （值已由滑杆角色的 `value` 承担，避免重复朗读）。
  /// - `valueText`：值文案 —— 格式（百分比 / 单位 / 档位名）**全部由调用方决定**；
  ///   `nil` 时用系统 Double 本地化，库内不拼任何单位或标点。
  public init(
    value: Binding<Double>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil,
    showsValueLabel: Bool = false,
    valueText: ((Double) -> Text)? = nil,
    announcementText: ((Double) -> Text)? = nil
  ) {
    self._value = value
    self._range = .constant(bounds)
    self.label = label
    self.bounds = bounds
    self.step = step
    self.onEditingChanged = onEditingChanged
    self.showsValueLabel = showsValueLabel
    self.valueText = valueText
    self.announcementText = announcementText
    self.isRange = false
    self.rangeText = nil
    self.rangeAnnouncementText = nil
    self.lowerAccessibilityLabel = nil
    self.upperAccessibilityLabel = nil
  }

  /// 范围构造（B17；设计 08 §4「两个手柄，用于区间；两端不允许交叉，最小间隔 = 1 步长」）。
  ///
  /// - `rangeText`：区间文案（含「–」等分隔符）**必须由调用方给**（L-B 零标点）；
  ///   为 nil 时即使 `showsValueLabel` 为 true 也不显示值（库内不拼分隔符）。
  /// - `lowerAccessibilityLabel` / `upperAccessibilityLabel`：两个手柄各自的读屏名；
  ///   nil 时复用 `label`（读屏仍能靠 value 区分两端）。
  public init(
    range: Binding<ClosedRange<Double>>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil,
    showsValueLabel: Bool = false,
    rangeText: ((ClosedRange<Double>) -> Text)? = nil,
    lowerAccessibilityLabel: Text? = nil,
    upperAccessibilityLabel: Text? = nil,
    rangeAnnouncementText: ((ClosedRange<Double>) -> Text)? = nil
  ) {
    self._value = .constant(bounds.lowerBound)
    self._range = range
    self.label = label
    self.bounds = bounds
    self.step = step
    self.onEditingChanged = onEditingChanged
    self.showsValueLabel = showsValueLabel
    self.valueText = nil
    self.announcementText = nil
    self.isRange = true
    self.rangeText = rangeText
    self.rangeAnnouncementText = rangeAnnouncementText
    self.lowerAccessibilityLabel = lowerAccessibilityLabel
    self.upperAccessibilityLabel = upperAccessibilityLabel
  }

  /// 标签行 + 轨道；松手时触发一次轻触觉并回调。
  ///
  /// 默认（`showsValueLabel == false`）仍然只有"标签 + 轨道"两层，和加值之前逐像素一致；
  /// 只有显式要求值标签时才把标签换成"标签 + 值"一行（设计 08 §6）。
  public var body: some View {
    if isRange {
      rangeBody
    } else {
      singleBody
    }
  }

  /// 单值形态（与加范围之前逐像素一致）。
  private var singleBody: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      labelRow
      track
    }
    .frame(minWidth: WDSliderMetrics.minWidth, alignment: .leading)
  }

  /// 范围形态：标签行 + 双手柄轨道。
  private var rangeBody: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      labelRow
      rangeTrack
    }
    .frame(minWidth: WDSliderMetrics.minWidth, alignment: .leading)
  }

  /// 标签本身（设计 08 §6：footnote、次要文字色）。
  private var labelView: some View {
    label
      .wdFont(WDType.footnote)
      .wdLineBox(WDType.footnote)
      .foregroundStyle(colors.textSecondary)
  }

  /// 标签行（设计 08 §6「两者在同一行」）。
  ///
  /// 默认（`showsValueLabel == false`）**不加任何修饰**：渲染的就是 `labelView` 本身，
  /// 与加值之前的子树、测量和像素完全一致；只有要显示值时才是"标签 + Spacer + 值"。
  @ViewBuilder private var labelRow: some View {
    if showsValueLabel, let text = valueLabelText {
      HStack(alignment: .firstTextBaseline, spacing: WDSliderMetrics.valueLabelSpacing) {
        labelView
        Spacer(minLength: 0)
        valueLabel(text)
      }
      .opacity(labelOpacity)
    } else {
      labelView
        .opacity(labelOpacity)
    }
  }

  /// 自绘部分的禁用态不透明度（见 `disabledOpacity` 的说明）。
  private var labelOpacity: Double { isEnabled ? 1 : disabledOpacity }

  /// 当前值（设计 08 §6：等宽数字，拖动时宽度不跳动）。
  ///
  /// 文案来源是 `valueText`（调用方给格式）或系统 Double 本地化；读数由滑杆角色承担，
  /// 这里对读屏隐藏，避免同一个值被读两遍。
  private func valueLabel(_ text: Text) -> some View {
    text
      .wdFont(WDType.footnote)
      .wdLineBox(WDType.footnote)
      .monospacedDigit()
      .foregroundStyle(colors.textSecondary)
      .frame(width: valueLabelWidth, alignment: .trailing)
      .accessibilityHidden(true)
  }

  /// 值文案：调用方给的 `Text` 原样透传；没给时用系统 Double 本地化（不拼单位/百分号）。
  private var valueLabelText: Text? {
    if isRange {
      // 区间分隔符属文案，库内不拼（L-B）⇒ 调用方没给就不显示值。
      return rangeText?(range)
    }
    if let valueText {
      return valueText(value)
    }
    return
      Text(value, format: WDSliderMetrics.valueFormat)  // wd-structure-check:disable R21 — 行盒
  }

  /// 轨道：透明 UISlider 负责手势，SwiftUI 覆盖层负责视觉。
  private var track: some View {
    ZStack(alignment: .leading) {
      WDSliderControl(
        value: value,
        bounds: bounds,
        step: step,
        isEnabled: isEnabled,
        layoutDirection: layoutDirection,
        onValueChange: { newValue in value = newValue },
        onTapValue: handleTap,
        onEditingChanged: handleEditingChanged
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      trackOverlay
    }
    .frame(height: hotAreaHeight)
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { width in
      trackWidth = width
    }
    // 聚焦光环：画在热区之外（热区尺寸不变 ⇒ 默认路径的布局与命中区域都不受影响）。
    // 只有「读屏焦点 + 可用」同时成立时才多这一层；不满足时视图树与加值之前完全相同。
    .overlay(alignment: .topLeading) {
      focusRing
    }
    .accessibilityRepresentation { accessibilitySlider }
  }

  // MARK: - 范围轨道（B17）

  /// 范围轨道：透明 UIControl 负责手势，SwiftUI 覆盖层画「轨道 + 两端之间的填充 + 两个手柄」。
  private var rangeTrack: some View {
    ZStack(alignment: .leading) {
      WDSliderRangeControl(
        lower: range.lowerBound,
        upper: range.upperBound,
        bounds: bounds,
        step: step,
        isEnabled: isEnabled,
        layoutDirection: layoutDirection,
        onRangeChange: { lower, upper in
          range = lower...upper
        },
        onTapThumb: handleRangeTap,
        onEditingChanged: handleRangeEditing,
        onActiveThumbChange: { thumb in
          activeThumb = thumb
        }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      rangeOverlay
    }
    .frame(height: hotAreaHeight)
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { width in
      trackWidth = width
    }
    // 读屏：两个可调整元素（下端 / 上端），语义与单值同源（原生 Slider）。
    .accessibilityRepresentation { rangeAccessibilitySliders }
  }

  private var rangeOverlay: some View {
    ZStack(alignment: .leading) {
      Capsule()
        .fill(colors.borderHairlineStrong)
        .frame(width: usableWidth, height: WDSliderMetrics.trackHeight)
        .offset(x: WDSliderMetrics.trackInset)

      Capsule()
        .fill(WDGradient.mid.linearGradient)
        .frame(
          width: usableWidth * (upperFraction - lowerFraction),
          height: WDSliderMetrics.trackHeight
        )
        .offset(x: WDSliderMetrics.trackInset + usableWidth * lowerFraction)

      rangeThumb(
        fraction: lowerFraction, isActive: activeThumb == 0,
        showsFocusRing: focusTarget == .lower && isEnabled)
      rangeThumb(
        fraction: upperFraction, isActive: activeThumb == 1,
        showsFocusRing: focusTarget == .upper && isEnabled)
    }
    .opacity(labelOpacity)
  }

  /// 范围手柄（视觉与单值手柄同源：白 + hairline + elevation.1；活动手柄放大 1.15）。
  ///
  /// 聚焦光环与单值同源（设计 08 §5：手柄外扩 3pt）：用同一个 `Circle` 形状 + 同一个 `outset`，
  /// 因此两端的光环半径与单值完全一致。
  private func rangeThumb(fraction: CGFloat, isActive: Bool, showsFocusRing: Bool) -> some View {
    Circle()
      .fill(.white)
      .overlay(
        Circle().strokeBorder(colors.borderHairline, lineWidth: WDSliderMetrics.hairlineWidth)
      )
      .frame(width: thumbDiameter, height: thumbDiameter)
      .wdShadow(WDElevation.e1)
      .scaleEffect(isActive ? WDSliderMetrics.dragScale : 1)
      .offset(x: usableWidth * fraction)
      .animation(.easeOut(duration: WDSliderMetrics.visualDuration), value: isActive)
      .wdFocusRing(Circle(), isPresented: showsFocusRing)
      .allowsHitTesting(false)
  }

  /// 读屏表示：两个原生 Slider（各自一个可调整元素），写回时做区间约束。
  @ViewBuilder private var rangeAccessibilitySliders: some View {
    VStack {
      if let step {
        focusHosted(.lower) {
          Slider(value: lowerBinding, in: bounds, step: step)
            .accessibilityLabel(lowerAccessibilityLabel ?? label)
        }
        focusHosted(.upper) {
          Slider(value: upperBinding, in: bounds, step: step)
            .accessibilityLabel(upperAccessibilityLabel ?? label)
        }
      } else {
        focusHosted(.lower) {
          Slider(value: lowerBinding, in: bounds)
            .accessibilityLabel(lowerAccessibilityLabel ?? label)
        }
        focusHosted(.upper) {
          Slider(value: upperBinding, in: bounds)
            .accessibilityLabel(upperAccessibilityLabel ?? label)
        }
      }
    }
  }

  /// 下端点写回：夹在 [bounds.lower, upper − gap]。
  private var lowerBinding: Binding<Double> {
    Binding(
      get: { range.lowerBound },
      set: { proposed in
        commitLower(proposed)
      })
  }

  /// 上端点写回：夹在 [lower + gap, bounds.upper]。
  private var upperBinding: Binding<Double> {
    Binding(
      get: { range.upperBound },
      set: { proposed in
        commitUpper(proposed)
      })
  }

  /// 点击轨道：最近的手柄跳到目标值（200ms 过渡；Reduce Motion 瞬移）。
  private func handleRangeTap(_ thumb: Int, _ target: Double) {
    guard isEnabled else { return }
    var lower = range.lowerBound
    var upper = range.upperBound
    let gap = WDSliderRangeMath.minimumGap(step: step)
    if thumb == 0 {
      lower = WDSliderRangeMath.clampedLower(target, upper: upper, in: bounds, gap: gap)
    } else {
      upper = WDSliderRangeMath.clampedUpper(target, lower: lower, in: bounds, gap: gap)
    }
    withAnimation(reduceMotion ? nil : .easeOut(duration: WDSliderMetrics.tapDuration)) {
      range = lower...upper
    }
  }

  /// 松手 = 一次有效变更：轻触觉 x1（端点改 rigid）；拖动开始/结束回调透传；松手播报一次。
  private func handleRangeEditing(_ editing: Bool, _ newRange: ClosedRange<Double>) {
    guard isEnabled else { return }
    if !editing {
      activeThumb = nil
      let atEdge =
        newRange.lowerBound <= bounds.lowerBound + WDSliderMetrics.edgeEpsilon
        || newRange.upperBound >= bounds.upperBound - WDSliderMetrics.edgeEpsilon
      WDHaptics.shared.play(atEdge ? .edge : .press, budget: budget)
      announceRangeRelease(newRange)
    }
    onEditingChanged?(editing)
  }

  /// 范围松手播报（同单值口径：注入 + 节流；措辞由调用方给）。
  private func announceRangeRelease(_ released: ClosedRange<Double>) {
    guard let announcer, let rangeAnnouncementText else { return }
    let now = ContinuousClock.now
    guard WDAnnouncementThrottle.shouldAnnounceAfterRelease(now: now, last: lastAnnouncement)
    else { return }
    lastAnnouncement = now
    announcer(rangeAnnouncementText(released), .polite)
  }

  private func commitLower(_ proposed: Double) {
    let gap = WDSliderRangeMath.minimumGap(step: step)
    let lower = WDSliderRangeMath.clampedLower(
      proposed, upper: range.upperBound, in: bounds, gap: gap)
    guard lower != range.lowerBound else { return }
    range = lower...range.upperBound
  }

  private func commitUpper(_ proposed: Double) {
    let gap = WDSliderRangeMath.minimumGap(step: step)
    let upper = WDSliderRangeMath.clampedUpper(
      proposed, lower: range.lowerBound, in: bounds, gap: gap)
    guard upper != range.upperBound else { return }
    range = range.lowerBound...upper
  }

  /// 端点比例（0…1），与单值 `fraction` 同源。
  private var lowerFraction: CGFloat { fraction(of: range.lowerBound) }
  private var upperFraction: CGFloat { fraction(of: range.upperBound) }

  private func fraction(of value: Double) -> CGFloat {
    let span = bounds.upperBound - bounds.lowerBound
    guard span > 0 else { return 0 }
    let raw = (value - bounds.lowerBound) / span
    return CGFloat(min(max(raw, 0), 1))
  }

  /// 轨道覆盖层（轨道 + 填充 + 手柄）：禁用态按设计 08 §5 整体 45%。
  ///
  /// 透明度只盖在自绘层上，不盖手势层 —— 见 `labelOpacity` 的说明。
  private var trackOverlay: some View {
    ZStack(alignment: .leading) {
      trackBackground
      trackFill
      thumb
    }
    .opacity(labelOpacity)
  }

  /// 未填充轨道（border.hairline-strong，6pt）。
  private var trackBackground: some View {
    Capsule()
      .fill(colors.borderHairlineStrong)
      .frame(width: usableWidth, height: WDSliderMetrics.trackHeight)
      .offset(x: WDSliderMetrics.trackInset)
      .allowsHitTesting(false)
  }

  /// 已填充段（gradient.mid，6pt）。
  private var trackFill: some View {
    Capsule()
      .fill(WDGradient.mid.linearGradient)
      .frame(width: usableWidth * fraction, height: WDSliderMetrics.trackHeight)
      .offset(x: fillOffset)
      .allowsHitTesting(false)
  }

  /// 手柄（白 + hairline + elevation.1；拖拽 1.15）。
  ///
  /// 尺寸与偏移和加值之前一字不差；多出来的 `onGeometryChange` 只**读**手柄中心在热区里的
  /// 横向位置（光环要画在热区外，ZStack 的子视图会被热区裁掉，所以不能直接把光环放进 ZStack）。
  private var thumb: some View {
    thumbCircle
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.frame(in: .local).midX
      } action: { centerX in
        thumbCenterX = centerX
      }
  }

  /// 手柄本体（视觉与偏移）。
  private var thumbCircle: some View {
    Circle()
      .fill(.white)
      .overlay(
        Circle().strokeBorder(colors.borderHairline, lineWidth: WDSliderMetrics.hairlineWidth)
      )
      .frame(width: thumbDiameter, height: thumbDiameter)
      .wdShadow(WDElevation.e1)
      .scaleEffect(isEditing ? WDSliderMetrics.dragScale : 1)
      .offset(x: usableWidth * fraction)
      .animation(.easeOut(duration: WDSliderMetrics.visualDuration), value: isEditing)
      .allowsHitTesting(false)
  }

  /// 手柄聚焦光环（设计 08 §5：手柄外扩 3pt，`state.focus.ring` 槽位 + 160ms 淡入）。
  ///
  /// 半径由 `WDSliderMetrics.focusRingRadius` 决定（只聚焦且可用时才有 —— 半径 0 就是不画），
  /// 淡入由 `WDSliderMetrics.focusRingAnimation` 决定（Reduce Motion ⇒ 直出）。
  @ViewBuilder private var focusRing: some View {
    let isFocused = focusTarget == .single
    let diameter = WDSliderMetrics.focusRingDiameter(
      isFocused: isFocused, isEnabled: isEnabled)
    if diameter > 0 {
      Circle()
        .strokeBorder(
          colors.textBrand.opacity(WDSliderMetrics.focusRingAlpha),
          lineWidth: WDSliderMetrics.focusRingWidth
        )
        .frame(width: diameter, height: diameter)
        .offset(
          WDSliderMetrics.focusRingOrigin(
            thumbCenterX: thumbCenterX, hotAreaHeight: hotAreaHeight,
            isFocused: isFocused, isEnabled: isEnabled)
        )
        .animation(
          WDSliderMetrics.focusRingAnimation(reduceMotion: reduceMotion),
          value: isFocused
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  /// 读屏语义：借原生 Slider 提供 slider 角色、当前值、可调整手势（同 WDProgressBar 口径）。
  @ViewBuilder private var accessibilitySlider: some View {
    if let step {
      focusHosted(.single) {
        Slider(value: $value, in: bounds, step: step)
          .accessibilityLabel(label)
      }
    } else {
      focusHosted(.single) {
        Slider(value: $value, in: bounds)
          .accessibilityLabel(label)
      }
    }
  }

  /// 把表示层的原生控件包进焦点宿主（焦点变化回写到 `focusTarget`，光环据此显示）。
  private func focusHosted<V: View>(_ target: WDFocusRingTarget, @ViewBuilder _ content: () -> V)
    -> some View
  {
    WDAccessibilityFocusHost(focused: $focusTarget, target: target, content: content)
  }

  /// 松手（false）= 一次有效变更：轻触觉 x1 + 调用方回调（设计 08 §8）。
  /// 拖到端点时改用 rigid（设计 08 §11），同一次操作仍只抖一次；
  /// 松手后按设计 08 §10 播报一次（`announcementText` 未注入则不播）。
  private func handleEditingChanged(_ editing: Bool, value newValue: Double) {
    isEditing = editing
    guard isEnabled else { return }
    if !editing {
      let atEdge =
        newValue <= bounds.lowerBound + WDSliderMetrics.edgeEpsilon
        || newValue >= bounds.upperBound - WDSliderMetrics.edgeEpsilon
      WDHaptics.shared.play(atEdge ? .edge : .press, budget: budget)
      announceRelease(newValue)
    }
    onEditingChanged?(editing)
  }

  /// 松手播报（设计 08 §10「数值变化不做 aria-live 实时播报，只在松手后播报一次」）。
  ///
  /// 两道闸门：① 调用方注入了文案；② 距上次播报已过 `WDAnnouncementThrottle` 的最小间隔
  /// （连点轨道/连拖不会刷屏）。措辞完全由调用方给（L-B），库只决定「何时播」。
  private func announceRelease(_ released: Double) {
    guard let announcer, let announcementText else { return }
    let now = ContinuousClock.now
    guard WDAnnouncementThrottle.shouldAnnounceAfterRelease(now: now, last: lastAnnouncement)
    else { return }
    lastAnnouncement = now
    announcer(announcementText(released), .polite)
  }

  /// 点击轨道：200ms 过渡跳到目标值（Reduce Motion 时瞬移）。
  private func handleTap(_ target: Double) {
    withAnimation(reduceMotion ? nil : .easeOut(duration: WDSliderMetrics.tapDuration)) {
      value = target
    }
  }

  /// 轨道可用宽度（两端各内缩手柄半径）。
  private var usableWidth: CGFloat {
    max(trackWidth - WDSliderMetrics.thumbDiameter, 0)
  }

  /// 当前值在轨道上的比例（0…1）。
  private var fraction: CGFloat {
    let span = bounds.upperBound - bounds.lowerBound
    guard span > 0 else { return 0 }
    let raw = (value - bounds.lowerBound) / span
    return CGFloat(min(max(raw, 0), 1))
  }

  /// 填充段起点：轨道左端（RTL 由 SwiftUI 的 leading 对齐自动镜像）。
  private var fillOffset: CGFloat { WDSliderMetrics.trackInset }

  /// 热区高度 = WDSize.touchTargetMin（44；轨道视觉 6，上下各扩 19）。
  private var hotAreaHeight: CGFloat { WDSize.touchTargetMin }

  /// 手柄直径 26。
  private var thumbDiameter: CGFloat { WDSliderMetrics.thumbDiameter }

  /// 数值标签的可读宽度（见 `WDSliderMetrics.valueLabelWidth`）。
  private var valueLabelWidth: CGFloat {
    WDSliderMetrics.valueLabelWidth(available: trackWidth)
  }

  /// 禁用态整体不透明度（设计 08 §5 的 45%，不是 WDState 的通用 40%）。
  ///
  /// 它只盖在**自绘**部分（标签行 + 轨道覆盖层），不套在整个滑杆外层：
  /// 外层 opacity 会把 `accessibilityRepresentation` 生成的 UIKit 层一起变透明，
  /// 读屏焦点落到禁用滑杆时设到的是隐藏层元素，可调整手势会失效。
  private var disabledOpacity: CGFloat { WDSliderMetrics.disabledOpacity }
}
