# B10–B16 接线面（Foundation，**已由协调者落地，实现者只读**）

> **落地状态（2026-11-15）**：以下三个环境键与两个写入口已加在 `Sources/WisdomUI/Foundation/Theme/WDEnvironment.swift` 末尾，`typecheck` / `check-structure --strict` / `check-format` 三绿。
> 最终形态：`wdAnnouncerText` 是 `(@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?` 闭包（不是 `WDTextPlayback` 类型）——`WDTextPlayback` 不需要落地，本节 §1 前半段的 Internal 类型方案作废，以 §1 后半段（闭包形态）为准。

> 目的：组件不能写 Environment（R18），也不宜在 Swift 6 严格并发下直接把非 Sendable 的 `any WDAnnouncing` 存进 `struct View`。本文件冻结本批新增的三个**读取面**与它们的**写入口**；组件只读环境值。

## 1. 播报通道：`wdAnnouncerText`（读）/ `wdAnnouncer(_:)`（写）

```swift
// Internal/WDTextPlayback.swift（Internal；零 public）
/// 已包装的播报通道：把任意 WDAnnouncer 收成 `(Text, 优先级) -> Void`，便于放进 Sendable 环境值。
struct WDTextPlayback: Sendable, Equatable {
  private let handler: @MainActor @Sendable (Text, WDAnnouncementPriority) -> Void
  init(handler: @escaping @MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)
  func post(_ text: Text, priority: WDAnnouncementPriority)
}
```

```swift
// Foundation/Theme/WDEnvironment.swift
extension EnvironmentValues {
  /// 播报通道（组件只读；写入口 = View.wdAnnouncer(_:)）
  public var wdAnnouncerText: WDTextPlayback? { get set }
}

extension View {
  /// 注入播报通道（`@MainActor` 闭包：`nil` = 不播报）。
  public func wdAnnouncer(_ announcer: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)?) -> some View
}
```

组件用法：

```swift
@Environment(\.wdAnnouncerText) private var announcer
// 播报（文案是调用方给的 Text；nil 就不播）
if let announcer, let text = texts?.refreshing {
  announcer.post(text, priority: .polite)
}
```

> ⚠️ **可见性说明**：`WDTextPlayback` 在 Internal/ 里是 `internal`，而 `wdAnnouncerText` 是 Foundation 的 `public` 环境属性 ⇒ 该 public 属性的类型必须是 public。**最终实现取法**：`wdAnnouncerText` 的**返回类型**用 `((Text, WDAnnouncementPriority) -> Void)?` 的 `@MainActor @Sendable` 闭包形态（`WDAnnouncementPriority` 本身是 public），**不暴露 Internal 类型**：

```swift
extension EnvironmentValues {
  /// 播报通道（组件只读）。写入口 = View.wdAnnouncer(_:)
  public var wdAnnouncerText: (@MainActor @Sendable (Text, WDAnnouncementPriority) -> Void)? { get set }
}
```

组件里存成 `let` 局部使用即可（闭包是 `Sendable`，可存进 `struct View` 的属性）。

## 2. 滚动量：`wdScrollOffsetY`（读）/ `wdScrollOffsetY(_:)`（写）

```swift
extension EnvironmentValues {
  /// 宿主的纵向滚动量（pt；向下滚为正）。**nil = 不联动**（默认）。
  public var wdScrollOffsetY: CGFloat? { get set }
}

extension View {
  /// 注入滚动量（调用方从 ScrollView 的 `onScrollGeometryChange` 取 `contentOffset.y` 喂进来）。
  public func wdScrollOffsetY(_ offset: CGFloat?) -> some View
}
```

## 3. 读屏焦点：`wdFocusRingFocused`（只读，**无公开写入口**）

```swift
extension EnvironmentValues {
  /// 读屏焦点是否落在最近一次 `.wdFocusRing()` 标记的节点上（派生态，无写入口）。
  var wdFocusRingFocused: Bool { get set }
}

extension View {
  /// 标记"焦点落点"（`@AccessibilityFocusState` 内部维护；用于手柄光环一类视觉反馈）。
  func wdFocusRing() -> some View
}
```

实现要点：`wdFocusRing()` 内部用 `@AccessibilityFocusState<Bool>`（`Bool` 版本无参，不需要构造 `WDA11yFocusID`），把 `focused` 的值通过 `.onChange(of:)` 写进**本文件私有**的 Environment 键；组件读到 `Bool`。**`onChange(of:)` 仍然写 Environment ⇒ 必须留在 `WDEnvironment.swift` 内部**（R18 的写入口就是本文件）。

## 4. 与组件实现者的分工

- 实现者：**只读**上面三个环境值；不要在组件里新增环境键、不要改本文件的公开面。
- 协调者：本文件的实现与单测（`Tests/WisdomUITests/Foundation/Theme/WDEnvironmentTests.swift` 补充：环境值默认 nil/false、写入口生效、只降不变式）。
