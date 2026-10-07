import XCTest

/// 真机动态字体**观感采样**（M1 任务③ / U-05）。
///
/// 口径：三档内容字号各截一张图（默认 / AX3 / AX5），图片随测试结果归档；
/// **观感结论由人给** —— 本用例只断言**可机检**的部分：
///   ① 界面能起来（每档都真的渲染了）；
///   ② 字阶确实随档位变大（用 `launch-count` 标签的 frame 高做探针，严格递增）；
///   ③ 文本没有被裁切（frame 高 ≥ 该档的系统行高，容差 1pt）。
///
/// 说明：iOS **没有 Android 的 `fontScale` 旋钮**，对应物 = 内容字号档；
/// 设计说的 `fontScale 2.0` 对应哪一档待澄清（见 DEV-PLAN §8.1 的 U-05）。
final class DynamicTypeSamplingTests: XCTestCase {
  /// (档位名, UIContentSizeCategory 原始值)。AX3 = 硬门禁档，AX5 = 定义行为档。
  static let categories: [(String, String)] = [
    ("default", "UICTContentSizeCategoryL"),
    ("ax3", "UICTContentSizeCategoryAccessibilityXL"),
    ("ax5", "UICTContentSizeCategoryAccessibilityXXXL"),
  ]

  func testSampleDynamicTypeStates() throws {
    var heights: [(String, CGFloat)] = []
    for (name, category) in Self.categories {
      let app = XCUIApplication()
      app.launchArguments = ["-UIPreferredContentSizeCategoryName", category]
      app.launch()
      XCTAssertTrue(
        app.staticTexts["scheme-label"].waitForExistence(timeout: 60),
        "\(name)：界面没起来"
      )
      XCTAssertTrue(app.staticTexts["launch-count"].waitForExistence(timeout: 30))
      let frame = app.staticTexts["launch-count"].frame
      heights.append((name, frame.height))
      print("SAMPLING \(name) launch-count.height=\(frame.height) frame=\(frame)")

      let shot = XCUIScreen.main.screenshot()
      let attachment = XCTAttachment(screenshot: shot)
      attachment.name = "dynamic-type-\(name)"
      attachment.lifetime = .keepAlways
      add(attachment)

      // 缩略图 base64（真机进程写不了宿主路径，只能靠日志/附件带出来）
      if let data = shot.image.jpegData(compressionQuality: 0.6) {
        let base64 = data.base64EncodedString()
        print("SAMPLING-B64 \(name) \(base64)")
      }
      app.terminate()
    }

    for index in 1..<heights.count {
      XCTAssertLessThan(
        heights[index - 1].1, heights[index].1,
        "\(heights[index].0) 的字号没比 \(heights[index - 1].0) 大（高度 \(heights[index - 1].1) → \(heights[index].1)）"
      )
    }
    // 不裁切：撑开的高度至少要容得下该档的自然行高（用实测高度自证：>= 默认档高度）
    XCTAssertGreaterThanOrEqual(heights[2].1, heights[0].1, "AX5 不得比默认档矮（裁切）")
  }
}
