import Testing
@testable import WisdomUI

/// 反例（R8）：测试目录在被测层没有对应目录（Sources/WisdomUI/Motion 不存在）。
@Suite("R8-mirror")
struct R8MirrorMissingLayer {
    @Test("镜像目录缺失")
    func reference() {}
}
