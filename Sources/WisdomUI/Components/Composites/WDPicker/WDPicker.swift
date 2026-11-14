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

/// 选择器形态（设计 22 §4：菜单 / 滚轮 / 内联）。
public enum WDPickerStyle: String, CaseIterable, Sendable, Equatable {
  /// 自绘菜单浮层（触发入口下方展开，可翻转；设计 22 §4「菜单」）。
  case menu
  /// 底部系统 `Picker(.wheel)`（设计 22 §11 的 iOS 滚轮载体）。
  case wheel
  /// 直接平铺在页面里（设计 22 §4「内联」；选项 ≤ 8 时用）。
  case inline
}

/// 选择器（SPEC §2.10-#22；M5）。
///
/// 设计口径（设计 22）：
/// - 触发入口高 **44**；左侧标签、右侧当前值 + **chevron-down**；未选显示占位符（`text.tertiary`）；
/// - 菜单形态 = **自绘浮层**：圆角 14、最小宽 180、最大宽 = 屏宽 − 32、行高 44、水平内距 14、
///   与入口间距 4、空间不足自动翻转、当前项打勾并滚到可视区中间、240ms 弹簧入场；
/// - 滚轮形态 = 底部系统 `Picker(.wheel)`（平台差异 §11：保留系统控件的读屏/键盘行为）；
/// - 内联形态 = 选项直接平铺（≤ 8 项）；
/// - 空 `options` ⇒ debug 断言；点遮罩/Esc 关闭不改变当前值。
public struct WDPicker: View {
  @Binding private var selection: String?
  private let label: Text
  private let options: [WDPickerOption]
  private let placeholder: Text?
  private let style: WDPickerStyle

  @Environment(\.wdColors) private var colors
  @Environment(\.wdTheme) private var theme
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.isEnabled) private var isEnabled

  @State private var showsWheel = false
  @State private var anchorBox = WDPickerAnchorBox()

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

  /// 触发入口 +（按形态）菜单浮层、滚轮弹层或内联列表。
  public var body: some View {
    Group {
      switch style {
      case .menu:
        triggerButton {
          presentMenu()
        }
      case .wheel:
        triggerButton {
          showsWheel = true
        }
        .sheet(isPresented: $showsWheel) {
          wheelSheet
        }
      case .inline:
        WDPickerOptionList(sections: menuSections, selection: selection, onSelect: select)
          .accessibilityElement(children: .contain)
          .accessibilityLabel(label)
      }
    }
    .opacity(isEnabled ? 1 : disabledOpacity)
    .onAppear {
      assert(!options.isEmpty, "WDPicker options 不能为空（设计 22）")
    }
    .onDisappear {
      WDPickerMenuPresenter.shared.dismiss()
    }
  }

  // MARK: - 触发入口

  private func triggerButton(action: @escaping () -> Void) -> some View {
    Button {
      guard isEnabled, !options.isEmpty else {
        return
      }
      action()
    } label: {
      trigger
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background(anchorReader)
  }

  /// 触发入口在窗口坐标系里的矩形（引用类型：滚动时更新不触发重绘）。
  private var anchorReader: some View {
    GeometryReader { proxy in
      Color.clear
        .onAppear {
          anchorBox.rect = proxy.frame(in: .global)
        }
        .onChange(of: proxy.frame(in: .global)) { _, rect in
          anchorBox.rect = rect
        }
    }
  }

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
      WDIcon(icon: .expand, size: .sm)
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

  private var selectedOption: WDPickerOption? {
    options.first {
      $0.id == selection
    }
  }

  // MARK: - 菜单浮层

  private func presentMenu() {
    let anchorRect = anchorBox.rect
    guard anchorRect.width > 0, anchorRect.height > 0 else {
      return
    }
    let sections = menuSections
    let current = selection
    WDPickerMenuPresenter.shared.present(theme: theme, colorScheme: colorScheme) {
      size, safeArea, channel in
      WDPickerMenuLayer(
        anchorRect: anchorRect,
        containerSize: size,
        safeArea: safeArea,
        sections: sections,
        selection: current,
        dismissChannel: channel,
        onSelect: { id in
          selection = id
        },
        onRequestDismiss: {
          WDPickerMenuPresenter.shared.dismiss()
        }
      )
    }
  }

  private var menuSections: [WDPickerMenuSection] {
    var sections: [WDPickerMenuSection] = []
    for option in options {
      if let last = sections.last, last.header == option.group {
        sections[sections.count - 1] = WDPickerMenuSection(
          id: last.id, header: last.header, options: last.options + [option])
      } else {
        sections.append(
          WDPickerMenuSection(id: sections.count, header: option.group, options: [option]))
      }
    }
    return sections
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
      get: {
        selection ?? options.first?.id ?? ""
      },
      set: {
        selection = $0
      }
    )
  }

  // MARK: - 状态

  private func select(_ id: String) {
    guard isEnabled else {
      return
    }
    selection = id
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

/// 触发入口窗口坐标的持有者（不参与 SwiftUI 状态更新，避免滚动时逐帧重绘）。
final class WDPickerAnchorBox {
  var rect: CGRect = .zero
}
