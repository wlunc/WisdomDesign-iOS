import Foundation

/// 反例（R5）：Internal 引用了 Composites。
struct R5BadDependency {
    let host = Composites.WDInternalBridge()
}
