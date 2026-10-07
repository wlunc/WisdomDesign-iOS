import SwiftUI
import Testing
import UIKit
import WisdomUI

/// 快照支撑：状态矩阵、渲染器显式表、基线的记录与比对（SPEC §1.6 / §1.5.5）。
///
/// 矩阵口径：文档写作「六态：浅/深 × 默认/AX3 × LTR/RTL」，三个轴相乘 = `8 态`
///（「六态」是 U6 交互态的词，见 DEV-PLAN §2.2/§15.1-⑦）。本实现按括号里的三个轴执行，
/// 计数偏差登记为文档回写项。
///
/// 渲染器（E6 的显式表）：玻璃类 6 个必须走 UIHostingController + drawHierarchy
///（ImageRenderer 不渲染 Material/glassEffect），其余走 ImageRenderer。
@MainActor
enum SnapshotSupport {
  enum Appearance: String, CaseIterable, Sendable { case light, dark }
  enum TypeSize: String, CaseIterable, Sendable { case `default`, ax3 }
  enum Direction: String, CaseIterable, Sendable { case ltr, rtl }

  struct State: Hashable, Sendable {
    let appearance: Appearance
    let typeSize: TypeSize
    let direction: Direction
    var id: String { "\(appearance.rawValue)-\(typeSize.rawValue)-\(direction.rawValue)" }
  }

  /// 8 态矩阵（浅/深 × 默认/AX3 × LTR/RTL）。
  static let matrix: [State] = Appearance.allCases.flatMap { appearance in
    TypeSize.allCases.flatMap { typeSize in
      Direction.allCases.map { direction in
        State(appearance: appearance, typeSize: typeSize, direction: direction)
      }
    }
  }

  /// 玻璃类 6 个（SPEC §1.6 的 E6 补充）——必须用 drawHierarchy 渲染器。
  static let glassComponents: [String] = [
    "WDBottomSheet", "WDActionSheet", "WDTabBar", "WDNavigationBar", "WDToolbar", "WDCard.glass",
  ]

  static func requiresHierarchyRenderer(_ component: String) -> Bool {
    glassComponents.contains(component)
  }

  /// 该状态使用的调色板。
  ///
  /// @@WDColorValues.light/.dark@@ 是**固定色**（不是自适应 @@Color(wdLight:dark:)@@），
  /// 所以深色态必须显式把 @@.dark@@ 注入画廊，光靠 @@colorScheme@@ 环境是不够的。
  static func values(for state: State) -> WDColorValues {
    state.appearance == .dark ? .dark : .light
  }

  /// 把状态的环境套到任意视图上（色外观 / 动态字体档 / 书写方向）。
  static func styled(_ view: some View, state: State) -> some View {
    view
      .environment(\.colorScheme, state.appearance == .dark ? .dark : .light)
      .environment(\.dynamicTypeSize, state.typeSize == .ax3 ? .accessibility3 : .large)
      .environment(\.layoutDirection, state.direction == .rtl ? .rightToLeft : .leftToRight)
  }

  /// 渲染成 PNG（普通视图走 ImageRenderer）。
  ///
  /// **只固定宽度、不固定高度**：高度由内容决定 —— 固定高度会把画廊上下裁掉
  /// （M1 首版实测就是这样丢掉顶部标题与底部 overline 的）。
  static func png(_ view: some View, state: State, size: CGSize, scale: CGFloat = 2) -> Data? {
    let content = styled(view, state: state)
      .frame(width: size.width, alignment: .topLeading)
      .fixedSize(horizontal: false, vertical: true)
    let renderer = ImageRenderer(content: content)
    renderer.scale = scale
    return renderer.uiImage?.pngData()
  }

  /// 基线目录（源码目录；记录模式写它，普通模式读 bundle 资源）。
  static var sourceBaselineDirectory: URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Baselines")
  }

  static func bundledBaseline(_ name: String) -> Data? {
    guard let url = Bundle.module.url(forResource: "Baselines/\(name)", withExtension: "png") else {
      return nil
    }
    return try? Data(contentsOf: url)
  }

  static func bundledManifest() -> Manifest? {
    guard let url = Bundle.module.url(forResource: "Baselines/manifest", withExtension: "json")
    else {
      return nil
    }
    return try? JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
  }

  /// 基线 manifest：必须含工具链与设备（F26），否则跨机器比对就是假绿。
  struct Manifest: Codable, Sendable {
    struct Environment: Codable, Sendable {
      let xcode: String
      let sdk: String
      let deviceType: String
      let runtime: String
    }
    let environment: Environment
    /// 每个基线的 SHA-256（PNG 字节）。
    let sha256: [String: String]
    /// 像素差容忍比例：字节不同但像素几乎相同时不算漂移。
    let pixelDiffTolerance: Double
  }

  enum Verdict: Equatable {
    case identical
    case withinTolerance(pixelDiff: Double)
    case drifted(pixelDiff: Double)
    case missingBaseline
    case undecodable
  }

  /// 与基线比对：先比字节，再比像素（容忍度来自 manifest）。
  static func compare(name: String, png: Data) -> (Verdict, Manifest?) {
    let manifest = bundledManifest()
    guard let baseline = bundledBaseline(name) else { return (.missingBaseline, manifest) }
    if baseline == png { return (.identical, manifest) }
    guard let ratio = pixelDiffRatio(baseline, png) else { return (.undecodable, manifest) }
    let tolerance = manifest?.pixelDiffTolerance ?? 0.002
    return ratio <= tolerance
      ? (.withinTolerance(pixelDiff: ratio), manifest)
      : (.drifted(pixelDiff: ratio), manifest)
  }

  struct Bitmap {
    let width: Int
    let height: Int
    let pixels: [UInt8]
  }

  /// 逐像素差比例（RGBA8；尺寸不同直接记 1.0）。
  static func pixelDiffRatio(_ lhs: Data, _ rhs: Data) -> Double? {
    guard let a = bitmap(lhs), let b = bitmap(rhs) else { return nil }
    guard a.width == b.width, a.height == b.height else { return 1 }
    var differing = 0
    var total = 0
    for index in stride(from: 0, to: min(a.pixels.count, b.pixels.count), by: 4) {
      total += 1
      let dr = abs(Int(a.pixels[index]) - Int(b.pixels[index]))
      let dg = abs(Int(a.pixels[index + 1]) - Int(b.pixels[index + 1]))
      let db = abs(Int(a.pixels[index + 2]) - Int(b.pixels[index + 2]))
      let da = abs(Int(a.pixels[index + 3]) - Int(b.pixels[index + 3]))
      if max(max(dr, dg), max(db, da)) > 2 { differing += 1 }
    }
    guard total > 0 else { return nil }
    return Double(differing) / Double(total)
  }

  /// PNG → RGBA8 位图。
  static func bitmap(_ data: Data) -> Bitmap? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else { return nil }
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
      let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return Bitmap(width: width, height: height, pixels: pixels)
  }

  /// 基线缺失时的入库动作：**写盘（可能失败）+ 打印 base64**。
  ///
  /// 为什么不用环境变量开关：`xcodebuild test-without-building` **不会**把宿主 shell 的环境
  /// 带进模拟器里的测试进程（实测：`WD_SNAPSHOT_RECORD=1` 对测试不可见），所以"重录"的显式动作
  /// 定义为**删掉基线文件再跑**——缺失路径本身就是记录路径。
  static func record(name: String, png: Data) {
    let directory = sourceBaselineDirectory
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("\(name).png")
    let wrote = (try? png.write(to: url)) != nil
    print("BASELINE-B64 \(name) \(png.base64EncodedString())")
    print("BASELINE-PATH \(name) \(url.path) wrote=\(wrote)")
  }

  static func currentManifest(sha256: [String: String]) -> Manifest {
    let environment = ProcessInfo.processInfo.environment
    let runtime = environment["SIMULATOR_RUNTIME_VERSION"] ?? "unknown"
    return Manifest(
      environment: Manifest.Environment(
        xcode: environment["WD_XCODE_VERSION"] ?? "Xcode 26.6",
        sdk: runtime,
        deviceType: environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown",
        runtime: runtime
      ),
      sha256: sha256,
      pixelDiffTolerance: 0.002
    )
  }

  /// 校验一个状态：记录模式写盘 + 打印 base64；否则比对，缺失 = fail。
  static func verify(name: String, view: some View, state: State, size: CGSize) {
    guard let png = png(view, state: state, size: size) else {
      Issue.record("快照渲染失败：\(name)（\(state.id)）")
      return
    }
    let (verdict, manifest) = compare(name: name, png: png)
    switch verdict {
    case .identical:
      break
    case .withinTolerance(let ratio):
      print("快照 \(name)（\(state.id)）：像素差 \(ratio) 在容忍内（编码差异，不算漂移）")
    case .drifted(let ratio):
      let tolerance = manifest?.pixelDiffTolerance ?? 0.002
      Issue.record(
        """
        快照漂移：\(name)（\(state.id)）像素差 \(ratio)（容忍 \(tolerance)）
        —— 先判断是基线漂移还是实现变化（DEV-PLAN §16.4-③）
        """
      )
    case .missingBaseline:
      record(name: name, png: png)
      Issue.record(
        """
        基线缺失：\(name)（\(state.id)）—— 缺失 = fail；
        本次已把 PNG 写到 Baselines/ 并在日志打印 BASELINE-B64（取出后提交，再跑一次即为绿）
        """
      )
    case .undecodable:
      Issue.record("基线不可解码：\(name)（\(state.id)）")
    }
  }
}
