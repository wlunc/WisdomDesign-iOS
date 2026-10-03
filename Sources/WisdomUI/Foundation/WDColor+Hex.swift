import SwiftUI

// 生成代码用到的颜色构造器。手写文件，不属于生成产物。

extension Color {
    /// 单值颜色，不随深浅色变化。
    init(wd hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// 浅深成对颜色。跟随系统外观切换，不需要主题对象。
    init(wdLight light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            return UIColor(
                red: CGFloat((isDark ? dark : light) >> 16 & 0xFF) / 255,
                green: CGFloat((isDark ? dark : light) >> 8 & 0xFF) / 255,
                blue: CGFloat((isDark ? dark : light) & 0xFF) / 255,
                alpha: CGFloat(isDark ? darkAlpha : lightAlpha)
            )
        })
    }
}
