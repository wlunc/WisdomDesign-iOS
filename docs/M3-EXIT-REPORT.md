# M3 出口报告 —— 封板批（`WDListSection` + 公开 API 冻结）

> 里程碑：**M3**（口径来源 = `docs/DEV-PLAN.md` §2.4）｜报告日期：**2026-11-12**
> 判定人：ios-lead｜**状态：通过（2026-11-12）** —— 技术判据 6/6；**项目负责人明确决定忽略 nightly₃ 门禁**（实测仅第 1/3 日；第 2/3、3/3 日不补跑）。
> 判定环境：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）
> 关联：`docs/M3-SIGNATURE-FREEZE.md`、`docs/M3-PREP-LISTSECTION.md`、`docs/M3-API-FREEZE.md`、`docs/U09-SIZE-BASELINE.md`

## 1. 出口判据逐条判定（DEV-PLAN §2.4 的 6 条）

| # | 判据 | 证据 | 结论 |
| --- | --- | --- | --- |
| ① | `api/WisdomUI.api.json` 入库且 `git diff --exit-code` 绿 | PR-2：`dump-api: 与基线零 diff（symbols=661）`；SHA-256 `a3392784…`；记录 = `docs/M3-API-FREEZE.md` | ✅ |
| ② | 命名与枚举规则内联表 §5.3 全部对齐 | 12 个契约 yaml（11 件 + `WDListSection`）回填设计仓；校验：受控值 canonical（`loading`/`text`/`on`/`checked`/`selected`/`selection`）全部命中、`slots` 全部 ⊆ 21 名词表（`WDDivider` 写「无」）、枚举 case 与 API 基线归一化集合全部相等 | ✅ |
| ③ | 快照与契约用例全绿 | `WDListSectionSnapshotTests`：**4 变体 × 8 态 = 32 张**；全仓基线 **136 张**；nightly-1b：**17 个快照测试 / 14 suites 全绿**；组件单测 **7 条**（空组/末行/选中/密度/页脚/动作热区）；demo 目录与预览已挂载 | ✅ |
| ④ | 覆盖率转门槛：`Foundation/**` ≥ 80%（排除 `generated/`） | `ci.sh pr` 第 4 阶段已由「只打印」改为**硬门槛**；实测 **97.73%（603/617）≥ 80%**（`WisdomUI` 总覆盖率 61.14%，只报不拦） | ✅ |
| ⑤ | 体积门槛值定为「P50 + 10%」并写进 README/CHANGELOG | 同构消费方 3 次归档：581,632 B − 86,016 B = **495,616 B**（3 次完全相同）⇒ 门槛 = **545,178 B（≈532 KB）**，按增量表达；已写 `README.md`、`CHANGELOG.md`、`docs/U09-SIZE-BASELINE.md` §6 | ✅ |
| ⑥ | 封板批 12 件 primitives 在报告中占位、无缺件 | 见 §5：M2 的 11 件 + `WDListSection` = **12/12 ✅**；其余 8 件 primitives 按 M4/M5 各自批前冻结 | ✅ |

**封板附带（SPEC §1.1.2/§1.5.5）**：M3 起 R7/R15/R21 的 warning 转拦——PR-0 已改
`Scripts/check-structure.sh --strict`；本次清理后 **0 warning / 51 处带理由豁免**（R7 中 3 处改用令牌）。

**门禁强度**：`PR + nightly₃ + 发布前`。

- **PR：✅ 全绿（2026-11-12）**——`passed=113 failed=0`、符号 661 零 diff、`Foundation/**` 97.73% 过门槛、`--strict` 结构门禁 0 warning、warm **20.84 s**（n=1，最终 HEAD 复跑）。
- **nightly：按项目负责人决定豁免**——实测 **第 1/3 日（2026-11-12）绿**：设备编译 2.13 s + 17 快照测试（136 基线）27.52 s + demo 四类目审计 67.65 s；3 条 UITest 全过，`AUDIT-ISSUE=0`；整条 97.29 s。
- **决定记录**：项目负责人 2026-11-12 明确「忽略 nightly，继续」⇒ **第 2/3 日（11-13）与第 3/3 日（11-14）不补跑**；M3 按技术判据 6/6 判定通过。该豁免不改变 §4-②（Thinning 未验证）的处置。
- **发布前层**：归档体积已测（未 Thinning）；Thinning 增量仍【未验证】（M6 发布前层），见 §4。

## 2. 本批交付物

| 项 | 内容 |
| --- | --- |
| 组件 | `WDListSection`（数据驱动 `items` + `selection` + `header` + `headerAction` + `footer`；空组隐藏、末行 `isLast` 传递） |
| 源码 | `Sources/WisdomUI/Components/Primitives/WDListSection/`（`WDListSection.swift` + `+Previews.swift`）；`DRAFT` 注释已清除 |
| 单测 | `Tests/WisdomUITests/Components/WDListSectionTests.swift`（7 条） |
| 快照 | `Tests/WisdomUISnapshotTests/WDListSectionSnapshotTests.swift`；4 变体 × 8 态 = **32 张基线**（总 136 张；manifest 已更新） |
| demo | 组件目录新增 `WDListSection`（结构分组）+ 实时预览 + 档位/状态分区；**审计视口扩到 12 件**（含标题动作热区 44） |
| 契约 | 设计仓 `../wisdomdesign/contracts/`：11 件 + `WDListSection` = **12 个 yaml**（提交 `89779f7`）；params/slots/default + 枚举全量 case |
| API 封板 | `docs/M3-API-FREEZE.md`（661 符号 / SHA-256 / 复跑命令 / 封板口径） |
| 门槛 | 覆盖率硬门槛（`ci.sh` 第 4 阶段）；归档体积门槛（README / U09 §6） |
| 结构门禁 | `ci.sh` PR-0 转 `check-structure.sh --strict`（SPEC §1.1.2/§1.5.5 的 M3 升级）；R7 清理：3 处改令牌、10 处带理由豁免；R21 2 处带理由豁免；结果 **0 warning / 51 suppressed** |

## 3. 门禁原始数据

### 3.1 PR（2026-11-12）

| 阶段 | 耗时 |
| --- | --- |
| PR-0 host 规则（`--strict`）+ 格式 + 令牌溯源 | 1.63 s |
| PR-1a build-for-testing（含 `WD_API_SMOKE`） | 2.52 s |
| PR-1b test-without-building（`WisdomUITests`）+ 覆盖率采集 | 13.85 s |
| PR-2 API 冻结 | 2.27 s |
| 覆盖率门槛（Foundation ≥ 80%） | 0.56 s |
| **合计** | **20.84 s**（warm，n=1） |

测试结论：`result=Passed passed=113 failed=0 skipped=0`；覆盖率：`WisdomUI 61.14%`、`Foundation/** 97.73%（603/617）`。结构门禁：`--strict`，0 warning / 51 处带理由豁免。

### 3.2 nightly 第 1/3 日（2026-11-12）

| 阶段 | 结果 |
| --- | --- |
| nightly-1a 设备编译（generic/platform=iOS） | 2.13 s，绿 |
| nightly-1b 快照（`WisdomUISnapshotTests`） | 27.52 s；**17 tests / 14 suites 全绿**（136 基线） |
| nightly-2 demo 无障碍审计（4 类目） | 67.65 s；**3 条 UITest 全过**、`AUDIT-ISSUE=0`；已知窄例外按 M2 出口报告 §4-② 逐条点名（固定字号头像/徽标、行的单行截断） |
| **合计** | **97.29 s** |

> 仅第 1 日实测；第 2/3、3/3 日按项目负责人 2026-11-12 的决定不补跑。

## 4. 未验证 / 未闭合台账（**不得写成已通过**）

| # | 项 | 现状 | 回填责任 / 时点 |
| --- | --- | --- | --- |
| ① | **nightly 连续 3 日绿** | **项目负责人 2026-11-12 决定豁免**；实测仅 1/3（2026-11-12 绿），11-13、11-14 不补跑 | 项目负责人（已决定）/ M3 出口 |
| ② | **归档 Thinning 增量** | **【未验证】**：未签名归档不能导出 thinned IPA；当前门槛是**未 Thinning** 口径（同构消费方增量 P50 = 495,616 B） | ios-lead + tech-lead / **M6 发布前层**；口径变更须在 CHANGELOG 说明 |
| ③ | **`WDCheckbox` 契约名的 Android 书面复核** | 契约 yaml 已按 `checked` 落库；`android/docs/SPEC.md` §2.10 R3A-01 已记载「保持 checked」，**书面复核仍待 android-lead** | android-lead / M3 出口后随契约面复核（不阻塞本批 6 条判据） |
| ④ | **真机采样（U-05）** | M1 遗留；设备无线连接无法 bootstrap XCUITest | 用户 + ios-dev / M6 前 |
| ⑤ | **组件级覆盖率** | 只报不拦（本批未设门槛，符合判据④只要求 `Foundation/**`） | — |

## 5. 封板批 12 件 primitives 占位（判据⑥）

| # | 组件 | 状态 | 批次 |
| --- | --- | --- | --- |
| 1 | `WDTextField` | ✅ | M2 |
| 2 | `WDListRow` | ✅ | M2 |
| 3 | `WDButton` | ✅ | M2 |
| 4 | `WDIconButton` | ✅ | M2 |
| 5 | `WDSwitch` | ✅ | M2 |
| 6 | `WDCheckbox` | ✅ | M2 |
| 7 | `WDBadge` | ✅ | M2 |
| 8 | `WDAvatar` | ✅ | M2 |
| 9 | `WDDivider` | ✅ | M2 |
| 10 | `WDCard` | ✅ | M2 |
| 11 | `WDIcon` | ✅（M2 登记的差异不属缺件） | M2 |
| 12 | **`WDListSection`** | **✅** | **M3** |

> 其余 primitives：`WDProgressBar`/`WDProgressRing`（M4）、`WDSearchField`/`WDRadio`/`WDSlider`/`WDStepper`/`WDChip`/`WDAvatarStack`（M5）——按各自批前签名冻结执行；20/20 完成于 M5 出口。

## 6. 判定记录

| 项 | 值 |
| --- | --- |
| 技术判据 | **6/6 ✅**（§1） |
| 门禁 | PR ✅；nightly **1/3**（2026-11-12）；发布前层：归档已测、Thinning【未验证】 |
| 结论 | **通过（2026-11-12）**：技术判据 6/6；项目负责人明确决定忽略 nightly₃ 门禁（实测 1/3，不补跑） |
| 签字 | ios-lead（技术判定）；项目负责人（豁免决定，2026-11-12） |
| 条件 | nightly 第 2/3、3/3 日未跑；Thinning 增量仍【未验证】，留 M6 发布前层。**本豁免仅针对 M3 批出口，不改变后续批的 nightly 要求** |
| 备注 | 本报告每条结论对应可重跑命令或已入库产物；nightly 门禁豁免是项目负责人的显式决定，不是"已通过"的事实改写 |

## 7. 复跑命令（逐条可复现）

```bash
cd iOS
Scripts/ci.sh pr        # PR 门禁（含 Foundation ≥ 80% 覆盖率门槛、API 零 diff）
Scripts/ci.sh nightly   # 设备编译 + 17 个快照测试 + demo 四类目审计
Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json
# 体积（3 次重复；详见 docs/U09-SIZE-BASELINE.md §6）
xcodebuild archive -project Examples/BaselineShell/BaselineShell.xcodeproj -scheme BaselineShell \
  -destination 'generic/platform=iOS' -archivePath .build/size/baseline.xcarchive CODE_SIGNING_ALLOWED=NO
xcodebuild archive -project Examples/BaselineShellWithLibrary/BaselineShellWithLibrary.xcodeproj \
  -scheme BaselineShellWithLibrary -destination 'generic/platform=iOS' \
  -archivePath .build/size/lib.xcarchive CODE_SIGNING_ALLOWED=NO
```
