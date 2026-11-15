# B4 契约变更请求 —— WDIconButton.yaml（2026-11-15）

> **状态：已落库**（2026-11-15，设计仓 contracts/WDIconButton.yaml）。

> **背景**：项目负责人 2026-11-14 授权扩公开；B4 给 WDIconButtonVariant 增加 filled/tonal/glass/outline。
> **为什么是"请求"**：契约真源在设计仓 ../wisdomdesign/contracts/，本仓只读。
> **落库记录**：2026-11-15 已落库设计仓 contracts/WDIconButton.yaml。

## 增量

~~~yaml
enums:
  WDIconButtonVariant: [plain, filled, tonal, glass, outline]
~~~

## 兼容性

- 新增枚举 case = 源级 breaking（穷尽 switch）；minor + Breaking 段；
- 无新 init / 参数；API 1266 → **1270**（+4）。

## 登记偏差

- filled 背景由 gradient.mid 改 text.brand 实底（原白字 2.51:1 不达图形 3:1）；
- 圆角方形形态、聚焦光环、长按提示仍未实现。
