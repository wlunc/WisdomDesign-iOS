# M3 开工前自检 —— `WDListSection`

> 用途：M3（封板批）只有 1 件组件 `WDListSection` + 公开 API 冻结 + 覆盖率/体积门槛。
> 本文件是**开工前的只读准备**（不实现、不改代码）：把入口判据、规格锚点、签名待决点、
> 测试计划和风险一次列清；M2 出口签字后照此开写。
> 日期：2026-11-10｜状态：**准备稿**（签名**未冻结**，I-2 未过）｜关联：`docs/SPEC.md` §2.10-#19、
> `docs/DEV-PLAN.md` §2.4 / §13.1 / §21.6-#19、设计仓 `specs/01-basic.md` #19。

## 1. 入口判据（I-1…I-5）

| # | 判据 | 现状 | 缺什么 |
| --- | --- | --- | --- |
| I-1 | 上一里程碑出口已判定 | **未** | M2 出口：nightly 第 2/3 日 + 签字（**契约确认已于 2026-11-10 闭合**，见 `docs/CONTRACTS-CONFIRMATION-REQUEST.md` §5；yaml 回填 = M3 出口前） |
| I-2 | 批前签名冻结 | **未** | 本文件 §3 的待决点必须先裁决，产出冻结表 |
| I-3 | 令牌/契约已冻结 | ✅（令牌 32 槽位/schemes 已冻结；契约以 M2 冻结表单代替） | **已确认（2026-11-10，架构师）** = `docs/CONTRACTS-CONFIRMATION-REQUEST.md` §5；本件 `WDListSection` 的契约仍按 I-2 另行冻结 |
| I-4 | 门禁可跑且绿 | ✅（PR 全绿；nightly 第 1 日绿） | 第 2/3 日 |
| I-5 | 未闭合前置有默认执行项 | ✅ | 本文件 §3/§6 |

## 2. 规格锚点（只引用，不复述）

- **槽位/受控值**：`selection`（受控值）；槽位 `header`、`footer`、`items`（21 名词表内）。
- **关键默认**：末行无分隔（矩阵"关键默认"列）；分组空则**整组隐藏**。
- **设计要点**（设计 19）：标题 `overline` 12 · 500 · 字距 +0.6、`text.secondary`；标题右侧动作可选
  （≤1，`text.brand`）；内容容器 = **一个卡片**，内部是 `WDListRow` 序列；页脚 `footnote`、`text.secondary`；
  间距：标题↔内容 8、内容↔页脚 4、组间 24、页面左右 16；标题左侧与卡片文本对齐额外 +2。
- **无障碍**：标题 = `header` 语义；朗读顺序 = 标题 → 标题动作 → 组内各行 → 页脚；页脚作为补充说明。
- **密度**：消费 `@Environment(\.wdDensity)`（行高由 `WDListRow` 自己按 `max(密度下限, 槽位派生)` 算）。
- **动画**：无（分组不做进出动画）。

## 3. 签名待决点（**I-2 冻结会必须逐条拍板**）

> 候选签名只是**提案**，不是结论；4 个问题不解决就开写，会在 M3 出口暴露"空分组无法隐藏/末行分隔线
> 无法保证"这类结构性问题。

### Q1 `items` 用 ViewBuilder 还是数据数组？

| 方案 | 形态 | 优点 | 代价 |
| --- | --- | --- | --- |
| A | `@ViewBuilder items: () -> Items` | 与现有组件风格一致、灵活 | **无法识别空集合**（"空分组整组隐藏"做不到）；**无法知道末行**（"末行无分隔"做不到） |
| B | `items: [Item]` + `@ViewBuilder row: (Item) -> some View`（或内部直接产 `WDListRow`） | 空集合/末行/选择态都可机器化 | `items` 在 U3 词表里是"值数组"，与本组件的槽位分类要确认（F48） |
| **建议** | **B**（数据驱动），`Item: Identifiable`；空数组 ⇒ 整组隐藏；最后一行的 `showsSeparator = false` 自动处理 | — | 需要架构师确认 `items` 分类（值数组） |

### Q2 `selection` 的受控值类型？

SPEC 只写了名字，没给类型。候选：
- `Binding<Set<Item.ID>>`（多选）；
- `Binding<Item.ID?>`（单选）；
- 或不要受控值、由 `WDListRow.isSelected` 由调用方逐行给（但 C-15 已把 `selection` 记为本组件受控值）。

**建议**：`selection: Binding<Set<Item.ID>>`（多选；单选场景传一个元素的集合或用 `WDRadio`）。
若架构师要求单选，则改 `Binding<Item.ID?>` —— 这是**源级 breaking 的取舍**，必须在冻结会定死。

### Q3 标题右侧动作放哪？

`header`/`footer`/`items` 三个槽位里**没有 action 名**。候选：
- 新增参数 `headerAction: WDListSectionAction?`（`label: Text` + `action: () -> Void`，≤1）；
- 或把动作塞进 `header` 的 ViewBuilder（a11y 顺序无法保证，且标题本身不可点）。

**建议**：新增 `headerAction` 参数（带默认 `nil`，additive）；a11y 顺序由组件保证。

### Q4 卡片容器复用谁？

设计要求"内容容器 = 一个卡片"。两个选择：
- 复用 `WDCard(style: .elevated)`：但 `WDCard` 内距固定 16，会把 `WDListRow` 自带的左右 16 变成 32；
- **组件内自绘容器**（surface.card + radius.xl + hairline + elevation.e1，**水平内距 0**，让行自己的 16 生效）。

**建议**：自绘容器 + 复用令牌与 `WDElevation.e1`；**不要**为了复用去改 `WDCard` 的冻结签名（M2 已封）。

### Q5 空组隐藏与页脚/动作的组合

- 空组：整组隐藏（连标题/页脚/动作一起）；
- 有页脚但 0 行：也隐藏（否则出现"空标题+汇总"）。

**建议**：以 `items.isEmpty` 为唯一判据。

## 4. 提案签名（草案，冻结前不得进代码）

```swift
public struct WDListSectionAction: Sendable {
  public let label: Text
  public init(label: Text)
}

public struct WDListSection<Item: Identifiable, Row: View, Footer: View>: View {
  public init(
    selection: Binding<Set<Item.ID>> = .constant([]),
    items: [Item],
    header: Text,
    headerAction: WDListSectionAction? = nil,
    onHeaderAction: (() -> Void)? = nil,
    @ViewBuilder row: @escaping (Item) -> Row,
    @ViewBuilder footer: () -> Footer
  )
}
```

> 待决：`selection` 默认值（`.constant([])` 是否合理）、`onHeaderAction` 与 `headerAction` 是否合并成一个
> 带闭包的值类型、`footer` 是否要可选（`EmptyView` 默认）。冻结会逐条定。

## 5. 测试计划（六类断言，开工即按此写）

| # | 类别 | 断言 |
| --- | --- | --- |
| 1 | API 形状 | 参数名/默认值与冻结表逐字一致；`items` 分类与 U3 冻结一致 |
| 2 | 边界 | 空 `items` ⇒ 整组隐藏（高度 0 / 不在层级）；只有 1 行时末行无分隔；组内行数 N ⇒ 分隔线 N−1 条 |
| 3 | 密度 | `.wdDensity(.compact)` 下组内行高按 `max(44, 槽位派生)`；comfortable 下按 60 起 |
| 4 | 无障碍 | 标题带 header trait（代码级 + demo 审计）；朗读顺序 标题→动作→行→页脚（demo 层人工/审计） |
| 5 | 快照 | 8 态 × {标准, 带动作, 带页脚, 空组}（空组应只有空白） |
| 6 | 行盒 | 标题 overline 行盒、页脚 footnote 行盒；中英混排不裁切 |

## 6. 风险与对策

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| Q1/Q2 未定就开写 | 空组隐藏/末行分隔做不对，返工 | 冻结会先过 §3，五问逐条签字 |
| `items` 分类与 U3 冲突 | 两端契约不一致 | 冻结会带上架构师，按 F48 记录 |
| 卡片内距翻倍 | 视觉错位（32 vs 16） | 自绘容器（水平内距 0），不复用带 16 内距的 `WDCard` |
| 末行分隔与 `WDListRow.showsSeparator` 的职责重叠 | 双分隔/漏分隔 | Section 显式传 `showsSeparator: index != count-1`；单测钉住 |
| 空组与页脚组合 | 空白标题+汇总 | 以 `items.isEmpty` 一票隐藏 |

## 7. M3 其余三件（同一批）

1. **公开 API 封板**：`api/WisdomUI.api.json` 已零 diff（641 符号）；补"基线入库 + 签字 + CHANGELOG"即视为冻结；
2. **覆盖率转门槛**：`Foundation/**` **97.69%** 已过 80%（2026-11-10 实测）；把"只打印"改成"门槛"即可；
3. **体积门槛定值**：先按 `docs/U09-SIZE-BASELINE.md` 的缺口补"同构消费方 + 三次归档"，再按 P50+10% 定值，
   写进 README/CHANGELOG（U-09）；
4. **契约回填（11 件 yaml）**：M2 判据②的**生效条件**（架构师 2026-11-10 确认）。
   位置 = `../wisdomdesign/contracts/<Component>.yaml`（不是 iOS 仓）；内容/判定口径 = 
   `docs/CONTRACTS-CONFIRMATION-REQUEST.md` §5.3；**回填 = 誊录**，不得借机改签名/默认值/槽位/枚举。
   前置确认（§5.5）：① android-lead 复核 `WDCheckbox` 的 `checked`（android SPEC §2.10 已记载改名，需书面确认一次）；
   ② 默认值检出表述的 P21 回写（ios-lead）。

## 8. 执行顺序（M2 出口签字后）

1. 冻结会（§3 五问）→ 冻结表落盘 → 删/改本文件的状态行；
2. 实现 `WDListSection` + 六类断言 → `ci.sh pr` 绿；
3. 8 态基线入库 → nightly 第 1 日；
4. 补体积门槛与 API 封板 → nightly 第 2/3 日；
5. M3 出口报告 + 签字。
