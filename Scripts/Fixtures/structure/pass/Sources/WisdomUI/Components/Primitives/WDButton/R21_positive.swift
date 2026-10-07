import SwiftUI

/// 正例（R21）：Text 的最近容器给了令牌 minHeight，行盒可随动态字体增长。
public struct R21PositiveLabel: View {
    public var body: some View {
        Text(verbatim: "ok")
            .frame(minHeight: WDHeight.row)
    }
}
