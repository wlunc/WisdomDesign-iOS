import SwiftUI

/// 导航栏模式（设计 33 §3：内联 44 / 标准 56 / 大标题 96）。
public enum WDNavigationBarMode: String, CaseIterable, Sendable, Equatable {
  /// 内联（紧凑）44。
  case inline
  /// 标准 56。
  case standard
  /// 大标题 96（内联行 44 + 大标题区 52）。
  case largeTitle
}

/// 导航栏底色档（设计 33 §4：透明 / 玻璃）。
public enum WDNavigationBarStyle: String, CaseIterable, Sendable, Equatable {
  /// 透明底（内容未滚动）。
  case transparent
  /// 玻璃底（经 `WDGlass.resolve`）。
  case glass
}

/// 导航栏右侧动作（≤2 个；每个必须有读屏标签）。
public struct WDNavigationBarAction: Identifiable {
  /// 稳定身份。
  public let id: String
  /// 图标语义名。
  public let icon: WDIconName
  /// 读屏标签。
  public let accessibilityLabel: Text
  /// 动作。
  public let action: () -> Void

  /// 构造：身份 + 图标 + 标签 + 动作。
  public init(
    id: String,
    icon: WDIconName,
    accessibilityLabel: Text,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.icon = icon
    self.accessibilityLabel = accessibilityLabel
    self.action = action
  }
}

/// 导航栏（SPEC §2.10-#33；M5）。
///
/// 设计口径（设计 33）：
/// - 内联 44 / 标准 56 / 大标题 96；左右边距 16；图标按钮视觉 32、热区 44；
/// - 透明 / 玻璃两档；玻璃走 `WDGlass.resolve`（文字级别 primary）并计入效果配额；
/// - 返回按钮标签由调用方给（如「返回家庭列表」）；右侧 ≤2 个动作；
/// - 标题作为页面标题（header trait）被首个朗读。
///
/// Q6：滚动联动（透明→玻璃、大标题收缩）本轮不做，`style` 由调用方显式给；差异登记在
/// `docs/M5-EXIT-REPORT.md`。安全区由调用方安装（`.safeAreaInset`）。
public struct WDNavigationBar: View {
  private let title: Text
  private let mode: WDNavigationBarMode
  private let style: WDNavigationBarStyle
  private let backAccessibilityLabel: Text?
  private let onBack: (() -> Void)?
  private let actions: [WDNavigationBarAction]

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  /// 构造：标题 + 模式/底色 + 返回 + 右侧动作。
  public init(
    title: Text,
    mode: WDNavigationBarMode = .standard,
    style: WDNavigationBarStyle = .transparent,
    backAccessibilityLabel: Text? = nil,
    onBack: (() -> Void)? = nil,
    actions: [WDNavigationBarAction] = []
  ) {
    self.title = title
    self.mode = mode
    self.style = style
    self.backAccessibilityLabel = backAccessibilityLabel
    self.onBack = onBack
    self.actions = actions
  }

  /// 顶栏（+ 大标题行）。
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      topRow
      if mode == .largeTitle {
        largeTitleRow
      }
    }
    .background(barBackground)
    .overlay(alignment: .bottom) { bottomHairline }
    .accessibilityElement(children: .contain)
    .onAppear {
      assert(actions.count <= Self.maxActions, "WDNavigationBar 右侧最多 2 个动作（设计 33 §6）")
    }
  }

  // MARK: - 零件

  private var topRow: some View {
    ZStack {
      HStack(spacing: WDSpacing.s3) {
        if let backAccessibilityLabel {
          backButton(backAccessibilityLabel)
        }
        Spacer(minLength: 0)
        ForEach(actions) { action in
          actionButton(action)
        }
      }
      if mode != .largeTitle {
        title
          .wdFont(WDType.headline)
          .wdLineBox(WDType.headline)
          .foregroundStyle(colors.textPrimary)
          .lineLimit(1)
          .accessibilityAddTraits(.isHeader)
          .padding(.horizontal, Self.titleHorizontalInset)
      }
    }
    .padding(.horizontal, WDSpacing.s5)
    .frame(minHeight: topRowHeight)
  }

  private var largeTitleRow: some View {
    title
      .wdFont(WDType.largeTitle)
      .wdLineBox(WDType.largeTitle)
      .foregroundStyle(colors.textPrimary)
      .lineLimit(1)
      .accessibilityAddTraits(.isHeader)
      .padding(.horizontal, WDSpacing.s5)
      .frame(minHeight: Self.largeTitleRowHeight, alignment: .leading)
  }

  private func backButton(_ label: Text) -> some View {
    Button {
      onBack?()
    } label: {
      WDIcon(icon: .back, size: .md)
        .foregroundStyle(colors.textBrand)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private func actionButton(_ action: WDNavigationBarAction) -> some View {
    Button {
      action.action()
    } label: {
      WDIcon(icon: action.icon, size: .md)
        .foregroundStyle(colors.textBrand)
        .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(action.accessibilityLabel)
  }

  // MARK: - 视觉

  private var barBackground: Color {
    switch style {
    case .transparent:
      return .clear
    case .glass:
      switch WDGlass.resolve(
        textLevel: .primary,
        appearance: appearance,
        capabilities: WDGlassCapabilities(supportsGlass: Self.runtimeSupportsGlass()),
        budget: budget,
        level: .thick
      ) {
      case .glass: return colors.surfaceGlass
      case .glassStrong: return colors.surfaceGlassStrong
      case .opaque: return colors.surfaceCardSolid
      }
    }
  }

  @ViewBuilder private var bottomHairline: some View {
    if style == .glass {
      Rectangle()
        .fill(colors.borderHairline)
        .frame(height: 1)
    }
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  private var topRowHeight: CGFloat {
    switch mode {
    case .inline, .largeTitle: return WDSize.navbarCompact
    case .standard: return WDSize.navbarStandard
    }
  }

  /// 右侧动作上限 2（设计 33 §6）。
  private static let maxActions = 2  // wd-structure-check:disable R7 — 设计
  /// 大标题行高 52（设计 33 §3：96 = 44 + 52）。
  private static let largeTitleRowHeight: CGFloat = 52  // wd-structure-check:disable R7 — 设计值
  /// 标题水平留白，避免与返回/动作重叠（设计 33 §6）。
  private static let titleHorizontalInset: CGFloat = 48  // wd-structure-check:disable R7 — 设计
}
