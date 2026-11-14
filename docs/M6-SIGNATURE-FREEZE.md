# M6 批前签名冻结（1 件）—— 已冻结

> 用途：满足 **I-2**（批前签名冻结）。M6 = **场景组件 1 件 + 回归发布**（`docs/DEV-PLAN.md` §2.7/§3）。
> 日期：**2026-11-14**｜状态：**已冻结（项目负责人 2026-11-14「开始M6」+ 两项范围确认）**
> 依据：`docs/SPEC.md` §2.10-#37、设计仓 `docs/specs/03-patterns.md` §37、`docs/DEV-PLAN.md` §21.6 的 M6 十问、`../AGENTS.md` §6/§10/§12。
> 关联：`../wisdomdesign/contracts/WDAssigneePicker.yaml`、`docs/M6-EXIT-REPORT.md`（结批时产出）。

## 1. 入口判据（I-1…I-5）

| # | 判据 | 现状 |
| --- | --- | --- |
| I-1 | 上一里程碑出口已判定 | ✅ **M5 技术判据 6/6**（`docs/M5-EXIT-REPORT.md`）；nightly **2/3**（2026-11-13、11-14 绿；11-15 未到）。**项目负责人 2026-11-14 决定按 M3/M4 先例豁免 nightly₃**，判定 M5 出口通过。 |
| I-2 | 1 件签名 + 契约入库 | ✅ **本文件 + `../wisdomdesign/contracts/WDAssigneePicker.yaml`**（见 §3） |
| I-3 | 令牌 / 契约已冻结 | ✅ `schemes` 维度、32 色槽位、玻璃档位、配额 7 条、弹簧 μ=1.0、行高单值键均已生效 |
| I-4 | 门禁可跑且为绿 | ✅ 基线 `Scripts/ci.sh pr` 全绿（**156 tests / 1212 符号 / Foundation 97.26% / warm 32.49 s**，2026-11-14 实测）；本机需 **full-access** 才能起 Xcode 宏插件与 xctest |
| I-5 | 未闭合前置项都有默认执行项 | ✅ 见 §5 的 D1–D9；**Android 仍在 M1（M2–M5 未实现）⇒ 双端 tag `v1.0.0` 本轮不闭合**，已确认 iOS 先行、tag 待 Android 追平 |

## 2. 冻结签名

> 通则：受控值用 `Binding`；枚举一律 `String, CaseIterable, Sendable`（+ `Equatable`）；
> 含 `Text` 的值类型**不声明 `Hashable`**；**库内零文案** —— 组标签、成员名、读屏句、位置措辞全部由调用方以 `Text` 传入。

### 2.1 `WDAssigneePicker`（设计 37；落 `Components/Composites/`）

```swift
// MARK: #37 WDAssigneePicker（设计 37；头像横排选择；标准 40 / 紧凑 32）
public enum WDAssigneePickerSize: String, CaseIterable, Sendable, Equatable {
  /// 头像 40 + 名字 + 选中外环外径 52（设计 37 §3）。
  case standard
  /// 头像 32、不显示名字、外环外径 44（设计 37 §4「紧凑」）。
  case compact
}

/// 一位候选人（值数组 `items`）。
public struct WDAssigneePickerItem: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 头像值（复用 `WDAvatarValue`；头像直径由组件按档位给）。
  public let avatar: WDAvatarValue
  /// **读屏名（必填）**：设计 37 §10 的「妈妈…」由此给（L-B 零文案）。
  public let accessibilityLabel: Text
  /// 可见名字（设计 37 §7：可选、`type.caption1`、≤ 4 个汉字、超出截断）；nil = 只显示头像。
  public let name: Text?
  /// 是否可选（设计 37 §5：已离开家庭的成员 = false，40% 去饱和、仍可见）。
  public let isEnabled: Bool
  /// 不可选原因（设计 37 §10 的「已离开」；只作读屏 hint，nil = 无）。
  public let unavailableReason: Text?

  public init(
    id: String,
    avatar: WDAvatarValue,
    accessibilityLabel: Text,
    name: Text? = nil,
    isEnabled: Bool = true,
    unavailableReason: Text? = nil
  )
}

/// 「未指派」虚拟项（设计 37 §2/§4：首位固定、虚线圈 + `user-x`；点它清空选择）。
public struct WDAssigneePickerUnassigned: Sendable, Equatable {
  /// 可见名字（如「未指派」；紧凑档不显示）。
  public let label: Text
  /// 读屏名（必填）。
  public let accessibilityLabel: Text

  public init(label: Text, accessibilityLabel: Text)
}

public struct WDAssigneePicker: View {
  /// **单选**（默认）：`nil` = 未指派/未选；点已选项**不取消**（设计 37 §12）。
  /// `unassigned` 非 nil 时首位渲染「未指派」，点它把 `selection` 置 nil。
  public init(
    selection: Binding<String?>,
    label: Text,
    items: [WDAssigneePickerItem],
    unassigned: WDAssigneePickerUnassigned? = nil,
    size: WDAssigneePickerSize = .standard,
    positionText: ((Int, Int) -> Text)? = nil,
    onOverflowTap: (() -> Void)? = nil,
    overflowAccessibilityLabel: Text? = nil
  )

  /// **多选**（设计 37 §4「参与人」场景）：点已选项 = 取消该项；无「未指派」项。
  public init(
    selection: Binding<Set<String>>,
    label: Text,
    items: [WDAssigneePickerItem],
    size: WDAssigneePickerSize = .standard,
    positionText: ((Int, Int) -> Text)? = nil,
    onOverflowTap: (() -> Void)? = nil,
    overflowAccessibilityLabel: Text? = nil
  )
}
```

> **为什么两个 init**：单选受控值与多选受控值类型不同（`String?` / `Set<String>`），用编译期分离避免运行期模式串；
> 与 M5 的 `WDChip` 三 init（Q5）同口径。契约 `params` 只登记默认（单选）形态，多选重载在 yaml 注释里写明。

### 2.2 设计口径 → 冻结实现（逐条可判）

| 设计 37 | 冻结口径 |
| --- | --- |
| §3 头像 40 / 间距 `space.4` 12 / 选中外环 2pt + 4 间隙（外径 52） | 头像 40（紧凑 32）；**项槽 = 52（紧凑 44），槽间距 12**（对齐画廊 `.wd-assign` 的 gap；头像视觉间距 24）；选中环 = 52 槽 `strokeBorder` 2pt（内边 48）+ 头像**静止 1.0** ⇒ 圈内间隙 **4**（紧凑同） |
| §3 名字与头像间距 `space.2` 4；名字 `type.caption1` | VStack 间距 4；`.wdFont(WDType.caption1)` + `.wdLineBox(WDType.caption1)`；`lineLimit(1)` 截断 |
| §2 未指派项 虚线圈 + `user-x` | **52 槽虚线圈**（1.5pt `borderHairlineStrong`，dash 3/3）+ `person.fill.xmark`（契约 `icons.json` 的 iOS 映射由 `person.crop.circle.badge.xmark` 修正；Android 仍 `person_off`）；选中时换 2pt 品牌实线圈 + 品牌色图标 |
| §5 选中名字 | 品牌色 + 600（`.fontWeight(.semibold)`）；未选 `text.secondary` |
| §3 最多直接显示 6 个（含「未指派」），超出显示 `+n` | `maxVisible = 6`（含未指派）；超出时 6 个 + `+n` 圆片（n = 总数 − 6），样式对齐 `WDAvatarStack` 的溢出片 |
| §4 单选 / 多选 / 带未指派 / 紧凑 | 两个 init（单选/多选）+ `unassigned` 参数 + `WDAssigneePickerSize` |
| §5 选中：头像缩放 1.05 + 品牌环；200ms `spring.bouncy`、环 160ms 淡入 | **先弹到 1.05 再回弹到 1.0**（`bouncingID` + 200ms 后复位；静止尺寸不变）+ `WDMotion.Spring.bouncy`；环 `.easeOut(0.16)`（`WDMotion.Duration.fast`）；Reduce Motion ⇒ 无动画 |
| §5 按下：缩放 0.94 / 100ms | `ButtonStyle` `scaleEffect(0.94)` + `WDMotion.Duration.instant` |
| §5 禁用成员：40% 去饱和、仍可见不可选 | `isEnabled: false` ⇒ 该项 `.opacity(0.4)` + `.saturation(0)`；**仍留在无障碍树**（读屏 hint = `unavailableReason`） |
| §5 整体禁用：全部 40% | `@Environment(\.isEnabled)` ⇒ 整组 40% + 全部不可交互 |
| §6 横向滚动、滚动条不显示、初始滚到选中项 | `ScrollView(.horizontal)` + `.scrollIndicators(.hidden)` + `ScrollViewReader` 在 `onAppear` 滚到选中项；选中项若在第 6 位之后，**替换进可见窗口**（保证「选中项在可视区」）；Reduce Motion ⇒ 无动画 |
| §6 组标签 `type.footnote` / `text.secondary` | `.wdFont(WDType.footnote)` + `colors.textSecondary`；与组间距 `space.3` 8（设计未给值，取令牌默认） |
| §6 与下方内容间距 `space.5` / 横向内边距 `space.5` | **由调用方给**（库内组件统一不自带外边距；差异登记 D8） |
| §10 组 = `radiogroup`/`group` + 组标签 | `.accessibilityElement(children: .contain)` + `.accessibilityLabel(label)`；SwiftUI 无 `radiogroup`/`radio` trait ⇒ 逐项 `.isSelected`（与 `WDRadio` ③ 同口径，登记差异） |
| §10 「第 n 项，共 m 项」 | `positionText: ((Int, Int) -> Text)?`：调用方给措辞（库内零文案）；非 nil 时写入 `.accessibilityValue`。nil = 不朗读位置（同 `WDRadio` ③，登记差异） |
| §10 禁用的成员朗读「…已离开，不可选」 | `.accessibilityHint(unavailableReason)` + 系统 disabled 语义（「变暗」）；原因文案由调用方给 |
| §10 头像首字标记为装饰 | 头像在按钮内 `.accessibilityElement(children: .ignore)`，整项由按钮的 `accessibilityLabel` 朗读 |
| §10 热区 ≥ 44×44 | 每项 `.frame(minWidth: 44, minHeight: 44)`（标准 52、紧凑 44） |

### 2.3 语义 / 触觉

| 事件 | 语义 |
| --- | --- |
| 单选点未选项 | 切换到该项；`.toggle` 轻触觉一次 |
| 单选点已选项 | **不变**（设计 37 §12）；无触觉 |
| 点「未指派」 | `selection = nil`；`.toggle` 一次 |
| 多选点未选项 / 已选项 | 加入 / 移除；`.toggle` 一次 |
| 点禁用成员 | 无变化、无触觉 |
| 滚到选中项 | 240ms `motion.spring.gentle`（Reduce Motion ⇒ 直接定位） |
| 点 `+n` | 调 `onOverflowTap`（库不自行弹面板，见 D3） |

## 3. 契约条目（同批回填 `../wisdomdesign/contracts/`）

```yaml
component: WDAssigneePicker
params: [selection, label, items, unassigned, size]
slots: [items, label]
default: {unassigned: null, size: .standard}
enums: {WDAssigneePickerSize: [standard, compact]}
```

| 项 | 值 |
| --- | --- |
| 受控值（C-15 canonical / iOS） | `selection` / `selection` |
| `slots` | `items`、`label`（组标签） |
| 关键默认 | `unassigned = nil`、`size = .standard`、`positionText/onOverflowTap/overflowAccessibilityLabel = nil` |
| 枚举 | `WDAssigneePickerSize`(standard, compact) |
| 多选重载 | `selection: Binding<Set<String>>`（同一 `selection` 参数名；yaml 注释登记） |

## 4. 验证计划（冻结后执行）

1. `Scripts/dump-api.sh`：新增符号与冻结表逐字一致；API 基线随成因同提交（+1 组件 ≈ +30 符号）。
2. 契约断言：组件类型名集合 **36 → 37**；枚举 `allCases.map(\.rawValue)` 与契约一致；默认值断言。
3. 单测（`M6ComponentsTests`）：
   - 尺寸：标准头像 40 / 外环外径 52 / 紧凑 32 / 外环 44（±1）；每项热区 ≥ 44；
   - 单选：切换、点已选项不回调、点「未指派」清空；
   - 多选：加/减、Set 内容正确；
   - 溢出：7 项 → 6 + `+1`；含未指派时计入 6；`onOverflowTap` 回调；
   - 禁用成员：点击无回调、仍在无障碍树；整体禁用：无回调；
   - `positionText` 收到 (index, total) 且顺序含「未指派」为第 1 项。
4. 八态快照（浅/深 × 默认/AX3 × LTR/RTL）：`WDAssigneePicker` **8 张新基线**（总 **344**）；单选 + 未指派 / 多选 / 紧凑 / 整体禁用 / 溢出 `+n` 全部并入同一画布样本（`assigneepicker-*`）。**渲染器 = `UIHostingController` + `drawHierarchy`**：组件内含横向 `ScrollView`，`ImageRenderer` 会把滚动内容画成空白（2026-11-14 实测后改）。
5. 无障碍：`performAccessibilityAudit` 四类目（demo 审计视口 + M6 代表实例）；VoiceOver 走查记录见 `docs/M6-EXIT-REPORT.md`。
6. demo：组件目录 36 → **37 件**；详情页含单选/多选/未指派/紧凑/禁用/溢出六个场景。

## 5. 已拍板与默认执行项（2026-11-14）

| # | 问题 | 最终口径 |
| --- | --- | --- |
| **D1** | 多选 API 形态 | **两个 init 编译期分离**（单选 `Binding<String?>` / 多选 `Binding<Set<String>>`），同 `WDChip` Q5 口径 |
| **D2** | 「未指派」项 | **内置虚拟项**（`WDAssigneePickerUnassigned`，仅单选）；`selection == nil` 即未指派；点它清空 |
| **D3** | 溢出 `+n` 展开 | **`onOverflowTap` 回调**；库不自弹 `WDBottomSheet`（零文案 / 零内容依赖），展开的完整列表由调用方承载；**差异登记** |
| **D4** | 长按成员资料浮层 | **不做**（库无资料内容模型；同 `WDAvatarStack` 的「点击展开不可表达」），**差异登记** |
| **D5** | 已离开成员 | `isEnabled: false` + `unavailableReason: Text?`（读屏 hint）；视觉 40% 去饱和 |
| **D6** | 名字 | 视觉 `name: Text?`（≤4 字由调用方保证，库只截断）；读屏 `accessibilityLabel` **必填**（L-B） |
| **D7** | 位置朗读 | 可选闭包 `positionText(index, total)`；nil = 不朗读位置（与 `WDRadio` ③ 同口径，差异登记） |
| **D8** | 外边距 16 | **调用方给**（组件不自带外边距，与库内其余组件一致） |
| **D9** | 选中项不可见时 | 第 6 位之后被选中 ⇒ **替换进可见窗口**（保证「初始渲染选中项在可视区内」）；顺序以外的置换登记为实现细节 |
| **D10** | 双端 tag | **本轮只做 iOS**；`v1.0.0` 待 Android M2–M5 追平后双端同时打（项目负责人 2026-11-14 确认） |
| **D11** | **2026-11-14 视觉复核（用户指出未指派/圈间隙不一致）** | 未指派改 **52 虚线圈 + `person.fill.xmark`**（契约 iOS 映射修正）；选中环按 **52 槽 2pt**、头像**静止 1.0**（选中只做 200ms 弹到 1.05 后回弹，原 1.05 常驻是错误）；项槽间距按画廊 **12**；选中名字品牌色 + 600 |

## 6. 确认与合并记录

| 项 | 值 |
| --- | --- |
| 确认人 | 项目负责人 |
| 日期 | 2026-11-14 |
| 结论 | 同意豁免 M5 nightly₃ 并开 M6；M6 范围 = iOS 全流程（组件 + 回归 + 截图封板 + 发布前层），双端 tag 待 Android；签名按 §2 冻结，D1–D9 按默认执行项 |
| 后续 | 契约 yaml 已回填；实现与门禁见 `docs/M6-EXIT-REPORT.md` |

## 7. 实现完成与差异（2026-11-14）

- 1 件落地（`Components/Composites/WDAssigneePicker/`）；结构断言 **7 条**（`M6ComponentsTests`）；
  快照 **8 张**（M6 时总 **344**；后续 ProgressBar 补齐 +8 ⇒ 当前 **352**）；demo **37 件**；`Scripts/ci.sh pr` **164 tests / 1246 符号 / Foundation 97.11%**；
  demo **14 条 UITest** 全过（含四类目无障碍审计与 AssigneePicker 交互）。
- 契约已回填设计仓：`contracts/WDAssigneePicker.yaml`（设计仓提交 `fa08037`）。
- **已接受差异**（逐条见 `docs/M6-EXIT-REPORT.md` §4）：溢出展开走 `onOverflowTap` 回调；长按资料浮层不做；
  `radiogroup`/`radio` 角色不可表达；位置朗读可选；外边距由调用方给；选中项替换进可见窗口。
- **未验证**：VoiceOver 人审（无 USB 真机）、Thinning 增量（未签名归档）、真机 hitch、
  双端 tag `v1.0.0`（Android 停在 M1）——按 `docs/SPEC.md` §8.2 记【未验证】。
- **门禁**：M5 nightly 2/3 按项目负责人 2026-11-14 先例豁免；M6 nightly 第 **1/3** 日绿（2026-11-14，待连续 3 日）。
