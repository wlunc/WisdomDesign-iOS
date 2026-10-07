import Testing
@testable import WisdomUI

/// 正例（R8）：测试目录镜像 Foundation 层，@testable import 指向被测层。
@Suite("R8")
struct R8PositiveMirror {
    @Test("镜像目录存在，引用层正确")
    func reference() {}
}
