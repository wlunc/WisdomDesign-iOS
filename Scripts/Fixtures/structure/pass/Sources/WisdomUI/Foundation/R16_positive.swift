import SwiftUI

/// 正例（R16）：库不覆写平台设置，只做读取。
public enum R16PositivePlatformSettings {
    public static func isDark(_ scheme: ColorScheme) -> Bool { scheme == .dark }
}
