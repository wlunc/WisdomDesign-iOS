# M2 批前签名冻结表单（I-2）

> 用途：满足 `docs/DEV-PLAN.md` §3.1 的入口判据 **I-2**（批前签名冻结）。
> **时点说明（照抄 I-2 原文）**：`contracts/*.yaml` 库为 **M0-5 才落库**；在此之前该判据以**本表单**代替。
> 填报日期：2026-10-07｜填报人：ios-agent｜**待确认人：ios-lead（签名）＋ 架构师（契约名）**
> 批次：**M2 = 11 件**（`WDTextField`(C)、`WDListRow`(C)、`WDButton`、`WDIconButton`、`WDSwitch`、`WDCheckbox`、`WDBadge`、`WDAvatar`、`WDDivider`、`WDCard`、`WDIcon`）

## 0. 状态图例与依据

| 标记 | 含义 |
| --- | --- |
| **已冻结** | 有**权威签名块**（SPEC 专节或 M0-11 冒烟段的显式声明），本表单只做誊录与交叉核对 |
| **提案** | SPEC **没有**签名块，只有 §2.10 的形态行 / C-15 行；本表单据其**逐字推导**出提案，**必须经冻结会确认后才算冻结** |
| **阻塞** | 有前置未满足（见 §3），**在解除前不得开工该件** |

**三处真源**（缺一不可，冲突时按 §2 裁决链）：① `docs/SPEC.md` §2.2/§2.3/§2.4/§2.10/§2.11（实现细节唯一出处）；② `docs/DEV-PLAN.md` §5.3 = **C-15 定名表**（受控值参数名唯一真源）；③ `Sources/WisdomUI/APISurface/WDAPISurface.swift`（M0-11 冒烟段 = M0 已锁定的公开面）。
**通用约束**：枚举一律 `String` 原始值 + `CaseIterable` + `Sendable`、**不加 `@frozen`**（F-20）；受控值名以 C-15 为准（F-14）；槽位词表 21 名（F-15）；读屏标签由调用方给、库内零文案（F-08/L-B）。

## 1. 逐件签名

### 1.1 已冻结（誊录自冒烟段 / SPEC）

| 件 | 权威签名 | 来源 |
| --- | --- | --- |
| `WDButton` | `init(variant: WDButtonVariant = .filled, size: WDButtonSize = .md, isLoading: Bool = false, loadingAccessibilityText: Text? = nil, leadingIcon: WDIconName? = nil, trailingIcon: WDIconName? = nil, action: @escaping () -> Void, @ViewBuilder label: () -> Label)`；另有 `Label == Text` 的两条便利构造（`_ text: LocalizedStringKey` 与 `verbatim text: String`，参数集合同上）；`enum WDButtonVariant { filled, tonal, glass, outline, plain, destructive }`、`enum WDButtonSize { sm, md, lg }`；`extension ButtonStyle where Self == WDButtonStyle { static func wd(_ variant:size:) }` | 冒烟段（SPEC §2.2 专节） |
| `WDTextField` | `init(text: Binding<String>, label: Text, appearance: WDTextFieldAppearance = .init(), isEditable: Bool = true, onSubmit: (() -> Void)? = nil, onEditingChanged: ((Bool) -> Void)? = nil)`；`WDTextFieldAppearance`（`variant/placeholder/prefix/accessory/helper/isSecure/submitLabel`，全参数有默认值，**只 `Sendable`**）；`enum WDTextFieldPrefix { none, icon(WDIconName), text(Text) }`；`WDTextFieldAccessory { none, unit(Text), clear(accessibilityLabel:), reveal(hiddenAccessibilityLabel:shownAccessibilityLabel:), count(current:limit:) }`；`WDTextFieldHelper { none, hint(Text), error(Text) }` | 冒烟段（SPEC §2.3 专节） |
| `WDListRow` | `init(title: Text, subtitle: Text? = nil, leading: WDListRowLeading = .none, trailing: WDListRowTrailing = .none, isSelected: Bool = false, swipeAction: WDListRowSwipeAction = .none, showsSeparator: Bool = true, action: (() -> Void)? = nil)`；`WDListRowLeading { none, icon(WDIconName), avatar(WDAvatarValue), checkbox, selectionIndicator }`；`WDListRowTrailing { none, value(Text), badge(WDBadgeValue), avatar(WDAvatarValue), disclosure }`；`@MainActor enum WDListRowSwipeAction { none, delete(title:onDelete:) }`（含闭包 ⇒ 不声明 `Equatable`） | 冒烟段（SPEC §2.4 专节） |

### 1.2 提案（**2026-10-07 冻结会通过 R1–R3 后按建议冻结**；据 §2.10 形态行 + C-15 逐字推导）

> **结论（2026-10-07）**：R1/R2/R3 已由 ios-lead 裁决（见 §5.0 与 §5.4）。本表 8 条的**唯一待决点都已由 R1–R3 或建议解决** ⇒ 按建议冻结。
> 其中 3 项属**判断项**（非规则推出）：**①@@size@@ 复用 @@WDButtonSize@@**、**⑤值类型保持 @@struct@@**、**⑧@@WDIconSize@@ 默认 @@.md@@** —— 已按建议记录，**可一句话推翻**（推翻需同步改本表与 §5.1）。

| 件 | 提案签名 | 推导依据 | 待决点 |
| --- | --- | --- | --- |
| `WDIconButton` | `init(icon: WDIconName, accessibilityLabel: Text, variant: WDIconButtonVariant = .plain, size: WDButtonSize = .md, isLoading: Bool = false, action: @escaping () -> Void)`；`enum WDIconButtonVariant`（至少含 `plain`） | §2.10-#02（受控值 `isLoading`；槽位 `icon` + **a11y 标签必填**；特例 `.plain`）；SPEC:869 明确 `accessibilityLabel: Text` **无默认值** | ① 档位枚举的完整 case 集（是否与 `WDButtonVariant` 同族）② `size` 是否复用 `WDButtonSize` |
| `WDSwitch` | `init(isOn: Binding<Bool>, label: Text)` | §2.10-#05（受控值 `isOn` ✓；槽位 `label`） | `label` 是否必填（L-B 倾向必填） |
| `WDCheckbox` | `init(isChecked: Binding<Bool>, label: Text)` | §2.10-#06（受控值 **`isChecked`** ✓，C-15 唯一改名）；SPEC:12 强调"正文旧、结论新" | **契约名冻结有前置**（见 §3-②） |
| `WDBadge` | `init(_ label: Text)` | §2.10-#11（受控值 —；槽位 `label`；特例 4 汉字） | 是否需要档位/色调参数（§2.10 未给 ⇒ 提案**不加**） |
| `WDAvatar` | `init(_ value: WDAvatarValue, size: WDAvatarSize = .md)` | §2.10-#12（槽位 `icon`,`label`；特例"直径锁死"） | 直径档位是否存在；`WDAvatarValue` 的成员（见下） |
| `WDDivider` | `init()`（装饰件） | §2.10-#14（槽位"无"；装饰 `accessibilityHidden`；不进树） | 是否需要 `orientation`/`inset`（§2.10 未给 ⇒ 提案**不加**） |
| `WDCard` | `init(style: WDCardStyle = .elevated, @ViewBuilder content: () -> Content)` | §2.10-#17（槽位 `content`；特例 `.elevated`）；§2.11 给了 `WDCardStyle` 的类型声明（R3-01）；快照渲染器表含 **`WDCard(.glass)`** | `.glass` 是否属 `WDCardStyle` 的 case（快照表按此写） |
| `WDIcon` | `init(_ name: WDIconName)` | §2.10-#20（槽位 `icon`；装饰：不进树） | 是否有尺寸档位参数 |

### 1.3 被引用但**成员未定义**的值类型（同属冻结范围）

| 类型 | 现状 | 提案 |
| --- | --- | --- |
| `WDIconName` | 冒烟段只有 **1 个占位 case `placeholder`**；真源是**生成物的 44 条语义名**（I-M0-h）**尚未产出** | **不得自造**：等生成器产出后整段替换（冒烟段注释已写明"落地时必须同 PR 删除本段"） |
| `WDAvatarValue` | 冒烟段是**空 `struct`**（只锁类型名） | 提案：`initials: Text?` + `icon: WDIconName?`（库内零资源 ⇒ 不接受图片名）**待决** |
| `WDBadgeValue` | 同上，空 `struct` | 提案：`text: Text`（对应 §2.10-#11 的 `label` 槽位）**待决** |

## 2. C-15 一致性交叉核对（I-3-① 的口径）

| 件 | C-15 受控值名 | 本表单签名中的形参名 | 一致？ |
| --- | --- | --- | --- |
| `WDButton` | `loading` / `isLoading` | `isLoading` ✓ | ✅ |
| `WDIconButton` | `loading` / `isLoading` | `isLoading` ✓ | ✅ |
| `WDTextField` | `text` / `Binding<String>` ✓ | `text: Binding<String>` ✓ | ✅ |
| `WDSwitch` | `on` / `isOn` ✓ | `isOn` ✓ | ✅ |
| `WDCheckbox` | `checked` / **`isChecked`** ✓ | `isChecked` ✓ | ✅（**契约侧待 Android**，见 §3-②） |
| `WDListRow` | `isSelected`（§2.4） | `isSelected` ✓ | ✅ |
| `WDBadge` / `WDAvatar` / `WDDivider` / `WDCard` / `WDIcon` | —（无受控值） | — | ✅ |

**槽位核对**：`WDButton` = `label/leadingIcon/trailingIcon` ✅；`WDIconButton` = `icon` + a11y 标签 ✅；`WDTextField` = `label/prefix/accessory/helper` ✅；`WDSwitch`/`WDCheckbox` = `label` ✅；`WDBadge` = `label` ✅；`WDAvatar` = `icon/label` ✅；`WDDivider` = 无 ✅；`WDCard` = `content` ✅；`WDIcon` = `icon` ✅；`WDListRow` = `title/subtitle/leading/trailing`（§2.4，含 `content` 例外）—— 全部落在 **21 名词表**内（F-15）。

## 3. 阻塞与前置（**I-2 判定的关键**）

| # | 阻塞 | 影响 | 解除条件 |
| --- | --- | --- | --- |
| ① | **`WDIconName` 的 44 条语义名未产出** —— **完整设计稿见 `docs/ICON-PIPELINE.md`**（含 44 条对照表与 §6 的两条实测结论）（I-M0-h：生成器尚未产出 icon 产物；冒烟段只有占位 case）—— **注意：名单本身不缺**。2026-10-07 核实：设计仓 `../wisdomdesign/docs/08-icons.md` §4「语义对照表」**已给全 44 条**（导航 7 + 操作 12 + 状态 8 + 表单 6 + 内容分类 11），每条含 SF Symbols 与 Material Symbols 两端名；图标尺寸阶梯（`sm 16 / md 20 / lg 24 / xl 28`）亦在该文档 §2。**缺的是两段管道**：设计仓 `contracts/`（M0-5）收录 + 生成器产出产物。`mirrorsInRTL` 在该文档出现 0 次，但 F-07 规定它只用于契约断言（渲染靠 SF Symbols 自带镜像元数据）⇒ 可机械推导，不必等设计 | **8 件受影响**：凡签名或槽位引用 `WDIconName` 的件（`WDButton`/`WDIconButton`/`WDListRow`/`WDAvatar`/`WDIcon` 直接引用；`WDTextFieldPrefix.icon` 间接）+ 值类型 `WDAvatarValue`/`WDBadgeValue` 成员未定 ⇒ `WDListRow` 的 `.avatar`/`.badge` 槽位无法实现 | 设计仓 `contracts/` 给出 44 条语义名 → 生成器产出 `generated/WDIconName.swift` → 同 PR 删除冒烟段占位 |
| ② | **SPEC R3-d**：`contracts/WDCheckbox.yaml` 的 `params[].name` **不得在 Android 改完前冻结**（Android 侧 14 行改名进度） | `WDCheckbox` 的**契约名**冻结（iOS 侧已改名为 `isChecked`，实现不受影响） | android-lead 完成改名 |
| ③ | `contracts/*.yaml` 库未落库（M0-5） | I-2 的"`params/slots/default` 入库"一项**按本表单代替**（I-2 原文允许） | M0-5 落库后回填 |

## 4. 冻结会待决清单（请逐条给结论，不要默认通过）—— **逐条建议见 §5**

1. §1.2 的 **8 条提案签名**是否照原样冻结？（逐件确认，尤其 `WDIconButtonVariant` 的 case 集与 `WDAvatar` 是否有直径档）
2. `WDAvatarValue` / `WDBadgeValue` 的成员（§1.3）是否按提案冻结？
3. 阻塞 ①（`WDIconName`）的处置：名单已在设计仓 `08-icons.md` §4（44 条，**无需设计再给**）⇒ 剩下的是**管道**（`contracts/` 收录 + 生成器产出）。请在两条里二选一：**(a) 等生成物**，再开工全部 8 件受影响件；**(b) 先开工不依赖图标的 5 件**（`WDSwitch`/`WDCheckbox`/`WDBadge`/`WDDivider`/`WDCard`）+ `WDTextField`（其 `Prefix.icon` 一个 case 延后），把 `WDButton`/`WDListRow`/`WDAvatar`/`WDIconButton`/`WDIcon` 留到生成物到位
4. `WDIconName` 的形态：**rawValue 用语义名还是 SF Symbol 名**？语义名到 SF Symbols 的映射表放**生成物**还是手写？（F-07 的口径 = 契约只统一语义名、iOS 按名取 SF Symbols）
4. 阻塞 ②（`WDCheckbox` 契约名）是否**只冻结 iOS 实现形态**、契约名留空待 Android？

---

> **本表单不做的事**：不改 SPEC、不改 C-15、不代拟任何 SPEC 未授权的成员（避免"凭空发明的 API"进入 `api/WisdomUI.api.json` 基线 —— 冒烟段注释对此有明确纪律）。
> 冻结会通过后，逐件开工的入口判据（I-1…I-5）才算齐备。

## 5. 冻结会逐条确认稿（2026-10-07 版）

> 用法：**先过 §5.0 的三条通用规则**（一次定完可省掉逐条重复讨论），再逐件在 §5.1 的「结论」栏勾选。
> 会议结束后：把结论回填到 §1.1/§1.2（把「提案」改成「已冻结」并标注日期与签字人），并在 §5.4 留档。
> **纪律**：本稿不发明 SPEC 未给的档位/参数（通则 R3）；凡与契约名相关的取舍都以"I-3① 逐行比对能过"为准绳。

### 5.0 先定三条通用规则（建议一次通过）

| # | 规则 | 理由 | 例外 |
| --- | --- | --- | --- |
| **R1** | 单槽位组件的 `init` 用**带标签**形参（`label:`/`icon:`/`value:`/`content:`），**不用 `_` 无标签** | I-3① 的判据是 "C-15 与 `contracts/<component>.yaml` 的 `params[].name` **逐行比对 0 不一致**"；无标签形参在契约里**没有对应的 name** ⇒ 这条机器断言会失配 | `WDButton` 已有的 `_ text: LocalizedStringKey` 是**便利重载**、不承载受控值名 ✅；M2 不新增同类 |
| **R2（2026-10-07 裁决：放宽）** | **允许 `Text("")` 作为槽位默认值**（"给不给文案"由**使用方**决定）；「没有这个槽」仍用**可选类型** `Text? = nil` 表达。**一处例外**：`WDIconButton.accessibilityLabel` —— SPEC:869 明文"无默认值"（防"忘传标签"），本放宽**未覆盖**该处 | L-B：文案与读屏标签由调用方给；与 SPEC:869（`WDIconButton` 的 `accessibilityLabel: Text` **无默认值**）同一条纪律 | `WDListRow.subtitle: Text? = nil` 这类**可选槽**不受本规则限制（它表达「没有」，不是「默认文案」） |
| **R3** | §2.10 **未给的档位/参数一律不加** | 不发明 API。**但延后不是免费的，代价要如实写**：① **新增枚举 case = 源级 breaking**（F-20：minor + Breaking 段 + 迁移片段；枚举非 `frozen` ⇒ 二进制不受影响，破坏的是消费方的穷举 `switch`）；② **给既有公开 `init` 追加带默认值的参数** = 破坏符号快照连续性（§2.9 规则 1：需显式基线更新 + CHANGELOG）。两笔代价都**远小于**「现在发明未经设计确认的档位」——那会要么被设计否决、要么长期背一个没人要的 API | 无 |

### 5.1 逐件确认（8 件）

> 每件的「结论」栏请勾一个：☐ **照原样冻结** ｜ ☐ **修改为**（写明）

**① `WDIconButton`**（§2.10-#02）
```swift
public enum WDIconButtonVariant: String, CaseIterable, Sendable, Equatable { case plain }
public struct WDIconButton: View {
  public init(icon: WDIconName, accessibilityLabel: Text,
              variant: WDIconButtonVariant = .plain,
              size: WDButtonSize = .md,
              isLoading: Bool = false,
              action: @escaping () -> Void)
}
```
- 依据：§2.10-#02（受控值 `isLoading`；槽位 `icon` + **a11y 标签必填**；特例 `.plain`）+ SPEC:869（`accessibilityLabel: Text` 无默认值）+ C-15。
- 待决：**(i)** `WDIconButtonVariant` 的 case 集 —— **建议只 `plain`**（§2.10 只钉了这一档；其余等设计依据，R3）；**(ii)** `size` —— **建议复用 `WDButtonSize`**（一档尺寸体系优于两套）。
- **附带说明（不在本次签名范围，但实现时必须钉住）**：`WDButtonSize` 是**控件档**（盒高 sm/md/lg），`WDIconSize` 是**图形档**（16/20/24/28），两者**不是同一套**。「控件档 → 图标档」的映射（例如 `.lg` 按钮里用几号图标）属**实现内部的既定映射**，实现时要写进文档并加断言；若设计另有口径，届时按设计改。
- 结论：☐

**② `WDSwitch`**（§2.10-#05）
```swift
public struct WDSwitch: View {
  public init(isOn: Binding<Bool>, label: Text)
}
```
- 依据：§2.10-#05（受控值 `isOn` ✓；槽位 `label`）+ C-15。
- 待决：`label` 既是**可见文本**又兼作读屏标签 —— **建议是**（槽位词表对开关只有 `label` 一个槽；再要一个独立 a11y 标签属发明，R3）。
- 结论：☐

**③ `WDCheckbox`**（§2.10-#06）
```swift
public struct WDCheckbox: View {
  public init(isChecked: Binding<Bool>, label: Text)
}
```
- 依据：§2.10-#06 + SPEC:12（"正文旧、结论新"：**以 `isChecked` 为准**）+ C-15（iOS 侧唯一改名）。
- 待决：**契约名**冻结有前置（SPEC **R3-d**：Android 14 行改名未完成前 `contracts/WDCheckbox.yaml` 的 `params[].name` 不得冻结）—— **建议：先冻结 iOS 实现形态（`isChecked`），契约 `params[].name` 标注"待 Android"**。
- 结论：☐

**④ `WDBadge`**（§2.10-#11）
```swift
public struct WDBadge: View {
  public init(label: Text)
}
```
- 依据：§2.10-#11（受控值 —；槽位 `label`；特例"4 汉字"= 宽度上限，属**实现约束、不进签名**）。
- 待决：是否要色调/档位 —— **建议不加**（§2.10 未给，R3）。
- 结论：☐

**⑤ `WDAvatar` + `WDAvatarValue`**（§2.10-#12）
```swift
public struct WDAvatarValue: Sendable, Equatable {
  public init(icon: WDIconName)
  public init(label: Text)
}
public struct WDAvatar: View {
  public init(value: WDAvatarValue)
}
```
- 依据：§2.10-#12（槽位 `icon`,`label`；无障碍"读成员名"⇒ label 本身即读屏文本，**不需要第二个 a11y 参数**；特例"直径锁死"）。
- 待决：**(i)** 值类型**保持 `struct`**（冒烟段已声明 `struct`；改 `enum` 属类型形变更）—— **建议保持**；**(ii)** 是否要尺寸档 —— **建议不加**（§2.10 只给"直径锁死"）。
- 结论：☐

**⑥ `WDDivider`**（§2.10-#14）
```swift
public struct WDDivider: View {
  public init()
}
```
- 依据：§2.10-#14（槽位"无"；装饰 `accessibilityHidden`、不进树 ⇒ 属**实现**）。
- 待决：是否要 `orientation`/`inset` —— **建议不加**（R3）。
- 结论：☐

**⑦ `WDCard`**（§2.10-#17；**唯一有权威签名块的一件**）
```swift
public enum WDCardStyle: String, CaseIterable, Sendable, Equatable { case elevated, outlined, glass }
public struct WDCard<Content: View>: View {
  public init(style: WDCardStyle = .elevated, @ViewBuilder content: () -> Content)
}
```
- 依据：**SPEC §2.11** 已给枚举声明、case、默认值 `.elevated` 与参数连接式 `WDCard(style: WDCardStyle = .elevated, …)`；§2.10-#17 槽位 `content`、容器 `contain`；快照渲染器表含 **`WDCard(.glass)`**（⇒ `glass` 必需）。
- 待决：**无** —— 建议照原样冻结（本件不是提案，是誊录）。
- 结论：☐

**⑧ `WDIcon` + `WDIconSize`**（§2.10-#20）
```swift
public enum WDIconSize: String, CaseIterable, Sendable, Equatable { case sm, md, lg, xl }
public struct WDIcon: View {
  public init(icon: WDIconName, size: WDIconSize = .md)
}
```
- 依据：§2.10-#20（槽位 `icon`；装饰：不进树）；设计仓 `08-icons.md` §2 的**四档**（16/20/24/28 + 线宽）⇒ 档位**来自设计、非发明**；`WDIconSize` 为 **public**（已定）。
- 待决：默认档 —— **建议 `.md`**（设计文档：md=20 用于"表单前缀、列表、工具栏"，是主用档）。
- 结论：☐

### 5.2 值类型成员（同属本次冻结范围）

| 类型 | 提案 | 理由 | 结论 |
| --- | --- | --- | --- |
| `WDAvatarValue` | 见 §5.1-⑤（两个 `init`：`icon:` / `label:`） | 对应 §2.10-#12 的两个槽位 | ☐ |
| `WDBadgeValue` | `public struct WDBadgeValue: Sendable, Equatable { public init(label: Text) }` | 它是 `WDListRowTrailing.badge(WDBadgeValue)` 的**值形态**，与 `WDBadge` 同源 | ☐ |

### 5.3 阻塞处置（二选一）

| 选项 | 内容 | 代价 |
| --- | --- | --- |
| (a) 等生成物 | 等 `contracts/icons.json` + 生成器产出 `WDIconName.swift` 落地后再开工全部 8 件受影响件 | M2 全线停在契约管道上 |
| **(b) 建议** | **先开工不依赖图标的 6 件**：`WDSwitch` / `WDCheckbox` / `WDBadge` / `WDDivider` / `WDCard` + `WDTextField`（其 `Prefix.icon` 一个 case 延后）；把 `WDButton` / `WDListRow` / `WDAvatar` / `WDIconButton` / `WDIcon` 留到生成物到位 | 需要维护一份"延后清单"（已在本表列明） |

### 5.4 决议记录表（会上填写；会后回填 §1 并留档）

| # | 决策项 | 结论 | 签字 | 日期 |
| --- | --- | --- | --- | --- |
| R1 | 单槽位用带标签 `init` | ✅ **通过**（带标签） | ios-lead | 2026-10-07 |
| R2 | 槽位默认值 | ⚠️ **修改后通过**：**允许 `Text("")`**（由使用方决定）；可选槽仍用 `Text? = nil`；`accessibilityLabel` 按 SPEC:869 保持无默认值 | ios-lead | 2026-10-07 |
| R3 | 未给档位不发明 | ✅ **通过**（按建议：只冻结 §2.10 给出的档位；延后的两笔代价见 §5.0-R3） | ios-lead | 2026-10-07 |
| ①–⑧ | §5.1 逐件 | ☐ 全部照原样 ☐ 逐件修改（见各件） | | |
| 5.2 | 两个值类型成员 | ☐ 通过 ☐ 修改 | | |
| 5.3 | 阻塞处置 | ☐ (a) 等 ☐ (b) 先开工 6 件 | | |
| 5.5 | `WDIconName` 形态（见下） | ☐ rawValue = 语义名 ☐ 其他 | | |

**5.5 `WDIconName` 的形态**（解堵时要用，先记结论）：**建议 rawValue = 语义名**（契约键的代码镜像；Apple 改名/换符号时契约键稳定），语义名到 SF Symbols 的映射表**放生成物**（纯字符串表、无需 Swift 类型构造 ⇒ 与 `WDColorValues` 那种手写层不同；详见 `docs/ICON-PIPELINE.md` §4）。
