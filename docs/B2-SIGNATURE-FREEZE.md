# B2 批前签名冻结 —— WDAvatar 五档 / 在线 / 停用（2026-11-15）

> **授权**：项目负责人 2026-11-14「允许扩公开」；B2 为授权后的第二批。
> **口径来源**：设计 12 §3–§5（五档 / 在线点 / 停用）+ SPEC §2.10-#12。
> **前置**：B1（WDBadge 六态）已完成；M2/M5 已判定通过。

## 1. 公开签名增量（只增不改）

~~~swift
public enum WDAvatarSize: String, CaseIterable, Sendable, Equatable {
  case xs, sm, md, lg, xl
}

extension WDAvatar {
  /// 新增重载；既有 init(value:)（md 32）保留。
  public init(
    value: WDAvatarValue,
    size: WDAvatarSize,
    isOnline: Bool = false,
    isDisabled: Bool = false
  )
}
~~~

**兼容性**：新增公开类型 + 新增重载 = 源码/二进制兼容；既有 init(value:) 与 WDAvatarValue 不变。
**API**：1254 → **1261（+7：1 type + 5 cases + 1 init）**。
**契约**：见 docs/B2-CONTRACT-CHANGE-REQUEST.md（设计仓 contracts/WDAvatar.yaml 增量待落库）。

## 2. 设计值落点

| 项 | 值 | 来源 |
| --- | --- | --- |
| 直径 | 20 / 28 / 32 / 40 / 56（令牌 size.avatar.*） | 设计 12 §3 |
| 首字号 | 9 / 11 / 12 / 14 / 18（固定，不随动态字体） | 设计 12 §3 |
| 在线点 | 10×10、2pt 宿主底色描边、status.success | 设计 12 §4 |
| 停用 | 整体 50% + 去饱和 | 设计 12 §5 |
| 图标档 | xs/sm → 16、md → 20、lg/xl → 24 | 设计未给，按直径近似（登记） |

## 3. 未纳入本批（仍登记）

- **成员四色底色**：设计 token 未提供 4 组 avatar palette（画廊里的 a1–a4 是硬编码渐变）；需设计给色值后另批；
- **照片形态**：WDAvatarValue 无 Image 载荷，需新增值形态与裁切参数；
- **在线状态并入读屏**：设计 12 §10 要求「妈妈，在线」，但库内零文案（L-B），需调用方提供措辞或新增读屏槽位。

## 4. 验收

- 单测：五档直径 ±1 / rawValue / 在线不改变尺寸 / 停用可构造；AX5 不放大仍成立；
- 快照：avatar-* 8 张扩展并重录；受影响 avatarstack-* 8 张、assigneepicker-* 8 张同步重录（字号/图标档按设计修正）；
- 门禁：Scripts/ci.sh pr（172 tests / 1261 符号零 diff）+ 快照 45 tests / 360 张；
- 文档：CHANGELOG / M2 出口报告回填。
