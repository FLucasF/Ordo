import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/preferences_repository.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ids.dart';
import '../../domain/quick_add.dart' show foldForSearch;
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import '../search/quick_search.dart';
import '../settings/settings_dialog.dart';
import 'shortcut_help.dart';

/// Command palette (Ctrl+K): "Nova tarefa", navigation with its shortcuts, help; while
/// typing, lists and tags to jump to and "Buscar '…'". It has no task actions, as in TickTick.
Future<void> showCommandPalette(BuildContext context, {required void Function(Scope scope) onGo, required Future<void> Function() onAddTask}) async {
  final run = await showDialog<Future<void> Function(BuildContext context)>(
    context: context,
    builder: (_) => _CommandPalette(onGo: onGo, onAddTask: onAddTask),
  );
  if (run != null && context.mounted) await run(context);
}

class _Command {
  const _Command({required this.icon, required this.label, required this.run, this.shortcut, this.color, this.section});

  final IconData icon;
  final Color? color;
  final String label;
  final String? shortcut;

  /// Section header shown above the first command of each section.
  final String? section;
  final Future<void> Function(BuildContext context) run;
}

class _CommandPalette extends ConsumerStatefulWidget {
  const _CommandPalette({required this.onGo, required this.onAddTask});

  final void Function(Scope scope) onGo;
  final Future<void> Function() onAddTask;

  @override
  ConsumerState<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<_CommandPalette> {
  final _query = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);
  int _highlighted = 0;
  List<_Command> _visible = const [];

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _visible.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlighted = (_highlighted + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)) % _visible.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      Navigator.pop(context, _visible[_highlighted].run);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<_Command> _commands(AppLocalizations t, TtColors tt, Snapshot s) {
    final labels = Labels(t);
    Future<void> go(Scope scope) async => widget.onGo(scope);
    _Command smart(SmartList l, IconData icon, String? shortcut) =>
        _Command(icon: icon, label: labels.smartList(l), shortcut: shortcut, run: (_) => go(SmartScope(l)));
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final query = foldForSearch(_query.text.trim());
    bool matches(String label) => query.isEmpty || foldForSearch(label).contains(query);

    final fixed = [
      _Command(icon: Icons.add, label: t.paletteNewTask, shortcut: 'N', run: (_) => widget.onAddTask()),
      _Command(icon: Icons.search, label: t.navSearch, shortcut: '/', section: t.shortcutsNavigation, run: showQuickSearch),
      _Command(icon: Icons.settings_outlined, label: t.shortcutSettings, shortcut: 'G→S', run: showSettings),
      smart(SmartList.all, Icons.all_inbox_outlined, 'G→A'),
      smart(SmartList.today, Icons.today_outlined, 'G→T'),
      smart(SmartList.tomorrow, Icons.wb_twilight_outlined, 'G→R'),
      smart(SmartList.next7Days, Icons.date_range_outlined, 'G→N'),
      _Command(icon: Icons.inbox_outlined, label: t.inbox, shortcut: 'G→I', run: (_) => go(const ListScope(inboxListId))),
      smart(SmartList.completed, Icons.check_box_outlined, null),
      smart(SmartList.wontDo, Icons.cancel_outlined, null),
      smart(SmartList.trash, Icons.delete_outline, null),
      // The modules: each opens its screen; turned-off features stay out.
      for (final (icon, label, route, feature) in [
        (Icons.check_box_outlined, t.navTasks, Routes.initial, null),
        (Icons.calendar_month_outlined, t.navCalendar, Routes.calendar, AppFeature.calendar),
        (Icons.grid_view_outlined, t.navMatrix, Routes.matrix, AppFeature.matrix),
        (Icons.track_changes, t.navHabit, Routes.habit, AppFeature.habit),
        (Icons.timer_outlined, t.navFocus, Routes.focus, AppFeature.focus),
        (Icons.hourglass_bottom, t.navCountdown, Routes.countdown, AppFeature.countdown),
        (Icons.account_balance_wallet_outlined, t.navFinance, Routes.finance, AppFeature.finance),
        (Icons.restaurant_outlined, t.navDiet, Routes.diet, AppFeature.diet),
        (Icons.insights_outlined, t.statsTitle, Routes.statistics, null),
      ])
        if (feature == null || prefs.has(feature))
          _Command(
            icon: icon,
            label: label,
            section: route == Routes.initial ? t.paletteModules : null,
            run: (context) async => GoRouter.of(context).go(route),
          ),
      smart(SmartList.summary, Icons.summarize_outlined, 'G→B'),
      _Command(icon: Icons.keyboard_outlined, label: t.shortcutsTitle, shortcut: '?', section: t.navHelp, run: showShortcutHelp),
    ].where((c) => matches(c.label)).toList();

    if (query.isEmpty) return fixed;
    final term = _query.text.trim();
    return [
      ...fixed,
      for (final (i, l) in s.activeLists.where((l) => l.id != inboxListId && matches(l.name)).take(8).indexed)
        _Command(
          icon: Icons.list,
          color: parseHexColor(l.color),
          label: l.name,
          section: i == 0 ? t.sidebarLists : null,
          run: (_) => go(ListScope(l.id)),
        ),
      for (final (i, f) in s.folders.where((f) => f.deletedAt == null && matches(f.name)).take(8).indexed)
        _Command(icon: Icons.folder_outlined, label: f.name, section: i == 0 ? t.paletteFolders : null, run: (_) => go(FolderScope(f.id))),
      for (final (i, tag) in s.activeTags.where((tag) => matches(tag.name)).take(8).indexed)
        _Command(
          icon: Icons.sell_outlined,
          color: parseHexColor(tag.color),
          label: tag.name,
          section: i == 0 ? t.sidebarTags : null,
          run: (_) => go(TagScope(tag.id)),
        ),
      _Command(
        icon: Icons.search,
        label: t.paletteSearchFor(term),
        run: (context) => showQuickSearch(context, initialQuery: term),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    _visible = _commands(t, tt, s);
    if (_highlighted >= _visible.length) _highlighted = 0;

    return Dialog(
      alignment: const Alignment(0, -0.5),
      child: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _query,
                focusNode: _focus,
                autofocus: true,
                style: TextStyle(color: tt.text, fontSize: 15),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: t.paletteHint,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() => _highlighted = 0),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  for (final (i, c) in _visible.indexed) ...[
                    if (c.section != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Text(
                          c.section!,
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                      ),
                    InkWell(
                      onTap: () => Navigator.pop(context, c.run),
                      child: Container(
                        height: 36,
                        color: i == _highlighted ? tt.selected : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(c.icon, size: 17, color: c.color ?? tt.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                c.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: tt.text),
                              ),
                            ),
                            if (c.shortcut != null)
                              Text(
                                c.shortcut!,
                                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
