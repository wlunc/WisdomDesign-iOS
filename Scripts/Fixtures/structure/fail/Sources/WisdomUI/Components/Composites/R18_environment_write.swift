import SwiftUI

/// 反例（R18）：组件里写 Environment（写入口只允许 Foundation/Theme 的 View 修饰符）。
public struct R18BadWrite: View {
    public var body: some View {
        Color.clear
            .environment(\.wdDensity, .compact)
    }
}
