import Foundation

/// 正例（R6）：Internal 零 public（内部实现不进公开面）。
enum R6PositiveInternal {
    static func scaled(_ value: Double) -> Double { value }
}
