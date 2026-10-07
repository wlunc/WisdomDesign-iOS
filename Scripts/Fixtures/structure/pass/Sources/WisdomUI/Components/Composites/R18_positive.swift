import SwiftUI

/// 正例（R18）：组件只读 Environment；写入口只在 Foundation/Theme 的 View 修饰符。
public struct R18PositiveBanner: View {
    @Environment(\.wdEffectsBudget) private var budget

    public var body: some View { Color.clear }
}
