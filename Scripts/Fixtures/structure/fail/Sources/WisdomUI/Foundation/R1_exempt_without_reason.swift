import SwiftUI

public enum R1ExemptWithoutReason {
    /// 反例（豁免语法）：disable 指令没有理由（分隔符后为空）⇒ 不生效，R1 仍然报。
    public static let leaked: WDButton.Type? = nil  // wd-structure-check:disable R1 —
}
