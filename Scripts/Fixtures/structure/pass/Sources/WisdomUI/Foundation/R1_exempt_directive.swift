import SwiftUI

public enum R1ExemptionSample {
    /// 正例（豁免语法）：本行原本命中 R1，同行的 disable 指令（带理由）把它豁免掉。
    public static let leaked: WDButton.Type? = nil  // wd-structure-check:disable R1 — 豁免语法演练：fail 树另有"无理由不生效"的对照样本
}
