import SwiftUI

/// 反例（R21）：Text 的最近容器既没有令牌 minHeight 也没有 .wdLineBox(...)。
public struct R21BadLabel: View {
    public var body: some View {
        Text(verbatim: "bad")
    }
}
