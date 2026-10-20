import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/diet_repository.dart';
import 'package:task_manager/domain/diet/diet.dart';

void main() {
  final taco = parseTaco(File('assets/taco.json').readAsStringSync());

  test('the TACO table: 597 foods per 100 g, household measures, blanks kept unknown', () {
    expect(taco, hasLength(597));
    final rice = taco.firstWhere((f) => f.id == 'taco:1');
    expect(rice.name, 'Arroz, integral, cozido');
    expect((rice.per100g.kcal, rice.per100g.protein, rice.per100g.carbs, rice.per100g.fat), (123.5, 2.59, 25.81, 1.0));
    expect(rice.defaultMeasure?.name, 'colher de sopa cheia');
    expect(rice.defaultMeasure?.grams, 25);
    expect(taco.where((f) => f.per100g.kcal == null), hasLength(6), reason: 'TACO leaves some foods without energy');
  });

  test('search ignores accents and case, every word must match, the best match first', () {
    final sugar = searchFoods(taco, 'acucar');
    expect(sugar, isNotEmpty);
    expect(sugar.every((f) => foldForSearch(f.name).contains('acucar')), isTrue);
    expect(sugar.first.name.toLowerCase(), startsWith('açúcar'));
    // Names starting with "Arroz" before those that only mention rice further on.
    final rice = searchFoods(taco, 'arroz');
    final firstOther = rice.indexWhere((f) => !f.name.startsWith('Arroz'));
    expect(rice.take(firstOther < 0 ? rice.length : firstOther).every((f) => f.name.startsWith('Arroz')), isTrue);
    expect(rice.skip(firstOther < 0 ? rice.length : firstOther).every((f) => !f.name.startsWith('Arroz')), isTrue);
    expect(searchFoods(taco, 'arroz integral').every((f) => foldForSearch(f.name).contains('integral')), isTrue);
    expect(searchFoods(taco, '   '), isEmpty);
    // The user's own food comes before TACO's on an equal match.
    const mine = Food(id: 'x', name: 'Arroz, da vó', per100g: Nutrients(kcal: 150), custom: true);
    expect(searchFoods([...taco, mine], 'arroz').first.id, 'x');
  });

  test('portions and sums: per 100 g scaled to the grams; an unknown value stays out of the sum', () {
    const per100 = Nutrients(kcal: 200, protein: 10, carbs: 30, fat: 5);
    final half = per100.forGrams(50);
    expect((half.kcal, half.protein, half.fiber), (100.0, 5.0, null));
    final total = half + const Nutrients(kcal: 60, fiber: 2);
    expect((total.kcal, total.protein, total.fiber), (160.0, 5.0, 2.0));
    expect(portionText(2, 'colher de sopa cheia', 50), '2 colher de sopa cheia (50 g)');
    expect(portionText(150, null, 150), '150 g');
    expect(portionText(1.5, 'xícara', 240), '1,5 xícara (240 g)');
  });

  test('the suggested meal is the one whose time is the closest before; before the first, the first', () {
    const meals = [
      (id: 'breakfast', time: 420),
      (id: 'lunch', time: 750),
      (id: 'snack', time: null),
      (id: 'preWorkout', time: 1020),
      (id: 'dinner', time: 1170),
    ];
    expect(suggestMealAt(meals, DateTime(2026, 10, 9, 7, 30)), 'breakfast');
    expect(suggestMealAt(meals, DateTime(2026, 10, 9, 12, 30)), 'lunch');
    expect(suggestMealAt(meals, DateTime(2026, 10, 9, 17, 10)), 'preWorkout');
    expect(suggestMealAt(meals, DateTime(2026, 10, 9, 23)), 'dinner');
    expect(suggestMealAt(meals, DateTime(2026, 10, 9, 5)), 'breakfast');
    expect(suggestMealAt(const [(id: 'x', time: null)], DateTime(2026, 10, 9, 5)), isNull);
  });

  test('the diary: entries keep a copy of the food; editing, deleting with undo, own foods', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DietRepository(db, clock: FixedClock(DateTime(2026, 10, 9, 12)));
    final rice = taco.firstWhere((f) => f.id == 'taco:1');
    final spoon = rice.defaultMeasure!;
    final a = await repo.addEntry(day: DateTime(2026, 10, 9), meal: 'lunch', food: rice, quantity: 4, measure: spoon);
    final own = await repo.createFood(
      name: 'Whey',
      per100g: const Nutrients(kcal: 400, protein: 80, carbs: 8, fat: 6),
      measures: [(id: null, name: 'scoop', grams: 30)],
    );
    var s = await repo.load();
    final whey = s.customFoods.single;
    expect((whey.name, whey.defaultMeasure?.name, whey.defaultMeasure?.grams), ('Whey', 'scoop', 30.0));
    await repo.addEntry(day: DateTime(2026, 10, 9), meal: 'afternoonSnack', food: whey, quantity: 1, measure: whey.defaultMeasure);
    s = await repo.load();
    final day = s.entriesOn(DateTime(2026, 10, 9));
    expect(day.map((e) => e.grams), [100.0, 30.0]);
    final total = day.map(entryNutrients).fold(Nutrients.zero, (sum, n) => sum + n);
    expect(total.kcal, closeTo(123.5 + 120, 0.001));

    // Changing the food keeps what was eaten; the entry changes only when edited.
    await repo.updateFood(own, name: 'Whey 2', per100g: const Nutrients(kcal: 380));
    expect((await repo.load()).entries.last.kcal, 400);
    await repo.updateEntry(a, day: DateTime(2026, 10, 10), meal: 'dinner', quantity: 150);
    s = await repo.load();
    final moved = s.entries.firstWhere((e) => e.id == a);
    expect((dietDay(moved.day), moved.meal, moved.grams, moved.measureName), (DateTime(2026, 10, 10), 'dinner', 150.0, null));

    await repo.deleteEntry(a);
    expect((await repo.load()).entries, hasLength(1));
    await repo.deleteEntry(a, restore: true);
    expect((await repo.load()).entries, hasLength(2));
    await repo.deleteFood(own);
    s = await repo.load();
    expect(s.foods, isEmpty);
    expect(s.entries, hasLength(2), reason: 'the diary keeps what was eaten');
  });

  test('household measures: many per own food, the one of before kept until saved, the user\'s on TACO foods', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DietRepository(db, clock: FixedClock(DateTime(2026, 10, 9, 12)));
    // A food of schema v19, with its single measure in the row.
    await db
        .into(db.dietFoods)
        .insert(
          DietFoodsCompanion.insert(
            id: 'old',
            createdAt: DateTime.utc(2026, 9),
            updatedAt: DateTime.utc(2026, 9),
            name: 'Granola',
            kcal: const Value(450),
            measureName: const Value('xícara'),
            measureGrams: const Value(80),
          ),
        );
    var s = await repo.load();
    expect([for (final m in s.customFoods.single.measures) (m.name, m.grams)], [('xícara', 80.0)], reason: 'read as before');
    // Saved with one more: both go to the table, the row's columns are emptied.
    await repo.updateFood(
      'old',
      name: 'Granola',
      per100g: const Nutrients(kcal: 450),
      measures: [(id: null, name: 'xícara', grams: 80), (id: null, name: 'colher', grams: 10)],
    );
    s = await repo.load();
    expect([for (final m in s.customFoods.single.measures) m.name], ['xícara', 'colher']);
    expect(s.foods.single.measureName, isNull);
    final spoon = s.customFoods.single.measures.last;
    // The bin on one of them.
    await repo.updateFood('old', name: 'Granola', per100g: const Nutrients(kcal: 450), measures: [(id: spoon.id, name: 'colher cheia', grams: 12)]);
    s = await repo.load();
    expect([for (final m in s.customFoods.single.measures) (m.name, m.grams)], [('colher cheia', 12.0)]);

    // TACO's food: the table's measures, then the user's.
    final rice = taco.firstWhere((f) => f.id == 'taco:1');
    final ladle = await repo.addMeasure(foodId: 'taco:1', name: 'concha', grams: 90);
    s = await repo.load();
    final full = s.allFoods(taco).firstWhere((f) => f.id == 'taco:1');
    expect(full.measures.length, rice.measures.length + 1);
    expect((full.measures.last.name, full.measures.last.id), ('concha', ladle));
    expect(full.defaultMeasure?.name, rice.defaultMeasure?.name, reason: 'TACO\'s default stays');
    await repo.deleteMeasure(ladle);
    expect((await repo.load()).userMeasuresOf('taco:1'), isEmpty);
  });

  test('meals: the six of before, one placed by its time, moved, archived when used, deleted when not', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DietRepository(db, clock: FixedClock(DateTime(2026, 10, 9, 12)));
    List<String> order(DietSnapshot s) => [for (final m in s.activeMeals) m.id];
    final pre = await repo.createMeal(name: 'Pré-treino', time: 17 * 60);
    var s = await repo.load();
    expect(order(s), ['breakfast', 'morningSnack', 'lunch', 'afternoonSnack', pre, 'dinner', 'supper']);
    await repo.moveMeal(pre, up: true);
    s = await repo.load();
    expect(order(s).indexOf(pre), 3);
    await repo.moveMeal('breakfast', up: true);
    expect(order(await repo.load()).first, 'breakfast', reason: 'the first stays first');
    await repo.updateMeal('lunch', name: 'Almoço de domingo', time: 13 * 60);
    s = await repo.load();
    expect((s.meal('lunch')?.name, s.meal('lunch')?.time), ('Almoço de domingo', 780));

    final rice = taco.firstWhere((f) => f.id == 'taco:1');
    await repo.addEntry(day: DateTime(2026, 10, 9), meal: pre, food: rice, quantity: 100);
    await repo.archiveMeal(pre);
    s = await repo.load();
    expect(order(s), isNot(contains(pre)));
    expect(s.meal(pre)?.archivedAt, isNotNull, reason: 'its entries still name it');
    expect(s.entries.single.meal, pre);
    await repo.archiveMeal(pre, restore: true);
    await repo.deleteMeal('supper');
    s = await repo.load();
    expect(order(s), isNot(contains('supper')));
    expect(s.meal('supper'), isNull);
    expect(order(s), contains(pre));
  });

  test('the plan: items by weekday, "Importar plano do dia" links the entries and never duplicates', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DietRepository(db, clock: FixedClock(DateTime(2026, 10, 9, 12)));
    final rice = taco.firstWhere((f) => f.id == 'taco:1');
    final beans = taco.firstWhere((f) => f.name == 'Feijão, carioca, cozido');
    final everyDay = await repo.addPlanItem(meal: 'lunch', food: rice, quantity: 4, measure: rice.defaultMeasure);
    final weekend = await repo.addPlanItem(meal: 'lunch', food: beans, quantity: 120, weekdays: '6,7');
    final breakfast = await repo.addPlanItem(meal: 'breakfast', food: beans, quantity: 50, weekdays: '5');
    // Friday 9/10: the every-day item and Friday's, breakfast first.
    expect(await repo.importPlan(DateTime(2026, 10, 9)), 2);
    var s = await repo.load();
    var day = s.entriesOn(DateTime(2026, 10, 9));
    expect([for (final e in day) e.planItemId], [breakfast, everyDay]);
    expect((day.last.grams, day.last.measureName, day.last.kcal), (100.0, rice.defaultMeasure!.name, rice.per100g.kcal));
    expect(await repo.importPlan(DateTime(2026, 10, 9)), 0, reason: 'imported already');
    expect((await repo.load()).entriesOn(DateTime(2026, 10, 9)), hasLength(2));
    // An entry deleted comes back on importing again; edited ones stay linked.
    await repo.deleteEntry(day.first.id);
    await repo.updateEntry(day.last.id, day: DateTime(2026, 10, 9), meal: 'lunch', quantity: 6, measure: rice.defaultMeasure);
    expect(await repo.importPlan(DateTime(2026, 10, 9)), 1);
    s = await repo.load();
    day = s.entriesOn(DateTime(2026, 10, 9));
    expect(day.where((e) => e.planItemId == everyDay).single.grams, 150);
    // Saturday: the weekend's.
    expect(await repo.importPlan(DateTime(2026, 10, 10)), 2);
    expect((await repo.load()).entriesOn(DateTime(2026, 10, 10)).map((e) => e.planItemId), containsAll([everyDay, weekend]));
    // Editing and deleting a plan item.
    await repo.updatePlanItem(weekend, meal: 'dinner', quantity: 100, weekdays: '', food: rice);
    s = await repo.load();
    final edited = s.plan.firstWhere((i) => i.id == weekend);
    expect((edited.meal, edited.weekdays, edited.foodId, edited.grams), ('dinner', '', 'taco:1', 100.0));
    await repo.deletePlanItem(weekend);
    s = await repo.load();
    expect(s.plan, hasLength(2));
    expect(s.planItems, hasLength(3), reason: 'deleted ones stay for the history');
  });
}
