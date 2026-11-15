import SwiftUI

/// 单选选项（设计 07；值数组 `options`）。
///
/// `detail` 对应设计 07 §4 的「带描述」变体（选项下方一行 footnote）；nil = 无描述。
public struct WDRadioOption: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 选项文案。
  public let label: Text
  /// 选项描述（设计「带描述」变体）。
  public let detail: Text?

  /// 构造：身份 + 文案 + 可选描述。
  public init(id: String, label: Text, detail: Text? = nil) {
    self.id = id
    self.label = label
    self.detail = detail
  }
}

/// 单选尺寸档（设计 07 §3）。
public enum WDRadioSize: String, CaseIterable, Sendable, Equatable {
  /// 标准档：外圆 26、内点 12、标签 `subheadline`。
  case standard
  /// 紧凑档：外圆 22、内点 10、标签 `footnote`。
  case compact
}

/// 档位几何（internal 供单测断言；不进入公开 API）。
struct WDRadioGeometry: Sendable, Equatable {
  let indicatorSize: CGFloat
  let innerDot: CGFloat
  let textStyle: WDTextStyle

  /// 按档位解析几何（设计 07 §3；描边 1.5 与组内间距 12 两档共用）。
  static func of(_ size: WDRadioSize) -> WDRadioGeometry {
    switch size {
    case .standard:
      return WDRadioGeometry(
        indicatorSize: 26,  // wd-structure-check:disable R7 — 设计 07 §3
        innerDot: 12,  // wd-structure-check:disable R7 — 设计 07 §3
        textStyle: WDType.subheadline)
    case .compact:
      return WDRadioGeometry(
        indicatorSize: 22,  // wd-structure-check:disable R7 — 设计 07 §3
        innerDot: 10,  // wd-structure-check:disable R7 — 设计 07 §3
        textStyle: WDType.footnote)
    }
  }
}

/// 单选组（SPEC §2.10-#07；M5）。
///
/// 设计口径（设计 07）：
/// - 标准档外圆 **26**、内圆点 **12**、标签 `subheadline` 15；
/// - 紧凑档外圆 **22**、内圆点 **10**、标签 `footnote` 13；
/// - 未选 = 1.5pt `border.hairline-strong` 描边 + `fill.field`；已选 = `gradient.mid` + 白内点；
/// - 组内互斥、点击已选项**不重复回调**、不可取消；热区 ≥44；组内间距 12。
///
/// 既有 `selection` + `label` + `options` 构造保持标准档；紧凑档走带 `size` 的构造。
/// `radiogroup`/`radio` 角色（SwiftUI 无对应 trait）差异仍登记在
/// `docs/M5-EXIT-REPORT.md`。
public struct WDRadio: View {
  @Binding private var selection: String
  private let label: Text
  private let size: WDRadioSize
  private let options: [WDRadioOption]

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：受控值 + 组标签 + 选项数组（标准档）。
  public init(selection: Binding<String>, label: Text, options: [WDRadioOption]) {
    self.init(selection: selection, label: label, size: .standard, options: options)
  }

  /// 构造：受控值 + 组标签 + 尺寸档 + 选项数组。
  public init(
    selection: Binding<String>, label: Text, size: WDRadioSize, options: [WDRadioOption]
  ) {
    self._selection = selection
    self.label = label
    self.size = size
    self.options = options
  }

  /// 纵向选项列表；整组作为一个容器（组标签由 `label` 提供）。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      ForEach(options) { option in
        row(option)
      }
    }
    .opacity(isEnabled ? 1 : disabledOpacity)
    .accessibilityElement(children: .contain)
    .accessibilityLabel(label)
    .onAppear {
      assert(options.count <= Self.maxOptions, "WDRadio 组内最多 5 项（设计 07 §6）")
    }
  }

  private func row(_ option: WDRadioOption) -> some View {
    let isSelected = option.id == selection
    let geometry = WDRadioGeometry.of(size)
    return Button {
      guard isEnabled, !isSelected else { return }
      selection = option.id
      WDHaptics.shared.play(.toggle, budget: budget)
    } label: {
      HStack(alignment: option.detail == nil ? .center : .top, spacing: WDSpacing.s3) {
        indicator(isSelected: isSelected, geometry: geometry)
        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          option.label
            .wdFont(geometry.textStyle)
            .wdLineBox(geometry.textStyle)
            .foregroundStyle(colors.textPrimary)
          if let detail = option.detail {
            detail
              .wdFont(WDType.footnote)
              .wdLineBox(WDType.footnote)
              .foregroundStyle(colors.textSecondary)
          }
        }
        Spacer(minLength: 0)
      }
      .frame(minHeight: WDSize.touchTargetMin, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(WDRadioRowStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder private func indicator(
    isSelected: Bool, geometry: WDRadioGeometry
  ) -> some View {
    ZStack {
      if isSelected {
        Circle()
          .fill(WDGradient.mid.linearGradient)
        Circle()
          .fill(colors.textOnDark)
          .frame(width: geometry.innerDot, height: geometry.innerDot)
      } else {
        Circle()
          .fill(colors.fillField)
        Circle()
          .stroke(colors.borderHairlineStrong, lineWidth: Self.stroke)
      }
    }
    .frame(width: geometry.indicatorSize, height: geometry.indicatorSize)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: isSelected)
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 未选描边 1.5（设计 07 §5；两档共用）。
  private static let stroke: CGFloat = 1.5  // wd-structure-check:disable R7 — 设计值
  /// 组内上限 5（设计 07 §6）。
  private static let maxOptions = 5  // wd-structure-check:disable R7 — 设计 07 §6 的上限
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}

/// 按下缩放 0.92（设计 07 §5）；按下态来源 = `ButtonStyleConfiguration`。
private struct WDRadioRowStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.92 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
