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

  // `WDButton` / `WDButtonVariant` / `WDButtonStyle` / `WDListRow` 全家 **已由 M2 落地**
  //（`Components/Primitives/{WDButton,WDListRow}/`），故此冒烟段按纪律删除。

  // MARK: - ② 弹层公开面（SPEC §2.5）

  // WDBottomSheetDetent / WDBottomSheetDetents / wdSheet / WDActionSheetItem / wdActionSheet
  // 已由 M4 落地（Components/Composites/{WDBottomSheet,WDActionSheet}/），故按纪律从冒烟段删除。

  // MARK: - ③ 无障碍与语义公开面（SPEC §2.6.2 / §3.6）

  // `WDSemantics` / `WDAnnouncementPriority` / `WDAnnouncing` / `WDSystemAnnouncer` /
  // `WDAnnouncementThrottle` / `WDA11yFocusID` **已由 2026-11-10 的 a11y 层实现**
  //（`Sources/WisdomUI/Foundation/A11y/`），故此冒烟段按纪律删除（实现落地 = 同 PR 退役）。

  // MARK: - ④ 主题 / 材质 / 动效公开面（SPEC §3.2 / §3.5）

  // U10 的 `WDAppearance` / `WDGlassResolution` / `WDTextLevel` / `WDGlass.resolve`
  // 与 `WDGlassCapabilities` / `WDEffectsBudget` **已由 M1-⑤ 实现**（`Foundation/Material/`），
  // 故从此冒烟段删除（冒烟只放尚未实现的声明 —— 实现落地即删，SPEC §9.2-I-M0-d 的口径）。

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
// 落地清单：`WDIconName`（I-M0-h）、`WDBadgeValue` 与 `WDAvatarValue`（M2）**均已落地**。
// `WDGlassCapabilities` / `WDEffectsBudget` = M1/M4；`WDMotionToken` 成员 = M1。

// `WDIconName` **已由设计仓生成器产出**（Foundation/generated/WDIconName.swift，契约源 = contracts/icons.json），
// 故从此冒烟段删除（I-M0-h 落地）。

// `WDAvatarValue` 已由 M2 的 WDAvatar 实现（`Components/Primitives/WDAvatar/WDAvatar.swift`），
// 故从此冒烟段删除。

// `WDBadgeValue` 已由 M2 的 WDBadge 实现（`Components/Primitives/WDBadge/WDBadge.swift`），
// 故此前已从冒烟段删除。

// U10 的 `WDGlassCapabilities` 与 `WDEffectsBudget` **已由 M1-⑤ 实现**
//（`Foundation/Material/`：能力只有 supportsGlass 一项；预算已编码 §12.2 的 7 条硬上限），
// 故从此冒烟段删除。

#endif
