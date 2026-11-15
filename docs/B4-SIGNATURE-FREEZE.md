# B4 批前签名冻结 —— WDIconButton 五变体（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B4 为第四批。
> **口径来源**：设计 02 §4（filled / tonal / glass / outline / plain）+ DF-04 图形 3:1。
> **前置**：B1/B2/B3 已完成。

## 1. 公开签名增量

~~~swift
public enum WDIconButtonVariant: String, CaseIterable, Sendable, Equatable {
  case plain      // 既有
  case filled
  case tonal
  case glass
  case outline
}
~~~

**兼容性**：新增 4 个 case = 源级 breaking（穷尽 switch 需补分支）；minor + Breaking 段 + 迁移片段。
无新 init/参数。API 1266 → **1270（+4）**。
**契约**：见 docs/B4-CONTRACT-CHANGE-REQUEST.md。

## 2. 配色与 DF-04（对比度优先）

| 变体 | 背景 | 图标 | 偏差 / 理由 |
| --- | --- | --- | --- |
| plain | 透明 | text.brand | 无（既有） |
| filled | **text.brand 实底** | 浅色白 / 深色 text.on-light-primary | 设计 gradient.mid + 白在浅端仅 2.51:1（图形门槛 3:1）⇒ 改实底；浅 4.86、深 8+ |
| tonal | surface.tint | text.on-soft | 无 |
| glass | surface.glass-strong | text.primary + hairline | 无 |
| outline | 透明 | text.primary + hairline-strong | 无 |

单测对 5 变体 × 浅/深断言 ≥3:1；press 缩放 0.97（instant）；禁用 40%。

## 3. 未纳入（仍登记）

- 圆角方形形态（设计 02 §3 的 radius.sm 备选）需形状参数；
- 聚焦光环、长按工具提示；
- 图标按钮无加载态（设计 02 §5）；既有 isLoading 参数保留但不在新变体语义内。

## 4. 验收

- 单测：五变体 rawValue / 5×2 对比度 / 原档位与热区断言保持；
- 快照：iconbutton-* 8 张扩展重录（总 **360**）；
- 门禁：Scripts/ci.sh pr（175 tests / 1270 符号零 diff）+ 快照 45 tests；
- 文档：CHANGELOG（Added + Breaking）、M2 出口报告回填。
