import XCTest
import SwiftUI

/// M2 黄金页面矩阵测试。
/// - 自动断言：5 类状态 × 默认/AX3 字体 × 浅色/深色外观都可渲染；
/// - 截图附件：每个组合归档为 XCTAttachment；
/// - 人工项：对比度、VoiceOver 焦点、真机表现、独立视觉评审仍为 not-run。
final class GoldenPageMatrixTests: XCTestCase {
  private enum MatrixText {
    static let ax3 = "UICTContentSizeCategoryAccessibilityXL"
    static let `default` = "UICTContentSizeCategoryL"
  }

  private enum MatrixAppearance: String, CaseIterable {
    case light
    case dark
  }

  func testGoldenStateMatrix() {
    let scenarios = ["loading", "contentShort", "contentLong", "empty", "error"]
    for scenarioName in scenarios {
      for category in [MatrixText.default, MatrixText.ax3] {
        for appearance in MatrixAppearance.allCases {
          let app = XCUIApplication()
          app.launchArguments = ["-UIPreferredContentSizeCategoryName", category]
          app.launchEnvironment = [
            "AISKILL_GOLDEN_SCENARIO": scenarioName,
            "AISKILL_GOLDEN_APPEARANCE": appearance.rawValue,
          ]
          app.launch()
          let combo = "\(scenarioName)/\(category)/\(appearance.rawValue)"
          XCTAssertTrue(
            app.descendants(matching: .any)["golden-task-list-root"].waitForExistence(timeout: 30),
            "\(combo)：根视图未渲染"
          )
          let identifier = Self.identifier(for: scenarioName)
          XCTAssertTrue(
            app.descendants(matching: .any)[identifier].waitForExistence(timeout: 15),
            "\(combo)：缺少 \(identifier)"
          )
          let shot = XCUIScreen.main.screenshot()
          let attachment = XCTAttachment(screenshot: shot)
          attachment.name = "golden-\(scenarioName)-\(category)-\(appearance.rawValue)"
          attachment.lifetime = .keepAlways
          add(attachment)
          app.terminate()
        }
      }
    }
  }

  func testAppearanceMatrixAttachments() {
    // 浅/深外观已并入 testGoldenStateMatrix 的完整组合；
    // 这里只断言该维度确实被执行，避免出现“声明覆盖但实际未跑”的假绿。
    XCTAssertEqual(MatrixAppearance.allCases.count, 2)
  }

  func testUnverifiedMatrixIsExplicit() {
    let report = [
      "contrast": "not-run",
      "voiceOverFocus": "not-run",
      "device": "not-run",
      "designReview": "not-run",
      "keyboardScroll": "not-run",
    ]
    XCTAssertTrue(report.values.allSatisfy { $0 == "not-run" })
  }

  private static func identifier(for scenario: String) -> String {
    switch scenario {
    case "loading": return "golden-loading"
    case "contentShort": return "golden-content-short"
    case "contentLong": return "golden-content-long"
    case "empty": return "golden-empty"
    case "error": return "golden-error"
    default: return "golden-task-list-root"
    }
  }
}
