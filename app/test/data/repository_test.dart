import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/core/sort_order.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/recurrence.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  test('the database starts with the Inbox', () async {
    final s = await repo.loadSnapshot();
    expect(s.activeLists.map((l) => l.id), [inboxListId]);
  });

  test("stores TickTick's codes", () async {
    final id = await repo.createTask(listId: inboxListId, title: 'Reunião', priority: Priority.high, kind: TaskKind.checklist);
    await repo.markWontDo(id);
    final row = await db.customSelect('SELECT priority, status, kind FROM tasks').getSingle();
    expect(row.read<int>('priority'), 5);
    expect(row.read<int>('status'), -1);
    expect(row.read<String>('kind'), 'CHECKLIST');
  });

  test('an unknown code in the database fails instead of becoming a default', () async {
    await db.customStatement(
      'INSERT INTO tasks (id, created_at, updated_at, list_id, sort_order, priority) '
      "VALUES ('x', '2026-09-24T12:00:00.000Z', '2026-09-24T12:00:00.000Z', 'inbox', 0, 2)",
    );
    await expectLater(db.select(db.tasks).get(), throwsFormatException);
  });

  test('foreign keys are enforced', () async {
    await expectLater(repo.createTask(listId: 'missing'), throwsA(anything));
  });

  test('new tasks go to the top by default', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'A');
    final b = await repo.createTask(listId: inboxListId, title: 'B');
    expect((await repo.task(b)).sortOrder, (await repo.task(a)).sortOrder - SortOrder.step);
  });

  test('completing a task completes its open subtasks; reopen only reopens the task', () async {
    final parent = await repo.createTask(listId: inboxListId, title: 'Pai');
    final child = await repo.createTask(listId: inboxListId, title: 'Filho', parentId: parent);
    await repo.complete(parent);
    expect((await repo.task(child)).status, TaskStatus.completed);
    await repo.reopen(parent);
    expect((await repo.task(parent)).status, TaskStatus.open);
    expect((await repo.task(child)).status, TaskStatus.completed);
  });

  test('delete sends the task and its subtasks to the trash; restore brings them back', () async {
    final parent = await repo.createTask(listId: inboxListId, title: 'Pai');
    final child = await repo.createTask(listId: inboxListId, title: 'Filho', parentId: parent);
    await repo.delete(parent);
    expect((await repo.task(child)).deletedAt, isNotNull);
    await repo.restore(parent);
    expect((await repo.task(child)).deletedAt, isNull);
  });

  test('restoring a task whose list was deleted puts it in the Inbox', () async {
    final list = await repo.createList(name: 'Trabalho');
    final id = await repo.createTask(listId: list, title: 'T');
    await repo.deleteList(list);
    expect((await repo.task(id)).deletedAt, isNotNull);
    await repo.restore(id);
    expect((await repo.task(id)).listId, inboxListId);
  });

  test('empty trash deletes rows, items and tag links', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T', kind: TaskKind.checklist);
    await repo.addChecklistItem(id, title: 'item');
    final tag = await repo.createTag('clone');
    await repo.setTaskTags(id, {tag});
    await repo.delete(id);
    await repo.emptyTrash();
    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await db.select(db.checklistItems).get(), isEmpty);
    expect(await db.select(db.taskTags).get(), isEmpty);
  });

  test('the Inbox cannot be archived nor deleted', () {
    expect(() => repo.archiveList(inboxListId, archived: true), throwsA(isA<RuleViolation>()));
    expect(() => repo.deleteList(inboxListId), throwsA(isA<RuleViolation>()));
  });

  test('checking every checklist item completes the task', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'Mala', kind: TaskKind.checklist);
    final a = await repo.addChecklistItem(id, title: 'A');
    final b = await repo.addChecklistItem(id, title: 'B');
    await repo.setChecklistItemCompleted(a, completed: true);
    expect((await repo.task(id)).progress, 50);
    await repo.setChecklistItemCompleted(b, completed: true);
    final t = await repo.task(id);
    expect(t.progress, 100);
    expect(t.status, TaskStatus.completed);
  });

  test('checklist mode turns description lines into items and back', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T', content: '- um\n- dois\n\n3. três');
    await repo.toggleChecklist(id);
    final items = await db.select(db.checklistItems).get();
    expect(items.map((i) => i.title), ['um', 'dois', 'três']);
    await repo.toggleChecklist(id);
    expect((await repo.task(id)).content, 'um\ndois\ntrês');
  });

  test('a task with subtasks cannot become a note', () async {
    final parent = await repo.createTask(listId: inboxListId, title: 'Pai');
    await repo.createTask(listId: inboxListId, title: 'Filho', parentId: parent);
    await expectLater(repo.convert(parent, TaskKind.note), throwsA(isA<RuleViolation>()));
  });

  test('subtasks go up to 5 levels and never loop', () async {
    var parent = await repo.createTask(listId: inboxListId, title: 'n0');
    final root = parent;
    for (var i = 1; i < 5; i++) {
      parent = await repo.createTask(listId: inboxListId, title: 'n$i', parentId: parent);
    }
    final extra = await repo.createTask(listId: inboxListId, title: 'n5');
    await expectLater(repo.makeSubtask(extra, parent), throwsA(isA<RuleViolation>()));
    await expectLater(repo.makeSubtask(root, parent), throwsA(isA<RuleViolation>()));
  });

  test('moving a task moves its subtasks to the new list', () async {
    final list = await repo.createList(name: 'Outra');
    final parent = await repo.createTask(listId: inboxListId, title: 'Pai');
    final child = await repo.createTask(listId: inboxListId, title: 'Filho', parentId: parent);
    await repo.move(parent, list);
    expect((await repo.task(child)).listId, list);
  });

  test('duplicating a list copies sections and open tasks with the suffix', () async {
    final list = await repo.createList(name: 'Clone');
    final section = await repo.createSection(list, 'Fazendo');
    await repo.createTask(listId: list, title: 'aberta', sectionId: section);
    final done = await repo.createTask(listId: list, title: 'feita');
    await repo.complete(done);
    final copy = await repo.duplicateList(list, copySuffix: ' copiar');
    final s = await repo.loadSnapshot();
    expect(s.listById[copy]!.name, 'Clone copiar');
    expect(s.sectionsOf(copy).map((x) => x.name), ['Fazendo']);
    final copied = s.tasks.where((t) => t.listId == copy).toList();
    expect(copied.map((t) => t.title), ['aberta']);
    expect(copied.single.sectionId, s.sectionsOf(copy).single.id);
    // Above the original, without its color.
    expect(s.listById[copy]!.sortOrder, lessThan(s.listById[list]!.sortOrder));
    expect(s.listById[copy]!.color, isNull);

    // "Todas as tarefas, preservando…" / "…sem o status de concluídas".
    final kept = await repo.duplicateList(list, copySuffix: ' copiar', mode: ListCopyMode.keepStatus);
    final reopened = await repo.duplicateList(list, copySuffix: ' copiar', mode: ListCopyMode.allReopened);
    final after = await repo.loadSnapshot();
    Map<String, TaskStatus> statuses(String listId) => {for (final t in after.tasks.where((t) => t.listId == listId)) t.title: t.status};
    expect(statuses(kept), {'aberta': TaskStatus.open, 'feita': TaskStatus.completed});
    expect(statuses(reopened), {'aberta': TaskStatus.open, 'feita': TaskStatus.open});
  });

  test('tags: duplicate names reuse the tag, merge moves links, delete lifts sub-tags', () async {
    final a = await repo.createTag('#clone');
    expect(await repo.createTag('clone'), a);
    final b = await repo.createTag('teste');
    final child = await repo.createTag('sub', parentId: a);
    final task = await repo.createTask(listId: inboxListId, title: 'T', tagIds: [a]);
    await repo.mergeTags(a, b);
    final s = await repo.loadSnapshot();
    expect(s.tagsOf(task).map((t) => t.name), ['teste']);
    expect(s.tagById[child]!.parentId, isNull);
    await expectLater(repo.editTag(b, name: 'sub'), throwsA(isA<RuleViolation>()));
  });

  test('new sections are created at the top', () async {
    final list = await repo.createList(name: 'L');
    await repo.createSection(list, 'Primeira');
    await repo.createSection(list, 'Segunda');
    final s = await repo.loadSnapshot();
    expect(s.sectionsOf(list).map((x) => x.name), ['Segunda', 'Primeira']);
  });

  test('watchSnapshot emits again after a write', () async {
    final stream = repo.watchSnapshot();
    final counts = <int>[];
    final sub = stream.listen((s) => counts.add(s.tasks.length));
    await pumpEventQueue();
    await repo.createTask(listId: inboxListId, title: 'nova');
    await pumpEventQueue();
    await sub.cancel();
    expect(counts.first, 0);
    expect(counts.last, 1);
  });

  test('dates are stored in UTC', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T', dueDate: DateTime(2026, 9, 25));
    final t = await repo.task(id);
    expect(t.dueDate!.toLocal(), DateTime(2026, 9, 25));
    await repo.setDueDate(id, null);
    expect((await repo.task(id)).dueDate, isNull);
    expect(const Value<String?>.absent().present, isFalse);
  });

  test('moveBefore places a task before the target and reindexes when needed', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'a', atTop: false);
    final b = await repo.createTask(listId: inboxListId, title: 'b', atTop: false);
    final c = await repo.createTask(listId: inboxListId, title: 'c', atTop: false);
    await repo.moveBefore(c, b);
    Future<List<String>> order() async =>
        ((await repo.loadSnapshot()).tasks.where((t) => t.parentId == null).toList()..sort((x, y) => x.sortOrder.compareTo(y.sortOrder)))
            .map((t) => t.title)
            .toList();
    expect(await order(), ['a', 'c', 'b']);
    // Force adjacent orders, then move again: the siblings get reindexed.
    await repo.reorder(a, 0);
    await repo.reorder(c, 1);
    await repo.reorder(b, 2);
    await repo.moveBefore(b, c);
    expect(await order(), ['a', 'b', 'c']);
  });

  test('moveAfter places a task after the target, at the end too, and reindexes when needed', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'a', atTop: false);
    final b = await repo.createTask(listId: inboxListId, title: 'b', atTop: false);
    final c = await repo.createTask(listId: inboxListId, title: 'c', atTop: false);
    Future<List<String>> order() async =>
        ((await repo.loadSnapshot()).tasks.where((t) => t.parentId == null).toList()..sort((x, y) => x.sortOrder.compareTo(y.sortOrder)))
            .map((t) => t.title)
            .toList();
    await repo.moveAfter(a, c);
    expect(await order(), ['b', 'c', 'a']);
    await repo.moveAfter(a, b);
    expect(await order(), ['b', 'a', 'c']);
    // Adjacent orders: the siblings get reindexed.
    await repo.reorder(b, 0);
    await repo.reorder(a, 1);
    await repo.reorder(c, 2);
    await repo.moveAfter(c, b);
    expect(await order(), ['b', 'c', 'a']);
  });

  test('moveBefore adopts the target level and section; loops are refused', () async {
    final list = await repo.createList(name: 'L');
    final section = await repo.createSection(list, 'S');
    final parent = await repo.createTask(listId: list, title: 'pai', sectionId: section);
    final child = await repo.createTask(listId: list, title: 'filho', parentId: parent, sectionId: section);
    final loose = await repo.createTask(listId: inboxListId, title: 'solta');
    await repo.moveBefore(loose, child);
    final moved = await repo.task(loose);
    expect(moved.parentId, parent);
    expect(moved.listId, list);
    expect(moved.sectionId, section);
    await expectLater(repo.moveBefore(parent, child), throwsA(isA<RuleViolation>()));
  });

  test('moveToSectionTop moves a task to the top of a section at the top level', () async {
    final list = await repo.createList(name: 'L');
    final section = await repo.createSection(list, 'S');
    final first = await repo.createTask(listId: list, title: 'primeira', sectionId: section);
    final other = await repo.createTask(listId: inboxListId, title: 'outra');
    await repo.moveToSectionTop(other, list, section);
    final t = await repo.task(other);
    expect(t.sectionId, section);
    expect(t.sortOrder, lessThan((await repo.task(first)).sortOrder));
  });

  test('completing a repeating task leaves a completed copy and moves to the next date', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'Regar plantas', dueDate: DateTime(2026, 9, 24), repeatRule: 'FREQ=DAILY;COUNT=2');
    await repo.complete(id);
    final s = await repo.loadSnapshot();
    final original = s.taskById[id]!;
    expect(original.status, TaskStatus.open);
    expect(original.dueDate!.toLocal(), DateTime(2026, 9, 25));
    expect(original.repeatRule, contains('COUNT=1'));
    final copy = s.tasks.singleWhere((t) => t.id != id);
    expect(copy.status, TaskStatus.completed);
    expect(copy.dueDate!.toLocal(), DateTime(2026, 9, 24));
    expect(copy.repeatRule, isNull);
    // Last occurrence (COUNT=1): completes for real.
    await repo.complete(id);
    expect((await repo.task(id)).status, TaskStatus.completed);
  });

  test('reminders are stored per task and removed with it', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T', reminders: ['PT0S', '-PT15M']);
    expect((await repo.remindersOf(id)).toSet(), {'PT0S', '-PT15M'});
    await repo.setReminders(id, {'-P1D'});
    expect(await repo.remindersOf(id), ['-P1D']);
    expect((await repo.loadSnapshot()).remindersOf(id), ['-P1D']);
    await repo.delete(id);
    await repo.deleteForever(id);
    expect(await db.select(db.taskReminders).get(), isEmpty);
  });

  test('setSchedule writes date, reminders and repetition; no date clears them', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T');
    await repo.setSchedule(
      id,
      dueDate: DateTime(2026, 9, 28, 9),
      isAllDay: false,
      reminders: {'PT0S'},
      repeatRule: 'FREQ=DAILY;INTERVAL=1',
      repeatFrom: RepeatFrom.completion,
    );
    var t = await repo.task(id);
    expect(t.dueDate!.toLocal(), DateTime(2026, 9, 28, 9));
    expect(t.isAllDay, isFalse);
    expect(t.repeatRule, 'FREQ=DAILY;INTERVAL=1');
    expect(t.repeatFrom, RepeatFrom.completion.code);
    expect(await repo.remindersOf(id), ['PT0S']);

    await repo.setSchedule(id, dueDate: null, reminders: {'PT0S'}, repeatRule: 'FREQ=DAILY;INTERVAL=1');
    t = await repo.task(id);
    expect(t.dueDate, isNull);
    expect(t.repeatRule, isNull);
    expect(await repo.remindersOf(id), isEmpty);
  });

  test('a duration keeps its start; a single date or a start after the end drops it', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T');
    await repo.setSchedule(id, startDate: DateTime(2026, 9, 25, 10), dueDate: DateTime(2026, 9, 25, 11), isAllDay: false);
    var t = await repo.task(id);
    expect(t.startDate!.toLocal(), DateTime(2026, 9, 25, 10));
    expect(t.dueDate!.toLocal(), DateTime(2026, 9, 25, 11));

    await repo.setDueDate(id, DateTime(2026, 9, 26));
    t = await repo.task(id);
    expect(t.startDate, t.dueDate);

    await repo.setSchedule(id, startDate: DateTime(2026, 9, 28), dueDate: DateTime(2026, 9, 27));
    t = await repo.task(id);
    expect(t.startDate, t.dueDate);
  });

  test('merge makes the tasks subtasks of a new one; postpone shifts start and end', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'A');
    final b = await repo.createTask(listId: inboxListId, title: 'B');
    final merged = await repo.merge([a, b], 'Nova tarefa mesclada.');
    expect((await repo.task(a)).parentId, merged);
    expect((await repo.task(b)).parentId, merged);
    expect((await repo.task(merged)).title, 'Nova tarefa mesclada.');

    await repo.setSchedule(a, startDate: DateTime(2026, 9, 25, 10), dueDate: DateTime(2026, 9, 25, 11), isAllDay: false);
    await repo.postpone(a, 7);
    final t = await repo.task(a);
    expect((t.startDate!.toLocal(), t.dueDate!.toLocal()), (DateTime(2026, 10, 2, 10), DateTime(2026, 10, 2, 11)));
    await repo.postpone(b, 1);
    expect((await repo.task(b)).dueDate!.toLocal(), isNotNull, reason: 'a task without a date gets one');
  });

  test('templates: save a checklist task with tags, create a task from it without a date', () async {
    final tag = await repo.createTag('viagem');
    final t = await repo.createTask(listId: inboxListId, title: 'Mala', kind: TaskKind.checklist, dueDate: DateTime(2026, 9, 26), tagIds: [tag]);
    final a = await repo.addChecklistItem(t, title: 'Passaporte');
    await repo.addChecklistItem(t, title: 'Carregador', afterItemId: a);
    final template = await repo.saveTaskAsTemplate(t, 'Mala de viagem');

    final work = await repo.createList(name: 'Trabalho');
    final created = await repo.createTaskFromTemplate(template, listId: work);
    final s = await repo.loadSnapshot();
    final task = s.taskById[created]!;
    expect((task.title, task.listId, task.kind, task.dueDate), ('Mala', work, TaskKind.checklist, null));
    expect(s.itemsOf(created).map((i) => i.title), ['Passaporte', 'Carregador']);
    expect(s.tagsOf(created).map((x) => x.id), [tag]);

    await repo.renameTemplate(template, 'Mala');
    expect((await repo.watchTemplates().first).single.name, 'Mala');
    await repo.deleteTemplate(template);
    expect(await repo.watchTemplates().first, isEmpty);
  });

  test('comments: add, edit, delete; deleting the task forever removes them', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'T');
    final c = await repo.addComment(id, '  Primeiro comentário ');
    await repo.addComment(id, 'Segundo');
    expect((await repo.watchComments(id).first).map((x) => x.body), ['Primeiro comentário', 'Segundo']);
    await repo.editComment(c, 'Editado');
    await repo.deleteComment((await repo.watchComments(id).first).last.id);
    expect((await repo.watchComments(id).first).map((x) => x.body), ['Editado']);
    await repo.delete(id);
    await repo.deleteForever(id);
    expect(await db.select(db.comments).get(), isEmpty);
  });
}
