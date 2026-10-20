import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../domain/diet/diet.dart';
import '../domain/diet/plan.dart';
import 'db/database.dart';

/// The user's foods, meals, measures, plan and what was eaten (not deleted ones, but for the plan).
class DietSnapshot {
  const DietSnapshot({required this.foods, required this.entries, this.meals = const [], this.measures = const [], this.planItems = const []});

  static const empty = DietSnapshot(foods: [], entries: []);

  final List<DietFood> foods;

  /// All days, in each day's meal order (as added).
  final List<DietEntry> entries;

  /// The meals in their order, archived ones too (their entries keep showing).
  final List<DietMeal> meals;

  /// The household measures the user added, of own foods and of TACO's, in their order.
  final List<DietFoodMeasure> measures;

  /// Every plan item, deleted ones too: the adherence of a past day uses the plan of then.
  final List<DietPlanItem> planItems;

  /// The meals in use (not archived).
  List<DietMeal> get activeMeals => [
    for (final m in meals)
      if (m.archivedAt == null) m,
  ];

  /// The plan as it is now.
  List<DietPlanItem> get plan => [
    for (final i in planItems)
      if (i.deletedAt == null) i,
  ];

  DietMeal? meal(String id) => meals.where((m) => m.id == id).firstOrNull;

  /// The measures the user added to [foodId].
  List<FoodMeasure> userMeasuresOf(String foodId) => [
    for (final m in measures)
      if (m.foodId == foodId) FoodMeasure(name: m.name, grams: m.grams, id: m.id),
  ];

  /// The user's foods as [Food]s (custom ones, searched along with TACO).
  List<Food> get customFoods => [for (final f in foods) dietFoodOf(f, userMeasuresOf(f.id))];

  /// A TACO food with the measures the user added to it.
  Food withUserMeasures(Food food) => food.withExtraMeasures(userMeasuresOf(food.id));

  /// The user's foods and TACO's, each with all its measures.
  List<Food> allFoods(List<Food> taco) {
    final extra = {for (final m in measures) m.foodId};
    return [...customFoods, for (final f in taco) extra.contains(f.id) ? withUserMeasures(f) : f];
  }

  List<DietEntry> entriesOn(DateTime day) => [
    for (final e in entries)
      if (dietDay(e.day) == day) e,
  ];
}

/// A stored day (UTC midnight) as the local day.
DateTime dietDay(DateTime stored) => DateTime(stored.year, stored.month, stored.day);

DateTime _storedDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

/// An own food with its measures: the one of before schema v20 (its row's measureName, until the
/// food is saved again and it moves to DietFoodMeasures), then those of the table.
Food dietFoodOf(DietFood f, [List<FoodMeasure> measures = const []]) => Food(
  id: f.id,
  name: f.name,
  per100g: Nutrients(kcal: f.kcal, protein: f.protein, carbs: f.carbs, fat: f.fat, fiber: f.fiber),
  measures: [
    if (f.measureName case final name? when (f.measureGrams ?? 0) > 0) FoodMeasure(name: name, grams: f.measureGrams!),
    ...measures,
  ],
  custom: true,
);

/// What an entry adds up to (its values per 100 g for its grams).
Nutrients entryNutrients(DietEntry e) => Nutrients(kcal: e.kcal, protein: e.protein, carbs: e.carbs, fat: e.fat, fiber: e.fiber).forGrams(e.grams);

/// What a plan item adds up to.
Nutrients planItemNutrients(DietPlanItem i) =>
    Nutrients(kcal: i.kcal, protein: i.protein, carbs: i.carbs, fat: i.fat, fiber: i.fiber).forGrams(i.grams);

/// A measure being edited in the food form: [id] null for a new one.
typedef MeasureDraft = ({String? id, String name, double grams});

/// Every write of Dieta. Kept apart from [Repository], as Finanças: diet changes don't reload the tasks.
class DietRepository {
  DietRepository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  /// A fresh snapshot on every change. The query text must differ from the others' (drift shares
  /// one stream between identical queries, whatever tables they read).
  Stream<DietSnapshot> watch() => _db
      .customSelect('SELECT 1 AS diet', readsFrom: {_db.dietFoods, _db.dietEntries, _db.dietMeals, _db.dietFoodMeasures, _db.dietPlanItems})
      .watch()
      .asyncMap((_) => load());

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
    final meals =
        await (_db.select(_db.dietMeals)
              ..where((m) => m.deletedAt.isNull())
              ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
            .get();
    final measures =
        await (_db.select(_db.dietFoodMeasures)
              ..where((m) => m.deletedAt.isNull())
              ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
            .get();
    final plan = await (_db.select(_db.dietPlanItems)..orderBy([(i) => OrderingTerm(expression: i.sortOrder)])).get();
    return DietSnapshot(foods: foods, entries: entries, meals: meals, measures: measures, planItems: plan);
  });

  // ------------------------------------------------------------------ foods

  /// "Cadastrar alimento": values per 100 g, its household measures; returns its id.
  Future<String> createFood({required String name, required Nutrients per100g, List<MeasureDraft> measures = const []}) => _db.transaction(() async {
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
          ),
        );
    await _saveMeasures(id, measures);
    return id;
  });

  /// The diary keeps its copies: changing a food doesn't change what was already eaten. [measures]
  /// (null = as they are) become the food's measures, the old single one included.
  Future<void> updateFood(String id, {required String name, required Nutrients per100g, List<MeasureDraft>? measures}) => _db.transaction(() async {
    await (_db.update(_db.dietFoods)..where((f) => f.id.equals(id))).write(
      DietFoodsCompanion(
        name: Value(name.trim()),
        kcal: Value(per100g.kcal),
        protein: Value(per100g.protein),
        carbs: Value(per100g.carbs),
        fat: Value(per100g.fat),
        fiber: Value(per100g.fiber),
        // The measure of before goes to the table with the others.
        measureName: measures == null ? const Value.absent() : const Value(null),
        measureGrams: measures == null ? const Value.absent() : const Value(null),
        updatedAt: Value(_now),
      ),
    );
    if (measures != null) await _saveMeasures(id, measures);
  });

  /// Makes [drafts] the measures of [foodId], in their order: new ones added, the others changed,
  /// those left out deleted. Blank names and non-positive grams are dropped.
  Future<void> _saveMeasures(String foodId, List<MeasureDraft> drafts) async {
    final current = await (_db.select(_db.dietFoodMeasures)..where((m) => m.foodId.equals(foodId) & m.deletedAt.isNull())).get();
    final valid = [
      for (final d in drafts)
        if (d.name.trim().isNotEmpty && d.grams > 0) d,
    ];
    final kept = {for (final d in valid) ?d.id};
    for (final m in current) {
      if (!kept.contains(m.id)) {
        await (_db.update(
          _db.dietFoodMeasures,
        )..where((x) => x.id.equals(m.id))).write(DietFoodMeasuresCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
      }
    }
    for (final (i, d) in valid.indexed) {
      if (d.id case final id? when current.any((m) => m.id == id)) {
        await (_db.update(_db.dietFoodMeasures)..where((m) => m.id.equals(id))).write(
          DietFoodMeasuresCompanion(name: Value(d.name.trim()), grams: Value(d.grams), sortOrder: Value(i), updatedAt: Value(_now)),
        );
      } else {
        await _db
            .into(_db.dietFoodMeasures)
            .insert(
              DietFoodMeasuresCompanion.insert(
                id: newId(),
                createdAt: _now,
                updatedAt: _now,
                foodId: foodId,
                name: d.name.trim(),
                grams: d.grams,
                sortOrder: i,
              ),
            );
      }
    }
  }

  /// Deletes a food (the diary keeps what was eaten); [restore] undoes it.
  Future<void> deleteFood(String id, {bool restore = false}) => (_db.update(
    _db.dietFoods,
  )..where((f) => f.id.equals(id))).write(DietFoodsCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ household measures

  /// "+ Medida" on any food, a TACO one ("taco:1") included; returns its id.
  Future<String> addMeasure({required String foodId, required String name, required double grams}) async {
    final id = newId();
    final last =
        await (_db.selectOnly(_db.dietFoodMeasures)
              ..addColumns([_db.dietFoodMeasures.sortOrder.max()])
              ..where(_db.dietFoodMeasures.foodId.equals(foodId)))
            .map((r) => r.read(_db.dietFoodMeasures.sortOrder.max()))
            .getSingle();
    await _db
        .into(_db.dietFoodMeasures)
        .insert(
          DietFoodMeasuresCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            foodId: foodId,
            name: name.trim(),
            grams: grams,
            sortOrder: (last ?? -1) + 1,
          ),
        );
    return id;
  }

  /// Deletes a measure the user added; [restore] undoes it. Entries keep their grams.
  Future<void> deleteMeasure(String id, {bool restore = false}) => (_db.update(
    _db.dietFoodMeasures,
  )..where((m) => m.id.equals(id))).write(DietFoodMeasuresCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ meals

  Future<List<DietMeal>> _meals() =>
      (_db.select(_db.dietMeals)
            ..where((m) => m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
          .get();

  Future<void> _renumber(List<DietMeal> ordered) async {
    for (final (i, m) in ordered.indexed) {
      if (m.sortOrder != i) {
        await (_db.update(_db.dietMeals)..where((x) => x.id.equals(m.id))).write(DietMealsCompanion(sortOrder: Value(i), updatedAt: Value(_now)));
      }
    }
  }

  /// "+ Refeição": placed by its [time] (minutes after midnight) among the meals in use, or last
  /// without one; returns its id.
  Future<String> createMeal({required String name, int? time}) => _db.transaction(() async {
    final id = newId();
    final meals = await _meals();
    await _db
        .into(_db.dietMeals)
        .insert(
          DietMealsCompanion.insert(id: id, createdAt: _now, updatedAt: _now, name: Value(name.trim()), time: Value(time), sortOrder: meals.length),
        );
    final created = (await (_db.select(_db.dietMeals)..where((m) => m.id.equals(id))).getSingle());
    final at = time == null ? -1 : meals.indexWhere((m) => m.archivedAt == null && m.time != null && m.time! > time);
    await _renumber([...meals]..insert(at < 0 ? meals.length : at, created));
    return id;
  });

  /// A meal's name (empty on a built-in one = its label) and time (null = none).
  Future<void> updateMeal(String id, {required String name, int? time}) => (_db.update(
    _db.dietMeals,
  )..where((m) => m.id.equals(id))).write(DietMealsCompanion(name: Value(name.trim()), time: Value(time), updatedAt: Value(_now)));

  /// Moves a meal one place up or down among the meals in use.
  Future<void> moveMeal(String id, {required bool up}) => _db.transaction(() async {
    final meals = await _meals();
    final active = [
      for (final (i, m) in meals.indexed)
        if (m.archivedAt == null) i,
    ];
    final at = active.indexWhere((i) => meals[i].id == id);
    final to = up ? at - 1 : at + 1;
    if (at < 0 || to < 0 || to >= active.length) return;
    final a = active[at], b = active[to];
    final ordered = [...meals];
    ordered[a] = meals[b];
    ordered[b] = meals[a];
    await _renumber(ordered);
  });

  /// Archives a meal (out of the diary's list and the forms; its entries keep showing on their
  /// days); [restore] brings it back.
  Future<void> archiveMeal(String id, {bool restore = false}) => (_db.update(
    _db.dietMeals,
  )..where((m) => m.id.equals(id))).write(DietMealsCompanion(archivedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  /// Deletes a meal nothing uses; [restore] undoes it.
  Future<void> deleteMeal(String id, {bool restore = false}) => (_db.update(
    _db.dietMeals,
  )..where((m) => m.id.equals(id))).write(DietMealsCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ the diary

  Future<int> _nextEntryOrder() async =>
      ((await (_db.selectOnly(
            _db.dietEntries,
          )..addColumns([_db.dietEntries.sortOrder.max()])).map((r) => r.read(_db.dietEntries.sortOrder.max())).getSingle()) ??
          0) +
      1;

  /// [quantity] of [measure] (null = grams) of [food], eaten in [meal] (a DietMeals id) on [day];
  /// returns its id. [planItemId]: imported from the plan.
  Future<String> addEntry({
    required DateTime day,
    required String meal,
    required Food food,
    required double quantity,
    FoodMeasure? measure,
    String? planItemId,
  }) async {
    final id = newId();
    final n = food.per100g;
    await _db
        .into(_db.dietEntries)
        .insert(
          DietEntriesCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            day: _storedDay(day),
            meal: meal,
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
            sortOrder: await _nextEntryOrder(),
            planItemId: Value(planItemId),
          ),
        );
    return id;
  }

  /// Changes an entry: its meal, day, amount, or the food itself (when [food] is given, its values
  /// are copied again). An entry from the plan stays linked to it, so a swap counts as a change.
  Future<void> updateEntry(String id, {required DateTime day, required String meal, required double quantity, FoodMeasure? measure, Food? food}) =>
      (_db.update(_db.dietEntries)..where((e) => e.id.equals(id))).write(
        DietEntriesCompanion(
          day: Value(_storedDay(day)),
          meal: Value(meal),
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

  // ------------------------------------------------------------------ the plan

  /// A food of the plan in [meal], on [weekdays] (CSV of DateTime.weekday, '' = every day).
  Future<String> addPlanItem({required String meal, required Food food, required double quantity, FoodMeasure? measure, String weekdays = ''}) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.dietPlanItems,
    )..addColumns([_db.dietPlanItems.sortOrder.max()])).map((r) => r.read(_db.dietPlanItems.sortOrder.max())).getSingle();
    final n = food.per100g;
    await _db
        .into(_db.dietPlanItems)
        .insert(
          DietPlanItemsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            weekdays: Value(weekdays),
            meal: meal,
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

  /// Changes a plan item; [food] given = another food, its values copied.
  Future<void> updatePlanItem(
    String id, {
    required String meal,
    required double quantity,
    FoodMeasure? measure,
    required String weekdays,
    Food? food,
  }) => (_db.update(_db.dietPlanItems)..where((i) => i.id.equals(id))).write(
    DietPlanItemsCompanion(
      meal: Value(meal),
      weekdays: Value(weekdays),
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

  /// Deletes a plan item (the days it was eaten keep their entries); [restore] undoes it.
  Future<void> deletePlanItem(String id, {bool restore = false}) => (_db.update(
    _db.dietPlanItems,
  )..where((i) => i.id.equals(id))).write(DietPlanItemsCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  /// "Importar plano do dia": an entry for each item of [day]'s weekday, linked to it and with its
  /// values; items already imported that day (an entry of theirs is there) are skipped, so importing
  /// twice adds nothing. Returns how many were added.
  Future<int> importPlan(DateTime day) => _db.transaction(() async {
    final items = await (_db.select(_db.dietPlanItems)..where((i) => i.deletedAt.isNull())).get();
    final meals = await _meals();
    final order = {for (final (i, m) in meals.indexed) m.id: i};
    final done = {
      for (final e in await (_db.select(_db.dietEntries)..where((e) => e.deletedAt.isNull() & e.day.equals(_storedDay(day)))).get()) ?e.planItemId,
    };
    final todo =
        [
          for (final i in items)
            if (planItemOnWeekday(i, day) && !done.contains(i.id)) i,
        ]..sort((a, b) {
          // In the meals' order, then the plan's.
          final byMeal = (order[a.meal] ?? meals.length).compareTo(order[b.meal] ?? meals.length);
          return byMeal != 0 ? byMeal : a.sortOrder.compareTo(b.sortOrder);
        });
    var next = await _nextEntryOrder();
    for (final i in todo) {
      await _db
          .into(_db.dietEntries)
          .insert(
            DietEntriesCompanion.insert(
              id: newId(),
              createdAt: _now,
              updatedAt: _now,
              day: _storedDay(day),
              meal: i.meal,
              foodId: i.foodId,
              name: i.name,
              quantity: i.quantity,
              measureName: Value(i.measureName),
              grams: i.grams,
              kcal: Value(i.kcal),
              protein: Value(i.protein),
              carbs: Value(i.carbs),
              fat: Value(i.fat),
              fiber: Value(i.fiber),
              sortOrder: next++,
              planItemId: Value(i.id),
            ),
          );
    }
    return todo.length;
  });
}
