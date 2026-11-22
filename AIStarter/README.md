# AIStarter — M2 iOS 纵向切片消费方

独立消费方工程，只通过 `import WisdomUI` 使用公开 API；不改发布库、不访问 Internal、不复制 Demo 私有辅助类型。

- `AIStarter/APIMinimalExample.swift`：最小调用例。
- `AIStarter/TaskListView.swift`：黄金任务列表页（模板 `ai-skill-provider/templates/task-list.swift` 的受控重命名副本）。
- `copy_template.js`：白名单页面名 + 目标校验 + 默认拒绝覆盖；不执行模板内脚本、不清理其它文件。
- `GoldenPageMatrixTests/`：UI testing target（`com.apple.product-type.bundle.ui-testing`，`TEST_TARGET_NAME=AIStarter`，依赖 app target）。

编译（cwd = 仓库根）：

```bash
CFFIXED_USER_HOME=$PWD/iOS/.build/home xcodebuild build \
  -project iOS/AIStarter/AIStarter.xcodeproj -scheme AIStarter \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath iOS/.build/dd-ai-starter-rel CODE_SIGNING_ALLOWED=NO
```

类型检查（cwd = 仓库根，4 个源文件；与 `verification.json#ios-minimal-typecheck` 一致）：

```bash
xcrun swiftc -typecheck -swift-version 6 -target arm64-apple-ios17.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -module-cache-path iOS/.build/module-cache \
  -I iOS/.build/dd-ai-starter-rel/Build/Products/Release-iphonesimulator \
  iOS/AIStarter/AIStarter/AIStarterApp.swift \
  iOS/AIStarter/AIStarter/ContentView.swift \
  iOS/AIStarter/AIStarter/APIMinimalExample.swift \
  iOS/AIStarter/AIStarter/TaskListView.swift
```

## Verification log（2026-11-22 更新）

- Release xcodebuild：exit 0 / BUILD SUCCEEDED（`verification.json#ios-consumer-xcodebuild-release`）。
- swiftc typecheck：4 个源文件 exit 0（`verification.json#ios-minimal-typecheck`）。
- 脚手架：合法复制 rc=0（逐字节相同）；覆盖、`../` 与 symlink 逃逸、非法 page/dir/name 均 rc=1（`verification.json#ios-scaffold-safety`）。
- GoldenPageMatrixTests：早期 Debug/Release 两次尝试为构建失败（PreviewsMacros / `_main`）；改为 UI testing target 后，最终 Release 尝试构建成功并产出 `GoldenPageMatrixTests-Runner.app`，但 test runner 启动被沙箱阻塞：`Pseudo Terminal Setup Error (Operation not permitted)`，exit 65，0 条 UI 断言执行。命令、模拟器、xcresult 与矩阵见 `GoldenPageMatrixReport.json` 与 `verification.json#ios-ui-matrix`。
- 真机、宿主加载、独立设计评审保持 not-run；未冒充验证通过。
