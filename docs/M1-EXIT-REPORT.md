# M1 出口报告 —— 基础设施（无组件交付）

> 里程碑：**M1**（口径来源 = `docs/DEV-PLAN.md` §2.2）｜判定日期：**2026-10-07**｜判定人：ios-lead（**待签字**）
> 判定环境：Xcode 26.6（Build 17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）／真机 iPhone 17（iOS 26.6，Lun1991）
> **结论：出口判据 5 条全部达成**（其中 1 条部分达成并已登记）；**2 项任务未完成**（真机观感采样、弹簧评审），二者**均不在出口判据之内**，均已在 §4 按【未验证】登记。

## 1. 出口判据逐条判定

| # | 判据（DEV-PLAN §2.2） | 证据 | 结论 |
| --- | --- | --- | --- |
| ① | 行盒 fixtures（zh/en）绿 | `WDLineBoxTest` 4 条用例：fixture 完整性（**缺失 = fail**）、U5-a（默认档单行 \|渲染盒 − max(设计, natural)\| ≤ 0.5pt）、U5-b（多行 n=2/3 ≤ 1pt）、U5-c（**AX1–AX5 五个放大档**不裁切）、自然行高漂移（12 档 × ≤0.5pt）。fixture = **288 条**（12 档 × 12 字阶 × {en, zh} × {字体级, 渲染级}） | ✅ |
| ② | 12 条性能预算有数（本端报告 + `.build/perf/{date}.json`） | **部分达成**：门禁三态耗时已实测并落盘（`.build/perf/ci-measure-20261007.json`：warm 7.98 / clean 14.46 / cold 58.88 s，n=3 中位数，已回填 README 与 SPEC §1.5.2）。**组件级 12 条性能预算（渲染/内存）此刻无组件可测** | ⚠️ 部分（见 §4-③） |
| ③ | demo 与 `WisdomUIDemoUITests` 可跑 | `xcodebuild test -project Examples/WisdomUIDemo … -only-testing:WisdomUIDemoUITests` → **2 tests / 0 failures**（方案切换 + 无障碍审计四类目，**严格模式：不吞任何 issue**） | ✅（模拟器） |
| ④ | 运行时 scheme 切换用例通过 | `testSchemeSwitchingAtRuntime`：值必须变 + **启动序号不变**（进程未重启 ⇒ F-05）；库侧另有 4 条主题用例（派生关系 / 同进程两套值 / scheme 清单不回退 / **取像素验证主题真驱动渲染**：浅 0xF1F8FA、深 0x0A1B26） | ✅ |
| ⑤ | 三件套单测骨架存在且**能红/能绿** | `WDGlassTests` / `WDEffectsBudgetTests` / `WDContrastTests` 共 34 条；含两条**必须红**用例（深色不得返回 `glass`、浅色 `glass` 不得承载 secondary/tertiary）。能红的实证：首版把"最不利"误写成"玻璃叠在画布上"，该用例**当场变红**并推翻假结论 | ✅ |

**判定汇总**：✅ 4 条 + ⚠️ 1 条（部分）；无阻断项。

## 2. 交付物与提交（全部已入库，工作区干净）

| 提交 | 内容 |
| --- | --- |
| `9c1fa37` | M1-① 字阶层三件（`WDTypographyMapping` / `WDFontMetrics` / `WDFont`）+ U5 行盒断言 + zh/en fixture |
| `24e4815` | M1-② `WisdomUIPreviews` 画廊 + `WisdomUISnapshotTests`（8 态矩阵、渲染器显式表、PNG 字节 + 逐像素差双判、manifest）+ **16 张基线入库** |
| `5e29077` / `140521c` | M1-⑥ 主题层（`WDTheme` / `wdTheme` / `wdColors` 只读派生）+ `Examples/WisdomUIDemo`（app + UITests + 本地包依赖 + xcconfig 占位） |
| `ddf1d13` | **修缺陷**：字号来源改为系统 `preferredFont`（原手算在放大档偏小 2–3pt）；`wdFont` 改用 text style（动态字体才被系统认可） |
| `c7eb91f` | **修缺陷**：demo 审计视口避开 11pt（系统审计把 caption2 判为不支持动态字体，登记 U-10）；审计回到严格模式 |
| `824e109` | M1-⑤ 三件套骨架（`WDGlass.resolve` / `WDEffectsBudget` / `WDContrast`）+ 删除对应冒烟段 |
| `097b5c2` | M1-③ 真机动态字体采样用例（准备件；真机实跑见 §4-①） |
| `3a420a9` | U-04：fixture 扩到 12 档 × 12 字阶 |

## 3. 实测数据（最近一次 `ci.sh pr` 全绿）

| 项 | 数值 |
| --- | --- |
| 门禁结论 | **全绿**（PR-0 / PR-1a / PR-1b / PR-2 / 覆盖率报告） |
| 分阶段耗时 | PR-0 1.38 s｜PR-1a 1.32 s｜PR-1b 11.89 s｜PR-2 1.51 s｜覆盖率 0.67 s｜**合计 16.77 s** |
| 测试 | `passed=34 failed=0 skipped=0` |
| 符号快照 | 与基线**零 diff**（symbols=371） |
| 覆盖率 | `WisdomUI` **55.79%** |
| 快照 | 16 张基线（2 画廊 × 8 态），复跑 4 tests passed |
| 行盒 fixture | 288 条（12 档 × 12 字阶 × 2 语种 × 2 层） |
| 字阶实测（渲染级，body） | xSmall 17.00 → large 20.33 → AX1 33.67 → AX3 48.00 → AX5 63.33（3.1×）；largeTitle @AX5 = 71.67 |
| 对比度账目（最不利口径） | light.glass/secondary **3.64**、tertiary **3.09**、dark.glass/primary **4.14**、dark.glassStrong/secondary **4.16**、tertiary **2.93** —— 与设计 §12.3 的 3.6 / 3.1 / 4.1 / 4.2 / 2.9 **逐条吻合**；浅色画布 primary/secondary/tertiary = 16.36 / 7.10 / 6.04（设计 16.3 / 7.1 / 6.0） |

## 4. 【未验证】台账（一律不得写成"已通过"）

| # | 项 | 现状 | 依赖谁 / 何时 |
| --- | --- | --- | --- |
| ① | **M1-③ 真机 `fontScale 2.0` / AX3 观感采样** | **未采样**。真机链路已打通到装包（签名、证书信任、开发者模式、配对全部 ✅），但 UI 测试 runner 无法 bootstrap（`exited with code 74 before establishing connection`；**设备无任何 runner/App 崩溃日志** ⇒ 根本没启动；同时 `notification_proxy` 报 `The device is passcode protected`）。**根因已定位（2026-10-07）**：设备为**无线连接**（`devicectl` 的 `transportType = localNetwork`、隧道走 tcp；`system_profiler SPUSBDataType` 里没有 iPhone）—— **XCUITest 的 runner 在真机上需要 USB 直连**，而 `⌘R` 跑 app 不受影响，与实测现象（直接运行正常 / 跑测试失败）完全一致。**待澄清**：iOS 无 `fontScale` 旋钮，设计说的 2.0 对应哪个内容字号档 | **USB 直连**后重跑（兜底：设置 → 开发者 → 启用 UI 自动化）。观感结论必须**人**给 |
| ② | **M1-④ 弹簧 μ=1.0 并排评审（设计确认关）** | **未做**。阻塞点不是"没人签字"，而是**没有评审对象**：动效层（`WDMotion`）尚未实现 | M4 动效落地 → 出并排材料 → 设计确认 |
| ③ | **12 条性能预算（组件级）** | 只有门禁耗时；渲染/内存预算**无组件可测** | M2 首批 11 件落地后补测 |
| ④ | U-03 / U-04 | ✅ **已闭合**（本端实测 zh/en 两层；12 档 × 12 字阶） | — |
| ⑤ | SPM pin 后"移动 tag"失败模式（U-08） | 未测（政策无条件是成立的） | M6 发布前 |

## 5. 登记项（待回写 / 待签发，均不阻塞 M2）

| 项 | 内容 | 状态 |
| --- | --- | --- |
| **P14** | SPEC §2.6.3 放大档判据 `≥ ⌈natural × n⌉` **对非整数自然高不可满足**（caption2/AX3/n=2：⌈71.67⌉ = 72 > 真实 71.67）⇒ 建议改 `≥ natural × n − 0.5pt` | **待回写**（实现已按新形式落地） |
| **P15** | 快照矩阵写作"六态"但三轴相乘 = **8 态** | **待回写**（实现按 8 态，含计数断言） |
| **U-10** | 系统无障碍审计把 **11pt（caption2）** 文本判为 Dynamic Type unsupported（**纯 SwiftUI `.font(.caption2)` 同样被报**，与库无关） | **待裁决**（组件若必须在审计视口用 caption2，需一条带理由的窄例外或与设计改档） |
| DF-02 / DF-03 / DF-04 | 玻璃矩阵 / 7 条配额 / 对比度门槛需设计**签发** | 已按 AGENTS §12 的条文实现，账目与设计吻合 |
| DF-10 | iOS 17–25 玻璃降级 | 已按**默认执行项**实现（纯色降级 ⇒ 只返回 `opaque`） |
| DF-14 | `motion.duration.reduced` 150ms / 160ms | 待设计（动效层未做） |

## 6. 放行建议

- **M1 入口判据**（I-1 上一里程碑出口已判定 ／ I-3 令牌含 `schemes` 维度 ／ I-4 门禁可跑且为绿）**全部满足** ⇒ **M2 可以开工**。
- 本报告即为 I-1 所要求的"出口报告已落盘"。
- M2 第 0 步 = **批前签名冻结**（I-2）：11 件的完整签名（含枚举 case 与默认值）+ `contracts/<component>.yaml` 的 `params`/`slots`/`default`。**时点说明**：`contracts/*.yaml` 库为 M0-5 才落库，在此之前该判据以**批前签名冻结会登记表单**代替。
- §4 的 ①②③ 三项不构成 M2 的阻断项，但**必须随 M2 出口一并复核**（否则会变成"永远没人做"的悬空项）。

---

> 本报告的每一条结论都对应可重跑的命令或已入库的产物；凡未跑通的一律标【未验证】并写明依赖，**没有一处写成"已通过"**。
