import SwiftUI
import WisdomUI

// MARK: - 详情页通用容器

/// 详情页的白色分区卡片。
struct DemoSection<Content: View>: View {
  let title: String
  let subtitle: String?
  private let content: Content

  @Environment(\.wdColors) private var colors

  init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
    self.title = title
    self.subtitle = subtitle
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      VStack(alignment: .leading, spacing: WDSpacing.s1) {
        Text(verbatim: title)
          .wdFont(WDType.title3)
          .foregroundStyle(colors.textPrimary)
        if let subtitle {
          Text(verbatim: subtitle)
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      content
    }
    .padding(WDSpacing.s5)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
        .fill(colors.surfaceCard)
    )
    .overlay(
      RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
        .stroke(colors.borderHairline, lineWidth: 1)
    )
  }
}

/// 实时预览的画布：用分组底色 + 一层柔和品牌渐变，玻璃档位也能看出材质差异。
struct DemoPreviewCanvas<Content: View>: View {
  private let content: Content

  @Environment(\.wdColors) private var colors

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .frame(maxWidth: .infinity, minHeight: 136)
      .padding(WDSpacing.s5)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
            .fill(colors.bgGrouped)
          Circle()
            .fill(WDGradient.surface.linearGradient)
            .frame(width: 180, height: 180)
            .blur(radius: 28)
            .offset(x: 118, y: -72)
            .opacity(0.55)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
          .stroke(colors.borderHairline, lineWidth: 1)
      )
  }
}

/// 当前配置摘要的小胶囊。
struct DemoConfigChips: View {
  let values: [String]

  @Environment(\.wdColors) private var colors

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: WDSpacing.s2) {
        ForEach(Array(values.enumerated()), id: \.offset) { index, value in
          Text(verbatim: value)
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textOnSoft)
            .padding(.horizontal, WDSpacing.s3)
            .padding(.vertical, WDSpacing.s1)
            .background(Capsule().fill(colors.surfaceTint))
            .accessibilityIdentifier("config-chip-\(index)")
        }
      }
    }
  }
}

/// 卡片里的小信息胶囊。
struct DemoInfoPill: View {
  let text: String

  @Environment(\.wdColors) private var colors

  var body: some View {
    Text(verbatim: text)
      .wdFont(WDType.caption1)
      .foregroundStyle(colors.textOnSoft)
      .padding(.horizontal, WDSpacing.s3)
      .padding(.vertical, WDSpacing.s1)
      .background(Capsule().fill(colors.surfaceTint))
  }
}

/// 列表行示例共用的白色底座。
struct DemoRowGroup<Content: View>: View {
  private let content: Content

  @Environment(\.wdColors) private var colors

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .background(colors.surfaceCardSolid)
      .clipShape(RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous)
          .stroke(colors.borderHairline, lineWidth: 1)
      )
  }
}

// MARK: - 实时预览

/// 根据组件类型路由到对应的实时预览。
struct DemoComponentPreview: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  var body: some View {
    switch component.id {
    case .button:
      DemoButtonPreview(settings: $settings)
    case .iconButton:
      DemoIconButtonPreview(settings: $settings)
    case .textField:
      DemoTextFieldPreview(settings: $settings)
    case .switchControl:
      DemoSwitchPreview(settings: $settings)
    case .checkbox:
      DemoCheckboxPreview(settings: $settings)
    case .listRow:
      DemoListRowPreview(settings: $settings)
    case .card:
      DemoCardPreview(settings: $settings)
    case .badge:
      DemoBadgePreview()
    case .avatar:
      DemoAvatarPreview()
    case .icon:
      DemoIconPreview(settings: $settings)
    case .divider:
      DemoDividerPreview()
    case .listSection:
      DemoListSectionPreview()
    }
  }
}

private struct DemoButtonPreview: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  private var title: String {
    switch settings.buttonVariant {
    case .filled: return "提交任务"
    case .tonal: return "分享"
    case .glass: return "浮层操作"
    case .outline: return "继续"
    case .plain: return "了解更多"
    case .destructive: return "删除"
    }
  }

  private var leadingIcon: WDIconName? {
    switch settings.buttonVariant {
    case .filled: return .add
    case .tonal: return .share
    case .destructive: return .delete
    case .glass, .outline, .plain: return nil
    }
  }

  var body: some View {
    VStack(spacing: WDSpacing.s3) {
      WDButton(
        verbatim: title,
        variant: settings.buttonVariant,
        size: settings.buttonSize,
        isLoading: settings.buttonLoading,
        loadingAccessibilityText: Text(verbatim: "处理中"),
        leadingIcon: leadingIcon,
        action: { settings.buttonTapCount += 1 }
      )
      .disabled(settings.buttonDisabled)

      Text(verbatim: "轻触 \(settings.buttonTapCount) 次")
        .wdFont(WDType.caption1)
        .foregroundStyle(colors.textTertiary)
    }
  }
}

private struct DemoIconButtonPreview: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(spacing: WDSpacing.s3) {
      WDIconButton(
        icon: settings.iconButtonIcon,
        accessibilityLabel: Text(verbatim: "图标动作"),
        variant: settings.iconButtonVariant,
        size: settings.iconButtonSize,
        isLoading: settings.iconButtonLoading,
        action: { settings.iconButtonTapCount += 1 }
      )
      .disabled(settings.iconButtonDisabled)

      Text(verbatim: "轻触 \(settings.iconButtonTapCount) 次")
        .wdFont(WDType.caption1)
        .foregroundStyle(colors.textTertiary)
    }
  }
}

private struct DemoTextFieldPreview: View {
  @Binding var settings: DemoComponentSettings

  var body: some View {
    WDTextField(
      text: $settings.textFieldText,
      label: Text(verbatim: "任务名称"),
      appearance: appearance,
      isEditable: !settings.textFieldReadOnly
    )
  }

  private var appearance: WDTextFieldAppearance {
    var appearance = WDTextFieldAppearance()
    appearance.variant = settings.textFieldVariant
    appearance.placeholder = Text(verbatim: "例如：整理储物间")
    appearance.prefix = settings.textFieldPrefix.value()
    appearance.accessory = settings.textFieldAccessory.value(
      currentCount: settings.textFieldText.count
    )
    appearance.helper = settings.textFieldHelper.value()
    appearance.isSecure = settings.textFieldSecure
    return appearance
  }
}

private struct DemoSwitchPreview: View {
  @Binding var settings: DemoComponentSettings

  var body: some View {
    WDSwitch(isOn: $settings.switchOn, label: Text(verbatim: "共享给家人"))
  }
}

private struct DemoCheckboxPreview: View {
  @Binding var settings: DemoComponentSettings

  var body: some View {
    WDCheckbox(isChecked: $settings.checkboxChecked, label: Text(verbatim: "每日提醒"))
  }
}

private struct DemoListRowPreview: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(spacing: WDSpacing.s3) {
      DemoRowGroup {
        WDListRow(
          title: Text(verbatim: "整理储物间"),
          subtitle: Text(verbatim: "今天 18:00 前 · 家务"),
          leading: settings.rowLeading.value(),
          trailing: settings.rowTrailing.value(),
          isSelected: settings.rowSelected,
          showsSeparator: settings.rowShowsSeparator,
          action: settings.rowTappable ? { handleTap() } : nil
        )
      }

      Text(verbatim: settings.rowTappable ? "轻触 \(settings.rowTapCount) 次" : "未传 action：纯内容，不可点")
        .wdFont(WDType.caption1)
        .foregroundStyle(colors.textTertiary)
    }
  }

  private func handleTap() {
    settings.rowTapCount += 1
    if settings.rowLeading == .checkbox || settings.rowLeading == .selection {
      settings.rowSelected.toggle()
    }
  }
}

private struct DemoListSectionPreview: View {
  private struct Item: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
  }

  private let items = [
    Item(id: 1, title: "整理储物间", subtitle: "今天 18:00 前"),
    Item(id: 2, title: "擦窗", subtitle: "已完成"),
    Item(id: 3, title: "更换床单", subtitle: "明天"),
  ]

  var body: some View {
    DemoPreviewCanvas {
      WDListSection(items: items, selection: [2], header: Text(verbatim: "今天")) {
        item, context in
        WDListRow(
          title: Text(verbatim: item.title),
          subtitle: Text(verbatim: item.subtitle),
          leading: .icon(.task),
          isSelected: context.isSelected,
          showsSeparator: !context.isLast,
          action: {}
        )
      }
    }
  }
}

private struct DemoCardPreview: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    WDCard(style: settings.cardStyle) {
      VStack(alignment: .leading, spacing: WDSpacing.s3) {
        HStack(alignment: .firstTextBaseline, spacing: WDSpacing.s2) {
          Text(verbatim: "本周家务")
            .wdFont(WDType.headline)
            .foregroundStyle(colors.textPrimary)
          Spacer(minLength: 0)
          WDBadge(label: Text(verbatim: "进行中"))
        }
        Text(verbatim: "已完成 3 项，共 5 项")
          .wdFont(WDType.footnote)
          .foregroundStyle(colors.textSecondary)
        WDDivider()
        HStack(spacing: WDSpacing.s3) {
          WDIcon(icon: .task, size: .md)
            .foregroundStyle(colors.textBrand)
          VStack(alignment: .leading, spacing: WDSpacing.s1) {
            Text(verbatim: "整理储物间")
              .wdFont(WDType.subheadline)
              .foregroundStyle(colors.textPrimary)
            Text(verbatim: "今天 18:00 前")
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textSecondary)
          }
          Spacer(minLength: 0)
          Text(verbatim: "3 件")
            .wdFont(WDType.footnote)
            .foregroundStyle(colors.textSecondary)
        }
      }
    }
  }
}

private struct DemoBadgePreview: View {
  var body: some View {
    HStack(spacing: WDSpacing.s3) {
      WDBadge(label: Text(verbatim: "进行中"))
      WDBadge(label: Text(verbatim: "已完成"))
      WDBadge(label: Text(verbatim: "3 件"))
    }
  }
}

private struct DemoAvatarPreview: View {
  var body: some View {
    HStack(spacing: WDSpacing.s5) {
      WDAvatar(value: .init(icon: .profile))
      WDAvatar(value: .init(label: Text(verbatim: "妈")))
      WDAvatar(value: .init(label: Text(verbatim: "阿杰")))
    }
  }
}

private struct DemoIconPreview: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(spacing: WDSpacing.s3) {
      WDIcon(icon: settings.iconName, size: settings.iconSize)
        .foregroundStyle(colors.textBrand)
      Text(verbatim: settings.iconName.rawValue + " · " + settings.iconSize.demoTitle)
        .wdFont(WDType.caption1)
        .foregroundStyle(colors.textTertiary)
    }
  }
}

private struct DemoDividerPreview: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      Text(verbatim: "上方内容")
        .wdFont(WDType.subheadline)
        .foregroundStyle(colors.textSecondary)
      WDDivider()
      Text(verbatim: "下方内容")
        .wdFont(WDType.subheadline)
        .foregroundStyle(colors.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
