# M4 批前签名冻结（9 件）—— 草案，待确认

> 用途：满足 I-2（批前签名冻结）。M4 = 反馈与弹层 9 件（`docs/DEV-PLAN.md` §2.5）。
> 日期：**2026-11-12**｜状态：**草案（待项目负责人确认）**｜依据：`docs/SPEC.md` §2.5/§2.10、设计仓
> `specs/01-basic.md` #15/#16、`specs/02-advanced.md` #25–#31、`docs/DEV-PLAN.md` §21.6 的 M4 十问。
> **未确认前不得开写**；确认后本文件转为 `已冻结`，并回填 9 个 `../wisdomdesign/contracts/*.yaml`。

## 1. 入口判据（I-1…I-5）

| # | 判据 | 现状 |
| --- | --- | --- |
| I-1 | 上一里程碑出口已判定 | ✅ M3 已判定通过（2026-11-12；nightly 门禁由项目负责人决定豁免） |
| I-2 | 9 件签名 + 契约入库 | **本文件 + 9 个 yaml（待确认后回填）** |
| I-3 | 令牌/契约已冻结 | ✅ `schemes` / 32 槽位 / 玻璃档位 / 效果配额 7 条已生效 |
| I-4 | 门禁可跑且绿 | ✅ `ci.sh pr` 全绿（`--strict` + 覆盖率门槛 + 661 符号零 diff） |
| I-5 | 未闭合前置有默认执行项 | ✅ 见 §5 的 Q1–Q4 |

## 2. 拟冻结签名（推荐值）

### 2.1 弹层（`WDBottomSheet` / `WDActionSheet` / `WDAlert` / `WDToast`）

```swift
public enum WDBottomSheetDetent: String, CaseIterable, Sendable, Equatable { case half, large }
public enum WDBottomSheetDetents: Sendable, Equatable { case all; case fixed(WDBottomSheetDetent) }

extension View {
  public func wdSheet<Content: View, Footer: View>(
    isPresented: Binding<Bool>,
    detents: WDBottomSheetDetents = .all,
    initialDetent: WDBottomSheetDetent = .half,
    interactiveDismissDisabled: Bool = false,
    title: Text? = nil,
    closeButtonAccessibilityLabel: Text,
    onCloseButtonTap: (() -> Void)? = nil,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content,
    @ViewBuilder footer: () -> Footer
  ) -> some View
}

public struct WDActionSheetItem: Identifiable, Sendable, Equatable {
  public enum Role: Sendable, Equatable { case `default`, destructive, cancel }
  public let id: String
  public let label: Text
  public let role: Role
  public init(id: String, label: Text, role: Role = .default)
}

extension View {
  public func wdActionSheet(
    isPresented: Binding<Bool>,
    title: Text? = nil,
    message: Text? = nil,
    items: [WDActionSheetItem],
    onSelect: @escaping (WDActionSheetItem.ID) -> Void,
    onCancel: (() -> Void)? = nil
  ) -> some View
}

public struct WDAlertAction {
  public enum Role: Sendable, Equatable { case `default`, cancel, destructive }
  public let label: Text
  public let role: Role
  public let action: () -> Void
  public init(label: Text, role: Role = .default, action: @escaping () -> Void)
}

extension View {
  /// 双按钮 / 单按钮 / 危险按钮。
  public func wdAlert(
    isPresented: Binding<Bool>,
    title: Text,
    message: Text? = nil,
    actions: [WDAlertAction],
    onDismiss: (() -> Void)? = nil
  ) -> some View

  /// 带输入变体（Q3）。
  public func wdAlert<Content: View>(
    isPresented: Binding<Bool>,
    title: Text,
    message: Text? = nil,
    actions: [WDAlertAction],
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) -> some View
}

public enum WDToastVariant: String, CaseIterable, Sendable, Equatable {
  case neutral, success, warning, danger
}
public struct WDToastAction {
  public let label: Text
  public let action: () -> Void
  public init(label: Text, action: @escaping () -> Void)
}

extension View {
  public func wdToast(
    isPresented: Binding<Bool>,
    variant: WDToastVariant = .neutral,
    message: Text,
    action: WDToastAction? = nil,
    durationMilliseconds: Int = 3000,
    onDismiss: (() -> Void)? = nil
  ) -> some View
}
```

### 2.2 反馈与占位（`WDBanner` / `WDEmptyState` / `WDSkeleton`）

```swift
public enum WDBannerVariant: String, CaseIterable, Sendable, Equatable {
  case info, warning, danger     // Q1：设计稿另有 success；推荐按 C-15/U2 只冻结 3 个
}
public struct WDBannerAction {
  public let label: Text
  public let action: () -> Void
  public init(label: Text, action: @escaping () -> Void)
}

public struct WDBanner: View {
  public init(
    isVisible: Binding<Bool>,
    variant: WDBannerVariant = .info,
    message: Text,
    action: WDBannerAction? = nil,
    dismissAccessibilityLabel: Text? = nil   // 非 nil ⇒ 显示关闭键
  )
}

public struct WDEmptyStateAction {
  public let label: Text
  public let isLoading: Bool
  public let action: () -> Void
  public init(label: Text, isLoading: Bool = false, action: @escaping () -> Void)
}

public struct WDEmptyState: View {
  public init(
    icon: WDIconName? = nil,
    title: Text,
    message: Text? = nil,
    action: WDEmptyStateAction? = nil
  )
}

public enum WDSkeletonVariant: String, CaseIterable, Sendable, Equatable { case text, list, card }

public struct WDSkeleton: View {
  public init(variant: WDSkeletonVariant = .text, lineCount: Int = 3)
}
```

### 2.3 进度（`WDProgressBar` / `WDProgressRing`）

```swift
public struct WDProgressBar: View {
  /// 确定态：value 钳制到 0...1；valueText 由调用方给（"45%" / "3 / 5"）。
  public init(value: Double, label: Text? = nil, valueText: Text? = nil)
  /// 不确定态：不提供 valuenow，朗读"加载中"。
  public init(label: Text? = nil, valueText: Text? = nil)
}

public enum WDProgressRingSize: String, CaseIterable, Sendable, Equatable { case standard, compact }

public struct WDProgressRing: View {
  public init(
    value: Double,
    size: WDProgressRingSize = .standard,
    label: Text? = nil,
    valueText: Text? = nil
  )
}
```

## 3. 契约条目（确认后回填 `../wisdomdesign/contracts/`）

| 组件 | 受控值（C-15 canonical） | `slots` | `default` | 枚举 |
| --- | --- | --- | --- | --- |
| `WDBottomSheet` | `presented` / `isPresented` | `title`,`content`,`footer` | `detents = .all`、`initialDetent = .half`、`interactiveDismissDisabled = false` | `WDBottomSheetDetent`(half,large)/`WDBottomSheetDetents`(all,fixed) |
| `WDActionSheet` | `presented` / `isPresented` | `title`,`message`,`items` | `title/message/onCancel = nil` | `WDActionSheetItem.Role`(default,destructive,cancel) |
| `WDAlert` | `presented` / `isPresented` | `title`,`message`,`actions` | `message/onDismiss = nil` | `WDAlertAction.Role`(default,cancel,destructive) |
| `WDToast` | `presented` / `isPresented` | `message`,`actions` | `variant = .neutral`、`action = nil`、`durationMilliseconds = 3000` | `WDToastVariant`(neutral,success,warning,danger) |
| `WDBanner` | `visible` / `isVisible` | `message`,`actions` | `variant = .info`、`action/dismissAccessibilityLabel = nil` | `WDBannerVariant`(info,warning,danger)（Q1） |
| `WDEmptyState` | — | `title`,`message`,`actions` | `icon/message/action = nil` | — |
| `WDSkeleton` | — | 无 | `variant = .text`、`lineCount = 3` | `WDSkeletonVariant`(text,list,card) |
| `WDProgressBar` | `value` | `label`,`valueText` | `label/valueText = nil`（不确定态用无 value 的重载） | — |
| `WDProgressRing` | `value` | `label`,`valueText` | `size = .standard`、`label/valueText = nil` | `WDProgressRingSize`(standard,compact) |

> 槽位全部 ⊆ 21 名词表；`WDSkeleton` 无槽位写「无」。`params[].name` 的受控值取 canonical；iOS 形参名另记。

## 4. 验证计划（冻结后执行）

1. `Scripts/dump-api.sh`：新增符号与冻结表逐字一致；API 基线随成因提交。
2. 单测：进度钳制 0/1/越界、Alert 按钮顺序/禁用防重、ActionSheet 空 items 断言、Toast 时长下限/操作态 ≥5000、Banner 关闭控件、Skeleton 只播报一次。
3. 快照：9 件 × 8 态；玻璃类 `WDBottomSheet`/`WDActionSheet` 用 `UIHostingController`+`drawHierarchy`。
4. 无障碍：demo 审计视口扩到 21 件；Alert/BottomSheet/ActionSheet 的焦点陷阱与归还（`WDA11yFocusID`）。
5. 效果配额 7 条：每条的计数/降级断言；"同屏模糊面可数"。
6. 对比度：每套 scheme 的最不利取色账目；玻璃档位矩阵（含两条"必须红"用例）。
7. 性能：9 件渲染耗时进 M4 出口报告（只报不拦）。

## 5. 需要拍板的 4 个点

| # | 问题 | 推荐 | 备选/代价 |
| --- | --- | --- | --- |
| **Q1** | `WDBannerVariant` 是 3 个还是 4 个？ | **3 个**（info/warning/danger，与 C-15/U2 的 Android 集合一致） | 加 `success`（设计 §4 有）⇒ 跨端 U 项不一致，且新增 case 属源级 breaking；需先改 C-15/Android 契约 |
| **Q2** | Toast 自动消失的计时归谁？ | **组件内 `.task` 结构化计时**（`durationMilliseconds`，随视图消失取消；把"组件自建计时器"的禁令限定为 `Timer`/`DispatchQueue` 泄漏） | 调用方计时 ⇒ 组件只做展示，但 3s/5s 语义要调用方重复实现，且"悬停暂停"难保证 |
| **Q3** | Alert 的"带输入"变体现在做吗？ | **做**：第二个 `content` 重载（设计 §4 的第 4 变体） | 延后 ⇒ 需登记差异，M4 只做 3 变体 |
| **Q4** | ProgressBar 的"分段"变体现在做吗？ | **暂不做**（§21.6 的十问只要求确定/不确定；分段用 `valueText` 调 `WDProgressBar` 之外组合） | 做 ⇒ 需要 `segments/completed` 参数，API 面变大；设计 §4 有该变体 |

> 其余实现细节（Alert 自绘 270 卡片 vs 系统 `.alert`、Toast 挂 window vs 锚点 overlay、Skeleton `lineCount` 命名）
> 按"设计保真优先 + 系统能力可用"处理，不单列拍板项；落地时在 PR 描述登记。

## 6. 确认与合并记录

| 项 | 值 |
| --- | --- |
| 确认人 | 待项目负责人 |
| 日期 | 待定 |
| 结论 | 待定（Q1–Q4） |
| 后续 | 确认后：回填 9 个 yaml → 实现 → PR/nightly → M4 出口报告 |
