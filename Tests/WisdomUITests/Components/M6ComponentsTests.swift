import SwiftUI
import Testing
import UIKit

@testable import WisdomUI

/// M6 场景组件的结构断言（尺寸 / 溢出 / 选中可见性 / 位置朗读；不含动画与真实点击）。
@MainActor
@Suite("M6 场景组件")
struct M6ComponentsTests {
  private func size<V: View>(_ view: V, width: CGFloat = 360) -> CGSize {
    let controller = UIHostingController(rootView: view)
    return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
  }

  private func items(_ count: Int, disabledIndex: Int? = nil) -> [WDAssigneePickerItem] {
    (1...count).map { index in
      WDAssigneePickerItem(
        id: "m\(index)",
        avatar: WDAvatarValue(label: Text(verbatim: "\(index)")),
        accessibilityLabel: Text(verbatim: "成员\(index)"),
        name: Text(verbatim: "成员\(index)"),
        isEnabled: disabledIndex != index,
        unavailableReason: disabledIndex == index ? Text(verbatim: "已离开") : nil
      )
    }
  }

  @Test("档位：头像 40 / 32，选中外环 52 / 44（设计 37 §3/§4）")
  func metrics() {
    let standard = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(2))
    let compact = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(2),
      size: .compact)

    #expect(standard.avatarDiameter == WDSize.avatarLg)
    #expect(standard.outerDiameter == standard.avatarDiameter + 12)
    #expect(compact.avatarDiameter == WDSize.avatarMd)
    #expect(compact.outerDiameter == compact.avatarDiameter + 12)
    #expect(standard.avatarDiameter > compact.avatarDiameter)
  }

  @Test("最多直接显示 6 个（含未指派），超出 +n")
  func overflow() {
    let six = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(6))
    #expect(six.visibleMembers.count == 6)
    #expect(six.hiddenCount == 0)

    let eight = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(8))
    #expect(eight.visibleMembers.count == 6)
    #expect(eight.hiddenCount == 2)

    let withUnassigned = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(8),
      unassigned: .init(label: Text(verbatim: "未指派"), accessibilityLabel: Text(verbatim: "未指派")))
    #expect(withUnassigned.visibleMembers.count == 5)
    #expect(withUnassigned.hiddenCount == 3)
  }

  @Test("选中项在窗口外时替换进第 6 位（D9）")
  func selectedStaysVisible() {
    let picker = WDAssigneePicker(
      selection: .constant("m8" as String?), label: Text(verbatim: "指派给"), items: items(8))
    #expect(picker.visibleMembers.count == 6)
    #expect(picker.visibleMembers.contains { $0.id == "m8" })
    #expect(picker.visibleMembers.last?.id == "m8")
  }

  @Test("位置朗读闭包按 (index, total) 给值；未指派计为第 1 项")
  func positionText() {
    let picker = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(4),
      unassigned: .init(label: Text(verbatim: "未指派"), accessibilityLabel: Text(verbatim: "未指派")),
      positionText: { index, total in Text(verbatim: "\(index)/\(total)") })
    #expect(picker.positionValue(1) == Text(verbatim: "1/5"))
    #expect(picker.positionValue(5) == Text(verbatim: "5/5"))

    let plain = WDAssigneePicker(
      selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(2))
    #expect(plain.positionValue(1) == Text(verbatim: ""))
  }

  @Test("高度：标准含名字高于紧凑；紧凑仍 ≥ 44 热区")
  func heights() {
    let standard = size(
      WDAssigneePicker(
        selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(3)))
    let compact = size(
      WDAssigneePicker(
        selection: .constant(nil as String?), label: Text(verbatim: "指派给"), items: items(3),
        size: .compact))
    #expect(standard.height > compact.height)
    #expect(compact.height >= WDSize.touchTargetMin)
  }

  @Test("枚举 case 与契约一致")
  func enums() {
    #expect(WDAssigneePickerSize.allCases.map(\.rawValue) == ["standard", "compact"])
  }

  @Test("单选 / 多选两个 init 都可构造；禁用项构造稳定")
  func initializers() {
    var single: String? = "m1"
    var multi: Set<String> = ["m1"]
    let singleBinding = Binding(get: { single }, set: { single = $0 })
    let multiBinding = Binding(get: { multi }, set: { multi = $0 })
    _ = WDAssigneePicker(
      selection: singleBinding, label: Text(verbatim: "指派给"), items: items(3, disabledIndex: 2))
    _ = WDAssigneePicker(
      selection: multiBinding, label: Text(verbatim: "参与人"), items: items(3),
      size: .compact, onOverflowTap: {}, overflowAccessibilityLabel: Text(verbatim: "查看全部"))
    #expect(single == "m1")
    #expect(multi == ["m1"])
  }
}
