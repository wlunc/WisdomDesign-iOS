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

  /// WDAssigneePicker：单选点已选项不取消、点「未指派」清空、紧凑设置生效。
  func testAssigneePickerSelectionAndSettings() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDAssigneePicker"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDAssigneePicker 行未出现")
    row.tap()
    XCTAssertTrue(
      app.navigationBars["WDAssigneePicker"].waitForExistence(timeout: 20), "详情未出现")

    let single = app.otherElements["assignee-picker-single"]
    XCTAssertTrue(single.waitForExistence(timeout: 20), "单选预览未出现")
    let dad = single.buttons["爸爸"]
    XCTAssertTrue(dad.waitForExistence(timeout: 20), "成员按钮未出现")
    dad.tap()
    XCTAssertTrue(dad.isSelected, "点成员后应选中")
    dad.tap()
    XCTAssertTrue(dad.isSelected, "单选点已选项不应取消")

    let unassigned = single.buttons["未指派"]
    XCTAssertTrue(unassigned.waitForExistence(timeout: 20), "未指派项未出现")
    unassigned.tap()
    XCTAssertTrue(unassigned.isSelected, "点未指派应选中它（清空选择）")
    XCTAssertFalse(dad.isSelected, "清空后成员不应仍选中")

    let settingsButton = app.buttons["component-settings-button"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 20), "设置按钮未出现")
    settingsButton.tap()
    let compact = app.buttons["setting-assigneepicker-size-1"]
    XCTAssertTrue(compact.waitForExistence(timeout: 20), "紧凑尺寸选项未出现")
    compact.tap()
    app.buttons["settings-done-button"].tap()
    let chip = app.staticTexts["config-chip-0"]
    XCTAssertTrue(chip.waitForExistence(timeout: 20), "配置摘要未出现")
    XCTAssertEqual(chip.label, "compact", "切换尺寸后配置摘要必须更新")
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

  /// WDSlider：点击轨道必须跳到触点位置（UITapGestureRecognizer 集成验证）。
  func testSliderTapJumps() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDSlider"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDSlider 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDSlider"].waitForExistence(timeout: 20), "WDSlider 详情未出现")

    let slider = app.sliders["完成度"].firstMatch
    XCTAssertTrue(slider.waitForExistence(timeout: 20), "滑杆未进入无障碍树")

    let before = slider.value as? String
    XCTAssertNotNil(before, "滑杆应有当前值")

    slider.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)).tap()
    // 等 200ms 过渡结束。
    Thread.sleep(forTimeInterval: 0.4)

    let after = slider.value as? String
    XCTAssertNotEqual(before, after, "点击轨道后值必须变化（200ms 过渡后）")
  }

  /// WDToast：向上滑必须立即关闭（设计 28 §8）。
  func testToastSwipeUpDismisses() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDToast"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDToast 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDToast"].waitForExistence(timeout: 20), "WDToast 详情未出现")

    let trigger = app.buttons["显示 Toast"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "显示 Toast 按钮未出现")
    trigger.tap()

    let message = app.staticTexts["任务已保存"]
    XCTAssertTrue(message.waitForExistence(timeout: 20), "Toast 未出现")
    XCTAssertTrue(message.isHittable, "Toast 文案应可命中，frame=\(message.frame)")

    let start = message.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
    start.press(forDuration: 0.2, thenDragTo: end)
    XCTAssertFalse(message.waitForExistence(timeout: 2), "上滑后 Toast 应立即关闭")
  }

  /// WDToast：窗口层浮层只占自身区域，页面其余位置仍可交互（非阻塞）。
  func testToastDoesNotBlockPage() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDToast"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDToast 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDToast"].waitForExistence(timeout: 20), "WDToast 详情未出现")

    app.buttons["显示 Toast"].tap()
    XCTAssertTrue(app.staticTexts["任务已保存"].waitForExistence(timeout: 20), "Toast 未出现")

    // Toast 在底部；页面中间的触发按钮必须仍能命中，而不是被全屏浮层拦截。
    let trigger = app.buttons["显示 Toast"]
    XCTAssertTrue(trigger.isHittable, "Toast 出现时页面按钮应仍可点")
    trigger.tap()
    XCTAssertTrue(app.staticTexts["任务已保存"].waitForExistence(timeout: 20), "页面点击应生效")
  }

  /// WDToast：带操作停留 5 秒后自动消失（窗口层计时与移除）。
  func testToastAutoDismisses() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDToast"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDToast 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDToast"].waitForExistence(timeout: 20), "WDToast 详情未出现")
    app.buttons["显示 Toast"].tap()

    let message = app.staticTexts["任务已保存"]
    XCTAssertTrue(message.waitForExistence(timeout: 20), "Toast 未出现")

    let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: message)
    wait(for: [gone], timeout: 8)
  }

  /// WDPicker：菜单形态必须走自绘浮层（展开出现、选中后关闭）。
  func testPickerMenuOpensAndSelects() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDPicker"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDPicker 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDPicker"].waitForExistence(timeout: 20), "WDPicker 详情未出现")

    // 内联形态已经平铺了一份同名选项；菜单展开后会再多一份。
    let options = app.buttons.matching(NSPredicate(format: "label == %@", "任务"))
    let inlineCount = options.count

    let trigger = app.buttons.matching(NSPredicate(format: "label == %@", "分类")).firstMatch
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "菜单触发入口未出现")
    trigger.tap()

    // 菜单展开后同名选项两份；被遮罩盖住的那份不可点，只有菜单里那份可点。
    let expandedCount = options.count
    XCTAssertGreaterThan(expandedCount, inlineCount, "菜单未展开")
    let menuOption = (0..<expandedCount)
      .map {
        options.element(boundBy: $0)
      }
      .first {
        $0.isHittable
      }
    XCTAssertNotNil(menuOption, "菜单里的选项不可点")
    menuOption?.tap()

    var closed = false
    for _ in 0..<20 {
      if options.count == inlineCount {
        closed = true
        break
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    XCTAssertTrue(closed, "选中后菜单应关闭")
  }

  /// 切到 dark scheme 后，ActionSheet/BottomSheet 必须跟随主题；截图供人工核对。
  func testSheetsFollowDarkScheme() {
    let app = XCUIApplication()
    app.launch()

    app.buttons["theme-button"].tap()
    let picker = app.segmentedControls["scheme-picker"]
    XCTAssertTrue(picker.waitForExistence(timeout: 20), "scheme-picker 未出现")
    picker.buttons.element(boundBy: 1).tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()

    let actionRow = app.buttons["component-row-WDActionSheet"]
    XCTAssertTrue(actionRow.waitForExistence(timeout: 20))
    if !actionRow.isHittable { app.swipeUp() }
    actionRow.tap()
    app.buttons["打开操作表"].tap()
    let cancel = app.buttons["取消"]
    XCTAssertTrue(cancel.waitForExistence(timeout: 20), "ActionSheet 未出现")
    let actionShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    actionShot.name = "actionsheet-dark"
    actionShot.lifetime = .keepAlways
    add(actionShot)
    cancel.tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()

    let sheetRow = app.buttons["component-row-WDBottomSheet"]
    XCTAssertTrue(sheetRow.waitForExistence(timeout: 20))
    if !sheetRow.isHittable { app.swipeUp() }
    sheetRow.tap()
    app.buttons["打开底部面板"].tap()
    let close = app.buttons["关闭成员选择"]
    XCTAssertTrue(close.waitForExistence(timeout: 20), "BottomSheet 未出现")
    let sheetShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    sheetShot.name = "bottomsheet-dark"
    sheetShot.lifetime = .keepAlways
    add(sheetShot)
    close.tap()
  }

  /// BottomSheet 长内容：内部滚动不得拖动面板（关闭键位置不变）。
  func testBottomSheetLongContentScrollDoesNotMovePanel() {
    let app = XCUIApplication()
    app.launch()

    let sheetRow = app.buttons["scenario-row-bottomSheet"]
    XCTAssertTrue(sheetRow.waitForExistence(timeout: 20), "底部面板容器场景未出现")
    if !sheetRow.isHittable { app.swipeUp() }
    sheetRow.tap()

    let open = app.buttons["打开组合面板"]
    XCTAssertTrue(open.waitForExistence(timeout: 20), "打开组合面板按钮未出现")
    open.tap()

    let close = app.buttons["关闭新建任务"]
    XCTAssertTrue(close.waitForExistence(timeout: 20), "组合面板未出现")
    let before = close.frame

    let anchor = app.staticTexts["今天 18:00 前"]
    XCTAssertTrue(anchor.waitForExistence(timeout: 20), "面板内容未出现")
    let start = anchor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
    start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
    start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
    XCTAssertTrue(close.exists, "内部滚动不应关闭面板")
    XCTAssertEqual(close.frame.minY, before.minY, accuracy: 1, "内部滚动不应移动面板")

    let middleRow = app.staticTexts["倒垃圾"]
    XCTAssertTrue(middleRow.waitForExistence(timeout: 5), "长列表中段未出现")
    XCTAssertTrue(middleRow.isHittable, "内部滚动应能滚动列表")
    close.tap()
  }

  /// BottomSheet 长内容在顶部时，下拉仍应拖动面板并关闭。
  func testBottomSheetLongContentTopPullCloses() {
    let app = XCUIApplication()
    app.launch()

    let sheetRow = app.buttons["scenario-row-bottomSheet"]
    XCTAssertTrue(sheetRow.waitForExistence(timeout: 20), "底部面板容器场景未出现")
    if !sheetRow.isHittable { app.swipeUp() }
    sheetRow.tap()

    let open = app.buttons["打开组合面板"]
    XCTAssertTrue(open.waitForExistence(timeout: 20), "打开组合面板按钮未出现")
    open.tap()

    let close = app.buttons["关闭新建任务"]
    XCTAssertTrue(close.waitForExistence(timeout: 20), "组合面板未出现")
    let anchor = app.staticTexts["今天 18:00 前"]
    XCTAssertTrue(anchor.waitForExistence(timeout: 20), "面板内容未出现")
    let start = anchor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
    XCTAssertFalse(close.waitForExistence(timeout: 2), "长内容在顶部下拉应关闭面板")
  }

  /// 组合场景：卡片容器页、底部面板容器页，各截一张图。
  func testCompositionScenariosOpen() {
    let app = XCUIApplication()
    app.launch()

    let cardRow = app.buttons["scenario-row-card"]
    XCTAssertTrue(cardRow.waitForExistence(timeout: 20), "卡片容器场景未出现")
    cardRow.tap()
    XCTAssertTrue(app.navigationBars["卡片容器"].waitForExistence(timeout: 20), "卡片容器页未出现")
    let cardShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    cardShot.name = "composition-card"
    cardShot.lifetime = .keepAlways
    add(cardShot)

    app.navigationBars.buttons.element(boundBy: 0).tap()
    let sheetRow = app.buttons["scenario-row-bottomSheet"]
    XCTAssertTrue(sheetRow.waitForExistence(timeout: 20), "底部面板容器场景未出现")
    sheetRow.tap()
    XCTAssertTrue(app.navigationBars["底部面板容器"].waitForExistence(timeout: 20), "底部面板容器页未出现")

    let open = app.buttons["打开组合面板"]
    XCTAssertTrue(open.waitForExistence(timeout: 20), "打开组合面板按钮未出现")
    open.tap()
    let close = app.buttons["关闭新建任务"]
    XCTAssertTrue(close.waitForExistence(timeout: 20), "组合面板未出现")
    Thread.sleep(forTimeInterval: 0.5)
    let sheetShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    sheetShot.name = "composition-sheet"
    sheetShot.lifetime = .keepAlways
    add(sheetShot)

    close.tap()
    XCTAssertFalse(close.waitForExistence(timeout: 2), "关闭后组合面板应消失")
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

  /// WDPullRefresh：全屏 List 下拉 → 松手触发一次刷新、计数 +1；刷新中截图供人工核对设计 32 的环。
  func testPullRefreshRingAndTrigger() {
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDPullRefresh"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDPullRefresh 行未出现")
    if !row.isHittable { app.swipeUp() }
    row.tap()

    let fullScreen = app.buttons["pull-refresh-fullscreen"]
    XCTAssertTrue(fullScreen.waitForExistence(timeout: 20), "全屏下拉演示入口未出现")
    fullScreen.tap()

    let scroll = app.descendants(matching: .any)
      .matching(identifier: "pull-refresh-fullscreen-scroll").firstMatch
    XCTAssertTrue(scroll.waitForExistence(timeout: 20), "全屏列表未出现")
    let count = app.staticTexts["pull-refresh-fullscreen-count"]
    XCTAssertTrue(count.waitForExistence(timeout: 20), "刷新计数未出现")
    XCTAssertEqual(count.label, "刷新 0 次")

    let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
    let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
    start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)

    // 松手后刷新中：品牌环应覆盖在列表上方（截图供人工核对 24pt / 2pt 环）。
    let refreshingShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    refreshingShot.name = "pull-refresh-refreshing"
    refreshingShot.lifetime = .keepAlways
    add(refreshingShot)

    let refreshed = app.staticTexts["刷新 1 次"]
    XCTAssertTrue(refreshed.waitForExistence(timeout: 5), "松开过阈值应触发一次刷新")
    XCTAssertEqual(refreshed.label, "刷新 1 次")

    // 刷新完成后环收起：再截一张，确认列表无残留位移。
    Thread.sleep(forTimeInterval: 0.5)
    let completedShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    completedShot.name = "pull-refresh-completed"
    completedShot.lifetime = .keepAlways
    add(completedShot)
    XCTAssertTrue(count.exists)
  }

  // MARK: - B20 键盘实证（A-8 / A-9 / A-10）

  // 口径：这三条交互此前只有「下标推进 / 换算」层的单测（A-8 arrowIndex、A-9 WDPickerMenuFocus、
  // A-10 WDDatePickerGrid.moved），**从未被真实按键事件驱动过**。这里用 XCUITest 的
  // typeKey(_:modifierFlags:) 发真硬件键盘事件，断言控件的**可观察副作用**：
  // 不调任何库内函数伪造断言，只看无障碍树（isSelected / value / 月份标题文案）。

  /// B20·A-8：分段控件 ←/→ 改变选中项；到端点再按一次停在端点，不环绕不越界。
  ///
  /// 详情页里同名段有三套（实时预览 1 套 + 实底/玻璃变体各 1 套，标签都是 今天/本周/全部）。
  /// 变体两套是常量绑定 —— 按键不可能改动它们，正好当「按键究竟打给了谁」的对照组：
  /// 只有实时预览那一套随按键变，才说明按键落点是它而不是某个变体。
  func testSegmentedControlArrowKeysSwitchSelection() throws {
    // 模拟器不可实证：typeKey 送不进 SwiftUI .onKeyPress（typeText 可进 TextField），
    // 待真机 + 完全键盘访问走查（证据见 docs/B20-EXIT-REPORT.md §4.1）。
    try XCTSkipIf(true, "模拟器不可实证：typeKey 无法驱动 SwiftUI .onKeyPress，待真机 FKA 走查")
    let app = XCUIApplication()
    app.launch()

    let row = app.buttons["component-row-WDSegmentedControl"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDSegmentedControl 行未出现")
    row.tap()
    XCTAssertTrue(
      app.navigationBars["WDSegmentedControl"].waitForExistence(timeout: 20), "详情未出现")

    let todays = app.buttons.matching(NSPredicate(format: "label == %@", "今天"))
    let weeks = app.buttons.matching(NSPredicate(format: "label == %@", "本周"))
    let alls = app.buttons.matching(NSPredicate(format: "label == %@", "全部"))
    XCTAssertGreaterThanOrEqual(todays.count, 3, "详情页应有三套同名分段（预览 + 两个变体）")
    XCTAssertGreaterThanOrEqual(weeks.count, 3, "「本周」段数量不足")
    XCTAssertGreaterThanOrEqual(alls.count, 3, "「全部」段数量不足")

    // 初始选中态：实时预览 = 今天；实底变体 = 本周（常量）；玻璃变体 = 今天（常量）。
    XCTAssertEqual(Self.selectedCount(weeks), 1, "初始应恰有一套选中「本周」（实底变体）")

    // 拿键盘焦点：按键只送给有焦点的那一套，所以先按一次 →，用「哪一套的选中项变了」
    // 反推出按键打在谁身上。详情页里有两套都选中「今天」（实时预览 + 玻璃变体），
    // 常量绑定的那套按什么都不会变 —— 逐个试，直到某一套真的被推动（不假设无障碍树顺序）。
    let todayCandidates = Self.selectedElements(todays)
    XCTAssertGreaterThanOrEqual(todayCandidates.count, 2, "初始应有两套分段选中「今天」（预览 + 玻璃变体）")

    var selectedWeek: XCUIElement?
    for candidate in todayCandidates {
      candidate.tap()
      pressKey(app, XCUIKeyboardKey.rightArrow)
      if Self.selectedCount(weeks) >= 2 {
        selectedWeek = Self.firstSelected(weeks)
        break
      }
      // 这套没被推动（多半是常量绑定的对照组）：把焦点还回去，试下一套。
      candidate.tap()
    }

    XCTAssertNotNil(selectedWeek, "按 → 后应有一整套分段选中「本周」（选中项随按键改变）")
    guard let week = selectedWeek else { return }
    XCTAssertEqual(Self.selectedCount(weeks), 2, "→ 只能推动一套分段的选中项（另一套是常量本周）")
    XCTAssertEqual(Self.selectedCount(todays), 1, "→ 后应只剩玻璃变体仍选中「今天」")

    // 同排（minY 相同）的三段属于同一套控件 ⇒ 用它的行定位「今天 / 全部」两个兄弟段。
    let rowY = week.frame.minY
    let today = Self.elementInRow(todays, y: rowY)
    let all = Self.elementInRow(alls, y: rowY)
    XCTAssertNotNil(today, "没找到与「本周」同排的「今天」段")
    XCTAssertNotNil(all, "没找到与「本周」同排的「全部」段")
    guard let todaySegment = today, let allSegment = all else { return }

    XCTAssertFalse(todaySegment.isSelected, "按 → 后同套的「今天」不应仍选中")

    pressKey(app, XCUIKeyboardKey.leftArrow)
    XCTAssertTrue(todaySegment.isSelected, "按 ← 后应回到「今天」")

    // 左端点：再按 ← 必须停住（不环绕到末段「全部」）。
    pressKey(app, XCUIKeyboardKey.leftArrow)
    XCTAssertTrue(todaySegment.isSelected, "左端点再按 ← 应停在「今天」")
    XCTAssertFalse(allSegment.isSelected, "左端点不得环绕到「全部」")
    XCTAssertEqual(Self.selectedCount(alls), 0, "左端点不得让任何一套选中「全部」")

    // 右端点：一路 → 到末段，再按一次 → 必须停住。
    pressKey(app, XCUIKeyboardKey.rightArrow)
    pressKey(app, XCUIKeyboardKey.rightArrow)
    XCTAssertTrue(allSegment.isSelected, "连按 → 应选中末段「全部」")
    pressKey(app, XCUIKeyboardKey.rightArrow)
    XCTAssertTrue(allSegment.isSelected, "右端点再按 → 应停在「全部」")
    XCTAssertFalse(todaySegment.isSelected, "右端点不得环绕到「今天」")
  }

  /// 当前选中该标签元素的个数（用于区分「常量绑定的对照组」与「真的被按键推动的那一套」）。
  private static func selectedCount(_ query: XCUIElementQuery) -> Int {
    var count = 0
    for index in 0..<query.count where query.element(boundBy: index).isSelected {
      count += 1
    }
    return count
  }

  /// 所有选中该标签的元素（按无障碍树顺序）。
  private static func selectedElements(_ query: XCUIElementQuery) -> [XCUIElement] {
    var elements: [XCUIElement] = []
    for index in 0..<query.count where query.element(boundBy: index).isSelected {
      elements.append(query.element(boundBy: index))
    }
    return elements
  }

  /// 第一个选中该标签的元素（nil = 一个都没选中）。
  private static func firstSelected(_ query: XCUIElementQuery) -> XCUIElement? {
    for index in 0..<query.count where query.element(boundBy: index).isSelected {
      return query.element(boundBy: index)
    }
    return nil
  }

  /// 与给定纵坐标同排的元素（同一套分段控件里的兄弟段）。
  private static func elementInRow(_ query: XCUIElementQuery, y: CGFloat) -> XCUIElement? {
    for index in 0..<query.count {
      let element = query.element(boundBy: index)
      if abs(element.frame.minY - y) < 1 {
        return element
      }
    }
    return nil
  }

  /// B20·A-9：菜单展开后 ↓ 移动键盘焦点，Enter 提交**当前焦点项**并关闭、只触发一次。
  ///
  /// 焦点在浮层里是自绘光环（不进无障碍树），所以「焦点移动」只能通过**提交结果**间接证明：
  /// 初始选中「家务」，↓ 一次后提交必须是「任务」——换了一格就说明 ↓ 真的移动了焦点。
  func testPickerMenuDownArrowThenEnterCommitsFocusedOption() throws {
    // 模拟器不可实证：typeKey 送不进 SwiftUI .onKeyPress（typeText 可进 TextField），
    // 待真机 + 完全键盘访问走查（证据见 docs/B20-EXIT-REPORT.md §4.1）。
    try XCTSkipIf(true, "模拟器不可实证：typeKey 无法驱动 SwiftUI .onKeyPress，待真机 FKA 走查")
    let app = XCUIApplication()
    app.launch()

    let probe = openPickerMenu(app)
    XCTAssertEqual(probe.trigger.value as? String, "家务", "菜单初始值应为「家务」")
    let inlineCount = probe.inlineCount

    pressKey(app, XCUIKeyboardKey.downArrow)
    pressKey(app, XCUIKeyboardKey.return)
    XCTAssertTrue(menuClosed(app, label: "任务", backTo: inlineCount), "Enter 后菜单应关闭")

    XCTAssertEqual(probe.trigger.value as? String, "任务", "Enter 应提交 ↓ 移动后的焦点项「任务」")

    // 「只触发一次」：值已经落在「任务」；再按一次 Enter 不得把值推到另一个选项
    // （若浮层在关闭后又被重开并继续推进焦点，值就会变成「出行」——那才是二次提交）。
    pressKey(app, XCUIKeyboardKey.return)
    XCTAssertEqual(probe.trigger.value as? String, "任务", "重复 Enter 不得二次提交")
  }

  /// B20·A-9：↑ 从首项回绕到末项（首尾回绕）。
  ///
  /// 初始焦点 = 选中项「家务」（首项）；↑ 一次按环形推进应回绕到末项「出行」。
  func testPickerMenuUpArrowWrapsToLastOption() throws {
    // 模拟器不可实证：typeKey 送不进 SwiftUI .onKeyPress（typeText 可进 TextField），
    // 待真机 + 完全键盘访问走查（证据见 docs/B20-EXIT-REPORT.md §4.1）。
    try XCTSkipIf(true, "模拟器不可实证：typeKey 无法驱动 SwiftUI .onKeyPress，待真机 FKA 走查")
    let app = XCUIApplication()
    app.launch()

    let probe = openPickerMenu(app)
    XCTAssertEqual(probe.trigger.value as? String, "家务", "菜单初始值应为「家务」")
    let inlineCount = probe.inlineCount

    pressKey(app, XCUIKeyboardKey.upArrow)
    pressKey(app, XCUIKeyboardKey.return)
    XCTAssertTrue(menuClosed(app, label: "任务", backTo: inlineCount), "Enter 后菜单应关闭")

    XCTAssertEqual(probe.trigger.value as? String, "出行", "↑ 应从首项回绕到末项「出行」")
  }

  /// B20·A-9：Esc 关闭菜单，且**不改变当前值**（即便先按过 ↓ 移动了焦点）。
  func testPickerMenuEscapeClosesWithoutChangingValue() throws {
    // 模拟器不可实证：typeKey 送不进 SwiftUI .onKeyPress（typeText 可进 TextField），
    // 待真机 + 完全键盘访问走查（证据见 docs/B20-EXIT-REPORT.md §4.1）。
    try XCTSkipIf(true, "模拟器不可实证：typeKey 无法驱动 SwiftUI .onKeyPress，待真机 FKA 走查")
    let app = XCUIApplication()
    app.launch()

    let probe = openPickerMenu(app)
    XCTAssertEqual(probe.trigger.value as? String, "家务", "菜单初始值应为「家务」")
    let inlineCount = probe.inlineCount

    pressKey(app, XCUIKeyboardKey.downArrow)
    pressKey(app, XCUIKeyboardKey.escape)

    XCTAssertTrue(menuClosed(app, label: "任务", backTo: inlineCount), "Esc 后菜单应关闭")
    XCTAssertEqual(probe.trigger.value as? String, "家务", "Esc 不得改变当前值（焦点移动不等于提交）")
  }

  /// B20·A-10：日期网格 → 每次一天；跨月时月份标题随之切换。
  ///
  /// 焦点日在无障碍树里只有高亮圈（纯视觉），读不出去；可断言的可观察量是**月份标题**：
  /// 从今天起一路按 → 到下月第 1 天，标题必须换月，且按的次数等于「到下月 1 日的天数」
  /// —— 正好卡死「一次按键 = 一天」。
  func testDatePickerRightArrowMovesOneDayAndFlipsMonthTitle() throws {
    // 模拟器不可实证：typeKey 送不进 SwiftUI .onKeyPress（typeText 可进 TextField），
    // 待真机 + 完全键盘访问走查（证据见 docs/B20-EXIT-REPORT.md §4.1）。
    try XCTSkipIf(true, "模拟器不可实证：typeKey 无法驱动 SwiftUI .onKeyPress，待真机 FKA 走查")
    let app = XCUIApplication()
    app.launch()

    let monthHeader = openDatePickerSheet(app)
    let startMonth = monthHeader.label
    let expected = Self.pressesToNextMonth(stepDays: 1)

    var presses = 0
    while presses < Self.maxDayPresses {
      pressKey(app, XCUIKeyboardKey.rightArrow)
      presses += 1
      if monthHeader.label != startMonth {
        break
      }
    }

    XCTAssertNotEqual(monthHeader.label, startMonth, "按 → 跨月后月份标题应跟着切换")
    XCTAssertLessThanOrEqual(
      abs(presses - expected), 1,
      "→ 每次应只前进一天：期望 \(expected) 次，实际 \(presses) 次")
  }

  /// B20·A-10：日期网格 ↓ 每次一周；跨月时月份标题随之切换。
  ///
  /// 与上一条同源：起点都是今天，所以按的次数只要约等于 ⌈到下月 1 日的天数 / 7⌉，
  /// 就同时证明了「↓ = 一周」与「跨月翻页」；并且这个次数必然不超过 5（一个月最多 31 天）。
  func testDatePickerDownArrowMovesOneWeekAndFlipsMonthTitle() throws {
    // 模拟器不可实证：typeKey 送不进 SwiftUI .onKeyPress（typeText 可进 TextField），
    // 待真机 + 完全键盘访问走查（证据见 docs/B20-EXIT-REPORT.md §4.1）。
    try XCTSkipIf(true, "模拟器不可实证：typeKey 无法驱动 SwiftUI .onKeyPress，待真机 FKA 走查")
    let app = XCUIApplication()
    app.launch()

    let monthHeader = openDatePickerSheet(app)
    let startMonth = monthHeader.label
    let expected = Self.pressesToNextMonth(stepDays: Self.weekLength)

    var presses = 0
    while presses < Self.maxWeekPresses {
      pressKey(app, XCUIKeyboardKey.downArrow)
      presses += 1
      if monthHeader.label != startMonth {
        break
      }
    }

    XCTAssertNotEqual(monthHeader.label, startMonth, "按 ↓ 跨月后月份标题应跟着切换")
    XCTAssertLessThanOrEqual(
      abs(presses - expected), 1,
      "↓ 每次应前进一周：期望 \(expected) 次，实际 \(presses) 次")
    XCTAssertLessThanOrEqual(presses, Self.maxWeekPresses, "↓ 若按月步进，次数会明显超出上限")
  }

  // MARK: - B20 键盘用例的支撑（不改变既有用例行为）

  /// 按一次键并等一小会儿让布局/动画落定。
  ///
  /// `typeKey(_:modifierFlags:)` 的入参在 Xcode 26 是类型化的 `XCUIKeyboardKey`（不再是 `String`），
  /// 所以这里按真实类型收参，避免退化成字符串常量拼接。
  private func pressKey(_ app: XCUIApplication, _ key: XCUIKeyboardKey) {
    app.typeKey(key, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  /// 展开菜单的结果：触发入口 + **展开前**的同名选项数量（判断「菜单是否已关闭」的基线）。
  private struct PickerMenuProbe {
    let trigger: XCUIElement
    let inlineCount: Int
  }

  /// 进 WDPicker 详情页并展开菜单形态的弹出层；返回触发入口与展开前的基线数量。
  private func openPickerMenu(_ app: XCUIApplication) -> PickerMenuProbe {
    let row = app.buttons["component-row-WDPicker"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDPicker 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDPicker"].waitForExistence(timeout: 20), "详情未出现")

    // 详情页里有三个 WDPicker（菜单 / 滚轮 / 内联），标签都是「分类」；第 0 个是实时预览。
    let triggers = app.buttons.matching(NSPredicate(format: "label == %@", "分类"))
    XCTAssertGreaterThanOrEqual(triggers.count, 1, "菜单触发入口未出现")
    let trigger = triggers.element(boundBy: 0)
    XCTAssertTrue(trigger.waitForExistence(timeout: 20), "菜单触发入口未出现")

    let inlineCount = menuOptions(app, label: "任务").count
    trigger.tap()
    var expanded = false
    for _ in 0..<20 {
      if menuOptions(app, label: "任务").count > inlineCount {
        expanded = true
        break
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    XCTAssertTrue(expanded, "菜单未展开（展开后同名选项应多出一份）")
    return PickerMenuProbe(trigger: trigger, inlineCount: inlineCount)
  }

  /// 某标签的选项按钮集合（菜单展开后会多一份；内联形态本来就有平铺的一份）。
  private func menuOptions(_ app: XCUIApplication, label: String) -> XCUIElementQuery {
    app.buttons.matching(NSPredicate(format: "label == %@", label))
  }

  /// 菜单是否已关闭（同名选项回落到展开前的数量）。
  private func menuClosed(_ app: XCUIApplication, label: String, backTo inlineCount: Int) -> Bool {
    for _ in 0..<20 {
      if menuOptions(app, label: label).count == inlineCount {
        return true
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    return false
  }

  /// 进 WDDatePicker 详情页并打开月历弹层；返回月份标题元素（标签形如 2026年11月）。
  private func openDatePickerSheet(_ app: XCUIApplication) -> XCUIElement {
    let row = app.buttons["component-row-WDDatePicker"]
    XCTAssertTrue(row.waitForExistence(timeout: 20), "WDDatePicker 行未出现")
    row.tap()
    XCTAssertTrue(app.navigationBars["WDDatePicker"].waitForExistence(timeout: 20), "详情未出现")

    // 详情页里「截止日期」出现两次（实时预览 + 变体），第 0 个是实时预览。
    let triggers = app.buttons.matching(NSPredicate(format: "label == %@", "截止日期"))
    XCTAssertGreaterThanOrEqual(triggers.count, 1, "日期触发入口未出现")
    triggers.element(boundBy: 0).tap()

    // 月份标题是弹层里唯一以「月」结尾的静态文本（日期单元的标签以星期结尾）。
    let header = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "月")).firstMatch
    XCTAssertTrue(header.waitForExistence(timeout: 20), "月历弹层未出现（月份标题缺失）")
    return header
  }

  /// 一周 7 天（与 WDDatePickerGrid.weekLength 同值；这里只用于断言口径，不参与实现）。
  private static let weekLength = 7  // wd-structure-check:disable R7 — 设计 23 §3 的 7 列
  /// → 的按次上限：一个月最多 31 天，留 1 次余量。
  private static let maxDayPresses = 32
  /// ↓ 的按次上限：⌈31 / 7⌉ = 5，留 1 次余量。
  private static let maxWeekPresses = 6

  /// 从今天跨到下月 1 日需要按几次（stepDays = 每次按键前进的天数）。
  private static func pressesToNextMonth(stepDays: Int) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    guard let monthEnd = calendar.dateInterval(of: .month, for: today)?.end else {
      return 0
    }
    let days =
      calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: monthEnd)).day
      ?? 0
    let steps = Double(days) / Double(max(stepDays, 1))
    return Int(steps.rounded(.up))
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
