# B2 契约变更请求 —— WDAvatar.yaml（2026-11-15）

> **状态：已落库**（2026-11-15，设计仓 contracts/WDAvatar.yaml）。

> **背景**：项目负责人 2026-11-14 授权扩公开；B2 新增 WDAvatarSize 与 init(value:size:isOnline:isDisabled:)。
> **为什么是"请求"**：契约真源在设计仓 ../wisdomdesign/contracts/，本仓对设计仓只读。
> **落库记录**：2026-11-15 已落库设计仓 contracts/WDAvatar.yaml。

## 增量

~~~yaml
# B2 增量（2026-11-15）：五档 + 在线 + 停用；新增重载，只增不改
params:
  - name: size
    ios: size
    type: WDAvatarSize
    default: null        # 仅 init(value:size:isOnline:isDisabled:) 必填
  - name: isOnline
    ios: isOnline
    type: Bool
    default: false
  - name: isDisabled
    ios: isDisabled
    type: Bool
    default: false

enums:
  WDAvatarSize: [xs, sm, md, lg, xl]
~~~

## 兼容性

- 既有 init(value:) / WDAvatarValue 两形态不变；新增重载源码/二进制兼容；
- API 1254 → **1261**（+7）。

## 登记偏差

- 图标档：设计未给头像内图标尺寸，按直径近似（xs/sm 16、md 20、lg/xl 24）；
- 成员四色底色、照片、在线状态朗读仍未实现（设计 token / L-B 限制）。
