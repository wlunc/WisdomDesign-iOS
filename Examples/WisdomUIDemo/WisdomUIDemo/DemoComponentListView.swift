import SwiftUI
import WisdomUI

/// 根列表：按类别浏览已实现的组件。点击任意一行进入详情页。
struct DemoComponentListView: View {
  @Binding var scheme: String

  @Environment(\.wdColors) private var colors

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s6) {
        DemoCatalogHero()

        ForEach(DemoComponentCategory.allCases) { category in
          let entries = DemoComponentCatalog.entries(in: category)
          if !entries.isEmpty {
            DemoCategorySection(category: category, entries: entries)
          }
        }

        DemoCatalogFooter()
      }
      .padding(.horizontal, WDSpacing.s5)
      .padding(.top, WDSpacing.s2)
      .padding(.bottom, WDSpacing.s8)
      .frame(maxWidth: 720)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .background(colors.bgCanvas.ignoresSafeArea())
    .navigationTitle(Text(verbatim: "组件"))
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        NavigationLink {
          DemoThemeView(scheme: $scheme)
        } label: {
          Image(systemName: "paintpalette")
        }
        .accessibilityLabel(Text(verbatim: "主题与令牌"))
        .accessibilityIdentifier("theme-button")
      }
    }
  }
}

// MARK: - 头部

private struct DemoCatalogHero: View {
  @Environment(\.wdColors) private var colors

  private var categoryCount: Int {
    DemoComponentCategory.allCases.filter {
      !DemoComponentCatalog.entries(in: $0).isEmpty
    }.count
  }

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s4) {
      HStack(alignment: .top, spacing: WDSpacing.s4) {
        VStack(alignment: .leading, spacing: WDSpacing.s2) {
          Text(verbatim: "WISDOM UI")
            .wdFont(WDType.overline)
            .foregroundStyle(colors.textOnSoft)
          Text(verbatim: "组件目录")
            .wdFont(WDType.title1)
            .foregroundStyle(colors.textOnSoft)
          Text(verbatim: "按类别浏览，点进任意组件查看实时预览、档位与状态细节。")
            .wdFont(WDType.subheadline)
            .foregroundStyle(colors.textOnSoft)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        DemoBrandMark()
      }

      HStack(spacing: WDSpacing.s2) {
        DemoMetric(value: "\(DemoComponentCatalog.totalCount)", label: "已实现")
        DemoMetric(value: "\(categoryCount)", label: "类别")
        DemoMetric(value: "M2", label: "批次")
      }
    }
    .padding(WDSpacing.s5)
    .background(
      RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
        .fill(WDGradient.surface.linearGradient)
    )
    .overlay(
      RoundedRectangle(cornerRadius: WDRadius.xl, style: .continuous)
        .stroke(colors.borderHairline, lineWidth: 1)
    )
  }
}

private struct DemoBrandMark: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
        .fill(WDGradient.fill.linearGradient)
        .frame(width: 56, height: 56)
        .shadow(color: colors.textBrand.opacity(0.18), radius: 12, x: 0, y: 6)
      WDIcon(icon: .chore, size: .lg)
        .foregroundStyle(colors.textOnDark)
    }
    .accessibilityHidden(true)
  }
}

private struct DemoMetric: View {
  let value: String
  let label: String

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(verbatim: value)
        .wdFont(WDType.title3)
        .foregroundStyle(colors.textOnSoft)
      Text(verbatim: label)
        .wdFont(WDType.caption1)
        .foregroundStyle(colors.textOnSoft)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, WDSpacing.s3)
    .padding(.vertical, WDSpacing.s2)
    .background(
      RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
        .fill(colors.surfaceCardSolid.opacity(0.72))
    )
  }
}

// MARK: - 分类

private struct DemoCategorySection: View {
  let category: DemoComponentCategory
  let entries: [DemoComponentEntry]

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      HStack(spacing: WDSpacing.s3) {
        ZStack {
          RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
            .fill(colors.surfaceTint)
            .frame(width: 32, height: 32)
          WDIcon(icon: category.icon, size: .sm)
            .foregroundStyle(colors.textOnSoft)
        }

        VStack(alignment: .leading, spacing: 0) {
          Text(verbatim: category.title)
            .wdFont(WDType.title3)
            .foregroundStyle(colors.textPrimary)
          Text(verbatim: category.subtitle)
            .wdFont(WDType.caption1)
            .foregroundStyle(colors.textSecondary)
        }

        Spacer(minLength: 0)

        Text(verbatim: "\(entries.count) 个")
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
          .padding(.horizontal, WDSpacing.s3)
          .padding(.vertical, WDSpacing.s1)
          .background(Capsule().fill(colors.surfaceCardSolid))
      }

      VStack(spacing: WDSpacing.s2) {
        ForEach(entries) { entry in
          NavigationLink(value: entry) {
            DemoComponentRow(entry: entry)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("component-row-\(entry.id.rawValue)")
        }
      }
    }
  }
}

private struct DemoComponentRow: View {
  let entry: DemoComponentEntry

  @Environment(\.wdColors) private var colors

  var body: some View {
    HStack(spacing: WDSpacing.s4) {
      ZStack {
        RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
          .fill(colors.surfaceTint)
          .frame(width: 42, height: 42)
        WDIcon(icon: entry.icon, size: .md)
          .foregroundStyle(colors.textOnSoft)
      }

      VStack(alignment: .leading, spacing: WDSpacing.s1) {
        HStack(spacing: WDSpacing.s2) {
          Text(verbatim: entry.name)
            .wdFont(WDType.headline)
            .foregroundStyle(colors.textPrimary)
          if entry.hasEnumSettings {
            Text(verbatim: "可配置")
              .wdFont(WDType.caption1)
              .foregroundStyle(colors.textBrand)
              .padding(.horizontal, WDSpacing.s2)
              .padding(.vertical, 1)
              .background(Capsule().fill(colors.surfaceTint))
          }
        }

        Text(verbatim: entry.summary)
          .wdFont(WDType.caption1)
          .foregroundStyle(colors.textSecondary)
          .lineLimit(2)
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
}

// MARK: - 页脚

private struct DemoCatalogFooter: View {
  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      Text(verbatim: "关于这个 demo")
        .wdFont(WDType.footnote)
        .foregroundStyle(colors.textPrimary)
      Text(
        verbatim:
          "当前覆盖 M2 已实现的 11 件 primitives。M3–M6 的组件会随批次继续加入；"
          + "主题与令牌、无障碍审计视口在右上角的调色板入口里。"
      )
      .wdFont(WDType.caption1)
      .foregroundStyle(colors.textTertiary)
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(WDSpacing.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: WDRadius.lg, style: .continuous)
        .fill(colors.surfaceCardSunken)
    )
  }
}
