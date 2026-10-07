import SwiftUI

/// 效果预算（DF-03 的 **7 条硬上限**；F16/F28：降低透明度**没有**系统等价物，靠它兜底）。
///
/// 只读纪律（R18）：组件**只读** `wdEffectsBudget`；写入口只有 `Foundation/Theme/WDEnvironment.swift`
/// 的 `View` 修饰符，且**只能降不能升**（`reduced` 是唯一被认可的降法）。
public struct WDEffectsBudget: Sendable, Equatable {
  /// ① 同屏模糊面数量上限（列表项内 0；深色 Tab 栏直接不透明省一次模糊）。
  public let blurSurfaces: Int
  /// ② 色晕 `wash` 处数上限（每屏 1，禁动画；实现必须一次绘制画 3 段 radial）。
  public let washes: Int
  /// ③ 高光扫过 `sheen` 处数上限（每屏 ≤1，只用于强调卡片）。
  public let sheens: Int
  /// ④ 骨架微光处数上限（同屏 ≤6，超出用静态灰块）。
  public let skeletonShimmers: Int
  /// ⑤ 阴影档位上限：列表项 `e0`/`e1`；`e3` 每屏 ≤1。
  public let strongElevations: Int
  /// ⑥ 动画环（进度环 / 下拉环）数量上限。
  public let animatedRings: Int
  /// ⑦ 触觉次数上限（同一次操作 1 次，需节流）。
  public let hapticsPerAction: Int

  /// 七条上限逐项给值（默认取 `WDEffectsBudget.default`；降级用 `reduced`/`downgraded(to:)`）。
  public init(
    blurSurfaces: Int,
    washes: Int,
    sheens: Int,
    skeletonShimmers: Int,
    strongElevations: Int,
    animatedRings: Int,
    hapticsPerAction: Int
  ) {
    self.blurSurfaces = blurSurfaces
    self.washes = washes
    self.sheens = sheens
    self.skeletonShimmers = skeletonShimmers
    self.strongElevations = strongElevations
    self.animatedRings = animatedRings
    self.hapticsPerAction = hapticsPerAction
  }

  /// 默认预算 = 7 条上限的原值（DF-03）。
  public static let `default` = WDEffectsBudget(
    blurSurfaces: 1,
    washes: 1,
    sheens: 1,
    skeletonShimmers: 6,
    strongElevations: 1,
    animatedRings: 1,
    hapticsPerAction: 1
  )

  /// 关闭全部效果（降低透明度 / 高对比度 / 低电量场景的降级档）。
  public static let minimal = WDEffectsBudget(
    blurSurfaces: 0,
    washes: 0,
    sheens: 0,
    skeletonShimmers: 0,
    strongElevations: 0,
    animatedRings: 0,
    hapticsPerAction: 1
  )

  /// 与另一份预算取字段级下界 —— **"只降不升"的机器保证**（环境修饰符用它）。
  public func downgraded(to other: WDEffectsBudget) -> WDEffectsBudget {
    WDEffectsBudget(
      blurSurfaces: min(blurSurfaces, other.blurSurfaces),
      washes: min(washes, other.washes),
      sheens: min(sheens, other.sheens),
      skeletonShimmers: min(skeletonShimmers, other.skeletonShimmers),
      strongElevations: min(strongElevations, other.strongElevations),
      animatedRings: min(animatedRings, other.animatedRings),
      hapticsPerAction: min(hapticsPerAction, other.hapticsPerAction)
    )
  }

  /// 降级到更小的预算：**只降不升**（对每个字段取下界；想升会得到原值）。
  public func reduced(
    blurSurfaces: Int? = nil,
    washes: Int? = nil,
    sheens: Int? = nil,
    skeletonShimmers: Int? = nil,
    strongElevations: Int? = nil,
    animatedRings: Int? = nil,
    hapticsPerAction: Int? = nil
  ) -> WDEffectsBudget {
    func lower(_ current: Int, _ wanted: Int?) -> Int {
      guard let wanted else { return current }
      return min(current, max(0, wanted))
    }
    return WDEffectsBudget(
      blurSurfaces: lower(self.blurSurfaces, blurSurfaces),
      washes: lower(self.washes, washes),
      sheens: lower(self.sheens, sheens),
      skeletonShimmers: lower(self.skeletonShimmers, skeletonShimmers),
      strongElevations: lower(self.strongElevations, strongElevations),
      animatedRings: lower(self.animatedRings, animatedRings),
      hapticsPerAction: lower(self.hapticsPerAction, hapticsPerAction)
    )
  }
}
