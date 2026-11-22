import SwiftUI

/// 工具栏按钮（设计 35；值数组 `items`）。
public struct WDToolbarItem: Identifiable {
  /// 稳定身份。
  public let id: String
  /// 图标语义名。
  public let icon: WDIconName
  /// 读屏标签（必填；图标按钮必须有标签）。
  public let accessibilityLabel: Text
  /// 选中态（如"加粗"已启用）。
  public let isSelected: Bool
  /// 可用态（禁用按钮保持显示，不隐藏整条工具栏）。
  public let isEnabled: Bool
  /// 动作。
  public let action: () -> Void

  /// 构造：身份 + 图标 + 标签 + 状态 + 动作。
  public init(
    id: String,
    icon: WDIconName,
    accessibilityLabel: Text,
    isSelected: Bool = false,
    isEnabled: Bool = true,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.isSelected = isSelected
    self.isEnabled = isEnabled
    self.action = action
  }
}

/// 工具栏（SPEC §2.10-#35；M5）。
///
/// 设计口径（设计 35）：
/// - 容器高 **48**、内边距 6、圆角 `radius.full`；按钮视觉 36×36、图标 20、热区 ≥44；
/// - 默认 `surface.glass-strong` + hairline + `elevation.1`；选中 = `gradient.mid` + 白图标；
/// - 最多 7 个操作，超过收进「更多」菜单；无可用操作时按钮禁用、**不隐藏整条工具栏**；
/// - 整条工具栏有分组标签（`accessibilityLabel`），每个按钮独立标签。
public struct WDToolbar: View {
  private let items: [WDToolbarItem]
  private let accessibilityLabel: Text
  private let overflowAccessibilityLabel: Text?
  /// 长按提示开关（A-14；设计 14 §3）。默认 `false` = 既有"长按无响应"行为，零快照影响。
  private let showsTooltips: Bool

  @Environment(\.wdColors) private var colors
  @Environment(\.wdEffectsBudget) private var budget
  /// 读屏焦点所在的项（B18：聚焦光环；按 id 记，同一时刻只有一个）。
  @State private var focusedItemID: String?
  /// 长按提示可见的项（A-14；同一时刻至多一个 —— 按住谁显示谁）。
  @State private var tooltipItemID: String?
  /// 本轮按下的仲裁门闩（F1；Button 闭包 ⇄ 样式状态机共享。每项一个引用实例，
  /// 按 itemID 记 —— 按下时由样式复位）。
  @State private var arbitrationLatches: [String: WDToolbarArbitrationLatch] = [:]

  /// 构造：项数组 + 分组标签 + 溢出菜单标签。
  ///
  /// - Parameters:
  ///   - showsTooltips: 长按 500ms 显示文字提示（A-14；设计 14 §3）。默认 `false`。
  ///     启用时：长按达到阈值即显示提示并**吞掉本次点击**（抬手不执行 action）；
  ///     500ms 内抬手 = 普通点击。文案与 `accessibilityLabel` 同源（§3.5），不新增字段。
  public init(
    items: [WDToolbarItem],
    accessibilityLabel: Text,
    overflowAccessibilityLabel: Text? = nil,
    showsTooltips: Bool = false
  ) {
    self.items = items
    self.accessibilityLabel = accessibilityLabel
    self.overflowAccessibilityLabel = overflowAccessibilityLabel
    self.showsTooltips = showsTooltips
  }

  /// 胶囊容器 + 按钮 / 溢出菜单。
  public var body: some View {
    HStack(spacing: WDSpacing.s2) {
      ForEach(visibleItems) { item in
        itemButton(item)
      }
      if let overflowAccessibilityLabel, !overflowItems.isEmpty {
        overflowMenu(overflowAccessibilityLabel)
      }
    }
    .padding(.horizontal, Self.horizontalPadding)
    .padding(.vertical, Self.verticalPadding)
    .frame(minHeight: Self.containerHeight)
    .background(
      Capsule()
        .fill(colors.surfaceGlassStrong)
        .overlay(Capsule().stroke(colors.borderHairline, lineWidth: 1))
        .wdShadow(WDElevation.e1)
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel(accessibilityLabel)
  }

  // MARK: - 零件

  /// 取该项的门闩（没有则建 —— 引用类型，跨 Button 闭包与样式状态机共享）。
  private func latchFor(_ itemID: String) -> WDToolbarArbitrationLatch {
    if let existing = arbitrationLatches[itemID] { return existing }
    let fresh = WDToolbarArbitrationLatch()
    arbitrationLatches[itemID] = fresh
    return fresh
  }

  private func itemButton(_ item: WDToolbarItem) -> some View {
    WDAccessibilityFocusHost(
      focused: Binding(
        get: { focusedItemID == item.id ? .single : nil },
        set: { newValue in
          if newValue == nil {
            if focusedItemID == item.id { focusedItemID = nil }
          } else {
            focusedItemID = item.id
          }
        }),
      target: .single
    ) {
      Button {
        // A-14/F1：门闩检查 —— 长按达标/作废的本轮点击在这里被吞（唯一执行路径 =
        // Button 原生闭包；仲裁状态机只判定 + 置闩，不再自行执行 action）。
        let latch = arbitrationLatches[item.id]
        if showsTooltips && item.isEnabled, latch?.isConsumed == true {
          latch?.isConsumed = false
          return
        }
        guard item.isEnabled else { return }
        WDHaptics.shared.play(.press, budget: budget)
        item.action()
      } label: {
        WDIcon(icon: item.icon, size: .md)
          .foregroundStyle(item.isSelected ? colors.textOnDark : colors.textPrimary)
          .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
          .background(
            RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
              .fill(
                item.isSelected
                  ? AnyShapeStyle(WDGradient.mid.linearGradient) : AnyShapeStyle(Color.clear))
          )
          .contentShape(Rectangle())
      }
      // A-14：长按仲裁。提示启用时按钮的 action 由仲裁状态机 + 门闩把关 ——
      // 「抬手是否执行 action」的唯一判断点在 WDToolbarArbitration.decide(.release)，
      // 门闩见 WDToolbarArbitrationLatch（禁用 .simultaneousGesture 的原因见该类型注释）。
      .buttonStyle(
        WDToolbarItemPressStyle(
          arbitration: showsTooltips && item.isEnabled
            ? WDToolbarItemArbitrationContext(
              itemID: item.id,
              threshold: WDSize.tooltipPressDuration,
              latch: latchFor(item.id),
              onTooltip: { id in tooltipItemID = id },
              onTooltipEnd: { id in if tooltipItemID == id { tooltipItemID = nil } })
            : nil
        )
      )
      // 长按提示气泡（A-14；只对可见按钮，溢出菜单项不加 —— 设计 §3.1-C5）。
      .wdToolbarTooltip(
        text: item.accessibilityLabel,
        isVisible: showsTooltips && tooltipItemID == item.id
      )
      // 聚焦光环（设计 35 §5「与 Button 一致」；B18 补齐，形状跟按钮的圆角方）。
      .wdFocusRing(
        RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous),
        isPresented: focusedItemID == item.id && item.isEnabled
      )
      .disabled(!item.isEnabled)
      .opacity(item.isEnabled ? 1 : disabledOpacity)
      .accessibilityLabel(item.accessibilityLabel)
      .accessibilityAddTraits(item.isSelected ? .isSelected : [])
    }
  }

  private func overflowMenu(_ label: Text) -> some View {
    Menu {
      ForEach(overflowItems) { item in
        Button {
          guard item.isEnabled else { return }
          item.action()
        } label: {
          item.accessibilityLabel
        }
        .disabled(!item.isEnabled)
      }
    } label: {
      WDIcon(icon: .more, size: .md)
        .foregroundStyle(colors.textPrimary)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .accessibilityLabel(label)
  }

  // MARK: - 计算

  /// 视觉上最多 7 个操作（6 个按钮 + 「更多」）。
  private var visibleItems: [WDToolbarItem] {
    overflowItems.isEmpty ? items : Array(items.prefix(Self.maxVisibleItems - 1))
  }

  private var overflowItems: [WDToolbarItem] {
    items.count > Self.maxVisibleItems ? Array(items.dropFirst(Self.maxVisibleItems - 1)) : []
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 容器高 48（设计 35 §3）。
  private static let containerHeight: CGFloat = 48  // wd-structure-check:disable R7 — 设计值
  /// 容器水平内边距 6（设计 35 §3）。
  private static let horizontalPadding: CGFloat = 6  // wd-structure-check:disable R7 — 设计值
  /// 容器垂直内边距 2（44 热区 + 2×2 = 48；设计视觉按钮 36 + 6×2 = 48，热区优先）。
  private static let verticalPadding: CGFloat = 2  // wd-structure-check:disable R7 — 热区推导
  /// 最多 7 个操作（设计 35 §7）。
  private static let maxVisibleItems = 7  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 工具栏按钮的按下态（设计 35 §5：缩放 0.94 + `fill.pressed`；`motion.duration.instant`）。
///
/// A-14 起：无仲裁参数时走既有路径（`plainBody`），行为逐帧一致；
/// 带仲裁参数时走长按仲裁路径（见 `WDToolbarItemArbitrationContext`）。
private struct WDToolbarItemPressStyle: ButtonStyle {
  /// nil = 零仲裁（既有路径）；非 nil = 提示启用（A-14）。
  let arbitration: WDToolbarItemArbitrationContext?

  /// 按下底色走环境色（R10：组件内不得用静态令牌入口 `WDColor.*`）。
  @Environment(\.wdColors) private var colors

  func makeBody(configuration: Configuration) -> some View {
    if let arbitration {
      arbitedBody(configuration: configuration, arbitration: arbitration)
    } else {
      plainBody(configuration: configuration)
    }
  }

  /// 既有路径（提示关闭）：按下 0.94 + fill.pressed，无仲裁 —— 与改造前逐帧一致。
  private func plainBody(configuration: Configuration) -> some View {
    configuration.label
      .background {
        RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
          .fill(
            configuration.isPressed
              ? AnyShapeStyle(colors.fillPressed) : AnyShapeStyle(Color.clear))
      }
      .scaleEffect(configuration.isPressed ? pressedScale : 1)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }

  /// 仲裁路径（提示开启）：按下态与计时由同一个状态机驱动。
  @State private var phase: WDToolbarArbitration.Phase = .idle
  @State private var thresholdTask: Task<Void, Never>?

  private func arbitedBody(
    configuration: Configuration,
    arbitration: WDToolbarItemArbitrationContext
  ) -> some View {
    let isPressedVisually: Bool = {
      if case .pressing = phase { return true }
      return false
    }()
    return configuration.label
      .background {
        RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
          .fill(isPressedVisually ? AnyShapeStyle(colors.fillPressed) : AnyShapeStyle(Color.clear))
      }
      .scaleEffect(isPressedVisually ? pressedScale : 1)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: isPressedVisually)
      // F3：滑出热区 → 喂 .dragOut（手势作废）。minimumDistance ≥ 1 合仓规（SPEC §3.4），
      // 零位移轻点不进拖动分支；按住后移出按钮 ⇒ 触发（系统 Button 的 isPressed 同步变 false，
      // 顺序上 drag 先到 —— 门闩与作废相位都以状态机为准）。
      .gesture(
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
          .onChanged { value in
            let inBounds =
              value.startLocation.x >= 0 && value.startLocation.y >= 0
              && value.location.x >= 0 && value.location.y >= 0
            if phase != .consumed,
              !inBounds
                || value.translation.width.magnitude > WDSize.touchTargetMin
                || value.translation.height.magnitude > WDSize.touchTargetMin
            {
              let (d, p) = WDToolbarArbitration.decide(
                .dragOut(at: ProcessInfo.processInfo.systemUptime), in: phase,
                threshold: arbitration.threshold)
              phase = p
              if d == .voidGesture {
                arbitration.latch.isConsumed = true  // 作废：Button 闭包吞掉
                arbitration.onTooltipEnd(arbitration.itemID)
              }
            }
          }
      )
      // 阈值计时：按下后 500ms 喂 thresholdFired；抬手/作废即取消（一次性延时，非轮询）。
      .onChange(of: configuration.isPressed) { _, pressed in
        handlePressChange(pressed, arbitration: arbitration)
      }
  }

  /// 按下/抬手 → 状态机事件。视图层喂事件的唯一入口。
  ///
  /// F1 门闩口径：action 的**唯一执行路径 = Button 原生闭包**（见 WDToolbar.itemButton）。
  /// 状态机不再自行执行 action：
  /// - 按下：复位门闩（新一轮）；
  /// - 阈值到点（showTooltip）：**置闩** —— 抬手时 Button 闭包读到闩 → 吞掉本次点击；
  /// - 快速抬手（performAction）：闩保持 false —— Button 闭包正常执行一次；
  /// - 作废/收尾：闩保持置位，Button 闭包吞掉并复位。
  private func handlePressChange(
    _ pressed: Bool,
    arbitration: WDToolbarItemArbitrationContext
  ) {
    thresholdTask?.cancel()
    thresholdTask = nil
    if pressed {
      arbitration.latch.isConsumed = false  // 新一轮：复位门闩
      let (decision, next) = WDToolbarArbitration.decide(
        .press(at: ProcessInfo.processInfo.systemUptime), in: phase,
        threshold: arbitration.threshold)
      phase = next
      guard decision == .pressed else { return }
      // 一次性阈值延时（500ms）：到点喂 thresholdFired。抬手时上方已 cancel。
      thresholdTask = Task { @MainActor in
        try? await Task.sleep(for: .seconds(arbitration.threshold))
        guard !Task.isCancelled else { return }
        let (d, p) = WDToolbarArbitration.decide(
          .thresholdFired, in: phase, threshold: arbitration.threshold)
        phase = p
        if d == .showTooltip {
          arbitration.latch.isConsumed = true  // 置闩：本轮点击已被吞
          arbitration.onTooltip(arbitration.itemID)
        }
      }
    } else {
      // 抬手：**唯一判断点** —— 状态机只判定，不执行 action。
      // performAction = 闩保持 false（Button 闭包正常执行一次）；
      // 其余（hideTooltip/void/none）= 闩保持置位，Button 闭包吞掉并复位。
      let (decision, next) = WDToolbarArbitration.decide(
        .release(at: ProcessInfo.processInfo.systemUptime), in: phase,
        threshold: arbitration.threshold)
      phase = next
      switch decision {
      case .performAction:
        break  // 闩为 false：Button 原生闭包执行（无双触发）
      case .hideTooltip:
        arbitration.onTooltipEnd(arbitration.itemID)
      default:
        break
      }
    }
  }

  /// 按下缩放 0.94（设计 35 §5）。
  private var pressedScale: CGFloat { 0.94 }  // wd-structure-check:disable R7 — 设计 35 §5
}
