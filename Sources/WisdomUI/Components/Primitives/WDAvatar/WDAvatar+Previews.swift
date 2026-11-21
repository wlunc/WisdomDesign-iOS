#if WD_PREVIEWS
  import SwiftUI

  private struct WDAvatarPreviewHost: View {
    var body: some View {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        // 无 tone（A-11 之前的观感）：surface.tint 底 + text.on-soft 首字。
        HStack(spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "妈")))
          WDAvatar(value: .init(label: Text(verbatim: "明")))
          WDAvatar(value: .init(label: Text(verbatim: "A")))
          WDAvatar(value: .init(icon: .profile))
          WDAvatar(value: .init(icon: .unassigned))
        }
        // 成员四色：底 = fill、首字 = ink（同一句话四个档位，浅/深两外观都由令牌解析）。
        HStack(spacing: WDSpacing.s4) {
          ForEach(WDMemberTone.allCases, id: \.self) { tone in
            WDAvatar(value: .init(label: Text(verbatim: "林")), size: .lg, tone: tone)
          }
        }
        HStack(alignment: .bottom, spacing: WDSpacing.s4) {
          ForEach(WDAvatarSize.allCases, id: \.self) { size in
            WDAvatar(value: .init(label: Text(verbatim: "妈")), size: size, tone: .tone3)
          }
        }
        // 照片形态 + 回退内容（照片不可用时退回文字/图标；这里用 SF Symbol 当图片源）。
        HStack(alignment: .bottom, spacing: WDSpacing.s4) {
          WDAvatar(
            value: .init(image: Image(systemName: "photo.artframe"), label: Text(verbatim: "林")),
            size: .xl, tone: .tone2)
          WDAvatar(
            value: .init(image: Image(systemName: "photo.artframe"), label: Text(verbatim: "林")),
            size: .xl, tone: .tone2, hostColor: WDColor.bgCanvas)
        }
        HStack(alignment: .bottom, spacing: WDSpacing.s4) {
          WDAvatar(value: .init(label: Text(verbatim: "林")), size: .lg, isOnline: true)
          WDAvatar(value: .init(label: Text(verbatim: "B")), size: .lg, isDisabled: true)
          WDAvatar(
            value: .init(label: Text(verbatim: "林")), size: .lg, isOnline: true, tone: .tone4)
        }
      }
      .padding(WDSpacing.s5)
    }
  }

  #Preview("WDAvatar 浅色") {
    WDAvatarPreviewHost()
  }

  #Preview("WDAvatar 深色") {
    WDAvatarPreviewHost()
      .preferredColorScheme(.dark)
  }
#endif
