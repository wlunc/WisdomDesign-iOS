import SwiftUI

/// 正例（R13a）：类型擦除改用泛型；静态常量用 `static let`（不用 AnyView / static var）。
/// 注：本行注释里就有 `AnyView` 与 `static var =`，先剥离注释再匹配 ⇒ 不该命中。
public struct R13aPositiveContainer<Content: View>: View {
    /// 字符串字面量里的 `AnyView` 同样不算代码（先剥离字符串字面量再匹配）。
    public static let debugText = "AnyView"

    private let content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View { content }
}
