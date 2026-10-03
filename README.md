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
另有 `WDGradient` `WDElevation` `WDMotion`。深浅色由 `Color` 自动跟随系统，不需要主题对象。

## 令牌来源

`Sources/WisdomUI/Foundation/Generated/WDTokens.swift` 由设计仓库生成，**不要手改**：

```bash
# 在 wisdomdesign 仓库
node tools/token-build/build.js
```

改色值、字号、圆角一律改 `wisdomdesign/tokens/wisdom.tokens.json`。

## 开发

```bash
swift build
swift test
```
