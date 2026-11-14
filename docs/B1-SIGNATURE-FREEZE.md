# B1 批前签名冻结 —— WDBadge 六变体（2026-11-14）

> **授权**：项目负责人 2026-11-14 明确「允许扩公开」；本批是授权后的第一批（B1）。
> **口径来源**：设计 11 §4（六种状态变体）+ SPEC §2.10-#11 + DF-04 对比度硬门槛。
> **前置**：M2/M5 已判定通过；WDBadge 既有 init(label:) / init(value:) 与计数/圆点形态不变。

## 1. 公开签名增量（只增不改）

~~~swift
/// 六种状态变体（设计 11 §4）。
public enum WDBadgeVariant: String, CaseIterable, Sendable, Equatable {
  case shared
  case schedule
  case pending
  case success
  case warning
  case danger
}

extension WDBadge {
  /// 新增重载；既有 init(label:) / init(value:) 保留。
  public init(label: Text, variant: WDBadgeVariant)
}
~~~

**兼容性**：新增公开类型 + 新增重载 = 源码/二进制兼容；**未向既有枚举新增 case**；API 符号基线 **1246 → 1254（+8）**。
**契约**：见 docs/B1-CONTRACT-CHANGE-REQUEST.md（设计仓 contracts/WDBadge.yaml 增量待设计侧落库）。

## 2. 配色与 DF-04（**对比度优先**的登记偏差）

设计 11 §4 原配色在浅色 soft 底上不满足 4.5:1，按 DF-04 硬门槛调整；每行给实测比例（浅/深）：

| 变体 | 背景 | 文字 | 偏差 / 理由 |
| --- | --- | --- | --- |
| shared | surface.tint | text.on-soft | 无（沿用） |
| schedule | **status.info 实底** | 浅色白 / 深色 text.on-light-primary | 原 gradient.mid 上白字仅 **2.51 / 4.23:1** ⇒ 改实底；浅 4.86、深 8+ |
| pending | surface.glass-strong | text.brand | 无；合成后 ≥4.5 |
| success | status-soft.success | **text.on-soft** | 原 status.success 仅 **4.32:1** ⇒ 改深色中性；9.8 |
| warning | status-soft.warning | **text.on-soft** | 原 status.warning 4.58 达标，但统一取 10.17 保持一致 |
| danger | status-soft.danger | **text.on-soft** | 原 status.danger 仅 **3.94:1** ⇒ 改深色中性；9.33 |

> 深色侧原 status 文字均 ≥7.4，但为两端一致统一 text.on-soft（9.3+）。单测 WDBadgeTests.variantContrast 对 6 变体 × 浅/深逐条断言 ≥4.5。

## 3. 未纳入本批（仍登记）

- 徽标的**图标形状**差异（设计 11 §10 的"颜色不是唯一信号"）需新增 icon 槽位/参数，留待后续批；
- WDListRowTrailing.badge 仍只接受无变体值形态（避免联动改 WDListRow 签名）。

## 4. 验收

- 单测：六变体 rawValue / 高度 24±1 / 对比度 6×2；
- 快照：新增 badge-variants-* **8 张**（浅/深 × 默认/AX3 × LTR/RTL），总 **360**；
- 门禁：Scripts/ci.sh pr（169 tests / 1254 符号零 diff / Foundation ≥80%）+ 快照 45 tests；
- 文档：CHANGELOG.md、M2/M5 出口报告回填。
