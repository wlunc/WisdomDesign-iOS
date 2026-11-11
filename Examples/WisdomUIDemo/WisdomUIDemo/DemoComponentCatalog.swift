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
    case .switchControl, .checkbox, .badge, .avatar, .divider:
      return []
    }
  }
}
