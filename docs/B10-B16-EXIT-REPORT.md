# B10–B16 出口报告 —— 纯代码可继续项（2026-11-15）

> 里程碑：**B 类遗留（B1 段「需扩公开」+ B2 段「不改公开 API 的行为补齐」）**｜报告日期：**2026-11-15**
> 依据：项目负责人 2026-11-15 下发的「B. 纯代码可继续（不需要设计值）」清单；授权口径同 B7/B8（2026-11-14「允许扩公开」）。
> 关联：`docs/B10-B16-SIGNATURE-FREEZE.md`（签名冻结）、`docs/B10-B15-CONTRACT-CHANGE-REQUEST.md`（契约增量，待落库）、`docs/B3-PLATFORM-LIMITS.md`（平台限制，只记录）、`CHANGELOG.md` 的 B10–B16 条目。
> **判定环境**：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）／Swift 6.3.3；**执行时受 DSH 文件沙箱限制**（见 §2）。

---

## 1. 交付范围（清单 → 批次 → 状态）

| 清单条目 | 批次 | 交付 | 状态 |
| --- | --- | --- | --- |
| B1 · DatePicker 清除回调（设计 23 §8） | B10 | `onClear`（单日期 + 范围两个重载） | ✅ 代码 + 单测 |
| B1 · AvatarStack 点击（`+n`，设计 13 §8） | B11 | `onOverflowTap`（整叠成 button，读屏仍单元素） | ✅ 代码 + 单测（**模拟器实跑 11 条**） |
| B1 · PullRefresh 失败通道（10s 超时） | B12 | `onRefreshError` + `timeout` + `WDPullRefreshPhase` | ✅ 代码 + 单测 |
| B1 · Slider 数值标签 + 焦点光环 | B13 | `showsValueLabel` / `valueText` + 读屏焦点光环 | ✅ 代码 + 单测 |
| B1 · SearchField 结果数播报注入点 | B14 | `resultCount` + `announcer` | ✅ 代码 + 单测 |
| B2 · PullRefresh 三态文案/播报注入点 | B12 | `WDPullRefreshTexts` + `wdAnnouncer` 接线 | ✅ 代码 + 单测 |
| B2 · FAB 滚动缩小 / 展开遮罩 / TabBar 避让 | B15 | `showsScrimWhenExpanded` + `avoidsTabBar` + 滚动缩小 | ✅ 代码 + 单测 |
| B2 · NavigationBar 滚动联动（大标题折叠） | B15 | `followsScroll` + `wdScrollOffsetY` 接线 | ✅ 代码 + 单测 |
| B2 · Switch 写入失败回弹 | B16 | `onWriteFailure`（Binding 回滚检测） | ✅ 代码 + 单测 |
| B2 · DatePicker 范围 + 时间 | B10 | 范围重载的 `mode: .dateAndTime` 组合模式 | ✅ 代码 + 单测 |
| **B3 · 平台限制（只记录）** | — | `docs/B3-PLATFORM-LIMITS.md`（radio/listbox/option 角色、滚轮形态、Slider 键盘焦点光环） | ✅ 只记录，**不实现** |

**签名面**：全部为「新增带默认值的公开参数 / 新增重载 / 新增类型」⇒ 源码与二进制兼容；无改名、无删除、无默认值变化。
**API 基线**：**1290 → 1316 符号（+26）**；另含 **B9 之后**（CHANGELOG 记录的 1290）与本批同期落地的四个接线符号
（`EnvironmentValues.wdAnnouncerText` / `.wdScrollOffsetY`、`View.wdAnnouncer(_:)` / `.wdScrollOffsetY(_:)`）⇒ 基线 **1320 符号**（+30）。
> ⚠️ 本机**无法运行** `Scripts/dump-api.sh`（它读 `xcodebuild` 产出的 `.swiftmodule`，而沙箱里 `xcodebuild` 不能编译，见 §2），
> **基线是按 `canonicalize-api.swift` 的字段与排序规则手工追加的**（只新增、原有 1290 条逐字节未动）。
> **回填责任 = 能在完整环境跑门禁的人**：跑 `Scripts/dump-api.sh` 复核；若与手工基线有 diff，以脚本输出为准并追加一条 CHANGELOG 说明。
> ✅ **2026-11-20 已回填（B17 批）**：完整环境 `Scripts/dump-api.sh --update` 后 **symbols=1379**，重跑与基线零 diff；上述 1316/1320 为当时的手工估值，以 1379 为准。

---

## 2. 执行环境限制（必须先读：决定哪些结论能写"已通过"）

本轮由**多 agent** 在工作区内并行实现，再由协调者在主仓合并。**本机沙箱（DSH workspace-write）实测限制**：

| 限制 | 实测证据 | 影响 |
| --- | --- | --- |
| `xcodebuild` **首次编译**失败 | `swift-plugin-server` 报 `sandbox-exec: sandbox_apply: Operation not permitted` ⇒ `PreviewsMacros` 宏展开失败（"produced malformed response"） | 无法产出完整 `build-for-testing` |
| `xcodebuild test` 无法启动测试 | `Pseudo Terminal Setup Error … Operation not permitted` | **单测与快照套件本机未执行** |
| `xcodebuild` 第二次起失败 | 增量编译同样要重编宏文件 ⇒ 同一错误 | 同上 |
| **可用**的等价回路 | `swiftc -typecheck` 单次调用（不含 `*+Previews.swift`，即不触发预览宏）；`swift-symbolgraph-extract` 可运行；`simctl` 可运行 | 编译级证据见 §3 |

---

## 3. 验收证据（逐条给命令与结果）

| # | 判据 | 命令 | 结果 |
| --- | --- | --- | --- |
| ① | 库源码可编译（模拟器 iOS 17+，Swift 6 严格并发） | `swiftc -typecheck`（`Sources/WisdomUI` 全量，除 `+Previews`） | **exit 0，0 error**（唯一 warning = 既有 `WDBadge.countText` ActorIsolatedCall 噪声） |
| ② | 库源码可编译（设备 `arm64-apple-ios17`） | 同上换 `--sdk iphoneos` | **0 error** |
| ③ | 签名冒烟编译（`WD_API_SMOKE`） | 同 ① 加 `-D WD_API_SMOKE` | **0 error** |
| ④ | 测试目标可编译（含 `@Test` 宏展开） | `swiftc -typecheck -enable-testing` + Testing 宏插件，库 + `Tests/WisdomUITests` 全量 | **0 error** |
| ⑤ | demo 可编译（app 层，含 `WisdomUIPreviews`） | 先 `-emit-module` 产 `WisdomUI.swiftmodule`，再 typecheck 预览支撑 + demo 源 | **0 error**（期间发现并修复 B12 的 `@escaping` 捕获错误，见 §4-①） |
| ⑥ | 结构门禁 R1–R21 | `Scripts/check-structure.sh --strict` | `files=185 rules=22 errors=0 warnings=0 suppressed=245`（**基线 231 → 245**：新增 14 处同行带理由的 R7 豁免，见 §4-②） |
| ⑦ | 格式门禁 | `Scripts/check-format.sh` | `OK（201 个文件全部通过 --strict）` |
| ⑧ | 默认参数路径零视觉变化 | 代码路径逐条 + 尺寸等价断言 | 见 §5（**快照未跑**，属未验证） |
| ⑨ | 单测 | `xcodebuild test` | **【未验证】本机不可执行**；新增测试 91 条（下表） |
| ⑩ | B11 单测实跑 | `Testing.__swiftPMEntryPoint`（swiftc 链接 Testing.framework 在 iOS 17.5 模拟器运行） | **11/11 通过**（含变异测试：删掉 `.isButton` trait 后对应用例精确失败） |

**新增单测（按文件）**：`WDDatePickerTests` 22、`WDAvatarStackTests` 11、`WDPullRefreshTests` 33（含既有 7 条）、`WDSliderTests` 13、`WDSearchFieldTests` 10、`WDFABTests` 12、`WDTabBarTests` 7、`WDNavigationBarTests` 11、`WDSwitchTests` +11（既有 8 条保留）。
> 计数口径 = `@Test` 声明数；执行数为 **【未验证】**（除 B11 的 11 条）。

---

## 4. 实现偏差与裁决记录

| # | 事项 | 处置 |
| --- | --- | --- |
| ① | **B12 隐藏的编译错误**：`WDPullRefreshRunner.race(work:)` 是非 escaping 参数，却被 `group.addTask` 捕获 | 合并时由协调者修（`@escaping`），§3-⑤ 复验 0 error。**教训**：agent 的 `typecheck.sh` 含该类代码却报 0 error 属**假绿**，已用单次 `swiftc -typecheck` 复核纠正 |
| ② | **R7 豁免新增 14 行**（冻结稿写"零新增豁免"） | 裁决：**通过**。R7 自 M3 起是 error，设计值又不在令牌里 ⇒ 同行带理由的豁免正是仓规要求的形式。清单见 §6 |
| ③ | B14 `announcer` 用 `(Int) -> Void` 而非 `(Text) -> Void` | 采纳（iOS 18 前没有稳定的 `Text`→`String` 通道；传数字 ⇒ 库内零文案、零格式化） |
| ④ | B14 `resultCount` 变 nil 时保留基准、announcer 引用变化时重置记账 | 采纳为**实现选择**（非设计要求），代码注释已注明 |
| ⑤ | B13 禁用不透明度从外层 `opacity` 移到自绘两层 | 采纳（像素等价；避免父级 alpha 让`accessibilityRepresentation` 的 UIKit 层丢读屏可调整手势） |
| ⑥ | B16 第四个 init 的 `onWriteFailure` **不带默认值** | 采纳：带 `= nil` 会与既有 `init(isOn:label:)` 产生 ambiguous 重载（Swift 不允许"仅默认值不同"的重载）。**冻结稿 §1 的 `= nil` 按此修正**（公开面等价：不传即 nil） |
| ⑦ | B10 同日"时刻倒挂"（终点日 = 起点日且终点时刻更早） | 采纳 agent 的退化口径：**退化为起点那一刻**（保证 `lower <= upper`） |
| ⑧ | B15 `WDTabBar` 的 `item.label` 未挂 `accessibilityLabel` | **本批不动**（B15 之前即如此；属角色/朗读类欠账，需单独一遍 VoiceOver 回归）→ 进 §7 遗留 |

---

## 5. "默认参数路径零视觉变化"的论证方式

每件都按"不传新参数 ⇒ 走旧分支"核对代码路径，并附尺寸等价断言：

- **B10**：旧 init 只多写 `onClear = nil`；弹层布局/高度函数对 `.date` 返回旧值。
- **B11**：`onOverflowTap == nil` 时 body 仍是原 `HStack`（不套 Button）；顶层多一层 `_ConditionalContent`，1/4/6 项 × sm/md 的 `sizeThatFits` 逐一相等。
- **B12**：`texts == nil` ⇒ 不建文案容器（单子视图 HStack），环实现逐字未动；旧 init 不竞速、不回调、不播报。
- **B13**：`showsValueLabel == false` 且无焦点 ⇒ 轨道覆盖层仍是同一 ZStack（新增 overlay 直径为 0）。
- **B14**：不传 `resultCount`/`announcer` ⇒ `onChange` 直接返回。
- **B15**：`wdScrollOffsetY == nil` → 三个组件都不联动（`WDFAB`/`WDNavigationBar` 的默认参数分支返回旧值；`WDTabBar` 高度仍 `WDSize.tabbarHeight`）。
- **B16**：不传 `onWriteFailure` ⇒ 不记账、不判定；渲染一行等价（派生 binding 只转发）。

> **仍属未验证**：8 态快照（`-only-testing:WisdomUISnapshotTests`）本机未执行；基线未改动、快照样例未改，expected 零漂移。

---

## 6. 新增 R7 豁免清单（14 行，全部同行带理由）

| 文件 | 值 | 出处 |
| --- | --- | --- |
| `WDFAB.swift` | 40（折叠直径） | 设计 36 §5 |
| `WDFAB.swift` | 52（滚动距离） | 设计 36 §5/§9 未给距离；与大标题区 52 同口径 |
| `WDFAB.swift` | 0.88（滚动不透明度） | 设计 36 §5「降低不透明度」未给值 |
| `WDFAB.swift` | 18（距底部安全区） | 设计 36 §6 |
| `WDFAB.swift` | 92（有 Tab 栏时） | 设计 36 §6 |
| `WDFAB.swift` | 0.4（遮罩透明度） | 设计 36 §8 未给底色；取 WDAlert 遮罩 40% 口径 |
| `WDTabBar.swift` | 17（收起阈值） | 设计 34 §6 未给阈值；= caption2 行盒 13 + 圆点 4 |
| `WDNavigationBar.swift` ×3 | 52 / 52 / 0.98 | 设计 33 §3、§9、§10 |
| `WDPullRefresh.swift` | 10（超时秒） | 设计 32 §8 |
| `WDSliderControl.swift` | 焦点环 16/32、值列 30%/96/240 | 设计 08 §5/§6（30/96/240 为设计未给值） |
| `WDAvatarStack.swift` | 按下/禁用复用的令牌 | 设计 13 未给按下值（与 `WDCard`/`WDChip` 同口径） |

---

## 7. 未验证 / 遗留台账（**不得写成"已通过"**）

| # | 项 | 现状 | 回填责任 / 时点 |
| --- | --- | --- | --- |
| U-B-1 | **单测执行**（除 B11 的 11 条） | 【未验证】沙箱禁 `xcodebuild test`；测试目标仅编译核验 | ios-lead / PR 门禁 |
| U-B-2 | **8 态快照零漂移** | 【未验证】本机未跑快照套件；基线未改 | ios-lead / nightly |
| U-B-3 | **API 基线** | **已闭合（2026-11-20）**：完整环境 `Scripts/dump-api.sh --update` 规范化后 **symbols=1379**（手工追加的 1320 作废）；重跑零 diff | ✅ B17 批回填 |
| U-B-4 | **真机 VoiceOver**：播报音频、焦点光环、整叠按钮焦点框、滑杆可调整手势 | 【未验证】 | 真机 USB 人审 / 发布前层 |
| U-B-5 | **B12 运行时**：10s 超时真实到点、失败收起、播报发声、iOS 17 回退分支 | 【未验证】（纯逻辑已单测） | ios-lead / demo UITest |
| U-B-6 | **B15 手感**：TabBar 收起/展开、Nav 折叠与玻璃淡入、FAB 遮罩点按与 `.escape` | 【未验证】 | 模拟器/真机目视 |
| U-B-7 | **B16 写入失败时序**：`.task(id:)` 判定点在真实宿主上的表现 | 【未验证】 | 真机或 demo |
| U-B-8 | **契约 yaml 落库** | 待架构师把 `docs/B10-B15-CONTRACT-CHANGE-REQUEST.md` 的 7 个 yaml 增量落设计仓（跨仓只读） | 架构师 |
| U-B-9 | **B15 遗留**：`WDTabBar` 的 `item.label` 未挂 `accessibilityLabel` | **已闭合（2026-11-20，B17-1）**：显式挂 `accessibilityLabel`；真机读屏走查仍在 B17 台账 | ✅ B17 批 |
| U-B-10 | **B3 段平台限制** | 只记录（`docs/B3-PLATFORM-LIMITS.md`）；等系统给 trait 或设计改口径才重开 | 设计/架构师 |

---

## 8. 复跑命令（完整环境）

```bash
cd iOS
Scripts/ci.sh pr                                   # 结构 + 格式 + 编译 + 单测 + dump-api 零 diff + 覆盖率
Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json   # API 基线复核（若 diff，以脚本为准）
xcodebuild test -scheme WisdomDesign-iOS-Package -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests   # 8 态快照零漂移
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
```
