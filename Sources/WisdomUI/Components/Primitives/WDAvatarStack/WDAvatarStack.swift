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
/// 冻结签名无点击动作参数（设计 13 §8 的"点击展开"不可表达），差异登记在
/// `docs/M5-EXIT-REPORT.md`。
public struct WDAvatarStack: View {
  private let items: [WDAvatarStackItem]
  private let accessibilityLabel: Text
  private let size: WDAvatarStackSize

  @Environment(\.wdColors) private var colors

  /// 构造：项数组 + 整叠读屏标签 + 档位。
  public init(
    items: [WDAvatarStackItem],
    accessibilityLabel: Text,
    size: WDAvatarStackSize = .md
  ) {
    self.items = items
    self.accessibilityLabel = accessibilityLabel
    self.size = size
  }

  /// 最多 4 个头像 + 溢出计数；右压左。
  public var body: some View {
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

  // MARK: - 零件

  private var overflowView: some View {
    Text(verbatim: "+\(overflowCount)")
      .wdFont(WDType.caption1)
      .wdLineBox(WDType.caption1)
      .foregroundStyle(colors.textSecondary)
      .frame(width: diameter, height: diameter)
      .background(Circle().fill(colors.surfaceGlassStrong))
      .overlay(Circle().stroke(colors.surfaceCard, lineWidth: Self.borderWidth))
  }

  // MARK: - 计算

  private var visibleItems: [WDAvatarStackItem] {
    Array(items.prefix(Self.maxVisible))
  }

  private var overflowCount: Int {
    max(0, items.count - Self.maxVisible)
  }

  private var diameter: CGFloat {
    switch size {
    case .sm: return WDSize.avatarSm
    case .md: return WDSize.avatarMd
    }
  }

  private var overlap: CGFloat {
    diameter * Self.overlapRatio
  }

  /// 最多显示 4 个（设计 13 §3）。
  private static let maxVisible = 4  // wd-structure-check:disable R7 — 设计 13 §3 的显示上限
  /// 重叠量 = 直径的 30%（设计 13 §3）。
  private static let overlapRatio: CGFloat = 0.3  // wd-structure-check:disable R7 — 设计值
  /// 描边 2pt（设计 13 §3）。
  private static let borderWidth: CGFloat = 2  // wd-structure-check:disable R7 — 设计值
}
