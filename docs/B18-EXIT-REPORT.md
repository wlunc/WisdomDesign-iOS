# B18 出口报告 —— 代码欠账收口（2026-11-20）

> 依据：项目负责人 2026-11-20「补上代码欠账」；承接 `docs/DEBT-LEDGER.md` 的 A 类清单。
> 关联：`docs/B18-SIGNATURE-FREEZE.md`（签名冻结）、`CHANGELOG.md`、`docs/DEBT-LEDGER.md`（状态回写）。
> **判定环境**：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，711BF16D-…）／Swift 6；DSH workspace-write 沙箱。

---

## 1. 交付范围（台账条目 → 本批状态）

| 台账 # | 项 | 交付 | 状态 |
| --- | --- | --- | --- |
| A-1 | `WDSlider` 焦点光环是死代码 | 焦点经 `WDAccessibilityFocusHost` 从表示层回写；单值与范围两端都挂光环（外扩 3pt / 32% / 160ms，共用 `WDFocusRingStyle`） | ✅ 代码；真机【未验证】 |
| A-2 | `WDSlider` 松手后不播报 | 新增 `announcementText`（单值）/ `rangeAnnouncementText`（范围）注入点；松手播一次 polite，经 `WDAnnouncementThrottle` 节流 | ✅ 代码 + 纯逻辑测试 |
| A-3 | `WDButton` 亮度 96% / 聚焦光环 / 悬停 98% | 按下与悬停用黑色蒙层做乘法压暗（96→4%、98→2%）；聚焦光环挂胶囊 | ✅ 代码 |
| A-4 | `WDIconButton` 聚焦光环 | 挂容器形状（圆 / 圆角方） | ✅ 代码 |
| A-5 | `WDCheckbox` 按下缩放 0.90 | `onLongPressGesture(minimumDuration: .infinity)` 的 `onPressingChanged` 拿按下态（不是自造 `DragGesture`） | ✅ 代码 |
| A-6 | `WDToolbar` 按下 0.94 + `fill.pressed` | 新增 `WDToolbarItemPressStyle`（`.plain` 拿不到按下态，必须走 ButtonStyle）+ 聚焦光环 | ✅ 代码 |
| A-7 | `WDTabBar` 角标未并入朗读 | 有角标时整项挂 `accessibilityValue`（`WDBadgeValue.accessibilityText`，dot/0 不挂） | ✅ 代码 + 测试 |
| A-12 | 进度阈值播报 / Toast·Banner 的 polite 播报 | `WDProgressBar` / `WDProgressRing` 跨 25/50/75/100 播一次；`WDToast` 出现、`WDBanner` 出现各 polite 一次 | ✅ 代码 + 测试 |
| A-15 | 范围滑杆零覆盖 | 预览加范围样例；demo 新增「范围滑杆」场景（连续 + 步长两例） | ✅ 代码；快照【未验证】 |
| A-16 | B15 滚动联动在 demo 零使用 | demo 新增「滚动联动」场景（真实 `ScrollView` + `.wdScrollOffsetY`，Nav 折叠 / Tab 收起 / FAB 缩小与遮罩） | ✅ 代码 |
| A-17 | 过期提示无样例 | 预览与 demo 各加一例（danger 色 + hint） | ✅ 代码 |

**未做（仍在台账）**：A-8 `WDSegmentedControl` 段间拖动、A-9 `WDPicker` 键盘环形焦点、A-10 `WDDatePicker` 方向键网格导航、A-11 `WDAvatar` 成员配色/照片、A-13 `WDCard.media`、A-14 `WDToolbar` 长按 tooltip。

**API**：符号数仍为 **1380**（只给既有 init 追加带默认值的参数，不新增符号名）；`Scripts/dump-api.sh` 重跑**零 diff**。

---

## 2. 验证证据

| # | 判据 | 命令 | 结果 |
| --- | --- | --- | --- |
| ① | 结构门禁 R1–R21 | `Scripts/check-structure.sh --strict` | `files=188 rules=22 errors=0 warnings=0 suppressed=256` |
| ② | 格式门禁 | `Scripts/check-format.sh` | `OK（204 个文件全部通过 --strict）` |
| ③ | 库 + 测试目标编译 | `xcodebuild build-for-testing … -disable-sandbox` | **exit 0，0 error** |
| ④ | demo app 编译（含新场景） | `xcodebuild build -project Examples/WisdomUIDemo…` | **exit 0，0 error** |
| ⑤ | API 基线 | `Scripts/dump-api.sh` | **零 diff（symbols=1380）** |
| ⑥ | 单测执行 | `xcodebuild test-without-building …` | **【未验证】** 沙箱禁 PTY（`openpty: Operation not permitted`）；full-access 审批本轮仍未应答 |
| ⑦ | 8 态快照 / demo 审计 | `-only-testing:WisdomUISnapshotTests` / `WisdomUIDemoUITests` | **【未验证】** 同 ⑥ |

**新增单测**：`Tests/WisdomUITests/Components/WDB18DebtTests.swift`（9 条，纯逻辑与常量；全套 335 → **344**）。

---

## 3. 设计口径与取舍（逐条给依据）

| 项 | 依据 | 取舍 |
| --- | --- | --- |
| 按下亮度 96% 用黑色蒙层 | 设计 01 §5「亮度降到 96%」 | `.brightness` 是加法位移，表达不了「乘 0.96」；4% 黑蒙层等价于对不透明像素做乘法压暗（与 `WDCard` 同口径） |
| 悬停只在有指针时生效 | 设计 01 §5「仅指针设备」 | `onHover` 在触屏上是空操作，不会带来额外视觉 |
| 复选框按下用 `onPressingChanged` | 设计 06 §5「缩放 0.90」 | `ToggleStyle.Configuration` 没有 `isPressed`；`onLongPressGesture(minimumDuration:)` 的 `onPressingChanged` 是系统按下跟踪，**不是** SPEC §3.4 禁止的自造 `DragGesture` |
| 工具栏按下必须走 ButtonStyle | 设计 35 §5「缩放 0.94 + `fill.pressed`」 | `.buttonStyle(.plain)` 拿不到按下态；新增私有 `ButtonStyle`，公开面不变 |
| 滑杆焦点走 Binding 而不是环境键 | 设计 08 §5 | `accessibilityRepresentation` 内部写的环境不会传回宿主视图；Binding 能穿过表示层（也避开 R18「组件写环境」） |
| 阈值播报用现有 `WDAnnouncementThrottle` | 设计 15 §10 / `06-accessibility.md` §3.5 | 复用「向上跨阈值 + 最小间隔」两条闸门，不新造节流 |

---

## 4. 未验证台账（**不得写成「已通过」**）

| # | 项 | 现状 | 回填责任 / 时点 |
| --- | --- | --- | --- |
| U-B18-1 | 单测复跑（344 条） | 【未验证】沙箱禁 PTY；full-access 审批未应答 | ios-lead / PR 门禁 |
| U-B18-2 | 8 态快照零漂移 + 新增场景快照 | 【未验证】本批未新增基线 | ios-lead / nightly |
| U-B18-3 | 真机 VoiceOver：光环是否随焦点出现、松手播报是否只播一次、角标朗读顺序 | 【未验证】无 USB 真机 | 真机走查 / 发布前层 |
| U-B18-4 | demo 新增三场景的审计与目视 | 【未验证】编译通过但未跑 UITest | demo UITest |

---

## 5. 复跑命令

```bash
cd iOS
Scripts/ci.sh pr                                   # 结构 + 格式 + 编译 + 单测 + dump-api 零 diff
xcodebuild test -scheme WisdomDesign-iOS-Package -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
```
