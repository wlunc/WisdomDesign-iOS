# M5 批前签名冻结（15 件）—— 已冻结

> 用途：满足 I-2（批前签名冻结）。M5 = **导航与表单 15 件**（`docs/DEV-PLAN.md` §2.6/§3）。
> 日期：**2026-11-13**｜状态：**已冻结 + 已开始实现（项目负责人逐项确认）**
> 依据：`docs/SPEC.md` §2.10 矩阵（#04/#07/#08/#09/#10/#13/#21/#22/#23/#24/#32/#33/#34/#35/#36）、
> 设计仓 `docs/specs/01-basic.md` #04/#07/#08/#09/#10/#13、`docs/specs/02-advanced.md` #21–#24/#32–#36、
> `docs/DEV-PLAN.md` §21.6 的 M5 十问、`../AGENTS.md` §6/§10/§12。

## 1. 入口判据（I-1…I-5）

| # | 判据 | 现状 |
| --- | --- | --- |
| I-1 | 上一里程碑出口已判定 | ✅ M4 已判定通过（`docs/M4-EXIT-REPORT.md` 7/7） |
| I-2 | 15 件签名 + 契约入库 | ✅ **本文件 + 15 个 yaml + WDBadge 增量**（见 §3） |
| I-3 | 令牌/契约已冻结 | ✅ `schemes` 维度、32 色槽位、玻璃档位、配额 7 条、弹簧 μ=1.0、行高单值键均已生效 |
| I-4 | 门禁可跑且为绿 | ✅ 基线 `Scripts/ci.sh pr` 绿（M5 后 **146 tests / 1211 符号 / Foundation 97.26%**）；本机沙箱需 full-access 才能起 xctest |
| I-5 | 未闭合前置有默认执行项 | ✅ O-7（PullToRefresh 用 `.refreshable` 系统视觉）按默认执行；U7 上界 = AX3/175%（设计 06 §4.1）；Q1–Q7 已拍板（§5） |

## 2. 冻结签名

> 通则：受控值用 `Binding`；枚举一律 `String, CaseIterable, Sendable`（+ `Equatable`）；含 `Text` 的值类型不声明 `Hashable`；
> 含动作闭包的值类型只 `Identifiable`（不声明 `Sendable/Equatable`，与 `WDListSectionAction`/`WDActionSheetItem` 同口径）；
> 库内零文案：所有标签/占位/单位/读屏句由调用方以 `Text` 传入，库只提供结构。

### 2.1 表单与选择（6 件 primitives）

```swift
// MARK: #04 WDSearchField（设计 04；46 高 = WDSize.fieldHeight；radius.full）
public struct WDSearchField: View {
  /// 标准变体（无取消按钮）。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    onSubmit: (() -> Void)? = nil
  )
  /// 带取消变体（聚焦时展开取消按钮；cancelLabel 在展开时必填、收起时不占位）。
  public init(
    text: Binding<String>,
    placeholder: Text,
    leadingIcon: WDIconName = .search,
    clearAccessibilityLabel: Text,
    cancelLabel: Text,
    onCancel: (() -> Void)? = nil,
    onSubmit: (() -> Void)? = nil
  )
}

// MARK: #07 WDRadio（设计 07；组标签 + 选项数组；单选不可取消）
public struct WDRadioOption: Identifiable, Sendable, Equatable {
  public let id: String
  public let label: Text
  public let detail: Text?              // 设计「带描述」变体；nil = 无描述
  public init(id: String, label: Text, detail: Text? = nil)
}
public struct WDRadio: View {
  public init(selection: Binding<String>, label: Text, options: [WDRadioOption])
}

// MARK: #08 WDSlider（设计 08；本轮载体 = 原生 Slider，见 Q1；签名与载体解耦）
public struct WDSlider: View {
  public init(
    value: Binding<Double>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,                // 有值 = 离散档；松手吸附由系统完成
    onEditingChanged: ((Bool) -> Void)? = nil   // false = 松手（调用方据此播报一次）
  )
}

// MARK: #09 WDStepper（设计 09；36/30；到边界禁用对应键）
public enum WDStepperSize: String, CaseIterable, Sendable, Equatable {
  case standard, compact
}
public struct WDStepper: View {
  public init(
    value: Binding<Int>,
    label: Text,                        // 可调整控件的读屏标签（由调用方给，如「数量」）
    in bounds: ClosedRange<Int>,
    step: Int = 1,
    size: WDStepperSize = .standard,
    unit: Text? = nil                   // 设计「带单位」变体；nil = 无单位
  )
}

// MARK: #10 WDChip（设计 10；三种用法用三个 init 做编译期分离）
public enum WDChipSize: String, CaseIterable, Sendable, Equatable {
  case standard, compact
}
public struct WDChip: View {
  /// 展示型：不可交互、不进焦点序列。
  public init(label: Text, leadingIcon: WDIconName? = nil, size: WDChipSize = .standard)
  /// 可选中型：切换 selected（整组语义由调用方选 checkbox/radio 容器承担）。
  public init(
    label: Text, isSelected: Binding<Bool>,
    leadingIcon: WDIconName? = nil, size: WDChipSize = .standard
  )
  /// 可删除型：删除键独立可达（热区 ≥44），标签由调用方给（如「移除筛选：妈妈」）。
  public init(
    label: Text, leadingIcon: WDIconName? = nil, size: WDChipSize = .standard,
    deleteAccessibilityLabel: Text, onDelete: @escaping () -> Void
  )
}

// MARK: #13 WDAvatarStack（设计 13；max 4 + 「+n」；sm 28 / md 32；重叠 30%）
public enum WDAvatarStackSize: String, CaseIterable, Sendable, Equatable {
  case sm, md
}
public struct WDAvatarStackItem: Identifiable, Sendable, Equatable {
  public let id: String
  public let avatar: WDAvatarValue
  public init(id: String, avatar: WDAvatarValue)
}
public struct WDAvatarStack: View {
  public init(
    items: [WDAvatarStackItem],
    accessibilityLabel: Text,           // 整叠只读一次（如「家庭成员 6 人：…」）
    size: WDAvatarStackSize = .md
  )
}
```

### 2.2 导航与容器（9 件 composites）

```swift
// MARK: #21 WDSegmentedControl（设计 21；容器 38 / 段最小 56 / 指示块弹簧滑动）
public struct WDSegmentedControlItem: Identifiable, Sendable, Equatable {
  public let id: String
  public let label: Text
  public init(id: String, label: Text)
}
public enum WDSegmentedControlStyle: String, CaseIterable, Sendable, Equatable {
  case glass, solid
}
public struct WDSegmentedControl: View {
  public init(
    items: [WDSegmentedControlItem],
    selection: Binding<String>,
    style: WDSegmentedControlStyle = .solid
  )
}

// MARK: #22 WDPicker（设计 22；触发入口 44；菜单 = 系统 Menu，滚轮 = 系统 Picker(.wheel)）
public struct WDPickerOption: Identifiable, Sendable, Equatable {
  public let id: String
  public let label: Text
  public let group: Text?               // 设计「分组标题」；nil = 不分组的选项
  public init(id: String, label: Text, group: Text? = nil)
}
public enum WDPickerStyle: String, CaseIterable, Sendable, Equatable {
  case menu, wheel
}
public struct WDPicker: View {
  public init(
    selection: Binding<String?>,
    label: Text,                        // 触发入口的读屏标签（如「分类」）
    options: [WDPickerOption],
    placeholder: Text? = nil,           // 无选中时的显示（如「请选择」）；nil = 只显示箭头
    style: WDPickerStyle = .menu
  )
}

// MARK: #23 WDDatePicker（设计 23；触发入口 44；.date = 自建月历；.time = 系统滚轮）
public enum WDDatePickerMode: String, CaseIterable, Sendable, Equatable {
  case date, time, dateAndTime
}
public struct WDDatePickerQuickOption: Identifiable, Sendable, Equatable {
  public let id: String
  public let label: Text               // 如「今天」「明天」
  public let date: Date
  public init(id: String, label: Text, date: Date)
}
public struct WDDatePicker: View {
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,            // 未选时的显示（如「设置日期」）
    quickOptions: [WDDatePickerQuickOption] = []   // 仅 .date 模式渲染（设计 23 §2/§6）
  )
}

// MARK: #24 WDFormRow（设计 24；行最小 44；标签 + 控件 + 说明/错误）
public enum WDFormRowLayout: String, CaseIterable, Sendable, Equatable {
  case horizontal, vertical
}
public struct WDFormRow<Control: View>: View {
  public init(
    label: Text,
    layout: WDFormRowLayout = .horizontal,
    helper: Text? = nil,                // 说明文字
    error: Text? = nil,                 // 错误文字（替换说明，不叠加）
    requiredLabel: Text? = nil,         // 必填标记（如「必填」）；nil = 非必填
    @ViewBuilder control: () -> Control
  )
}

// MARK: #32 WDPullRefresh（设计 32；O-7 默认：.refreshable + 系统视觉）
public struct WDPullRefresh: ViewModifier {
  public init(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,                 // 提供时同时挂「刷新」自定义无障碍操作（设计 §10）
    onRefresh: @escaping @Sendable () async -> Void
  )
  public func body(content: Content) -> some View
}
extension View {
  public func wdPullRefresh(
    isRefreshing: Binding<Bool>,
    label: Text? = nil,
    onRefresh: @escaping @Sendable () async -> Void
  ) -> some View
}

// MARK: #33 WDNavigationBar（设计 33；内联 44 / 标准 56 / 大标题 96；滚动联动本轮不做，见 Q6）
public enum WDNavigationBarMode: String, CaseIterable, Sendable, Equatable {
  case inline, standard, largeTitle
}
public enum WDNavigationBarStyle: String, CaseIterable, Sendable, Equatable {
  case transparent, glass
}
public struct WDNavigationBarAction: Identifiable {
  public let id: String
  public let icon: WDIconName
  public let accessibilityLabel: Text
  public let action: () -> Void
  public init(id: String, icon: WDIconName, accessibilityLabel: Text, action: @escaping () -> Void)
}
public struct WDNavigationBar: View {
  public init(
    title: Text,
    mode: WDNavigationBarMode = .standard,
    style: WDNavigationBarStyle = .transparent,
    backAccessibilityLabel: Text? = nil,     // 提供时显示返回按钮（如「返回家庭列表」）
    onBack: (() -> Void)? = nil,
    actions: [WDNavigationBarAction] = []    // 右侧 ≤2 个（超出 debug 断言）
  )
}

// MARK: #34 WDTabBar（设计 34；悬浮胶囊；高度用令牌 56；角标复用 WDBadge 值形态）
public struct WDTabBarItem: Identifiable, Sendable, Equatable {
  public let id: String
  public let icon: WDIconName
  public let label: Text
  public let badge: WDBadgeValue?      // 见 §2.3 的 WDBadge 增量（count/dot）
  public init(id: String, icon: WDIconName, label: Text, badge: WDBadgeValue? = nil)
}
public struct WDTabBar: View {
  public init(items: [WDTabBarItem], selection: Binding<String>)
}

// MARK: #35 WDToolbar（设计 35；容器 48 / 按钮 36 / ≤7 项）
public struct WDToolbarItem: Identifiable {
  public let id: String
  public let icon: WDIconName
  public let accessibilityLabel: Text
  public let isSelected: Bool
  public let isEnabled: Bool
  public let action: () -> Void
  public init(
    id: String, icon: WDIconName, accessibilityLabel: Text,
    isSelected: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void
  )
}
public struct WDToolbar: View {
  public init(
    items: [WDToolbarItem],
    accessibilityLabel: Text,               // 整条工具栏的分组标签（如「编辑工具」）
    overflowAccessibilityLabel: Text? = nil // items > 7 时「更多」菜单的标签（debug 断言非 nil）
  )
}

// MARK: #36 WDFAB（设计 36；56/64/40；圆角方/圆；可展开）
public enum WDFABSize: String, CaseIterable, Sendable, Equatable {
  case small, standard, large
}
public enum WDFABShape: String, CaseIterable, Sendable, Equatable {
  case roundedSquare, circle
}
public struct WDFABAction: Identifiable {
  public let id: String
  public let icon: WDIconName
  public let label: Text
  public let action: () -> Void
  public init(id: String, icon: WDIconName, label: Text, action: @escaping () -> Void)
}
public struct WDFAB: View {
  public init(
    icon: WDIconName,
    accessibilityLabel: Text,               // 写动作（如「新建任务」）
    size: WDFABSize = .standard,
    shape: WDFABShape = .roundedSquare,
    actions: [WDFABAction] = [],            // 非空 = 可展开（≤4，debug 断言）
    action: (() -> Void)? = nil             // actions 为空时的主操作
  )
}
```

### 2.3 批前增量：`WDBadge` 计数/圆点形态（Q7 = B）

M2 裁决 C⑤「WDBadge 变体/计数 → M4/M5 首个带徽标调用方」在本批兑现；**只增不改**（现有 `init(label:)` 与渲染不变）。

```swift
public struct WDBadgeValue: Sendable, Equatable {
  public init(label: Text)        // 既有（状态胶囊，24 高）
  public init(count: Int)         // 新增：计数胶囊（高 20 / 最小宽 20；0 ⇒ 不渲染；>99 ⇒ 「99+」）
  public static let dot: WDBadgeValue   // 新增：圆点 7×7
}
public struct WDBadge: View {
  public init(label: Text)        // 既有
  public init(value: WDBadgeValue)      // 新增（WDTabBar / WDListRow 复用同一套渲染）
}
```

> 兼容性：**追加公开 init / 静态常量 = 源码兼容**，但会破坏符号快照连续性 ⇒ 本批做一次**显式 API 基线更新**并在 `CHANGELOG.md` 记录；不新增枚举 case、不改已有形参类型/标签。槽位仍为 `label`，`count/dot` 是值形态（记 params）。

## 3. 契约条目（同批回填 `../wisdomdesign/contracts/`）

| 组件 | 受控值（C-15 canonical / iOS） | `slots` | 关键默认 | 枚举 |
| --- | --- | --- | --- | --- |
| `WDSearchField` | `text` / `text` | `placeholder`,`leadingIcon`,`label`（取消） | `leadingIcon = .search`；`cancelLabel/onCancel/onSubmit = nil` | — |
| `WDRadio` | `selection` / `selection` | `label`（组）,`options` | — | —（ID = String） |
| `WDSlider` | `value` / `value` | `label` | `in = 0...1`；`step = nil` | — |
| `WDStepper` | `value` / `value` | `label` | `step = 1`；`size = .standard`；`unit = nil` | `WDStepperSize`(standard,compact) |
| `WDChip` | `selected` / `isSelected`（仅可选中 init） | `label`,`leadingIcon` | `size = .standard`；`leadingIcon = nil` | `WDChipSize`(standard,compact) |
| `WDAvatarStack` | — | `items` | `size = .md`；`accessibilityLabel` 必填 | `WDAvatarStackSize`(sm,md) |
| `WDSegmentedControl` | `selection` / `selection` | `items` | `style = .solid` | `WDSegmentedControlStyle`(glass,solid) |
| `WDPicker` | `selection` / `selection` | `label`,`options` | `placeholder = nil`；`style = .menu` | `WDPickerStyle`(menu,wheel) |
| `WDDatePicker` | `date` / `date` | `label` | `mode = .date`；`placeholder = nil`；`quickOptions = []`；`bounds = nil` | `WDDatePickerMode`(date,time,dateAndTime) |
| `WDFormRow` | — | `label`,`control` | `layout = .horizontal`；`helper/error/requiredLabel = nil` | `WDFormRowLayout`(horizontal,vertical) |
| `WDPullRefresh` | `refreshing` / `isRefreshing` | `label` | `label = nil` | — |
| `WDNavigationBar` | — | `title`,`leading`,`trailing` | `mode = .standard`；`style = .transparent`；`back/actions = nil/[]` | `WDNavigationBarMode`(inline,standard,largeTitle)/`WDNavigationBarStyle`(transparent,glass) |
| `WDTabBar` | `selection` / `selection` | `items` | `badge = nil` | — |
| `WDToolbar` | — | `items` | `overflowAccessibilityLabel = nil` | — |
| `WDFAB` | — | `icon`,`label`（读屏标签） | `size = .standard`；`shape = .roundedSquare`；`actions = []`；`action = nil` | `WDFABSize`(small,standard,large)/`WDFABShape`(roundedSquare,circle) |
| `WDBadge`（增量） | — | `label` | `value = nil`（既有 `init(label:)` 不变） | — |

> 槽位全部 ⊆ 21 名词表；`params[].name` 的受控值取 canonical；iOS 形参名另记（仅 `WDChip.selected → isSelected` 一处差异）。

## 4. 验证计划（冻结后执行）

1. `Scripts/dump-api.sh`：新增符号与冻结表逐字一致；API 基线随成因提交（15 件 + WDBadge 增量）。
2. 结构/契约断言：每个枚举 `allCases.map(\.rawValue)` 与契约一致；默认值断言；空数据断言（`WDPicker options`/`WDTabBar items`/`WDSegmentedControl items`/`WDToolbar items`）。
3. 单测：单选互斥与"点已选项不回调"、滑块松手单次回调/阈值钳制、步进上下限/长按加速/高频无额外触觉、Chip 删除键独立动作、AvatarStack max 4 与 +n 计算、Segmented 2–5 断言与不重复回调、Picker 菜单/wheel 两形态与未选态、DatePicker 自建月历（今天/选中/禁用/min-max/键盘二维移动/快捷 Chip/本地化）、FormRow 错误替换说明、PullToRefresh 进行中不重复触发 + 自定义刷新动作、NavBar ≤2 动作/返回标签/大标题、TabBar 选中与角标、Toolbar 溢出 >7、FAB 展开/收起与主操作、WDBadge 计数/圆点/0 隐藏/99+。
4. 八态快照（浅/深 × 默认/AX3 × LTR/RTL）：15 件 × 8 = **120 张新基线**（总 328）；玻璃类 `WDNavigationBar`/`WDTabBar`/`WDToolbar` 用 `UIHostingController` + `drawHierarchy`；另 `WDBadge` 计数/圆点各补快照。
5. 无障碍：`searchbox` / selected trait / 可调整动作 / 单元素朗读 / 热区 ≥44 / 月历逐日完整日期；demo 审计视口扩到 36 件（M6 前）。
6. 动态字体降级矩阵：AX3 下 `WDFormRow` 左右→上下、`WDTabBar` 标签 2 行、`WDToolbar` 横滚不压间距、compact 三条规则（不缩字/只压留白/热区仍 44）。
7. 性能：15 件渲染耗时进 M5 出口报告（只报不拦）。

## 5. 已拍板的 7 个点（2026-11-13）

| # | 问题 | 最终口径 |
| --- | --- | --- |
| **Q1** | `WDSlider` 视觉载体 | **本轮先原生 `Slider`**（系统手势/读屏合规；轨道 6 / 手柄 26 / 刻度标签差异登记）；**自绘后续在不改签名的前提下替换**（Internal 内 UISlider 桥接；自造 DragGesture 被 §3.4 禁止） |
| **Q2** | `WDPicker` / `WDDatePicker` 弹层 | **菜单 = 系统 `Menu`；滚轮 = 系统 `Picker(.wheel)`（底部弹出）；日期 = 自建月历**（44×44、今天圆点、选中实心、min/max 禁用、逐日完整朗读）；`.dateAndTime` = 自建月历 + 系统时间滚轮；**快捷 Chip 本轮实现** |
| **Q3** | `WDTabBar` 高度 | **令牌 `WDSize.tabbarHeight = 56`**；与设计 58 的 2pt 差登记 |
| **Q4** | `WDAvatarStack` 朗读 | **必填 `accessibilityLabel: Text`**（整叠只读一次；契约 `slots` 仍只记 `items`） |
| **Q5** | `WDChip` API | **三个 init 编译期分离**（展示 / 可选 binding / 可删除 label+onDelete） |
| **Q6** | `WDNavigationBar` 滚动联动 | **本轮不做**：`style` 由调用方显式给；大标题不随滚动收缩（差异登记） |
| **Q7** | `WDTabBar` 角标 | **扩展 `WDBadge`**（新增 count/dot 值形态，只增不改）+ 显式 API 基线更新 + CHANGELOG |

> 其余实现细节（Chip 图标尺寸、TabBar 标签字号 10 vs 令牌 caption2 11、Toolbar/FAB 的滚动联动、DatePicker 清除按钮、
> Picker 内联形态、Slider 范围双手柄）按"最小可验证实现 + 差异登记"处理，逐条进 `docs/M5-EXIT-REPORT.md` 的差异表。

## 6. 确认与合并记录

| 项 | 值 |
| --- | --- |
| 确认人 | 项目负责人 |
| 日期 | 2026-11-13 |
| 结论 | Q1 = 先原生、自绘后续替换；Q2 = 系统 Menu/wheel + 自建月历 + 快捷 Chip；Q3 = 令牌 56；Q4 = 必填 accessibilityLabel；Q5 = 三 init；Q6 = 不做滚动联动；Q7 = 扩展 WDBadge |
| 后续 | 15 个 yaml + WDBadge 增量已回填；实现与门禁见 `docs/M5-EXIT-REPORT.md` |
## 7. 实现完成与差异（2026-11-13）

- 15 件全部落地（`Components/{Primitives,Composites}/`）；结构断言 24 条、性能采样 1 条、快照 16 个测试 / 128 张基线（总 336）。
- 契约：15 个新 yaml + `WDBadge.yaml` 增量；`WDRadio` 的 ID 改为 String、`WDDatePicker` 增 `in bounds`（实现期冻结修订，已同步本文件 §2）。
- **已接受的差异**（逐条见 `docs/M5-EXIT-REPORT.md` §4）：Slider 原生载体视觉；Picker 只做菜单/滚轮；
  DatePicker 未做范围/清除/二维键盘网格；NavBar 无滚动联动；TabBar 56/图标 20/标签 11；
  Toolbar 垂直内距 2（热区优先）；FAB 无滚动缩小/遮罩/焦点移入；WDBadge 计数底用破坏色渐变。
- **门禁修复**：M4 Toast 与 M5 的 UIHostingController 快照并发时窗口互顶 ⇒ nightly 快照加
  `-parallel-testing-enabled NO`（`Scripts/ci.sh`），实测 336 张全绿。
- **nightly₃**：本轮只实跑 1 次完整 nightly；按项目负责人 2026-11-12 对 M3/M4 的豁免先例待确认。
- **更名（2026-11-13，用户裁决）**：`WDPullToRefresh` → `WDPullRefresh`，修饰符 `.wdPullToRefresh` → `.wdPullRefresh`；
  契约 yaml 同名更新；**Android 侧契约名待同步**（C-15 #32，android-lead）；CHANGELOG 的 Breaking 段已记。