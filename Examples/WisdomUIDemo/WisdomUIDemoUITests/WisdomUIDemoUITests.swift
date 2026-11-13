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

    let themeButton = app.buttons["theme-button"]
    XCTAssertTrue(themeButton.waitForExistence(timeout: 20), "主题入口未出现")
    themeButton.tap()

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

    let themeButton = app.buttons["theme-button"]
    XCTAssertTrue(themeButton.waitForExistence(timeout: 20), "主题入口未出现")
    themeButton.tap()
    XCTAssertTrue(app.staticTexts["scheme-label"].waitForExistence(timeout: 20))
    try audit(app, scope: "theme")

    let auditLink = app.buttons["audit-viewport-link"]
    XCTAssertTrue(auditLink.waitForExistence(timeout: 20), "审计视口入口未出现")
    auditLink.tap()
    XCTAssertTrue(app.buttons["提交"].waitForExistence(timeout: 20), "组件审计视口未出现")
    try audit(app, scope: "components")
  }

  /// 组件目录：分类存在、点击进入详情、右上角设置能切换枚举并影响预览。
  func testComponentCatalogNavigationAndSettings() {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.staticTexts["操作"].waitForExistence(timeout: 20), "分类「操作」未出现")
    XCTAssertTrue(app.staticTexts["输入与选择"].exists, "分类「输入与选择」未出现")
    XCTAssertTrue(app.staticTexts["内容展示"].exists, "分类「内容展示」未出现")
    XCTAssertTrue(app.staticTexts["布局与结构"].exists, "分类「布局与结构」未出现")

    let buttonRow = app.buttons["component-row-WDButton"]
    XCTAssertTrue(buttonRow.waitForExistence(timeout: 20), "WDButton 行未出现")
    buttonRow.tap()

    XCTAssertTrue(app.navigationBars["WDButton"].waitForExistence(timeout: 20), "WDButton 详情未出现")

    let settingsButton = app.buttons["component-settings-button"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 20), "枚举组件的设置按钮未出现")
    settingsButton.tap()

    let tonalOption = app.buttons["setting-button-variant-1"]
    XCTAssertTrue(tonalOption.waitForExistence(timeout: 20), "变体选项未出现")
    tonalOption.tap()

    let doneButton = app.buttons["settings-done-button"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 20), "设置完成按钮未出现")
    doneButton.tap()

    let configChip = app.staticTexts["config-chip-0"]
    XCTAssertTrue(configChip.waitForExistence(timeout: 20), "配置摘要未出现")
    XCTAssertEqual(configChip.label, "柔色", "切换变体后配置摘要必须更新")
  }

  /// ActionSheet：从目录进入详情、打开、点取消关闭；截图附在 result bundle 里供人工核对透明背景。
  func testActionSheetPresentsAndDismisses() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDActionSheet"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDActionSheet 行未出现")
    row.tap()

    let trigger = app.buttons["打开操作表"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "打开操作表按钮未出现")
    trigger.tap()

    let cancel = app.buttons["取消"]
    XCTAssertTrue(cancel.waitForExistence(timeout: 20), "ActionSheet 未出现")
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = "actionsheet-presented"
    attachment.lifetime = .keepAlways
    add(attachment)

    cancel.tap()
    XCTAssertFalse(cancel.waitForExistence(timeout: 2), "点取消后 ActionSheet 应关闭")
  }

  /// BottomSheet：系统 sheet 打开后截图（核对把手/标题/内容/底部操作区），再点关闭。
  func testBottomSheetPresentsAndDismisses() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDBottomSheet"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDBottomSheet 行未出现")
    row.tap()

    let trigger = app.buttons["打开底部面板"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "打开底部面板按钮未出现")
    trigger.tap()

    let close = app.buttons["关闭成员选择"]
    XCTAssertTrue(close.waitForExistence(timeout: 20), "BottomSheet 未出现")
    Thread.sleep(forTimeInterval: 0.6)  // 等系统 sheet 落位，截图才是半屏 detent
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = "bottomsheet-presented"
    attachment.lifetime = .keepAlways
    add(attachment)

    close.tap()
    XCTAssertFalse(close.waitForExistence(timeout: 2), "点关闭后 BottomSheet 应关闭")
  }

  /// BottomSheet：点输入框弹出键盘，验证面板上移、字段不被遮挡。
  func testBottomSheetKeyboardAvoidsField() throws {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDBottomSheet"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDBottomSheet 行未出现")
    row.tap()

    let trigger = app.buttons["打开底部面板"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "打开底部面板按钮未出现")
    trigger.tap()

    let field = app.textFields["任务名称"]
    XCTAssertTrue(field.waitForExistence(timeout: 20), "任务名称输入框未出现")
    field.tap()

    let keyboard = app.keyboards.firstMatch
    guard keyboard.waitForExistence(timeout: 5) else {
      throw XCTSkip("模拟器未显示软件键盘，无法验证键盘避让")
    }
    Thread.sleep(forTimeInterval: 0.5)
    XCTAssertLessThan(field.frame.maxY, keyboard.frame.minY, "面板未上移，字段被键盘遮挡")

    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = "bottomsheet-keyboard"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  /// BottomSheet：内容在顶部时下滑，应拖动面板并关闭（UIScrollView 桥接路径）。
  func testBottomSheetSwipeDownFromContentCloses() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDBottomSheet"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDBottomSheet 行未出现")
    row.tap()

    let trigger = app.buttons["打开底部面板"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "打开底部面板按钮未出现")
    trigger.tap()

    let close = app.buttons["关闭成员选择"]
    XCTAssertTrue(close.waitForExistence(timeout: 20), "BottomSheet 未出现")
    let content = app.staticTexts.containing(
      NSPredicate(format: "label CONTAINS %@", "下滑关闭")
    ).firstMatch
    XCTAssertTrue(content.waitForExistence(timeout: 20), "面板内容未出现")
    let start = content.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
    XCTAssertFalse(close.waitForExistence(timeout: 2), "内容顶部下滑应关闭 BottomSheet")
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

      if let reason = AuditExceptions.known(
        scope: scope, identifier: issue.element?.identifier ?? "", label: label, compact: compact
      ) {
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
  static func known(
    scope: String, identifier: String, label: String, compact: String
  ) -> String? {
    // 2026-11-12：nightly 第 3 日首次红 —— iOS 26 审计对卡片圆角附近的 13pt 文本偶发报
    // "Contrast nearly passed"（同一代码复跑 3/3 绿；元素 = theme 页的 launch-count，
    // text.primary on surface.card 实测约 16:1，不是 WCAG 失败）。只放行这条**告警**；
    // "Contrast failed" 仍严格失败，且不扩大到其他元素。
    if scope == "theme", identifier == "launch-count",
      compact.hasPrefix("Contrast nearly passed")
    {
      return "iOS 26 审计 near-threshold 告警（非 WCAG 失败；复跑 3/3 绿）"
    }
    guard scope == "components" else { return nil }
    if compact.hasPrefix("Dynamic Type"), ["妈", "进行中"].contains(label) {
      return "固定字号设计例外（头像首字 12pt / 徽标 11pt）"
    }
    if compact.hasPrefix("Text clipped"),
      ["整理储物间", "妈妈的待办", "今天 18:00 前", "已完成 2 项"].contains(label)
    {
      return "设计 18 §7 的单行截断（审计按 lineLimit(1) 判可能截断）"
    }
    return nil
  }
}
