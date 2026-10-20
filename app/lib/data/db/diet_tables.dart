import 'package:drift/drift.dart';

import 'tables.dart';

// Dieta, schema v19. Values per 100 g of the food (null = not measured); days are the local day at
// UTC midnight, like Finanças'.

/// The user's own foods ("Meus alimentos"), next to the TACO table bundled with the app. One optional
/// household measure ([measureName] of [measureGrams] g).
@DataClassName('DietFood')
class DietFoods extends Table with SyncedRow {
  TextColumn get name => text()();
  RealColumn get kcal => real().nullable()();
  RealColumn get protein => real().nullable()();
  RealColumn get carbs => real().nullable()();
  RealColumn get fat => real().nullable()();
  RealColumn get fiber => real().nullable()();
  TextColumn get measureName => text().nullable()();
  RealColumn get measureGrams => real().nullable()();
}

/// What was eaten: a food in a meal of a day. The food's name and values per 100 g are copied, so an
/// entry keeps its sums when the food changes or goes away. [quantity] of [measureName] (null = grams)
/// makes [grams].
@DataClassName('DietEntry')
class DietEntries extends Table with SyncedRow {
  DateTimeColumn get day => dateTime()();
  TextColumn get meal => text()();

  /// "taco:1" or a [DietFoods] id.
  TextColumn get foodId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get measureName => text().nullable()();
  RealColumn get grams => real()();
  RealColumn get kcal => real().nullable()();
  RealColumn get protein => real().nullable()();
  RealColumn get carbs => real().nullable()();
  RealColumn get fat => real().nullable()();
  RealColumn get fiber => real().nullable()();
  IntColumn get sortOrder => integer()();

  /// The plan item this entry came from ("Importar plano do dia"), for the adherence (schema v20).
  TextColumn get planItemId => text().nullable()();
}

/// The meals of the day (schema v20). The six of before keep their codes as ids ("breakfast",
/// "lunch"…) with an empty [name], shown by its built-in label; the user's own have a name. [time] in
/// minutes after midnight suggests the meal when adding food.
@DataClassName('DietMeal')
class DietMeals extends Table with SyncedRow {
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get time => integer().nullable()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// Household measures (schema v20), as many as wanted, of an own food or of a TACO one ("taco:1").
@DataClassName('DietFoodMeasure')
class DietFoodMeasures extends Table with SyncedRow {
  TextColumn get foodId => text()();
  TextColumn get name => text()();
  RealColumn get grams => real()();
  IntColumn get sortOrder => integer()();
}

/// The meal plan ("Plano alimentar", schema v20): a food of a meal, on [weekdays] (DateTime.weekday
/// numbers joined by commas; empty = every day). Values copied like [DietEntries].
@DataClassName('DietPlanItem')
class DietPlanItems extends Table with SyncedRow {
  TextColumn get weekdays => text().withDefault(const Constant(''))();
  TextColumn get meal => text()();
  TextColumn get foodId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get measureName => text().nullable()();
  RealColumn get grams => real()();
  RealColumn get kcal => real().nullable()();
  RealColumn get protein => real().nullable()();
  RealColumn get carbs => real().nullable()();
  RealColumn get fat => real().nullable()();
  RealColumn get fiber => real().nullable()();
  IntColumn get sortOrder => integer()();
}
