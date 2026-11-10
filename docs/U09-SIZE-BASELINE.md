# U-09 体积基线（预测量）—— E3-iOS-a 的分母已测；配对分子与 Thinning 仍缺

> 口径来源：`docs/SPEC.md` §1.2.3（E3-iOS-a/b、I10、IOS-13）+ `Examples/BaselineShell/README.md`。
> 日期：**2026-11-10**｜环境：Xcode 26.6（17F113）／`generic/platform=iOS`／Release 归档／`CODE_SIGNING_ALLOWED=NO`
> 状态：**【部分实测】** —— 未签名归档的两端体积已有数；**Thinning 增量与"同构消费方"配对仍未测**。

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
| ② | **同构消费方（配对分子）** | 需要一个"与 BaselineShell 同构、但改用 `WDListRow`/`WDCard` 渲染"的 app；现在没有，且当前处于**代码冻结期**（nightly 连续 3 日不能改源） | M3 开工后（新建 `Examples/BaselineShellWithLibrary`；改它=改基线，需单独提交 + CHANGELOG） |
| ③ | **E3-iOS-b（每组件边际增量）** | 需要"每件一个配对壳"或差量构建；成本高，规格标"只报不拦 → M4 起门槛" | M4 |
| ④ | **门槛值** | 规格要求 P50 + 10%（M1–M3 三次报告）；现在只有 1 次预测量 | M3 出口（tech-lead + 架构师定，写 README/CHANGELOG） |

## 5. 建议的 M3 收口顺序

1. M2 出口通过后，新建 `Examples/BaselineShellWithLibrary`（同构、仅替换行/卡片为 `WDListRow`/`WDCard`）；
2. 两端各归档 3 次（同一配置），取中位数 ⇒ 得到 E3-iOS-a 的**第一次正式数字**；
3. 与 M1/M2 已有数字（若历史报告只有门禁耗时，则如实记"体积只此一次"）合成 P50 + 10%；
4. 把门槛值写进 `README.md` + `CHANGELOG.md`，并更新 `docs/DEV-PLAN.md` §8.1 的 U-09 状态为"已回填"。

> 纪律：**未测之前不写门槛值**（SPEC §1.2.3 / IOS-13）；本次预测量只用于把方法钉住。
