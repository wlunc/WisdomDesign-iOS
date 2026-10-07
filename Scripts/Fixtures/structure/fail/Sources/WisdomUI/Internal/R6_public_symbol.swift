import Foundation

/// 反例（R6）：Internal 出现 public（内部实现必须零公开面）。
public struct R6PublicSymbol {
    public init() {}
}
