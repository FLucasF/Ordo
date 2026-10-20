import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/diet_repository.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/diet/diet.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/domain/journal/day_summary.dart';
import 'package:task_manager/domain/journal/journal.dart';

JournalEntry entry(int day, {int? mood, int? energy, String notes = '', String highlight = ''}) => JournalEntry(
  id: 'e$day',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  day: DateTime.utc(2026, 10, day),
  mood: mood,
  energy: energy,
  notes: notes,
  highlight: highlight,
);

void main() {
  group('entries', () {
    test('excerpt: the notes without markup or pictures, on one line, cut; else the highlight', () {
      final e = entry(1, notes: '# Manhã\n\nFui à **praia** com [a Ana](task:1)\n\n![file](abc/foto.jpg)\n- nadei');
      expect(journalExcerpt(e), 'Manhã Fui à praia com a Ana nadei');
      expect(journalExcerpt(e, max: 9), 'Manhã Fui…');
      expect(journalExcerpt(entry(2, highlight: 'Gratidão pelo sol')), 'Gratidão pelo sol');
      expect(journalEntryIsEmpty(entry(3)), isTrue);
      expect(journalEntryIsEmpty(entry(3, energy: 1)), isFalse);
    });

    test('search: every word, in the notes or the highlight, without accents or case', () {
      final e = entry(1, notes: 'Reunião com o **João** no café', highlight: 'Pão quentinho');
      expect(journalMatches(e, 'joao reuniao'), isTrue);
      expect(journalMatches(e, 'PAO'), isTrue);
      expect(journalMatches(e, 'joao chuva'), isFalse);
      expect(journalMatches(e, '  '), isTrue);
    });

    test('history: filters by mood and energy, leaves empty entries out, newest first', () {
      final entries = [
        entry(1, mood: 5, energy: 4, notes: 'praia'),
        entry(2, mood: 2, energy: 1, notes: 'chuva'),
        entry(3),
        entry(4, mood: 5, energy: 2, highlight: 'praia de novo'),
      ];
      List<String> ids(List<JournalEntry> l) => [for (final e in l) e.id];
      expect(ids(journalHistory(entries)), ['e4', 'e2', 'e1']);
      expect(ids(journalHistory(entries, moods: {5})), ['e4', 'e1']);
      expect(ids(journalHistory(entries, moods: {5}, energies: {4})), ['e1']);
      expect(ids(journalHistory(entries, query: 'praia', energies: {1, 2})), ['e4']);
    });

    test('series: days with a mood or an energy in the period, oldest first', () {
      final entries = [entry(5, mood: 3), entry(1, energy: 2), entry(2), entry(31, mood: 4)];
      final series = journalSeries(entries, DateTime(2026, 10), DateTime(2026, 10, 31));
      expect([for (final p in series) (p.day.day, p.mood, p.energy)], [(1, null, 2), (5, 3, null)]);
    });
  });

  group('day summary', () {
    late AppDatabase db;
    final clock = FixedClock(DateTime(2026, 10, 20, 9));
    final day = DateTime(2026, 10, 20);

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('tasks done, habits, calories against the target, focus and money of the day; other days left out', () async {
      final clockValue = _Clock(DateTime(2026, 10, 20, 10));
      final repo = Repository(db, clock: clockValue);
      final a = await repo.createTask(listId: inboxListId, title: 'a');
      final b = await repo.createTask(listId: inboxListId, title: 'b');
      final c = await repo.createTask(listId: inboxListId, title: 'c');
      await repo.complete(a);
      await repo.complete(b);
      clockValue.value = DateTime(2026, 10, 21, 8);
      await repo.complete(c);

      final read = await repo.createHabit(HabitsCompanion(name: const Value('Ler'), startDate: Value(DateTime(2026, 10, 1))));
      await repo.createHabit(HabitsCompanion(name: const Value('Correr'), startDate: Value(DateTime(2026, 10, 1))));
      final walk = await repo.createHabit(HabitsCompanion(name: const Value('Andar'), startDate: Value(DateTime(2026, 10, 1))));
      await repo.checkIn(read, day);
      await repo.markHabitDay(walk, day, HabitMark.skipped);

      await repo.addFocusRecord(
        FocusRecordDraft(startedAt: DateTime(2026, 10, 20, 14), endedAt: DateTime(2026, 10, 20, 14, 25), seconds: 25 * 60, mode: FocusMode.pomo),
      );
      await repo.addFocusRecord(
        FocusRecordDraft(startedAt: DateTime(2026, 10, 19, 14), endedAt: DateTime(2026, 10, 19, 15), seconds: 3600, mode: FocusMode.stopwatch),
      );

      final money = FinanceRepository(db, clock: clock);
      await money.addEntry(kind: FinKind.income, amount: 500000, date: day);
      await money.addEntry(kind: FinKind.expense, amount: 4590, date: day);
      await money.addEntry(kind: FinKind.expense, amount: 999, date: DateTime(2026, 10, 19));

      final diet = DietRepository(db, clock: clock);
      const rice = Food(id: 'taco:1', name: 'Arroz', per100g: Nutrients(kcal: 124));
      await diet.addEntry(day: day, meal: Meal.lunch, food: rice, quantity: 200);
      await diet.addEntry(
        day: day,
        meal: Meal.dinner,
        food: const Food(id: 'x', name: 'Sem valor', per100g: Nutrients()),
        quantity: 50,
      );
      await diet.addEntry(day: DateTime(2026, 10, 19), meal: Meal.lunch, food: rice, quantity: 100);

      final s = journalDaySummary(
        day: day,
        snapshot: await repo.loadSnapshot(),
        focus: await repo.watchFocusRecords().first,
        finance: await money.load(),
        diet: (await diet.load()).entries,
        kcalTarget: 2000,
      );
      expect(s.tasksDone, 2);
      expect((s.habitsDone, s.habitsTotal), (1, 2));
      expect((s.kcal, s.kcalTarget), (248.0, 2000.0));
      expect(s.focusMinutes, 25);
      expect((s.income, s.expense), (500000, 4590));
      expect(s.isEmpty, isFalse);
    });

    test('a day with nothing, or without the modules, is empty; no target without calories', () {
      final s = journalDaySummary(day: day, kcalTarget: 2000);
      expect(s.isEmpty, isTrue);
      expect(s.kcalTarget, isNull);
    });

    test("the calorie target is read from Dieta's preference, whatever its shape", () {
      expect(journalCalorieTarget({'kcal': 2100, 'protein': 120}), 2100);
      expect(journalCalorieTarget({'calories': 1800.5}), 1800.5);
      expect(journalCalorieTarget(1900), 1900);
      expect(journalCalorieTarget({'kcal': 0}), isNull);
      expect(journalCalorieTarget({'kcal': '2000'}), isNull);
      expect(journalCalorieTarget('x'), isNull);
      expect(journalCalorieTarget(null), isNull);
    });
  });
}

class _Clock implements Clock {
  _Clock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}
