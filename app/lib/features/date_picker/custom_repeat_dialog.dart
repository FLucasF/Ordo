import 'package:flutter/material.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/custom_repeat.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations.dart';
import 'month_calendar.dart';

/// "Personalizado" repetition: by due date, by completion or on specific dates; every N
/// days/weeks/months/years; weekdays; monthly "Cada" / "No" / "Dia útil"; yearly "Cada" / "No".
/// Returns the rule without its end ("A repetição termina" is kept by the caller).
Future<({String rule, RepeatFrom from})?> showCustomRepeatDialog(
  BuildContext context, {
  required String? rule,
  required RepeatFrom from,
  required DateTime day,
  required DateTime now,
}) => showDialog<({String rule, RepeatFrom from})>(
  context: context,
  builder: (_) => _CustomRepeatDialog(draft: CustomRepeatDraft.fromRule(rule, from, day), now: now),
);

class _CustomRepeatDialog extends StatefulWidget {
  const _CustomRepeatDialog({required this.draft, required this.now});

  final CustomRepeatDraft draft;
  final DateTime now;

  @override
  State<_CustomRepeatDialog> createState() => _CustomRepeatDialogState();
}

class _CustomRepeatDialogState extends State<_CustomRepeatDialog> {
  late final CustomRepeatDraft _d = widget.draft;
  late final _interval = TextEditingController(text: '${_d.interval}');
  late DateTime _month = DateTime(widget.now.year, widget.now.month);

  @override
  void dispose() {
    _interval.dispose();
    super.dispose();
  }

  void _update(void Function() change) => setState(change);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final rule = _d.toRule();
    final small = TextStyle(color: tt.textSecondary, fontSize: TtText.body);

    // Sunday first, as in the calendar (D S T Q Q S S).
    final weekOrder = weekdayOrder();
    final weekdayNames = {for (final wd in weekOrder) wd: labels.weekday(DateTime(2026, 9, 20 + wd % 7))};
    final ordinals = {1: t.ordinalFirst, 2: t.ordinalSecond, 3: t.ordinalThird, 4: t.ordinalFourth, -1: t.ordinalLast};
    final months = {for (var m = 1; m <= 12; m++) m: labels.monthLong(DateTime(2026, m))};

    Widget dropdown<T>(T value, Map<T, String> items, void Function(T) onChanged) => DropdownButton<T>(
      value: value,
      isDense: true,
      items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
      onChanged: (v) {
        if (v != null) _update(() => onChanged(v));
      },
    );

    Widget chip(String label, {required bool selected, required VoidCallback onTap, double width = 40, double height = 30}) => InkWell(
      onTap: () => _update(onTap),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? tt.primary : tt.fieldFill, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : tt.text)),
      ),
    );

    Widget segments(List<(MonthlyKind, String)> options) => SegmentedButton<MonthlyKind>(
      segments: [
        for (final (kind, label) in options)
          ButtonSegment(
            value: kind,
            label: Text(label, style: const TextStyle(fontSize: 12)),
          ),
      ],
      selected: {options.any((o) => o.$1 == _d.monthlyKind) ? _d.monthlyKind : options.first.$1},
      showSelectedIcon: false,
      onSelectionChanged: (s) => _update(() => _d.monthlyKind = s.first),
    );

    final units = {
      RepeatUnit.day: t.unitDay,
      RepeatUnit.week: t.unitWeek,
      RepeatUnit.month: t.unitMonth,
      if (_d.mode != RepeatBasis.completion) RepeatUnit.year: t.unitYear,
    };
    if (!units.containsKey(_d.unit)) _d.unit = RepeatUnit.month;
    final byDueDate = _d.mode == RepeatBasis.dueDate;

    return AlertDialog(
      title: Text(t.repeatCustom, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<RepeatBasis>(
                value: _d.mode,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: RepeatBasis.dueDate, child: Text(t.repeatFromDue)),
                  DropdownMenuItem(value: RepeatBasis.completion, child: Text(t.repeatFromCompletion)),
                  DropdownMenuItem(value: RepeatBasis.specificDates, child: Text(t.repeatSpecificDates)),
                ],
                onChanged: (v) => _update(() => _d.mode = v ?? RepeatBasis.dueDate),
              ),
              const SizedBox(height: 12),
              if (_d.mode == RepeatBasis.specificDates) ...[
                Text(
                  t.repeatPickDates,
                  style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
                ),
                MonthCalendar(
                  month: _month,
                  today: startOfDay(widget.now),
                  isSelected: _d.dates.contains,
                  occurrences: const {},
                  title: labels.monthTitle(_month),
                  onPrevious: () => _update(() => _month = DateTime(_month.year, _month.month - 1)),
                  onNext: () => _update(() => _month = DateTime(_month.year, _month.month + 1)),
                  onToday: () => _update(() => _month = DateTime(widget.now.year, widget.now.month)),
                  onPick: (day) => _update(() => _d.dates.contains(day) ? _d.dates.remove(day) : _d.dates.add(day)),
                ),
              ] else ...[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Text(t.repeatEvery, style: small),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _interval,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (v) => _update(() => _d.interval = int.tryParse(v.trim()) ?? 1),
                      ),
                    ),
                    dropdown(_d.unit, units, (u) => _d.unit = u),
                  ],
                ),
                const SizedBox(height: 12),
                // The days of the week, also with "dia": picking one makes it weekly on the days picked.
                if (byDueDate && (_d.unit == RepeatUnit.week || _d.unit == RepeatUnit.day)) ...[
                  Row(
                    children: [
                      for (final wd in weekOrder)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: chip(
                              labels.weekdayShort(DateTime(2026, 9, 20 + wd % 7)),
                              width: double.infinity,
                              height: 40,
                              selected: _d.unit == RepeatUnit.week && _d.weekdays.contains(wd),
                              onTap: () {
                                if (_d.unit != RepeatUnit.week) {
                                  _d
                                    ..unit = RepeatUnit.week
                                    ..weekdays = {wd};
                                } else if (_d.weekdays.contains(wd)) {
                                  // At least one day stays picked.
                                  if (_d.weekdays.length > 1) _d.weekdays.remove(wd);
                                } else {
                                  _d.weekdays.add(wd);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final (label, days) in [
                        (t.repeatPickWorkdays, {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday}),
                        (t.repeatPickWeekend, {DateTime.saturday, DateTime.sunday}),
                        (t.repeatPickAllDays, {for (var d = 1; d <= 7; d++) d}),
                      ])
                        ActionChip(
                          label: Text(label, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _update(() {
                            _d
                              ..unit = RepeatUnit.week
                              ..weekdays = {...days};
                          }),
                        ),
                    ],
                  ),
                ],
                if (byDueDate && _d.unit == RepeatUnit.month) ...[
                  segments([
                    (MonthlyKind.each, t.repeatMonthEach),
                    (MonthlyKind.onWeekday, t.repeatMonthOn),
                    (MonthlyKind.workday, t.repeatMonthWorkday),
                  ]),
                  const SizedBox(height: 10),
                  switch (_d.monthlyKind) {
                    MonthlyKind.each => Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (var day = 1; day <= 31; day++)
                          chip(
                            '$day',
                            selected: _d.monthDays.contains(day),
                            onTap: () => _d.monthDays.contains(day) ? _d.monthDays.remove(day) : _d.monthDays.add(day),
                          ),
                        chip(
                          t.repeatLastDay,
                          width: 128,
                          selected: _d.monthDays.contains(-1),
                          onTap: () => _d.monthDays.contains(-1) ? _d.monthDays.remove(-1) : _d.monthDays.add(-1),
                        ),
                      ],
                    ),
                    MonthlyKind.onWeekday => Wrap(
                      spacing: 12,
                      children: [dropdown(_d.ordinal, ordinals, (o) => _d.ordinal = o), dropdown(_d.weekday, weekdayNames, (w) => _d.weekday = w)],
                    ),
                    MonthlyKind.workday => dropdown(_d.firstWorkday, {true: t.workdayFirst, false: t.workdayLast}, (v) => _d.firstWorkday = v),
                  },
                ],
                if (_d.canSkipWeekends)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(t.repeatSkipWeekends),
                    value: _d.skipWeekends,
                    onChanged: (v) => _update(() => _d.skipWeekends = v ?? false),
                  ),
                if (byDueDate && _d.unit == RepeatUnit.year) ...[
                  segments([(MonthlyKind.each, t.repeatMonthEach), (MonthlyKind.onWeekday, t.repeatMonthOn)]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      dropdown(_d.month, months, (m) => _d.month = m),
                      if (_d.monthlyKind == MonthlyKind.onWeekday) ...[
                        dropdown(_d.ordinal, ordinals, (o) => _d.ordinal = o),
                        dropdown(_d.weekday, weekdayNames, (w) => _d.weekday = w),
                      ] else
                        dropdown(_d.monthDay, {for (var d = 1; d <= 31; d++) d: '$d'}, (d) => _d.monthDay = d),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: rule == null ? null : () => Navigator.pop(context, (rule: rule, from: _d.repeatFrom)), child: Text(t.actionOk)),
      ],
    );
  }
}
