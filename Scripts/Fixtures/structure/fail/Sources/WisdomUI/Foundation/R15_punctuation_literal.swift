import SwiftUI

/// 反例（R15）：字符串字面量带标点 / 词序模板（库内零文案）。
public enum R15BadCopy {
    public static let separator = "、"
    public static let template = "第 1 项"
}
