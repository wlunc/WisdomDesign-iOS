import SwiftUI

/// 与 demo 首屏同构的最小视图树（**不引用任何 `WisdomUI` 类型**）。
struct ContentView: View {
  var body: some View {
    NavigationStack {
      List(0..<20, id: \.self) { index in
        HStack(spacing: 12) {
          Circle()
            .frame(width: 40, height: 40)
          VStack(alignment: .leading, spacing: 4) {
            Text("Row \(index + 1)")
            Text("Baseline shell row")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 8)
      }
      .navigationTitle("Baseline Shell")
    }
  }
}
