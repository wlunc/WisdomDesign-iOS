import SwiftUI
import WisdomUI

/// 语义色槽位画廊：32 个槽位各一格（名称 + 色块），把令牌层的取值暴露成可见差异。
public struct WDSlotGallery: View {
  private let values: WDColorValues

  /// - Parameter values: 该套 scheme 的 32 槽位值（默认 `.light`）。
  public init(values: WDColorValues = .light) {
    self.values = values
  }

  /// 32 个语义色槽位的两列网格（名称 + 色块）。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s3) {
      Text(verbatim: "Color slots")
        .wdFont(WDType.title2)
        .wdLineBox(WDType.title2)
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: WDSpacing.s2), count: 2),
        spacing: WDSpacing.s2
      ) {
        ForEach(WDColorSlot.allCases, id: \.self) { slot in
          HStack(spacing: WDSpacing.s2) {
            RoundedRectangle(cornerRadius: WDRadius.xs)
              .fill(Self.color(for: slot, in: values))
              .frame(width: WDSpacing.s6, height: WDSpacing.s6)
            Text(verbatim: slot.rawValue)
              .wdFont(WDType.caption2)
              .wdLineBox(WDType.caption2)
          }
        }
      }
    }
    .foregroundStyle(values.textPrimary)
    .padding(WDSpacing.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(values.bgCanvas)
  }

  /// 槽位 → 颜色（32 个槽位逐一映射；这是画廊的**穷举**保证，不依赖反射）。
  static func color(for slot: WDColorSlot, in values: WDColorValues) -> Color {
    switch slot {
    case .bgCanvas: return values.bgCanvas
    case .bgGrouped: return values.bgGrouped
    case .surfaceCard: return values.surfaceCard
    case .surfaceCardSolid: return values.surfaceCardSolid
    case .surfaceCardSunken: return values.surfaceCardSunken
    case .surfaceTint: return values.surfaceTint
    case .surfaceGlass: return values.surfaceGlass
    case .surfaceGlassStrong: return values.surfaceGlassStrong
    case .textPrimary: return values.textPrimary
    case .textSecondary: return values.textSecondary
    case .textTertiary: return values.textTertiary
    case .textDisabled: return values.textDisabled
    case .textOnLightPrimary: return values.textOnLightPrimary
    case .textOnLightSecondary: return values.textOnLightSecondary
    case .textOnLightTertiary: return values.textOnLightTertiary
    case .textOnSoft: return values.textOnSoft
    case .textOnFill: return values.textOnFill
    case .textOnDark: return values.textOnDark
    case .textBrand: return values.textBrand
    case .borderHairline: return values.borderHairline
    case .borderHairlineStrong: return values.borderHairlineStrong
    case .borderGlassTop: return values.borderGlassTop
    case .fillField: return values.fillField
    case .fillPressed: return values.fillPressed
    case .statusSuccess: return values.statusSuccess
    case .statusInfo: return values.statusInfo
    case .statusWarning: return values.statusWarning
    case .statusDanger: return values.statusDanger
    case .statusSoftSuccess: return values.statusSoftSuccess
    case .statusSoftInfo: return values.statusSoftInfo
    case .statusSoftWarning: return values.statusSoftWarning
    case .statusSoftDanger: return values.statusSoftDanger
    }
  }
}
