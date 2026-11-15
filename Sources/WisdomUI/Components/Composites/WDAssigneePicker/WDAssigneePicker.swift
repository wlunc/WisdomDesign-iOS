import SwiftUI

/// 头像横排尺寸档（设计 37 §4：标准 40 / 紧凑 32 且不显示名字）。
public enum WDAssigneePickerSize: String, CaseIterable, Sendable, Equatable {
  /// 头像 40 + 名字 + 选中外环外径 52（设计 37 §3）。
  case standard
  /// 头像 32、不显示名字、外环外径 44（设计 37 §4「紧凑」）。
  case compact
}

/// 指派候选人的一项（设计 37；值数组 `items`）。
public struct WDAssigneePickerItem: Identifiable, Sendable, Equatable {
  /// 稳定身份。
  public let id: String
  /// 头像值（与 `WDAvatar` 共用形态；直径由组件按档位给）。
  public let avatar: WDAvatarValue
  /// 读屏名（设计 37 §10 的「妈妈…」；L-B 零文案，由调用方给）。
  public let accessibilityLabel: Text
  /// 可见名字（设计 37 §7：可选、`type.caption1`、≤ 4 个汉字）；nil = 只显示头像。
  public let name: Text?
  /// 是否可选（设计 37 §5：已离开家庭的成员 = false，40% 去饱和、仍可见）。
  public let isEnabled: Bool
  /// 不可选原因（设计 37 §10 的「已离开」；只作读屏 hint，nil = 无）。
  public let unavailableReason: Text?

  /// 构造：身份 + 头像 + 读屏名 + 可见名字 + 可选性 + 原因。
  public init(
    id: String,
    avatar: WDAvatarValue,
    accessibilityLabel: Text,
    name: Text? = nil,
    isEnabled: Bool = true,
    unavailableReason: Text? = nil
  ) {
    self.id = id
    self.avatar = avatar
    self.accessibilityLabel = accessibilityLabel
    self.name = name
    self.isEnabled = isEnabled
    self.unavailableReason = unavailableReason
  }
}

/// 「未指派」虚拟项（设计 37 §2/§4：首位固定、虚线圈 + `user-x`；点它清空选择）。
public struct WDAssigneePickerUnassigned: Sendable, Equatable {
  /// 可见名字（如「未指派」；紧凑档不显示）。
  public let label: Text
  /// 读屏名（必填）。
  public let accessibilityLabel: Text

  /// 构造：可见名字 + 读屏名。
  public init(label: Text, accessibilityLabel: Text) {
    self.label = label
    self.accessibilityLabel = accessibilityLabel
  }
}

/// 指派选择（SPEC §2.10-#37；M6）。
///
/// 设计口径（设计 37）：
/// - 头像 **40**（紧凑 32）、横向间距 `space.4` 12、选中外环 **2pt 品牌色 + 4 间隙（外径 52）**；
/// - 名字可选（`type.caption1`、≤ 4 汉字、超出截断）、与头像间距 `space.2` 4；
/// - 最多直接显示 **6** 个（含「未指派」），超出显示 `+n`；
/// - 单选默认（点已选项不取消）/ 多选（参与人）/ 带未指派 / 紧凑 四类变体；
/// - 选中：头像弹到 1.05 后回弹到 1.0（200ms `spring.bouncy`）+ 品牌环（160ms 淡入）；按下 0.94；
/// - 已离开成员 40% 去饱和、仍可见不可选；横向滚动、初始滚到选中项。
///
/// 冻结签名与差异见 `docs/M6-SIGNATURE-FREEZE.md`（D1–D9）。
public struct WDAssigneePicker: View {
  /// 受控值的两种形态：单选（`String?`，nil = 未指派）与多选（`Set<String>`）。
  private enum SelectionMode {
    case single(Binding<String?>)
    case multiple(Binding<Set<String>>)
  }

  private let mode: SelectionMode
  private let label: Text
  private let items: [WDAssigneePickerItem]
  private let unassigned: WDAssigneePickerUnassigned?
  private let size: WDAssigneePickerSize
  private let positionText: ((Int, Int) -> Text)?
  private let onOverflowTap: (() -> Void)?
  private let overflowAccessibilityLabel: Text?

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.wdAppearance) private var appearance
  @Environment(\.wdEffectsBudget) private var budget

  @State private var bouncingID: String?

  /// 单选（默认）：`nil` = 未指派/未选；点已选项**不取消**（设计 37 §12）。
  public init(
    selection: Binding<String?>,
    label: Text,
    items: [WDAssigneePickerItem],
    unassigned: WDAssigneePickerUnassigned? = nil,
    size: WDAssigneePickerSize = .standard,
    positionText: ((Int, Int) -> Text)? = nil,
    onOverflowTap: (() -> Void)? = nil,
    overflowAccessibilityLabel: Text? = nil
  ) {
    self.mode = .single(selection)
    self.label = label
    self.items = items
    self.unassigned = unassigned
    self.size = size
    self.positionText = positionText
    self.onOverflowTap = onOverflowTap
    self.overflowAccessibilityLabel = overflowAccessibilityLabel
  }

  /// 多选（设计 37 §4「参与人」）：点已选项 = 取消该项；无「未指派」项。
  public init(
    selection: Binding<Set<String>>,
    label: Text,
    items: [WDAssigneePickerItem],
    size: WDAssigneePickerSize = .standard,
    positionText: ((Int, Int) -> Text)? = nil,
    onOverflowTap: (() -> Void)? = nil,
    overflowAccessibilityLabel: Text? = nil
  ) {
    self.mode = .multiple(selection)
    self.label = label
    self.items = items
    self.unassigned = nil
    self.size = size
    self.positionText = positionText
    self.onOverflowTap = onOverflowTap
    self.overflowAccessibilityLabel = overflowAccessibilityLabel
  }

  /// 组标签 + 横排头像；整组一个容器（组标签由 `label` 提供）。
  public var body: some View {
    ScrollViewReader { proxy in
      VStack(alignment: .leading, spacing: WDSpacing.s3) {
        label
          .wdFont(WDType.footnote)
          .wdLineBox(WDType.footnote)
          .foregroundStyle(colors.textSecondary)
          .accessibilityHidden(true)
        ScrollView(.horizontal) {
          HStack(alignment: .top, spacing: WDSpacing.s4) {
            if let unassigned {
              unassignedView(unassigned)
                .id(Self.unassignedID)
            }
            ForEach(Array(visibleMembers.enumerated()), id: \.element.id) { _, item in
              memberView(item)
                .id(item.id)
            }
            if hiddenCount > 0 {
              overflowView
            }
          }
        }
        .scrollIndicators(.hidden)
      }
      .opacity(isEnabled ? 1 : disabledOpacity)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(label)
      .onAppear {
        scrollToSelection(proxy)
      }
      .task(id: bouncingID) {
        await resetBounce()
      }
    }
  }

  // MARK: - 头像项

  private func memberView(_ item: WDAssigneePickerItem) -> some View {
    let index = (items.firstIndex(where: { $0.id == item.id }) ?? 0) + unassignedOffset + 1
    let selected = isSelected(item.id)
    return Button {
      select(item)
    } label: {
      slot(
        selected: selected,
        title: size == .standard ? item.name : nil,
        avatar: item.avatar,
        unassigned: false,
        itemEnabled: item.isEnabled,
        bounce: bouncingID == item.id
      )
    }
    .buttonStyle(WDAssigneePickerItemStyle())
    .disabled(!isEnabled || !item.isEnabled)
    .accessibilityLabel(item.accessibilityLabel)
    .accessibilityValue(positionValue(index))
    .accessibilityHint(unavailableHint(item))
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func unassignedView(_ unassigned: WDAssigneePickerUnassigned) -> some View {
    let selected = isUnassignedSelected
    return Button {
      selectUnassigned()
    } label: {
      slot(
        selected: selected,
        title: size == .standard ? unassigned.label : nil,
        avatar: nil,
        unassigned: true,
        itemEnabled: true,
        bounce: bouncingID == Self.unassignedID
      )
    }
    .buttonStyle(WDAssigneePickerItemStyle())
    .disabled(!isEnabled)
    .accessibilityLabel(unassigned.accessibilityLabel)
    .accessibilityValue(positionValue(1))
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  @ViewBuilder private var overflowView: some View {
    let content = ZStack {
      Circle()
        .fill(colors.surfaceGlassStrong)
      Text(verbatim: "+\(hiddenCount)")
        .wdFont(WDType.caption1)
        .wdLineBox(WDType.caption1)
        .foregroundStyle(colors.textSecondary)
    }
    .frame(width: avatarDiameter, height: avatarDiameter)
    .frame(minWidth: WDSize.touchTargetMin, minHeight: WDSize.touchTargetMin)
    .contentShape(Rectangle())
    .accessibilityLabel(overflowAccessibilityLabel ?? Text(verbatim: "+\(hiddenCount)"))

    if let onOverflowTap {
      Button(action: onOverflowTap) { content }
        .buttonStyle(WDAssigneePickerItemStyle())
        .disabled(!isEnabled)
    } else {
      content
    }
  }

  /// 头像槽：52 选择圈 + 头像（或未指派虚线圈）+ 可选名字。
  @ViewBuilder private func slot(
    selected: Bool,
    title: Text?,
    avatar: WDAvatarValue?,
    unassigned: Bool,
    itemEnabled: Bool,
    bounce: Bool
  ) -> some View {
    VStack(spacing: WDSpacing.s2) {
      pickCircle(selected: selected, avatar: avatar, unassigned: unassigned, bounce: bounce)

      if let title {
        title
          .wdFont(WDType.caption1)
          .wdLineBox(WDType.caption1)
          .lineLimit(1)
          .fontWeight(selected ? .semibold : .regular)
          .foregroundStyle(selected ? colors.textBrand : colors.textSecondary)
          .frame(width: outerDiameter)
      }
    }
    .frame(minWidth: WDSize.touchTargetMin, alignment: .center)
    .opacity(itemEnabled ? 1 : disabledOpacity)
    .saturation(itemEnabled ? 1 : 0)
    .contentShape(Rectangle())
  }

  /// 选择圈 = 52 槽（紧凑 44）：选中 = 2pt 品牌描边；未指派未选 = 1.5pt 虚线。
  /// 头像静止为 1.0（与圈留 4 间隙）；「缩放 1.05 后回弹」只做一次性 bounce，不改变静止尺寸。
  @ViewBuilder private func pickCircle(
    selected: Bool,
    avatar: WDAvatarValue?,
    unassigned: Bool,
    bounce: Bool
  ) -> some View {
    ZStack {
      if selected {
        Circle()
          .strokeBorder(colors.textBrand, lineWidth: Self.ringWidth)
          .transition(.opacity)
      } else if unassigned {
        Circle()
          .strokeBorder(
            colors.borderHairlineStrong,
            style: StrokeStyle(lineWidth: Self.dashedWidth, dash: Self.dashedPattern)
          )
      }
      if let avatar {
        WDAvatar(value: avatar, size: isCompact ? .md : .lg)
          .scaleEffect(bounce ? Self.selectedScale : 1)
      } else if unassigned {
        WDIcon(icon: .unassigned, size: .md)
          .foregroundStyle(selected ? colors.textBrand : colors.textTertiary)
          .scaleEffect(bounce ? Self.selectedScale : 1)
      }
    }
    .frame(width: outerDiameter, height: outerDiameter)
    .animation(selectionAnimation, value: selected)
    .animation(selectionAnimation, value: bounce)
  }

  // MARK: - 行为

  private func select(_ item: WDAssigneePickerItem) {
    guard isEnabled, item.isEnabled else { return }
    switch mode {
    case .single(let binding):
      guard binding.wrappedValue != item.id else { return }
      binding.wrappedValue = item.id
    case .multiple(let binding):
      var selection = binding.wrappedValue
      if selection.contains(item.id) {
        selection.remove(item.id)
      } else {
        selection.insert(item.id)
      }
      binding.wrappedValue = selection
    }
    WDHaptics.shared.play(.toggle, budget: budget)
    bouncingID = item.id
  }

  private func selectUnassigned() {
    guard isEnabled, case .single(let binding) = mode else { return }
    guard binding.wrappedValue != nil else { return }
    binding.wrappedValue = nil
    WDHaptics.shared.play(.toggle, budget: budget)
    bouncingID = Self.unassignedID
  }

  /// 选中弹一下后回到 1.0（设计 37 §5/§9：200ms bouncy 后回弹，静止尺寸不变）。
  private func resetBounce() async {
    guard let id = bouncingID else { return }
    try? await Task.sleep(for: .seconds(Self.bounceReset))
    guard !Task.isCancelled, bouncingID == id else { return }
    bouncingID = nil
  }

  /// 初始渲染把当前选中项滚到可视区中间（设计 37 §6/§9）。
  private func scrollToSelection(_ proxy: ScrollViewProxy) {
    guard let target = scrollTarget else { return }
    DispatchQueue.main.async {
      if appearance.reduceMotion {
        proxy.scrollTo(target, anchor: .center)
      } else {
        withAnimation(WDMotion.Spring.gentle) {
          proxy.scrollTo(target, anchor: .center)
        }
      }
    }
  }

  // MARK: - 选择态

  private func isSelected(_ id: String) -> Bool {
    switch mode {
    case .single(let binding):
      return binding.wrappedValue == id
    case .multiple(let binding):
      return binding.wrappedValue.contains(id)
    }
  }

  private var isUnassignedSelected: Bool {
    guard case .single(let binding) = mode, unassigned != nil else { return false }
    return binding.wrappedValue == nil
  }

  /// 单选/多选的首个选中项（用于初始滚动；多选按 `items` 顺序取第一个）。
  private var primarySelectedID: String? {
    switch mode {
    case .single(let binding):
      return binding.wrappedValue
    case .multiple(let binding):
      let selection = binding.wrappedValue
      return items.first(where: { selection.contains($0.id) })?.id
    }
  }

  private var scrollTarget: String? {
    if let id = primarySelectedID {
      return visibleMembers.contains(where: { $0.id == id }) ? id : nil
    }
    return isUnassignedSelected ? Self.unassignedID : nil
  }

  // MARK: - 计算

  /// 可见成员：最多 `maxVisible` 个（含未指派）；选中项若在窗口外则替换进第 6 位（D9）。
  /// 可见成员（internal：供结构测试断言，不是公开 API）。
  var visibleMembers: [WDAssigneePickerItem] {
    let memberSlots = Self.maxVisible - unassignedOffset
    guard items.count > memberSlots else { return items }
    var visible = Array(items.prefix(memberSlots))
    if let id = primarySelectedID,
      !visible.contains(where: { $0.id == id }),
      let selected = items.first(where: { $0.id == id }),
      !visible.isEmpty
    {
      visible[visible.count - 1] = selected
    }
    return visible
  }

  /// 溢出人数 = 总人数（含未指派）− 直接显示数。
  /// 溢出人数（internal：供结构测试断言，不是公开 API）。
  var hiddenCount: Int {
    let shown = (unassigned == nil ? 0 : 1) + visibleMembers.count
    return max(0, items.count + unassignedOffset - shown)
  }

  private var unassignedOffset: Int {
    unassigned == nil ? 0 : 1
  }

  private var isCompact: Bool {
    size == .compact
  }

  /// 头像直径（internal：供结构测试断言，不是公开 API）。
  var avatarDiameter: CGFloat {
    isCompact ? WDSize.avatarMd : WDSize.avatarLg
  }

  /// 选中环外径（internal：供结构测试断言，不是公开 API）。
  var outerDiameter: CGFloat {
    avatarDiameter + ringInset * 2  // wd-structure-check:disable R7 — 外径 = 头像 + 2×(间隙+描边)
  }

  /// 选中环占用的外侧宽度（4 间隙 + 2 描边）。
  private var ringInset: CGFloat {
    Self.ringGap + Self.ringWidth
  }

  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / Self.percentScale
  }

  private var selectionAnimation: Animation? {
    appearance.reduceMotion ? nil : WDMotion.Spring.bouncy
  }

  /// 位置朗读值（internal：供结构测试断言，不是公开 API）。
  func positionValue(_ index: Int) -> Text {
    guard let positionText else {
      return Text(verbatim: "")  // wd-structure-check:disable R21 — a11y
    }
    return positionText(index, max(items.count + unassignedOffset, 1))
  }

  private func unavailableHint(_ item: WDAssigneePickerItem) -> Text {
    guard !item.isEnabled else {
      return Text(verbatim: "")  // wd-structure-check:disable R21 — a11y
    }
    return item.unavailableReason ?? Text(verbatim: "")  // wd-structure-check:disable R21 — a11y
  }

  // MARK: - 常量（设计 37）

  /// 最多直接显示 6 个（含「未指派」；设计 37 §3）。
  private static let maxVisible = 6  // wd-structure-check:disable R7 — 设计 37 §3 的显示上限
  /// 选中环描边 2pt（设计 37 §3）。
  private static let ringWidth: CGFloat = 2  // wd-structure-check:disable R7 — 设计 37 §3
  /// 头像与外环的间隙 4（设计 37 §3）。
  private static let ringGap: CGFloat = 4  // wd-structure-check:disable R7 — 设计 37 §3
  /// 选中缩放 1.05（设计 37 §5）。
  private static let selectedScale: CGFloat = 1.05  // wd-structure-check:disable R7 — 设计 37 §5
  /// 未指派虚线圈描边 1.5（设计 37 §2 的「虚线圈」）。
  private static let dashedWidth: CGFloat = 1.5  // wd-structure-check:disable R7 — 设计 37 §2
  /// 虚线圈的 dash 节奏（设计未给值；取 3/3 的最小可辨识节奏）。
  private static let dashedPattern: [CGFloat] = [3, 3]  // wd-structure-check:disable R7 — 设计未给值
  /// 百分数换算的分母。
  private static let percentScale: CGFloat = 100  // wd-structure-check:disable R7 — 百分数
  /// 选中回弹的复位延迟 200ms（设计 37 §5/§9）。
  private static let bounceReset: TimeInterval = 0.2  // wd-structure-check:disable R7 — 设计37
  /// 未指派项的滚动锚点 id。
  private static let unassignedID = "__wd_assigneePicker_unassigned__"
}

/// 按下缩放 0.94 / 100ms（设计 37 §5；按下态来源 = `ButtonStyleConfiguration`）。
private struct WDAssigneePickerItemStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.94 : 1)  // wd-structure-check:disable R7 — 设计 37 §5
      .animation(.easeOut(duration: WDMotion.Duration.instant), value: configuration.isPressed)
  }
}
