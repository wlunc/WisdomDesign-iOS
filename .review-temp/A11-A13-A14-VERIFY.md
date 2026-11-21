# A-11 / A-13 / A-14 验证报告（27 条逐项）

> 验证者：captain（t4 由 captain 接管 —— wd-verifier 被 429 打断）。
> **独立性声明**：本报告是**证据层**（静态核对 + 门禁实跑），实现也是 captain 完成的，
> 因此本报告**不构成独立质量判断**；独立 verdict 由 t5（wd-reviewer，成员）给出，
> 评审者应把本报告当线索而非结论，高风险条目自行复核。
> 设计真源：`../wisdomdesign/docs/14-member-tones-media-tooltip.md`（定稿 v1.0）。
> 环境限制：本机 PTY 耗尽、xctest 无法连接 ⇒ **一切测试执行记【无法验证】**。

## 图例
✅ 通过（带文件:行号证据）｜ ❌ 不通过｜ ⚪ 无法验证（需运行时/真机）

## 一、A-11 WDAvatar（设计 14 §1）

1. ✅ 默认 tone=nil 回落 surfaceTint：`WDAvatar.swift:259` `tone?.fill ?? colors.surfaceTint`
2. ✅ tone 非 nil 走 fill/ink、无硬编码色值：`:264` `tone?.ink ?? colors.textOnSoft`；组件源 grep 十六进制仅 1 命中且在**文档注释**（:135 "10x10"），无实际色值字面量
3. ✅ 回退链硬顺序 photo→label→icon：`WDAvatarValue.resolved` `:106-113`（三个 if let 顺序即设计 §1.4 回退链）
4. ✅ 照片 2pt 描边 + 描边色可传：`WDAvatarMetrics.swift:34` `photoRingWidth = WDSize.avatarRing`；`WDAvatar.swift:269` `hostColor ?? colors.surfaceCardSolid`（在线点共用 ringColor :239）
5. ⚪ 加载不占位/失败不破图：**代码层**成立（`WDAvatarImage` 只在就绪时构造，image=nil 直接落回退档，架构上无占位帧）；**运行时行为**无法验证（需渲染）
6. ✅ 淡入 160ms 无缩放：`WDAvatarMetrics.swift:36` `photoFadeDuration = WDMotion.Duration.fast`；photoLayer 无 scaleEffect
7. ✅ FNV1a32 + 五 fixture：`WDMemberTone+Assign.swift:37-39`（0x811C_9DC5 / 0x0100_0193 / &* 回绕 / value.utf8）；fixture 断言在 WDAvatarTests memberToneFixtures —— 代码就位，**执行⚪**
8. ✅ Equatable 语义：手写 `==` `WDAvatar.swift:81-85`（只比 label/icon/是否有照片）；语义注释 :37-41；未删 Equatable；grep AnyView 0 命中

## 二、A-13 WDCard.media（设计 14 §2）

9. ✅ 图片带通栏、文字区 16：`WDCard.swift:155-161` VStack(图片带 + content.padding(s5))——padding 只在文字区
10. ✅ 整卡单次 clipShape：grep clipShape 3 命中（shape 定义 1 + 调用 chrome 2），无带内圆角
11. ✅ 令牌驱动几何：`:311-312` `.aspectRatio(WDSize.cardMediaAspectRatio)` + `.frame(minHeight: WDSize.cardMediaMinHeight)`
12. ✅ 灰底占位：`:303` `Color(colors.surfaceCardSunken)`（image nil 与图片层同框、淡入盖住）
13. ✅ media 与 glass/sunken 互斥（构造层强制）：非 .media 档 media 恒 nil（两个重载 `style == .media ? media : nil`）；测试 mediaMutuallyExclusive 断言 `elevatedWithMediaParam.media == nil`。**口径**：构造层忽略而非运行时断言
14. ✅ 图片默认装饰/给标签进树：`:319` `.accessibilityHidden(media.accessibilityLabel == nil)` + `:320` accessibilityLabel
15. ✅ 按下蒙层覆盖整卡：复用 WDCardButtonStyle（configuration.label 含图片带）
16. ✅ 既有四档零变化：background switch 补 media → surfaceCard（其余分支原样）；阴影/描边分支未动

## 三、A-14 WDToolbar（设计 14 §3）

17. ✅ showsTooltips 默认 false：init 参数带默认值；arbitration==nil 走 plainBody 与改造前逐帧一致
18. ✅ 阈值走令牌：`WDToolbar.swift:137` `threshold: WDSize.tooltipPressDuration`
19. ✅ 「500ms 后抬手不执行」唯一判断点：`WDToolbarTooltip.swift:65-73` decide(.release, .pressing)——`at - since < threshold → performAction` 否则 `hideTooltip/consumed`。注释明确标注"唯一判断点"
20. ✅ 无 simultaneousGesture：WDToolbar 目录 3 文件 grep，唯一命中是**注释**（WDToolbar.swift:131 说明禁用原因）
21. ✅ 单状态机：按下态/计时/决策全走 `WDToolbarArbitration` 纯函数；onChange(of: isPressed) 是视图层喂事件唯一入口
22. ✅ 气泡几何/样式：全部走令牌（WDSize.tooltipHeight/MaxWidth/Offset、WDRadius.xs）；surfaceCardSolid 实底 + hairline + e2；caption2 单行；无箭头；越界夹紧 :196-199
23. ✅ 动效：appearDuration=0.12（R7 豁免注释引用 §4.2-Q2）/ disappearDuration=WDMotion.Duration.fast；reduceMotion 判断位移（:168-171）
24. ✅ 提示不进树 + 按钮保留 label：`:170` `.accessibilityHidden(true)` + `.allowsHitTesting(false)`；itemButton 的 accessibilityLabel 未动

## 四、跨切面

25. ✅ 三份实现互不踩文件：avatar 只动 WDAvatar 目录+Foundation/Tokens+Internal/Controls；card 只动 WDCard 目录+demo catalog（amend 后入 scope）；toolbar 只动 WDToolbar 目录。测试文件各自独立（WDAvatarTests/WDCardTests/M5ComponentsTests）
26. ✅ generated/ 未手改：git status 显示 generated 3 文件的修改**先于**本批（令牌 v1.1.0 变更集带入，时间戳 11-21 11:38），本批实现期间无 generated 改动
27. ✅ 三门禁实跑（captain 本轮，非抄实现者）：
    - `check-structure.sh --strict` exit 0（files=196 errors=0 warnings=0）
    - `check-format.sh` exit 0（212 文件全过）
    - `build-for-testing` exit 0（TEST BUILD SUCCEEDED，0 error）

## 五、【无法验证】清单（非"通过"）

- 三个组件的单测**执行**（WDAvatarTests 5+ / WDCardTests 5 / M5ComponentsTests 6 条新增）：本机 PTY 耗尽、xctest 无法建立连接。测试代码已随 build-for-testing 编译（0 error）。
- 8 态快照：本批零新基线（无法录制）。
- 真机手势回归（A-14 的 500ms 内点按 vs 超时抬手）：设计 §4.3 D-7 明确需真机人审。
- 像素级断言（tone 底色、照片渲染）：探针代码就位，执行⚪。

## 结论（证据层，非 verdict）

27 条中 24 条静态通过（带行号证据）、3 条运行时项记⚪；无一条 ❌。
独立 verdict 请看 t5（wd-reviewer）。