# BaselineShellWithLibrary —— E3-iOS-a 的「同构消费方」分子

**它是什么**：与 [`../BaselineShell`](../BaselineShell) **同构**的最小 SwiftUI app（同样的 target 结构、
同样的构建设置、同样的一个 `NavigationStack` + 20 行列表屏幕），**唯一差异 = 引入 `WisdomUI` 并用
`WDListRow` 渲染行**。E3-iOS-a 的归档增量 = **本壳归档体积 − BaselineShell 归档体积**。

**它不是什么**：不是 demo（`Examples/WisdomUIDemo` 有主题页、组件目录、审计视口）；不要在这里加页面、
资源或第三方依赖。

## 纪律

- **与 `BaselineShell` 成对修改**：改任何一边都要两边同批提交，并在 `CHANGELOG.md` 标注
  （否则历史测量值之间不可比）。
- **不检入 team / bundle id**：pbxproj 用占位 `com.example.baselineshellwithlibrary`。
- **不加 `Resources/`**：与分母的差异要尽量只落在"是否引入本库"这一件事上。

## 命令

```bash
# 设备编译自检（不需要模拟器/签名）
xcodebuild build -project Examples/BaselineShellWithLibrary/BaselineShellWithLibrary.xcodeproj \
  -scheme BaselineShellWithLibrary -destination 'generic/platform=iOS' \
  -derivedDataPath .build/dd-baseline-lib -quiet CODE_SIGNING_ALLOWED=NO

# 归档（E3-iOS-a 的分子；必须与 BaselineShell 同配置、同 destination）
xcodebuild archive -project Examples/BaselineShellWithLibrary/BaselineShellWithLibrary.xcodeproj \
  -scheme BaselineShellWithLibrary -destination 'generic/platform=iOS' \
  -archivePath .build/archive-baseline-lib.xcarchive \
  -derivedDataPath .build/dd-archive-baseline-lib CODE_SIGNING_ALLOWED=NO
```

## 口径与状态

- 口径 = `docs/SPEC.md` §1.2.3 / IOS-13：体积**只报不拦**，M4 起转门槛；门槛值 = M1–M3 三次报告的
  P50 + 10%（或绝对上限），由 tech-lead + 架构师在 M3 出口定 —— **未测之前不写门槛值**。
## 已测（2026-11-11，首次成对归档）

| 目标 | `.app` | 可执行文件 |
| --- | --- | --- |
| `BaselineShell`（分母） | 86,016 B | 76,848 B |
| **本壳**（分子） | **561,152 B** | **552,016 B** |
| **E3-iOS-a 增量（未 Thinning）** | **475,136 B ≈ 464 KB** | **475,168 B ≈ 464 KB** |

环境：Xcode 26.6 / `generic/platform=iOS` / Release 归档 / `CODE_SIGNING_ALLOWED=NO`；
两边用同一命令与同一 derivedData 根。

**【未验证】**：① Thinning 增量（需签名导出 thinned IPA；当前是**未 Thinning** 的归档体积差）；
② 三次报告取 P50（M3 出口定门槛值）。
