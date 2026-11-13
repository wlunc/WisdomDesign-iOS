import SwiftUI
import WisdomUI

/// 组件目录的分组：demo 用「用途」而不是库内部的 Primitives/Composites 分层来组织浏览。
enum DemoComponentCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
  case actions
  case input
  case display
  case structure

  var id: String { rawValue }

  /// 分组标题。
  var title: String {
    switch self {
    case .actions: return "操作"
    case .input: return "输入与选择"
    case .display: return "内容展示"
    case .structure: return "布局与结构"
    }
  }

  /// 分组副标题（一句话说明这一组解决什么问题）。
  var subtitle: String {
    switch self {
    case .actions: return "触发动作与导航"
    case .input: return "文本输入与真假选择"
    case .display: return "信息呈现与内容组织"
    case .structure: return "分隔与视觉节奏"
    }
  }

  /// 分组图标（沿用契约里的语义名）。
  var icon: WDIconName {
    switch self {
    case .actions: return .add
    case .input: return .edit
    case .display: return .photo
    case .structure: return .sort
    }
  }
}

/// 组件标识。每个 case 都直接对应一个真实类型名，方便在详情页里做穷尽分支。
enum DemoComponentID: String, CaseIterable, Identifiable, Hashable, Sendable {
  case button = "WDButton"
  case iconButton = "WDIconButton"
  case textField = "WDTextField"
  case switchControl = "WDSwitch"
  case checkbox = "WDCheckbox"
  case listRow = "WDListRow"
  case card = "WDCard"
  case badge = "WDBadge"
  case avatar = "WDAvatar"
  case icon = "WDIcon"
  case divider = "WDDivider"
  case listSection = "WDListSection"
  case progressBar = "WDProgressBar"
  case progressRing = "WDProgressRing"
  case banner = "WDBanner"
  case emptyState = "WDEmptyState"
  case skeleton = "WDSkeleton"
  case alert = "WDAlert"
  case actionSheet = "WDActionSheet"
  case bottomSheet = "WDBottomSheet"
  case toast = "WDToast"

  var id: String { rawValue }
}

/// 目录条目：列表页只需要这一层；详情页按 id 分支到具体的展示视图。
struct DemoComponentEntry: Identifiable, Hashable, Sendable {
  let id: DemoComponentID
  let category: DemoComponentCategory
  let icon: WDIconName
  let summary: String
  let layer: String
  let batch: String
  let highlights: [String]
  let hasEnumSettings: Bool

  /// 组件类型名。
  var name: String { id.rawValue }
}

/// 组件目录（只列已经实现的 M2 组件；后续批次随实现逐步加入）。
enum DemoComponentCatalog {
  static let entries: [DemoComponentEntry] = [
    DemoComponentEntry(
      id: .button,
      category: .actions,
      icon: .add,
      summary: "主要操作入口。六种外观档位、三档高度，支持加载、禁用与按下反馈。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "6 个变体：filled / tonal / glass / outline / plain / destructive",
        "3 档高度 32 / 44 / 52，热区统一补到 44",
        "加载态忽略 action 但保留宽度；禁用态 40% 不透明度",
      ],
      hasEnumSettings: true
    ),
    DemoComponentEntry(
      id: .iconButton,
      category: .actions,
      icon: .search,
      summary: "紧凑的图标动作。视觉尺寸 32 / 44 / 52，热区固定 44×44，语义由调用方标签提供。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "视觉尺寸 32 / 44 / 52，热区恒为 44×44",
        "图标是装饰件；无障碍标签必填",
        "当前冻结的变体只有 plain",
      ],
      hasEnumSettings: true
    ),
    DemoComponentEntry(
      id: .alert,
      category: .actions,
      icon: .overdue,
      summary: "阻断式弹窗。固定 270 卡片、遮罩点击不关闭、支持带输入变体。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "固定宽 270、圆角 24、elevation.3",
        "取消在左、确认/危险在右；点击后禁用防重复",
        "出现时焦点移入弹层（screenChanged）",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .actionSheet,
      category: .actions,
      icon: .more,
      summary: "底部操作表。行高 44，取消键与操作列表视觉分离，空 items 在 debug 下断言。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "行高 44；破坏性项用 status.danger",
        "取消键独立成组",
        "系统 sheet 负责焦点陷阱与键盘避让",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .bottomSheet,
      category: .actions,
      icon: .expand,
      summary: "底部面板。half / large 两档，标题、内容、页脚三段，关闭键标签必填。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "档位 0.5 / 0.92，默认 .all",
        "关闭键无障碍标签必填",
        "下滑关闭由系统接管；interactiveDismissDisabled 可关",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .toast,
      category: .actions,
      icon: .done,
      summary: "非阻塞轻提示。玻璃胶囊、3 秒/带操作 5 秒自动消失，不抢焦点。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "单行高 46、圆角 full",
        "组件内 .task 计时，随视图消失取消",
        "四个变体：neutral / success / warning / danger",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .textField,
      category: .input,
      icon: .edit,
      summary: "带常驻标签、前缀、尾部附件与辅助文案的输入字段，覆盖密文、只读和错误态。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "字段盒 46pt；所有变体和状态高度一致",
        "前缀 / 尾部附件 / 辅助文案三个槽位",
        "错误文案走 accessibilityHint；只读态在 U6 六态之外",
      ],
      hasEnumSettings: true
    ),
    DemoComponentEntry(
      id: .switchControl,
      category: .input,
      icon: .done,
      summary: "开关。轨道 51×31、滑块 27，整行可点，开关状态由系统的 switch 角色朗读。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "轨道 51×31，滑块 27，行程 20",
        "整行可点，切换轻触觉一次",
        "真 Toggle：开关状态由系统朗读",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .checkbox,
      category: .input,
      icon: .todo,
      summary: "复选框。方框 26pt、圆角 9pt，勾是描边路径；整行可点，状态由系统朗读。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "方框 26pt、圆角 9pt、描边 1.5pt",
        "勾是画出来的描边路径，不依赖图标资源",
        "真 Toggle：选中状态由系统朗读",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .listRow,
      category: .display,
      icon: .task,
      summary: "列表行。组合前导、尾部槽位，行高随槽位派生，支持选中、分隔线和点击语义。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "行高随槽位派生：44 / 60 / 76",
        "leading 5 种、trailing 5 种",
        "只有传 action 才成为按钮；否则是纯内容",
      ],
      hasEnumSettings: true
    ),
    DemoComponentEntry(
      id: .card,
      category: .display,
      icon: .duplicate,
      summary: "内容卡片。elevated / outlined / glass 三种外观，固定 16 内边距与 24 圆角。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "内边距 16、圆角 24",
        "只有 glass 使用玻璃效果；iOS 17–25 纯色降级",
        "静态卡对读屏使用 children: .contain",
      ],
      hasEnumSettings: true
    ),
    DemoComponentEntry(
      id: .badge,
      category: .display,
      icon: .inProgress,
      summary: "状态胶囊。固定 11pt / 600、胶囊高 24，不进入无障碍焦点序列。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "固定 11pt / 600，不随动态字体放大（设计例外）",
        "胶囊高 24、水平内距 10",
        "装饰件：由宿主决定怎样并入朗读",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .avatar,
      category: .display,
      icon: .profile,
      summary: "圆形头像。默认 md 直径 32，支持图标占位与首字/姓名两种载荷。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "默认 md 直径 32",
        "两种载荷：icon 占位 / label 首字或姓名",
        "首字号固定 12pt，不随动态字体放大",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .icon,
      category: .display,
      icon: .chore,
      summary: "契约语义图标。44 个语义名映射到 SF Symbols，四档尺寸，装饰件不进无障碍树。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "44 个语义名 → SF Symbols",
        "四档尺寸：16 / 20 / 24 / 28",
        "装饰件：不进无障碍树，颜色由容器给",
      ],
      hasEnumSettings: true
    ),
    DemoComponentEntry(
      id: .progressBar,
      category: .display,
      icon: .inProgress,
      summary: "线性进度。确定态按百分比填充，不确定态来回移动，完成态换成功色。",
      layer: "Primitives",
      batch: "M4",
      highlights: [
        "轨道高 6、圆角 full、最小宽 100",
        "数值钳制到 0...1；完成时成功触觉一次",
        "只跨 25/50/75/100 播报（由调用方给标签）",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .progressRing,
      category: .display,
      icon: .inProgress,
      summary: "环形进度。标准 60 / 紧凑 44，线帽圆头，完成时环色转成功色。",
      layer: "Primitives",
      batch: "M4",
      highlights: [
        "标准 60 / 紧凑 44；线宽 6 / 5",
        "12 点方向顺时针，线帽圆头",
        "环本身装饰，信息由 label / valueText 承担",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .banner,
      category: .display,
      icon: .offline,
      summary: "常驻页面提示。软底渐变、最多 2 行，支持一个操作与可选关闭键。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "三变体：info / warning / danger（success 不在冻结面内）",
        "错误态文字加粗、图标与文字同时变化",
        "可见性由调用方的 isVisible 持有",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .emptyState,
      category: .display,
      icon: .task,
      summary: "空状态。图标底座 56 + 标题 + 说明 + 最多一个主操作。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "图标底座 56×56，装饰件",
        "说明最多 2 行，文本最大宽 240",
        "无操作时整块不可交互",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .skeleton,
      category: .display,
      icon: .duplicate,
      summary: "骨架占位。文本 / 列表 / 卡片三形态，微光 2200ms，减弱动效或预算不足时静态。",
      layer: "Composites",
      batch: "M4",
      highlights: [
        "文本行高 11、圆角 6、宽度 70% / 45%",
        "列表行与 WDListRow 等高",
        "整区只朗读一次（标签由调用方给）",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .divider,
      category: .structure,
      icon: .sort,
      summary: "全宽 hairline 分割线。1pt 高、无圆角、无状态，不进入无障碍树。",
      layer: "Primitives",
      batch: "M2",
      highlights: [
        "1pt 高、全宽、border.hairline 色",
        "无圆角、无状态",
        "装饰件：不进无障碍树",
      ],
      hasEnumSettings: false
    ),
    DemoComponentEntry(
      id: .listSection,
      category: .structure,
      icon: .task,
      summary: "数据驱动的列表分组：标题、标题动作、一个内容卡片与可选页脚；空集合整组隐藏。",
      layer: "Primitives",
      batch: "M3",
      highlights: [
        "空 items 整组隐藏（连标题/动作/页脚）",
        "末行通过 WDListSectionRowContext.isLast 交给行关分隔线",
        "标题 overline + 内容卡片 + 可选页脚 footnote",
      ],
      hasEnumSettings: false
    ),
  ]

  /// 某个分组下的条目（保持目录里的书写顺序）。
  static func entries(in category: DemoComponentCategory) -> [DemoComponentEntry] {
    entries.filter { $0.category == category }
  }

  /// 已实现组件数。
  static var totalCount: Int { entries.count }
}

// MARK: - 枚举的 demo 文案

extension WDButtonVariant {
  /// 设置面板与配置摘要里使用的中文名。
  var demoTitle: String {
    switch self {
    case .filled: return "填充"
    case .tonal: return "柔色"
    case .glass: return "玻璃"
    case .outline: return "描边"
    case .plain: return "纯文字"
    case .destructive: return "破坏性"
    }
  }
}

extension WDButtonSize {
  /// 设置面板里使用的尺寸名。
  var demoTitle: String {
    switch self {
    case .sm: return "小 · 32"
    case .md: return "中 · 44"
    case .lg: return "大 · 52"
    }
  }
}

extension WDIconButtonVariant {
  /// 图标按钮当前只有一档。
  var demoTitle: String {
    switch self {
    case .plain: return "纯图标"
    }
  }
}

extension WDTextFieldVariant {
  /// 字段形态名。
  var demoTitle: String {
    switch self {
    case .inset: return "内嵌"
    case .outline: return "描边"
    case .glass: return "玻璃"
    }
  }
}

extension WDCardStyle {
  /// 卡片外观名。
  var demoTitle: String {
    switch self {
    case .elevated: return "浮起"
    case .outlined: return "描边"
    case .glass: return "玻璃"
    }
  }
}

extension WDIconSize {
  /// 图标尺寸名。
  var demoTitle: String {
    switch self {
    case .sm: return "小 16"
    case .md: return "中 20"
    case .lg: return "大 24"
    case .xl: return "特大 28"
    }
  }
}

// MARK: - 关联值枚举的 demo 选项

/// WDListRowLeading 在设置面板里的可选项（关联值固定成 demo 示例）。
enum DemoListRowLeading: String, CaseIterable, Identifiable, Hashable {
  case none
  case icon
  case avatar
  case checkbox
  case selection

  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "无"
    case .icon: return "图标底座"
    case .avatar: return "头像"
    case .checkbox: return "勾选框"
    case .selection: return "单选圆点"
    }
  }

  /// 转成组件参数。
  func value() -> WDListRowLeading {
    switch self {
    case .none: return .none
    case .icon: return .icon(.task)
    case .avatar: return .avatar(.init(label: Text(verbatim: "妈")))
    case .checkbox: return .checkbox
    case .selection: return .selectionIndicator
    }
  }
}

/// WDListRowTrailing 在设置面板里的可选项（关联值固定成 demo 示例）。
enum DemoListRowTrailing: String, CaseIterable, Identifiable, Hashable {
  case none
  case value
  case badge
  case avatar
  case disclosure

  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "无"
    case .value: return "值文本"
    case .badge: return "徽标"
    case .avatar: return "头像"
    case .disclosure: return "箭头"
    }
  }

  /// 转成组件参数。
  func value() -> WDListRowTrailing {
    switch self {
    case .none: return .none
    case .value: return .value(Text(verbatim: "3 件"))
    case .badge: return .badge(.init(label: Text(verbatim: "进行中")))
    case .avatar: return .avatar(.init(label: Text(verbatim: "爸")))
    case .disclosure: return .disclosure
    }
  }
}

/// 字段前缀槽位的 demo 选项。
enum DemoTextFieldPrefix: String, CaseIterable, Identifiable, Hashable {
  case none
  case icon
  case text

  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "无"
    case .icon: return "图标"
    case .text: return "文本"
    }
  }

  /// 转成组件参数。
  func value() -> WDTextFieldPrefix {
    switch self {
    case .none: return .none
    case .icon: return .icon(.search)
    case .text: return .text(Text(verbatim: "¥"))
    }
  }
}

/// 字段尾部附件的 demo 选项。
enum DemoTextFieldAccessory: String, CaseIterable, Identifiable, Hashable {
  case none
  case unit
  case clear
  case reveal
  case count

  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "无"
    case .unit: return "单位文本"
    case .clear: return "清除按钮"
    case .reveal: return "显隐密码"
    case .count: return "计数"
    }
  }

  /// 转成组件参数。
  func value(currentCount: Int) -> WDTextFieldAccessory {
    switch self {
    case .none: return .none
    case .unit: return .unit(Text(verbatim: "kg"))
    case .clear: return .clear(accessibilityLabel: Text(verbatim: "清除"))
    case .reveal:
      return .reveal(
        hiddenAccessibilityLabel: Text(verbatim: "显示密码"),
        shownAccessibilityLabel: Text(verbatim: "隐藏密码")
      )
    case .count: return .count(current: currentCount, limit: 20)
    }
  }
}

/// 字段辅助文案槽位的 demo 选项。
enum DemoTextFieldHelper: String, CaseIterable, Identifiable, Hashable {
  case none
  case hint
  case error

  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "无"
    case .hint: return "提示"
    case .error: return "错误"
    }
  }

  /// 转成组件参数。
  func value() -> WDTextFieldHelper {
    switch self {
    case .none: return .none
    case .hint: return .hint(Text(verbatim: "名称可以稍后修改"))
    case .error: return .error(Text(verbatim: "名称已被占用"))
    }
  }
}

// MARK: - 详情页的本地设置

/// 详情页里的全部可切换配置。
///
/// demo 故意把可选枚举摊平成一组值：详情页和设置面板共享同一份 State，
/// 所以设置面板里的切换会立即反映到下面的实时预览。
struct DemoComponentSettings {
  var buttonVariant: WDButtonVariant = .filled
  var buttonSize: WDButtonSize = .md
  var buttonLoading = false
  var buttonDisabled = false
  var buttonTapCount = 0

  var iconButtonVariant: WDIconButtonVariant = .plain
  var iconButtonSize: WDButtonSize = .md
  var iconButtonIcon: WDIconName = .add
  var iconButtonLoading = false
  var iconButtonDisabled = false
  var iconButtonTapCount = 0

  var textFieldVariant: WDTextFieldVariant = .inset
  var textFieldPrefix: DemoTextFieldPrefix = .icon
  var textFieldAccessory: DemoTextFieldAccessory = .clear
  var textFieldHelper: DemoTextFieldHelper = .hint
  var textFieldSecure = false
  var textFieldReadOnly = false
  var textFieldText = "整理储物间"

  var cardStyle: WDCardStyle = .elevated

  var rowLeading: DemoListRowLeading = .icon
  var rowTrailing: DemoListRowTrailing = .value
  var rowSelected = true
  var rowShowsSeparator = true
  var rowTappable = true
  var rowTapCount = 0

  var iconName: WDIconName = .home
  var iconSize: WDIconSize = .md

  var switchOn = true
  var checkboxChecked = true

  /// 当前配置摘要（显示在实时预览上方的小胶囊里）。
  func summary(for id: DemoComponentID) -> [String] {
    switch id {
    case .button:
      var items = [buttonVariant.demoTitle, buttonSize.demoTitle]
      if buttonLoading { items.append("加载中") }
      if buttonDisabled { items.append("禁用") }
      return items
    case .iconButton:
      var items = [iconButtonSize.demoTitle, iconButtonIcon.rawValue]
      if iconButtonLoading { items.append("加载中") }
      if iconButtonDisabled { items.append("禁用") }
      return items
    case .textField:
      var items = [textFieldVariant.demoTitle]
      if textFieldPrefix != .none { items.append("前缀：" + textFieldPrefix.title) }
      if textFieldAccessory != .none { items.append("附件：" + textFieldAccessory.title) }
      if textFieldHelper != .none { items.append("辅助：" + textFieldHelper.title) }
      if textFieldSecure { items.append("密文") }
      if textFieldReadOnly { items.append("只读") }
      return items
    case .card:
      return [cardStyle.demoTitle]
    case .listRow:
      var items = [rowLeading.title, rowTrailing.title]
      if rowSelected { items.append("选中") }
      if !rowShowsSeparator { items.append("无分隔线") }
      if rowTappable { items.append("可点击") }
      return items
    case .icon:
      return [iconName.rawValue, iconSize.demoTitle]
    case .switchControl, .checkbox, .badge, .avatar, .divider, .listSection,
      .progressBar, .progressRing, .banner, .emptyState, .skeleton,
      .alert, .actionSheet, .bottomSheet, .toast:
      return []
    }
  }
}

/// 组合场景：不是新的组件类型，而是「容器 + 已有组件」的演示入口。
struct DemoScenario: Identifiable, Hashable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let icon: WDIconName
}

enum DemoScenarioCatalog {
  static let entries: [DemoScenario] = [
    DemoScenario(
      id: "card",
      title: "卡片容器",
      subtitle: "WDCard 里组合头像、徽章、进度、开关、列表与按钮",
      icon: .sort
    ),
    DemoScenario(
      id: "bottomSheet",
      title: "底部面板容器",
      subtitle: "WDBottomSheet 里组合输入框、卡片、开关、进度与固定页脚",
      icon: .expand
    ),
  ]
}
