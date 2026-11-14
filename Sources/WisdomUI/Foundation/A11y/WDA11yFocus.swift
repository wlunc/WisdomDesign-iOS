import UIKit

/// 无障碍焦点移动（内部；Components 不直接 import UIKit，统一走这里）。
@MainActor
enum WDA11yFocus {
  /// 弹层出现：把焦点移到新出现的模态内容（系统会选第一个可达元素）。
  static func screenChanged() {
    UIAccessibility.post(notification: .screenChanged, argument: nil)
  }

  /// 弹层出现前：捕获当前读屏焦点元素，供关闭后归还。
  static func captureFocusedElement() -> Any? {
    UIAccessibility.focusedElement(using: nil)
  }

  /// 弹层关闭：把焦点还给它出现前的元素（设计 25 的焦点归入/归还）。
  static func restoreFocus(_ element: Any?) {
    guard let element else { return }
    UIAccessibility.post(notification: .layoutChanged, argument: element)
  }
}
