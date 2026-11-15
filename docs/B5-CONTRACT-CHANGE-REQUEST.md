# B5 契约变更请求 —— WDSwitch.yaml（2026-11-15）

> **状态：已落库**（2026-11-15，设计仓 contracts/WDSwitch.yaml）。

> **背景**：项目负责人 2026-11-14 授权扩公开；B5 新增 WDSwitchSize 与描述位重载。
> **为什么是"请求"**：契约真源在设计仓 ../wisdomdesign/contracts/，本仓只读。
> **落库记录**：2026-11-15 已落库设计仓 contracts/WDSwitch.yaml。

## 增量

~~~yaml
params:
  - name: description
    ios: description
    type: Text?
    default: null
  - name: size
    ios: size
    type: WDSwitchSize
    default: .standard   # 既有重载等价

enums:
  WDSwitchSize: [standard, compact]
~~~

## 兼容性

- 新增公开类型 + 新增重载：源码/二进制兼容；既有 init(isOn:label:) 保留；
- API 1270 → **1274**（+4）。

## 登记偏差

- 拖动滑块、写入失败回弹、聚焦光环、精确 260/300ms 曲线仍未实现（见签名冻结 §3）。
