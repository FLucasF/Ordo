import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../app/format/date_labels.dart';
import '../app/theme/app_theme.dart';
import '../core/clock.dart';
import '../domain/calendar.dart';
import '../domain/snapshot.dart';
import '../domain/subscriptions.dart';
import '../features/calendar/calendar_widgets.dart';
import '../l10n/app_localizations.dart';
import '../core/app_folder.dart';

// The phone's home-screen calendar widget (Android) and the desktop mini calendar (Windows): the app writes what it shows (the days around
// today with their entries, colors and texts) to a JSON file in its files folder, and the widget
// (android/.../CalendarWidget.kt) draws it as a day, a week or a month. The widget asks the app to
// open a day or create a task through the launch intent.

const _channel = MethodChannel('tarefas/widget');

/// The file the Android widget reads (`context.filesDir/calendar_widget.json`).
const calendarWidgetFile = 'calendar_widget.json';

/// The days written: from a month and a half before today to four months after (the widget's arrows
/// go that far).
({DateTime from, DateTime to}) calendarWidgetRange(DateTime today) =>
    (from: today.subtract(const Duration(days: 45)), to: today.add(const Duration(days: 120)));

String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// What the widget shows: the texts, the week's first day, today, and each day's entries (all-day
/// ones first, then by time) as {title, color, start and end minutes (-1 all day), done}.
Map<String, Object?> calendarWidgetData({
  required Snapshot snapshot,
  required CalendarOptions options,
  required List<CalendarSubscription> subscriptions,
  required TtColors colors,
  required AppLocalizations t,
  required DateTime now,
  List<CalendarEntry> extra = const [],
  List<SubscribedEvent> events = const [],
}) {
  final today = startOfDay(now);
  final (:from, :to) = calendarWidgetRange(today);
  final entries = [...calendarEntries(snapshot, from, to, options, now: now, events: events), ...extra];
  final byDay = <String, List<(CalendarEntry, Map<String, Object?>)>>{};
  for (final e in entries) {
    final color = _hex(calendarEntryColor(e, snapshot, options, colors, subscriptions));
    for (var d = e.firstDay; !d.isAfter(e.lastDay); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.isBefore(from) || !d.isBefore(to)) continue;
      // On its first day a timed entry shows its start (and its end, that day or midnight); on the
      // next ones it's there all day.
      final timed = !e.isAllDay && d == e.firstDay;
      final start = e.start.hour * 60 + e.start.minute;
      final end = !e.end.isAfter(e.start)
          ? -1
          : startOfDay(e.end) == d
          ? e.end.hour * 60 + e.end.minute
          : 24 * 60;
      byDay.putIfAbsent(_day(d), () => []).add((
        e,
        {'t': e.title.isEmpty ? t.untitled : e.title, 'c': color, 's': timed ? start : -1, 'e': timed ? end : -1, 'd': e.isDone},
      ));
    }
  }
  final labels = DateLabels(t);
  return {
    'v': 1,
    'today': _day(today),
    'firstWeekday': DateConventions.firstWeekday,
    'primary': _hex(colors.primary),
    'labels': {
      'day': t.widgetDay,
      'week': t.widgetWeek,
      'month': t.widgetMonth,
      'empty': t.widgetEmpty,
      'allDay': t.widgetAllDay,
      // The desktop mini calendar's own texts.
      'layerTop': t.miniLayerTop,
      'layerNormal': t.miniLayerNormal,
      'layerDesktop': t.miniLayerDesktop,
      'close': t.miniClose,
      'months': [for (var m = 1; m <= 12; m++) labels.monthLong(DateTime(2026, m))],
      // Monday first, as DateTime.weekday.
      'weekdays': [for (var d = 0; d < 7; d++) labels.weekdayShort(DateTime(2026, 9, 28 + d))],
    },
    'days': {
      for (final MapEntry(key: day, value: list) in byDay.entries)
        day: [for (final (_, json) in list..sort((a, b) => _order(a.$2).compareTo(_order(b.$2)))) json],
    },
  };
}

int _order(Map<String, Object?> e) => e['s']! as int;

/// Writes the data and asks the widgets on the home screen to redraw (Android); on Windows the mini
/// calendar (lib/features/mini_calendar) follows the file by itself.
Future<void> exportCalendarWidget(Map<String, Object?> data) async {
  if (!Platform.isAndroid && !Platform.isWindows) return;
  final dir = await appDataDirectory();
  final file = File(p.join(dir.path, calendarWidgetFile));
  final partial = File('${file.path}.part');
  await partial.writeAsString(jsonEncode(data), flush: true);
  await partial.rename(file.path);
  if (Platform.isAndroid) await _channel.invokeMethod<void>('refresh');
}

/// What a widget tap asks the app: open a day ("open", with the day and the view) or create a task
/// on a day ("create").
typedef WidgetAction = ({String action, DateTime day, String mode});

/// "open|2026-10-09|d" as a [WidgetAction] (null when it is not one).
WidgetAction? parseWidgetAction(Object? raw) => _parse(raw);

WidgetAction? _parse(Object? raw) {
  if (raw is! String) return null;
  final parts = raw.split('|');
  if (parts.length < 3) return null;
  final day = DateTime.tryParse(parts[1]);
  if (day == null) return null;
  return (action: parts[0], day: day, mode: parts[2]);
}

/// The tap that opened the app, if any (taken once), then every later one while it runs.
Future<void> listenCalendarWidget(void Function(WidgetAction action) onAction) async {
  if (!Platform.isAndroid) return;
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'action') {
      if (_parse(call.arguments) case final a?) onAction(a);
    }
  });
  if (_parse(await _channel.invokeMethod<String>('takeAction')) case final a?) onAction(a);
}
