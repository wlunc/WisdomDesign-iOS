import SwiftUI

/// 正例（R10）：颜色只走 Environment 槽位，不写静态令牌入口 WDColor.。
public struct R10PositiveSurface: View {
  @Environment(\.wdColors) private var colors

  public var body: some View { colors.surfaceCard }
}

/// 正例（R10 **收窄后**）：**字阶不在禁列** —— 字号不可主题化（SPEC §3.1），
/// 且 `wdFont(_:)` 的唯一参数就是 `WDTextStyle`；禁掉 `WDType.` 会让合法写法不存在。
public struct R10PositiveTypeStyle: View {
  public var body: some View {
    Text(verbatim: "x")
      .wdFont(WDType.body)
      .wdLineBox(WDType.body)
  }
}
