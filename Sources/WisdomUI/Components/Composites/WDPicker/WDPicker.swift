import SwiftUI

/// 选择项（设计 22；值数组 `options`）。
public struct WDPickerOption: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 选项文案。
  public let label: Text
  /// 分组标题（设计 22 §7）；nil = 不分组。
  public let group: Text?

  /// 构造：身份 + 文案 + 可选分组。
  public init(id: String, label: Text, group: Text? = nil) {
    self.id = id
    self.label = label
    self.group = group
  }
}

/// 选择器形态（设计 22 §4：菜单 / 滚轮；内联形态本轮不做）。
public enum WDPickerStyle: String, CaseIterable, Sendable, Equatable {
  /// 系统 `Menu`（设计 22 §11 的 iOS 菜单载体）。
  case menu
  /// 底部系统 `Picker(.wheel)`。
  case wheel
}

/// 选择器（SPEC §2.10-#22；M5）。
///
/// 设计口径（设计 22）：
/// - 触发入口高 **44**；左侧标签、右侧当前值 + `chevron`；未选显示占位符（`text.tertiary`）；
/// - 菜单形态 = 系统 `Menu`（带分组标题与当前项标记）；滚轮形态 = 底部系统 `Picker(.wheel)`；
/// - 空 `options` ⇒ debug 断言；点击遮罩/取消不改变当前值。
///
/// 弹出层最小宽 180 / 当前项自动滚到中间 / `listbox` 角色由系统 Menu/Wheel 承担（差异登记在
/// `docs/M5-EXIT-REPORT.md`）。
public struct WDPicker: View {
  @Binding private var selection: String?
  private let label: Text
  private let options: [WDPickerOption]
  private let placeholder: Text?
  private let style: WDPickerStyle

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled

  @State private var showsWheel = false

  /// 构造：受控选中 id + 标签 + 选项 + 占位 + 形态。
  public init(
    selection: Binding<String?>,
    label: Text,
    options: [WDPickerOption],
    placeholder: Text? = nil,
    style: WDPickerStyle = .menu
  ) {
    self._selection = selection
    self.label = label
    self.options = options
    self.placeholder = placeholder
    self.style = style
  }

  /// 触发入口 +（按形态）菜单或滚轮。
  public var body: some View {
    Group {
      switch style {
      case .menu:
        Menu {
          menuContent
        } label: {
          trigger
        }
      case .wheel:
        Button {
          guard isEnabled, !options.isEmpty else { return }
          showsWheel = true
        } label: {
          trigger
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showsWheel) {
          wheelSheet
        }
      }
    }
    .opacity(isEnabled ? 1 : disabledOpacity)
    .onAppear {
      assert(!options.isEmpty, "WDPicker options 不能为空（设计 22）")
    }
  }

  // MARK: - 触发入口

  private var trigger: some View {
    HStack(spacing: WDSpacing.s3) {
      label
        .wdFont(WDType.subheadline)
        .wdLineBox(WDType.subheadline)
        .foregroundStyle(colors.textPrimary)
      Spacer(minLength: WDSpacing.s3)
      if let valueText {
        valueText
          .wdFont(WDType.subheadline)
          .wdLineBox(WDType.subheadline)
          .foregroundStyle(selection == nil ? colors.textTertiary : colors.textPrimary)
          .lineLimit(1)
      }
      WDIcon(icon: .disclose, size: .sm)
        .foregroundStyle(colors.textTertiary)
    }
    .frame(minHeight: WDSize.controlMd)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityLabel(label)
    .accessibilityValue(valueText ?? Text(verbatim: ""))
  }

  private var valueText: Text? {
    selectedOption?.label ?? placeholder
  }

  // MARK: - 菜单

  @ViewBuilder private var menuContent: some View {
    ForEach(Array(groupedOptions.enumerated()), id: \.offset) { pair in
      let group = pair.element
      if let header = group.header {
        Section {
          menuRows(group.options)
        } header: {
          header
        }
      } else {
        menuRows(group.options)
      }
    }
  }

  @ViewBuilder private func menuRows(_ rows: [WDPickerOption]) -> some View {
    ForEach(rows) { option in
      Button {
        select(option)
      } label: {
        if option.id == selection {
          Label {
            option.label
          } icon: {
            WDIcon(icon: .done, size: .sm)
          }
        } else {
          option.label
        }
      }
      .accessibilityAddTraits(option.id == selection ? .isSelected : [])
    }
  }

  private struct OptionGroup {
    let header: Text?
    let options: [WDPickerOption]
  }

  private var groupedOptions: [OptionGroup] {
    var groups: [OptionGroup] = []
    for option in options {
      if let last = groups.last, last.header == option.group {
        groups[groups.count - 1] = OptionGroup(
          header: last.header, options: last.options + [option])
      } else {
        groups.append(OptionGroup(header: option.group, options: [option]))
      }
    }
    return groups
  }

  // MARK: - 滚轮

  private var wheelSheet: some View {
    VStack(spacing: WDSpacing.s4) {
      Picker(selection: wheelBinding) {
        ForEach(options) { option in
          option.label.tag(option.id)
        }
      } label: {
        label
      }
      .pickerStyle(.wheel)
      .labelsHidden()
    }
    .padding(WDSpacing.s5)
    .presentationDetents([.height(Self.wheelSheetHeight)])
    .presentationDragIndicator(.visible)
  }

  private var wheelBinding: Binding<String> {
    Binding(
      get: { selection ?? options.first?.id ?? "" },
      set: { selection = $0 }
    )
  }

  // MARK: - 状态

  private var selectedOption: WDPickerOption? {
    options.first { $0.id == selection }
  }

  private func select(_ option: WDPickerOption) {
    guard isEnabled else { return }
    selection = option.id
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 滚轮弹出层高度（设计 22 未给；取可容纳 5 行的默认）。
  private static let wheelSheetHeight: CGFloat = 260  // wd-structure-check:disable R7 — 设计未给值，取默认
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
}
