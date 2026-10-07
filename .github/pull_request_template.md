```注意：本模板与 `docs/SPEC.md` §1.4 的"最终版"一致；门禁段按 I-M0-f 之后的实际情况改写为 `Scripts/ci.sh pr`（一条命令等价于原来的四步），**为避免与 M0 出口⑥的判据自相矛盾，本文件不出现 host 侧 SwiftPM 命令的字面串**。
```

## 变更类型

- [ ] feat / fix / perf / refactor / style / test / build / ci / docs / chore
- [ ] 纯移动（无语义变化）｜ [ ] 语义变化（描述里给出 public API 前后对照）
- [ ] 本 PR 需要保留提交历史（跨层移动 / API 冻结）→ 用 rebase-merge

## 跨端边界

- [ ] 未触及 U 系列（令牌名/枚举名与 case/槽位名/默认值/行盒语义/状态优先级/触控数值/无障碍行为/玻璃档位/动效令牌/生成物溯源）
- [ ] 触及 U 系列 → 已在 `contracts/**` 更新，附 Android 侧同步 PR/commit 链接：______
- [ ] 触及 F 系列 → 已在 `contracts/README.md` 的"两端形态"表登记：______

## 反模式自检

- [ ] 未给 iOS 组件加 `enabled:` 参数（可用性只走 `.disabled(_:)`）
- [ ] 未自造 `DragGesture` 按下态（按下只来自 `ButtonStyleConfiguration.isPressed`）
- [ ] 未造 Saver 等价物；`Components/**` 未引入静态 `WDColor.*`（R10）

## L-B 自检

- [ ] 未在库内引入任何分隔符/语序模板/状态文案（`WDSemantics` 只做结构拼接）
- [ ] 新增读屏标签参数：必填，或 `requiredWhen` 已登记

## 门禁自检（`xcodebuild` + 模拟器；不是 host 侧 SwiftPM 命令）

一步版（等价于下面各步）：

```bash
Scripts/ci.sh pr
```

- [ ] `Scripts/check-structure.sh`（R1–R21）绿
- [ ] `Scripts/check-format.sh` 绿
- [ ] `build-for-testing` 绿（含 `WD_API_SMOKE` 签名冒烟）
- [ ] `test-without-building -only-testing:WisdomUITests` 绿；测试结论 `passed ≥ 1` 且覆盖率报告已生成
- [ ] `Scripts/dump-api.sh` 后 `git diff --exit-code -- api/WisdomUI.api.json` 绿
- [ ] `CHANGELOG.md` 已更新（Breaking 段含迁移片段）

## 契约与无障碍

- [ ] 新组件已写 `contracts/acceptance.yaml` 条目 + `preview-cases.yaml` 用例名
- [ ] 语义槽位按 `../wisdomdesign/docs/06-accessibility.md` §3.3 全表（label/value/traits/隐藏/合并/错误态）
- [ ] 播报/触觉已登记（无 / 一次 / 频控阈值），走 `announcement-cases.json`
- [ ] 容器高度/文本行盒的断言对象已写清（字段盒 / 行盒 / 组件容器是**三张表**）

## 证据

- 截图/日志/命令输出：______
