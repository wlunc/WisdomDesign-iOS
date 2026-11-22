// WisdomDesign M2 iOS golden-page template (public API only).
// Template ID: ai-skill-ios-task-list-v1. BUSINESS_EDIT_BEGIN/BUSINESS_EDIT_END is the safe edit area.
import SwiftUI
import WisdomUI

public struct AISkillTask: Identifiable, Sendable, Equatable {
  public let id: String
  public let title: String
  public let detail: String
  public let isDone: Bool
  public init(id: String, title: String, detail: String, isDone: Bool) {
    self.id = id; self.title = title; self.detail = detail; self.isDone = isDone
  }
}

public enum AISkillTaskState: Sendable, Equatable {
  case loading
  case content([AISkillTask])
  case empty
  case error(String)
  var contentTasks: [AISkillTask]? {
    switch self { case .content(let tasks): return tasks; default: return nil }
  }
}

public enum AISkillTaskContentLength: String, Sendable, Equatable {
  case short
  case long
}

public enum AISkillGoldenScenario: String, CaseIterable, Sendable, Equatable {
  case loading
  case contentShort
  case contentLong
  case empty
  case error

  public var contentLength: AISkillTaskContentLength {
    switch self { case .contentLong: return .long; default: return .short }
  }

  public func makeState() -> AISkillTaskState {
    switch self {
    case .loading: return .loading
    case .contentShort: return .content(Self.tasks(long: false))
    case .contentLong: return .content(Self.tasks(long: true))
    case .empty: return .empty
    case .error: return .error("网络连接不可用，请稍后重试")
    }
  }

  private static func tasks(long: Bool) -> [AISkillTask] {
    let suffix = long ? "这是一个用于黄金页面边界矩阵的非常长的任务标题，用来验证大字体与长文案在列表行中不会被截断而应自然换行。" : "简短说明"
    return [
      AISkillTask(id: "t1", title: "家庭任务 \(suffix)", detail: suffix, isDone: false),
      AISkillTask(id: "t2", title: "预约牙医", detail: "联系诊所确认时间", isDone: true)
    ]
  }
}

public struct AISkillTaskListView: View {
  @State private var mode: AISkillTaskState
  @State private var isRefreshing = false
  @State private var selected = Set<String>()
  private let onPrimaryAction: () -> Void
  private let contentLength: AISkillTaskContentLength

  // BUSINESS_EDIT_BEGIN: replace labels, seed data and action wiring only; do not change public API or template ID.
  public init(scenario: AISkillGoldenScenario = .loading, onPrimaryAction: @escaping () -> Void = {}) {
    self.onPrimaryAction = onPrimaryAction
    self.contentLength = scenario.contentLength
    self._mode = State(initialValue: scenario.makeState())
  }
  // BUSINESS_EDIT_END

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: WDSpacing.s4) {
        switch mode {
        case .loading:
          WDSkeleton(variant: .list, lineCount: 3, accessibilityLabel: Text(verbatim: "任务列表加载中"))
            .accessibilityIdentifier("golden-loading")
        case .content(let tasks):
          WDListSection(items: tasks, selection: selected, header: Text(verbatim: "家庭任务")) { task, context in
            WDListRow(
              title: Text(verbatim: task.title),
              subtitle: Text(verbatim: task.detail),
              leading: task.isDone ? .icon(.done) : .icon(.todo),
              trailing: .disclosure,
              isSelected: context.isSelected
            ) { selected.formSymmetricDifference([task.id]) }
            .accessibilityIdentifier("golden-row-\(task.id)")
          }
          .accessibilityIdentifier("golden-content-\(contentLength.rawValue)")
        case .empty:
          WDEmptyState(icon: .task, title: Text(verbatim: "暂无任务"), message: Text(verbatim: "创建第一条任务"), action: WDEmptyStateAction(label: Text(verbatim: "新建任务"), action: onPrimaryAction))
            .accessibilityIdentifier("golden-empty")
        case .error(let message):
          WDBanner(isVisible: .constant(true), variant: .danger, message: Text(verbatim: "加载失败：\(message)"))
            .accessibilityIdentifier("golden-error")
        }
      }
      .padding(.horizontal, WDSpacing.s4)
      .padding(.bottom, WDSpacing.s10)
    }
    .accessibilityIdentifier("golden-task-list-root")
    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: WDSpacing.s4) }
    .overlay(alignment: .bottomTrailing) {
      WDFAB(icon: .add, accessibilityLabel: Text(verbatim: "新建任务"), action: onPrimaryAction, avoidsTabBar: true)
        .padding(.trailing, WDSpacing.s4)
        .padding(.bottom, WDSpacing.s4)
        .accessibilityIdentifier("golden-primary-action")
    }
    .wdPullRefresh(isRefreshing: $isRefreshing) {
      try? await Task.sleep(nanoseconds: 100_000_000)
      mode = .content(AISkillGoldenScenario.contentShort.makeState().contentTasks ?? [])
    }
    .wdFont(WDType.body)
    .wdLineBox(WDType.body, lines: 1)
    .wdAnnouncer { text, _ in _ = text }
  }
}
