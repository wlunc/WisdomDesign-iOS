import SwiftUI

/// 正例（R1）：标识符边界——`WDIconName` / `WDButtonStyle` / `MyWDButton` 都不是组件类型名本身。
public enum R1PositiveBoundary {
    public static let icon: WDIconName? = nil
    public static let style: WDButtonStyle? = nil
    public static let legacy: MyWDButton.Type? = nil
}
