// Sources/WisdomUI/APISurface/WDAPISurface.swift
//
// I-M0-d · M0-11 签名冒烟（SPEC §1.2.2）
//
// 作用：把"当前尚未实现"的公开签名放进**真实编译图**，让签名级错误在 M0 就是编译错误——
// 触发方式是 PR-1 的**同一次** `build-for-testing`：
//     xcodebuild build-for-testing … SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'
// 本地/GUI/release 不带该标志（与 `WD_PREVIEWS` 同类纪律）。
//
// 三条纪律：
//   ① 整文件由 `#if WD_API_SMOKE` 包裹：不开标志时**零内容**；
//   ② 只放签名，函数体一律 `fatalError()`；
//   ③ **不得重复声明 M0 已存在的类型**——否则一开标志就是"重复声明"编译错误（IOS-01 blocker）。
//
// 显式排除清单（**禁止**在此重声明；SPEC §1.2.2 表）：
//   · `Sources/WisdomUI/Foundation/WDTokenTypes.swift`：
//     `WDTextStyle` / `WDShadowLayer` / `WDGradientSpec` / `View.wdShadow(_:)`；
//   · `Sources/WisdomUI/Foundation/Generated/WDTokens.swift` 的**全部**类型：
//     `WDColor` / `WDGradient` / `WDSpacing` / `WDRadius` / `WDSize` / `WDType` / `WDElevation` / `WDMotion`
//     及其成员（含 `WDMotion.Duration`、`WDMotion.Spring`）。
//
// 退役规则（SPEC §1.2.2）：某条真实声明落地时，**在同一 PR 里删除本文件对应段落**，并确认
// `WD_API_SMOKE` 仍编译通过；M3 起可切换为"对真实模块跑公共面快照对比"后整体删除。
//
// ⚠️ 与 I-M0-h 的接口（必须同 PR 处理）：`Generated/WDIconName.swift` 落地时，本文件末尾
// `smoke 专用最小替身` 段的 `WDIconName` 必须同 PR 删除，否则重复声明。

#if WD_API_SMOKE

  import SwiftUI

  // MARK: - ① 组件公开面（SPEC §2.2–§2.4）

  /// 按钮外观档位（SPEC §2.2）。
  public enum WDButtonVariant: String, CaseIterable, Sendable, Equatable {
    case filled, tonal, glass, outline, plain, destructive
  }

  /// 按钮尺寸档位（SPEC §2.2）。
  public enum WDButtonSize: String, CaseIterable, Sendable, Equatable {
    case sm, md, lg
  }

  /// 主按钮（SPEC §2.2；M2 首件）。
  public struct WDButton<Label: View>: View {
    /// 8 参构造（S2 上限；`label` 为 `@ViewBuilder`）。
    public init(
      variant: WDButtonVariant = .filled,
      size: WDButtonSize = .md,
      isLoading: Bool = false,
      loadingAccessibilityText: Text? = nil,
      leadingIcon: WDIconName? = nil,
      trailingIcon: WDIconName? = nil,
      action: @escaping () -> Void,
      @ViewBuilder label: () -> Label
    ) {
      fatalError()
    }

    /// M2 落地时必须是**真 `Button`**（pressed 唯一来源）；此处只锁签名。
    public var body: some View {
      fatalError()
    }
  }

  extension WDButton where Label == Text {
    /// 文案便利构造。
    public init(
      _ text: LocalizedStringKey,
      variant: WDButtonVariant = .filled,
      size: WDButtonSize = .md,
      isLoading: Bool = false,
      loadingAccessibilityText: Text? = nil,
      leadingIcon: WDIconName? = nil,
      trailingIcon: WDIconName? = nil,
      action: @escaping () -> Void
    ) {
      fatalError()
    }

    /// 字面量便利构造（参数集合同上一条构造）。
    public init(
      verbatim text: String,
      variant: WDButtonVariant = .filled,
      size: WDButtonSize = .md,
      isLoading: Bool = false,
      loadingAccessibilityText: Text? = nil,
      leadingIcon: WDIconName? = nil,
      trailingIcon: WDIconName? = nil,
      action: @escaping () -> Void
    ) {
      fatalError()
    }
  }

  /// 按钮 chrome 的 `ButtonStyle`（SPEC §2.2）。
  public struct WDButtonStyle: ButtonStyle {
    /// 构造（档位 + 加载态）。
    public init(
      variant: WDButtonVariant = .filled, size: WDButtonSize = .md, isLoading: Bool = false
    ) {
      fatalError()
    }

    /// chrome 渲染：M2 转交内部件 `_WDButtonChrome`（读 `@Environment(\.isEnabled)`）。
    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
      fatalError()
    }
  }

  extension ButtonStyle where Self == WDButtonStyle {
    /// 填充档工厂（R13b 允许：协议扩展里的计算型工厂）。
    public static var wdFilled: WDButtonStyle {
      fatalError()
    }

    /// 指定档位的工厂。
    public static func wd(_ variant: WDButtonVariant, size: WDButtonSize = .md) -> WDButtonStyle {
      fatalError()
    }
  }

  /// 字段外观档位（SPEC §2.3）。
  public enum WDTextFieldVariant: String, CaseIterable, Sendable, Equatable {
    case inset, outline, glass
  }

  /// 字段前缀槽（SPEC §2.3）。
  public enum WDTextFieldPrefix: Sendable, Equatable {
    case none
    case icon(WDIconName)
    case text(Text)
  }

  /// 字段尾部附件槽（SPEC §2.3；`clear` 独立可达、不合并）。
  public enum WDTextFieldAccessory: Sendable, Equatable {
    case none
    case unit(Text)
    case clear(accessibilityLabel: Text)
    case reveal(hiddenAccessibilityLabel: Text, shownAccessibilityLabel: Text)
    case count(current: Int, limit: Int)
  }

  /// 字段辅助文案槽（SPEC §2.3）。
  public enum WDTextFieldHelper: Sendable, Equatable {
    case none
    case hint(Text)
    case error(Text)
  }

  /// 字段外观对象（★ 只 `Sendable`：`SubmitLabel` 不 `Equatable`；SPEC §2.3）。
  public struct WDTextFieldAppearance: Sendable {
    /// 档位。
    public var variant: WDTextFieldVariant = .inset
    /// 占位串（由调用方给）。
    public var placeholder: Text? = nil
    /// 前缀。
    public var prefix: WDTextFieldPrefix = .none
    /// 尾部附件。
    public var accessory: WDTextFieldAccessory = .none
    /// 辅助文案。
    public var helper: WDTextFieldHelper = .none
    /// 是否密文。
    public var isSecure: Bool = false
    /// 回车键类型。
    public var submitLabel: SubmitLabel = .done

    /// 构造（全参数默认值）。
    public init(
      variant: WDTextFieldVariant = .inset,
      placeholder: Text? = nil,
      prefix: WDTextFieldPrefix = .none,
      accessory: WDTextFieldAccessory = .none,
      helper: WDTextFieldHelper = .none,
      isSecure: Bool = false,
      submitLabel: SubmitLabel = .done
    ) {
      fatalError()
    }
  }

  /// 输入字段（SPEC §2.3；字段盒 46 的验收锚点在 M2）。
  public struct WDTextField: View {
    /// 构造。
    public init(
      text: Binding<String>,
      label: Text,
      appearance: WDTextFieldAppearance = .init(),
      isEditable: Bool = true,
      onSubmit: (() -> Void)? = nil,
      onEditingChanged: ((Bool) -> Void)? = nil
    ) {
      fatalError()
    }

    /// 真实渲染在 M2；此处只锁签名。
    public var body: some View {
      fatalError()
    }
  }

  /// 列表行行首槽（SPEC §2.4）。
  public enum WDListRowLeading: Sendable, Equatable {
    case none
    case icon(WDIconName)
    case avatar(WDAvatarValue)
    case checkbox
    case selectionIndicator
  }

  /// 列表行行尾槽（SPEC §2.4）。
  public enum WDListRowTrailing: Sendable, Equatable {
    case none
    case value(Text)
    case badge(WDBadgeValue)
    case avatar(WDAvatarValue)
    case disclosure
  }

  /// 滑动动作（含闭包 ⇒ `@MainActor`，不声明 `Equatable`；SPEC §2.4）。
  @MainActor public enum WDListRowSwipeAction {
    case none
    case delete(title: Text, onDelete: () -> Void)
  }

  /// 列表行（SPEC §2.4；7 参，已删除 `tertiary`）。
  public struct WDListRow: View {
    /// 构造。
    public init(
      title: Text,
      subtitle: Text? = nil,
      leading: WDListRowLeading = .none,
      trailing: WDListRowTrailing = .none,
      isSelected: Bool = false,
      swipeAction: WDListRowSwipeAction = .none,
      showsSeparator: Bool = true,
      action: (() -> Void)? = nil
    ) {
      fatalError()
    }

    /// 真实渲染在 M2；此处只锁签名。
    public var body: some View {
      fatalError()
    }
  }

  // MARK: - ② 弹层公开面（SPEC §2.5）

  /// 面板档位（0.5 / 0.92；SPEC §2.5）。
  public enum WDBottomSheetDetent: String, CaseIterable, Sendable, Equatable {
    case half, large
  }

  /// 档位联合（iOS 独有 ⇒ 登记 F38；默认 `.all` 与 Android 默认档一致）。
  public enum WDBottomSheetDetents: Sendable, Equatable {
    case all
    case fixed(WDBottomSheetDetent)
  }

  extension View {
    /// 底部面板修饰符（锚点视图形态 ⇒ F21；`closeButtonAccessibilityLabel` 必填）。
    public func wdSheet<Content: View, Footer: View>(
      isPresented: Binding<Bool>,
      detents: WDBottomSheetDetents = .all,
      initialDetent: WDBottomSheetDetent = .half,
      interactiveDismissDisabled: Bool = false,
      title: Text? = nil,
      closeButtonAccessibilityLabel: Text,
      onCloseButtonTap: (() -> Void)? = nil,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: () -> Content,
      @ViewBuilder footer: () -> Footer
    ) -> some View {
      fatalError()
    }
  }

  /// 操作表选项（★ 不是 `Hashable`：含 `Text`；SPEC §2.5）。
  public struct WDActionSheetItem: Identifiable, Sendable, Equatable {
    /// 选项角色。
    public enum Role: Sendable, Equatable {
      case `default`
      case destructive
      case cancel
    }

    /// 稳定身份。
    public let id: String
    /// 标签文案（调用方给）。
    public let label: Text
    /// 角色。
    public let role: Role
  }

  extension View {
    /// 操作表修饰符（可见性唯一真源在调用方；无 `onDismissAttempt`）。
    public func wdActionSheet(
      isPresented: Binding<Bool>,
      title: Text? = nil,
      message: Text? = nil,
      items: [WDActionSheetItem],
      onSelect: @escaping (WDActionSheetItem.ID) -> Void,
      onCancel: (() -> Void)? = nil
    ) -> some View {
      fatalError()
    }
  }

  // MARK: - ③ 无障碍与语义公开面（SPEC §2.6.2 / §3.6）

  /// 语义拼接原语：只做**结构**（零标点、零语序、零状态文案；B2/D5）。
  public enum WDSemantics {
    /// 按 `separator` 拼接文本块。
    public static func join(_ parts: [Text], separator: Text) -> Text {
      fatalError()
    }

    /// 位置措辞（措辞与分隔符均由调用方给）。
    public static func positional(label: Text, positionText: Text, separator: Text) -> Text {
      fatalError()
    }

    /// 纯逻辑重载（供两端 fixtures）。
    public static func join(_ parts: [String], separator: String) -> String {
      fatalError()
    }
  }

  /// 播报优先级（SPEC §2.6.2）。
  public enum WDAnnouncementPriority: Sendable, Equatable {
    case polite
    case assertive
  }

  /// 播报网关（★ 去 `Sendable`；口径 = §1.2.1 隔离注解表）。
  @MainActor public protocol WDAnnouncing {
    /// 同步播报（无 `Task`）。
    func post(_ text: String, priority: WDAnnouncementPriority)
  }

  /// 系统播报实现（M1 落地：同步调 `AccessibilityNotification.Announcement(_:).post()`）。
  @MainActor public struct WDSystemAnnouncer: WDAnnouncing {
    /// 同步播报。
    public func post(_ text: String, priority: WDAnnouncementPriority) {
      fatalError()
    }
  }

  /// 播报节流（纯逻辑，两端同源 fixtures `announcement-cases.json`）。
  public enum WDAnnouncementThrottle {
    /// 是否应播报（阈值集合由调用方给）。
    public static func shouldAnnounce(previous: Double, current: Double, thresholds: [Double])
      -> Bool
    {
      fatalError()
    }

    /// 释放后是否应播报。
    public static func shouldAnnounceAfterRelease(
      now: ContinuousClock.Instant,
      last: ContinuousClock.Instant?
    ) -> Bool {
      fatalError()
    }
  }

  /// 无障碍焦点身份（`@AccessibilityFocusState` 需要 `Hashable` ⇒ 不能用 `Text`；§2.6.2）。
  public struct WDA11yFocusID: Hashable, Sendable {
    /// 原始值。
    public let rawValue: String
  }

  // MARK: - ④ 主题 / 材质 / 动效公开面（SPEC §3.2 / §3.5）

  /// 平台外观快照（字段名 + `WDGlassResolution` = U10 契约真源；IOS-11）。
  public struct WDAppearance: Sendable, Equatable {
    /// 亮/暗。
    public let colorScheme: ColorScheme
    /// 对比度（`.standard` / `.increased`）。
    public let contrast: ColorSchemeContrast
    /// 降低透明度。
    public let reduceTransparency: Bool
    /// 不依赖颜色的区分。
    public let differentiateWithoutColor: Bool
    /// 减弱动效。
    public let reduceMotion: Bool
  }

  /// 玻璃解析结果（U10 输出：`opaque` / `glass` / `glassStrong`）。
  public enum WDGlassResolution: Sendable, Equatable {
    case opaque
    case glass
    case glassStrong
  }

  /// 文字级别（U10 输入之一）。
  public enum WDTextLevel: Sendable, Equatable {
    case primary
    case secondary
    case tertiary
  }

  /// 玻璃解析器（§3.2；`contrast == .increased` / `reduceTransparency` ⇒ `opaque`）。
  public enum WDGlass {
    /// 解析档位。
    public static func resolve(
      textLevel: WDTextLevel,
      appearance: WDAppearance,
      capabilities: WDGlassCapabilities,
      budget: WDEffectsBudget
    ) -> WDGlassResolution {
      fatalError()
    }
  }

  /// 动效令牌协议（§3.5；成员待 M1 定，此处只锁约束名）。
  public protocol WDMotionToken {}

  extension View {
    /// 属性动画唯一入口（内含 Reduce Motion 归一，不给组件留开关）。
    public func wdAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
      fatalError()
    }

    /// 令牌动画唯一入口。
    public func wdAnimation<M: WDMotionToken, V: Equatable>(_ token: M, value: V) -> some View {
      fatalError()
    }
  }

  // MARK: - smoke 专用最小替身（真实声明落地时**同 PR 删除本段**）
  //
  // 下面这些类型被上面的签名引用，但 SPEC 未给定义（或由生成物承载）。此处**只锁类型名与必要约束**，
  // 不代拟任何成员——避免把凭空发明的 API 写进 `api/WisdomUI.api.json` 符号快照基线。
  // 落地清单：`WDIconName` = I-M0-h（生成物）⚠️；`WDAvatarValue` / `WDBadgeValue` = M2/M5；
  // `WDGlassCapabilities` / `WDEffectsBudget` = M1/M4；`WDMotionToken` 成员 = M1。

  /// 图标语义名（44 条语义名由生成物承载）。
  /// ⚠️ **`Generated/WDIconName.swift` 落地（I-M0-h）时必须同 PR 删除本段**，否则重复声明。
  /// `placeholder` 是 smoke 占位 case（raw-value 枚举不能零 case）；不代表任何真实图标语义。
  public enum WDIconName: String, CaseIterable, Sendable, Equatable {
    /// smoke 占位（随本段一并删除）。
    case placeholder
  }

  /// 头像值（真实声明落 M2/M5）。
  public struct WDAvatarValue: Sendable, Equatable {}

  /// 徽标值（真实声明落 M2/M5）。
  public struct WDBadgeValue: Sendable, Equatable {}

  /// 玻璃能力集合（U10 输入；成员待 M1/M4 定）。
  public struct WDGlassCapabilities: Sendable, Equatable {}

  /// 效果配额（U10 输入；§12.2 的 7 条硬上限在 M4 编码）。
  public struct WDEffectsBudget: Sendable, Equatable {}

#endif
