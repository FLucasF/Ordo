import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/diet_repository.dart';
import '../../domain/diet/diet.dart';
import '../../domain/diet/plan.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../finance/finance_widgets.dart' show FinChip, FormHeader, showFinanceDialog;

/// The built-in label of the six meals of before ("Café da manhã", "Almoço"…); null for other ids.
String? builtInMealLabel(AppLocalizations t, String id) => switch (id) {
  'breakfast' => t.dietMealBreakfast,
  'morningSnack' => t.dietMealMorningSnack,
  'lunch' => t.dietMealLunch,
  'afternoonSnack' => t.dietMealAfternoonSnack,
  'dinner' => t.dietMealDinner,
  'supper' => t.dietMealSupper,
  _ => null,
};

/// A meal's name: its own, else the built-in label of its id.
String mealName(AppLocalizations t, DietMeal meal) => meal.name.isNotEmpty ? meal.name : (builtInMealLabel(t, meal.id) ?? t.dietMeal);

/// The name of the meal [id] an entry or plan item is in, even when the meal is gone.
String mealNameOf(AppLocalizations t, DietSnapshot diet, String id) => switch (diet.meal(id)) {
  final m? => mealName(t, m),
  null => builtInMealLabel(t, id) ?? t.dietMeal,
};

/// "07:00" (or "7:00 AM") of minutes after midnight.
String mealTimeText(int minutes) => DateLabels.time(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

/// "Seg, Qua, Sex" in the week's order, or "Todos os dias".
String weekdaysText(AppLocalizations t, String csv) {
  final days = parseWeekdays(csv);
  if (days.isEmpty) return t.dietPlanEveryDay;
  final labels = DateLabels(t);
  return [
    for (final wd in weekdayOrder())
      if (days.contains(wd)) labels.weekdayShort(weekdayDate(wd)),
  ].join(', ');
}

/// A date on weekday [wd] (2026-09-20 was a Sunday), for its short name.
DateTime weekdayDate(int wd) => DateTime(2026, 9, 20 + wd % 7);

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

/// The food with its household measures as they are now (TACO's, the user's): an entry's copy has
/// none, and a measure may have been added since the food was picked. The values stay [food]'s.
Food _withMeasures(Food food, List<Food> all) {
  final full = all.where((f) => f.id == food.id).firstOrNull;
  return full == null
      ? food
      : Food(id: food.id, name: food.name, group: full.group, per100g: food.per100g, measures: full.measures, custom: full.custom);
}

/// The meal suggested now: the one whose time is the closest before; else the first in use.
String suggestedMeal(DietSnapshot diet, DateTime now) =>
    suggestMealAt([for (final m in diet.activeMeals) (id: m.id, time: m.time)], now) ?? diet.activeMeals.firstOrNull?.id ?? 'lunch';

/// "Adicionar alimento" (on [day], in [meal], [food] already chosen) or editing an [editing] entry:
/// the meal, the food searched in TACO and the user's own, and the amount in grams or a household
/// measure; the editing form has the bin.
Future<void> showDietEntryForm(BuildContext context, {DietEntry? editing, DateTime? day, String? meal, Food? food}) => showFinanceDialog<void>(
  context,
  builder: (_) => _EntryForm(editing: editing, day: day, meal: meal, food: food),
);

/// "Adicionar ao plano" (in [meal], on [weekday] or every day) or editing a plan item: the same form
/// as the diary's, with the days of the week instead of the day.
Future<void> showDietPlanItemForm(BuildContext context, {DietPlanItem? editing, String? meal, int? weekday}) => showFinanceDialog<void>(
  context,
  builder: (_) => _EntryForm(editingPlan: editing, meal: meal, plan: true, weekday: weekday),
);

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({this.editing, this.editingPlan, this.day, this.meal, this.food, this.plan = false, this.weekday});

  final DietEntry? editing;
  final DietPlanItem? editingPlan;
  final DateTime? day;
  final String? meal;
  final Food? food;

  /// A plan item instead of an entry.
  final bool plan;
  final int? weekday;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  late final DietEntry? _e = widget.editing;
  late final DietPlanItem? _p = widget.editingPlan;
  late String _meal =
      _e?.meal ?? _p?.meal ?? widget.meal ?? suggestedMeal(ref.read(dietProvider).value ?? DietSnapshot.empty, ref.read(clockProvider).now());
  late final DateTime _day = _e == null ? (widget.day ?? startOfDay(ref.read(clockProvider).now())) : dietDay(_e.day);
  late final Set<int> _weekdays = _p == null ? {?widget.weekday} : parseWeekdays(_p.weekdays);
  late Food? _food = widget.food ?? _copiedFood();
  late final _quantity = TextEditingController(text: _e != null ? formatGrams(_e.quantity) : (_p != null ? formatGrams(_p.quantity) : ''));
  final _query = TextEditingController();

  /// The measure picked by its name (null = grams); set when the food is picked.
  late String? _measureName = _e?.measureName ?? _p?.measureName;
  bool _showError = false;

  Food? _copiedFood() {
    if (_e case final e?) {
      return Food(
        id: e.foodId,
        name: e.name,
        per100g: Nutrients(kcal: e.kcal, protein: e.protein, carbs: e.carbs, fat: e.fat, fiber: e.fiber),
      );
    }
    if (_p case final p?) {
      return Food(
        id: p.foodId,
        name: p.name,
        per100g: Nutrients(kcal: p.kcal, protein: p.protein, carbs: p.carbs, fat: p.fat, fiber: p.fiber),
      );
    }
    return null;
  }

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
    if (widget.plan) {
      final weekdays = weekdaysCsv(_weekdays);
      if (_p case final p?) {
        await repo.updatePlanItem(
          p.id,
          meal: _meal,
          quantity: quantity,
          measure: measure,
          weekdays: weekdays,
          food: food.id == p.foodId ? null : food,
        );
      } else {
        await repo.addPlanItem(meal: _meal, food: food, quantity: quantity, measure: measure, weekdays: weekdays);
      }
    } else if (_e case final editing?) {
      // A food changed is copied again; the same food keeps the values it was eaten with.
      await repo.updateEntry(editing.id, day: _day, meal: _meal, quantity: quantity, measure: measure, food: food.id == editing.foodId ? null : food);
    } else {
      await repo.addEntry(day: _day, meal: _meal, food: food, quantity: quantity, measure: measure);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(dietRepositoryProvider);
    final page = Navigator.of(context).context;
    Navigator.pop(context);
    if (_p case final p?) {
      await repo.deletePlanItem(p.id);
      if (page.mounted) {
        showToast(page, t.dietPlanItemDeleted, undo: () => repo.deletePlanItem(p.id, restore: true), redo: () => repo.deletePlanItem(p.id));
      }
    } else if (_e case final e?) {
      await repo.deleteEntry(e.id);
      if (page.mounted) showToast(page, t.dietEntryDeleted, undo: () => repo.deleteEntry(e.id, restore: true), redo: () => repo.deleteEntry(e.id));
    }
  }

  /// "+ Medida" beside the measures: added to the food (TACO's too) and picked.
  Future<void> _newMeasure(Food food) async {
    final made = await showMeasurePrompt(context);
    if (made == null || !mounted) return;
    await ref.read(dietRepositoryProvider).addMeasure(foodId: food.id, name: made.name, grams: made.grams);
    if (!mounted) return;
    setState(() {
      _measureName = made.name;
      if (parseDecimal(_quantity.text) == null || _measureOf(food) == null) _quantity.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final diet = ref.watch(dietProvider).value ?? DietSnapshot.empty;
    final taco = ref.watch(tacoProvider).value ?? const <Food>[];
    final all = diet.allFoods(taco);
    final food = _food == null ? null : _withMeasures(_food!, all);
    final measure = food == null ? null : _measureOf(food);
    final quantity = parseDecimal(_quantity.text);
    final grams = quantity == null ? null : (measure == null ? quantity : quantity * measure.grams);
    final portion = food == null || grams == null ? null : food.per100g.forGrams(grams);
    final results = food == null ? searchFoods(all, _query.text, limit: 30) : const <Food>[];
    // The meals in use, and the one of what is edited even when archived.
    final meals = [
      for (final m in diet.meals)
        if (m.archivedAt == null || m.id == _meal) (id: m.id, name: mealName(t, m)),
    ];
    if (!meals.any((m) => m.id == _meal)) meals.add((id: _meal, name: mealNameOf(t, diet, _meal)));
    final labels = DateLabels(t);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: widget.plan ? (_p == null ? t.dietAddToPlan : t.dietEditPlanItem) : (_e == null ? t.dietAddFood : t.dietEditEntry),
          onSave: () => unawaited(_save(food)),
          onDelete: _e == null && _p == null ? null : () => unawaited(_delete()),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _meal,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.dietMeal, isDense: true),
                items: [
                  for (final m in meals)
                    DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (m) => setState(() => _meal = m ?? _meal),
              ),
              if (widget.plan) ...[
                const SizedBox(height: 12),
                Text(
                  t.dietPlanDays,
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final wd in weekdayOrder())
                      FinChip(
                        label: labels.weekdayShort(weekdayDate(wd)),
                        selected: _weekdays.contains(wd),
                        onTap: () => setState(() => _weekdays.contains(wd) ? _weekdays.remove(wd) : _weekdays.add(wd)),
                      ),
                  ],
                ),
              ],
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
                        // Rebuilt when a measure is added, so the new one can be the value.
                        key: ValueKey('${food.id}/${food.measures.length}'),
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
                    IconButton(
                      tooltip: t.dietNewMeasure,
                      icon: Icon(Icons.add, size: 20, color: tt.textSecondary),
                      onPressed: () => unawaited(_newMeasure(food)),
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

/// "Nova medida": a name and its grams; null when cancelled or incomplete.
Future<({String name, double grams})?> showMeasurePrompt(BuildContext context) =>
    showDialog<({String name, double grams})>(context: context, builder: (_) => const _MeasurePrompt());

class _MeasurePrompt extends StatefulWidget {
  const _MeasurePrompt();

  @override
  State<_MeasurePrompt> createState() => _MeasurePromptState();
}

class _MeasurePromptState extends State<_MeasurePrompt> {
  final _name = TextEditingController();
  final _grams = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _grams.dispose();
    super.dispose();
  }

  void _done() {
    final grams = parseDecimal(_grams.text);
    if (_name.text.trim().isEmpty || grams == null || grams <= 0) return;
    Navigator.pop(context, (name: _name.text.trim(), grams: grams));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.dietNewMeasure),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: t.dietMeasureLabel, isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(labelText: t.dietMeasureGramsShort, suffixText: 'g', isDense: true),
              onSubmitted: (_) => _done(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: _done, child: Text(t.actionAdd)),
      ],
    );
  }
}

/// "Medidas caseiras" of a TACO food: the table's (as they are) and the user's, each with its bin,
/// and "+ Medida".
Future<void> showFoodMeasures(BuildContext context, Food food) => showFinanceDialog<void>(context, builder: (_) => _FoodMeasures(food: food));

class _FoodMeasures extends ConsumerStatefulWidget {
  const _FoodMeasures({required this.food});

  final Food food;

  @override
  ConsumerState<_FoodMeasures> createState() => _FoodMeasuresState();
}

class _FoodMeasuresState extends ConsumerState<_FoodMeasures> {
  /// Deleted while the dialog is open: they stay in sight, faded, with "Desfazer" (the toast's is
  /// under the dialog).
  final _deleted = <FoodMeasure>[];

  Future<void> _delete(FoodMeasure m) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(dietRepositoryProvider);
    await repo.deleteMeasure(m.id!);
    if (!mounted) return;
    setState(() => _deleted.add(m));
    showToast(context, t.dietMeasureDeleted, undo: () => repo.deleteMeasure(m.id!, restore: true), redo: () => repo.deleteMeasure(m.id!));
  }

  Future<void> _restore(FoodMeasure m) async {
    await ref.read(dietRepositoryProvider).deleteMeasure(m.id!, restore: true);
    if (mounted) setState(() => _deleted.remove(m));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final food = widget.food;
    final diet = ref.watch(dietProvider).value ?? DietSnapshot.empty;
    final mine = diet.userMeasuresOf(food.id);
    final repo = ref.read(dietRepositoryProvider);
    Widget line(FoodMeasure m, {Widget? action, bool faded = false}) => Row(
      children: [
        Expanded(
          child: Text(
            m.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: faded ? tt.textTertiary : tt.text, decoration: faded ? TextDecoration.lineThrough : null),
          ),
        ),
        Text('${formatGrams(m.grams)} g', style: TextStyle(color: faded ? tt.textTertiary : tt.textSecondary)),
        action ?? const SizedBox(width: 48, height: 40),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(t.dietMeasures, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose)),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(
                food.name,
                style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
              ),
              if (food.measures.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  t.dietTacoMeasures,
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
                for (final m in food.measures) line(m),
              ],
              const SizedBox(height: 12),
              Text(
                t.dietMyMeasures,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
              if (mine.isEmpty && _deleted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(t.dietNoMeasures, style: TextStyle(color: tt.textTertiary)),
                ),
              for (final m in mine)
                line(
                  m,
                  action: IconButton(
                    tooltip: t.actionDelete,
                    icon: Icon(Icons.delete_outline, size: 20, color: tt.overdue),
                    onPressed: () => unawaited(_delete(m)),
                  ),
                ),
              for (final m in _deleted)
                if (!mine.any((x) => x.id == m.id))
                  line(
                    m,
                    faded: true,
                    action: TextButton(onPressed: () => unawaited(_restore(m)), child: Text(t.toastUndo)),
                  ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.dietAddMeasure),
                  onPressed: () async {
                    final made = await showMeasurePrompt(context);
                    if (made != null) await repo.addMeasure(foodId: food.id, name: made.name, grams: made.grams);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// "Novo alimento" / "Editar alimento": a name, the values per 100 g (blank = unknown) and its
/// household measures ("+ Medida", a bin on each). With [use] ("Não achei" while adding), returns
/// the food made to put it in the entry at once.
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

/// A measure row of the food form: [id] null for one not saved in the table yet (a new one, or the
/// single measure of before schema v20, which moves to the table on saving).
class _MeasureRow {
  _MeasureRow({this.id, String name = '', double? grams})
    : name = TextEditingController(text: name),
      grams = TextEditingController(text: grams == null ? '' : formatGrams(grams));

  final String? id;
  final TextEditingController name;
  final TextEditingController grams;

  void dispose() {
    name.dispose();
    grams.dispose();
  }
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  late final DietFood? _f = widget.editing;
  late final _name = TextEditingController(text: _f?.name ?? widget.name);
  late final _kcal = TextEditingController(text: _f?.kcal == null ? '' : formatGrams(_f!.kcal));
  late final _protein = TextEditingController(text: _f?.protein == null ? '' : formatGrams(_f!.protein));
  late final _carbs = TextEditingController(text: _f?.carbs == null ? '' : formatGrams(_f!.carbs));
  late final _fat = TextEditingController(text: _f?.fat == null ? '' : formatGrams(_f!.fat));
  late final _fiber = TextEditingController(text: _f?.fiber == null ? '' : formatGrams(_f!.fiber));
  late final List<_MeasureRow> _measures = _initialMeasures();
  bool _showError = false;

  List<_MeasureRow> _initialMeasures() {
    final f = _f;
    if (f == null) return [];
    final diet = ref.read(dietProvider).value ?? DietSnapshot.empty;
    return [
      if (f.measureName case final name? when (f.measureGrams ?? 0) > 0) _MeasureRow(name: name, grams: f.measureGrams),
      for (final m in diet.userMeasuresOf(f.id)) _MeasureRow(id: m.id, name: m.name, grams: m.grams),
    ];
  }

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat, _fiber]) {
      c.dispose();
    }
    for (final m in _measures) {
      m.dispose();
    }
    super.dispose();
  }

  /// The calories from the macros, used when the field is left empty.
  double? get _kcalFromMacros => kcalFromMacros(protein: parseDecimal(_protein.text), carbs: parseDecimal(_carbs.text), fat: parseDecimal(_fat.text));

  Nutrients get _per100g => Nutrients(
    kcal: parseDecimal(_kcal.text) ?? _kcalFromMacros,
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
    final drafts = <MeasureDraft>[
      for (final m in _measures)
        if (parseDecimal(m.grams.text) case final grams? when grams > 0 && m.name.text.trim().isNotEmpty)
          (id: m.id, name: m.name.text.trim(), grams: grams),
    ];
    final editing = _f;
    final String id;
    if (editing == null) {
      id = await repo.createFood(name: name, per100g: per100g, measures: drafts);
    } else {
      id = editing.id;
      await repo.updateFood(id, name: name, per100g: per100g, measures: drafts);
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      Food(
        id: id,
        name: name,
        per100g: per100g,
        custom: true,
        measures: [for (final d in drafts) FoodMeasure(name: d.name, grams: d.grams)],
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
    // Empty calories show what the macros give (and that is what is saved).
    final fromMacros = _kcal.text.trim().isEmpty ? _kcalFromMacros : null;
    Widget number(TextEditingController c, String label, String unit, {String? hint, String? helper}) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          isDense: true,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          floatingLabelBehavior: hint == null ? null : FloatingLabelBehavior.always,
        ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  number(
                    _kcal,
                    t.dietKcal,
                    'kcal',
                    hint: fromMacros == null ? null : formatKcal(fromMacros),
                    helper: fromMacros == null ? null : t.dietKcalFromMacros,
                  ),
                  const SizedBox(width: 12),
                  number(_protein, t.dietProtein, 'g'),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [number(_carbs, t.dietCarbs, 'g'), const SizedBox(width: 12), number(_fat, t.dietFat, 'g')]),
              const SizedBox(height: 8),
              Row(children: [number(_fiber, t.dietFiber, 'g'), const SizedBox(width: 12), const Spacer()]),
              const SizedBox(height: 14),
              Text(
                t.dietMeasures,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
              for (final m in _measures)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: m.name,
                          decoration: InputDecoration(labelText: t.dietMeasureLabel, isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      number(m.grams, t.dietMeasureGramsShort, 'g'),
                      IconButton(
                        tooltip: t.actionDelete,
                        icon: Icon(Icons.delete_outline, size: 20, color: tt.overdue),
                        onPressed: () {
                          setState(() => _measures.remove(m));
                          // Its fields leave the tree on the next frame.
                          WidgetsBinding.instance.addPostFrameCallback((_) => m.dispose());
                        },
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.dietAddMeasure),
                  onPressed: () => setState(() => _measures.add(_MeasureRow())),
                ),
              ),
              if (widget.use) ...[const SizedBox(height: 16), FilledButton(onPressed: () => unawaited(_save()), child: Text(t.dietSaveAndUse))],
            ],
          ),
        ),
      ],
    );
  }
}
