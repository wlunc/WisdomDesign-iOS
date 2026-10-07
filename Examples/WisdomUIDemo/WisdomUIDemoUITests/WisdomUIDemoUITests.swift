import XCTest

/// demo 层 UI 测试（M1 交付物）：① 运行时 scheme 切换；② 无障碍审计四类目。
///
/// `performAccessibilityAudit` 只能跑在 XCUITest 里（SPEC §1.5.5），所以它在 demo 工程而不是包里。
final class WisdomUIDemoUITests: XCTestCase {
  override func setUp() {
    continueAfterFailure = false
  }

  /// 运行时换 scheme：值变了、**进程没重启**。
  ///
  /// 「没重启」的证据 = app 自己维护的启动序号（`launch-count`）：进程重启必然让它变大。
  /// （`XCUIApplication` 没有公开的 `processID`，实测编译不过——所以用这个可观测的等价物。）
  func testSchemeSwitchingAtRuntime() {
    let app = XCUIApplication()
    app.launch()

    let label = app.staticTexts["scheme-label"]
    XCTAssertTrue(label.waitForExistence(timeout: 20), "scheme-label 未出现")
    let schemeBefore = label.value as? String
    let launchBefore = app.staticTexts["launch-count"].value as? String
    XCTAssertNotNil(launchBefore, "launch-count 未出现")

    app.segmentedControls["scheme-picker"].buttons.element(boundBy: 1).tap()

    let schemeAfter = label.value as? String
    XCTAssertNotEqual(schemeBefore, schemeAfter, "切换后 scheme 值必须变（换肤不能是假的）")
    XCTAssertEqual(
      app.staticTexts["launch-count"].value as? String, launchBefore,
      "换 scheme 不得重启进程（启动序号变了就说明重启了）"
    )
    XCTAssertEqual(app.state, .runningForeground, "切换后 app 必须仍在前台")
  }

  /// 无障碍审计四类目（contrast / hitRegion / textClipped / dynamicType）。
  ///
  /// 用 `issueHandler` 逐条**打印**违规明细（auditType + 描述 + 元素）后再让它失败：
  /// 默认实现只抛一句 "Dynamic Type font sizes are partially unsupported"，定位不到元素。
  func testAccessibilityAudit() throws {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.staticTexts["scheme-label"].waitForExistence(timeout: 20))
    try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .textClipped, .dynamicType]) {
      issue in
      print(
        """
        AUDIT-ISSUE type=\(issue.auditType) \
        element=\(issue.element?.identifier ?? "-")/\(issue.element.map { String(describing: $0.elementType) } ?? "-") \
        frame=\(issue.element?.frame.debugDescription ?? "-") \
        compact=\(issue.compactDescription) \
        detail=\(issue.detailedDescription)
        """
      )
      // **严格模式**：返回 false = 不吞任何 issue（打印只是为了失败时能定位到元素）。
      return false
    }
  }
}
