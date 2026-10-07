# Scripts/Fixtures/structure —— 结构检查器固定样本（SPEC §1.1.1 驱动③）

样本**只被检查器读取，不参与包编译**（不在任何 target 的 `path` 下）。两棵树各是一份"迷你仓"，
路径按真实层级摆放（`Sources/WisdomUI/{Foundation,Components/{Primitives,Composites,Patterns},Internal}`、`Tests/…`），
因为 R1–R6/R8/R9/R12 是**路径相关**规则。

| 目录 | 约定 |
| --- | --- |
| `pass/` | 正例：整棵树对 R1–R21 **零命中**；每条规则另有 `R<id>_*.swift` 专题样本 |
| `fail/` | 反例：每条规则一个 `R<id>_*.swift` 专用样本（R4 是目录级规则，样本 = `Components/Patterns/`） |

自证方式：`Scripts/test-checker.sh`（逐规则一正一反 + 退出码 + 专用样本归属 + 整树覆盖 + 豁免语法 + 生成物大小写）。

覆盖的边界情形：
- **豁免语法**：`R1_exempt_directive.swift`（有理由 ⇒ 生效）vs `R1_exempt_without_reason.swift`（无理由 ⇒ 不生效）；
- **生成物目录大小写**：`Generated/R12_no_banner_uppercase.swift` 与 `generated/R12_no_banner_lowercase.swift`
  都必须被判为生成物（M0 生成器改造前后两种形态，本任务不做目录重命名）。
