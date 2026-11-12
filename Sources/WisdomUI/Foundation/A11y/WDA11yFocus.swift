import UIKit

/// 无障碍焦点移动（内部；Components 不直接 import UIKit，统一走这里）。
@MainActor
enum WDA11yFocus {
  /// 弹层出现：把焦点移到新出现的模态内容（系统会选第一个可达元素）。
  static func screenChanged() {
    UIAccessibility.post(notification: .screenChanged, argument: nil)
  }
}
