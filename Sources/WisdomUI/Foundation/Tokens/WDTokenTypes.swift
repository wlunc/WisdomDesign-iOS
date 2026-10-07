import SwiftUI

// 生成代码引用的基础类型与修饰符。手写文件，不属于生成产物。

/// 一个字阶的完整描述。
public struct WDTextStyle: Sendable {
    public let size: CGFloat
    public let lineHeight: CGFloat
    public let weight: Font.Weight

    public init(size: CGFloat, lineHeight: CGFloat, weight: Font.Weight) {
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
    }

    /// 行高比由设计决定，不交给系统默认。
    public var font: Font {
        .system(size: size, weight: weight)
    }

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
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let color: Color

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
        layers.reduce(AnyView(self)) { view, layer in
            AnyView(
                view.shadow(
                    color: layer.color,
                    radius: layer.blur / 2,
                    x: layer.x,
                    y: layer.y
                )
            )
        }
    }
}

/// 渐变描述。角度沿用 CSS 口径（0° 向上，顺时针），由各平台换算成自己的坐标系。
public struct WDGradientSpec: Sendable {
    public let angleDegrees: Double
    public let stops: [(color: Color, location: Double)]

    public init(angleDegrees: Double, stops: [(color: Color, location: Double)]) {
        self.angleDegrees = angleDegrees
        self.stops = stops
    }

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
