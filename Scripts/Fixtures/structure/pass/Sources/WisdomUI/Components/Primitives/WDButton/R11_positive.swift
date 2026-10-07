import SwiftUI

/// 正例（R11）：字号唯一入口 wdFont(_:)（字阶从 Environment 取，不用 .font(.system( 或 WDType.）。
/// 注：本行注释里就有 `.font(.system(` 与 `WDType.`，先剥离注释再匹配 ⇒ R10/R11 都不该命中。
public struct R11PositiveLabel: View {
    @Environment(\.wdType) private var type

    public var body: some View {
        Text(verbatim: "ok")
            .wdFont(type.body)
            .frame(minHeight: WDHeight.row)
    }
}
