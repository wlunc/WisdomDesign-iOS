import SwiftUI
import Testing
import WisdomUI

/// `WDListSection` 的 8 态快照（浅/深 × 默认/AX3 × LTR/RTL）。
///
/// 变体 = 标准 / 标题动作 / 带页脚 / 空组；空组按设计 19 的「整组隐藏」应只有空白。
/// 组件不是玻璃类 ⇒ 走 `ImageRenderer`（E6 显式表）。
@MainActor
@Suite("WDListSection 快照", .serialized)
struct WDListSectionSnapshotTests {
  static let canvas = CGSize(width: 360, height: 640)

  private struct Item: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
  }

  private enum Variant: String, CaseIterable {
    case standard
    case action
    case footer
    case empty
  }

  private static let items = [
    Item(id: 1, title: "整理储物间", subtitle: "今天 18:00 前"),
    Item(id: 2, title: "擦窗", subtitle: "已完成"),
    Item(id: 3, title: "更换床单", subtitle: "明天"),
  ]

  private struct Sample: View {
    let values: WDColorValues
    let variant: Variant

    private var items: [Item] { WDListSectionSnapshotTests.items }

    var body: some View {
      content
        .padding(WDSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(values.bgCanvas)
        .wdTheme(WDTheme(colors: values))
    }

    @ViewBuilder private var content: some View {
      switch variant {
      case .standard:
        WDListSection(items: items, selection: [2], header: Text(verbatim: "今天")) { item, context in
          row(item, context)
        }
      case .action:
        WDListSection(
          items: items,
          selection: [2],
          header: Text(verbatim: "本周"),
          headerAction: .init(label: Text(verbatim: "编辑"), action: {})
        ) { item, context in
          row(item, context)
        }
      case .footer:
        WDListSection(items: items, header: Text(verbatim: "已完成")) { item, context in
          row(item, context)
        } footer: {
          Text(verbatim: "共 3 项，已完成 1 项")
        }
      case .empty:
        WDListSection(items: [Item](), header: Text(verbatim: "空组")) { _, _ in
          EmptyView()
        }
        .frame(minHeight: 80, alignment: .top)
      }
    }

    private func row(_ item: Item, _ context: WDListSectionRowContext) -> some View {
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

  @Test("WDListSection：4 变体 × 8 态基线一致（缺失 = fail）")
  func snapshots() {
    for variant in Variant.allCases {
      for state in SnapshotSupport.matrix {
        SnapshotSupport.verify(
          name: "listsection-\(variant.rawValue)-\(state.id)",
          view: Sample(values: SnapshotSupport.values(for: state), variant: variant),
          state: state,
          size: Self.canvas
        )
      }
    }
  }
}
