import SwiftUI

/// 正例（R15）：非白名单目录里的**契约键名**字面量（SPEC §3.7 的 I41：「其余只允许『标识符/键名』」）。
/// 键名用 `.` / `-` / `_` 连接——这些字符在 R15 的标点集里，但键名不是文案，不判。
/// 反面对照 = `R15_punctuation_literal.swift`（`、` 与词序模板仍必须命中）。
public enum R15KeyNameLiteral {
    public static let slotPaths: [String] = ["text.primary", "surface.card-solid", "fill.pressed"]
    public static let schemeNames: [String] = ["light", "dark"]
    public static let dashed = "hairline-strong"
}
