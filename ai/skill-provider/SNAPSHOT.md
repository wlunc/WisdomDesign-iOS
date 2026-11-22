# iOS Provider 快照与 dist 一致性（只读核对）

> 维护者：iOS Provider（ai/skill-provider）；本文件是 F6 的显式 stale 登记与复现说明。
> 复核来源：`wisdomdesign/AIOptimize/review/02-ios.md` IOS-R2-F6。

## 1. 当前快照状态：stale（已显式声明）

| 项 | 值 |
| --- | --- |
| Provider 快照 commit | `c3c32f3c81f66444abd10614acfc0095f80aebd6`（dirty=true，5 个文件） |
| 快照捕获时 API 哈希 | `123136bdf1f5299d740e1e220c7973eb82914c5df53eb093053ac51469158c34` |
| 当前 iOS HEAD | `64539fe78d9a036a6e34cbfa01c72e4430c0e2b0`（clean） |
| 当前 API 哈希 | `1d3be9d703f9ea54710905a6d90db2e9ef7c05b55ab8d8f529c9b2843b725348` |
| 生成器 pin | `EXPECTED_API_SHA = 123136bd…`（见 `api-cards/generate_api_cards.py`） |
| 声明位置 | `verification.json#/snapshot`（status=stale）与 `api-cards/SOURCES.json#/baseline`（stale=true） |

原因：iOS 仓在 provider 快照（2026-11-21 18:xx）之后前进了 `64539fe`（A-11/A-13/A-14 组件收口），
`api/WisdomUI.api.json` 已变化；生成器的防漂移 pin 因此拒绝当前 HEAD 快照。这是**有意拒绝**，不是生成失败。

## 2. 可复现性证据（对声明快照重放）

```bash
git -C iOS show c3c32f3:api/WisdomUI.api.json > /tmp/wisdom-api-baseline.json
python3 iOS/ai/skill-provider/api-cards/generate_api_cards.py \
  --api /tmp/wisdom-api-baseline.json \
  --out iOS/ai/skill-provider/api-cards
# exit 0; wrote 33 API cards (api sha256=123136bd…)
```

- 重放结果与仓库 33 张卡、index.json 逐字节一致（2026-11-22 复核：排除仓库内生成器脚本与 SOURCES.json 后 `diff -r` rc=0）。
- 用当前 HEAD API 重放：`EXPECTED_API_SHA` 不匹配，exit 1，并提示本文件。
- 33 张卡都不再包含非法的 `iosLabel` 属性；iOS 标签映射保留在允许字段 `limitations`（"iOS label mapping: …"），
  精确参数标签仍在 `signature` 中。

## 3. 刷新（re-baseline）步骤

1. 在 iOS 仓确认目标 commit 与干净/脏状态，记录 `git rev-parse HEAD` 与 `git status --short`。
2. 更新 `generate_api_cards.py` 的 `EXPECTED_API_SHA` 与 `EXPECTED_ICON_SHA`。
3. 更新 `provider.json#/source`（commit/dirty/dirtyFiles/contentHash）与 `SOURCES.json#/baseline`。
4. 重跑生成器与 `python3 iOS/ai/skill-provider/validate_provider.py`，确认退出码 0。
5. 更新 `verification.json#/snapshot` 为 current（或删除 stale 标记），重新构建包（须在 t4 打包复核结束后由流水线负责人执行）。

## 4. dist 一致性（只读核对；本轮**未**重写 dist）

复核时 `wisdomdesign/dist/ai-skill/v1.0.0/wisdom-page-ios/manifest.json`：

| 项 | dist 当前值 | Provider 源当前值 | 结论 |
| --- | --- | --- | --- |
| `sources.ios.commit` | `64539fe…` | 快照 `c3c32f3…`（stale） | 不一致；dist 是 09:57 打包时 INPUT HEAD，provider 是基线快照；需在 re-baseline 或重打包时对齐 |
| `coverage.ios.apiCardFiles` | `35` | 实际卡片 33（另有 index.json + SOURCES.json） | 计数口径错误（package.py 统计 `api-cards/*.json`）；应由流水线负责人改为仅计卡片或改名 `apiCardJsonFiles` |
| `coverage.ios.status` | `experimental`（`computedAtBuild:true`，含 evidenceRefs） | `experimental`（validate_provider.py 重算） | 值一致；但 dist 是复制值，不证明重算；建议 package.py 调用/读取 `verification.statusComputation` 后写入 |
| provider 文件 | 内嵌 `c3c32f3` 的 provider.json/verification.json | 同上 | 与 `sources.ios.commit=64539fe` 组合会误导读者 |

> 约束：t4（打包/CI 复核）进行中，本任务**不重写 dist**。以上为核对结论，修复动作留给流水线负责人或 re-baseline 后重打包。
