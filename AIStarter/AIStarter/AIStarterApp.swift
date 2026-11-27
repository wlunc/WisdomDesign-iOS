import SwiftUI
import WisdomUI

@main
struct AIStarterApp: App {
  private var scenario: AISkillGoldenScenario {
    let raw = ProcessInfo.processInfo.environment["AISKILL_GOLDEN_SCENARIO"] ?? ""
    return AISkillGoldenScenario(rawValue: raw) ?? .loading
  }

  /// nil = follow the simulator/system appearance; "light" / "dark" force one for the matrix.
  private var forcedColorScheme: ColorScheme? {
    switch ProcessInfo.processInfo.environment["AISKILL_GOLDEN_APPEARANCE"] {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  var body: some Scene {
    WindowGroup {
      TabView {
        TaskListView(scenario: scenario)
          .tabItem { Label("任务", systemImage: "list.bullet") }
        APIMinimalExample()
          .tabItem { Label("API", systemImage: "wrench.and.screwdriver") }
      }
      .preferredColorScheme(forcedColorScheme)
    }
  }
}
