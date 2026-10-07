import SwiftUI

/// 反例（R4）：Components/Patterns/ 存在即 error（目录级判定，不依赖文件内容）。
public struct R4PatternSample: View {
    public var body: some View { Color.clear }
}
