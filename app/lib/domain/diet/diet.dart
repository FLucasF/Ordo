import 'dart:convert';

// Dieta: the foods (the TACO table and the user's own), what was eaten each day by meal, and the sums.
// Values are per 100 g of the food; null is "not measured" (TACO leaves some blank), never 0.

/// Energy and macronutrients of an amount of food. A null value is unknown; a sum keeps the known
/// part (the total is then a floor, see [incomplete]).
class Nutrients {
  const Nutrients({this.kcal, this.protein, this.carbs, this.fat, this.fiber});

  static const zero = Nutrients(kcal: 0, protein: 0, carbs: 0, fat: 0, fiber: 0);

  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;

  /// [grams] of a food whose values are per 100 g.
  Nutrients forGrams(double grams) {
    double? scale(double? v) => v == null ? null : v * grams / 100;
    return Nutrients(kcal: scale(kcal), protein: scale(protein), carbs: scale(carbs), fat: scale(fat), fiber: scale(fiber));
  }

  Nutrients operator +(Nutrients o) {
    double? add(double? a, double? b) => a == null ? b : (b == null ? a : a + b);
    return Nutrients(
      kcal: add(kcal, o.kcal),
      protein: add(protein, o.protein),
      carbs: add(carbs, o.carbs),
      fat: add(fat, o.fat),
      fiber: add(fiber, o.fiber),
    );
  }
}

/// A household measure of a food: "colher de sopa cheia" = 25 g.
class FoodMeasure {
  const FoodMeasure({required this.name, required this.grams, this.isDefault = false});

  final String name;
  final double grams;
  final bool isDefault;
}

/// A food the diary can use: from the TACO table ([id] "taco:1") or the user's own ([id] its row id).
class Food {
  const Food({required this.id, required this.name, required this.per100g, this.group = '', this.measures = const [], this.custom = false});

  final String id;
  final String name;
  final String group;
  final Nutrients per100g;
  final List<FoodMeasure> measures;
  final bool custom;

  /// The measure picked first: the default one, else the first.
  FoodMeasure? get defaultMeasure => measures.where((m) => m.isDefault).firstOrNull ?? measures.firstOrNull;
}

/// The day's meals, in their order.
enum Meal {
  breakfast('breakfast'),
  morningSnack('morningSnack'),
  lunch('lunch'),
  afternoonSnack('afternoonSnack'),
  dinner('dinner'),
  supper('supper');

  const Meal(this.code);
  final String code;

  static Meal fromCode(String code) => values.where((m) => m.code == code).firstOrNull ?? lunch;

  /// The meal around [time]: breakfast until 10h, a snack until 11h30, lunch until 15h, a snack until
  /// 18h, dinner until 21h30, supper after.
  static Meal at(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes < 10 * 60) return breakfast;
    if (minutes < 11 * 60 + 30) return morningSnack;
    if (minutes < 15 * 60) return lunch;
    if (minutes < 18 * 60) return afternoonSnack;
    if (minutes < 21 * 60 + 30) return dinner;
    return supper;
  }
}

/// The TACO table as bundled in assets/taco.json (tool/make_taco_asset.py).
List<Food> parseTaco(String json) {
  final data = jsonDecode(json) as Map<String, Object?>;
  final measures = data['measures']! as Map<String, Object?>;
  double? number(Object? v) => (v as num?)?.toDouble();
  return [
    for (final row in data['foods']! as List<Object?>)
      if (row case [final int code, final String group, final String name, final kcal, final protein, final carbs, final fat, final fiber])
        Food(
          id: 'taco:$code',
          name: name,
          group: group,
          per100g: Nutrients(kcal: number(kcal), protein: number(protein), carbs: number(carbs), fat: number(fat), fiber: number(fiber)),
          measures: [
            for (final m in (measures['$code'] as List<Object?>?) ?? const [])
              if (m case [final String name, final num grams, final bool isDefault])
                FoodMeasure(name: name, grams: grams.toDouble(), isDefault: isDefault),
          ],
        ),
  ];
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
};

/// Lowercase without accents, so "acucar" finds "Açúcar".
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final ch in text.toLowerCase().split('')) {
    buffer.write(_accents[ch] ?? ch);
  }
  return buffer.toString();
}

/// Foods matching every word of [term] (accents and case ignored), best first: the whole name, the
/// name starting with the term ("Arroz, ..."), the term as a word, the name starting with it, then
/// any match; the user's own before TACO's, shorter names before longer, then alphabetically.
List<Food> searchFoods(Iterable<Food> foods, String term, {int limit = 40}) {
  final query = foldForSearch(term.trim());
  if (query.isEmpty) return const [];
  final words = query.split(RegExp(r'\s+'));
  final scored = <(int, Food, String)>[];
  for (final food in foods) {
    final name = foldForSearch(food.name);
    if (!words.every(name.contains)) continue;
    final int rank;
    if (name == query) {
      rank = 0;
    } else if (name.startsWith('$query,') || name.startsWith('$query ')) {
      rank = 1;
    } else if (RegExp('(^|[\\s,(])${RegExp.escape(query)}([\\s,)]|\$)').hasMatch(name)) {
      rank = 2;
    } else if (name.startsWith(query)) {
      rank = 3;
    } else {
      rank = 4;
    }
    scored.add((rank, food, name));
  }
  scored.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    if (a.$2.custom != b.$2.custom) return a.$2.custom ? -1 : 1;
    if (a.$3.length != b.$3.length) return a.$3.length.compareTo(b.$3.length);
    return a.$3.compareTo(b.$3);
  });
  return [for (final s in scored.take(limit)) s.$2];
}

/// "150 g", "2 colher de sopa cheia (50 g)", "1,5 xícara (240 g)".
String portionText(double quantity, String? measure, double grams) {
  String n(double v) => (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)).replaceAll('.', ',');
  return measure == null ? '${n(grams)} g' : '${n(quantity)} $measure (${n(grams)} g)';
}

/// Calories from the macros (Atwater: 4 kcal per gram of protein and of carbohydrate, 9 per gram of
/// fat); null when none of them is known.
double? kcalFromMacros({double? protein, double? carbs, double? fat}) =>
    protein == null && carbs == null && fat == null ? null : (protein ?? 0) * 4 + (carbs ?? 0) * 4 + (fat ?? 0) * 9;
