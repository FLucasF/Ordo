import 'diet.dart';

/// Daily targets of Dieta (⚙ Metas), kept in the preferences. A null value has no target.
class DietTargets {
  const DietTargets({this.kcal, this.protein, this.carbs, this.fat, this.energyFromMacros = false});

  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  /// The calorie target comes from the macros' (P×4 + C×4 + G×9) instead of [kcal].
  final bool energyFromMacros;

  /// The calorie target in use: typed, or from the macros.
  double? get energy => energyFromMacros ? kcalFromMacros(protein: protein, carbs: carbs, fat: fat) : kcal;

  bool get isEmpty => energy == null && protein == null && carbs == null && fat == null;

  Map<String, Object?> toJson() => {'kcal': kcal, 'protein': protein, 'carbs': carbs, 'fat': fat, 'fromMacros': energyFromMacros};

  /// A bad or missing value is no target, so a broken row never breaks the screen.
  static DietTargets fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const DietTargets();
    double? n(Object? v) => v is num && v > 0 ? v.toDouble() : null;
    return DietTargets(
      kcal: n(json['kcal']),
      protein: n(json['protein']),
      carbs: n(json['carbs']),
      fat: n(json['fat']),
      energyFromMacros: json['fromMacros'] == true,
    );
  }
}

/// Where an amount stands against its target: below (under 90%), near (90% to 110%) or over (above
/// 110%), the bar's grey-blue, green and red.
enum TargetLevel { below, near, over }

TargetLevel targetLevel(double consumed, double target) {
  final ratio = target <= 0 ? 0 : consumed / target;
  if (ratio > 1.1) return TargetLevel.over;
  if (ratio >= 0.9) return TargetLevel.near;
  return TargetLevel.below;
}
