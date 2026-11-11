import SwiftUI

/// E3-iOS-a 的**分子**：「同构消费方」壳。
///
/// 与 `Examples/BaselineShell` 同构（同样的 target 结构、构建设置与一个 20 行列表屏幕），
/// **唯一差异 = 引入 `WisdomUI` 并用 `WDListRow` 渲染行**。
/// E3-iOS-a 的归档增量 = 本壳归档体积 − `BaselineShell` 归档体积。
///
/// **改本壳 = 改基线**：任何改动都要与 `BaselineShell` 成对提交，并在 `CHANGELOG.md` 标注
/// （否则历史测量值之间不可比）。
@main
struct BaselineShellWithLibraryApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
