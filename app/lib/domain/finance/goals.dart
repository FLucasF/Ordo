import '../../data/db/database.dart';
import 'finance.dart';

/// A "Caixinha" with its moves: what is in it, what is left to the target and, with a target day,
/// how much to put in each month to get there.
class GoalSummary {
  GoalSummary({required this.goal, required this.moves, required DateTime today})
    : saved = moves.fold(0, (sum, m) => sum + m.amount),
      _today = DateTime(today.year, today.month, today.day);

  final FinGoal goal;

  /// Newest first.
  final List<FinGoalMove> moves;

  /// Put in minus taken out.
  final int saved;
  final DateTime _today;

  /// "Faltam R$ X" (0 once reached).
  int get left => goal.target - saved < 0 ? 0 : goal.target - saved;

  bool get reached => saved >= goal.target;

  /// From 0 to 1, for the progress bar.
  double get progress => goal.target <= 0
      ? 1
      : saved <= 0
      ? 0
      : (saved / goal.target).clamp(0, 1).toDouble();

  /// Whether the target day went by without reaching the target.
  bool get pastDue => !reached && goal.dueOn != null && _today.isAfter(finDay(goal.dueOn!));

  /// The months left to save in (see [depositsUntil]); null without a target day.
  int? get monthsLeft => goal.dueOn == null ? null : depositsUntil(_today, finDay(goal.dueOn!));

  /// What to put in each month to reach the target on its day, rounded up to the cent; null without a
  /// target day, 0 once reached, everything left when the day went by.
  int? get perMonth {
    final months = monthsLeft;
    if (months == null) return null;
    if (left == 0) return 0;
    if (months == 0) return left;
    return (left + months - 1) ~/ months;
  }
}

/// How many monthly deposits fit from [today] to [due], both included: today's and one on the same
/// date of each month after it (Oct 20 to Dec 31 = Oct 20, Nov 20 and Dec 20 = 3). 0 when [due]
/// went by.
int depositsUntil(DateTime today, DateTime due) {
  if (due.isBefore(today)) return 0;
  var months = (due.year - today.year) * 12 + due.month - today.month;
  // The last month's deposit day comes after the target day.
  if (due.day < today.day && DateTime(due.year, due.month + 1, 0).day >= today.day) months--;
  return months + 1;
}

/// The goals with their moves (newest first), in their order: the ones in use, or the archived ones.
List<GoalSummary> goalSummaries(FinanceSnapshot s, DateTime today, {bool archived = false}) {
  final byGoal = <String, List<FinGoalMove>>{};
  for (final m in s.goalMoves) {
    byGoal.putIfAbsent(m.goalId, () => []).add(m);
  }
  return [
    for (final g in s.goals)
      if ((g.archivedAt != null) == archived)
        GoalSummary(
          goal: g,
          moves: (byGoal[g.id] ?? [])..sort((a, b) => a.date != b.date ? b.date.compareTo(a.date) : b.createdAt.compareTo(a.createdAt)),
          today: today,
        ),
  ];
}

/// The money in the goals (archived ones too: it is still set aside) and what went into them in
/// [month] (taken out counts against). Not income nor expenses: transfers.
({int total, int inMonth}) goalsSaved(FinanceSnapshot s, DateTime month) {
  final goals = {for (final g in s.goals) g.id};
  var total = 0, inMonth = 0;
  for (final m in s.goalMoves) {
    if (!goals.contains(m.goalId)) continue;
    total += m.amount;
    final day = finDay(m.date);
    if (day.year == month.year && day.month == month.month) inMonth += m.amount;
  }
  return (total: total, inMonth: inMonth);
}
