# B5 批前签名冻结 —— WDSwitch 紧凑档 / 描述位（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B5 为第五批。
> **口径来源**：设计 05 §3（标准 51×31 / 紧凑 40×24）与 §4（带描述）。
> **前置**：B1–B4 已完成。

## 1. 公开签名增量（只增不改）

~~~swift
public enum WDSwitchSize: String, CaseIterable, Sendable, Equatable {
  case standard
  case compact
}

extension WDSwitch {
  /// 新增重载；既有 init(isOn:label:) 保留。
  public init(
    isOn: Binding<Bool>,
    label: Text,
    description: Text?,
    size: WDSwitchSize
  )
}
~~~

**兼容性**：新增公开类型 + 新增重载 = 源码/二进制兼容；既有构造与标准档不变。
**API**：1270 → **1274（+4：1 type + 2 cases + 1 init）**。
**契约**：见 docs/B5-CONTRACT-CHANGE-REQUEST.md。

## 2. 设计值落点

| 项 | 标准 | 紧凑 | 来源 |
| --- | --- | --- | --- |
| 轨道 | 51×31 | 40×24 | 设计 05 §3 |
| 滑块 | 27 | 20 | 轨道高 − 4 |
| 行程 | 20 | 16 | 宽 − 滑块 − 4 |
| 内边距 | 2 | 2 | 设计 05 §3 |
| 描述 | footnote / text.secondary，标签下方一行 | 同 | 设计 05 §4 |

## 3. 未纳入（仍登记）

- 拖动滑块实时跟随/松手吸附（当前点击切换；拖动交互未实现）；
- 写入失败回弹 + Banner 说明（受控值语义，需调用方配合）；
- 聚焦光环；轨道 260ms / 滑块 300ms 的精确曲线未令牌化（当前用 base 240ms + spring.gentle）。

## 4. 验收

- 单测：两档几何自洽 / rawValue / 描述位增加高度 / 热区 ≥44；
- 快照：switch-* 8 张扩展重录（总 **360**）；
- 门禁：Scripts/ci.sh pr（177 tests / 1274 符号零 diff）+ 快照 45 tests；
- 文档：CHANGELOG、M2 出口报告回填。
