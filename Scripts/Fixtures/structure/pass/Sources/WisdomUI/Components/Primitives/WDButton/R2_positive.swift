import SwiftUI

/// 正例（R2）：Primitives 只依赖 Foundation + Internal，不引用 Composites。
public struct R2PositivePrimitive: View {
    public var body: some View { Color.clear }
}
