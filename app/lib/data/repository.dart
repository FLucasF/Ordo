import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../core/time_zones.dart';
import '../core/sort_order.dart';
import '../domain/enums.dart';
import '../domain/task_dates.dart';
import '../domain/filters.dart';
import '../domain/focus.dart';
import '../domain/recurrence.dart';
import '../domain/snapshot.dart';
import 'db/database.dart';

/// A broken business rule. The UI shows the localized message for [rule].
class RuleViolation implements Exception {
  const RuleViolation(this.rule);
  final Rule rule;
  @override
  String toString() => 'RuleViolation($rule)';
}

enum Rule { inboxCannotBeArchived, inboxCannotBeDeleted, taskCannotBeItsOwnParent, subtaskDepthLimit, taskWithSubtasksCannotBecomeNote, tagNameTaken }

/// Every write of the app. Created/updated/deleted times are UTC.
class Repository {
  Repository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  // ------------------------------------------------------------------ reading

  /// Emits a fresh snapshot on every change to any task-related table.
  Stream<Snapshot> watchSnapshot() => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _db.folders,
          _db.lists,
          _db.sections,
          _db.tasks,
          _db.checklistItems,
          _db.tags,
          _db.taskTags,
          _db.taskReminders,
          _db.countdowns,
          _db.habits,
          _db.habitCheckins,
          _db.filters,
        },
      )
      .watch()
      .asyncMap((_) => loadSnapshot());

  Future<Snapshot> loadSnapshot() => _db.transaction(
    () async => Snapshot(
      folders: await _db.select(_db.folders).get(),
      lists: await _db.select(_db.lists).get(),
      sections: await _db.select(_db.sections).get(),
      tasks: await _db.select(_db.tasks).get(),
      checklistItems: await _db.select(_db.checklistItems).get(),
      tags: await _db.select(_db.tags).get(),
      taskTags: await _db.select(_db.taskTags).get(),
      reminders: await _db.select(_db.taskReminders).get(),
      countdowns: await (_db.select(_db.countdowns)..where((c) => c.deletedAt.isNull())).get(),
      habits:
          await (_db.select(_db.habits)
                ..where((h) => h.deletedAt.isNull())
                ..orderBy([(h) => OrderingTerm(expression: h.sortOrder)]))
              .get(),
      habitCheckins: await _db.select(_db.habitCheckins).get(),
      filters:
          await (_db.select(_db.filters)
                ..where((f) => f.deletedAt.isNull())
                ..orderBy([(f) => OrderingTerm(expression: f.sortOrder)]))
              .get(),
    ),
  );

  Future<Task> task(String id) => (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle();

  // ------------------------------------------------------------------ folders

  Future<String> createFolder(String name) async {
    final id = newId();
    final last = await _maxTopOrder();
    await _db
        .into(_db.folders)
        .insert(FoldersCompanion.insert(id: id, createdAt: _now, updatedAt: _now, name: name.trim(), sortOrder: SortOrder.after(last)));
    return id;
  }

  Future<void> renameFolder(String id, String name) =>
      (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(FoldersCompanion(name: Value(name.trim()), updatedAt: Value(_now)));

  Future<void> pinFolder(String id, {required bool pinned}) =>
      (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(FoldersCompanion(pinnedAt: Value(pinned ? _now : null), updatedAt: Value(_now)));

  Future<void> setFolderCollapsed(String id, {required bool collapsed}) =>
      (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(FoldersCompanion(isCollapsed: Value(collapsed)));

  /// "Ungroup": the lists leave the folder and the folder goes away.
  Future<void> ungroupFolder(String id) => _db.transaction(() async {
    await (_db.update(_db.lists)..where((l) => l.folderId.equals(id))).write(ListsCompanion(folderId: const Value(null), updatedAt: Value(_now)));
    await (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(FoldersCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
  });

  // ------------------------------------------------------------------ lists

  Future<String> createList({
    required String name,
    String? emoji,
    String? color,
    String? folderId,
    ListKind kind = ListKind.tasks,
    ViewMode viewMode = ViewMode.list,
    bool showInSmartLists = true,
  }) async {
    final id = newId();
    final last = await _maxTopOrder();
    await _db
        .into(_db.lists)
        .insert(
          ListsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: name.trim(),
            emoji: Value(emoji),
            color: Value(color),
            folderId: Value(folderId),
            kind: Value(kind),
            viewMode: Value(viewMode),
            showInSmartLists: Value(showInSmartLists),
            sortOrder: SortOrder.after(last),
          ),
        );
    await _log(ActivityAction.listCreated, listId: id);
    return id;
  }

  Future<void> editList(
    String id, {
    required String name,
    String? emoji,
    String? color,
    String? folderId,
    required ListKind kind,
    required ViewMode viewMode,
    required bool showInSmartLists,
  }) async {
    final before = await (_db.select(_db.lists)..where((l) => l.id.equals(id))).getSingleOrNull();
    await (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
      ListsCompanion(
        name: Value(name.trim()),
        emoji: Value(emoji),
        color: Value(color),
        folderId: Value(folderId),
        kind: Value(kind),
        viewMode: Value(viewMode),
        showInSmartLists: Value(showInSmartLists),
        updatedAt: Value(_now),
      ),
    );
    if (before != null && before.name != name.trim()) await _log(ActivityAction.listTitle, listId: id, detail: name.trim());
  }

  Future<void> setListViewOptions(String id, {Grouping? grouping, Sorting? sorting, bool? showCompleted, bool? showDetails, ViewMode? viewMode}) =>
      (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
        ListsCompanion(
          groupBy: Value.absentIfNull(grouping),
          sortBy: Value.absentIfNull(sorting),
          showCompleted: Value.absentIfNull(showCompleted),
          showDetails: Value.absentIfNull(showDetails),
          viewMode: Value.absentIfNull(viewMode),
          updatedAt: Value(_now),
        ),
      );

  Future<void> pinList(String id, {required bool pinned}) =>
      (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(ListsCompanion(pinnedAt: Value(pinned ? _now : null), updatedAt: Value(_now)));

  Future<void> archiveList(String id, {required bool archived}) {
    if (id == inboxListId) throw const RuleViolation(Rule.inboxCannotBeArchived);
    return (_db.update(
      _db.lists,
    )..where((l) => l.id.equals(id))).write(ListsCompanion(archivedAt: Value(archived ? _now : null), updatedAt: Value(_now)));
  }

  /// Deleting a list sends its tasks to the Trash.
  Future<void> deleteList(String id) {
    if (id == inboxListId) throw const RuleViolation(Rule.inboxCannotBeDeleted);
    return _db.transaction(() async {
      await (_db.update(
        _db.tasks,
      )..where((t) => t.listId.equals(id) & t.deletedAt.isNull())).write(TasksCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
      await (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(ListsCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
    });
  }

  /// A folder's place among the folders and loose lists (dragged in the sidebar).
  Future<void> moveFolder(String id, int sortOrder) =>
      (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(FoldersCompanion(sortOrder: Value(sortOrder), updatedAt: Value(_now)));

  /// Moves a list into a folder (or out of one with `null`) and optionally to [sortOrder].
  Future<void> moveList(String id, {String? folderId, int? sortOrder}) => (_db.update(_db.lists)..where((l) => l.id.equals(id))).write(
    ListsCompanion(folderId: Value(folderId), sortOrder: Value.absentIfNull(sortOrder), updatedAt: Value(_now)),
  );

  /// Duplicate: same settings, sections and open tasks; the name gets " copiar" (as TickTick does).
  /// The suffix is the localized one passed by the UI.
  /// "Duplicar": "[nome] copiar" right above the original, with its sections but not
  /// its color; [mode] says which tasks go and whether they keep their completion.
  Future<String> duplicateList(String id, {required String copySuffix, ListCopyMode mode = ListCopyMode.openOnly}) => _db.transaction(() async {
    final source = await (_db.select(_db.lists)..where((l) => l.id.equals(id))).getSingle();
    final newListId = newId();
    await _db
        .into(_db.lists)
        .insert(
          source.copyWith(
            id: newListId,
            name: '${source.name}$copySuffix',
            createdAt: _now,
            updatedAt: _now,
            pinnedAt: const Value(null),
            color: const Value(null),
            sortOrder: source.sortOrder - 1,
          ),
        );
    final sectionMap = <String, String>{};
    for (final sec in await (_db.select(_db.sections)..where((s) => s.listId.equals(id) & s.deletedAt.isNull())).get()) {
      final copy = newId();
      sectionMap[sec.id] = copy;
      await _db.into(_db.sections).insert(sec.copyWith(id: copy, listId: newListId, createdAt: _now, updatedAt: _now));
    }
    final roots = await (_db.select(_db.tasks)..where((t) => t.listId.equals(id) & t.deletedAt.isNull() & t.parentId.isNull())).get();
    for (final t in roots) {
      if (mode == ListCopyMode.openOnly && t.status != TaskStatus.open) continue;
      await _copyTask(
        t,
        listId: newListId,
        sectionId: t.sectionId == null ? null : sectionMap[t.sectionId],
        parentId: null,
        reopen: mode == ListCopyMode.allReopened,
        openOnly: mode == ListCopyMode.openOnly,
      );
    }
    return newListId;
  });

  // ------------------------------------------------------------------ sections

  /// "Add Section" creates it at the top of the list.
  Future<String> createSection(String listId, String name, {int? sortOrder}) async {
    final id = newId();
    final first =
        await (_db.selectOnly(_db.sections)
              ..addColumns([_db.sections.sortOrder.min()])
              ..where(_db.sections.listId.equals(listId) & _db.sections.deletedAt.isNull()))
            .map((r) => r.read(_db.sections.sortOrder.min()))
            .getSingle();
    await _db
        .into(_db.sections)
        .insert(
          SectionsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            listId: listId,
            name: name.trim(),
            sortOrder: sortOrder ?? SortOrder.before(first),
          ),
        );
    return id;
  }

  Future<void> renameSection(String id, String name) =>
      (_db.update(_db.sections)..where((s) => s.id.equals(id))).write(SectionsCompanion(name: Value(name.trim()), updatedAt: Value(_now)));

  Future<void> reorderSection(String id, int sortOrder) =>
      (_db.update(_db.sections)..where((s) => s.id.equals(id))).write(SectionsCompanion(sortOrder: Value(sortOrder), updatedAt: Value(_now)));

  /// Deleting a section moves its tasks to "unsectioned" (inferred: TickTick behavior not observed).
  Future<void> deleteSection(String id) => _db.transaction(() async {
    await (_db.update(_db.tasks)..where((t) => t.sectionId.equals(id))).write(TasksCompanion(sectionId: const Value(null), updatedAt: Value(_now)));
    await (_db.update(_db.sections)..where((s) => s.id.equals(id))).write(SectionsCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
  });

  /// "Move to" another list: the section and its tasks change list.
  Future<void> moveSectionToList(String id, String listId) => _db.transaction(() async {
    await (_db.update(_db.sections)..where((s) => s.id.equals(id))).write(SectionsCompanion(listId: Value(listId), updatedAt: Value(_now)));
    for (final t in await (_db.select(_db.tasks)..where((t) => t.sectionId.equals(id))).get()) {
      await _moveWithDescendants(t.id, listId);
    }
  });

  // ------------------------------------------------------------------ tasks

  Future<String> createTask({
    required String listId,
    String title = '',
    String content = '',
    String? sectionId,
    String? parentId,
    DateTime? dueDate,
    DateTime? startDate,
    bool isAllDay = true,
    Priority priority = Priority.none,
    TaskKind kind = TaskKind.text,
    Iterable<String> tagIds = const [],
    String? repeatRule,
    RepeatFrom repeatFrom = RepeatFrom.dueDate,
    Iterable<String> reminders = const [],
    String? color,
    bool atTop = true,
  }) => _db.transaction(() async {
    final id = newId();
    final siblings = _db.tasks.listId.equals(listId) & (parentId == null ? _db.tasks.parentId.isNull() : _db.tasks.parentId.equals(parentId));
    final edgeExpr = atTop ? _db.tasks.sortOrder.min() : _db.tasks.sortOrder.max();
    final edge =
        await (_db.selectOnly(_db.tasks)
              ..addColumns([edgeExpr])
              ..where(siblings))
            .map((r) => r.read(edgeExpr))
            .getSingle();
    final list = await (_db.select(_db.lists)..where((l) => l.id.equals(listId))).getSingle();
    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            listId: listId,
            sectionId: Value(sectionId),
            parentId: Value(parentId),
            title: Value(title.trim()),
            content: Value(content),
            kind: Value(list.kind == ListKind.notes ? TaskKind.note : kind),
            priority: Value(priority),
            dueDate: Value(dueDate?.toUtc()),
            startDate: Value(dueDate == null ? null : (startDate != null && startDate.isBefore(dueDate) ? startDate : dueDate).toUtc()),
            isAllDay: Value(isAllDay),
            repeatRule: Value(repeatRule),
            repeatFrom: Value(repeatRule == null ? null : repeatFrom.code),
            color: Value(color),
            sortOrder: atTop ? SortOrder.before(edge) : SortOrder.after(edge),
          ),
        );
    for (final tagId in tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
    for (final trigger in reminders) {
      await _db.into(_db.taskReminders).insert(TaskRemindersCompanion.insert(taskId: id, trigger: trigger));
    }
    await _log(ActivityAction.created, taskId: id, listId: listId);
    return id;
  });

  /// Writes a task and records what changed in its "Atividades" (unless [log] is false).
  Future<void> _update(String id, TasksCompanion c, {bool log = true}) async {
    final before = log ? await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull() : null;
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(c.copyWith(updatedAt: Value(_now)));
    if (before != null) await _logChanges(before, c);
  }

  // ------------------------------------------------------------------ activities

  Future<void> _logChanges(Task before, TasksCompanion c) async {
    final listId = c.listId.present ? c.listId.value : before.listId;
    Future<void> log(ActivityAction action, [String detail = '']) => _log(action, taskId: before.id, listId: listId, detail: detail);
    if (c.status.present && c.status.value != before.status) {
      await log(switch (c.status.value) {
        TaskStatus.completed => ActivityAction.completed,
        TaskStatus.wontDo => ActivityAction.wontDo,
        TaskStatus.open => ActivityAction.reopened,
      });
    }
    if (c.deletedAt.present && (c.deletedAt.value == null) != (before.deletedAt == null)) {
      await log(c.deletedAt.value == null ? ActivityAction.restored : ActivityAction.deleted);
    }
    if (c.title.present && c.title.value != before.title) await log(ActivityAction.title, c.title.value);
    if (c.content.present && c.content.value != before.content) await log(ActivityAction.content);
    if (c.dueDate.present && c.dueDate.value != before.dueDate) {
      final due = c.dueDate.value;
      final allDay = c.isAllDay.present ? c.isAllDay.value : before.isAllDay;
      await log(ActivityAction.date, due == null ? '' : '${due.toIso8601String()}|${allDay ? 1 : 0}');
    }
    if (c.priority.present && c.priority.value != before.priority) await log(ActivityAction.priority, '${c.priority.value.code}');
    if (c.listId.present && c.listId.value != before.listId) await log(ActivityAction.moved, c.listId.value);
    if (c.repeatRule.present && c.repeatRule.value != before.repeatRule) await log(ActivityAction.repeat, c.repeatRule.value ?? '');
    if (c.pinnedAt.present && (c.pinnedAt.value == null) != (before.pinnedAt == null)) {
      await log(c.pinnedAt.value == null ? ActivityAction.unpinned : ActivityAction.pinned);
    }
    if (c.parentId.present && c.parentId.value != before.parentId) await log(ActivityAction.parent, c.parentId.value ?? '');
  }

  Future<void> _log(ActivityAction action, {String? taskId, String? listId, String detail = ''}) async {
    if (action.merges) {
      final last =
          await (_db.select(_db.activities)
                ..where((a) => taskId == null ? a.taskId.isNull() & a.listId.equals(listId ?? '') : a.taskId.equals(taskId))
                ..orderBy([
                  (a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc),
                  (a) => OrderingTerm(expression: a.rowId, mode: OrderingMode.desc),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (last != null && last.action == action && _now.difference(last.createdAt) < const Duration(minutes: 5)) {
        await (_db.update(
          _db.activities,
        )..where((a) => a.id.equals(last.id))).write(ActivitiesCompanion(detail: Value(detail), createdAt: Value(_now), updatedAt: Value(_now)));
        return;
      }
    }
    await _db
        .into(_db.activities)
        .insert(
          ActivitiesCompanion.insert(
            id: newId(),
            taskId: Value(taskId),
            listId: Value(listId),
            action: action,
            detail: Value(detail),
            createdAt: _now,
            updatedAt: _now,
          ),
        );
  }

  /// "Atividades da tarefa", newest first.
  Stream<List<Activity>> watchTaskActivities(String taskId) =>
      (_db.select(_db.activities)
            ..where((a) => a.taskId.equals(taskId))
            ..orderBy([
              (a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc),
              (a) => OrderingTerm(expression: a.rowId, mode: OrderingMode.desc),
            ]))
          .watch();

  /// "Atividades da lista": the list's own and those of its tasks, newest first.
  Stream<List<Activity>> watchListActivities(String listId) =>
      (_db.select(_db.activities)
            ..where((a) => a.listId.equals(listId))
            ..orderBy([
              (a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc),
              (a) => OrderingTerm(expression: a.rowId, mode: OrderingMode.desc),
            ]))
          .watch();

  Future<void> setTitle(String id, String title) => _update(id, TasksCompanion(title: Value(title)));

  /// "Análise de URL": the page's title replaces the link, which goes to the top of the content,
  /// unless the title was edited meanwhile.
  Future<void> titleFromLink(String id, {required String title, required String url}) async {
    final t = await (_db.select(_db.tasks)..where((r) => r.id.equals(id))).getSingleOrNull();
    if (t == null || t.title.trim() != url) return;
    await _update(id, TasksCompanion(title: Value(title), content: Value(t.content.isEmpty ? url : '$url\n\n${t.content}')), log: false);
  }

  Future<void> setContent(String id, String content) => _update(id, TasksCompanion(content: Value(content)));

  Future<void> setPriority(String id, Priority priority) => _update(id, TasksCompanion(priority: Value(priority)));

  /// The task's own color in the calendar (Google's event color); null = the default.
  Future<void> setTaskColor(String id, String? color) => _update(id, TasksCompanion(color: Value(color)), log: false);

  /// A label that changes color takes its tasks along.
  Future<void> recolorTasks(String from, String to) async {
    await (_db.update(_db.tasks)..where((t) => t.color.equals(from))).write(TasksCompanion(color: Value(to), updatedAt: Value(_now)));
  }

  /// Dragging between Matrix quadrants: the task and its subtasks take the priority.
  Future<void> setPriorityWithSubtasks(String id, Priority priority) => _db.transaction(() async {
    for (final d in [id, ...await _descendants(id)]) {
      await setPriority(d, priority);
    }
  });

  /// Due date (null = "no date"). All-day = local midnight. With [startDate] before it, the task has a
  /// duration; otherwise the start is the due date. Changing the date drops a pending snooze.
  Future<void> setDueDate(String id, DateTime? dueDate, {bool isAllDay = true, DateTime? startDate}) => _update(
    id,
    TasksCompanion(
      dueDate: Value(dueDate?.toUtc()),
      startDate: Value(dueDate == null ? null : (startDate != null && startDate.isBefore(dueDate) ? startDate : dueDate).toUtc()),
      isAllDay: Value(dueDate == null || isAllDay),
      snoozeUntil: const Value(null),
    ),
  );

  /// "Estimativa": Pomos or minutes; both null clears it.
  Future<void> setEstimate(String id, {int? pomos, int? minutes}) =>
      _update(id, TasksCompanion(estimatedPomos: Value(pomos), estimatedMinutes: Value(pomos == null ? minutes : null)), log: false);

  /// Puts a task on [day]: all-day (or dateless) tasks become all-day that day; timed ones keep their
  /// time and length ("Tarefas Sugeridas").
  Future<void> moveToDay(String id, DateTime day) async {
    final t = await task(id);
    final start = t.startLocal, due = t.endLocal;
    if (t.isAllDay || start == null || due == null) return setDueDate(id, day, isAllDay: true);
    final shift = Duration(days: daysBetween(startOfDay(start), day));
    await setDueDate(id, due.add(shift), isAllDay: false, startDate: start.add(shift));
  }

  /// "Adiar" on a fired reminder: it fires again at [until]; the due date stays.
  Future<void> snooze(String id, DateTime until) => _update(id, TasksCompanion(snoozeUntil: Value(until.toUtc())));

  Future<void> pinTask(String id, {required bool pinned}) => _update(id, TasksCompanion(pinnedAt: Value(pinned ? _now : null)));

  /// Repetition as an RRULE body (null = no repetition) and where it counts from.
  Future<void> setRepeat(String id, String? rule, {RepeatFrom from = RepeatFrom.dueDate}) =>
      _update(id, TasksCompanion(repeatRule: Value(rule), repeatFrom: Value(rule == null ? null : from.code)));

  /// Replaces the task's reminders (ISO-8601 triggers relative to the due date, see [TaskReminders]).
  Future<void> setReminders(String id, Set<String> triggers) => _db.transaction(() async {
    await (_db.delete(_db.taskReminders)..where((r) => r.taskId.equals(id))).go();
    for (final trigger in triggers) {
      await _db.into(_db.taskReminders).insert(TaskRemindersCompanion.insert(taskId: id, trigger: trigger));
    }
    await _update(id, const TasksCompanion());
  });

  /// Everything the date picker sets, in one step. No date also clears reminders and repetition.
  Future<void> setSchedule(
    String id, {
    required DateTime? dueDate,
    DateTime? startDate,
    bool isAllDay = true,
    Set<String> reminders = const {},
    String? repeatRule,
    RepeatFrom repeatFrom = RepeatFrom.dueDate,
    Value<String?> timeZone = const Value.absent(),
    bool? isFloating,
  }) => _db.transaction(() async {
    final hasDate = dueDate != null;
    await setDueDate(id, dueDate, isAllDay: isAllDay, startDate: startDate);
    await setReminders(id, hasDate ? reminders : const {});
    await setRepeat(id, hasDate ? repeatRule : null, from: repeatFrom);
    if (timeZone.present || isFloating != null) {
      await _update(id, TasksCompanion(timeZone: timeZone, isFloating: Value.absentIfNull(isFloating)), log: false);
    }
  });

  /// "Tempo flutuante": after this device moved to [deviceZone], floating tasks keep
  /// the clock time they had in their old zone. Returns how many moved.
  Future<int> reanchorFloating(String deviceZone) => _db.transaction(() async {
    final rows = await (_db.select(
      _db.tasks,
    )..where((t) => t.isFloating.equals(true) & t.timeZone.isNotNull() & t.timeZone.equals(deviceZone).not())).get();
    var moved = 0;
    for (final t in rows) {
      final old = t.timeZone!;
      if (findZone(old) == null) continue;
      DateTime? keep(DateTime? utc) => utc == null || t.isAllDay ? utc : localToWall(utc, old).toUtc();
      await (_db.update(_db.tasks)..where((r) => r.id.equals(t.id))).write(
        TasksCompanion(dueDate: Value(keep(t.dueDate)), startDate: Value(keep(t.startDate)), timeZone: Value(deviceZone)),
      );
      moved++;
    }
    return moved;
  });

  Future<List<String>> remindersOf(String id) async => [
    for (final r in await (_db.select(_db.taskReminders)..where((r) => r.taskId.equals(id))).get()) r.trigger,
  ];

  /// "Somente esta" (Google Calendar's recurring events): the occurrence starting on [day] leaves the
  /// series. The current one moves the task on to the next occurrence (the task goes to the trash when
  /// there is none); a later one is taken out of the rule.
  Future<void> skipOccurrence(String id, DateTime day) => _db.transaction(() async {
    final t = await task(id);
    final rule = t.repeatRule;
    final due = t.dueDate?.toLocal();
    if (rule == null || due == null) return;
    final start = (t.startDate ?? t.dueDate)!.toLocal();
    final first = DateTime(start.year, start.month, start.day);
    if (DateTime(day.year, day.month, day.day).isAfter(first)) {
      await setRepeat(id, excludingDay(rule, day), from: RepeatFrom.fromCode(t.repeatFrom));
      return;
    }
    final next = nextOccurrence(rule: rule, dueDate: due, from: RepeatFrom.dueDate, completedAt: _clock.now());
    if (next == null) {
      await delete(id);
      return;
    }
    final shift = next.dueDate.difference(due);
    await _update(
      id,
      TasksCompanion(
        dueDate: Value(next.dueDate.toUtc()),
        startDate: Value(t.startDate?.add(shift)),
        repeatRule: Value(next.rule),
        snoozeUntil: const Value(null),
      ),
    );
  });

  /// "Esta e as seguintes": the series stops before the occurrence starting on [day]; from its first
  /// occurrence, the whole task goes to the trash.
  Future<void> endSeriesBefore(String id, DateTime day) => _db.transaction(() async {
    final t = await task(id);
    final rule = t.repeatRule;
    if (rule == null) return;
    final start = (t.startDate ?? t.dueDate)!.toLocal();
    final cut = DateTime(day.year, day.month, day.day);
    if (!cut.isAfter(DateTime(start.year, start.month, start.day))) {
      await delete(id);
      return;
    }
    await setRepeat(id, endingOn(rule, cut.subtract(const Duration(days: 1))), from: RepeatFrom.fromCode(t.repeatFrom));
  });

  /// Puts [before] back as it was: its dates, repetition and place (undo of the above).
  Future<void> restoreSeries(Task before) => _db.transaction(() async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(before.id))).write(
      TasksCompanion(
        dueDate: Value(before.dueDate),
        startDate: Value(before.startDate),
        repeatRule: Value(before.repeatRule),
        repeatFrom: Value(before.repeatFrom),
        deletedAt: Value(before.deletedAt),
        updatedAt: Value(_now),
      ),
    );
  });

  /// Completing a task completes its open subtasks too. A repeating task instead leaves a
  /// completed copy of this occurrence and moves to the next date, keeping its id.
  Future<void> complete(String id) => _db.transaction(() async {
    final t = await task(id);
    final rule = t.repeatRule;
    final due = t.dueDate;
    if (rule != null && due != null && t.status == TaskStatus.open) {
      final next = nextOccurrence(rule: rule, dueDate: due.toLocal(), from: RepeatFrom.fromCode(t.repeatFrom), completedAt: _clock.now());
      if (next != null) {
        final copyId = newId();
        await _db
            .into(_db.tasks)
            .insert(
              t.copyWith(
                id: copyId,
                status: TaskStatus.completed,
                completedAt: Value(_now),
                repeatRule: const Value(null),
                repeatFrom: const Value(null),
                createdAt: _now,
                updatedAt: _now,
              ),
            );
        for (final r in await (_db.select(_db.taskTags)..where((r) => r.taskId.equals(id))).get()) {
          await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: copyId, tagId: r.tagId));
        }
        final shift = next.dueDate.difference(due.toLocal());
        await _update(
          id,
          TasksCompanion(
            dueDate: Value(next.dueDate.toUtc()),
            startDate: Value(t.startDate?.toLocal().add(shift).toUtc()),
            repeatRule: Value(next.rule),
            snoozeUntil: const Value(null),
          ),
          log: false,
        );
        await _log(ActivityAction.completed, taskId: id, listId: t.listId);
        return;
      }
    }
    for (final d in [id, ...await _descendants(id)]) {
      if ((await task(d)).status == TaskStatus.open) {
        await _update(d, TasksCompanion(status: const Value(TaskStatus.completed), completedAt: Value(_now)));
      }
    }
  });

  /// An imported task's status, completion and creation times as they were in the other app.
  Future<void> setImportedState(String id, {required TaskStatus status, DateTime? completedAt, DateTime? createdAt}) => _update(
    id,
    TasksCompanion(
      status: Value(status),
      completedAt: Value(status == TaskStatus.open ? null : (completedAt ?? _clock.now()).toUtc()),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt.toUtc()),
    ),
    log: false,
  );

  Future<void> markWontDo(String id) => _update(id, TasksCompanion(status: const Value(TaskStatus.wontDo), completedAt: Value(_now)));

  /// Reopen / undo completion ("Reabrir" in Won't do).
  Future<void> reopen(String id) => _update(id, const TasksCompanion(status: Value(TaskStatus.open), completedAt: Value(null)));

  /// Delete: goes to the Trash with its subtasks, no confirmation.
  Future<void> delete(String id) => _db.transaction(() async {
    for (final d in [id, ...await _descendants(id)]) {
      await _update(d, TasksCompanion(deletedAt: Value(_now)));
    }
  });

  /// Restore from the Trash to the original list (or to the Inbox if that list is gone).
  Future<void> restore(String id) => _db.transaction(() async {
    final t = await task(id);
    final list = await (_db.select(_db.lists)..where((l) => l.id.equals(t.listId))).getSingleOrNull();
    final target = list == null || list.deletedAt != null ? inboxListId : t.listId;
    for (final d in [id, ...await _descendants(id, includeDeleted: true)]) {
      await _update(d, TasksCompanion(deletedAt: const Value(null), listId: Value(target)));
    }
  });

  Future<void> deleteForever(String id) => _db.transaction(() async {
    final ids = [id, ...await _descendants(id, includeDeleted: true)];
    await (_db.delete(_db.taskTags)..where((r) => r.taskId.isIn(ids))).go();
    await (_db.delete(_db.checklistItems)..where((i) => i.taskId.isIn(ids))).go();
    await (_db.delete(_db.taskReminders)..where((r) => r.taskId.isIn(ids))).go();
    await (_db.delete(_db.comments)..where((c) => c.taskId.isIn(ids))).go();
    // A task deleted for good leaves no history behind.
    await (_db.delete(_db.activities)..where((a) => a.taskId.isIn(ids))).go();
    for (final d in ids.reversed) {
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(d))).go();
    }
  });

  Future<void> emptyTrash() => _db.transaction(() async {
    final deleted = await (_db.select(_db.tasks)..where((t) => t.deletedAt.isNotNull())).get();
    final ids = {for (final t in deleted) t.id};
    for (final t in deleted.where((t) => t.parentId == null || !ids.contains(t.parentId))) {
      await deleteForever(t.id);
    }
  });

  /// Move to another list (and section); subtasks go along.
  Future<void> move(String id, String listId, {String? sectionId}) => _db.transaction(() async {
    final t = await task(id);
    final leavesParent = t.parentId != null && (await task(t.parentId!)).listId != listId;
    await _update(id, TasksCompanion(sectionId: Value(sectionId), parentId: leavesParent ? const Value(null) : const Value.absent()));
    await _moveWithDescendants(id, listId);
  });

  Future<void> reorder(String id, int sortOrder, {Value<String?> sectionId = const Value.absent()}) =>
      _update(id, TasksCompanion(sortOrder: Value(sortOrder), sectionId: sectionId));

  /// Drag and drop in the list: puts [id] right before [targetId], at the target's level (same parent,
  /// same list), taking [sectionId] when given or the target's section otherwise.
  Future<void> moveBefore(String id, String targetId, {Value<String?> sectionId = const Value.absent()}) => _db.transaction(() async {
    if (id == targetId) return;
    final target = await task(targetId);
    final parentId = target.parentId;
    if (parentId != null && (parentId == id || (await _descendants(id)).contains(parentId))) {
      throw const RuleViolation(Rule.taskCannotBeItsOwnParent);
    }
    var siblings = await _siblings(target.listId, parentId, excluding: id);
    var index = siblings.indexWhere((t) => t.id == targetId);
    int? order = index <= 0 ? SortOrder.before(target.sortOrder) : SortOrder.between(siblings[index - 1].sortOrder, target.sortOrder);
    if (order == null) {
      await _reindex(siblings);
      siblings = await _siblings(target.listId, parentId, excluding: id);
      index = siblings.indexWhere((t) => t.id == targetId);
      order = SortOrder.between(siblings[index - 1].sortOrder, siblings[index].sortOrder)!;
    }
    await _update(
      id,
      TasksCompanion(parentId: Value(parentId), sortOrder: Value(order), sectionId: sectionId.present ? sectionId : Value(target.sectionId)),
    );
    await _moveWithDescendants(id, target.listId);
  });

  /// Drop on the lower half of a task: right after it among its siblings (after its subtasks).
  Future<void> moveAfter(String id, String targetId, {Value<String?> sectionId = const Value.absent()}) => _db.transaction(() async {
    if (id == targetId) return;
    final target = await task(targetId);
    final parentId = target.parentId;
    if (parentId != null && (parentId == id || (await _descendants(id)).contains(parentId))) {
      throw const RuleViolation(Rule.taskCannotBeItsOwnParent);
    }
    var siblings = await _siblings(target.listId, parentId, excluding: id);
    var index = siblings.indexWhere((t) => t.id == targetId);
    int? order = index == siblings.length - 1
        ? SortOrder.after(target.sortOrder)
        : SortOrder.between(target.sortOrder, siblings[index + 1].sortOrder);
    if (order == null) {
      await _reindex(siblings);
      siblings = await _siblings(target.listId, parentId, excluding: id);
      index = siblings.indexWhere((t) => t.id == targetId);
      order = SortOrder.between(siblings[index].sortOrder, siblings[index + 1].sortOrder)!;
    }
    await _update(
      id,
      TasksCompanion(parentId: Value(parentId), sortOrder: Value(order), sectionId: sectionId.present ? sectionId : Value(target.sectionId)),
    );
    await _moveWithDescendants(id, target.listId);
  });

  /// Drop on a section header: the task goes to the top of that section, at the top level.
  Future<void> moveToSectionTop(String id, String listId, String? sectionId) => _db.transaction(() async {
    final roots = await _siblings(listId, null, excluding: id);
    final inSection = roots.where((t) => t.sectionId == sectionId).toList();
    final first = inSection.isEmpty ? roots.firstOrNull?.sortOrder : inSection.first.sortOrder;
    await _update(id, TasksCompanion(parentId: const Value(null), sectionId: Value(sectionId), sortOrder: Value(SortOrder.before(first))));
    await _moveWithDescendants(id, listId);
  });

  Future<List<Task>> _siblings(String listId, String? parentId, {required String excluding}) =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.listId.equals(listId) &
                  (parentId == null ? t.parentId.isNull() : t.parentId.equals(parentId)) &
                  t.deletedAt.isNull() &
                  t.id.equals(excluding).not(),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<void> _reindex(List<Task> ordered) async {
    final orders = SortOrder.reindex(ordered.length);
    for (var i = 0; i < ordered.length; i++) {
      await _update(ordered[i].id, TasksCompanion(sortOrder: Value(orders[i])));
    }
  }

  /// "Link parent task": becomes a subtask (up to 5 levels) in the parent's list.
  Future<void> makeSubtask(String id, String parentId) => _db.transaction(() async {
    if (id == parentId || (await _descendants(id)).contains(parentId)) throw const RuleViolation(Rule.taskCannotBeItsOwnParent);
    final parent = await task(parentId);
    var depth = 0;
    for (Task? p = parent; p?.parentId != null; p = await task(p!.parentId!)) {
      depth++;
    }
    if (depth >= 4) throw const RuleViolation(Rule.subtaskDepthLimit);
    await _update(id, TasksCompanion(parentId: Value(parentId), sectionId: Value(parent.sectionId)));
    await _moveWithDescendants(id, parent.listId);
  });

  Future<void> removeParent(String id) => _update(id, const TasksCompanion(parentId: Value(null)));

  /// "Mesclar": a new task titled [title] in the first task's list, with [ids] as its
  /// subtasks. Returns the new task.
  Future<String> merge(List<String> ids, String title) => _db.transaction(() async {
    final first = await task(ids.first);
    final merged = await createTask(listId: first.listId, sectionId: first.sectionId, title: title);
    for (final id in ids) {
      await makeSubtask(id, merged);
    }
    return merged;
  });

  /// "Atrasar": moves the dates of [id] by [days] (start and end together); a task without a date
  /// gets today plus [days].
  Future<void> postpone(String id, int days) => _db.transaction(() async {
    final t = await task(id);
    final due = t.dueDate?.toLocal();
    if (due == null) {
      final today = _clock.now();
      await setDueDate(id, DateTime(today.year, today.month, today.day + days));
      return;
    }
    DateTime shift(DateTime d) => DateTime(d.year, d.month, d.day + days, d.hour, d.minute);
    await setDueDate(id, shift(due), isAllDay: t.isAllDay, startDate: t.startDate == null ? null : shift(t.startDate!.toLocal()));
  });

  Future<String> duplicate(String id) => _db.transaction(() async {
    final t = await task(id);
    return _copyTask(t, listId: t.listId, sectionId: t.sectionId, parentId: t.parentId, sortOrder: t.sortOrder + 1);
  });

  /// Convert to note ↔ task (a task with subtasks can't become a note).
  Future<void> convert(String id, TaskKind to) async {
    if (to == TaskKind.note && (await _descendants(id)).isNotEmpty) throw const RuleViolation(Rule.taskWithSubtasksCannotBecomeNote);
    await _update(id, TasksCompanion(kind: Value(to)));
  }

  /// Toggles checklist mode: description lines become items and back.
  Future<void> toggleChecklist(String id) => _db.transaction(() async {
    final t = await task(id);
    if (t.kind == TaskKind.checklist) {
      final items =
          await (_db.select(_db.checklistItems)
                ..where((i) => i.taskId.equals(id) & i.deletedAt.isNull())
                ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
              .get();
      final text = items.map((i) => i.title).where((s) => s.trim().isNotEmpty).join('\n');
      await (_db.delete(_db.checklistItems)..where((i) => i.taskId.equals(id))).go();
      await _update(id, TasksCompanion(kind: const Value(TaskKind.text), content: Value(text), progress: const Value(0)));
    } else {
      final lines = t.content
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'^\s*([-*]|\d+\.)\s+(\[[ x]\]\s+)?'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();
      for (var i = 0; i < lines.length; i++) {
        await _db
            .into(_db.checklistItems)
            .insert(
              ChecklistItemsCompanion.insert(
                id: newId(),
                createdAt: _now,
                updatedAt: _now,
                taskId: id,
                title: Value(lines[i]),
                sortOrder: i * SortOrder.step,
              ),
            );
      }
      await _update(id, const TasksCompanion(kind: Value(TaskKind.checklist), content: Value('')));
    }
  });

  // ------------------------------------------------------------------ checklist items

  Future<String> addChecklistItem(String taskId, {String title = '', String? afterItemId}) => _db.transaction(() async {
    final items =
        await (_db.select(_db.checklistItems)
              ..where((i) => i.taskId.equals(taskId) & i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
            .get();
    final index = afterItemId == null ? -1 : items.indexWhere((i) => i.id == afterItemId);
    final sortOrder = index < 0 || index == items.length - 1
        ? SortOrder.after(items.lastOrNull?.sortOrder)
        : SortOrder.between(items[index].sortOrder, items[index + 1].sortOrder) ?? items[index].sortOrder + 1;
    final id = newId();
    await _db
        .into(_db.checklistItems)
        .insert(ChecklistItemsCompanion.insert(id: id, createdAt: _now, updatedAt: _now, taskId: taskId, title: Value(title), sortOrder: sortOrder));
    await _recomputeProgress(taskId);
    return id;
  });

  Future<void> setChecklistItemTitle(String id, String title) =>
      (_db.update(_db.checklistItems)..where((i) => i.id.equals(id))).write(ChecklistItemsCompanion(title: Value(title), updatedAt: Value(_now)));

  /// Reminder of a checklist item; null removes it. All-day = local midnight.
  Future<void> setChecklistItemDate(String id, DateTime? date, {bool isAllDay = true}) =>
      (_db.update(_db.checklistItems)..where((i) => i.id.equals(id))).write(
        ChecklistItemsCompanion(dueDate: Value(date?.toUtc()), isAllDay: Value(date == null || isAllDay), updatedAt: Value(_now)),
      );

  /// Checking the last open item completes the task.
  Future<void> setChecklistItemCompleted(String id, {required bool completed}) => _db.transaction(() async {
    await (_db.update(_db.checklistItems)..where((i) => i.id.equals(id))).write(
      ChecklistItemsCompanion(isCompleted: Value(completed), completedAt: Value(completed ? _now : null), updatedAt: Value(_now)),
    );
    final item = await (_db.select(_db.checklistItems)..where((i) => i.id.equals(id))).getSingle();
    final progress = await _recomputeProgress(item.taskId);
    if (progress == 100 && (await task(item.taskId)).status == TaskStatus.open) await complete(item.taskId);
  });

  Future<void> deleteChecklistItem(String id) => _db.transaction(() async {
    final item = await (_db.select(_db.checklistItems)..where((i) => i.id.equals(id))).getSingle();
    await (_db.delete(_db.checklistItems)..where((i) => i.id.equals(id))).go();
    await _recomputeProgress(item.taskId);
  });

  Future<void> reorderChecklistItem(String id, int sortOrder) => (_db.update(
    _db.checklistItems,
  )..where((i) => i.id.equals(id))).write(ChecklistItemsCompanion(sortOrder: Value(sortOrder), updatedAt: Value(_now)));

  Future<int> _recomputeProgress(String taskId) async {
    final items = await (_db.select(_db.checklistItems)..where((i) => i.taskId.equals(taskId) & i.deletedAt.isNull())).get();
    final progress = items.isEmpty ? 0 : (100 * items.where((i) => i.isCompleted).length / items.length).round();
    await _update(taskId, TasksCompanion(progress: Value(progress)));
    return progress;
  }

  // ------------------------------------------------------------------ tags

  /// Returns the existing tag id when a tag with that name already exists.
  Future<String> createTag(String name, {String? color, String? parentId}) async {
    final clean = _cleanTagName(name);
    final existing = await (_db.select(_db.tags)..where((t) => t.name.equals(clean))).getSingleOrNull();
    if (existing != null) return existing.id;
    final id = newId();
    final last = await _maxOrder(_db.tags, _db.tags.sortOrder);
    await _db
        .into(_db.tags)
        .insert(
          TagsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: clean,
            color: Value(color),
            parentId: Value(parentId),
            sortOrder: SortOrder.after(last),
          ),
        );
    return id;
  }

  Future<void> editTag(String id, {required String name, String? color, String? parentId}) async {
    final clean = _cleanTagName(name);
    final other = await (_db.select(_db.tags)..where((t) => t.name.equals(clean) & t.id.equals(id).not())).getSingleOrNull();
    if (other != null) throw const RuleViolation(Rule.tagNameTaken);
    await (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(name: Value(clean), color: Value(color), parentId: Value(parentId), updatedAt: Value(_now)),
    );
  }

  Future<void> pinTag(String id, {required bool pinned}) =>
      (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(TagsCompanion(pinnedAt: Value(pinned ? _now : null), updatedAt: Value(_now)));

  /// Deleting a tag removes it from every task; its sub-tags move up a level.
  Future<void> deleteTag(String id) => _db.transaction(() async {
    await (_db.delete(_db.taskTags)..where((r) => r.tagId.equals(id))).go();
    await (_db.update(_db.tags)..where((t) => t.parentId.equals(id))).write(const TagsCompanion(parentId: Value(null)));
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  });

  /// Merge: tasks of [sourceId] get [targetId] and the source is deleted.
  Future<void> mergeTags(String sourceId, String targetId) => _db.transaction(() async {
    for (final r in await (_db.select(_db.taskTags)..where((r) => r.tagId.equals(sourceId))).get()) {
      await _db
          .into(_db.taskTags)
          .insert(
            TaskTagsCompanion.insert(taskId: r.taskId, tagId: targetId),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await deleteTag(sourceId);
  });

  Future<void> setTaskTags(String taskId, Set<String> tagIds) => _db.transaction(() async {
    await (_db.delete(_db.taskTags)..where((r) => r.taskId.equals(taskId))).go();
    for (final tagId in tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: taskId, tagId: tagId));
    }
    await _update(taskId, const TasksCompanion());
    final t = await task(taskId);
    final names = [for (final tag in await (_db.select(_db.tags)..where((x) => x.id.isIn(tagIds))).get()) '#${tag.name}'];
    await _log(ActivityAction.tags, taskId: taskId, listId: t.listId, detail: names.join(' '));
  });

  static String _cleanTagName(String name) => name.trim().replaceFirst(RegExp(r'^#'), '');

  // ------------------------------------------------------------------ helpers

  /// Folders and loose lists share one order in the sidebar: a new one goes after both.
  Future<int?> _maxTopOrder() async {
    final folders = await _maxOrder(_db.folders, _db.folders.sortOrder);
    final lists = await _maxOrder(_db.lists, _db.lists.sortOrder);
    if (folders == null) return lists;
    if (lists == null) return folders;
    return folders > lists ? folders : lists;
  }

  Future<int?> _maxOrder<T extends Table, D>(TableInfo<T, D> table, GeneratedColumn<int> column) =>
      (_db.selectOnly(table)..addColumns([column.max()])).map((r) => r.read(column.max())).getSingle();

  Future<List<String>> _descendants(String id, {bool includeDeleted = false}) async {
    final result = <String>[];
    var frontier = [id];
    while (frontier.isNotEmpty) {
      final children = await (_db.select(
        _db.tasks,
      )..where((t) => t.parentId.isIn(frontier) & (includeDeleted ? const Constant(true) : t.deletedAt.isNull()))).get();
      frontier = [for (final c in children) c.id];
      result.addAll(frontier);
    }
    return result;
  }

  Future<void> _moveWithDescendants(String id, String listId) async {
    for (final d in [id, ...await _descendants(id, includeDeleted: true)]) {
      await _update(d, TasksCompanion(listId: Value(listId)));
    }
  }

  /// [reopen] copies closed tasks as open; [openOnly] leaves closed subtasks out.
  Future<String> _copyTask(
    Task t, {
    required String listId,
    required String? sectionId,
    required String? parentId,
    int? sortOrder,
    bool reopen = false,
    bool openOnly = false,
  }) async {
    final id = newId();
    await _db
        .into(_db.tasks)
        .insert(
          t.copyWith(
            id: id,
            listId: listId,
            sectionId: Value(sectionId),
            parentId: Value(parentId),
            createdAt: _now,
            updatedAt: _now,
            sortOrder: sortOrder ?? t.sortOrder,
            status: reopen ? TaskStatus.open : t.status,
            completedAt: reopen ? const Value(null) : Value(t.completedAt),
          ),
        );
    for (final i in await (_db.select(_db.checklistItems)..where((i) => i.taskId.equals(t.id) & i.deletedAt.isNull())).get()) {
      await _db.into(_db.checklistItems).insert(i.copyWith(id: newId(), taskId: id, createdAt: _now, updatedAt: _now));
    }
    for (final r in await (_db.select(_db.taskTags)..where((r) => r.taskId.equals(t.id))).get()) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: r.tagId));
    }
    for (final c in await (_db.select(_db.tasks)..where((c) => c.parentId.equals(t.id) & c.deletedAt.isNull())).get()) {
      if (openOnly && c.status != TaskStatus.open) continue;
      await _copyTask(c, listId: listId, sectionId: sectionId, parentId: id, reopen: reopen, openOnly: openOnly);
    }
    return id;
  }

  // ------------------------------------------------------------------ templates

  /// Templates in manual order.
  Stream<List<TaskTemplate>> watchTemplates() =>
      (_db.select(_db.templates)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .watch();

  Future<String> createTemplate({
    required String name,
    String title = '',
    String content = '',
    TaskKind kind = TaskKind.text,
    List<String> items = const [],
    Set<String> tagIds = const {},
  }) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.templates,
    )..addColumns([_db.templates.sortOrder.max()])).map((r) => r.read(_db.templates.sortOrder.max())).getSingle();
    await _db
        .into(_db.templates)
        .insert(
          TemplatesCompanion.insert(
            id: id,
            name: name.trim(),
            title: Value(title.trim()),
            content: Value(content),
            kind: Value(kind),
            items: Value(items.map((i) => i.trim()).where((i) => i.isNotEmpty).join('\n')),
            tagIds: Value(tagIds.join(',')),
            sortOrder: SortOrder.after(last),
            createdAt: _now,
            updatedAt: _now,
          ),
        );
    return id;
  }

  /// "Salvar como modelo": the task's title, content, checklist items and tags.
  Future<String> saveTaskAsTemplate(String taskId, String name) async {
    final t = await task(taskId);
    final items =
        await (_db.select(_db.checklistItems)
              ..where((i) => i.taskId.equals(taskId) & i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
            .get();
    final tags = await (_db.select(_db.taskTags)..where((r) => r.taskId.equals(taskId))).get();
    return createTemplate(
      name: name,
      title: t.title,
      content: t.content,
      kind: t.kind,
      items: [for (final i in items) i.title],
      tagIds: {for (final r in tags) r.tagId},
    );
  }

  Future<void> renameTemplate(String id, String name) =>
      (_db.update(_db.templates)..where((t) => t.id.equals(id))).write(TemplatesCompanion(name: Value(name.trim()), updatedAt: Value(_now)));

  Future<void> deleteTemplate(String id) => (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();

  /// "Adicionar a partir do modelo": a task with the template's title, content, checklist and tags, without
  /// a date or repetition. Tags deleted meanwhile are skipped.
  Future<String> createTaskFromTemplate(String templateId, {required String listId, String? sectionId}) => _db.transaction(() async {
    final template = await (_db.select(_db.templates)..where((t) => t.id.equals(templateId))).getSingle();
    final existingTags = {
      for (final tag in await _db.select(_db.tags).get())
        if (tag.deletedAt == null) tag.id,
    };
    final id = await createTask(
      listId: listId,
      sectionId: sectionId,
      title: template.title.isEmpty ? template.name : template.title,
      content: template.content,
      kind: template.kind,
      tagIds: template.tagIds.split(',').where(existingTags.contains).toSet(),
    );
    if (template.kind == TaskKind.checklist) {
      String? previous;
      for (final line in template.items.split('\n').where((l) => l.trim().isNotEmpty)) {
        previous = await addChecklistItem(id, title: line, afterItemId: previous);
      }
    }
    return id;
  });

  // ------------------------------------------------------------------ comments

  /// Comments of a task, oldest first.
  Stream<List<Comment>> watchComments(String taskId) =>
      (_db.select(_db.comments)
            ..where((c) => c.taskId.equals(taskId) & c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm(expression: c.createdAt)]))
          .watch();

  Future<String> addComment(String taskId, String body) async {
    final id = newId();
    await _db.into(_db.comments).insert(CommentsCompanion.insert(id: id, taskId: taskId, body: body.trim(), createdAt: _now, updatedAt: _now));
    return id;
  }

  Future<void> editComment(String id, String body) =>
      (_db.update(_db.comments)..where((c) => c.id.equals(id))).write(CommentsCompanion(body: Value(body.trim()), updatedAt: Value(_now)));

  Future<void> deleteComment(String id) =>
      (_db.update(_db.comments)..where((c) => c.id.equals(id))).write(CommentsCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ countdowns

  /// Stores a calendar [date] at UTC midnight so the day never shifts with the time zone.
  static DateTime _calendarDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  Future<String> createCountdown({
    required String name,
    required DateTime date,
    CountdownType type = CountdownType.countdown,
    CountMode countMode = CountMode.standard,
    bool countUp = false,
    bool ignoreYear = false,
    bool showAge = false,
    Set<String> reminders = const {},
    String? repeatRule,
    CountdownVisibility visibility = CountdownVisibility.onTheDay,
    int style = 0,
    String? color,
    String? icon,
    String? iconColor,
    String? image,
  }) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.countdowns,
    )..addColumns([_db.countdowns.sortOrder.max()])).map((r) => r.read(_db.countdowns.sortOrder.max())).getSingle();
    await _db
        .into(_db.countdowns)
        .insert(
          CountdownsCompanion.insert(
            id: id,
            name: name.trim(),
            date: _calendarDate(date),
            type: Value(type),
            countMode: Value(countMode),
            countUp: Value(countUp),
            ignoreYear: Value(ignoreYear),
            showAge: Value(showAge),
            reminders: Value(reminders.join(',')),
            repeatRule: Value(repeatRule),
            visibility: Value(visibility),
            style: Value(style),
            color: Value(color),
            icon: Value(icon),
            iconColor: Value(iconColor),
            image: Value(image),
            sortOrder: SortOrder.after(last),
            createdAt: _now,
            updatedAt: _now,
          ),
        );
    return id;
  }

  /// Saves the edit form (one step, "Salvar").
  Future<void> updateCountdown(
    String id, {
    required String name,
    required DateTime date,
    required CountdownType type,
    required CountMode countMode,
    bool countUp = false,
    required bool ignoreYear,
    required bool showAge,
    required Set<String> reminders,
    required String? repeatRule,
    required CountdownVisibility visibility,
  }) => (_db.update(_db.countdowns)..where((c) => c.id.equals(id))).write(
    CountdownsCompanion(
      name: Value(name.trim()),
      date: Value(_calendarDate(date)),
      type: Value(type),
      countMode: Value(countMode),
      countUp: Value(countUp),
      ignoreYear: Value(ignoreYear),
      showAge: Value(showAge),
      reminders: Value(reminders.join(',')),
      repeatRule: Value(repeatRule),
      visibility: Value(visibility),
      updatedAt: Value(_now),
    ),
  );

  /// "Estilo": layout, color, icon and background picture.
  Future<void> setCountdownStyle(String id, {required int style, String? color, String? icon, String? iconColor, String? image}) =>
      (_db.update(_db.countdowns)..where((c) => c.id.equals(id))).write(
        CountdownsCompanion(
          style: Value(style),
          color: Value(color),
          icon: Value(icon),
          iconColor: Value(iconColor),
          image: Value(image),
          updatedAt: Value(_now),
        ),
      );

  Future<void> setCountdownNote(String id, String note) =>
      (_db.update(_db.countdowns)..where((c) => c.id.equals(id))).write(CountdownsCompanion(note: Value(note), updatedAt: Value(_now)));

  Future<void> archiveCountdown(String id, {required bool archived}) => (_db.update(
    _db.countdowns,
  )..where((c) => c.id.equals(id))).write(CountdownsCompanion(archivedAt: Value(archived ? _now : null), updatedAt: Value(_now)));

  /// Only one countdown is pinned at a time (the pinned one goes first).
  Future<void> pinCountdown(String id, {required bool pinned}) => _db.transaction(() async {
    if (pinned) {
      await (_db.update(_db.countdowns)..where((c) => c.pinnedAt.isNotNull() & c.id.equals(id).not())).write(
        CountdownsCompanion(pinnedAt: const Value(null), updatedAt: Value(_now)),
      );
    }
    await (_db.update(
      _db.countdowns,
    )..where((c) => c.id.equals(id))).write(CountdownsCompanion(pinnedAt: Value(pinned ? _now : null), updatedAt: Value(_now)));
  });

  /// "Deletar": countdowns have no trash.
  Future<void> deleteCountdown(String id) => (_db.delete(_db.countdowns)..where((c) => c.id.equals(id))).go();

  // ------------------------------------------------------------------ focus

  /// "Foco em registro", newest first.
  Stream<List<FocusRecord>> watchFocusRecords() =>
      (_db.select(_db.focusRecords)
            ..where((r) => r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm(expression: r.startedAt, mode: OrderingMode.desc)]))
          .watch();

  Future<String> addFocusRecord(FocusRecordDraft d, {String? timerId}) async {
    final id = newId();
    await _db
        .into(_db.focusRecords)
        .insert(
          FocusRecordsCompanion.insert(
            id: id,
            startedAt: d.startedAt.toUtc(),
            endedAt: d.endedAt.toUtc(),
            seconds: d.seconds,
            mode: Value(d.mode),
            taskId: Value(d.taskId),
            timerId: Value(timerId),
            note: Value(d.note),
            createdAt: _now,
            updatedAt: _now,
          ),
        );
    return id;
  }

  Future<void> updateFocusRecord(
    String id, {
    String? note,
    Value<String?> taskId = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    int? seconds,
  }) => (_db.update(_db.focusRecords)..where((r) => r.id.equals(id))).write(
    FocusRecordsCompanion(
      note: Value.absentIfNull(note),
      taskId: taskId,
      startedAt: Value.absentIfNull(startedAt?.toUtc()),
      endedAt: Value.absentIfNull(endedAt?.toUtc()),
      seconds: Value.absentIfNull(seconds),
      updatedAt: Value(_now),
    ),
  );

  /// "Editar duração do foco": the record counts [seconds]; it starts earlier when it no longer fits.
  Future<void> setFocusRecordLength(String id, int seconds) async {
    final r = await (_db.select(_db.focusRecords)..where((r) => r.id.equals(id))).getSingleOrNull();
    if (r == null) return;
    final earliest = r.endedAt.subtract(Duration(seconds: seconds));
    await updateFocusRecord(id, seconds: seconds, startedAt: earliest.isBefore(r.startedAt) ? earliest : null);
  }

  Future<void> deleteFocusRecord(String id) => (_db.delete(_db.focusRecords)..where((r) => r.id.equals(id))).go();

  /// "Excluir tudo".
  Future<void> deleteAllFocusRecords() => _db.delete(_db.focusRecords).go();

  // ------------------------------------------------------------------ habits

  static DateTime _habitDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

  /// "Criar Hábito".
  Future<String> createHabit(HabitsCompanion habit) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.habits,
    )..addColumns([_db.habits.sortOrder.max()])).map((r) => r.read(_db.habits.sortOrder.max())).getSingle();
    await _db
        .into(_db.habits)
        .insert(
          habit.copyWith(
            id: Value(id),
            startDate: Value(_habitDay(habit.startDate.present ? habit.startDate.value : _clock.now())),
            sortOrder: Value(SortOrder.after(last)),
            createdAt: Value(_now),
            updatedAt: Value(_now),
          ),
        );
    return id;
  }

  Future<void> updateHabit(String id, HabitsCompanion changes) => (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
    changes.copyWith(startDate: changes.startDate.present ? Value(_habitDay(changes.startDate.value)) : const Value.absent(), updatedAt: Value(_now)),
  );

  Future<void> archiveHabit(String id, {required bool archived}) => (_db.update(
    _db.habits,
  )..where((h) => h.id.equals(id))).write(HabitsCompanion(archivedAt: Value(archived ? _now : null), updatedAt: Value(_now)));

  /// Deleting a habit deletes its check-ins.
  Future<void> deleteHabit(String id) => _db.transaction(() async {
    await (_db.delete(_db.habitCheckins)..where((c) => c.habitId.equals(id))).go();
    await (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();
  });

  Future<HabitCheckin?> _checkin(String habitId, DateTime day) =>
      (_db.select(_db.habitCheckins)..where((c) => c.habitId.equals(habitId) & c.day.equals(_habitDay(day)))).getSingleOrNull();

  Future<void> _writeCheckin(String habitId, DateTime day, HabitCheckinsCompanion changes) async {
    final existing = await _checkin(habitId, day);
    if (existing == null) {
      await _db
          .into(_db.habitCheckins)
          .insert(
            changes.copyWith(id: Value(newId()), habitId: Value(habitId), day: Value(_habitDay(day)), createdAt: Value(_now), updatedAt: Value(_now)),
          );
    } else {
      await (_db.update(_db.habitCheckins)..where((c) => c.id.equals(existing.id))).write(changes.copyWith(updatedAt: Value(_now)));
    }
  }

  /// A click on the day's dot: a simple habit is done; an amount habit adds its
  /// step ("Automático"), [amount] ("Manual") or the whole goal ("Complete todos").
  Future<void> checkIn(String habitId, DateTime day, {double? amount}) => _db.transaction(() async {
    final h = await (_db.select(_db.habits)..where((x) => x.id.equals(habitId))).getSingle();
    final current = (await _checkin(habitId, day))?.value ?? 0;
    final value = switch ((h.goal, h.checkMode)) {
      (HabitGoal.checkIn, _) => 1.0,
      (_, HabitCheckMode.completeAll) => h.goalAmount,
      (_, HabitCheckMode.manual) => current + (amount ?? 0),
      (_, HabitCheckMode.auto) => current + (amount ?? h.step),
    };
    await _writeCheckin(habitId, day, HabitCheckinsCompanion(value: Value(value), mark: const Value(HabitMark.none)));
  });

  /// "Pular" and "Incompleta".
  Future<void> markHabitDay(String habitId, DateTime day, HabitMark mark) => _writeCheckin(habitId, day, HabitCheckinsCompanion(mark: Value(mark)));

  /// "Reiniciar hábito": the day goes back to open (the log stays).
  Future<void> resetHabitDay(String habitId, DateTime day) =>
      _writeCheckin(habitId, day, const HabitCheckinsCompanion(value: Value(0), mark: Value(HabitMark.none)));

  /// "Registro de hábitos": mood (1-5) and note of the day.
  Future<void> saveHabitLog(String habitId, DateTime day, {int? mood, required String note}) =>
      _writeCheckin(habitId, day, HabitCheckinsCompanion(mood: Value(mood), note: Value(note.trim())));

  // ------------------------------------------------------------------ filters

  /// "Adicionar Filtro".
  Future<String> createFilter(String name, FilterRule rule) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.filters,
    )..addColumns([_db.filters.sortOrder.max()])).map((r) => r.read(_db.filters.sortOrder.max())).getSingle();
    await _db
        .into(_db.filters)
        .insert(
          FiltersCompanion.insert(id: id, name: name.trim(), rule: rule.encode(), sortOrder: SortOrder.after(last), createdAt: _now, updatedAt: _now),
        );
    return id;
  }

  Future<void> updateFilter(String id, {required String name, required FilterRule rule}) => (_db.update(
    _db.filters,
  )..where((f) => f.id.equals(id))).write(FiltersCompanion(name: Value(name.trim()), rule: Value(rule.encode()), updatedAt: Value(_now)));

  Future<void> pinFilter(String id, {required bool pinned}) =>
      (_db.update(_db.filters)..where((f) => f.id.equals(id))).write(FiltersCompanion(pinnedAt: Value(pinned ? _now : null), updatedAt: Value(_now)));

  Future<void> deleteFilter(String id) => (_db.delete(_db.filters)..where((f) => f.id.equals(id))).go();
}

/// What "Duplicar lista" copies.
enum ListCopyMode {
  /// "Apenas tarefas incompletas".
  openOnly,

  /// "Todas as tarefas, preservando o status de conclusão".
  keepStatus,

  /// "Todas as tarefas, sem o status de concluídas".
  allReopened,
}
