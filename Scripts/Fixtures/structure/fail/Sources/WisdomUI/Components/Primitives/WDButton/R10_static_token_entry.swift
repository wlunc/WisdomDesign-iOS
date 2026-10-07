import SwiftUI

/// 反例（R10）：组件里直接用静态令牌入口。
public struct R10BadToken: View {
    public var body: some View { WDColor.textPrimary }
}
