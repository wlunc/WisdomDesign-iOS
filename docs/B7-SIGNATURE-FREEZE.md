# B7 批前签名冻结 —— Card 可点 / Checkbox 紧凑 / Radio 紧凑 / FAB 焦点（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B7 为扩公开后的实现批。
> **口径来源**：设计 17 §5/§8（可点卡）、设计 06 §3（Checkbox 紧凑 22）、设计 07 §3（Radio 紧凑 22）、设计 36 §10（FAB 展开焦点）。
> **前置**：B1–B6 已完成；契约 B1–B6 已落库。

## 1. 公开签名增量（只增不改）

~~~swift
public enum WDCheckboxSize: String, CaseIterable, Sendable, Equatable {
  case standard, compact
}
extension WDCheckbox {
  public init(isChecked: Binding<Bool>, label: Text, size: WDCheckboxSize, isIndeterminate: Bool = false)
}

public enum WDRadioSize: String, CaseIterable, Sendable, Equatable {
  case standard, compact
}
extension WDRadio {
  public init(selection: Binding<String>, label: Text, size: WDRadioSize, options: [WDRadioOption])
}

extension WDCard {
  public init(style: WDCardStyle = .elevated, action: @escaping () -> Void, @ViewBuilder content: () -> Content)
}
~~~

**兼容性**：新增公开类型/重载；既有 init 全部保留。API 1276 → **1285（+9：2 类型 + 4 cases + 3 init）**。
**契约**：已同步 contracts/WDCheckbox.yaml / WDRadio.yaml / WDCard.yaml（2026-11-15）。

## 2. 设计值落点

| 项 | 值 | 来源 |
| --- | --- | --- |
| Checkbox 标准 / 紧凑 | 方框 26/22、圆角 9/7、标签 subheadline/footnote | 设计 06 §3 |
| Radio 标准 / 紧凑 | 外圆 26/22、内点 12/10、标签 subheadline/footnote | 设计 07 §3 |
| Card 可点 | 按下亮度 96%（4% 黑蒙层）、instant、禁用 40% | 设计 17 §5/§8 |
| FAB 展开焦点 | 焦点移到第一个子操作 | 设计 36 §10 |

## 3. 未纳入 / 残留

- WDCard media 变体仍未实现；
- 可点卡内嵌套可点子元素由调用方禁止（Button 语义会合并子元素）；
- Checkbox 紧凑档沿用标准勾/横杠尺寸；光晕、无标签表头形态仍未做；
- Radio 紧凑档已补，但 radiogroup/radio 角色与“第 n 项，共 m 项”仍受 SwiftUI trait 限制；
- FAB 仅补焦点移入；滚动缩小、展开遮罩、TabBar 安全区避让仍未做；焦点行为无真机 VoiceOver 验证；
- 新交互未加 demo UI 测试（Card 可点、Checkbox/Radio 紧凑仅单测 + 快照）。

## 4. 验收

- 单测：187 tests（新增 Checkbox/Radio/Card 断言；FAB 无单测）；
- 快照：45 tests / 360 张（checkbox/card/radio 各 8 张重录）；
- 门禁：Scripts/ci.sh pr（187 tests / 1285 符号零 diff / Foundation ≥80%）；
- 契约：contracts-check.rb 通过（38 唯一枚举 / 39 定义）。
