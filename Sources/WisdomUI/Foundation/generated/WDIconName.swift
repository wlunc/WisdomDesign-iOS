// 本文件由 wisdomdesign/tools/token-build/build.js 生成，请勿手改。
// 修改请编辑 wisdomdesign/contracts/icons.json 后重新生成。
// contracts v1.0.0 · sha256:aab3bb93f508

import Foundation

/// 图标语义名（44 条；契约真源 = contracts/icons.json）。
///
/// 本文件由设计仓生成器写入（R12）；**不要手改**。
public enum WDIconName: String, CaseIterable, Sendable, Hashable {
  case home = "home"
  case calendar = "calendar"
  case members = "members"
  case profile = "profile"
  case back = "back"
  case close = "close"
  case more = "more"
  case add = "add"
  case edit = "edit"
  case delete = "delete"
  case share = "share"
  case search = "search"
  case filter = "filter"
  case sort = "sort"
  case duplicate = "duplicate"
  case undo = "undo"
  case redo = "redo"
  case disclose = "disclose"
  case expand = "expand"
  case done = "done"
  case todo = "todo"
  case overdue = "overdue"
  case reminder = "reminder"
  case doNotDisturb = "doNotDisturb"
  case inProgress = "inProgress"
  case synced = "synced"
  case offline = "offline"
  case clear = "clear"
  case showPassword = "showPassword"
  case hidePassword = "hidePassword"
  case date = "date"
  case time = "time"
  case unassigned = "unassigned"
  case task = "task"
  case chore = "chore"
  case shopping = "shopping"
  case meal = "meal"
  case travel = "travel"
  case health = "health"
  case study = "study"
  case pet = "pet"
  case plant = "plant"
  case bill = "bill"
  case photo = "photo"

  /// 本端实现符号（SF Symbols）；换符号属契约变更。
  public var symbolName: String {
    switch self {
    case .home: return "house.fill"
    case .calendar: return "calendar"
    case .members: return "person.2.fill"
    case .profile: return "person.fill"
    case .back: return "chevron.left"
    case .close: return "xmark"
    case .more: return "ellipsis"
    case .add: return "plus"
    case .edit: return "pencil"
    case .delete: return "trash"
    case .share: return "square.and.arrow.up"
    case .search: return "magnifyingglass"
    case .filter: return "line.3.horizontal.decrease"
    case .sort: return "arrow.up.arrow.down"
    case .duplicate: return "doc.on.doc"
    case .undo: return "arrow.uturn.backward"
    case .redo: return "arrow.uturn.forward"
    case .disclose: return "chevron.right"
    case .expand: return "chevron.down"
    case .done: return "checkmark.circle.fill"
    case .todo: return "circle"
    case .overdue: return "exclamationmark.circle.fill"
    case .reminder: return "bell.fill"
    case .doNotDisturb: return "bell.slash.fill"
    case .inProgress: return "clock"
    case .synced: return "arrow.triangle.2.circlepath"
    case .offline: return "wifi.slash"
    case .clear: return "xmark.circle.fill"
    case .showPassword: return "eye"
    case .hidePassword: return "eye.slash"
    case .date: return "calendar"
    case .time: return "clock"
    case .unassigned: return "person.crop.circle.badge.xmark"
    case .task: return "list.bullet"
    case .chore: return "sparkles"
    case .shopping: return "basket"
    case .meal: return "fork.knife"
    case .travel: return "car.fill"
    case .health: return "heart.fill"
    case .study: return "book.fill"
    case .pet: return "pawprint.fill"
    case .plant: return "leaf.fill"
    case .bill: return "creditcard.fill"
    case .photo: return "photo"
    }
  }

  /// 是否随书写方向镜像（**契约断言用**；渲染由 SF Symbols 自带机制负责）。
  public var mirrorsInRTL: Bool { Self.mirrorsInRTLNames.contains(self) }

  /// 需要镜像的语义名集合（契约列）。
  public static let mirrorsInRTLNames: Set<WDIconName> = [.back, .sort, .undo, .redo, .disclose]
}
