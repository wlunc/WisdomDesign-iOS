# B19 出口报告 —— 验证层首次跑通 + 三处回归修复（2026-11-20）

> 依据：项目负责人 2026-11-20「继续台账里未完成的」；承接 `docs/DEBT-LEDGER.md` 的 **C 类验证欠账**与 §1.5 的回归。
> 关联：`docs/DEBT-LEDGER.md`（状态回写）、`CHANGELOG.md`、`docs/B19-SIGNATURE-FREEZE.md`（本批零 API 变化）。
> **判定环境**：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）／Swift 6.3；DSH **danger-full-access**（PTY 可用）。

---

## 1. 本批做了什么（不是再写一遍代码，是把验证层跑起来）

台账 C-1～C-3 三条自 M2 起一直写着【未验证】，原因是执行沙箱禁 PTY（`openpty: Operation not permitted`）。
本批先**证伪该前提**：`danger-full-access` 下 `script -q /dev/null` 返回 0 ⇒ 单测、快照、UITest 三条门禁都能跑。
于是把三条全部跑通，并**依据实跑结果**修掉门禁抓出的三处真实回归。

| # | 台账项 | 本批结果 |
| --- | --- | --- |
| C-1 | 单测复跑 | ✅ **344 passed / 0 failed**（344 条 `@Test`，45 个 suite，17.6 s） |
| C-2 | 8 态快照零漂移 | ✅ **45 tests / 18 suites 全过**，360 张基线（修完 §3 的三处回归后） |
| C-3 | demo 无障碍审计 | ✅ **18 tests / 0 failures**（262.3 s；contrast / hitRegion / textClipped / dynamicType 四类目） |
| — | Foundation 覆盖率 | **95.46%**（610/639，排除 `generated/`；门槛 80%） |
| — | API 基线 | **符号 1380**，`dump-api` 重跑与文件**零 diff**（本批未新增/未改动任何公开符号）。注：`ci.sh pr` 的 `git diff --exit-code` 仍会红 —— 原因是 **B10–B19 全部改动都还没提交**（工作区 68 个文件），不是基线不一致 |
| — | 结构 / 格式 | `files=188 rules=22 errors=0 warnings=0` ／ `204 文件全部通过 --strict` |

**PR 门禁耗时（warm）**：PR-0 2.13 s ＋ PR-1a 2.72 s ＋ PR-1b 21.9 s ＋ PR-2 1.55 s ＋ 覆盖率 0.63 s ≈ **29 s**。

---

## 2. 交付明细

| 项 | 内容 |
| --- | --- |
| 回归修复 | 三处，见 §3（`WDA11yRuntime` 焦点闸门、导航栏内联标题、TabBar 阴影） |
| 新增内部件 | `Internal/A11y/WDFocusRing.swift` 增 `WDA11yRuntime` ＋ `View.wdAccessibilityFocused(_:)` / `(_:equals:)`（**全 internal，零 public**） |
| 测试 | 启用 `WDSearchFieldTests.defaultPathKeepsFieldHeight`（此前 `.disabled("尺寸依赖宿主布局…")`，现可跑且绿） |
| 基线 | `WDFAB` 8 张**重录**（B15 的 18pt 底部留白 ⇒ 内容上移 36px，旧基线滞后）；`manifest.json` 校正（补 8 张 `progressbar-indeterminate`、刷新 16 处 sha256） |
| API | **无变化**（1380，零 diff） |

---

## 3. 三处回归（**门禁抓出来的，不是猜的**）

### 3.1 B-4-① 读屏焦点绑定 × `ImageRenderer` = 整棵子树渲染空白

**现象**：B18 合入后首次跑快照，`Banner` / `Toast` / `EmptyState` / `DatePicker` 的 8 态**全部**像素差 1.0（= 尺寸或内容完全不符）。

**定位（8 个对照探针，全部实跑）**：

| 探针 | 内容 | 结果 |
| --- | --- | --- |
| p1 | 普通 `Button` + `.accessibilityFocused` | **空白** |
| p2 | 同上 + `.accessibilityElement(children: .contain)` | 空白 |
| p3 | 同上包 `Group` | 空白 |
| p4 | `.accessibilityRepresentation` 内挂焦点 | 只渲染被表示的那一层 |
| p5 | 一个子视图挂焦点、兄弟不挂 | 挂的那个消失、兄弟正常 |
| p6/p7/p8/p9 | 焦点挂 `.overlay` ／ 表示层内 `Button` ／ 背景代理 ／ 1×1 兄弟 | 均**无法**同时满足「能渲染 + 语义正确」 |
| h1–h4 | 同一批改用层级渲染器（`UIHostingController` + `drawHierarchy`） | **正常** |

⇒ 结论：SwiftUI 的 `@AccessibilityFocusState` 与 `ImageRenderer` 不兼容；只要挂上绑定，`ImageRenderer` 就把该子树当不可渲染内容。

**修法**：焦点绑定本来就只在读屏运行时才有意义（设计 06 §5 的「聚焦光环」指**读屏聚焦**）。
新增运行状态闸门 `WDA11yRuntime.isAssistiveTechRunning`（`isVoiceOverRunning || isSwitchControlRunning`），
读屏未开启时**不挂绑定**（像素与 B18 之前一致），开启后才挂（光环与焦点归还照常工作）。
对外只暴露两个 **internal** 修饰符，`WDAccessibilityFocusHost` 与 `WDFAB` 的四处调用全部改走它们。

**为什么不改测试渲染器了事**：`ImageRenderer` 是快照门禁的默认渲染器（360 张里绝大多数走它）。
让组件在读屏关闭时也能被 `ImageRenderer` 正确渲染，才是任何消费方（预览、截图、第三方核对）都能受益的修法。

### 3.2 B-4-② `WDNavigationBar` 的 `.inline` / `.standard` 模式标题整条透明（B15 引入）

**现象**：重录后对比实拍，`navigationbar-light-default-ltr` 里「家庭」「任务」两处标题**完全消失**（第一行只剩返回箭头与编辑图标）。

**根因**：B15 给内联标题加了 `.opacity(progress)`（大标题折叠时淡入）。但 `.inline` / `.standard` 模式**没有大标题**，
`titleProgress` 在该路径恒返回 0（「不联动 ⇒ 保持展开」）⇒ 内联标题被乘成 **0 透明**。

**修法**：折叠只属于 `.largeTitle` 模式 —— 新增 `inlineTitleOpacity`（非大标题模式恒 1）、
`isInlineTitleShowing` 同步为 `mode != .largeTitle || progress > 0`。

**影响面**：导航栏两个最常用模式此前**没有任何标题**；因为快照门禁从未执行过，这个缺陷从 B15 起没被发现。

### 3.3 B-4-③ `WDTabBar` 胶囊阴影被 `.clipped()` 裁掉（B15 引入）

**现象**：`tabbar-light-default-ltr` 底边一圈 `elevation.2` 阴影消失（像素差 0.7%，实拍可见底边「贴平」）。

**根因**：B15 为「滚动收起」在容器上加了 `.frame(maxHeight:) + .clipped()`；阴影画在视图边界**之外**，被一并裁掉。

**修法**：去掉容器级 `.clipped()`。收起时的裁切本来就由标签行自己的 `.frame(maxHeight: 0) + .clipped()` 完成，容器不需要再裁一次。

---

## 4. 基线变更（逐张给理由，不是「重录洗绿」）

| 文件 | 变更 | 理由 |
| --- | --- | --- |
| `fab-*.png`（8 张） | 重录 | B15 给组件加了 **18pt 底部留白**（设计 36 §6「距底部安全区 18」）；八态内容整体上移 **36 px**（= 18 × 2 倍缩放）。旧基线记录于该改动之前 ⇒ **基线滞后**，已按设计值核对 |
| `navigationbar-*.png` / `tabbar-*.png` | **未变更** | §3.2 / §3.3 修完后与旧基线**逐像素一致** ⇒ 反证这两处是回归、且已恢复原状 |
| `emptystate-*` / `banner-*` / `toast-*` / `datepicker-*` | **未变更** | §3.1 修完后与旧基线一致（同因） |
| `manifest.json` | 校正 | 补 8 张 `progressbar-indeterminate-*`（此前未登记）；刷新 16 处 sha256（含 fab 8 张与 progressbar 8 张） |

> **判据**：修完三处回归后，除 fab 8 张外**全部基线零改动即绿** —— 若是「漂移就重录」，不会出现这种结果。

---

## 5. 未验证台账（**不得写成「已通过」**）

| # | 项 | 现状 | 回填责任 / 时点 |
| --- | --- | --- | --- |
| U-B19-1 | 真机 VoiceOver：光环随焦点出现、松手播报只播一次、角标朗读顺序 | 【未验证】无 USB 真机 | 真机走查 / 发布前层 |
| U-B19-2 | `WDA11yRuntime` 闸门的真机验证：读屏开启时焦点绑定确实生效 | 【未验证】模拟器里 `isVoiceOverRunning` 恒 false，闸门分支**未被真机走过** | 真机走查（M6 §3.2 的 V1–V8） |
| U-B19-3 | Thinning 增量、真机 hitch / 首帧 | 【未验证】未签名归档不能导出 thinned IPA | 发布前层 |
| U-B19-4 | 双端同 tag `v1.0.0` | ❌ 不成立：Android 仓仍停在 M0 | Android 追平 |

---

## 6. 复跑命令

```bash
cd iOS
Scripts/ci.sh pr                                   # 结构 + 格式 + 编译 + 344 单测 + dump-api 零 diff + 覆盖率
xcodebuild test -scheme WisdomDesign-iOS-Package \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
```

> 三条都**必须**在允许 PTY 的环境跑（本仓历史失败原因就是沙箱禁 PTY，不是代码问题）。
