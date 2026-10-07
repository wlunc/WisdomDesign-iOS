import SwiftUI

/// 正例（R13b）：`static var` 只允许出现在样式工厂扩展的计算型工厂里（无初始化器）。
extension ButtonStyle where Self == R13bPositiveStyle {
    public static var wdFilled: R13bPositiveStyle { R13bPositiveStyle() }
}
