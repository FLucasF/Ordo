import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/project.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Thursday, 2026-09-24, noon.
  final now = DateTime(2026, 9, 24, 12);
  late FixedClock clock;

  setUp(() {
    clock = FixedClock(now);
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  /// A task in [listId] due on [due] (all-day), completed at [doneAt] when given.
  Future<String> task(String listId, String title, {DateTime? due, DateTime? doneAt, bool timed = false}) async {
    final id = await repo.createTask(listId: listId, title: title, dueDate: due, isAllDay: !timed);
    if (doneAt != null) {
      clock.time = doneAt;
      await repo.complete(id);
      clock.time = now;
    }
    return id;
  }

  Future<Task> load(String id) async => (await repo.loadSnapshot()).taskById[id]!;

  group('accuracy', () {
    test('done by the due date 100%, after 50%, overdue and open 0%; no date or still ahead don\'t count', () async {
      final list = await repo.createList(name: 'Projeto');
      final onTime = await task(list, 'no prazo', due: DateTime(2026, 9, 20), doneAt: DateTime(2026, 9, 20, 22));
      final late = await task(list, 'depois', due: DateTime(2026, 9, 20), doneAt: DateTime(2026, 9, 21, 8));
      final missed = await task(list, 'vencida', due: DateTime(2026, 9, 23));
      final noDate = await task(list, 'sem prazo', doneAt: DateTime(2026, 9, 22));
      final ahead = await task(list, 'futura', due: DateTime(2026, 9, 30));
      final dueToday = await task(list, 'hoje', due: DateTime(2026, 9, 24));
      final aheadDone = await task(list, 'adiantada', due: DateTime(2026, 9, 30), doneAt: DateTime(2026, 9, 23));

      expect(taskAccuracy(await load(onTime), now), 1);
      expect(taskAccuracy(await load(late), now), 0.5);
      expect(taskAccuracy(await load(missed), now), 0);
      expect(taskAccuracy(await load(noDate), now), isNull);
      expect(taskAccuracy(await load(ahead), now), isNull);
      // An all-day task is late only once its day is over.
      expect(taskAccuracy(await load(dueToday), now), isNull);
      expect(taskAccuracy(await load(aheadDone), now), 1);

      final tasks = [
        for (final id in [onTime, late, missed, noDate, ahead, dueToday, aheadDone]) await load(id),
      ];
      final a = Accuracy.of(tasks, now);
      expect(a.counted, 4);
      expect(a.rate, closeTo((1 + 0.5 + 0 + 1) / 4, 1e-9));
      expect((a.onTime, a.late, a.missed), (2, 1, 1));
      expect([for (final t in a.lateTasks) t.title], ['depois', 'vencida']);
      expect(Accuracy.of(const [], now).rate, isNull);
    });

    test('a timed task is judged by its time', () async {
      final list = await repo.createList(name: 'P');
      final id = await task(list, 'reunião', due: DateTime(2026, 9, 24, 10), timed: true, doneAt: DateTime(2026, 9, 24, 11));
      expect(taskAccuracy(await load(id), now), 0.5);
      final open = await task(list, 'ligação', due: DateTime(2026, 9, 24, 9), timed: true);
      expect(taskAccuracy(await load(open), now), 0);
    });
  });

  group('pace', () {
    test('remaining ÷ days left against the last 7 days, green / yellow / red', () async {
      final list = await repo.createList(name: 'P');
      for (var i = 0; i < 7; i++) {
        await task(list, 'aberta $i');
      }
      // 7 done in the last 7 days: 1 a day.
      for (var i = 0; i < 7; i++) {
        await task(list, 'feita $i', doneAt: DateTime(2026, 9, 24 - i, 9));
      }
      // Done before the window: doesn't count for the recent pace.
      await task(list, 'antiga', doneAt: DateTime(2026, 9, 10));
      final tasks = (await repo.loadSnapshot()).tasks;

      // 7 left in 10 days: 0.7 a day; doing 1 a day is on track.
      final easy = projectPace(tasks, DateTime(2026, 10, 4), now)!;
      expect(easy.remaining, 7);
      expect(easy.daysLeft, 10);
      expect(easy.perDay, closeTo(0.7, 1e-9));
      expect(easy.recent, closeTo(1, 1e-9));
      expect(easy.level, PaceLevel.onTrack);
      // 7 in 5 days: 1.4 a day; 1 is at least 60% of it.
      expect(projectPace(tasks, DateTime(2026, 9, 29), now)!.level, PaceLevel.close);
      // 7 in 2 days: 3.5 a day.
      expect(projectPace(tasks, DateTime(2026, 9, 26), now)!.level, PaceLevel.behind);
      // On the day itself, everything left is for today.
      expect(projectPace(tasks, DateTime(2026, 9, 24), now)!.perDay, 7);
      // Once the day has passed there is no pace.
      expect(projectPace(tasks, DateTime(2026, 9, 23), now), isNull);
    });

    test('nothing left is on track', () {
      expect(projectPace(const [], DateTime(2026, 10, 1), now)!.level, PaceLevel.onTrack);
    });
  });

  test('completions per day, from the first day to the last', () async {
    final list = await repo.createList(name: 'P');
    await task(list, 'a', doneAt: DateTime(2026, 9, 20, 8));
    await task(list, 'b', doneAt: DateTime(2026, 9, 20, 18));
    await task(list, 'c', doneAt: DateTime(2026, 9, 22, 8));
    await task(list, 'd');
    final tasks = (await repo.loadSnapshot()).tasks;
    expect(completionsPerDay(tasks, DateTime(2026, 9, 19), DateTime(2026, 9, 22)), [0, 2, 0, 1]);
  });

  group('project of a countdown', () {
    test('a list project takes its sublists; an area takes its lists; notes and "won\'t do" stay out', () async {
      final area = await repo.createFolder('Faculdade');
      final calc = await repo.createList(name: 'Cálculo', folderId: area);
      final lista3 = await repo.createList(name: 'Lista 3', parentId: calc);
      final other = await repo.createList(name: 'Outra');
      await task(calc, 'derivadas');
      await task(lista3, 'exercício 1', doneAt: DateTime(2026, 9, 23));
      await task(other, 'fora');
      final dropped = await task(calc, 'desisti');
      await repo.markWontDo(dropped);
      final note = await repo.createTask(listId: calc, title: 'nota', kind: TaskKind.note);
      expect(note, isNotEmpty);

      final byList = await repo.createCountdown(name: 'Prova', date: DateTime(2026, 10, 1), listId: calc);
      final byArea = await repo.createCountdown(name: 'Semestre', date: DateTime(2026, 12, 1), folderId: area);
      final s = await repo.loadSnapshot();
      final listProject = s.countdowns.firstWhere((c) => c.id == byList);
      final areaProject = s.countdowns.firstWhere((c) => c.id == byArea);
      expect(isProject(listProject), isTrue);
      expect([for (final l in projectLists(s, listProject)) l.name], ['Cálculo', 'Lista 3']);
      expect({for (final t in projectTasks(s, listProject)) t.title}, {'derivadas', 'exercício 1'});
      expect({for (final t in projectTasks(s, areaProject)) t.title}, {'derivadas', 'exercício 1'});
      final p = ProjectProgress.of(projectTasks(s, listProject));
      expect((p.done, p.total, p.ratio), (1, 2, 0.5));
      // Unlinked: no project, and the plain countdown keeps working.
      final plain = await repo.createCountdown(name: 'Férias', date: DateTime(2026, 12, 20));
      final s2 = await repo.loadSnapshot();
      expect(isProject(s2.countdowns.firstWhere((c) => c.id == plain)), isFalse);
      expect(projectTasks(s2, s2.countdowns.firstWhere((c) => c.id == plain)), isEmpty);
    });

    test('progress by section and the next deadlines', () async {
      final list = await repo.createList(name: 'Obra');
      final sec = await repo.createSection(list, 'Pintura');
      await repo.createTask(listId: list, sectionId: sec, title: 'parede', dueDate: DateTime(2026, 9, 28));
      await task(list, 'piso', due: DateTime(2026, 9, 26));
      await task(list, 'atrasada', due: DateTime(2026, 9, 20));
      await task(list, 'feita', due: DateTime(2026, 9, 21), doneAt: DateTime(2026, 9, 21));
      final s = await repo.loadSnapshot();
      final tasks = s.tasks.where((t) => t.listId == list).toList();
      final parts = progressBySection(s, [s.listById[list]!], tasks);
      expect([for (final p in parts) (p.sectionId, p.progress.done, p.progress.total)], [(null, 1, 3), (sec, 0, 1)]);
      expect([for (final t in upcomingWithDeadline(tasks)) t.title], ['atrasada', 'piso', 'parede']);
    });
  });

  group('final report', () {
    test('trophies, deadlines, accuracy, evolution and best day; JSON round trip', () async {
      final list = await repo.createList(name: 'P');
      // A 10-day project, from 09-15 to 09-24, every deadline met.
      await task(list, 'a', due: DateTime(2026, 9, 16), doneAt: DateTime(2026, 9, 16, 10));
      await task(list, 'b', due: DateTime(2026, 9, 20), doneAt: DateTime(2026, 9, 19, 10));
      await task(list, 'c', due: DateTime(2026, 9, 22), doneAt: DateTime(2026, 9, 22, 10));
      await task(list, 'd', due: DateTime(2026, 9, 23), doneAt: DateTime(2026, 9, 22, 18));
      await task(list, 'e', doneAt: DateTime(2026, 9, 24, 9));
      final tasks = (await repo.loadSnapshot()).tasks.where((t) => t.listId == list).toList();
      final r = buildProjectReport(tasks, start: DateTime(2026, 9, 15), end: DateTime(2026, 9, 24));

      expect((r.done, r.total), (5, 5));
      expect(r.accuracy, 1);
      expect((r.onTime, r.late, r.missed), (4, 0, 0));
      expect(r.evolution, [0, 1, 0, 0, 1, 0, 0, 2, 0, 1]);
      expect(r.bestDay, DateTime(2026, 9, 22));
      expect(r.bestDayCount, 2);
      // 4 of 5 in the last 7 days: 0.57 a day against 0.5 for the whole project.
      expect(r.trophies, {Trophy.allDone, Trophy.allOnTime, Trophy.strongFinish, Trophy.noLate7});

      final back = ProjectReport.decode(r.encode())!;
      expect((back.start, back.end, back.done, back.total, back.accuracy), (r.start, r.end, 5, 5, 1.0));
      expect(back.evolution, r.evolution);
      expect(back.bestDay, r.bestDay);
      expect(back.trophies, r.trophies);
      expect(back.evolutionStart, DateTime(2026, 9, 15));
      expect(ProjectReport.decode('not json'), isNull);
      expect(ProjectReport.decode(null), isNull);
    });

    test('late and missed tasks take the trophies away; work after the end does not count', () async {
      final list = await repo.createList(name: 'P');
      await task(list, 'atrasou', due: DateTime(2026, 9, 18), doneAt: DateTime(2026, 9, 19));
      await task(list, 'perdida', due: DateTime(2026, 9, 21));
      // Done after the project's end: open in the report.
      await task(list, 'depois do fim', due: DateTime(2026, 9, 22), doneAt: DateTime(2026, 9, 24));
      final tasks = (await repo.loadSnapshot()).tasks.where((t) => t.listId == list).toList();
      final r = buildProjectReport(tasks, start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 22));
      expect((r.done, r.total), (1, 3));
      expect((r.onTime, r.late, r.missed), (0, 1, 2));
      expect(r.accuracy, closeTo(0.5 / 3, 1e-9));
      expect(r.trophies, isEmpty);
    });
  });

  test('a linked countdown closes by itself the day after its day, once', () async {
    final list = await repo.createList(name: 'P');
    final id = await repo.createCountdown(name: 'Entrega', date: DateTime(2026, 9, 23), listId: list);
    final plainId = await repo.createCountdown(name: 'Só data', date: DateTime(2026, 9, 1));
    Future<Countdown> load(String id) async => (await repo.loadSnapshot()).countdowns.firstWhere((c) => c.id == id);
    expect(closesByItself(await load(plainId), now), isFalse);
    expect(closesByItself(await load(id), DateTime(2026, 9, 23, 20)), isFalse);
    expect(closesByItself(await load(id), now), isTrue);
    await repo.closeProject(id, '{}');
    expect(closesByItself(await load(id), now), isFalse);
    // Reopened, it keeps its report and stays open.
    await repo.reopenProject(id);
    final reopened = await load(id);
    expect(reopened.closedAt, isNull);
    expect(reopened.report, '{}');
    expect(closesByItself(reopened, now), isFalse);
  });
}
