import SwiftUI

/// 正例（R2/R14）：Primitives 只用 Foundation + Internal，不 import UIKit。
public struct WDButton: View {
    public var body: some View { Color.clear }
}

/// 正例（R13b）：`static var` 只允许出现在 ButtonStyle/ToggleStyle/ViewModifier
/// 的 `where Self ==` 计算型工厂里（无初始化器）。
extension ButtonStyle where Self == WDButtonStyle {
    public static var wdFilled: WDButtonStyle { WDButtonStyle() }
}
