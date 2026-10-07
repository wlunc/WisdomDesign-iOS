// swift-tools-version: 6.1
import PackageDescription

// I-M0-a：终态口径 = iOS/docs/SPEC.md §1.2（签名级）。
// 五条纪律：
//   ① 平台只声明 .iOS(.v17)（桌面平台不声明；门禁一律 xcodebuild + 模拟器）；
//   ② 语言模式显式钉死 Swift 6（包级 + target 级双保险）；
//   ③ **不声明 build tool plugin**（SPEC §1.1.1-E1：attach 会让每个消费方的构建图编译检查器，
//      且默认静默 ⇒ 成本换零生效；M0 唯一强制入口 = Scripts/check-structure.sh）；
//   ④ wd-structure-check 是 host 可执行 target，**只 import Foundation，不依赖 WisdomUI**（I19）；
//      门禁可在 host 侧秒级跑，不触发 WisdomUI 的 iOS-only 编译图。
//   ⑤ 尚未落地的 target 不提前声明：WisdomUIPreviews / WisdomUISnapshotTests 的 path 目前不存在，
//      提前写进清单会让 manifest 直接失败 ⇒ 随 M1 交付物加入（本文件只声明已存在的三个 target）。

let package = Package(
  name: "WisdomDesign-iOS",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    // 发布面只有 1 个（F-10）：WisdomUIPreviews 不进 products。
    .library(name: "WisdomUI", targets: ["WisdomUI"])
  ],
  targets: [
    .target(
      name: "WisdomUI",
      path: "Sources/WisdomUI",
      swiftSettings: [
        // 预览守卫是 SwiftPM .define，不是 #if DEBUG（SPEC §1.6）。
        .define("WD_PREVIEWS", .when(configuration: .debug)),
        .swiftLanguageMode(.v6),
      ]
    ),
    .executableTarget(
      name: "wd-structure-check",
      path: "Sources/wd-structure-check"
        // 无 dependencies：依赖 WisdomUI 会把 host 检查器绑到 iOS-only 编译图上。
    ),
    // 测试 target 依赖分离（I08）：WisdomUITests 只依赖 WisdomUI；
    // WisdomUISnapshotTests（依赖 WisdomUIPreviews + Baselines 资源）随 M1 快照交付物加入。
    // 预览支撑（不进 products；只带共享视图，不携带资源）。
    .target(
      name: "WisdomUIPreviews",
      dependencies: ["WisdomUI"],
      path: "Sources/WisdomUIPreviews",
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "WisdomUITests",
      dependencies: ["WisdomUI"],
      path: "Tests/WisdomUITests"
    ),
    // 快照 target 依赖分离（I08）：只有它依赖 WisdomUIPreviews；
    // resources 只出现在测试 target（快照基线），主 target 永远 resources: []。
    .testTarget(
      name: "WisdomUISnapshotTests",
      dependencies: ["WisdomUI", "WisdomUIPreviews"],
      path: "Tests/WisdomUISnapshotTests",
      resources: [.copy("Baselines")]
    ),
  ],
  // 包级语言模式：与上面的 target 级 .swiftLanguageMode(.v6) 互为双保险。
  swiftLanguageModes: [.v6]
)
