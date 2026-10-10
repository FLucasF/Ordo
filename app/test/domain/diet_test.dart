import 'dart:io';

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
    expect(Meal.at(DateTime(2026, 10, 9, 7, 30)), Meal.breakfast);
    expect(Meal.at(DateTime(2026, 10, 9, 12, 30)), Meal.lunch);
    expect(Meal.at(DateTime(2026, 10, 9, 22)), Meal.supper);
  });

  test('the diary: entries keep a copy of the food; editing, deleting with undo, own foods', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DietRepository(db, clock: FixedClock(DateTime(2026, 10, 9, 12)));
    final rice = taco.firstWhere((f) => f.id == 'taco:1');
    final spoon = rice.defaultMeasure!;
    final a = await repo.addEntry(day: DateTime(2026, 10, 9), meal: Meal.lunch, food: rice, quantity: 4, measure: spoon);
    final own = await repo.createFood(
      name: 'Whey',
      per100g: const Nutrients(kcal: 400, protein: 80, carbs: 8, fat: 6),
      measureName: 'scoop',
      measureGrams: 30,
    );
    var s = await repo.load();
    final whey = s.customFoods.single;
    expect((whey.name, whey.defaultMeasure?.name, whey.defaultMeasure?.grams), ('Whey', 'scoop', 30.0));
    await repo.addEntry(day: DateTime(2026, 10, 9), meal: Meal.afternoonSnack, food: whey, quantity: 1, measure: whey.defaultMeasure);
    s = await repo.load();
    final day = s.entriesOn(DateTime(2026, 10, 9));
    expect(day.map((e) => e.grams), [100.0, 30.0]);
    final total = day.map(entryNutrients).fold(Nutrients.zero, (sum, n) => sum + n);
    expect(total.kcal, closeTo(123.5 + 120, 0.001));

    // Changing the food keeps what was eaten; the entry changes only when edited.
    await repo.updateFood(own, name: 'Whey 2', per100g: const Nutrients(kcal: 380));
    expect((await repo.load()).entries.last.kcal, 400);
    await repo.updateEntry(a, day: DateTime(2026, 10, 10), meal: Meal.dinner, quantity: 150);
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
}
