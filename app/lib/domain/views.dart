import '../core/clock.dart';
import '../core/ids.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'reminders.dart';
import 'filters.dart';
import 'snapshot.dart';
import 'task_dates.dart';

/// TickTick smart lists with the webapp route segment.
enum SmartList {
  all('all'),
  today('today'),
  tomorrow('tomorrow'),
  next7Days('week'),

  /// "Resumo": a report, not a task list.
  summary('summary'),
  completed('completed'),
  wontDo('abandoned'),
  trash('trash');

  const SmartList(this.route);

  final String route;

  static SmartList? fromRoute(String route) => values.where((l) => l.route == route).firstOrNull;

  /// Date-based smart lists (a task created in them gets that day's date).
  bool get isDateBased => this == today || this == tomorrow || this == next7Days;

  /// Smart lists of closed or deleted tasks (no add field).
  bool get isReadOnly => this == completed || this == wontDo || this == trash;
}

/// What is open in the middle column.
sealed class Scope {
  const Scope();
}

/// A custom filter.
final class FilterScope extends Scope {
  const FilterScope(this.filterId);
  final String filterId;
  @override
  bool operator ==(Object other) => other is FilterScope && other.filterId == filterId;
  @override
  int get hashCode => Object.hash('filter', filterId);
}

final class ListScope extends Scope {
  const ListScope(this.listId);
  final String listId;
  @override
  bool operator ==(Object other) => other is ListScope && other.listId == listId;
  @override
  int get hashCode => listId.hashCode;
}

final class FolderScope extends Scope {
  const FolderScope(this.folderId);
  final String folderId;
  @override
  bool operator ==(Object other) => other is FolderScope && other.folderId == folderId;
  @override
  int get hashCode => folderId.hashCode;
}

final class TagScope extends Scope {
  const TagScope(this.tagId);
  final String tagId;
  @override
  bool operator ==(Object other) => other is TagScope && other.tagId == tagId;
  @override
  int get hashCode => tagId.hashCode;
}

final class SmartScope extends Scope {
  const SmartScope(this.smartList);
  final SmartList smartList;
  @override
  bool operator ==(Object other) => other is SmartScope && other.smartList == smartList;
  @override
  int get hashCode => smartList.hashCode;
}

/// Group header, described by meaning; the UI turns it into localized text.
sealed class GroupHeader {
  const GroupHeader();
}

/// Group without a header (a flat list).
final class NoHeader extends GroupHeader {
  const NoHeader();
}

final class PinnedHeader extends GroupHeader {
  const PinnedHeader();
}

final class UnpinnedHeader extends GroupHeader {
  const UnpinnedHeader();
}

/// Tasks without a section in a sectioned list.
final class UnsectionedHeader extends GroupHeader {
  const UnsectionedHeader();
}

final class SectionHeader extends GroupHeader {
  const SectionHeader(this.name);
  final String name;
}

final class OverdueHeader extends GroupHeader {
  const OverdueHeader();
}

/// A specific day ("Quinta-feira, Hoje", "Sábado, 26 setembro").
final class DayHeader extends GroupHeader {
  const DayHeader(this.day);
  final DateTime day;
}

final class Next7DaysHeader extends GroupHeader {
  const Next7DaysHeader();
}

final class LaterHeader extends GroupHeader {
  const LaterHeader();
}

final class NoDateHeader extends GroupHeader {
  const NoDateHeader();
}

final class PriorityHeader extends GroupHeader {
  const PriorityHeader(this.priority);
  final Priority priority;
}

final class TagHeader extends GroupHeader {
  const TagHeader(this.name);
  final String name;
}

final class NoTagHeader extends GroupHeader {
  const NoTagHeader();
}

final class ListHeader extends GroupHeader {
  const ListHeader(this.listId);
  final String listId;
}

/// Completed (and won't-do) tasks at the end of a view.
final class ClosedHeader extends GroupHeader {
  const ClosedHeader({required this.includesWontDo});
  final bool includesWontDo;
}

/// A task row ready for the screen.
class TaskRow {
  const TaskRow({
    required this.task,
    required this.depth,
    required this.hasChildren,
    required this.isCollapsed,
    required this.tags,
    required this.list,
    required this.checklistProgress,
    this.hasReminders = false,
    this.hasAttachment = false,
  });

  final Task task;

  /// Shows the alarm icon next to the date.
  final bool hasReminders;

  /// Shows the paperclip in the row.
  final bool hasAttachment;

  /// Subtask depth (0 = top level).
  final int depth;
  final bool hasChildren;
  final bool isCollapsed;
  final List<Tag> tags;

  /// The task's list, shown in the row when the scope is not that list (smart list, tag, folder).
  final TaskList? list;

  /// Checklist progress (0-100) when the task is in checklist mode.
  final int? checklistProgress;

  bool get hasContent => task.content.trim().isNotEmpty;
}

class TaskGroup {
  const TaskGroup({required this.key, required this.header, required this.rows, this.isClosed = false, this.sectionId});

  final String key;
  final GroupHeader header;
  final List<TaskRow> rows;

  /// Completed / won't-do group (shows 5 rows plus "Ver mais").
  final bool isClosed;

  /// Section of the list (for "add to section"); null for unsectioned and other groups.
  final String? sectionId;
}

enum EmptyState { inbox, list, notes, tag, smart, completed, wontDo, trash }

/// What the "add task" field shows as hint.
sealed class AddHint {
  const AddHint();
}

/// "Adicionar tarefa".
final class AddPlainHint extends AddHint {
  const AddPlainHint();
}

/// "Adicionar nota".
final class AddNoteHint extends AddHint {
  const AddNoteHint();
}

/// `Adicionar tarefa a '[list]'`.
final class AddToListHint extends AddHint {
  const AddToListHint(this.listId);
  final String listId;
}

/// `Adicionar tarefa a '#[tag]'`.
final class AddToTagHint extends AddHint {
  const AddToTagHint(this.tagId);
  final String tagId;
}

/// Where the "add task" field creates and with which defaults.
class AddTarget {
  const AddTarget({required this.listId, required this.hint, this.dueDate, this.tagId, this.usesDefaultList = false});

  final String listId;

  /// Outside a list (smart lists, tags, filters) the task goes to the "Lista padrão".
  final bool usesDefaultList;

  /// The target with another list (the "Lista padrão"); a hint naming the list names the new one.
  AddTarget withList(String listId) => AddTarget(
    listId: listId,
    hint: hint is AddToListHint ? AddToListHint(listId) : hint,
    dueDate: dueDate,
    tagId: tagId,
    usesDefaultList: usesDefaultList,
  );
  final AddHint hint;
  final DateTime? dueDate;
  final String? tagId;
}

class ViewContent {
  const ViewContent({required this.groups, required this.emptyState, this.addTarget});

  final List<TaskGroup> groups;
  final EmptyState emptyState;

  /// Null for scopes without an add field.
  final AddTarget? addTarget;

  bool get isEmpty => groups.every((g) => g.rows.isEmpty);
}

/// Display options of a scope (sort button and "…" menu).
class ViewOptions {
  const ViewOptions({
    this.grouping = Grouping.custom,
    this.sorting = Sorting.custom,
    this.showCompleted = true,
    this.descending = false,
    this.showDetails = false,
  });

  final Grouping grouping;
  final Sorting sorting;
  final bool showCompleted;

  /// "Ordem: Decrescente" of the groups; pinned stay first and closed last.
  final bool descending;

  /// "Mostrar detalhes": content preview, tag chips and subtask count under each title.
  final bool showDetails;

  ViewOptions copyWith({Grouping? grouping, Sorting? sorting, bool? showCompleted, bool? descending, bool? showDetails}) => ViewOptions(
    grouping: grouping ?? this.grouping,
    sorting: sorting ?? this.sorting,
    showCompleted: showCompleted ?? this.showCompleted,
    descending: descending ?? this.descending,
    showDetails: showDetails ?? this.showDetails,
  );
}

/// Smart lists group and sort by date by default.
const smartListDefaultOptions = ViewOptions(grouping: Grouping.date, sorting: Sorting.date);

/// [overdueLast]: the "Atrasadas" section at the end (Settings → Mais configurações).
ViewContent buildView(
  Snapshot s,
  Scope scope,
  DateTime now, {
  ViewOptions options = const ViewOptions(),
  Set<String> collapsed = const {},
  bool overdueLast = false,
  ClosedFilter closedFilter = const ClosedFilter(),
  bool withSublists = false,
}) {
  final today = startOfDay(now);
  return switch (scope) {
    SmartScope(smartList: SmartList.completed) => _closedByDay(s, TaskStatus.completed, EmptyState.completed, closedFilter, today),
    SmartScope(smartList: SmartList.wontDo) => _closedByDay(s, TaskStatus.wontDo, EmptyState.wontDo, closedFilter, today),
    SmartScope(smartList: SmartList.trash) => _trash(s),
    SmartScope(smartList: SmartList.summary) => const ViewContent(groups: [], emptyState: EmptyState.smart),
    _ => _taskView(s, scope, today, options, collapsed, overdueLast: overdueLast, withSublists: withSublists),
  };
}

/// [withSublists]: a list's view ("Incluir sublistas") also shows the tasks of its sublists, grouped by
/// sublist when grouped by the list's own order.
ViewContent _taskView(
  Snapshot s,
  Scope scope,
  DateTime today,
  ViewOptions options,
  Set<String> collapsed, {
  bool overdueLast = false,
  bool withSublists = false,
}) {
  final filter = scope is FilterScope ? s.filterById[scope.filterId] : null;
  final sublists = scope is ListScope && withSublists ? s.sublistsDeep(scope.listId) : const <TaskList>[];
  final sublistIds = {for (final l in sublists) l.id};
  final rule = filter == null ? null : FilterRule.decode(filter.rule);
  bool isCandidate(Task t) {
    if (t.deletedAt != null) return false;
    final list = s.listById[t.listId];
    if (list == null || list.deletedAt != null) return false;
    final toStart = t.daysToStart(today);
    return switch (scope) {
      ListScope(:final listId) => t.listId == listId || sublistIds.contains(t.listId),
      FolderScope(:final folderId) => list.folderId == folderId && list.archivedAt == null,
      TagScope(:final tagId) => s.tagsOf(t.id).any((tag) => tag.id == tagId || tag.parentId == tagId) && list.archivedAt == null,
      SmartScope(:final smartList) =>
        s.inSmartLists(t) &&
            switch (smartList) {
              SmartList.all => true,
              // Overdue tasks and tasks already under way count as today (a task with a "Duração").
              SmartList.today => toStart != null && toStart <= 0,
              SmartList.tomorrow => t.isOn(today.add(const Duration(days: 1))),
              SmartList.next7Days => toStart != null && toStart <= 6,
              _ => false,
            },
      FilterScope() => rule != null && filterMatches(s, t, rule, today),
    };
  }

  final candidates = s.tasks.where(isCandidate).toList();
  final open = candidates.where((t) => t.status == TaskStatus.open).toList();
  final openIds = {for (final t in open) t.id};
  final roots = open.where((t) => t.parentId == null || !openIds.contains(t.parentId)).toList();
  final showList = scope is! ListScope;

  TaskRow row(Task t, int depth) {
    final children = s.childrenOf(t.id).where((c) => openIds.contains(c.id));
    final items = t.kind == TaskKind.checklist ? s.itemsOf(t.id) : const <ChecklistItem>[];
    return TaskRow(
      task: t,
      depth: depth,
      hasChildren: children.isNotEmpty,
      isCollapsed: collapsed.contains(t.id),
      tags: s.tagsOf(t.id),
      list: showList || sublistIds.contains(t.listId) ? s.listById[t.listId] : null,
      checklistProgress: t.kind == TaskKind.checklist && items.isNotEmpty
          ? (100 * items.where((i) => i.isCompleted).length / items.length).round()
          : null,
      hasReminders: ReminderPresets.firing(s.remindersOf(t.id)).isNotEmpty,
      hasAttachment: _attachmentPattern.hasMatch(t.content),
    );
  }

  // Open subtasks right below their parent, in any grouping.
  List<TaskRow> withChildren(Task t, int depth) {
    final r = row(t, depth);
    if (r.isCollapsed || depth >= 4) return [r];
    final children = s.childrenOf(t.id).where((c) => openIds.contains(c.id)).toList();
    return [r, for (final c in children) ...withChildren(c, depth + 1)];
  }

  List<TaskRow> sortAndExpand(List<Task> tasks) => [for (final t in _sort(tasks, options.sorting, s)) ...withChildren(t, 0)];

  final groups = <TaskGroup>[];
  final pinned = roots.where((t) => t.pinnedAt != null).toList()..sort((a, b) => b.pinnedAt!.compareTo(a.pinnedAt!));
  final unpinned = roots.where((t) => t.pinnedAt == null).toList();
  if (pinned.isNotEmpty) {
    groups.add(TaskGroup(key: 'pinned', header: const PinnedHeader(), rows: [for (final t in pinned) ...withChildren(t, 0)]));
  }

  /// A list's tasks by section: "unsectioned" first, then one group per section.
  List<TaskGroup> bySection(String listId, List<Task> tasks) {
    final sections = s.sectionsOf(listId);
    final sectionIds = {for (final sec in sections) sec.id};
    return [
      TaskGroup(
        key: 'section:',
        header: const UnsectionedHeader(),
        rows: sortAndExpand(tasks.where((t) => t.sectionId == null || !sectionIds.contains(t.sectionId)).toList()),
      ),
      for (final sec in sections)
        TaskGroup(
          key: 'section:${sec.id}',
          header: SectionHeader(sec.name),
          sectionId: sec.id,
          rows: sortAndExpand(tasks.where((t) => t.sectionId == sec.id).toList()),
        ),
    ];
  }

  final dayByDay = scope is SmartScope && scope.smartList == SmartList.next7Days;
  switch (options.grouping) {
    // "Incluir sublistas": the list's own tasks (by section when it has them), then each sublist's.
    case Grouping.custom when scope is ListScope && sublists.isNotEmpty:
      final own = unpinned.where((t) => t.listId == scope.listId).toList();
      if (s.sectionsOf(scope.listId).isNotEmpty) {
        groups.addAll(bySection(scope.listId, own));
      } else if (own.isNotEmpty) {
        groups.add(TaskGroup(key: 'list:${scope.listId}', header: ListHeader(scope.listId), rows: sortAndExpand(own)));
      }
      for (final l in sublists) {
        final tasks = unpinned.where((t) => t.listId == l.id).toList();
        if (tasks.isNotEmpty) groups.add(TaskGroup(key: 'list:${l.id}', header: ListHeader(l.id), rows: sortAndExpand(tasks)));
      }
    case Grouping.custom when scope is ListScope && s.sectionsOf(scope.listId).isNotEmpty:
      groups.addAll(bySection(scope.listId, unpinned));
    case Grouping.custom when scope is FolderScope:
      // Sublists right under their parent list.
      for (final (l, _) in s.listTree(s.activeLists.where((l) => l.folderId == scope.folderId))) {
        final tasks = unpinned.where((t) => t.listId == l.id).toList();
        if (tasks.isNotEmpty) groups.add(TaskGroup(key: 'list:${l.id}', header: ListHeader(l.id), rows: sortAndExpand(tasks)));
      }
    case Grouping.date:
      final byKey = <String, List<Task>>{};
      final headers = <String, GroupHeader>{};
      for (final t in unpinned) {
        final (key, header) = _dateGroup(t, today, dayByDay: dayByDay, overdueLast: overdueLast);
        (byKey[key] ??= []).add(t);
        headers[key] = header;
      }
      for (final key in byKey.keys.toList()..sort()) {
        groups.add(TaskGroup(key: 'date:$key', header: headers[key]!, rows: sortAndExpand(byKey[key]!)));
      }
    case Grouping.list:
      for (final l in s.activeLists) {
        final tasks = unpinned.where((t) => t.listId == l.id).toList();
        if (tasks.isNotEmpty) groups.add(TaskGroup(key: 'list:${l.id}', header: ListHeader(l.id), rows: sortAndExpand(tasks)));
      }
    case Grouping.priority:
      for (final p in Priority.values.reversed) {
        final tasks = unpinned.where((t) => t.priority == p).toList();
        if (tasks.isNotEmpty) groups.add(TaskGroup(key: 'priority:${p.code}', header: PriorityHeader(p), rows: sortAndExpand(tasks)));
      }
    case Grouping.tag:
      final byTag = <String, List<Task>>{};
      for (final t in unpinned) {
        final tags = s.tagsOf(t.id);
        (byTag[tags.isEmpty ? '' : tags.first.name] ??= []).add(t);
      }
      final names = byTag.keys.where((n) => n.isNotEmpty).toList()..sort();
      for (final n in [...names, if (byTag.containsKey('')) '']) {
        groups.add(TaskGroup(key: 'tag:$n', header: n.isEmpty ? const NoTagHeader() : TagHeader(n), rows: sortAndExpand(byTag[n]!)));
      }
    case Grouping.custom || Grouping.modifiedTime || Grouping.none:
      groups.add(TaskGroup(key: 'unpinned', header: pinned.isNotEmpty ? const UnpinnedHeader() : const NoHeader(), rows: sortAndExpand(unpinned)));
  }

  if (options.descending) {
    final first = pinned.isNotEmpty ? 1 : 0;
    final rest = groups.sublist(first).reversed.toList();
    groups
      ..removeRange(first, groups.length)
      ..addAll(rest);
  }

  // Completed and won't-do tasks at the end, in a collapsible group.
  if (options.showCompleted) {
    final closed = candidates.where((t) {
      if (t.status == TaskStatus.open) return false;
      if (scope is SmartScope && scope.smartList == SmartList.today) {
        final c = t.completedAt;
        return c != null && daysBetween(today, c.toLocal()) == 0;
      }
      return true;
    }).toList()..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));
    if (closed.isNotEmpty) {
      groups.add(
        TaskGroup(
          key: 'closed',
          header: ClosedHeader(includesWontDo: closed.any((t) => t.status == TaskStatus.wontDo)),
          isClosed: true,
          rows: [for (final t in closed) row(t, 0)],
        ),
      );
    }
  }

  final currentList = scope is ListScope ? s.listById[scope.listId] : null;
  final isNotes = currentList?.kind == ListKind.notes;
  return ViewContent(
    groups: groups,
    addTarget: _addTarget(s, scope, today, isNotes: isNotes),
    emptyState: switch (scope) {
      ListScope() when isNotes => EmptyState.notes,
      ListScope(:final listId) when listId == inboxListId => EmptyState.inbox,
      ListScope() => EmptyState.list,
      TagScope() => EmptyState.tag,
      _ => EmptyState.smart,
    },
  );
}

/// Where the add field creates ("Adicionar tarefa a 'Caixa de Entrada'").
AddTarget? _addTarget(Snapshot s, Scope scope, DateTime today, {required bool isNotes}) => switch (scope) {
  ListScope(:final listId) => AddTarget(listId: listId, hint: isNotes ? const AddNoteHint() : const AddPlainHint()),
  FolderScope(:final folderId) => switch (s.activeLists.where((l) => l.folderId == folderId).firstOrNull) {
    null => null,
    final first => AddTarget(listId: first.id, hint: AddToListHint(first.id)),
  },
  TagScope(:final tagId) => AddTarget(listId: inboxListId, tagId: tagId, hint: AddToTagHint(tagId), usesDefaultList: true),
  FilterScope() => const AddTarget(listId: inboxListId, hint: AddPlainHint(), usesDefaultList: true),
  SmartScope(:final smartList) =>
    smartList.isReadOnly
        ? null
        : AddTarget(
            listId: inboxListId,
            hint: const AddToListHint(inboxListId),
            usesDefaultList: true,
            dueDate: switch (smartList) {
              SmartList.today || SmartList.next7Days => today,
              SmartList.tomorrow => today.add(const Duration(days: 1)),
              _ => null,
            },
          ),
};

/// Date group: sortable key and header. Overdue first; no date last.
(String, GroupHeader) _dateGroup(Task t, DateTime today, {required bool dayByDay, bool overdueLast = false}) {
  final toEnd = t.daysToEnd(today), toStart = t.daysToStart(today);
  if (toEnd == null || toStart == null) return ('9', const NoDateHeader());
  if (toEnd < 0) return (overdueLast ? '8' : '0', const OverdueHeader());
  // A task under way sits on today.
  final days = toStart < 0 ? 0 : toStart;
  if (days <= 1 || (dayByDay && days <= 6)) return ('1${days.toString().padLeft(2, '0')}', DayHeader(today.add(Duration(days: days))));
  if (days <= 6) return ('2', const Next7DaysHeader());
  return ('3', const LaterHeader());
}

List<Task> _sort(List<Task> tasks, Sorting sorting, Snapshot s) {
  int byOrder(Task a, Task b) => a.sortOrder.compareTo(b.sortOrder);
  int byDate(Task a, Task b) {
    final da = a.startDate ?? a.dueDate, db = b.startDate ?? b.dueDate;
    if (da == null && db == null) return byOrder(a, b);
    if (da == null) return 1;
    if (db == null) return -1;
    final c = da.compareTo(db);
    return c != 0 ? c : byOrder(a, b);
  }

  return [...tasks]..sort(switch (sorting) {
    Sorting.custom => byOrder,
    Sorting.date => byDate,
    Sorting.title => (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    Sorting.priority => (a, b) {
      final c = b.priority.code.compareTo(a.priority.code);
      return c != 0 ? c : byDate(a, b);
    },
    Sorting.createdTime => (a, b) => b.createdAt.compareTo(a.createdAt),
    Sorting.modifiedTime => (a, b) => b.updatedAt.compareTo(a.updatedAt),
    Sorting.tag => (a, b) {
      String name(Task t) => s.tagsOf(t.id).firstOrNull?.name ?? '\u{10FFFF}';
      final c = name(a).compareTo(name(b));
      return c != 0 ? c : byOrder(a, b);
    },
  });
}

/// Completed / Won't do: grouped by the day they were closed.
/// "Todas as datas" of Concluído and Não será feito.
enum ClosedDate { all, thisWeek, lastWeek, thisMonth, otherMonth }

/// Filters of Concluído and Não será feito: when the task was closed and its list (null = all).
class ClosedFilter {
  const ClosedFilter({this.date = ClosedDate.all, this.month, this.listId});

  final ClosedDate date;

  /// First day of the month of "Outro mês".
  final DateTime? month;
  final String? listId;

  bool get isDefault => date == ClosedDate.all && listId == null;

  /// Whether a task closed at [closed] (local) in [taskListId] passes, [today] being today.
  bool matches(DateTime closed, String taskListId, DateTime today) => _within(closed, taskListId, window(today));

  /// The [from, to) days of [date] around [today]; null ends are open. Worked out once per view:
  /// building local dates is slow enough to matter over thousands of closed tasks.
  (DateTime?, DateTime?) window(DateTime today) {
    final week = startOfWeek(today);
    return switch (date) {
      ClosedDate.all => (null, null),
      ClosedDate.thisWeek => (week, DateTime(week.year, week.month, week.day + 7)),
      ClosedDate.lastWeek => (DateTime(week.year, week.month, week.day - 7), week),
      ClosedDate.thisMonth => (DateTime(today.year, today.month), DateTime(today.year, today.month + 1)),
      ClosedDate.otherMonth => month == null ? (null, null) : (month, DateTime(month!.year, month!.month + 1)),
    };
  }

  bool _within(DateTime closed, String taskListId, (DateTime?, DateTime?) window) {
    if (listId != null && taskListId != listId) return false;
    final (from, to) = window;
    return (from == null || !closed.isBefore(from)) && (to == null || closed.isBefore(to));
  }
}

ViewContent _closedByDay(Snapshot s, TaskStatus status, EmptyState empty, ClosedFilter filter, DateTime today) {
  final window = filter.window(today);
  final tasks =
      s.tasks
          .where(
            (t) =>
                t.deletedAt == null &&
                t.status == status &&
                s.listById[t.listId]?.deletedAt == null &&
                filter._within((t.completedAt ?? t.updatedAt).toLocal(), t.listId, window),
          )
          .toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));
  // Grouped by a y/m/d number; the day's DateTime is built once per day, not once per task.
  final byDay = <int, List<Task>>{};
  final days = <int, DateTime>{};
  for (final t in tasks) {
    final at = (t.completedAt ?? t.updatedAt).toLocal();
    final key = at.year * 10000 + at.month * 100 + at.day;
    (byDay[key] ??= []).add(t);
    days[key] ??= startOfDay(at);
  }
  return ViewContent(
    emptyState: empty,
    groups: [
      for (final e in byDay.entries)
        TaskGroup(
          key: 'day:${days[e.key]!.toIso8601String()}',
          header: DayHeader(days[e.key]!),
          rows: [
            for (final t in e.value)
              TaskRow(
                task: t,
                depth: 0,
                hasChildren: false,
                isCollapsed: false,
                tags: s.tagsOf(t.id),
                list: s.listById[t.listId],
                checklistProgress: null,
              ),
          ],
        ),
    ],
  );
}

/// Trash: deleted tasks; subtasks stay collapsed inside their parent.
ViewContent _trash(Snapshot s) {
  final deleted = s.tasks.where((t) => t.deletedAt != null).toList();
  final ids = {for (final t in deleted) t.id};
  final roots = deleted.where((t) => t.parentId == null || !ids.contains(t.parentId)).toList()..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  return ViewContent(
    emptyState: EmptyState.trash,
    groups: [
      TaskGroup(
        key: 'trash',
        header: const NoHeader(),
        rows: [
          for (final t in roots)
            TaskRow(
              task: t,
              depth: 0,
              hasChildren: deleted.any((c) => c.parentId == t.id),
              isCollapsed: true,
              tags: s.tagsOf(t.id),
              list: s.listById[t.listId],
              checklistProgress: null,
            ),
        ],
      ),
    ],
  );
}

/// Open-task counts shown in the sidebar (subtasks included, as in TickTick).
class Counts {
  /// [includeNotes] false: "Mostrar (Ocultar Nota)" counts only tasks.
  Counts(Snapshot s, DateTime now, {bool includeNotes = true}) {
    final today = startOfDay(now);
    final rules = {for (final f in s.filters) f.id: FilterRule.decode(f.rule)};
    for (final t in s.tasks) {
      if (!Snapshot.isOpen(t) || (!includeNotes && t.kind == TaskKind.note)) continue;
      for (final r in rules.entries) {
        if (filterMatches(s, t, r.value, today)) byFilter[r.key] = (byFilter[r.key] ?? 0) + 1;
      }
      final list = s.listById[t.listId];
      if (list == null || list.deletedAt != null) continue;
      byList[t.listId] = (byList[t.listId] ?? 0) + 1;
      final folder = list.folderId;
      if (folder != null && list.archivedAt == null) byFolder[folder] = (byFolder[folder] ?? 0) + 1;
      for (final tag in s.tagsOf(t.id)) {
        byTag[tag.id] = (byTag[tag.id] ?? 0) + 1;
        final parent = tag.parentId;
        if (parent != null) byTag[parent] = (byTag[parent] ?? 0) + 1;
      }
      if (!s.inSmartLists(t)) continue;
      _add(SmartList.all);
      final toStart = t.daysToStart(today);
      if (toStart == null) continue;
      if (toStart <= 0) _add(SmartList.today);
      if (t.isOn(today.add(const Duration(days: 1)))) _add(SmartList.tomorrow);
      if (toStart <= 6) _add(SmartList.next7Days);
    }
  }

  final Map<String, int> byList = {};
  final Map<String, int> byFolder = {};
  final Map<String, int> byTag = {};
  final Map<String, int> byFilter = {};
  final Map<SmartList, int> bySmartList = {};

  void _add(SmartList l) => bySmartList[l] = (bySmartList[l] ?? 0) + 1;
}

/// `![file](<id>/<name>)`: an attachment in the content (see the markdown codec).
final _attachmentPattern = RegExp(r'!\[[^\]]*\]\([^)/\s:]+/[^)]+\)');

/// "Experimente Tarefas Sugeridas" of Hoje: open tasks to plan the day with — overdue,
/// the next days' and, the most important first, some without a date.
({List<Task> overdue, List<Task> upcoming, List<Task> noDate}) suggestedForToday(Snapshot s, DateTime now, {int noDateLimit = 10}) {
  final today = startOfDay(now);
  final open = [
    for (final t in s.tasks)
      if (Snapshot.isOpen(t) && t.parentId == null && t.kind != TaskKind.note && s.inSmartLists(t)) t,
  ];
  int byDate(Task a, Task b) => (a.endLocal ?? today).compareTo(b.endLocal ?? today);
  final overdue = [
    for (final t in open)
      if (t.daysToEnd(today) case final d? when d < 0) t,
  ]..sort(byDate);
  final upcoming = [
    for (final t in open)
      if (t.daysToStart(today) case final d? when d >= 1 && d <= 7) t,
  ]..sort(byDate);
  final noDate = [
    for (final t in open)
      if (t.dueDate == null) t,
  ]..sort((a, b) => b.priority.code != a.priority.code ? b.priority.code.compareTo(a.priority.code) : b.createdAt.compareTo(a.createdAt));
  return (overdue: overdue, upcoming: upcoming, noDate: noDate.take(noDateLimit).toList());
}
