# B10–B16 签名冻结（**已归档，勿改**）

> 本目录是 2026-11-15 多 agent 批次执行期的协调材料，**已冻结归档**。
> 权威文档在上一级目录：
> - 签名冻结（含 §4 未纳入 / §5 验收）：`../B10-B16-SIGNATURE-FREEZE.md`
> - 出口报告（含未验证台账）：`../B10-B16-EXIT-REPORT.md`
> - 接线面（环境键与写入口）：`B10-B16-WIRING.md`
> - 各 agent 的工作区副本（`B10-B16-FREEZE.md`）与本文同源，实施中以 `../B10-B16-SIGNATURE-FREEZE.md` 为准。
>
> **本次实施中的两处口径修正**（已经写进 `../B10-B16-EXIT-REPORT.md` §4 与 CHANGELOG）：
> 1. **B16**：第四个 init 的 `onWriteFailure` **不带默认值**（带 `= nil` 会与既有 `init(isOn:label:)` 产生 ambiguous 重载）；
> 2. **B12**：`init` 的 `timeout` 默认值必须写裸 `.seconds(10)`（公开默认参数不能引用 internal 常量），语义不变。
