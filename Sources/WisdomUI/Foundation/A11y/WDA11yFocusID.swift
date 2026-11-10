/// 无障碍焦点身份（`@AccessibilityFocusState` 需要 `Hashable` ⇒ 不能用 `Text`；SPEC §2.6.2 / I40）。
///
/// 说明：本类型按 SPEC 的冻结形态落地 —— **只有公开只读属性、没有公开构造器**；
/// 实例由库内组件（弹层/行等）产出并交给调用方做焦点比较。若后续需要调用方自造 ID，
/// 属签名变更，须先走 SPEC/契约流程（见 `docs/DEV-PLAN.md` §2.3 的登记）。
public struct WDA11yFocusID: Hashable, Sendable {
  /// 原始值。
  public let rawValue: String
}
