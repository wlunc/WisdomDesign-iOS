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
  ///
  /// 覆盖两个页签：① `主题`（M1 的字阶/槽位画廊）；② `组件`（M2 的 11 件审计视口）。
  func testAccessibilityAudit() throws {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.staticTexts["scheme-label"].waitForExistence(timeout: 20))
    try audit(app, scope: "theme")

    let componentsTab = app.segmentedControls["page-picker"].buttons["组件"]
    XCTAssertTrue(componentsTab.waitForExistence(timeout: 20), "组件页签未出现")
    componentsTab.tap()
    XCTAssertTrue(app.buttons["提交"].waitForExistence(timeout: 20), "组件审计视口未出现")
    try audit(app, scope: "components")
  }

  /// 单个页签的严格审计。**只放行两类别有理由的窄例外**（其余一律失败）：
  ///   · 固定字号组件（头像首字 12pt / 徽标 11pt）的 dynamicType —— 设计例外，登记 M2 出口报告 §4；
  ///   · 列表行标题/副标题的 textClipped —— 设计 18 §7 要求单行截断，审计按 `lineLimit(1)` 判"可能截断"。
  /// 例外必须在这里**逐条点名 label**，不允许按类别整体吞掉。
  private func audit(_ app: XCUIApplication, scope: String) throws {
    try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .textClipped, .dynamicType]) {
      issue in
      let label = issue.element?.label ?? "-"
      let compact = issue.compactDescription

      if let reason = AuditExceptions.known(scope: scope, label: label, compact: compact) {
        print("AUDIT-KNOWN scope=\(scope) label=\(label) reason=\(reason)")
        return true
      }

      print(
        """
        AUDIT-ISSUE scope=\(scope) type=\(issue.auditType) \
        element=\(issue.element?.identifier ?? "-")/\(issue.element.map { String(describing: $0.elementType) } ?? "-") \
        label=\(label) value=\(issue.element?.value as? String ?? "-") \
        frame=\(issue.element?.frame.debugDescription ?? "-") \
        compact=\(compact) \
        detail=\(issue.detailedDescription)
        """
      )
      // **严格模式**：返回 false = 不吞任何 issue。
      return false
    }
  }

}

/// 已知的、带理由的窄例外（M2 出口报告 §4-② 有登记）。
///
/// 放在独立 `enum` 而不是测试类里：审计回调是 `@Sendable`，捕获测试类的 `Self` 会触发
/// "sending non-Sendable metatype" 的 Swift 6 错误。
private enum AuditExceptions {
  static func known(scope: String, label: String, compact: String) -> String? {
    guard scope == "components" else { return nil }
    if compact.hasPrefix("Dynamic Type"), ["妈", "进行中"].contains(label) {
      return "固定字号设计例外（头像首字 12pt / 徽标 11pt）"
    }
    if compact.hasPrefix("Text clipped"), ["整理储物间", "妈妈的待办", "今天 18:00 前"].contains(label) {
      return "设计 18 §7 的单行截断（审计按 lineLimit(1) 判可能截断）"
    }
    return nil
  }
}
