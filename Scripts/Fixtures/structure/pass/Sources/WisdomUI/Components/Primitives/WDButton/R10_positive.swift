import SwiftUI

/// 正例（R10）：颜色只走 Environment 槽位，不写静态令牌入口 WDColor./WDType.。
public struct R10PositiveSurface: View {
    @Environment(\.wdColors) private var colors

    public var body: some View { colors.surfaceCard }
}
