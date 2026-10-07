import SwiftUI

/// 正例（R20）：公开协议不同时要求 @MainActor 与 Sendable（二选一，见 SPEC §1.2.1）。
public protocol R20PositiveGateway: Sendable {
    func post(_ value: String)
}
