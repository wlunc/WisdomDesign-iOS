# B17 出口报告 —— 遗留收口（2026-11-20）

> 里程碑：B 类遗留的收口批｜报告日期：**2026-11-20**
> 依据：项目负责人 2026-11-20「继续完成」；承接 `docs/B10-B16-EXIT-REPORT.md` §7 与 `docs/M5-EXIT-REPORT.md` §4。
> 关联：`docs/B17-SIGNATURE-FREEZE.md`（签名冻结）、`docs/B17-CONTRACT-CHANGE-REQUEST.md`（契约增量，待落库）、`CHANGELOG.md`。
> **判定环境**：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）／Swift 6.3.3；DSH workspace-write 沙箱。

---

## 1. 交付范围（清单 → 批次 → 状态）

| 清单条目 | 批次 | 交付 | 状态 |
| --- | --- | --- | --- |
| B15 遗留 · `WDTabBar` 的 `item.label` 未挂 `accessibilityLabel` | B17-1 | 显式标签（收起态标签被压到 0 时仍有稳定名称） | ✅ 代码；真机读屏【未验证】 |
| `WDFAB` 焦点归还 | B17-2 | 收起后把读屏焦点还给主按钮（含遮罩 / escape / 子操作 / 主按钮四种收起路径） | ✅ 代码；真机读屏【未验证】 |
| `WDDatePicker` 跨午夜过期翻转 / 读屏「已过期」 | B17-3 | 系统 `NSCalendarDayChanged` + 回到前台刷新（**零计时器**）；新增 `expiredAccessibilityHint` 注入点 | ✅ 代码 + 纯逻辑可测；真机读屏【未验证】 |
| `WDSlider` 范围双手柄 | B17-4 | `init(range:…)`：两端不交叉 / 最小间隔 1 步长 / 松手吸附 / 点轨道 200ms / 两端各自可调整语义 | ✅ 代码 + 纯逻辑与尺寸测试（执行见 §3） |
| `WDSlider` 键盘焦点光环 | — | 平台限制，只记录 | ⏸ 维持 `docs/B3-PLATFORM-LIMITS.md` L-5 |
| `WDCard` media 变体 | — | **本批不做**：设计 17 未给图片几何（宽高比 / 通栏 / 失败态），且 F-15 的 21 个槽位词表没有 `media` | 📝 登记（§5-①） |
| `WDToolbar` 长按 tooltip | — | **本批不做**：`Button` 与长按手势的仲裁需真机/UITest 回归；无该条件时实现会带「长按也执行 action」的风险 | 📝 登记（§5-②） |

**API**：**1290 → 1380 符号（+90）**。B10–B16 的手工基线（当时计 1378）在完整环境用 `Scripts/dump-api.sh` 规范化后为 **1379**（U-B-3 闭合）；B17 新增 1 个 init（范围）+ 1 个既有 init 的追加参数（过期提示，符号数不变）。**无删除、无改名。**

---

## 2. 验证证据（逐条给命令与结果）

| # | 判据 | 命令 | 结果 |
| --- | --- | --- | --- |
| ① | 结构门禁 R1–R21 | `Scripts/check-structure.sh --strict` | `files=186 rules=22 errors=0 warnings=0 suppressed=246` |
| ② | 格式门禁 | `Scripts/check-format.sh` | `OK（202 个文件全部通过 --strict）` |
| ③ | 库 + 测试目标编译（模拟器 / Swift 6 / 含 `#Preview` 宏） | `xcodebuild build-for-testing … OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox'` | **exit 0，0 error**（沙箱内会拦 `swift-plugin-server`，加该 flag 后可在 workspace-write 下完成编译） |
| ④ | API 基线 | `Scripts/dump-api.sh` | **与基线零 diff（symbols=1380）** |
| ⑤ | 单测执行 | `xcodebuild test-without-building …` | **【未验证】** 本机沙箱禁 PTY（`openpty: Operation not permitted`）；需要 `danger-full-access` 审批，本轮审批不可用（见 §3） |
| ⑥ | 8 态快照零漂移 | `-only-testing:WisdomUISnapshotTests` | **【未验证】** 同 ⑤；本批未新增/改动快照样例与基线 |

**B10–B16 首次完整环境实跑**（2026-11-20 19:16，full-access 一次）：`330 tests in 44 suites`，**9 个 issue**，集中在 4 个文件：
`WDPullRefreshTests`（1）、`WDNavigationBarTests`（1）、`WDAvatarStackTests`（7）。根因与修复见 §4；**修复后未复跑（审批不可用）**。

---

## 3. 执行环境限制（决定哪些结论能写「已通过」）

| 限制 | 实测证据 | 影响 |
| --- | --- | --- |
| 模拟器单测无法在沙箱内启动 | `xcodebuild test` 报 `Pseudo Terminal Setup Error`；`script -q /dev/null` 报 `openpty: Operation not permitted` | 单测与快照本机未执行 |
| 宏插件在沙箱内失败 | `swift-plugin-server … sandbox_apply: Operation not permitted` | `-disable-sandbox` 后编译通过（`build-for-testing` 可跑） |
| full-access 审批 | 本轮两次申请均超时（无应答） | 无法复跑 ⑤⑥；不在报告里写「已通过」 |
| `simctl spawn` 直跑测试 bundle | `Mach-O 64-bit bundle` ⇒ `Exec format error` | 需要 xctest 宿主，不采用 |

**结论口径**：代码与静态门禁 = 已验证；**单测执行、快照样片、真机 VoiceOver = 【未验证】**，按 `docs/SPEC.md` §8.2 记账。

---

## 4. 修复 B10–B16 的 3 处红灯

| # | 失败 | 根因 | 修复 |
| --- | --- | --- | --- |
| F-1 | `WDPullRefreshTests.relayRoundTrip`：第二次 `takeOutcome()` 仍返回 `.failed` | 注释写「读后即清」，实现只出栈未清值 | `takeOutcome` 读出后置 `nil` |
| F-2 | `WDNavigationBarTests.largeTitleCollapsesInView`：折叠后 85 ≠ 44 | `.frame(minHeight: 0)` 只是下限，压不到 0；大标题行仍占内容高 | 联动路径改**定高** `frame(height:)`；不联动路径保持 `minHeight`（U7 只增不裁） |
| F-3 | `WDAvatarStackTests` 3 条无障碍断言：`accessibilityElements` 为空 | 无 AX 客户端的单测宿主里 SwiftUI 不填充元素表（`WDCardTests` 已登记同一限制） | 读不到元素表时跳过并注明真机走查；不制造假红 |

> F-2 的修复依据：`.frame(minHeight:)` 不会压缩子视图（VStack 的内容高仍参与布局），所以折叠态整栏 = 44 + 大标题行内容高（实测多 41）。改定高后行高按进度归 0，标题靠 `offset` 上移 + 淡出，不裁字。

---

## 5. 本批未纳入项（逐条给解除条件）

| # | 项 | 不做的具体原因 | 解除条件 |
| --- | --- | --- | --- |
| ① | `WDCard` `media` 变体 | 设计 17 §3 只写「所有变体内边距 16」、§4 写「顶部图片 + 文字区」，**未给图片宽高比、是否通栏、加载失败态**；F-15 的 21 个槽位词表没有 `media`，新增槽位属 U 系列 | 设计给图片几何 + 架构师/android-lead 确认槽位词；随后按 B17 同流程开工 |
| ② | `WDToolbar` 长按 tooltip（设计 35 §8） | `Button` 上叠 `onLongPressGesture` 时，长按抬手是否也触发 action 取决于手势仲裁；本轮无真机/UITest 手势回归条件 | 给出可执行的手势回归（或设计接受「长按也触发 action」） |
| ③ | `WDSlider` 键盘焦点光环 | UISlider 无可观测的键盘聚焦事件（平台限制） | 见 `docs/B3-PLATFORM-LIMITS.md` L-5 |

---

## 6. 未验证台账（**不得写成「已通过」**）

| # | 项 | 现状 | 回填责任 / 时点 |
| --- | --- | --- | --- |
| U-B17-1 | 单测复跑（335 条，含新增范围用例） | 【未验证】修复后未复跑（审批不可用） | ios-lead / PR 门禁 |
| U-B17-2 | 8 态快照零漂移 | 【未验证】本机未跑快照套件；未改基线 | ios-lead / nightly |
| U-B17-3 | 范围滑杆的触摸/读屏实测 | 【未验证】纯逻辑与尺寸已测；UIControl 的命中、长按/拖动、两个可调整元素需真机 | 真机 USB 人审 / demo UITest |
| U-B17-4 | TabBar 收起态读屏名称、FAB 焦点归还 | 【未验证】 | 真机 VoiceOver 走查 |
| U-B17-5 | 跨午夜过期翻转的真实时钟行为 | 【未验证】系统 `NSCalendarDayChanged` 的投递时点只能在真机/长驻进程观察 | 真机（改系统时间或跨日） |
| U-B17-6 | 契约 yaml 落库（WDSlider / WDDatePicker）与 C-15 第 08 行增补 | 待架构师 | 架构师 |

---

## 7. 复跑命令（完整环境）

```bash
cd iOS
Scripts/ci.sh pr                                   # 结构 + 格式 + 编译 + 单测 + dump-api 零 diff + 覆盖率
Scripts/dump-api.sh                               # 复核零 diff（symbols=1380）
xcodebuild test -scheme WisdomDesign-iOS-Package -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests   # 8 态快照零漂移
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
```
