import SwiftUI

/// 骨架形态（设计 31 §4：文本 / 列表 / 卡片）。
public enum WDSkeletonVariant: String, CaseIterable, Sendable, Equatable {
  case text
  case list
  case card
}

/// 骨架占位（SPEC §2.10-#31；设计 31）。
///
/// 形状与真实内容一致；骨架内**不写任何文字**；微光 2200ms 循环，减弱动效或预算不足时静态。
/// 读屏标签由调用方给（L-B），整区只朗读一次；加载完成后的「内容已加载」由调用方处理。
public struct WDSkeleton: View {
  private let variant: WDSkeletonVariant
  private let lineCount: Int
  private let accessibilityLabel: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget
  @Environment(\.wdDensity) private var density

  /// 文本行宽度比例（设计 31 §3：70% / 45%）。
  private static let wideLine: CGFloat = 0.70  // wd-structure-check:disable R7 — 设计 31 §3
  private static let narrowLine: CGFloat = 0.45  // wd-structure-check:disable R7 — 设计 31 §3
  private static let textLineMax = 4  // wd-structure-check:disable R7 — 设计 31 §4 的文本行上限
  private static let listRowCount = 5  // wd-structure-check:disable R7 — 设计 31 §4 的列表行数
  private static let cardButtonWidth: CGFloat = 96  // wd-structure-check:disable R7 — 设计
  private static let shimmerDuration: TimeInterval = 2.2  // wd-structure-check:disable R7 — 设计

  @State private var shimmer = false

  /// 构造。
  public init(
    variant: WDSkeletonVariant = .text,
    lineCount: Int = 3,  // wd-structure-check:disable R7 — 设计 31 §3
    accessibilityLabel: Text? = nil
  ) {
    self.variant = variant
    self.lineCount = lineCount
    self.accessibilityLabel = accessibilityLabel
  }

  /// 渲染。
  public var body: some View {
    content
      .overlay { shimmerOverlay }
      .clipShape(RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous))
      .accessibilityElement(children: .ignore)
      .modifier(WDSkeletonAccessibility(label: accessibilityLabel))
      .onAppear { shimmer = shouldShimmer }
  }

  @ViewBuilder private var content: some View {
    switch variant {
    case .text:
      textBlock
    case .list:
      listBlock
    case .card:
      cardBlock
    }
  }

  private var shouldShimmer: Bool {
    !appearance.reduceMotion && budget.skeletonShimmers > 0
  }

  // MARK: - 文本

  private var textBlock: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      ForEach(0..<max(1, min(lineCount, Self.textLineMax)), id: \.self) { index in
        let even = index.isMultiple(of: 2)  // wd-structure-check:disable R7 — 设计
        skeletonLine(width: even ? Self.wideLine : Self.narrowLine)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - 列表

  private var listBlock: some View {
    VStack(spacing: 0) {
      ForEach(0..<Self.listRowCount, id: \.self) { index in
        HStack(spacing: WDSpacing.s4) {
          Circle()
            .fill(colors.surfaceTint)
            .frame(minWidth: WDSize.avatarMd, minHeight: WDSize.avatarMd)
          VStack(alignment: .leading, spacing: WDSpacing.s2) {
            skeletonLine(width: Self.wideLine)
            skeletonLine(width: Self.narrowLine)
          }
        }
        .padding(.horizontal, WDSpacing.s5)
        .frame(
          minHeight: density == .comfortable ? WDSize.rowHeightComfortable : WDSize.rowHeightCompact
        )
        .overlay(alignment: .bottom) {
          if index < Self.listRowCount - 1 {
            Rectangle()
              .fill(colors.borderHairline)
              .frame(height: 1)
              .padding(.leading, WDSpacing.s5 + WDSize.avatarMd + WDSpacing.s4)
          }
        }
      }
    }
  }

  // MARK: - 卡片

  private var cardBlock: some View {
    WDCard(style: .elevated) {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        skeletonLine(width: Self.narrowLine)
        skeletonLine(width: Self.wideLine)
        RoundedRectangle(cornerRadius: WDRadius.full, style: .continuous)
          .fill(colors.surfaceTint)
          .frame(width: Self.cardButtonWidth, height: WDSize.controlSm)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: - 灰块

  private func skeletonLine(width: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 6, style: .continuous)  // wd-structure-check:disable R7 — 设计
      .fill(colors.surfaceTint)
      .frame(height: 11)  // wd-structure-check:disable R7 — 设计 31 §3 的文本行高
      .containerRelativeFrame(.horizontal) { length, _ in length * width }
  }

  @ViewBuilder private var shimmerOverlay: some View {
    if shouldShimmer {
      LinearGradient(
        colors: [.clear, colors.surfaceCard.opacity(0.55), .clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .rotationEffect(.degrees(18))  // wd-structure-check:disable R7 — 设计 31 §9 的微光角度
      .offset(x: shimmer ? 280 : -280)  // wd-structure-check:disable R7 — 设计 31 §9 的微光扫过行程
      .animation(
        .linear(duration: Self.shimmerDuration).repeatForever(autoreverses: false),
        value: shimmer
      )
      .allowsHitTesting(false)
    }
  }
}

/// 骨架的无障碍：调用方给了标签就整区朗读一次；没给就当装饰。
private struct WDSkeletonAccessibility: ViewModifier {
  let label: Text?

  func body(content: Content) -> some View {
    if let label {
      content.accessibilityLabel(label)
    } else {
      content.accessibilityHidden(true)
    }
  }
}
