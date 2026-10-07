import SwiftUI
import Testing
import WisdomUIPreviews

/// M1 六（八）态快照：令牌与字阶画廊 × 浅/深 × 默认/AX3 × LTR/RTL。
///
/// UIHostingController / ImageRenderer / sizeThatFits 必须主线程串行（SPEC §1.6 的 F2.3）
/// ⇒ suite 加 `.serialized` + `MainActor`。
@MainActor
@Suite("六（八）态快照", .serialized)
struct WDGallerySnapshotTests {
  static let typographySize = CGSize(width: 360, height: 640)
  static let slotsSize = CGSize(width: 360, height: 760)

  @Test("字阶画廊：8 态基线一致（缺失 = fail）")
  func typographyGallery() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "typography-\(state.id)",
        view: WDTypographyGallery(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.typographySize
      )
    }
  }

  @Test("槽位画廊：8 态基线一致（缺失 = fail）")
  func slotGallery() {
    for state in SnapshotSupport.matrix {
      SnapshotSupport.verify(
        name: "slots-\(state.id)",
        view: WDSlotGallery(values: SnapshotSupport.values(for: state)),
        state: state,
        size: Self.slotsSize
      )
    }
  }

  @Test("渲染器表：玻璃类 6 个必须走 drawHierarchy（E6 显式表）")
  func rendererTable() {
    #expect(SnapshotSupport.glassComponents.count == 6)
    for component in SnapshotSupport.glassComponents {
      #expect(SnapshotSupport.requiresHierarchyRenderer(component))
    }
    #expect(!SnapshotSupport.requiresHierarchyRenderer("WDButton"))
  }

  @Test("矩阵是 8 态而不是 6 态（文档计数偏差已登记）")
  func matrixSize() {
    #expect(SnapshotSupport.matrix.count == 8)
    #expect(Set(SnapshotSupport.matrix.map(\.id)).count == 8)
  }
}
