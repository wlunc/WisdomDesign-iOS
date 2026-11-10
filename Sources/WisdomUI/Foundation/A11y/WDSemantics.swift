import SwiftUI

/// 语义拼接原语：**只做结构**（零标点、零语序、零状态文案；B2/D5）。
///
/// 读屏结果由调用方拼好再读，库不提供任何默认分隔符或词序模板：
///   · `join`：把各块按 `separator` 串起来（分隔符由调用方给）；
///   · `positional`：把 `positionText` 放在 `label` 之后（顺序是结构，不是语序）。
///
/// 测试口径（SPEC §2.6.2）：用非中文分隔符（`"|"`、`"／"`）断言，从测试侧证明库内没有默认分隔符。
public enum WDSemantics {
  /// 按 `separator` 拼接文本块。
  ///
  /// - 空数组 ⇒ 空文本（`Text(verbatim: "")`）；
  /// - 不做空块剔除（`Text` 无法取串；调用方要剔除时用 `[String]` 重载）。
  public static func join(_ parts: [Text], separator: Text) -> Text {
    guard let first = parts.first else { return Text(verbatim: "") }
    return parts.dropFirst().reduce(first) { partial, next in
      partial + separator + next
    }
  }

  /// 位置措辞（措辞与分隔符均由调用方给）。
  public static func positional(label: Text, positionText: Text, separator: Text) -> Text {
    label + separator + positionText
  }

  /// 纯逻辑重载（供两端 fixtures）。
  ///
  /// 空串按 Android 侧同口径剔除（`filter { it.isNotEmpty() }`），保证两端拼接结果逐字一致。
  public static func join(_ parts: [String], separator: String) -> String {
    parts.filter { !$0.isEmpty }.joined(separator: separator)
  }
}
