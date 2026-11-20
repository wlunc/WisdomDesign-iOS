# B17 批前签名冻结 —— 遗留收口（2026-11-20）

> **依据**：项目负责人 2026-11-20 的「继续完成」指令，承接 `docs/B10-B16-EXIT-REPORT.md` §7 的遗留台账（U-B-9 等）与 `docs/M5-EXIT-REPORT.md` §4 的零散登记。
> **授权口径**：延续 B7/B8/B10 的「允许扩公开」——**只增不改**（既有 init / 默认值 / 类型一律保留；带默认值的新参数按 SPEC §2.9 规则 1 走显式基线更新）。
> **口径来源**：设计 08 §4/§5（范围）、设计 23 §5（过期色）、设计 34（TabBar）、设计 36 §10（FAB 焦点）＋ `docs/SPEC.md` §2.10/§2.11。
> **前置**：B1–B16 已落地；本批同时修复 B10–B16 在完整环境首跑暴露的 4 处红灯（见 §4）。

---

## 1. 本批范围（做 / 不做）

| # | 组件 | 事项 | 来源 | 交付 |
| --- | --- | --- | --- | --- |
| B17-1 | `WDTabBar` | `item.label` 显式挂 `accessibilityLabel`（收起态标签被压到 0 时读屏仍有稳定名称） | B10–B16 出口 §7 U-B-9；设计 34 | 行为修正，**零 API** |
| B17-2 | `WDFAB` | 收起后读屏焦点归还主按钮（展开时子操作移出可访问树） | 设计 36 §10；M5 §4-⑮ | 行为修正，**零 API** |
| B17-3 | `WDDatePicker` | ① 过期色按**系统「日变更」通知**跨午夜刷新（**不自建计时器**）；② 新增 `expiredAccessibilityHint` 注入点（颜色之外的非视觉信号） | 设计 23 §5/§10；B8 残留 | API +1 参数（既有 init 追加默认值） |
| B17-4 | `WDSlider` | **范围（双手柄）**：`Binding<ClosedRange<Double>>` + 两端不交叉 + 最小间隔 = 1 步长 | 设计 08 §4/§5/§8/§9 | API +1 init |

**本批不做（逐条给理由，不做即登记）**：

| 项 | 理由 | 登记处 |
| --- | --- | --- |
| `WDCard` `media` 变体 | 设计 17 §3 只写「所有变体内边距 16」、§4 写「顶部图片 + 文字区」，**未给图片宽高比、是否通栏、加载失败态**；且 F-15 的 21 个槽位词表**没有 `media`** ⇒ 新槽位属 U 系列，需设计给值 + 架构师确认。先按 G-01 口径登记，不自行发明槽位词。 | 本文件 §5；`docs/B17-EXIT-REPORT.md` §5 |
| `WDToolbar` 长按 tooltip | 设计 35 §8 有要求，但 `Button` 上叠 `onLongPressGesture` 会让"长按"与"点按"在真实手势序列里竞争（长按抬手是否触发 action 取决于手势仲裁），**本轮无真机/模拟器手势回归条件**；先登记，等能跑 UITest 时再实现。 | 本文件 §5；`docs/B17-EXIT-REPORT.md` §5 |
| `WDSlider` 键盘焦点光环 | 平台限制（UISlider 无可观测的键盘聚焦事件），已登记 | `docs/B3-PLATFORM-LIMITS.md` L-5（不变） |
| `WDDatePicker` 自建跨午夜计时器 | 仓规禁止组件自建计时器；本批改用系统通知实现同一效果 | — |

---

## 2. 公开签名增量（只增不改）

```swift
// ── B17-3 WDDatePicker（Composites）──────────────────────────────────────────
// 在 B10 的单日期完整构造末尾追加一个默认参数（旧调用点源码零改动）。
extension WDDatePicker {
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,
    quickOptions: [WDDatePickerQuickOption] = [],
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil,
    onClear: (@MainActor @Sendable () -> Void)? = nil,
    expiredAccessibilityHint: Text? = nil   // ← B17 新增
  )
}

// ── B17-4 WDSlider（Primitives）───────────────────────────────────────────────
extension WDSlider {
  /// 范围（双手柄）。两端不允许交叉，最小间隔 = 1 步长（step 为 nil 时允许重合）。
  public init(
    range: Binding<ClosedRange<Double>>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil,
    showsValueLabel: Bool = false,
    rangeText: ((ClosedRange<Double>) -> Text)? = nil,
    lowerAccessibilityLabel: Text? = nil,
    upperAccessibilityLabel: Text? = nil
  )
}
```

**L-B 口径**：范围的值文案含分隔符，**必须由调用方给**（`rangeText`，与单值的 `valueText` 分开命名，避免同一契约键两种类型）；`nil` 时即使 `showsValueLabel` 为 true 也不显示值——库内不拼「–」。两个手柄的读屏名同理（`lowerAccessibilityLabel`/`upperAccessibilityLabel`，nil 时复用 `label`）。

**内部新增（零 public）**：`WDSliderRangeControl` / `WDSliderRangeUIControl` / `WDSliderRangeMath`（`Internal/Controls/WDSliderRangeControl.swift`）。

---

## 3. 契约增量（待落库设计仓）

| 组件 | 变更 | 备注 |
| --- | --- | --- |
| `WDSlider` | `params` 追加 `range: Binding<ClosedRange<Double>>`（与 `value` 二选一）、`rangeText`、`lowerAccessibilityLabel`、`upperAccessibilityLabel`；`slots` 不变 | C-15 第 08 行需增补「`range`（范围形态）」，**待架构师确认** |
| `WDDatePicker` | `params` 追加 `expiredAccessibilityHint: Text?`（默认 null） | 只影响单日期完整构造 |

详见 `docs/B17-CONTRACT-CHANGE-REQUEST.md`。

---

## 4. 同时修复的 B10–B16 红灯（完整环境首跑）

| # | 失败 | 根因 | 修复 |
| --- | --- | --- | --- |
| F-1 | `WDPullRefreshTests.relayRoundTrip`：第二次 `takeOutcome()` 仍返回 `.failed` | `takeOutcome` 注释写「读后即清」，实现只出栈未清值 | `takeOutcome` 读出后置 `nil` |
| F-2 | `WDNavigationBarTests.largeTitleCollapsesInView`：折叠后高度比 44 多 41 | `.frame(minHeight: 0)` 只是下限，压不到 0；大标题行仍占内容高 | 联动路径改**定高**（`frame(height:)`），不联动路径保持 `minHeight` |
| F-3 | `WDAvatarStackTests` 3 条无障碍断言：`accessibilityElements` 为空 | 单测宿主无 AX 客户端时 SwiftUI 不填充元素表（`WDCardTests` 已登记同一限制） | 读不到元素表时跳过并注明「真机走查覆盖」，不制造假红（U-B-4） |

---

## 5. 未纳入项的确切解除条件

1. **`WDCard` media**：设计 17 给出「顶部图片 + 文字区的宽高比 / 是否通栏 / 失败占位」；F-15 槽位词表增补 `media`（架构师 + android-lead 确认）。满足后按本批同一套流程开工。
2. **`WDToolbar` tooltip**：给出可执行的真机/模拟器手势回归（长按抬手不触发 action、点按仍触发），或设计改口径接受「长按也触发 action」。
3. **`WDSlider` 键盘光环**：见 `docs/B3-PLATFORM-LIMITS.md` L-5。

---

## 6. 验收判据

1. `Scripts/check-structure.sh --strict`：0 error / 0 warning；
2. `Scripts/check-format.sh`：全绿；
3. `xcodebuild build-for-testing`（模拟器，Swift 6）0 error；
4. `Scripts/dump-api.sh`：基线按本批增量显式更新，重跑零 diff；
5. 单测：范围数学 / 尺寸 / 值文案 / 过期判定与跨日刷新 / TabBar 与 FAB 无障碍断言（能跑的环境）——本机限制见出口报告 §4；
6. 快照：默认路径零漂移（本批不新增快照样例；范围形态无基线，登记为未覆盖）。
