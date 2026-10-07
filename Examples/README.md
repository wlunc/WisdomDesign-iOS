# Examples —— 基线与非发布物

本目录**不发布**、**不进 products**、**不参与符号快照**（`Scripts/dump-api.sh` 只取
`WisdomUI` 模块）。它只做两件事：① 归档体积的**分母**；② 演示与无障碍审计的宿主（M1 起）。

| 目录 | 角色 | 时点 |
| --- | --- | --- |
| `BaselineShell/` | **归档体积基线**（E3-iOS-a 的分母：同构、**不引入 WisdomUI**） | I-M0-j（已交付，见其 README） |
| `WisdomUIDemo/` | 演示 + 无障碍审计宿主（`performAccessibilityAudit` 四类目）+ 运行时换 scheme 的载体 | **M1 交付物**（当前不存在） |

**共同纪律**：

- **不检入 team / bundle id**：pbxproj 用占位值，本地用 xcconfig 或命令行覆盖（SPEC §1.6-①）。
- **门禁不覆盖本目录的编译**：`Scripts/ci.sh pr` 只编 `WisdomUI` 包；Examples 各自用
  `xcodebuild -project …` 单独编（见各自 README）。但**格式门禁的清单包含本目录**的
  `.swift`（除非显式排除）⇒ 这里的代码同样要过 `--strict`。
- **基线改动单独提交**并在 `CHANGELOG.md` 标注：分母变了，历史体积数字之间就不可比。
