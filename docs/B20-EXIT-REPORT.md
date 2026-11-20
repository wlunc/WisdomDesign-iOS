# B20 出口报告 —— 台账剩余可纯代码项收口（2026-11-20）

> 依据：项目负责人 2026-11-20「开启下一批任务」；承接 `docs/DEBT-LEDGER.md` §5 的「下一批候选」。
> 关联：`docs/DEBT-LEDGER.md`（状态回写）、`CHANGELOG.md`。
> **判定环境**：Xcode 26.6（17F113）／iOS 26.5 模拟器（iPhone Air，UDID 711BF16D-…）／Swift 6；DSH **danger-full-access**。

---

## 0. 过程说明（重要：本批由 agent 团队并行执行，中途遭遇上游限流）

本批以 6 人 agent 团队执行（3 个实现 + 1 快照 + 1 验证 + 1 评审）。执行中团队全体遭遇上游 **429 限流**（`quota_exceeded`，重置时间 2026-11-21 19:52 +08），4 个成员在任务中途终止、任务被判 failed。

**captain 处置**：没有盲目重派（限流在重置前不会恢复），而是逐项核查已落盘的工作：
1. 编译验证：`build-for-testing` exit 0；
2. 单测：**377 tests / 47 suites 全过**（B19 的 344 + 本批新增 33）；
3. **接线核查**（评审最担心的「纯函数 + 单测 = 假实现」）：逐文件确认拖动状态真的驱动了指示块、`onKeyPress` 真的挂在可聚焦容器上、`presentationDetents` 真的换成了 `CustomPresentationDetent`；
4. **captain 独立探针**：另写 5 条验收探针（不进交付物）验证换算函数与视图侧同源、方向键端点钳制、Picker 环形回绕、日期跨月、弹层高度随内容变化 —— **5/5 通过**；
5. 全量快照：**46 tests / 368 张零漂移**。

结论：三份实现的**代码与接线均已完成**，缺的是成员自己的收口报告与评审 verdict（因限流中断）。本报告据 captain 实测补记。

---

## 1. 交付（台账条目 → 状态）

| 台账 # | 项 | 交付 | 状态 |
| --- | --- | --- | --- |
| A-8 | `WDSegmentedControl` 段间拖动 / 位置文案 / 方向键 | `DragGesture(minimumDistance: 1)` + 横向占优判定：跟手写 `dragSegmentIndex`（只改视觉）、松手吸附并走与点击**同一条** `commit(index:)`；`WDSemantics.positional` 位置文案（措辞与分隔符由调用方注入）；`onKeyPress(.leftArrow/.rightArrow)` 即时切换、端点不环绕、RTL 镜像 | ✅ 代码 + 探针；真机键盘【未验证】 |
| A-9 | `WDPicker` 菜单键盘导航 | `WDPickerMenuFocus`（环形推进、分组标题跳过、初始落选中项）；弹出层 `.focusable() + .focused() + .onKeyPress(...)`；↓/↑ 移动并滚动、Enter/Space 提交一次、Esc 关闭不改值 | ✅ 代码 + 探针；真机键盘【未验证】 |
| A-10 | `WDDatePicker` 方向键网格 + 弹层自适应高度 | 新增 `WDDatePickerGrid`（±1 天 / ±7 天、RTL 镜像、跨月自动翻页、越界归一为最近可选日）+ `WDDatePickerSheetHeight`（`CustomPresentationDetent` 按内容量高并夹在可用高度内，三种组合） | ✅ 代码 + 探针；小屏/横屏真机【未验证】 |
| A-15 | 范围滑杆 8 态快照 | `WDSliderRangeSnapshotTests`（`verifyHierarchy`，双手柄 + 区间填充 + 区间文案）；8 张 `slider-range-*` 基线；总基线 360 → **368** | ✅ 已闭合 |

**API**：**符号数仍 1380，但公开签名有一处变化** —— `WDSegmentedControl.init` 追加两个**带默认值**的参数（`positionText: ((Int, Int) -> Text)? = nil`、`positionSeparator: Text = Text(verbatim: "")`），用于位置文案的 L-B 注入（措辞由调用方给）。按 SPEC §2.9 规则 1：**源码兼容、ABI/符号数不变，但破坏符号快照连续性** ⇒ 已按 `Scripts/dump-api.sh --update` 显式更新基线（`api/WisdomUI.api.json` 2 行），须与成因同提交。A-9/A-10 两项确为零公开面变化（全在 internal 层）。

---

## 2. 验证证据（captain 实测，非成员自报）

| # | 判据 | 命令 | 结果 |
| --- | --- | --- | --- |
| ① | 结构门禁 | `Scripts/check-structure.sh --strict` | `files=193 rules=22 errors=0 warnings=0` |
| ② | 格式门禁 | `Scripts/check-format.sh` | `OK（209 文件）` |
| ③ | 编译 | `xcodebuild build-for-testing` | **exit 0** |
| ④ | 单测 | `xcodebuild test -only-testing:WisdomUITests` | **377 passed / 0 failed**（47 suites） |
| ⑤ | 快照 | `xcodebuild test -only-testing:WisdomUISnapshotTests` | **46 tests / 19 suites 全过**，368 张零漂移 |
| ⑥ | API 基线 | `Scripts/dump-api.sh` | **零 diff（symbols=1380）** |
| ⑦ | captain 探针 | 临时 suite（已删） | **5/5 通过**（见 §0-4） |

### 仓规核对（逐条 grep）

| 规则 | 检查 | 结果 |
| --- | --- | --- |
| R14 | `import UIKit` in 三个组件目录 | **0** |
| R13a | `AnyView` | **0** |
| SPEC §3.4 | `DragGesture(minimumDistance: 0)` | **0 处实际调用**（唯一命中是注释里说明「本处为何不属于该禁则」，实际代码为 `minimumDistance: 1`） |
| L-B | 组件内中文字面量 | **0** |

---

## 3. 设计取舍（逐条给依据）

| 项 | 依据 | 取舍 |
| --- | --- | --- |
| 分段拖动用 `minimumDistance: 1` 而非 0 | SPEC §3.4 禁的是用 `minimumDistance: 0` **伪造按下态**；按下只能来自 `ButtonStyleConfiguration.isPressed` | `minimumDistance: 1` ⇒ 轻点（零位移）永不进拖动分支，点击路径逐字不变；与 `WDSwitch` 轨道拖动同形 |
| 分段容器不额外 `focusable()` | 设计 21 §10：段是唯一可见焦点 | 按键从段冒泡到容器处理，不新增焦点目标（避免读屏多一个空焦点） |
| Picker 弹层 `focusEffectDisabled()` | 设计 22 §10「展开后焦点进入弹出层」 | 需要接键盘就必须可聚焦，但弹层本身不是可选项、不该显示焦点框 ⇒ 关掉视觉聚焦效果 |
| 日期弹层用 `CustomPresentationDetent` | 设计 23 §8 + §10 的 44 触控口径 | 只有 `Context.maxDetentValue` 才拿得到系统为该弹层留出的可用高度；在 `body` 里算拿不到，固定三档又违反「自适应」 |
| 日期越界归一而非报错 | 设计 23 §5「禁用 40%，日历中不可选的日期降到 30%」 | 焦点落到不可选日时归一为最近可选日，比「停住不动」更符合键盘操作预期，且不崩溃 |

---

## 4. 未验证台账（**不得写成「已通过」**）

| # | 项 | 现状 | 回填责任 / 时点 |
| --- | --- | --- | --- |
| U-B20-1 | **真机硬件键盘实按键**：分段控件方向键、Picker 菜单方向键/Enter/Esc、日期方向键 | 【未验证】模拟器无法真正产生硬件键盘事件；单测只覆盖下标推进与换算，`onKeyPress` 的实际触发需真机（完全键盘访问） | 真机走查 / 发布前层 |
| U-B20-2 | 分段拖动的手感与阈值（横向占优判定是否误伤纵向滚动） | 【未验证】需真机或 UITest 手势 | demo UITest / 真机 |
| U-B20-3 | 日期弹层在**小屏 / 横屏 / AX5** 下的夹取效果 | 【未验证】纯函数有单测，真实 detent 在极端尺寸下的表现未跑 | 真机走查 |
| U-B20-4 | 范围滑杆 8 张新基线的**真机观感**（双色段/描边） | 【未验证】快照已入库且零漂移，真机未看 | 真机走查 |
| U-B20-5 | `wd-verifier` 的字面命令复跑、`wd-reviewer` 的最终 verdict | 【未完成】两者均因 429 限流在任务中途终止；captain 已用实测补记（§2），但**独立评审 verdict 缺失** | 下一轮团队补齐 |

---

## 5. 复跑命令

```bash
cd iOS
Scripts/ci.sh pr                                   # 结构 + 格式 + 编译 + 377 单测 + dump-api 零 diff + 覆盖率
xcodebuild test -scheme WisdomDesign-iOS-Package \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests
```

> 必须允许 PTY（本仓历史失败原因就是沙箱禁 PTY）。
