import SwiftUI

/// 反例（R11）：绕过 wdFont(_:) 直接用系统字体入口。
public struct R11BadFont: View {
    private let pointSize: CGFloat

    public init(pointSize: CGFloat) { self.pointSize = pointSize }

    public var body: some View {
        Text(verbatim: "ok")
            .font(.system(size: pointSize))
            .frame(minHeight: WDHeight.row)
    }
}
