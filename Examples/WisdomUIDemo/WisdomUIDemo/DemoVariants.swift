import SwiftUI
import WisdomUI

// MARK: - 档位与形态

/// 详情页的档位一览。只展示当前组件真实存在的枚举档位。
struct DemoVariantsSection: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  @ViewBuilder var body: some View {
    switch component.id {
    case .button:
      DemoButtonVariants(settings: $settings)
    case .iconButton:
      DemoIconButtonVariants(settings: $settings)
    case .textField:
      DemoTextFieldVariants()
    case .card:
      DemoCardVariants()
    case .listRow:
      DemoListRowVariants(settings: $settings)
    case .badge:
      DemoBadgeVariants()
    case .avatar:
      DemoAvatarVariants()
    case .icon:
      DemoIconVariants(settings: $settings)
    case .divider:
      DemoDividerVariants()
    case .listSection:
      DemoListSectionVariants()
    case .switchControl, .checkbox:
      EmptyView()
    }
  }
}

/// 详情页的状态一览。没有额外状态的组件在这里不出现。
struct DemoStatesSection: View {
  let component: DemoComponentEntry
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  @ViewBuilder var body: some View {
    switch component.id {
    case .button:
      DemoSection("状态", subtitle: "加载态保留容器宽度；禁用态整体 40% 不透明度。") {
        HStack(spacing: WDSpacing.s3) {
          WDButton(
            verbatim: "提交",
            isLoading: true,
            loadingAccessibilityText: Text(verbatim: "处理中")
          ) {}
          WDButton(verbatim: "提交") {}
            .disabled(true)
        }
      }
    case .iconButton:
      DemoSection("状态", subtitle: "加载时用指示器替换图标，视觉宽度不变。") {
        HStack(spacing: WDSpacing.s4) {
          WDIconButton(
            icon: .add,
            accessibilityLabel: Text(verbatim: "新增"),
            isLoading: true
          ) {}
          WDIconButton(icon: .add, accessibilityLabel: Text(verbatim: "新增")) {}
            .disabled(true)
        }
      }
    case .textField:
      DemoSection("状态", subtitle: "禁用态 40%；只读态使用下沉底色，不属于 U6 六态。") {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          DemoTextFieldSample(
            title: "禁用",
            appearance: DemoTextFieldAppearance.make(
              variant: .inset, helper: .hint(Text(verbatim: "暂时不可编辑"))),
            disabled: true
          )
          DemoTextFieldSample(
            title: "只读",
            appearance: DemoTextFieldAppearance.make(variant: .inset, helper: .none),
            isEditable: false
          )
        }
      }
    case .switchControl:
      DemoSection("状态", subtitle: "开 / 关由系统 switch 角色朗读；禁用态保留整行布局。") {
        VStack(alignment: .leading, spacing: WDSpacing.s2) {
          WDSwitch(isOn: .constant(true), label: Text(verbatim: "开启"))
          WDSwitch(isOn: .constant(false), label: Text(verbatim: "关闭"))
          WDSwitch(isOn: .constant(true), label: Text(verbatim: "禁用"))
            .disabled(true)
        }
      }
    case .checkbox:
      DemoSection("状态", subtitle: "选中 / 未选中由系统朗读；勾是描边路径。") {
        VStack(alignment: .leading, spacing: WDSpacing.s2) {
          WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "已选中"))
          WDCheckbox(isChecked: .constant(false), label: Text(verbatim: "未选中"))
          WDCheckbox(isChecked: .constant(true), label: Text(verbatim: "禁用"))
            .disabled(true)
        }
      }
    case .listRow:
      DemoSection("状态", subtitle: "选中态显示左侧品牌条；action 为 nil 时不会获得按钮语义。") {
        VStack(alignment: .leading, spacing: WDSpacing.s4) {
          DemoRowGroup {
            VStack(spacing: 0) {
              WDListRow(title: Text(verbatim: "选中行"), isSelected: true)
              WDListRow(title: Text(verbatim: "未选中行"))
            }
          }
          DemoRowGroup {
            WDListRow(
              title: Text(verbatim: "静态行"),
              subtitle: Text(verbatim: "没有 action：纯内容"),
              showsSeparator: false
            )
          }
        }
      }
    case .card, .badge, .avatar, .icon, .divider, .listSection:
      EmptyView()
    }
  }
}

// MARK: - Button

private struct DemoButtonVariants: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("六种变体", subtitle: "同一个动作在不同层级里的视觉权重。") {
      VStack(spacing: WDSpacing.s3) {
        ForEach(WDButtonVariant.allCases, id: \.rawValue) { variant in
          HStack(spacing: WDSpacing.s3) {
            Text(verbatim: variant.demoTitle)
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textSecondary)
              .frame(width: 44, alignment: .leading)
            WDButton(verbatim: variant == .destructive ? "删除" : "提交", variant: variant) {}
            Spacer(minLength: 0)
          }
        }
      }
    }

    DemoSection("三档尺寸", subtitle: "当前变体在 32 / 44 / 52 三档高度下的表现。") {
      VStack(spacing: WDSpacing.s3) {
        ForEach(WDButtonSize.allCases, id: \.rawValue) { size in
          HStack(spacing: WDSpacing.s3) {
            Text(verbatim: size.demoTitle)
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textSecondary)
              .frame(width: 58, alignment: .leading)
            WDButton(verbatim: "提交", variant: settings.buttonVariant, size: size) {}
            Spacer(minLength: 0)
          }
        }
      }
    }
  }
}

// MARK: - IconButton

private struct DemoIconButtonVariants: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("三档尺寸", subtitle: "视觉尺寸 32 / 44 / 52，热区始终补到 44×44。") {
      VStack(spacing: WDSpacing.s3) {
        ForEach(WDButtonSize.allCases, id: \.rawValue) { size in
          HStack(spacing: WDSpacing.s3) {
            Text(verbatim: size.demoTitle)
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textSecondary)
              .frame(width: 58, alignment: .leading)
            WDIconButton(
              icon: settings.iconButtonIcon,
              accessibilityLabel: Text(verbatim: "图标动作"),
              size: size
            ) {}
            Spacer(minLength: 0)
          }
        }
        HStack(spacing: WDSpacing.s2) {
          DemoInfoPill(text: "变体：plain")
          DemoInfoPill(text: "冻结签名只有一档")
        }
      }
    }
  }
}

// MARK: - TextField

private struct DemoTextFieldVariants: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("三种形态", subtitle: "字段盒都是 46pt；形态只改变底色、描边与玻璃处理。") {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        ForEach(WDTextFieldVariant.allCases, id: \.rawValue) { variant in
          DemoTextFieldSample(
            title: variant.demoTitle + " · " + variant.rawValue,
            appearance: DemoTextFieldAppearance.make(
              variant: variant, helper: .hint(Text(verbatim: "辅助提示")))
          )
        }
      }
    }

    DemoSection("槽位组合", subtitle: "前缀、尾部附件与辅助文案可以自由组合。") {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        DemoTextFieldSample(
          title: "图标前缀 + 清除 + 提示",
          appearance: DemoTextFieldAppearance.make(
            variant: .inset,
            prefix: .icon(.search),
            accessory: .clear(accessibilityLabel: Text(verbatim: "清除")),
            helper: .hint(Text(verbatim: "搜索任务名称"))
          )
        )
        DemoTextFieldSample(
          title: "文本前缀 + 单位 + 错误",
          text: "12",
          appearance: DemoTextFieldAppearance.make(
            variant: .outline,
            prefix: .text(Text(verbatim: "¥")),
            accessory: .unit(Text(verbatim: "元")),
            helper: .error(Text(verbatim: "金额超出预算"))
          )
        )
        DemoTextFieldSample(
          title: "密文 + 显隐",
          text: "wisdom-2026",
          appearance: DemoTextFieldAppearance.make(
            variant: .glass,
            accessory: .reveal(
              hiddenAccessibilityLabel: Text(verbatim: "显示密码"),
              shownAccessibilityLabel: Text(verbatim: "隐藏密码")
            ),
            helper: .none,
            isSecure: true
          )
        )
      }
    }
  }
}

/// 独立的字段样例：每个样例有自己的文本状态，互不干扰。
private struct DemoTextFieldSample: View {
  let title: String
  let appearance: WDTextFieldAppearance
  let isEditable: Bool
  let disabled: Bool

  @State private var text: String

  @Environment(\.wdColors) private var colors

  init(
    title: String,
    text: String = "整理储物间",
    appearance: WDTextFieldAppearance,
    isEditable: Bool = true,
    disabled: Bool = false
  ) {
    self.title = title
    self.appearance = appearance
    self.isEditable = isEditable
    self.disabled = disabled
    _text = State(initialValue: text)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      Text(verbatim: title)
        .wdFont(WDType.caption1)
        .foregroundStyle(colors.textTertiary)
      WDTextField(
        text: $text,
        label: Text(verbatim: "任务名称"),
        appearance: appearance,
        isEditable: isEditable
      )
    }
  }
}

private enum DemoTextFieldAppearance {
  static func make(
    variant: WDTextFieldVariant,
    prefix: WDTextFieldPrefix = .none,
    accessory: WDTextFieldAccessory = .none,
    helper: WDTextFieldHelper = .none,
    isSecure: Bool = false
  ) -> WDTextFieldAppearance {
    var appearance = WDTextFieldAppearance()
    appearance.variant = variant
    appearance.placeholder = Text(verbatim: "输入任务名称")
    appearance.prefix = prefix
    appearance.accessory = accessory
    appearance.helper = helper
    appearance.isSecure = isSecure
    return appearance
  }
}

// MARK: - Card

private struct DemoCardVariants: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("三种外观", subtitle: "elevated 有阴影，outlined 只有描边，glass 在 iOS 26 上叠加系统玻璃。") {
      VStack(alignment: .leading, spacing: WDSpacing.s3) {
        ForEach(WDCardStyle.allCases, id: \.rawValue) { style in
          VStack(alignment: .leading, spacing: WDSpacing.s2) {
            Text(verbatim: style.demoTitle + " · " + style.rawValue)
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textTertiary)
            WDCard(style: style) {
              VStack(alignment: .leading, spacing: WDSpacing.s1) {
                Text(verbatim: "每周复盘")
                  .wdFont(WDType.headline)
                  .foregroundStyle(colors.textPrimary)
                Text(verbatim: "周日 20:00 · 家庭会议")
                  .wdFont(WDType.footnote)
                  .foregroundStyle(colors.textSecondary)
              }
            }
          }
        }
      }
    }
  }
}

// MARK: - ListRow

private struct DemoListRowVariants: View {
  @Binding var settings: DemoComponentSettings

  var body: some View {
    DemoSection("leading 槽位", subtitle: "行首 5 种组合；行高会随槽位内容派生。") {
      DemoRowGroup {
        VStack(spacing: 0) {
          ForEach(DemoListRowLeading.allCases) { leading in
            WDListRow(
              title: Text(verbatim: leading.title),
              subtitle: Text(verbatim: "leading = " + leading.rawValue),
              leading: leading.value(),
              trailing: .disclosure
            )
          }
        }
      }
    }

    DemoSection("trailing 槽位", subtitle: "行尾最多一个槽位；徽标和头像会进入三行 76 档。") {
      DemoRowGroup {
        VStack(spacing: 0) {
          ForEach(DemoListRowTrailing.allCases) { trailing in
            WDListRow(
              title: Text(verbatim: "整理储物间"),
              subtitle: Text(verbatim: "trailing = " + trailing.rawValue),
              leading: .icon(.task),
              trailing: trailing.value()
            )
          }
        }
      }
    }

    DemoSection("当前组合", subtitle: "把设置里的 leading / trailing 组合起来看实际效果。") {
      DemoRowGroup {
        WDListRow(
          title: Text(verbatim: "整理储物间"),
          subtitle: Text(verbatim: "今天 18:00 前 · 家务"),
          leading: settings.rowLeading.value(),
          trailing: settings.rowTrailing.value(),
          isSelected: settings.rowSelected,
          showsSeparator: settings.rowShowsSeparator
        )
      }
    }
  }
}

// MARK: - ListSection

private struct DemoListSectionItem: Identifiable {
  let id: Int
  let title: String
  let subtitle: String
}

private struct DemoListSectionVariants: View {
  @Environment(\.wdColors) private var colors

  private let items = [
    DemoListSectionItem(id: 1, title: "整理储物间", subtitle: "今天 18:00 前"),
    DemoListSectionItem(id: 2, title: "擦窗", subtitle: "已完成"),
    DemoListSectionItem(id: 3, title: "更换床单", subtitle: "明天"),
  ]

  var body: some View {
    VStack(spacing: WDSpacing.s6) {
      DemoSection("标准分组", subtitle: "标题 + 一个内容卡片；选中集合由 WDListSection 转成行上下文。") {
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

      DemoSection(
        "标题动作与页脚",
        subtitle: "标题右侧最多一个动作；页脚 footnote 由组件施加，样式不必调用方重复。"
      ) {
        WDListSection(
          items: items,
          header: Text(verbatim: "本周"),
          headerAction: .init(label: Text(verbatim: "编辑"), action: {})
        ) { item, context in
          WDListRow(
            title: Text(verbatim: item.title),
            subtitle: Text(verbatim: item.subtitle),
            leading: .icon(.task),
            isSelected: context.isSelected,
            showsSeparator: !context.isLast,
            action: {}
          )
        } footer: {
          Text(verbatim: "共 3 项，已完成 1 项")
        }
      }

      DemoSection("空分组", subtitle: "空 items 是唯一判据：整组隐藏，不出现空标题或空页脚。") {
        VStack(alignment: .leading, spacing: WDSpacing.s3) {
          WDListSection(items: [DemoListSectionItem](), header: Text(verbatim: "空组")) { _, _ in
            EmptyView()
          }
          Text(verbatim: "上面这个分组什么都不渲染（连标题也不出现）。")
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textTertiary)
        }
      }
    }
  }
}

// MARK: - Badge

private struct DemoBadgeVariants: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("状态胶囊", subtitle: "当前签名只提供中性色；文案完全由调用方给。") {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(spacing: WDSpacing.s2) {
          WDBadge(label: Text(verbatim: "进行中"))
          WDBadge(label: Text(verbatim: "已完成"))
          WDBadge(label: Text(verbatim: "3 件"))
        }
        DemoRowGroup {
          WDListRow(
            title: Text(verbatim: "妈妈的待办"),
            subtitle: Text(verbatim: "已完成 2 项"),
            leading: .avatar(.init(label: Text(verbatim: "妈"))),
            trailing: .badge(.init(label: Text(verbatim: "进行中")))
          )
        }
        Text(verbatim: "徽标是装饰件，不进入无障碍焦点序列。")
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textTertiary)
      }
    }
  }
}

// MARK: - Avatar

private struct DemoAvatarVariants: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("两种载荷", subtitle: "icon 占位与 label 首字/姓名；直径固定为 md 32。") {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        HStack(alignment: .top, spacing: WDSpacing.s5) {
          VStack(spacing: WDSpacing.s2) {
            WDAvatar(value: .init(icon: .profile))
            Text(verbatim: "icon")
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textTertiary)
          }
          VStack(spacing: WDSpacing.s2) {
            WDAvatar(value: .init(label: Text(verbatim: "妈")))
            Text(verbatim: "单字")
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textTertiary)
          }
          VStack(spacing: WDSpacing.s2) {
            WDAvatar(value: .init(label: Text(verbatim: "阿杰")))
            Text(verbatim: "姓名")
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textTertiary)
          }
        }
        DemoRowGroup {
          WDListRow(
            title: Text(verbatim: "家庭成员"),
            subtitle: Text(verbatim: "3 位成员"),
            leading: .avatar(.init(label: Text(verbatim: "妈"))),
            trailing: .disclosure
          )
        }
      }
    }
  }
}

// MARK: - Icon

private struct DemoIconVariants: View {
  @Binding var settings: DemoComponentSettings

  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("四档尺寸", subtitle: "图标尺寸锁死，不随动态字体放大。") {
      HStack(alignment: .bottom, spacing: WDSpacing.s5) {
        ForEach(WDIconSize.allCases, id: \.rawValue) { size in
          VStack(spacing: WDSpacing.s2) {
            WDIcon(icon: settings.iconName, size: size)
              .foregroundStyle(colors.textBrand)
            Text(verbatim: size.demoTitle)
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textTertiary)
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
  }
}

// MARK: - Divider

private struct DemoDividerVariants: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    DemoSection("使用上下文", subtitle: "全宽 hairline；列表行内部另有一条从文本区起始内缩的分隔线。") {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        VStack(alignment: .leading, spacing: WDSpacing.s2) {
          Text(verbatim: "上方分组")
            .wdFont(WDType.subheadline)
            .foregroundStyle(colors.textSecondary)
          WDDivider()
          Text(verbatim: "下方分组")
            .wdFont(WDType.subheadline)
            .foregroundStyle(colors.textSecondary)
        }
        DemoRowGroup {
          VStack(spacing: 0) {
            WDListRow(
              title: Text(verbatim: "整理储物间"),
              leading: .icon(.task),
              trailing: .value(Text(verbatim: "3 件"))
            )
            WDListRow(
              title: Text(verbatim: "洗车"),
              leading: .icon(.travel),
              trailing: .value(Text(verbatim: "1 件"))
            )
          }
        }
      }
    }
  }
}
