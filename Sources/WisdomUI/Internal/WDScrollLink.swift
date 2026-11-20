import Foundation

/// 滚动联动件的共享纯逻辑（B15：FAB / TabBar / NavigationBar）。
///
/// 三个组件都只读 `wdScrollOffsetY`（`CGFloat?`）：**nil = 不联动**（调用方没接滚动容器，
/// 默认路径像素完全不变）。本文件只做数值换算，不碰视图，便于纯逻辑单测（B15 要求）。
///
/// 约定（三处一致）：**offset 增大 = 内容上移 = 向下滚动**；负值 = 回弹/下拉。
/// 所有换算都把负值当 0 处理 —— 回弹期与"到顶"同口径，不会因为弹性位移多走一段。
enum WDScrollLink {
  /// 把可选 offset 归一为 ≥ 0 的量（nil 由调用方决定不联动；负值按 0）。
  static func clamped(_ scrollOffsetY: CGFloat?) -> CGFloat {
    guard let scrollOffsetY, scrollOffsetY > 0 else { return 0 }
    return scrollOffsetY
  }

  /// 线性进度：offset 从 0 走到 `end` 时 0 → 1，之后封顶 1。
  ///
  /// - Parameter end: 进度走满的 offset（**必须 > 0**；≤ 0 视为立即走满，避免除零）。
  static func progress(scrollOffsetY: CGFloat?, distance: CGFloat) -> CGFloat {
    let offset = clamped(scrollOffsetY)
    guard distance > 0 else { return 1 }
    return min(1, offset / distance)
  }

  /// 淡入量：从 `start` 到 `end` 之间线性 0 → 1（阶梯函数，边界处是跳变而不是线性）。
  ///
  /// 典型用法：导航栏"一离开顶部（offset > 0）就 240ms 交叉淡化成玻璃"—— `start = 0`、
  /// `end` 取一个极小值即可得到阶跃，且仍然落在同一套纯函数里。
  static func ramp(scrollOffsetY: CGFloat?, start: CGFloat, end: CGFloat) -> CGFloat {
    let offset = clamped(scrollOffsetY)
    guard end > start else { return offset > start ? 1 : 0 }
    if offset <= start { return 0 }
    if offset >= end { return 1 }
    return (offset - start) / (end - start)
  }

  /// 同一个量上的双端插值（`from` 在 `start`、`to` 在 `end`；两端之外各自夹住）。
  static func interpolate(
    scrollOffsetY: CGFloat?,
    start: CGFloat,
    end: CGFloat,
    from: CGFloat,
    to: CGFloat
  ) -> CGFloat {
    guard end > start else {
      return clamped(scrollOffsetY) > start ? to : from
    }
    return from + (to - from) * ramp(scrollOffsetY: scrollOffsetY, start: start, end: end)
  }
}
