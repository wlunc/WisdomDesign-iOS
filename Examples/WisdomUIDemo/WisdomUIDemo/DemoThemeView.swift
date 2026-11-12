import SwiftUI
import WisdomUI

/// 主题与令牌页：保留 M1 的运行时 scheme 切换、字阶/槽位画廊，以及 M2 的无障碍审计入口。
struct DemoThemeView: View {
  @Binding var scheme: String

  @Environment(\.wdColors) private var colors

  private let launchCount = UserDefaults.standard.integer(forKey: "wd.demo.launchCount")

  private var theme: WDTheme {
    WDTheme.named(scheme) ?? .default
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        schemeCard
        auditLink
        DemoTypeRoster()
        DemoSlotRoster(colors: theme.colors)
      }
      .padding(.horizontal, WDSpacing.s5)
      .padding(.top, WDSpacing.s2)
      .padding(.bottom, WDSpacing.s8)
      .frame(maxWidth: 720)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .background(colors.bgCanvas.ignoresSafeArea())
    .navigationTitle(Text(verbatim: "主题与令牌"))
    .navigationBarTitleDisplayMode(.inline)
  }

  private var schemeCard: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      VStack(alignment: .leading, spacing: WDSpacing.s1) {
        Text(verbatim: "运行时 scheme")
          .wdFont(WDType.title3)
          .foregroundStyle(colors.textPrimary)
        Text(verbatim: "切换的是已经生成的 light / dark；值变化触发重算，不重启进程。")
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Picker("Scheme", selection: $scheme) {
        ForEach(WDColorValues.wdSchemeNames, id: \.self) { name in
          Text(verbatim: name).tag(name)
        }
      }
      .pickerStyle(.segmented)
      .accessibilityIdentifier("scheme-picker")

      HStack(spacing: WDSpacing.s3) {
        VStack(alignment: .leading, spacing: 0) {
          Text(verbatim: "scheme")
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textTertiary)
          Text(verbatim: theme.scheme)
            .wdFont(WDType.footnote)
            .foregroundStyle(colors.textPrimary)
            .accessibilityIdentifier("scheme-label")
            .accessibilityValue(theme.scheme)
        }
        Spacer(minLength: 0)
        VStack(alignment: .trailing, spacing: 0) {
          Text(verbatim: "launches")
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textTertiary)
          Text(verbatim: "\(launchCount)")
            .wdFont(WDType.footnote)
            .foregroundStyle(colors.textPrimary)
            .accessibilityIdentifier("launch-count")
            .accessibilityValue(String(launchCount))
        }
      }
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

  private var auditLink: some View {
    NavigationLink {
      DemoAuditViewport()
    } label: {
      HStack(spacing: WDSpacing.s4) {
        ZStack {
          RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
            .fill(colors.surfaceTint)
            .frame(width: 42, height: 42)
          WDIcon(icon: .search, size: .md)
            .foregroundStyle(colors.textOnSoft)
        }
        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          Text(verbatim: "无障碍审计视口")
            .wdFont(WDType.headline)
            .foregroundStyle(colors.textPrimary)
          Text(verbatim: "M2/M3/M4 的 21 件组件；4 件弹层从组件详情页打开，其余实例在这里审计。")
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        WDIcon(icon: .disclose, size: .sm)
          .foregroundStyle(colors.textTertiary)
      }
      .padding(WDSpacing.s4)
      .background(
        RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
          .fill(colors.surfaceCard)
      )
      .overlay(
        RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
          .stroke(colors.borderHairline, lineWidth: 1)
      )
      .contentShape(RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("audit-viewport-link")
  }
}

// MARK: - 无障碍审计视口（M2 交付物，nightly 依赖）

/// 组件无障碍审计视口：M2/M3/M4 的组件各放一个代表性实例（弹层从详情页打开）。
///
/// 这个页面刻意保持“全部实例在一屏”的旧形态：nightly 的 4 类目审计需要一个稳定、
/// 可复现的覆盖范围。它从主题页进入，不再占用主列表。
struct DemoAuditViewport: View {
  @Environment(\.wdColors) private var colors

  @State private var text = "整理储物间"
  @State private var switchOn = true
  @State private var checked = true

  private struct AuditSectionItem: Identifiable {
    let id: Int
    let title: String
  }

  private let auditSectionItems = [
    AuditSectionItem(id: 1, title: "整理储物间"),
    AuditSectionItem(id: 2, title: "洗车"),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        WDCard(style: .elevated) {
          VStack(alignment: .leading, spacing: WDSpacing.s4) {
            WDTextField(
              text: $text,
              label: Text(verbatim: "任务名称"),
              appearance: .init(helper: .error(Text(verbatim: "名称已被占用")))
            )
            WDListRow(
              title: Text(verbatim: "整理储物间"),
              subtitle: Text(verbatim: "今天 18:00 前"),
              leading: .icon(.task),
              trailing: .value(Text(verbatim: "3 件")),
              action: {}
            )
            WDListRow(
              title: Text(verbatim: "妈妈的待办"),
              subtitle: Text(verbatim: "已完成 2 项"),
              leading: .avatar(.init(label: Text(verbatim: "妈"))),
              trailing: .badge(.init(label: Text(verbatim: "进行中")))
            )
            WDListRow(
              title: Text(verbatim: "每天八杯水"),
              leading: .checkbox,
              isSelected: true,
              action: {}
            )
          }
        }

        WDListSection(
          items: auditSectionItems,
          header: Text(verbatim: "本周"),
          headerAction: .init(label: Text(verbatim: "编辑"), action: {})
        ) { item, context in
          WDListRow(
            title: Text(verbatim: item.title),
            showsSeparator: !context.isLast,
            action: {}
          )
        } footer: {
          Text(verbatim: "共 2 项")
        }

        HStack(spacing: WDSpacing.s3) {
          WDButton(verbatim: "提交") {}
          WDButton(verbatim: "分享", variant: .tonal) {}
          WDButton(verbatim: "删除", variant: .destructive) {}
        }

        HStack(spacing: WDSpacing.s3) {
          WDIconButton(icon: .search, accessibilityLabel: Text(verbatim: "搜索")) {}
          WDIconButton(icon: .add, accessibilityLabel: Text(verbatim: "新增"), size: .sm) {}
        }

        WDSwitch(isOn: $switchOn, label: Text(verbatim: "共享给家人"))
        WDCheckbox(isChecked: $checked, label: Text(verbatim: "每日提醒"))

        HStack(spacing: WDSpacing.s3) {
          WDBadge(label: Text(verbatim: "已完成"))
          WDAvatar(value: .init(label: Text(verbatim: "妈")))
          WDIcon(icon: .home, size: .lg)
        }

        WDDivider()

        WDProgressBar(value: 0.45, label: Text(verbatim: "上传进度"), valueText: Text(verbatim: "45%"))

        HStack(alignment: .top, spacing: WDSpacing.s5) {
          WDProgressRing(value: 0.6, label: Text(verbatim: "本周"), valueText: Text(verbatim: "3/5"))
          WDProgressRing(value: 0.45, size: .compact, label: Text(verbatim: "紧凑"))
        }

        WDBanner(
          isVisible: .constant(true),
          variant: .info,
          message: Text(verbatim: "已同步到家庭空间")
        )

        WDEmptyState(
          icon: .task,
          title: Text(verbatim: "还没有任务"),
          message: Text(verbatim: "新建后在这里显示。")
        )

        WDSkeleton(variant: .text, lineCount: 3, accessibilityLabel: Text(verbatim: "加载中"))
      }
      .padding(WDSpacing.s4)
      .frame(maxWidth: 720)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .background(colors.bgCanvas.ignoresSafeArea())
    .navigationTitle(Text(verbatim: "无障碍审计视口"))
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - 字阶与槽位画廊

/// 12 条字阶的展示（走唯一的字体入口 wdFont + 行盒 wdLineBox）。
private struct DemoTypeRoster: View {
  private static let styles: [(String, WDTextStyle)] = [
    ("largeTitle", WDType.largeTitle),
    ("title1", WDType.title1),
    ("title2", WDType.title2),
    ("title3", WDType.title3),
    ("headline", WDType.headline),
    ("body", WDType.body),
    ("callout", WDType.callout),
    ("subheadline", WDType.subheadline),
    ("footnote", WDType.footnote),
    ("caption1", WDType.caption1),
    ("caption2", WDType.caption2),
    ("overline", WDType.overline),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      Text(verbatim: "Typography")
        .wdFont(WDType.title2)
        .wdLineBox(WDType.title2)
      ForEach(Array(Self.styles.enumerated()), id: \.offset) { _, item in
        VStack(alignment: .leading, spacing: WDSpacing.s1) {
          Text(verbatim: item.0)
            .wdFont(WDType.caption1)
            .wdLineBox(WDType.caption1)
          Text(verbatim: "示例文本一二三")
            .wdFont(item.1)
            .wdLineBox(item.1)
          Text(verbatim: "Sample text")
            .wdFont(item.1)
            .wdLineBox(item.1)
        }
      }
    }
  }
}

/// 32 个语义槽位的展示（值来自当前主题，不是静态常量）。
private struct DemoSlotRoster: View {
  let colors: WDColorValues

  private static let slots: [(String, KeyPath<WDColorValues, Color>)] = [
    ("bg.canvas", \.bgCanvas), ("bg.grouped", \.bgGrouped),
    ("surface.card", \.surfaceCard), ("surface.card-solid", \.surfaceCardSolid),
    ("surface.card-sunken", \.surfaceCardSunken), ("surface.tint", \.surfaceTint),
    ("surface.glass", \.surfaceGlass), ("surface.glass-strong", \.surfaceGlassStrong),
    ("text.primary", \.textPrimary), ("text.secondary", \.textSecondary),
    ("text.tertiary", \.textTertiary), ("text.disabled", \.textDisabled),
    ("text.on-light-primary", \.textOnLightPrimary),
    ("text.on-light-secondary", \.textOnLightSecondary),
    ("text.on-light-tertiary", \.textOnLightTertiary), ("text.on-soft", \.textOnSoft),
    ("text.on-fill", \.textOnFill), ("text.on-dark", \.textOnDark),
    ("text.brand", \.textBrand), ("border.hairline", \.borderHairline),
    ("border.hairline-strong", \.borderHairlineStrong), ("border.glass-top", \.borderGlassTop),
    ("fill.field", \.fillField), ("fill.pressed", \.fillPressed),
    ("status.success", \.statusSuccess), ("status.info", \.statusInfo),
    ("status.warning", \.statusWarning), ("status.danger", \.statusDanger),
    ("status.soft-success", \.statusSoftSuccess), ("status.soft-info", \.statusSoftInfo),
    ("status.soft-warning", \.statusSoftWarning), ("status.soft-danger", \.statusSoftDanger),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      Text(verbatim: "Color slots")
        .wdFont(WDType.title2)
        .wdLineBox(WDType.title2)
      ForEach(Array(Self.slots.enumerated()), id: \.offset) { _, item in
        HStack(spacing: WDSpacing.s2) {
          RoundedRectangle(cornerRadius: WDRadius.xs)
            .fill(colors[keyPath: item.1])
            .frame(width: WDSpacing.s6, height: WDSpacing.s6)
          Text(verbatim: item.0)
            .wdFont(WDType.caption2)
            .wdLineBox(WDType.caption2)
        }
      }
    }
  }
}
