# t6 修复记录（F1–F8）

> 来源：`wisdomdesign/AIOptimize/review/02-ios.md`（R2，verdict=needs_revision）
> 范围：仅 `iOS/ai/skill-provider/**`、`iOS/AIStarter/**`；未改 iOS api 基线、generated、组件源码；
> t4 打包复核期间未重写 `wisdomdesign/dist`。
>
> 注：package.py 级强制重算不在本任务允许写路径（`wisdomdesign/tools/ai-skill/**` 仅 CI 接线）；provider validator 已实现证据重算，并登记“打包前运行”责任与 CI 豁免，见 `CI-INTEGRATION.md`。

## 修复项与落点

| ID | 修复 | 文件 |
| --- | --- | --- |
| F1 high | 33 卡移除未声明的 `iosLabel`（schema `additionalProperties:false`）；标签信息迁移到允许字段 `limitations`（"iOS label mapping: …"），精确标签保留在 `signature`；生成器不再输出该属性；validator 改为对 provider/capabilities/每张卡执行完整 schema 子集校验 + index==磁盘==精确计数 | `api-cards/generate_api_cards.py`、`api-cards/*.json`、`validate_provider.py` |
| F2 medium | 新增证据重算：`derive_effective_status()` 由卡片 evidence、capabilities evidence、verification 命令/矩阵/unverified 推导 effective，并与 `provider.json` 的 effective/declared/computedAtBuild 断言；`verification.statusComputation` 记录命令/时间/输入；CI 无法跨仓访问 iOS，登记为 `exempt-registered`（`CI-INTEGRATION.md`） | `validate_provider.py`、`provider.json`、`verification.json`、`CI-INTEGRATION.md` |
| F3 medium | typecheck 命令改为 cwd=`.` 下可直接运行（全部 `iOS/...` 根相对 + `-I iOS/.build/...`）；实测 rc=0；README/verification 统一为 4 个源文件 | `verification.json`、`AIStarter/README.md` |
| F4 medium | 卡片次引用改为可解析的 JSON pointer `SOURCES.json#/baseline/apiSnapshotSha256`；3 处 `verification.json#ios-minimal-compile` 改为 `#ios-minimal-typecheck`；validator 增加引用解析检查（文件存在 + pointer/command id） | `generate_api_cards.py`、`provider.json`、`capabilities.json`、`validate_provider.py` |
| F5 low | GoldenPageMatrixReport / README 补齐最终 PTY attempt（CE28D919、exit 65、xcresult、0 断言），并保留修复前两次构建失败为历史 | `AIStarter/GoldenPageMatrixReport.json`、`AIStarter/README.md` |
| F6 low | 明确标 stale：`verification.snapshot` + `SOURCES.baseline` 记录 baseline c3c32f3/API 123136bd → HEAD 64539fe/API 1d3be9d7；卡片按基线快照重放（exit 0，逐字节一致）；dist 只读审计记录在 `verification.distAudit` 与 `SNAPSHOT.md`（不重写 dist） | `verification.json`、`SOURCES.json`、`SNAPSHOT.md` |
| F7 low | `GoldenPageMatrixTests` 从 `bundle.unit-test` 改为 `bundle.ui-testing`，补 `TEST_TARGET_NAME=AIStarter` 与 app target 依赖；实测构建产出 `GoldenPageMatrixTests-Runner.app`（仍因沙箱 PTY blocked） | `AIStarter.xcodeproj/project.pbxproj`、`verification.json`（uiMatrixTarget） |
| F8 low | 声明 API 卡覆盖 10/37 目录组件（+5 Foundation 入口）：`verification.apiCardCoverage` 与 `capabilities.componentCoverage`；validator 与 catalog 交叉校验 | `verification.json`、`capabilities.json`、`validate_provider.py` |

## 重跑命令与退出码（2026-11-22）

| 命令 | 退出码 |
| --- | --- |
| `python3 iOS/ai/skill-provider/validate_provider.py` | 0（33 cards, recomputed experimental, snapshot stale, coverage 10/37） |
| `node` + 仓库 schema-lite 校验 33 卡 | 0；invalid cards = 0 |
| 生成器重放（`--api` = c3c32f3 基线快照，`--out` 临时目录） | 0；与仓库卡 `diff -r` = 0 |
| 生成器对当前 HEAD API | 1（预期：防漂移 pin 拒绝，提示 SNAPSHOT.md） |
| Release `xcodebuild build`（verification.json #1） | 0 / BUILD SUCCEEDED |
| `swiftc -typecheck`（verification.json #2，cwd=根） | 0（4 源文件） |
| 脚手架合法复制 / 覆盖 / 逃逸 / symlink / 非法输入 | 0 / 1 / 1 / 1 / 1（合法复制逐字节相同） |
| UI matrix `xcodebuild test`（UI-testing target） | 65（构建成功产出 Runner；test runner PTY blocked，0 断言） |
| validator 负例：注入 iosLabel / effective=verified / 悬空 ref | 均 1（并已恢复） |

## 边界

- `git status` 仍只有预先存在的 `.gitignore` tracked 变更；`Sources/**`、`Tests/**`、`api/WisdomUI.api.json` 零 diff；5 个基线 dirty 文件哈希未变。
- `wisdomdesign/dist/**` 未修改；dist 中 `apiCardFiles=35`、sources.ios.commit=64539fe 与旧 provider 的差异记录在 `verification.distAudit` / `SNAPSHOT.md`，留给流水线负责人（t4 结束后）处理。
