import SwiftUI

// MARK: - 长按仲裁状态机（设计 14 §3.3；A-14 的核心）

/// 工具栏按钮的长按仲裁：**纯函数**，输入事件序列输出决策。
///
/// 为什么做成纯函数：设计 §3.3 的仲裁表（六行）必须能被单测**不依赖时序地**断言 ——
/// 把状态与迁移放在这里，视图层（`WDToolbarItemPressStyle` 的仲裁路径）只负责喂事件与执行决策。
/// 「抬手是否执行 action」的**唯一判断点** = `decision(for: .release)` 一处（设计硬要求 2）。
///
/// 仲裁表（设计 §3.3，逐行）：
/// - 按下（0ms）→ 按下态（缩放 0.94 + `fill.pressed`），与原行为一致；
/// - 按住到 **500ms** → 显示提示；取消按下态；**吞掉本次点击**；
/// - 500ms 内抬手 → 普通点击：执行 `action`，不显示提示；
/// - 500ms 后抬手 → **不执行** `action`；提示保持到抬手后 160ms 淡出；
/// - 500ms 后滑出热区 → 提示消失，本次手势作废（不执行 action）；
/// - `isEnabled == false` → 不显示提示（禁用按钮不该被探索式触发）。
enum WDToolbarArbitration {
  /// 仲裁输入事件。
  enum Event: Equatable {
    /// 按下（携带按下时刻，相对任意单调起点）。
    case press(at: TimeInterval)
    /// 抬手（携带时刻）。
    case release(at: TimeInterval)
    /// 按住期间滑出按钮热区（携带时刻）。
    case dragOut(at: TimeInterval)
    /// 长按阈值计时器到点（由外层 Task 在 500ms 后喂入）。
    case thresholdFired
  }

  /// 仲裁决策。
  enum Decision: Equatable {
    /// 进入按下态。
    case pressed
    /// 执行 action（普通点击，无提示）。
    case performAction
    /// 显示提示（阈值到点），吞掉点击。
    case showTooltip
    /// 手势作废（滑出热区），隐藏提示、不执行 action。
    case voidGesture
    /// 抬手后隐藏提示（超阈值抬手的收尾）。
    case hideTooltip
    /// 无事发生（重复事件、空闲态杂音）。
    case none
  }

  /// 仲裁状态。
  enum Phase: Equatable {
    case idle
    /// 按下未到阈值。
    case pressing(since: TimeInterval)
    /// 阈值已过、提示已显示（本轮吞点击）。
    case tooltipShown
    /// 手势已作废 / 已收尾。
    case consumed
  }

  /// 对单个事件给出决策。**抬手是否执行 action 的唯一判断点**在 `.release` 分支。
  static func decide(_ event: Event, in phase: Phase, threshold: TimeInterval) -> (Decision, Phase)
  {
    switch (event, phase) {
    case (.press(let at), .idle):
      return (.pressed, .pressing(since: at))

    // —— 唯一判断点：抬手是否执行 action ——
    case (.release(let at), .pressing(let since)):
      if at - since < threshold {
        // 设计 §3.3 第 3 行：500ms 内抬手 = 普通点击，执行 action，不显示提示。
        return (.performAction, .idle)
      } else {
        // 设计 §3.3 第 4 行：500ms 后抬手 = 不执行 action；提示保持到抬手后 160ms 淡出
        //（淡出由视图层在 hideTooltip 后接管；状态机只负责"不执行"）。
        return (.hideTooltip, .consumed)
      }

    // 阈值到点：显示提示、取消按下态、吞掉本次点击（§3.3 第 2 行）。
    case (.thresholdFired, .pressing):
      return (.showTooltip, .tooltipShown)

    // 提示显示期间抬手：不执行 action，只收尾 —— 气泡的 160ms 淡出由视图层
    // 的 .animation(value: isVisible) 完成（设计 §3.3 第 4 行「提示保持到抬手后 160ms 淡出」）。
    case (.release, .tooltipShown):
      return (.hideTooltip, .consumed)

    // 滑出热区：提示消失、手势作废（§3.3 第 5 行）。
    case (.dragOut, .pressing), (.dragOut, .tooltipShown):
      return (.voidGesture, .consumed)

    // 空闲态杂音 / consumed 后的一切：忽略。
    case (_, .idle), (_, .consumed):
      return (.none, .consumed)

    // 其余组合在语义上不可达（如 tooltipShown 中再次 thresholdFired、pressing 中重复 press）：
    // 按杂音处理，相位不变（不是 consumed —— pressing 相位仍需保住计时器语义）。
    default:
      return (.none, phase)
    }
  }
}

// MARK: - 提示气泡（设计 14 §3.2/§3.4/§3.6）

// MARK: - 仲裁接线（视图层 → 状态机）

/// 仲裁上下文：把纯状态机的决策接到视图层（WDToolbar 持有的回调）。
/// 非 Sendable（回调都在 MainActor）——按钮样式本身就在 MainActor 上。
/// 仲裁门闩（F1）：Button 的 action 闭包与仲裁样式共享的"本轮是否已吞"标记。
/// 引用类型 —— 两侧看到同一份状态；每次按下时由样式复位。
final class WDToolbarArbitrationLatch {
  /// true = 本轮点击已被仲裁吞掉（长按达标/作废），Button 闭包必须直接 return。
  var isConsumed = false
}

struct WDToolbarItemArbitrationContext {
  let itemID: String
  /// 长按阈值（秒；令牌 `WDSize.tooltipPressDuration` = 0.500）。
  let threshold: Double
  /// 共享门闩（Button 闭包 ⇄ 样式状态机）。
  let latch: WDToolbarArbitrationLatch
  /// 阈值到点 → 显示该项的提示。
  let onTooltip: (String) -> Void
  /// 提示收尾 → 隐藏该项的提示。
  let onTooltipEnd: (String) -> Void
}

/// 长按提示气泡：28 高 / 最大宽 200 / 距按钮热区上边 8 / 圆角 8；
/// 底 `surface.card-solid` 实底（**不上玻璃**）+ hairline + `elevation.e2`；
/// 文字 `caption2` 单行 `text.primary`，左右内距 8；水平居中、越界平移进安全区（内侧留 8），无箭头。
/// 动效（§3.4）：出现 **120ms** 淡入 + 上移 4pt、`easeOut`（不用 spring）；消失 **160ms** 淡出；
/// Reduce Motion 只淡入淡出、无位移。120ms 不在 `motion.duration` 档位内（100/160/240/340/500），
/// 按设计 §4.2-Q2 默认执行项**硬编码为组件内常量**（不进令牌档位）。
/// 无障碍（§3.6）：`accessibilityHidden(true)` 不进无障碍树、不重复播报；
/// 长按不是唯一入口 —— 按钮的点击路径仍在。
struct WDToolbarTooltip: View {
  let text: Text
  let isVisible: Bool

  @Environment(\.wdColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// 出现时长 120ms（设计 §4.2-Q2 默认执行项：不在 motion.duration 档位内，硬编码于此，不进令牌）。
  static let appearDuration: Double = 0.12  // wd-structure-check:disable R7 — 设计 14 §4.2-Q2 默认执行项
  /// 消失时长 = motion.duration.fast（160ms；设计 §3.4）。
  static let disappearDuration: Double = WDMotion.Duration.fast
  /// 出现位移 4pt（Reduce Motion 下为 0；设计 §3.4）。
  static let appearOffset: CGFloat = 4  // wd-structure-check:disable R7 — 设计 14 §3.4 出现位移
  /// 距按钮热区上边 8（令牌 WDSize.tooltipOffset；设计 §3.2「距按钮热区上边 8」）。
  static let gapAboveButton: CGFloat = WDSize.tooltipOffset

  /// 水平越界时距安全区（屏幕缘）的内缩（设计 §3.2）。
  static let screenEdgeInset: CGFloat = WDSpacing.s3

  var body: some View {
    text
      .wdFont(WDType.caption2)
      .foregroundStyle(colors.textPrimary)
      .lineLimit(1)
      .padding(.horizontal, WDSpacing.s3)
      .frame(minHeight: WDSize.tooltipHeight)
      .frame(maxWidth: WDSize.tooltipMaxWidth)
      .background(
        RoundedRectangle(cornerRadius: WDRadius.xs, style: .continuous)
          .fill(colors.surfaceCardSolid)
          .overlay(
            RoundedRectangle(cornerRadius: WDRadius.xs, style: .continuous)
              .stroke(colors.borderHairline, lineWidth: 1)
          )
      )
      .modifier(WDToolbarTooltipShadow())
      // 出现：120ms 淡入 + 上移 4pt（Reduce Motion 只淡入淡出、无位移）；消失：160ms 淡出。
      //
      // 位移方向 = 「起点偏低、稳态归零」：稳态 offset = 0 ⇒ 气泡的真实下边缘由
      // `WDToolbarTooltipAnchor` 的 alignmentGuide 锚在「距按钮热区上边 8」；
      // 入场从 +4 上移到 0，**不预支进静态几何** ⇒ 普通 / Reduce Motion / 大字号三种情况
      // 稳态间距恒为 8pt（R2 验证 #22 与 §8.4 的根因都在这条预支上）。
      .opacity(isVisible ? 1 : 0)
      .offset(y: reduceMotion ? 0 : (isVisible ? 0 : Self.appearOffset))
      .animation(
        isVisible
          ? .easeOut(duration: Self.appearDuration)
          : .easeOut(duration: Self.disappearDuration),
        value: isVisible
      )
      .accessibilityHidden(true)  // 设计 §3.6：提示不进无障碍树，不重复播报
      .allowsHitTesting(false)
  }
}

/// 气泡阴影 `elevation.e2`（浮层档；设计 §3.2）。
private struct WDToolbarTooltipShadow: ViewModifier {
  func body(content: Content) -> some View {
    content.wdShadow(WDElevation.e2)
  }
}

// MARK: - 气泡定位（按钮中心对齐 + 越界平移进安全区）

/// 把气泡挂在按钮上方（§3.2：水平居中于按钮；越界时平移进安全区、内侧留 8，不做箭头）。
/// 用 overlay + `GeometryReader` 读按钮与容器的横向几何，纯定位，不改布局流。
struct WDToolbarTooltipAnchor: ViewModifier {
  let text: Text
  let isVisible: Bool

  func body(content: Content) -> some View {
    content.overlay(alignment: .top) {
      // **下边锚定**（R2 验证 §8 requiredFix B）：气泡的真实下边缘距按钮热区上边
      // `gapAboveButton`(8) —— 用 alignmentGuide 读气泡**自己**的 bottom，而不是
      // 用「中心 - 固定半高」推算。好处：普通 / Reduce Motion / 动态字体放大后的可变高度
      // 三种情况**恒为 8pt**，不会因为高度增长把间距吃掉（§8.4）。
      //
      // 横向仍走全局坐标夹紧（F4）：GeometryReader 读按钮全局 frame，夹紧后换算回局部。
      //
      // ⚠️ **必须插一层 \`Color.clear.overlay(alignment:)\`**（R2 验证 §9 V4-F1 blocker）：
      // \`alignmentGuide\` 只是「向父容器声明对齐边」，**只有父容器消费该维度时才生效**。
      // \`GeometryReader\` 把内容按 topLeading 摆放、不消费自定义导引 ⇒ 直接挂在 GR 内容上
      // 的 guide 是死代码，气泡会压回按钮左上角（实测重叠 28–44pt）。
      // 这层 overlay 是真正消费两轴 guide 的容器，且用 \`.topLeading\` 显式指定两维
      //（不用 \`.top\` —— 它的横向维度是 .center，会与 .leading guide 打架，V4-F3）。
      GeometryReader { proxy in
        let buttonFrame = proxy.frame(in: .global)
        let buttonMidX = buttonFrame.midX
        let halfMax =
          WDSize.tooltipMaxWidth / 2  // wd-structure-check:disable R7 — 几何取半
          + WDToolbarTooltip.screenEdgeInset
        let screenWidth = UIScreen.main.bounds.width
        let clampedGlobalMidX = min(max(buttonMidX, halfMax), screenWidth - halfMax)
        let localMidX = clampedGlobalMidX - buttonFrame.minX
        Color.clear.overlay(alignment: .topLeading) {
          WDToolbarTooltip(text: text, isVisible: isVisible)
            .fixedSize(horizontal: true, vertical: true)
            .alignmentGuide(.top) { dimensions in
              // 气泡自身坐标系里：bottom = 高度；上移 (高度 + 间距) ⇒ 下边缘落在 -间距。
              dimensions[.bottom] + WDToolbarTooltip.gapAboveButton
            }
            .alignmentGuide(.leading) { dimensions in
              // 水平居中于按钮：气泡中心对齐 localMidX ⇒ leading = center − 宽度/2。
              let halfWidth =
                dimensions[.trailing] / 2  // wd-structure-check:disable R7 — 几何取半
              return halfWidth - localMidX
            }
        }
      }
    }
  }
}

extension View {
  /// 在按钮正上方挂提示气泡（越界平移进安全区；internal 供 WDToolbar 使用）。
  func wdToolbarTooltip(text: Text, isVisible: Bool) -> some View {
    modifier(WDToolbarTooltipAnchor(text: text, isVisible: isVisible))
  }
}
