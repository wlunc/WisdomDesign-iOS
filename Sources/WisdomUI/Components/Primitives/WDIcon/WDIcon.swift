import SwiftUI

/// 图标（SPEC §2.10-#20；M2 首批）。
///
/// - 语义名由契约承载（`WDIconName`，生成物）：iOS 按名取 SF Symbols（F-07）。
/// - 尺寸走 `WDIconMetrics` 的手写映射，**不随动态字体放大**（设计：图标尺寸锁死）。
/// - **装饰件：不进无障碍树**（SPEC §2.10-#20 的"装饰：不进树"）。
/// - **不设颜色**：由容器用 `foregroundStyle(_:)` 给（图标颜色在设计里是槽位语义，
///   属于宿主组件；这样 `WDTextField` 的前缀图标能自动拿到 `text.tertiary`）。
public struct WDIcon: View {
  private let icon: WDIconName
  private let size: WDIconSize

  /// 构造（SPEC §2.10-#20；`size` 默认 `.md` —— 设计文档里 md=20 是主用档）。
  public init(icon: WDIconName, size: WDIconSize = .md) {
    self.icon = icon
    self.size = size
  }

  /// 渲染：SF Symbols 按契约里的符号名取图。
  public var body: some View {
    Image(systemName: icon.symbolName)
      .font(WDIconMetrics.font(for: size))
      .accessibilityHidden(true)
  }
}
