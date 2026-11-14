import SwiftUI

/// 菜单勾（画廊 22 的 lucide check：24 viewBox 的 M20 6 9 17l-5-5，round cap/join）。
///
/// 放在 Internal：几何是第三方图标的原始坐标，数值字面量不属于"组件私有魔数"（R7 白名单）。
struct WDPickerCheckmark: Shape {
  func path(in rect: CGRect) -> Path {
    let scale = rect.width / 24
    var path = Path()
    path.move(to: CGPoint(x: 20 * scale, y: 6 * scale))
    path.addLine(to: CGPoint(x: 9 * scale, y: 17 * scale))
    path.addLine(to: CGPoint(x: 4 * scale, y: 12 * scale))
    return path
  }
}
