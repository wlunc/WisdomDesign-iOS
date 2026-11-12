# M3 公开 API 封板记录

> 用途：M3 出口判据①（`docs/DEV-PLAN.md` §2.4）的落盘件——公开 API 基线入库 + 封板动作与口径。
> 日期：**2026-11-12**｜签署：ios-lead（判定）｜复核：项目负责人
> 关联：`Scripts/dump-api.sh`、`api/WisdomUI.api.json`、`docs/SPEC.md` §2.9、`docs/DEV-PLAN.md` §9。

## 1. 基线事实（可复跑）

| 项 | 值 |
| --- | --- |
| 基线文件 | `api/WisdomUI.api.json`（已入库，随成因提交） |
| 符号数 | **661** |
| SHA-256 | `a339278405d0c9898d6bea2f5cbf3cf71d1cc0cf8880362b5253527cbc11b3ff` |
| 生成器 | `Scripts/canonicalize-api.swift`（字段白名单 + 合并扩展图 + 排序） |
| 工具链 | Xcode 26.6（17F113）／Swift 6.3.3／iphonesimulator 26.5 |
| 目标 | `arm64-apple-ios17.0-simulator` |
| 排除源 | `Sources/WisdomUI/APISurface/WDAPISurface.swift`（M0 冒烟段，已退役） |

**复跑命令（PR-2 同款）**：

```bash
cd iOS
Scripts/dump-api.sh
git diff --exit-code -- api/WisdomUI.api.json
```

2026-11-12 的 M3 复核结果：`dump-api: 与基线零 diff（symbols=661）`。

## 2. 封板口径（自本记录起生效）

1. **基线随成因提交**：任何改变公开面的提交，必须在**同一提交**内更新 `api/WisdomUI.api.json`（`docs/SPEC.md` §2.9 规则 2）；跨提交漂移 = 门禁红。
2. **默认值也在基线里**：本仓 canonicalizer 的 `decl` 含默认值（例 `size: WDButtonSize = .md`），因此默认值漂移会体现为基线 diff。跨端 ABI 语义不变；契约断言仍是唯一真源（P21 已回写，见 `docs/DEV-PLAN.md` §6）。
3. **兼容性判定**：追加带默认值的公开 `init` 参数 = 源码兼容但**破坏符号快照连续性**（需显式基线更新 + CHANGELOG）；改参数类型/标签、新增枚举 case = 源级 breaking；改名/删除 = major。走 `docs/SPEC.md` §2.9 与 U/契约流程。
4. **封板不等于冻结设计**：M4–M6 的新增组件按各批 I-2 冻结后继续追加符号；本记录只保证**当前基线可复现、零未解释差异**。

## 3. 本次纳入基线的组件面

- M2 的 11 件 primitives（`WDTextField`/`WDListRow`/`WDButton`/…）；
- M3 的 `WDListSection` + `WDListSectionAction` + `WDListSectionRowContext`；
- M1 的 Foundation 公开面（字体/主题/玻璃/对比度/无障碍/图标度量）与本记录同源。

## 4. 签字

| 项 | 值 |
| --- | --- |
| 判定人 | ios-lead |
| 日期 | 2026-11-12 |
| 结论 | **API 基线入库且零 diff，封板**（判据① ✅） |
| 复核 | 项目负责人（待确认） |
| 后续 | M4 起新增符号按批冻结；任何 breaking 走 CHANGELOG 的 Breaking 段 + 迁移片段 |
