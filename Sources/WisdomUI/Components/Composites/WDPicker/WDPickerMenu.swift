import SwiftUI

/// 菜单分组（内部）：一段可带分组标题的选项（设计 22 §7）。
struct WDPickerMenuSection: Identifiable, Equatable {
  let id: Int
  let header: Text?
  let options: [WDPickerOption]
}

/// 菜单浮层的几何口径（设计 22 §3/§5/§6；内部暴露给单测）。
enum WDPickerMenuMetrics {
  /// 选项行高（设计 22 §3：44）。
  static let rowHeight = WDSize.controlMd
  /// 分组标题的上下内距（画廊 22 弹出层：8 / 2，合计 26 ≈ 16 行盒 + 10）。
  static let headerTop = WDSpacing.s3
  static let headerBottom = WDSpacing.s1
  /// 选项水平内距（设计 22 §3：14）。
  static let rowInset: CGFloat = 14  // wd-structure-check:disable R7 — 设计 22 §3
  /// 分组内选项额外缩进（设计 22 §7：space.5）。
  static let groupIndent = WDSpacing.s5
  /// 弹出层内距（设计 22 未给值；取画廊 22 弹出层的 6）。
  static let panelPadding: CGFloat = 6  // wd-structure-check:disable R7 — 画廊 22 弹出层
  /// 弹出层最小宽 / 屏幕左右留白（设计 22 §3：180 / 屏幕宽 − 32）。
  static let minWidth: CGFloat = 180  // wd-structure-check:disable R7 — 设计 22 §3
  static let screenMargin = WDSpacing.s5
  /// 与触发入口的间距（设计 22 §6：space.2 = 4）。
  static let gap = WDSpacing.s2
  /// 入场缩放起点（设计 22 §5：0.96 → 1）。
  static let enterScale: CGFloat = 0.96  // wd-structure-check:disable R7 — 设计 22 §5
  /// 选中行底色（设计 22 画廊 selected：brand 10%，行底 8 圆角）。
  static let selectedFillOpacity: CGFloat = 0.10  // wd-structure-check:disable R7 — 设计 22 画廊
  /// 菜单勾线宽（画廊 22 用 lucide 的 16pt 图标：24 viewBox / stroke 2 ⇒ 2 × 16/24）。
  static let checkStroke: CGFloat = 2 * (16.0 / 24.0)  // wd-structure-check:disable R7 — 画廊 22
}

/// 弹出层定位结果（内部；单测覆盖下方/翻转/夹取）。
struct WDPickerMenuPlacement: Equatable {
  let origin: CGPoint
  let size: CGSize
  let below: Bool

  /// 入场缩放的锚点：从触发入口那一侧长出来。
  var scaleAnchor: UnitPoint {
    below ? .top : .bottom
  }

  /// 计算浮层位置：优先下方；放不下且上方空间更大时翻转；与触发入口同侧对齐并夹在屏幕留白内。
  static func resolve(
    anchorRect: CGRect,
    naturalSize: CGSize,
    containerSize: CGSize,
    safeArea: EdgeInsets,
    isRTL: Bool = false
  ) -> WDPickerMenuPlacement {
    let sideMargins = WDPickerMenuMetrics.screenMargin * 2  // wd-structure-check:disable R7 — 左右两侧
    let maxWidth = max(0, containerSize.width - sideMargins)
    let width = min(max(naturalSize.width, WDPickerMenuMetrics.minWidth), maxWidth)
    let spaceBelow =
      containerSize.height - safeArea.bottom - WDPickerMenuMetrics.gap - anchorRect.maxY
    let spaceAbove = anchorRect.minY - safeArea.top - WDPickerMenuMetrics.gap
    let below = spaceBelow >= naturalSize.height || spaceBelow >= spaceAbove
    let available = max(0, below ? spaceBelow : spaceAbove)
    let height = min(naturalSize.height, available)
    let maxX = max(
      WDPickerMenuMetrics.screenMargin,
      containerSize.width - WDPickerMenuMetrics.screenMargin - width)
    let alignedX = isRTL ? anchorRect.maxX - width : anchorRect.minX
    let x = min(max(alignedX, WDPickerMenuMetrics.screenMargin), maxX)
    let rawY =
      below
      ? anchorRect.maxY + WDPickerMenuMetrics.gap
      : anchorRect.minY - WDPickerMenuMetrics.gap - height
    let minY = safeArea.top
    let maxY = max(minY, containerSize.height - safeArea.bottom - height)
    let y = min(max(rawY, minY), maxY)
    return WDPickerMenuPlacement(
      origin: CGPoint(x: x, y: y),
      size: CGSize(width: width, height: height),
      below: below
    )
  }
}

/// 菜单浮层（窗口级）：遮罩 + 弹出面板 + 定位/翻转 + 滚动到当前项。
struct WDPickerMenuLayer: View {
  let anchorRect: CGRect
  let containerSize: CGSize
  let safeArea: EdgeInsets
  let sections: [WDPickerMenuSection]
  let selection: String?
  let dismissChannel: WDPickerMenuDismissChannel
  let onSelect: (String) -> Void
  let onRequestDismiss: () -> Void

  @Environment(\.wdColors) private var colors
  @Environment(\.layoutDirection) private var layoutDirection
  @State private var naturalSize: CGSize = .zero
  @State private var appeared = false
  @State private var closing = false

  private var placement: WDPickerMenuPlacement {
    WDPickerMenuPlacement.resolve(
      anchorRect: anchorRect,
      naturalSize: naturalSize,
      containerSize: containerSize,
      safeArea: safeArea,
      isRTL: layoutDirection == .rightToLeft
    )
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      scrim
      if naturalSize == .zero {
        measuredContent
      } else {
        panel
      }
    }
    .frame(width: containerSize.width, height: containerSize.height, alignment: .topLeading)
    .ignoresSafeArea()
    .onAppear {
      WDA11yFocus.screenChanged()
      dismissChannel.handler = {
        dismiss()
      }
    }
    .onDisappear {
      dismissChannel.handler = nil
    }
  }

  // MARK: - 遮罩

  private var scrim: some View {
    Color.clear
      .contentShape(Rectangle())
      .onTapGesture {
        dismiss()
      }
      .accessibilityHidden(true)
  }

  // MARK: - 面板

  private var panel: some View {
    let layout = placement
    return ScrollViewReader { proxy in
      ScrollView {
        WDPickerOptionList(sections: sections, selection: selection) { id in
          onSelect(id)
          dismiss()
        }
        .padding(WDPickerMenuMetrics.panelPadding)
      }
      .scrollIndicators(.hidden)
      .frame(width: layout.size.width, height: layout.size.height)
      .background(colors.surfaceCardSolid)
      .clipShape(RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: WDRadius.md, style: .continuous)
          .stroke(colors.borderHairline, lineWidth: 1)
      )
      .wdShadow(WDElevation.e2)
      .accessibilityAddTraits(.isModal)
      .accessibilityAction(.escape) {
        dismiss()
      }
      .scaleEffect(
        appeared ? 1 : WDPickerMenuMetrics.enterScale,
        anchor: layout.scaleAnchor
      )
      .opacity(appeared ? 1 : 0)
      .offset(x: layout.origin.x, y: layout.origin.y)
      .onAppear {
        scrollToSelection(proxy)
      }
    }
  }

  /// 自然尺寸测量（不入布局、不可点、不可读）：宽度由内容决定，再做 180–屏宽夹取。
  private var measuredContent: some View {
    WDPickerOptionList(sections: sections, selection: selection) { _ in }
      .padding(WDPickerMenuMetrics.panelPadding)
      .fixedSize()
      .background(
        GeometryReader { proxy in
          Color.clear
            .onAppear {
              measure(proxy.size)
            }
            .onChange(of: proxy.size) { _, size in
              measure(size)
            }
        }
      )
      .frame(width: 0, height: 0, alignment: .topLeading)
      .hidden()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  /// 记录自然尺寸并开始入场动画。
  private func measure(_ size: CGSize) {
    guard size != .zero, size != naturalSize else {
      return
    }
    naturalSize = size
    reveal()
  }

  // MARK: - 行为

  /// 展开后把当前项滚到可视区中间（设计 22 §8）。
  private func scrollToSelection(_ proxy: ScrollViewProxy) {
    guard let target = selection ?? sections.first?.options.first?.id else {
      return
    }
    DispatchQueue.main.async {
      proxy.scrollTo(target, anchor: .center)
    }
  }

  private func reveal() {
    guard !appeared else {
      return
    }
    DispatchQueue.main.async {
      withAnimation(WDMotion.Spring.gentle) {
        appeared = true
      }
    }
  }

  private func dismiss() {
    guard !closing else {
      return
    }
    closing = true
    guard appeared else {
      onRequestDismiss()
      return
    }
    withAnimation(.easeOut(duration: WDMotion.Duration.fast)) {
      appeared = false
    } completion: {
      onRequestDismiss()
    }
  }
}

/// 选项列表（弹出层与内联共用；分组标题 + 44 行 + 左侧勾）。
struct WDPickerOptionList: View {
  let sections: [WDPickerMenuSection]
  let selection: String?
  let onSelect: (String) -> Void

  @Environment(\.wdColors) private var colors

  var body: some View {
    VStack(spacing: 0) {
      ForEach(sections) { section in
        if let header = section.header {
          headerRow(header)
        }
        ForEach(section.options) { option in
          WDPickerOptionRow(
            option: option,
            isSelected: option.id == selection,
            indented: section.header != nil
          ) {
            onSelect($0)
          }
        }
      }
    }
  }

  private func headerRow(_ header: Text) -> some View {
    header
      .wdFont(WDType.overline)
      .wdLineBox(WDType.overline)
      .foregroundStyle(colors.textTertiary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, WDPickerMenuMetrics.rowInset)
      .padding(.trailing, WDPickerMenuMetrics.rowInset)
      .padding(.top, WDPickerMenuMetrics.headerTop)
      .padding(.bottom, WDPickerMenuMetrics.headerBottom)
      .accessibilityAddTraits(.isHeader)
  }
}

/// 单个选项行（44 高；左侧勾位固定占位，选中项打勾）。
struct WDPickerOptionRow: View {
  let option: WDPickerOption
  let isSelected: Bool
  let indented: Bool
  let onSelect: (String) -> Void

  @Environment(\.wdColors) private var colors

  var body: some View {
    Button {
      onSelect(option.id)
    } label: {
      HStack(spacing: WDSpacing.s3) {
        checkSlot
        option.label
          .wdFont(WDType.subheadline)
          .wdLineBox(WDType.subheadline)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundStyle(isSelected ? colors.textBrand : colors.textPrimary)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.leading, leadingInset)
      .padding(.trailing, WDPickerMenuMetrics.rowInset)
      .frame(minHeight: WDPickerMenuMetrics.rowHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(WDPickerOptionRowStyle(isSelected: isSelected))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var leadingInset: CGFloat {
    WDPickerMenuMetrics.rowInset + (indented ? WDPickerMenuMetrics.groupIndent : 0)
  }

  private var checkSlot: some View {
    let slot = WDSize.iconSm
    return ZStack {
      if isSelected {
        WDPickerCheckmark()
          .stroke(
            colors.textBrand,
            style: StrokeStyle(
              lineWidth: WDPickerMenuMetrics.checkStroke, lineCap: .round, lineJoin: .round)
          )
          .frame(width: slot, height: slot)
          .transition(.opacity)
      }
    }
    .frame(width: slot, height: slot)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: isSelected)
  }
}

/// 选项行的选中底色与按下反馈（设计 22 画廊：选中行 = brand 10% 底 + 8 圆角，字重 600）。
private struct WDPickerOptionRowStyle: ButtonStyle {
  let isSelected: Bool

  @Environment(\.wdColors) private var colors

  func makeBody(configuration: Configuration) -> some View {
    let shape = RoundedRectangle(cornerRadius: WDRadius.xs, style: .continuous)
    return configuration.label
      .background(shape.fill(fill(pressed: configuration.isPressed)))
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }

  private func fill(pressed: Bool) -> Color {
    if pressed {
      return colors.fillPressed
    }
    return isSelected
      ? colors.textBrand.opacity(WDPickerMenuMetrics.selectedFillOpacity)
      : Color.clear
  }
}
