import SwiftUI

/// 反例（R3）：Composites 引用了已删除的 Patterns 层。
public struct R3BadDependency {
    public let host: Patterns.AnyPattern
}
