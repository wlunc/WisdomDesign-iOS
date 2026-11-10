# M2 出口报告 —— 首批 11 件（代码 11/11；**出口未判定**）

> 里程碑：**M2**（口径来源 = `docs/DEV-PLAN.md` §2.3）｜报告日期：**2026-11-10**｜判定人：ios-lead（**待签字**）
> 判定环境：Xcode 26.6（Build 17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）
> **结论：11 件代码与逐件六类断言已落地；出口判据 6 条中 5 条达成、1 条未闭合**
> （契约 `contracts/*.yaml` 未落库）；且夜间门禁只跑了**第 1/3 日** ⇒ **本批不能判定通过**。

## 1. 出口判据逐条判定（DEV-PLAN §2.3 的 6 条）

| # | 判据 | 证据 | 结论 |
| --- | --- | --- | --- |
| ① | 迁移后 `api/WisdomUI.api.json` 无未解释差异 | 符号 453 → **641**，逐批随成因提交并写 CHANGELOG（+18 / +16 / +22 / +13 / +43 / +53）；末次 `dump-api` **零 diff** | ✅ |
| ② | 11 件的契约用例名与实现一致（`params`/`slots`/`default` 与 §5.3） | 11 件签名与 `docs/M2-SIGNATURE-FREEZE.md` 逐字一致（编译级自证）；`contracts/*.yaml` **仍未落库**，按 I-2 原文以冻结表单代替；**架构师确认仍待** | ⚠️ 部分 |
| ③ | 六态截图入库且 `--tokens-trace` 绿 | **104 张基线**（M1 的 16 + M2 的 88 = 11 件 × 8 态）；PR-0 的 tokens trace 绿 | ✅ |
| ④ | 无障碍断言（语义树/热区/对比度最不利取色）通过 | demo 增加**组件审计视口**（11 件代表性实例，两个页签分别跑 4 类目）；审计绿，**6 条带理由的窄例外**逐条点名（固定字号头像/徽标 ×3、单行截断 ×3）；装饰件不进树、必填标签、触觉网关有单测 | ✅（含 2 类登记例外，见 §4-②） |
| ⑤ | 该批性能数字进报告（不拦） | §3 的 11 件渲染耗时（只报不拦） | ✅ |
| ⑥ | 冒烟退役 | `WD_API_SMOKE` 只剩弹层（§2.5）与动效（§3.5）；`WDTextField`/`WDIcon`/`WDButton`/`WDListRow`/a11y 全族已同提交删除 | ✅ |

**门禁强度**：`PR+nightly₃`。PR 已绿；nightly **第 1/3 日绿**（2026-11-10），连续 3 日尚未满足。

## 2. 交付物（按阶段；完整提交链见 `git log`）

| 阶段 | 内容 |
| --- | --- |
| M2 首批 | `WDTextField`（46pt 字段盒 + 四槽位 + 状态）、`WDIcon` + `WDIconName`（44 条） |
| P0 | API 基线回填 + 冻结表单补签 + 状态回填 |
| P1 | 无障碍层（`WDSemantics` / `WDAnnouncing` / 节流 / 焦点 ID）+ 两件补齐六类断言 + 16 张基线 |
| P2 | `WDBadge`/`WDDivider` → `WDAvatar` → 布局密度 + 触觉网关 + `WDSwitch` → `WDCheckbox`/`WDCard`/`WDIconButton` → `WDButton`/`WDListRow`；共 **41 条组件测试**、**11 个 Previews**、**88 张 8 态基线** |

**代码规模**：`Sources/WisdomUI` 的 11 件组件全部落在 `Components/Primitives/**`；`Internal/WDHaptics.swift`（可注入 sink）与 `Foundation/Theme/WDLayoutDensity.swift` 同步落地。

## 3. 性能数字（模拟器相对量；**只报不拦**）

口径：快照同款渲染路径，每件 15 次（前 3 次预热丢弃，n=12），iPhone Air / iOS 26.5 模拟器。
**两种渲染路径不可横向比较**：`ImageRenderer` 组是纯 SwiftUI 渲染；`UIHostingController` 组每轮含窗口创建 + 图层合成（数字天然高一个量级）。

| 组件 | 路径 | avg ms | min ms |
| --- | --- | --- | --- |
| `WDIcon` | ImageRenderer | 5.18 | 2.95 |
| `WDBadge` | ImageRenderer | 7.83 | 4.18 |
| `WDDivider` | ImageRenderer | 12.75 | 3.38 |
| `WDAvatar` | ImageRenderer | 16.08 | 3.95 |
| `WDCheckbox` | ImageRenderer | 18.78 | 5.34 |
| `WDSwitch` | ImageRenderer | 21.79 | 5.90 |
| `WDCard` | ImageRenderer | 13.58 | 7.77 |
| `WDListRow` | ImageRenderer | 12.04 | 7.54 |
| `WDTextField` | UIHostingController | 74.16 | 68.54 |
| `WDIconButton` | UIHostingController | 62.50 | 57.55 |
| `WDButton` | UIHostingController | 71.38 | 66.38 |

> 原始日志：`.build/logs/m2-perf.log`。**不写入任何预算阈值**（M3 起才考虑门槛）。

## 4. 未验证 / 未闭合台账（**不得写成已通过**）

| # | 项 | 现状 | 依赖谁 / 何时 |
| --- | --- | --- | --- |
| ① | **nightly 连续 3 日绿** | 第 **1/3** 日绿（2026-11-10：设备编译 6.7s + 快照 15 tests + demo 审计 50.8s） | 2026-11-11、11-12 各再跑一次；owner = ios-dev |
| ② | **组件无障碍审计的窄例外** | 审计已覆盖 11 件（两页签）；放行 6 条并逐条点名：固定字号（头像首字 12pt ×2、徽标 11pt）与行的单行截断（×3）。**语音播报的音频效果仍不可机检**（靠代码级实现 + 人工 review） | ios-lead 裁决例外是否接受 / M2 出口前 |
| ③ | **错误态 assertive 播报** | `WDTextField` 只挂 `accessibilityHint`；播报层（`WDSystemAnnouncer`）已落地，但组件无注入点 ⇒ 需裁决"调用方播报 vs 组件注入" | ios-lead + 架构师 / M2 出口前 |
| ④ | **契约 `contracts/*.yaml`** | 未落库；I-2 以冻结表单代替；架构师确认仍待（**确认请求与可回复文本 = `docs/CONTRACTS-CONFIRMATION-REQUEST.md`**） | 架构师 / M2 出口前 |
| ⑤ | **真机采样（U-05）** | 设备无线连接，XCUITest runner 无法 bootstrap；`⌘R` 不受影响。观感结论必须人给（USB 直连后重跑） | 用户 + ios-dev / M1 遗留，M2 出口随批复核 |
| ⑥ | **U-10（caption2 审计）** | 系统审计把 11pt 文本判为 Dynamic Type unsupported；组件若在审计视口用 caption2 需窄例外或改档 | ios-lead + tech-lead / 挂 demo 审计前 |
| ⑦ | **M1 出口报告签字** | `M1-EXIT-REPORT.md` 判定人仍"待签字" | ios-lead / 与 M2 出口一并 |

## 5. 冻结签名的差异登记（`docs/DEV-PLAN.md` §2.3 ①–⑬）—— **已裁决（2026-11-10）**

> **裁决结果**：按建议全部执行 —— **A 接受 6 条 + 审计例外 3 类**（已回写 SPEC 的 P17–P20）、
> **C 延后 8 条**（逐条写延后批次与触发条件）、**B 改签名 0 条**。明细见
> [`docs/M2-DEVIATIONS.md`](M2-DEVIATIONS.md) §5。

累计 **14 条**，全部是"冻结签名表达不了设计稿"的取舍（不是实现缺陷），逐条带 owner 与"**M2 出口前**"时点。
**逐条裁决清单（含建议与代价）= [`docs/M2-DEVIATIONS.md`](M2-DEVIATIONS.md)**：

- ①–④：`WDTextField` 播报归属 / 显隐切换 selection / 渲染器表 P17 / `WDA11yFocusID` 无公开构造器；
- ⑤–⑦：`WDBadge` 变体、`WDDivider` 内缩档、`WDAvatar` 五档/配色/在线态；
- ⑧–⑪：`WDSwitch` 紧凑档/描述位、`WDCheckbox` 半选/紧凑档、`WDCard` sunken/media/可点、
  `WDIconButton` 其余四变体；
- ⑫–⑭：`WDButton` 字号/图标档近似与聚焦光环、`WDListRow` 徽标朗读合并/`selectionIndicator` 语义、
  行的选中底改不透明 `surface.tint`（审计可证明优先）。

## 6. 放行建议

- **不判定 M2 通过**。剩余动作（按顺序）：
  1. 2026-11-11 / 11-12 各跑一次 `Scripts/ci.sh nightly`，凑满连续 3 日绿（当前第 1/3 日，已含组件审计）；
  2. 与架构师对齐 `contracts/*.yaml`（或书面确认"冻结表单 = 本批契约"），补判据 ②；
  3. 全部绿后由 ios-lead 签字，再开 M3（`WDListSection` + API 封板 + `Foundation/**` ≥80% + 体积门槛）。
- 本报告与 `M1-EXIT-REPORT.md` 一样：**每条结论都对应可重跑的命令或已入库产物**；未跑通的一律标【未验证】。
