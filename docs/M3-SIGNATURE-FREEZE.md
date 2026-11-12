# M3 批前签名冻结（`WDListSection`）—— **草案，待 ios-lead 确认**

> 状态：**已确认（2026-11-12）**。依据 = `docs/M2-SIGNOFF-PACKAGE.md` §4.1 的五个推荐值；
> 项目负责人 2026-11-12 「确认签字，其他问题按照建议」⇒ **五问按推荐值冻结**，实现按此落地。
> 本文件与实现先在分支 `feat/m3-wdlist-section` 验证，M2 签字后合并（M2 已于 2026-11-12 签字通过）。
> 关联：`docs/M3-PREP-LISTSECTION.md`（五问背景）、`docs/SPEC.md` §2.10-#19、设计仓 `specs/01-basic.md` #19。

## 1. 五问裁决（推荐值 → 本草案采用值）

| # | 议题 | 推荐/采用 | 说明 |
| --- | --- | --- | --- |
| Q1 | `items` 形态 | **数据数组** `[Item]` + `row` 构建器 | 空集合 ⇒ 整组隐藏；末行 ⇒ `isLast` 可机器化（ViewBuilder 无法判空/判末行） |
| Q2 | `selection` 类型 | **`Set<Item.ID>`（只读值）** | 与 `WDListRow.isSelected`（值）一致；单选场景传单元素集合。**与 M2-SIGNOFF 的 `Binding<Set<Item.ID>>` 不同**，见 §5-② |
| Q3 | 标题右侧动作 | **`WDListSectionAction(label:action:)` 参数**，≤1 个 | `header`/`footer`/`items` 词表里没有 action 名；a11y 顺序由组件保证 |
| Q4 | 卡片容器 | **组件内自绘**（`surface.card` + `radius.xl` + hairline + `elevation.e1`，水平内距 0） | `WDCard` 内距固定 16 会让行内距翻倍；不改 M2 已封的 `WDCard` |
| Q5 | 空组隐藏 | **`items.isEmpty` 一票隐藏** | 连标题/动作/页脚一起隐藏，不出现空标题+汇总 |

## 2. 拟冻结签名（草案）

```swift
// Sources/WisdomUI/Components/Primitives/WDListSection/WDListSection.swift
public struct WDListSectionAction {
    public let label: Text
    public let action: () -> Void
    public init(label: Text, action: @escaping () -> Void)
}

public struct WDListSectionRowContext: Sendable, Equatable {
    public let isSelected: Bool   // selection.contains(item.id)
    public let isLast: Bool       // 末行 ⇒ 行自己传 showsSeparator: false
    public init(isSelected: Bool, isLast: Bool)
}

public struct WDListSection<Item: Identifiable, Row: View, Footer: View>: View {
    public init(
        items: [Item],
        selection: Set<Item.ID> = [],
        header: Text,
        headerAction: WDListSectionAction? = nil,
        @ViewBuilder row: @escaping (Item, WDListSectionRowContext) -> Row,
        @ViewBuilder footer: () -> Footer)
}

extension WDListSection where Footer == EmptyView {
    public init(items: [Item], selection: Set<Item.ID> = [], header: Text,
                headerAction: WDListSectionAction? = nil,
                @ViewBuilder row: @escaping (Item, WDListSectionRowContext) -> Row)   // 页脚可选
}
```

## 3. 契约条目（拟回填 `contracts/WDListSection.yaml`）

| 键 | 值 |
| --- | --- |
| `params[].name` | `items`、`selection`、`header`、`headerAction`、`row`、`footer` |
| 受控值（C-15） | `selection`（`Set<Item.ID>`，默认 `[]`） |
| `slots`（⊆21 名） | `header`、`items`、`footer` |
| `default` | `selection = []`、`headerAction = nil`、`footer` = 无（`EmptyView` 重载） |
| 枚举 case | 无新增（`WDListSection` 本身不新增枚举） |
| 行上下文 | `WDListSectionRowContext(isSelected:isLast:)`（新增公开值类型，C 类 additive） |

## 4. 验证计划（冻结确认后执行）

1. `Scripts/dump-api.sh`：新增符号与冻结表逐字一致（预期 +3 类型 +2 init +2 属性 +2 init 参数）；
2. 单测：空组隐藏/末行标志/选中传递/密度/页脚/标题动作热区（已写 7 条）；
3. 8 态快照：标准 / 带动作 / 带页脚 / 空组；
4. demo 审计：把 `WDListSection` 挂进组件审计视口（M3 批内）；
5. `ci.sh pr` + nightly ×3。

## 5. 已确认的 5 个细节（2026-11-12 按建议冻结）

| # | 细节 | 草案取值 | 备选 |
| --- | --- | --- | --- |
| ① | `items` 在契约里算"值数组"还是"槽位" | 值数组（参数） | 若按槽位，需改成 `@ViewBuilder`（则失去空组/末行机器保证） |
| ② | `selection` 是值还是 `Binding` | **值 `Set<Item.ID>`** | `Binding<Set<Item.ID>>`（但组件只读，绑定无写入方 ⇒ 语义空转） |
| ③ | 行上下文形态 | 结构体 `WDListSectionRowContext` | 两个 Bool 参数 `(Item, Bool, Bool)`（参数更多、顺序易错） |
| ④ | 标题动作热区 | 带动作时**头行 44**（a11y） | 视觉 16 行高 + 负内距扩热区（hacky）；或接受 <44（不推荐） |
| ⑤ | 页脚字体/颜色施加方式 | 组件对 `footer` 子树施加 `wdFont(.footnote)` + `textSecondary` | 由调用方自己给（组件只给间距），则契约需注明"页脚样式调用方负责" |

> 2026-11-12 确认：§5 五个细节**全部维持草案取值**（`items` 值数组 / `selection` 值 / 行上下文结构体 /
> 动作时头行 44 / 页脚样式由组件施加）。代码里的 `DRAFT` 注释在合并时清除。

## 6. 确认与合并记录

| 项 | 值 |
| --- | --- |
| 确认人 | 项目负责人（按建议） |
| 日期 | 2026-11-12 |
| 五问 | 全部维持 §5 草案取值 |
| 合并前置 | M2 已签字（2026-11-12）✅；分支 `ci.sh pr` 绿 |
| 签名后续变更 | 只重写 init/context；布局与测试可复用 |
