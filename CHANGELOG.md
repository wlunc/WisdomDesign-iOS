# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 的结构；版本号遵循语义化版本。
**三层版本台账**（`docs/DEV-PLAN.md` §10）：① 令牌数据（设计仓生成物）② 契约（`contracts/`）
③ **库**（本文件）。三者不一致时**先对齐再发版**。

## [Unreleased]

### Added

- **M4 九件落地（反馈与弹层）**：`WDBottomSheet`（系统 sheet + half/large 档位）、`WDActionSheet`、
  `WDAlert`（270 卡片 + 带输入重载 + screenChanged 焦点移入）、`WDToast`（组件内 .task 计时）、
  `WDBanner`（3 变体 + 软底渐变）、`WDEmptyState`、`WDSkeleton`（text/list/card + 2200ms 微光）、
  `WDProgressBar`、`WDProgressRing`。冒烟段的 sheet/actionSheet 声明同 PR 退役；
  `WDHaptics` 增加 success 种类（进度 100%）。
- **M4 快照与 demo**：9 件 × 8 态 = **72 张新基线**（总 **208**）；demo 组件目录扩到 **21 件**，
  弹层从详情页触发，审计视口加入进度条/环、Banner、EmptyState、Skeleton；3 条 UITest 全过。
- **M4 对比度账目**：设计仓 `contracts/contrast.json`（light/dark 34 对 + 玻璃禁止对）；
  ProgressBar 填充因 `gradient.mid` 浅端仅 2.02:1 改为品牌色渐变（3.91:1 / 6.71:1）。
- **`WDListSection` 六类断言收尾（M3）**：清掉 `DRAFT` 注释；新增 `WDListSectionSnapshotTests`——
  **4 变体（标准 / 标题动作 / 带页脚 / 空组）× 8 态 = 32 张基线**（空组应只有空白）；
  demo 组件目录新增 `WDListSection` 条目与实时预览，审计视口扩到 **12 件**（M2 11 + M3 1）。
- **M3 公开 API 封板**：`api/WisdomUI.api.json` 入库且 `dump-api` **零 diff（661 符号）**；
  记录 = `docs/M3-API-FREEZE.md`（SHA-256、工具链、复跑命令与封板口径）。
- **M3 契约回填（设计仓 `contracts/`，12 个 yaml）**：M2 的 11 件 + `WDListSection`；
  `params`（受控值取 C-15 canonical）/ `slots`（21 名词表子集或「无」）/ `default` + 枚举全量 case。
  回填 = 誊录，不改签名/默认值/槽位/枚举（设计仓提交 `feat(contracts): M2/M3 契约条目回填`）。
- **M3 覆盖率门槛**：`Scripts/ci.sh pr` 的覆盖率阶段由「只打印」改为**硬门槛**——
  `Foundation/**`（排除 `generated/`）**≥ 80%** 才绿；本次实测 **97.73%（603/617）**。
- **API 基线随 M4 九件更新**：`api/WisdomUI.api.json` **661 → 860 符号（+199）**；无移除。
- **M3 结构门禁转严格（`--strict`）**：按 SPEC §1.1.2/§1.5.5，M3 起 R7/R15/R21 的 warning 转拦；
  PR-0 改为 `check-structure.sh --strict`。清理：`WDIconButton` 三档视觉尺寸改用
  `WDSize.controlSm/Md/Lg` 令牌；其余 10 处数值字面量（WCAG 公式、十六进制解码、DF-03 配额、
  热区补量）与 2 处文本容器按规则**同行带理由豁免**；结果 **0 warning / 51 suppressed**。
- **M3 归档体积门槛（E3-iOS-a）**：同构消费方与分母各归档 3 次，3 次完全相同
  （BaselineShell 86,016 B / 消费方 581,632 B）——增量 P50 = **495,616 B（≈484 KB）**，
  门槛 = `P50 × 1.10` = **545,178 B（≈532 KB）**，
  按增量表达；写入 `README.md` / `docs/U09-SIZE-BASELINE.md` §6。Thinning 增量仍【未验证】（M6 发布前层）。
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
- **`WDListSection`（M3）**：数据驱动的列表分组（`items`/`selection`/`header`/
  `headerAction`/`footer`）；空集合自动隐藏整组、末行通过 `WDListSectionRowContext.isLast`
  交给行自己关分隔线；7 条单测（空组/末行/选中/密度/页脚/动作热区）+ 2 个预览。
  签名冻结 = `docs/M3-SIGNATURE-FREEZE.md`（2026-11-12 按建议确认；7 条单测 + 2 预览）。
- **E3-iOS-a 同构消费方壳**（2026-11-11）：新增
  `Examples/BaselineShellWithLibrary`（与 `BaselineShell` 同构、行改用 `WDListRow`）；
  首次成对归档（未 Thinning，Release）：baseline 86,016 B / 本壳 561,152 B，增量 **475,136 B ≈ 464 KB**。
- **demo 组件目录改版**（2026-11-10）：主入口从"所有组件堆在一个页签"改为按用途分组的组件目录
  （操作 / 输入与选择 / 内容展示 / 布局与结构，覆盖 11 件 primitives）；点击进入详情页，
  提供实时预览、档位/状态与实现细节；带枚举的 6 件组件在详情右上角提供"设置"切换，
  关闭设置后预览显示新配置。主题与令牌、无障碍审计视口迁到目录右上角的调色板入口；
  UITest 增加目录导航 + 枚举切换断言，审计例外补"已完成 2 项"（列表行单行截断，设计 18 §7）。
- **demo 组件审计视口**（2026-11-10）：`Examples/WisdomUIDemo` 增加"组件"页签（11 件代表性实例）；
  页签用**分段控件**而非 `TabView`——iOS 26 的浮动玻璃 Tab 栏会压住滚动内容，令对比度审计误判。
  demo UITest 对两个页签分别跑 contrast / hitRegion / textClipped / dynamicType；6 条窄例外
  （头像首字/徽标固定字号 ×3、列表行单行截断 ×3）在测试里**逐条点名并打印理由**，其余仍严格失败。
- **M2 组件（收尾）**：`WDButton`（6 变体 × 3 尺寸；按下 0.97 + 轻触觉；加载态宽度不变、
  标签留在无障碍树且 `loadingAccessibilityText` 必填；公开 `WDButtonStyle` + `.wdFilled` / `.wd(_:size:)`；
  `filled`/`destructive` 用渐变 + brand 阴影，`glass` 走 `WDGlass.resolve` + iOS 26 `glassEffect`）
  与 `WDListRow`（行高 44/60/76 = `max(密度下限, 槽位派生)`；前导 5 种 / 尾部 5 种；选中 3pt 品牌条 +
  8% 底；分隔线按 62 内缩；可点行走真 `Button` + pressed 底；左滑删除 + 自定义无障碍删除操作）。
  冻结签名差异（按钮字号档/聚焦光环、行的徽标朗读合并/selectionIndicator 语义）登记
  `docs/DEV-PLAN.md` §2.3；组件测试 6 条 + 两件 8 态快照（16 张基线）。**M2 11/11 代码全部落地**。
- **M2 组件（续四）**：`WDCheckbox`（方框 26 / 圆角 9 / 勾用描边路径；两态；切换轻触觉 ×1）、
  `WDCard`（elevated / outlined / glass 三档；内距 16 固定、圆角 24；玻璃走 `WDGlass.resolve` +
  iOS 26 `glassEffect`、17–25 纯色降级）、`WDIconButton`（plain 档；sm 32 / md 44 / lg 52 视觉、
  **热区恒 44**；无障碍标签必填）。冻结签名差异（Checkbox 半选/紧凑档、Card sunken/media/可点卡、
  IconButton 其余四变体）登记 `docs/DEV-PLAN.md` §2.3；组件测试 8 条 + 三件 8 态快照（24 张基线）。
- **Foundation 覆盖率补齐**（2026-11-10）：新增 16 条单测覆盖颜色槽位（32 槽位/补丁构造/
  light↔dark 差异）、令牌基础类型（`WDTextStyle` 四项派生、`WDShadowLayer`、`WGradientSpec`）
  与环境写入口（`wdTheme`/`wdTheme(scheme:)`/`wdColors`/`wdEffectsBudget` 只降不升/`wdDensity`/
  `wdAppearance` 派生）；`Foundation/**`（排除 generated）**67.3% → 97.69%**，M3 的 80% 门槛预达标。
- **基础设施补齐**（2026-11-10；P2 的依赖项）：`WDLayoutDensity` + `wdDensity`（环境只读 +
  唯一写入口；默认 `comfortable`，行高下限 60/44，F44）；`Internal/WDHaptics.swift`
  （可注入 sink + `WDEffectsBudget` 的"一次操作最多一次"闸门；测试用捕获器断言次数，不真的震动）。
- **M2 组件（续三）**：`WDSwitch`（标准档轨道 51×31、滑块 27、行程 20；开 `gradient.mid`、
  关 hairline 描边；整行可点、切换轻触觉 ×1；角色由真 `Toggle` 提供，库内零"开/关"文案）。
  冻结签名无紧凑档/描述位 ⇒ 差异登记 `docs/DEV-PLAN.md` §2.3；组件测试 3 条 + 8 态快照（8 张基线）。
- **M2 组件（续二）**：`WDAvatar` + `WDAvatarValue`（圆底 + 首字/图标；默认 md 32、首字号 12 固定；
  文字形态把 `label` 作为无障碍标签，图标形态是装饰）。冻结签名无 size/ID/在线态/照片参数 ⇒
  五档直径、按成员 ID 固定配色、在线点、停用态不可表达，差异登记在 `docs/DEV-PLAN.md` §2.3；
  组件测试 3 条 + 组件级 8 态快照（8 张基线）。
- **M2 组件（续）**：`WDDivider`（全宽 1pt `border.hairline`、无状态、不进树）与
  `WDBadge` + `WDBadgeValue`（状态胶囊高 24 / 内距 10 / 固定 11pt·600；中性 shared 配色；
  不进入焦点序列）。冻结签名无 variant/计数参数 ⇒ 只实现状态胶囊与全宽档，差异登记在
  `docs/DEV-PLAN.md` §2.3；组件测试 7 条 + 组件级 8 态快照 ×2（16 张基线）。
- **无障碍层落地**（2026-11-10）：`WDSemantics`（`join` / `positional`，零标点、零语序，
  `[String]` 纯逻辑重载按 Android 同口径剔除空串）；`WDAnnouncementPriority` / `WDAnnouncing` /
  `WDSystemAnnouncer`（同步、无 `Task`；`polite` → `PageScrolled`、`assertive` → `Announcement`）；
  `WDAnnouncementThrottle`（进度只向上跨阈值；释放后 1s 节流，数值登记 D-8）；
  `WDA11yFocusID`（`Hashable` 焦点身份）。M0-11 冒烟段的对应声明**同提交退役**；
  测试 9 条（语义渲染等价 / 阈值与节流 / 焦点身份）。
- **M1 基础设施**（2026-10-07 交付）：`wdFont(_:)` 单入口 + 行盒度量（12 档 × 12 字阶 × {en, zh} ×
  {字体级, 渲染级} = **288 条 fixture**）；`WDTheme` / `wdTheme` / `wdColors` 运行时换肤（换已生成的
  scheme，值变更触发重组、**不重启进程**）；三件套 `WDGlass` / `WDEffectsBudget` / `WDContrast` +
  **34 条参数化用例**（含两条"必须红"用例）；`WisdomUIPreviews` 画廊 + `WisdomUISnapshotTests`
  （8 态矩阵、**16 张基线**）；`Examples/WisdomUIDemo`（app + 无障碍审计 UITests）。
- **M2 首批（2/11 组件完成六类断言；2 条登记未闭合）**：`WDTextField`（46pt 字段盒、三变体、
  聚焦/错误/禁用/只读、label/prefix/accessory/helper 四槽位、附件按钮独立可达、密文/计数）与
  `WDIcon` + `WDIconMetrics`（四档 16/20/24/28，**不随动态字体放大**、装饰件不进树）；
  `WDIconName` 生成物（44 条语义名 + SF Symbols 映射，`contracts v1.0.0 · sha256:aab3bb93f508`）；
  组件测试 **10 条**（字段盒 46±1、三态等高、辅助行、最小宽、AX3 生长、计数阈值、AX5 不缩放）、
  `+Previews.swift` ×2、组件级 **8 态快照 ×2（16 张基线）**。未闭合：错误态 assertive 播报（依赖
  `WDAnnouncing` 层）、显隐切换的 selection 位置（iOS 17 走降级路径；见 `docs/DEV-PLAN.md` §2.3）。

### Changed

- **`WDSkeleton` 微光与宽度修复**：微光由旋转色带改为水平 `sourceAtop` 扫光（只落在灰块上，不再出现斜方块）；
  行宽改 `maxWidth` + 固定短行留白，避免 `containerRelativeFrame` 在嵌套 HStack 里把 demo 撑出屏幕；8 态基线重录。
- **`WDBanner` 对齐修复**：HStack 由 top 改 center（图标/文案/操作/关闭键同一垂直中心）；
  文案行盒改 1 行下限（多行自然长高，不再为单行预留两行）；关闭键改 `sm`（视觉 16）。
  8 态 banner 基线重录。
- 生成物目录 `Foundation/Generated/` → `Foundation/generated/`（**纯移动，零内容变化**；
  M0-2 生成器的目标态）。格式清单的排除模式随之写成 `/Foundation/[Gg]enerated/`。
- `Foundation/WDTokenTypes.swift` → `Foundation/Tokens/WDTokenTypes.swift`（纯移动）。
- `WDTextStyle` 改为 **4 存储字段**（新增 `letterSpacing`）、加 `Equatable`、
  构造器按 O-10 转 `internal`；新增派生 `lineHeightRatio`。
- README 的"开发"段改为门禁口径（`Scripts/ci.sh`）+ 预览三限制；补齐 `Examples/` 说明。
- **`WDTextField` 视觉与状态补齐**（2026-11-10）：三变体（`inset`/`outline`/`glass`，玻璃走
  `WDGlass.resolve` 且 iOS 17–25 纯色降级）、聚焦描边+光环、错误描边、禁用 40%、只读下沉底、
  点容器聚焦、错误态 `accessibilityHint`（F22）；组件级 8 态快照改用 `UIHostingController` 渲染器
  （`ImageRenderer` 对 `TextField` 输出全透明，登记 **P17**）。
- **API 基线随 M2 两件回填**：`api/WisdomUI.api.json` **+18 符号**（`WDIcon` 全家、`WDIconSize` 四档、
  `WDTextFieldPrefix.icon`、`WDTextFieldAccessory.clear/reveal`）。按 SPEC §1.5.3，基线变更单独提交
  （`chore(api): …`），**不得**与实现提交混在一次提交里。
- **API 基线随无障碍层更新**：`api/WisdomUI.api.json` **+16 符号**（`WDSemantics`、`WDAnnouncementPriority`、
  `WDAnnouncing`、`WDSystemAnnouncer`、`WDAnnouncementThrottle`、`WDA11yFocusID`）——这些声明原先只在
  冒烟段（被规范化器排除），随实现落地首次进入公开面；无移除。
- **API 基线随 WDBadge/WDDivider 更新**：`api/WisdomUI.api.json` **+22 符号**（`WDBadge`、
  `WDDivider`、`WDBadgeValue` 及其 View 扩展入口）——两件从冒烟段/提案落地后首次进入公开面；
  无移除。
- **API 基线随 WDAvatar 更新**：`api/WisdomUI.api.json` **+13 符号**（`WDAvatar`、`WDAvatarValue`
  及其 View 扩展入口）——从冒烟段落地后首次进入公开面；无移除。
- **API 基线随布局密度/WDSwitch 更新**：`api/WisdomUI.api.json` **+22 符号**（`WDLayoutDensity`、
  `wdDensity` 读写入口、`WDSwitch` 及其 View 扩展入口）；无移除。
- **API 基线随 WDCheckbox/WDCard/WDIconButton 更新**：`api/WisdomUI.api.json` **+43 符号**
  （`WDCheckbox`、`WDCard`/`WDCardStyle`、`WDIconButton`/`WDIconButtonVariant`、`WDButtonSize`
  及其 View 扩展入口）；无移除。
- **`WDListRow` 选中底**：设计 18 的 8% 半透明品牌底会令系统对比度审计按**未合成**背景色计算
  （实测 `text.primary` 不达标）⇒ 改为不透明 `surface.tint`；8 态基线同步重录。
- **API 基线随 WDButton/WDListRow 更新**：`api/WisdomUI.api.json` **+53 符号**（`WDButton` 全家、
  `WDButtonStyle`、`ButtonStyle` 工厂、`WDListRow` 全家及其 View 扩展入口）；无移除 ⇒
  **M2 的 11 件公开面全部进入基线**。

### Breaking

- `WDTextStyle.init(size:lineHeight:weight:)` **移除**（改为 `internal` 的 4 参数构造器）。
  本仓尚无消费方；迁移 = **不要自行构造字阶**，改用 `WDType.*` 常量。
- 其余无公开签名移除。本轮 API 基线变化：**+136 / −1**（`api/WisdomUI.api.json` 必须与成因**同一提交**）。

### Fixed

- **demo 审计夹具**（2026-11-12）：为 theme 页 `launch-count` 的 iOS 26 "Contrast nearly passed"
  告警加一条**点名窄例外**（13pt 文本；实测 text.primary on surface.card 约 16:1，**非 WCAG 失败**；
  同代码复跑 3/3 绿）。`Contrast failed` 仍严格失败，且不扩大到其他元素。

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
