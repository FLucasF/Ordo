import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../domain/diet/diet.dart';
import 'db/database.dart';

/// The user's foods and what was eaten (not deleted ones).
class DietSnapshot {
  const DietSnapshot({required this.foods, required this.entries});

  static const empty = DietSnapshot(foods: [], entries: []);

  final List<DietFood> foods;

  /// All days, in each day's meal order (as added).
  final List<DietEntry> entries;

  /// The user's foods as [Food]s (custom ones, searched along with TACO).
  List<Food> get customFoods => [for (final f in foods) dietFoodOf(f)];

  List<DietEntry> entriesOn(DateTime day) => [
    for (final e in entries)
      if (dietDay(e.day) == day) e,
  ];
}

/// A stored day (UTC midnight) as the local day.
DateTime dietDay(DateTime stored) => DateTime(stored.year, stored.month, stored.day);

DateTime _storedDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

Food dietFoodOf(DietFood f) => Food(
  id: f.id,
  name: f.name,
  per100g: Nutrients(kcal: f.kcal, protein: f.protein, carbs: f.carbs, fat: f.fat, fiber: f.fiber),
  measures: [if (f.measureName case final name? when (f.measureGrams ?? 0) > 0) FoodMeasure(name: name, grams: f.measureGrams!, isDefault: true)],
  custom: true,
);

/// What an entry adds up to (its values per 100 g for its grams).
Nutrients entryNutrients(DietEntry e) => Nutrients(kcal: e.kcal, protein: e.protein, carbs: e.carbs, fat: e.fat, fiber: e.fiber).forGrams(e.grams);

/// Every write of Dieta. Kept apart from [Repository], as Finanças: diet changes don't reload the tasks.
class DietRepository {
  DietRepository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  /// A fresh snapshot on every change. The query text must differ from the others' (drift shares
  /// one stream between identical queries, whatever tables they read).
  Stream<DietSnapshot> watch() => _db.customSelect('SELECT 1 AS diet', readsFrom: {_db.dietFoods, _db.dietEntries}).watch().asyncMap((_) => load());

  Future<DietSnapshot> load() => _db.transaction(() async {
    final foods =
        await (_db.select(_db.dietFoods)
              ..where((f) => f.deletedAt.isNull())
              ..orderBy([(f) => OrderingTerm(expression: f.name)]))
            .get();
    final entries =
        await (_db.select(_db.dietEntries)
              ..where((e) => e.deletedAt.isNull())
              ..orderBy([(e) => OrderingTerm(expression: e.day), (e) => OrderingTerm(expression: e.sortOrder)]))
            .get();
    return DietSnapshot(foods: foods, entries: entries);
  });

  // ------------------------------------------------------------------ foods

  /// "Cadastrar alimento": values per 100 g; returns its id.
  Future<String> createFood({required String name, required Nutrients per100g, String? measureName, double? measureGrams}) async {
    final id = newId();
    await _db
        .into(_db.dietFoods)
        .insert(
          DietFoodsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: name.trim(),
            kcal: Value(per100g.kcal),
            protein: Value(per100g.protein),
            carbs: Value(per100g.carbs),
            fat: Value(per100g.fat),
            fiber: Value(per100g.fiber),
            measureName: Value(_measure(measureName, measureGrams)),
            measureGrams: Value(_measure(measureName, measureGrams) == null ? null : measureGrams),
          ),
        );
    return id;
  }

  /// The diary keeps its copies: changing a food doesn't change what was already eaten.
  Future<void> updateFood(String id, {required String name, required Nutrients per100g, String? measureName, double? measureGrams}) =>
      (_db.update(_db.dietFoods)..where((f) => f.id.equals(id))).write(
        DietFoodsCompanion(
          name: Value(name.trim()),
          kcal: Value(per100g.kcal),
          protein: Value(per100g.protein),
          carbs: Value(per100g.carbs),
          fat: Value(per100g.fat),
          fiber: Value(per100g.fiber),
          measureName: Value(_measure(measureName, measureGrams)),
          measureGrams: Value(_measure(measureName, measureGrams) == null ? null : measureGrams),
          updatedAt: Value(_now),
        ),
      );

  String? _measure(String? name, double? grams) => name == null || name.trim().isEmpty || (grams ?? 0) <= 0 ? null : name.trim();

  /// Deletes a food (the diary keeps what was eaten); [restore] undoes it.
  Future<void> deleteFood(String id, {bool restore = false}) => (_db.update(
    _db.dietFoods,
  )..where((f) => f.id.equals(id))).write(DietFoodsCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ the diary

  /// [quantity] of [measure] (null = grams) of [food], eaten in [meal] on [day]; returns its id.
  Future<String> addEntry({required DateTime day, required Meal meal, required Food food, required double quantity, FoodMeasure? measure}) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.dietEntries,
    )..addColumns([_db.dietEntries.sortOrder.max()])).map((r) => r.read(_db.dietEntries.sortOrder.max())).getSingle();
    final n = food.per100g;
    await _db
        .into(_db.dietEntries)
        .insert(
          DietEntriesCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            day: _storedDay(day),
            meal: meal.code,
            foodId: food.id,
            name: food.name,
            quantity: quantity,
            measureName: Value(measure?.name),
            grams: measure == null ? quantity : quantity * measure.grams,
            kcal: Value(n.kcal),
            protein: Value(n.protein),
            carbs: Value(n.carbs),
            fat: Value(n.fat),
            fiber: Value(n.fiber),
            sortOrder: (last ?? 0) + 1,
          ),
        );
    return id;
  }

  /// Changes an entry: its meal, day, amount, or the food itself (when [food] is given, its values
  /// are copied again).
  Future<void> updateEntry(String id, {required DateTime day, required Meal meal, required double quantity, FoodMeasure? measure, Food? food}) =>
      (_db.update(_db.dietEntries)..where((e) => e.id.equals(id))).write(
        DietEntriesCompanion(
          day: Value(_storedDay(day)),
          meal: Value(meal.code),
          quantity: Value(quantity),
          measureName: Value(measure?.name),
          grams: Value(measure == null ? quantity : quantity * measure.grams),
          foodId: food == null ? const Value.absent() : Value(food.id),
          name: food == null ? const Value.absent() : Value(food.name),
          kcal: food == null ? const Value.absent() : Value(food.per100g.kcal),
          protein: food == null ? const Value.absent() : Value(food.per100g.protein),
          carbs: food == null ? const Value.absent() : Value(food.per100g.carbs),
          fat: food == null ? const Value.absent() : Value(food.per100g.fat),
          fiber: food == null ? const Value.absent() : Value(food.per100g.fiber),
          updatedAt: Value(_now),
        ),
      );

  /// Deletes an entry; [restore] undoes it (the toast's "Desfazer").
  Future<void> deleteEntry(String id, {bool restore = false}) => (_db.update(
    _db.dietEntries,
  )..where((e) => e.id.equals(id))).write(DietEntriesCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));
}
