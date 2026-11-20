# M5 出口报告 —— 导航与表单（15 件）

> 里程碑：**M5**（口径来源 = `docs/DEV-PLAN.md` §2.6）｜报告日期：**2026-11-13**（**2026-11-14 复核**）
> 判定人：ios-lead｜**状态：技术判据 6/6 通过；nightly 连续 **2/3** 日（2026-11-13、11-14 绿；11-15 待跑或按负责人豁免先例确认）**
> 判定环境：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）
> 关联：`docs/M5-SIGNATURE-FREEZE.md`、`docs/DEV-PLAN.md` §21.6 的 M5 十问、`../wisdomdesign/contracts/`

## 1. 出口判据逐条判定（DEV-PLAN §2.6 的 6 条）

| # | 判据 | 证据 | 结论 |
| --- | --- | --- | --- |
| ① | **20/20 primitives 完成**（11 + 1 + 2 + 6） | `Components/Primitives/` 20 个目录：M2 11 + M3 1 + M4 2 + M5 6（SearchField/Radio/Slider/Stepper/Chip/AvatarStack）；M5 结构测试 `M5ComponentsTests` 23 条 | ✅ |
| ② | 动态字体降级矩阵（含 compact 三条规则）绿 | 8 态快照含 **AX3**（15 件 × 8）；`WDFormRow` 在 AX3 下横向→上下（单测）；compact 三条规则（不缩字号 / 只压留白 / 热区仍 44）单测绿 | ✅ |
| ③ | RTL 六态截图（LTR/RTL 两态）入库 | 8 态矩阵含 LTR/RTL；**128 张新基线**（总 **336**），`xcodebuild test -parallel-testing-enabled NO` 全绿 | ✅ |
| ④ | 该批性能数字进报告 | §3 的 15 件 ImageRenderer 耗时（n=12，只报不拦） | ✅ |
| ⑤ | 组件类型名清单与 U3/F 注册表集合相等 | `M5ComponentsTests.contractTypeNames`：已实现的 **36** 件与 `contracts/*.yaml` 的 `component` 集合相等（M6 的 `WDAssigneePicker` 尚无契约，37 件在 M6 闭合） | ✅（36/36 已实现件） |
| ⑥ | 无新增未登记差异（差异须进 §6 的回写/登记清单） | §4 逐条登记；Q1–Q7 拍板记录在 `docs/M5-SIGNATURE-FREEZE.md` §5 | ✅ |

**门禁**：`PR + nightly₃`。PR 全绿（**2026-11-14 复核：156 tests / 1212 符号零 diff** / `Foundation/**` **97.26% ≥ 80%** / `--strict` 0 warning；整条 **33.03 s**）。
**2026-11-14 自绘载体复跑**：PR **165 tests / 1246 符号零 diff / 33.52 s**；快照 **44 tests / 352 张全绿**（slider 8 张重录）。
nightly **2026-11-14 复核**（金标 iPhone Air）：设备编译 **7.81 s** + 快照 **45.29 s**（336 张全绿，`-parallel-testing-enabled NO` 串行）
+ demo 无障碍审计 **202.76 s**（**13 条** UITest 全过），整条 **255.86 s 绿**；**连续 3 日 nightly = 2/3**
（11-13、11-14 连续绿；11-15 待跑，或按 M3/M4 的 2026-11-12 豁免先例确认）。

## 2. 本批交付物

| 项 | 内容 |
| --- | --- |
| 组件 | `WDSearchField` / `WDRadio` / `WDSlider` / `WDStepper` / `WDChip` / `WDAvatarStack` / `WDSegmentedControl` / `WDPicker` / `WDDatePicker` / `WDFormRow` / `WDPullRefresh` / `WDNavigationBar` / `WDTabBar` / `WDToolbar` / `WDFAB` |
| 落点 | `Components/Primitives/` 6 个新目录、`Components/Composites/` 9 个新目录（各含 `+Previews.swift`） |
| 增量 | `WDBadge` 新增 `WDBadgeValue.init(count:)` / `.dot` 与 `WDBadge.init(value:)`（只增不改；`WDListRow` 改用同一值形态） |
| 契约 | 15 个新 yaml + `WDBadge.yaml` 增量（共 **36** 个 yaml）；params / slots / default / enums |
| API 基线 | **1212 符号**（M4 的 861 + **351**）；`dump-api` 零 diff |
| 测试 | 结构断言 **24 条**（M5Components 24 + 性能 1）；快照 **16 个测试 / 128 张基线**；PR **156 tests** |
| demo | 组件目录 **36 件**（M5 +15）；M5 详情页含**档位 / 状态 / 设置**（13 件可切枚举）与可交互实时预览；审计视口加入 M5 代表实例；demo 构建通过；`WisdomUIDemoUITests` **13 tests / 0 failures**（含四类目审计） |

## 3. 性能数字（ImageRenderer；只报不拦）

口径：`ImageRenderer` 渲染一次 PNG（scale 1），前 3 次预热丢弃，n=12；单位 ms。

| 组件 | avg | min |
| --- | --- | --- |
| `WDSearchField` | 22.91 | 8.43 |
| `WDRadio` | 12.57 | 1.24 |
| `WDSlider` | 10.26 | 3.46 |
| `WDStepper` | 1.41 | 1.24 |
| `WDChip` | 2.88 | 1.99 |
| `WDAvatarStack` | 2.87 | 1.07 |
| `WDSegmentedControl` | 7.26 | 1.87 |
| `WDPicker` | 4.46 | 3.31 |
| `WDDatePicker` | 4.00 | 1.87 |
| `WDFormRow` | 2.39 | 1.23 |
| `WDPullRefresh` | 4.35 | 2.15 |
| `WDNavigationBar` | 1.36 | 0.71 |
| `WDTabBar` | 6.56 | 4.44 |
| `WDToolbar` | 0.83 | 0.79 |
| `WDFAB` | 1.62 | 0.57 |

> `WDSearchField`/`WDRadio` 的 avg 受 UIKit/首次布局影响；min 更接近稳态。原始输出 = PR 日志的 `M5PERF` 行。

## 4. 实现差异与未验证（**不得写成已通过**）

| # | 项 | 现状 | 时点 / owner |
| --- | --- | --- | --- |
| ① | `WDSlider` 视觉载体 | **已修（2026-11-14，B 类遗留）**：手势与读屏改由 Internal `UISlider` 承载（系统拖拽/键盘/可调整语义；不自造 `DragGesture`），视觉改 SwiftUI 覆盖层——轨道 6（`border.hairline-strong`）、填充 `gradient.mid`、手柄 26（白 + 1pt hairline + `elevation.1`）、两端内缩 13、拖拽 1.15（100ms）、禁用 45%、RTL 由 leading 对齐自动镜像。**交互补齐**：点击轨道按触点换算目标值并做 200ms 过渡（Reduce Motion 瞬移）、松手按 `step` 吸附、拖到端点用 `rigid` 触觉（同一次操作仍只抖一次）。**残留**：聚焦光环、数值标签跟随、范围双手柄（后两者需签名扩展）；带刻度 = `step` 吸附（画廊无可见刻度点） | 已修（快照 8 张重录；PR **166 tests** / 1246 符号零 diff；demo **18 条 UITest / 265.44 s** 全绿，含滑块点击与 Toast 三条用例）；残留项仍登记 |；**B13（2026-11-15）已补数值标签（`showsValueLabel`/`valueText`）与读屏焦点光环**；**B17（2026-11-20）补齐范围双手柄**（`init(range:…)`：两端不交叉、最小间隔 = 1 步长、松手吸附、两个可调整语义）
| ② | `WDSearchField` 结果播报/防抖 | 300ms 防抖仍由调用方负责；**B14（2026-11-15）已补结果数播报注入点**：`resultCount` + `announcer`（传数字，措辞由调用方给） | 调用方 / M6 前如需再议 |
| ③ | `WDRadio` 角色与紧凑档 | **紧凑 22 已补（B7，2026-11-15）**：`WDRadioSize` + 22/10/footnote；`radiogroup`/`radio` 角色与"第 n 项，共 m 项"SwiftUI 无对应 trait ⇒ 仍只加 `.isSelected` | 紧凑档已闭合；角色待 M6 复核 |
| ④ | `WDStepper` 字号/节奏 | 标准字号用 subheadline 15（设计 14，+1）；长按节奏取 0.45s/0.2s→0.06s（设计未给值）；紧凑档 30 视觉但整体布局 ≥44 | 已登记；设计给值后可改 |
| ⑤ | `WDChip` 图标/溢出 | 图标用 token sm 16（设计 15，+1）；横向滚动/换行由调用方布局；删除键与芯片相邻（不重叠） | 已登记 |
| ⑥ | `WDAvatarStack` | **B11（2026-11-15）已补点击**：`onOverflowTap`（整叠成 button，读屏仍单元素）；描边色固定 `surfaceCard`（容器底色不可注入）；点击展开不可表达；sm 档图标仍 20 | M6 前如需可扩签名 |
| ⑦ | `WDSegmentedControl` | 无 `tablist`/`tab` 角色与位置文案；指示块改为自定义 `Layout` 直接定位（原 `GeometryReader` 量测会取到 0 宽导致选中态只剩字重差异，已修）；不支持段间横向拖动；玻璃档为纯色填充（未做强模糊） | 已修/已登记 |
| ⑧ | `WDPicker` 形态 | **已由 ㉑ 修正（2026-11-14，用户裁决「完全按照设计稿」）**：菜单改自绘浮层（44 行/14 圆角/翻转/滚动到当前项/遮罩与 Esc 不提交），内联形态已补（`.inline`） | 已修；残留 = 滚轮弹层仍是系统 `.wheel`（设计 22 §11 指定）且即时提交 |
| ⑨ | `WDDatePicker` 形态 | `.date` 自建月历；`.time` 系统滚轮；`.dateAndTime` = 月历 + 滚轮；范围变体与清除按钮已由 **B6** 补齐；**B10（2026-11-15）补了清除回调 `onClear` 与范围+时间组合**；二维方向键网格导航与弹层自适应高度仍未实现；**B17（2026-11-20）过期色改按系统 `NSCalendarDayChanged` + 回到前台刷新（零计时器），并补 `expiredAccessibilityHint` 注入点** | M6 前可补范围/清除 |
| ⑩ | `WDFormRow` 标签关联 | 标签与控件靠阅读顺序 + 错误 hint 关联，非程序化 `accessibilityLabel` 合并；错误替换说明 | M6 无障碍回归复核 |
| ⑪ | `WDPullRefresh` 自绘项 | **已由 ⑳ 修正（2026-11-14）**：原系统 `.refreshable` 视觉与设计 32 不符 | 已修；残留 = 三态文案/刷新播报不进库（L-B；组件只画环）+ iOS 17 回退系统视觉 |
| ⑫ | `WDNavigationBar` 滚动联动 | Q6 口径仍是 style 由调用方显式给；**B15（2026-11-15）补了 opt-in 的滚动联动**（`followsScroll` + `wdScrollOffsetY`：大标题折叠 + 透明→玻璃）；右侧 >2 动作 debug 断言后只渲染前 2；玻璃档为纯色填充 | Q6 已拍板；M6 前可补 |
| ⑬ | `WDTabBar` 尺寸/角标 | 高度用令牌 **56**（设计 58，-2）；图标 20（设计 22，-2）；标签 caption2 11（设计 10，+1）；角标 a11y 未并入宿主朗读（同 M2 ⑬）；滚动收缩已由 B15 补齐；**B17（2026-11-20）把 `item.label` 显式挂 `accessibilityLabel`（收起态也有稳定名称）**；深色不透明已实现 | 已登记（Q3/Q7） |
| ⑭ | `WDToolbar` 位置/尺寸 | 顶部/底部/键盘上方由调用方放置；垂直内边距 2（44 热区 + 2×2 = 48；设计视觉 6）；玻璃档纯色；长按 tooltip 未实现（B17 复核：`Button` 与长按手势仲裁需真机/UITest 回归，仍开放） | 已登记 |
| ⑮ | `WDFAB` 交互增强 | 焦点移入第一个子操作已由 **B7** 补齐；**B15（2026-11-15）补了滚动缩小、展开遮罩（`showsScrimWhenExpanded`）与 TabBar 避让（`avoidsTabBar`）**；**B17（2026-11-20）补收起后读屏焦点归还主按钮** | M6 前可补 |
| ⑯ | `WDBadge` 增量 | 计数底用 `WDGradient.destructive`（设计 --g-danger）；圆点只有品牌色一档；**M2 ⑥ 六种状态变体已由 B1 补齐**（`WDBadgeVariant`，2026-11-14；对比度优先偏差见 `docs/B1-SIGNATURE-FREEZE.md`） | 六态已闭合；计数/圆点配色仍登记 |
| ⑰ | 快照并发 | M4 Toast 与 M5 的 UIHostingController 快照并发时窗口互顶（像素差 8–14%）；nightly 快照加 `-parallel-testing-enabled NO` 后全绿（`Scripts/ci.sh` 已改） | 已修复（2026-11-13） |
| ⑱ | 真机 / VoiceOver / Thinning | 真机观感、读屏播报音频、Thinning 增量仍【未验证】 | M6 前 / 发布前层 |
| ⑲ | **`WDPullToRefresh` → `WDPullRefresh`** | 2026-11-13 用户裁决的更名（含 `.wdPullRefresh`）：公开类型/修饰符/契约/快照/API 基线同步；**Android 侧契约名待同步**（C-15 #32） | android-lead；iOS 侧已完成 |
| ⑳ | **`WDPullRefresh` 自绘修正** | **B12（2026-11-15）已补失败通道 + 10s 超时 + 三态文案/播报注入点**：`onRefreshError`/`timeout`/`texts`/`WDPullRefreshPhase`；**2026-11-14 用户裁决**：指示器动画与设计 32 不符 ⇒ iOS 18+ 改自绘。已实现：24pt 环 / 2pt 线宽 / 阈值 64 / 最大下拉 120 / 下拉随位移画进度 / 刷新中品牌弧 1s 线性旋转 / 完成后 160ms 收起 / 到阈值一次 `.medium` 触觉 / Reduce Motion 静态弧；环覆盖列表顶部、保持释放位置、不改锚点高度；进行中不重复触发；外部 `isRefreshing=true` 也会显示环。**未实现/残留**：三态文案（L-B：库内零文案，组件只画环 = 设计 32 §4 极简变体；无阈值进度回调）、刷新开始/结束播报（库内零文案 / 无 announcer 注入点）、10s 超时失败 Toast（无失败通道/库内零文案）、内容不足以滚动时的下拉（系统 ScrollView 不回弹 ⇒ 不触发，设计 32 q9 允许"明确禁用"）、iOS 17 回退系统 `.refreshable` 视觉 | 已修（单测 7 + demo XCUITest 1 绿；API 基线零 diff）；契约 yaml 载体注释已于 2026-11-14 同步设计仓（`contracts/WDPullRefresh.yaml`） |
| ㉑ | **`WDPicker` 全量对齐设计 22** | **2026-11-14 用户裁决「完全按照设计稿」**：菜单改窗口级自绘浮层（圆角 14 / 行高 44 / 水平内距 14 / 最小宽 180 / 最大宽 = 屏宽 − 32 / 与入口间距 4 / 空间不足翻转 / 当前项打勾并滚到可视区中间（选中行 = brand 10% 底 + brand 字 + 600，对齐画廊 22 `.sel`）/ 遮罩与硬件 Esc 关闭不提交 / `motion.spring.gentle` 入场 + 160ms 淡出 / 分组标题 `type.overline` + 组内缩进 `space.5`）；新增 `.inline` 内联形态；触发箭头 `chevron.right → chevron.down`；遮罩由新增 `WDPickerMenuPresenter` 承载（与 `WDBottomSheetPresenter` 同构，锚点定位不同）。**残留**：滚轮形态仍是系统 `Picker(.wheel)` 且滚动即时提交（设计 22 §11 指定系统载体，§8 的"关闭不改变值"按菜单形态执行）；触发入口的"展开选择"/未选"未选择"朗读文案属调用方（L-B 零文案，未加 hint 参数）；`listbox`/`option` 角色 SwiftUI 无对应 trait ⇒ 只加 `.isModal` + `.isSelected`（同 `WDRadio` ③ 口径）；菜单未做硬件键盘方向键环形焦点。 | 已修（M5 单测 22 绿 + picker 8 态基线重录 + 菜单浮层实机截图核对；API 基线 +1 case）；契约 `WDPickerStyle` 已同步 `[menu, wheel, inline]`（2026-11-14，含 Android C-15 副本） |
| ㉒ | **快照稳定性与审计误判** | **2026-11-14 复核发现并修复**：① `DatePicker` 快照用 `Date()`，跨日会漂移（实测 11-14 两张 RTL 基线过期）⇒ 改用固定 `Date` + UTC/`zh_CN`，8 张基线重录；② `WDButton` 顶部高光原为独立 overlay，demo 对比度审计把它当按钮背景，`提交` 深色对比度被误判 ⇒ 高光移入 `background` 层，视觉不变、审计恢复绿。 | 已修（336 张快照 + 13 条 demo UITest 绿） |

## 5. 判定记录

| 项 | 值 |
| --- | --- |
| 技术判据 | **6/6 ✅**（§1） |
| 门禁 | PR ✅（156 tests / 1212 符号 / 97.26%）；nightly ✅（设备 7.81 s + 快照 336 张 45.29 s + demo 审计 13 tests 202.76 s；整条 255.86 s）；nightly 第 **2/3** 日 |
| 结论 | **技术判据通过（2026-11-13，ios-lead；2026-11-14 复核仍 6/6）**；nightly 2/3 日绿，11-15 待跑或按负责人豁免先例确认 |
| 条件 | §4 的差异/未验证项已登记；nightly 2/3；真机与 Thinning 留 M6 |
| 后续 | M6（`WDAssigneePicker` + 无障碍回归 + 截图封板 + 双端 tag `v1.0.0`） |

## 6. 复跑命令

```bash
cd iOS
Scripts/ci.sh pr                    # 156 tests / 1212 符号 / Foundation ≥80% / --strict
xcodebuild test -scheme WisdomDesign-iOS-Package -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests     # 336 张基线
Scripts/ci.sh nightly                # 设备编译 + 快照（串行）+ demo 审计
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
```