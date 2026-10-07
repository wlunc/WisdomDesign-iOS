# Examples —— 基线与非发布物

本目录**不发布**、**不进 products**、**不参与符号快照**（`Scripts/dump-api.sh` 只取
`WisdomUI` 模块）。它只做两件事：① 归档体积的**分母**；② 演示与无障碍审计的宿主（M1 起）。

| 目录 | 角色 | 时点 |
| --- | --- | --- |
| `BaselineShell/` | **归档体积基线**（E3-iOS-a 的分母：同构、**不引入 WisdomUI**） | I-M0-j（已交付，见其 README） |
| `WisdomUIDemo/` | 演示 + 无障碍审计宿主（`performAccessibilityAudit` 四类目）+ 运行时换 scheme 的载体 | **M1 交付物**（已建；UITest 的首次实跑见 DEV-PLAN §2.2 的【未验证】标注） |

**共同纪律**：

- **不检入 team / bundle id**：pbxproj 用占位值，本地用 xcconfig 或命令行覆盖（SPEC §1.6-①）。
- **门禁不覆盖本目录的编译**：`Scripts/ci.sh pr` 只编 `WisdomUI` 包；Examples 各自用
  `xcodebuild -project …` 单独编（见各自 README）。但**格式门禁的清单包含本目录**的
  `.swift`（除非显式排除）⇒ 这里的代码同样要过 `--strict`。
- **基线改动单独提交**并在 `CHANGELOG.md` 标注：分母变了，历史体积数字之间就不可比。
- **审计视口内避免 11pt（`caption2`）**：系统无障碍审计把它判为 Dynamic Type 不支持（连纯 SwiftUI
  `.font(.caption2)` 也一样），与库实现无关 —— 证据与待裁决见 `docs/DEV-PLAN.md` §8.1 的 **U-10**。
- **demo 只能依赖 `WisdomUI` 这一个 product**（F-10）：`WisdomUIPreviews` 没有进 `products`，
  外部 Xcode 工程看不到它（实测报 `Missing package product 'WisdomUIPreviews'`）。
  ⇒ 画廊留在包内（预览 + 快照用），demo 自建展示内容。
