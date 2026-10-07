// iOS/Scripts/canonicalize-api.swift —— host 工具（只 import Foundation）
//
// I-M0-e：把 `swift-symbolgraph-extract` 的**原始**输出规范化，供 `api/WisdomUI.api.json` 入库。
// 口径：iOS/docs/SPEC.md §1.5.3 ——
//   · 条目只保留 `{kind, path, decl, access}`；
//   · **丢弃** `usr` / `location` / `docComment` / `mixins` / `relationships` / `accessibility` / `spi`
//     （以及 `declarationFragments` 里的 `preciseIdentifier` = USR，否则 Xcode 升级即全量红）；
//   · 按 `path` 排序（本实现按 `path` → `kind` → `decl` 三级排序，保证重跑零 diff）；
//   · 文件头记录工具链身份 `{xcode, sdk, swift, target, module}`。
//
// 用法（可以给多个输入：`swift-symbolgraph-extract` 会把"本模块声明"与
// "对其它模块类型的扩展"分成 `<Module>.symbols.json` 与 `<Module>@<ExtendedModule>.symbols.json`
// —— 后者承载 `View.wdShadow` / `.wdSheet` 这类**扩展公开 API**，漏掉会让基线不完整）：
//   swift Scripts/canonicalize-api.swift <raw.symbols.json> [<raw@Ext.symbols.json> …]
//                                    [--module WisdomUI] [--target <triple>]
//                                    [--exclude-source <源文件后缀>]… [--source-root <源码根子串>]…
// 输出：规范化 JSON 到 stdout（失败 = 非 0 退出码 + stderr 说明）。

import Foundation

// MARK: - 工具链身份

/// 工具链身份（进基线文件头；只记版本号，不记本机绝对路径）。
struct Toolchain {
  var xcodeVersion: String
  var xcodeBuild: String
  var sdkName: String
  var swiftVersion: String

  static func detect(sdk: String?, swift: String?) -> Toolchain {
    let xcodeRaw = run("/usr/bin/xcodebuild", ["-version"]) ?? ""
    let xcodeLines = xcodeRaw.split(separator: "\n").map { String($0) }
    let versionLine = xcodeLines.first(where: { $0.hasPrefix("Xcode ") }) ?? ""
    let buildLine = xcodeLines.first(where: { $0.hasPrefix("Build version ") }) ?? ""

    let sdkVersion =
      sdk
      ?? run("/usr/bin/xcrun", ["--sdk", "iphonesimulator", "--show-sdk-version"])?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let swiftRaw = swift ?? run("/usr/bin/swift", ["--version"]) ?? ""

    return Toolchain(
      xcodeVersion: versionLine.replacingOccurrences(of: "Xcode ", with: "").isEmpty
        ? "unknown" : versionLine.replacingOccurrences(of: "Xcode ", with: ""),
      xcodeBuild: buildLine.replacingOccurrences(of: "Build version ", with: "").isEmpty
        ? "unknown" : buildLine.replacingOccurrences(of: "Build version ", with: ""),
      sdkName: (sdkVersion?.isEmpty ?? true) ? "unknown" : "iphonesimulator\(sdkVersion ?? "")",
      swiftVersion: parseSwiftVersion(swiftRaw)
    )
  }

  private static func parseSwiftVersion(_ raw: String) -> String {
    // 形如 "swift-driver version: 1.148.6 Apple Swift version 6.3.3 (...)"
    guard let range = raw.range(of: "Swift version ") else { return "unknown" }
    let rest = raw[range.upperBound...]
    let token = rest.prefix { $0 != " " && $0 != "(" }
    return token.isEmpty ? "unknown" : String(token)
  }
}

/// 运行一个 host 命令并返回 stdout（失败返回 nil；stderr 丢弃）。
func run(_ launchPath: String, _ arguments: [String]) -> String? {
  guard FileManager.default.isExecutableFile(atPath: launchPath) else { return nil }
  let process = Process()
  process.executableURL = URL(fileURLWithPath: launchPath)
  process.arguments = arguments
  let out = Pipe()
  process.standardOutput = out
  process.standardError = Pipe()
  do {
    try process.run()
  } catch {
    return nil
  }
  let data = out.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  guard process.terminationStatus == 0 else { return nil }
  return String(decoding: data, as: UTF8.self)
}

// MARK: - 规范化

/// 一条规范化的符号条目。
struct CanonicalSymbol: Comparable {
  let kind: String
  let path: String
  let decl: String
  let access: String

  static func < (lhs: CanonicalSymbol, rhs: CanonicalSymbol) -> Bool {
    if lhs.path != rhs.path { return lhs.path < rhs.path }
    if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
    return lhs.decl < rhs.decl
  }
}

/// 单行化声明文本：拼接 `declarationFragments[*].spelling`（**不取** `preciseIdentifier`）。
func canonicalDeclaration(_ symbol: [String: Any]) -> String {
  guard let fragments = symbol["declarationFragments"] as? [[String: Any]] else { return "" }
  let joined = fragments.compactMap { $0["spelling"] as? String }.joined()
  return
    joined
    .replacingOccurrences(of: "\n", with: " ")
    .split(separator: " ", omittingEmptySubsequences: true)
    .joined(separator: " ")
}

/// 源位置（`location.uri`，百分号解码后）。只用于过滤，**不进输出**。
func sourceLocation(of symbol: [String: Any]) -> String {
  let uri = ((symbol["location"] as? [String: Any])?["uri"] as? String) ?? ""
  return uri.removingPercentEncoding ?? uri
}

/// 第一遍：被排除源文件**声明的顶层路径段**（= 该文件里声明的类型名）。
///
/// 为什么需要：冒烟文件里的 `struct WDTextField: View` 之类会让 `swift-symbolgraph-extract`
/// 在**扩展图**里为冒烟类型合成条目（如 `WDTextField.wdShadow(_:)`），而这些条目的 `location`
/// 指向本仓的**真实**文件（`WDTokenTypes.swift`）⇒ 规则 C 抓不到。用"该文件声明的类型名"做前缀
/// 剔除，既自维护（不需要手写名单），也不会误伤：没有冒烟时该集合为空。
func excludedTypeRoots(in symbols: [[String: Any]], excludingSources: [String]) -> Set<String> {
  guard !excludingSources.isEmpty else { return [] }
  // 只有"声明**新类型**"的条目才作为前缀：`extension View { … }` 的 pathComponents[0] 是 SDK 类型名
  // （`View`），若一并当前缀会把真实的 `View.wdShadow(_:)` 误删。
  let typeKinds: Set<String> = [
    "swift.struct", "swift.enum", "swift.class", "swift.protocol", "swift.actor", "swift.typealias",
  ]
  var roots: Set<String> = []
  for symbol in symbols {
    let location = sourceLocation(of: symbol)
    guard excludingSources.contains(where: { location.hasSuffix($0) }) else { continue }
    let kind = ((symbol["kind"] as? [String: Any])?["identifier"] as? String) ?? ""
    guard typeKinds.contains(kind) else { continue }
    if let first = (symbol["pathComponents"] as? [String])?.first {
      roots.insert(first)
    }
  }
  return roots
}

func canonicalSymbols(
  from rawSymbols: [[String: Any]],
  excludingSources: [String],
  excludedTypeRoots: Set<String>,
  sourceRoots: [String]
) -> [CanonicalSymbol] {
  var out: [CanonicalSymbol] = []
  for symbol in rawSymbols {
    // SPI 不进公开面
    if (symbol["spi"] as? Bool) == true { continue }

    let location = sourceLocation(of: symbol)

    // 规则 A：没有源位置的条目不是"我们声明的公开面"。
    // 判定依据（[实测]）：无冒烟时 157/157 条都带 location；带 `WD_API_SMOKE` 时多出的 2359 条
    // （`WDTextField.searchable(…)` 之类的系统继承成员）全部**无 location** ⇒ 一律剔除。
    if location.isEmpty { continue }

    // 规则 B：只保留声明落在指定源码根内的符号（防止把外模块位置误收进基线）。
    if !sourceRoots.isEmpty, !sourceRoots.contains(where: { location.contains($0) }) { continue }

    // 规则 C：按**源文件**排除签名冒烟文件。
    // PR-1 的 build-for-testing 带 `WD_API_SMOKE`，而 PR-2 复用同一份 DerivedData 且不额外编译
    // ⇒ 该模块里含冒烟声明；冒烟不是发布面，必须剔除，否则基线随 PR-1 的标志漂移。
    if excludingSources.contains(where: { location.hasSuffix($0) }) { continue }

    let access = (symbol["accessLevel"] as? String) ?? "public"
    guard access == "public" else { continue }
    let kindContainer = symbol["kind"] as? [String: Any]
    let kind = (kindContainer?["identifier"] as? String) ?? "unknown"
    let pathComponents = (symbol["pathComponents"] as? [String]) ?? []
    guard !pathComponents.isEmpty else { continue }

    // 规则 D：剔除由被排除源文件声明的类型派生的合成条目（见 excludedTypeRoots 注释）。
    if let first = pathComponents.first, excludedTypeRoots.contains(first) { continue }

    out.append(
      CanonicalSymbol(
        kind: kind,
        path: pathComponents.joined(separator: "."),
        decl: canonicalDeclaration(symbol),
        access: access
      )
    )
  }
  return out.sorted()
}

// MARK: - 入口

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("canonicalize-api: \(message)\n".utf8))
  exit(2)
}

var arguments = Array(CommandLine.arguments.dropFirst())
var module = "WisdomUI"
var target = "arm64-apple-ios17.0-simulator"
var sdkVersion: String?
var swiftVersion: String?
var inputs: [String] = []
var excludedSources: [String] = []
var sourceRoots: [String] = []

var index = 0
while index < arguments.count {
  let argument = arguments[index]
  switch argument {
  case "--module":
    index += 1
    guard index < arguments.count else { fail("--module 缺少参数") }
    module = arguments[index]
  case "--target":
    index += 1
    guard index < arguments.count else { fail("--target 缺少参数") }
    target = arguments[index]
  case "--exclude-source":
    index += 1
    guard index < arguments.count else { fail("--exclude-source 缺少参数") }
    excludedSources.append(arguments[index])
  case "--source-root":
    index += 1
    guard index < arguments.count else { fail("--source-root 缺少参数") }
    sourceRoots.append(arguments[index])
  case "--sdk-version":
    index += 1
    guard index < arguments.count else { fail("--sdk-version 缺少参数") }
    sdkVersion = arguments[index]
  case "--swift-version":
    index += 1
    guard index < arguments.count else { fail("--swift-version 缺少参数") }
    swiftVersion = arguments[index]
  case "--help", "-h":
    print(
      """
      canonicalize-api —— 规范化 swift-symbolgraph-extract 输出（SPEC §1.5.3）
      用法：swift Scripts/canonicalize-api.swift <raw.symbols.json> [--module M] [--target T]
      """
    )
    exit(0)
  default:
    if argument.hasPrefix("--") { fail("未知参数 '\(argument)'") }
    inputs.append(argument)
  }
  index += 1
}

guard !inputs.isEmpty else { fail("需要至少 1 个输入文件（--help）") }
var rawSymbols: [[String: Any]] = []
for input in inputs {
  let inputURL = URL(fileURLWithPath: input)
  guard let data = try? Data(contentsOf: inputURL) else { fail("读不到输入文件 \(input)") }
  guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    fail("输入不是合法 JSON：\(input)")
  }
  rawSymbols.append(contentsOf: (root["symbols"] as? [[String: Any]]) ?? [])
}

// 第一遍：算出"被排除源文件声明的类型名"（规则 D 的前缀集合）。
let typeRootsToDrop = excludedTypeRoots(in: rawSymbols, excludingSources: excludedSources)

// 第二遍：规范化 + 去重。
var merged: [CanonicalSymbol] = []
var seen = Set<String>()
for symbol in canonicalSymbols(
  from: rawSymbols,
  excludingSources: excludedSources,
  excludedTypeRoots: typeRootsToDrop,
  sourceRoots: sourceRoots
) {
  let key = "\(symbol.kind)\u{1}\(symbol.path)\u{1}\(symbol.decl)\u{1}\(symbol.access)"
  if seen.insert(key).inserted { merged.append(symbol) }
}
let symbols = merged.sorted()
let toolchain = Toolchain.detect(sdk: sdkVersion, swift: swiftVersion)
let manifest: [String: Any] = [
  "module": module,
  "target": target,
  "xcode": ["version": toolchain.xcodeVersion, "build": toolchain.xcodeBuild],
  "sdk": ["name": toolchain.sdkName],
  "swift": ["version": toolchain.swiftVersion],
  "generator": "Scripts/canonicalize-api.swift",
  "excludedSources": excludedSources,
  "sourceRoots": sourceRoots,
  "notes":
    "只保留 kind/path/decl/access；丢弃 usr/location/docComment/mixins/relationships/accessibility/spi",
]

let payload: [String: Any] = [
  "manifest": manifest,
  "symbols": symbols.map {
    ["kind": $0.kind, "path": $0.path, "decl": $0.decl, "access": $0.access]
  },
]

let options: JSONSerialization.WritingOptions = [
  .prettyPrinted, .sortedKeys, .withoutEscapingSlashes,
]
guard let output = try? JSONSerialization.data(withJSONObject: payload, options: options) else {
  fail("序列化失败")
}
FileHandle.standardOutput.write(output)
FileHandle.standardOutput.write(Data("\n".utf8))
