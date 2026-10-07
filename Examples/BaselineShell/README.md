# BaselineShell —— 归档体积基线（E3-iOS-a 的分母）

**它是什么**：一个**同构但不引入 WisdomUI** 的最小 SwiftUI app。E3-iOS-a 量的是"引入本库后归档
Thinning 的增量"，分母必须固定 —— 否则每次比较的是不同的空壳（SPEC §1.2.3 的 I10）。

**它不是什么**：不是 demo（demo = `Examples/WisdomUIDemo`，M1 交付物，用来跑无障碍审计与
预览矩阵）。本 shell 只做体积分母：**不要**在这里加组件、加依赖、加资源。

## 纪律

- **不引入 WisdomUI**：一旦引入，分母就没了（量出来的增量恒为 0）。
- **改它 = 改基线**：任何改动单独提交 + 在 `CHANGELOG.md` 标注，否则历史测量值不可比。
- **不检入 team / bundle id**：pbxproj 里是占位值（`DEVELOPMENT_TEAM = ""`、
  `PRODUCT_BUNDLE_IDENTIFIER = com.example.baselineshell`）；归档时用 xcconfig 或命令行覆盖，
  **不要把真值写回仓库**（SPEC §1.6-①）。
- **不加 `Resources/`**：基线与消费方的差异要尽量只落在"是否引入本库"这一件事上。

## 命令

设备编译自检（不需要模拟器、不需要签名）：

```bash
xcodebuild build -project Examples/BaselineShell/BaselineShell.xcodeproj -scheme BaselineShell -destination 'generic/platform=iOS' -derivedDataPath .build/dd-baseline -quiet CODE_SIGNING_ALLOWED=NO
```

归档（E3-iOS-a 的分母；必须与消费方 app 同配置、同 destination 才可比）：

```bash
xcodebuild archive -project Examples/BaselineShell/BaselineShell.xcodeproj -scheme BaselineShell -destination 'generic/platform=iOS' -archivePath .build/archive-baseline.xcarchive CODE_SIGNING_ALLOWED=NO
```

## 口径与状态

**口径**（SPEC §1.2.3 / IOS-13）：体积**只报不拦**，M4 起转门槛；门槛值 = M1–M3 三次报告的
P50 + 10%（或绝对上限），由 tech-lead + 架构师在 M3 出口定 —— **未测之前不写门槛值**。

**实测（2026-10-07）**：Debug 设备编译 `EXIT=0`，产物
`.build/dd-baseline/Build/Products/Debug-iphoneos/BaselineShell.app`（可执行 72,688 B）。
（Debug 产物里有 `__preview.dylib`，因为 `ENABLE_PREVIEWS = YES`；Release/归档不含。）

**【未验证】**：① 归档与 Thinning 增量**尚未跑**；② E3-iOS-a 的"消费方 app − 本 shell"配对测量要等
demo（M1）与 M3 的体积报告 —— 回填责任 = ios-lead，时点 = M3 出口（`docs/DEV-PLAN.md` §8.1 的 U-09）。
