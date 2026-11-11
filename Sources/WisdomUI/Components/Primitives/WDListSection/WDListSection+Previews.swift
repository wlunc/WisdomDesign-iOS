#if WD_PREVIEWS
  import SwiftUI

  private struct WDListSectionPreviewItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
  }

  private struct WDListSectionPreviewHost: View {
    private let items = [
      WDListSectionPreviewItem(id: 1, title: "整理储物间", subtitle: "今天 18:00 前"),
      WDListSectionPreviewItem(id: 2, title: "擦窗", subtitle: "已完成"),
      WDListSectionPreviewItem(id: 3, title: "更换床单", subtitle: "明天"),
    ]

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s7) {
        WDListSection(items: items, selection: [2], header: Text(verbatim: "今天")) {
          item, context in
          WDListRow(
            title: Text(verbatim: item.title),
            subtitle: Text(verbatim: item.subtitle),
            isSelected: context.isSelected,
            showsSeparator: !context.isLast,
            action: {}
          )
        }

        WDListSection(
          items: items,
          header: Text(verbatim: "本周"),
          headerAction: .init(label: Text(verbatim: "编辑"), action: {})
        ) { item, context in
          WDListRow(
            title: Text(verbatim: item.title),
            showsSeparator: !context.isLast,
            action: {}
          )
        } footer: {
          Text(verbatim: "共 3 项，已完成 1 项")
        }

        WDListSection(items: [WDListSectionPreviewItem](), header: Text(verbatim: "空组不显示")) {
          _, _ in
          EmptyView()
        }
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDListSection 浅色") {
    WDListSectionPreviewHost()
  }

  #Preview("WDListSection 深色") {
    WDListSectionPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
