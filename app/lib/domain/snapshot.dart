import '../data/db/database.dart';
import 'enums.dart';

/// In-memory picture of everything the task screens need. The database emits a new snapshot on
/// every change; every view (list, smart list, tag, folder) is derived from it by pure functions.
class Snapshot {
  Snapshot({
    required this.folders,
    required this.lists,
    required this.sections,
    required this.tasks,
    required this.checklistItems,
    required this.tags,
    required this.taskTags,
    this.reminders = const [],
    this.countdowns = const [],
    this.habits = const [],
    this.habitCheckins = const [],
    this.filters = const [],
  }) {
    for (final f in filters) {
      filterById[f.id] = f;
    }
    for (final c in habitCheckins) {
      (checkinsByHabit[c.habitId] ??= []).add(c);
    }
    for (final r in reminders) {
      (remindersByTask[r.taskId] ??= []).add(r.trigger);
    }
    for (final l in lists) {
      listById[l.id] = l;
    }
    for (final f in folders) {
      folderById[f.id] = f;
    }
    for (final t in tags) {
      tagById[t.id] = t;
    }
    for (final t in tasks) {
      taskById[t.id] = t;
      final parent = t.parentId;
      if (parent != null) (childrenByParent[parent] ??= []).add(t);
    }
    for (final i in checklistItems) {
      (itemsByTask[i.taskId] ??= []).add(i);
    }
    for (final items in itemsByTask.values) {
      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    for (final r in taskTags) {
      final tag = tagById[r.tagId];
      if (tag != null) (tagsByTask[r.taskId] ??= []).add(tag);
    }
  }

  Snapshot.empty()
    : this(folders: const [], lists: const [], sections: const [], tasks: const [], checklistItems: const [], tags: const [], taskTags: const []);

  final List<Folder> folders;
  final List<TaskList> lists;
  final List<Section> sections;
  final List<Task> tasks;
  final List<ChecklistItem> checklistItems;
  final List<Tag> tags;
  final List<TaskTag> taskTags;
  final List<TaskReminder> reminders;

  /// Countdowns that are not deleted.
  final List<Countdown> countdowns;

  /// Habits in manual order and every check-in.
  final List<Habit> habits;
  final List<HabitCheckin> habitCheckins;
  final Map<String, List<HabitCheckin>> checkinsByHabit = {};

  List<HabitCheckin> checkinsOf(String habitId) => checkinsByHabit[habitId] ?? const [];

  /// Custom filters.
  final List<TaskFilter> filters;
  final Map<String, TaskFilter> filterById = {};

  final Map<String, TaskList> listById = {};
  final Map<String, Folder> folderById = {};
  final Map<String, Tag> tagById = {};
  final Map<String, Task> taskById = {};
  final Map<String, List<Task>> childrenByParent = {};
  final Map<String, List<ChecklistItem>> itemsByTask = {};
  final Map<String, List<Tag>> tagsByTask = {};
  final Map<String, List<String>> remindersByTask = {};

  /// Lists shown in the sidebar (not deleted nor archived), in manual order.
  List<TaskList> get activeLists =>
      lists.where((l) => l.deletedAt == null && l.archivedAt == null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<TaskList> get archivedLists =>
      lists.where((l) => l.deletedAt == null && l.archivedAt != null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Folder> get activeFolders => folders.where((f) => f.deletedAt == null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Active sublists by their parent list, in manual order (worked out once: the sidebar asks per row).
  late final Map<String, List<TaskList>> _sublists = () {
    final map = <String, List<TaskList>>{};
    for (final l in activeLists) {
      final parent = l.parentId;
      if (parent != null) (map[parent] ??= []).add(l);
    }
    return map;
  }();

  /// The active lists right inside [listId].
  List<TaskList> sublistsOf(String listId) => _sublists[listId] ?? const [];

  /// The active (not archived) list [l] hangs under; null at the top, and also when the parent is
  /// archived or gone (the sublist then shows at the top).
  TaskList? activeParentOf(TaskList l) {
    final parent = l.parentId == null ? null : listById[l.parentId];
    return parent == null || parent.deletedAt != null || parent.archivedAt != null ? null : parent;
  }

  /// Level of [l] among the lists: 0 at the top, up to 2 (three levels).
  int listDepth(TaskList l) {
    var depth = 0;
    for (var p = activeParentOf(l); p != null && depth < 10; p = activeParentOf(p)) {
      depth++;
    }
    return depth;
  }

  /// The active lists under [listId] at any depth, each parent before its sublists.
  List<TaskList> sublistsDeep(String listId) => [
    for (final child in sublistsOf(listId)) ...[child, ...sublistsDeep(child.id)],
  ];

  /// [lists] in tree order with their depth: each list followed by its sublists among [lists]. A list
  /// whose parent is not among them is a root.
  List<(TaskList, int)> listTree(Iterable<TaskList> lists) {
    final among = {for (final l in lists) l.id: l};
    final result = <(TaskList, int)>[];
    void visit(TaskList l, int depth) {
      result.add((l, depth));
      for (final child in sublistsOf(l.id)) {
        if (among.containsKey(child.id) && depth < 10) visit(child, depth + 1);
      }
    }

    for (final l in among.values) {
      if (l.parentId == null || !among.containsKey(l.parentId) || activeParentOf(l) == null) visit(l, 0);
    }
    return result;
  }

  List<Tag> get activeTags => tags.where((t) => t.deletedAt == null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Section> sectionsOf(String listId) =>
      sections.where((s) => s.listId == listId && s.deletedAt == null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Task> childrenOf(String taskId) =>
      (childrenByParent[taskId] ?? const <Task>[]).where((t) => t.deletedAt == null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<ChecklistItem> itemsOf(String taskId) => (itemsByTask[taskId] ?? const <ChecklistItem>[]).where((i) => i.deletedAt == null).toList();

  List<Tag> tagsOf(String taskId) => tagsByTask[taskId] ?? const [];

  /// Reminder triggers of a task (see domain/reminders.dart).
  List<String> remindersOf(String taskId) => remindersByTask[taskId] ?? const [];

  /// Whether the task's list takes part in the smart lists (not archived, "Show in Smart List" on).
  bool inSmartLists(Task t) {
    final l = listById[t.listId];
    return l != null && l.deletedAt == null && l.archivedAt == null && l.showInSmartLists;
  }

  /// Parent chain (top-most first) of a subtask.
  List<Task> ancestorsOf(Task t) {
    final chain = <Task>[];
    var current = t.parentId == null ? null : taskById[t.parentId];
    while (current != null && chain.length < 10) {
      chain.insert(0, current);
      current = current.parentId == null ? null : taskById[current.parentId];
    }
    return chain;
  }

  static bool isOpen(Task t) => t.deletedAt == null && t.status == TaskStatus.open;
}
