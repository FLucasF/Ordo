import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/diet_repository.dart';
import '../../domain/diet/diet.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../finance/finance_widgets.dart' show FormHeader, showFinanceDialog;

/// "Café da manhã", "Almoço"…
String mealLabel(AppLocalizations t, Meal meal) => switch (meal) {
  Meal.breakfast => t.dietMealBreakfast,
  Meal.morningSnack => t.dietMealMorningSnack,
  Meal.lunch => t.dietMealLunch,
  Meal.afternoonSnack => t.dietMealAfternoonSnack,
  Meal.dinner => t.dietMealDinner,
  Meal.supper => t.dietMealSupper,
};

/// "1.234" (kcal, whole); "—" when unknown.
String formatKcal(double? kcal) {
  if (kcal == null) return '—';
  final digits = kcal.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// "12,5" (grams, one decimal); "—" when unknown.
String formatGrams(double? grams) => grams == null ? '—' : grams.toStringAsFixed(1).replaceAll('.', ',').replaceAll(RegExp(r',0$'), '');

/// "12,5" or "12.5" typed; null when it isn't a number.
double? parseDecimal(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t);
}

/// "P 2,6 g · C 25,8 g · G 1 g".
String macrosText(Nutrients n) => 'P ${formatGrams(n.protein)} g · C ${formatGrams(n.carbs)} g · G ${formatGrams(n.fat)} g';

/// The food with its household measures: an entry's copy has none, the table's food has them.
Food _withMeasures(Food food, List<Food> all) {
  if (food.measures.isNotEmpty) return food;
  final full = all.where((f) => f.id == food.id).firstOrNull;
  return full == null
      ? food
      : Food(id: food.id, name: food.name, group: full.group, per100g: food.per100g, measures: full.measures, custom: full.custom);
}

/// "Adicionar alimento" (on [day], in [meal], [food] already chosen) or editing an [editing] entry:
/// the meal, the food searched in TACO and the user's own, and the amount in grams or a household
/// measure; the editing form has the bin.
Future<void> showDietEntryForm(BuildContext context, {DietEntry? editing, DateTime? day, Meal? meal, Food? food}) => showFinanceDialog<void>(
  context,
  builder: (_) => _EntryForm(editing: editing, day: day, meal: meal, food: food),
);

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({this.editing, this.day, this.meal, this.food});

  final DietEntry? editing;
  final DateTime? day;
  final Meal? meal;
  final Food? food;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  late final DietEntry? _e = widget.editing;
  late Meal _meal = _e == null ? (widget.meal ?? Meal.at(ref.read(clockProvider).now())) : Meal.fromCode(_e.meal);
  late final DateTime _day = _e == null ? (widget.day ?? startOfDay(ref.read(clockProvider).now())) : dietDay(_e.day);
  late Food? _food =
      widget.food ??
      (_e == null
          ? null
          : Food(
              id: _e.foodId,
              name: _e.name,
              per100g: Nutrients(kcal: _e.kcal, protein: _e.protein, carbs: _e.carbs, fat: _e.fat, fiber: _e.fiber),
            ));
  late final _quantity = TextEditingController(text: _e == null ? '' : formatGrams(_e.quantity));
  final _query = TextEditingController();

  /// The measure picked by its name (null = grams); set when the food is picked.
  late String? _measureName = _e?.measureName;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    // A food chosen beforehand (from the foods' list): its default measure, 1 of it, or 100 g.
    final food = widget.food;
    if (_e == null && food != null) {
      _measureName = food.defaultMeasure?.name;
      _quantity.text = food.defaultMeasure == null ? '100' : '1';
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _query.dispose();
    super.dispose();
  }

  void _pick(Food food) => setState(() {
    _food = food;
    // The default measure, 1 of it; without measures, 100 g.
    _measureName = food.defaultMeasure?.name;
    _quantity.text = food.defaultMeasure == null ? '100' : '1';
  });

  FoodMeasure? _measureOf(Food food) => food.measures.where((m) => m.name == _measureName).firstOrNull;

  Future<void> _save(Food? food) async {
    final quantity = parseDecimal(_quantity.text);
    if (food == null || quantity == null || quantity <= 0) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(dietRepositoryProvider);
    final measure = _measureOf(food);
    final editing = _e;
    if (editing == null) {
      await repo.addEntry(day: _day, meal: _meal, food: food, quantity: quantity, measure: measure);
    } else {
      // A food changed is copied again; the same food keeps the values it was eaten with.
      await repo.updateEntry(editing.id, day: _day, meal: _meal, quantity: quantity, measure: measure, food: food.id == editing.foodId ? null : food);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete(DietEntry e) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(dietRepositoryProvider);
    final page = Navigator.of(context).context;
    Navigator.pop(context);
    await repo.deleteEntry(e.id);
    if (page.mounted) showToast(page, t.dietEntryDeleted, undo: () => repo.deleteEntry(e.id, restore: true), redo: () => repo.deleteEntry(e.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final diet = ref.watch(dietProvider).value ?? DietSnapshot.empty;
    final taco = ref.watch(tacoProvider).value ?? const <Food>[];
    final all = [...diet.customFoods, ...taco];
    final food = _food == null ? null : _withMeasures(_food!, all);
    final measure = food == null ? null : _measureOf(food);
    final quantity = parseDecimal(_quantity.text);
    final grams = quantity == null ? null : (measure == null ? quantity : quantity * measure.grams);
    final portion = food == null || grams == null ? null : food.per100g.forGrams(grams);
    final results = food == null ? searchFoods(all, _query.text, limit: 30) : const <Food>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: _e == null ? t.dietAddFood : t.dietEditEntry,
          onSave: () => unawaited(_save(food)),
          onDelete: switch (_e) {
            final e? => () => unawaited(_delete(e)),
            null => null,
          },
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              DropdownButtonFormField<Meal>(
                initialValue: _meal,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.dietMeal, isDense: true),
                items: [for (final m in Meal.values) DropdownMenuItem(value: m, child: Text(mealLabel(t, m)))],
                onChanged: (m) => setState(() => _meal = m ?? _meal),
              ),
              const SizedBox(height: 14),
              if (food == null) ...[
                TextField(
                  controller: _query,
                  autofocus: true,
                  decoration: InputDecoration(hintText: t.dietSearchHint, prefixIcon: const Icon(Icons.search, size: 20), isDense: true),
                  onChanged: (_) => setState(() {}),
                ),
                for (final f in results)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(f.name, style: TextStyle(color: tt.text)),
                    subtitle: Text(f.custom ? t.dietMine : f.group, style: TextStyle(color: tt.textTertiary)),
                    trailing: Text(
                      t.dietPerHundred(formatKcal(f.per100g.kcal)),
                      style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
                    ),
                    onTap: () => _pick(f),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t.dietNotFound),
                    onPressed: () async {
                      final created = await showDietFoodForm(context, name: _query.text.trim(), use: true);
                      if (created != null && mounted) _pick(created);
                    },
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                          ),
                          Text(
                            '${t.dietPerHundred(formatKcal(food.per100g.kcal))} · ${macrosText(food.per100g)}',
                            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => setState(() => _food = null), child: Text(t.dietChangeFood)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: InputDecoration(labelText: t.dietQuantity, isDense: true),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => unawaited(_save(food)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(food.id),
                        initialValue: measure == null ? -1 : food.measures.indexOf(measure),
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: [
                          DropdownMenuItem(value: -1, child: Text(t.dietGrams)),
                          for (final (i, m) in food.measures.indexed)
                            DropdownMenuItem(
                              value: i,
                              child: Text('${m.name} (${formatGrams(m.grams)} g)', overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (i) => setState(() => _measureName = i == null || i < 0 ? null : food.measures[i].name),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (portion != null && grams != null)
                  Text(
                    '${t.dietPortionResult(formatGrams(grams), formatKcal(portion.kcal))} · ${macrosText(portion)}',
                    style: TextStyle(color: tt.primary, fontWeight: FontWeight.w600),
                  ),
              ],
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t.dietQuantityRequired,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Novo alimento" / "Editar alimento": a name and the values per 100 g (blank = unknown), and a
/// household measure. With [use] ("Não achei" while adding), returns the food made to put it in
/// the entry at once.
Future<Food?> showDietFoodForm(BuildContext context, {DietFood? editing, String name = '', bool use = false}) => showFinanceDialog<Food>(
  context,
  builder: (_) => _FoodForm(editing: editing, name: name, use: use),
);

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({this.editing, required this.name, required this.use});

  final DietFood? editing;
  final String name;
  final bool use;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  late final DietFood? _f = widget.editing;
  late final _name = TextEditingController(text: _f?.name ?? widget.name);
  late final _kcal = TextEditingController(text: _f?.kcal == null ? '' : formatGrams(_f!.kcal));
  late final _protein = TextEditingController(text: _f?.protein == null ? '' : formatGrams(_f!.protein));
  late final _carbs = TextEditingController(text: _f?.carbs == null ? '' : formatGrams(_f!.carbs));
  late final _fat = TextEditingController(text: _f?.fat == null ? '' : formatGrams(_f!.fat));
  late final _fiber = TextEditingController(text: _f?.fiber == null ? '' : formatGrams(_f!.fiber));
  late final _measure = TextEditingController(text: _f?.measureName ?? '');
  late final _measureGrams = TextEditingController(text: _f?.measureGrams == null ? '' : formatGrams(_f!.measureGrams));
  bool _showError = false;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat, _fiber, _measure, _measureGrams]) {
      c.dispose();
    }
    super.dispose();
  }

  Nutrients get _per100g => Nutrients(
    kcal: parseDecimal(_kcal.text),
    protein: parseDecimal(_protein.text),
    carbs: parseDecimal(_carbs.text),
    fat: parseDecimal(_fat.text),
    fiber: parseDecimal(_fiber.text),
  );

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(dietRepositoryProvider);
    final per100g = _per100g;
    final grams = parseDecimal(_measureGrams.text);
    final editing = _f;
    final String id;
    if (editing == null) {
      id = await repo.createFood(name: name, per100g: per100g, measureName: _measure.text, measureGrams: grams);
    } else {
      id = editing.id;
      await repo.updateFood(id, name: name, per100g: per100g, measureName: _measure.text, measureGrams: grams);
    }
    if (!mounted) return;
    final measureName = _measure.text.trim();
    Navigator.pop(
      context,
      Food(
        id: id,
        name: name,
        per100g: per100g,
        custom: true,
        measures: [if (measureName.isNotEmpty && (grams ?? 0) > 0) FoodMeasure(name: measureName, grams: grams!, isDefault: true)],
      ),
    );
  }

  Future<void> _delete(DietFood f) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(dietRepositoryProvider);
    final page = Navigator.of(context).context;
    Navigator.pop(context);
    await repo.deleteFood(f.id);
    if (page.mounted) showToast(page, t.dietFoodDeleted, undo: () => repo.deleteFood(f.id, restore: true), redo: () => repo.deleteFood(f.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    Widget number(TextEditingController c, String label, String unit) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(labelText: label, suffixText: unit, isDense: true),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: _f == null ? t.dietNewFood : t.dietEditFood,
          onSave: () => unawaited(_save()),
          onDelete: switch (_f) {
            final f? => () => unawaited(_delete(f)),
            null => null,
          },
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _name,
                autofocus: _f == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: t.dietName, isDense: true),
              ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.dietNameRequired,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                t.dietPer100,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
              const SizedBox(height: 6),
              Row(children: [number(_kcal, t.dietKcal, 'kcal'), const SizedBox(width: 12), number(_protein, t.dietProtein, 'g')]),
              const SizedBox(height: 8),
              Row(children: [number(_carbs, t.dietCarbs, 'g'), const SizedBox(width: 12), number(_fat, t.dietFat, 'g')]),
              const SizedBox(height: 8),
              Row(children: [number(_fiber, t.dietFiber, 'g'), const SizedBox(width: 12), const Spacer()]),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _measure,
                      decoration: InputDecoration(labelText: t.dietMeasureName, isDense: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  number(_measureGrams, t.dietMeasureGrams, 'g'),
                ],
              ),
              if (widget.use) ...[const SizedBox(height: 16), FilledButton(onPressed: () => unawaited(_save()), child: Text(t.dietSaveAndUse))],
            ],
          ),
        ),
      ],
    );
  }
}
