import SwiftUI

/// 反例（R1）：Foundation 层出现组件类型名。
public enum R1ComponentLeak {
    public static let button: WDButton.Type = WDButton.self
}
