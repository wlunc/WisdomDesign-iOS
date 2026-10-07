// iOS/Sources/wd-structure-check/main.swift
//
// wd-structure-check —— iOS 结构 / 依赖 / 字面量 / 生成物检查器（host 可执行 target）。
//
// 口径来源：iOS/docs/SPEC.md §1.1.1–§1.1.2（规则表 R1–R21）+ AGENTS.md §10（硬禁清单）。
//
// 硬约束（照 SPEC §1.1.1）：
//   · 只 import Foundation；**不得依赖 WisdomUI**（I19）——否则 host 构建会触发 iOS-only 编译图；
//   · host triple 下 Swift Regex（macOS 13+）不可用 ⇒ 一律 NSRegularExpression；
//   · 通用实现纪律：① 先剥离注释与字符串字面量再匹配；② 标识符边界匹配；③ 行内豁免语法。
//
// 行内豁免（理由非空才生效，reviewer 按"豁免必须同行给理由"审）：
//     // wd-structure-check:disable R1 — 理由
//   · 只作用于**同一行**的违规；规则 id 可用逗号/空格分隔多个，或写 all；
//   · 分隔符支持 `—`（U+2014）与 `--`；分隔符缺失或理由为空 = 不生效。
//
// 判定面说明（按"意图优先"落定，避免把规则做成恒红）：
//   · R15（L-B 零文案）判定面 = **字符串字面量内容**（注释/文档注释不判）。若按字面把
//     `,.;:!?` 匹配到剥离后的代码上，任意 `类型: 值` 冒号与英文文档注释句点都会恒红。
//   · R15 的**键名白名单**（`Scanner.isKeyNameLiteral`）：SPEC §3.7 的 I41 写的是「其余只允许
//     『标识符/键名』」，而键名（如语义色槽位路径 `text.primary`）天然含 `.` ⇒ 只按标点集判会
//     把契约键名判成文案（假红）。形态 = ASCII 字母数字段 + 单个 `.`/`-`/`_` 连接，首尾非分隔符；
//     正例样本 = `Foundation/Theme/R15_key_name_literal.swift`，反例仍是 `R15_punctuation_literal.swift`。
//   · 路径归类**大小写不敏感**（`Generated/` 与目标态 `generated/` 都识别为生成物），
//     以覆盖 M0 生成器改造前后两种目录形态（本任务不做目录重命名）。
//   · R3（SPEC 判定列为"—"）落地为与 R2/R5 同形的目录名级判定：`Composites/**` 不得出现
//     `Patterns` / `Previews` / `WisdomUIPreviews` / `wd-structure-check`。
//   · R21 是**启发式**（warning）：`Text(` 命中点上下各 12 行窗口内必须有 `minHeight:` 或 `.wdLineBox(`。
//   · **不在 R1–R21 内**的两项（建议后续补规则或并入 ci.sh 门禁）：`Sources/WisdomUI/Resources/`
//     目录存在即 error（硬约束 5）；`Package.swift` 的 build tool plugin 声明（M0 不声明）。
//
// 退出码：0 = 无 error 级违规（warning 打印但不拦）；1 = 有 error 级违规（--strict 下任何违规）；
//         2 = 用法 / IO 错误。

import Foundation

// MARK: - 严重级别

enum Severity: String {
  case error
  case warning
}

// MARK: - 违规条目

/// 规则内部产出的"位置 + 文案"；rule id 与 severity 由引擎按规则定义盖章，避免两处漂移。
struct Finding {
  let path: String
  let line: Int
  let message: String
}

/// 盖章后的违规（对外的唯一形态）。
struct Violation {
  let rule: String
  let severity: Severity
  let path: String
  let line: Int
  let message: String

  var textLine: String {
    let location = line > 0 ? "\(path):\(line)" : path
    return "\(severity.rawValue) \(rule) \(location) — \(message)"
  }
}

// MARK: - 字符串字面量

struct Literal {
  let text: String
  let line: Int
}

// MARK: - 正则（NSRegularExpression 包装；不用 Swift Regex）

final class Regex {
  private let expression: NSRegularExpression

  init(_ pattern: String, options: NSRegularExpression.Options = []) {
    do {
      expression = try NSRegularExpression(pattern: pattern, options: options)
    } catch {
      // 规则模式是编译期常量；模式写错 = 开发期错误，直接崩以便自检立刻暴露。
      fatalError("wd-structure-check: 非法正则 '\(pattern)'：\(error)")
    }
  }

  func results(in text: String) -> [NSTextCheckingResult] {
    expression.matches(in: text, range: NSRange(text.startIndex..., in: text))
  }

  func isMatch(_ text: String) -> Bool {
    expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
  }
}

/// 标识符边界匹配（SPEC §1.1.2 通用纪律 2）。
func identifierPattern(_ name: String) -> String {
  "(?<![A-Za-z0-9_])\(NSRegularExpression.escapedPattern(for: name))(?![A-Za-z0-9_])"
}

// MARK: - 注释 / 字符串剥离

/// 最小扫描器：把注释与字符串字面量替换成空格（保留换行与字符总数），同时收集字面量内容。
enum Stripper {
  struct Result {
    let code: String
    let literals: [Literal]
  }

  static func strip(_ text: String) -> Result {
    let chars = Array(text)
    var out = chars
    var literals: [Literal] = []
    var index = 0
    var line = 1

    while index < chars.count {
      let char = chars[index]

      if char == "\n" {
        line += 1
        index += 1
        continue
      }

      // 行注释
      if char == "/", index + 1 < chars.count, chars[index + 1] == "/" {
        var end = index
        while end < chars.count, chars[end] != "\n" { end += 1 }
        blank(&out, chars, index, end)
        index = end
        continue
      }

      // 块注释（Swift 支持嵌套）
      if char == "/", index + 1 < chars.count, chars[index + 1] == "*" {
        let start = index
        var depth = 0
        var end = index
        var consumedLine = line
        while end < chars.count {
          if chars[end] == "/", end + 1 < chars.count, chars[end + 1] == "*" {
            depth += 1
            end += 2
            continue
          }
          if chars[end] == "*", end + 1 < chars.count, chars[end + 1] == "/" {
            depth -= 1
            end += 2
            if depth == 0 { break }
            continue
          }
          if chars[end] == "\n" { consumedLine += 1 }
          end += 1
        }
        blank(&out, chars, start, min(end, chars.count))
        line = consumedLine
        index = end
        continue
      }

      // 字符串字面量（含 raw 前缀 `#`）
      var hashes = 0
      var quoteIndex = index
      if char == "#" {
        var h = 0
        while index + h < chars.count, chars[index + h] == "#" { h += 1 }
        if index + h < chars.count, chars[index + h] == "\"" {
          hashes = h
          quoteIndex = index + h
        } else {
          index += 1
          continue
        }
      } else if char == "\"" {
        quoteIndex = index
      } else {
        index += 1
        continue
      }

      let scanned = scanLiteral(chars, quoteIndex: quoteIndex, hashes: hashes, line: line)
      literals.append(Literal(text: scanned.content, line: scanned.contentLine))
      blank(&out, chars, index, min(scanned.end, chars.count))
      line = scanned.endLine
      index = scanned.end
    }

    return Result(code: String(out), literals: literals)
  }

  private static func blank(_ out: inout [Character], _ chars: [Character], _ from: Int, _ to: Int)
  {
    var i = max(0, from)
    let limit = min(to, chars.count)
    while i < limit {
      if chars[i] != "\n" { out[i] = " " }
      i += 1
    }
  }

  private static func scanLiteral(
    _ chars: [Character],
    quoteIndex: Int,
    hashes: Int,
    line: Int
  ) -> (end: Int, content: String, contentLine: Int, endLine: Int) {
    let isMultiline =
      quoteIndex + 2 < chars.count
      && chars[quoteIndex] == "\""
      && chars[quoteIndex + 1] == "\""
      && chars[quoteIndex + 2] == "\""

    var index = quoteIndex + (isMultiline ? 3 : 1)
    let contentStart = index
    var contentEnd = index
    var currentLine = line
    var escaped = false

    func skipHashes(_ from: Int) -> Int {
      var k = 0
      while k < hashes, from + k < chars.count, chars[from + k] == "#" { k += 1 }
      return from + k
    }

    while index < chars.count {
      let char = chars[index]
      if char == "\n" { currentLine += 1 }

      if isMultiline {
        if char == "\"",
          index + 2 < chars.count,
          chars[index + 1] == "\"",
          chars[index + 2] == "\""
        {
          contentEnd = index
          index = skipHashes(index + 3)
          break
        }
      } else if escaped {
        escaped = false
      } else if char == "\\", hashes == 0 {
        escaped = true
      } else if char == "\"" {
        contentEnd = index
        index = skipHashes(index + 1)
        break
      }
      index += 1
    }

    let content = contentEnd > contentStart ? String(chars[contentStart..<contentEnd]) : ""
    return (index, content, line, currentLine)
  }
}

// MARK: - 文件归类

enum Layer: String {
  case foundation
  case primitives
  case composites
  case patterns
  case internalLayer
  case previews
  case checker
  case other
}

struct FileClass {
  let relativePath: String
  let layer: Layer
  let isGenerated: Bool
  let isUnderTokens: Bool
  let isUnderTests: Bool
  let isPreviewsFile: Bool
  let isUnderWisdomUI: Bool

  var isComponents: Bool {
    layer == .primitives || layer == .composites || layer == .patterns
  }

  /// SPEC §1.1.2 "R1–R21 通用白名单"：Generated / Tokens / Internal / Tests / *+Previews.swift。
  /// 该白名单只对"取值与溯源类"规则（R1/R7/R13a/R13b/R15/R16/R17）生效；
  /// 结构性规则（R2/R3/R5/R6）按各自的目录范围独立判定（否则 R5/R6 会自相矛盾）。
  var isWhitelisted: Bool {
    isGenerated || isUnderTokens || isUnderTests || isPreviewsFile || layer == .internalLayer
  }

  var isLibraryNonWhitelisted: Bool {
    isUnderWisdomUI && !isWhitelisted
  }

  var isComponentsNonWhitelisted: Bool {
    isComponents && !isWhitelisted
  }
}

func classify(relativePath: String) -> FileClass {
  let components = relativePath.split(separator: "/").map(String.init)
  let lowered = components.map { $0.lowercased() }

  let isGenerated = lowered.contains("generated")
  let isUnderTokens = lowered.contains("tokens")
  let isUnderTests = lowered.first == "tests"
  let isPreviewsFile = relativePath.hasSuffix("+Previews.swift")
  let isUnderWisdomUI = lowered.count >= 2 && lowered[0] == "sources" && lowered[1] == "wisdomui"

  var layer: Layer = .other
  if lowered.count >= 2, lowered[0] == "sources" {
    if lowered[1] == "wisdomui" {
      let rest = Array(lowered.dropFirst(2))
      switch rest.first {
      case "foundation":
        layer = .foundation
      case "internal":
        layer = .internalLayer
      case "components":
        switch rest.dropFirst().first {
        case "primitives": layer = .primitives
        case "composites": layer = .composites
        case "patterns": layer = .patterns
        default: layer = .other
        }
      default:
        layer = .other
      }
    } else if lowered[1] == "wisdomuipreviews" {
      layer = .previews
    } else if lowered[1] == "wd-structure-check" {
      layer = .checker
    }
  }

  return FileClass(
    relativePath: relativePath,
    layer: layer,
    isGenerated: isGenerated,
    isUnderTokens: isUnderTokens,
    isUnderTests: isUnderTests,
    isPreviewsFile: isPreviewsFile,
    isUnderWisdomUI: isUnderWisdomUI
  )
}

// MARK: - 源文件

struct SourceFile {
  let path: String
  let raw: String
  /// 剥离注释与字符串后的代码（与 `raw` 字符数一致，换行保留）。
  let code: String
  let literals: [Literal]
  let klass: FileClass
  let rawLines: [String]
  let codeLines: [String]
  /// 每行首字符偏移（基于 `code`）。
  let lineStarts: [Int]

  init(path: String, raw: String, klass: FileClass) {
    self.path = path
    self.raw = raw
    self.klass = klass

    let stripped = Stripper.strip(raw)
    self.code = stripped.code
    self.literals = stripped.literals
    self.rawLines = raw.components(separatedBy: "\n")
    self.codeLines = stripped.code.components(separatedBy: "\n")

    var starts: [Int] = [0]
    var offset = 0
    for character in stripped.code {
      offset += 1
      if character == "\n" { starts.append(offset) }
    }
    self.lineStarts = starts
  }

  /// 字符偏移 → 1-based 行号。
  func lineNumber(atOffset offset: Int) -> Int {
    var low = 0
    var high = lineStarts.count - 1
    while low < high {
      let mid = (low + high + 1) / 2
      if lineStarts[mid] <= offset { low = mid } else { high = mid - 1 }
    }
    return low + 1
  }

  func lineStartOffset(_ line: Int) -> Int {
    guard !lineStarts.isEmpty else { return 0 }
    let index = min(max(line - 1, 0), lineStarts.count - 1)
    return lineStarts[index]
  }

  /// 把 NSRange 转成"字符偏移 → 行号"。
  func lineNumber(of range: NSRange) -> Int {
    guard let stringRange = Range(range, in: code) else { return 0 }
    return lineNumber(atOffset: code.distance(from: code.startIndex, to: stringRange.lowerBound))
  }

  func characterOffset(of range: NSRange) -> Int? {
    guard let stringRange = Range(range, in: code) else { return nil }
    return code.distance(from: code.startIndex, to: stringRange.lowerBound)
  }

  /// 命中区间**末尾**的字符偏移（用于取"声明体 `{` 的位置"）。
  func characterOffset(ofUpperBound range: NSRange) -> Int? {
    guard let stringRange = Range(range, in: code) else { return nil }
    return code.distance(from: code.startIndex, to: stringRange.upperBound)
  }

  func snippet(of range: NSRange) -> String {
    guard let stringRange = Range(range, in: code) else { return "" }
    return String(code[stringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// `offset` 之前、最近一个语句边界（`{` / `}` / `;`）到 `offset` 的文本。
  func leadingText(beforeOffset offset: Int, window: Int = 600) -> String {
    let chars = Array(code)
    let limit = min(max(offset, 0), chars.count)
    let floor = max(0, limit - window)
    var start = floor
    var index = limit - 1
    while index >= floor {
      let char = chars[index]
      if char == "{" || char == "}" || char == ";" {
        start = index + 1
        break
      }
      index -= 1
    }
    return String(chars[start..<limit])
  }

  /// 从 `offset` 起到首个 stop 字符（不含）的文本。
  func text(fromOffset offset: Int, upToFirstOf stops: [Character]) -> String {
    let chars = Array(code)
    guard offset >= 0, offset < chars.count else { return "" }
    var index = offset
    while index < chars.count, !stops.contains(chars[index]) { index += 1 }
    return String(chars[offset..<index])
  }

  /// 包含 `offset` 的最内层闭合作用域的声明头（上一个语句边界 → 该作用域的 `{`）。
  func enclosingScopeHeader(atOffset offset: Int) -> String {
    let chars = Array(code)
    var stack: [Int] = []
    let limit = min(max(offset, 0), chars.count)
    var index = 0
    while index < limit {
      let char = chars[index]
      if char == "{" {
        stack.append(index)
      } else if char == "}", !stack.isEmpty {
        stack.removeLast()
      }
      index += 1
    }
    guard let open = stack.last else { return "" }
    var start = 0
    var back = open - 1
    while back >= 0 {
      let char = chars[back]
      if char == "{" || char == "}" || char == ";" {
        start = back + 1
        break
      }
      back -= 1
    }
    return String(chars[start..<open])
  }

  /// 从 `openingBraceOffset` 处的 `{` 到配对 `}` 的整段文本。
  func bodyText(openingBraceOffset: Int) -> String? {
    let chars = Array(code)
    guard openingBraceOffset >= 0, openingBraceOffset < chars.count,
      chars[openingBraceOffset] == "{"
    else {
      return nil
    }
    var depth = 0
    var index = openingBraceOffset
    while index < chars.count {
      if chars[index] == "{" {
        depth += 1
      } else if chars[index] == "}" {
        depth -= 1
        if depth == 0 { return String(chars[openingBraceOffset...index]) }
      }
      index += 1
    }
    return nil
  }

  /// 以 `line` 为中心、上下各 `radius` 行的剥离后文本窗口（R21 的启发式判定面）。
  func window(aroundLine line: Int, radius: Int) -> String {
    let start = max(0, line - 1 - radius)
    let end = min(codeLines.count - 1, line - 1 + radius)
    guard start <= end else { return "" }
    return codeLines[start...end].joined(separator: "\n")
  }
}

// MARK: - 扫描

struct RuleContext {
  let rootPath: String
  let directories: Set<String>
  let componentNames: [String]

  func dirExists(_ relativePath: String) -> Bool {
    directories.contains(relativePath.lowercased())
  }
}

struct Layout {
  let rootPath: String
  let files: [SourceFile]
  let directories: Set<String>
  let componentNames: [String]

  var context: RuleContext {
    RuleContext(rootPath: rootPath, directories: directories, componentNames: componentNames)
  }
}

enum Scanner {
  /// 不进入的目录（构建产物/用户态）。
  static let skippedDirectories: Set<String> = [
    "build", ".build", ".swiftpm", "deriveddata", "xcuserdata", "node_modules",
  ]

  static func scan(root: URL) throws -> Layout {
    var files: [SourceFile] = []
    var directories: Set<String> = []
    let manager = FileManager.default

    for top in ["Sources", "Tests"] {
      let url = root.appendingPathComponent(top)
      var isDirectory: ObjCBool = false
      guard manager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue
      else {
        continue
      }
      try walk(url, relative: top, files: &files, directories: &directories)
    }

    files.sort { $0.path < $1.path }

    return Layout(
      rootPath: root.path,
      files: files,
      directories: directories,
      componentNames: componentNames(in: files)
    )
  }

  private static func walk(
    _ url: URL,
    relative: String,
    files: inout [SourceFile],
    directories: inout Set<String>
  ) throws {
    let manager = FileManager.default
    let entries = try manager.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )
    for entry in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
      let name = entry.lastPathComponent
      let childRelative = relative + "/" + name
      let values = try entry.resourceValues(forKeys: [.isDirectoryKey])
      if values.isDirectory == true {
        if skippedDirectories.contains(name.lowercased()) { continue }
        directories.insert(childRelative.lowercased())
        try walk(entry, relative: childRelative, files: &files, directories: &directories)
      } else if name.hasSuffix(".swift") {
        let data = try Data(contentsOf: entry)
        let raw = String(decoding: data, as: UTF8.self)
        files.append(
          SourceFile(path: childRelative, raw: raw, klass: classify(relativePath: childRelative)))
      }
    }
  }

  /// 组件名集合 = `Components/<family>/<X>/` 的目录名。
  /// 采纳条件：目录名以 `WD` 开头，或目录内存在与目录同名的 `.swift`（一组件一目录约定），
  /// 以免把 `Support/` 之类的辅助目录名当成组件类型名（SPEC R1 的误报修正意图）。
  private static func componentNames(in files: [SourceFile]) -> [String] {
    var names: Set<String> = []
    for file in files {
      let components = file.path.split(separator: "/").map(String.init)
      guard components.count >= 5,
        components[0] == "Sources",
        components[1] == "WisdomUI",
        components[2] == "Components"
      else { continue }
      let family = components[3].lowercased()
      guard family == "primitives" || family == "composites" || family == "patterns" else {
        continue
      }
      let directory = components[4]
      let fileName = components[components.count - 1]
      if directory.hasPrefix("WD") || fileName == "\(directory).swift" {
        names.insert(directory)
      }
    }
    return names.sorted()
  }
}

// MARK: - 规则骨架

struct Rule {
  enum Scope: String {
    case file
    case tree
  }

  let id: String
  let severity: Severity
  let scope: Scope
  let summary: String
  let runFile: (SourceFile, RuleContext) -> [Finding]
  let runTree: (RuleContext) -> [Finding]

  init(
    id: String,
    severity: Severity,
    summary: String,
    file: @escaping (SourceFile, RuleContext) -> [Finding]
  ) {
    self.id = id
    self.severity = severity
    self.scope = .file
    self.summary = summary
    self.runFile = file
    self.runTree = { _ in [] }
  }

  init(
    id: String,
    severity: Severity,
    summary: String,
    tree: @escaping (RuleContext) -> [Finding]
  ) {
    self.id = id
    self.severity = severity
    self.scope = .tree
    self.summary = summary
    self.runFile = { _, _ in [] }
    self.runTree = tree
  }
}

/// 正则命中 → Finding（默认按行去重，避免同一行刷屏）。
func collect(
  _ regex: Regex,
  in file: SourceFile,
  dedupeByLine: Bool = true,
  message: (String) -> String
) -> [Finding] {
  var findings: [Finding] = []
  var seen: Set<Int> = []
  for result in regex.results(in: file.code) {
    let line = file.lineNumber(of: result.range)
    if dedupeByLine, seen.contains(line) { continue }
    seen.insert(line)
    findings.append(
      Finding(path: file.path, line: line, message: message(file.snippet(of: result.range)))
    )
  }
  return findings
}

func capture(_ result: NSTextCheckingResult, _ index: Int, in text: String) -> String? {
  guard index < result.numberOfRanges,
    let range = Range(result.range(at: index), in: text)
  else { return nil }
  return String(text[range])
}

// MARK: - 规则 R1–R21

func makeRules() -> [Rule] {
  // 复用正则（编译一次）
  let composeWord = Regex(identifierPattern("Composites"))
  let patternsWord = Regex(identifierPattern("Patterns"))
  let previewsWord = Regex(identifierPattern("Previews"))
  let previewsModule = Regex(identifierPattern("WisdomUIPreviews"))
  let checkerModule = Regex(identifierPattern("wd-structure-check"))
  let publicWord = Regex(identifierPattern("public"))
  let numericLiteral = Regex("\\b\\d+(\\.\\d+)?\\b")
  let anyViewWord = Regex(identifierPattern("AnyView"))
  let staticVar = Regex("(?<![A-Za-z0-9_])static\\s+var\\s+([A-Za-z_][A-Za-z0-9_]*)")
  let factoryExtension = Regex(
    "extension\\s+(ButtonStyle|ToggleStyle|ViewModifier)\\b[\\s\\S]*?where\\s+Self\\s*==")
  let testableImport = Regex("(?<![A-Za-z0-9_])@testable\\s+import\\s+([A-Za-z_][A-Za-z0-9_]*)")
  let frameToken = Regex(#"\.frame\(\s*(?:height|width)\s*:\s*WD"#)
  let staticTokenEntry = Regex("(?<![A-Za-z0-9_])(WDColor|WDType)\\.")
  let fontEntry = Regex(
    #"\.font\(\s*\.system\(|(?<![A-Za-z0-9_])Font\.system\(|\.font\(\s*WDType\."#)
  let uikitImport = Regex("(?m)^[ \\t]*import[ \\t]+UIKit\\b")
  let platformOverride = Regex(
    #"\.preferredColorScheme\(|\.environment\(\\\.colorScheme|\.environment\(\\\.dynamicTypeSize"#
  )
  let environmentWrite = Regex(
    #"(?<![A-Za-z0-9_])\.environment\(|\\\.wdDensity\s*=|\\\.wdEffectsBudget\s*="#
  )
  let overridesType = Regex(
    "(?<![A-Za-z0-9_])(?:struct|enum|class|protocol|typealias)[ \\t]+([A-Za-z_][A-Za-z0-9_]*Overrides)"
  )
  let protocolDecl = Regex("(?<![A-Za-z0-9_])protocol[ \\t]+([A-Za-z_][A-Za-z0-9_]*)")
  let mainActorAttribute = Regex(identifierPattern("@MainActor"))
  let sendableWord = Regex(identifierPattern("Sendable"))
  let hashableWord = Regex(identifierPattern("Hashable"))
  let typeWithConformance = Regex(
    "(?m)^[ \\t]*(?:public|open)[ \\t]+(?:final[ \\t]+)?(?:struct|enum|class|actor)[ \\t]+([A-Za-z_][A-Za-z0-9_]*)([^{]*)\\{"
  )
  let storedTextProperty = Regex(
    "\\b(?:let|var)\\s+[A-Za-z_][A-Za-z0-9_]*\\s*:\\s*(?:Text|Label|SubmitLabel)\\b"
  )
  let textView = Regex("(?<![A-Za-z0-9_])Text\\(")

  // 规则适用面（见 FileClass.isWhitelisted 的注释）
  func r13Scope(_ file: SourceFile) -> Bool { file.klass.isLibraryNonWhitelisted }
  func componentsScope(_ file: SourceFile) -> Bool { file.klass.isComponentsNonWhitelisted }

  var rules: [Rule] = []

  // R1 —— Foundation/** 不得出现组件类型名
  rules.append(
    Rule(
      id: "R1",
      severity: .error,
      summary: "Foundation/** 不得出现组件类型名（名字来自 Components/**/<X>/ 目录名）"
    ) { file, context in
      guard file.klass.layer == .foundation, !file.klass.isWhitelisted else { return [] }
      guard !context.componentNames.isEmpty else { return [] }
      var findings: [Finding] = []
      for name in context.componentNames {
        findings += collect(Regex(identifierPattern(name)), in: file) { token in
          "Foundation/** 不得引用组件类型名 '\(token)'（标识符边界；组件名集合来自 Components/**/<X>/）"
        }
      }
      return findings
    }
  )

  // R2 —— Primitives/** 只依赖 Foundation + Internal
  rules.append(
    Rule(
      id: "R2",
      severity: .error,
      summary: "Primitives/** 只依赖 Foundation + Internal（出现 Composites 即 violation）"
    ) { file, _ in
      guard file.klass.layer == .primitives, !file.klass.isGenerated, !file.klass.isPreviewsFile
      else {
        return []
      }
      return collect(composeWord, in: file) { token in
        "Primitives/** 不得出现 '\(token)'（只允许依赖 Foundation + Internal）"
      }
    }
  )

  // R3 —— Composites/** 只依赖 Foundation + Primitives + Internal
  rules.append(
    Rule(
      id: "R3",
      severity: .error,
      summary: "Composites/** 只依赖 Foundation + Primitives + Internal"
    ) { file, _ in
      guard file.klass.layer == .composites, !file.klass.isGenerated, !file.klass.isPreviewsFile
      else {
        return []
      }
      var findings: [Finding] = []
      for regex in [patternsWord, previewsWord, previewsModule, checkerModule] {
        findings += collect(regex, in: file) { token in
          "Composites/** 只允许依赖 Foundation + Primitives + Internal（出现 '\(token)'）"
        }
      }
      return findings
    }
  )

  // R4 —— 不得存在 Components/Patterns/（目录级）
  rules.append(
    Rule(
      id: "R4",
      severity: .error,
      summary: "不得存在 Components/Patterns/（存在即 error）",
      tree: { context in
        let path = "Sources/WisdomUI/Components/Patterns"
        guard context.dirExists(path) else { return [] }
        return [
          Finding(
            path: path,
            line: 0,
            message: "Components/Patterns/ 不得存在（已删除；存在即 error）"
          )
        ]
      }
    )
  )

  // R5 —— Internal/** 不得依赖 Composites
  rules.append(
    Rule(
      id: "R5",
      severity: .error,
      summary: "Internal/** 不得依赖 Composites"
    ) { file, _ in
      guard file.klass.layer == .internalLayer, !file.klass.isGenerated else { return [] }
      return collect(composeWord, in: file) { token in
        "Internal/** 不得依赖 Composites（出现 '\(token)'）"
      }
    }
  )

  // R6 —— Internal/** 不得出现 public
  rules.append(
    Rule(
      id: "R6",
      severity: .error,
      summary: "Internal/** 零 public（剥离注释/字符串后匹配）"
    ) { file, _ in
      guard file.klass.layer == .internalLayer, !file.klass.isGenerated else { return [] }
      return collect(publicWord, in: file) { token in
        "Internal/** 不得出现 '\(token)'（内部实现零公开面）"
      }
    }
  )

  // R7 —— 数值字面量必须可追溯到令牌（M0–M2 warning，M3 起 error）
  rules.append(
    Rule(
      id: "R7",
      severity: .warning,
      summary: "数值字面量必须可追溯到令牌（白名单 Generated/Tokens/Internal/Tests/+Previews）"
    ) { file, _ in
      let inScope = file.klass.layer == .foundation || file.klass.isComponents
      guard inScope, !file.klass.isWhitelisted else { return [] }

      var findings: [Finding] = []
      var seenLines: Set<Int> = []
      for result in numericLiteral.results(in: file.code) {
        guard let offset = file.characterOffset(of: result.range) else { continue }
        let token = file.snippet(of: result.range)
        let line = file.lineNumber(atOffset: offset)
        let lineIndex = line - 1
        let lineText = file.codeLines.indices.contains(lineIndex) ? file.codeLines[lineIndex] : ""
        let column = max(0, offset - file.lineStartOffset(line))
        let prefix = String(lineText.prefix(column))

        if isTraceableNumber(
          token: token,
          range: result.range,
          code: file.code,
          lineText: lineText,
          prefix: prefix
        ) {
          continue
        }
        if seenLines.contains(line) { continue }
        seenLines.insert(line)
        findings.append(
          Finding(
            path: file.path,
            line: line,
            message: "数值字面量 '\(token)' 必须可追溯到令牌或 F 系列登记表"
              + "（豁免：0/1/-1、.opacity(、zIndex、lineLimit、数组索引、#available 版本号）"
          )
        )
      }
      return findings
    }
  )

  // R8 —— Tests/** 镜像被测层
  rules.append(
    Rule(
      id: "R8",
      severity: .error,
      summary: "Tests/** 镜像被测层（目录形状 + @testable import 引用层）"
    ) { file, context in
      guard file.klass.isUnderTests else { return [] }
      var findings: [Finding] = []

      // ① @testable import 必须指向被测层
      for result in testableImport.results(in: file.code) {
        let name = capture(result, 1, in: file.code) ?? "?"
        guard !Scanner.allowedTestableImports.contains(name) else { continue }
        findings.append(
          Finding(
            path: file.path,
            line: file.lineNumber(of: result.range),
            message: "@testable import '\(name)' 不是被测层"
              + "（只允许 \(Scanner.allowedTestableImports.sorted().joined(separator: " / "))）"
          )
        )
      }

      // ② 目录形状：Tests/<Target>/<层…>/ 必须在 Sources 下有对应目录
      let components = file.path.split(separator: "/").map(String.init)
      if components.count >= 4, components[0] == "Tests" {
        let mirror = components.dropFirst(2).dropLast().joined(separator: "/")
        let top = mirror.split(separator: "/").first.map { String($0).lowercased() } ?? ""
        if Scanner.mirrorLayerNames.contains(top) {
          let candidates = [
            "Sources/WisdomUI/\(mirror)",
            "Sources/WisdomUI/Components/\(mirror)",
          ]
          if !candidates.contains(where: { context.dirExists($0) }) {
            findings.append(
              Finding(
                path: file.path,
                line: 1,
                message: "测试目录 'Tests/\(components[1])/\(mirror)' 在被测层没有对应目录"
                  + "（允许：\(candidates.joined(separator: " 或 "))）"
              )
            )
          }
        }
      }
      return findings
    }
  )

  // R9 —— 组件禁 .frame(height:/width:) 绑令牌常量
  rules.append(
    Rule(
      id: "R9",
      severity: .error,
      summary: "Components/** 禁 .frame(height:/width:) 绑令牌常量（动态字体必须靠 minHeight 增长）"
    ) { file, _ in
      guard componentsScope(file) else { return [] }
      return collect(frameToken, in: file) { token in
        "禁 '\(token)…'（固定尺寸挡住动态字体增长；改用 minHeight: 令牌）"
      }
    }
  )

  // R10 —— 组件禁静态令牌入口
  rules.append(
    Rule(
      id: "R10",
      severity: .error,
      summary: "Components/** 禁静态令牌入口 WDColor./WDType."
    ) { file, _ in
      guard componentsScope(file) else { return [] }
      return collect(staticTokenEntry, in: file) { token in
        "禁静态令牌入口 '\(token)'（必须走 @Environment(\\.wdColors) 等运行期槽位）"
      }
    }
  )

  // R11 —— 组件禁字体系统入口
  rules.append(
    Rule(
      id: "R11",
      severity: .error,
      summary: "Components/** 禁 .font(.system(/Font.system(/.font(WDType.（唯一入口 wdFont）"
    ) { file, _ in
      guard componentsScope(file) else { return [] }
      return collect(fontEntry, in: file) { token in
        "禁 '\(token)'（字号唯一入口 = wdFont(_:)，行盒 = wdLineBox(_:)）"
      }
    }
  )

  // R12 —— Generated/（含目标态 generated/）只允许生成器写入
  rules.append(
    Rule(
      id: "R12",
      severity: .error,
      summary: "生成物（Generated/ 或 generated/）首两行必须是生成器 banner"
    ) { file, _ in
      guard file.klass.isGenerated else { return [] }
      let head = Array(file.rawLines.prefix(2)).joined(separator: "\n")
      let lowered = head.lowercased()
      let hasGenerator = lowered.contains("token-build")
      let hasNoEdit = head.contains("请勿手改") || lowered.contains("do not edit")
      let hasOrigin = head.contains("本文件由") || lowered.contains("generated by")
      let startsWithComment =
        file.rawLines.first?.trimmingCharacters(in: .whitespaces).hasPrefix("//") ?? false

      if hasGenerator, hasNoEdit, hasOrigin, startsWithComment { return [] }
      return [
        Finding(
          path: file.path,
          line: 1,
          message: "生成物首两行缺少生成器 banner（需含 token-build + 本文件由/Generated by"
            + " + 请勿手改/DO NOT EDIT）——只允许 ../wisdomdesign/tools/token-build/build.js 写入"
        )
      ]
    }
  )

  // R13a —— 禁带初始化器的 static var + AnyView
  rules.append(
    Rule(
      id: "R13a",
      severity: .error,
      summary: "禁带初始化器的 static var（存储型静态可变状态）与 AnyView"
    ) { file, _ in
      guard r13Scope(file) else { return [] }
      var findings: [Finding] = []
      for result in staticVar.results(in: file.code) {
        guard let range = Range(result.range, in: file.code) else { continue }
        let name = capture(result, 1, in: file.code) ?? "?"
        let tail = String(file.code[range.upperBound...].prefix(200))
        if hasInitializer(in: tail) {
          let line = file.lineNumber(of: result.range)
          findings.append(
            Finding(
              path: file.path,
              line: line,
              message: "static var '\(name)' 不得带初始化器（存储型静态可变状态；改 static let"
                + " 或 ButtonStyle/ToggleStyle/ViewModifier 的计算型工厂）"
            )
          )
        }
      }
      findings += collect(anyViewWord, in: file) { token in
        "禁 '\(token)'（类型擦除破坏 diff 与性能；改用泛型或具体类型）"
      }
      return findings
    }
  )

  // R13b —— 计算型 static var 只允许在样式工厂扩展里
  rules.append(
    Rule(
      id: "R13b",
      severity: .error,
      summary:
        "计算型 static var 只允许出现在 extension (ButtonStyle|ToggleStyle|ViewModifier) where Self == …"
    ) { file, _ in
      guard r13Scope(file) else { return [] }
      var findings: [Finding] = []
      for result in staticVar.results(in: file.code) {
        guard let range = Range(result.range, in: file.code) else { continue }
        let name = capture(result, 1, in: file.code) ?? "?"
        let tail = String(file.code[range.upperBound...].prefix(200))
        // 有初始化器 → 归 R13a，跳过
        if hasInitializer(in: tail) { continue }
        let offset = file.characterOffset(of: result.range) ?? 0
        let header = file.enclosingScopeHeader(atOffset: offset)
        if factoryExtension.isMatch(header) { continue }
        findings.append(
          Finding(
            path: file.path,
            line: file.lineNumber(of: result.range),
            message: "计算型 static var '\(name)' 只允许出现在 ButtonStyle / ToggleStyle / ViewModifier"
              + " 的 `where Self ==` 工厂扩展里"
          )
        )
      }
      return findings
    }
  )

  // R14 —— Components/** 禁 import UIKit
  rules.append(
    Rule(
      id: "R14",
      severity: .error,
      summary: "Components/** 禁 import UIKit（只允许 Foundation/Typography 与 Internal）"
    ) { file, _ in
      guard componentsScope(file) else { return [] }
      return collect(uikitImport, in: file) { token in
        "禁 '\(token)'（UIKit 只允许出现在 Foundation/Typography 与 Internal）"
      }
    }
  )

  // R15 —— L-B 机器化（判定面 = 字符串字面量）
  rules.append(
    Rule(
      id: "R15",
      severity: .error,
      summary: "L-B：Sources/WisdomUI/** 的字符串字面量不得含标点或词序模板"
    ) { file, _ in
      guard file.klass.isLibraryNonWhitelisted else { return [] }
      var findings: [Finding] = []
      for literal in file.literals {
        // I41 白名单句：非白名单文件「只允许标识符/键名」⇒ 键名形态的字面量不判（见 isKeyNameLiteral）。
        if Scanner.isKeyNameLiteral(literal.text) { continue }
        if let hit = literal.text.first(where: { Scanner.lbPunctuation.contains($0) }) {
          findings.append(
            Finding(
              path: file.path,
              line: literal.line,
              message: "库内零文案（L-B）：字符串字面量不得含标点 '\(hit)'"
                + "（读屏标签/语序由调用方传入，库只给结构拼接原语）"
            )
          )
        } else if let template = Scanner.lbWordOrder.first(where: { literal.text.contains($0) }) {
          findings.append(
            Finding(
              path: file.path,
              line: literal.line,
              message: "库内零文案（L-B）：字符串字面量不得含词序模板 '\(template)'"
            )
          )
        }
      }
      return findings
    }
  )

  // R16 —— 库不覆写平台设置
  rules.append(
    Rule(
      id: "R16",
      severity: .error,
      summary:
        "Sources/WisdomUI/** 禁 .preferredColorScheme( / .environment(\\.colorScheme / .environment(\\.dynamicTypeSize"
    ) { file, _ in
      guard file.klass.isLibraryNonWhitelisted else { return [] }
      return collect(platformOverride, in: file) { token in
        "库不覆写平台无障碍/外观设置：禁 '\(token)'（预览/测试/demo 白名单）"
      }
    }
  )

  // R17 —— 公开类型含 Text/Label/SubmitLabel 存储字段时不得 Hashable
  rules.append(
    Rule(
      id: "R17",
      severity: .error,
      summary: "公开类型含 Text/Label/SubmitLabel 存储字段时不得声明 Hashable（B1）"
    ) { file, _ in
      guard file.klass.isLibraryNonWhitelisted else { return [] }
      var findings: [Finding] = []
      for result in typeWithConformance.results(in: file.code) {
        let name = capture(result, 1, in: file.code) ?? "?"
        let conformance = capture(result, 2, in: file.code) ?? ""
        guard hashableWord.isMatch(conformance) else { continue }
        // 命中以声明的 `{` 结尾 ⇒ 体起点 = 命中末尾 - 1
        guard let upper = file.characterOffset(ofUpperBound: result.range) else { continue }
        let openOffset = upper - 1
        guard let body = file.bodyText(openingBraceOffset: openOffset) else { continue }
        guard storedTextProperty.isMatch(body) else { continue }
        findings.append(
          Finding(
            path: file.path,
            line: file.lineNumber(of: result.range),
            message: "公开类型 '\(name)' 含 Text/Label/SubmitLabel 存储字段，不得声明 Hashable"
              + "（Text 非 Hashable；= B1 防复发）"
          )
        )
      }
      return findings
    }
  )

  // R18 —— Components/** 禁写 Environment
  rules.append(
    Rule(
      id: "R18",
      severity: .error,
      summary: "Components/** 禁写 Environment（写入口只在 Foundation/Theme/WDEnvironment.swift）"
    ) { file, _ in
      guard componentsScope(file) else { return [] }
      return collect(environmentWrite, in: file) { token in
        "组件不得写 Environment：禁 '\(token)'（只读 @Environment；写入口只允许 Foundation/Theme 的 View 修饰符）"
      }
    }
  )

  // R19 —— 只允许三类 *Overrides 类型
  rules.append(
    Rule(
      id: "R19",
      severity: .error,
      summary: "只允许 WDColorOverrides / WDGradientOverrides / WDMaterialOverrides 三类 *Overrides 类型"
    ) { file, _ in
      guard file.klass.isUnderWisdomUI, !file.klass.isGenerated, !file.klass.isPreviewsFile else {
        return []
      }
      var findings: [Finding] = []
      for result in overridesType.results(in: file.code) {
        let name = capture(result, 1, in: file.code) ?? "?"
        guard !Scanner.allowedOverridesTypes.contains(name) else { continue }
        findings.append(
          Finding(
            path: file.path,
            line: file.lineNumber(of: result.range),
            message:
              "类型 '\(name)' 不在允许的覆盖面内（只允许 \(Scanner.allowedOverridesTypes.sorted().joined(separator: " / "))）"
          )
        )
      }
      return findings
    }
  )

  // R20 —— 公开协议不得既 Sendable 又要求 @MainActor（warning，主靠隔离注解表 + 单测）
  rules.append(
    Rule(
      id: "R20",
      severity: .warning,
      summary: "公开协议不得既 Sendable 又 @MainActor（软提示；主靠 §1.2.1 隔离注解表）"
    ) { file, _ in
      guard file.klass.isLibraryNonWhitelisted else { return [] }
      var findings: [Finding] = []
      for result in protocolDecl.results(in: file.code) {
        let name = capture(result, 1, in: file.code) ?? "?"
        guard let offset = file.characterOffset(of: result.range) else { continue }
        let header =
          file.leadingText(beforeOffset: offset)
          + file.text(fromOffset: offset, upToFirstOf: ["{", "}", ";"])
        guard mainActorAttribute.isMatch(header), sendableWord.isMatch(header) else { continue }
        findings.append(
          Finding(
            path: file.path,
            line: file.lineNumber(of: result.range),
            message: "公开协议 '\(name)' 同时要求 @MainActor 与 Sendable（#ConformanceIsolation 编译错误；"
              + "按 §1.2.1 隔离注解表去掉其中一项）"
          )
        )
      }
      return findings
    }
  )

  // R21 —— 文本容器必须有令牌 minHeight 或 .wdLineBox（warning，启发式）
  rules.append(
    Rule(
      id: "R21",
      severity: .warning,
      summary: "Components/** 的 Text 最近容器必须有令牌 minHeight 或 .wdLineBox(...)（U5/F13）"
    ) { file, _ in
      guard componentsScope(file) else { return [] }
      var findings: [Finding] = []
      var seenLines: Set<Int> = []
      for result in textView.results(in: file.code) {
        guard let offset = file.characterOffset(of: result.range) else { continue }
        let line = file.lineNumber(atOffset: offset)
        if seenLines.contains(line) { continue }
        seenLines.insert(line)
        let window = file.window(aroundLine: line, radius: Scanner.textContainerWindow)
        if window.contains("minHeight:") || window.contains(".wdLineBox(") { continue }
        findings.append(
          Finding(
            path: file.path,
            line: line,
            message: "Text 的最近容器缺少令牌 `minHeight:` 或 `.wdLineBox(...)`"
              + "（行盒硬约束 U5/F13：禁 Mode.Fixed / lineHeightMultiple）"
          )
        )
      }
      return findings
    }
  )

  return rules
}

/// `static var` 之后的窗口里，`=` 是否先于 `{` 出现（= 有初始化器 / 存储型）。
func hasInitializer(in tail: String) -> Bool {
  let equalsIndex = tail.firstIndex(of: "=")
  let braceIndex = tail.firstIndex(of: "{")
  switch (equalsIndex, braceIndex) {
  case let (equals?, brace?): return equals < brace
  case (nil, _): return false
  case (_?, nil): return true
  }
}

// MARK: - R7 豁免判定

func isTraceableNumber(
  token: String,
  range: NSRange,
  code: String,
  lineText: String,
  prefix: String
) -> Bool {
  // 豁免 0 / 1 / -1（`-1` 的正则命中是 `1`）
  if token == "0" || token == "1" { return true }

  // 豁免数组索引 [0] / [1] / [12]
  if let stringRange = Range(range, in: code) {
    let lower = stringRange.lowerBound
    let upper = stringRange.upperBound
    if lower > code.startIndex, code[code.index(before: lower)] == "[" {
      if upper < code.endIndex, code[upper] == "]" { return true }
    }
  }

  // 豁免 .opacity( / .zIndex( / lineLimit( 的（首参）数值
  if Regex(#"(\.opacity|\.zIndex|\.lineLimit)\(\s*$"#).isMatch(prefix) { return true }

  // 豁免 #available / @available 版本号
  if lineText.contains("#available(") || lineText.contains("@available(") { return true }

  return false
}

// MARK: - 行内豁免

enum Suppression {
  static let marker = "wd-structure-check:disable"

  /// 同一行是否有针对该规则、且理由非空的豁免指令。
  static func isSuppressed(rule: String, line: String) -> Bool {
    guard let markerRange = line.range(of: marker) else { return false }
    let rest = String(line[markerRange.upperBound...])

    let separators = ["—", "--"]
    let candidates = separators.compactMap { rest.range(of: $0) }
    guard let separator = candidates.min(by: { $0.lowerBound < $1.lowerBound }) else {
      return false
    }

    let rulesPart = String(rest[rest.startIndex..<separator.lowerBound])
    let reason = String(rest[separator.upperBound...])
      .trimmingCharacters(in: CharacterSet(charactersIn: "- \t"))
    guard !reason.isEmpty else { return false }

    let ids =
      rulesPart
      .split(whereSeparator: { $0 == "," || $0 == " " || $0 == "\t" || $0 == "、" })
      .map(String.init)
    return ids.contains(rule) || ids.contains("all")
  }
}

// MARK: - 引擎

struct Report {
  let violations: [Violation]
  let suppressed: Int
  let ruleCount: Int
}

enum Engine {
  static func run(rules: [Rule], layout: Layout, options: Options) -> Report {
    let active = rules.filter { options.onlyRules.isEmpty || options.onlyRules.contains($0.id) }
    let context = layout.context
    var raw: [Violation] = []

    for rule in active {
      switch rule.scope {
      case .tree:
        for finding in rule.runTree(context) {
          raw.append(
            Violation(
              rule: rule.id,
              severity: rule.severity,
              path: finding.path,
              line: finding.line,
              message: finding.message
            )
          )
        }
      case .file:
        for file in layout.files {
          for finding in rule.runFile(file, context) {
            raw.append(
              Violation(
                rule: rule.id,
                severity: rule.severity,
                path: finding.path,
                line: finding.line,
                message: finding.message
              )
            )
          }
        }
      }
    }

    var fileByPath: [String: SourceFile] = [:]
    for file in layout.files { fileByPath[file.path] = file }

    var kept: [Violation] = []
    var suppressed = 0
    for violation in raw {
      if violation.line > 0,
        let file = fileByPath[violation.path],
        violation.line <= file.rawLines.count,
        Suppression.isSuppressed(rule: violation.rule, line: file.rawLines[violation.line - 1])
      {
        suppressed += 1
        continue
      }
      kept.append(violation)
    }

    kept.sort { lhs, rhs in
      if lhs.path != rhs.path { return lhs.path < rhs.path }
      if lhs.line != rhs.line { return lhs.line < rhs.line }
      return lhs.rule < rhs.rule
    }

    return Report(violations: kept, suppressed: suppressed, ruleCount: active.count)
  }
}

// MARK: - 选项

enum OptionError: Error, CustomStringConvertible {
  case message(String)

  var description: String {
    switch self {
    case let .message(text): return text
    }
  }
}

struct Options {
  var root = "."
  var onlyRules: Set<String> = []
  var strict = false
  var listRules = false
  var help = false
  var quiet = false
  /// 只跑跨仓令牌溯源（SPEC §1.5.4-3 / I-M0-g），不跑 R1–R21。
  var tokensTrace = false
  /// manifest 路径覆盖（默认 <root>/../wisdomdesign/dist/tokens.manifest.json）。
  var tokensManifest: String?

  static let usage = """
    wd-structure-check —— iOS 结构/依赖/字面量/生成物检查器（R1–R21）

    用法：
      wd-structure-check [--root <目录>] [--rule <Rn>]... [--strict] [--quiet] [--list-rules] [--tokens-trace] [--help]

    参数：
      --root <目录>    扫描根（需含 Sources/ 和/或 Tests/；默认 .）
      --rule <Rn>      只跑指定规则（可重复；如 --rule R1 --rule R13a）
      --strict         warning 也视为失败（M3 起把 R7/R20/R21 转 error 后可用）
      --quiet          只输出退出码，不打印违规与摘要
      --list-rules     列出规则：id<TAB>severity<TAB>scope<TAB>summary
      --tokens-trace   跨仓同批自证：读设计仓 dist/tokens.manifest.json，断言 sha12 与生成物一致
                       （manifest 缺失 = fail；SPEC §1.5.4-3。默认路径 <root>/../wisdomdesign/dist/tokens.manifest.json）
      --tokens-manifest <路径>  覆盖 manifest 路径（相对 <root> 或绝对；也可用环境变量 WD_TOKENS_MANIFEST）
      -h, --help       本帮助

    行内豁免（理由非空才生效）：
      // wd-structure-check:disable R1 — 理由
      规则 id 可用逗号/空格分隔多个，或写 all；分隔符支持 `—` 与 `--`；只作用于同一行。

    退出码：0 = 无 error 级违规；1 = 有 error 级违规（--strict 下任何违规）；2 = 用法/IO 错误。
    """

  static func parse(_ arguments: [String]) throws -> Options {
    var options = Options()
    var index = 1
    while index < arguments.count {
      let argument = arguments[index]
      switch argument {
      case "--root":
        index += 1
        guard index < arguments.count else { throw OptionError.message("--root 缺少参数") }
        options.root = arguments[index]
      case "--rule":
        index += 1
        guard index < arguments.count else { throw OptionError.message("--rule 缺少参数") }
        options.onlyRules.insert(arguments[index])
      case "--strict":
        options.strict = true
      case "--quiet":
        options.quiet = true
      case "--list-rules":
        options.listRules = true
      case "--tokens-trace":
        options.tokensTrace = true
      case "--tokens-manifest":
        index += 1
        guard index < arguments.count else { throw OptionError.message("--tokens-manifest 缺少参数") }
        options.tokensManifest = arguments[index]
      case "-h", "--help":
        options.help = true
      default:
        if argument.hasPrefix("--root=") {
          options.root = String(argument.dropFirst("--root=".count))
        } else if argument.hasPrefix("--rule=") {
          options.onlyRules.insert(String(argument.dropFirst("--rule=".count)))
        } else if argument.hasPrefix("--tokens-manifest=") {
          options.tokensManifest = String(argument.dropFirst("--tokens-manifest=".count))
        } else {
          throw OptionError.message("未知参数 '\(argument)'（--help 看用法）")
        }
      }
      index += 1
    }
    return options
  }
}

// MARK: - 常量

extension Scanner {
  static let allowedTestableImports: Set<String> = [
    "WisdomUI", "WisdomUIPreviews", "wd-structure-check",
  ]

  static let mirrorLayerNames: Set<String> = [
    "foundation", "components", "internal", "primitives", "composites",
    "typography", "theme", "layout", "motion", "material", "accessibility",
    "icons", "tokens", "generated",
  ]

  static let allowedOverridesTypes: Set<String> = [
    "WDColorOverrides", "WDGradientOverrides", "WDMaterialOverrides",
  ]

  /// 「标识符/键名」形态（SPEC §1.1.2 的 R15 + §3.7 的 I41：「其余只允许标识符/键名」）。
  ///
  /// R15 原实现只要字面量里出现 L-B 标点就报错，于是**契约键名**（如语义色槽位路径
  /// `text.primary`）在非白名单目录里必然假红——与 I41 的白名单句冲突。
  /// 形态判定：ASCII 字母数字段，用**单个** `.` / `-` / `_` 连接，首尾不得是分隔符。
  /// 通过：`text.primary`、`card-solid`、`fill.pressed`；不通过：`Loading...`、`a, b`、`第 1 项`。
  /// 只看形态不看语义：中文文案本就不含 ASCII 标点，不受本白名单影响。
  static func isKeyNameLiteral(_ text: String) -> Bool {
    guard !text.isEmpty else { return false }
    var sawAlnum = false
    var previousWasSeparator = true
    for character in text {
      if character.isASCII, character.isLetter || character.isNumber {
        sawAlnum = true
        previousWasSeparator = false
      } else if character == "." || character == "-" || character == "_" {
        guard !previousWasSeparator else { return false }
        previousWasSeparator = true
      } else {
        return false
      }
    }
    return sawAlnum && !previousWasSeparator
  }

  /// L-B 标点集合（照 SPEC §1.1.2 R15）。
  static let lbPunctuation: Set<Character> = [
    "，", "。", "、", "；", "：", "！", "？", ",", ".", ";", ":", "!", "?",
  ]

  /// L-B 词序模板（照 SPEC §1.1.2 R15）。
  static let lbWordOrder: [String] = ["第", "共", "关闭", " of "]

  /// R21 的容器窗口半径（行）。
  static let textContainerWindow = 12
}

// MARK: - 令牌溯源（--tokens-trace；SPEC §1.5.4-3 / I-M0-g）

/// 跨仓同批自证：读设计仓的 `dist/tokens.manifest.json`（随设计仓 tag 冻结），
/// 断言它与本端**生成物**的「令牌变更集标识」一致。
///
/// 判据（**缺失 = fail，不 skip**；SPEC §1.5.4-3、§9.3-5）：
///   ① manifest 存在且可解析（JSON）；
///   ② 生成物 banner（`generated/WDTokens.swift` 第 3 行）的 `tokens v<version> · sha256:<sha12>`；
///   ③ `generated/WDTokensVersion.swift` 的 `version` / `sha256` / `sha12` 常量；
///   ④ manifest 里 `iOS/` 前缀的 artifact **至少 1 条**且文件在工作区中存在。
///
/// **不比对每条 artifact 的 sha256 字节**：那是生成器 `--check` 的职责（重跑并逐字节比对）；
/// 本命令只做「与设计仓同批」这一件事（`WDTokensVersion` 只能证明 iOS 内部自洽，见 SPEC §1.5.4-3）。
enum TokenTrace {
  struct Manifest {
    let version: String
    let sha256: String
    let sha12: String
    let iOSArtifacts: [String]
  }

  enum TraceError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
      switch self {
      case .message(let text): return text
      }
    }
  }

  /// 默认路径 = `<root>/../wisdomdesign/dist/tokens.manifest.json`（root 即 iOS 仓根）。
  /// 覆盖优先级：`--tokens-manifest` > 环境变量 `WD_TOKENS_MANIFEST` > 默认。
  static func manifestURL(root: URL, override: String?) -> URL {
    let value = override ?? ProcessInfo.processInfo.environment["WD_TOKENS_MANIFEST"]
    if let value, !value.isEmpty {
      if value.hasPrefix("/") { return URL(fileURLWithPath: value).standardizedFileURL }
      return root.appendingPathComponent(value).standardizedFileURL
    }
    return root.deletingLastPathComponent()
      .appendingPathComponent("wisdomdesign/dist/tokens.manifest.json")
      .standardizedFileURL
  }

  static func loadManifest(_ url: URL) throws -> Manifest {
    let data = try Data(contentsOf: url)
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw TraceError.message("manifest 不是 JSON 对象")
    }
    func string(_ key: String) throws -> String {
      guard let value = object[key] as? String, !value.isEmpty else {
        throw TraceError.message("manifest 缺字段 '\(key)'")
      }
      return value
    }
    let artifacts = (object["artifacts"] as? [[String: Any]] ?? [])
      .compactMap { $0["path"] as? String }
      .filter { $0.hasPrefix("iOS/") }
    return Manifest(
      version: try string("version"),
      sha256: try string("sha256"),
      sha12: try string("sha12"),
      iOSArtifacts: artifacts
    )
  }

  /// 生成物 banner（第 3 行）：`// tokens v<version> · sha256:<sha12> · …`
  static func parseBanner(_ text: String) -> (version: String, sha12: String)? {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    guard lines.count >= 3 else { return nil }
    let third = String(lines[2])
    guard let versionRange = third.range(of: "tokens v") else { return nil }
    let version = third[versionRange.upperBound...].prefix { $0 != " " && $0 != "·" }
    guard let hashRange = third.range(of: "sha256:") else { return nil }
    let sha12 = third[hashRange.upperBound...].prefix { $0.isHexDigit }
    guard !version.isEmpty, !sha12.isEmpty else { return nil }
    return (String(version), String(sha12))
  }

  /// 读 `public static let <name>: String = "<值>"` 的字面量（生成物形态固定，够用）。
  static func swiftConstant(_ name: String, in text: String) -> String? {
    for line in text.split(separator: "\n") {
      guard line.contains("static let \(name)") else { continue }
      guard let open = line.range(of: "\"") else { continue }
      let rest = line[open.upperBound...]
      guard let close = rest.firstIndex(of: "\"") else { continue }
      return String(rest[..<close])
    }
    return nil
  }

  static func run(root: URL, override: String?, quiet: Bool) -> Int32 {
    let url = manifestURL(root: root, override: override)
    let workspace = root.deletingLastPathComponent()
    let shown =
      url.path.hasPrefix(workspace.path + "/")
      ? String(url.path.dropFirst(workspace.path.count + 1)) : url.path

    guard FileManager.default.fileExists(atPath: url.path) else {
      emitError(
        "tokens-trace: manifest 缺失 —— \(shown)\n"
          + "  SPEC §1.5.4-3：manifest 缺失 = fail（不 skip）。\n"
          + "  修法：在设计仓跑 node tools/token-build/build.js --platforms=none --emit-manifest；\n"
          + "        或把设计仓 checkout 到 \(workspace.path)/wisdomdesign；\n"
          + "        或用 --tokens-manifest / WD_TOKENS_MANIFEST 指定路径。",
        code: 1
      )
    }

    let manifest: Manifest
    do {
      manifest = try loadManifest(url)
    } catch {
      emitError("tokens-trace: manifest 解析失败（\(shown)）：\(error)", code: 1)
    }

    var failures = 0
    func expect(_ condition: Bool, _ ok: String, _ bad: String) {
      if quiet {
        if !condition { failures += 1 }
        return
      }
      if condition {
        print("✓ \(ok)")
      } else {
        print("✗ \(bad)")
        failures += 1
      }
    }

    let generated = root.appendingPathComponent("Sources/WisdomUI/Foundation/generated")
    let tokensFile = generated.appendingPathComponent("WDTokens.swift")
    let versionFile = generated.appendingPathComponent("WDTokensVersion.swift")
    let banner = (try? String(contentsOf: tokensFile, encoding: .utf8)).flatMap(parseBanner)
    let versionText = (try? String(contentsOf: versionFile, encoding: .utf8)) ?? ""

    expect(
      banner != nil,
      "生成物 banner 可解析（generated/WDTokens.swift 第 3 行）",
      "生成物 banner 缺失或不可解析：generated/WDTokens.swift 第 3 行应形如 // tokens v<version> · sha256:<sha12>"
    )
    expect(
      banner?.sha12 == manifest.sha12,
      "banner.sha12 == manifest.sha12（\(manifest.sha12)）",
      "banner.sha12 != manifest.sha12：banner=\(banner?.sha12 ?? "?") manifest=\(manifest.sha12)"
    )
    expect(
      banner?.version == manifest.version,
      "banner.version == manifest.version（\(manifest.version)）",
      "banner.version != manifest.version：banner=\(banner?.version ?? "?") manifest=\(manifest.version)"
    )

    let swiftVersion = swiftConstant("version", in: versionText)
    let swiftSHA256 = swiftConstant("sha256", in: versionText)
    let swiftSHA12 = swiftConstant("sha12", in: versionText)
    expect(
      swiftVersion == manifest.version,
      "WDTokensVersion.version == manifest.version",
      "WDTokensVersion.version != manifest.version：\(swiftVersion ?? "?") vs \(manifest.version)"
    )
    expect(
      swiftSHA256 == manifest.sha256,
      "WDTokensVersion.sha256 == manifest.sha256",
      "WDTokensVersion.sha256 != manifest.sha256：\(swiftSHA256 ?? "?") vs \(manifest.sha256)"
    )
    expect(
      swiftSHA12 == manifest.sha12,
      "WDTokensVersion.sha12 == manifest.sha12",
      "WDTokensVersion.sha12 != manifest.sha12：\(swiftSHA12 ?? "?") vs \(manifest.sha12)"
    )

    expect(
      !manifest.iOSArtifacts.isEmpty,
      "manifest 覆盖 iOS 端产物（\(manifest.iOSArtifacts.count) 条）",
      "manifest 里没有 iOS/ 前缀的 artifact ⇒ 本端未被覆盖（0 条也算假绿）"
    )
    let missing = manifest.iOSArtifacts.filter {
      !FileManager.default.fileExists(atPath: workspace.appendingPathComponent($0).path)
    }
    expect(
      missing.isEmpty,
      "manifest 列的 \(manifest.iOSArtifacts.count) 条 iOS 产物都在工作区",
      "manifest 列的 iOS 产物缺失：\(missing.joined(separator: ", "))"
    )

    if !quiet {
      print(
        "wd-structure-check: tokens-trace manifest=\(shown) version=\(manifest.version)"
          + " sha12=\(manifest.sha12) iOS_artifacts=\(manifest.iOSArtifacts.count) failures=\(failures)"
      )
    }
    return failures > 0 ? 1 : 0
  }
}

// MARK: - 入口

func emitError(_ message: String, code: Int32) -> Never {
  FileHandle.standardError.write(Data("wd-structure-check: \(message)\n".utf8))
  exit(code)
}

let options: Options
do {
  options = try Options.parse(CommandLine.arguments)
} catch {
  emitError("\(error)", code: 2)
}

if options.help {
  print(Options.usage)
  exit(0)
}

let rules = makeRules()

if options.listRules {
  for rule in rules {
    print("\(rule.id)\t\(rule.severity.rawValue)\t\(rule.scope.rawValue)\t\(rule.summary)")
  }
  exit(0)
}

let knownRuleIDs = Set(rules.map(\.id))
let unknownRuleIDs = options.onlyRules.subtracting(knownRuleIDs)
guard unknownRuleIDs.isEmpty else {
  emitError("未知规则 id：\(unknownRuleIDs.sorted().joined(separator: ", "))", code: 2)
}

let rootURL = URL(fileURLWithPath: options.root).standardizedFileURL
var rootIsDirectory: ObjCBool = false
guard FileManager.default.fileExists(atPath: rootURL.path, isDirectory: &rootIsDirectory),
  rootIsDirectory.boolValue
else {
  emitError("--root '\(options.root)' 不存在或不是目录", code: 2)
}

if options.tokensTrace {
  exit(TokenTrace.run(root: rootURL, override: options.tokensManifest, quiet: options.quiet))
}

let layout: Layout
do {
  layout = try Scanner.scan(root: rootURL)
} catch {
  emitError("扫描 '\(options.root)' 失败：\(error)", code: 2)
}

let report = Engine.run(rules: rules, layout: layout, options: options)
let errorCount = report.violations.filter { $0.severity == .error }.count
let warningCount = report.violations.count - errorCount

if !options.quiet {
  for violation in report.violations {
    print(violation.textLine)
  }
  print(
    "wd-structure-check: root=\(options.root) files=\(layout.files.count) rules=\(report.ruleCount)"
      + " errors=\(errorCount) warnings=\(warningCount) suppressed=\(report.suppressed)"
  )
}

if errorCount > 0 { exit(1) }
if options.strict, !report.violations.isEmpty { exit(1) }
exit(0)
