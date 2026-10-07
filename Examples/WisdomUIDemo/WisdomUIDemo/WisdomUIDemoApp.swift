import SwiftUI

@main
struct WisdomUIDemoApp: App {
  /// 本进程的启动序号：进程每次启动 +1 并落 UserDefaults。
  ///
  /// 用途 = UI 测试里验证「换 scheme **不重启进程**」的**真实证据**：
  /// `XCUIApplication` 没有公开的 `processID`，但重启必然让这个计数变大。
  init() {
    let key = "wd.demo.launchCount"
    let next = UserDefaults.standard.integer(forKey: key) + 1
    UserDefaults.standard.set(next, forKey: key)
  }

  var body: some Scene {
    WindowGroup {
      DemoRootView()
    }
  }
}
