# B10–B16 契约变更请求 —— 六个组件 yaml 增量（2026-11-15）

> **状态：待落库**（契约真源在 `../wisdomdesign/contracts/`，本仓对设计仓**只读**；请架构师/设计侧按本文件落库）。
> **背景**：项目负责人 2026-11-15 下发「B. 纯代码可继续」清单；B1 段（需扩公开）落地为 **B10–B14**，B2 段（不改公开 API 的行为补齐）落地为 **B15–B16**（其中 B15 的 `WDTabBar` 不改公开面）。
> **冻结稿**：`docs/B10-B16-SIGNATURE-FREEZE.md`（§1 汇总签名 / §3 设计值出处）。
> **口径**：只增不改；C-15 参数名不变；槽位集合（U3 21 名）不变。

---

## 1. `WDDatePicker.yaml`（B10）

```yaml
params:
  - name: onClear                     # B10 增量；清除回调（设计 23 §8 的 onChange(nil)）
    ios: onClear
    type: "(@MainActor @Sendable () -> Void)?"
    default: null
default:
  onClear: null
# 范围重载（既有 range 构造）追加 mode：默认 .date；.time 在范围下按 .date 处理
```
> ⚠️ 既有 `mode` 参数已存在（默认 `.date`）；**范围重载也接受 `mode`**，属同一参数在另一重载可表达 —— 不新增参数名。

## 2. `WDAvatarStack.yaml`（B11）

```yaml
params:
  - name: onOverflowTap               # B11 增量；整叠点击（设计 13 §8）
    ios: onOverflowTap
    type: "(@MainActor @Sendable () -> Void)?"
    default: null
default:
  onOverflowTap: null
```

## 3. `WDPullRefresh.yaml`（B12）

```yaml
params:
  - name: onRefreshError              # B12 增量；失败通道（抛错或超时）
    ios: onRefreshError
    type: "(@MainActor @Sendable (any Error) -> Void)?"
    default: null
  - name: timeout                     # B12 增量；刷新超时（设计 32 §8 的 10s）
    ios: timeout
    type: "Duration"
    default: .seconds(10)
  - name: texts                       # B12 增量；三态文案 + 完成/失败播报的 L-B 注入点
    ios: texts
    type: "WDPullRefreshTexts?"
    default: null
default:
  onRefreshError: null
  timeout: .seconds(10)
  texts: null
enums:
  WDPullRefreshPhase: [idle, pulling, armed, refreshing, completed, failed]
```
> 注：`WDPullRefreshTexts` 是**值类型**（非枚举）：`{pull, release, refreshing, completed, failed: Text?}`。
> `onRefresh` 在**新重载**里为 `throws`；既有 `onRefresh: () async -> Void` 重载不变（Android 侧无对应概念，F50 已登记"视觉载体自由"）。

## 4. `WDSlider.yaml`（B13）

```yaml
params:
  - name: showsValueLabel             # B13 增量；数值标签（设计 08 §6）
    ios: showsValueLabel
    type: "Bool"
    default: false
  - name: valueText                   # B13 增量；数值标签文案（L-B；nil = 系统数字格式）
    ios: valueText
    type: "((Double) -> Text)?"
    default: null
default:
  showsValueLabel: false
  valueText: null
```

## 5. `WDSearchField.yaml`（B14）

```yaml
params:
  - name: resultCount                 # B14 增量；结果数（供播报）
    ios: resultCount
    type: "Int?"
    default: null
  - name: announcer                   # B14 增量；结果数变化时的播报注入点（L-B：措辞由调用方给）
    ios: announcer
    type: "(@MainActor @Sendable (Int) -> Void)?"
    default: null
default:
  resultCount: null
  announcer: null
```

## 6. `WDFAB.yaml`（B15）

```yaml
params:
  - name: showsScrimWhenExpanded      # B15 增量；展开遮罩（设计 36 §8）
    ios: showsScrimWhenExpanded
    type: "Bool"
    default: false
  - name: avoidsTabBar                # B15 增量；与 TabBar 共存时的底部避让（设计 36 §6 的 92）
    ios: avoidsTabBar
    type: "Bool"
    default: false
default:
  showsScrimWhenExpanded: false
  avoidsTabBar: false
```

## 7. `WDNavigationBar.yaml`（B15）

```yaml
params:
  - name: followsScroll               # B15 增量；滚动联动（设计 33 §4/§5/§8）
    ios: followsScroll
    type: "Bool"
    default: false
default:
  followsScroll: false
```

## 8. `WDSwitch.yaml`（B16）

```yaml
params:
  - name: onWriteFailure              # B16 增量；写入失败回弹（设计 05 §8）
    ios: onWriteFailure
    type: "(@MainActor @Sendable (Bool) -> Void)?"
    default: null
default:
  onWriteFailure: null
```

---

## 9. 兼容性与编号

- **全部新增参数带默认值** ⇒ 源码/二进制兼容；符号快照按 SPEC §2.9 规则 1 需显式更新基线（同提交 + CHANGELOG）。
- **新增类型**：`WDPullRefreshPhase`（枚举，`String` rawValue + `CaseIterable` + `Sendable`，F-20 口径）、`WDPullRefreshTexts`（值类型）。
- **槽位集合**不变（U3 21 名）；**C-15 参数名**不变（无受控值改名）。
- **跨端一致性**：本批新增参数全部是 **F 系列**（各端自由的行为补齐）或 iOS 独有的 L-B 注入点，**不触及 U 系列** ⇒ 不需要 android-lead + tech-lead 确认；请架构师按上表落六个 yaml。
- **不触及** `WDTabBar.yaml`（B15 的 TabBar 收缩走环境键，无新参数）。
