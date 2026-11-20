# B19 签名冻结 —— 零 API 变化（2026-11-20）

> 批次性质：**验证层跑通 + 回归修复**，不新增、不改动任何 **public** 符号。
> 关联：`docs/B19-EXIT-REPORT.md`、`docs/DEBT-LEDGER.md`。

## 1. 公开面判定

| 项 | 结论 | 证据 |
| --- | --- | --- |
| API 符号数 | **1380（不变）** | `Scripts/dump-api.sh` 重跑输出 `与基线零 diff（symbols=1380）`；重跑前后 `api/WisdomUI.api.json` 的 sha256 一致（`bff55154…`） |
| 新增 public 符号 | **0** | 本批新增的 `WDA11yRuntime` / `wdAccessibilityFocused(_:)` / `wdAccessibilityFocused(_:equals:)` 全在 `Internal/A11y/`，不带 `public`（R6） |
| 改动既有 public 签名 | **0** | 未触碰任何 `public init` / 公开属性 |
| 契约 yaml | 无需变更 | 无参数/槽位/默认值变化 |

## 2. 内部件变更（不进 API 基线）

| 文件 | 变更 |
| --- | --- |
| `Sources/WisdomUI/Internal/A11y/WDFocusRing.swift` | 增 `WDA11yRuntime.isAssistiveTechRunning`；`WDAccessibilityFocusHost` 按闸门挂绑定；增两个 internal `View` 扩展 |
| `Sources/WisdomUI/Components/Composites/WDFAB/WDFAB.swift` | 两处 `.accessibilityFocused` 改走闸门入口 |
| `Sources/WisdomUI/Components/Composites/WDNavigationBar/WDNavigationBar.swift` | 内联标题透明度/可见性按模式区分（回归修复） |
| `Sources/WisdomUI/Components/Composites/WDTabBar/WDTabBar.swift` | 去掉容器级 `.clipped()`（回归修复） |
| `Tests/WisdomUITests/Components/WDSearchFieldTests.swift` | 启用此前 `.disabled` 的尺寸断言 |

## 3. 兼容性判定（`docs/SPEC.md` §2.9）

零公开变化 ⇒ **源码兼容 / 二进制兼容 / 符号快照连续**；无 CHANGELOG 的 Breaking 段。

## 4. 判据核对

| 判据 | 结果 |
| --- | --- |
| `Scripts/check-structure.sh --strict` | `files=188 rules=22 errors=0 warnings=0 suppressed=256` |
| `Scripts/check-format.sh` | `204 个文件全部通过 --strict` |
| `Scripts/dump-api.sh` | `与基线零 diff（symbols=1380）`（重跑后文件 sha256 不变） |
