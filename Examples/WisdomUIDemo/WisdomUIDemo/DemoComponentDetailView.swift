import SwiftUI
import WisdomUI

/// 组件详情页：实时预览 + 档位/状态一览 + 枚举设置。
struct DemoComponentDetailView: View {
  let component: DemoComponentEntry

  @State private var settings = DemoComponentSettings()
  @State private var showsSettings = false

  @Environment(\.wdColors) private var colors

  private var currentSummary: [String] {
    settings.summary(for: component.id)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        DemoDetailHeader(component: component)

        DemoSection(
          "实时预览",
          subtitle: component.hasEnumSettings
            ? "右上角「设置」可以切换枚举；关闭设置后，这里的预览会显示新配置。"
            : "直接与组件交互，观察状态变化。"
        ) {
          if !currentSummary.isEmpty {
            DemoConfigChips(values: currentSummary)
          }
          DemoPreviewCanvas {
            DemoComponentPreview(component: component, settings: $settings)
          }
        }

        DemoVariantsSection(component: component, settings: $settings)
        DemoStatesSection(component: component, settings: $settings)
        DemoDetailHighlights(component: component)
      }
      .padding(.horizontal, WDSpacing.s5)
      .padding(.top, WDSpacing.s2)
      .padding(.bottom, WDSpacing.s8)
    }
    .background(colors.bgCanvas.ignoresSafeArea())
    .navigationTitle(Text(verbatim: component.name))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if component.hasEnumSettings {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showsSettings = true
          } label: {
            Label("设置", systemImage: "gearshape")
          }
          .accessibilityLabel(Text(verbatim: "设置"))
          .accessibilityIdentifier("component-settings-button")
        }
      }
    }
    .sheet(isPresented: $showsSettings) {
      DemoComponentSettingsView(component: component, settings: $settings)
    }
  }
}

// MARK: - 头部

private struct DemoDetailHeader: View {
  let component: DemoComponentEntry

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      HStack(alignment: .center, spacing: WDSpacing.s4) {
        ZStack {
          RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
            .fill(WDGradient.surface.linearGradient)
            .frame(width: 56, height: 56)
          WDIcon(icon: component.icon, size: .lg)
            .foregroundStyle(colors.textOnSoft)
        }

        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          Text(verbatim: component.name)
            .wdFont(WDType.title2)
            .foregroundStyle(colors.textPrimary)
          Text(
            verbatim: component.category.title + " · " + component.layer + " · " + component.batch
          )
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
        }
        Spacer(minLength: 0)
      }

      Text(verbatim: component.summary)
        .wdFont(WDType.body)
        .foregroundStyle(colors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: WDSpacing.s2) {
        DemoInfoPill(text: component.layer)
        DemoInfoPill(text: component.batch)
        DemoInfoPill(text: component.hasEnumSettings ? "可切换枚举" : "无枚举")
      }
    }
  }
}

private struct DemoDetailHighlights: View {
  let component: DemoComponentEntry

  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("实现细节", subtitle: "来自当前冻结签名与设计口径。") {
      VStack(alignment: .leading, spacing: WDSpacing.s3) {
        ForEach(component.highlights, id: \.self) { text in
          HStack(alignment: .top, spacing: WDSpacing.s3) {
            Circle()
              .fill(colors.textBrand)
              .frame(width: 5, height: 5)
              .padding(.top, 6)
            Text(verbatim: text)
              .wdFont(WDType.subheadline)
              .foregroundStyle(colors.textSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        if component.hasEnumSettings {
          WDDivider()
          Text(verbatim: "提示：这里的设置只改变 demo 的展示参数，不会修改库里的默认值。")
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

// MARK: - 设置面板

private struct DemoComponentSettingsView: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  @Environment(\.dismiss) private var dismiss
  @Environment(\.wdColors) private var colors

  var body: some View {
    NavigationStack {
      List {
        settingsContent
      }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(colors.bgCanvas)
      .navigationTitle(Text(verbatim: component.name + " 设置"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(colors.bgCanvas, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("重置") {
            settings = DemoComponentSettings()
          }
          .accessibilityIdentifier("settings-reset-button")
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("完成") {
            dismiss()
          }
          .fontWeight(.semibold)
          .accessibilityIdentifier("settings-done-button")
        }
      }
    }
    .presentationDetents(presentationDetents)
    .presentationDragIndicator(.visible)
  }

  /// 长设置页（图标网格、字段槽位、行槽位）直接开大，短设置页保留中等高度。
  private var presentationDetents: Set<PresentationDetent> {
    switch component.id {
    case .icon, .iconButton, .textField, .listRow:
      return [.large]
    case .button, .card:
      return [.medium, .large]
    case .switchControl, .checkbox, .badge, .avatar, .divider, .listSection:
      return [.medium]
    }
  }

  @ViewBuilder private var settingsContent: some View {
    switch component.id {
    case .button:
      Section {
        DemoChoiceRow(
          title: "变体",
          selection: $settings.buttonVariant,
          options: WDButtonVariant.allCases,
          identifier: "setting-button-variant"
        ) { value in
          value.demoTitle + " · " + value.rawValue
        }
        DemoChoiceRow(
          title: "尺寸",
          selection: $settings.buttonSize,
          options: WDButtonSize.allCases,
          identifier: "setting-button-size"
        ) { value in
          value.demoTitle
        }
      } header: {
        DemoSettingHeader(title: "外观")
      }

      Section {
        DemoToggleRow(
          title: "加载中",
          isOn: $settings.buttonLoading,
          identifier: "setting-button-loading"
        )
        DemoToggleRow(
          title: "禁用",
          isOn: $settings.buttonDisabled,
          identifier: "setting-button-disabled"
        )
      } header: {
        DemoSettingHeader(title: "状态")
      }

    case .iconButton:
      Section {
        DemoChoiceRow(
          title: "尺寸",
          selection: $settings.iconButtonSize,
          options: WDButtonSize.allCases,
          identifier: "setting-icon-button-size"
        ) { value in
          value.demoTitle
        }
      } header: {
        DemoSettingHeader(title: "外观")
      }

      Section {
        DemoIconChoiceGrid(selection: $settings.iconButtonIcon)
      } header: {
        DemoSettingHeader(title: "图标")
      }

      Section {
        DemoToggleRow(
          title: "加载中",
          isOn: $settings.iconButtonLoading,
          identifier: "setting-icon-button-loading"
        )
        DemoToggleRow(
          title: "禁用",
          isOn: $settings.iconButtonDisabled,
          identifier: "setting-icon-button-disabled"
        )
      } header: {
        DemoSettingHeader(title: "状态")
      }

    case .textField:
      Section {
        DemoChoiceRow(
          title: "形态",
          selection: $settings.textFieldVariant,
          options: WDTextFieldVariant.allCases,
          identifier: "setting-textfield-variant"
        ) { value in
          value.demoTitle + " · " + value.rawValue
        }
      } header: {
        DemoSettingHeader(title: "外观")
      }

      Section {
        DemoChoiceRow(
          title: "前缀",
          selection: $settings.textFieldPrefix,
          options: DemoTextFieldPrefix.allCases,
          identifier: "setting-textfield-prefix"
        ) { value in
          value.title
        }
        DemoChoiceRow(
          title: "尾部附件",
          selection: $settings.textFieldAccessory,
          options: DemoTextFieldAccessory.allCases,
          identifier: "setting-textfield-accessory"
        ) { value in
          value.title
        }
        DemoChoiceRow(
          title: "辅助文案",
          selection: $settings.textFieldHelper,
          options: DemoTextFieldHelper.allCases,
          identifier: "setting-textfield-helper"
        ) { value in
          value.title
        }
      } header: {
        DemoSettingHeader(title: "槽位")
      }

      Section {
        DemoToggleRow(
          title: "密文",
          isOn: $settings.textFieldSecure,
          identifier: "setting-textfield-secure"
        )
        DemoToggleRow(
          title: "只读",
          isOn: $settings.textFieldReadOnly,
          identifier: "setting-textfield-readonly"
        )
      } header: {
        DemoSettingHeader(title: "状态")
      }

    case .card:
      Section {
        DemoChoiceRow(
          title: "外观",
          selection: $settings.cardStyle,
          options: WDCardStyle.allCases,
          identifier: "setting-card-style"
        ) { value in
          value.demoTitle + " · " + value.rawValue
        }
      }

    case .listRow:
      Section {
        DemoChoiceRow(
          title: "行首",
          selection: $settings.rowLeading,
          options: DemoListRowLeading.allCases,
          identifier: "setting-listrow-leading"
        ) { value in
          value.title
        }
        DemoChoiceRow(
          title: "行尾",
          selection: $settings.rowTrailing,
          options: DemoListRowTrailing.allCases,
          identifier: "setting-listrow-trailing"
        ) { value in
          value.title
        }
      } header: {
        DemoSettingHeader(title: "槽位")
      }

      Section {
        DemoToggleRow(
          title: "选中",
          isOn: $settings.rowSelected,
          identifier: "setting-listrow-selected"
        )
        DemoToggleRow(
          title: "显示分隔线",
          isOn: $settings.rowShowsSeparator,
          identifier: "setting-listrow-separator"
        )
        DemoToggleRow(
          title: "可点击",
          isOn: $settings.rowTappable,
          identifier: "setting-listrow-tappable"
        )
      } header: {
        DemoSettingHeader(title: "状态")
      }

    case .icon:
      Section {
        DemoChoiceRow(
          title: "尺寸",
          selection: $settings.iconSize,
          options: WDIconSize.allCases,
          identifier: "setting-icon-size"
        ) { value in
          value.demoTitle
        }
      }

      Section {
        DemoIconChoiceGrid(selection: $settings.iconName)
      } header: {
        DemoSettingHeader(title: "图标（44 个语义名）")
      }

    case .switchControl, .checkbox, .badge, .avatar, .divider, .listSection:
      Section {
        Text(verbatim: "该组件没有可切换的枚举。")
          .wdFont(WDType.body)
          .foregroundStyle(colors.textSecondary)
      } header: {
        DemoSettingHeader(title: "提示")
      }
    }
  }
}

private struct DemoSettingHeader: View {
  let title: String

  @Environment(\.wdColors) private var colors

  var body: some View {
    Text(verbatim: title)
      .wdFont(WDType.footnote)
      .foregroundStyle(colors.textSecondary)
  }
}

/// 一组单选：所有选项直接铺开，点一下即切换（不依赖 Hashable，也不藏进系统 Menu）。
private struct DemoChoiceRow<Value: Equatable>: View {
  let title: String
  @Binding var selection: Value
  let options: [Value]
  let identifier: String
  let titleFor: (Value) -> String

  @Environment(\.wdColors) private var colors

  init(
    title: String,
    selection: Binding<Value>,
    options: [Value],
    identifier: String,
    titleFor: @escaping (Value) -> String
  ) {
    self.title = title
    self._selection = selection
    self.options = options
    self.identifier = identifier
    self.titleFor = titleFor
  }

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      Text(verbatim: title)
        .wdFont(WDType.body)
        .foregroundStyle(colors.textPrimary)

      VStack(spacing: 0) {
        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
          Button {
            selection = option
          } label: {
            HStack(spacing: WDSpacing.s3) {
              Text(verbatim: titleFor(option))
                .wdFont(WDType.subheadline)
                .foregroundStyle(colors.textPrimary)
              Spacer(minLength: 0)
              if option == selection {
                WDIcon(icon: .done, size: .sm)
                  .foregroundStyle(colors.textBrand)
              }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(Text(verbatim: titleFor(option)))
          .accessibilityIdentifier("\(identifier)-\(index)")
          .accessibilityAddTraits(option == selection ? .isSelected : [])

          if index < options.count - 1 {
            Rectangle()
              .fill(colors.borderHairline)
              .frame(height: 1)
              .padding(.leading, WDSpacing.s1)
          }
        }
      }
      .padding(.leading, WDSpacing.s2)
    }
    .padding(.vertical, WDSpacing.s1)
  }
}

private struct DemoToggleRow: View {
  let title: String
  @Binding var isOn: Bool
  let identifier: String

  @Environment(\.wdColors) private var colors

  var body: some View {
    Toggle(isOn: $isOn) {
      Text(verbatim: title)
        .wdFont(WDType.body)
        .foregroundStyle(colors.textPrimary)
    }
    .tint(colors.textBrand)
    .accessibilityIdentifier(identifier)
  }
}

/// 44 个图标语义名的网格选择器。
private struct DemoIconChoiceGrid: View {
  @Binding var selection: WDIconName

  @Environment(\.wdColors) private var colors

  private let columns = [GridItem(.adaptive(minimum: 72), spacing: WDSpacing.s2)]

  var body: some View {
    LazyVGrid(columns: columns, spacing: WDSpacing.s2) {
      ForEach(WDIconName.allCases, id: \.self) { icon in
        Button {
          selection = icon
        } label: {
          VStack(spacing: WDSpacing.s2) {
            WDIcon(icon: icon, size: .md)
            Text(verbatim: icon.rawValue)
              .wdFont(WDType.caption2)
              .lineLimit(1)
              .minimumScaleFactor(0.6)
          }
          .frame(maxWidth: .infinity, minHeight: 48)
          .padding(.vertical, WDSpacing.s2)
          .foregroundStyle(selection == icon ? colors.textOnSoft : colors.textPrimary)
          .background(
            RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
              .fill(selection == icon ? colors.surfaceTint : colors.surfaceCardSunken)
          )
          .overlay(
            RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
              .stroke(
                selection == icon ? colors.textBrand : colors.borderHairline,
                lineWidth: selection == icon ? 1.5 : 1
              )
          )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: icon.rawValue))
        .accessibilityIdentifier("icon-option-\(icon.rawValue)")
      }
    }
    .padding(.vertical, WDSpacing.s2)
  }
}
