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
import '../../data/journal_repository.dart';
import '../../domain/journal/journal.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import '../date_picker/month_calendar.dart';
import '../detail/content_editor.dart';
import '../detail/task_detail_pane.dart' show showTaskPopup;
import '../shell/app_shell.dart';
import '../statistics/charts.dart' show LineChart;
import 'journal_widgets.dart';

/// Tabs of Diário (`/journal/{tab}`).
enum JournalTab {
  day('day'),
  timeline('timeline'),
  calendar('calendar');

  const JournalTab(this.route);
  final String route;

  static JournalTab fromRoute(String? route) => values.where((t) => t.route == route).firstOrNull ?? day;
}

/// The day Diário shows (null = today). Outside the page: a tab change builds a new one.
class JournalDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void show(DateTime? day) => state = day;
}

final journalDayProvider = NotifierProvider<JournalDayNotifier, DateTime?>(JournalDayNotifier.new);

/// The history's search and filters (moods and energies; empty = all), kept across its two views.
typedef JournalFilter = ({String query, Set<int> moods, Set<int> energies});

class JournalFilterNotifier extends Notifier<JournalFilter> {
  @override
  JournalFilter build() => (query: '', moods: const {}, energies: const {});

  void search(String query) => state = (query: query, moods: state.moods, energies: state.energies);

  void toggleMood(int mood) => state = (query: state.query, moods: _toggle(state.moods, mood), energies: state.energies);

  void toggleEnergy(int level) => state = (query: state.query, moods: state.moods, energies: _toggle(state.energies, level));

  void clear() => state = build();

  static Set<int> _toggle(Set<int> set, int value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

final journalFilterProvider = NotifierProvider<JournalFilterNotifier, JournalFilter>(JournalFilterNotifier.new);

/// Diário in the Calendar's look: the month on the left (days written are marked; a click opens the
/// day), the tabs Dia, Linha do tempo and Calendário under the top bar, and "+ Escrever hoje".
///
/// Dia: the day's mood, energy, main goal for tomorrow (the "highlight" column) and notes (the tasks' editor, with pictures), saved as they
/// change, and the day's summary from the other modules. Linha do tempo: the entries, newest first,
/// with search and filters. Calendário: each day tinted by its mood, and the month's mood and energy.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key, required this.tab});

  final JournalTab tab;

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  bool _panel = true;
  DateTime? _panelMonth;

  /// The month of the Calendário tab (null = the shown day's).
  DateTime? _month;

  void _openDay(DateTime? day) {
    ref.read(journalDayProvider.notifier).show(day);
    if (widget.tab != JournalTab.day) context.go(Routes.journalOf(JournalTab.day.route));
  }

  Future<void> _delete(JournalEntry e) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(journalRepositoryProvider);
    await repo.delete(e.id);
    if (mounted) showToast(context, t.journalEntryDeleted, undo: () => repo.delete(e.id, restore: true), redo: () => repo.delete(e.id));
  }

  Future<void> _entryMenu(JournalEntry e, Offset at) async {
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
        _openDay(journalDay(e.day));
      case 'delete':
        await _delete(e);
    }
  }

  /// The phone's calendar (the panel's month is not shown there).
  Future<void> _pickDay(DateTime day, DateTime today, Set<DateTime> written) async {
    final dates = DateLabels(AppLocalizations.of(context));
    var month = DateTime(day.year, day.month);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => MonthCalendar(
                month: month,
                today: today,
                isSelected: (d) => d == day,
                occurrences: written,
                title: dates.monthTitle(month),
                onPrevious: () => setState(() => month = DateTime(month.year, month.month - 1)),
                onNext: () => setState(() => month = DateTime(month.year, month.month + 1)),
                onToday: () => Navigator.pop(context, today),
                onPick: (d) => Navigator.pop(context, d),
              ),
            ),
          ),
        ),
      ),
    );
    if (picked != null && mounted) _openDay(picked == today ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final dates = DateLabels(t);
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final day = ref.watch(journalDayProvider) ?? today;
    final journal = ref.watch(journalProvider).value ?? JournalSnapshot.empty;
    final written = {
      for (final e in journal.entries)
        if (!journalEntryIsEmpty(e)) journalDay(e.day),
    };
    final entry = journal.on(day);
    final month = _month ?? DateTime(day.year, day.month);

    void create() => _openDay(null);

    final topBar = ShellTopBar(
      title: switch (widget.tab) {
        JournalTab.day => dates.dayHeader(day, today),
        JournalTab.timeline => t.navJournal,
        JournalTab.calendar => dates.monthTitle(month),
      },
      onTogglePanel: () => setState(() => _panel = !_panel),
      onCreate: create,
      createLabel: t.journalWriteToday,
      actions: [
        if (widget.tab == JournalTab.day) ...[
          if (entry != null && !journalEntryIsEmpty(entry))
            IconButton(
              tooltip: t.journalDeleteEntry,
              icon: Icon(Icons.delete_outline, color: context.tt.textSecondary),
              onPressed: () => unawaited(_delete(entry)),
            ),
          if (narrow)
            IconButton(
              tooltip: t.journalPickDay,
              icon: Icon(Icons.calendar_month_outlined, color: context.tt.textSecondary),
              onPressed: () => unawaited(_pickDay(day, today, written)),
            ),
          TodayPill(label: t.calendarToday, onPressed: () => _openDay(null)),
          ShellArrows(
            onPrevious: () => _openDay(DateTime(day.year, day.month, day.day - 1)),
            onNext: () => _openDay(DateTime(day.year, day.month, day.day + 1)),
          ),
        ],
        if (widget.tab == JournalTab.calendar) ...[
          TodayPill(label: t.calendarToday, onPressed: () => setState(() => _month = DateTime(today.year, today.month))),
          ShellArrows(
            onPrevious: () => setState(() => _month = DateTime(month.year, month.month - 1)),
            onNext: () => setState(() => _month = DateTime(month.year, month.month + 1)),
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
          occurrences: written,
          title: dates.monthTitle(shownMonth),
          onPrevious: () => setState(() => _panelMonth = DateTime(shownMonth.year, shownMonth.month - 1)),
          onNext: () => setState(() => _panelMonth = DateTime(shownMonth.year, shownMonth.month + 1)),
          onToday: () {
            setState(() => _panelMonth = null);
            _openDay(null);
          },
          onPick: (d) {
            setState(() => _panelMonth = null);
            _openDay(d == today ? null : d);
          },
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShellTabs<JournalTab>(
          selected: widget.tab,
          onSelected: (tab) => context.go(Routes.journalOf(tab.route)),
          tabs: [
            (value: JournalTab.day, label: t.journalTabDay, icon: Icons.edit_note),
            (value: JournalTab.timeline, label: t.journalTabTimeline, icon: Icons.view_agenda_outlined),
            (value: JournalTab.calendar, label: t.journalTabCalendar, icon: Icons.calendar_month_outlined),
          ],
        ),
        Expanded(
          child: switch (widget.tab) {
            // A new editor for each day: the old one saves what was typed into its own day.
            JournalTab.day => _DayEntry(key: ValueKey(day), day: day, entry: entry),
            JournalTab.timeline => _timeline(t, journal, today, narrow),
            JournalTab.calendar => _calendar(t, journal, month, today, narrow),
          },
        ),
      ],
    );

    return ModuleScaffold(
      module: AppModule.journal,
      child: ShellLayout(panel: panel, panelOpen: _panel, topBar: topBar, body: body, onCreate: create, createLabel: t.journalWriteToday),
    );
  }

  Widget _timeline(AppLocalizations t, JournalSnapshot journal, DateTime today, bool narrow) {
    final tt = context.tt;
    final filter = ref.watch(journalFilterProvider);
    final entries = journalHistory(journal.entries, query: filter.query, moods: filter.moods, energies: filter.energies);
    final any = journal.entries.any((e) => !journalEntryIsEmpty(e));
    final dates = DateLabels(t);
    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 12, narrow ? 12 : 20, 32),
      children: [
        const _HistoryFilters(search: true),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(any ? t.journalNoResults : t.journalTimelineEmpty, style: TextStyle(color: tt.textTertiary)),
          ),
        for (final e in entries)
          _TimelineRow(
            entry: e,
            date: dates.dayHeader(journalDay(e.day), today),
            onTap: () => _openDay(journalDay(e.day) == today ? null : journalDay(e.day)),
            onMenu: (at) => unawaited(_entryMenu(e, at)),
          ),
      ],
    );
  }

  Widget _calendar(AppLocalizations t, JournalSnapshot journal, DateTime month, DateTime today, bool narrow) {
    final tt = context.tt;
    final filter = ref.watch(journalFilterProvider);
    final shown = {
      for (final e in journalHistory(journal.entries, query: filter.query, moods: filter.moods, energies: filter.energies)) journalDay(e.day): e,
    };
    final series = journalSeries(shown.values.toList(), month, DateTime(month.year, month.month + 1));
    final moods = [
      for (final p in series)
        if (p.mood != null) p,
    ];
    final energies = [
      for (final p in series)
        if (p.energy != null) p,
    ];
    Widget chart(String label, List<JournalPoint> points, int? Function(JournalPoint) value) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
        ),
        LineChart(height: 110, maxValue: 5, values: [for (final p in points) value(p)!.toDouble()], labels: [for (final p in points) '${p.day.day}']),
      ],
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 8 : 20, 12, narrow ? 8 : 20, 32),
      children: [
        const _HistoryFilters(search: false),
        const SizedBox(height: 12),
        MoodMonth(
          month: month,
          today: today,
          moodOf: (d) => shown[d]?.mood,
          hasEntry: shown.containsKey,
          onPick: (d) => _openDay(d == today ? null : d),
        ),
        BodyHeading(t.journalChart),
        if (series.isEmpty)
          Text(t.journalChartEmpty, style: TextStyle(color: tt.textTertiary))
        else ...[
          if (moods.isNotEmpty) chart(t.journalMood, moods, (p) => p.mood),
          if (energies.isNotEmpty) ...[const SizedBox(height: 8), chart(t.journalEnergy, energies, (p) => p.energy)],
        ],
      ],
    );
  }
}

/// The history's search (on the timeline) and its mood and energy filters.
class _HistoryFilters extends ConsumerStatefulWidget {
  const _HistoryFilters({required this.search});

  final bool search;

  @override
  ConsumerState<_HistoryFilters> createState() => _HistoryFiltersState();
}

class _HistoryFiltersState extends ConsumerState<_HistoryFilters> {
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: ref.read(journalFilterProvider).query);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final filter = ref.watch(journalFilterProvider);
    final notifier = ref.read(journalFilterProvider.notifier);
    final active = filter.query.trim().isNotEmpty || filter.moods.isNotEmpty || filter.energies.isNotEmpty;
    Widget labeled(String label, Widget child) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.search) ...[
          TextField(
            controller: _query,
            decoration: InputDecoration(
              hintText: t.journalSearchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: tt.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onChanged: notifier.search,
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 20,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            labeled(t.journalMood, MoodPicker(compact: true, isSelected: filter.moods.contains, onPick: notifier.toggleMood)),
            labeled(t.journalEnergy, EnergyPicker(compact: true, isFilled: filter.energies.contains, onPick: notifier.toggleEnergy)),
            if (active)
              TextButton(
                onPressed: () {
                  _query.clear();
                  notifier.clear();
                },
                child: Text(t.journalFilterClear),
              ),
          ],
        ),
      ],
    );
  }
}

/// An entry of the timeline: its mood's face, the day, the energy and the beginning of the notes. A
/// click opens the day; right click, long press or ⋯ offer Editar and Deletar.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.date, required this.onTap, required this.onMenu});

  final JournalEntry entry;
  final String date;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMenu;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final mood = entry.mood, energy = entry.energy;
    final excerpt = journalExcerpt(entry);
    return GestureDetector(
      onSecondaryTapUp: (d) => onMenu(d.globalPosition),
      onLongPressStart: (d) => onMenu(d.globalPosition),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mood == null ? tt.fieldFill : journalMoodColor(mood).withValues(alpha: 0.25),
                ),
                child: Text(mood == null ? '📝' : journalMoodFaces[mood - 1], style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                          ),
                        ),
                        if (energy != null) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: t.journalEnergyLevel(energy),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt, size: 16, color: Color(0xFFF2B866)),
                                Text(
                                  '$energy',
                                  style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      excerpt.isEmpty ? t.journalNoText : excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: TtText.small, color: excerpt.isEmpty ? tt.textFaint : tt.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              RowMenuButton(onMenu: onMenu),
            ],
          ),
        ),
      ),
    );
  }
}

/// The day's entry: mood and energy at a tap, the highlight and the notes saved after a short pause,
/// and the day's summary at the end.
class _DayEntry extends ConsumerStatefulWidget {
  const _DayEntry({super.key, required this.day, required this.entry});

  final DateTime day;
  final JournalEntry? entry;

  @override
  ConsumerState<_DayEntry> createState() => _DayEntryState();
}

class _DayEntryState extends ConsumerState<_DayEntry> {
  late final _highlight = TextEditingController(text: widget.entry?.highlight ?? '');
  final _highlightFocus = FocusNode();
  Timer? _debounce;

  /// The page's scroll: its bar stays in sight on a computer, where a long day's notes go past the
  /// window's bottom.
  final _scroll = ScrollController();

  /// Read once: the last save runs in [dispose], when ref can no longer be used.
  late final JournalRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(journalRepositoryProvider);
  }

  @override
  void didUpdateWidget(_DayEntry old) {
    super.didUpdateWidget(old);
    // Loaded late, deleted, or changed by a sync: follow it, unless it is being typed.
    final stored = widget.entry?.highlight ?? '';
    if (stored != _highlight.text && !_highlightFocus.hasFocus && !(_debounce?.isActive ?? false)) _highlight.text = stored;
  }

  void _highlightChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => unawaited(_repo.setHighlight(widget.day, text)));
  }

  @override
  void dispose() {
    // Leaving the day (or the page) with a pause not yet over still saves it.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_repo.setHighlight(widget.day, _highlight.text));
    }
    _highlight.dispose();
    _highlightFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final entry = widget.entry;
    final mood = entry?.mood, energy = entry?.energy;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
      ),
    );
    final page = ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 16, narrow ? 12 : 20, 40),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        label(mood == null ? t.journalMood : '${t.journalMood} · ${journalMoodLabel(t, mood)}'),
                        MoodPicker(isSelected: (m) => m == mood, onPick: (m) => unawaited(_repo.setMood(widget.day, m == mood ? null : m))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        label(energy == null ? t.journalEnergy : '${t.journalEnergy} · $energy/5'),
                        EnergyPicker(
                          isFilled: (level) => energy != null && level <= energy,
                          onPick: (level) => unawaited(_repo.setEnergy(widget.day, level == energy ? null : level)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                label(t.journalHighlight),
                TextField(
                  key: const ValueKey('journalHighlight'),
                  controller: _highlight,
                  focusNode: _highlightFocus,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: t.journalHighlightHint,
                    prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: tt.fieldFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: _highlightChanged,
                ),
                const SizedBox(height: 20),
                label(t.journalNotes),
                Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tt.divider),
                  ),
                  child: ContentEditor(
                    markdown: entry?.notes ?? '',
                    placeholder: t.journalNotesPlaceholder,
                    onChanged: (md) => unawaited(_repo.setNotes(widget.day, md)),
                    attachments: ref.read(attachmentStoreProvider),
                    now: ref.read(clockProvider).now,
                    // A task linked with "[[" opens over the page.
                    onOpenTask: (id) {
                      final linked = ref.read(snapshotProvider).value?.taskById[id];
                      if (linked != null && linked.deletedAt == null) unawaited(showTaskPopup(context, linked));
                    },
                  ),
                ),
                const SizedBox(height: 24),
                JournalSummaryCard(day: widget.day),
              ],
            ),
          ),
        ),
      ],
    );
    if (narrow) return page;
    // In place of the platform's own bar, which only shows while scrolling.
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), child: page),
    );
  }
}
