import SwiftUI

/// 正例（R17）：含 Text 存储字段的公开类型只到 Equatable/Sendable，不声明 Hashable。
public struct R17PositiveLabel: Equatable, Sendable {
    public let title: Text

    public init(title: Text) { self.title = title }
}
