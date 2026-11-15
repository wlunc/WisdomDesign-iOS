# B6 批前签名冻结 —— WDDatePicker 范围 / 清除（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B6 为第六批。
> **口径来源**：设计 23 §4（范围）/ §8（清除）/ §7（范围显示）。
> **前置**：B1–B5 已完成。

## 1. 公开签名增量（只增不改）

~~~swift
extension WDDatePicker {
  /// 单日期 + 可选清除按钮。
  public init(
    date: Binding<Date?>,
    label: Text,
    mode: WDDatePickerMode = .date,
    placeholder: Text? = nil,
    quickOptions: [WDDatePickerQuickOption] = [],
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool,
    clearAccessibilityLabel: Text?
  )

  /// 日期范围（仅日期模式；可选清除按钮）。
  public init(
    range: Binding<ClosedRange<Date>?>,
    label: Text,
    placeholder: Text? = nil,
    in bounds: ClosedRange<Date>? = nil,
    showsClearButton: Bool = false,
    clearAccessibilityLabel: Text? = nil
  )
}
~~~

**兼容性**：两个新增重载；既有 init 全部保留。API 1274 → **1276（+2）**。
**契约**：见 docs/B6-CONTRACT-CHANGE-REQUEST.md。

## 2. 行为口径

- 范围：第一次点设起点（单点范围）、第二次点完成；点早于起点或范围已完成时重新开始（内部 WDDateRangeSelection 单测覆盖）；
- 范围显示：同年「月日 – 月日」，跨年带年份；跟随系统区域格式，**不硬编码 YYYY-MM-DD**；
- 日历：端点实心品牌圆、区间内浅底；范围选完自动关闭；
- 清除：仅当 showsClearButton 且 clearAccessibilityLabel 非 nil 时渲染；清空 binding（库内零文案）；
- 快捷 Chip 仍只在单日期 .date 渲染；范围不显示。

## 3. 未纳入（仍登记）

- 范围 + 时间组合；
- 范围中间段的具体视觉（设计只规定端点；当前用 surface.tint）；
- 清除回调（设计 §8 的 onChange(nil)）——当前以 binding 为信号，无回调参数；
- 快捷项与范围联动、过期色（既有 status.danger 逻辑未加）。

## 4. 验收

- 单测：范围/清除入口 ≥44；两步选择纯逻辑（首点/完成/回退重开）；
- 快照：datepicker-* 8 张扩展重录（总 **360**）；
- 门禁：Scripts/ci.sh pr（179 tests / 1276 符号零 diff）+ 快照 45 tests；
- 文档：CHANGELOG、M2 出口报告回填。
