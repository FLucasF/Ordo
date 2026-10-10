import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/reminder_plan.dart';
import '../core/app_folder.dart';

/// Where notifications are scheduled (the OS in the app, a fake in tests).
abstract interface class NotificationGateway {
  Future<void> schedule(PlannedReminder reminder);
  Future<void> cancel(int id);
}

/// Record of what is scheduled with the OS: notification id → [PlannedReminder.signature]. Windows
/// cannot list pending notifications, so the app keeps its own record between runs.
abstract interface class ScheduledStore {
  Future<Map<int, String>> load();
  Future<void> save(Map<int, String> scheduled);
}

class MemoryScheduledStore implements ScheduledStore {
  Map<int, String> value = {};

  @override
  Future<Map<int, String>> load() async => {...value};

  @override
  Future<void> save(Map<int, String> scheduled) async => value = {...scheduled};
}

/// JSON file next to the database; it is device state, so it is not part of backups.
class FileScheduledStore implements ScheduledStore {
  Future<File> _file() async => File(p.join((await appDataDirectory()).path, 'scheduled_reminders.json'));

  @override
  Future<Map<int, String>> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return {};
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) return {};
      return {
        for (final e in json.entries)
          if (int.tryParse(e.key) case final int id when e.value is String) id: e.value! as String,
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> save(Map<int, String> scheduled) async {
    final file = await _file();
    await file.writeAsString(jsonEncode({for (final e in scheduled.entries) '${e.key}': e.value}));
  }
}

/// Makes the OS notifications match the plan: cancels what is gone or changed and schedules what is
/// new or changed. A notification that already fired stays on screen while [keepFired] says its task
/// still needs it (open, with a date), and is dismissed once the task is completed, deleted or
/// rescheduled. Calls are serialized, so rapid data changes never interleave.
class ReminderScheduler {
  ReminderScheduler(this._gateway, this._store);

  final NotificationGateway _gateway;
  final ScheduledStore _store;
  Future<void> _last = Future.value();

  /// Fired notifications older than this are forgotten (left to the OS).
  static const forgetAfter = Duration(days: 7);

  Future<void> sync(List<PlannedReminder> plan, {required DateTime now, required bool Function(String owner) keepFired}) =>
      _last = _last.then((_) => _sync(plan, now, keepFired), onError: (_) => _sync(plan, now, keepFired));

  Future<void> _sync(List<PlannedReminder> plan, DateTime now, bool Function(String owner) keepFired) async {
    final scheduled = await _store.load();
    final wanted = {for (final r in plan) r.id: r};
    for (final entry in scheduled.entries.toList()) {
      final id = entry.key;
      final keep = wanted[id];
      if (keep != null && keep.signature == entry.value) continue;
      final at = PlannedReminder.signatureTime(entry.value);
      final owner = PlannedReminder.signatureTaskId(entry.value);
      final fired = at != null && !at.isAfter(now);
      if (keep == null && fired && owner != null && keepFired(owner)) {
        if (now.difference(at) > forgetAfter) scheduled.remove(id);
        continue;
      }
      await _gateway.cancel(id);
      scheduled.remove(id);
    }
    for (final r in plan) {
      if (scheduled.containsKey(r.id)) continue;
      await _gateway.schedule(r);
      scheduled[r.id] = r.signature;
    }
    await _store.save(scheduled);
  }
}
