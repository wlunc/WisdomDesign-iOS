import SwiftUI

/// 头像的照片载荷（设计 14 §1.4；A-11）。
///
/// 库里**不做异步加载**（零资源 / 零网络 / 零第三方依赖）："就绪"由调用方判定 ——
/// 拿得到图就构造本类型，拿不到就不构造，值类型自己退回文字/图标形态。
/// 这条分工一次解决设计里三个硬要求：
/// - **加载中不占位、不骨架**：没有 URL 就没有"加载中"的中间态，压根不画占位；
/// - **失败 / 空图不出现破图**：破图只来自"取图失败后仍画一个 image 框"，这里没有那个框；
/// - **回退内容由调用方给，库内不猜**：回退用 `WDAvatarValue` 里调用方自己的文字/图标。
///
/// 照片按 `.resizable().scaledToFill()` 铺满圆形（裁切重心居中，设计 §1.4）；
/// 人脸偏置由调用方裁图（`unitPoint` 焦点参数 = 设计 14 §1.6-A11-Q1，本轮不进签名）。
public struct WDAvatarImage: Sendable {
  /// 已就绪的图片。
  let image: Image
  /// 照片的读屏文本；`nil` = **装饰性**（默认），给了才进无障碍树（设计 14 §2.5 的同口径）。
  let accessibilityLabel: Text?

  /// 照片形态：已就绪的图片 + 可选读屏文本。
  public init(_ image: Image, accessibilityLabel: Text? = nil) {
    self.image = image
    self.accessibilityLabel = accessibilityLabel
  }
}

/// 头像的值形态（WDAvatar 的载荷；SPEC §2.10-#12 / 冻结表单 §5.1-⑤）。
///
/// 三个构造入口对应三个槽位：
/// - `init(icon:)` —— 无姓名时的 person 占位；
/// - `init(label:)` —— 调用方给的首字/姓名（库内不推导）；
/// - `init(image:)` —— 照片形态（A-11），可同时带文字/图标作为**回退内容**。
///
/// **回退链是硬规则**（设计 14 §1.4）：有照片且已就绪 → 照片；否则有文字 → 落色文字头像；
/// 否则有图标 → person 图标。解析结果见 `resolved`。
///
/// **Equatable 语义（照片负载是 SwiftUI `Image`，本版选择「只看有没有图」）**：
/// `==` 只比较 **label、icon 与"是否有照片"**，**不比较照片本身**。
/// 理由：照片的身份（同一张图的不同 provider / 不同 scale 的同一图）不是值语义的一部分，
/// 逐像素比较没有意义；而"有没有图"是回退链唯一的开关 —— 它变了渲染结果就变了，
/// 必须参与相等。调用方若要在照片更换时强制重算，请在外面换 `.id(...)`，库里不猜图的等价性。
public struct WDAvatarValue: Sendable, Equatable {
  /// 图标占位（照片形态下作回退）。
  let icon: WDIconName?
  /// 文字（首字或姓名；库内不推导，由调用方给；照片形态下作回退）。
  let label: Text?
  /// 照片（A-11；就绪才有值）。
  let photo: WDAvatarImage?

  /// 图标形态。
  public init(icon: WDIconName) {
    self.icon = icon
    self.label = nil
    self.photo = nil
  }

  /// 文字形态。
  public init(label: Text) {
    self.icon = nil
    self.label = label
    self.photo = nil
  }

  /// 照片形态（A-11）。`label` / `icon` 是**回退内容**：照片不可用时显示，不是叠加内容。
  ///
  /// `image` 是可选的，回退链因此在**值构造处**就能表达完整：
  /// 图还没下载好 / 下载失败 ⇒ 传 `nil`（连同回退内容），渲染直接落到文字或图标档，
  /// 中间不存在"占位帧"或"破图帧"。照片就绪后再构造一个新值即可（160ms 淡入由组件负责）。
  ///
  /// F8 提示：`==` 不比较照片负载本身 —— 若调用方把本值用于 Equatable 驱动的 diff
  ///（`.animation(value:)` / `EquatableView` / `ForEach`）且需要"同一人换了照片"触发更新，
  /// 请在调用点换 `.id(...)`（如 `.id(memberID + photoVersion)`）；SwiftUI 结构化 diff
  /// 不受影响（照片照常重渲染）。
  public init(
    image: Image?,
    label: Text? = nil,
    icon: WDIconName? = nil,
    accessibilityLabel: Text? = nil
  ) {
    self.icon = icon
    self.label = label
    self.photo = image.map { WDAvatarImage($0, accessibilityLabel: accessibilityLabel) }
  }

  /// 相等：只比 label / icon / **是否有照片**（见类型注释的"Equatable 语义"）。
  public static func == (lhs: WDAvatarValue, rhs: WDAvatarValue) -> Bool {
    lhs.label == rhs.label
      && lhs.icon == rhs.icon
      && (lhs.photo == nil) == (rhs.photo == nil)
  }
}

extension WDAvatarValue {
  /// 回退链的解析结果（设计 14 §1.4 的三档 + 空）。
  enum Resolved {
    /// 有照片且已就绪。
    case photo(WDAvatarImage)
    /// 落色文字头像。
    case label(Text)
    /// person 图标占位。
    case icon(WDIconName)
    /// 三个槽位都空（不画内容，只留底色圆）。
    case empty
  }

  /// 按设计给的**硬顺序**解析：照片 → 文字 → 图标。
  ///
  /// internal 而非 private：回退链是设计硬规则，必须能被单测逐档断言
  ///（见 `Tests/WisdomUITests/Components/WDAvatarTests.swift`）。
  var resolved: Resolved {
    if let photo {
      return .photo(photo)
    }
    if let label {
      return .label(label)
    }
    if let icon {
      return .icon(icon)
    }
    return .empty
  }
}

/// 头像尺寸档（设计 12 §3：xs 20 / sm 28 / md 32 / lg 40 / xl 56）。
public enum WDAvatarSize: String, CaseIterable, Sendable, Equatable {
  case xs
  case sm
  case md
  case lg
  case xl
}

/// 头像（SPEC §2.10-#12；M2；B2 扩五档/在线/停用；A-11 扩成员四色/照片形态）。
///
/// 设计口径（设计 12 + 设计 14 §1）：
/// - 五档直径 20 / 28 / 32 / 40 / 56，首字号 9 / 11 / 12 / 14 / 18，首字号不随动态字体放大；
/// - 成员四色 `tone`：底 = `WDMemberTone.fill`、首字/图标 = `WDMemberTone.ink`；
///   不传 = 回落 `surface.tint`（与 A-11 之前的观感逐像素一致）；
/// - 照片形态：Circle 裁切 + 2pt 描边（`size.avatar.ring`），描边色 = 宿主底色；
/// - 在线点 10x10、2pt 描边；离线不显示灰点；已停用整体 50% 并去饱和。
///
/// `fill` / `ink` 已随外观解析（生成物里是 `Color(wdLight:dark:)`），
/// 组件侧**不再分辨明暗** —— 深色端四档是另一组值，由令牌层负责。
///
/// **仍未表达**（已登记）：在线状态并入读屏（L-B 零文案，需调用方提供措辞）。
public struct WDAvatar: View {
  private let value: WDAvatarValue
  private let size: WDAvatarSize
  private let isOnline: Bool
  private let isDisabled: Bool
  private let tone: WDMemberTone?
  private let hostColor: Color?

  @Environment(\.wdColors) private var colors

  /// 构造（既有；默认 md 32 档，不带状态）。
  public init(value: WDAvatarValue) {
    self.init(value: value, size: .md)
  }

  /// 构造（B2 增量：五档 + 在线点 + 已停用；A-11 增量：成员四色 + 宿主底色）。
  ///
  /// - Parameters:
  ///   - tone: 成员四色档（`WDMemberTone.assign(memberID:)` 的结果）；`nil` = `surface.tint`。
  ///   - hostColor: 宿主底色 —— 照片描边与在线点描边都用它（设计 14 §1.4 / §1.5）。
  ///     `nil` = `surface.card-solid`（既有默认）；放在画布上时传 `bg.canvas`，
  ///     否则描边比宿主更亮，会像"底下一圈白边"。
  public init(
    value: WDAvatarValue,
    size: WDAvatarSize,
    isOnline: Bool = false,
    isDisabled: Bool = false,
    tone: WDMemberTone? = nil,
    hostColor: Color? = nil
  ) {
    self.value = value
    self.size = size
    self.isOnline = isOnline
    self.isDisabled = isDisabled
    self.tone = tone
    self.hostColor = hostColor
  }

  /// 圆形底 + 首字/图标/照片 + 可选在线点。
  public var body: some View {
    ZStack {
      backdrop
      content
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .overlay(alignment: .bottomTrailing) {
      if isOnline {
        onlineDot
      }
    }
    .opacity(isDisabled ? WDAvatarMetrics.disabledOpacity : 1)
    .saturation(isDisabled ? 0 : 1)
    .animation(photoFade, value: showsPhoto)
    .modifier(WDAvatarAccessibility(value: value))
  }

  /// 底色圆：照片形态**不铺底色**（照片自己铺满；加载中既然不占位，也就没有"底色圆先露出来"的中间帧）。
  @ViewBuilder private var backdrop: some View {
    if !showsPhoto {
      Circle().fill(backgroundColor)
    }
  }

  /// 按回退链画内容（照片 → 文字 → 图标）。
  @ViewBuilder private var content: some View {
    switch value.resolved {
    case .photo(let photo):
      photoLayer(photo)
    case .label(let label):
      label
        .font(initialsFont)
        .foregroundStyle(foregroundColor)
        .lineLimit(1)
    case .icon(let icon):
      WDIcon(icon: icon, size: iconSize)
        .foregroundStyle(foregroundColor)
    case .empty:
      EmptyView()
    }
  }

  /// 照片：铺满圆形 + 2pt 宿主底色描边（描边画在裁切之前，所以与圆边严格同心）。
  private func photoLayer(_ photo: WDAvatarImage) -> some View {
    photo.image
      .resizable()
      .scaledToFill()
      .frame(width: diameter, height: diameter)
      .overlay(
        Circle().strokeBorder(ringColor, lineWidth: WDAvatarMetrics.photoRingWidth)
      )
  }

  /// 在线状态点（status.success + 2pt 宿主底色描边；设计 12 §4 / 设计 14 §1.5）。
  private var onlineDot: some View {
    Circle()
      .fill(colors.statusSuccess)
      .overlay(
        Circle().strokeBorder(ringColor, lineWidth: WDAvatarMetrics.onlineBorderWidth)
      )
      .frame(width: onlineDotSize, height: onlineDotSize)
      .accessibilityHidden(true)
  }

  /// 照片淡入（160ms = `motion.duration.fast`）：**只淡入、不缩放**（设计 12 §9 / 设计 14 §1.4）。
  /// 减弱动态下保留淡变：设计只禁位移与缩放，淡变本身不产生前庭刺激。
  private var photoFade: Animation? {
    .easeOut(duration: WDAvatarMetrics.photoFadeDuration)
  }

  /// 是否正在显示照片（回退链第一档）；照片出现/消失的动画由它驱动。
  private var showsPhoto: Bool {
    if case .photo = value.resolved { return true }
    return false
  }

  /// 底色：有 tone 走成员四色，否则回落既有 `surface.tint`（逐像素不变）。
  private var backgroundColor: Color {
    tone?.fill ?? colors.surfaceTint
  }

  /// 首字/图标色：有 tone 走该档 `ink`，否则回落既有 `text.on-soft`。
  private var foregroundColor: Color {
    tone?.ink ?? colors.textOnSoft
  }

  /// 描边色 = 宿主底色（照片描边与在线点描边共用；设计 14 §1.4 / §1.5）。
  private var ringColor: Color {
    hostColor ?? colors.surfaceCardSolid
  }

  /// 在线点边长 10（设计 12 §4）。
  private var onlineDotSize: CGFloat { WDAvatarMetrics.onlineDotSize }

  /// 直径（设计 12 §3；R9 禁 frame 绑令牌，故先落变量）。
  private var diameter: CGFloat {
    WDAvatarMetrics.diameter(size)
  }

  /// 首字号（设计 12 §3，锁定不随动态字体放大）。
  private var initialsFont: Font {
    .system(size: WDAvatarMetrics.initialsSize(size))  // wd-structure-check:disable R11 — 设计字号
  }

  /// 图标档位：xs/sm → 16，md → 20，lg/xl → 24（设计未给图标档，按直径近似）。
  private var iconSize: WDIconSize {
    switch size {
    case .xs, .sm: return .sm
    case .md: return .md
    case .lg, .xl: return .lg
    }
  }
}

/// 无障碍：照片形态读 `accessibilityLabel`（没给 = 装饰性，不进树）；
/// 文字形态读调用方给的文本；图标形态是占位（装饰，不进树）。
private struct WDAvatarAccessibility: ViewModifier {
  let value: WDAvatarValue

  @ViewBuilder func body(content: Content) -> some View {
    switch value.resolved {
    case .photo(let photo):
      if let label = photo.accessibilityLabel {
        content
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(label)
      } else {
        content.accessibilityHidden(true)
      }
    case .label(let label):
      content
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    case .icon, .empty:
      content.accessibilityHidden(true)
    }
  }
}
