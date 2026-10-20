import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/time_zones.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/calendar.dart';
import '../../domain/finance/finance_calendar.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/reminders.dart';
import '../../domain/task_dates.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';
import '../common/shell_widgets.dart';
import '../common/time_zone_picker.dart';
import '../date_picker/date_picker.dart';
import '../detail/task_detail_pane.dart';
import '../finance/entry_form.dart' show showEntryForm;
import '../focus/focus_page.dart' show focusRecordsProvider;
import '../shell/app_shell.dart';
import '../tasks/batch_pane.dart';
import '../sidebar/sidebar.dart';
import '../subscriptions/subscriptions.dart';
import 'calendar_create_popup.dart';
import 'calendar_edit_page.dart';
import 'calendar_grid.dart';
import '../search/quick_search.dart';
import 'calendar_details_popup.dart';
import 'calendar_insights_panel.dart';
import '../common/feedback.dart';
import 'calendar_side_panel.dart';
import 'color_label_menu.dart';
import 'recurring_scope.dart';
import 'calendar_timeline.dart';
import 'calendar_widgets.dart';

/// The day the calendar shows; kept across modes (null = today).
class CalendarAnchor extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? day) => state = day;
}

final calendarAnchorProvider = NotifierProvider<CalendarAnchor, DateTime?>(CalendarAnchor.new);

String calendarModeLabel(AppLocalizations t, CalendarMode m) => switch (m) {
  CalendarMode.day => t.calendarModeDay,
  CalendarMode.week => t.calendarModeWeek,
  CalendarMode.month => t.calendarModeMonth,
  CalendarMode.year => t.calendarModeYear,
  CalendarMode.agenda => t.calendarModeAgenda,
  CalendarMode.multiDay => t.calendarModeMultiDay,
  CalendarMode.multiWeek => t.calendarModeMultiWeek,
};

/// Shortcut of each mode, as Google Calendar's: D/1, W/2, M/3,
/// X/4 (the custom number of days), A/5 and Y.
const _modeKeys = {
  CalendarMode.day: [LogicalKeyboardKey.keyD, LogicalKeyboardKey.digit1],
  CalendarMode.week: [LogicalKeyboardKey.keyW, LogicalKeyboardKey.digit2],
  CalendarMode.month: [LogicalKeyboardKey.keyM, LogicalKeyboardKey.digit3],
  CalendarMode.multiDay: [LogicalKeyboardKey.keyX, LogicalKeyboardKey.digit4],
  CalendarMode.agenda: [LogicalKeyboardKey.keyA, LogicalKeyboardKey.digit5],
  CalendarMode.year: [LogicalKeyboardKey.keyY],
};

/// Calendar module (`#c/all/calendar/{mode}`): header with the period, the mode
/// selector, "Hoje" and ‹ ›; "…" has "Organizar tarefas", the list filter and the view options.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key, this.mode});

  /// Null: the last mode used.
  final CalendarMode? mode;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  bool _arrange = false;

  /// "Split view": the lists next to the calendar; a task dropped on a list moves there
  /// keeping its time, on Hoje / Amanhã takes that day.
  bool _lists = false;

  /// Google Calendar's left panel (desktop), toggled by ☰.
  bool _panel = true;

  /// Google's "Time Insights" panel on the right.
  bool _insights = false;

  /// The task being created in the create card: shown as a provisional block on the grid.
  DateSelection? _draft;

  /// Where the last press was, so the create card opens beside it.
  Offset? _lastPress;

  /// Last Shift + wheel step (a trackpad sends many small scrolls).
  DateTime _lastWheelStep = DateTime(2000);
  final _focus = FocusNode(debugLabel: 'calendar');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Preferences get _prefs => ref.read(preferencesProvider).value ?? Preferences.defaults;

  DateTime get _today => startOfDay(ref.read(clockProvider).now());

  void _setMode(CalendarMode mode) {
    unawaited(ref.read(preferencesRepositoryProvider).setCalendarMode(mode));
    context.go(Routes.calendarOf(mode));
  }

  void _setAnchor(DateTime day) => ref.read(calendarAnchorProvider.notifier).set(startOfDay(day));

  Future<void> _setOptions(CalendarOptions o) => ref.read(preferencesRepositoryProvider).setCalendarOptions(o);

  // ---------------------------------------------------------------- actions

  Future<void> _open(CalendarEntry e, {Rect? anchor}) async {
    // Ctrl+click picks tasks for the batch panel.
    if (HardwareKeyboard.instance.isControlPressed && e.kind == CalendarEntryKind.task && !e.isOccurrence && e.task != null) {
      ref.read(taskSelectionProvider.notifier).toggle(e.task!.id);
      return;
    }
    switch (e.kind) {
      // A task: Google's details popup beside it (centered on phones); ⋮ opens TickTick's detail.
      case CalendarEntryKind.task when e.task != null:
        final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
        final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
        await showCalendarDetails(
          context,
          entry: e,
          color: _colorOf(e, s, _prefs.calendarOptions),
          anchor: narrow ? null : anchor,
          near: narrow ? null : _lastPress,
          onOpenDetail: () => unawaited(_openDetail(e.task!)),
        );
      case CalendarEntryKind.task || CalendarEntryKind.checklistItem:
        if (e.task case final task?) await _openDetail(task);
      case CalendarEntryKind.habit:
        context.go(Routes.habit);
      case CalendarEntryKind.countdown:
        context.go(Routes.countdown);
      case CalendarEntryKind.event:
        await showSubscribedEvent(context, ref, e.title, e.start, e.end, isAllDay: e.isAllDay, calendarId: e.id);
      case CalendarEntryKind.finance:
        final near = anchor?.center ?? _lastPress;
        await _financeMenu(e, near ?? MediaQuery.sizeOf(context).center(Offset.zero));
      case CalendarEntryKind.focus:
        if (e.task case final task?) {
          await showTaskDetailDialog(context, task);
        } else {
          context.go(Routes.focus);
        }
    }
  }

  /// Google Calendar's create card, by the pressed spot.
  void _create(DateSelection schedule, {bool centered = false}) {
    // A timed click without a length gets the default duration (Google's hour when none is set).
    final due = schedule.dueDate;
    final minutes = _prefs.taskDefaults.durationMinutes ?? 60;
    final timedPoint = due != null && !schedule.isAllDay && schedule.startDate == null;
    unawaited(
      _showCreate(
        DateSelection(
          dueDate: timedPoint ? due.add(Duration(minutes: minutes)) : due,
          startDate: timedPoint ? due : schedule.startDate,
          isAllDay: schedule.isAllDay,
        ),
        centered: centered,
      ),
    );
  }

  Future<void> _showCreate(DateSelection schedule, {required bool centered}) => showCalendarCreatePopup(
    context,
    near: centered ? null : _lastPress,
    schedule: DateSelection(
      dueDate: schedule.dueDate,
      startDate: schedule.startDate,
      isAllDay: schedule.isAllDay,
      // Default reminders: "Na hora" for a task with a time.
      reminders: schedule.isAllDay ? const {} : const {ReminderPresets.onTime},
    ),
    onDraft: (draft) {
      if (mounted) setState(() => _draft = draft);
    },
    onMoreOptions: (draft) => unawaited(showTaskEditPage(context, draft)),
  );

  Future<void> _move(String taskId, DateTime day, {DateTime? time}) async {
    final task = ref.read(snapshotProvider).value?.taskById[taskId];
    if (task == null) return;
    final repo = ref.read(repositoryProvider);
    final saved = AppLocalizations.of(context).toastSaved;
    if (task.dueDate == null) {
      // From "Organizar tarefas": the day, or the time it was dropped on.
      await repo.setDueDate(taskId, time ?? day, isAllDay: time == null);
      if (mounted) {
        showToast(
          context,
          saved,
          undo: () => repo.setDueDate(taskId, null),
          redo: () => repo.setDueDate(taskId, time ?? day, isAllDay: time == null),
        );
      }
      return;
    }
    final to = movedDates(task, day, time: time);
    // Ctrl or Alt held while dropping: a copy goes there and the task stays.
    final keyboard = HardwareKeyboard.instance;
    final copied = keyboard.isControlPressed || keyboard.isAltPressed;
    if (!copied && task.repeatRule != null) {
      final scope = await scopeFor(context, task, task.startLocal!, delete: false);
      if (scope == null || !mounted) return;
      if (scope == RecurringScope.one) return _detach(task, to);
    }
    final id = copied ? await repo.duplicate(taskId) : taskId;
    await repo.setDueDate(id, to.due, isAllDay: to.isAllDay, startDate: to.start);
    if (!mounted) return;
    if (copied) {
      showToast(context, saved, undo: () => repo.delete(id), redo: () => repo.restore(id));
    } else {
      showToast(
        context,
        saved,
        undo: () => repo.setDueDate(id, task.endLocal, isAllDay: task.isAllDay, startDate: task.startLocal),
        redo: () => repo.setDueDate(id, to.due, isAllDay: to.isAllDay, startDate: to.start),
      );
    }
  }

  /// "Somente esta" for a repeating task moved or stretched: a copy without repetition goes to [to]
  /// and the series skips this occurrence.
  Future<void> _detach(Task task, ({DateTime due, DateTime? start, bool isAllDay}) to) async {
    final repo = ref.read(repositoryProvider);
    final saved = AppLocalizations.of(context).toastSaved;
    final copy = await repo.duplicate(task.id);
    await repo.setRepeat(copy, null);
    await repo.setDueDate(copy, to.due, isAllDay: to.isAllDay, startDate: to.start);
    await repo.skipOccurrence(task.id, task.startLocal!);
    if (!mounted) return;
    showToast(
      context,
      saved,
      undo: () async {
        await repo.delete(copy);
        await repo.restoreSeries(task);
      },
    );
  }

  Future<void> _resize(Task task, DateTime end) async {
    if (task.repeatRule != null) {
      final scope = await scopeFor(context, task, task.startLocal!, delete: false);
      if (scope == null || !mounted) return;
      if (scope == RecurringScope.one) return _detach(task, (due: end, start: task.startLocal, isAllDay: false));
    }
    final repo = ref.read(repositoryProvider);
    final saved = AppLocalizations.of(context).toastSaved;
    await repo.setDueDate(task.id, end, isAllDay: false, startDate: task.startLocal);
    if (!mounted) return;
    showToast(
      context,
      saved,
      undo: () => repo.setDueDate(task.id, task.endLocal, isAllDay: false, startDate: task.startLocal),
      redo: () => repo.setDueDate(task.id, end, isAllDay: false, startDate: task.startLocal),
    );
  }

  /// One panel at a time on the right: "Organizar tarefas" or Time Insights.
  void _rightPanel({bool arrange = false, bool insights = false}) => setState(() {
    _arrange = arrange;
    _insights = insights;
  });

  /// The period Time Insights describe: "Quinta-feira, 24 de setembro de 2026", "Setembro 2026",
  /// "20 – 26 de set. de 2026".
  String _periodTitle(DateLabels labels, CalendarMode mode, DateTime anchor, ({DateTime from, int days}) period) {
    final last = DateTime(period.from.year, period.from.month, period.from.day + period.days - 1);
    return switch (mode) {
      CalendarMode.day => labels.fullDate(period.from),
      CalendarMode.month => labels.monthTitle(anchor),
      CalendarMode.year => '${anchor.year}',
      _ when period.days == 1 => labels.fullDate(period.from),
      _ when last.year != period.from.year =>
        '${period.from.day} de ${labels.monthShort(period.from)}. de ${period.from.year} – ${last.day} de ${labels.monthShort(last)}. de ${last.year}',
      _ when last.month != period.from.month =>
        '${period.from.day} de ${labels.monthShort(period.from)}. – ${last.day} de ${labels.monthShort(last)}. de ${last.year}',
      _ => '${period.from.day} – ${last.day} de ${labels.monthShort(last)}. de ${last.year}',
    };
  }

  /// Phones have no room beside the calendar: the insights open as a page.
  Future<void> _showInsightsPage(List<CalendarEntry> entries, ({DateTime from, int days}) period, String title) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: SafeArea(
        child: CalendarInsightsPanel(
          entries: entries,
          from: period.from,
          days: period.days,
          period: title,
          width: null,
          onClose: () => Navigator.pop(context),
        ),
      ),
    ),
  );

  /// TickTick's full task detail, in a dialog (the whole screen on a phone).
  Future<void> _openDetail(Task task) => showTaskDetailDialog(context, task);

  /// A click on a Finanças due day: open its tab, or a new entry on that day.
  Future<void> _financeMenu(CalendarEntry e, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'open', height: 36, child: Text(t.finOpenInFinance)),
        PopupMenuItem(value: 'entry', height: 36, child: Text(t.finNewEntryOnDay)),
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case 'open':
        context.go(
          Routes.financeOf(switch (e.id.split(':').first) {
            'invoice' => 'cards',
            'loan' => 'loans',
            _ => 'recurring',
          }),
        );
      case 'entry':
        await showEntryForm(context, date: e.start);
    }
  }

  /// Right click on a task: Google's menu, "Excluir" and the colors, with "Salvo" / "Desfazer". On a
  /// Finanças due day, the same menu as its click.
  Future<void> _entryMenu(CalendarEntry e, Offset at) async {
    if (e.kind == CalendarEntryKind.finance) return _financeMenu(e, at);
    final task = e.task;
    if (e.kind != CalendarEntryKind.task || task == null) return;
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final done = task.status != TaskStatus.open;
    final picked = await showColorLabelMenu(
      context,
      near: at,
      current: task.color,
      actions: [
        ColorMenuAction.open,
        if (!e.isOccurrence) done ? ColorMenuAction.reopen : ColorMenuAction.complete,
        ColorMenuAction.duplicate,
        ColorMenuAction.delete,
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case ColorMenuActed(action: ColorMenuAction.open):
        await _open(e);
      case ColorMenuActed(action: ColorMenuAction.complete):
        await repo.complete(task.id);
        if (mounted) showToast(context, t.toastTaskCompleted, undo: () => repo.reopen(task.id), redo: () => repo.complete(task.id));
      case ColorMenuActed(action: ColorMenuAction.reopen):
        await repo.reopen(task.id);
      case ColorMenuActed(action: ColorMenuAction.duplicate):
        final copy = await repo.duplicate(task.id);
        if (mounted) showToast(context, t.toastSaved, undo: () => repo.delete(copy), redo: () => repo.restore(copy));
      case ColorMenuActed(action: ColorMenuAction.delete):
        final scope = await scopeFor(context, task, e.start, delete: true);
        if (scope != null && mounted) await deleteOccurrence(context, repo, task, e.start, scope);
      case ColorPicked(:final color) when color != task.color:
        await repo.setTaskColor(task.id, color);
        if (!mounted) return;
        showToast(context, t.toastSaved, undo: () => repo.setTaskColor(task.id, task.color), redo: () => repo.setTaskColor(task.id, color));
      case _:
        break;
    }
  }

  Color _colorOf(CalendarEntry e, Snapshot s, CalendarOptions o) =>
      calendarEntryColor(e, s, o, context.tt, (ref.read(preferencesProvider).value ?? Preferences.defaults).subscriptions);

  Future<void> _showDay(DateTime day, List<CalendarEntry> entries, CalendarActions actions) async {
    final labels = DateLabels(AppLocalizations.of(context));
    await showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(labels.dayHeader(day, _today), style: const TextStyle(fontSize: 15)),
        children: [
          for (final e in entries)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                actions.open(e);
              },
              child: CalendarChip(entry: e, color: actions.colorOf(e), height: 22, look: actions.look),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- menus

  Future<void> _viewOptions() async {
    await showDialog<void>(context: context, builder: (_) => const _ViewOptionsDialog());
  }

  Future<void> _listFilter() async {
    final t = AppLocalizations.of(context);
    final labels = Labels(t);
    final lists = (ref.read(snapshotProvider).value ?? Snapshot.empty()).activeLists;
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final selected = {..._prefs.calendarOptions.listIds};
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(t.calendarListFilter, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: 320,
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(dense: true, value: selected.isEmpty, title: Text(t.searchAll), onChanged: (_) => setLocal(selected.clear)),
                  for (final l in lists)
                    CheckboxListTile(
                      dense: true,
                      value: selected.contains(l.id),
                      title: Text(labels.listName(l)),
                      onChanged: (on) => setLocal(() => on == true ? selected.add(l.id) : selected.remove(l.id)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, selected), child: Text(t.actionOk)),
            ],
          ),
        );
      },
    );
    if (picked != null) await _setOptions(_prefs.calendarOptions.copyWith(listIds: picked));
  }

  /// C and "+ Criar": a task at the next whole hour of today, an hour long, as Google's "c".
  void _createNow() {
    final now = ref.read(clockProvider).now();
    final start = DateTime(now.year, now.month, now.day, now.hour + 1);
    _create(DateSelection(startDate: start, dueDate: start.add(const Duration(hours: 1)), isAllDay: false), centered: true);
  }

  /// G: a date picker, and the calendar goes to the chosen day.
  Future<void> _goToDate() async {
    final today = startOfDay(ref.read(clockProvider).now());
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(calendarAnchorProvider) ?? today,
      firstDate: DateTime(today.year - 20),
      lastDate: DateTime(today.year + 20),
    );
    if (picked != null) _setAnchor(picked);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isAltPressed) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // T: back to today.
    if (key == LogicalKeyboardKey.keyT) {
      ref.read(calendarAnchorProvider.notifier).set(null);
      return KeyEventResult.handled;
    }
    // Google Calendar's J/N next period and K/P previous; C creates; G goes to a date.
    final step = switch (key) {
      LogicalKeyboardKey.keyJ || LogicalKeyboardKey.keyN => 1,
      LogicalKeyboardKey.keyK || LogicalKeyboardKey.keyP => -1,
      _ => 0,
    };
    if (step != 0) {
      final prefs = _prefs;
      final mode = widget.mode ?? prefs.calendarMode;
      final today = startOfDay(ref.read(clockProvider).now());
      _setAnchor(calendarStep(mode, ref.read(calendarAnchorProvider) ?? today, step, prefs.calendarOptions));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyC) {
      _createNow();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyG) {
      unawaited(_goToDate());
      return KeyEventResult.handled;
    }
    // Z: undo the last action (the one whose toast offered "Desfazer").
    if (key == LogicalKeyboardKey.keyZ) {
      final undone = AppLocalizations.of(context).toastUndone;
      unawaited(() async {
        if (await ActionHistory.undo() && mounted) showToast(context, undone);
      }());
      return KeyEventResult.handled;
    }
    for (final entry in _modeKeys.entries) {
      if (entry.value.contains(event.logicalKey)) {
        _setMode(entry.key);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final mode = widget.mode ?? prefs.calendarMode;
    final options = prefs.calendarOptions;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final anchor = ref.watch(calendarAnchorProvider) ?? today;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final focusRecords = options.showFocus ? ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[] : const <FocusRecord>[];
    final period = calendarPeriod(mode, anchor, options);
    final to = DateTime(period.from.year, period.from.month, period.from.day + period.days);
    final selection = ref.watch(taskSelectionProvider);
    final entries = calendarEntries(
      s,
      period.from,
      to,
      options,
      now: now,
      focusRecords: focusRecords,
      events: subscribedEventsBetween(ref, period.from, to),
    );
    // Finanças: recurring bills, card invoices and the day to collect each loan.
    if (options.showFinance && prefs.has(AppFeature.finance)) {
      if (ref.watch(financeProvider).value case final finance?) {
        entries.addAll(financeCalendarEntries(t, financeDues(finance, period.from, to, today)));
      }
    }
    // Time Insights count what is scheduled, not the task being drawn; a month counts only its days.
    final counted = List.of(entries);
    final insightsPeriod = mode == CalendarMode.month
        ? (from: DateTime(anchor.year, anchor.month), days: DateUtils.getDaysInMonth(anchor.year, anchor.month))
        : period;
    final insightsTitle = _periodTitle(labels, mode, anchor, insightsPeriod);
    if (_draft case DateSelection(dueDate: final due?) && final draft) {
      entries.add(
        CalendarEntry(
          kind: CalendarEntryKind.task,
          id: '',
          title: '(${t.untitled})',
          start: draft.startDate ?? due,
          end: draft.isAllDay ? due : (draft.startDate == null ? due.add(const Duration(minutes: 30)) : due),
          isAllDay: draft.isAllDay,
        ),
      );
    }

    late final CalendarActions actions;
    actions = CalendarActions(
      open: (e, {anchor}) => unawaited(_open(e, anchor: anchor)),
      create: _create,
      move: (id, day, {time}) => unawaited(_move(id, day, time: time)),
      resize: (task, end) => unawaited(_resize(task, end)),
      colorOf: (e) => _colorOf(e, s, options),
      menu: (e, at) => unawaited(_entryMenu(e, at)),
      showDay: (day, list) => unawaited(_showDay(day, list, actions)),
      isSelected: (e) => e.kind == CalendarEntryKind.task && selection.contains(e.id),
      look: CalendarLook(classic: options.classicStyle, icons: options.showIcons, pastBefore: options.dimPast ? now : null),
    );

    final middle = DateTime(period.from.year, period.from.month, period.from.day + (period.days - 1) ~/ 2);
    final shownMonth = switch (mode) {
      CalendarMode.month || CalendarMode.agenda => anchor,
      _ => middle,
    };
    // Phones drop the current year from the title, so the header fits.
    final title = mode == CalendarMode.year
        ? '${anchor.year}'
        : (narrow && shownMonth.year == today.year ? labels.monthTitle(shownMonth).split(' ').first : labels.monthTitle(shownMonth));

    final body = switch (mode) {
      CalendarMode.month => CalendarMonthGrid(
        from: period.from,
        weeks: period.days ~/ 7,
        entries: entries,
        today: today,
        actions: actions,
        month: anchor.month,
        hideWeekends: !options.showWeekends,
      ),
      CalendarMode.multiWeek => CalendarMonthGrid(
        from: period.from,
        weeks: period.days ~/ 7,
        entries: entries,
        today: today,
        actions: actions,
        hideWeekends: !options.showWeekends,
      ),
      CalendarMode.day || CalendarMode.week || CalendarMode.multiDay => CalendarTimeline(
        hideWeekends: !options.showWeekends && mode != CalendarMode.day,
        key: ValueKey((mode, period.from)),
        from: period.from,
        days: period.days,
        entries: entries,
        today: today,
        now: now,
        actions: actions,
        zones: options.timeZones,
        hiddenBefore: options.hiddenBefore,
        hiddenAfter: options.hiddenAfter,
        minMinutes: options.shortAs30 ? 30 : 0,
      ),
      CalendarMode.year => CalendarYearView(
        year: anchor.year,
        entries: entries,
        today: today,
        onMonth: (m) {
          _setAnchor(m);
          _setMode(CalendarMode.month);
        },
        onDay: (d) {
          _setAnchor(d);
          _setMode(CalendarMode.week);
        },
      ),
      CalendarMode.agenda => CalendarAgenda(from: period.from, days: period.days, entries: entries, today: today, actions: actions),
    };

    final header = ShellTopBar(
      title: title,
      onTogglePanel: () => setState(() => _panel = !_panel),
      // "+ Nova tarefa": at the next hour, in the create popup.
      onCreate: _createNow,
      createLabel: t.paletteNewTask,
      actions: [
        if (!narrow)
          IconButton(
            tooltip: t.navSearch,
            icon: Icon(Icons.search, color: tt.textSecondary),
            onPressed: () => unawaited(showQuickSearch(context)),
          ),
        ViewPill<Object>(
          label: calendarModeLabel(t, mode),
          onSelected: (v) => switch (v) {
            final CalendarMode m => _setMode(m),
            'weekends' => unawaited(_setOptions(options.copyWith(showWeekends: !options.showWeekends))),
            'completed' => unawaited(_setOptions(options.copyWith(showCompleted: !options.showCompleted))),
            _ => null,
          },
          items: () => [
            for (final m in CalendarMode.values)
              CheckedPopupMenuItem<Object>(
                value: m,
                checked: m == mode,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(switch (m) {
                        CalendarMode.multiDay => '${calendarModeLabel(t, m)} · ${t.calendarMultiDays(options.multiDays)}',
                        CalendarMode.multiWeek => '${calendarModeLabel(t, m)} · ${t.calendarMultiWeeks(options.multiWeeks)}',
                        _ => calendarModeLabel(t, m),
                      }),
                    ),
                    if (_modeKeys[m] case final keys?)
                      Text(
                        keys.first.keyLabel,
                        style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                      ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            CheckedPopupMenuItem<Object>(value: 'weekends', checked: options.showWeekends, child: Text(t.calendarShowWeekends)),
            CheckedPopupMenuItem<Object>(value: 'completed', checked: options.showCompleted, child: Text(t.calendarShowCompleted)),
          ],
        ),
        SizedBox(width: narrow ? 4 : 8),
        TodayPill(
          label: t.calendarToday,
          tooltip: '${labels.fullDate(today)} (T)',
          onPressed: () => ref.read(calendarAnchorProvider.notifier).set(null),
        ),
        ShellArrows(
          onPrevious: () => _setAnchor(calendarStep(mode, anchor, -1, options)),
          onNext: () => _setAnchor(calendarStep(mode, anchor, 1, options)),
        ),
        PopupMenuButton<String>(
          tooltip: '',
          icon: Icon(Icons.more_horiz, color: tt.textSecondary),
          onSelected: (v) => switch (v) {
            'arrange' => _rightPanel(arrange: !_arrange),
            'split' => setState(() => _lists = !_lists),
            'lists' => unawaited(_listFilter()),
            'insights' when narrow => unawaited(_showInsightsPage(counted, insightsPeriod, insightsTitle)),
            'insights' => _rightPanel(insights: !_insights),
            _ => unawaited(_viewOptions()),
          },
          itemBuilder: (_) => [
            if (!narrow) CheckedPopupMenuItem(value: 'arrange', checked: _arrange, child: Text(t.calendarArrange)),
            if (!narrow) CheckedPopupMenuItem(value: 'split', checked: _lists, child: Text(t.calendarShowLists)),
            if (narrow)
              PopupMenuItem(value: 'insights', height: 36, child: Text(t.insightsTitle))
            else
              CheckedPopupMenuItem(value: 'insights', checked: _insights, child: Text(t.insightsTitle)),
            PopupMenuItem(value: 'lists', height: 36, child: Text(t.calendarListFilter)),
            PopupMenuItem(value: 'options', height: 36, child: Text(t.calendarViewOptions)),
          ],
        ),
      ],
    );

    return ModuleScaffold(
      module: AppModule.calendar,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Container(
          color: tt.screen,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_lists && !narrow) ...[
                const Sidebar(current: null),
                VerticalDivider(width: 1, color: tt.divider),
              ] else if (_panel && !narrow) ...[
                CalendarSidePanel(
                  anchor: anchor,
                  onDay: _setAnchor,
                  insights: CalendarInsightsSummary(
                    entries: counted,
                    from: insightsPeriod.from,
                    days: insightsPeriod.days,
                    period: insightsTitle,
                    onMore: () => _rightPanel(insights: true),
                  ),
                ),
                VerticalDivider(width: 1, color: tt.divider),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      // Shift + wheel (or a sideways scroll) moves the dates.
                      child: Listener(
                        onPointerDown: (e) => _lastPress = e.position,
                        onPointerSignal: (e) {
                          if (e is! PointerScrollEvent || HardwareKeyboard.instance.isControlPressed) return;
                          final dx = e.scrollDelta.dx != 0 ? e.scrollDelta.dx : (HardwareKeyboard.instance.isShiftPressed ? e.scrollDelta.dy : 0.0);
                          final wall = DateTime.now();
                          if (dx == 0 || wall.difference(_lastWheelStep) < const Duration(milliseconds: 250)) return;
                          _lastWheelStep = wall;
                          _setAnchor(calendarStep(mode, anchor, dx > 0 ? 1 : -1, options));
                        },
                        // A phone: the round "+" in the corner, as the other screens.
                        child: narrow
                            ? Stack(
                                children: [
                                  Positioned.fill(child: body),
                                  Positioned(
                                    right: 16,
                                    bottom: 16,
                                    child: FloatingActionButton(
                                      tooltip: t.paletteNewTask,
                                      backgroundColor: tt.primary,
                                      foregroundColor: Colors.white,
                                      onPressed: _createNow,
                                      child: const Icon(Icons.add),
                                    ),
                                  ),
                                ],
                              )
                            : body,
                      ),
                    ),
                  ],
                ),
              ),
              // Several tasks picked with Ctrl+click: the batch panel (as in the lists).
              if (selection.length > 1 && !narrow)
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: tt.divider)),
                  ),
                  child: const BatchPane(scope: SmartScope(SmartList.all)),
                )
              else if (_arrange && !narrow)
                _ArrangePanel(options: options, onClose: () => setState(() => _arrange = false))
              else if (_insights && !narrow)
                CalendarInsightsPanel(
                  entries: counted,
                  from: insightsPeriod.from,
                  days: insightsPeriod.days,
                  period: insightsTitle,
                  onClose: () => setState(() => _insights = false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Organizar tarefas": the open tasks without a date, to drag onto the calendar.
class _ArrangePanel extends ConsumerWidget {
  const _ArrangePanel({required this.options, required this.onClose});

  final CalendarOptions options;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final tasks = [
      for (final task in s.tasks)
        if (Snapshot.isOpen(task) &&
            task.dueDate == null &&
            s.listById[task.listId]?.archivedAt == null &&
            (options.listIds.isEmpty || options.listIds.contains(task.listId)))
          task,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: tt.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.calendarArrange,
                    style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              t.calendarArrangeHint,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(t.calendarArrangeEmpty, style: TextStyle(color: tt.textTertiary)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    children: [
                      for (final task in tasks)
                        calendarDraggable(
                          context,
                          taskId: task.id,
                          feedback: Container(
                            width: 220,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: tt.text, fontSize: TtText.small),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: tt.hover, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title.isEmpty ? t.untitled : task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: TtText.body, color: tt.text),
                                  ),
                                ),
                                if (s.listById[task.listId] case final list?)
                                  Text(labels.listName(list), style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// "Opções de visualização".
class _ViewOptionsDialog extends ConsumerWidget {
  const _ViewOptionsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final o = prefs.calendarOptions;
    void set(CalendarOptions next) => unawaited(ref.read(preferencesRepositoryProvider).setCalendarOptions(next));
    Widget toggle(String label, bool value, CalendarOptions Function(bool) next) => SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(fontSize: TtText.body, color: tt.text),
      ),
      value: value,
      onChanged: (v) => set(next(v)),
    );
    Widget stepper(String label, int value, int min, int max, CalendarOptions Function(int) next) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: TtText.body, color: tt.text),
          ),
        ),
        IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: value > min ? () => set(next(value - 1)) : null),
        Text('$value', style: TextStyle(color: tt.text)),
        IconButton(icon: const Icon(Icons.add, size: 16), onPressed: value < max ? () => set(next(value + 1)) : null),
      ],
    );
    return AlertDialog(
      title: Text(t.calendarViewOptions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              toggle(t.calendarShowCompleted, o.showCompleted, (v) => o.copyWith(showCompleted: v)),
              toggle(t.calendarShowChecklist, o.showChecklistItems, (v) => o.copyWith(showChecklistItems: v)),
              toggle(t.calendarShowRepeats, o.showRepeats, (v) => o.copyWith(showRepeats: v)),
              toggle(t.calendarShowHabits, o.showHabits, (v) => o.copyWith(showHabits: v)),
              toggle(t.calendarShowFocus, o.showFocus, (v) => o.copyWith(showFocus: v)),
              toggle(t.calendarShowCountdowns, o.showCountdowns, (v) => o.copyWith(showCountdowns: v)),
              if (prefs.has(AppFeature.finance)) toggle(t.calendarShowFinance, o.showFinance, (v) => o.copyWith(showFinance: v)),
              toggle(t.calendarShowWeekends, o.showWeekends, (v) => o.copyWith(showWeekends: v)),
              toggle(t.calendarDimPast, o.dimPast, (v) => o.copyWith(dimPast: v)),
              toggle(t.calendarShortAs30, o.shortAs30, (v) => o.copyWith(shortAs30: v)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.calendarColorBy,
                      style: TextStyle(fontSize: TtText.body, color: tt.text),
                    ),
                  ),
                  DropdownButton<CalendarColorBy>(
                    value: o.colorBy,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: CalendarColorBy.list, child: Text(t.calendarColorByList)),
                      DropdownMenuItem(value: CalendarColorBy.tag, child: Text(t.calendarColorByTag)),
                      DropdownMenuItem(value: CalendarColorBy.priority, child: Text(t.calendarColorByPriority)),
                    ],
                    onChanged: (v) => set(o.copyWith(colorBy: v)),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.calendarStyle,
                      style: TextStyle(fontSize: TtText.body, color: tt.text),
                    ),
                  ),
                  DropdownButton<bool>(
                    value: o.classicStyle,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: TtText.body, color: tt.text),
                    items: [
                      DropdownMenuItem(value: false, child: Text(t.calendarStyleModern)),
                      DropdownMenuItem(value: true, child: Text(t.calendarStyleClassic)),
                    ],
                    onChanged: (v) => set(o.copyWith(classicStyle: v)),
                  ),
                ],
              ),
              toggle(t.calendarShowIcons, o.showIcons, (v) => o.copyWith(showIcons: v)),
              const SizedBox(height: 8),
              // "Fusos adicionais": up to four, shown left of the hours in Dia, Semana and Multi-Dia.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.calendarTimeZones,
                  style: TextStyle(fontSize: TtText.body, color: tt.text),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final zone in o.timeZones)
                    InputChip(
                      label: Text('${zoneCity(zone)} (${zoneOffsetLabel(zone, ref.read(clockProvider).now())})'),
                      onDeleted: () => set(o.copyWith(timeZones: [...o.timeZones]..remove(zone))),
                    ),
                  if (o.timeZones.length < CalendarOptions.maxTimeZones)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(t.calendarAddTimeZone),
                      onPressed: () async {
                        final zone = await pickTimeZone(context, ref.read(clockProvider).now());
                        if (zone != null && !o.timeZones.contains(zone)) set(o.copyWith(timeZones: [...o.timeZones, zone]));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // The hidden ranges of the timeline ("ajustam o intervalo oculto").
              stepper(t.calendarHideBefore, o.hiddenBefore, 0, 12, (v) => o.copyWith(hiddenBefore: v)),
              stepper(t.calendarHideAfter, o.hiddenAfter, 12, 24, (v) => o.copyWith(hiddenAfter: v)),
              stepper(t.calendarModeMultiDay, o.multiDays, 1, 14, (v) => o.copyWith(multiDays: v)),
              stepper(t.calendarModeMultiWeek, o.multiWeeks, 1, 6, (v) => o.copyWith(multiWeeks: v)),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose))],
    );
  }
}
