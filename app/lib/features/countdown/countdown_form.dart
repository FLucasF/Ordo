import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/repository.dart';
import '../../domain/countdown.dart';
import '../../domain/enums.dart';
import '../../domain/recurrence.dart';
import '../../domain/reminders.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../date_picker/custom_repeat_dialog.dart';
import '../date_picker/date_picker.dart';
import '../habits/habit_form.dart' show habitSectionLabel;
import 'countdown_card.dart';

String countdownTypeLabel(AppLocalizations t, CountdownType type) => switch (type) {
  CountdownType.countdown => t.countdownTypeCountdown,
  CountdownType.specialDay => t.countdownTypeSpecial,
  CountdownType.birthday => t.countdownTypeBirthday,
  CountdownType.holiday => t.countdownTypeHoliday,
};

/// New countdown: the data, "Próximo", then the style; editing is one step with "Salvar"
/// (§26.12).
Future<void> showCountdownForm(BuildContext context, {required CountdownType type, Countdown? editing}) => showDialog<void>(
  context: context,
  builder: (_) => _CountdownForm(type: type, editing: editing),
);

/// Deletes a countdown, after asking (it can't be undone). [close] runs just before (the form closing
/// itself).
Future<void> deleteCountdownAsking(BuildContext context, Repository repo, Countdown countdown, {VoidCallback? close}) async {
  final t = AppLocalizations.of(context);
  if (!await confirm(context, message: t.countdownDeleteConfirm(countdown.name), confirmLabel: t.countdownDelete)) return;
  close?.call();
  await repo.deleteCountdown(countdown.id);
}

class _CountdownForm extends ConsumerStatefulWidget {
  const _CountdownForm({required this.type, this.editing});

  final CountdownType type;
  final Countdown? editing;

  @override
  ConsumerState<_CountdownForm> createState() => _CountdownFormState();
}

class _CountdownFormState extends ConsumerState<_CountdownForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late CountdownType _type = widget.editing?.type ?? widget.type;
  late DateTime _date = widget.editing == null ? startOfDay(ref.read(clockProvider).now()) : countdownDate(widget.editing!);
  // Default reminders: "No dia, 3 dias antes".
  late final Set<String> _reminders = widget.editing == null
      ? {ReminderPresets.onTheDay, ReminderPresets.threeDaysBeforeAt9}
      : widget.editing!.reminders.split(',').where((r) => r.isNotEmpty).toSet();
  late String? _rule = widget.editing?.repeatRule ?? (_yearlyByDefault ? _yearly(_date) : null);
  late CountMode _mode = widget.editing?.countMode ?? CountMode.standard;
  late bool _countUp = widget.editing?.countUp ?? false;
  late CountdownVisibility _visibility = widget.editing?.visibility ?? CountdownVisibility.onTheDay;
  late bool _ignoreYear = widget.editing?.ignoreYear ?? false;
  late bool _showAge = widget.editing?.showAge ?? false;
  bool _styleStep = false;
  int _style = 0;
  String? _color;

  /// "Vincular a uma lista ou área": the project it counts down to (one of the two, or none).
  late String? _listId = widget.editing?.listId;
  late String? _folderId = widget.editing?.folderId;

  /// "Seguir a sequência de": a habit, or a habit section, whose days in a row it counts toward
  /// [_goalDays] instead of a date.
  late String? _habitId = widget.editing?.habitId;
  late String? _habitSection = widget.editing?.habitSection;
  late int _goalDays = widget.editing?.goalDays ?? 30;

  bool get _followsHabit => _habitId != null || _habitSection != null;

  bool get _hasDirection => _type == CountdownType.birthday || _type == CountdownType.specialDay;

  /// Only the types with a "Modo de Contagem" count up.
  bool get _countsUp => _hasDirection && _countUp;

  bool get _yearlyByDefault => widget.type == CountdownType.birthday || widget.type == CountdownType.holiday;

  static String _yearly(DateTime d) => 'FREQ=YEARLY;INTERVAL=1;BYMONTH=${d.month};BYMONTHDAY=${d.day}';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// "Ícone" and "Imagem de fundo".
  String? _icon;
  String? _iconColor;
  String? _image;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (_followsHabit) {
      _reminders.clear();
      _rule = null;
      _listId = null;
      _folderId = null;
    }
    final repo = ref.read(repositoryProvider);
    final editing = widget.editing;
    if (editing != null) {
      await repo.updateCountdown(
        editing.id,
        name: name,
        date: _date,
        type: _type,
        countMode: _mode,
        countUp: _countsUp,
        ignoreYear: _ignoreYear,
        showAge: _showAge,
        reminders: _reminders,
        repeatRule: _rule,
        visibility: _visibility,
        listId: Value(_listId),
        folderId: Value(_folderId),
        habitId: Value(_habitId),
        habitSection: Value(_habitSection),
        goalDays: Value(_followsHabit ? _goalDays : null),
      );
    } else {
      await repo.createCountdown(
        name: name,
        date: _date,
        type: _type,
        countMode: _mode,
        countUp: _countsUp,
        ignoreYear: _ignoreYear,
        showAge: _showAge,
        reminders: _reminders,
        repeatRule: _rule,
        visibility: _visibility,
        style: _style,
        color: _color,
        icon: _icon,
        iconColor: _iconColor,
        image: _image,
        listId: _listId,
        folderId: _folderId,
        habitId: _habitId,
        habitSection: _habitSection,
        goalDays: _followsHabit ? _goalDays : null,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  /// "Seguir a sequência de": none, the habits, then the habit sections. The value is `h:id` or
  /// `s:section`; '' for none.
  Widget _followField(AppLocalizations t) {
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final habits = [
      for (final h in s.habits)
        if (h.deletedAt == null && h.archivedAt == null) h,
    ];
    final value = _habitId != null ? 'h:$_habitId' : (_habitSection != null ? 's:$_habitSection' : '');
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(t.countdownFollowNone)),
      for (final h in habits)
        DropdownMenuItem(
          value: 'h:${h.id}',
          child: Text('${h.icon.isEmpty ? '' : '${h.icon} '}${h.name}', overflow: TextOverflow.ellipsis),
        ),
      for (final section in {for (final h in habits) h.section})
        DropdownMenuItem(
          value: 's:$section',
          child: Text(t.countdownFollowSection(habitSectionLabel(t, section)), overflow: TextOverflow.ellipsis),
        ),
    ];
    return DropdownButton<String>(
      key: const ValueKey('countdownFollow'),
      // A habit that is gone reads as none.
      value: items.any((i) => i.value == value) ? value : '',
      isExpanded: true,
      items: items,
      onChanged: (v) => setState(() {
        _habitId = v != null && v.startsWith('h:') ? v.substring(2) : null;
        _habitSection = v != null && v.startsWith('s:') ? v.substring(2) : null;
      }),
    );
  }

  /// "Meta (dias seguidos)": the usual goals, and any other typed.
  Widget _goalField(AppLocalizations t) => DropdownButton<int>(
    value: _goalDays,
    items: [
      for (final n in {7, 21, 30, 60, 90, 100, 365, _goalDays}) DropdownMenuItem(value: n, child: Text(t.habitDaysValue(n))),
      DropdownMenuItem(value: -1, child: Text(t.repeatCustom)),
    ],
    onChanged: (v) async {
      if (v != -1) return setState(() => _goalDays = v ?? _goalDays);
      final text = await promptText(context, title: t.countdownGoalDays, initial: '$_goalDays');
      final n = int.tryParse(text?.trim() ?? '');
      if (n != null && n > 0) setState(() => _goalDays = n);
    },
  );

  /// "Vincular a uma lista ou área": none, the areas, then the lists (sublists indented). The value is
  /// `f:id` or `l:id`; '' for none.
  Widget _linkField(AppLocalizations t) {
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final value = _listId != null ? 'l:$_listId' : (_folderId != null ? 'f:$_folderId' : '');
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(t.countdownLinkNone)),
      for (final f in s.activeFolders)
        DropdownMenuItem(
          value: 'f:${f.id}',
          child: Text(t.countdownLinkArea(f.name), overflow: TextOverflow.ellipsis),
        ),
      for (final (l, depth) in s.listTree(s.activeLists))
        DropdownMenuItem(
          value: 'l:${l.id}',
          child: Padding(
            padding: EdgeInsets.only(left: 16.0 * depth),
            child: Text('${l.emoji == null ? '' : '${l.emoji} '}${Labels(t).listName(l)}', overflow: TextOverflow.ellipsis),
          ),
        ),
    ];
    return DropdownButton<String>(
      // A project that is gone reads as none.
      value: items.any((i) => i.value == value) ? value : '',
      isExpanded: true,
      items: items,
      onChanged: (v) => setState(() {
        _listId = v != null && v.startsWith('l:') ? v.substring(2) : null;
        _folderId = v != null && v.startsWith('f:') ? v.substring(2) : null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_styleStep ? t.countdownStyle : countdownTypeLabel(t, _type), style: const TextStyle(fontSize: 15)),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: _styleStep ? _styleContent(t) : _dataContent(t))),
      actions: [
        if (widget.editing case final c?)
          IconButton(
            tooltip: t.countdownDelete,
            icon: Icon(Icons.delete_outline, color: context.tt.overdue),
            onPressed: () => unawaited(deleteCountdownAsking(context, ref.read(repositoryProvider), c, close: () => Navigator.pop(context))),
          ),
        if (_styleStep)
          TextButton(onPressed: () => setState(() => _styleStep = false), child: Text(t.actionBack))
        else
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        if (widget.editing != null || _styleStep)
          FilledButton(onPressed: () => unawaited(_save()), child: Text(widget.editing != null ? t.actionSave : t.actionOk))
        else
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isNotEmpty) setState(() => _styleStep = true);
            },
            child: Text(t.actionNext),
          ),
      ],
    );
  }

  /// A label and its field. On phones the label doesn't take a fixed column: short fields stay beside
  /// it, and [wide] ones (the reminder chips) go below it with the whole width.
  Widget _row(String label, Widget child, {bool wide = false}) {
    final tt = context.tt;
    final text = Text(
      label,
      style: TextStyle(color: tt.textSecondary, fontSize: TtText.body),
    );
    final compact = MediaQuery.sizeOf(context).width < 600;
    if (compact && wide) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 6), child]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (compact) Expanded(child: text) else SizedBox(width: 150, child: text),
          if (compact)
            Flexible(child: child)
          else
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
        ],
      ),
    );
  }

  Widget _dataContent(AppLocalizations t) {
    final tt = context.tt;
    String two(int n) => n.toString().padLeft(2, '0');
    final presets = repeatPresets(t, _date)..remove('FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR');
    final suggestions = t.countdownSpecialSuggestions.split('\n');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.countdownName,
            // "Data Especial" suggests names.
            suffixIcon: _type == CountdownType.specialDay
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.lightbulb_outline, size: 18, color: tt.textTertiary),
                    onSelected: (name) => setState(() => _name.text = name),
                    itemBuilder: (_) => [for (final s in suggestions) PopupMenuItem(value: s, height: 36, child: Text(s))],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        // Following a habit's streak, there is no date: no reminders nor repetition either.
        _row(t.countdownFollow, _followField(t), wide: true),
        if (_followsHabit) _row(t.countdownGoalDays, _goalField(t)),
        if (!_followsHabit) ...[
          _row(
            t.countdownDate,
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2200));
                if (picked == null) return;
                setState(() {
                  _date = picked;
                  if (_rule != null && _rule!.startsWith('FREQ=YEARLY')) _rule = _yearly(picked);
                });
              },
              child: Text('${two(_date.day)}/${two(_date.month)}/${_date.year}'),
            ),
          ),
          if (_type == CountdownType.birthday) ...[
            _row(t.countdownIgnoreYear, Switch(value: _ignoreYear, onChanged: (v) => setState(() => _ignoreYear = v))),
            if (!_ignoreYear) _row(t.countdownShowAge, Switch(value: _showAge, onChanged: (v) => setState(() => _showAge = v))),
          ],
          _row(
            t.pickerReminder,
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final r in ReminderPresets.allDay)
                  FilterChip(
                    label: Text(reminderLabel(t, r), style: const TextStyle(fontSize: 12)),
                    selected: _reminders.contains(r),
                    showCheckmark: false,
                    onSelected: (on) => setState(() => on ? _reminders.add(r) : _reminders.remove(r)),
                  ),
                // "Lembrete constante".
                FilterChip(
                  avatar: const Icon(Icons.notifications_active_outlined, size: 14),
                  label: Text(t.reminderConstant, style: const TextStyle(fontSize: 12)),
                  selected: _reminders.contains(ReminderPresets.constant),
                  showCheckmark: false,
                  onSelected: (on) => setState(() => on ? _reminders.add(ReminderPresets.constant) : _reminders.remove(ReminderPresets.constant)),
                ),
              ],
            ),
            wide: true,
          ),
          _row(
            t.pickerRepeat,
            DropdownButton<String>(
              value: _rule == null ? '' : (presets.containsKey(_rule) ? _rule : 'custom'),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: '', child: Text(t.pickerNone)),
                for (final p in presets.entries) DropdownMenuItem(value: p.key, child: Text(p.value)),
                DropdownMenuItem(value: 'custom', child: Text(t.repeatCustom)),
              ],
              onChanged: (v) async {
                if (v == 'custom') {
                  final custom = await showCustomRepeatDialog(
                    context,
                    rule: _rule,
                    from: RepeatFrom.dueDate,
                    day: _date,
                    now: ref.read(clockProvider).now(),
                  );
                  if (custom != null) setState(() => _rule = custom.rule);
                } else {
                  setState(() => _rule = v == null || v.isEmpty ? null : v);
                }
              },
            ),
          ),
        ],
        _row(
          t.countdownType,
          DropdownButton<CountdownType>(
            value: _type,
            isExpanded: true,
            items: [for (final ty in CountdownType.values) DropdownMenuItem(value: ty, child: Text(countdownTypeLabel(t, ty)))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
        ),
        // "Modo de Contagem": Aniversário and Data Especial only.
        if (_hasDirection && !_followsHabit)
          _row(
            t.countdownDirection,
            DropdownButton<bool>(
              value: _countUp,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: false, child: Text(t.countdownDirectionDown)),
                DropdownMenuItem(value: true, child: Text(t.countdownDirectionUp)),
              ],
              onChanged: (v) => setState(() => _countUp = v ?? _countUp),
            ),
          ),
        // Holidays have no counting mode.
        if (_type != CountdownType.holiday && !_followsHabit)
          _row(
            t.countdownCountMode,
            DropdownButton<CountMode>(
              value: _mode,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: CountMode.standard,
                  child: Tooltip(message: t.countModeStandardHint, child: Text(t.countModeStandard)),
                ),
                DropdownMenuItem(
                  value: CountMode.plusOne,
                  child: Tooltip(message: t.countModePlusOneHint, child: Text(t.countModePlusOne)),
                ),
              ],
              onChanged: (v) => setState(() => _mode = v ?? _mode),
            ),
          ),
        if (!_followsHabit) _row(t.countdownLink, _linkField(t), wide: true),
        _row(
          t.countdownVisibility,
          DropdownButton<CountdownVisibility>(
            value: _visibility,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: CountdownVisibility.onTheDay, child: Text(t.visibilityOnTheDay)),
              DropdownMenuItem(value: CountdownVisibility.threeDaysBefore, child: Text(t.visibilityThreeDays)),
              DropdownMenuItem(value: CountdownVisibility.sevenDaysBefore, child: Text(t.visibilitySevenDays)),
              DropdownMenuItem(value: CountdownVisibility.always, child: Text(t.visibilityAlways)),
              DropdownMenuItem(value: CountdownVisibility.never, child: Text(t.visibilityNever)),
            ],
            onChanged: (v) => setState(() => _visibility = v ?? _visibility),
          ),
        ),
      ],
    );
  }

  Widget _styleContent(AppLocalizations t) {
    final tt = context.tt;
    final preview = previewCountdown(
      name: _name.text.trim(),
      date: _date,
      type: _type,
      mode: _mode,
      rule: _rule,
      showAge: _showAge,
      ignoreYear: _ignoreYear,
      countUp: _countsUp,
      icon: _icon,
      iconColor: _iconColor,
      image: _image,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < countdownStyles; i++)
              GestureDetector(
                onTap: () => setState(() => _style = i),
                child: Container(
                  width: 128,
                  decoration: BoxDecoration(
                    border: Border.all(color: _style == i ? tt.primary : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: 84,
                    child: CountdownCardBody(countdown: preview, style: i, color: parseHexColor(_color) ?? tt.primary, compact: true),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CountdownLookFields(
          icon: _icon,
          iconColor: _iconColor,
          image: _image,
          onIcon: (icon, color) => setState(() {
            _icon = icon;
            _iconColor = color;
          }),
          onImage: (v) => setState(() => _image = v),
        ),
        const SizedBox(height: 8),
        Text(
          t.countdownColor,
          style: TextStyle(color: tt.textSecondary, fontSize: TtText.body),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final c in presetColors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: parseHexColor(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: _color == c ? tt.text : Colors.transparent, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
