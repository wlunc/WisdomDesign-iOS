import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// `WDAvatar`（M2；B2 扩五档/在线/停用；A-11 扩成员四色/照片形态 + 回退链）的组件级断言。
///
/// 覆盖三块：
/// 1. 设计 12：五档直径、固定字号、在线点不改变尺寸、已停用可构造；
/// 2. 设计 14 §1.3：`WDMemberTone.assign(memberID:)` 的五个 fixture + 三条规则（纯函数/撞色/UTF-8）；
/// 3. 设计 14 §1.4：照片回退链（有图 → 照片；无图有字 → 落色文字；无图无字有图标 → person 图标）
///    与"tone 默认回落 `surface.tint`"的像素级证据。
@MainActor
@Suite("WDAvatar（M2 + A-11）")
struct WDAvatarTests {
  private static func size(
    _ value: WDAvatarValue,
    avatarSize: WDAvatarSize? = nil,
    isOnline: Bool = false,
    typeSize: DynamicTypeSize = .large
  ) -> CGSize {
    let avatar =
      avatarSize.map {
        WDAvatar(value: value, size: $0, isOnline: isOnline)
      } ?? WDAvatar(value: value)
    let controller = UIHostingController(
      rootView:
        avatar
        .environment(\.dynamicTypeSize, typeSize)
        .wdTheme(.light)
    )
    return controller.sizeThatFits(in: CGSize(width: 200, height: 200))
  }

  @Test("直径锁死 32 ± 1（md 档；文字/图标两种形态一致）")
  func diameterIs32() {
    let label = Self.size(.init(label: Text(verbatim: "妈")))
    let icon = Self.size(.init(icon: .profile))
    #expect(abs(label.width - 32) <= 1, "文字头像宽度实测 \(label.width)")
    #expect(abs(label.height - 32) <= 1, "文字头像高度实测 \(label.height)")
    #expect(abs(icon.width - 32) <= 1, "图标头像宽度实测 \(icon.width)")
    #expect(abs(icon.height - 32) <= 1, "图标头像高度实测 \(icon.height)")
  }

  @Test("五档直径 20 / 28 / 32 / 40 / 56（±1）；rawValue 稳定")
  func fiveSizes() {
    #expect(
      WDAvatarSize.allCases.map(\.rawValue) == ["xs", "sm", "md", "lg", "xl"])
    let expected: [WDAvatarSize: CGFloat] = [
      .xs: 20, .sm: 28, .md: 32, .lg: 40, .xl: 56,
    ]
    for size in WDAvatarSize.allCases {
      let measured = Self.size(.init(label: Text(verbatim: "妈")), avatarSize: size)
      let target = expected[size] ?? 0
      #expect(abs(measured.width - target) <= 1, "\(size.rawValue) 宽 \(measured.width)")
      #expect(abs(measured.height - target) <= 1, "\(size.rawValue) 高 \(measured.height)")
    }
  }

  @Test("在线点只做 overlay，不改变头像尺寸")
  func onlineKeepsSize() {
    let plain = Self.size(.init(label: Text(verbatim: "妈")), avatarSize: .lg)
    let online = Self.size(
      .init(label: Text(verbatim: "妈")), avatarSize: .lg, isOnline: true)
    #expect(plain == online)
  }

  @Test("已停用可构造（50% + 去饱和）")
  func disabledConstructible() {
    let avatar = WDAvatar(
      value: .init(label: Text(verbatim: "妈")), size: .md, isDisabled: true)
    let controller = UIHostingController(rootView: avatar.wdTheme(.light))
    #expect(controller.sizeThatFits(in: CGSize(width: 200, height: 200)).width > 0)
  }

  @Test("AX5 下不放大：直径与首字号按设计固定（例外项，R7/R11 行内豁免）")
  func fixedAtLargeType() {
    let normal = Self.size(.init(label: Text(verbatim: "妈")), typeSize: .large)
    let ax5 = Self.size(.init(label: Text(verbatim: "妈")), typeSize: .accessibility5)
    #expect(abs(normal.width - ax5.width) <= 0.5, "宽度放大了：\(normal.width) → \(ax5.width)")
    #expect(abs(normal.height - ax5.height) <= 0.5, "高度放大了：\(normal.height) → \(ax5.height)")
  }

  @Test("两个值形态可构造、可比较（送给 WDListRowLeading.avatar）")
  func valueType() {
    #expect(
      WDAvatarValue(label: Text(verbatim: "妈")) == WDAvatarValue(label: Text(verbatim: "妈")))
    #expect(WDAvatarValue(icon: .profile) == WDAvatarValue(icon: .profile))
    #expect(WDAvatarValue(icon: .profile) != WDAvatarValue(label: Text(verbatim: "妈")))
  }

  // MARK: - A-11 · 四色分配（设计 14 §1.3）

  @Test("FNV-1a 五个 fixture：u_1001→tone4、u_1002→tone3、u_1003→tone2、u_1004→tone1、u_1005→tone4")
  func memberToneFixtures() {
    // fixture 表 = 设计 14 §1.3「取样结果」；两端对拍靠这五行。
    let expected: [String: WDMemberTone] = [
      "u_1001": .tone4,
      "u_1002": .tone3,
      "u_1003": .tone2,
      "u_1004": .tone1,
      "u_1005": .tone4,
    ]
    for (memberID, tone) in expected {
      #expect(
        WDMemberTone.assign(memberID: memberID) == tone,
        "\(memberID) 应落 \(tone.rawValue)，实测 \(WDMemberTone.assign(memberID: memberID).rawValue)")
    }
    // 中间量也对：设计把 FNV-1a 的 32 位值逐行写出来了，两端调试时先比哈希再比档。
    let hashes: [String: UInt32] = [
      "u_1001": 1_050_025_199,
      "u_1002": 1_066_802_818,
      "u_1003": 1_083_580_437,
      "u_1004": 966_137_104,
      "u_1005": 982_914_723,
    ]
    for (memberID, hash) in hashes {
      #expect(
        WDMemberTone.fnv1a32(memberID) == hash,
        "\(memberID) 的 FNV-1a 应为 \(hash)，实测 \(WDMemberTone.fnv1a32(memberID))")
    }
  }

  @Test("分配是纯函数；允许撞色（u_1001 与 u_1005 都是 tone-4）")
  func memberToneIsPureAndMayCollide() {
    #expect(WDMemberTone.assign(memberID: "u_1001") == WDMemberTone.assign(memberID: "u_1001"))
    #expect(WDMemberTone.assign(memberID: "u_1001") == WDMemberTone.assign(memberID: "u_1005"))
    // 空 ID 不崩、也落在四档之内（FNV-1a 的空串结果 = 偏移基 0x811C9DC5）。
    #expect(WDMemberTone.allCases.contains(WDMemberTone.assign(memberID: "")))
  }

  @Test("按 UTF-8 逐字节：非 ASCII 成员 ID 也稳定出档（两端同算法）")
  func memberToneUsesUTF8Bytes() {
    // 中文成员 ID：按 UTF-8 字节算，不按 Character 算 —— 换个算法这里就会漂。
    let tone = WDMemberTone.assign(memberID: "成员-甲")
    #expect(WDMemberTone.allCases.contains(tone))
    #expect(tone == WDMemberTone.assign(memberID: "成员-甲"))
    // 单字节偏置可逐字节复核：'a' 的码位就是它的 UTF-8 字节。
    #expect(WDMemberTone.fnv1a32("a") == (UInt32(0x811C_9DC5) ^ 0x61) &* 0x0100_0193)
  }

  // MARK: - A-11 · 四色渲染与默认回落（设计 14 §1.2 / §1.4）

  @Test("tone 非 nil：底 = fill（浅色 tone-1 = 0xB0D5DF）")
  func toneDrivesBackground() {
    let sampled = Self.pixel(
      WDAvatar(value: .init(label: Text(verbatim: "妈")), size: .md, tone: .tone1),
      theme: .light)
    #expect(
      Self.isClose(sampled, red: 0xB0, green: 0xD5, blue: 0xDF),
      "tone-1 底色应为 0xB0D5DF，实测 \(sampled)")
  }

  @Test("tone = nil：回落 surface.tint（既有观感逐像素不变）")
  func defaultToneFallsBackToSurfaceTint() {
    let fallback = Self.pixel(
      WDAvatar(value: .init(label: Text(verbatim: "妈")), size: .md), theme: .light)
    let tint = Self.rgb(WDColorValues.light.surfaceTint)
    #expect(
      Self.isClose(fallback, red: tint.r, green: tint.g, blue: tint.b),
      "默认底色应为 surface.tint \(tint)，实测 \(fallback)")
    // 既有构造 init(value:) 与显式 md 档等价（语义不变）。
    let legacy = Self.pixel(WDAvatar(value: .init(label: Text(verbatim: "妈"))), theme: .light)
    #expect(legacy == fallback)
  }

  // MARK: - A-11 · 照片形态与回退链（设计 14 §1.4）

  @Test("回退链第一档：照片就绪 → resolved 是 .photo")
  func photoWins() {
    let value = WDAvatarValue(
      image: Image(systemName: "person.crop.circle.fill"), label: Text(verbatim: "妈"))
    guard case .photo = value.resolved else {
      Issue.record("有照片时 resolved 必须是 .photo（照片优先于文字）")
      return
    }
    #expect(value != WDAvatarValue(label: Text(verbatim: "妈")), "有图与无图的值必须不相等")
  }

  @Test("照片形态真的画图：圆心像素是图片本身，不铺 tone / tint 底色")
  func photoRendersImageNotBackdrop() {
    let red = Self.solidImage(red: 0xFF, green: 0x00, blue: 0x00)
    let sampled = Self.pixel(
      WDAvatar(
        value: .init(image: red, label: Text(verbatim: "妈")), size: .md, tone: .tone3),
      theme: .light)
    #expect(sampled.r >= 200 && sampled.g <= 60 && sampled.b <= 60, "圆心应是照片本身，实测 \(sampled)")
  }

  @Test("回退链第二档：没有照片但有文字 → 落色文字头像（走 tone 底色）")
  func fallsBackToLabel() {
    // 调用方取图失败 ⇒ `image: nil`（连回退内容一起给）⇒ 值里没有照片 ⇒ 落到文字档。
    let failedFetch = WDAvatarValue(image: nil, label: Text(verbatim: "妈"))
    guard case .label = failedFetch.resolved else {
      Issue.record("image: nil 时必须落到文字档（禁止破图/占位帧）")
      return
    }
    #expect(failedFetch == WDAvatarValue(label: Text(verbatim: "妈")), "空图与纯文字形态等价")
    let value = WDAvatarValue(label: Text(verbatim: "妈"))
    guard case .label = value.resolved else {
      Issue.record("无照片有文字时 resolved 必须是 .label")
      return
    }
    let sampled = Self.pixel(
      WDAvatar(value: value, size: .md, tone: .tone4), theme: .light)
    #expect(
      Self.isClose(sampled, red: 0x06, green: 0x52, blue: 0x79),
      "回退后的文字头像应铺 tone-4 底色 0x065279，实测 \(sampled)")
  }

  @Test("回退链第三档：没有照片也没有文字 → person 图标（surface.tint 底 + text.on-soft）")
  func fallsBackToIcon() {
    let value = WDAvatarValue(icon: .profile)
    guard case .icon(let icon) = value.resolved else {
      Issue.record("只有图标时 resolved 必须是 .icon")
      return
    }
    #expect(icon == .profile)
    let sampled = Self.pixel(WDAvatar(value: value, size: .md), theme: .light)
    let tint = Self.rgb(WDColorValues.light.surfaceTint)
    #expect(
      Self.isClose(sampled, red: tint.r, green: tint.g, blue: tint.b),
      "图标形态的底仍是 surface.tint，实测 \(sampled)")
  }

  @Test("照片形态的尺寸与文字形态一致（2pt 描边不撑大直径）")
  func photoKeepsDiameter() {
    let photo = Self.size(
      .init(image: Image(systemName: "person.crop.circle.fill"), label: Text(verbatim: "妈")),
      avatarSize: .xl)
    let label = Self.size(.init(label: Text(verbatim: "妈")), avatarSize: .xl)
    #expect(abs(photo.width - label.width) <= 0.5, "照片宽 \(photo.width) vs 文字宽 \(label.width)")
    #expect(
      abs(photo.height - label.height) <= 0.5, "照片高 \(photo.height) vs 文字高 \(label.height)")
  }

  @Test("Equatable 只看 label / icon / 是否有照片（照片负载本身不参与相等）")
  func equatableIgnoresPhotoPayload() {
    let person = Image(systemName: "person.crop.circle.fill")
    let other = Image(systemName: "photo")
    let lhs = WDAvatarValue(image: person, label: Text(verbatim: "妈"))
    let rhs = WDAvatarValue(image: other, label: Text(verbatim: "妈"))
    #expect(lhs == rhs, "两张不同的图 + 同一个回退文字 ⇒ 相等（只看有没有图）")
    #expect(lhs != WDAvatarValue(label: Text(verbatim: "妈")), "有图 != 无图")
    #expect(
      WDAvatarValue(image: person, label: Text(verbatim: "妈"))
        != WDAvatarValue(image: person, label: Text(verbatim: "明")),
      "回退文字不同 ⇒ 不相等")
  }

  // MARK: - 像素取样（ImageRenderer 出图后按点取像素；不依赖快照基线）

  private struct Probe: View {
    let avatar: WDAvatar

    var body: some View {
      avatar
    }
  }

  /// 渲染 md 档（32×32）后取**圆内偏上**的一点：避开中间的首字，也不踩圆边的抗锯齿。
  static func pixel(_ avatar: WDAvatar, theme: WDTheme) -> (r: Int, g: Int, b: Int) {
    let side = 32
    let renderer = ImageRenderer(
      content: Probe(avatar: avatar).wdTheme(theme).frame(width: 32, height: 32))
    renderer.scale = 1
    guard let image = renderer.uiImage, let cgImage = image.cgImage else { return (-1, -1, -1) }
    var buffer = [UInt8](repeating: 0, count: side * side * 4)
    guard
      let context = CGContext(
        data: &buffer, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return (-1, -1, -1) }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
    // 圆心 (16,16)；取 (16,6)：距圆心 10pt，圆半径 16pt ⇒ 圆内且远离首字。
    let x = 16
    let y = 6
    let offset = y * side * 4 + x * 4
    return (Int(buffer[offset]), Int(buffer[offset + 1]), Int(buffer[offset + 2]))
  }

  /// 单色图（用于证明"画的是照片本身"）。
  static func solidImage(red: Int, green: Int, blue: Int) -> Image {
    let size = CGSize(width: 4, height: 4)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
      let scale: CGFloat = 255  // wd-structure-check:disable R7 — 测试夹具的 0–255 → 0–1 换算
      UIColor(
        red: CGFloat(red) / scale, green: CGFloat(green) / scale, blue: CGFloat(blue) / scale,
        alpha: 1
      ).setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
    return Image(uiImage: image)
  }

  static func rgb(_ color: Color) -> (r: Int, g: Int, b: Int) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    let scale: CGFloat = 255  // wd-structure-check:disable R7 — 0–1 → 0–255 的换算系数
    return (
      Int((red * scale).rounded()), Int((green * scale).rounded()), Int((blue * scale).rounded())
    )
  }

  static func isClose(_ pixel: (r: Int, g: Int, b: Int), red: Int, green: Int, blue: Int) -> Bool {
    abs(pixel.r - red) <= 2 && abs(pixel.g - green) <= 2 && abs(pixel.b - blue) <= 2
  }
}
