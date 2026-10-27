import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/habits.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../date_picker/date_picker.dart';
import '../tasks/task_actions.dart' show pickTags;
import 'habit_widgets.dart';
import '../common/emoji_picker.dart';

/// Habit sections: Manhã, Tarde, Noite, Outros.
const habitSections = ['morning', 'afternoon', 'evening', 'others'];

/// The "Adicionar Seção" entry of the section menu.
const _newSection = '\u0000new';

String habitSectionLabel(AppLocalizations t, String section) => switch (section) {
  'morning' => t.habitSectionMorning,
  'afternoon' => t.habitSectionAfternoon,
  'evening' => t.habitSectionEvening,
  'others' => t.habitSectionOthers,
  _ => section,
};

/// "Criar Hábito" / edit.
/// [preset] fills a new habit from the gallery (its emoji and name).
Future<void> showHabitForm(BuildContext context, {Habit? editing, ({String icon, String name})? preset}) => showDialog<void>(
  context: context,
  builder: (_) => _HabitForm(editing: editing, preset: preset),
);

class _HabitForm extends ConsumerStatefulWidget {
  const _HabitForm({this.editing, this.preset});

  final Habit? editing;
  final ({String icon, String name})? preset;

  @override
  ConsumerState<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends ConsumerState<_HabitForm> {
  Habit? get _h => widget.editing;
  late final _name = TextEditingController(text: _h?.name ?? widget.preset?.name ?? '');
  late final _motto = TextEditingController(text: _h?.motto ?? '');
  late final _icon = TextEditingController(text: _h?.icon ?? widget.preset?.icon ?? '');
  late final _amount = TextEditingController(text: _h == null ? '1' : _num(_h!.goalAmount));
  late final _unit = TextEditingController(text: _h?.unit ?? '');
  late final _step = TextEditingController(text: _h == null ? '1' : _num(_h!.step));
  late String? _color = _h?.color ?? presetColors[5];
  late HabitFrequency _frequency = _h?.frequency ?? HabitFrequency.daily;
  late final Set<int> _weekdays = _h == null || habitWeekdays(_h!).isEmpty ? {1, 2, 3, 4, 5, 6, 7} : habitWeekdays(_h!);
  late int _perWeek = _h?.perWeek ?? 3;
  late int _everyDays = _h?.everyDays ?? 2;
  late HabitGoal _goal = _h?.goal ?? HabitGoal.checkIn;
  late HabitCheckMode _checkMode = _h?.checkMode ?? HabitCheckMode.auto;
  late DateTime _start = _h == null ? startOfDay(ref.read(clockProvider).now()) : habitStart(_h!);
  late int? _targetDays = _h?.targetDays;
  late String _section = _h?.section ?? 'others';
  late final List<String> _reminders = _h == null ? [] : _h!.reminders.split(',').where((r) => r.isNotEmpty).toList();
  late bool _autoLog = _h?.autoShowLog ?? false;
  late final Set<String> _tags = _h == null ? {} : habitTagIds(_h!);

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    for (final c in [_name, _motto, _icon, _amount, _unit, _step]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    double number(TextEditingController c, double fallback) {
      final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
      return v == null || v <= 0 ? fallback : v;
    }

    final companion = HabitsCompanion(
      name: Value(name),
      motto: Value(_motto.text.trim()),
      icon: Value(_icon.text.trim().characters.take(1).toString()),
      color: Value(_color),
      frequency: Value(_frequency),
      weekdays: Value(_weekdays.length == 7 ? '' : (_weekdays.toList()..sort()).join(',')),
      perWeek: Value(_perWeek),
      everyDays: Value(_everyDays),
      goal: Value(_goal),
      goalAmount: Value(_goal == HabitGoal.amount ? number(_amount, 1) : 1),
      unit: Value(_unit.text.trim()),
      checkMode: Value(_checkMode),
      step: Value(number(_step, 1)),
      startDate: Value(_start),
      targetDays: Value(_targetDays),
      section: Value(_section),
      reminders: Value(_reminders.join(',')),
      autoShowLog: Value(_autoLog),
      tags: Value(_tags.join(',')),
    );
    final repo = ref.read(repositoryProvider);
    final editing = _h;
    if (editing == null) {
      await repo.createHabit(companion);
    } else {
      await repo.updateHabit(editing.id, companion);
    }
    if (mounted) Navigator.pop(context);
  }

  /// Phones: the label goes above its field, which gets the whole width.
  bool get _compact => MediaQuery.sizeOf(context).width < 600;

  Widget _row(String label, Widget child) {
    final text = Text(
      label,
      style: TextStyle(color: context.tt.textSecondary, fontSize: TtText.body),
    );
    if (_compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 6), child]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Padding(padding: const EdgeInsets.only(top: 10), child: text),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }

  /// One choice among a few: segments on a wide screen, chips that wrap on a phone.
  Widget _choice<T>(List<(T, String)> options, T selected, ValueChanged<T> onChanged) {
    if (_compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final (value, label) in options)
            ChoiceChip(label: Text(label), selected: value == selected, showCheckmark: false, onSelected: (_) => onChanged(value)),
        ],
      );
    }
    return SegmentedButton<T>(
      segments: [for (final (value, label) in options) ButtonSegment(value: value, label: Text(label))],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (v) => onChanged(v.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Sunday first, as the rest of the app.
    const order = [7, 1, 2, 3, 4, 5, 6];
    final initials = {
      7: t.weekInitialSunday,
      1: t.weekInitialMonday,
      2: t.weekInitialTuesday,
      3: t.weekInitialWednesday,
      4: t.weekInitialThursday,
      5: t.weekInitialFriday,
      6: t.weekInitialSaturday,
    };
    String two(int n) => n.toString().padLeft(2, '0');

    return AlertDialog(
      title: Text(_h == null ? t.habitNew : t.habitEditTitle, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // The habit's emoji, picked from all of them like a list's icon ("Redefinir" removes it).
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showEmojiPicker(context);
                      if (picked != null) setState(() => _icon.text = picked);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: context.tt.fieldFill, borderRadius: BorderRadius.circular(8)),
                      child: _icon.text.isEmpty
                          ? Icon(Icons.add_reaction_outlined, color: context.tt.textTertiary)
                          : Text(_icon.text, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      autofocus: true,
                      decoration: InputDecoration(hintText: t.habitNameHint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  HabitColorButton(color: _color, onChanged: (c) => setState(() => _color = c)),
                ],
              ),
              TextField(
                controller: _motto,
                decoration: InputDecoration(hintText: t.habitMottoHint, isDense: true),
              ),
              const SizedBox(height: 8),
              _row(
                t.habitFrequency,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _choice(
                      [(HabitFrequency.daily, t.habitDaily), (HabitFrequency.weekly, t.habitWeekly), (HabitFrequency.interval, t.habitInterval)],
                      _frequency,
                      (v) => setState(() => _frequency = v),
                    ),
                    const SizedBox(height: 8),
                    switch (_frequency) {
                      HabitFrequency.daily => Wrap(
                        spacing: 4,
                        children: [
                          for (final d in order)
                            FilterChip(
                              label: Text(initials[d]!),
                              selected: _weekdays.contains(d),
                              showCheckmark: false,
                              onSelected: (on) => setState(() {
                                if (on) {
                                  _weekdays.add(d);
                                } else if (_weekdays.length > 1) {
                                  _weekdays.remove(d);
                                }
                              }),
                            ),
                        ],
                      ),
                      HabitFrequency.weekly => DropdownButton<int>(
                        value: _perWeek,
                        items: [for (var n = 1; n <= 6; n++) DropdownMenuItem(value: n, child: Text(t.habitTimesPerWeek(n)))],
                        onChanged: (v) => setState(() => _perWeek = v ?? _perWeek),
                      ),
                      HabitFrequency.interval => DropdownButton<int>(
                        value: _everyDays,
                        items: [for (var n = 2; n <= 30; n++) DropdownMenuItem(value: n, child: Text(t.habitEveryDays(n)))],
                        onChanged: (v) => setState(() => _everyDays = v ?? _everyDays),
                      ),
                    },
                  ],
                ),
              ),
              _row(
                t.habitGoal,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _choice([(HabitGoal.checkIn, t.habitGoalAll), (HabitGoal.amount, t.habitGoalAmount)], _goal, (v) => setState(() => _goal = v)),
                    if (_goal == HabitGoal.amount) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${t.habitPerDay} '),
                          SizedBox(
                            width: 60,
                            child: TextField(controller: _amount, keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _unit,
                              decoration: InputDecoration(hintText: t.habitUnitDefault),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('${t.habitCheckMode} '),
                          DropdownButton<HabitCheckMode>(
                            value: _checkMode,
                            items: [
                              DropdownMenuItem(value: HabitCheckMode.auto, child: Text(t.habitCheckAuto)),
                              DropdownMenuItem(value: HabitCheckMode.manual, child: Text(t.habitCheckManual)),
                              DropdownMenuItem(value: HabitCheckMode.completeAll, child: Text(t.habitCheckAll)),
                            ],
                            onChanged: (v) => setState(() => _checkMode = v ?? _checkMode),
                          ),
                        ],
                      ),
                      if (_checkMode == HabitCheckMode.auto)
                        Row(
                          children: [
                            Text('${t.habitStep} '),
                            SizedBox(
                              width: 60,
                              child: TextField(controller: _step, keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
              _row(
                t.habitStartDate,
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _start = picked);
                  },
                  child: Text('${_start.day} ${DateLabels(t).monthLong(_start)} ${_start.year}'),
                ),
              ),
              _row(
                t.habitTargetDays,
                DropdownButton<int?>(
                  value: _targetDays,
                  items: [
                    DropdownMenuItem(child: Text(t.habitForever)),
                    for (final n in {7, 21, 30, 100, 365, ?_targetDays}) DropdownMenuItem(value: n, child: Text(t.habitDaysValue(n))),
                    DropdownMenuItem(value: -1, child: Text(t.repeatCustom)),
                  ],
                  onChanged: (v) async {
                    if (v == -1) {
                      final text = await promptText(context, title: t.habitTargetDays, initial: '60');
                      final n = int.tryParse(text?.trim() ?? '');
                      if (n != null && n > 0) setState(() => _targetDays = n);
                    } else {
                      setState(() => _targetDays = v);
                    }
                  },
                ),
              ),
              _row(
                t.habitSection,
                DropdownButton<String>(
                  value: _section,
                  items: [
                    for (final s in {
                      ...habitSections,
                      // Sections made with "Adicionar Seção".
                      for (final h in ref.watch(snapshotProvider).value?.habits ?? const <Habit>[])
                        if (h.deletedAt == null) h.section,
                      _section,
                    })
                      DropdownMenuItem(value: s, child: Text(habitSectionLabel(t, s))),
                    DropdownMenuItem(value: _newSection, child: Text('+ ${t.habitAddSection}')),
                  ],
                  onChanged: (v) async {
                    if (v != _newSection) return setState(() => _section = v ?? _section);
                    final name = await promptText(context, title: t.habitAddSection, hint: t.sectionNew);
                    if (name != null && name.trim().isNotEmpty) setState(() => _section = name.trim());
                  },
                ),
              ),
              // The tasks' tags: chips (× takes one off) and "+" to pick or create.
              _row(
                t.menuTags,
                Builder(
                  builder: (context) {
                    final tagById = ref.watch(snapshotProvider).value?.tagById ?? const <String, Tag>{};
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final id in _tags)
                          if (tagById[id] case final tag? when tag.deletedAt == null)
                            InputChip(
                              label: Text(tag.name),
                              backgroundColor: (parseHexColor(tag.color) ?? context.tt.textTertiary).withValues(alpha: 0.2),
                              side: BorderSide.none,
                              onDeleted: () => setState(() => _tags.remove(id)),
                            ),
                        ActionChip(
                          key: const ValueKey('habitTags'),
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(t.detailAddTag),
                          onPressed: () async {
                            final picked = await pickTags(context, ref, initial: _tags);
                            if (picked != null) {
                              setState(() => _tags
                                ..clear()
                                ..addAll(picked));
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              _row(
                t.habitReminder,
                Wrap(
                  spacing: 6,
                  children: [
                    for (final r in _reminders) InputChip(label: Text(r), onDeleted: () => setState(() => _reminders.remove(r))),
                    if (_reminders.length < 10)
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(t.habitReminder),
                        onPressed: () async {
                          final time = await showTimeDialog(context, initial: const TimeOfDay(hour: 18, minute: 0));
                          if (time != null) setState(() => _reminders.add('${two(time.hour)}:${two(time.minute)}'));
                        },
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.habitAutoLog),
                value: _autoLog,
                onChanged: (v) => setState(() => _autoLog = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_h case final h?) ...[
          IconButton(
            tooltip: t.habitDelete,
            icon: Icon(Icons.delete_outline, color: context.tt.overdue),
            onPressed: () => unawaited(deleteHabitAsking(context, ref.read(repositoryProvider), h, close: () => Navigator.pop(context))),
          ),
          TextButton(onPressed: () => unawaited(_archive(h)), child: Text(t.habitArchive)),
        ],
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => unawaited(_save()), child: Text(t.actionSave)),
      ],
    );
  }

  Future<void> _archive(Habit h) async {
    final t = AppLocalizations.of(context);
    await ref.read(repositoryProvider).archiveHabit(h.id, archived: true);
    if (!mounted) return;
    final page = Navigator.of(context).context;
    Navigator.pop(context);
    if (page.mounted) showToast(page, t.toastArchived);
  }
}
