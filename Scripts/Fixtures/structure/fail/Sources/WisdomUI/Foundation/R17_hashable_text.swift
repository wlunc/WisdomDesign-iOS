import SwiftUI

/// 反例（R17）：含 Text 存储字段的公开类型误声明 Hashable。
public struct R17BadLabel: Hashable {
    public let title: Text
    public let count: Int
}
