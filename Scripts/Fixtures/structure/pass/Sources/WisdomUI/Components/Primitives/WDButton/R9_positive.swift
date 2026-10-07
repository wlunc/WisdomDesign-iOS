import SwiftUI

/// 正例（R9）：高度增长靠 minHeight 令牌，不用 .frame(height:)/.frame(width:)。
public struct R9PositiveRow: View {
    public var body: some View {
        Color.clear
            .frame(minHeight: WDHeight.row)
            .frame(maxWidth: .infinity)
    }
}
