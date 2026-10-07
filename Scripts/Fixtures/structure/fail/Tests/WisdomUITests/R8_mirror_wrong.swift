import Testing
@testable import WidgetKit
import WisdomUI

/// 反例（R8）：@testable import 引用了非被测层。
@Suite("R8")
struct R8MirrorWrong {
    @Test("引用层错误")
    func reference() {}
}
