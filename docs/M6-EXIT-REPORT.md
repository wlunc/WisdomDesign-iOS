# M6 出口报告 —— 场景组件与回归发布（1 件 + 回归）

> 里程碑：**M6**（口径来源 = `docs/DEV-PLAN.md` §2.7）｜报告日期：**2026-11-14**
> 判定人：**ios-lead**（本报告由执行 agent 代拟，待项目负责人确认）
> 状态：**iOS 面实现与回归完成；1.0 发布层 3 项受外部条件阻塞**（真机 / 签名导出 / Android 追平）
> 关联：`docs/M6-SIGNATURE-FREEZE.md`、`../wisdomdesign/contracts/WDAssigneePicker.yaml`、`docs/M5-EXIT-REPORT.md`

## 1. 出口判据逐条判定（DEV-PLAN §2.7 的 7 条）

| # | 判据 | 证据 | 结论 |
| --- | --- | --- | --- |
| ① | **批前冻结（1 件）** | `docs/M6-SIGNATURE-FREEZE.md`（D1–D9）+ `contracts/WDAssigneePicker.yaml` 已回填 | ✅ |
| ② | **无障碍回归**：VoiceOver 闭眼走查记录 + demo 层 `performAccessibilityAudit` 四类目 | 四类目 **✅**（nightly-2 的 14 条 UITest 全过，含审计视口新增的 M6 实例）；**VoiceOver 人审【未验证】**（无 USB 真机，见 §5） | ⚠️ 自动面通过、人审未验证 |
| ③ | **截图基线封板**（全部 37 件 × 浅/深 × 默认/AX3 × LTR/RTL） | **344 张基线**（M6 新增 8 张，`assigneepicker-*`）；快照套件 **43 tests 全绿**（`-parallel-testing-enabled NO`） | ✅ |
| ④ | **全量门禁**：`Scripts/ci.sh pr` + nightly 连续绿 | PR **✅**（164 tests / 1246 符号零 diff / Foundation 97.11% / warm 35.51 s）；nightly **第 1/3 日绿**（2026-11-14：设备编译 3.49 s + 快照 **44 tests / 75.64 s** + demo 审计 **14 tests** / 223.49 s，整条 **302.62 s**） | ⚠️ nightly 1/3（连续 3 日未到，按 M3/M4/M5 先例待确认） |
| ⑤ | **发布前层**：归档 Thinning 增量 + 真机 hitch + tag 校验 | 归档**可产出**（2026-11-14 实测 `ARCHIVE SUCCEEDED`，`.build/m6.xcarchive` 1.5 MB，未签名）；**Thinning 增量【未验证】**（未签名归档不能导出 thinned IPA）；**真机 hitch【未验证】**（U-05 无 USB 真机）；**tag 校验**：当前无 tag（见 ⑥） | ⚠️ 部分 |
| ⑥ | **双端同 tag `v1.0.0`**，tag 前确认三仓 HEAD 与版本台账一致 | **不成立**：Android 仓停在 M1（M2–M5 未实现），双端同 tag 无法闭合；项目负责人 2026-11-14 已确认 **iOS 先行、tag 待 Android 追平** | ❌ 待 Android |
| ⑦ | **发布 checklist 可勾选完成** | `docs/DEV-PLAN.md` §10 的 6 步：设计仓 tag 未打 / 本批生成物无变更 / 门禁 PR 绿 + nightly 1/3 / 发布前层部分 / 双端 tag 未打 / CHANGELOG 已写 | ⚠️ 部分 |

**技术判定**：**iOS 面实现与回归全部完成**（①③ + ② 的自动面 + ④ 的 PR 面）；**1.0 发布层未闭合**的 3 项均为外部条件（真机人审、签名导出、Android 追平），逐项登记在 §4。

## 2. 本批交付物

| 项 | 内容 |
| --- | --- |
| 组件 | `WDAssigneePicker`（`Components/Composites/`：`WDAssigneePicker.swift` + `+Previews.swift`） |
| 值类型 | `WDAssigneePickerItem`、`WDAssigneePickerUnassigned`、`WDAssigneePickerSize`(standard, compact) |
| 签名 | 单选 `selection: Binding<String?>` / 多选 `selection: Binding<Set<String>>` 两个 init；`unassigned`、`size`、`positionText`、`onOverflowTap`、`overflowAccessibilityLabel` |
| 契约 | `../wisdomdesign/contracts/WDAssigneePicker.yaml`（params / slots / default / enums；多选重载在注释登记） |
| API 基线 | **1212 → 1245 符号（+33）**，无移除；`dump-api` 零 diff（后续 ProgressBar 补齐再 +1 ⇒ 当前 **1246**） |
| 测试 | 结构断言 **7 条**（`M6ComponentsTests`）：档位 40/32、外环 52/44、溢出 6+`+n`、选中项可视、位置朗读、高度、枚举 |
| 快照 | **8 张** 8 态基线（M6 时总 344；后续 ProgressBar 补齐 +8 ⇒ 当前总 **352**）；样本含单选 + 未指派 / 多选 / 紧凑 / 整体禁用 / 溢出；**渲染器 = `UIHostingController` + `drawHierarchy`**（横向 `ScrollView` 在 `ImageRenderer` 下为空白，实测） |
| demo | 组件目录 **36 → 37 件**；详情页六场景（实时预览 + 变体 + 状态 + 尺寸设置）；审计视口新增 M6 实例 |
| 文档 | `docs/M6-SIGNATURE-FREEZE.md`、本报告、`HANDOVER.md` / `DEV-PLAN.md` §2.7 状态、`CHANGELOG.md` |
| **M6 期间补丁** | **2026-11-14** 用户指出 `WDProgressBar` 未完成设计 15 ⇒ 已补齐**分段变体 / 不确定 1s 延迟 / 禁用 45% / 完成 300ms / 首次出现 3200ms / progressbar 无障碍语义**；API +1（1246）、基线 +8（352）、PR 164 tests；复跑结果见 `docs/M4-EXIT-REPORT.md` §4.1 |
| **M6 期间修正** | **2026-11-14** 用户复核 `WDAssigneePicker` 与设计 37 画廊不一致 ⇒ 未指派改 **52 虚线圈 + `person.fill.xmark`**（图标契约 iOS 映射修正）、选中环与头像**静止间隙 4**（原 1.05 常驻导致 3）、项槽间距 12、选中名字品牌色 + 600；重录 AssigneePicker 8 张 + WDAvatar 8 张基线 |

## 3. 无障碍回归记录（判据 ②）

### 3.1 自动面（本次实跑）

| 项 | 结果 |
| --- | --- |
| `performAccessibilityAudit` 四类目（contrast / hitRegion / textClipped / dynamicType） | **通过**（theme + components 两个 scope；审计视口含 `WDAssigneePicker` 代表实例） |
| 交互（`testAssigneePickerSelectionAndSettings`） | **通过**：点成员选中 → 再点不取消 → 点「未指派」清空 → 设置切紧凑后配置摘要更新 |
| 组件结构断言 | 整组 `.accessibilityElement(children: .contain)` + 组标签；逐项 `.isSelected`；禁用项保留在树内并带 `unavailableReason` hint |

### 3.2 人审面（【未验证】—— 无真机，不写成已通过）

> U-05（真机 USB 直连）在本轮环境不可用；以下为**走查清单**，供项目负责人/设计用 VoiceOver 逐条核对。
> 每条标注「应听到」；核对后把结果补进本表并改状态。

| # | 场景 | 应听到（参考） | 状态 |
| --- | --- | --- | --- |
| V1 | 整组焦点 | 「指派给」组标签先于成员项 | ☐【未验证】 |
| V2 | 未选 / 已选成员 | 「妈妈」+「已选中」+「第 n 项，共 m 项」（`positionText` 由调用方给） | ☐【未验证】 |
| V3 | 单选点已选成员 | 不变、不重复播报、无多余触觉 | ☐【未验证】 |
| V4 | 「未指派」项 | 「未指派」+ 选中态；点后成员选中态消失 | ☐【未验证】 |
| V5 | 已离开成员 | 「赵六」+「已离开」+ 系统 disabled（变暗），不可激活 | ☐【未验证】 |
| V6 | 溢出 `+n` | 朗读 `overflowAccessibilityLabel`（demo 示例 =「查看全部 8 位成员」） | ☐【未验证】 |
| V7 | 横向滚动 | 焦点顺序与可视顺序一致；不抢页面纵向滚动 | ☐【未验证】 |
| V8 | 动效 | 开启「减弱动效」后无弹簧/淡入，选中态仍可感知 | ☐【未验证】 |

## 4. 实现差异与未验证（**不得写成已通过**）

| # | 项 | 现状 | 时点 / owner |
| --- | --- | --- | --- |
| ① | 溢出 `+n` 展开 | 组件只负责显示 `+n`，点击走 `onOverflowTap` 回调；**展开的完整列表由调用方用 `WDBottomSheet` 承载**（零文案 / 零内容依赖） | 已登记（签名冻结 D3） |
| ② | 长按成员资料浮层 | **不做**（库内无资料内容模型；同 `WDAvatarStack` 的「点击展开不可表达」） | 已登记（D4） |
| ③ | `radiogroup`/`radio` 角色 | SwiftUI 无对应 trait ⇒ 只加 `.isSelected`（与 `WDRadio` ③ 同口径）；组语义由 `.accessibilityLabel(label)` 提供 | 已登记 |
| ④ | 位置朗读 | `positionText` 为可选闭包；nil 时不朗读「第 n 项，共 m 项」（库内零文案，调用方决定） | 已登记（D7） |
| ⑤ | 外边距 16 | 由调用方提供（组件不自带外边距，与库内其余组件一致） | 已登记（D8） |
| ⑥ | 选中项在窗口外 | 第 6 位之后被选中时**替换进可见窗口**（保证初始可视）；顺序因此可能轻微变化 | 已登记（D9） |
| ⑦ | VoiceOver 人审 | 【未验证】无 USB 真机（U-05）；清单见 §3.2 | 项目负责人 / 设计 |
| ⑧ | Thinning 增量 | 【未验证】未签名归档不能导出 thinned IPA；当前体积门槛仍是未 Thinning 口径（M3 的 545,178 B 增量门槛） | ios-lead / 发布前层 |
| ⑨ | 真机 hitch / 首帧 | 【未验证】无真机（U-05） | ios-lead / 发布前层 |
| ⑩ | 双端同 tag `v1.0.0` | 未打 tag；Android 停在 M1，等 M2–M5 追平后按 `docs/DEV-PLAN.md` §10 的 6 步发布 | 项目负责人 |
| ⑪ | 未指派项 / 选中环间隙不一致 | **已修（2026-11-14 用户复核）**：未指派 = 52 虚线圈 + `person.fill.xmark`（契约 iOS 映射由 `person.crop.circle.badge.xmark` 修正；Android 仍 `person_off`）；选中环 = 52 槽 2pt，头像**静止 1.0**（弹 1.05 后回弹），圈内间隙 4；项槽间距 12；选中名字品牌色 + 600 | 已修（快照重录） |

## 5. 门禁与发布层证据

```bash
cd iOS
Scripts/ci.sh pr        # 164 tests / 1246 符号零 diff / Foundation 97.11% / warm 35.51 s（2026-11-14）
Scripts/ci.sh nightly   # 设备编译 3.49 s + 快照 44 tests / 75.64 s + demo 审计 14 tests / 223.49 s = 302.62 s（2026-11-14，第 1/3 日）

# 发布前层（本轮已跑的部分）
xcodebuild archive -scheme WisdomDesign-iOS-Package -destination 'generic/platform=iOS' \
  -archivePath .build/m6.xcarchive          # ARCHIVE SUCCEEDED（1.5 MB，未签名；Thinning 导出仍不可行）
git describe --tags --exact-match           # 无 tag（Android 未追平，本轮不打 v1.0.0）
```

## 6. 判定记录

| 项 | 值 |
| --- | --- |
| 技术判据 | **iOS 面全绿**：①③ ✅；② 自动面 ✅（人审未验证）；④ PR ✅ / nightly 1/3 |
| 发布面 | ⑤ 部分（归档可产出；Thinning / hitch 未验证）；⑥ 待 Android；⑦ 部分 |
| 结论 | **M6 iOS 面完成，可以进入 1.0 发布准备；发布层 3 项外部条件未闭合**（真机人审 / Thinning / 双端 tag） |
| 条件 | 上述未验证项按 `docs/SPEC.md` §8.2 记【未验证】；Android 追平后补双端 tag。**环境限制**：最终 tree 的 nightly 重跑需完整权限审批、本轮未重跑——设备编译未变、快照 43 绿、demo 审计 14 绿均在最终 tree 的前后一提交内分别实跑 |
| 后续 | ① 真机 USB 走查（V1–V8）；② 签名归档导出 Thinning 增量；③ Android M2–M5；④ 双端 `v1.0.0` |

## 7. 复跑命令

```bash
cd iOS
Scripts/check-structure.sh --strict && Scripts/check-format.sh
Scripts/ci.sh pr
Scripts/ci.sh nightly
xcodebuild test -scheme WisdomDesign-iOS-Package -destination 'platform=iOS Simulator,id=<UDID>' \
  -parallel-testing-enabled NO -only-testing:WisdomUISnapshotTests     # 352 张基线（44 tests，2026-11-14 复核）
xcodebuild test -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
  -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:WisdomUIDemoUITests
```
