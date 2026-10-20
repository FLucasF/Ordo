import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
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
import '../finance/finance_widgets.dart' show FinChip;
import 'diet_forms.dart';

/// "34%", or "—" when nothing counts.
String adherenceText(double? score) => score == null ? '—' : '${(score * 100).round()}%';

/// The adherence of [day] (see [dayAdherence]) from the snapshot and the calorie target.
DayAdherence? adherenceOn(DietSnapshot diet, DietTargets targets, DateTime day, DateTime today, [Map<DateTime, List<DietEntry>>? byDay]) =>
    dayAdherence(day: day, today: today, planItems: diet.planItems, entries: byDay?[day] ?? diet.entriesOn(day), kcalTarget: targets.energy);

/// The "Plano" tab: how well the plan is kept (the last 7 days, the month, and the month as a heat
/// map; a day opens it in the diary), then the plan meal by meal, all of it or a weekday's.
class DietPlanView extends ConsumerStatefulWidget {
  const DietPlanView({super.key, required this.diet, required this.targets, required this.today, required this.onOpenDay});

  final DietSnapshot diet;
  final DietTargets targets;
  final DateTime today;
  final ValueChanged<DateTime> onOpenDay;

  @override
  ConsumerState<DietPlanView> createState() => _DietPlanViewState();
}

class _DietPlanViewState extends ConsumerState<DietPlanView> {
  /// The weekday shown (0 = all items); today's to begin with.
  int? _weekday;
  DateTime? _month;

  Future<void> _itemMenu(DietPlanItem item, Offset at) async {
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
        await showDietPlanItemForm(context, editing: item);
      case 'delete':
        final repo = ref.read(dietRepositoryProvider);
        await repo.deletePlanItem(item.id);
        if (mounted) {
          showToast(
            context,
            t.dietPlanItemDeleted,
            undo: () => repo.deletePlanItem(item.id, restore: true),
            redo: () => repo.deletePlanItem(item.id),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final diet = widget.diet;
    final weekday = _weekday ?? widget.today.weekday;
    final plan = diet.plan;
    final shown = [
      for (final i in plan)
        if (weekday == 0 || planItemOnWeekday(i, weekdayDate(weekday))) i,
    ];
    // The meals in use, then archived or gone ones that still have items.
    final mealIds = [
      for (final m in diet.meals)
        if (m.archivedAt == null || plan.any((i) => i.meal == m.id)) m.id,
    ];
    for (final i in plan) {
      if (!mealIds.contains(i.meal)) mealIds.add(i.meal);
    }
    final total = shown.map(planItemNutrients).fold(Nutrients.zero, (sum, n) => sum + n);
    final labels = DateLabels(t);

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 12, narrow ? 12 : 20, 32),
      children: [
        _Adherence(
          diet: diet,
          targets: widget.targets,
          today: widget.today,
          month: _month ?? DateTime(widget.today.year, widget.today.month),
          onMonth: (m) => setState(() => _month = m),
          onOpenDay: widget.onOpenDay,
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: tt.divider),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FinChip(label: t.dietPlanAll, selected: weekday == 0, onTap: () => setState(() => _weekday = 0)),
            for (final wd in weekdayOrder())
              FinChip(label: labels.weekdayShort(weekdayDate(wd)), selected: weekday == wd, onTap: () => setState(() => _weekday = wd)),
          ],
        ),
        if (weekday != 0 && shown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${t.dietPlanTotal}: ${formatKcal(total.kcal)} kcal · ${macrosText(total)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
            ),
          ),
        if (plan.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(t.dietPlanEmpty, style: TextStyle(color: tt.textTertiary)),
          ),
        for (final id in mealIds) ...[
          BodyHeading(
            mealNameOf(t, diet, id),
            trailing: IconButton(
              tooltip: t.dietAddTo(mealNameOf(t, diet, id)),
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.add, size: 18, color: tt.textSecondary),
              onPressed: () => unawaited(showDietPlanItemForm(context, meal: id)),
            ),
          ),
          for (final i in shown)
            if (i.meal == id)
              AgendaLine(
                color: tt.palette.green,
                title: i.name,
                subtitle: [portionText(i.quantity, i.measureName, i.grams), if (i.weekdays.isNotEmpty) weekdaysText(t, i.weekdays)].join(' · '),
                trailing: Text(
                  '${formatKcal(planItemNutrients(i).kcal)} kcal',
                  style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                ),
                onTap: () => unawaited(showDietPlanItemForm(context, editing: i)),
                onMenu: (at) => unawaited(_itemMenu(i, at)),
              ),
        ],
      ],
    );
  }
}

/// "Adesão": the last 7 days' and the month's means, and the month as a heat map (a stronger green
/// is a more disciplined day; grey days don't count).
class _Adherence extends StatelessWidget {
  const _Adherence({
    required this.diet,
    required this.targets,
    required this.today,
    required this.month,
    required this.onMonth,
    required this.onOpenDay,
  });

  final DietSnapshot diet;
  final DietTargets targets;
  final DateTime today;
  final DateTime month;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final byDay = <DateTime, List<DietEntry>>{};
    for (final e in diet.entries) {
      (byDay[dietDay(e.day)] ??= []).add(e);
    }
    DayAdherence? on(DateTime d) => adherenceOn(diet, targets, d, today, byDay);
    final week = meanAdherence([for (var i = 0; i < 7; i++) on(DateTime(today.year, today.month, today.day - i))]);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final scores = {for (var d = 1; d <= days; d++) d: on(DateTime(month.year, month.month, d))};
    final green = tt.palette.green;
    Color heat(double? score) => score == null ? tt.fieldFill : Color.lerp(green.withValues(alpha: 0.15), green, score)!;
    final lead = (DateTime(month.year, month.month).weekday - weekdayOrder().first + 7) % 7;
    final cells = [...List<int?>.filled(lead, null), for (var d = 1; d <= days; d++) d];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t.dietAdherence,
                  style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: t.dietAdherenceHelp,
                  child: Icon(Icons.info_outline, size: 16, color: tt.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FigureStrip(
              figures: [
                (label: t.dietAdherenceWeek, value: adherenceText(week), color: null, hint: null),
                (label: labels.monthTitle(month), value: adherenceText(meanAdherence(scores.values)), color: null, hint: null),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    labels.monthTitle(month),
                    style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.chevron_left, color: tt.textSecondary),
                  onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.chevron_right, color: tt.textSecondary),
                  onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
                ),
              ],
            ),
            Row(
              children: [
                for (final wd in weekdayOrder())
                  Expanded(
                    child: Center(
                      child: Text(
                        labels.weekdayShort(weekdayDate(wd)),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(fontSize: 11, color: tt.textTertiary),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var row = 0; row < cells.length ~/ 7; row++)
              Row(
                children: [
                  for (final d in cells.sublist(row * 7, row * 7 + 7))
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: d == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.all(2),
                                child: Tooltip(
                                  message: adherenceText(scores[d]?.score),
                                  child: InkWell(
                                    key: ValueKey('adherence-$d'),
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () => onOpenDay(DateTime(month.year, month.month, d)),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: heat(scores[d]?.score),
                                        borderRadius: BorderRadius.circular(4),
                                        border: DateTime(month.year, month.month, d) == today ? Border.all(color: tt.primary, width: 1.5) : null,
                                      ),
                                      child: Text(
                                        '$d',
                                        style: TextStyle(fontSize: 11, color: (scores[d]?.score ?? 0) > 0.55 ? Colors.white : tt.textSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(t.dietAdherenceLess, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                const SizedBox(width: 4),
                for (final s in [0.0, 0.25, 0.5, 0.75, 1.0])
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: heat(s), borderRadius: BorderRadius.circular(2)),
                  ),
                const SizedBox(width: 4),
                Text(t.dietAdherenceMore, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
