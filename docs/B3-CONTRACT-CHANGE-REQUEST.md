# B3 契约变更请求 —— WDCard.yaml / WDDivider.yaml（2026-11-15）

> **背景**：项目负责人 2026-11-14 授权扩公开；B3 新增 WDCardStyle.sunken、WDDividerStyle 与 init(style:)。
> **为什么是"请求"**：契约真源在设计仓 ../wisdomdesign/contracts/，本仓只读。
> **待办**：设计/架构侧落库；发布前必须闭合。

## WDCard.yaml 增量

~~~yaml
enums:
  WDCardStyle: [elevated, outlined, glass, sunken]   # B3 追加 sunken
~~~

## WDDivider.yaml 增量

~~~yaml
params:
  - name: style
    ios: style
    type: WDDividerStyle
    default: .full

enums:
  WDDividerStyle: [full, inset]
~~~

## 兼容性

- WDCardStyle 新增 case = 源级 breaking（穷尽 switch）；minor + Breaking 段；
- WDDivider 新增类型 + 重载 = 兼容；既有 init() 保留；
- API 1261 → **1266**（+5：1 case + 1 type + 2 cases + 1 init）。
