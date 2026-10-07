import SwiftUI

/// 反例（R16）：库内覆写平台外观 / 无障碍设置。
public struct R16BadOverride: View {
    public var body: some View {
        Color.clear
            .preferredColorScheme(.dark)
            .environment(\.dynamicTypeSize, .large)
    }
}
