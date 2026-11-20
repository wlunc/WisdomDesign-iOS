import SwiftUI

/// 头像堆叠尺寸档（设计 13 §3：sm 28 / md 32）。
public enum WDAvatarStackSize: String, CaseIterable, Sendable, Equatable {
  /// 28。
  case sm
  /// 32。
  case md
}

/// 头像堆叠的一项（设计 13；值数组 `items`）。
public struct WDAvatarStackItem: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 头像值（与 `WDAvatar` 共用形态）。
  public let avatar: WDAvatarValue

  /// 构造：身份 + 头像值。
  public init(id: String, avatar: WDAvatarValue) {
    self.id = id
    self.avatar = avatar
  }
}

/// 头像堆叠（SPEC §2.10-#13；M5）。
///
/// 设计口径（设计 13）：
/// - 头像档位 sm 28 / md 32；重叠量 = 直径的 **30%**（28→8，32→9）；描边 2pt；
/// - 最多显示 **4** 个，超出显示 `+n`（n = 总数 − 已显示数）；
/// - 右侧头像压在左侧之上（描边不被遮挡）；
/// - **整叠只读一次**（`accessibilityLabel` 必填，由调用方拼完整句；库内零文案）；
/// - 小于 2 人不使用堆叠（调用方判断；本组件对 0/1 项也保持稳定渲染）。
///
/// 交互（设计 13 §8「点击堆叠 / 点击 +n = 同一动作」）：
/// - 传 `onOverflowTap` ⇒ 整叠成为**一个真 `Button`**（不做自造手势），点击区域 = 整叠 bounds；
///   读屏仍只读一个元素，角色补 `.isButton`；`.disabled(true)` 时不可点（设计 13 §10 热区不变）；
/// - 不传（默认 `nil`）⇒ 与扩展前**逐像素一致**：仍是非交互容器，不改描边色、不加按下反馈，
///   否则会改变 M5 已封板的快照基线。
public struct WDAvatarStack: View {
  private let items: [WDAvatarStackItem]
  private let accessibilityLabel: Text
  private let size: WDAvatarStackSize
  private let onOverflowTap: (@MainActor @Sendable () -> Void)?

  @Environment(\.wdColors) private var colors

  /// 构造：项数组 + 整叠读屏标签 + 档位（设计 13 §3）。
  public init(
    items: [WDAvatarStackItem],
    accessibilityLabel: Text,
    size: WDAvatarStackSize = .md
  ) {
    self.init(items: items, accessibilityLabel: accessibilityLabel, size: size, onOverflowTap: nil)
  }

  /// 构造：项数组 + 整叠读屏标签 + 档位 + 整叠点击回调（设计 13 §8）。
  ///
  /// - Parameter onOverflowTap: 整叠点击（点堆叠与点 `+n` 为同一动作）。`nil` = 不可点（默认，视觉与扩展前一致）。
  public init(
    items: [WDAvatarStackItem],
    accessibilityLabel: Text,
    size: WDAvatarStackSize = .md,
    onOverflowTap: (@MainActor @Sendable () -> Void)? = nil
  ) {
    self.items = items
    self.accessibilityLabel = accessibilityLabel
    self.size = size
    self.onOverflowTap = onOverflowTap
  }

  /// 最多 4 个头像 + 溢出计数；右压左；可点时整叠包成一个 Button。
  public var body: some View {
    if WDAvatarStack.isInteractive(onOverflowTap) {
      Button(action: { onOverflowTap?() }) {
        stack
          .contentShape(Rectangle())
      }
      .buttonStyle(WDAvatarStackPressStyle())
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibilityLabel)
      .accessibilityAddTraits(.isButton)
    } else {
      stack
    }
  }

  // MARK: - 零件

  /// 纯视觉堆叠（设计 13 §2：右侧头像 zIndex 更高，描边不被遮挡）。
  private var stack: some View {
    HStack(spacing: -overlap) {
      ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
        WDAvatar(value: item.avatar, size: size == .sm ? .sm : .md)
          .overlay(Circle().stroke(colors.surfaceCard, lineWidth: Self.borderWidth))
          .zIndex(Double(index))
      }
      if overflowCount > 0 {
        overflowView
          .zIndex(Double(visibleItems.count))
      }
    }
    .frame(minHeight: WDSize.touchTargetMin)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
  }

  private var overflowView: some View {
    Text(verbatim: "+" + String(overflowCount))
      .wdFont(WDType.caption1)
      .wdLineBox(WDType.caption1)
      .foregroundStyle(colors.textSecondary)
      .frame(width: diameter, height: diameter)
      .background(Circle().fill(colors.surfaceGlassStrong))
      .overlay(Circle().stroke(colors.surfaceCard, lineWidth: Self.borderWidth))
  }

  // MARK: - 计算

  private var visibleItems: [WDAvatarStackItem] {
    WDAvatarStack.visibleItems(items)
  }

  private var overflowCount: Int {
    WDAvatarStack.overflowCount(items.count)
  }

  private var diameter: CGFloat {
    WDAvatarStack.diameter(size)
  }

  private var overlap: CGFloat {
    WDAvatarStack.overlap(diameter: diameter)
  }

  // MARK: - 纯逻辑（internal；单测入口，非公开面）

  /// 最多显示 4 个（设计 13 §3）。
  static let maxVisible = 4  // wd-structure-check:disable R7 — 设计 13 §3 的显示上限
  /// 重叠量 = 直径的 30%（设计 13 §3）。
  static let overlapRatio: CGFloat = 0.3  // wd-structure-check:disable R7 — 设计值
  /// 描边 2pt（设计 13 §3）。
  static let borderWidth: CGFloat = 2  // wd-structure-check:disable R7 — 设计值

  /// 是否整叠可点：只有注入回调时才成为 Button（`nil` = 保持扩展前的纯容器）。
  static func isInteractive(_ onOverflowTap: (@MainActor @Sendable () -> Void)?) -> Bool {
    onOverflowTap != nil
  }

  /// 实际渲染的头像（设计 13 §3：上限 4；超出部分由 `+n` 代表）。
  static func visibleItems(_ items: [WDAvatarStackItem]) -> [WDAvatarStackItem] {
    Array(items.prefix(maxVisible))
  }

  /// 显示的头像数（= `min(总数, 4)`）。
  static func visibleCount(_ total: Int) -> Int {
    min(max(0, total), maxVisible)
  }

  /// 溢出计数 n = 总数 − 已显示数（设计 13 §7；总数 ≤ 4 ⇒ 0，不显示 `+n`）。
  ///
  /// 纯函数：负总数按 0 处理（防御性），永远不返回负数。
  static func overflowCount(_ total: Int) -> Int {
    max(0, total - maxVisible)
  }

  /// 档位直径（设计 13 §3：sm 28 / md 32，取令牌）。
  static func diameter(_ size: WDAvatarStackSize) -> CGFloat {
    switch size {
    case .sm: return WDSize.avatarSm
    case .md: return WDSize.avatarMd
    }
  }

  /// 相邻头像的重叠量 = 直径 × 30%（设计 13 §3）。
  static func overlap(diameter: CGFloat) -> CGFloat {
    diameter * overlapRatio
  }

  /// 堆叠总宽（设计 13 §6：直径 + (可见项数 − 1) × (直径 − 重叠量)；0 项 = 0）。
  static func stackWidth(visibleCount: Int, diameter: CGFloat) -> CGFloat {
    guard visibleCount > 0 else { return 0 }
    return diameter + CGFloat(visibleCount - 1) * (diameter - overlap(diameter: diameter))
  }
}

/// 可点整叠的按下反馈：亮度 96%（= 黑色 4% 蒙层，与 `WDCard`/按下令牌同口径）+ 禁用 40%。
///
/// 只在 `onOverflowTap` 非 nil 的构造里出现 ⇒ 默认路径不受影响。
struct WDAvatarStackPressStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  /// 构造（无参数）。
  init() {}

  /// 按下蒙层不透明度：亮度 96% ⇒ 黑色 4%。
  var pressedDimOpacity: CGFloat {
    (Self.percentScale - WDState.pressedBrightness) / Self.percentScale
  }

  /// 禁用态整体 40%（`state.disabled.alpha`）。
  var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  /// 百分数换算分母。
  static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数分母

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .overlay {
        RoundedRectangle(cornerRadius: WDRadius.sm, style: .continuous)
          .fill(Color.black)
          .opacity(configuration.isPressed ? pressedDimOpacity : 0)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      .opacity(isEnabled ? 1 : disabledOpacity)
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
