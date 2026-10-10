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
}
