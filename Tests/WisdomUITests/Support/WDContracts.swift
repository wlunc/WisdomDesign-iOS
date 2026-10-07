import Foundation
import WisdomUI

// 契约读取与跨仓自证（I-M0-g；SPEC §1.5.4-2 / §1.5.4-3）。
//
// 两条纪律（SPEC §1.5.4-2）：
//   ① **解析失败必须 fail，不得 skip**（同 U14/REL-8）——所有入口一律 `throws`，调用方用 `try`；
//   ② 路径解析顺序 = 环境变量 → `#filePath` 上溯（Tests → iOS → workspace）→ 抛错。

/// 契约 / 令牌 manifest 读取失败。**一律抛出，不返回 nil、不 skip**。
public enum WDContractsError: Error {
  /// 按所有候选路径都没找到契约目录（`searched` 给实际找过的路径，便于 CI 定位）。
  case notFound(searched: [String])
  /// JSON 存在但解不开。
  case decodeFailed(URL, Error)
  /// 跨仓 `tokens.manifest.json` 缺失（SPEC §1.5.4-3：**缺失 = fail**）。
  case missingTokenManifest(searched: [String])
}

/// `wisdomdesign/dist/tokens.manifest.json` 的镜像（SPEC §1.5.4-3 指定的四个字段）。
public struct WDTokenManifest: Decodable, Sendable {
  /// 一条生成物（iOS / Android 各端）的路径与内容哈希。
  public struct Artifact: Decodable, Sendable {
    /// 工作区相对路径（如 `iOS/Sources/WisdomUI/Foundation/generated/WDTokens.swift`）。
    public let path: String
    /// 该文件的 SHA-256。
    public let sha256: String
  }

  /// 令牌变更集版本（= `tokens/wisdom.tokens.json` 的 `$version`）。
  public let version: String
  /// 令牌源文件字节的 SHA-256。
  public let sha256: String
  /// 上面那个值的前 12 位；**跨仓同批自证就是断言它与 `WDTokensVersion.sha12` 相等**。
  public let sha12: String
  /// 本次生成覆盖的全部产物。
  public let artifacts: [Artifact]
}

/// 契约与跨仓自证的读取入口（测试支持代码；**不进发布 product**）。
public enum WDContracts {
  /// 契约真源目录（`wisdomdesign/contracts`；M0-5 起由架构师落库）。
  ///
  /// 解析顺序：① 环境变量 `WD_CONTRACTS_DIR`（CI 侧显式导出）② `#filePath` 上溯
  /// （Tests → iOS → workspace）③ 都没有 ⇒ `WDContractsError.notFound`。
  public static func locate() throws -> URL {
    var searched: [String] = []
    let environment = ProcessInfo.processInfo.environment
    if let raw = environment["WD_CONTRACTS_DIR"], !raw.isEmpty {
      let url = URL(fileURLWithPath: raw).standardizedFileURL
      if isDirectory(url) { return url }
      searched.append(url.path)
    }
    for candidate in searchUp(relativePath: "wisdomdesign/contracts") {
      if isDirectory(candidate) { return candidate }
      searched.append(candidate.path)
    }
    throw WDContractsError.notFound(searched: searched)
  }

  /// 读设计仓的 `dist/tokens.manifest.json`（随设计仓 tag 冻结）。
  ///
  /// **缺失 = fail**（SPEC §1.5.4-3）：抛 `WDContractsError.missingTokenManifest`，调用方
  /// **不得**把它当成 skip（swift-testing 里 `try` 抛出即失败）。路径可用
  /// `WD_TOKENS_MANIFEST` 覆盖。
  public static func tokenManifest() throws -> WDTokenManifest {
    var searched: [String] = []
    var candidates: [URL] = []
    let environment = ProcessInfo.processInfo.environment
    if let raw = environment["WD_TOKENS_MANIFEST"], !raw.isEmpty {
      candidates.append(URL(fileURLWithPath: raw).standardizedFileURL)
    }
    candidates.append(contentsOf: searchUp(relativePath: "wisdomdesign/dist/tokens.manifest.json"))

    for url in candidates {
      guard FileManager.default.fileExists(atPath: url.path) else {
        searched.append(url.path)
        continue
      }
      do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WDTokenManifest.self, from: data)
      } catch {
        throw WDContractsError.decodeFailed(url, error)
      }
    }
    throw WDContractsError.missingTokenManifest(searched: searched)
  }

  // MARK: - 未实现（等 M0-5 的 contracts/dist/*.json）
  //
  // SPEC §1.5.4-2 还列了三个读契约 JSON 的入口：previewCaseNames() / acceptanceComponents() /
  // componentTypeNames()。它们读的是 contracts/dist/*.json（由 build.js 的 --emit-contracts-json
  // 从 contracts/*.yaml 镜像而来），而**该目录与 JSON schema 属 M0-5 的交付物**（设计仓当前
  // 没有 contracts/）——文件切分与字段名都还没定，先写就是**替架构师发明契约**，故留空。
  // 落地条件：contracts/dist/*.json 入库 + 一份字段说明；届时按同一套 locate() + Decodable 补上。

  // MARK: - 内部

  /// 从 `#filePath` 所在目录逐级上溯，产出 `<祖先>/<relativePath>` 的全部候选。
  private static func searchUp(relativePath: String) -> [URL] {
    var results: [URL] = []
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().standardizedFileURL
    for _ in 0..<6 {
      results.append(directory.appendingPathComponent(relativePath).standardizedFileURL)
      let parent = directory.deletingLastPathComponent()
      if parent.path == directory.path { break }
      directory = parent
    }
    return results
  }

  /// 目录存在性（用 `isDirectory` 而不是 `fileExists`：同名文件不算命中）。
  private static func isDirectory(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
  }
}
