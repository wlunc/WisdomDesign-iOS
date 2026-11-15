# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 的结构；版本号遵循语义化版本。
**三层版本台账**（`docs/DEV-PLAN.md` §10）：① 令牌数据（设计仓生成物）② 契约（`contracts/`）
③ **库**（本文件）。三者不一致时**先对齐再发版**。

## [Unreleased]

### Added

- **B9 行为欠账（2026-11-15；API 零变化）**：`WDCheckbox` 选中光晕（`brand` 42% → 透明，
  400ms 一次，Reduce Motion / 禁用 / 半选不播）；`WDSwitch` 支持拖动滑块实时跟随、松手吸附、
  按下 1.06、轨道 260ms 线性 / 滑块 300ms 精确曲线；`WDToast` 旋转/分屏后按新 bounds 与安全区
  重排；`WDListRow` 尾部徽标文本并入整行朗读（徽标仍不独立进焦点）。**API 1290 零变化**；
  206 tests / 360 张快照零漂移；demo 18 条 UITest 全绿。**残留**：Checkbox 光晕观感与
  Switch 拖动/ScrollView 竞争需真机确认；Toast 悬停仍待真机；ListRow 朗读需 VoiceOver 实测。

- **B8 实现欠账（2026-11-15；授权扩公开）**：`WDIconButton` 新增 `WDIconButtonShape`
  （circle / roundedSquare，radius.sm）与 shape 重载；`WDCheckbox` 新增无标签重载（仅方框 +
  必填 accessibilityLabel，用于表头全选）；`WDDatePicker` 单日期早于今天时文字改用
  `status.danger`（范围 / `.time` 不套用）。**API 1285 → 1290（+5）**；`iconbutton-*`、
  `checkbox-*`、`datepicker-*` 各 8 张重录。契约已同步 IconButton/Checkbox 两个 yaml。
  **残留**：IconButton lg 方形视觉复核、Checkbox 光晕/无标签朗读实测、DatePicker 跨午夜不自动翻转、
  读屏未播报“已过期”。

- **B7 实现欠账（2026-11-15；授权扩公开）**：`WDCard` 新增可点卡（按下亮度 96%、instant、
  禁用 40%、button 语义）；`WDCheckbox` / `WDRadio` 新增紧凑档（22px 方框/外圆，标签 footnote）；
  `WDFAB` 展开时读屏焦点移入第一个子操作。**API 1276 → 1285（+9）**；`checkbox-*`、`card-*`、
  `radio-*` 各 8 张扩展重录。契约已同步 Checkbox/Radio/Card 三个 yaml。**残留**：Card media、
  Checkbox 光晕/无标签、Radio 角色、FAB 遮罩/滚动/安全区、可点卡嵌套子元素约束。

- **`WDDatePicker` 范围 + 清除（2026-11-15，B6；授权扩公开）**：新增范围重载
  `init(range:label:placeholder:in:showsClearButton:clearAccessibilityLabel:)`（仅日期模式）与
  单日期清除重载；范围两步选择（起点→终点，往前点重开），同年“月日 – 月日”、跨年带年份，
  跟随系统区域格式；清除仅在提供标签时渲染。**API 1274 → 1276（+2）**；`datepicker-*`
  8 张扩展重录。**残留**：范围+时间、范围中点视觉、清除回调、过期色。契约增量见
  `docs/B6-CONTRACT-CHANGE-REQUEST.md`；已落库设计仓（2026-11-15）。

- **`WDSwitch` 紧凑档 + 描述位（2026-11-15，B5；授权扩公开）**：新增公开 `WDSwitchSize`
  （standard 51×31 / compact 40×24，滑块 27/20、行程 20/16）与
  `init(isOn:label:description:size:)`；既有 `init(isOn:label:)` 保留。描述位在标签下方一行
  footnote / text.secondary。**API 1270 → 1274（+4）**；`switch-*` 8 张扩展重录。
  **残留**：拖动滑块/松手吸附、写入失败回弹、聚焦光环、精确 260/300ms 曲线。
  契约增量见 `docs/B5-CONTRACT-CHANGE-REQUEST.md`；已落库设计仓（2026-11-15）。

- **`WDIconButton` 五变体（2026-11-15，B4；授权扩公开）**：`WDIconButtonVariant` 新增
  filled / tonal / glass / outline（既有 plain 不变），按下缩放 0.97、禁用 40%。**对比度优先**：
  filled 用 `text.brand` 实底 + 浅色白 / 深色 `text.on-light-primary`（设计 `gradient.mid` + 白
  仅 2.51:1，不达图形 3:1）。**API 1266 → 1270（+4）**；`iconbutton-*` 8 张扩展重录。
  **残留**：圆角方形形态、聚焦光环、长按提示、加载态语义。契约增量见
  `docs/B4-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDCard` sunken + `WDDivider` 内缩（2026-11-15，B3；授权扩公开）**：`WDCardStyle` 新增
  `.sunken`（`surface.card-sunken`、无描边、无阴影）；`WDDivider` 新增 `WDDividerStyle`
  （full / inset，内缩起点 62）与 `init(style:)`，既有 `init()` 保留。**API 1261 → 1266（+5）**。
  `card-*`、`divider-*` 各 8 张扩展重录（总 **360**）。**残留**：Card 的 media 变体与可点卡。
  契约增量见 `docs/B3-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDAvatar` 五档 / 在线 / 停用（2026-11-15，B2；授权扩公开）**：新增公开 `WDAvatarSize`
  （xs 20 / sm 28 / md 32 / lg 40 / xl 56，首字号 9/11/12/14/18）与
  `init(value:size:isOnline:isDisabled:)`；既有 `init(value:)`（md 32）不变。在线点 10×10 +
  2pt 描边，停用整体 50% 去饱和；图标档按直径近似（xs/sm 16、md 20、lg/xl 24，已登记）。
  **API 1254 → 1261（+7）**。`avatar-*` 8 张扩展重录，受字号/图标档影响的 `avatarstack-*`、
  `assigneepicker-*` 各 8 张同步重录（总 **360**）。**残留**：成员四色底色（缺 token）、照片形态、
  在线状态读屏措辞（L-B）。契约增量见 `docs/B2-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDBadge` 六种状态变体（2026-11-14，B1；项目负责人授权扩公开）**：新增公开 `WDBadgeVariant`
  （shared / schedule / pending / success / warning / danger）与 `init(label:variant:)`；既有
  `init(label:)` / `init(value:)`、计数/圆点形态不变，**API 1246 → 1254（+8）**。**对比度优先**（DF-04）：
  soft 变体文字统一 `text.on-soft`（原 status 色 success 4.32 / danger 3.94 不达 4.5）；schedule 改
  `status.info` 实底（原 `gradient.mid` 白字仅 2.51–4.23），浅色白 / 深色 `text.on-light-primary`。
  新增 8 张 `badge-variants-*` 基线（总 **360**）+ 2 条单测（六态/高度、6×2 对比度）。契约增量见
  `docs/B1-CONTRACT-CHANGE-REQUEST.md`（已于 2026-11-15 落库设计仓）。

- **`WDSlider` 自绘载体 + 交互补齐（2026-11-14，B 类遗留）**：手势/读屏改由 Internal `UISlider` 承载
  （系统拖拽、键盘方向键、读屏可调整语义；避免自造 `DragGesture`），视觉改 SwiftUI 覆盖层——轨道 6pt
  （`border.hairline-strong`）、填充 `gradient.mid`、手柄 26（白 + 1pt hairline + `elevation.1`）、两端内缩
  13、拖拽 1.15（100ms）、禁用 45%、RTL 自动镜像；热区 44、最小宽 120 不变。**交互**：点击轨道按触点
  换算目标值并做 200ms 过渡（Reduce Motion 瞬移）；松手按 `step` 吸附；拖到端点改 `rigid` 触觉
  （同一次操作仍只抖一次）。**公开签名零变化**（API 1246 符号零 diff）；`slider-*` **8 张快照基线重录**、
  manifest 哈希同步；新增 2 条结构断言（吸附/热区 + 点击换算 LTR/RTL；PR **166 tests**）。
  **残留**：聚焦光环、数值标签跟随、范围双手柄（后两者需签名扩展）；带刻度 = `step` 吸附（画廊无可见刻度点）。
  demo 新增 `testSliderTapJumps`（点 15% 位置后值必须变化）；完整 demo 套件 **15 条 / 220.88 s** 全绿。

- **`WDAlert` 焦点归还（2026-11-14，B 类遗留）**：出现前用 `UIAccessibility.focusedElement` 捕获当前读屏
  焦点元素，关闭后用 `.layoutChanged` 归还；不改公开签名（无需公开 `WDA11yFocusID` 构造器）。
  真机 VoiceOver 人审仍【未验证】。

- **`WDToast` 窗口层 + 悬停暂停 + 上滑关闭（2026-11-14，B 类遗留）**：浮层改挂 Top VC 的 view（只占
  自身尺寸，不拦截页面其余触摸；解决局部容器裁切，设计 28 §11）。指针悬停时冻结倒计时、移出后按
  剩余时间恢复（`ContinuousClock` 截止时刻 + task 重启，不新增自建计时器）；上滑（最小 10 / 阈值
  16）立即关闭；停留下限仍为纯提示 3s / 带操作 5s。公开签名零变化。demo 新增上滑 / 自动消失 /
  非阻塞 3 条用例，完整套件 **18 条 / 265.44 s** 全绿。**未验证**：模拟器无指针悬停，暂停未人审；
  旋转期间不重排浮层 frame（生命周期短，未处理）。

- **`WDAssigneePicker` 视觉对齐设计 37 画廊（2026-11-14，用户复核）**：未指派改 **52 虚线圈 +
  `person.fill.xmark`**（图标契约 `icons.json` 的 iOS 映射由 `person.crop.circle.badge.xmark` 修正；
  Android 仍 `person_off`）；选中环按 **52 槽 2pt**、头像**静止 1.0**（选中只做 200ms 弹到 1.05 后回弹，
  原 1.05 常驻是错误），圈内间隙 **4**；项槽间距 **12**；选中名字品牌色 + 600。
  重录 AssigneePicker **8 张** + WDAvatar **8 张**基线（未指派图标变更）。

- **`WDProgressBar` 补齐设计 15（2026-11-14，用户指出缺口）**：新增**分段变体**
  `init(segments:completed:label:valueText:)`（n 段表示 n 项完成几项，段间距 2，全完成换成功色）；
  并补齐此前登记/未实现的设计项——**不确定态超过 1 秒才出现**、**禁用整体 45%**、
  **完成 300ms 过渡**、**首次出现 3200ms 缓出**、以及 **progressbar 无障碍语义**
  （`accessibilityRepresentation` 借 `ProgressView` 提供角色/当前值；不确定态不给 valuenow）。
  新增 1 条结构断言；API 基线 1245 → **1246 符号（+1，无移除）**；契约 `contracts/WDProgressBar.yaml` 补
  `segments`/`completed`。分段填充用品牌色（沿用 M4 的对比度改判）。

- **M6 场景组件 `WDAssigneePicker`（指派选择）**（2026-11-14）：头像横排 **40**（紧凑 **32**）、
  选中外环外径 **52**（紧凑 44）、最多直接显示 **6** 个 + `+n`；**单选**
  `selection: Binding<String?>` 与 **多选** `selection: Binding<Set<String>>` 两个 init
  （编译期分离，同 `WDChip` 口径）；「未指派」内置虚拟项（`WDAssigneePickerUnassigned`，
  点它清空选择）；已离开成员 `isEnabled: false` + `unavailableReason`（40% 去饱和、仍进无障碍树）；
  `positionText: ((Int, Int) -> Text)?` 给「第 n 项，共 m 项」措辞（L-B 零文案）；
  溢出展开由 `onOverflowTap` 交给调用方（库不自弹面板）。签名冻结 =
  `docs/M6-SIGNATURE-FREEZE.md`；契约 `contracts/WDAssigneePicker.yaml`；API 基线
  **1212 → 1245 符号（+33）**无移除。
- **M6 快照与 demo**：`WDAssigneePicker` **8 张新基线**（总 **344**）；demo 组件目录扩到
  **37 件**（新增 M6 详情页：单选 + 未指派 / 多选 / 紧凑 / 溢出 / 整体禁用），审计视口加入
  AssigneePicker 代表实例。

- **`WDCheckbox` 半选态**（2026-11-14，用户裁决；设计 06 §5）：新增 `isIndeterminate: Bool = false`
  （additive、源码兼容；不改受控值类型）。视觉 = 同已选底 + **12×2.4 白色横杠**；点半选 → 变全选
  （不做三态循环）；demo（静态 + 可交互两例）/previews/快照均补半选；API 基线 `WDCheckbox.init` 更新。
  半选朗读文案仍属调用方（L-B 零文案，需要时外层加 `.accessibilityValue(_:)`）。
  契约 `contracts/WDCheckbox.yaml` 已补 `indeterminate`（2026-11-14）；Android 侧 C-15 副本同步
  （新增默认参数 = 二进制不兼容 ⇒ 走重载/major）。

- **M5 十五件落地（导航与表单）**：`WDSearchField`、`WDRadio`、`WDSlider`（原生 Slider 载体）、
  `WDStepper`、`WDChip`（展示/可选/可删除三个 init）、`WDAvatarStack`（max 4 + 溢出计数）、
  `WDSegmentedControl`（38 高 + 弹簧指示块）、`WDPicker`（系统 Menu + wheel）、
  `WDDatePicker`（自建月历 + 系统时间滚轮 + 快捷 Chip + min/max）、`WDFormRow`（AX 自动上下排布）、
  `WDPullRefresh`（系统 .refreshable + 读屏刷新操作）、`WDNavigationBar`、`WDTabBar`（深色自动不透明）、
  `WDToolbar`（>7 项收进更多）、`WDFAB`（可展开）。同一批把 `WDBadge` 扩了 `count`/`dot` 两种值形态
  （只增不改，闭合 M2 延后项⑤）。
- **M5 快照与 demo**：15 件 × 8 态 + Badge 计数/圆点 = **128 张新基线**（总 **336**）；
  demo 组件目录扩到 **36 件**（M5 详情页含档位/状态/设置，13 件可切枚举），审计视口加入 M5 代表实例。
- **M5 契约回填（设计仓 `contracts/`，15 个 yaml）**：params / slots / default + 枚举全量 case；
  `WDBadge.yaml` 增量记录 count/dot 值形态。
- **M4 九件落地（反馈与弹层）**：`WDBottomSheet`（窗口级自绘贴边面板 + half/large 档位）、`WDActionSheet`、
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

- **`WDButton` 填充/柔色对齐画廊 01**（2026-11-14，用户裁决）：`tonal` 底由 `surface.tint`
  改为 **`gradient.surface`**（与画廊 `.wd-btn.tonal` 的 `--g-surface` 一致）；`filled` / `tonal`
  补 **1px 顶部内高光**（画廊 `inset 0 1px 0`；令牌 `border.glass-top` 全值，浅色 .8 更接近真机可见度）；
  按钮 8 态快照基线重录。设计仓已同步（2026-11-14）：`design/preview` 的 tonal 改渐变、
  `docs/specs/01-basic.md` / `contracts/WDButton.yaml` / `contrast.json` 回填；
  `Chip 已选` / `Badge shared` 仍走 `surface.tint`（Button 单点例外）。

- **勾的绘制按设计稿重做**（2026-11-14，用户裁决）：`WDCheckbox` 的勾改为**2.2pt、rotate(42°) 的 5×10 L**
  （与画廊 06 的 `border-right + border-bottom` 同形，butt 端、miter 角），`WDPicker` 菜单勾改为
  画廊 22 的 **lucide check**（16pt / 24 viewBox / round cap+join，线宽 2 × 16/24）；
  对应快照基线重录：`checkbox` 8 态 + `listrow` 8 态（后者含 `.checkbox` 前导槽）。

- **`WDPicker` 按设计 22 全量对齐**（2026-11-14，用户裁决「完全按照设计稿」）：菜单形态从系统 `Menu`
  改为**窗口级自绘浮层**——圆角 14 / 选项行 44 / 最小宽 180 / 最大宽 = 屏宽 − 32 / 与入口间距 4 /
  空间不足自动翻转 / 当前项打勾并滚到可视区中间、选中行 = brand 10% 底 + brand 字 + 600（画廊 22 `.sel`）/
  遮罩与硬件键盘 Esc 关闭且不提交 /
  `motion.spring.gentle` 入场 + 160ms 淡出；分组标题 `type.overline`、组内选项缩进 `space.5`；
  滚轮形态保持系统 `Picker(.wheel)`（设计 22 §11 的平台差异条款）；新增 `.inline` 内联形态
  （≤ 8 项直接平铺）；触发入口箭头由 `chevron.right` 改为 **`chevron.down`**（设计 22 §2）。
  同步：picker 8 态快照基线重录、API 基线 +1 case、demo/previews 补内联样例。

- **BottomSheet 长内容滚动冲突**：内容可滚动时只观察 `UIScrollView` 既有 pan，不再叠加第二套手势；
  不可滚动时才补并行 pan，保证短内容也能从内容区下拉关闭。新增长内容 UI 测试
  （内部滚动到列表末项、关闭键位置不变）。
- **ActionSheet / BottomSheet 跟随宿主题**：窗口级 presenter 继承调用方的 `wdTheme` 与 `colorScheme`
  （hosting controller 注入主题 + `overrideUserInterfaceStyle`）；dark scheme 下遮罩、列表卡、取消卡、
  面板、文字都切到深色。新增 dark scheme UI 测试。
- **demo 组合场景**：新增「组合场景」入口——卡片容器（`WDCard` + Avatar/Badge/Progress/Switch/ListSection/Button）
  与底部面板容器（`WDBottomSheet` + TextField/Card/Switch/Checkbox/Progress/固定页脚）；
  目录页展示 21 件组件 + 2 个场景，新增组合场景 UI 测试与截图。
- **`WDBottomSheet` 按设计 26 补齐并改自绘贴边**：标题 `title3`、头部 56；内容 `ScrollView` + 12
  顶距；底部操作区固定、1pt 分割线、高 72、右对齐；面板左右/底部贴屏幕、顶部 32 圆角、把手 36×5；
  half/large 档位、把手拖拽/点击切换、下滑关闭、点遮罩关闭、键盘上移；焦点归还（layoutChanged）
  与 VoiceOver `.escape` 动作；键盘避让有 UI 测试（字段在键盘上方）；内容滚到顶后下拉经
  UIScrollView 桥接拖动面板（有 UI 测试）。8 态基线重录。
- **`WDActionSheet` 按设计 27 参考重排**：左右 16 内距；标题/说明移入列表卡片顶部（caption1 /
  text.secondary + 底部分隔线）；行左对齐、可选 20pt 前置图标；取消为独立 48pt **圆角卡片**
  （18 圆角、semibold、e2 阴影）；破坏性项置底。呈现改为 **窗口级 presenter + 自绘遮罩**：
  透明背景、无系统 sheet 半透明边框；**遮罩静态出现，面板单独滑入/滑出**；点遮罩 = 取消。8 态基线重录。
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

- **`WDIconButtonVariant` 新增 4 个 case**（pre-1.0 源级 breaking，2026-11-15；设计 02 §4）：
  按 F-20，新增枚举 case 属源级 breaking（minor + 本段 + 迁移片段）。迁移 = 一般无需改代码；
  仅当调用方对该枚举做**穷举 `switch`** 时补 filled/tonal/glass/outline 分支。
  契约 `contracts/WDIconButton.yaml` 的 enums 需同步为 `[plain, filled, tonal, glass, outline]`
  （见 `docs/B4-CONTRACT-CHANGE-REQUEST.md`）。

- **`WDCardStyle` 新增 `.sunken`**（pre-1.0 源级 breaking，2026-11-15；设计 17 §4 的第四档）：
  按 F-20，新增枚举 case 属源级 breaking（minor + 本段 + 迁移片段）。迁移 = 一般无需改代码；
  仅当调用方对 `WDCardStyle` 做**穷举 `switch`** 时补一个 `.sunken` 分支。
  契约 `contracts/WDCard.yaml` 的 `enums.WDCardStyle` 需同步为 `[elevated, outlined, glass, sunken]`
  （见 `docs/B3-CONTRACT-CHANGE-REQUEST.md`）。

- **`WDPickerStyle` 新增 `.inline`**（pre-1.0 源级 breaking，2026-11-14；设计 22 §4 的三形态要求）：
  按 F-20，新增枚举 case 属源级 breaking（minor + 本段 + 迁移片段）。迁移 = 一般无需改代码；
  仅当调用方对 `WDPickerStyle` 做**穷举 `switch`** 时补一个 `.inline` 分支。
  契约 `contracts/WDPicker.yaml` 的 `enums.WDPickerStyle` 已同步为 `[menu, wheel, inline]`（2026-11-14）；
  Android 侧 C-15 副本同步为 `WDPickerStyle{Menu, Wheel, Inline}`。

- **`WDPullToRefresh` → `WDPullRefresh`**（pre-1.0 源级 breaking，2026-11-13；用户裁决）：
  公开类型与修饰符 `.wdPullToRefresh` → `.wdPullRefresh`；契约 yaml 同名更新；
  **Android 侧契约名待同步**（C-15 #32，android-lead）。迁移 = 全局替换两个标识符。
- `WDTextStyle.init(size:lineHeight:weight:)` **移除**（改为 `internal` 的 4 参数构造器）。
  本仓尚无消费方；迁移 = **不要自行构造字阶**，改用 `WDType.*` 常量。
- 其余无公开签名移除。本轮 API 基线变化：**+136 / −1**（`api/WisdomUI.api.json` 必须与成因**同一提交**）。

### Fixed

- **快照稳定性与 demo 对比度审计误判**（2026-11-14 复核）：`WDDatePicker` 快照改用固定 `Date`
  （UTC / `zh_CN`），消除跨日与 RTL 漂移；`WDButton` 的 1pt 顶部高光从独立 overlay 移入
  `background` 层，视觉不变，但不再被 `performAccessibilityAudit(.contrast)` 当成按钮背景
  （`提交` 的深色对比度曾被误判；移入背景层后 demo 13 条 UITest 全绿）。

- **`WDPullRefresh` 指示器与设计 32 不符**（2026-11-14，用户裁决）：原系统 `.refreshable` 的
  旋转 spinner 与设计稿的 24pt 品牌环不一致。iOS 18+ 改为自绘：24pt 环 / 2pt 线宽 /
  阈值 64 / 最大下拉 120 / 下拉随位移画进度 / 刷新中品牌弧 1s 线性旋转 / 完成后 160ms 收起 /
  到阈值一次 `.medium` 触觉 / Reduce Motion 静态弧；指示器覆盖在列表顶部、保持释放位置且不改变
  锚点高度；iOS 17 回退系统 `.refreshable`（登记差异）。三态文案不进库（L-B 零文案），
  组件实现设计 32 §4 的「极简」变体（只有环）；公开签名与 `api/WisdomUI.api.json` **零 diff**。
  新增单测 7 条 + demo XCUITest 1 条（下拉→计数 +1，含刷新中/完成截图）。契约 yaml 的载体注释
  已同步（`../wisdomdesign/contracts/WDPullRefresh.yaml`，2026-11-14）。

- **`WDSegmentedControl` 选中指示块不显示 / 详情页被拉满高度**（2026-11-13）：原用
  `GeometryReader` 背景量测段宽，首帧/快照/真机首屏可能拿到 0 宽 ⇒ 只剩字重差异；改为自定义
  `Layout` 直接等分并定位指示块（高度恒为内容高 32，忽略父级提出的高度，避免 demo 详情页被拉满），
  同时补上禁用态 40% 不透明度。8 张基线同步重录。
- **`WDTabBar` 图标整体偏上**（2026-11-13）：单行标签此前用 `wdLineBox(..., lines: 2)` 预留了两行行盒，
  图标/标签/圆点被顶到容器顶部；改为单行行盒 + `lineLimit(2)`，单行时垂直居中、两行时自然增高。
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