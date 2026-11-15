# B1 契约变更请求 —— WDBadge.yaml（2026-11-14）

> **状态：已落库**（2026-11-15，设计仓 contracts/WDBadge.yaml）。

> **背景**：项目负责人 2026-11-14 授权扩公开；B1 新增 WDBadgeVariant 与 init(label:variant:)。
> **为什么是"请求"**：契约真源在设计仓 ../wisdomdesign/contracts/，本仓对设计仓只读（跨仓写入零容忍）。
> **落库记录**：2026-11-15 已落库设计仓 contracts/WDBadge.yaml。

## 增量（在既有文件末尾追加/合并）

~~~yaml
# B1 增量（2026-11-14）：六种状态变体；新增重载，只增不改
params:
  - name: variant
    ios: variant
    type: WDBadgeVariant
    default: .shared    # 仅 init(label:variant:) 必填；既有重载语义默认 .shared

enums:
  WDBadgeVariant: [shared, schedule, pending, success, warning, danger]
~~~

## 兼容性

- 新增公开类型 + 新增 init 重载：源码/二进制兼容；
- 既有 init(label:) / init(value:)、WDBadgeValue 三形态、计数/圆点尺寸均不变；
- API 符号基线 1246 → **1254**（+8：1 type + 6 cases + 1 init）。

## 设计登记偏差（对比度优先，详见 docs/B1-SIGNATURE-FREEZE.md §2）

- schedule：gradient.mid + 白字 → status.info 实底 + 浅色白 / 深色 text.on-light-primary；
- success/warning/danger：文字改 text.on-soft（原 status 色 4.32 / 4.58 / 3.94，danger 与 success 不达 4.5）。
