import SwiftUI

/// 反例（R9）：固定高度绑令牌常量，挡住动态字体增长。
public struct R9BadFrame: View {
    public var body: some View {
        Color.clear
            .frame(height: WDHeight.row)
    }
}
