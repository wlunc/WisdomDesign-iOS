import SwiftUI

/// 正例（R7）：0/1/-1、数组索引、.opacity(、zIndex、lineLimit、#available 版本号都在豁免面内。
public enum R7PositiveExemptions {
    public static let zero = 0
    public static let one = 1
    public static let negativeOne = -1
    public static let indexed = [0, 1][1]
}

public struct R7PositiveView: View {
    public var body: some View {
        Color.clear
            .opacity(0.5)
            .zIndex(2)
    }
}

public enum R7PositiveAvailability {
    public static func isSupported() -> Bool {
        if #available(iOS 17, *) { return true }
        return false
    }
}
