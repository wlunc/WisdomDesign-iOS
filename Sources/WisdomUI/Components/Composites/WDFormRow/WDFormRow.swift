import SwiftUI

/// 表单项排布（设计 24 §4：左右 / 上下）。
public enum WDFormRowLayout: String, CaseIterable, Sendable, Equatable {
  /// 标签居左、控件居右（控件窄时）。
  case horizontal
  /// 标签在上、控件在下并全宽（控件宽时）。
  case vertical
}

/// 表单行（SPEC §2.10-#24；M5）。
///
/// 设计口径（设计 24）：
/// - 行最小高 **44**；标签 `subheadline` 15（text.primary）；说明/错误 `footnote` 13；
/// - 标签与控件间距 12；错误文字**替换**说明文字，不叠加；
/// - 左右排布时标签列宽 **96**，AX 字号下自动改为上下排布（U7 降级规则 1）；
/// - 错误态把错误文案挂在控件的 `accessibilityHint` 上（库内零文案，文案由调用方给）；
/// - 必填标记由调用方给 `requiredLabel`（如「必填」），不靠颜色/星号。
public struct WDFormRow<Control: View>: View {
  private let label: Text
  private let layout: WDFormRowLayout
  private let helper: Text?
  private let error: Text?
  private let requiredLabel: Text?
  private let control: Control

  @Environment(\.wdColors) private var colors
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  /// 构造：标签 + 排布 + 说明/错误/必填 + 控件。
  public init(
    label: Text,
    layout: WDFormRowLayout = .horizontal,
    helper: Text? = nil,
    error: Text? = nil,
    requiredLabel: Text? = nil,
    @ViewBuilder control: () -> Control
  ) {
    self.label = label
    self.layout = layout
    self.helper = helper
    self.error = error
    self.requiredLabel = requiredLabel
    self.control = control()
  }

  /// 排布（AX 字号下横向自动降级为上下）+ 说明/错误。
  public var body: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      if usesVerticalLayout {
        verticalContent
      } else {
        horizontalContent
      }
      messageView
    }
    .frame(minHeight: WDSize.touchTargetMin, alignment: .leading)
    .opacity(isEnabled ? 1 : disabledOpacity)
    .animation(.easeOut(duration: WDMotion.Duration.fast), value: hasError)
  }

  // MARK: - 排布

  private var horizontalContent: some View {
    HStack(alignment: .center, spacing: WDSpacing.s4) {
      labelView
        .frame(minWidth: WDFormRowMetrics.labelColumnWidth, alignment: .leading)
      Spacer(minLength: WDSpacing.s3)
      controlView
    }
  }

  private var verticalContent: some View {
    VStack(alignment: .leading, spacing: WDSpacing.s2) {
      labelView
      controlView
    }
  }

  private var labelView: some View {
    HStack(spacing: WDSpacing.s1) {
      label
        .wdFont(WDType.subheadline)
        .wdLineBox(WDType.subheadline)
        .foregroundStyle(colors.textPrimary)
        .lineLimit(1)
        .accessibilityAddTraits(.isHeader)
      if let requiredLabel {
        requiredLabel
          .wdFont(WDType.footnote)
          .wdLineBox(WDType.footnote)
          .foregroundStyle(colors.statusDanger)
      }
    }
  }

  /// 控件；错误态把错误文案挂成 hint（读屏先读标签再读控件）。
  private var controlView: some View {
    Group {
      if let error {
        control.accessibilityHint(error)
      } else {
        control
      }
    }
  }

  @ViewBuilder private var messageView: some View {
    if let error {
      error
        .wdFont(WDType.footnote)
        .wdLineBox(WDType.footnote)
        .foregroundStyle(colors.statusDanger)
    } else if let helper {
      helper
        .wdFont(WDType.footnote)
        .wdLineBox(WDType.footnote)
        .foregroundStyle(colors.textSecondary)
    }
  }

  // MARK: - 状态/几何

  private var usesVerticalLayout: Bool {
    layout == .vertical || dynamicTypeSize.isAccessibilitySize
  }

  private var hasError: Bool {
    error != nil
  }

  /// 禁用态整体不透明度（`state.disabled.alpha` = 40，百分数换算）。
  private var disabledOpacity: CGFloat {
    WDState.disabledAlpha / 100  // wd-structure-check:disable R7 — 百分数分母
  }

}

/// 表单项几何（泛型类型不能有静态存储属性 ⇒ 放在非泛型容器）。
private enum WDFormRowMetrics {
  /// 标签列宽 96（设计 24 §3）。
  static let labelColumnWidth: CGFloat = 96  // wd-structure-check:disable R7 — 设计值
}
