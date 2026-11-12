# M2 签字包 —— 出口判定 + M1/M2 签字请求 + M3 冻结会议程

> 用途：把"签字前要看的证据、要回的话、M3 开工要拍板的事"一次备好。
> 时点：**2026-11-11 晚**（nightly 第 2/3 日已绿）。**已于 2026-11-12 签字：M2 判定通过、M1 补签通过**（记录见两份出口报告的判定记录节）。
> 判定人：ios-lead（M2）+ ios-lead（M1 补签）｜参加 M3 冻结会：ios-lead（主持）、架构师、设计、tech-lead。
> 关联：[`M2-EXIT-REPORT.md`](M2-EXIT-REPORT.md)、[`M1-EXIT-REPORT.md`](M1-EXIT-REPORT.md)、
> [`CONTRACTS-CONFIRMATION-REQUEST.md`](CONTRACTS-CONFIRMATION-REQUEST.md) §5、[`M3-PREP-LISTSECTION.md`](M3-PREP-LISTSECTION.md)、
> [`M2-DEVIATIONS.md`](M2-DEVIATIONS.md) §5、[`U09-SIZE-BASELINE.md`](U09-SIZE-BASELINE.md)。

## 1. M2 出口判定表（6/6 均有结论）

| # | 判据 | 证据（可复跑） | 结论 |
| --- | --- | --- | --- |
| ① | API 无未解释差异 | `Scripts/dump-api.sh` → 641 符号零 diff；逐批 +18/+16/+22/+13/+43/+53 均有成因提交与 CHANGELOG | ✅ |
| ② | 契约用例名与实现一致 | 冻结表单 §1.1+§5.1+§5.2；架构师 **2026-11-10 书面确认（选项 B）**；11 个 `contracts/*.yaml` 回填 = **M3 出口前**（逾期 → 本判据回到未闭合） | ✅（替代闭合） |
| ③ | 8 态截图入库 + tokens trace | **104 张基线**（M1 16 + M2 88）；`ci.sh pr` 的 PR-0 tokens trace 绿 | ✅ |
| ④ | 无障碍断言 | demo 目录 + 审计视口覆盖 11 件；两页签 × 4 类目审计绿；**6 条 `AUDIT-KNOWN`**（nightly 两日均实测 6 条：固定字号头像/徽标、单行截断；个别运行会多 1 条可见元素的同类例外，已在点名清单内）；音频播报不可机检 | ✅（含登记例外） |
| ⑤ | 性能数字进报告 | `M2-EXIT-REPORT.md` §3：11 件渲染耗时（只报不拦） | ✅ |
| ⑥ | 冒烟退役 | `WD_API_SMOKE` 只剩弹层（§2.5）与动效（§3.5） | ✅ |

**nightly（连续 3 日）**：
- 第 1 日（2026-11-10）：设备编译 2.8s + 16 tests 快照 + demo 审计 47.0s ✅
- 第 2 日（2026-11-11）：设备编译 2.1s + 16 tests 快照 + demo 审计 69.6s（3 条 UITest）✅
- 第 3 日（2026-11-12）：**首跑红 → 复跑绿**。首跑报 `launch-count` 的 "Contrast nearly passed"
  （13pt 文本，实测约 16:1，非 WCAG 失败；同代码复跑 3/3 绿）；审计夹具加点名窄例外后整条
  nightly 绿（1.2s + 16 tests + 审计 69.1s）✅；**07:49 最终复跑绿**（1.3s + 16 tests + 审计 68.5s，
  `AUDIT-ISSUE=0`）。库代码三天未变。
  签字时确认：**是否将 11-12 计入 3 日窗口**（若要求严格重启，出口顺延至 11-14）。

**门禁复核值**（2026-11-11，HEAD `309a6a3` 的库代码与 `bf856c8` 相同）：
`106 passed / 0 failed`、符号 **641 零 diff**、模块覆盖率 **61.06%**、`Foundation/**` **97.69%（593/607）**、warm **21.30 s**。

## 2. 可直接回复的签字文本（复制即用）

### 2.1 M2（在 11-12 第 3 日 nightly 绿后回）

> 依据 `iOS/docs/M2-EXIT-REPORT.md`：M2 出口判据 6 条均有结论（② 以 `M2-SIGNATURE-FREEZE.md`
> §1.1+§5.1+§5.2 为契约副本，架构师 2026-11-10 书面确认；`contracts/*.yaml` 回填不晚于 M3 出口，
> 逾期则判据②回到未闭合）；nightly 连续 3 日绿（2026-11-10/11/12）；demo 无障碍审计覆盖 11 件，
> 6 条审计例外（部分运行 7 条）已点名并接受。**判定：通过。** 遗留随 M3/M4 复核：U-05 真机采样、U-10、弹簧 μ 评审。
> 判定人：ios-lead｜日期：＿＿＿＿

### 2.2 M1（补签，可与 M2 同日）

> 依据 `iOS/docs/M1-EXIT-REPORT.md`：M1 九项交付与门禁全绿（34 tests / 371 符号 / 16 张基线）。
> **判定：通过。** 遗留：U-05 真机 `fontScale/AX3` 观感（须 USB 直连后由人给结论）、U-10、
> 弹簧 μ 并排评审（M4 动效落地后）、P14/P15 回写。判定人：ios-lead｜日期：＿＿＿＿

> 说明：M1 签字不阻塞 M2 出口（I-1 只看"上一里程碑出口报告是否落盘"），但**必须随 M2 一起补**，
> 否则会变成"永远没人签"的悬空项。

## 3. 签字前应知的三项遗留（不构成 M2 阻断）

| 项 | 现状 | 何时/谁 |
| --- | --- | --- |
| **U-05 真机采样** | 设备无线连接 ⇒ XCUITest runner 无法 bootstrap；`⌘R` 正常 | USB 直连后重跑；观感结论必须人给 |
| **U-10（caption2 审计）** | 系统把 11pt 判 Dynamic Type unsupported；**本组件审计视口未使用 caption2** | tech-lead + 设计；M5 前裁决 |
| **弹簧 μ 评审** | 无评审对象（`WDMotion` 未实现） | M4 动效落地后出并排材料 |

## 4. M3 冻结会议程（约 45 分钟；M2 签字后 / 同日可开）

**目标**：冻结 `WDListSection` 签名（I-2）+ 定 M3 出口的三件义务（契约回填、体积门槛、API 封板）。

**会前必读**（15 分钟）：[`M3-PREP-LISTSECTION.md`](M3-PREP-LISTSECTION.md) §2–§3、
`SPEC.md` §2.10-#19、设计仓 `specs/01-basic.md` #19、[`CONTRACTS-CONFIRMATION-REQUEST.md`](CONTRACTS-CONFIRMATION-REQUEST.md) §5.3。

### 4.1 五个签名待决点（逐条拍板，记入冻结表）

| # | 议题 | 选项 | 建议 | 决定（留空） |
| --- | --- | --- | --- | --- |
| Q1 | `items` 形态 | A `@ViewBuilder`（灵活，但**无法判空/判末行**）；B `items: [Item]` + `row` 构建器（空组隐藏、末行无分隔可机器化） | **B（数据驱动）** | ＿＿ |
| Q2 | `selection` 受控值类型 | `Binding<Set<Item.ID>>`（多选）；`Binding<Item.ID?>`（单选）；或不受控（与 C-15 冲突） | **`Set<Item.ID>`**；单选场景传单元素集合 | ＿＿ |
| Q3 | 标题右侧动作 | 新增 `headerAction` 参数；或塞进 `header` 构建器 | **新增参数**（≤1 个、`text.brand`、a11y 顺序由组件保证） | ＿＿ |
| Q4 | 卡片容器 | 复用 `WDCard`（内距 16 ⇒ 行内距翻倍 32）；组件内自绘（水平内距 0，复用令牌/阴影） | **自绘容器**（不改 M2 已封的 `WDCard`） | ＿＿ |
| Q5 | 空组隐藏 | 以 `items.isEmpty` 一票隐藏（连标题/动作/页脚）；或由调用方传 `isHidden` | **`items.isEmpty` 自动隐藏** | ＿＿ |

> 冻结会产出：`WDListSection` 的签名表（进 `M2-SIGNATURE-FREEZE.md` 同格式的新文件或 §5 追加）+ 决定记录。
> **签名表落盘前不得开写**（I-2）。

### 4.2 M3 出口三件义务（同一会议确认）

| 义务 | 内容 | 负责人 | 时点 |
| --- | --- | --- | --- |
| **契约回填** | `../wisdomdesign/contracts/<Component>.yaml` **11 个**；回填=誊录（不得改签名/默认值/槽位/枚举）；判定口径 = `CONTRACTS-CONFIRMATION-REQUEST.md` §5.3 | ios-lead + 架构师 | **不晚于 M3 出口** |
| **体积门槛** | 新建同构消费方壳 → 两端各归档 3 次 → P50 + 10%（或绝对上限）写 README/CHANGELOG；预测量见 `U09-SIZE-BASELINE.md` | ios-lead + tech-lead | M3 出口 |
| **API 封板** | `api/WisdomUI.api.json` 已零 diff；补"基线入库 + 签字 + CHANGELOG"即封板 | ios-lead | M3 出口 |

**M3 出口还差的登记项**：P21（默认值检出表述回写）；`WDCheckbox` 的 `checked` 由 android-lead 书面复核一次。
覆盖率已预达标（`Foundation/**` 97.69% ≥ 80%），M3 只需把"只打印"改成"门槛"。

## 5. 11-12 → M3 的时间线

| 时点 | 动作 | 负责人 |
| --- | --- | --- |
| 11-12 白天/晚 | 跑 `Scripts/ci.sh nightly`（第 3 日）；**代码冻结不变** | 我（需放权）/ ios-dev |
| 三绿后 | 回 §2 的两段签字文本 | ios-lead |
| 同日或 11-13 | 冻结会（§4.1 五问）→ 冻结表落盘 | ios-lead 主持 |
| 冻结表落盘后 | 开写 `WDListSection`（六类断言）→ `ci.sh pr` → 8 态基线 → nightly 第 1 日 | 我 |
| M3 出口前 | 契约 11 yaml 回填 + 体积门槛定值 + API 封板签字 + P21 回写 | 对应 owner |

## 6. 附件（都在 `iOS/docs/`）

- 出口判定：[`M2-EXIT-REPORT.md`](M2-EXIT-REPORT.md)、[`M1-EXIT-REPORT.md`](M1-EXIT-REPORT.md)
- 契约：[`CONTRACTS-CONFIRMATION-REQUEST.md`](CONTRACTS-CONFIRMATION-REQUEST.md)、[`M2-SIGNATURE-FREEZE.md`](M2-SIGNATURE-FREEZE.md)
- 裁决：[`M2-DEVIATIONS.md`](M2-DEVIATIONS.md) §5
- M3：[`M3-PREP-LISTSECTION.md`](M3-PREP-LISTSECTION.md)
- 体积：[`U09-SIZE-BASELINE.md`](U09-SIZE-BASELINE.md)
