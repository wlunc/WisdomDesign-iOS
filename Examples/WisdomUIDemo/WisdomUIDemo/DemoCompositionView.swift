import SwiftUI
import WisdomUI

// MARK: - 组合场景：容器 + 组件

/// 卡片容器：WDCard 里组合头像、徽章、进度、开关、列表与按钮。
struct DemoCardCompositionView: View {
  @State private var styleRaw = WDCardStyle.elevated.rawValue
  @State private var reminder = true
  @State private var autoArchive = false
  @State private var inFamily = true

  @Environment(\.wdColors) private var colors

  private var style: WDCardStyle {
    WDCardStyle(rawValue: styleRaw) ?? .elevated
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        DemoCompositionHeader(
          icon: .sort,
          title: "卡片容器",
          subtitle: "WDCard 是容器：同一张卡里可以组合头像、徽章、进度、开关、列表行和按钮。",
          tags: ["WDCard", "WDListSection", "WDProgressBar", "WDSwitch", "WDButton"]
        )

        DemoSection("任务摘要卡", subtitle: "WDCard + Avatar / Badge / Progress / Divider / Button") {
          VStack(spacing: WDSpacing.s3) {
            Picker("卡片样式", selection: $styleRaw) {
              ForEach(WDCardStyle.allCases, id: \.rawValue) { cardStyle in
                Text(verbatim: cardStyle.demoTitle).tag(cardStyle.rawValue)
              }
            }
            .pickerStyle(.segmented)

            DemoPreviewCanvas {
              WDCard(style: style) {
                VStack(alignment: .leading, spacing: WDSpacing.s4) {
                  HStack(spacing: WDSpacing.s3) {
                    WDAvatar(value: .init(label: Text(verbatim: "妈")))
                    VStack(alignment: .leading, spacing: WDSpacing.s1) {
                      Text(verbatim: "本周家务")
                        .wdFont(WDType.headline)
                        .foregroundStyle(colors.textPrimary)
                      Text(verbatim: "已完成 3 项，共 5 项")
                        .wdFont(WDType.footnote)
                        .foregroundStyle(colors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    WDBadge(label: Text(verbatim: "进行中"))
                    WDIconButton(
                      icon: .more,
                      accessibilityLabel: Text(verbatim: "更多家务操作"),
                      size: .sm
                    ) {}
                  }

                  WDProgressBar(
                    value: 0.6,
                    label: Text(verbatim: "完成度"),
                    valueText: Text(verbatim: "3/5")
                  )

                  WDDivider()

                  HStack(spacing: WDSpacing.s3) {
                    WDIcon(icon: .calendar, size: .sm)
                      .foregroundStyle(colors.textTertiary)
                    Text(verbatim: "今天 18:00 前")
                      .wdFont(WDType.subheadline)
                      .foregroundStyle(colors.textSecondary)
                    Spacer(minLength: 0)
                    Text(verbatim: "2 件")
                      .wdFont(WDType.footnote)
                      .foregroundStyle(colors.textSecondary)
                  }

                  HStack(spacing: WDSpacing.s3) {
                    WDButton(verbatim: "添加任务", variant: .tonal, size: .sm) {}
                    WDButton(verbatim: "查看全部", variant: .plain, size: .sm) {}
                  }
                }
              }
            }
          }
        }

        DemoSection("设置卡片", subtitle: "WDCard + WDSwitch / WDCheckbox / WDBadge") {
          DemoPreviewCanvas {
            WDCard(style: .outlined) {
              VStack(alignment: .leading, spacing: WDSpacing.s4) {
                HStack(spacing: WDSpacing.s3) {
                  Text(verbatim: "提醒设置")
                    .wdFont(WDType.headline)
                    .foregroundStyle(colors.textPrimary)
                  Spacer(minLength: 0)
                  WDBadge(label: Text(verbatim: "已开启"))
                }

                WDSwitch(isOn: $reminder, label: Text(verbatim: "每日提醒"))
                WDSwitch(isOn: $autoArchive, label: Text(verbatim: "完成后自动归档"))
                WDCheckbox(isChecked: $inFamily, label: Text(verbatim: "加入家庭空间"))

                WDDivider()

                HStack(spacing: WDSpacing.s3) {
                  WDIcon(icon: .synced, size: .sm)
                    .foregroundStyle(colors.textTertiary)
                  Text(verbatim: "离线也可编辑，联网后自动同步")
                    .wdFont(WDType.caption1)
                    .foregroundStyle(colors.textSecondary)
                  Spacer(minLength: 0)
                  WDBadge(label: Text(verbatim: "已同步"))
                }
              }
            }
          }
        }

        DemoSection("嵌套列表卡", subtitle: "WDCard 里再放 WDListSection / WDListRow") {
          DemoPreviewCanvas {
            WDCard(style: .elevated) {
              WDListSection(
                items: DemoCompositionTask.items,
                selection: [],
                header: Text(verbatim: "今天的任务")
              ) { item, context in
                WDListRow(
                  title: Text(verbatim: item.title),
                  subtitle: Text(verbatim: item.subtitle),
                  leading: .icon(item.icon),
                  isSelected: context.isSelected,
                  showsSeparator: !context.isLast,
                  action: {}
                )
              }
            }
          }
        }

        DemoSection("组合要点", subtitle: "容器只负责边界与节奏，内部组件保持自己的语义。") {
          VStack(alignment: .leading, spacing: WDSpacing.s3) {
            ForEach(DemoCompositionTask.cardNotes, id: \.self) { note in
              DemoCompositionBullet(text: note)
            }
          }
        }
      }
      .padding(.horizontal, WDSpacing.s5)
      .padding(.top, WDSpacing.s2)
      .padding(.bottom, WDSpacing.s8)
    }
    .background(colors.bgCanvas.ignoresSafeArea())
    .navigationTitle(Text(verbatim: "卡片容器"))
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// 底部面板容器：面板里组合输入框、卡片、开关、进度与固定页脚。
struct DemoBottomSheetCompositionView: View {
  @State private var shown = false
  @State private var taskTitle = "整理储物间"
  @State private var reminder = true
  @State private var inFamily = true

  @Environment(\.wdColors) private var colors

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        DemoCompositionHeader(
          icon: .expand,
          title: "底部面板容器",
          subtitle: "WDBottomSheet 是容器：面板里可以继续放 Card、TextField、Switch、Progress 和固定页脚。",
          tags: ["WDBottomSheet", "WDCard", "WDTextField", "WDSwitch", "WDButton"]
        )

        DemoSection("组合面板", subtitle: "点按钮打开：输入框 + 卡片 + 开关 + 进度 + 页脚") {
          DemoPreviewCanvas {
            VStack(spacing: WDSpacing.s4) {
              WDButton(verbatim: "打开组合面板") { shown = true }
              HStack(spacing: WDSpacing.s2) {
                WDBadge(label: Text(verbatim: "表单"))
                WDBadge(label: Text(verbatim: "嵌套卡片"))
                WDBadge(label: Text(verbatim: "固定页脚"))
              }
              Text(verbatim: "面板打开后，可以试试点输入框：键盘会把面板整体上移。")
                .wdFont(WDType.footnote)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
          }
        }

        DemoSection("面板里的层级", subtitle: "面板容器 → 内容 → 卡片容器 → 行/开关") {
          VStack(alignment: .leading, spacing: WDSpacing.s3) {
            DemoCompositionBullet(text: "WDBottomSheet：标题、滚动内容、固定页脚")
            DemoCompositionBullet(text: "WDCard：任务信息与提醒开关的二级分组")
            DemoCompositionBullet(text: "WDTextField / WDSwitch / WDCheckbox：表单输入")
            DemoCompositionBullet(text: "WDProgressBar：面板内的状态反馈")
            DemoCompositionBullet(text: "WDButton：页脚主次操作，右对齐")
          }
        }
      }
      .padding(.horizontal, WDSpacing.s5)
      .padding(.top, WDSpacing.s2)
      .padding(.bottom, WDSpacing.s8)
    }
    .background(colors.bgCanvas.ignoresSafeArea())
    .navigationTitle(Text(verbatim: "底部面板容器"))
    .navigationBarTitleDisplayMode(.inline)
    .wdSheet(
      isPresented: $shown,
      detents: .all,
      initialDetent: .half,
      title: Text(verbatim: "新建任务"),
      closeButtonAccessibilityLabel: Text(verbatim: "关闭新建任务")
    ) {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDTextField(text: $taskTitle, label: Text(verbatim: "任务名称"))

        WDCard(style: .outlined) {
          VStack(alignment: .leading, spacing: WDSpacing.s3) {
            HStack(spacing: WDSpacing.s3) {
              WDIcon(icon: .calendar, size: .sm)
                .foregroundStyle(colors.textTertiary)
              Text(verbatim: "今天 18:00 前")
                .wdFont(WDType.subheadline)
                .foregroundStyle(colors.textSecondary)
              Spacer(minLength: 0)
              WDBadge(label: Text(verbatim: "提醒"))
            }

            WDDivider()
            WDSwitch(isOn: $reminder, label: Text(verbatim: "到时提醒"))
            WDCheckbox(isChecked: $inFamily, label: Text(verbatim: "加入家庭空间"))
          }
        }

        HStack(spacing: WDSpacing.s2) {
          WDBadge(label: Text(verbatim: "家务"))
          WDBadge(label: Text(verbatim: "中等"))
          WDBadge(label: Text(verbatim: "今天"))
        }

        WDProgressBar(
          value: 0.6,
          label: Text(verbatim: "本周完成度"),
          valueText: Text(verbatim: "3/5")
        )

        WDListSection(
          items: DemoCompositionTask.subtasks,
          selection: [],
          header: Text(verbatim: "子任务")
        ) { item, context in
          WDListRow(
            title: Text(verbatim: item.title),
            subtitle: Text(verbatim: item.subtitle),
            leading: .icon(item.icon),
            isSelected: context.isSelected,
            showsSeparator: !context.isLast,
            action: {}
          )
        }
      }
    } footer: {
      HStack(spacing: WDSpacing.s3) {
        WDButton(verbatim: "取消", variant: .outline) { shown = false }
        WDButton(verbatim: "创建", variant: .filled) { shown = false }
      }
    }
  }
}

// MARK: - 组合页通用件

private struct DemoCompositionHeader: View {
  let icon: WDIconName
  let title: String
  let subtitle: String
  let tags: [String]

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      HStack(alignment: .center, spacing: WDSpacing.s4) {
        ZStack {
          RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
            .fill(WDGradient.surface.linearGradient)
            .frame(width: 56, height: 56)
          WDIcon(icon: icon, size: .lg)
            .foregroundStyle(colors.textOnSoft)
        }

        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          Text(verbatim: title)
            .wdFont(WDType.title2)
            .foregroundStyle(colors.textPrimary)
          Text(verbatim: "组合场景 · 容器")
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textSecondary)
        }
        Spacer(minLength: 0)
      }

      Text(verbatim: subtitle)
        .wdFont(WDType.body)
        .foregroundStyle(colors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: WDSpacing.s2) {
          ForEach(tags, id: \.self) { tag in
            DemoInfoPill(text: tag)
              .fixedSize()
          }
        }
      }
    }
  }
}

private struct DemoCompositionBullet: View {
  let text: String

  @Environment(\.wdColors) private var colors

  var body: some View {
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
}

private struct DemoCompositionTask: Identifiable, Hashable {
  let id: Int
  let title: String
  let subtitle: String
  let icon: WDIconName

  static let items: [DemoCompositionTask] = [
    .init(id: 1, title: "整理储物间", subtitle: "今天 18:00 前", icon: .task),
    .init(id: 2, title: "擦窗", subtitle: "已完成", icon: .chore),
    .init(id: 3, title: "更换床单", subtitle: "明天", icon: .chore),
  ]

  static let subtasks: [DemoCompositionTask] = [
    .init(id: 11, title: "擦拭台面", subtitle: "厨房", icon: .chore),
    .init(id: 12, title: "清理冰箱", subtitle: "厨房", icon: .chore),
    .init(id: 13, title: "倒垃圾", subtitle: "今天", icon: .chore),
    .init(id: 14, title: "洗窗帘", subtitle: "周末", icon: .chore),
    .init(id: 15, title: "整理鞋柜", subtitle: "玄关", icon: .chore),
    .init(id: 16, title: "给植物浇水", subtitle: "阳台", icon: .plant),
  ]

  static let cardNotes: [String] = [
    "卡片自身负责背景、圆角、描边与阴影；内部保留组件的行高与触控热区。",
    "列表放在卡片里时，仍由 WDListSection 处理分组标题与末行分隔线。",
    "进度、徽章、开关是并列语义，不改变卡片的容器角色。",
  ]
}
