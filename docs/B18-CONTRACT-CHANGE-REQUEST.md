# B18 契约变更请求 —— WDSlider 播报注入点（2026-11-20）

> **状态：待落库**（契约真源在 `../wisdomdesign/contracts/`，本仓对设计仓**只读**）。
> **背景**：项目负责人 2026-11-20「补上代码欠账」；B18 补了 `WDSlider` 的松手播报（设计 08 §10 / `SPEC.md` §2.10-#08）。
> **冻结稿**：`docs/B18-SIGNATURE-FREEZE.md`。
> **口径**：只增不改；不改既有参数名/默认值；槽位集合（U3 21 名）不变。

---

## 1. `WDSlider.yaml`

```yaml
params:
  # 既有：value / range / label / bounds / step / onEditingChanged /
  #       showsValueLabel / valueText / rangeText / lowerAccessibilityLabel / upperAccessibilityLabel
  - name: announcementText         # B18 增量；单值松手播报文案（L-B：措辞由调用方给）
    ios: announcementText
    type: "((Double) -> Text)?"
    default: null
  - name: rangeAnnouncementText    # B18 增量；范围松手播报文案（L-B）
    ios: rangeAnnouncementText
    type: "((ClosedRange<Double>) -> Text)?"
    default: null
default:
  announcementText: null
  rangeAnnouncementText: null
```

**为什么另起两个键而不是复用 `valueText`**：契约的 `params[].type` 是单值键，`valueText` 已是
`((Double) -> Text)?`；播报文案与可见值文案在**独立开关**下（可见值可以关、播报仍要），
同键会被读成「显示值 = 播报」的强耦合 ⇒ 拆成独立键（与 B17 的 `rangeText` 同一处理方式）。

**播报时机**：只在**松手**（`onEditingChanged(false)`）后播一次，polite；拖动过程中不播
（设计 08 §10「数值变化不做 aria-live 实时播报，只在松手后播报一次」）。

---

## 2. 槽位 / 枚举

无变化：`slots` 仍为 `[label]`；`enums` 无新增。

---

## 3. 与 B17 合并落库

`WDSlider.yaml` 的 B17（`range` / `rangeText` / 两个手柄标签）与 B18（两个播报键）应在**同一次**
落库中提交，避免 yaml 的 `params` 顺序与 `docs/DEV-PLAN.md` §5.3 反复对不上。
