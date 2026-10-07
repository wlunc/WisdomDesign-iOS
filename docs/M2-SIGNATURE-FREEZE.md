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

### 1.2 提案（**待冻结会确认**；据 §2.10 形态行 + C-15 逐字推导）

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
| ① | **`WDIconName` 的 44 条语义名未产出**（I-M0-h：生成器尚未产出 icon 产物；冒烟段只有占位 case） | **8 件受影响**：凡签名或槽位引用 `WDIconName` 的件（`WDButton`/`WDIconButton`/`WDListRow`/`WDAvatar`/`WDIcon` 直接引用；`WDTextFieldPrefix.icon` 间接）+ 值类型 `WDAvatarValue`/`WDBadgeValue` 成员未定 ⇒ `WDListRow` 的 `.avatar`/`.badge` 槽位无法实现 | 设计仓 `contracts/` 给出 44 条语义名 → 生成器产出 `generated/WDIconName.swift` → 同 PR 删除冒烟段占位 |
| ② | **SPEC R3-d**：`contracts/WDCheckbox.yaml` 的 `params[].name` **不得在 Android 改完前冻结**（Android 侧 14 行改名进度） | `WDCheckbox` 的**契约名**冻结（iOS 侧已改名为 `isChecked`，实现不受影响） | android-lead 完成改名 |
| ③ | `contracts/*.yaml` 库未落库（M0-5） | I-2 的"`params/slots/default` 入库"一项**按本表单代替**（I-2 原文允许） | M0-5 落库后回填 |

## 4. 冻结会待决清单（请逐条给结论，不要默认通过）

1. §1.2 的 **8 条提案签名**是否照原样冻结？（逐件确认，尤其 `WDIconButtonVariant` 的 case 集与 `WDAvatar` 是否有直径档）
2. `WDAvatarValue` / `WDBadgeValue` 的成员（§1.3）是否按提案冻结？
3. 阻塞 ①（`WDIconName`）的处置：**等生成物**（推荐）还是**先冻结其余 10 件、`WDIcon` 单独排**？（注意：`WDButton` 等的 `leadingIcon` 参数也依赖它）
4. 阻塞 ②（`WDCheckbox` 契约名）是否**只冻结 iOS 实现形态**、契约名留空待 Android？

---

> **本表单不做的事**：不改 SPEC、不改 C-15、不代拟任何 SPEC 未授权的成员（避免"凭空发明的 API"进入 `api/WisdomUI.api.json` 基线 —— 冒烟段注释对此有明确纪律）。
> 冻结会通过后，逐件开工的入口判据（I-1…I-5）才算齐备。
