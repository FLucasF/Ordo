import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/focus_controller.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../data/preferences_repository.dart';
import '../../domain/enums.dart';
import '../../domain/focus.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/backdrop.dart';
import '../backup/backup_actions.dart';
import '../detail/task_detail_pane.dart';
import '../tasks/batch_pane.dart';
import '../search/quick_search.dart';
import '../search/search_pane.dart';
import '../sidebar/sidebar.dart';
import '../summary/summary_pane.dart';
import '../tasks/task_list_pane.dart';
import '../tasks/timeline_board.dart';
import '../settings/settings_dialog.dart';
import '../sync/sync_indicator.dart';
import 'shortcut_help.dart';

/// Main layout. Wide windows: icon bar · sidebar · list · detail. Narrow windows and phones:
/// the webapp's narrow layout, with the sidebar in a drawer and the detail full screen.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.scope, required this.taskId, this.searchQuery});

  final Scope scope;
  final String? taskId;

  /// Set on the search page: the middle column shows the search instead of a list.
  final String? searchQuery;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarOpen = true;

  /// Widths being dragged (saved when the drag ends).
  double? _sidebarWidth;
  double? _detailWidth;
  final _scaffold = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;

  @override
  void didUpdateWidget(AppShell old) {
    super.didUpdateWidget(old);
    // A selection belongs to the view it was made in.
    if (old.scope != widget.scope || old.searchQuery != widget.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(taskSelectionProvider.notifier).clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < TtSizes.narrowBreakpoint;

    if (narrow) {
      final selecting = widget.searchQuery == null && ref.watch(taskSelectionProvider).isNotEmpty;
      if (widget.taskId != null) {
        return Scaffold(
          body: SafeArea(
            child: TaskDetailPane(scope: widget.scope, taskId: widget.taskId, onClose: () => context.go(Routes.of(widget.scope))),
          ),
        );
      }
      return PhoneBack(
        scaffold: _scaffold,
        drawerOpen: _drawerOpen,
        // Search goes back to where it was opened from; Hoje is the last stop before leaving the app.
        back: widget.searchQuery != null
            ? Routes.backFromSearch
            : widget.scope == const SmartScope(SmartList.today)
            ? null
            : Routes.initial,
        onEndSelection: selecting ? ref.read(taskSelectionProvider.notifier).clear : null,
        child: Scaffold(
          key: _scaffold,
          onDrawerChanged: (open) => setState(() => _drawerOpen = open),
          drawer: NavDrawer(current: widget.scope),
          bottomNavigationBar: selecting ? PhoneSelectionBar(scope: widget.scope) : null,
          body: SafeArea(
            child: widget.searchQuery != null
                ? SearchPane(initialQuery: widget.searchQuery!, selectedTaskId: null, isNarrow: true)
                : widget.scope == const SmartScope(SmartList.summary)
                ? SummaryPane(isNarrow: true, onToggleSidebar: () => _scaffold.currentState?.openDrawer())
                : AppBackdrop(
                    scope: widget.scope,
                    child: TaskListPane(
                      scope: widget.scope,
                      selectedTaskId: null,
                      isNarrow: true,
                      onToggleSidebar: () => _scaffold.currentState?.openDrawer(),
                    ),
                  ),
          ),
        ),
      );
    }

    final prefs = ref.watch(preferencesProvider).value;
    // Columns dragged by the user, within limits that keep the list usable.
    final sidebarWidth = (_sidebarWidth ?? prefs?.sidebarWidth ?? TtSizes.sidebarWidth).clamp(200.0, 480.0).toDouble();
    final maxDetail = math.max(TtSizes.detailMinWidth, width - sidebarWidth - 420).toDouble();
    final detailWidth = (_detailWidth ?? prefs?.detailWidth ?? width * TtSizes.detailFraction)
        .clamp(TtSizes.detailMinWidth, math.min(900.0, maxDetail))
        .toDouble();
    final batch = ref.watch(taskSelectionProvider).length > 1;
    // The Kanban and the timeline take the whole width until a task opens.
    final mode = ref.watch(viewModeProvider(widget.scope));
    final summary = widget.scope == const SmartScope(SmartList.summary) && widget.searchQuery == null;
    final fullWidth = summary || mode == ViewMode.kanban || (mode == ViewMode.timeline && supportsTimeline(widget.scope));
    // "Janela pop-up": the list keeps the width and the task opens over it.
    final popup = (prefs?.detailPopup ?? false) && widget.searchQuery == null;
    final showDetail = batch || (!popup && (widget.taskId != null || widget.searchQuery != null || !fullWidth));
    final popupTask = popup && !batch ? widget.taskId : null;
    // "Cartão": everything but the icon bar is a rounded card over the theme's color.
    final card = prefs?.cardStyle ?? false;
    return Scaffold(
      backgroundColor: card ? Color.alphaBlend(tt.primary.withValues(alpha: 0.22), tt.screen) : null,
      body: Stack(
        children: [
          Row(
            children: [
              const IconBar(),
              Expanded(
                child: _CardFrame(
                  enabled: card,
                  child: Row(
                    children: [
                      if (_sidebarOpen) ...[
                        Sidebar(current: widget.scope, width: sidebarWidth),
                        _ResizeHandle(
                          onDrag: (dx) => setState(() => _sidebarWidth = (sidebarWidth + dx).clamp(200.0, 480.0)),
                          onEnd: () => unawaited(ref.read(preferencesRepositoryProvider).setColumnWidths(sidebar: _sidebarWidth)),
                        ),
                      ],
                      Expanded(
                        child: widget.searchQuery != null
                            ? SearchPane(initialQuery: widget.searchQuery!, selectedTaskId: widget.taskId)
                            : summary
                            ? SummaryPane(onToggleSidebar: () => setState(() => _sidebarOpen = !_sidebarOpen))
                            // The "Papel de parede" goes behind the list only: the sidebar and the detail stay solid.
                            : AppBackdrop(
                                scope: widget.scope,
                                child: TaskListPane(
                                  scope: widget.scope,
                                  selectedTaskId: widget.taskId,
                                  onToggleSidebar: () => setState(() => _sidebarOpen = !_sidebarOpen),
                                ),
                              ),
                      ),
                      if (showDetail) ...[
                        _ResizeHandle(
                          line: tt.divider,
                          onDrag: (dx) => setState(() => _detailWidth = (detailWidth - dx).clamp(TtSizes.detailMinWidth, math.min(900.0, maxDetail))),
                          onEnd: () => unawaited(ref.read(preferencesRepositoryProvider).setColumnWidths(detail: _detailWidth)),
                        ),
                        SizedBox(
                          width: detailWidth,
                          // Several tasks selected: the batch panel replaces the detail.
                          child: batch ? BatchPane(scope: widget.scope) : TaskDetailPane(scope: widget.scope, taskId: widget.taskId),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (popupTask != null) ...[
            ModalBarrier(color: Colors.black54, onDismiss: () => context.go(Routes.of(widget.scope))),
            Center(
              child: Material(
                color: tt.screen,
                elevation: 12,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: math.min(720.0, width - 80),
                  height: math.min(760.0, MediaQuery.sizeOf(context).height - 80),
                  child: TaskDetailPane(scope: widget.scope, taskId: popupTask, onClose: () => context.go(Routes.of(widget.scope))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fixed left bar (50 px): avatar with the account menu and the module icons. Modules from
/// later phases (Calendar, Matrix, Focus, Habits, Countdown, Search) appear as they are built.
/// Modules of the icon bar; the current one is highlighted.
enum AppModule { tasks, calendar, matrix, focus, habit, countdown, finance, diet, journal }

class IconBar extends ConsumerWidget {
  const IconBar({super.key, this.current = AppModule.tasks});

  final AppModule current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final focus = ref.watch(focusProvider);
    if (focus.phase != FocusPhase.idle) ref.watch(focusClockProvider);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    return Container(
      width: TtSizes.iconBarWidth,
      color: tt.iconBar,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Builder(
            builder: (context) => InkWell(
              onTap: () {
                final box = context.findRenderObject()! as RenderBox;
                showAccountMenu(context, ref, box.localToGlobal(Offset(box.size.width, 0)));
              },
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF7B2FBE),
                child: Text(t.appTitle.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Tooltip(
            message: t.navTasks,
            child: IconButton(
              icon: Icon(Icons.check_box, color: current == AppModule.tasks ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.initial),
            ),
          ),
          if (prefs.has(AppFeature.calendar))
            IconButton(
              tooltip: t.navCalendar,
              icon: Icon(Icons.calendar_month_outlined, color: current == AppModule.calendar ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.calendar),
            ),
          if (prefs.has(AppFeature.matrix))
            IconButton(
              tooltip: t.navMatrix,
              icon: Icon(Icons.grid_view_rounded, color: current == AppModule.matrix ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.matrix),
            ),
          // Focus: a progress ring around the icon while a session runs, in any module.
          if (prefs.has(AppFeature.focus) || focus.phase != FocusPhase.idle)
            IconButton(
              tooltip: t.navFocus,
              icon: SizedBox(
                width: 26,
                height: 26,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (focus.phase != FocusPhase.idle)
                      CircularProgressIndicator(
                        value: focus.progress(ref.read(clockProvider).now()),
                        strokeWidth: 2.5,
                        color: tt.primary,
                        backgroundColor: tt.divider,
                      ),
                    Icon(
                      Icons.timer_outlined,
                      color: current == AppModule.focus ? tt.primary : tt.textTertiary,
                      size: focus.phase == FocusPhase.idle ? 22 : 15,
                    ),
                  ],
                ),
              ),
              onPressed: () => context.go(Routes.focus),
            ),
          // Hábito stands out from the other modules: always in the accent color, on a tinted circle.
          if (prefs.has(AppFeature.habit))
            IconButton(
              key: const ValueKey('iconBarHabit'),
              tooltip: t.navHabit,
              style: IconButton.styleFrom(backgroundColor: tt.primary.withValues(alpha: current == AppModule.habit ? 0.28 : 0.14)),
              icon: Icon(Icons.track_changes, color: tt.primary, size: 22),
              onPressed: () => context.go(Routes.habit),
            ),
          if (prefs.has(AppFeature.countdown))
            IconButton(
              tooltip: t.navCountdown,
              icon: Icon(Icons.hourglass_bottom, color: current == AppModule.countdown ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.countdown),
            ),
          if (prefs.has(AppFeature.finance))
            IconButton(
              tooltip: t.navFinance,
              icon: Icon(Icons.account_balance_wallet_outlined, color: current == AppModule.finance ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.finance),
            ),
          if (prefs.has(AppFeature.diet))
            IconButton(
              tooltip: t.navDiet,
              icon: Icon(Icons.restaurant_outlined, color: current == AppModule.diet ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.diet),
            ),
          if (prefs.has(AppFeature.journal))
            IconButton(
              tooltip: t.navJournal,
              icon: Icon(Icons.auto_stories_outlined, color: current == AppModule.journal ? tt.primary : tt.textTertiary, size: 22),
              onPressed: () => context.go(Routes.journal),
            ),
          IconButton(
            tooltip: t.navSearch,
            icon: Icon(Icons.search, color: tt.textTertiary, size: 22),
            onPressed: () => unawaited(showQuickSearch(context)),
          ),
          const Spacer(),
          // The linked devices' sync, when there is one.
          const SyncIndicator(),
          // "Ajuda": Página inicial · Atalhos · Sobre. The Help Center, feedback and
          // change log of TickTick are web pages of the company, so they are left out.
          PopupMenuButton<String>(
            tooltip: t.navHelp,
            icon: Icon(Icons.help_outline, color: tt.textTertiary, size: 22),
            onSelected: (v) => switch (v) {
              'home' => context.go(Routes.initial),
              'shortcuts' => unawaited(showShortcutHelp(context)),
              _ => unawaited(showSettings(context, tab: SettingsTab.about)),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'home', height: 36, child: Text(t.helpHome)),
              PopupMenuItem(value: 'shortcuts', height: 36, child: Text(t.shortcutsTitle)),
              PopupMenuItem(value: 'about', height: 36, child: Text(t.helpAbout)),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// The narrow layout's drawer: account, search, the sidebar and the modules.
class NavDrawer extends ConsumerWidget {
  const NavDrawer({super.key, this.current});

  /// The list shown, or null in a module.
  final Scope? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
    width: TtSizes.sidebarWidth,
    backgroundColor: context.tt.screen,
    child: SafeArea(
      child: Column(
        children: [
          _DrawerHeader(onBackup: () => showAccountMenu(context, ref, const Offset(20, 60))),
          Expanded(
            child: Sidebar(current: current, onNavigate: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    ),
  );
}

/// A module page: the icon bar on its left on wide screens; on narrow ones the [NavDrawer], opened by
/// the ☰ the page puts in its header ([drawerOf]).
class ModuleScaffold extends StatefulWidget {
  const ModuleScaffold({super.key, required this.module, required this.child});

  final AppModule module;
  final Widget child;

  /// Opens the drawer; null on wide screens, where the page shows no ☰.
  static VoidCallback? drawerOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_DrawerOpener>()?.open;

  @override
  State<ModuleScaffold> createState() => _ModuleScaffoldState();
}

class _ModuleScaffoldState extends State<ModuleScaffold> {
  final _scaffold = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= TtSizes.narrowBreakpoint) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconBar(current: widget.module),
              Expanded(child: AppBackdrop(child: widget.child)),
            ],
          ),
        ),
      );
    }
    return PhoneBack(
      scaffold: _scaffold,
      drawerOpen: _drawerOpen,
      back: Routes.initial,
      child: Scaffold(
        key: _scaffold,
        onDrawerChanged: (open) => setState(() => _drawerOpen = open),
        drawer: const NavDrawer(),
        body: SafeArea(
          child: AppBackdrop(
            child: _DrawerOpener(open: () => _scaffold.currentState?.openDrawer(), child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Android's back button on a phone: it closes the open drawer first; then it goes to [back] (Hoje, or
/// where the search was opened from); with no [back] (on Hoje) it leaves the app. Dialogs, menus and
/// the full-screen detail above the page keep their own back.
///
/// The [PopScope] tells Android that the app takes the back itself: with predictive back (on by default
/// from Android 16) the system would otherwise close the app without asking it.
class PhoneBack extends StatelessWidget {
  const PhoneBack({super.key, required this.scaffold, required this.drawerOpen, required this.back, required this.child, this.onEndSelection});

  final GlobalKey<ScaffoldState> scaffold;
  final bool drawerOpen;
  final String? back;
  final Widget child;

  /// While tasks are selected: back ends the selection first.
  final VoidCallback? onEndSelection;

  @override
  Widget build(BuildContext context) => PopScope(canPop: back == null && !drawerOpen && onEndSelection == null, child: _listener(context));

  Widget _listener(BuildContext context) => BackButtonListener(
    onBackButtonPressed: () async {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
      final state = scaffold.currentState;
      if (state != null && state.isDrawerOpen) {
        state.closeDrawer();
        return true;
      }
      if (onEndSelection case final end?) {
        end();
        return true;
      }
      final target = back;
      if (target == null) return false;
      context.go(target);
      return true;
    },
    child: child,
  );
}

/// The ☰ at the start of a module page's header on narrow screens; nothing on wide ones.
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final open = ModuleScaffold.drawerOf(context);
    if (open == null) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(Icons.menu, color: context.tt.textSecondary),
      onPressed: open,
    );
  }
}

class _DrawerOpener extends InheritedWidget {
  const _DrawerOpener({required this.open, required super.child});

  final VoidCallback open;

  @override
  bool updateShouldNotify(_DrawerOpener old) => false;
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onBackup});

  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onBackup,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7B2FBE),
              child: Text(t.appTitle.substring(0, 1), style: const TextStyle(color: Colors.white)),
            ),
          ),
          const Spacer(),
          const SyncIndicator(size: 20),
          IconButton(icon: const Icon(Icons.search), tooltip: t.navSearch, onPressed: () => unawaited(showQuickSearch(context))),
        ],
      ),
    );
  }
}

/// A column border that can be dragged sideways (cursor ↔).
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onDrag, required this.onEnd, this.line});

  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  /// The 1 px line drawn in the middle, if any.
  final Color? line;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeLeftRight,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
      onHorizontalDragEnd: (_) => onEnd(),
      child: SizedBox(
        width: 5,
        child: Center(child: Container(width: 1, color: line ?? Colors.transparent)),
      ),
    ),
  );
}

/// The "Cartão" interface: [child] as a rounded card with a margin; nothing when [enabled] is off.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
      child: Material(color: context.tt.screen, elevation: 2, borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias, child: child),
    );
  }
}
