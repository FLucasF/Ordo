import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/time_zones.dart';
import '../core/clock.dart';
import '../data/preferences_repository.dart';
import '../domain/reminder_plan.dart';
import '../domain/views.dart';
import '../features/backup/auto_backup.dart';
import '../features/backup/backup_actions.dart' show runAutoBackup;
import '../features/countdown/countdown_page.dart';
import '../features/focus/focus_page.dart';
import '../features/diet/diet_page.dart';
import '../features/finance/finance_page.dart';
import '../features/habits/habit_page.dart';
import '../domain/calendar.dart';
import '../features/calendar/calendar_page.dart';
import '../features/matrix/matrix_page.dart';
import '../features/statistics/statistics_page.dart';
import '../features/subscriptions/subscriptions.dart';
import '../features/reminders/reminder_popup.dart';
import '../features/templates/templates.dart';
import '../features/shell/app_shell.dart';
import '../l10n/app_localizations.dart';
import '../core/ids.dart';
import '../domain/finance/finance_calendar.dart';
import '../domain/subscriptions.dart';
import '../features/calendar/calendar_widgets.dart';
import '../features/date_picker/date_picker.dart';
import '../features/tasks/quick_add_modal.dart';
import '../platform/calendar_home_widget.dart';
import '../platform/desktop_shell.dart';
import '../platform/notifications.dart';
import '../platform/window_title.dart';
import 'providers.dart';
import 'reminders.dart';
import 'shortcuts/global_shortcuts.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'window_title.dart';
import '../features/common/color_choice.dart';
import 'focus_restorer.dart';
import 'latin_fallback.dart';

GoRouter buildRouter({String initialLocation = Routes.initial}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', redirect: (_, _) => Routes.initial),
    GoRoute(
      path: Routes.countdown,
      pageBuilder: (context, state) => const NoTransitionPage(child: CountdownPage()),
    ),
    GoRoute(
      path: Routes.focus,
      pageBuilder: (context, state) => const NoTransitionPage(child: FocusPage()),
    ),
    GoRoute(
      path: Routes.habit,
      pageBuilder: (context, state) => const NoTransitionPage(child: HabitPage()),
    ),
    GoRoute(
      path: Routes.finance,
      pageBuilder: (context, state) => const NoTransitionPage(child: FinancePage(tab: FinanceTab.entries)),
    ),
    GoRoute(
      path: '${Routes.finance}/:tab',
      pageBuilder: (context, state) => NoTransitionPage(child: FinancePage(tab: FinanceTab.fromRoute(state.pathParameters['tab']))),
    ),
    GoRoute(
      path: Routes.diet,
      pageBuilder: (context, state) => const NoTransitionPage(child: DietPage(tab: DietTab.diary)),
    ),
    GoRoute(
      path: '${Routes.diet}/:tab',
      pageBuilder: (context, state) => NoTransitionPage(child: DietPage(tab: DietTab.fromRoute(state.pathParameters['tab']))),
    ),
    GoRoute(
      path: Routes.statistics,
      pageBuilder: (context, state) => const NoTransitionPage(child: StatisticsPage(tab: StatsTab.overview)),
    ),
    GoRoute(
      path: '${Routes.statistics}/:tab',
      pageBuilder: (context, state) => NoTransitionPage(child: StatisticsPage(tab: StatsTab.fromRoute(state.pathParameters['tab']))),
    ),
    GoRoute(
      path: Routes.calendar,
      pageBuilder: (context, state) => const NoTransitionPage(child: CalendarPage()),
    ),
    GoRoute(
      path: '${Routes.calendar}/:mode',
      pageBuilder: (context, state) => NoTransitionPage(child: CalendarPage(mode: CalendarMode.fromRoute(state.pathParameters['mode']))),
    ),
    GoRoute(
      path: Routes.matrix,
      pageBuilder: (context, state) => const NoTransitionPage(child: MatrixPage()),
    ),
    GoRoute(
      path: Routes.search,
      pageBuilder: (context, state) => NoTransitionPage(
        child: AppShell(
          scope: const SmartScope(SmartList.all),
          taskId: state.uri.queryParameters['task'],
          searchQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/:kind/:id/tasks',
      pageBuilder: (context, state) =>
          NoTransitionPage(child: AppShell(scope: Routes.scopeOf(state.pathParameters['kind']!, state.pathParameters['id']!), taskId: null)),
      routes: [
        GoRoute(
          path: ':taskId',
          pageBuilder: (context, state) => NoTransitionPage(
            child: AppShell(
              scope: Routes.scopeOf(state.pathParameters['kind']!, state.pathParameters['id']!),
              taskId: state.pathParameters['taskId'],
            ),
          ),
        ),
      ],
    ),
  ],
);

class TasksApp extends ConsumerStatefulWidget {
  const TasksApp({super.key, this.initialLocation = Routes.initial});

  final String initialLocation;

  @override
  ConsumerState<TasksApp> createState() => _TasksAppState();
}

class _TasksAppState extends ConsumerState<TasksApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);
  final _windowTitle = WindowTitle();
  final _focusRestorer = FocusRestorer();
  Timer? _syncDebounce;
  Timer? _widgetDebounce;
  Timer? _periodicSync;
  StreamSubscription<ReminderResponse>? _responses;

  // In-app popups: reminders planned from the latest data, and the moment up to which they were shown.
  List<PlannedReminder> _plan = const [];
  late DateTime _poppedUntil = ref.read(clockProvider).now();
  Timer? _popupTimer;

  /// Windows: silences a reminder's system notification just before the app rings the despertador.
  Timer? _muteTimer;

  /// The tray, autostart and language last sent to Windows.
  (bool, bool, AppLanguage)? _desktop;
  Timer? _autoBackup;

  @override
  void initState() {
    super.initState();
    // Alt+Tab back to the window: typing goes on in the same field.
    _focusRestorer.attach();
    // Subscribed calendars older than 12 hours are downloaded again.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(refreshStaleSubscriptions(ref)));
    // The day's local backup, a little after start so it never slows the first screen, then checked
    // every hour, so an app left open for days still makes one a day.
    if (ref.read(autoBackupProvider) != null) {
      _autoBackup = Timer(const Duration(seconds: 10), () {
        unawaited(runAutoBackup(ref));
        _autoBackup = Timer.periodic(const Duration(hours: 1), (_) => unawaited(runAutoBackup(ref)));
      });
    }
    // "Tempo flutuante": tasks keep their clock time when this device changed zone.
    final zone = deviceZoneId();
    if (zone != null) {
      unawaited(
        ref.read(repositoryProvider).reanchorFloating(zone).catchError((Object e) {
          debugPrint('Floating tasks not moved: $e');
          return 0;
        }),
      );
    }
    unawaited(
      seedBuiltInTemplates(
        ref.read(repositoryProvider),
        ref.read(preferencesRepositoryProvider),
        reminderTexts,
      ).catchError((Object e) => debugPrint('Templates not seeded: $e')),
    );
    unawaited(
      seedBuiltInCountdowns(
        ref.read(repositoryProvider),
        ref.read(preferencesRepositoryProvider),
        reminderTexts,
        ref.read(clockProvider).now(),
      ).catchError((Object e) => debugPrint('Countdowns not seeded: $e')),
    );
    ref.listenManual(snapshotProvider, (_, next) {
      final snapshot = next.value;
      if (snapshot == null) return;
      _plan = planReminders(snapshot, _poppedUntil);
      _armPopupTimer();
    }, fireImmediately: true);
    // The phone's home-screen calendar widget and the desktop mini calendar follow the data, and
    // their taps open the app there.
    if (Platform.isAndroid || DesktopShell.available) {
      ref.listenManual(snapshotProvider, (_, _) => _widgetSoon(), fireImmediately: true);
      ref.listenManual(preferencesProvider, (_, _) => _widgetSoon());
      ref.listenManual(financeProvider, (_, _) => _widgetSoon());
      ref.listenManual(subscriptionFilesProvider, (_, _) => _widgetSoon());
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(listenCalendarWidget(_onWidgetAction)));
      DesktopShell.listenWidgetActions((raw) {
        if (parseWidgetAction(raw) case final a?) _onWidgetAction(a);
      });
    }
    final setup = ref.read(reminderSetupProvider);
    if (setup == null) return;
    // OS reminders follow the data; a periodic pass schedules reminders that enter the planning window.
    ref.listenManual(snapshotProvider, (_, next) {
      if (next.value != null) _syncSoon(setup);
    }, fireImmediately: true);
    ref.listenManual(preferencesProvider, (_, next) {
      if (next.value != null) _syncSoon(setup);
    });
    // Recurring bills and loans have reminders too.
    ref.listenManual(financeProvider, (_, next) {
      if (next.value != null) _syncSoon(setup);
    });
    _periodicSync = Timer.periodic(const Duration(hours: 6), (_) => _syncSoon(setup));
    // Windows: the tray ("Manter na bandeja ao fechar") and "Iniciar com o Windows".
    ref.listenManual(preferencesProvider, (_, next) {
      final prefs = next.value;
      if (prefs == null || _desktop == (prefs.closeToTray, prefs.launchAtStartup, prefs.language)) return;
      _desktop = (prefs.closeToTray, prefs.launchAtStartup, prefs.language);
      appLocale = prefs.language.locale;
      final t = reminderTexts;
      unawaited(
        DesktopShell.configureTray(enabled: prefs.closeToTray, tooltip: t.appTitle, open: t.trayOpen, mini: t.trayMiniCalendar, quit: t.trayQuit),
      );
      unawaited(DesktopShell.setAutostart(prefs.launchAtStartup));
    }, fireImmediately: true);
    _responses = setup.responses.listen((r) => unawaited(_onReminderResponse(r)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(setup.service.requestPermissions().catchError((Object e) => false));
      final launch = setup.launchResponse;
      if (launch != null) unawaited(_onReminderResponse(launch));
    });
  }

  void _armPopupTimer() {
    _popupTimer?.cancel();
    _muteTimer?.cancel();
    if (_plan.isEmpty) return;
    final wait = _plan.first.at.difference(ref.read(clockProvider).now());
    _popupTimer = Timer(wait.isNegative ? Duration.zero : wait + const Duration(milliseconds: 200), _popDue);
    // Windows with the despertador: the system's notification goes silent just before, as the app rings.
    if (_despertador && wait > const Duration(seconds: 2)) {
      _muteTimer = Timer(wait - const Duration(seconds: 2), () => unawaited(_muteDue(_plan.first.at)));
    }
  }

  bool get _despertador =>
      DesktopShell.available && (ref.read(preferencesProvider).value?.reminderSound ?? ReminderSound.alarmClock) == ReminderSound.alarmClock;

  Future<void> _muteDue(DateTime at) async {
    final setup = ref.read(reminderSetupProvider);
    if (setup == null) return;
    final gateway = OsNotificationGateway(setup.service, reminderTexts);
    final persistent = ref.read(preferencesProvider).value?.constantReminder ?? false;
    for (final r in _plan.where((r) => !r.at.isAfter(at.add(const Duration(seconds: 1))))) {
      await setup.service.cancel(r.id);
      await gateway.scheduleReminder(
        PlannedReminder(
          id: r.id,
          taskId: r.taskId,
          at: r.at,
          title: r.title,
          due: r.due,
          isAllDay: r.isAllDay,
          body: r.body,
          persistent: persistent,
          itemId: r.itemId,
          sound: ReminderSound.alarmClock,
        ),
        muted: true,
      );
    }
  }

  void _popDue() {
    final now = ref.read(clockProvider).now();
    final due = _plan.where((r) => r.at.isAfter(_poppedUntil) && !r.at.isAfter(now)).toList();
    if (due.isNotEmpty) ref.read(firedRemindersProvider.notifier).add(due);
    if (due.isNotEmpty && _despertador) unawaited(DesktopShell.playAlarm(loop: false));
    _poppedUntil = now;
    _plan = _plan.where((r) => r.at.isAfter(now)).toList();
    _armPopupTimer();
  }

  void _openTask(String taskId) {
    final task = ref.read(snapshotProvider).value?.taskById[taskId];
    if (task != null && task.deletedAt == null) _router.go(Routes.of(ListScope(task.listId), taskId: task.id));
  }

  /// Rewrites what the home-screen widget and the mini calendar show, a moment after the data settles.
  void _widgetSoon() {
    _widgetDebounce?.cancel();
    _widgetDebounce = Timer(const Duration(seconds: 1), () {
      final snapshot = ref.read(snapshotProvider).value;
      if (snapshot == null) return;
      final prefs = ref.read(preferencesProvider).value ?? Preferences.defaults;
      final now = ref.read(clockProvider).now();
      final today = startOfDay(now);
      final (:from, :to) = calendarWidgetRange(today);
      final t = reminderTexts;
      final options = prefs.calendarOptions;
      final files = ref.read(subscriptionFilesProvider).value ?? const {};
      final finance = ref.read(financeProvider).value;
      final data = calendarWidgetData(
        snapshot: snapshot,
        options: options,
        subscriptions: prefs.subscriptions,
        colors: buildTheme(dark: true, series: prefs.colorSeries, accent: parseHexColor(prefs.customAccent)).extension<TtColors>()!,
        t: t,
        now: now,
        events: [for (final sub in prefs.subscriptions) ...subscribedEvents(sub, from, to, icsEvents: files[sub.id])],
        extra: options.showFinance && prefs.has(AppFeature.finance) && finance != null
            ? financeCalendarEntries(t, financeDues(finance, from, to, today))
            : const [],
      );
      unawaited(exportCalendarWidget(data).catchError((Object e) => debugPrint('Calendar widget not updated: $e')));
    });
  }

  /// A tap on the widget: the Calendar on that day and view; "+" also opens the quick add for it.
  void _onWidgetAction(WidgetAction a) {
    ref.read(calendarAnchorProvider.notifier).set(a.day);
    _router.go(Routes.calendarOf(CalendarMode.fromRoute(a.mode)));
    if (a.action != 'create') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;
      unawaited(
        showQuickAddModal(
          context,
          target: const AddTarget(listId: inboxListId, hint: AddPlainHint()),
          schedule: DateSelection(dueDate: a.day),
        ),
      );
    });
  }

  void _syncSoon(ReminderSetup setup) {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 400), () {
      final snapshot = ref.read(snapshotProvider).value;
      if (snapshot == null) return;
      final prefs = ref.read(preferencesProvider).value ?? Preferences.defaults;
      unawaited(
        syncReminders(
          setup.scheduler,
          snapshot,
          prefs,
          ref.read(clockProvider).now(),
          reminderTexts,
          finance: ref.read(financeProvider).value,
        ).catchError((Object e) => debugPrint('Reminder sync failed: $e')),
      );
    });
  }

  Future<void> _onReminderResponse(ReminderResponse r) async {
    if (r.taskId.startsWith(dailyDigestPrefix)) {
      _router.go(Routes.of(const SmartScope(SmartList.today)));
      return;
    }
    if (r.taskId.startsWith(countdownPrefix)) {
      _router.go(Routes.countdown);
      return;
    }
    if (r.taskId.startsWith(habitPrefix)) {
      _router.go(Routes.habit);
      return;
    }
    if (r.taskId.startsWith(financePrefix)) {
      _router.go(Routes.financeOf(r.taskId.startsWith('${financePrefix}loan:') ? 'loans' : 'recurring'));
      return;
    }
    // A notification answered: the despertador stops, and opening it brings the window back.
    unawaited(DesktopShell.stopAlarm());
    if (r.action == NotificationAction.open) unawaited(DesktopShell.show());
    if (r.taskId == focusNotificationTask) {
      _router.go(Routes.focus);
      return;
    }
    final repo = ref.read(repositoryProvider);
    await applyReminderResponse(repo, r, ref.read(clockProvider).now());
    if (r.action != NotificationAction.open) return;
    try {
      final task = await repo.task(r.taskId);
      if (task.deletedAt == null) _router.go(Routes.of(ListScope(task.listId), taskId: task.id));
    } on StateError {
      // The task is gone.
    }
  }

  @override
  void dispose() {
    _focusRestorer.detach();
    _syncDebounce?.cancel();
    _widgetDebounce?.cancel();
    _periodicSync?.cancel();
    _popupTimer?.cancel();
    _muteTimer?.cancel();
    _autoBackup?.cancel();
    unawaited(_responses?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final theme = prefs.theme;
    DateConventions.firstWeekday = prefs.firstWeekday;
    DateConventions.use24h = prefs.use24h;
    DateConventions.weekNumbers = prefs.weekNumbers;
    DateConventions.dateOrder = prefs.dateOrder;
    // The running focus timer in the window title (Configurações de foco).
    ref.listen<String>(windowTitleProvider, (_, title) => unawaited(_windowTitle.set(title)));
    appLocale = prefs.language.locale;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: prefs.language.locale,
      supportedLocales: const [Locale('pt', 'BR'), Locale('pt'), Locale('la')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Flutter has no Latin: its own texts (copy, paste, the system's pickers) stay in Portuguese.
        LatinFallbackDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
        LatinFallbackDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
      ],
      theme: buildTheme(dark: false, series: prefs.colorSeries, accent: parseHexColor(prefs.customAccent)),
      darkTheme: buildTheme(dark: true, series: prefs.colorSeries, accent: parseHexColor(prefs.customAccent)),
      themeMode: switch (theme) {
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.system => ThemeMode.system,
      },
      routerConfig: _router,
      // Touching the app silences the despertador.
      builder: (context, child) => Listener(
        onPointerDown: (_) {
          if (DesktopShell.ringing) unawaited(DesktopShell.stopAlarm());
        },
        child: Stack(
          children: [
            GlobalShortcuts(router: _router, child: child ?? const SizedBox.shrink()),
            ReminderPopups(onOpen: _openTask, navigatorContext: () => _router.routerDelegate.navigatorKey.currentContext),
          ],
        ),
      ),
    );
  }
}
