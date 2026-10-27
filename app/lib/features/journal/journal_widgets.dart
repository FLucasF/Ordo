import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/diet_repository.dart';
import '../../data/preferences_repository.dart';
import '../../domain/finance/money.dart';
import '../../domain/journal/day_summary.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../diet/diet_forms.dart' show formatKcal;
import '../focus/focus_page.dart' show focusRecordsProvider;

/// The five moods, worst to best, as the habits' log shows them.
const journalMoodFaces = ['😞', '🙁', '😐', '🙂', '😄'];

/// Each mood's color in the calendar: red to green.
const _moodColors = [Color(0xFFE5534B), Color(0xFFF0883E), Color(0xFFE3B341), Color(0xFF8BC34A), Color(0xFF3FB950)];

Color journalMoodColor(int mood) => _moodColors[(mood - 1).clamp(0, 4)];

String journalMoodLabel(AppLocalizations t, int mood) => switch (mood) {
  1 => t.journalMood1,
  2 => t.journalMood2,
  3 => t.journalMood3,
  4 => t.journalMood4,
  _ => t.journalMood5,
};

/// The five faces in a row: one tap picks a mood, a tap on the picked one clears it. [compact] for the
/// filters.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.isSelected, required this.onPick, this.compact = false});

  final bool Function(int mood) isSelected;
  final ValueChanged<int> onPick;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final size = compact ? 30.0 : 44.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var mood = 1; mood <= 5; mood++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: journalMoodLabel(t, mood),
              child: Semantics(
                selected: isSelected(mood),
                button: true,
                label: journalMoodLabel(t, mood),
                child: InkWell(
                  key: ValueKey('mood$mood'),
                  customBorder: const CircleBorder(),
                  onTap: () => onPick(mood),
                  child: Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected(mood) ? journalMoodColor(mood).withValues(alpha: 0.25) : null,
                      border: Border.all(color: isSelected(mood) ? journalMoodColor(mood) : tt.divider, width: isSelected(mood) ? 2 : 1),
                    ),
                    child: Text(journalMoodFaces[mood - 1], style: TextStyle(fontSize: compact ? 15 : 22)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Energy from 1 to 5 as bolts: a tap fills up to it, a tap on the current level clears it. In the
/// filters ([compact]) each level is picked on its own.
class EnergyPicker extends StatelessWidget {
  const EnergyPicker({super.key, required this.isFilled, required this.onPick, this.compact = false});

  final bool Function(int level) isFilled;
  final ValueChanged<int> onPick;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var level = 1; level <= 5; level++)
          Tooltip(
            message: t.journalEnergyLevel(level),
            child: InkWell(
              key: ValueKey('energy$level'),
              borderRadius: BorderRadius.circular(6),
              onTap: () => onPick(level),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 4, vertical: 4),
                child: compact
                    ? Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isFilled(level) ? tt.primary.withValues(alpha: 0.2) : null,
                          border: Border.all(color: isFilled(level) ? tt.primary : tt.divider),
                        ),
                        child: Text(
                          '$level',
                          style: TextStyle(fontSize: TtText.small, color: isFilled(level) ? tt.primary : tt.textSecondary),
                        ),
                      )
                    : Icon(
                        isFilled(level) ? Icons.bolt : Icons.bolt_outlined,
                        size: 30,
                        color: isFilled(level) ? const Color(0xFFF2B866) : tt.textFaint,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Resumo do dia": what the other modules say about [day], computed when shown. Each line opens its
/// module; modules turned off in Settings are left out.
class JournalSummaryCard extends ConsumerWidget {
  const JournalSummaryCard({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final snapshot = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final summary = journalDaySummary(
      day: day,
      snapshot: snapshot,
      habits: prefs.has(AppFeature.habit),
      focus: prefs.has(AppFeature.focus) ? ref.watch(focusRecordsProvider).value ?? const [] : const [],
      finance: prefs.has(AppFeature.finance) ? ref.watch(financeProvider).value : null,
      diet: prefs.has(AppFeature.diet) ? (ref.watch(dietProvider).value ?? DietSnapshot.empty).entries : const [],
      kcalTarget: prefs.has(AppFeature.diet) ? ref.watch(journalCalorieTargetProvider).value : null,
    );

    Widget line(IconData icon, String text, String route) => InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tt.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tt.text),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tt.textTertiary),
          ],
        ),
      ),
    );

    final kcal = summary.kcal, target = summary.kcalTarget;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: tt.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tt.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.journalSummary,
            style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
          ),
          Text(
            t.journalSummaryHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          const SizedBox(height: 6),
          if (summary.tasksDone > 0)
            line(Icons.check_circle_outline, t.journalSummaryTasks(summary.tasksDone), Routes.of(const SmartScope(SmartList.completed))),
          if (summary.habitsTotal > 0) line(Icons.track_changes, t.journalSummaryHabits(summary.habitsDone, summary.habitsTotal), Routes.habit),
          if (kcal != null)
            line(
              Icons.restaurant_outlined,
              target == null ? t.journalSummaryDiet(formatKcal(kcal)) : t.journalSummaryDietTarget(formatKcal(kcal), formatKcal(target)),
              Routes.diet,
            ),
          if (summary.focusMinutes > 0) line(Icons.timer_outlined, t.journalSummaryFocus(summary.focusMinutes), Routes.focus),
          if (summary.finance)
            line(
              Icons.account_balance_wallet_outlined,
              t.journalSummaryFinance(formatMoney(summary.income), formatMoney(summary.expense), formatMoney(summary.balance)),
              Routes.finance,
            ),
          if (summary.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(t.journalSummaryEmpty, style: TextStyle(color: tt.textTertiary)),
            ),
        ],
      ),
    );
  }
}

/// The month of [month] with each day tinted by its mood ([moodOf]; null = nothing told); a tap
/// opens the day.
class MoodMonth extends StatelessWidget {
  const MoodMonth({super.key, required this.month, required this.today, required this.moodOf, required this.hasEntry, required this.onPick});

  final DateTime month;
  final DateTime today;
  final int? Function(DateTime day) moodOf;
  final bool Function(DateTime day) hasEntry;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final start = startOfWeek(DateTime(month.year, month.month));
    final sundayFirst = [
      t.weekInitialSunday,
      t.weekInitialMonday,
      t.weekInitialTuesday,
      t.weekInitialWednesday,
      t.weekInitialThursday,
      t.weekInitialFriday,
      t.weekInitialSaturday,
    ];
    final weeks = (daysBetween(start, DateTime(month.year, month.month + 1)) / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (final wd in weekdayOrder())
              Expanded(
                child: Center(
                  child: Text(sundayFirst[wd % 7], style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < weeks; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = DateTime(start.year, start.month, start.day + week * 7 + d);
                      final inMonth = day.month == month.month;
                      final mood = inMonth ? moodOf(day) : null;
                      final isToday = daysBetween(day, today) == 0;
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: InkWell(
                          key: inMonth ? ValueKey('moodDay${day.day}') : null,
                          borderRadius: BorderRadius.circular(8),
                          onTap: inMonth ? () => onPick(day) : null,
                          child: Container(
                            height: narrow ? 46 : 62,
                            decoration: BoxDecoration(
                              color: mood == null ? null : journalMoodColor(mood).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isToday ? tt.primary : tt.divider, width: isToday ? 2 : 1),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: TtText.small,
                                    fontWeight: isToday ? FontWeight.w700 : null,
                                    color: inMonth ? (isToday ? tt.primary : tt.text) : tt.textFaint,
                                  ),
                                ),
                                if (inMonth && (mood != null || hasEntry(day)))
                                  Expanded(
                                    child: Center(
                                      child: FittedBox(
                                        child: Text(
                                          mood == null ? '•' : journalMoodFaces[mood - 1],
                                          style: TextStyle(fontSize: narrow ? 14 : 20, color: tt.textSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
