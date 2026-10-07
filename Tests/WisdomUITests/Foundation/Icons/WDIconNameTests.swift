import Testing
import UIKit

@testable import WisdomUI

/// `WDIconName` 是**生成物**（契约源 = wisdomdesign/contracts/icons.json）。
/// 本套件守的是"生成物没被改坏 / 没漏 / 符号在本平台真的存在"——不重述契约内容。
@MainActor
@Suite("图标契约生成物")
struct WDIconNameTests {
  @Test("条数 == 44（契约计数）")
  func count() {
    #expect(WDIconName.allCases.count == 44)
  }

  @Test("每个语义名在本平台都有对应符号（SF Symbols 存在性）")
  func symbolsExist() {
    let missing = WDIconName.allCases.filter { UIImage(systemName: $0.symbolName) == nil }
    #expect(missing.isEmpty, "在本运行时上取不到符号：\(missing.map { "\($0.rawValue)→\($0.symbolName)" })")
  }

  @Test("rawValue == 语义名（契约键即代码键）")
  func rawValueIsSemanticName() {
    for icon in WDIconName.allCases {
      #expect(icon.rawValue == String(describing: icon))
    }
  }

  @Test("mirrorsInRTL 与集合成员一致，且集合 ⊆ allCases")
  func mirrorFlagConsistent() {
    let declared = WDIconName.mirrorsInRTLNames
    #expect(declared.isSubset(of: Set(WDIconName.allCases)))
    for icon in WDIconName.allCases {
      #expect(icon.mirrorsInRTL == declared.contains(icon))
    }
    // 当前声明值 = 5 条（设计签发契约列后随 icons.json 更新；此断言防"悄悄改动"）
    #expect(declared.count == 5)
  }
}
