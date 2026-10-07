# WisdomDesign-iOS

Wisdom Design System 的 SwiftUI 实现。

## 安装

```swift
.package(url: "https://github.com/wlunc/WisdomDesign-iOS.git", from: "1.0.0")

.target(
    name: "YourApp",
    dependencies: [.product(name: "WisdomUI", package: "WisdomDesign-iOS")]
)
```

仓库名是 `WisdomDesign-iOS`，产品名是 `WisdomUI`。

要求 iOS 17.0+。Liquid Glass 相关效果在 iOS 26 上走系统 `glassEffect`，17–25 降级为材质 + 描边。

## 命名

公开 API 一律 `WD` 前缀，与 Android 端保持同名：

```swift
import WisdomUI

Text("今天的任务").font(WDType.headline.font)

WDCard { ... }             // 组件（M2 起）
    .wdCardStyle(.elevated)
```

令牌分五个命名空间：`WDColor` `WDType` `WDSpacing` `WDRadius` `WDSize`，
另有 `WDGradient`（浅深成对的动态色，一条令牌覆盖两种外观）`WDElevation` `WDMotion`。
深浅色由 `Color` 自动跟随系统，不需要主题对象。

## 令牌来源

`Sources/WisdomUI/Foundation/generated/WDTokens.swift` 由设计仓库生成，**不要手改**：

```bash
# 在 wisdomdesign 仓库
node tools/token-build/build.js
```

改色值、字号、圆角一律改 `wisdomdesign/tokens/wisdom.tokens.json`。

## 开发与门禁

门禁一律 `xcodebuild` + 模拟器；**host 侧的 SwiftPM 命令不作门禁**（本包只声明 iOS 平台，host 编译必然失败）。

```bash
Scripts/ci.sh pr        # 每次提交必过：PR-0 host 规则/格式 → PR-1 模拟器编译 + 单测 → PR-2 API 冻结 → 覆盖率
Scripts/ci.sh doctor    # 只做环境自检（工具链 / scheme / destination），不编译
Scripts/ci.sh nightly   # 每批强制：设备编译 + 六态快照（六态套件是 M1 交付物，M1 前会以退出码 3 明确失败）
Scripts/ci.sh measure   # 过程成本测量（分阶段计时；**未测不写预算**）
```

运行时依赖：`xcodebuild`、`xcrun`（`simctl` / `xccov` / `xcresulttool` / `swift-symbolgraph-extract`）与 **`python3`**（解析模拟器 UDID 与测试结果包）；**不需要 `node`**（只有跨仓跑令牌生成器时才要）。GitHub 的 macOS runner 自带 `python3`。

### 三个已固化的值（`Scripts/ci.sh` 的常量；改动要三处同步 = 本表 + 脚本 + `docs/DEV-PLAN.md` §4）

| 项 | 冻结值 | 说明 |
| --- | --- | --- |
| scheme | `WisdomDesign-iOS-Package` | 包级聚合 scheme（名字由 `Package.swift` 的包名派生）。`xcodebuild -list` 另给 `WisdomUI`（只有库）与 `wd-structure-check`（host 检查器）——门禁**不取"第一个 scheme"** |
| destination | 最新可用 iOS 运行时的模拟器 **UDID** | 运行期由 `simctl list -j` 解析；**不按设备名硬编码** |
| DerivedData | `.build/dd` | 结果包 `.build/dd/pr.xcresult`、构建包 `.build/dd/pr-build.xcresult`、日志 `.build/logs/`、报告 `.build/perf/` |

### 缓存不落家目录

脚本用 `CFFIXED_USER_HOME` 把 **host 侧工具**看到的家目录钉到 `.build/home/`，于是 SwiftPM 的 manifest 缓存与 Xcode 用户目录都落在工作区内。这同时修掉了受限环境下的两处失败：`xcodebuild` 的 "Could not resolve package dependencies"，以及 `xcresulttool` 的 "permission … TestReport"。关掉：`WD_USER_HOME_PIN=0`。

### 门禁现状（**未验证的一律照实写**）

- `Scripts/ci.sh pr`：**首次全绿**（2026-10-06；Xcode 26.6 + iOS 26.5 模拟器）。

**门禁预算（实测，2026-10-07；`Scripts/ci.sh measure 3 --states=warm,clean,cold`，每态 n=3 取中位数；单位 = 秒）**：

| 阶段 | warm | clean | cold |
| --- | --- | --- | --- |
| PR-0 host 规则 + 格式 + 令牌溯源 | 1.49 | 1.48 | 2.16 |
| PR-1a build-for-testing（含签名冒烟） | 1.39 | 7.79 | 7.48 |
| PR-1b test-without-building + 覆盖率采集 | 2.88 | 2.82 | 2.90 |
| PR-2 API 冻结 | 1.61 | 1.78 | **45.51** |
| 覆盖率报告 | 0.67 | 0.65 | 0.69 |
| **合计** | **7.98** | **14.46** | **58.88** |

口径：**warm** = 复用现有缓存；**clean** = 每轮删 DerivedData；**cold** = 连 SwiftPM manifest 缓存与 module-cache 一起删。
cold 的 PR-2 那 45 s 是 `swift Scripts/canonicalize-api.swift` 的**宿主模块缓存被清后重编译**（每轮都付），不是 API 逻辑慢。
原始数据：`.build/perf/ci-measure-20261007.json`。**测法变了要重测**（改 `ci.sh` 的 PR 阶段、换 Xcode 大版本、换金标设备）。
- **覆盖率**：最近一次门禁 `WisdomUI` **12.70%**（令牌落地后模块体量增大、尚无组件用例 ⇒ 数字下降是分母变大，不是回退）；M3 起 `Foundation/**` ≥ 80% 才转门槛（排除 `generated/`）。
- `Scripts/ci.sh nightly`：**M1 前不可绿**——前置 `Tests/WisdomUISnapshotTests`（六态快照）是 M1 交付物；缺失时脚本以退出码 3 明确失败，**不静默跳过**。
- `.github/workflows/ci.yml`：**【未验证】** 本仓尚无一次 GitHub Actions 实跑（macOS 26 镜像标签与自带 Xcode 版本属外部事实）。

贡献流程（提交纪律、评审归属、不能自行决定的事）见 [CONTRIBUTING.md](CONTRIBUTING.md)；PR 自检清单见 [.github/pull_request_template.md](.github/pull_request_template.md)。

## 预览

`#Preview` 一律带 `#if WD_PREVIEWS` 守卫（SwiftPM 的 `.define`，**不是** `#if DEBUG`，见 `Package.swift`）。三条限制必须知道：

1. **需要宿主 app target** —— 预览不能只靠包本身；
2. **release 不编译** —— `WD_PREVIEWS` 只在 debug 配置下定义；
3. **材质/玻璃在预览里与真机不一致** —— `Material` / `glassEffect` 的观感不能作为验收依据（玻璃类的六态快照走 `UIHostingController` + `drawHierarchy`，见 `docs/SPEC.md` §1.6）。
