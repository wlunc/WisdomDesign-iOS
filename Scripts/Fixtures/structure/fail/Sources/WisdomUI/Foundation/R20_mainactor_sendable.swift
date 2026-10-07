import SwiftUI

/// 反例（R20）：公开协议同时要求 @MainActor 与 Sendable（#ConformanceIsolation 编译错误）。
@MainActor
public protocol R20BadGateway: Sendable {
    func post(_ value: String)
}
