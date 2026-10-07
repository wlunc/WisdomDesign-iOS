import Testing
import WisdomUI

/// 跨仓同批自证（SPEC §1.5.4-3 / §9.2 的 I-M0-g）。
///
/// 纪律：**manifest 缺失 = fail，不 skip** —— 所以这两个用例都直接 `try`，没有
/// `try?` / `XCTSkip` 之类的软化；设计仓没 checkout 时它们就是红的（有意为之）。
@Suite("契约与跨仓自证")
struct WDContractsTests {
  @Test("令牌 manifest 与生成物同批（sha12 相等）")
  func tokenManifestMatchesGeneratedTokens() throws {
    let manifest = try WDContracts.tokenManifest()
    #expect(manifest.sha12 == WDTokensVersion.sha12)
    #expect(manifest.sha256 == WDTokensVersion.sha256)
    #expect(manifest.version == WDTokensVersion.version)
    #expect(manifest.artifacts.isEmpty == false)
  }

  @Test("manifest 覆盖 iOS 端三件生成物")
  func manifestCoversIOSArtifacts() throws {
    let manifest = try WDContracts.tokenManifest()
    let iOSPaths = manifest.artifacts.map(\.path).filter { $0.hasPrefix("iOS/") }
    #expect(iOSPaths.count >= 3)
    for name in ["WDTokens.swift", "WDTokensVersion.swift", "WDColorSlots.swift"] {
      #expect(iOSPaths.contains { $0.hasSuffix(name) })
    }
  }
}
