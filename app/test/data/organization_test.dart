import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/snapshot.dart';
import 'package:task_manager/domain/views.dart';
import 'package:task_manager/features/backup/backup_service.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  final now = DateTime(2026, 9, 24, 12);
  final clock = FixedClock(now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<TaskList> list(String id) async => (await repo.loadSnapshot()).listById[id]!;

  Matcher breaks(Rule rule) => throwsA(isA<RuleViolation>().having((e) => e.rule, 'rule', rule));

  group('areas (folders)', () {
    test('created with emoji and color, edited, deleted with its lists left out, and restored', () async {
      final area = await repo.createFolder(' Saúde ', icon: '💪', color: '#35D870');
      final gym = await repo.createList(name: 'Academia', folderId: area);
      final diet = await repo.createList(name: 'Dieta', folderId: area);
      var s = await repo.loadSnapshot();
      expect((s.folderById[area]!.name, s.folderById[area]!.icon, s.folderById[area]!.color), ('Saúde', '💪', '#35D870'));

      await repo.editFolder(area, name: 'Corpo', icon: null, color: '#FF6161');
      s = await repo.loadSnapshot();
      expect((s.folderById[area]!.name, s.folderById[area]!.icon, s.folderById[area]!.color), ('Corpo', null, '#FF6161'));

      final left = await repo.deleteFolder(area);
      s = await repo.loadSnapshot();
      expect(left.toSet(), {gym, diet});
      expect(s.activeFolders, isEmpty);
      // Nothing else goes: the lists stay, out of the area.
      expect(s.activeLists.where((l) => l.id == gym || l.id == diet).map((l) => l.folderId), [null, null]);

      // "Desfazer".
      await repo.restoreFolder(area, left);
      s = await repo.loadSnapshot();
      expect(s.activeFolders.single.id, area);
      expect((await list(gym)).folderId, area);
    });
  });

  group('sublists', () {
    test('a sublist takes its parent\'s area, follows it, and goes 3 levels deep at most', () async {
      final area = await repo.createFolder('Faculdade');
      final uni = await repo.createList(name: 'Faculdade', folderId: area);
      final calc = await repo.createList(name: 'Cálculo', parentId: uni, folderId: null);
      final third = await repo.createList(name: 'Lista 3', parentId: calc);
      expect((await list(calc)).folderId, area);
      expect((await list(third)).parentId, calc);
      // A fourth level, a loop or the Inbox are refused.
      await expectLater(repo.createList(name: 'Fundo', parentId: third), breaks(Rule.sublistDepthLimit));
      await expectLater(repo.makeSublist(uni, third), breaks(Rule.listCannotBeItsOwnParent));
      await expectLater(repo.makeSublist(uni, uni), breaks(Rule.listCannotBeItsOwnParent));
      await expectLater(repo.makeSublist(inboxListId, uni), breaks(Rule.inboxCannotNest));
      // A list with sublists brings their levels along: three under a top list make four.
      final other = await repo.createList(name: 'Outra');
      await expectLater(repo.makeSublist(uni, other), breaks(Rule.sublistDepthLimit));
      await repo.makeSublist(calc, other);
      expect(((await list(calc)).parentId, (await list(third)).folderId), (other, null));
      await repo.makeSublist(calc, uni);
      await repo.makeSublist(third, other);
      expect((await list(third)).parentId, other);
      expect((await list(third)).folderId, isNull);

      // Moving the parent to another area takes its sublists.
      await repo.makeSublist(third, calc);
      final area2 = await repo.createFolder('Trabalho');
      await repo.moveList(uni, folderId: area2);
      expect([(await list(uni)).folderId, (await list(calc)).folderId, (await list(third)).folderId], [area2, area2, area2]);

      // The form: out of the parent, into an area of its own.
      await repo.editList(
        calc,
        name: 'Cálculo',
        folderId: area,
        parentId: const Value(null),
        kind: ListKind.tasks,
        viewMode: ViewMode.list,
        showInSmartLists: true,
      );
      expect(((await list(calc)).parentId, (await list(calc)).folderId, (await list(third)).folderId), (null, area, area));
      // Editing without touching "Dentro de" keeps the parent.
      await repo.editList(third, name: 'Lista 3b', folderId: null, kind: ListKind.tasks, viewMode: ViewMode.list, showInSmartLists: true);
      expect(((await list(third)).parentId, (await list(third)).folderId), (calc, area));
    });

    test('deleting or archiving a parent moves its sublists up a level, or takes them along', () async {
      final a = await repo.createList(name: 'A');
      final b = await repo.createList(name: 'B', parentId: a);
      final c = await repo.createList(name: 'C', parentId: b);
      final task = await repo.createTask(listId: c, title: 'em C');

      await repo.archiveList(b, archived: true);
      expect((await list(c)).parentId, a);
      expect((await list(c)).archivedAt, isNull);
      await repo.archiveList(b, archived: false);

      await repo.makeSublist(c, b);
      await repo.archiveList(b, archived: true, withSublists: true);
      expect((await list(c)).archivedAt, isNotNull);
      // Unarchived together.
      await repo.archiveList(b, archived: false);
      expect((await list(c)).archivedAt, isNull);

      await repo.deleteList(a);
      expect((await list(b)).parentId, isNull);
      expect((await list(b)).deletedAt, isNull);

      await repo.deleteList(b, withSublists: true);
      final s = await repo.loadSnapshot();
      expect(s.listById[c]!.deletedAt, isNotNull);
      expect(s.taskById[task]!.deletedAt, isNotNull);
    });

    test('views: the parent shows its sublists\' tasks grouped by sublist when asked; the area in tree order', () async {
      final area = await repo.createFolder('Faculdade');
      final calc = await repo.createList(name: 'Cálculo', folderId: area);
      final other = await repo.createList(name: 'Física', folderId: area);
      final third = await repo.createList(name: 'Lista 3', parentId: calc);
      await repo.createTask(listId: calc, title: 'limites');
      await repo.createTask(listId: third, title: 'exercício');
      await repo.createTask(listId: other, title: 'ondas');
      final s = await repo.loadSnapshot();

      List<String> titles(ViewContent v) => [
        for (final g in v.groups)
          for (final r in g.rows) r.task.title,
      ];
      expect(titles(buildView(s, ListScope(calc), now)), ['limites']);
      final withSublists = buildView(s, ListScope(calc), now, withSublists: true);
      expect([for (final g in withSublists.groups) (g.header as ListHeader).listId], [calc, third]);
      expect(titles(withSublists), ['limites', 'exercício']);
      // A sublist's task row names its list.
      expect(withSublists.groups.last.rows.single.list?.id, third);
      // Grouped by date, the sublists' tasks are in too.
      expect(titles(buildView(s, ListScope(calc), now, withSublists: true, options: const ViewOptions(grouping: Grouping.date))).toSet(), {
        'limites',
        'exercício',
      });
      // The area: each list followed by its sublists.
      expect([for (final g in buildView(s, FolderScope(area), now).groups) (g.header as ListHeader).listId], [calc, third, other]);
      expect(
        [for (final (l, depth) in s.listTree(s.activeLists.where((l) => l.folderId == area))) '${l.name}:$depth'],
        ['Cálculo:0', 'Lista 3:1', 'Física:0'],
      );
      expect(s.listDepth(s.listById[third]!), 1);

      // Moving a task into a sublist.
      final t = s.tasks.firstWhere((t) => t.title == 'limites');
      await repo.move(t.id, third);
      expect((await repo.loadSnapshot()).taskById[t.id]!.listId, third);
    });
  });

  test('a backup keeps sublists, areas\' look and countdown projects', () async {
    final temp = Directory.systemTemp.createTempSync('ordo_org_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final area = await repo.createFolder('Saúde', icon: '💪', color: '#35D870');
    // The sublist is created first and moved under a newer list, so a plain order would insert it first.
    final child = await repo.createList(name: 'Filha');
    final parent = await repo.createList(name: 'Mãe', folderId: area);
    await repo.makeSublist(child, parent);
    final cd = await repo.createCountdown(name: 'Meta', date: DateTime(2026, 10, 1), listId: parent);
    await repo.closeProject(cd, '{"v":1}');
    final bytes = await BackupService(db, tempDir: temp).export(withFiles: false);

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await BackupService(target, tempDir: temp).import(bytes);
    final s = await Repository(target, clock: clock).loadSnapshot();
    expect(s.listById[child]!.parentId, parent);
    expect(s.listById[child]!.folderId, area);
    expect((s.folderById[area]!.icon, s.folderById[area]!.color), ('💪', '#35D870'));
    final c = s.countdowns.single;
    expect((c.listId, c.report), (parent, '{"v":1}'));
    expect(c.closedAt, isNotNull);
  });

  test('countdown: linking to a list or an area, and a new day drops an open project\'s report', () async {
    final l = await repo.createList(name: 'P');
    final area = await repo.createFolder('A');
    final id = await repo.createCountdown(name: 'Meta', date: DateTime(2026, 10, 1), listId: l);
    Future<Countdown> load() async => (await repo.loadSnapshot()).countdowns.single;
    Future<void> save({required DateTime date, Value<String?> listId = const Value.absent(), Value<String?> folderId = const Value.absent()}) =>
        repo.updateCountdown(
          id,
          name: 'Meta',
          date: date,
          type: CountdownType.countdown,
          countMode: CountMode.standard,
          ignoreYear: false,
          showAge: false,
          reminders: const {},
          repeatRule: null,
          visibility: CountdownVisibility.onTheDay,
          listId: listId,
          folderId: folderId,
        );
    expect(((await load()).listId, (await load()).folderId), (l, null));
    await save(date: DateTime(2026, 10, 1), listId: const Value(null), folderId: Value(area));
    expect(((await load()).listId, (await load()).folderId), (null, area));
    // Absent: the link stays.
    await save(date: DateTime(2026, 10, 1));
    expect((await load()).folderId, area);

    await repo.closeProject(id, '{}');
    await repo.reopenProject(id);
    await save(date: DateTime(2026, 10, 1));
    expect((await load()).report, '{}');
    await save(date: DateTime(2026, 10, 9));
    expect((await load()).report, isNull);
  });

  test('Snapshot.empty has no sublists', () {
    expect(Snapshot.empty().sublistsOf('x'), isEmpty);
  });
}
