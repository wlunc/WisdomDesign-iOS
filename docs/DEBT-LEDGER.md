# 欠账台账（iOS 端，2026-11-20 盘点）

> **用途**：把散落在 `M2/M4/M5/M6/B10-B16/B17` 各出口报告、`B3-PLATFORM-LIMITS`、`M2-DEVIATIONS` 与代码注释里的欠账**汇成一页**，逐条给证据、严重度与解除条件。
> **口径**：本文件只是**索引 + 现状**，判定真源仍是各出口报告与 `docs/SPEC.md`；冲突时以出口报告为准。
> **纪律**：未跑通/未实测一律写【未验证】，不写「已通过」（`docs/SPEC.md` §8.2）。
> **状态标记**：`✅` = B18 已闭合；`◐` = 部分闭合（代码有了、缺快照或真机）；无标记 = 仍开放。B18 记录见 `docs/B18-EXIT-REPORT.md`。

---

## 0. 全景（按性质分四类）

| 类别 | 条数 | 能不能纯代码推进 |
| --- | --- | --- |
| A · 代码欠账 | 17 | 已闭合 **14 条**（A-1～A-7、A-11、A-12、A-13、A-14、A-15、A-16、A-17，2026-11-21 B21 批闭合 A-11/A-13/A-14）；部分闭合 **3 条**（A-8 缺 `tablist`/`tab` 角色与玻璃档、A-9 缺滚轮形态先选后确认、A-10 真机键盘与极端尺寸未走查）；仍开放 **0 条** |
| B · 契约欠账（要设计仓落库） | 3 | 不能（跨仓只读） |
| C · 验证欠账（要完整环境 / 真机） | 6 | 不能（环境） |
| D · 平台限制（不投入，只登记） | 5 | 不能（系统能力） |

---

## 1. A 类 · 代码欠账

### 1.1 优先处理（**文档声称已交付，代码实际未接线**）

| # | 项 | 证据（2026-11-20 实测） | 影响 | 解除条件 |
| --- | --- | --- | --- | --- |
| A-1 ✅ | **`WDSlider` 焦点光环是死代码** | `WDSlider.swift:48` 读 `\.wdFocusRingFocused`，但全仓 `.wdFocusRing()` **零调用点**（`grep -rn '\.wdFocusRing()' Sources Tests Examples` 只命中注释）。B13 出口写「读屏焦点光环已补」，实际永不显示 | 设计 08 §5 的「聚焦：手柄外扩 3pt」在真机上不存在；B17 出口的 U-B17-3 也依赖它 | 在 `track` 上把 `.wdFocusRing()` 挂到读屏表示层（`accessibilityRepresentation` 的 slider），并补一条「聚焦 → 半径 16」的视图级断言 |
| A-2 ✅ | **`WDSlider` 松手后不播报** | `SPEC.md:942` 要求「**松手后播报一次**」，B13 只做了触觉 + 回调；`WDSlider.swift` 内 `wdAnnouncerText` 零引用（全仓只有 `WDPullRefresh` 读该环境键） | 规格矩阵里 #08 的播报列未实现，且**未登记进任何出口报告** | 加 `announcer`/`valueText` 注入点复用现有 `View.wdAnnouncer(_:)`（L-B：措辞由调用方给），松手时播一次 |

### 1.2 已登记、仍开放的实现差异

| # | 项 | 证据 | 登记处 |
| --- | --- | --- | --- |
| A-3 ✅ | `WDButton` 按下**亮度 96%**、**聚焦光环**、**悬停 98%** 均未实现（只有 0.97 缩放） | `WDButton.swift:173` 仅 `scaleEffect`；`grep brightness|onHover` = 0 | `DEV-PLAN.md:209` ⑫；`M2-DEVIATIONS.md:35`（⑫ 光环「延后到 M5」——**M5 已结束仍未补**） |
| A-4 ✅ | `WDIconButton` 聚焦光环未实现 | `WDIconButton.swift` 只有 0.97 按下 | `B4-CONTRACT-CHANGE-REQUEST.md:24` |
| A-5 ✅ | `WDCheckbox` 按下缩放 **0.90**（设计 06 §5）未实现 | `grep ButtonStyle|isPressed` in `WDCheckbox.swift` = 0（B9 只补了选中光晕） | `M2-DEVIATIONS.md` ⑨；B7/B9 未闭合该项 |
| A-6 ✅ | `WDToolbar` 按钮按下 **0.94 缩放 + `fill.pressed`** 未实现 | `WDToolbar.swift:104` 是 `.buttonStyle(.plain)`，无按下样式 | `M5-EXIT-REPORT.md` §4-⑭ |
| A-7 ✅ | `WDTabBar` **角标未并入宿主朗读**（`accessibilityHidden` 的 `WDBadge` 内容读不到） | `WDTabBar.swift:96` 渲染 badge 无 a11yValue；对比 `WDListRow.swift:101` 已有徽标合并 | `M5-EXIT-REPORT.md` §4-⑬（同 M2 ⑬ 口径） |
| A-8 ◐ | `WDSegmentedControl` 无 `tablist`/`tab` 与位置文案；**不支持段间横向拖动**；玻璃档实为纯色 | **B20（2026-11-20）已补**：段间横向拖动（`DragGesture(minimumDistance: 1)` + 横向占优判定，跟手用 `dragSegmentIndex`、松手吸附走与点击同一条 `commit`）、`WDSemantics.positional` 位置文案（措辞/分隔符由调用方注入）、方向键 ←/→ 即时切换（设计 21 §8）。**仍开放**：`tablist`/`tab` 角色（平台限制 L-3）、玻璃档纯色 | 角色与玻璃档仍登记 |
| A-9 ◐ | `WDPicker` 滚轮形态即时提交（设计指定系统载体）、菜单无键盘环形焦点 | **B20（2026-11-20）已补菜单键盘导航**：方向键环形移动（`WDPickerMenuFocus`，首尾回绕、分组标题跳过）、Enter/Space 提交、Esc 关闭不改值；弹出层 `.focusable()` + `.focused()` 接键。**仍开放**：滚轮形态即时提交 = 平台限制 L-4 | 滚轮形态登记为 L-4，不动 |
| A-10 ◐ | `WDDatePicker` 二维方向键网格导航、弹层自适应高度未实现 | **B20（2026-11-20）已补**：`WDDatePickerGrid`（←/→ ±1 天、↑/↓ ±7 天，RTL 镜像，跨月自动翻页，越界归一为最近可选日）+ 弹层改为 `CustomPresentationDetent` 按内容量高并夹在可用高度内（`WDDatePickerSheetHeight`）。三项自适应：仅月历 / 仅时间 / 月历+时间 | 已闭合；真机键盘行为仍待走查 |
| A-11 ✅ | `WDAvatar` **成员配色 / 照片形态** | **2026-11-21 闭合**：`tone: WDMemberTone?`（nil 回落 surfaceTint 逐像素不变）、`hostColor` 描边色、`WDAvatarImage` 照片形态 + 回退链（照片→文字→图标）、`WDMemberTone.assign` FNV1a32（五 fixture）。证据：`WDAvatar.swift:163-177/:259/:264`、`WDMemberTone+Assign.swift:20-42`；评审 R2 pass |
| A-12 ✅ | `WDProgressBar` / `WDProgressRing` **25/50/75/100 阈值播报**未实现；`WDToast` / `WDBanner` 的 polite 播报也未实现 | 三者均无 `wdAnnouncerText` 引用（全仓仅 `WDPullRefresh` 有） | `M4-EXIT-REPORT.md` §4-⑥（只对 ProgressBar 记「调用方」）；Toast/Banner 在 §32 记「播报标签由调用方注入」，但 **SPEC §2.10 的 #28/#29 播报列仍写 polite** ⇒ 规格与实现口径不一致，需回写 |

### 1.3 新增能力的「零覆盖」缺口（B10–B17 落地但没人调用）

| # | 项 | 证据（2026-11-20 实测） | 影响 |
| --- | --- | --- | --- |
| A-15 ✅ | **范围滑杆（B17-4）无预览、无 demo、无快照** | **B20（2026-11-20）已闭合**：B18 补了预览与 demo，B20 补了 8 态快照 —— `WDSliderRangeSnapshotTests`（`verifyHierarchy` 渲染器）+ 8 张 `slider-range-*` 基线，总基线 360 → **368**；既有 360 张零改动，manifest 纯追加 8 条 | 已闭合 |
| A-16 ✅ | **B15 滚动联动在 demo 里零使用** | `followsScroll` / `wdScrollOffsetY` / `showsScrimWhenExpanded` / `avoidsTabBar` 在 `Examples` 命中 **0** | 大标题折叠、TabBar 收起、FAB 缩小/遮罩这条链**没有任何端到端验证**（U-B-6 的直接原因） |
| A-17 ✅ | **B17-3 过期提示无样例** | `expiredAccessibilityHint` 在 `Examples` 与 `*+Previews.swift` 命中 **0** | 视觉上一无所见；读屏提示只能靠真机手测 |

### 1.4 已登记但需要设计/签名才能动（见 §3 A 类结论）

| # | 项 | 状态 |
| --- | --- | --- |
| A-13 ✅ | `WDCard` `media` 变体 | **2026-11-21 闭合**：`WDCardStyle.media`（**源级 breaking**，F-20 minor + Breaking 段）+ `WDCardMedia` + 图片带（通栏/16:9/最小高 96/灰底占位/160ms 淡入）。证据：`WDCard.swift:148-178/:269-327`、`WDCardMedia.swift`；评审 R2 pass |
| A-14 ✅ | `WDToolbar` 长按 tooltip | **2026-11-21 闭合**：`showsTooltips`（默认 false）+ 500ms 门闩仲裁（Button 原生闭包 = 唯一执行路径，长按抬手不执行 action）+ 28 高气泡（全局坐标夹紧定位）。证据：`WDToolbarTooltip.swift:66-74` 判断点、`WDToolbar.swift:127-131` 吞点击；评审 R1 F1 blocker 与 F2-F4 全修，R2 pass。真机长按手势回归仍**【未验证】**（设计 §4.3 D-7） |

### 1.5 B19 复跑发现的回归（**照片层证据 → 已修**）

> 背景：C-1～C-3 首次在可跑环境执行（见 §3），8 态快照门禁当场抓出 3 处**真实回归**。
> 这些不是"基线漂移"，是代码缺陷；修法与证据如下。记录 = `docs/B19-EXIT-REPORT.md`。

| # | 回归 | 证据（2026-11-20 实测） | 影响 | 处置 |
| --- | --- | --- | --- | --- |
| B-4-① ✅ | **B18 的读屏焦点绑定会让 `ImageRenderer` 把整棵子树渲染成空白** | 8 个对照探针（同内容挂/不挂 `accessibilityFocused`）：不挂 = 正常；挂上 = 全透明（连 `accessibilityRepresentation` 也只救回被表示那一层）。后果：内嵌 `WDButton`/`WDIconButton` 的组合件快照全白（Banner/Toast/EmptyState/DatePicker 像素差 100%） | 快照门禁失效（假红），且未来任何用 `ImageRenderer` 的核对都拿不到画面 | 新增 `WDA11yRuntime.isAssistiveTechRunning`（VoiceOver / Switch Control）**闸门**：只在读屏运行时挂绑定；新增 `View.wdAccessibilityFocused(_:)` / `(_:equals:)` 两个内部入口，`WDAccessibilityFocusHost` 与 `WDFAB` 全部改走它 |
| B-4-② ✅ | **`WDNavigationBar` 在 `.inline` / `.standard` 模式下标题整条透明**（B15 引入） | 内联标题的不透明度乘了折叠进度，而该模式没有大标题、进度恒为 0 ⇒ 标题 0 透明（基线与实拍对比：标题与玻璃底下的"家底"文字一起消失） | 导航栏两个常用模式**没有标题**；属于 B15 落地时的形状缺陷，此前**从未被执行过**（快照从未跑） | 折叠只在大标题模式生效：`inlineTitleOpacity`（非大标题模式恒 1）、`isInlineTitleShowing` 同步修正 |
| B-4-③ ✅ | **`WDTabBar` 胶囊的 `elevation.2` 阴影被 `.clipped()` 裁掉**（B15 引入） | 容器为了"收起"加了 `.clipped()`，而阴影画在视图边界之外 ⇒ 底边一圈阴影消失（像素差 0.7%，实拍可见） | 悬浮胶囊失去浮起感 | 去掉容器级 `.clipped()`；收起裁切由标签行自己的 `maxHeight: 0 + clipped` 完成（该行本来就有） |

**另记**：`WDFAB` 的 8 张基线重录。原因是 B15 给组件加了 **18pt 底部留白**（设计 36 §6「距底部安全区 18」），
八态内容整体上移 36px（= 18 × 2 倍缩放）；旧基线记录于该改动之前 ⇒ **属基线滞后，不是回归**（已按设计值核对后重录）。

---

## 2. B 类 · 契约欠账（跨仓，只读）

| # | 项 | 证据 | 解除条件 |
| --- | --- | --- | --- |
| B-1 | **B10–B17 的契约增量全部未落库** | `wisdomdesign/contracts/` 的 `WDPullRefresh`/`WDSlider`/`WDSearchField`/`WDFAB`/`WDNavigationBar`/`WDDatePicker`/`WDAvatarStack` 里 `onRefreshError`/`showsValueLabel`/`resultCount`/`showsScrimWhenExpanded`/`followsScroll`/`onClear`/`rangeText` **grep 命中 0**；最后落库提交是 `5778f8a`（B8） | 架构师按 `B10-B15-CONTRACT-CHANGE-REQUEST.md` + `B17-CONTRACT-CHANGE-REQUEST.md` 落库 |
| B-2 | `contracts/README.md` 的变更历史表**只有 B1–B6**，缺 B7/B8 行（yaml 头已写 B7/B8 增量） | `README.md` §9 表尾 = B6 | 落库时补 B7/B8/B10–B17 行 + API 计数 |
| B-3 | **`contracts/announcement-cases.json` 从未落库**（SPEC §2.10 M0-5 追加交付 ① 要求「每行的播报/触觉进该 fixtures」） | `ls ../wisdomdesign/contracts/` 无此文件；`docs/` 内零引用 | 架构师补 fixtures；否则 37 行的播报口径只存在于 SPEC 表格 |

---

## 3. C 类 · 验证欠账（2026-11-20 起本机可跑：`danger-full-access` 下 PTY 可用）

| # | 项 | 现状 | 谁能回填 |
| --- | --- | --- | --- |
| C-1 ✅ | **单测复跑**（`Tests/WisdomUITests`） | **已回填（2026-11-20，B19）**：`danger-full-access` 下 PTY 可用（`script -q /dev/null` 实测通过）；`Scripts/ci.sh pr` 实测 **344 / 344 passed（0 failed）**，其中 B15 遗留的 `WDSearchFieldTests` 尺寸断言（此前 `.disabled`）已启用并绿 | — |
| C-2 ✅ | **8 态快照零漂移**（45 条快照测试 / 360 张基线） | **已回填（2026-11-20，B19）**：`xcodebuild test -only-testing:WisdomUISnapshotTests` **45 tests / 18 suites 全过**；同时抓出并修掉两处真实回归（见 §3 B-4） | — |
| C-3 ✅ | demo 无障碍审计（UITest） | **已回填（2026-11-20，B19）**：`WisdomUIDemoUITests` **18 tests / 0 failures（262.3 s）**（含 contrast / hitRegion / textClipped / dynamicType 四类目） | — |
| C-4 | 真机 VoiceOver 走查（M6 §3.2 的 V1–V8 + B17 的 TabBar/FAB/范围滑杆/过期提示） | 【未验证】无 USB 真机 | 项目负责人 / 设计 |
| C-5 | Thinning 增量、真机 hitch / 首帧 | 【未验证】未签名归档不能导出 thinned IPA | 发布前层 |
| C-6 | 双端同 tag `v1.0.0` | ❌ 不成立：Android 仓仍停在 M0（仅 6 个 `.kt`，M2–M5 未实现） | Android 追平 |

---

## 4. D 类 · 平台限制（不投入，只登记）

| # | 项 | 登记处 |
| --- | --- | --- |
| D-1 | `WDRadio` 无 `radio`/`radiogroup` trait | `B3-PLATFORM-LIMITS.md` L-1 |
| D-2 | `WDPicker` 菜单无 `listbox`/`option` trait | 同上 L-2 |
| D-3 | `WDSegmentedControl` 无 `tablist`/`tab` trait | 同上 L-3 |
| D-4 | `WDPicker` 滚轮「先选后确认」与系统 `.wheel` 冲突 | 同上 L-4 |
| D-5 | `WDSlider` 键盘聚焦光环（UISlider 无可观测键盘聚焦事件） | 同上 L-5 |

---

## 5. 建议的下一批（B18）切法

| 批次 | 内容 | 理由 |
| --- | --- | --- |
| **B18（已完成，2026-11-20）** | A-1 焦点光环接线、A-2 松手播报、A-3～A-6 按下/聚焦反馈、A-7 角标朗读、A-12 阈值与 polite 播报、A-15～A-17 覆盖 | 记录见 `docs/B18-EXIT-REPORT.md` |
| **B19（已完成，2026-11-20）** | **首次跑通验证层**（C-1 单测 344 全过 / C-2 快照 45 条 360 张零漂移 / C-3 demo 审计 18 条全过）+ 修 §1.5 的三处回归 + 启用此前 `.disabled` 的尺寸断言 | 记录见 `docs/B19-EXIT-REPORT.md`；**不新增 API**（符号仍 1380） |
| **B20（已完成，2026-11-20）** | A-8 段间拖动 + 位置文案 + 方向键、A-9 菜单键盘环形焦点、A-10 日期方向键网格 + 弹层自适应高度、A-15 范围滑杆 8 态基线 | 记录见 `docs/B20-EXIT-REPORT.md`；符号数仍 **1380**，但 `WDSegmentedControl.init` **追加 2 个带默认值参数**（源码兼容、快照已显式更新） |
| **下一批候选** | ~~A-11 `WDAvatar` 成员配色 / 照片形态~~ | **2026-11-21 已闭合**（B21 批；设计值已随令牌 v1.1.0 交付） |
| **待设计** | ~~A-13 `WDCard.media`、A-14 长按 tooltip~~ | **2026-11-21 已闭合**（B21 批；A-14 真机手势回归仍【未验证】） |
| **待设计** | F7 契约登记 | `contracts/WDAvatar.yaml` 需补 `hostColor`/`WDAvatarImage`/照片 init（跨仓只读，待设计仓落库） |
| **待架构师** | B-1 / B-3 契约落库与播报 fixtures | 跨仓只读 |

---

## 6. 数字快照（2026-11-20）

| 指标 | 值 |
| --- | --- |
| API 符号 | **1380**（`Scripts/dump-api.sh` 零 diff，B19 复跑实测） |
| 单测声明 / 实跑 | **378 条**（`Tests/WisdomUITests`）／**378 passed / 0 failed**（2026-11-21 复跑；+1 为 B20-C 的 RTL 对称性用例） |
| 快照测试 / 基线 | **46 条 / 368 张** ／ **46 tests 全过、零漂移**（2026-11-20 B20 实测；含新增 `slider-range-*` 8 张） |
| demo UITest | **18 条**（此前记 19 条为笔误；2026-11-20 实测 `Executed 18 tests, with 0 failures`，262.3 s） |
| 工作区未提交 | **68 个文件**（B19 后实测：40 modified + 28 untracked，含 B10–B19 全部改动与文档） |
| 结构/格式门禁 | `files=188 errors=0 warnings=0` / `204 文件全过` |
| Foundation 覆盖率 | **95.46%**（610/639，排除 `generated/`；门槛 80%） |
| PR 门禁耗时 | warm **≈49 s**（2026-11-20 实测：PR-0 2.1 + PR-1a 2.7 + PR-1b 21.9 + PR-2 1.6 + 覆盖率 0.6） |
