import SwiftUI

// 生成代码引用的基础类型与修饰符。手写文件，不属于生成产物。
// 位置口径：Foundation/Tokens/（docs/SPEC.md §1.1 的层内目录；I-M0-h 落点）。

/// 一个字阶的完整描述（**4 存储字段**；M0-1 冻结，见 docs/SPEC.md §2.1）。
///
/// §2.1 的两个「手写派生」里，`textStyle` 属 `Foundation/Typography/WDTypographyMapping.swift`
///（12 条映射，M1 字阶层）；本文件只放不需要映射表的 `lineHeightRatio`。
public struct WDTextStyle: Sendable, Equatable {
  /// 字号（pt）。
  public let size: CGFloat
  /// 设计行高（pt，总行盒高）。
  public let lineHeight: CGFloat
  /// 字重。
  public let weight: Font.Weight
  /// 字距（pt；令牌缺该字段时生成器 emit 0）。
  public let letterSpacing: CGFloat

  /// 构造：字号 + 行高 + 字重 + 字距。
  /// **internal**（O-10）：外部不构造字阶，只用 `WDType.*` 常量（生成物）。
  internal init(size: CGFloat, lineHeight: CGFloat, weight: Font.Weight, letterSpacing: CGFloat) {
    self.size = size
    self.lineHeight = lineHeight
    self.weight = weight
    self.letterSpacing = letterSpacing
  }

  /// 行高比（派生只读；不进令牌——真源保留绝对值）。
  public var lineHeightRatio: CGFloat {
    lineHeight / size
  }

  /// 行高对应的字体（行高比由设计决定，不交给系统默认）。
  public var font: Font {
    .system(size: size, weight: weight)
  }

  /// 行间距 = 行高 − 字号（不为负）。
  public var lineSpacing: CGFloat {
    max(0, lineHeight - size)
  }
}

extension WDTextStyle {
  /// 直接以设计字阶渲染文字。
  public func text(_ value: String) -> some View {
    Text(value)
      .font(font)
      .lineSpacing(lineSpacing)
  }
}

/// 一层阴影。
public struct WDShadowLayer: Sendable {
  /// 水平偏移（pt）。
  public let x: CGFloat
  /// 垂直偏移（pt）。
  public let y: CGFloat
  /// 模糊半径（pt）；渲染按 `radius: blur / 2` 折算。
  public let blur: CGFloat
  /// 阴影颜色（含透明度）。
  public let color: Color

  /// 构造：偏移 + 模糊半径 + 颜色。
  public init(x: CGFloat, y: CGFloat, blur: CGFloat, color: Color) {
    self.x = x
    self.y = y
    self.blur = blur
    self.color = color
  }
}

extension View {
  /// 叠加一层或多层阴影。高度令牌是双层（环境光 + 主光），逐层叠加而不是取最大那层。
  public func wdShadow(_ layers: [WDShadowLayer]) -> some View {
    modifier(WDShadowStack(layers: layers[...]))
  }
}

/// 逐层叠加阴影的递归修饰符。
/// 用 `ViewModifier` 递归替代 `AnyView` 擦除（R13a 禁 AnyView：类型擦除破坏 diff 与性能）；
/// 公开签名 `wdShadow(_:)` 不变。
private struct WDShadowStack: ViewModifier {
  let layers: ArraySlice<WDShadowLayer>

  @ViewBuilder
  func body(content: Content) -> some View {
    if let layer = layers.first {
      content
        .shadow(
          color: layer.color,
          radius: layer.blur / 2,
          x: layer.x,
          y: layer.y
        )
        .modifier(WDShadowStack(layers: layers.dropFirst()))
    } else {
      content
    }
  }
}

/// 渐变描述。角度沿用 CSS 口径（0° 向上，顺时针），由各平台换算成自己的坐标系。
public struct WDGradientSpec: Sendable {
  /// CSS 口径角度（0° 指向正上方，顺时针增加）。
  public let angleDegrees: Double
  /// 色标（颜色 + 位置 0…1）。
  public let stops: [(color: Color, location: Double)]

  /// 构造：角度 + 色标。
  public init(angleDegrees: Double, stops: [(color: Color, location: Double)]) {
    self.angleDegrees = angleDegrees
    self.stops = stops
  }

  /// 由色标换算出的 SwiftUI 线性渐变。
  public var linearGradient: LinearGradient {
    LinearGradient(
      stops: stops.map { .init(color: $0.color, location: $0.location) },
      startPoint: startPoint,
      endPoint: endPoint
    )
  }

  // CSS 角度：0° 指向正上方，顺时针增加
  private var unitVector: (dx: Double, dy: Double) {
    let radians = (angleDegrees - 90) * .pi / 180
    return (cos(radians), sin(radians))
  }

  private var startPoint: UnitPoint {
    let v = unitVector
    return UnitPoint(x: 0.5 - v.dx / 2, y: 0.5 - v.dy / 2)
  }

  private var endPoint: UnitPoint {
    let v = unitVector
    return UnitPoint(x: 0.5 + v.dx / 2, y: 0.5 + v.dy / 2)
  }
}
