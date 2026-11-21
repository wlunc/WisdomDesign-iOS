import SwiftUI

/// 卡片顶部图片带的载荷（设计 14 §2；A-13）。
///
/// 库里**不做异步加载**（零资源 / 零网络 / 零第三方依赖）："就绪"由调用方判定 ——
/// 拿得到图就构造 `WDCardMedia`，拿不到就不构造（`media: nil` 或 `image: nil`），
/// 渲染直接落到灰底占位档。这条分工一次解决设计 §2.3 的三个硬要求：
/// - **无骨架、无微光**：卡片不是列表加载态，没有 URL 就没有"加载中"的中间态；
/// - **不出破图**：破图只来自"取图失败后仍画 image 框"，这里没有那个框；
/// - **不留白**：灰底（`surface.card-sunken`）由组件兜底，调用方不传图也在。
///
/// 图片默认**装饰性**（`accessibilityHidden(true)`，设计 §2.5）：`media` 卡的图片是引子，
/// 信息在文字区。例外：图片本身是内容（相册缩略等）时由调用方给 `accessibilityLabel`，
/// 此时图片进无障碍树。
public struct WDCardMedia: Sendable {
  /// 已就绪的图片；`nil` = 灰底占位（加载中 / 失败 / 无图共用同一档，设计 §2.3）。
  let image: Image?
  /// 图片的读屏文本；`nil` = 装饰性（默认，不进无障碍树）。
  let accessibilityLabel: Text?

  /// 图片带：就绪图（或 `nil` 占位）+ 可选读屏文本。
  public init(_ image: Image?, accessibilityLabel: Text? = nil) {
    self.image = image
    self.accessibilityLabel = accessibilityLabel
  }
}
