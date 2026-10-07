import SwiftUI

/// 反例（R13b）：计算型 static var 出现在非样式工厂扩展里。
public enum R13bBadFactory {
    public static var badge: String { "bad" }
}
