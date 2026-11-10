# M2 裁决清单 —— 14 条签名差异 + 6 条审计例外

> 用途：M2 出口前需要一次**批量裁决**。本清单把 `docs/DEV-PLAN.md` §2.3 的 ①–⑭ 与
> demo 审计的 6 条例外（2 类）逐条列出，每条给「设计/规格要求 → 当前实现 → 建议 → 改了要付什么代价」。
> 状态：**已裁决（2026-11-10，项目负责人批量确认「全部按建议」）**；裁决汇总见 §5。
> 日期：2026-11-10｜裁决人：项目负责人（ios-lead/架构师/设计按条目复核）。
> 关联：`docs/M2-EXIT-REPORT.md` §5、`docs/M2-SIGNATURE-FREEZE.md`、`docs/SPEC.md` §2.10 / §2.4-2 / §2.6.2。

## 0. 三种裁决动作与代价（先统一口径）

| 动作 | 含义 | 代价 |
| --- | --- | --- |
| **A 接受现状** | 实现不变；在 DEV-PLAN/SPEC 回写一句"本批以此为准" | 零代码；需一次文档回写（`docs/DEV-PLAN.md` §6 的 P 项流程） |
| **B 改签名/补能力** | 扩参数、加 case、加公开构造器 | **additive**：源码兼容、符号快照变更（需单独提交 + CHANGELOG）；**新增枚举 case = 源级 breaking**（F-20：minor + Breaking 段） |
| **C 延后** | 保留登记，指定到后续批次；本批按现状收货 | 零成本；必须在条目里写"延后到 Mn + 触发条件"，不得变成无主项 |

> 纪律：**任何 B 都要先改契约真源（`contracts/README.md`，M0-5 落库后）再同步两端副本**；
> 本批的契约仍以 `M2-SIGNATURE-FREEZE.md` 代替（契约确认见 §4）。

## 1. 签名差异（①–⑭）

| # | 设计/规格要求 | 当前实现 | 建议 | B 的代价 | 裁决人 |
| --- | --- | --- | --- | --- | --- |
| ① | 错误出现时 **assertive 播报一次**（§2.10-#03） | 只挂 `accessibilityHint`（F22 的另一条路径）；播报层已实现，但组件无注入点 | **A**：定为"**调用方播报**"（demo/上层持 `WDSystemAnnouncer`），组件只负责读屏 hint；把验收从组件移到 demo 层 | B = 给 `WDTextField` 加环境键或 announcer 形参（改冻结签名，走 U 项） | ios-lead + 架构师 |
| ② | 显隐切换**保持光标位置**（SPEC §2.3 裁决 2） | iOS 17 无 `TextField(text:selection:)` ⇒ 降级为"焦点回填、光标落末尾" | **A**：接受降级；登记 M5 复查（若最低版本升到 iOS 18，改单实例 + selection） | B = 只支持 iOS 18+（改部署目标，属发布决策） | ios-lead |
| ③ | 渲染器表：`WDTextField` 记作"普通类 / ImageRenderer"（P17） | 实测 `ImageRenderer` 对 `TextField` **输出全透明** ⇒ 归 `UIHostingController`；含 `ProgressView` 的 `WDButton`/`WDIconButton` 同 | **A**：回写 SPEC §1.6 与 §13.1（把"普通类"改成"UIKit 接管类"）；未来组件按同一判据归类 | 无代码代价（纯文档回写） | ios-lead + 架构师 |
| ④ | `WDA11yFocusID` 有公开只读属性（§2.6.2） | 按冻结形态落地，**无公开构造器** ⇒ 模块外不能自造 ID | **C → M4**：弹层焦点归还前补 `public init(rawValue:)`（additive），同时给 SPEC 补初始化器 | B = 新增公开 init（additive，符号快照 +1） | ios-lead + 架构师 |
| ⑤ | `WDBadge` 六种状态变体 / 计数 / 圆点 / 0 隐藏 / 99+（设计 11 §4–§5） | 冻结签名只有 `label` ⇒ 只做 `shared` 中性胶囊；固定 11pt（例外见 A2） | **C → M4/M5**：等 `WDBadgeValue` 的实际调用方出现再扩 `variant`/`count` 参数（带默认值，additive） | B = 新增带默认值参数（源码兼容、快照变更）或枚举 case（源级 breaking） | ios-lead + 设计 |
| ⑥ | `WDDivider` 全宽 / **内缩 62** 两档（设计 14） | 只有全宽；行内缩进由 `WDListRow` 自带分隔线实现 | **C → M3**：若 `WDListSection` 需要独立内缩分割线，补 `inset` 参数（带默认值，additive） | B = 新增带默认值参数 | ios-lead + 设计 |
| ⑦ | `WDAvatar` 五档直径 / 按成员 ID 固定配色 / 在线点 / 停用 / 照片（设计 12） | 只做 md 32 的文字/图标；中性 `surface.tint` 底 | **C → M5**（`WDAvatarStack` 之前）：扩 `size`/`memberID`/`status` 参数；`WDAvatarValue` 需同时扩成员（additive） | B = 改值类型成员 + 新增带默认值参数（源码兼容、快照变更） | ios-lead + 设计 |
| ⑧ | `WDSwitch` 紧凑档 40×24 / 带描述位 / 按下 1.06 放大（设计 05） | 只做标准 51×31；无描述位；无按下放大 | **A/C**：紧凑档与描述位 **C → M5**；按下放大可 **C**（视觉细节，非验收点） | B = 加 `size`/`description` 参数（additive） | ios-lead + 设计 |
| ⑨ | `WDCheckbox` 半选三态 / 紧凑档 / 无标签表头（设计 06） | 只有两态标准档；无标签形态可用 `label: Text("")` 变通 | **C → 出现三态场景时**（M5 的列表多选）；半选需改受控值为三态枚举（**源级 breaking**，须走 U 项） | B（半选）= 改受控值类型，breaking；B（紧凑/无标签）= additive | ios-lead + 架构师 |
| ⑩ | `WDCard` sunken / media / 可点卡（按下 96%）（设计 17） | 三档实底（elevated/outlined/glass）；无可点卡 | **C → M3/M4**：`sunken` 先看 `WDListSection` 是否需要；可点卡等有真实场景再补 `action`（additive） | B = 新增枚举 case（**源级 breaking**）或 action 参数（additive） | ios-lead + 设计 |
| ⑪ | `WDIconButton` 五个变体（设计 02） | 只有 `.plain`（冻结表单只钉了 plain） | **C → M5**（导航栏/工具栏前）：补 `filled/tonal/glass/outline`（枚举 case，源级 breaking） | B = 新增枚举 case（minor + Breaking 段） | ios-lead + 设计 |
| ⑫ | `WDButton` 字号 13/15/16、图标 14/16/20、聚焦光环、按下亮度 96%（设计 01） | 字号用 13/15/17（lg 用 body 近似）、图标 16/16/20；只有 0.97 缩放，无光环/亮度 | **A**（字号/图标）：令牌已覆盖，差异可接受；**C**（聚焦光环）：M5 键盘导航验收前补；亮度用缩放替代 | B（光环）= 新增视觉层，不改签名；B（字号 16）= 需新字阶令牌（改令牌 = 两仓变更集） | ios-lead + 设计 |
| ⑬ | 行整行合并读、徽标内容并入朗读；`selectionIndicator` 语义（设计 18 §10） | 行已合并读；**徽标被 `accessibilityHidden`（未并入）**；`selectionIndicator` 按"圆点 + 品牌内点"实现 | **A + 回写**：`selectionIndicator` 在 SPEC §2.4 补一句"单选指示"；徽标朗读 **C → M3**（`WDListSection` 出现真实徽标行时，用行的 `accessibilityValue` 承接或给 `WDBadge` 加 `isDecorative` 开关） | B = `WDBadge` 加参数（additive） | ios-lead + 设计 |
| ⑭ | 行选中 = 左侧 3pt 品牌条 + **brand 8% 透明底**（设计 18 §5） | 改为**不透明 `surface.tint`**：半透明底会被系统对比度审计按未合成色计算，实测 `text.primary` 不达标 | **A**：接受实底（审计可证明优先），快照已记录视觉差异；请设计确认观感 | 无（视觉值，不是签名） | 设计 + ios-lead |

## 2. demo 审计例外（A1–A6 → 2 类）

审计已覆盖 11 件组件视口（两页签）；测试对例外**逐条点名**并打印理由，其余仍严格失败。

| # | 例外 | 实例 | 理由 | 建议 | 裁决人 |
| --- | --- | --- | --- | --- | --- |
| A1 | 固定字号：头像首字 12pt | `妈` ×2 | 设计 12：头像直径与首字号**锁死**、不随动态字体放大 | **接受**（设计例外）；测试已点名 | 设计 |
| A2 | 固定字号：徽标 11pt | `进行中` ×1 | 设计 11 §3：徽标字号 11 · 600 固定 | **接受**（设计例外）；测试已点名 | 设计 |
| A3 | 单行截断：行标题/副标题 | `整理储物间`、`妈妈的待办`、`今天 18:00 前` ×3 | 设计 18 §7 明确"单行、超出截断"；审计按 `lineLimit(1)` 判"可能截断" | **接受**；若希望放大档换行，属设计变更（改 `lineLimit(2)`） | 设计 |

> 口径：A1–A3 是**设计明确的例外**，不是实现缺陷；测试里点名的 label 一旦变化（改文案/改组件结构），
> 例外清单必须同步，否则审计会如实变红。

## 3. 裁决后的执行动作（按动作批量处理）

- **A 类（建议 ①②③⑫⑬⑭ + A1–A3）**：一次文档回写（`docs/DEV-PLAN.md` §6 登记 P 项 → 改 SPEC/DEV-PLAN），
  14 条里把对应行标"已裁决：接受"；不需要改代码。
- **C 类（④⑤⑥⑦⑧⑨⑩⑪⑬）**：在 `docs/DEV-PLAN.md` §2.3 的对应条目里写"**延后到 Mn**"，
  并把触发条件写清楚（例如 ⑤ = M4 首个带徽标的调用方出现）。
- **B 类**：先走契约真源流程（`contracts/README.md` → 两端副本），再改实现 + 符号快照 + CHANGELOG；
  涉及受控值**类型**变化的（⑨ 半选、⑩ 枚举 case）按 F-20 记为源级 breaking。

## 4. 与出口判据的关系

- 本清单**不改变** `M2-EXIT-REPORT.md` §1 的判据结论；它只决定"14 条差异怎么收口"。
- 出口仍差：**nightly 第 2/3 日**、**契约确认（⑮）**、**本清单裁决**、**ios-lead 签字**。

## 5. 裁决记录（2026-11-10）

**结论：按建议全部执行**（B 类 0 条；A 类 6 条 + C 类 8 条 + 审计例外 3 类接受）。

| 动作 | 条目 | 已执行的落地 |
| --- | --- | --- |
| **A 接受** | ① ② ③ ⑫ ⑭ + ⑬ 的 `selectionIndicator` 部分 + A1–A3 | SPEC 回写 **P17**（渲染器表）、**P18**（selectionIndicator）、**P19**（选中底）、**P20**（播报归属）；DEV-PLAN §2.3 记为已裁决 |
| **C 延后** | ④ → M4；⑤ → M4/M5；⑥ → M3；⑦ → M5；⑧ → M5；⑨ → M5；⑩ → M3/M4；⑪ → M5；⑬ 徽标朗读 → M3 | DEV-PLAN §2.3 每条写「延后到 Mn + 触发条件」（由对应批次的前置判据把关） |
| **B 改签名** | **本批 0 条** | 将来的 B 一律先改契约真源再改实现（F-20 的 breaking 口径） |

> 审计例外 A1–A3 的接受 = `Examples/WisdomUIDemo/WisdomUIDemoUITests` 里的 `AUDIT-KNOWN` 点名清单；
> label 变更时必须同步该清单（否则审计如实变红）。
