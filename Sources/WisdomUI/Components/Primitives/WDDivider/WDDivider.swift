import SwiftUI

/// 分割线（SPEC §2.10-#14；M2）。
///
/// 设计口径（设计 14）：1pt 高、`border.hairline`、无圆角、无状态、**不进无障碍树**。
/// 冻结签名只有 `init()` ⇒ **只实现全宽档**；内缩 62 档由 `WDListRow` 自带的分隔线负责
/// （差异已登记在 `docs/DEV-PLAN.md` §2.3）。
public struct WDDivider: View {
  @Environment(\.wdColors) private var colors

  /// 构造（装饰件，无参数）。
  public init() {}

  /// 渲染：一条全宽的 hairline。
  public var body: some View {
    Rectangle()
      .fill(colors.borderHairline)
      .frame(height: 1)
      .frame(maxWidth: .infinity)
      .accessibilityHidden(true)
  }
}
