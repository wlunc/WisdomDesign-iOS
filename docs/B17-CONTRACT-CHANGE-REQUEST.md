# B17 契约变更请求 —— WDSlider 范围 + WDDatePicker 过期提示（2026-11-20）

> **状态：待落库**（契约真源在 `../wisdomdesign/contracts/`，本仓对设计仓**只读**；请架构师/设计侧按本文件落库）。
> **背景**：项目负责人 2026-11-20「继续完成」；B17 把 `docs/M5-EXIT-REPORT.md` §4-① 的「范围双手柄」与 B8 的「读屏未播报已过期」两笔遗留收口。
> **冻结稿**：`docs/B17-SIGNATURE-FREEZE.md`（§2 汇总签名 / §1 范围）。
> **口径**：只增不改；**不改既有参数名/默认值**；槽位集合（U3 21 名）**不变**。

---

## 1. `WDSlider.yaml`（B17-4）

```yaml
params:
  # 既有：value / label / bounds / step / onEditingChanged / showsValueLabel / valueText
  - name: range                       # B17 增量；范围形态的受控值（与 value 二选一，不同 init）
    ios: range
    type: "Binding<ClosedRange<Double>>"
  - name: rangeText                   # B17 增量；区间文案（L-B：含分隔符，必须由调用方给）
    ios: rangeText
    type: "((ClosedRange<Double>) -> Text)?"
    default: null
  - name: lowerAccessibilityLabel     # B17 增量；下端手柄读屏名（nil ⇒ 复用 label）
    ios: lowerAccessibilityLabel
    type: "Text?"
    default: null
  - name: upperAccessibilityLabel     # B17 增量；上端手柄读屏名（nil ⇒ 复用 label）
    ios: upperAccessibilityLabel
    type: "Text?"
    default: null
default:
  range: null
  rangeText: null
  lowerAccessibilityLabel: null
  upperAccessibilityLabel: null
```

**C-15 增补（待架构师确认）**：`docs/DEV-PLAN.md` §5.3 第 **08** 行现为 `WDSlider | value | value`；
范围形态引入第二个受控值形态 ⇒ 建议把该行改为 `value / range`（iOS）↔ `value / range`（canonical），
语义 = **同一组件两种受控值形态，二选一**，不是两个必填参数。

**为什么另起 `rangeText` 而不是复用 `valueText`**：契约的 `params[].type` 是单值键；
`valueText` 已是 `((Double) -> Text)?`，范围需要 `((ClosedRange<Double>) -> Text)?`。
同键两型会让契约逐行比对无法机械执行 ⇒ 用独立键（与 `value` / `range` 同构）。

---

## 2. `WDDatePicker.yaml`（B17-3）

```yaml
params:
  # 既有：date / label / mode / placeholder / quickOptions / bounds /
  #       showsClearButton / clearAccessibilityLabel / onClear / range
  - name: expiredAccessibilityHint    # B17 增量；已过期时的读屏提示（L-B：文案由调用方给）
    ios: expiredAccessibilityHint
    type: "Text?"
    default: null
default:
  expiredAccessibilityHint: null
```

- **只对单日期构造生效**（范围不判过期，与 B8 的 `status.danger` 色口径一致）；
- 组件只在「确实过期」时挂 `.accessibilityHint`，**不做「已过期」字符串**（L-B）；
- 跨午夜刷新走系统 `NSCalendarDayChanged` + 回到前台，**没有新增任何参数**。

---

## 3. 槽位 / 枚举

无变化：`slots` 仍为 `[label]`（WDSlider）/ `[label]`（WDDatePicker）；`enums` 无新增 case。
