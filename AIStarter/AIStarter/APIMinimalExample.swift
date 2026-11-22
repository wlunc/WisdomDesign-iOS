import SwiftUI
import WisdomUI

/// M2-3 最小消费例：只使用公开符号，验证真实初始化、重载与 View 扩展。
struct APIMinimalExample: View {
  @State private var text = ""
  @State private var isRefreshing = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s3) {
        WDButton("Primary", variant: .filled, size: .md) {}
        WDButton(verbatim: "Verbatim") {}
        WDButton(variant: .tonal, action: {}) { Text(verbatim: "Custom label") }
        WDListRow(title: Text(verbatim: "Title"), subtitle: Text(verbatim: "Subtitle"), trailing: .disclosure) {}
        WDEmptyState(icon: .task, title: Text(verbatim: "Empty"))
        WDSkeleton(variant: .list, lineCount: 2)
        WDTextField(text: $text, label: Text(verbatim: "Title"), appearance: WDTextFieldAppearance(variant: .inset))
        Text("field: \(text)").wdFont(WDType.caption1).wdLineBox(WDType.caption1, lines: 1)
      }.padding(WDSpacing.s4)
    }
    .wdTheme(.light)
    .wdEffectsBudget(.default)
    .wdAnnouncer { _, _ in }
    .wdPullRefresh(isRefreshing: $isRefreshing) {}
  }
}
