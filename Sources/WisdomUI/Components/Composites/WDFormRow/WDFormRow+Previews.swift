#if WD_PREVIEWS
  import SwiftUI

  private struct WDFormRowPreviewHost: View {
    @State private var name = "整理储物间"
    @State private var enabled = true

    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s5) {
        WDFormRow(label: Text(verbatim: "任务名称")) {
          WDTextField(
            text: $name, label: Text(verbatim: "任务名称"),
            appearance: .init(placeholder: Text(verbatim: "输入任务名称")))
        }
        WDFormRow(
          label: Text(verbatim: "截止日期"),
          helper: Text(verbatim: "最晚今天 18:00"),
          requiredLabel: Text(verbatim: "必填")
        ) {
          Text(verbatim: "明天").wdFont(WDType.subheadline)
        }
        WDFormRow(
          label: Text(verbatim: "成员"),
          error: Text(verbatim: "成员不能为空")
        ) {
          Text(verbatim: "妈妈").wdFont(WDType.subheadline)
        }
        WDFormRow(label: Text(verbatim: "提醒"), layout: .vertical) {
          WDSwitch(isOn: $enabled, label: Text(verbatim: "开启提醒"))
        }
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDFormRow 浅色") {
    WDFormRowPreviewHost()
  }

  #Preview("WDFormRow 深色") {
    WDFormRowPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
