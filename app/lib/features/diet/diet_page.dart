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
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import '../date_picker/month_calendar.dart';
import '../shell/app_shell.dart';
import '../statistics/charts.dart' show DonutChart;
import 'diet_forms.dart';

/// Tabs of Dieta (`/diet/{tab}`).
enum DietTab {
  diary('diary'),
  foods('foods');

  const DietTab(this.route);
  final String route;

  static DietTab fromRoute(String? route) => values.where((t) => t.route == route).firstOrNull ?? diary;
}

/// Dieta in the Calendar's look: a left panel with the month (days with something eaten are marked;
/// a click opens the day), the tabs Diário and Alimentos under the top bar, and "+ Adicionar
/// alimento" (or "+ Novo alimento") at its end.
///
/// Diário: the day's calories and macros on top, then each meal with its foods (a click edits, ⋯
/// edits or deletes, "+" adds to that meal). Alimentos: the user's own foods, and a search over them
/// and the TACO table (a click adds the food to the day).
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
    final diary = widget.tab == DietTab.diary;

    void create() => unawaited(diary ? showDietEntryForm(context, day: day) : showDietFoodForm(context));
    final createLabel = diary ? t.dietAddFood : t.dietNewFood;

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
          ],
        ),
        Expanded(child: diary ? _diary(t, tt, diet, day, narrow) : _foods(t, tt, diet, taco, day, narrow)),
      ],
    );

    return ModuleScaffold(
      module: AppModule.diet,
      child: ShellLayout(panel: panel, panelOpen: _panel, topBar: topBar, body: body, onCreate: create, createLabel: createLabel),
    );
  }

  Widget _diary(AppLocalizations t, TtColors tt, DietSnapshot diet, DateTime day, bool narrow) {
    final entries = diet.entriesOn(day);
    final total = entries.map(entryNutrients).fold(Nutrients.zero, (sum, n) => sum + n);
    // A food without a value in the table: the sum is a floor.
    final incomplete = entries.any((e) => e.kcal == null || e.protein == null || e.carbs == null || e.fat == null);
    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 12, narrow ? 12 : 20, 32),
      children: [
        _DayTotals(total: total),
        if (incomplete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.dietIncomplete,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
          ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.dietDayEmpty, style: TextStyle(color: tt.textTertiary)),
          ),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        for (final meal in Meal.values) ...[
          () {
            final items = [
              for (final e in entries)
                if (e.meal == meal.code) e,
            ];
            final kcal = items.map(entryNutrients).fold(Nutrients.zero, (sum, n) => sum + n).kcal;
            return BodyHeading(
              mealLabel(t, meal),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (items.isNotEmpty)
                    Text(
                      '${formatKcal(kcal)} kcal',
                      style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                    ),
                  IconButton(
                    tooltip: t.dietAddTo(mealLabel(t, meal)),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.add, size: 18, color: tt.textSecondary),
                    onPressed: () => unawaited(showDietEntryForm(context, day: day, meal: meal)),
                  ),
                ],
              ),
            );
          }(),
          for (final e in entries)
            if (e.meal == meal.code)
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
  const _DayTotals({required this.total});

  final Nutrients total;

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

    Widget row(String label, String value, {bool last = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: tt.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: tt.text)),
          ),
          Text(
            value,
            style: TextStyle(color: tt.text, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
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
                      row(t.dietEnergy, '${formatKcal(total.kcal)} kcal'),
                      row(t.dietProtein, '${formatGrams(total.protein)} g'),
                      row(t.dietCarbs, '${formatGrams(total.carbs)} g'),
                      row(t.dietFat, '${formatGrams(total.fat)} g'),
                      row(t.dietFiber, '${formatGrams(total.fiber)} g', last: true),
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
