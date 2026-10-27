import '../core/clock.dart';
import '../data/db/database.dart';
import 'countdown.dart';
import 'habits.dart';
import 'recurrence.dart';
import 'reminders.dart';
import 'snapshot.dart';
import 'task_dates.dart';

/// "Som do lembrete" (Configurações → Notificações): the "Despertador", the system's sound or none.
enum ReminderSound { alarmClock, standard, silent }

/// One operating-system notification that should exist right now.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.taskId,
    required this.at,
    required this.title,
    required this.due,
    required this.isAllDay,
    this.body,
    this.persistent = false,
    this.itemId,
    this.sound = ReminderSound.standard,
  });

  /// Stable notification id derived from the task and the trigger (see [notificationId]).
  final int id;
  final String taskId;

  /// Local time the notification fires.
  final DateTime at;
  final String title;

  /// Local due date/time, for the notification body ("Hoje, 18:48").
  final DateTime due;
  final bool isAllDay;

  /// Fixed body text (the daily digest); task reminders show their date instead.
  final String? body;

  /// "Lembrete Constante": the notification stays until the user acts.
  final bool persistent;

  /// Set for the reminder of a checklist item; [title] is the item, [body] the task.
  final String? itemId;

  final ReminderSound sound;

  /// The same reminder with [sound].
  PlannedReminder withSound(ReminderSound sound) => PlannedReminder(
    id: id,
    taskId: taskId,
    at: at,
    title: title,
    due: due,
    isAllDay: isAllDay,
    body: body,
    persistent: persistent,
    itemId: itemId,
    sound: sound,
  );

  /// Task id, or `taskId/itemId` for a checklist item: what [keepsFiredReminders] checks.
  String get owner => itemId == null ? taskId : '$taskId/$itemId';

  /// The daily digest ("Notificações diárias") uses `daily:yyyymmdd` as its task id.
  bool get isDigest => taskId.startsWith(dailyDigestPrefix);

  /// Countdown reminders use `countdown:<id>` as their task id.
  bool get isCountdown => taskId.startsWith(countdownPrefix);

  /// Habit reminders use `habit:<id>` as their task id.
  bool get isHabit => taskId.startsWith(habitPrefix);

  /// Finance reminders (recurring bills, loans) use `finance:…` as their task id.
  bool get isFinance => taskId.startsWith(financePrefix);

  /// Changes whenever the notification must be replaced. Starts with the fire time and the task id
  /// (see [signatureTime] and [signatureTaskId]).
  String get signature => '${at.toIso8601String()}|$owner|${due.toIso8601String()}|$isAllDay|$persistent|$title|${body ?? ''}|${sound.name}';

  static DateTime? signatureTime(String signature) => DateTime.tryParse(signature.split('|').first);

  static String? signatureTaskId(String signature) {
    final parts = signature.split('|');
    return parts.length > 1 ? parts[1] : null;
  }

  @override
  String toString() => 'PlannedReminder($taskId at $at)';
}

/// Key used for the snoozed reminder of a task.
const snoozeKey = 'snooze';

const dailyDigestPrefix = 'daily:';

const countdownPrefix = 'countdown:';

const habitPrefix = 'habit:';

/// Finanças: `finance:recurring:<id>` and `finance:loan:<id>`.
const financePrefix = 'finance:';

String dailyDigestId(DateTime day) => '$dailyDigestPrefix${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

/// 31-bit FNV-1a hash of task id + trigger: Android and Windows need an int id that survives restarts.
int notificationId(String taskId, String key) {
  var hash = 0x811c9dc5;
  for (final unit in '$taskId|$key'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// Reminders of open tasks that fire after [now] and within [horizon], soonest first, at most [limit]
/// (Android keeps at most 500 alarms per app). Reconciled again whenever the data changes or the app
/// starts, so later reminders are scheduled as time goes by.
List<PlannedReminder> planReminders(
  Snapshot s,
  DateTime now, {
  Duration horizon = const Duration(days: 60),
  int limit = 200,
  bool persistent = false,
}) {
  final end = now.add(horizon);
  final planned = <PlannedReminder>[];
  for (final task in s.tasks) {
    // Tasks of archived or deleted lists do not remind.
    final list = s.listById[task.listId];
    if (!Snapshot.isOpen(task) || list == null || list.deletedAt != null || list.archivedAt != null) continue;
    // Reminders count from the start (the due date when there is no duration).
    final due = task.startLocal;
    if (due == null) continue;
    final triggers = s.remindersOf(task.id);
    final stays = persistent || triggers.contains(ReminderPresets.constant);
    void add(String key, DateTime at) {
      if (at.isAfter(now) && !at.isAfter(end)) {
        planned.add(
          PlannedReminder(
            id: notificationId(task.id, key),
            taskId: task.id,
            at: at,
            title: task.title,
            due: due,
            isAllDay: task.isAllDay,
            persistent: stays,
          ),
        );
      }
    }

    for (final trigger in ReminderPresets.firing(triggers)) {
      final DateTime at;
      if (trigger == ReminderPresets.atEnd) {
        // "No fim": the end of a timed task; 09:00 of the last day of an all-day one.
        final end = task.endLocal;
        if (end == null) continue;
        at = task.isAllDay ? DateTime(end.year, end.month, end.day, 9) : end;
        add(trigger, at);
        continue;
      }
      try {
        at = fireTime(due, trigger);
      } on FormatException {
        continue;
      }
      add(trigger, at);
    }
    final snooze = task.snoozeUntil;
    if (snooze != null) add(snoozeKey, snooze.toLocal());
  }
  // Checklist item reminders: at the item's time, or 09:00 on its day when all-day.
  for (final item in s.checklistItems) {
    final task = s.taskById[item.taskId];
    final list = task == null ? null : s.listById[task.listId];
    final date = item.dueDate?.toLocal();
    if (task == null || !Snapshot.isOpen(task) || list == null || list.deletedAt != null || list.archivedAt != null) continue;
    if (date == null || item.isCompleted || item.deletedAt != null) continue;
    final at = item.isAllDay ? DateTime(date.year, date.month, date.day, 9) : date;
    if (at.isAfter(now) && !at.isAfter(end)) {
      planned.add(
        PlannedReminder(
          id: notificationId(task.id, 'item:${item.id}'),
          taskId: task.id,
          itemId: item.id,
          at: at,
          title: item.title,
          body: task.title,
          due: date,
          isAllDay: item.isAllDay,
          persistent: persistent,
        ),
      );
    }
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.length > limit ? planned.sublist(0, limit) : planned;
}

/// "Notificações diárias": for each of the next [days] days, the tasks of that day's
/// "Hoje" (open, in smart lists, started or due by then, overdue included) and the alert time at
/// [minutes] after midnight. Days without tasks and times already past are left out.
List<({DateTime at, List<Task> tasks})> planDailyDigests(Snapshot s, DateTime now, int minutes, {int days = 7}) {
  final today = startOfDay(now);
  final digests = <({DateTime at, List<Task> tasks})>[];
  for (var i = 0; i < days; i++) {
    final day = today.add(Duration(days: i));
    final at = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
    if (!at.isAfter(now)) continue;
    final tasks = [
      for (final t in s.tasks)
        if (Snapshot.isOpen(t) && s.inSmartLists(t) && (t.daysToStart(day) ?? 1) <= 0) t,
    ]..sort((a, b) => (a.startDate ?? a.dueDate!).compareTo(b.startDate ?? b.dueDate!));
    if (tasks.isNotEmpty) digests.add((at: at, tasks: tasks));
  }
  return digests;
}

/// Whether an already-fired notification stays on screen: its task is open and still has a date or,
/// for a checklist item ([PlannedReminder.owner] `taskId/itemId`), the item is still open.
bool keepsFiredReminders(Snapshot s, String owner) {
  final [taskId, ...rest] = owner.split('/');
  final task = s.taskById[taskId];
  if (task == null || !Snapshot.isOpen(task)) return false;
  if (rest.isEmpty) return task.dueDate != null;
  final item = s.itemsOf(taskId).where((i) => i.id == rest.first).firstOrNull;
  return item != null && !item.isCompleted && item.dueDate != null;
}

/// Countdown reminders: triggers from the countdown's day at midnight ("No dia (09:00)",
/// "1 dia antes"…), for its next day and, when it repeats, the one after. [body] gives the card text.
List<PlannedReminder> planCountdownReminders(
  Snapshot s,
  DateTime now,
  String Function(Countdown c, DateTime day) body, {
  Duration horizon = const Duration(days: 60),
  bool persistent = false,
}) {
  final end = now.add(horizon);
  final planned = <PlannedReminder>[];
  for (final c in s.countdowns) {
    // One that follows a habit has no fixed day to remind of.
    if (c.archivedAt != null || c.deletedAt != null || c.reminders.isEmpty || countdownFollowsHabit(c)) continue;
    // Reminders go by the next occurrence, even when the card counts up.
    final first = countdownStatus(c, now, countUp: false).target;
    final triggers = c.reminders.split(',').where((t) => t.isNotEmpty).toList();
    final stays = persistent || triggers.contains(ReminderPresets.constant);
    final rule = c.repeatRule;
    final next = rule == null ? null : occurrenceOnOrAfter(rule: rule, start: countdownDate(c), day: first.add(const Duration(days: 1)));
    for (final day in [first, ?next]) {
      for (final trigger in ReminderPresets.firing(triggers)) {
        final DateTime at;
        try {
          at = fireTime(day, trigger);
        } on FormatException {
          continue;
        }
        if (!at.isAfter(now) || at.isAfter(end)) continue;
        planned.add(
          PlannedReminder(
            id: notificationId('$countdownPrefix${c.id}', '$trigger@${day.toIso8601String()}'),
            taskId: '$countdownPrefix${c.id}',
            at: at,
            title: c.name,
            body: body(c, at),
            due: day,
            isAllDay: true,
            persistent: stays,
          ),
        );
      }
    }
  }
  return planned;
}

/// Habit reminders: the chosen times on the next [days] due days, skipping days already
/// done.
List<PlannedReminder> planHabitReminders(Snapshot s, DateTime now, {int days = 7, bool persistent = false}) {
  final today = startOfDay(now);
  final planned = <PlannedReminder>[];
  for (final h in s.habits) {
    if (h.archivedAt != null || h.reminders.isEmpty) continue;
    for (var i = 0; i < days; i++) {
      final day = today.add(Duration(days: i));
      if (!habitIsDue(h, day)) continue;
      final checkin = s.checkinsOf(h.id).where((c) => daysBetween(habitDay(c.day), day) == 0).firstOrNull;
      if (habitDayState(h, checkin, day) == HabitDayState.done) continue;
      for (final time in h.reminders.split(',')) {
        final parts = time.split(':');
        if (parts.length != 2) continue;
        final at = DateTime(day.year, day.month, day.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
        if (!at.isAfter(now)) continue;
        planned.add(
          PlannedReminder(
            id: notificationId('$habitPrefix${h.id}', '$time@${day.toIso8601String()}'),
            taskId: '$habitPrefix${h.id}',
            at: at,
            title: h.name,
            body: '',
            due: day,
            isAllDay: true,
            persistent: persistent,
          ),
        );
      }
    }
  }
  return planned;
}
