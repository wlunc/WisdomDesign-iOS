#if WD_PREVIEWS
  import SwiftUI

  /// 预览宿主：`@State` 绑定需要宿主视图（`#Preview` 里不直接建 `Binding`）。
  private struct WDTextFieldPreviewHost: View {
    @State private var text = ""
    @State private var secureText = ""

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: WDSpacing.s5) {
          WDTextField(
            text: $text,
            label: Text("任务名称"),
            appearance: .init(placeholder: Text("例如 整理储物间"))
          )

          WDTextField(
            text: $text,
            label: Text("日期"),
            appearance: .init(
              variant: .outline,
              prefix: .icon(.calendar),
              accessory: .clear(accessibilityLabel: Text("清除内容"))
            )
          )

          WDTextField(
            text: $text,
            label: Text("预算"),
            appearance: .init(
              variant: .glass,
              prefix: .text(Text(verbatim: "USD")),
              accessory: .unit(Text(verbatim: "100"))
            )
          )

          WDTextField(
            text: $secureText,
            label: Text("密码"),
            appearance: .init(
              accessory: .reveal(
                hiddenAccessibilityLabel: Text("显示密码"),
                shownAccessibilityLabel: Text("隐藏密码")
              ),
              isSecure: true
            )
          )

          WDTextField(
            text: $text,
            label: Text("任务名称"),
            appearance: .init(
              accessory: .count(current: 9, limit: 10),
              helper: .error(Text("名称已被占用"))
            )
          )

          WDTextField(
            text: .constant("只读内容"),
            label: Text("只读"),
            appearance: .init(variant: .outline),
            isEditable: false
          )

          WDTextField(text: $text, label: Text("禁用"))
            .disabled(true)
        }
        .padding(WDSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  #Preview("WDTextField 浅色") {
    WDTextFieldPreviewHost()
  }

  #Preview("WDTextField 深色") {
    WDTextFieldPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
