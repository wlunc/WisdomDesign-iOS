# U-09 体积基线 —— E3-iOS-a 的配对已测并定门槛；Thinning 仍缺

> 口径来源：`docs/SPEC.md` §1.2.3（E3-iOS-a/b、I10、IOS-13）+ `Examples/BaselineShell/README.md`。
> 日期：**2026-11-10**（M3 正式测量追加于 **2026-11-12**）｜环境：Xcode 26.6（17F113）／`generic/platform=iOS`／Release 归档／`CODE_SIGNING_ALLOWED=NO`
> 状态：**【已定门槛（未 Thinning）】** —— 同构消费方配对已完成 3 次重复归档，E3-iOS-a 的 P50 与门槛已写入 §6；**Thinning 增量仍为【未验证】**。

## 1. 为什么现在测

M3 出口判据⑤要求"体积门槛值定为 P50 + 10%（或绝对上限）并写进 README/CHANGELOG"（U-09）。
门槛值要由 M1–M3 三次报告的 P50 推出 ⇒ **至少要先有可比的原始数字**。本次是"预测量"：
不改代码、只归档，目的是把方法、命令与已知缺口固定下来。

## 2. 实测数字（2026-11-10）

| 目标 | 归档路径 | `.app` 总体积 | 可执行文件 |
| --- | --- | --- | --- |
| **BaselineShell**（分母；不引入本库） | `.build/archive-baseline.xcarchive` | **86,016 B（84 KB）** | 76,848 B |
| **WisdomUIDemo**（参考分子；含 demo UI + 本库） | `.build/archive-demo.xcarchive` | **598,016 B（584 KB）** | 586,200 B |
| **参考差值**（demo − baseline） | — | **512,000 B（500 KB）** | 509,352 B（≈497 KB） |
| **同构消费方**（`BaselineShellWithLibrary`，仅引入库 + `WDListRow`；**2026-11-11 新增**） | `.build/archive-baseline-lib.xcarchive` | **561,152 B（548 KB）** | 552,016 B |
| **E3-iOS-a 增量**（同构消费方 − baseline，**未 Thinning**） | — | **475,136 B（≈464 KB）** | 475,168 B（≈464 KB） |

> ⚠️ **这个差值不是 E3-iOS-a**：E3-iOS-a 要求分母与分子**同构**（只差"是否引入 `WisdomUI`"）。
> 当前分子是 demo（主题页 + 组件页 + 审计视口），比空壳多出大量 UI 代码 ⇒ 500 KB 只能当**上界参考**，
> 不能当门槛基线。

## 3. 复现命令

```bash
# 分母（BaselineShell；不要给它加组件/依赖/资源）
xcodebuild archive -project Examples/BaselineShell/BaselineShell.xcodeproj -scheme BaselineShell \
  -destination 'generic/platform=iOS' -archivePath .build/archive-baseline.xcarchive \
  -derivedDataPath .build/dd-baseline CODE_SIGNING_ALLOWED=NO

# 参考分子（demo）
xcodebuild archive -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'generic/platform=iOS' -archivePath .build/archive-demo.xcarchive \
  -derivedDataPath .build/dd-archive-demo CODE_SIGNING_ALLOWED=NO

# 量体积（.app 目录 + 可执行文件）
du -sk .build/archive-baseline.xcarchive/Products/Applications/*.app
du -sk .build/archive-demo.xcarchive/Products/Applications/*.app
```

原始日志：`.build/logs/u09-archive.log`（两次归档均 `ARCHIVE SUCCEEDED`）。

## 4. 仍未验证（不得写成已通过）

| # | 缺口 | 为什么现在是缺的 | 补测时点 |
| --- | --- | --- | --- |
| ① | **Thinning 增量** | 未签名归档不能导出 thinned IPA（`-exportArchive` 需要签名/`exportOptionsPlist`） | M3 出口前（用开发证书导出，或改用"未签名 archive + 设备切片估算"并注明口径） |
| ② | **同构消费方（配对分子）** | ✅ **已建并测（2026-11-11）**：`Examples/BaselineShellWithLibrary`，与 BaselineShell 同构、行改用 `WDListRow`；2026-11-11 预测量 = **475,136 B（≈464 KB）**（当时 `WDListSection` 尚未合并）。**2026-11-12 正式测量（3 次重复，含 `WDListSection`）= 495,616 B（≈484 KB）**，见 §6 | 已闭合（M3 出口） |
| ③ | **E3-iOS-b（每组件边际增量）** | 需要"每件一个配对壳"或差量构建；成本高，规格标"只报不拦 → M4 起门槛" | M4 |
| ④ | **门槛值** | ✅ **已定（2026-11-12）**：E3-iOS-a（未 Thinning）P50 = 495,616 B，门槛 = P50 × 1.10 = **545,178 B（≈532 KB）**；写进 `README.md` / `CHANGELOG.md` / §6 | 已闭合（M3 出口） |

## 5. 建议的 M3 收口顺序

1. M2 出口通过后，新建 `Examples/BaselineShellWithLibrary`（同构、仅替换行/卡片为 `WDListRow`/`WDCard`）；
2. 两端各归档 3 次（同一配置），取中位数 ⇒ 得到 E3-iOS-a 的**第一次正式数字**；
3. 与 M1/M2 已有数字（若历史报告只有门禁耗时，则如实记"体积只此一次"）合成 P50 + 10%；
4. 把门槛值写进 `README.md` + `CHANGELOG.md`，并更新 `docs/DEV-PLAN.md` §8.1 的 U-09 状态为"已回填"。

> 纪律：**未测之前不写门槛值**（SPEC §1.2.3 / IOS-13）；本次预测量只用于把方法钉住。

## 6. M3 正式测量（2026-11-12）与门槛

**样本构造**：`BaselineShell`（分母）与 `BaselineShellWithLibrary`（分子）各归档 **3 次**，每次用
**全新 archive 路径 + 固定 derivedData**（`.build/size/dd-{baseline,lib}`），同一配置、同一 destination。
`WDListSection` 已合并进库（相对 2026-11-11 的预测量，分子因此增大约 20 KB）。

| 样本 | `BaselineShell` `.app` | 同构消费方 `.app` | E3-iOS-a 增量（`.app`） | 可执行文件增量 |
| --- | --- | --- | --- | --- |
| run 1 | 86,016 B | 581,632 B | **495,616 B** | 495,576 B |
| run 2 | 86,016 B | 581,632 B | **495,616 B** | 495,576 B |
| run 3 | 86,016 B | 581,632 B | **495,616 B** | 495,576 B |
| **P50（= 中位数）** | 86,016 B | 581,632 B | **495,616 B（≈484 KB）** | 495,576 B |

> 3 次完全相同（未 Thinning，`CODE_SIGNING_ALLOWED=NO`）。原始数据 =
> `.build/size/measurements.tsv`；归档日志 = `.build/size/{baseline,lib}-{1,2,3}.log`。
>
> **历史样本口径**：M1/M2 的出口报告只有门禁耗时与渲染性能，**没有归档体积数字**；因此本仓可比的历史
> E3-iOS-a 样本只有本次 3 次重复，P50 按这 3 次取。**不虚构 M1/M2 的体积样本**。

**门槛（M3 出口定值）**：

| 项 | 值 |
| --- | --- |
| 指标 | E3-iOS-a：同构消费方 − BaselineShell 的 `.app` 归档增量（**未 Thinning**） |
| P50 | **495,616 B** |
| 门槛 | **P50 × 1.10 = 545,177.6 B → 545,178 B（≈532 KB）** |
| 表达口径 | 门槛按**增量**表达（同构消费方 `.app` − BaselineShell `.app`），不按分子绝对值——分母漂移会失去可比性 |
| 时点 | M3 出口写入门槛；M4 起接入发布前层断言（`docs/SPEC.md` §1.2.3 的 "M4 起门槛"） |

> **仍为【未验证】**：Thinning 增量。当前门槛是**未 Thinning** 口径；签名导出 thinned IPA 的增量
> 留 M6 发布前层（`docs/DEV-PLAN.md` §2.7-⑤），届时若与未 Thinning 口径差异显著，按 U-09 重新定值并
> 在 CHANGELOG 说明，**不静默更换口径**。
