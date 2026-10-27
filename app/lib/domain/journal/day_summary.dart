import '../../data/db/database.dart';
import '../finance/finance.dart';
import '../habits.dart';
import '../snapshot.dart';
import '../statistics.dart' show completedBetween, focusBetween;
import 'journal.dart' show journalDay;
import '../diet/targets.dart';

/// What the other modules say about a day, for the end of the day's notes. Computed when shown, never
/// stored, so it is always right.
class JournalDaySummary {
  const JournalDaySummary({
    this.tasksDone = 0,
    this.habitsDone = 0,
    this.habitsTotal = 0,
    this.kcal,
    this.kcalTarget,
    this.focusMinutes = 0,
    this.income = 0,
    this.expense = 0,
    this.finance = false,
  });

  final int tasksDone;

  /// Habits whose goal was met that day, of those due that day (plus any met while not due; skipped
  /// ones left out).
  final int habitsDone;
  final int habitsTotal;

  /// Calories eaten (null = nothing in Dieta that day) and the daily target, when Dieta has one.
  final double? kcal;
  final double? kcalTarget;
  final int focusMinutes;

  /// Finanças' income and expenses dated that day, in cents.
  final int income;
  final int expense;

  /// Whether Finanças is on: its line shows every day, even with nothing entered (R$ 0,00).
  final bool finance;

  int get balance => income - expense;

  bool get isEmpty => tasksDone == 0 && habitsTotal == 0 && kcal == null && focusMinutes == 0 && !finance;
}

/// The summary of [day] (a local day) from the tasks' snapshot (tasks and, unless [habits] is false,
/// habits), the focus records, Finanças and Dieta's entries; a module left out (null) adds nothing.
JournalDaySummary journalDaySummary({
  required DateTime day,
  Snapshot? snapshot,
  bool habits = true,
  List<FocusRecord> focus = const [],
  FinanceSnapshot? finance,
  List<DietEntry> diet = const [],
  double? kcalTarget,
}) {
  final from = DateTime(day.year, day.month, day.day), to = DateTime(day.year, day.month, day.day + 1);

  var habitsDone = 0, habitsTotal = 0;
  if (snapshot != null && habits) {
    for (final h in snapshot.habits) {
      if (h.deletedAt != null || h.archivedAt != null) continue;
      final checkin = snapshot.checkinsOf(h.id).where((c) => c.deletedAt == null && habitDay(c.day) == from).firstOrNull;
      final state = habitDayState(h, checkin, from);
      if (state == HabitDayState.done) habitsDone++;
      // A skipped day isn't asked for.
      if (state != HabitDayState.notRequired && state != HabitDayState.skipped) habitsTotal++;
    }
  }

  double? kcal;
  for (final e in diet) {
    if (e.deletedAt != null || journalDay(e.day) != from) continue;
    // A food without its calories in the table adds nothing (the sum is then a floor, as in Dieta).
    kcal = (kcal ?? 0) + (e.kcal ?? 0) * e.grams / 100;
  }

  final totals = finance == null
      ? const FinTotals()
      : totalsOf([
          for (final e in finance.entries)
            if (e.deletedAt == null && finDay(e.date) == from) e,
        ]);

  return JournalDaySummary(
    tasksDone: snapshot == null ? 0 : completedBetween(snapshot, from, to).length,
    habitsDone: habitsDone,
    habitsTotal: habitsTotal,
    kcal: kcal,
    kcalTarget: kcal == null ? null : kcalTarget,
    focusMinutes: focusBetween(focus, from, to).inMinutes,
    income: totals.income,
    expense: totals.expense,
    finance: finance != null,
  );
}

/// The daily calorie target from Dieta's `diet.targets` preference (its JSON, see [DietTargets]), or a
/// bare number; null when missing, invalid or not positive.
double? journalCalorieTarget(Object? targets) => switch (targets) {
  final num n when n > 0 => n.toDouble(),
  // Dieta's ⚙ Metas: the typed calories, or the macros' when it computes them.
  final Map<Object?, Object?> m => DietTargets.fromJson(m.cast<String, Object?>()).energy,
  _ => null,
};
