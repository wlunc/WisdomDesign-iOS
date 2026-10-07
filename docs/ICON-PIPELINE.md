# 图标管道：从设计语义到 iOS 生成物（设计稿 v1）

> 状态：**设计稿，待冻结会/架构师确认**｜日期：2026-10-07｜范围：M2 的 `WDIconName` + `WDIcon`/`WDIconButton` 依赖
> 关联：`docs/M2-SIGNATURE-FREEZE.md` 阻塞①、`docs/DEV-PLAN.md` §5.1-F07、`AGENTS.md` §6-F-07
> **一句话**：44 条语义名**已经在设计仓**（`../wisdomdesign/docs/08-icons.md` §4），缺的不是设计决策，而是**契约层到两端代码的生成管道**。

## 1. 问题拆解（三件事，归属不同）

把三者混谈必然得出错误归属：

| # | 东西 | 性质 | 归属 |
| --- | --- | --- | --- |
| **A** | 44 条语义名 + **英文标识符** | 跨端标识符词汇（两端必须同名），契约的键 | **契约层** |
| **B** | 每条在两端的**实现符号**（`house.fill` / `home`） | 由设计选定（"优先 .rounded 变体"），换符号 = 视觉变化 | **契约层**（作为"每端实现列"） |
| **C** | 图标**尺寸阶梯** 16/20/24/28（+ 底座 34/40/56、圆角、渐变） | 设计**值**，消费方是组件，要能被 R7 追溯到令牌 | **令牌层** |

**为什么 A 不能塞进 `tokens/wisdom.tokens.json`**：本项目有**三层版本**（令牌 / 契约 / 库 —— F-18、§10）。A 是契约冻结物（F-07 原话："**契约**只统一 44 条语义名 + `mirrorsInRTL`"）。塞进令牌文件 = 把两层压成一层，以后"加一个图标"会被记成**令牌版本变化**（触发两端重新生成 + 令牌 CHANGELOG/tag 语义）—— 语义是错的。

## 2. 目标架构：给契约层配一条与令牌层**同构**的管道

不是"塞进现有文件"，而是复用那套已验证的机制（生成物 + banner + sha12 + manifest + 两端检查器自证）：

```
wisdomdesign/
├── tokens/wisdom.tokens.json        ← 令牌层（新增 size.icon.{sm,md,lg,xl}）
├── contracts/
│   ├── README.md                    ← 人读真源（U/F 表 + C-15 + 图标语义表，由 08-icons.md §4 迁入）
│   └── icons.json                   ← 机器可读原始数据（§3）
└── tools/token-build/build.js       ← 同一支生成器，两种输入

产物
├── dist/tokens.manifest.json        ← 不动（M0 已冻结 schema）
├── dist/contracts.manifest.json     ← 新增：同结构、独立版本
├── iOS/…/Foundation/generated/WDIconName.swift
└── android/…/foundation/generated/WDIconName.kt
```

**为什么另起一份 manifest**：`tokens.manifest.json` 的 `version`/`sha12` 语义 = **令牌版本**。把契约产物塞进去，等于让令牌 sha 去证明一个不由令牌决定的文件 —— 溯源链假成立。拆开后各证各的源，三层版本在产物层可见。

## 3. 契约数据（建议形状）

```json
{
  "$version": "1.0.0",
  "groups": [
    { "id": "navigation", "label": "导航", "icons": [
      { "id": "home", "semantic": "首页", "ios": "house.fill", "android": "home", "mirrorsInRTL": false }
    ]}
  ]
}
```

| 字段 | 纪律 |
| --- | --- |
| `id` | **英文标识符，由契约冻结**（两端常量同名）；名词单数、动词原形、词组 lowerCamelCase；**发布后改名 = breaking**（同 F-20） |
| `semantic` | 保留中文：人类可读的键，评审时对齐设计稿的唯一字段 |
| `ios` / `android` | 两列都进契约：它们**由设计选定**，不是实现细节（换符号 = 视觉变更 = 需设计确认） |
| `mirrorsInRTL` | 见 §6 —— **声明式**，iOS 侧不做机器推导（实测结论见 §6） |
| 格式 | **JSON**：设计仓生成器是零依赖 Node，`tokens/*.json` 已原生解析；为 icons 引入 YAML 解析器 = 往管道里塞一块无测试覆盖的自研件 |

## 4. iOS 产物形状

```swift
// 本文件由 wisdomdesign/tools/token-build/build.js 生成，请勿手改。
// 修改请编辑 wisdomdesign/contracts/icons.json 后重新生成。
// contracts v1.0.0 · sha256:xxxxxxxxxxxx

/// 图标语义名（44 条；契约真源 = contracts/icons.json）。
public enum WDIconName: String, CaseIterable, Sendable {
  case home = "home"
  // … 44 条

  /// 本端实现符号（SF Symbols）。换符号 = 契约变更，本文件不可手改。
  public var symbolName: String { … }
  /// 是否随书写方向镜像（**契约断言用**；渲染由 SF Symbols 自带机制负责）。
  public var mirrorsInRTL: Bool { … }
}
```

三个刻意选择：① **rawValue = 语义名**（枚举即"契约键的代码镜像"；Apple 改名/换符号时契约键稳定）；② **映射生成、不手写**（纯字符串表，无需 Swift 类型构造 ⇒ 与 `WDColorValues` 那种手写层不同）；③ `mirrorsInRTL` 做**计算属性**（无存储、Equatable 自动、可逐 case 断言）。

## 5. 尺寸阶梯（C 项，separate）

- 令牌层新增 `size.icon.{sm,md,lg,xl}` = `16/20/24/28`，**单值键、两端同值**（08-icons.md §2 对两端给同一张表）。底座那组（34/40/56 + 圆角 + `gradient.*`）属于**将来的容器件**，M2 不进令牌。
- iOS 侧另需一层**手写映射**：设计说的"线宽 1.6/1.8/2/2.2"在 SF Symbols 没有 stroke width 旋钮，对应物 = **pointSize + SymbolConfiguration 的 weight/scale**。这与 `WDTypographyMapping`（字阶 → `Font.TextStyle`）**同构**：生成物给值、手写层给平台语义、测试钉住"手写层不得偏离令牌"。
- "图标尺寸锁死、不随动态字体放大"（08-icons.md §2）⇒ 尺寸路径**不得走 `wdFont`**，并需一条断言守着（AX5 下渲染尺寸不变）。

## 6. 实测：两条核验结论（一条成立、一条**被推翻**）

2026-10-07 在 iOS 26.5 模拟器上对 44 条逐一核验：

**① 符号存在性 —— 成立** ✅ 44/44 全部存在（`UIImage(systemName:)` 非 nil，`missing count=0`）。设计文档的 SF Symbols 列可靠。
**注意**：本次核验跑在 **iOS 26.5**；本库部署目标是 **iOS 17**，而 SF Symbols 集合随系统版本增长。要有机器保证需在 **iOS 17 运行时**上跑该断言 —— 本机只有 26.1/26.5 两个运行时，**这是一条真实的已知缺口**（见 §8）。

**② RTL 镜像 —— 我原先的设计假设被推翻** ❌
- 假设一：用 `UIImage.flipsForRightToLeftLayoutDirection` 与契约列互相证伪 ⇒ **不成立**：44 条**全部为 false**（连 `chevron.left`/`arrow.uturn.backward` 也是）⇒ 该属性不是 SF Symbols 的镜像元数据源。
- 假设二：改用"LTR/RTL 渲染像素比对"作为行为证据 ⇒ **同样不成立**：结果与已知 RTL 行为**矛盾**（`calendar`/`list.bullet` 被判为"会变"，而 `chevron.left`/`chevron.right` 被判为"不变"）⇒ 该方法量到的是**布局位置差异**（`ImageRenderer` 的 layoutDirection 只驱动布局），不是符号镜像。
- **结论**：iOS 侧**不强行机器推导** `mirrorsInRTL`。该列由**设计声明**；iOS 侧只断言"列存在且取值合法"，真正的 RTL 视觉验证交给**已有的 8 态快照**（LTR/RTL 成对，见 `WisdomUISnapshotTests`）—— 那条链本来就是为此建的。

## 7. 验证网（调整后）

| 断言 | 做法 | 抓什么 |
| --- | --- | --- |
| 计数 | `WDIconName.allCases.count == 44` + 生成器 `--check` 断言源条数 | 漏生成/多生成 |
| **符号存在** | 遍历 `allCases`：`UIImage(systemName: name) != nil` | 拼错、Apple 改名/移除（**部署目标版本上跑才算数**，见 §6①） |
| **溯源** | 姊妹模式读 `contracts.manifest.json`：banner 的 sha12 == manifest sha12 == 源文件 sha | 生成物被手改 |
| 手写层不越权 | 尺寸映射的 pointSize == 令牌值 ±0.5；AX5 下渲染尺寸不变 | 自造值 / 意外缩放 |
| RTL 视觉 | 沿用 8 态快照（LTR/RTL 成对） | 镜像行为回归 |

## 8. 交付顺序（跨仓一个变更集，标识一致）

| 步 | 谁 | 产物 | 验收 |
| --- | --- | --- | --- |
| ① | 设计 + 架构师 | `contracts/icons.json`（44 条，含 id/semantic/两端符号/mirrorsInRTL）+ `contracts/README.md` 收录人读表 | 条数 44；id 无重复 |

> **责任归属（照抄 DEV-PLAN §9 的依赖表）**：**图标语义名清单 = 设计 + 架构师**；**契约 `params`/`slots`/`default` = 架构师 + 两端 lead**；**生成器 = 架构师**。
> **本端不写它**：DEV-PLAN §9 顶部明写「**不在本端范围**：契约文件库（M0-5 起真源迁入设计仓的 `contracts/README.md`；本端按只读副本执行）」⇒ 跨仓写入零容忍。
> ⚠️ **接手人尚未点名**：本仓 `AGENTS.md` §11 与 DEV-PLAN §9 都记着「**架构师与设计需要点名到人**」是唯一未决项，且「不点名 ⇒ M0 出口 ②③④ 与 **M2 批前签名冻结**顺延」。
> ⇒ **本步的真实阻塞是「人」，不是「工作量」**：规格已在本文件写全（§3 JSON 形状 / §7① 交付顺序 / §10 现成 44 行），接手人只需「审 44 行 id + 建 JSON + 改生成器 + 跑 `--check`」。
| ② | 设计仓工具 | `build.js` 加契约输入 + `WDIconName.{swift,kt}` + `dist/contracts.manifest.json` | `build.js --check` 绿 |
| ③ | 设计仓 | 令牌加 `size.icon.*` 并重生成 | `--check` 绿 |
| ④ | **iOS（我）** | 删冒烟占位；加姊妹溯源模式；`Foundation/Icons/` 手写尺寸映射 + §7 的验证网；快照加图标 LTR/RTL 对；`api/WisdomUI.api.json` 随成因更新 | `ci.sh pr` 全绿 |
| ⑤ | **Android（未开工，先入任务）** | `WDIconName.kt`（同名 id + Material 列）+ 常量断言 | 各自门禁绿 |

**标识**：本批为跨仓变更集，提交信息带同一标识（如 `contracts: v1.0.0`），三仓可 grep 对齐。

## 9. 明确不做

1. **解析 `08-icons.md` 的 markdown 表格**：把文档变成机器真源、解析器无测试覆盖、改排版即静默出错。
2. **SF Symbol 名做 rawValue**：契约键隐形，符号调整即契约漂移。
3. **给 `WDIcon` 开"任意 SF Symbol 字符串"逃生门**：等于允许绕过设计语言，且让"44 条"这个冻结数字失去意义；调用方要自定义图标直接用 SwiftUI 即可。
4. **在 iOS 侧机器推导 `mirrorsInRTL`**：见 §6②，两种方法都不成立（**已实测推翻，不写进契约**）。

## 10. 契约提案：44 条（id / 语义 / iOS / Android）

> 依据 = `../wisdomdesign/docs/08-icons.md` §4 逐行提取；`id` 按 §3 的命名规则拟定（**待确认**）；iOS 符号列已全部通过 §6① 的存在性核验。

**导航**（navigation，7 条）

| id | 语义 | iOS（SF Symbols） | Android（Material Symbols） |
| --- | --- | --- | --- |
| `home` | 首页 | `house.fill` | `home` |
| `calendar` | 日历 | `calendar` | `calendar_month` |
| `members` | 家庭 / 成员 | `person.2.fill` | `group` |
| `profile` | 我的 | `person.fill` | `person` |
| `back` | 返回 | `chevron.left` | `arrow_back` |
| `close` | 关闭 | `xmark` | `close` |
| `more` | 更多 | `ellipsis` | `more_horiz` |

**操作**（action，12 条）

| id | 语义 | iOS（SF Symbols） | Android（Material Symbols） |
| --- | --- | --- | --- |
| `add` | 新增 | `plus` | `add` |
| `edit` | 编辑 | `pencil` | `edit` |
| `delete` | 删除 | `trash` | `delete` |
| `share` | 分享 | `square.and.arrow.up` | `share` |
| `search` | 搜索 | `magnifyingglass` | `search` |
| `filter` | 筛选 | `line.3.horizontal.decrease` | `filter_list` |
| `sort` | 排序 | `arrow.up.arrow.down` | `swap_vert` |
| `duplicate` | 复制 | `doc.on.doc` | `content_copy` |
| `undo` | 撤销 | `arrow.uturn.backward` | `undo` |
| `redo` | 重做 | `arrow.uturn.forward` | `redo` |
| `disclose` | 进入下一级 | `chevron.right` | `chevron_right` |
| `expand` | 展开 | `chevron.down` | `expand_more` |

**状态**（status，8 条）

| id | 语义 | iOS（SF Symbols） | Android（Material Symbols） |
| --- | --- | --- | --- |
| `done` | 已完成 | `checkmark.circle.fill` | `check_circle` |
| `todo` | 未完成 | `circle` | `radio_button_unchecked` |
| `overdue` | 已逾期 | `exclamationmark.circle.fill` | `error` |
| `reminder` | 提醒 | `bell.fill` | `notifications` |
| `doNotDisturb` | 免打扰 | `bell.slash.fill` | `notifications_off` |
| `inProgress` | 进行中 | `clock` | `schedule` |
| `synced` | 已同步 | `arrow.triangle.2.circlepath` | `sync` |
| `offline` | 离线 | `wifi.slash` | `wifi_off` |

**表单**（form，6 条）

| id | 语义 | iOS（SF Symbols） | Android（Material Symbols） |
| --- | --- | --- | --- |
| `clear` | 清除 | `xmark.circle.fill` | `cancel` |
| `showPassword` | 显示密码 | `eye` | `visibility` |
| `hidePassword` | 隐藏密码 | `eye.slash` | `visibility_off` |
| `date` | 日期 | `calendar` | `calendar_month` |
| `time` | 时间 | `clock` | `schedule` |
| `unassigned` | 未指派 | `person.crop.circle.badge.xmark` | `person_off` |

**内容分类**（category，11 条）

| id | 语义 | iOS（SF Symbols） | Android（Material Symbols） |
| --- | --- | --- | --- |
| `task` | 任务 | `list.bullet` | `checklist` |
| `chore` | 家务 | `sparkles` | `auto_awesome` |
| `shopping` | 采购 | `basket` | `shopping_basket` |
| `meal` | 餐饮 | `fork.knife` | `restaurant` |
| `travel` | 出行 | `car.fill` | `directions_car` |
| `health` | 健康 | `heart.fill` | `favorite` |
| `study` | 学习 | `book.fill` | `menu_book` |
| `pet` | 宠物 | `pawprint.fill` | `pets` |
| `plant` | 植物 | `leaf.fill` | `eco` |
| `bill` | 账单 | `creditcard.fill` | `credit_card` |
| `photo` | 照片 | `photo` | `photo` |

**合计 44 条**（与 F-07 的「44 条」一致）。

> 表内 `ios` 列**已核验存在**（iOS 26.5 模拟器，44/44）；`mirrorsInRTL` 列**待设计声明**（§6②）。
