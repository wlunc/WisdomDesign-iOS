import SwiftUI

/// 芯片尺寸档（设计 10 §3）。
public enum WDChipSize: String, CaseIterable, Sendable, Equatable {
  /// 标准：高 32、水平内距 12、字号 13。
  case standard
  /// 紧凑：高 28、水平内距 10、字号 12。
  case compact
}

/// 芯片（SPEC §2.10-#10；M5）。
///
/// 设计口径（设计 10）：
/// - 标准 32 / 紧凑 28；圆角 `radius.full`；带图标时左 10 右 14，图标 15（token 最近档 16，差 1pt 登记）；
/// - 展示 = `surface.card` + `text.secondary` + hairline；
/// - 可选未选 = 同上；可选已选 = `surface.tint` + `text.on-soft` + `text.brand` 42% 描边 + 字重加粗；
/// - 删除键独立可达（热区 ≥44），点击不触发整行；展示型不进焦点序列。
///
/// 三种语义用三个 init 编译期分离（`docs/M5-SIGNATURE-FREEZE.md` Q5）：
/// `init(label:leadingIcon:size:)` / `init(label:isSelected:leadingIcon:size:)` /
/// `init(label:leadingIcon:size:deleteAccessibilityLabel:onDelete:)`。
public struct WDChip: View {
  private enum Mode {
    case display
    case selectable(Binding<Bool>)
    case deletable(label: Text, onDelete: () -> Void)
  }

  private let label: Text
  private let leadingIcon: WDIconName?
  private let size: WDChipSize
  private let mode: Mode

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  /// 展示型：不可交互、不进焦点序列。
  public init(label: Text, leadingIcon: WDIconName? = nil, size: WDChipSize = .standard) {
    self.label = label
    self.leadingIcon = leadingIcon
    self.size = size
    mode = .display
  }

  /// 可选中型：点击切换 `isSelected`。
  public init(
    label: Text,
    isSelected: Binding<Bool>,
    leadingIcon: WDIconName? = nil,
    size: WDChipSize = .standard
  ) {
    self.label = label
    self.leadingIcon = leadingIcon
    self.size = size
    mode = .selectable(isSelected)
  }

  /// 可删除型：删除键独立可达；标签由调用方给（如「移除筛选：妈妈」）。
  public init(
    label: Text,
    leadingIcon: WDIconName? = nil,
    size: WDChipSize = .standard,
    deleteAccessibilityLabel: Text,
    onDelete: @escaping () -> Void
  ) {
    self.label = label
    self.leadingIcon = leadingIcon
    self.size = size
    mode = .deletable(label: deleteAccessibilityLabel, onDelete: onDelete)
  }

  /// 按用法渲染。
  public var body: some View {
    switch mode {
    case .display:
      chip(isSelected: false)
    case .selectable(let isSelected):
      Button {
        guard isEnabled else { return }
        isSelected.wrappedValue.toggle()
        WDHaptics.shared.play(.toggle, budget: budget)
      } label: {
        chip(isSelected: isSelected.wrappedValue)
      }
      .buttonStyle(WDChipPressStyle())
      .opacity(isEnabled ? 1 : disabledOpacity)
      .accessibilityAddTraits(isSelected.wrappedValue ? .isSelected : [])
      .accessibilityLabel(label)
    case .deletable(let deleteLabel, let onDelete):
      HStack(spacing: 0) {
        chip(isSelected: false)
        Button {
          guard isEnabled else { return }
          onDelete()
        } label: {
          WDIcon(icon: .close, size: .sm)
            .foregroundStyle(colors.textSecondary)
            .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(deleteLabel)
      }
      .opacity(isEnabled ? 1 : disabledOpacity)
    }
  }

  // MARK: - 视觉

  private func chip(isSelected: Bool) -> some View {
    HStack(spacing: WDSpacing.s2) {
      if let leadingIcon {
        WDIcon(icon: leadingIcon, size: .sm)
          .foregroundStyle(isSelected ? colors.textOnSoft : colors.textSecondary)
      }
      label
        .wdFont(fontStyle)
        .wdLineBox(fontStyle)
        .fontWeight(isSelected ? .semibold : .regular)
        .foregroundStyle(isSelected ? colors.textOnSoft : colors.textSecondary)
        .lineLimit(1)
    }
    .padding(.leading, horizontalPadding.leading)
    .padding(.trailing, horizontalPadding.trailing)
    .frame(minHeight: height)
    .background(Capsule().fill(isSelected ? colors.surfaceTint : colors.surfaceCard))
    .overlay(Capsule().stroke(borderColor(isSelected: isSelected), lineWidth: 1))
  }

  private func borderColor(isSelected: Bool) -> Color {
    isSelected ? colors.textBrand.opacity(Self.selectedBorderAlpha) : colors.borderHairline
  }

  private var horizontalPadding: (leading: CGFloat, trailing: CGFloat) {
    switch size {
    case .standard:
      return leadingIcon == nil
        ? (WDSpacing.s4, WDSpacing.s4) : (Self.iconLeading, Self.iconTrailing)
    case .compact:
      return (Self.compactPadding, Self.compactPadding)
    }
  }

  private var height: CGFloat {
    switch size {
    case .standard: return WDSize.controlSm
    case .compact: return Self.compactHeight
    }
  }

  private var fontStyle: WDTextStyle {
    switch size {
    case .standard: return WDType.footnote  // 13
    case .compact: return WDType.caption1  // 12
    }
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 带图标时左内距 10（设计 10 §3）。
  private static let iconLeading: CGFloat = 10  // wd-structure-check:disable R7 — 设计值
  /// 带图标时右内距 14（设计 10 §3）。
  private static let iconTrailing: CGFloat = 14  // wd-structure-check:disable R7 — 设计值
  /// 紧凑档水平内距 10（设计 10 §3）。
  private static let compactPadding: CGFloat = 10  // wd-structure-check:disable R7 — 设计值
  /// 紧凑档高度 28（设计 10 §3）。
  private static let compactHeight: CGFloat = 28  // wd-structure-check:disable R7 — 设计值
  /// 选中描边透明度 42%（设计 10 §4）。
  private static let selectedBorderAlpha: CGFloat = 0.42  // wd-structure-check:disable R7 — 设计值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 按下缩放 0.96（设计 10 §5）。
private struct WDChipPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
