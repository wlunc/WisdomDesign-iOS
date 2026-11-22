import SwiftUI
import WisdomUI

@main
struct AIStarterApp: App {
  private var scenario: AISkillGoldenScenario {
    let raw = ProcessInfo.processInfo.environment["AISKILL_GOLDEN_SCENARIO"] ?? ""
    return AISkillGoldenScenario(rawValue: raw) ?? .loading
  }

  var body: some Scene {
    WindowGroup {
      TabView {
        TaskListView(scenario: scenario)
          .tabItem { Label("任务", systemImage: "list.bullet") }
        APIMinimalExample()
          .tabItem { Label("API", systemImage: "wrench.and.screwdriver") }
      }
    }
  }
}