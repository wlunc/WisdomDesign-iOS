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

/// 单选组（SPEC §2.10-#07；M5）。
///
/// 设计口径（设计 07）：
/// - 标准外圆 **26**、内圆点 **12**、标签 `subheadline` 15；
/// - 未选 = 1.5pt `border.hairline-strong` 描边 + `fill.field`；已选 = `gradient.mid` + 白内点；
/// - 组内互斥、点击已选项**不重复回调**、不可取消；热区 ≥44；组内间距 12。
///
/// 冻结签名只有 `selection` + `label` + `options`（ID = String；无紧凑档 22）⇒
/// 只做标准档；紧凑档与 `radiogroup`/`radio` 角色（SwiftUI 无对应 trait）差异登记在
/// `docs/M5-EXIT-REPORT.md`。
public struct WDRadio: View {
  @Binding private var selection: String
  private let label: Text
  private let options: [WDRadioOption]

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：受控值 + 组标签 + 选项数组。
  public init(selection: Binding<String>, label: Text, options: [WDRadioOption]) {
    self._selection = selection
    self.label = label
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
    return Button {
      guard isEnabled, !isSelected else { return }
      selection = option.id
      WDHaptics.shared.play(.toggle, budget: budget)
    } label: {
      HStack(alignment: option.detail == nil ? .center : .top, spacing: WDSpacing.s3) {
        indicator(isSelected: isSelected)
        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          option.label
            .wdFont(WDType.subheadline)
            .wdLineBox(WDType.subheadline)
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

  @ViewBuilder private func indicator(isSelected: Bool) -> some View {
    ZStack {
      if isSelected {
        Circle()
          .fill(WDGradient.mid.linearGradient)
        Circle()
          .fill(colors.textOnDark)
          .frame(width: Self.innerDot, height: Self.innerDot)
      } else {
        Circle()
          .fill(colors.fillField)
        Circle()
          .stroke(colors.borderHairlineStrong, lineWidth: Self.stroke)
      }
    }
    .frame(width: Self.indicatorSize, height: Self.indicatorSize)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: isSelected)
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 外圆直径 26（设计 07 §3；`WDSize.checkbox` 同值，但 R9 禁在 `frame` 里绑令牌）。
  private static let indicatorSize: CGFloat = 26  // wd-structure-check:disable R7 — 设计值
  /// 内圆点 12（设计 07 §3）。
  private static let innerDot: CGFloat = 12  // wd-structure-check:disable R7 — 设计值
  /// 未选描边 1.5（设计 07 §5）。
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
