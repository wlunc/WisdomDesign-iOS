# B8 批前签名冻结 —— IconButton 方形 / Checkbox 无标签 / DatePicker 过期色（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B8 为扩公开后的实现批。
> **口径来源**：设计 02 §3（radius.full / radius.sm）、设计 06 §4（无标签全选）、设计 23 §5（已过期 danger）。
> **前置**：B7 已完成；契约 B7 已落库。

## 1. 公开签名增量（只增不改）

~~~swift
public enum WDIconButtonShape: String, CaseIterable, Sendable, Equatable {
  case circle, roundedSquare
}
extension WDIconButton {
  public init(
    icon: WDIconName, accessibilityLabel: Text,
    variant: WDIconButtonVariant = .plain, size: WDButtonSize = .md,
    shape: WDIconButtonShape, isLoading: Bool = false,
    action: @escaping () -> Void
  )
}

extension WDCheckbox {
  public init(
    isChecked: Binding<Bool>, accessibilityLabel: Text,
    size: WDCheckboxSize = .standard, isIndeterminate: Bool = false
  )
}
~~~

**兼容性**：新增公开类型/重载；既有 init 全部保留。API 1285 → **1290（+5：1 类型 + 2 cases + 2 init）**。
**契约**：已同步 contracts/WDIconButton.yaml / WDCheckbox.yaml（2026-11-15）。

## 2. 行为与设计值

| 项 | 值 | 来源 |
| --- | --- | --- |
| IconButton 形态 | circle（默认）/ roundedSquare（radius.sm 10，continuous） | 设计 02 §3 |
| Checkbox 无标签 | 只渲染方框，读屏用 accessibilityLabel；热区 44×44 | 设计 06 §4 |
| DatePicker 过期 | 单日期早于今天 → 文字 status.danger；范围/.time 不套用 | 设计 23 §5 |

## 3. 未纳入 / 残留

- IconButton lg + roundedSquare 同用 radius.sm，设计只给 sm/md，需视觉复核；
- Checkbox 光晕、无标签行的朗读实测未做；
- DatePicker 过期色只在渲染时判定，跨午夜不会自动翻转（仓规禁组件自建计时器）；读屏未附加“已过期”状态；
- 新增交互未加 demo UI 测试。

## 4. 验收

- 单测：194 tests（新增 IconButton shape、Checkbox no-label、DatePicker expired 纯逻辑）；
- 快照：45 tests / 360 张（iconbutton/checkbox/datepicker 各 8 张重录）；
- 门禁：Scripts/ci.sh pr（194 tests / 1290 符号零 diff / Foundation ≥80%）；
- 契约：contracts-check.rb 通过（39 唯一枚举 / 40 定义）。
