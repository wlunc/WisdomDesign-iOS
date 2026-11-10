# 契约确认请求 —— M2 判据②的唯一外部输入

> 用途：M2 出口判据②「批内 11 件的契约用例名与实现一致（`params`/`slots`/`default` 与 §5.3 逐行一致）」
> 卡在 `contracts/*.yaml` 未落库。按 I-2 原文，该判据在本批**以冻结表单代替**；现在需要的是一句
> **架构师的书面确认**（或直接落库），即可闭合。
> 日期：2026-11-10｜请求方：iOS 侧（项目负责人已同意走"先确认、后回填"）｜确认人：**架构师**
> 关联：`docs/M2-SIGNATURE-FREEZE.md`、`docs/M2-EXIT-REPORT.md` §1-②、`docs/DEV-PLAN.md` §3.1-I-2。

## 1. 现状（可核对的证据）

- 11 件组件的公开签名与 `docs/M2-SIGNATURE-FREEZE.md` **逐字一致**（编译级自证：`api/WisdomUI.api.json`
  641 符号、`dump-api` 零 diff；签名变更会同时改基线）；
- 受控值名与 C-15 逐行核对通过（含唯一改名 `WDCheckbox.isChecked`；Android 侧 `params[].name` 仍待其改名）；
- 槽位名全部落在 21 名词表内（F-15）：`label/prefix/accessory/helper/title/subtitle/leading/trailing/content/icon/…`；
- `contracts/*.yaml` 库**仍未落库**（M0-5 未交付；`contracts/` 只有 `icons.json`）。

## 2. 两个可选动作（二选一，建议 B）

| 选项 | 内容 | 代价 | 对 M2 的影响 |
| --- | --- | --- | --- |
| **A 落库** | 架构师把 11 件的 `params`/`slots`/`default` 写进 `contracts/<component>.yaml` | 需要架构师排期；本批已冻结的签名不得再动 | 最彻底，但会阻塞 M2 出口 |
| **B 书面确认（建议）** | 确认"**本批以 `docs/M2-SIGNATURE-FREEZE.md` 的冻结签名为契约副本**；`contracts/*.yaml` 的落库时点 = **M3 出口前**，届时按本条回填，不视为契约漂移" | 一句回复；M3 出口前需补落库 | 立即闭合判据②，不阻塞 M3 |

> 建议 B 的理由：签名已经冻结且被 API 基线机器钉住；`contracts/` 缺的是**登记动作**，不是**语义分歧**。
> A 会把"登记延迟"变成"M2 出口延迟"，不划算。

## 3. 可直接回复的确认文本（复制即用）

> 确认：M2 的 11 件组件（`WDTextField`、`WDListRow`、`WDButton`、`WDIconButton`、`WDSwitch`、
> `WDCheckbox`、`WDBadge`、`WDAvatar`、`WDDivider`、`WDCard`、`WDIcon`）以
> `iOS/docs/M2-SIGNATURE-FREEZE.md`（2026-11-10 补签版）的冻结签名与 §1.1/§1.2 表为**本批契约副本**；
> `contracts/*.yaml` 于 M3 出口前落库回填，期间不视为契约漂移。
> 确认人：＿＿＿＿｜日期：＿＿＿＿

## 4. 回填时的检查项（给 M3 的提醒，不要求现在做）

1. `contracts/<component>.yaml` 的 `params[].name` 与 C-15 逐行一致（0 不一致）；
2. `slots` 必须是 21 名词表子集；无槽位写"无"；
3. `default` 与冻结表单 §1.1/§1.2 的默认值逐项一致；
4. `WDCheckbox` 的契约名 `checked`/`isChecked` 依赖 Android 侧 14 行改名（SPEC R3-d）——若届时未完成，
   在 yaml 里标注"待 Android"，**不要**为了闭环改 iOS 侧名字。
