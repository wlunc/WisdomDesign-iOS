import Foundation

/// 预览与快照用的**样例文本**（**零业务语义**：不定义任何业务模型，SPEC §1.6）。
///
/// 只提供中英双语的最小语料：CJK 用来暴露自然行高（PingFang SC ≈ 1.400em），
/// 拉丁用来对照主字体行盒（SF Pro ≈ 1.178em）。
public enum WDSampleData {
  /// 中文短句（单行）。
  public static let zh = "示例文本一二三"
  /// 英文短句（单行）。
  public static let en = "Sample text"
  /// 中文长句（多行换行用）。
  public static let zhLong = "示例文本一二三\n示例文本四五六"
  /// 英文长句（多行换行用）。
  public static let enLong = "Sample text line one\nSample text line two"
}
