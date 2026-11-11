import SwiftUI
import WisdomUI

/// 与 `BaselineShell/ContentView` 同构的屏幕：`NavigationStack` + 20 行列表。
///
/// 结构与基线壳一致；差异只有"行用 `WDListRow` 渲染"（同样带前导图标/标题/副标题），
/// 用于量 E3-iOS-a 的"引入本库"归档增量。
struct ContentView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(0..<20, id: \.self) { index in
            WDListRow(
              title: Text(verbatim: "Row \(index + 1)"),
              subtitle: Text(verbatim: "Baseline shell row"),
              leading: .icon(.task),
              action: nil
            )
          }
        }
      }
      .navigationTitle(Text(verbatim: "Baseline Shell"))
    }
  }
}
