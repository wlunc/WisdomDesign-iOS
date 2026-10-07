import SwiftUI

// 生成代码引用的主题类型。手写文件，不属于生成产物。
//
// 契约来源（两处，必须同时满足）：
//   ① generated/WDColorSlots.swift 文件头的「手写层契约」（I-M0-h）：
//      本文件提供 `internal init(<32 个命名参数，顺序与生成物一致>)`；WDColorSlot.allCases 顺序与生成物一致；
//      `init(_ patch:)` 的缺省值取 `WDColorValues.default`。
//   ② docs/SPEC.md §3.1（32 槽位 + 只允许颜色/渐变/材质三类槽位覆盖，R19）。
// 槽位清单与叶子路径由令牌真源机械推导（wisdomdesign/tokens/wisdom.tokens.json 的 semantic 叶子），
// 不要手抄：改令牌 → 重新生成 → 本文件的 32 个名字与顺序由生成器的 --check 兜住。

/// 一套 scheme 的 32 个语义色槽位值（U12）。
///
/// 槽位名 = `semantic.<scheme>` 的叶子路径（`text.primary` → `textPrimary`）。
/// 具体值不在这里：由生成器写进 `generated/WDColorSlots.swift` 的 `extension WDColorValues`
///（`light` / `dark` / `default` / `wdSchemeNames`）。
public struct WDColorValues: Sendable, Equatable {
  /// 槽位 `bg.canvas`。
  public let bgCanvas: Color
  /// 槽位 `bg.grouped`。
  public let bgGrouped: Color
  /// 槽位 `surface.card`。
  public let surfaceCard: Color
  /// 槽位 `surface.card-solid`。
  public let surfaceCardSolid: Color
  /// 槽位 `surface.card-sunken`。
  public let surfaceCardSunken: Color
  /// 槽位 `surface.tint`。
  public let surfaceTint: Color
  /// 槽位 `surface.glass`。
  public let surfaceGlass: Color
  /// 槽位 `surface.glass-strong`。
  public let surfaceGlassStrong: Color
  /// 槽位 `text.primary`。
  public let textPrimary: Color
  /// 槽位 `text.secondary`。
  public let textSecondary: Color
  /// 槽位 `text.tertiary`。
  public let textTertiary: Color
  /// 槽位 `text.disabled`。
  public let textDisabled: Color
  /// 槽位 `text.on-light-primary`。
  public let textOnLightPrimary: Color
  /// 槽位 `text.on-light-secondary`。
  public let textOnLightSecondary: Color
  /// 槽位 `text.on-light-tertiary`。
  public let textOnLightTertiary: Color
  /// 槽位 `text.on-soft`。
  public let textOnSoft: Color
  /// 槽位 `text.on-fill`。
  public let textOnFill: Color
  /// 槽位 `text.on-dark`。
  public let textOnDark: Color
  /// 槽位 `text.brand`。
  public let textBrand: Color
  /// 槽位 `border.hairline`。
  public let borderHairline: Color
  /// 槽位 `border.hairline-strong`。
  public let borderHairlineStrong: Color
  /// 槽位 `border.glass-top`。
  public let borderGlassTop: Color
  /// 槽位 `fill.field`。
  public let fillField: Color
  /// 槽位 `fill.pressed`。
  public let fillPressed: Color
  /// 槽位 `status.success`。
  public let statusSuccess: Color
  /// 槽位 `status.info`。
  public let statusInfo: Color
  /// 槽位 `status.warning`。
  public let statusWarning: Color
  /// 槽位 `status.danger`。
  public let statusDanger: Color
  /// 槽位 `status-soft.success`。
  public let statusSoftSuccess: Color
  /// 槽位 `status-soft.info`。
  public let statusSoftInfo: Color
  /// 槽位 `status-soft.warning`。
  public let statusSoftWarning: Color
  /// 槽位 `status-soft.danger`。
  public let statusSoftDanger: Color

  /// 由 32 个槽位直接构造。**internal**：外部只能走 `default`、生成的 scheme 常量或 `init(_:)`。
  internal init(
    bgCanvas: Color,
    bgGrouped: Color,
    surfaceCard: Color,
    surfaceCardSolid: Color,
    surfaceCardSunken: Color,
    surfaceTint: Color,
    surfaceGlass: Color,
    surfaceGlassStrong: Color,
    textPrimary: Color,
    textSecondary: Color,
    textTertiary: Color,
    textDisabled: Color,
    textOnLightPrimary: Color,
    textOnLightSecondary: Color,
    textOnLightTertiary: Color,
    textOnSoft: Color,
    textOnFill: Color,
    textOnDark: Color,
    textBrand: Color,
    borderHairline: Color,
    borderHairlineStrong: Color,
    borderGlassTop: Color,
    fillField: Color,
    fillPressed: Color,
    statusSuccess: Color,
    statusInfo: Color,
    statusWarning: Color,
    statusDanger: Color,
    statusSoftSuccess: Color,
    statusSoftInfo: Color,
    statusSoftWarning: Color,
    statusSoftDanger: Color
  ) {
    self.bgCanvas = bgCanvas
    self.bgGrouped = bgGrouped
    self.surfaceCard = surfaceCard
    self.surfaceCardSolid = surfaceCardSolid
    self.surfaceCardSunken = surfaceCardSunken
    self.surfaceTint = surfaceTint
    self.surfaceGlass = surfaceGlass
    self.surfaceGlassStrong = surfaceGlassStrong
    self.textPrimary = textPrimary
    self.textSecondary = textSecondary
    self.textTertiary = textTertiary
    self.textDisabled = textDisabled
    self.textOnLightPrimary = textOnLightPrimary
    self.textOnLightSecondary = textOnLightSecondary
    self.textOnLightTertiary = textOnLightTertiary
    self.textOnSoft = textOnSoft
    self.textOnFill = textOnFill
    self.textOnDark = textOnDark
    self.textBrand = textBrand
    self.borderHairline = borderHairline
    self.borderHairlineStrong = borderHairlineStrong
    self.borderGlassTop = borderGlassTop
    self.fillField = fillField
    self.fillPressed = fillPressed
    self.statusSuccess = statusSuccess
    self.statusInfo = statusInfo
    self.statusWarning = statusWarning
    self.statusDanger = statusDanger
    self.statusSoftSuccess = statusSoftSuccess
    self.statusSoftInfo = statusSoftInfo
    self.statusSoftWarning = statusSoftWarning
    self.statusSoftDanger = statusSoftDanger
  }

  /// 以覆盖补丁构造：未覆盖的槽位取 `WDColorValues.default`（基线）。
  public init(_ patch: WDColorOverrides) {
    self.init(
      bgCanvas: patch.bgCanvas ?? WDColorValues.default.bgCanvas,
      bgGrouped: patch.bgGrouped ?? WDColorValues.default.bgGrouped,
      surfaceCard: patch.surfaceCard ?? WDColorValues.default.surfaceCard,
      surfaceCardSolid: patch.surfaceCardSolid ?? WDColorValues.default.surfaceCardSolid,
      surfaceCardSunken: patch.surfaceCardSunken ?? WDColorValues.default.surfaceCardSunken,
      surfaceTint: patch.surfaceTint ?? WDColorValues.default.surfaceTint,
      surfaceGlass: patch.surfaceGlass ?? WDColorValues.default.surfaceGlass,
      surfaceGlassStrong: patch.surfaceGlassStrong ?? WDColorValues.default.surfaceGlassStrong,
      textPrimary: patch.textPrimary ?? WDColorValues.default.textPrimary,
      textSecondary: patch.textSecondary ?? WDColorValues.default.textSecondary,
      textTertiary: patch.textTertiary ?? WDColorValues.default.textTertiary,
      textDisabled: patch.textDisabled ?? WDColorValues.default.textDisabled,
      textOnLightPrimary: patch.textOnLightPrimary ?? WDColorValues.default.textOnLightPrimary,
      textOnLightSecondary: patch.textOnLightSecondary
        ?? WDColorValues.default.textOnLightSecondary,
      textOnLightTertiary: patch.textOnLightTertiary ?? WDColorValues.default.textOnLightTertiary,
      textOnSoft: patch.textOnSoft ?? WDColorValues.default.textOnSoft,
      textOnFill: patch.textOnFill ?? WDColorValues.default.textOnFill,
      textOnDark: patch.textOnDark ?? WDColorValues.default.textOnDark,
      textBrand: patch.textBrand ?? WDColorValues.default.textBrand,
      borderHairline: patch.borderHairline ?? WDColorValues.default.borderHairline,
      borderHairlineStrong: patch.borderHairlineStrong
        ?? WDColorValues.default.borderHairlineStrong,
      borderGlassTop: patch.borderGlassTop ?? WDColorValues.default.borderGlassTop,
      fillField: patch.fillField ?? WDColorValues.default.fillField,
      fillPressed: patch.fillPressed ?? WDColorValues.default.fillPressed,
      statusSuccess: patch.statusSuccess ?? WDColorValues.default.statusSuccess,
      statusInfo: patch.statusInfo ?? WDColorValues.default.statusInfo,
      statusWarning: patch.statusWarning ?? WDColorValues.default.statusWarning,
      statusDanger: patch.statusDanger ?? WDColorValues.default.statusDanger,
      statusSoftSuccess: patch.statusSoftSuccess ?? WDColorValues.default.statusSoftSuccess,
      statusSoftInfo: patch.statusSoftInfo ?? WDColorValues.default.statusSoftInfo,
      statusSoftWarning: patch.statusSoftWarning ?? WDColorValues.default.statusSoftWarning,
      statusSoftDanger: patch.statusSoftDanger ?? WDColorValues.default.statusSoftDanger
    )
  }
}

/// 颜色槽位覆盖补丁（R19 允许的三类 `*Overrides` 之一）。`nil` = 该槽位不覆盖。
public struct WDColorOverrides: Sendable {
  /// 覆盖 `bg.canvas`；`nil` = 用默认主题的值。
  public var bgCanvas: Color?
  /// 覆盖 `bg.grouped`；`nil` = 用默认主题的值。
  public var bgGrouped: Color?
  /// 覆盖 `surface.card`；`nil` = 用默认主题的值。
  public var surfaceCard: Color?
  /// 覆盖 `surface.card-solid`；`nil` = 用默认主题的值。
  public var surfaceCardSolid: Color?
  /// 覆盖 `surface.card-sunken`；`nil` = 用默认主题的值。
  public var surfaceCardSunken: Color?
  /// 覆盖 `surface.tint`；`nil` = 用默认主题的值。
  public var surfaceTint: Color?
  /// 覆盖 `surface.glass`；`nil` = 用默认主题的值。
  public var surfaceGlass: Color?
  /// 覆盖 `surface.glass-strong`；`nil` = 用默认主题的值。
  public var surfaceGlassStrong: Color?
  /// 覆盖 `text.primary`；`nil` = 用默认主题的值。
  public var textPrimary: Color?
  /// 覆盖 `text.secondary`；`nil` = 用默认主题的值。
  public var textSecondary: Color?
  /// 覆盖 `text.tertiary`；`nil` = 用默认主题的值。
  public var textTertiary: Color?
  /// 覆盖 `text.disabled`；`nil` = 用默认主题的值。
  public var textDisabled: Color?
  /// 覆盖 `text.on-light-primary`；`nil` = 用默认主题的值。
  public var textOnLightPrimary: Color?
  /// 覆盖 `text.on-light-secondary`；`nil` = 用默认主题的值。
  public var textOnLightSecondary: Color?
  /// 覆盖 `text.on-light-tertiary`；`nil` = 用默认主题的值。
  public var textOnLightTertiary: Color?
  /// 覆盖 `text.on-soft`；`nil` = 用默认主题的值。
  public var textOnSoft: Color?
  /// 覆盖 `text.on-fill`；`nil` = 用默认主题的值。
  public var textOnFill: Color?
  /// 覆盖 `text.on-dark`；`nil` = 用默认主题的值。
  public var textOnDark: Color?
  /// 覆盖 `text.brand`；`nil` = 用默认主题的值。
  public var textBrand: Color?
  /// 覆盖 `border.hairline`；`nil` = 用默认主题的值。
  public var borderHairline: Color?
  /// 覆盖 `border.hairline-strong`；`nil` = 用默认主题的值。
  public var borderHairlineStrong: Color?
  /// 覆盖 `border.glass-top`；`nil` = 用默认主题的值。
  public var borderGlassTop: Color?
  /// 覆盖 `fill.field`；`nil` = 用默认主题的值。
  public var fillField: Color?
  /// 覆盖 `fill.pressed`；`nil` = 用默认主题的值。
  public var fillPressed: Color?
  /// 覆盖 `status.success`；`nil` = 用默认主题的值。
  public var statusSuccess: Color?
  /// 覆盖 `status.info`；`nil` = 用默认主题的值。
  public var statusInfo: Color?
  /// 覆盖 `status.warning`；`nil` = 用默认主题的值。
  public var statusWarning: Color?
  /// 覆盖 `status.danger`；`nil` = 用默认主题的值。
  public var statusDanger: Color?
  /// 覆盖 `status-soft.success`；`nil` = 用默认主题的值。
  public var statusSoftSuccess: Color?
  /// 覆盖 `status-soft.info`；`nil` = 用默认主题的值。
  public var statusSoftInfo: Color?
  /// 覆盖 `status-soft.warning`；`nil` = 用默认主题的值。
  public var statusSoftWarning: Color?
  /// 覆盖 `status-soft.danger`；`nil` = 用默认主题的值。
  public var statusSoftDanger: Color?

  /// 构造：只给要覆盖的槽位，其余留 `nil`。
  public init(
    bgCanvas: Color? = nil,
    bgGrouped: Color? = nil,
    surfaceCard: Color? = nil,
    surfaceCardSolid: Color? = nil,
    surfaceCardSunken: Color? = nil,
    surfaceTint: Color? = nil,
    surfaceGlass: Color? = nil,
    surfaceGlassStrong: Color? = nil,
    textPrimary: Color? = nil,
    textSecondary: Color? = nil,
    textTertiary: Color? = nil,
    textDisabled: Color? = nil,
    textOnLightPrimary: Color? = nil,
    textOnLightSecondary: Color? = nil,
    textOnLightTertiary: Color? = nil,
    textOnSoft: Color? = nil,
    textOnFill: Color? = nil,
    textOnDark: Color? = nil,
    textBrand: Color? = nil,
    borderHairline: Color? = nil,
    borderHairlineStrong: Color? = nil,
    borderGlassTop: Color? = nil,
    fillField: Color? = nil,
    fillPressed: Color? = nil,
    statusSuccess: Color? = nil,
    statusInfo: Color? = nil,
    statusWarning: Color? = nil,
    statusDanger: Color? = nil,
    statusSoftSuccess: Color? = nil,
    statusSoftInfo: Color? = nil,
    statusSoftWarning: Color? = nil,
    statusSoftDanger: Color? = nil
  ) {
    self.bgCanvas = bgCanvas
    self.bgGrouped = bgGrouped
    self.surfaceCard = surfaceCard
    self.surfaceCardSolid = surfaceCardSolid
    self.surfaceCardSunken = surfaceCardSunken
    self.surfaceTint = surfaceTint
    self.surfaceGlass = surfaceGlass
    self.surfaceGlassStrong = surfaceGlassStrong
    self.textPrimary = textPrimary
    self.textSecondary = textSecondary
    self.textTertiary = textTertiary
    self.textDisabled = textDisabled
    self.textOnLightPrimary = textOnLightPrimary
    self.textOnLightSecondary = textOnLightSecondary
    self.textOnLightTertiary = textOnLightTertiary
    self.textOnSoft = textOnSoft
    self.textOnFill = textOnFill
    self.textOnDark = textOnDark
    self.textBrand = textBrand
    self.borderHairline = borderHairline
    self.borderHairlineStrong = borderHairlineStrong
    self.borderGlassTop = borderGlassTop
    self.fillField = fillField
    self.fillPressed = fillPressed
    self.statusSuccess = statusSuccess
    self.statusInfo = statusInfo
    self.statusWarning = statusWarning
    self.statusDanger = statusDanger
    self.statusSoftSuccess = statusSoftSuccess
    self.statusSoftInfo = statusSoftInfo
    self.statusSoftWarning = statusSoftWarning
    self.statusSoftDanger = statusSoftDanger
  }
}

/// 语义色槽位（U12 = 32 个，含 `text.disabled`）。
///
/// `allCases` 的顺序 = 生成器写出的槽位顺序（生成器 `--check` 断言计数 == 32）；
/// 枚举是 `String` 原始值 + `CaseIterable` + `Sendable`，**不加 `@frozen`**（F-20：新增 case 属源级 breaking）。
public enum WDColorSlot: String, CaseIterable, Sendable {
  /// 槽位 `bg.canvas`。
  case bgCanvas = "bg.canvas"
  /// 槽位 `bg.grouped`。
  case bgGrouped = "bg.grouped"
  /// 槽位 `surface.card`。
  case surfaceCard = "surface.card"
  /// 槽位 `surface.card-solid`。
  case surfaceCardSolid = "surface.card-solid"
  /// 槽位 `surface.card-sunken`。
  case surfaceCardSunken = "surface.card-sunken"
  /// 槽位 `surface.tint`。
  case surfaceTint = "surface.tint"
  /// 槽位 `surface.glass`。
  case surfaceGlass = "surface.glass"
  /// 槽位 `surface.glass-strong`。
  case surfaceGlassStrong = "surface.glass-strong"
  /// 槽位 `text.primary`。
  case textPrimary = "text.primary"
  /// 槽位 `text.secondary`。
  case textSecondary = "text.secondary"
  /// 槽位 `text.tertiary`。
  case textTertiary = "text.tertiary"
  /// 槽位 `text.disabled`。
  case textDisabled = "text.disabled"
  /// 槽位 `text.on-light-primary`。
  case textOnLightPrimary = "text.on-light-primary"
  /// 槽位 `text.on-light-secondary`。
  case textOnLightSecondary = "text.on-light-secondary"
  /// 槽位 `text.on-light-tertiary`。
  case textOnLightTertiary = "text.on-light-tertiary"
  /// 槽位 `text.on-soft`。
  case textOnSoft = "text.on-soft"
  /// 槽位 `text.on-fill`。
  case textOnFill = "text.on-fill"
  /// 槽位 `text.on-dark`。
  case textOnDark = "text.on-dark"
  /// 槽位 `text.brand`。
  case textBrand = "text.brand"
  /// 槽位 `border.hairline`。
  case borderHairline = "border.hairline"
  /// 槽位 `border.hairline-strong`。
  case borderHairlineStrong = "border.hairline-strong"
  /// 槽位 `border.glass-top`。
  case borderGlassTop = "border.glass-top"
  /// 槽位 `fill.field`。
  case fillField = "fill.field"
  /// 槽位 `fill.pressed`。
  case fillPressed = "fill.pressed"
  /// 槽位 `status.success`。
  case statusSuccess = "status.success"
  /// 槽位 `status.info`。
  case statusInfo = "status.info"
  /// 槽位 `status.warning`。
  case statusWarning = "status.warning"
  /// 槽位 `status.danger`。
  case statusDanger = "status.danger"
  /// 槽位 `status-soft.success`。
  case statusSoftSuccess = "status-soft.success"
  /// 槽位 `status-soft.info`。
  case statusSoftInfo = "status-soft.info"
  /// 槽位 `status-soft.warning`。
  case statusSoftWarning = "status-soft.warning"
  /// 槽位 `status-soft.danger`。
  case statusSoftDanger = "status-soft.danger"
}
