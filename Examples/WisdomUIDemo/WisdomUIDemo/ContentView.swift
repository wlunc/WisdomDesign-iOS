import SwiftUI
import WisdomUI

/// demo 根视图：**运行时 scheme 切换**（M1 交付物 / M1 出口④）。
///
/// 切换的是**已生成**的那几套 scheme（`WDColorValues.wdSchemeNames`）；值变更触发依赖该值的视图
/// 重算/重组，**不重启进程**（F-05）。`@State` 只存 scheme 名，主题本身是派生值 —— 与库里
/// 「`wdColors` 是 `wdTheme.colors` 的只读派生（不存第二份）」的口径一致。
///
/// **注意**：demo **不能** import `WisdomUIPreviews`（画廊在预览 target 里）——包只发布一个 product
/// `WisdomUI`（F-10），外部 Xcode 工程看不到未进 `products` 的 target。所以 demo 自己搭展示内容。
struct DemoRootView: View {
  /// 页签（**不用 TabView**：iOS 26 的浮动玻璃 Tab 栏会压住滚动内容，
  /// 让 `performAccessibilityAudit` 把"压在栏下的文字"判成对比度不达标）。
  private enum Page: String, CaseIterable, Hashable {
    case theme
    case components
  }

  @State private var scheme = WDColorValues.wdDefaultScheme
  @State private var page = Page.theme

  private let launchCount = UserDefaults.standard.integer(forKey: "wd.demo.launchCount")

  private var theme: WDTheme {
    WDTheme.named(scheme) ?? .default
  }

  var body: some View {
    VStack(spacing: WDSpacing.s3) {
      Picker("Page", selection: $page) {
        ForEach(Page.allCases, id: \.self) { page in
          Text(verbatim: page == .theme ? "主题" : "组件").tag(page)
        }
      }
      .pickerStyle(.segmented)
      .accessibilityIdentifier("page-picker")

      switch page {
      case .theme: themeTab
      case .components: DemoComponentsView(colors: theme.colors)
      }
    }
    .wdTheme(theme)
    .foregroundStyle(theme.colors.textPrimary)
    .background(theme.colors.bgCanvas)
  }

  /// 主题页：运行时 scheme 切换 + 字阶/槽位画廊（M1 交付物）。
  private var themeTab: some View {
    VStack(spacing: WDSpacing.s3) {
      Picker("Scheme", selection: $scheme) {
        ForEach(WDColorValues.wdSchemeNames, id: \.self) { name in
          Text(verbatim: name).tag(name)
        }
      }
      .pickerStyle(.segmented)
      .accessibilityIdentifier("scheme-picker")

      // UI 测试的观测点：切 scheme 后这里必须变，且**不重启进程**。
      Text(verbatim: theme.scheme)
        .wdFont(WDType.footnote)
        .accessibilityIdentifier("scheme-label")
        .accessibilityValue(theme.scheme)

      // 「不重启进程」的观测点：进程重启会让这个数变大。
      //
      // 字号用 footnote（13pt）而不是 caption2（11pt）：**系统无障碍审计把 11pt 文本判为
      // "Dynamic Type unsupported"** —— 实测连纯 SwiftUI 的 .font(.caption2) 也一样被报，与 wdFont
      // 无关（阶梯对照结论见 DEV-PLAN §8.1 的登记项）。审计视口内避免 11pt 即可，不必开例外。
      Text(verbatim: "launches: \(launchCount)")
        .wdFont(WDType.footnote)
        .accessibilityIdentifier("launch-count")
        .accessibilityValue(String(launchCount))

      ScrollView {
        VStack(alignment: .leading, spacing: WDSpacing.s6) {
          DemoTypeRoster()
          DemoSlotRoster(colors: theme.colors)
        }
        .padding(WDSpacing.s4)
      }
    }
  }
}

/// 组件页：**M2 无障碍审计视口**（nightly-2 的 4 类目审计走这里）。
///
/// 11 件各放一个代表性实例（全部带语义标签；装饰件按组件自身规则不进树）。
/// 固定字号组件（`WDBadge` 11pt / `WDAvatar` 12pt 首字）属设计例外，审计口径见
/// `docs/M2-EXIT-REPORT.md` §4-②。
struct DemoComponentsView: View {
  let colors: WDColorValues

  @State private var text = "整理储物间"
  @State private var switchOn = true
  @State private var checked = true

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
      }
      .padding(WDSpacing.s4)
    }
    .background(colors.bgCanvas)
  }
}

/// 12 条字阶的展示（走唯一的字体入口 `wdFont` + 行盒 `wdLineBox`）。
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

/// 32 个语义槽位的展示（值来自当前主题，不是静态常量 —— R10）。
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
