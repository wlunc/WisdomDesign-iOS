# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 的结构；版本号遵循语义化版本。
**三层版本台账**（`docs/DEV-PLAN.md` §10）：① 令牌数据（设计仓生成物）② 契约（`contracts/`）
③ **库**（本文件）。三者不一致时**先对齐再发版**。

## [Unreleased]

### Added

- **令牌流水线落地**：`Sources/WisdomUI/Foundation/generated/{WDTokens,WDTokensVersion,WDColorSlots}.swift`
  （设计仓 `tools/token-build/build.js` 生成；`tokens v1.0.0 · sha256:e552bb87e270`；
  **32 个语义色槽位**（含 `text.disabled`）；`schemes = [light, dark]`）。
- **主题手写层** `Foundation/Theme/WDColorValues.swift`：`WDColorValues`（32 槽位 + 补丁式
  `init(_:)`）、`WDColorOverrides`、`WDColorSlot`（`String` 原始值 +
  `CaseIterable` + `Sendable`，不加 `@frozen`）。
- **结构检查器** R1–R21（`Sources/wd-structure-check/`，host 侧、只依赖 Foundation）+
  固定样本自检（`Scripts/test-checker.sh`，各一正一反）+ 行内豁免语法。
- **跨仓同批自证**：`Scripts/check-structure.sh --tokens-trace`（读设计仓
  `dist/tokens.manifest.json`，断言 `sha12` 与生成物一致；**缺失 = fail**）；
  测试侧入口 `Tests/WisdomUITests/Support/WDContracts.swift`。
- **门禁入口** `Scripts/ci.sh`（`pr` / `nightly` / `measure` / `doctor`）与
  `.github/workflows/ci.yml`；API 冻结链路（`Scripts/dump-api.sh` + `api/WisdomUI.api.json`，
  规范化器丢弃 USR/绝对路径等易漂移字段）。
- **归档体积基线** `Examples/BaselineShell/`（E3-iOS-a 的分母：同构、不引入本库）。
- 协作文件：`CONTRIBUTING.md`、`.github/pull_request_template.md`、`.github/CODEOWNERS`。

### Changed

- 生成物目录 `Foundation/Generated/` → `Foundation/generated/`（**纯移动，零内容变化**；
  M0-2 生成器的目标态）。格式清单的排除模式随之写成 `/Foundation/[Gg]enerated/`。
- `Foundation/WDTokenTypes.swift` → `Foundation/Tokens/WDTokenTypes.swift`（纯移动）。
- `WDTextStyle` 改为 **4 存储字段**（新增 `letterSpacing`）、加 `Equatable`、
  构造器按 O-10 转 `internal`；新增派生 `lineHeightRatio`。
- README 的"开发"段改为门禁口径（`Scripts/ci.sh`）+ 预览三限制；补齐 `Examples/` 说明。

### Breaking

- `WDTextStyle.init(size:lineHeight:weight:)` **移除**（改为 `internal` 的 4 参数构造器）。
  本仓尚无消费方；迁移 = **不要自行构造字阶**，改用 `WDType.*` 常量。
- 其余无公开签名移除。本轮 API 基线变化：**+136 / −1**（`api/WisdomUI.api.json` 必须与成因**同一提交**）。

### Fixed

- **R15 对契约键名的假红**：原实现只要字面量含 L-B 标点就报错，而键名（如 `text.primary`）天然含
  `.` ⇒ 与 SPEC §3.7 的 I41"其余只允许标识符/键名"冲突。加键名形态白名单 + 正例样本
  （`R15_key_name_literal.swift`），反例（`、` 与词序模板）仍必须命中。

### 版本台账（发布时填）

| 层 | 值 | 来源 |
| --- | --- | --- |
| 令牌数据 | `1.0.0`（sha12 `e552bb87e270`） | `../wisdomdesign/dist/tokens.manifest.json` |
| 契约 | 未落库（M0-5 交付） | `../wisdomdesign/contracts/` |
| 库 | 未发布（无 tag） | 本仓 SPM tag |

## 发布 checklist（逐条可勾；口径 = `docs/DEV-PLAN.md` §10）

- [ ] **1. 设计仓冻结并打 tag**；生成器 `--check` 全绿（本端只读消费，不跨仓写）
- [ ] **2. 生成物 + 符号快照与成因同一提交**（`api/WisdomUI.api.json` 不得跨提交漂移）
- [ ] **3. 两端门禁绿**：`Scripts/ci.sh pr` + nightly **连续 3 日绿**
- [ ] **4. 发布前层**：真机 hitch（`scrollDecelerationMetric`）、首帧；归档 Thinning 增量
      （分母 = `Examples/BaselineShell/`）与体积门槛断言（U-09）
- [ ] **5. 双端同 tag** `v1.0.0`（**平台 tag 永远在最后**；tag 前核对三仓 HEAD 与版本台账）
- [ ] **6. 本文件写明 Breaking 段与迁移片段**（若追加/改签名）
- [ ] **7. 打错 tag 不移动不删除** ⇒ 发下一个补丁版本，并在本文件标注"废弃 vX.Y.Z"
