import SwiftUI

/// 归档体积基线的空壳 app —— **E3-iOS-a 的分母**（SPEC §1.2.3）。
///
/// 刻意**不引入 `WisdomUI`**：E3-iOS-a 量的是"引入该库后归档 Thinning 的增量"，
/// 所以分母必须是一个**同构但不含该库**的 app —— 同构 = 同样的 target 结构、同样的构建设置、
/// 同样规模的一个 SwiftUI 视图树。
///
/// **改本 shell 等于改基线**：任何改动都要单独提交，并在 `CHANGELOG.md` 标注
/// （否则历史测量值之间不可比）。
@main
struct BaselineShellApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
