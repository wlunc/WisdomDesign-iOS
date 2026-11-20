# B18 批前签名冻结 —— 代码欠账收口（2026-11-20）

> **依据**：项目负责人 2026-11-20「补上代码欠账」；清单 = `docs/DEBT-LEDGER.md` §1 的 A 类。
> **授权口径**：延续 B7/B8/B10/B17 的「允许扩公开」——**只增不改**（既有 init / 默认值 / 类型一律保留）。
> **口径来源**：设计 01 §5、02 §5、06 §5、08 §5/§10、15 §10、34 §10；`docs/SPEC.md` §2.10 的播报列。

---

## 1. 公开签名增量（只增不改）

```swift
// ── WDSlider（Primitives）───────────────────────────────────────────────────
extension WDSlider {
  // 既有单值完整构造末尾追加（旧调用点源码零改动）。
  public init(
    value: Binding<Double>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil,
    showsValueLabel: Bool = false,
    valueText: ((Double) -> Text)? = nil,
    announcementText: ((Double) -> Text)? = nil   // ← B18 新增（松手播报文案）
  )

  // 既有范围构造末尾追加。
  public init(
    range: Binding<ClosedRange<Double>>,
    label: Text,
    in bounds: ClosedRange<Double> = 0...1,
    step: Double? = nil,
    onEditingChanged: ((Bool) -> Void)? = nil,
    showsValueLabel: Bool = false,
    rangeText: ((ClosedRange<Double>) -> Text)? = nil,
    lowerAccessibilityLabel: Text? = nil,
    upperAccessibilityLabel: Text? = nil,
    rangeAnnouncementText: ((ClosedRange<Double>) -> Text)? = nil  // ← B18 新增
  )
}

// ── WDButtonStyle（公开 ButtonStyle）────────────────────────────────────────
extension WDButtonStyle {
  public init(
    variant: WDButtonVariant = .filled,
    size: WDButtonSize = .md,
    isLoading: Bool = false,
    isFocused: Bool = false        // ← B18 新增（聚焦光环）
  )
  static func dimOpacity(forBrightness: CGFloat) -> CGFloat   // 内部换算，供单测
}
```

**零签名变化的实现补齐**（无公开面变更）：`WDIconButton` / `WDToolbar` / `WDCheckbox` 的按下与聚焦反馈、`WDTabBar` 的角标朗读、`WDProgressBar` / `WDProgressRing` 的阈值播报、`WDToast` / `WDBanner` 的 polite 播报。

**内部新增（零 public）**：`Internal/A11y/WDFocusRing.swift` 的 `WDFocusRingStyle` / `WDFocusRingOverlay` / `WDAccessibilityFocusHost` / `WDFocusRingTarget`。

---

## 2. L-B 口径

所有新增文案都是**注入点**：`announcementText` / `rangeAnnouncementText` 的措辞由调用方给；Toast/Banner 播报的就是调用方传入的 `message`；进度条/环复用已有的 `valueText`。库内**一个中文字符串都没新增**（R15）。

---

## 3. 契约影响

| 组件 | 变更 | 备注 |
| --- | --- | --- |
| `WDSlider` | `params` 追加 `announcementText` / `rangeAnnouncementText`（默认 null） | 与 B17 的 `rangeText` 同批落库 |
| `WDButtonStyle` | 新增 `isFocused` 参数 | 样式件不在 `WDButton.yaml` 的 params 里（契约只登记组件参数） |
| 其余 | 仅实现变化 | 无需改 yaml |

详见 `docs/B18-CONTRACT-CHANGE-REQUEST.md`。

---

## 4. 验收判据

1. `Scripts/check-structure.sh --strict`：0 error / 0 warning；
2. `Scripts/check-format.sh`：全绿；
3. `xcodebuild build-for-testing`（模拟器 / Swift 6）：0 error；
4. demo app 编译：0 error；
5. `Scripts/dump-api.sh`：零 diff；
6. 新增单测 `WDB18DebtTests` 9 条（纯逻辑/常量）。
