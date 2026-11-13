import SwiftUI

/// 分段控件的一项（设计 21；值数组 `items`）。
public struct WDSegmentedControlItem: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 段文字。
  public let label: Text

  /// 构造：身份 + 文字。
  public init(id: String, label: Text) {
    self.id = id
    self.label = label
  }
}

/// 分段控件外观档（设计 21 §4：玻璃 / 实底）。
public enum WDSegmentedControlStyle: String, CaseIterable, Sendable, Equatable {
  /// `surface.glass` + hairline（经 `WDGlass.resolve` 降级）。
  case glass
  /// `fill.field`（页面内常规位置）。
  case solid
}

/// 分段控件（SPEC §2.10-#21；M5）。
///
/// 设计口径（设计 21）：
/// - 容器高 **38**（内容 32 + 上下内边距 3）、单段最小宽 **56**、段水平内距 14、字号 13（medium/选中 600）；
/// - 指示块 = 圆角胶囊、`surface.card-solid` + `elevation.1`，弹簧滑动（`motion.spring.snappy`）；
/// - 2–5 段等分，不按文字长度分配；点击已选项不重复回调；
/// - 玻璃档走 `WDGlass.resolve`（文字级别 secondary），计入效果配额；深色端自动降级为不透明。
///
/// 角色 `tablist`/`tab` 与"第 n 项，共 m 项"（SwiftUI 无对应 trait）差异登记在
/// `docs/M5-EXIT-REPORT.md`；段宽用 `.background` 里的 `GeometryReader` 量测（不包内容）。
public struct WDSegmentedControl: View {
  private let items: [WDSegmentedControlItem]
  @Binding private var selection: String
  private let style: WDSegmentedControlStyle

  @Environment(\.wdColors) private var colors
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  @State private var contentWidth: CGFloat = 0

  /// 构造：项数组 + 受控选中 id + 外观档。
  public init(
    items: [WDSegmentedControlItem],
    selection: Binding<String>,
    style: WDSegmentedControlStyle = .solid
  ) {
    self.items = items
    self._selection = selection
    self.style = style
  }

  /// 指示块 + 等分段落。
  public var body: some View {
    ZStack(alignment: .leading) {
      indicator
      segments
    }
    .padding(Self.containerPadding)
    .background(Capsule().fill(containerFill))
    .overlay(Capsule().stroke(containerStroke, lineWidth: 1))
    .accessibilityElement(children: .contain)
    .onAppear {
      assert(
        (Self.minSegments...Self.maxSegments).contains(items.count),
        "WDSegmentedControl 段数须为 2–5（设计 21 §4）"
      )
    }
  }

  // MARK: - 零件

  private var segments: some View {
    HStack(spacing: 0) {
      ForEach(items) { item in
        segment(item)
      }
    }
    .background(
      GeometryReader { proxy in
        Color.clear.preference(key: WDSegmentedWidthKey.self, value: proxy.size.width)
      }
    )
    .onPreferenceChange(WDSegmentedWidthKey.self) { contentWidth = $0 }
  }

  private func segment(_ item: WDSegmentedControlItem) -> some View {
    let isSelected = item.id == selection
    return Button {
      guard !isSelected else { return }
      selection = item.id
      WDHaptics.shared.play(.toggle, budget: budget)
    } label: {
      item.label
        .wdFont(WDType.footnote)
        .wdLineBox(WDType.footnote)
        .fontWeight(isSelected ? .semibold : .medium)
        .foregroundStyle(isSelected ? colors.textPrimary : colors.textSecondary)
        .frame(maxWidth: .infinity, minHeight: Self.contentHeight)
        .frame(minWidth: Self.minSegmentWidth)
        .contentShape(Rectangle())
    }
    .buttonStyle(WDSegmentedPressStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder private var indicator: some View {
    if items.count > 1 {
      Capsule()
        .fill(colors.surfaceCardSolid)
        .wdShadow(WDElevation.e1)
        .frame(width: segmentWidth, height: Self.contentHeight)
        .offset(x: CGFloat(selectedIndex) * segmentWidth)
        .animation(WDMotion.Spring.snappy, value: selection)
        .accessibilityHidden(true)
    }
  }

  // MARK: - 计算

  private var selectedIndex: Int {
    items.firstIndex { $0.id == selection } ?? 0
  }

  private var segmentWidth: CGFloat {
    guard !items.isEmpty else { return 0 }
    return contentWidth / CGFloat(items.count)
  }

  /// 容器底色：玻璃档走唯一入口；实底档 `fill.field`。
  private var containerFill: Color {
    switch style {
    case .solid:
      return colors.fillField
    case .glass:
      switch WDGlass.resolve(
        textLevel: .secondary,
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

  private var containerStroke: Color {
    switch style {
    case .solid: return .clear
    case .glass: return colors.borderHairline
    }
  }

  /// 运行时是否支持玻璃（iOS 26+；DF-10 默认执行项 = 17–25 纯色降级）。
  private static func runtimeSupportsGlass() -> Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  /// 段数下限 2（设计 21 §4）。
  private static let minSegments = 2  // wd-structure-check:disable R7 — 设计
  /// 段数上限 5（设计 21 §4）。
  private static let maxSegments = 5  // wd-structure-check:disable R7 — 设计
  /// 上下内边距 3（设计 21 §3）。
  private static let containerPadding: CGFloat = 3  // wd-structure-check:disable R7 — 设计值
  /// 内容高 32（设计 21 §3）。
  private static let contentHeight: CGFloat = 32  // wd-structure-check:disable R7 — 设计值
  /// 单段最小宽 56（设计 21 §3）。
  private static let minSegmentWidth: CGFloat = 56  // wd-structure-check:disable R7 — 设计值
}

/// 段宽量测（`.background` 里的 `GeometryReader`，不包内容）。
private struct WDSegmentedWidthKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

/// 按下时文字降到 70% 不透明度（设计 21 §5）。
private struct WDSegmentedPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.7 : 1)  // wd-structure-check:disable R7 — 设计值
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
