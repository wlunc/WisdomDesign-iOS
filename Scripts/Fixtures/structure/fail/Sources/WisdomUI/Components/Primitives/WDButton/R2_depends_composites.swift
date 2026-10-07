import SwiftUI

/// 反例（R2）：Primitives 引用了 Composites 层。
public struct R2BadDependency {
    public let host: Composites.AnyCard
}
