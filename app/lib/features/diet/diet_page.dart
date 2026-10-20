import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/diet_repository.dart';
import '../../domain/diet/diet.dart';
import '../../domain/diet/plan.dart';
import '../../domain/diet/targets.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import '../date_picker/month_calendar.dart';
import '../shell/app_shell.dart';
import '../statistics/charts.dart' show DonutChart;
import 'diet_forms.dart';
import 'diet_meals.dart';
import 'diet_plan.dart';
import 'diet_targets.dart';

/// Tabs of Dieta (`/diet/{tab}`).
enum DietTab {
  diary('diary'),
  foods('foods'),
  plan('plan');

  const DietTab(this.route);
  final String route;

  static DietTab fromRoute(String? route) => values.where((t) => t.route == route).firstOrNull ?? diary;
}

/// Dieta in the Calendar's look: a left panel with the month (days with something eaten are marked;
/// a click opens the day), the tabs Diário, Alimentos and Plano under the top bar, ⚙ Metas, and
/// "+ Adicionar alimento" (or "+ Novo alimento", "+ Adicionar ao plano") at its end.
///
/// Diário: the day's calories and macros against the targets, "Importar plano do dia", then each
/// meal with its foods (a click edits, ⋯ edits or deletes, "+" adds to that meal; the meal's name
/// edits it, its ⋯ moves or archives it) and "+ Refeição". Alimentos: the user's own foods, and a
/// search over them and the TACO table (a click adds the food to the day). Plano: see [DietPlanView].
class DietPage extends ConsumerStatefulWidget {
  const DietPage({super.key, required this.tab});

  final DietTab tab;

  @override
  ConsumerState<DietPage> createState() => _DietPageState();
}

class _DietPageState extends ConsumerState<DietPage> {
  bool _panel = true;

  /// The day shown (null = today).
  DateTime? _day;
  DateTime? _panelMonth;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _entryMenu(DietEntry e, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Text(t.actionDelete, style: TextStyle(color: context.tt.overdue)),
        ),
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case 'edit':
        await showDietEntryForm(context, editing: e);
      case 'delete':
        final repo = ref.read(dietRepositoryProvider);
        await repo.deleteEntry(e.id);
        if (mounted) showToast(context, t.dietEntryDeleted, undo: () => repo.deleteEntry(e.id, restore: true), redo: () => repo.deleteEntry(e.id));
    }
  }

  Future<void> _foodMenu(Food food, DietSnapshot diet, DateTime day, Offset at) async {
    final t = AppLocalizations.of(context);
    final own = diet.foods.where((f) => f.id == food.id).firstOrNull;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'add', height: 36, child: Text(t.dietAddToDay)),
        // An own food's measures are in its form; TACO's get the user's beside the table's.
        if (own == null) PopupMenuItem(value: 'measures', height: 36, child: Text(t.dietMeasures)),
        if (own != null) ...[
          PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
          PopupMenuItem(
            value: 'delete',
            height: 36,
            child: Text(t.actionDelete, style: TextStyle(color: context.tt.overdue)),
          ),
        ],
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case 'add':
        await showDietEntryForm(context, day: day, food: food);
      case 'measures':
        await showFoodMeasures(context, food);
      case 'edit' when own != null:
        await showDietFoodForm(context, editing: own);
      case 'delete' when own != null:
        final repo = ref.read(dietRepositoryProvider);
        await repo.deleteFood(own.id);
        if (mounted) showToast(context, t.dietFoodDeleted, undo: () => repo.deleteFood(own.id, restore: true), redo: () => repo.deleteFood(own.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final dates = DateLabels(t);
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final day = _day ?? today;
    final diet = ref.watch(dietProvider).value ?? DietSnapshot.empty;
    final taco = ref.watch(tacoProvider).value ?? const <Food>[];
    final targets = ref.watch(preferencesProvider).value?.dietTargets ?? const DietTargets();
    final diary = widget.tab == DietTab.diary;

    void create() => unawaited(switch (widget.tab) {
      DietTab.diary => showDietEntryForm(context, day: day),
      DietTab.foods => showDietFoodForm(context),
      DietTab.plan => showDietPlanItemForm(context),
    });
    final createLabel = switch (widget.tab) {
      DietTab.diary => t.dietAddFood,
      DietTab.foods => t.dietNewFood,
      DietTab.plan => t.dietAddToPlan,
    };

    final topBar = ShellTopBar(
      title: diary ? dates.dayHeader(day, today) : t.navDiet,
      onTogglePanel: () => setState(() => _panel = !_panel),
      onCreate: create,
      createLabel: createLabel,
      actions: [
        if (diary) ...[
          TodayPill(label: t.calendarToday, onPressed: () => setState(() => _day = null)),
          ShellArrows(
            onPrevious: () => setState(() => _day = day.subtract(const Duration(days: 1))),
            onNext: () => setState(() => _day = day.add(const Duration(days: 1))),
          ),
        ],
        IconButton(
          tooltip: t.dietTargets,
          icon: Icon(Icons.settings_outlined, color: tt.textSecondary),
          onPressed: () => unawaited(showDietTargetsForm(context)),
        ),
      ],
    );

    final shownMonth = _panelMonth ?? DateTime(day.year, day.month);
    final panel = ShellPanel(
      children: [
        MonthCalendar(
          month: shownMonth,
          today: today,
          isSelected: (d) => d == day,
          occurrences: {for (final e in diet.entries) dietDay(e.day)},
          title: dates.monthTitle(shownMonth),
          onPrevious: () => setState(() => _panelMonth = DateTime(shownMonth.year, shownMonth.month - 1)),
          onNext: () => setState(() => _panelMonth = DateTime(shownMonth.year, shownMonth.month + 1)),
          onToday: () => setState(() {
            _panelMonth = null;
            _day = null;
          }),
          onPick: (d) {
            setState(() {
              _panelMonth = null;
              _day = d == today ? null : d;
            });
            if (!diary) context.go(Routes.dietOf(DietTab.diary.route));
          },
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShellTabs<DietTab>(
          selected: widget.tab,
          onSelected: (tab) => context.go(Routes.dietOf(tab.route)),
          tabs: [
            (value: DietTab.diary, label: t.dietTabDiary, icon: Icons.restaurant_menu),
            (value: DietTab.foods, label: t.dietTabFoods, icon: Icons.menu_book_outlined),
            (value: DietTab.plan, label: t.dietTabPlan, icon: Icons.event_note_outlined),
          ],
        ),
        Expanded(
          child: switch (widget.tab) {
            DietTab.diary => _diary(t, tt, diet, targets, day, today, narrow),
            DietTab.foods => _foods(t, tt, diet, taco, day, narrow),
            DietTab.plan => DietPlanView(
              diet: diet,
              targets: targets,
              today: today,
              onOpenDay: (d) {
                setState(() {
                  _panelMonth = null;
                  _day = d == today ? null : d;
                });
                context.go(Routes.dietOf(DietTab.diary.route));
              },
            ),
          },
        ),
      ],
    );

    return ModuleScaffold(
      module: AppModule.diet,
      child: ShellLayout(panel: panel, panelOpen: _panel, topBar: topBar, body: body, onCreate: create, createLabel: createLabel),
    );
  }

  Future<void> _mealMenu(DietMeal meal, Offset at) async {
    final t = AppLocalizations.of(context);
    final archived = meal.archivedAt != null;
    final diet = ref.read(dietProvider).value ?? DietSnapshot.empty;
    // A meal with something in it is archived, not deleted (see [removeMeal]).
    final used = diet.entries.any((e) => e.meal == meal.id) || diet.planItems.any((i) => i.meal == meal.id);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
        if (archived)
          PopupMenuItem(value: 'restore', height: 36, child: Text(t.menuRestore))
        else ...[
          PopupMenuItem(value: 'up', height: 36, child: Text(t.dietMoveUp)),
          PopupMenuItem(value: 'down', height: 36, child: Text(t.dietMoveDown)),
          PopupMenuItem(
            value: 'remove',
            height: 36,
            child: Text(used ? t.actionArchive : t.actionDelete, style: TextStyle(color: context.tt.overdue)),
          ),
        ],
      ],
    );
    if (!mounted) return;
    final repo = ref.read(dietRepositoryProvider);
    switch (picked) {
      case 'edit':
        await showDietMealForm(context, editing: meal);
      case 'restore':
        await repo.archiveMeal(meal.id, restore: true);
      case 'up' || 'down':
        await repo.moveMeal(meal.id, up: picked == 'up');
      case 'remove':
        await removeMeal(context, ref, meal);
    }
  }

  Future<void> _importPlan(DateTime day) async {
    final t = AppLocalizations.of(context);
    final added = await ref.read(dietRepositoryProvider).importPlan(day);
    if (mounted) showToast(context, t.dietPlanImported(added));
  }

  Widget _diary(AppLocalizations t, TtColors tt, DietSnapshot diet, DietTargets targets, DateTime day, DateTime today, bool narrow) {
    final entries = diet.entriesOn(day);
    final total = entries.map(entryNutrients).fold(Nutrients.zero, (sum, n) => sum + n);
    // A food without a value in the table: the sum is a floor.
    final incomplete = entries.any((e) => e.kcal == null || e.protein == null || e.carbs == null || e.fat == null);
    final adherence = adherenceOn(diet, targets, day, today);
    final hasPlan = diet.plan.any((i) => planItemOnWeekday(i, day));
    // The meals in use, archived ones with something eaten this day, then meals gone that entries
    // still name.
    final meals = <(String, DietMeal?)>[
      for (final m in diet.meals)
        if (m.archivedAt == null || entries.any((e) => e.meal == m.id)) (m.id, m),
    ];
    for (final e in entries) {
      if (!meals.any((m) => m.$1 == e.meal)) meals.add((e.meal, null));
    }
    final archivedCount = diet.meals.where((m) => m.archivedAt != null).length;
    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 12, narrow ? 12 : 20, 32),
      children: [
        _DayTotals(total: total, targets: targets),
        if (incomplete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.dietIncomplete,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
          ),
        if (adherence != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.dietAdherenceDay(adherenceText(adherence.score)),
              style: TextStyle(fontWeight: FontWeight.w600, color: tt.palette.green),
            ),
          ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.dietDayEmpty, style: TextStyle(color: tt.textTertiary)),
          ),
        if (hasPlan)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.playlist_add, size: 18),
                label: Text(t.dietImportPlan),
                onPressed: () => unawaited(_importPlan(day)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        for (final (id, meal) in meals) ...[
          () {
            final items = [
              for (final e in entries)
                if (e.meal == id) e,
            ];
            final kcal = items.map(entryNutrients).fold(Nutrients.zero, (sum, n) => sum + n).kcal;
            final name = mealNameOf(t, diet, id);
            return _MealHeading(
              key: ValueKey('meal-$id'),
              name: name,
              time: meal?.time,
              archived: meal?.archivedAt != null,
              kcal: items.isEmpty ? null : kcal,
              onEdit: meal == null ? null : () => unawaited(showDietMealForm(context, editing: meal)),
              onAdd: () => unawaited(showDietEntryForm(context, day: day, meal: id)),
              onMenu: meal == null ? null : (at) => unawaited(_mealMenu(meal, at)),
            );
          }(),
          for (final e in entries)
            if (e.meal == id)
              AgendaLine(
                color: tt.primary,
                title: e.name,
                subtitle: '${portionText(e.quantity, e.measureName, e.grams)} · ${macrosText(entryNutrients(e))}',
                trailing: Text(
                  '${formatKcal(entryNutrients(e).kcal)} kcal',
                  style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                ),
                onTap: () => unawaited(showDietEntryForm(context, editing: e)),
                onMenu: (at) => unawaited(_entryMenu(e, at)),
              ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(icon: const Icon(Icons.add, size: 18), label: Text(t.dietMeal), onPressed: () => unawaited(showDietMealForm(context))),
            if (archivedCount > 0)
              TextButton(onPressed: () => unawaited(showArchivedMeals(context)), child: Text(t.dietArchivedMeals(archivedCount))),
          ],
        ),
      ],
    );
  }

  Widget _foods(AppLocalizations t, TtColors tt, DietSnapshot diet, List<Food> taco, DateTime day, bool narrow) {
    final mine = diet.customFoods;
    final query = _search.text.trim();
    final results = query.isEmpty ? null : searchFoods([...mine, ...taco], query, limit: 60);
    Widget line(Food f) => AgendaLine(
      color: f.custom ? tt.palette.green : tt.primary,
      title: f.name,
      subtitle: '${f.custom ? t.dietMine : f.group} · ${macrosText(f.per100g)}',
      trailing: Text(
        t.dietPerHundred(formatKcal(f.per100g.kcal)),
        style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
      ),
      onTap: () => unawaited(showDietEntryForm(context, day: day, food: f)),
      onMenu: (at) => unawaited(_foodMenu(f, diet, day, at)),
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 12, narrow ? 12 : 20, 32),
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: t.dietSearchHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            filled: true,
            fillColor: tt.fieldFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (results == null) ...[
          BodyHeading(t.dietMyFoods),
          if (mine.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t.dietMyFoodsEmpty, style: TextStyle(color: tt.textTertiary)),
            ),
          for (final f in mine) line(f),
        ] else ...[
          const SizedBox(height: 8),
          for (final f in results) line(f),
        ],
        const SizedBox(height: 16),
        Text(
          t.dietSource,
          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
        ),
      ],
    );
  }
}

/// The macros' colors, as in the Nutri app: protein blue, carbohydrates orange, fat purple.
const _proteinColor = Color(0xFF5BC4E5);
const _carbsColor = Color(0xFFF2B866);
const _fatColor = Color(0xFFB19CE6);

/// "Totais do dia": a ring of the energy coming from protein, carbohydrates and fat (4, 4 and 9 kcal
/// per gram) with the day's calories inside, the values beside it, and each macro's share under it.
class _DayTotals extends StatelessWidget {
  const _DayTotals({required this.total, required this.targets});

  final Nutrients total;
  final DietTargets targets;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final protein = (total.protein ?? 0) * 4, carbs = (total.carbs ?? 0) * 4, fat = (total.fat ?? 0) * 9;
    final energy = protein + carbs + fat;
    String pct(double part) {
      if (energy <= 0) return '0%';
      final v = part * 100 / energy;
      return '${(v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)).replaceAll('.', ',')}%';
    }

    /// A value, with "/ target" and a bar of the way to it when there is one: green near the
    /// target, red above 110%.
    Widget row(String label, double? value, String unit, String Function(double?) format, {double? target, bool last = false}) {
      final level = target == null ? null : targetLevel(value ?? 0, target);
      final color = switch (level) {
        TargetLevel.near => tt.palette.green,
        TargetLevel.over => tt.overdue,
        _ => tt.primary,
      };
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: tt.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tt.text),
                  ),
                ),
                // "1.234 / 2.000 kcal" shrinks a bit on a phone rather than being cut.
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      target == null ? '${format(value)} $unit' : '${format(value)} / ${format(target)} $unit',
                      style: TextStyle(color: level == TargetLevel.over ? tt.overdue : tt.text, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
              ],
            ),
            if (target != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ((value ?? 0) / target).clamp(0, 1).toDouble(),
                    minHeight: 4,
                    color: color,
                    backgroundColor: tt.fieldFill,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget legend(Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
        ),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.dietDayTotals,
              style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                DonutChart(
                  size: 116,
                  parts: [(protein, _proteinColor), (carbs, _carbsColor), (fat, _fatColor)],
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatKcal(total.kcal),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tt.text),
                      ),
                      Text('KCAL', style: TextStyle(fontSize: 10, letterSpacing: 0.6, color: tt.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      row(t.dietEnergy, total.kcal, 'kcal', formatKcal, target: targets.energy),
                      row(t.dietProtein, total.protein, 'g', formatGrams, target: targets.protein),
                      row(t.dietCarbs, total.carbs, 'g', formatGrams, target: targets.carbs),
                      row(t.dietFat, total.fat, 'g', formatGrams, target: targets.fat),
                      row(t.dietFiber, total.fiber, 'g', formatGrams, last: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                legend(_proteinColor, t.dietLegendProtein(pct(protein))),
                legend(_carbsColor, t.dietLegendCarbs(pct(carbs))),
                legend(_fatColor, t.dietLegendFat(pct(fat))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A meal's heading in the diary: its name (a click edits it) and time, the calories in it, "+"
/// to add food there and ⋯ (edit, move, archive or delete).
class _MealHeading extends StatelessWidget {
  const _MealHeading({
    super.key,
    required this.name,
    required this.time,
    required this.archived,
    required this.kcal,
    required this.onAdd,
    this.onEdit,
    this.onMenu,
  });

  final String name;
  final int? time;
  final bool archived;
  final double? kcal;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final ValueChanged<Offset>? onMenu;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final small = TextStyle(fontSize: TtText.small, color: tt.textTertiary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: archived ? tt.textSecondary : tt.text),
                        ),
                      ),
                      if (time != null || archived) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            [if (time != null) mealTimeText(time!), if (archived) t.dietMealArchivedTag].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (kcal != null)
            Text(
              '${formatKcal(kcal)} kcal',
              style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
            ),
          IconButton(
            tooltip: t.dietAddTo(name),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, size: 18, color: tt.textSecondary),
            onPressed: onAdd,
          ),
          if (onMenu != null) RowMenuButton(onMenu: onMenu!),
        ],
      ),
    );
  }
}
