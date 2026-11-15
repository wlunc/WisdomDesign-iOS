# B3 批前签名冻结 —— WDCard.sunken + WDDivider 内缩（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B3 为第三批。
> **口径来源**：设计 17 §4（sunken）+ 设计 14 §3/§4（内缩 62）。
> **前置**：B1（Badge 六态）、B2（Avatar 五档）已完成。

## 1. 公开签名增量

~~~swift
// WDCardStyle 新增 case（源级 breaking：穷尽 switch 需补 case）
public enum WDCardStyle: String, CaseIterable, Sendable, Equatable {
  case elevated, outlined, glass
  case sunken          // B3
}

// WDDivider 新增档位与重载；既有 init() 保留
public enum WDDividerStyle: String, CaseIterable, Sendable, Equatable {
  case full, inset
}
extension WDDivider {
  public init(style: WDDividerStyle)
}
~~~

**兼容性**：WDDivider 为新增类型 + 新增重载（兼容）；WDCard 为**新增枚举 case**（F-20 源级 breaking，
minor + Breaking 段 + 迁移片段）。API 1261 → **1266（+5）**。
**契约**：见 docs/B3-CONTRACT-CHANGE-REQUEST.md。

## 2. 设计值落点

| 项 | 值 | 来源 |
| --- | --- | --- |
| WDCard.sunken 背景 | surface.card-sunken | 设计 17 §4 |
| WDCard.sunken 描边/阴影 | 无 / 无 | 设计 17 §4 |
| WDDivider 内缩起点 | 62（16 + 34 + 12） | 设计 14 §3 |
| 线宽 / 颜色 | 1pt / border.hairline（两档一致） | 设计 14 |

## 3. 未纳入本批（仍登记）

- WDCard 的 media 变体（顶部图片 + 文字区）需新的内容 API；"可点卡"（按下 96%）需 action 参数；
- WDDivider 无其他形态。

## 4. 验收

- 单测：四档卡（含 sunken）内边距仍 16；分割线两档 1pt/满宽；rawValue 稳定；
- 快照：card-* 8 张、divider-* 8 张扩展重录（总 **360**）；
- 门禁：Scripts/ci.sh pr（173 tests / 1266 符号零 diff）+ 快照 45 tests；
- 文档：CHANGELOG（含 Breaking 段）、M2 出口报告回填。
