import SwiftUI

/// 反例（R13a）：类型擦除 + 带初始化器的存储型静态可变状态。
public struct R13aBadContainer: View {
    public static var shared = R13aBadContainer()

    public var body: some View { AnyView(Color.clear) }
}
