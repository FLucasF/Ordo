import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/countdown.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/habits.dart';
import 'package:task_manager/domain/journal/day_summary.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Tuesday, 2026-10-27.
  final now = DateTime(2026, 10, 27, 20);
  DateTime day(int d) => DateTime(2026, 10, d);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  Future<String> habit(String name, {String section = 'others', String weekdays = '', int start = 20}) =>
      repo.createHabit(HabitsCompanion(name: Value(name), section: Value(section), weekdays: Value(weekdays), startDate: Value(day(start))));

  test('a section\'s streak: days in a row with all its due habits done; today open does not break it', () async {
    final run = await habit('Correr', section: 'Ímpeto');
    final pray = await habit('Rezar', section: 'Ímpeto');
    // Sundays only: on the other days it is not asked for.
    final mass = await habit('Missa', section: 'Ímpeto', weekdays: '7');
    await habit('Ler'); // another section
    for (final d in [22, 23, 24, 25, 26]) {
      await repo.checkIn(run, day(d));
      await repo.checkIn(pray, day(d));
    }
    await repo.checkIn(mass, day(25));
    // Today (27): only one of the two done, still open.
    await repo.checkIn(run, day(27));
    var s = await repo.loadSnapshot();
    final section = s.habits.where((h) => h.section == 'Ímpeto').toList();
    expect(habitSectionStreak(section, s.checkinsOf, now), 5);

    // The Sunday habit undone on its Sunday breaks the run there.
    await repo.markHabitDay(mass, day(25), HabitMark.failed);
    s = await repo.loadSnapshot();
    expect(habitSectionStreak(s.habits.where((h) => h.section == 'Ímpeto').toList(), s.checkinsOf, now), 1);
  });

  test('a countdown that follows a habit counts the days left to its goal; the goal met shows the streak', () async {
    final run = await habit('Sem nicotina', start: 1);
    for (var d = 18; d <= 27; d++) {
      await repo.checkIn(run, day(d));
    }
    final id = await repo.createCountdown(name: '30 dias sem nicotina', date: day(27), habitId: run, goalDays: 30);
    var s = await repo.loadSnapshot();
    var c = s.countdowns.singleWhere((c) => c.id == id);
    expect(countdownFollowsHabit(c), isTrue);
    var status = countdownStatusIn(s, c, now);
    expect((status.streak, status.days, status.phase, status.target), (10, 20, CountdownPhase.future, day(27).add(const Duration(days: 20))));
    // Flipped (counting up): the streak itself.
    status = countdownStatusIn(s, c, now, countUp: true);
    expect((status.days, status.phase), (10, CountdownPhase.past));

    // A goal of 7, already met.
    await repo.updateCountdown(
      id,
      name: c.name,
      date: day(27),
      type: c.type,
      countMode: c.countMode,
      ignoreYear: false,
      showAge: false,
      reminders: const {},
      repeatRule: null,
      visibility: c.visibility,
      goalDays: const Value(7),
    );
    s = await repo.loadSnapshot();
    c = s.countdowns.singleWhere((c) => c.id == id);
    status = countdownStatusIn(s, c, now);
    expect((status.days, status.phase), (10, CountdownPhase.past));

    // A countdown to a date is as before.
    final plain = await repo.createCountdown(name: 'Viagem', date: day(30));
    s = await repo.loadSnapshot();
    final p = s.countdowns.singleWhere((c) => c.id == plain);
    expect(countdownFollowsHabit(p), isFalse);
    expect(countdownStatusIn(s, p, now).days, 3);
  });

  test('the day summary: a habit of Sundays only is not counted on the other days; Finanças always has its line', () async {
    final mass = await habit('Missa', weekdays: '7');
    final read = await habit('Ler');
    await repo.checkIn(read, day(27));
    final s = await repo.loadSnapshot();
    // Tuesday: only "Ler" is asked for, and it is done.
    var summary = journalDaySummary(day: day(27), snapshot: s);
    expect((summary.habitsDone, summary.habitsTotal), (1, 1));
    // Sunday 25: both asked for, none done.
    summary = journalDaySummary(day: day(25), snapshot: s);
    expect((summary.habitsDone, summary.habitsTotal), (0, 2));
    expect(mass, isNotEmpty);

    // Finanças on, nothing entered that day: the line is there with R$ 0,00.
    final finance = await FinanceRepository(db, clock: FixedClock(now)).load();
    summary = journalDaySummary(day: day(27), finance: finance);
    expect((summary.finance, summary.income, summary.expense, summary.balance, summary.isEmpty), (true, 0, 0, 0, false));
    // Finanças off: no line.
    expect(journalDaySummary(day: day(27)).finance, isFalse);
  });

  test('habitProgressOn: due habits of the day and how many are done', () async {
    await habit('Missa', weekdays: '7');
    final read = await habit('Ler');
    await habit('Correr');
    await repo.checkIn(read, day(27));
    final s = await repo.loadSnapshot();
    HabitCheckin? on(Habit h) => s.checkinsOf(h.id).where((c) => habitDay(c.day) == day(27)).firstOrNull;
    expect(habitProgressOn(s.habits, on, day(27)), (done: 1, due: 2));
  });

  test('habit tags are kept as ids; reorderHabits writes the dragged orders', () async {
    final tag = await repo.createTag('saúde');
    final id = await repo.createHabit(HabitsCompanion(name: const Value('Correr'), startDate: Value(day(20)), tags: Value(tag)));
    final other = await habit('Ler');
    var s = await repo.loadSnapshot();
    expect(habitTagIds(s.habits.singleWhere((h) => h.id == id)), {tag});
    expect([for (final h in s.habits) h.name], ['Correr', 'Ler']);
    await repo.reorderHabits({other: s.habits.first.sortOrder - 10});
    s = await repo.loadSnapshot();
    expect([for (final h in s.habits) h.name], ['Ler', 'Correr']);
  });
}
