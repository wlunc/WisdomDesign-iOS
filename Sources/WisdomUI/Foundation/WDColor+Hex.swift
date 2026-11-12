import SwiftUI

// 生成代码用到的颜色构造器。手写文件，不属于生成产物。

extension Color {
  /// 单值颜色，不随深浅色变化。
  init(wd hex: UInt32, alpha: Double = 1) {
    let red = Double((hex >> 16) & 0xFF) / 255  // wd-structure-check:disable R7 — 十六进制解码
    let green = Double((hex >> 8) & 0xFF) / 255  // wd-structure-check:disable R7 — 十六进制解码
    let blue = Double(hex & 0xFF) / 255  // wd-structure-check:disable R7 — 十六进制解码
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
  }

  /// 浅深成对颜色。跟随系统外观切换，不需要主题对象。
  init(wdLight light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) {
    self.init(
      uiColor: UIColor { traits in
        let isDark = traits.userInterfaceStyle == .dark
        let value = isDark ? dark : light
        let red = CGFloat((value >> 16) & 0xFF) / 255  // wd-structure-check:disable R7 — 十六进制解码
        let green = CGFloat((value >> 8) & 0xFF) / 255  // wd-structure-check:disable R7 — 十六进制解码
        let blue = CGFloat(value & 0xFF) / 255  // wd-structure-check:disable R7 — 十六进制解码
        return UIColor(
          red: red, green: green, blue: blue, alpha: CGFloat(isDark ? darkAlpha : lightAlpha)
        )
      })
  }
}
