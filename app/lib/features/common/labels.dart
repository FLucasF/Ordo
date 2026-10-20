import '../../app/format/date_labels.dart';
import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../data/repository.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';

/// Turns domain meanings (headers, empty states, rules) into the PT-BR texts of the UI.
class Labels {
  Labels(this.t) : dates = DateLabels(t);

  final AppLocalizations t;
  final DateLabels dates;

  String smartList(SmartList l) => switch (l) {
    SmartList.all => t.smartAll,
    SmartList.today => t.smartToday,
    SmartList.tomorrow => t.smartTomorrow,
    SmartList.next7Days => t.smartNext7Days,
    SmartList.completed => t.smartCompleted,
    SmartList.summary => t.smartSummary,
    SmartList.wontDo => t.smartWontDo,
    SmartList.trash => t.smartTrash,
  };

  /// The Inbox is stored with a placeholder name and always shown localized.
  String listName(TaskList l) => l.id == inboxListId ? t.inbox : l.name;

  String scopeTitle(Snapshot s, Scope scope) => switch (scope) {
    ListScope(:final listId) => s.listById[listId] == null ? '' : listName(s.listById[listId]!),
    FolderScope(:final folderId) => s.folderById[folderId]?.name ?? '',
    TagScope(:final tagId) => s.tagById[tagId]?.name ?? '',
    SmartScope(:final smartList) => this.smartList(smartList),
    FilterScope(:final filterId) => s.filterById[filterId]?.name ?? '',
  };

  String header(GroupHeader h, Snapshot s, DateTime today) => switch (h) {
    NoHeader() => '',
    PinnedHeader() => t.groupPinned,
    UnpinnedHeader() => t.groupUnpinned,
    UnsectionedHeader() => t.groupUnsectioned,
    SectionHeader(:final name) => name,
    OverdueHeader() => t.groupOverdue,
    DayHeader(:final day) => dates.dayHeader(day, today),
    Next7DaysHeader() => t.groupNext7Days,
    LaterHeader() => t.groupLater,
    NoDateHeader() => t.groupNoDate,
    PriorityHeader(:final priority) => switch (priority) {
      Priority.high => t.groupPriorityHigh,
      Priority.medium => t.groupPriorityMedium,
      Priority.low => t.groupPriorityLow,
      Priority.none => t.groupPriorityNone,
    },
    TagHeader(:final name) => name,
    NoTagHeader() => t.groupNoTag,
    ListHeader(:final listId) => s.listById[listId] == null ? '' : listName(s.listById[listId]!),
    ClosedHeader(:final includesWontDo) => includesWontDo ? t.groupCompletedAndWontDo : t.groupCompleted,
  };

  (String, String) emptyState(EmptyState e) => switch (e) {
    EmptyState.inbox => (t.emptyNoTasks, t.emptyInbox),
    EmptyState.list => (t.emptyNoTasks, t.emptyList),
    EmptyState.notes => (t.emptyNoNotes, t.emptyNotes),
    EmptyState.tag => (t.emptyNoTasks, t.emptyTag),
    EmptyState.smart => (t.emptyNoTasks, t.emptySmart),
    EmptyState.completed => (t.emptyCompletedTitle, t.emptyCompleted),
    EmptyState.wontDo => (t.emptyNoTasks, t.emptyWontDo),
    EmptyState.trash => (t.emptyTrashTitle, t.emptyTrash),
  };

  String addHint(AddHint h, Snapshot s) => switch (h) {
    AddPlainHint() => t.addTask,
    AddNoteHint() => t.addNote,
    AddToListHint(:final listId) => t.addTaskTo(s.listById[listId] == null ? t.inbox : listName(s.listById[listId]!)),
    AddToTagHint(:final tagId) => t.addTaskToTag(s.tagById[tagId]?.name ?? ''),
  };

  String rule(Rule r) => switch (r) {
    Rule.inboxCannotBeArchived => t.errorInboxCannotBeArchived,
    Rule.inboxCannotBeDeleted => t.errorInboxCannotBeDeleted,
    Rule.taskCannotBeItsOwnParent => t.errorTaskCannotBeItsOwnParent,
    Rule.subtaskDepthLimit => t.errorSubtaskDepthLimit,
    Rule.taskWithSubtasksCannotBecomeNote => t.errorTaskWithSubtasksCannotBecomeNote,
    Rule.tagNameTaken => t.errorTagNameTaken,
    Rule.listCannotBeItsOwnParent => t.errorListCannotBeItsOwnParent,
    Rule.sublistDepthLimit => t.errorSublistDepthLimit,
    Rule.inboxCannotNest => t.errorInboxCannotNest,
  };

  String priority(Priority p) => switch (p) {
    Priority.high => t.priorityHigh,
    Priority.medium => t.priorityMedium,
    Priority.low => t.priorityLow,
    Priority.none => t.priorityNone,
  };
}
