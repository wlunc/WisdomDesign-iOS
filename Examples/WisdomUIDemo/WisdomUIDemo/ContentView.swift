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
  @State private var scheme = WDColorValues.wdDefaultScheme

  private let launchCount = UserDefaults.standard.integer(forKey: "wd.demo.launchCount")

  private var theme: WDTheme {
    WDTheme.named(scheme) ?? .default
  }

  var body: some View {
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
    .foregroundStyle(theme.colors.textPrimary)
    .wdTheme(theme)
    .background(theme.colors.bgCanvas)
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
