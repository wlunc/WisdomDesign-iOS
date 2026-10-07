import SwiftUI
import UIKit

/// 反例（R14）：Components 层 import UIKit。
public struct R14BadImport: View {
    public var body: some View { Color.clear }
}
