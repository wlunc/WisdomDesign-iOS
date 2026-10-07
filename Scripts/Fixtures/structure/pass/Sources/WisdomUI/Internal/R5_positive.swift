import Foundation

/// 正例（R5/R6）：Internal 零 public，不引用 Composites。
struct R5PositiveClamp {
    static func apply(_ value: Double) -> Double { min(max(value, 0), 1) }
}
