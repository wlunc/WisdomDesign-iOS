import SwiftUI
import Testing
import WisdomUI

/// 效果配额（DF-03 的 **7 条硬上限**）—— M1 三件套之二。
@MainActor
@Suite("效果配额 7 条")
struct WDEffectsBudgetTests {
  @Test("默认预算 == §12.2 的七条上限原值")
  func defaults() {
    let budget = WDEffectsBudget.default
    #expect(budget.blurSurfaces == 1, "① 同屏模糊面 ≤1")
    #expect(budget.washes == 1, "② 色晕每屏 1 处")
    #expect(budget.sheens == 1, "③ sheen 每屏 ≤1")
    #expect(budget.skeletonShimmers == 6, "④ 骨架微光同屏 ≤6")
    #expect(budget.strongElevations == 1, "⑤ e3 每屏 ≤1")
    #expect(budget.animatedRings == 1, "⑥ 动画环每屏 ≤1")
    #expect(budget.hapticsPerAction == 1, "⑦ 触觉同一次操作 1 次")
  }

  @Test("minimal：效果全关（触觉保留 1 次 —— 它是节流而不是可关效果）")
  func minimal() {
    let budget = WDEffectsBudget.minimal
    #expect(budget.blurSurfaces == 0)
    #expect(budget.washes == 0)
    #expect(budget.sheens == 0)
    #expect(budget.skeletonShimmers == 0)
    #expect(budget.strongElevations == 0)
    #expect(budget.animatedRings == 0)
    #expect(budget.hapticsPerAction == 1)
  }

  @Test("reduced 只降不升：给更大的值得到原值（R18 的语义保证）")
  func reducedNeverRaises() {
    let budget = WDEffectsBudget.default.reduced(blurSurfaces: 5, skeletonShimmers: 99)
    #expect(budget.blurSurfaces == 1, "想升到 5 应保持 1")
    #expect(budget.skeletonShimmers == 6, "想升到 99 应保持 6")
    let lower = WDEffectsBudget.default.reduced(blurSurfaces: 0, skeletonShimmers: 3)
    #expect(lower.blurSurfaces == 0)
    #expect(lower.skeletonShimmers == 3)
    let negative = WDEffectsBudget.default.reduced(washes: -4)
    #expect(negative.washes == 0, "负值应被夹到 0")
  }

  @Test("downgraded(to:) 取字段级下界（环境修饰符的机器保证）")
  func downgradedTakesLowerBound() {
    let merged = WDEffectsBudget.default.downgraded(to: .minimal)
    #expect(merged == .minimal)
    let raised = WDEffectsBudget.minimal.downgraded(to: .default)
    #expect(raised == .minimal, "与更大的预算合并不得被'升'回去")
  }
}
