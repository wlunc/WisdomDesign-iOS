import SwiftUI

/// 正例（R14）：组件层不 import UIKit（UIKit 只允许 Foundation/Typography 与 Internal）。
public struct R14PositiveChip: View {
    public var body: some View { Color.clear }
}
