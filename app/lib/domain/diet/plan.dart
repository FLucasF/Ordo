import '../../data/db/database.dart';

// The meal plan ("Plano") and how closely a day followed it (the adherence).

/// "1,3,5" → {1, 3, 5}: DateTime.weekday numbers; empty is every day.
Set<int> parseWeekdays(String csv) => {
  for (final part in csv.split(','))
    if (int.tryParse(part.trim()) case final d? when d >= DateTime.monday && d <= DateTime.sunday) d,
};

/// The CSV of [days] in order; all seven, or none, is '' (every day).
String weekdaysCsv(Iterable<int> days) {
  final set = {...days.where((d) => d >= DateTime.monday && d <= DateTime.sunday)};
  if (set.length == 7) return '';
  return (set.toList()..sort()).join(',');
}

/// Whether [item] is in the plan on [day]'s weekday.
bool planItemOnWeekday(DietPlanItem item, DateTime day) {
  final days = parseWeekdays(item.weekdays);
  return days.isEmpty || days.contains(day.weekday);
}

/// The plan of [day] (a local day): the items of its weekday that existed then, created by the
/// end of it and not deleted before it ended, so deleting an item today doesn't rewrite the past.
List<DietPlanItem> planFor(Iterable<DietPlanItem> items, DateTime day) {
  final next = DateTime(day.year, day.month, day.day + 1);
  return [
    for (final i in items)
      if (planItemOnWeekday(i, day) && i.createdAt.toLocal().isBefore(next) && (i.deletedAt == null || !i.deletedAt!.toLocal().isBefore(next))) i,
  ];
}

/// How a plan item went on a day.
enum PlanOutcome {
  /// The planned food, its grams within ±10% of the plan's: 100%.
  asPlanned(1),

  /// Eaten in place of it with another amount, or another food: 50%.
  changed(0.5),

  /// Not eaten: 0%.
  skipped(0);

  const PlanOutcome(this.score);
  final double score;
}

/// The outcome of each item of [plan] (by its id) given the day's [entries]. An item's entry is the
/// one imported from it (its planItemId); failing that, an entry of the same food in the same meal
/// that no other item took, so eating the plan without importing it counts too.
Map<String, PlanOutcome> planOutcomes(List<DietPlanItem> plan, List<DietEntry> entries) {
  final taken = <String>{};
  final matched = <String, DietEntry>{};
  for (final item in plan) {
    final e = entries.where((e) => e.planItemId == item.id && !taken.contains(e.id)).firstOrNull;
    if (e != null) {
      matched[item.id] = e;
      taken.add(e.id);
    }
  }
  final planIds = {for (final i in plan) i.id};
  for (final item in plan) {
    if (matched.containsKey(item.id)) continue;
    final e = entries
        .where(
          (e) => !taken.contains(e.id) && (e.planItemId == null || !planIds.contains(e.planItemId)) && e.foodId == item.foodId && e.meal == item.meal,
        )
        .firstOrNull;
    if (e != null) {
      matched[item.id] = e;
      taken.add(e.id);
    }
  }
  return {
    for (final item in plan)
      item.id: switch (matched[item.id]) {
        null => PlanOutcome.skipped,
        final e when e.foodId == item.foodId && (e.grams - item.grams).abs() <= item.grams * 0.1 => PlanOutcome.asPlanned,
        _ => PlanOutcome.changed,
      },
  };
}

/// The calories eaten against the target: 100% within ±10%, then less, linearly, down to 0% at
/// ±50% (or beyond).
double calorieScore(double eaten, double target) {
  if (target <= 0) return 0;
  final off = (eaten - target).abs() / target;
  if (off <= 0.1) return 1;
  return (1 - (off - 0.1) / 0.4).clamp(0, 1).toDouble();
}

/// A day's adherence, from 0 to 1: its [plan] part (the mean of the items' outcomes) and its [calories]
/// part ([calorieScore]), null where there is no plan or no calorie target.
class DayAdherence {
  const DayAdherence({this.plan, this.calories});

  final double? plan;
  final double? calories;

  /// 70% the plan and 30% the calories when there are both, otherwise the one there is: the plan is
  /// the prescription; the calories still count when a food was swapped for an equivalent one.
  double get score => switch ((plan, calories)) {
    (final p?, final c?) => 0.7 * p + 0.3 * c,
    (final p?, null) => p,
    (null, final c?) => c,
    _ => 0,
  };
}

/// The adherence of [day] (a local day), or null when it doesn't count: a day still to come; today
/// before anything is eaten; a past day with nothing eaten and no plan for it (not kept, not
/// missed); a day without a plan and without a calorie target. A past day with a plan and nothing
/// eaten counts as every item skipped. [planItems] are all items, deleted ones too (see [planFor]);
/// [entries] are the day's.
DayAdherence? dayAdherence({
  required DateTime day,
  required DateTime today,
  required Iterable<DietPlanItem> planItems,
  required List<DietEntry> entries,
  double? kcalTarget,
}) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d.isAfter(t)) return null;
  final plan = planFor(planItems, d);
  if (entries.isEmpty && (d == t || plan.isEmpty)) return null;
  final target = kcalTarget != null && kcalTarget > 0 ? kcalTarget : null;
  if (plan.isEmpty && target == null) return null;
  final outcomes = planOutcomes(plan, entries).values;
  final eaten = entries.fold(0.0, (sum, e) => sum + (e.kcal ?? 0) * e.grams / 100);
  return DayAdherence(
    plan: plan.isEmpty ? null : outcomes.fold(0.0, (sum, o) => sum + o.score) / outcomes.length,
    calories: target == null ? null : calorieScore(eaten, target),
  );
}

/// The mean score of the days that count (null ones left out); null when none does.
double? meanAdherence(Iterable<DayAdherence?> days) {
  final scores = [
    for (final d in days)
      if (d != null) d.score,
  ];
  return scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
}
