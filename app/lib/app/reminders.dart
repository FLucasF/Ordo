import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/db/database.dart';
import '../data/finance_repository.dart';
import '../data/preferences_repository.dart';
import '../data/repository.dart';
import '../domain/countdown.dart';
import '../domain/enums.dart';
import '../domain/finance/finance.dart';
import '../domain/finance/finance_reminders.dart';
import '../domain/finance/money.dart';
import '../domain/reminder_plan.dart';
import '../domain/snapshot.dart';
import '../features/countdown/countdown_card.dart';
import '../l10n/app_localizations.dart';
import '../platform/notifications.dart';
import '../platform/reminder_scheduler.dart';
import 'format/date_labels.dart';
import '../core/app_folder.dart';

/// How long "Adiar" on a notification postpones the reminder.
const snoozeDuration = Duration(minutes: 15);

/// Everything the app needs to keep OS reminders in sync; absent in tests and on unsupported platforms.
class ReminderSetup {
  const ReminderSetup({required this.service, required this.scheduler, required this.responses, this.launchResponse});

  final NotificationService service;
  final ReminderScheduler scheduler;
  final Stream<ReminderResponse> responses;

  /// The notification that opened the app, handled once the UI is up.
  final ReminderResponse? launchResponse;
}

final reminderSetupProvider = Provider<ReminderSetup?>((ref) => null);

/// The language of the texts built outside the widget tree (notifications, the tray, the widgets),
/// set by the app from its preferences.
Locale appLocale = const Locale('pt', 'BR');

AppLocalizations get reminderTexts => lookupAppLocalizations(appLocale);

NotificationTexts notificationTexts(AppLocalizations t) => NotificationTexts(
  appName: t.appTitle,
  channelName: t.notificationChannelName,
  channelDescription: t.notificationChannelDescription,
  silentChannelName: t.notificationSilentChannelName,
  alarmChannelName: t.notificationAlarmChannelName,
  alarmClockChannelName: t.notificationAlarmClockChannelName,
  focusChannelName: t.notificationFocusChannelName,
  complete: t.notificationActionComplete,
  snooze: t.notificationActionSnooze,
  stop: t.notificationActionStop,
);

/// Schedules [PlannedReminder]s as OS notifications: the task title and its date ("Hoje, 18:48").
class OsNotificationGateway implements NotificationGateway {
  OsNotificationGateway(this._service, this._t);

  final NotificationService _service;
  final AppLocalizations _t;

  @override
  Future<void> schedule(PlannedReminder r) => scheduleReminder(r);

  /// [muted]: on Windows, when the app itself plays the despertador at that moment.
  Future<void> scheduleReminder(PlannedReminder r, {bool muted = false}) => _service.schedule(
    id: r.id,
    taskId: r.taskId,
    itemId: r.itemId,
    title: r.title.isEmpty ? _t.untitled : r.title,
    body: r.body ?? DateLabels(_t).detailDate(r.due, isAllDay: r.isAllDay, today: startOfDay(r.at)),
    at: r.at,
    withActions: !r.isDigest && !r.isCountdown && !r.isHabit && !r.isFinance,
    persistent: r.persistent,
    reminderSound: r.sound,
    muted: muted,
  );

  @override
  Future<void> cancel(int id) => _service.cancel(id);
}

/// Does what a notification button asked for. "Concluído" completes an open task (a repeating one
/// moves to its next date) or checks a checklist item; "Adiar" fires the reminder again in [snoozeDuration].
Future<void> applyReminderResponse(Repository repo, ReminderResponse r, DateTime now) async {
  final Task task;
  try {
    task = await repo.task(r.taskId);
  } on StateError {
    return; // deleted for good meanwhile
  }
  if (task.deletedAt != null || task.status != TaskStatus.open) return;
  final itemId = r.itemId;
  if (itemId != null) {
    // Checklist item: "Concluído" checks it (the last one completes the task).
    if (r.action == NotificationAction.complete) await repo.setChecklistItemCompleted(itemId, completed: true);
    return;
  }
  switch (r.action) {
    case NotificationAction.complete:
      await repo.complete(r.taskId);
    case NotificationAction.snooze:
      await repo.snooze(r.taskId, now.add(snoozeDuration));
    case NotificationAction.open:
      break;
  }
}

/// Brings the OS notifications in line with [snapshot], [finance] and [prefs]: task reminders, the
/// daily digest, habits, countdowns, recurring bills and loans.
Future<void> syncReminders(
  ReminderScheduler scheduler,
  Snapshot snapshot,
  Preferences prefs,
  DateTime now,
  AppLocalizations t, {
  FinanceSnapshot? finance,
}) {
  // "Som do lembrete" for tasks, habits and countdowns; the daily summary keeps the system's sound.
  final sound = prefs.reminderSound;
  final plan = [
    for (final r in planReminders(snapshot, now, persistent: prefs.constantReminder)) r.withSound(sound),
    ...dailyDigestReminders(snapshot, prefs, now, t),
    for (final r in planHabitReminders(snapshot, now, persistent: prefs.constantReminder)) r.withSound(sound),
    for (final r in planCountdownReminders(
      snapshot,
      now,
      (c, at) => countdownLegend(t, c, countdownStatus(c, at)),
      persistent: prefs.constantReminder,
    ))
      r.withSound(sound),
    if (finance != null && prefs.has(AppFeature.finance))
      for (final r in planFinanceReminders(finance, now, title: (a) => financeAlertTitle(t, a), body: (a) => formatMoney(a.amount)))
        r.withSound(sound),
  ];
  final today = dailyDigestId(now);
  return scheduler.sync(
    plan,
    now: now,
    // A fired digest stays for its own day; a task reminder while the task is open.
    keepFired: (id) => switch (id) {
      _ when id.startsWith(dailyDigestPrefix) => id == today,
      // A countdown's notification stays while the countdown exists and is not archived.
      _ when id.startsWith(habitPrefix) => snapshot.habits.any((h) => '$habitPrefix${h.id}' == id && h.archivedAt == null),
      _ when id.startsWith(countdownPrefix) => snapshot.countdowns.any((c) => '$countdownPrefix${c.id}' == id && c.archivedAt == null),
      _ when id.startsWith(financePrefix) => finance != null && keepsFinanceReminder(finance, id),
      _ => keepsFiredReminders(snapshot, id),
    },
  );
}

/// "Notificações diárias" as notifications: "Você tem 3 tarefas para hoje" and the first titles.
List<PlannedReminder> dailyDigestReminders(Snapshot snapshot, Preferences prefs, DateTime now, AppLocalizations t) {
  final minutes = prefs.dailyAlert;
  if (minutes == null) return const [];
  return [
    for (final d in planDailyDigests(snapshot, now, minutes))
      PlannedReminder(
        id: notificationId(dailyDigestId(d.at), 'digest'),
        taskId: dailyDigestId(d.at),
        at: d.at,
        title: t.dailyDigestTitle(d.tasks.length),
        body: [for (final task in d.tasks.take(3)) task.title.isEmpty ? t.untitled : task.title].join(', ') + (d.tasks.length > 3 ? '…' : ''),
        due: startOfDay(d.at),
        isAllDay: true,
      ),
  ];
}

/// Starts notifications on Android and Windows. Failures are logged, never fatal: the app works
/// without reminders.
Future<ReminderSetup?> initializeReminders() async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isWindows)) return null;
  // A debug run beside the installed app must not take over its notifications.
  if (isolatedDataDir != null) return null;
  try {
    final t = reminderTexts;
    final service = NotificationService(notificationTexts(t));
    // Lives as long as the app.
    // ignore: close_sinks
    final responses = StreamController<ReminderResponse>.broadcast();
    await service.initialize(
      onResponse: (response) {
        final r = ReminderResponse.decode(response);
        if (r != null) responses.add(r);
      },
      onBackgroundResponse: onBackgroundNotificationResponse,
    );
    final launch = await service.launchResponse();
    return ReminderSetup(
      service: service,
      scheduler: ReminderScheduler(OsNotificationGateway(service, t), FileScheduledStore()),
      responses: responses.stream,
      launchResponse: launch == null ? null : ReminderResponse.decode(launch),
    );
  } on Object catch (e, stack) {
    debugPrint('Reminders unavailable: $e\n$stack');
    return null;
  }
}

/// Android runs this in a background isolate when a notification button is pressed with the app
/// closed: applies the action and reschedules (the snoozed reminder, or dismissing the rest).
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(NotificationResponse response) async {
  final r = ReminderResponse.decode(response);
  if (r == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  try {
    final repo = Repository(db);
    final now = DateTime.now();
    await applyReminderResponse(repo, r, now);
    final t = reminderTexts;
    final service = NotificationService(notificationTexts(t));
    await service.initialize(onResponse: (_) {});
    final scheduler = ReminderScheduler(OsNotificationGateway(service, t), FileScheduledStore());
    final prefs = await PreferencesRepository(db).watch().first;
    await syncReminders(scheduler, await repo.loadSnapshot(), prefs, now, t, finance: await FinanceRepository(db).load());
  } finally {
    await db.close();
  }
}

/// Reminders that fired while the app was open, shown as in-app popups.
class FiredReminders extends Notifier<List<PlannedReminder>> {
  @override
  List<PlannedReminder> build() => const [];

  static bool _same(PlannedReminder a, PlannedReminder b) => a.id == b.id && a.at == b.at;

  void add(Iterable<PlannedReminder> fired) => state = [
    ...state,
    for (final r in fired)
      if (!state.any((s) => _same(s, r))) r,
  ];

  void remove(PlannedReminder r) => state = [...state.where((s) => !_same(s, r))];
}

final firedRemindersProvider = NotifierProvider<FiredReminders, List<PlannedReminder>>(FiredReminders.new);

/// "Aluguel vence hoje", "Internet vence em 12/10", "Hoje vence o empréstimo de João"…
String financeAlertTitle(AppLocalizations t, FinanceAlert a) => switch (a.kind) {
  FinanceAlertKind.billDue => t.finReminderBillTitle(a.name),
  FinanceAlertKind.billSoon => t.finReminderBillSoon(a.name, DateLabels.numeric(a.due, withYear: false)),
  FinanceAlertKind.loanDue => t.finReminderLoanDue(a.name),
  FinanceAlertKind.loanLate => t.finReminderLoanLate(a.name),
};
