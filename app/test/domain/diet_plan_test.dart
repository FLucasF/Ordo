import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/domain/diet/plan.dart';
import 'package:task_manager/domain/diet/targets.dart';

/// A plan item of 100 g (200 kcal per 100 g), made on 1/10/2026.
DietPlanItem item(
  String id, {
  String meal = 'lunch',
  String foodId = 'taco:1',
  double grams = 100,
  String weekdays = '',
  DateTime? created,
  DateTime? deleted,
}) => DietPlanItem(
  id: id,
  createdAt: created ?? DateTime(2026, 10),
  updatedAt: created ?? DateTime(2026, 10),
  deletedAt: deleted,
  weekdays: weekdays,
  meal: meal,
  foodId: foodId,
  name: id,
  quantity: grams,
  grams: grams,
  kcal: 200,
  sortOrder: 0,
);

/// An entry on 9/10/2026.
DietEntry entry(String id, {String meal = 'lunch', String foodId = 'taco:1', double grams = 100, String? planItemId, double kcal = 200}) => DietEntry(
  id: id,
  createdAt: DateTime(2026, 10, 9),
  updatedAt: DateTime(2026, 10, 9),
  day: DateTime.utc(2026, 10, 9),
  meal: meal,
  foodId: foodId,
  name: id,
  quantity: grams,
  grams: grams,
  kcal: kcal,
  sortOrder: 0,
  planItemId: planItemId,
);

void main() {
  final friday = DateTime(2026, 10, 9);
  final today = DateTime(2026, 10, 20);

  test('weekdays: CSV of DateTime.weekday, empty or all seven = every day', () {
    expect(parseWeekdays('1, 3,5,9,x'), {1, 3, 5});
    expect(parseWeekdays(''), isEmpty);
    expect(weekdaysCsv([5, 1, 3, 3]), '1,3,5');
    expect(weekdaysCsv([1, 2, 3, 4, 5, 6, 7]), '');
    expect(planItemOnWeekday(item('a', weekdays: '5'), friday), isTrue);
    expect(planItemOnWeekday(item('a', weekdays: '6,7'), friday), isFalse);
    expect(planItemOnWeekday(item('a'), friday), isTrue);
  });

  test('the plan of a day is the one of then: items made later or deleted before it are out', () {
    final items = [
      item('old'),
      item('later', created: DateTime(2026, 10, 15)),
      item('deletedBefore', deleted: DateTime(2026, 10, 5)),
      item('deletedAfter', deleted: DateTime(2026, 10, 12)),
      item('deletedThatDay', deleted: DateTime(2026, 10, 9, 18)),
      item('weekend', weekdays: '6,7'),
    ];
    expect([for (final i in planFor(items, friday)) i.id], ['old', 'deletedAfter']);
  });

  test('outcomes: as planned within ±10%, changed amount or food = 50%, skipped = 0%', () {
    final plan = [item('a'), item('b'), item('c'), item('d', foodId: 'taco:2', meal: 'dinner'), item('e')];
    final outcomes = planOutcomes(plan, [
      entry('x', planItemId: 'a', grams: 109),
      entry('y', planItemId: 'b', grams: 150),
      entry('z', planItemId: 'c', foodId: 'taco:9'),
      // Not imported, but the same food in the same meal.
      entry('w', meal: 'dinner', foodId: 'taco:2', grams: 95),
    ]);
    expect(outcomes, {
      'a': PlanOutcome.asPlanned,
      'b': PlanOutcome.changed,
      'c': PlanOutcome.changed,
      'd': PlanOutcome.asPlanned,
      'e': PlanOutcome.skipped,
    });
    // An entry counts for one item only.
    expect(planOutcomes([item('a'), item('b')], [entry('x')]).values, [PlanOutcome.asPlanned, PlanOutcome.skipped]);
  });

  test('calories: 100% within ±10% of the target, down to 0% at ±50%', () {
    expect(calorieScore(2100, 2000), 1);
    expect(calorieScore(1800, 2000), 1);
    expect(calorieScore(2600, 2000), closeTo(0.5, 1e-9));
    expect(calorieScore(1000, 2000), 0);
    expect(calorieScore(5000, 2000), 0);
  });

  test('a day: 70% the plan and 30% the calories; one of them alone when the other is missing', () {
    final plan = [item('a'), item('b')];
    // a as planned (100%), b skipped (0%): plan 50%; 200 kcal of a 200 target: 100%.
    final both = dayAdherence(
      day: friday,
      today: today,
      planItems: plan,
      entries: [entry('x', planItemId: 'a')],
      kcalTarget: 200,
    )!;
    expect((both.plan, both.calories), (0.5, 1.0));
    expect(both.score, closeTo(0.65, 1e-9));
    final planOnly = dayAdherence(
      day: friday,
      today: today,
      planItems: plan,
      entries: [entry('x', planItemId: 'a')],
    )!;
    expect((planOnly.calories, planOnly.score), (null, 0.5));
    final targetOnly = dayAdherence(day: friday, today: today, planItems: const [], entries: [entry('x', kcal: 100)], kcalTarget: 400)!;
    expect((targetOnly.plan, targetOnly.score), (null, 0.0));
  });

  test('days that don\'t count: still to come, today before eating, nothing eaten and no plan, no plan and no target', () {
    final plan = [item('a')];
    expect(dayAdherence(day: DateTime(2026, 10, 21), today: today, planItems: plan, entries: [entry('x')]), isNull);
    expect(dayAdherence(day: today, today: today, planItems: plan, entries: const []), isNull);
    expect(dayAdherence(day: friday, today: today, planItems: const [], entries: const [], kcalTarget: 2000), isNull);
    expect(dayAdherence(day: friday, today: today, planItems: const [], entries: [entry('x')]), isNull);
    // A past day of the plan with nothing eaten: all skipped.
    expect(dayAdherence(day: friday, today: today, planItems: plan, entries: const [], kcalTarget: 2000)?.score, 0);
    // Before the plan existed.
    expect(dayAdherence(day: DateTime(2026, 9, 20), today: today, planItems: plan, entries: const []), isNull);
  });

  test('means leave out the days that don\'t count', () {
    expect(meanAdherence([const DayAdherence(plan: 1), null, const DayAdherence(plan: 0.5)]), 0.75);
    expect(meanAdherence([null, null]), isNull);
  });

  test('targets: kept as JSON, the calories from the macros when asked, the bar\'s level', () {
    const targets = DietTargets(kcal: 2000, protein: 150, carbs: 200, fat: 60);
    expect(targets.energy, 2000);
    expect(const DietTargets(kcal: 2000, protein: 150, carbs: 200, fat: 60, energyFromMacros: true).energy, 150 * 4 + 200 * 4 + 60 * 9);
    final back = DietTargets.fromJson(targets.toJson());
    expect((back.kcal, back.protein, back.carbs, back.fat, back.energyFromMacros), (2000.0, 150.0, 200.0, 60.0, false));
    expect(DietTargets.fromJson('nonsense').isEmpty, isTrue);
    expect(DietTargets.fromJson({'kcal': -5, 'protein': 'x'}).isEmpty, isTrue);
    expect(targetLevel(1500, 2000), TargetLevel.below);
    expect(targetLevel(1800, 2000), TargetLevel.near);
    expect(targetLevel(2200, 2000), TargetLevel.near);
    expect(targetLevel(2201, 2000), TargetLevel.over);
  });
}
