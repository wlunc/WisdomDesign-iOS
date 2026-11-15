# B6 契约变更请求 —— WDDatePicker.yaml（2026-11-15）

> **背景**：项目负责人 2026-11-14 授权扩公开；B6 新增范围与清除重载。
> **为什么是"请求"**：契约真源在设计仓 ../wisdomdesign/contracts/，本仓只读。
> **待办**：设计/架构侧落库；发布前必须闭合。

## 增量

~~~yaml
params:
  - name: range
    ios: range
    type: ClosedRange<Date>?
    default: null          # 仅范围重载
  - name: showsClearButton
    ios: showsClearButton
    type: Bool
    default: false
  - name: clearAccessibilityLabel
    ios: clearAccessibilityLabel
    type: Text?
    default: null

enums: {}   # WDDatePickerMode 不变（date / time / dateAndTime）
~~~

## 兼容性

- 两个新增重载；既有 init 全部保留；
- API 1274 → **1276**（+2）。

## 登记偏差

- 范围中点视觉（surface.tint）、范围+时间组合、清除回调、过期色未实现。
