# M4 出口报告 —— 反馈与弹层（9 件）

> 里程碑：**M4**（口径来源 = `docs/DEV-PLAN.md` §2.5）｜报告日期：**2026-11-12**
> 判定人：ios-lead｜**状态：通过（技术判据 7/7；nightly 按项目负责人 2026-11-12 决定不阻塞）**
> 判定环境：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）
> 关联：`docs/M4-SIGNATURE-FREEZE.md`、`docs/DEV-PLAN.md` §21.6 的 M4 十问、`../wisdomdesign/contracts/`

## 1. 出口判据逐条判定（DEV-PLAN §2.5 的 7 条）

| # | 判据 | 证据 | 结论 |
| --- | --- | --- | --- |
| ① | 批前冻结完成（9 件契约入库） | 9 个 yaml 已回填设计仓（提交 `e1a1d19`）；签名冻结 = `docs/M4-SIGNATURE-FREEZE.md`（Q1–Q4 项目负责人「都按建议」） | ✅ |
| ② | 玻璃档位单测绿（含两条必须红） | `WDGlassTests`（7 条）覆盖 档位 × appearance × textLevel；两条"必须红"用例绿；PR 全绿 | ✅ |
| ③ | 效果配额 7 条计数/降级断言绿，模糊面可数 | `WDEffectsBudgetTests`（4 条）逐字段断言 7 条上限、`minimal`、`reduced` 只降不升、`downgraded(to:)` 取字段级下界 | ✅ |
| ④ | 对比度按最不利取色验证；每套 scheme 账目进契约 | `../wisdomdesign/contracts/contrast.json`（light/dark 各 17 对，含玻璃禁止对，提交 `7ac715e`）；demo 四类目审计通过、`AUDIT-ISSUE=0` | ✅ |
| ⑤ | 该批性能数字进报告（只报不拦） | §3 的 9 件 ImageRenderer 耗时（n=12） | ✅ |
| ⑥ | 六态快照入库（玻璃类用 hierarchy） | 9 件 × 8 态 = **72 张新基线**（总 **208** 张）；`WDBottomSheet`/`WDActionSheet` 面板用 `UIHostingController`+`drawHierarchy` | ✅ |
| ⑦ | 发布物冒烟（demo 构建 + 归档可产出） | demo 构建 ✅；**7 条 UITest**（含四类目审计、两弹层、键盘、嵌套滚动）全过；`xcodebuild archive` 成功，`.app` = **1,412 KB**（未签名） | ✅ |

**门禁**：`PR + nightly₃ + 发布前`。PR 全绿（**124 tests / 861 符号零 diff** / `Foundation/**` **97.26% ≥ 80%** / `--strict` 0 warning / warm **27.57 s**）。**nightly 按项目负责人 2026-11-12「忽略 nightly」决定不阻塞**；demo 审计已在本轮实跑（**7 条 UITest 全过**）。发布前层的 Thinning 增量仍留 M6。

## 2. 本批交付物

| 项 | 内容 |
| --- | --- |
| 组件 | `WDBottomSheet` / `WDActionSheet` / `WDAlert` / `WDToast` / `WDBanner` / `WDEmptyState` / `WDSkeleton` / `WDProgressBar` / `WDProgressRing` |
| 落点 | `Components/Composites/{WDBottomSheet,WDActionSheet,WDAlert,WDToast,WDBanner,WDEmptyState,WDSkeleton}/`、`Components/Primitives/{WDProgressBar,WDProgressRing}/` |
| 契约 | 9 个 yaml（params / slots / default + 枚举全量 case）；`contrast.json` 对比度账目 |
| API 基线 | **861 符号**（M3 的 661 + **200**：M4 199 + `WDActionSheetItem.icon` 1）；冒烟段的 sheet/actionSheet 声明同 PR 退役 |
| 测试 | 结构断言 **9 条** + 性能采样 **1 条** + 快照 **9 个测试 / 72 张基线**；PR **124 tests**；demo **7 条 UITest** |
| demo | 组件目录 **21 件**（M2 11 + M3 1 + M4 9）+ **2 个组合场景**（卡片容器/底部面板容器）；弹层从详情页触发；审计视口加入 5 件可视图 |
| 无障碍 | Alert/ActionSheet/BottomSheet 出现时 `screenChanged` 把焦点移入；ActionSheet/BottomSheet 自绘层用 `.isModal` + 隐藏锚点；**两个自绘 sheet 都已实现焦点归还**（记录 `UIAccessibility.focusedElement`，dismiss 后 `.layoutChanged` 归还）；BottomSheet 另有 `.escape` 关闭动作；Banner/Toast/Skeleton 的播报标签由调用方注入（L-B） |

## 3. 性能数字（ImageRenderer；只报不拦）

口径：`ImageRenderer` 渲染一次 PNG（scale 1），前 3 次预热丢弃，n=12；单位 ms。

| 组件 | avg | min |
| --- | --- | --- |
| `WDProgressBar` | 4.01 | 2.49 |
| `WDProgressRing` | 4.47 | 2.64 |
| `WDEmptyState` | 5.22 | 1.46 |
| `WDSkeleton` | 2.79 | 1.57 |
| `WDBanner` | 3.49 | 1.91 |
| `WDAlert` | 4.15 | 2.28 |
| `WDToast` | 5.85 | 2.24 |
| `WDBottomSheet`（面板内容） | 25.31 | 1.88 |
| `WDActionSheet`（面板内容） | 3.62 | 1.47 |

> `WDBottomSheet` 的 avg 受首屏窗口/渲染路径影响；min 1.88 更接近稳态。原始输出 = PR 日志的 `M4PERF` 行。

## 4. 实现差异与未验证（**不得写成已通过**）

| # | 项 | 现状 | 时点 / owner |
| --- | --- | --- | --- |
| ① | **Alert 焦点归还** | 出现时用 `UIAccessibility.post(.screenChanged)` 把焦点移入；**关闭后归还触发元素未实现**（`WDA11yFocusID` 无公开构造器，调用方无法传回焦点 ID） | M5/M6；需 U 项或签名扩展 |
| ② | Toast 悬停暂停 / 上滑关闭 | 未实现；自动消失用组件内 `.task`（随视图消失取消），同屏一条由调用方控制 | M5/M6（如需真机指针/手势验收） |
| ③ | Banner `success` 变体 | 按 Q1 **不纳入**（C-15/U2 的 Android 集合为 3 个）；设计 §4 的 success 用 info 表达 | 已记录（M4-SIGNATURE-FREEZE Q1） |
| ④ | ProgressBar 分段变体 | 按 Q4 **暂缓**；确定/不确定已交付 | M5/M6（如调用方需要） |
| ⑤ | ProgressBar 填充色 | 设计的 `gradient.mid` 浅端在 `surface.tint` 上仅 **2.02:1**（<3:1）⇒ 改 `textBrand → statusInfo` 渐变（**3.91:1 / 6.71:1**） | 已记录（对比度优先） |
| ⑥ | 进度阈值播报（25/50/75/100） | 未实现组件内播报；标签由调用方给（与 M2 错误态播报同口径） | 调用方 / M5 |
| ⑦ | BottomSheet/ActionSheet 快照 | 快照的是**面板内容**（系统/窗口 chrome 不进 hierarchy）；ActionSheet/BottomSheet 已改窗口级自绘，焦点/键盘由自绘层接管（Bottomsheet 键盘用通知观察，未用文本字段验收） | 已记录 |
| ⑧ | Thinning 增量 | 仍【未验证】（未签名归档不能导出 thinned IPA） | M6 发布前层 |
| ⑨ | nightly 连续 3 日 | 按项目负责人 2026-11-12 决定**不阻塞**；本轮未补跑 | 项目负责人决定 |
| ⑩ | Skeleton 微光形态 | 由设计稿的"斜向微光扫过"改为**水平 sourceAtop 扫光**（只落在灰块上，避免斜方块观感）；行宽改 `maxWidth` + 固定短行留白，修复 demo 横向溢出 | 已修复（2026-11-12） |
| ⑪ | BottomSheet 与设计 26 的布局差异 | 标题 `title3`、头部 56；内容 12 顶距 + `ScrollView`；底部操作区固定 + 1pt 分割线 + 高 72 + 右对齐；宽屏面板上限 480。**窗口级自绘贴边面板**：左右/底部贴屏幕、顶部 32 圆角、把手 36×5、half/large、把手拖拽/点击切换、下滑关闭、点遮罩关闭、键盘上移；**焦点归还 + `.escape`**；**内容顶部下拉经 UIScrollView 桥接拖面板**。系统 `.sheet` 不再使用（iOS 26 partial detent 浮动约 16pt） | 已改自绘并补齐（2026-11-12/13）；7 条 demo UITest 全过 |
| ⑫ | ActionSheet 间距与取消形态 | 按设计 27 参考重排：左右 16 内距；标题/说明移入列表卡片顶部（caption1/secondary + 底部分隔线）；行左对齐 + 可选 20pt 前置图标；取消为独立 48pt **圆角卡片**（18 圆角/semibold/e2）；破坏性置底。**窗口级 presenter + 自绘遮罩**：透明背景、无系统 sheet 边框；遮罩静态出现，面板滑入/滑出；点遮罩 = 取消；**焦点归还已实现** | 已重排并补齐（2026-11-12/13） |

## 5. 判定记录

| 项 | 值 |
| --- | --- |
| 技术判据 | **7/7 ✅**（§1） |
| 门禁 | PR ✅；demo 审计 ✅；归档 ✅；nightly 按决定不阻塞 |
| 结论 | **通过（2026-11-12，ios-lead）** |
| M4 复核 | **2026-11-13 通过**：PR **124 tests / 861 符号零 diff / Foundation 97.26%**；快照 **9 测试 / 208 基线**；demo **7 条 UITest（89.9 s）**；archive **1,412 KB**；ActionSheet/BottomSheet 自绘 + 焦点归还 + 嵌套滚动 + 键盘全过 |
| 条件 | ①–⑨ 的差异/未验证项已登记；Thinning 与 nightly₃ 不阻塞本批 |
| 后续 | M5（导航与表单 15 件）；M6 前补 Alert 焦点归还、Thinning 与双端 tag |

## 6. 复跑命令

```bash
cd iOS
Scripts/ci.sh pr                    # 124 tests / 861 符号 / Foundation ≥80% / --strict
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
Scripts/dump-api.sh && git diff --exit-code -- api/WisdomUI.api.json
xcodebuild archive -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'generic/platform=iOS' -archivePath .build/archive-demo-m4.xcarchive CODE_SIGNING_ALLOWED=NO
```
