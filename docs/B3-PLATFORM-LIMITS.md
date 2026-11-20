# B3 平台限制记录 —— radio / listbox / option 角色与 Picker 滚轮形态（2026-11-15）

> **状态：只记录，不实现。** 项目负责人 2026-11-15 清单 **B3 段**：「平台限制，记录即可（不建议继续投入）」。
> **性质**：这三件**不是**实现欠账，而是 **SwiftUI 侧不存在对应能力**；等系统给出能力（或改为 UIKit 自绘整件 + `UIAccessibility` 自定义）时才可能闭合，而后者等于为两个 trait 重写三个组件，代价与收益不成比例。
> **效力**：本文件是「B3 段不再投入」的唯一登记处；对应组件文件里的差异注释与本文件互相指向。

---

## 1. 受限项

| # | 组件 | 设计要求的语义 | SwiftUI 现状 | 本仓现行近似 | 依据 |
| --- | --- | --- | --- | --- | --- |
| L-1 | `WDRadio`（设计 07 §10） | 组 `radiogroup` + 项 `radio`，朗读「第 n 项，共 m 项」 | `AccessibilityTraits` **没有** `radio`/`radiogroup`；`accessibilityRepresentation` 能借的 `Picker(.inline/.segmented)` 语义是 `adjustable`/`button`，会把"单项可聚焦 + 可点"改成另一套交互 | 组 `.accessibilityElement(children: .contain)` + 每项 `.isSelected`；「第 n 项，共 m 项」由调用方用 `WDSemantics.positional` 拼入标签（L-B：措辞由调用方给） | `docs/M5-EXIT-REPORT.md` §4-③；F34（容器语义近似） |
| L-2 | `WDPicker` 菜单形态（设计 22 §10） | 浮层 `listbox` + 项 `option`，当前项 `aria-selected` | 同上：无 `listbox`/`option` trait | 浮层 `.isModal` + 选项 `.isSelected`；触发入口为 button（`.accessibilityValue` 读当前值） | `docs/M5-EXIT-REPORT.md` §4-㉑ |
| L-3 | `WDSegmentedControl`（设计 21 §10） | 容器 `tablist` + 段 `tab` + 内容区 `tabpanel` | 无 `tablist`/`tab` trait；内容区关联无法表达 | 容器 `.contain` + 段 `.isSelected` + 选中态同时改字重与指示块位置（不依赖颜色） | `docs/M5-EXIT-REPORT.md` §4-⑦ |
| L-4 | `WDPicker` 滚轮形态（设计 22 §11） | 滚轮弹层，**先选后确认**（关闭不提交时可选） | 设计 22 §11 **已明确指定 iOS 用系统 `Picker` + `.wheel`**；系统 `.wheel` 逐项即时提交、无"确认"步骤 | 保留系统 `.wheel`（"保留各自原生控件，只统一触发入口"）；菜单形态才做"关闭不改变值" | 设计 22 §11（指定）、§8（交互表） |
| L-5 | `WDSlider` 键盘焦点光环 | 键盘聚焦手柄时显示光环 | UISlider 的"键盘聚焦"在 iOS 上没有可观测的公开事件（`canBecomeFocused` 只对 tvOS 生效；iPadOS 全键盘控制在 SwiftUI 里不暴露聚焦回调），无法区分"键盘聚焦"与"触摸聚焦" | 焦点光环只接**读屏焦点**（B13）；键盘方向键调整仍由 UISlider 原生提供 | 本批 B13 登记 |

## 2. 判定：不再投入的理由（逐条）

1. **没有 API 就没有"接近"**：`AccessibilityTraits` 是位集合，`radio`/`tab`/`listbox` 都不在其中；用 `accessibilityRepresentation` 借别的控件会**改变交互模型**（读屏会读成"可调整"或"按钮"），比现状更差——这是 F34「容器语义近似」已登记的取舍，不是遗漏。
2. **改写整件不划算**：想要真 `UIAccessibilityTrait`，必须整件改成 `UIViewRepresentable` + 自定义 `UIAccessibility` 元素（丢掉 SwiftUI 的动态字体、行盒、主题令牌自动传播），并重新过一遍 8 态快照与无障碍审计；为 1 个 trait 重写组件，代价远超收益。
3. **设计稿已指定系统载体**：L-4 是**设计明确要求**（22 §11「保留各自原生控件」），不是平台缺陷；即时提交是系统 `.wheel` 的既定行为。
4. **语义等价物已具备**：三件的"可感知状态"都已由 `.isSelected` + 位置/字重/圆点（不依赖颜色）表达，读屏能读出选中态与当前值；缺的只是**角色名**。

## 3. 解除条件（谁、什么时点重开）

| 触发 | 处理 |
| --- | --- |
| iOS 给 SwiftUI `AccessibilityTraits` 增加 radio / tab / listbox / option（或 `accessibilityRole(_:)` 类 API） | 在本文件登记版本号，按新 trait 补三件 + 更新 8 态快照 + CHANGELOG |
| 设计改口径，要求"角色必须与 Android 一致" | 走 U 系列流程（需 android-lead + tech-lead 确认）；实现方式改为整件 `UIViewRepresentable`，本文件作废并出新的签名冻结 |
| 设计改 22 §11 要求滚轮也"先选后确认" | 属设计侧改稿 + 系统能力冲突，需设计裁决；本仓默认**保持系统 `.wheel`** |

## 4. 交叉引用

- 组件文件注释：`WDRadio.swift` / `WDPicker.swift` / `WDPickerMenu.swift` / `WDSegmentedControl.swift` / `WDSlider.swift` 内已有"差异登记"行，均指向本文件与 `docs/M5-EXIT-REPORT.md` §4。
- 规格侧：`docs/SPEC.md` §2.10 的"播报/触觉"列 + F34（容器语义近似）。
- 本批（B10–B16）实现时**不得**顺手补这三个角色，也不得为此改签名。
