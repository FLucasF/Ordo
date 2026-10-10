import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../platform/calendar_home_widget.dart' show calendarWidgetFile;

// The desktop mini calendar (Windows): a small window of its own (windows/runner/mini_window.cpp),
// run by a second Flutter engine from miniCalendarMain (lib/main.dart). It draws what the app writes
// for the phone's home-screen widget (calendar_widget.json, lib/platform/calendar_home_widget.dart)
// as a day, a week or a month, like the phone's widget, and asks the app through the runner to open
// a day or to create a task. It reads no database.

/// One entry of a day, as the app writes it.
class MiniEntry {
  const MiniEntry({required this.title, required this.color, required this.start, required this.end, required this.done});

  factory MiniEntry.fromJson(Map<String, Object?> json) => MiniEntry(
    title: json['t'] as String? ?? '',
    color: _parseColor(json['c']),
    start: (json['s'] as num?)?.toInt() ?? -1,
    end: (json['e'] as num?)?.toInt() ?? -1,
    done: json['d'] == true,
  );

  final String title;
  final Color color;

  /// Minutes of the day; -1 all day.
  final int start;
  final int end;
  final bool done;

  bool get allDay => start < 0;

  /// Half hours it lasts (1 for all-day and short ones), up to four hours.
  int get halfHours => start < 0 || end <= start ? 1 : ((end - start + 15) ~/ 30).clamp(1, 8);
}

Color _parseColor(Object? hex) {
  if (hex is String && hex.length == 7 && hex.startsWith('#')) {
    if (int.tryParse(hex.substring(1), radix: 16) case final v?) return Color(0xFF000000 | v);
  }
  return const Color(0xFF4772FA);
}

String _dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _time(int minute) => '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

/// What the mini calendar shows: the texts, the week's first day and each day's entries.
class MiniCalendarData {
  const MiniCalendarData(this.json);

  /// The file's text; anything unreadable shows an empty calendar.
  factory MiniCalendarData.parse(String? text) {
    try {
      if (jsonDecode(text ?? '') case final Map<String, Object?> json) return MiniCalendarData(json);
    } on FormatException {
      // Not written yet or cut short: empty until the next write.
    }
    return const MiniCalendarData({});
  }

  final Map<String, Object?> json;

  Map<String, Object?> get _labels => (json['labels'] as Map?)?.cast<String, Object?>() ?? const {};

  String label(String key, String fallback) => _labels[key] as String? ?? fallback;

  /// As DateTime.weekday.
  int get firstWeekday => (json['firstWeekday'] as num?)?.toInt() ?? DateTime.sunday;

  String month(int m) {
    final list = _labels['months'] as List?;
    final name = list != null && list.length == 12 ? '${list[m - 1]}' : '$m';
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  }

  /// [weekday] as DateTime.weekday (the file lists them Monday first).
  String weekday(int weekday) {
    final list = _labels['weekdays'] as List?;
    return list != null && list.length == 7 ? '${list[weekday - 1]}' : '$weekday';
  }

  List<MiniEntry> entries(DateTime day) {
    final list = (json['days'] as Map?)?[_dayKey(day)] as List?;
    return [
      for (final e in list ?? const <Object?>[])
        if (e is Map) MiniEntry.fromJson(e.cast<String, Object?>()),
    ];
  }

  DateTime weekStart(DateTime day) => DateTime(day.year, day.month, day.day - (day.weekday - firstWeekday + 7) % 7);
}

/// Where the window stays: above the other windows, among them, or on the desktop below them.
enum MiniLayer { top, normal, desktop }

/// An edge or corner of the window, by the Win32 hit-test code the runner resizes it from.
enum MiniEdge {
  left(10),
  right(11),
  top(12),
  topLeft(13),
  topRight(14),
  bottom(15),
  bottomLeft(16),
  bottomRight(17);

  const MiniEdge(this.hitTest);

  final int hitTest;
}

/// What the mini calendar remembers: the view ("d", "w" or "m") and the layer.
class MiniSettings {
  const MiniSettings({this.mode = 'd', this.layer = MiniLayer.top});

  factory MiniSettings.fromJson(Map<String, Object?> json) => MiniSettings(
    mode: switch (json['mode']) {
      final String m when const {'d', 'w', 'm'}.contains(m) => m,
      _ => 'd',
    },
    layer: MiniLayer.values.asNameMap()[json['layer']] ?? MiniLayer.top,
  );

  final String mode;
  final MiniLayer layer;

  MiniSettings copyWith({String? mode, MiniLayer? layer}) => MiniSettings(mode: mode ?? this.mode, layer: layer ?? this.layer);

  Map<String, Object?> toJson() => {'mode': mode, 'layer': layer.name};
}

/// What the mini calendar asks of its window and of the app.
abstract interface class MiniHost {
  void startDrag();
  void startResize(MiniEdge edge);
  void setLayer(MiniLayer layer);
  void close();

  /// Opens the app on [day] in [mode] (the Calendar's "d", "w" or "m"); [action] "create" also
  /// opens the quick add for that day.
  void open(String action, DateTime day, String mode);
  void save(MiniSettings settings);
}

/// The host of the real window: the runner's "tarefas/mini" channel, and a file beside the data.
class ChannelMiniHost implements MiniHost {
  ChannelMiniHost(this.folder);

  static const _channel = MethodChannel('tarefas/mini');
  static const settingsFile = 'mini_calendar.json';

  final Directory folder;

  Future<MiniSettings> load() async {
    try {
      if (jsonDecode(await File(p.join(folder.path, settingsFile)).readAsString()) case final Map<String, Object?> json) {
        return MiniSettings.fromJson(json);
      }
    } on Object {
      // First run, or a broken file: the defaults.
    }
    return const MiniSettings();
  }

  void _call(String method, [Object? arguments]) =>
      unawaited(_channel.invokeMethod<void>(method, arguments).catchError((Object e) => debugPrint('Mini calendar $method failed: $e')));

  @override
  void startDrag() => _call('startDrag');

  @override
  void startResize(MiniEdge edge) => _call('startResize', edge.hitTest);

  @override
  void setLayer(MiniLayer layer) => _call('setLayer', layer.index);

  @override
  void close() => _call('close');

  @override
  void open(String action, DateTime day, String mode) => _call('action', '$action|${_dayKey(day)}|$mode');

  @override
  void save(MiniSettings settings) => unawaited(
    File(p.join(folder.path, settingsFile)).writeAsString(jsonEncode(settings.toJson())).catchError((Object e) {
      debugPrint('Mini calendar settings not saved: $e');
      return File('');
    }),
  );
}

/// The window's app: reads the app's file in [folder] and follows its changes, and today at midnight.
class MiniCalendarWindow extends StatefulWidget {
  const MiniCalendarWindow({super.key, required this.folder, required this.host, required this.settings});

  final Directory folder;
  final MiniHost host;
  final MiniSettings settings;

  @override
  State<MiniCalendarWindow> createState() => _MiniCalendarWindowState();
}

class _MiniCalendarWindowState extends State<MiniCalendarWindow> {
  MiniCalendarData _data = const MiniCalendarData({});
  DateTime _today = DateTime.now();
  StreamSubscription<FileSystemEvent>? _watch;
  Timer? _debounce;
  Timer? _midnight;
  Timer? _poll;
  DateTime? _modified;

  File get _file => File(p.join(widget.folder.path, calendarWidgetFile));

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // The app rewrites the file (to a ".part", then renamed) whenever its data changes.
    _watch = widget.folder.watch().where((e) => p.basename(e.path) == calendarWidgetFile).listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () => unawaited(_load()));
    }, onError: (Object e) => debugPrint('Mini calendar not watching: $e'));
    // In case a change was missed.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => unawaited(_load(onlyIfChanged: true)));
    _armMidnight();
  }

  Future<void> _load({bool onlyIfChanged = false}) async {
    try {
      final modified = await _file.lastModified();
      if (onlyIfChanged && modified == _modified) return;
      final text = await _file.readAsString();
      _modified = modified;
      if (mounted) setState(() => _data = MiniCalendarData.parse(text));
    } on FileSystemException {
      // Not written yet: the app writes it once its data is loaded.
    }
  }

  void _armMidnight() {
    final now = DateTime.now();
    _midnight = Timer(DateTime(now.year, now.month, now.day + 1).difference(now) + const Duration(seconds: 5), () {
      if (mounted) setState(() => _today = DateTime.now());
      _armMidnight();
    });
  }

  @override
  void dispose() {
    unawaited(_watch?.cancel());
    _debounce?.cancel();
    _midnight?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, colorSchemeSeed: _MiniColors.primary),
    home: MiniCalendar(data: _data, today: _today, host: widget.host, settings: widget.settings),
  );
}

abstract final class _MiniColors {
  static const background = Color(0xFF232733);
  static const primary = Color(0xFF4772FA);
  static const pill = Color(0x404772FA);
  static const text = Colors.white;
  static const secondary = Color(0x99FFFFFF);
  static const tertiary = Color(0x66FFFFFF);
  static const line = Color(0x26FFFFFF);
}

/// The mini calendar itself: the title with ‹ › and "+", Dia / Semana / Mês, where the window stays,
/// and the chosen view; its edges resize the window and its empty top drags it.
class MiniCalendar extends StatefulWidget {
  const MiniCalendar({super.key, required this.data, required this.today, required this.host, required this.settings});

  final MiniCalendarData data;
  final DateTime today;
  final MiniHost host;
  final MiniSettings settings;

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late MiniSettings _settings = widget.settings;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    widget.host.setLayer(_settings.layer);
  }

  void _change(MiniSettings settings) {
    setState(() => _settings = settings);
    widget.host.save(settings);
  }

  DateTime get _today => DateTime(widget.today.year, widget.today.month, widget.today.day);

  /// The day, the week's first day or the month's first day shown.
  DateTime get _anchor => switch (_settings.mode) {
    'd' => DateTime(_today.year, _today.month, _today.day + _offset),
    'w' => () {
      final start = widget.data.weekStart(_today);
      return DateTime(start.year, start.month, start.day + 7 * _offset);
    }(),
    _ => DateTime(_today.year, _today.month + _offset),
  };

  String _title(DateTime anchor) {
    final data = widget.data;
    String short(int m) => data.month(m).substring(0, math.min(3, data.month(m).length)).toLowerCase();
    switch (_settings.mode) {
      case 'd':
        return '${data.weekday(anchor.weekday)}, ${anchor.day} ${data.month(anchor.month).toLowerCase()}';
      case 'w':
        final end = DateTime(anchor.year, anchor.month, anchor.day + 6);
        return anchor.month == end.month
            ? '${anchor.day}–${end.day} ${short(end.month)}'
            : '${anchor.day} ${short(anchor.month)} – ${end.day} ${short(end.month)}';
      default:
        return '${data.month(anchor.month)} ${anchor.year}';
    }
  }

  /// The day "+" creates on: the day shown, or today when it is in the week or month shown.
  DateTime _createDay(DateTime anchor) => switch (_settings.mode) {
    'd' => anchor,
    'w' => !_today.isBefore(anchor) && _today.isBefore(DateTime(anchor.year, anchor.month, anchor.day + 7)) ? _today : anchor,
    _ => _today.year == anchor.year && _today.month == anchor.month ? _today : anchor,
  };

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final anchor = _anchor;
    final host = widget.host;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _offset = 0),
                  onPanStart: (_) => host.startDrag(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _title(anchor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _MiniColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              _IconTap(icon: Icons.chevron_left, onTap: () => setState(() => _offset--)),
              _IconTap(icon: Icons.chevron_right, onTap: () => setState(() => _offset++)),
              const SizedBox(width: 4),
              _AddButton(onTap: () => host.open('create', _createDay(anchor), _settings.mode)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (mode, label) in [('d', data.label('day', 'Dia')), ('w', data.label('week', 'Semana')), ('m', data.label('month', 'Mês'))])
                _ModePill(
                  label: label,
                  selected: _settings.mode == mode,
                  onTap: () {
                    _offset = 0;
                    _change(_settings.copyWith(mode: mode));
                  },
                ),
              Expanded(
                child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => host.startDrag(), child: const SizedBox(height: 28)),
              ),
              _LayerMenu(
                data: data,
                layer: _settings.layer,
                onChanged: (layer) {
                  host.setLayer(layer);
                  _change(_settings.copyWith(layer: layer));
                },
              ),
              _IconTap(icon: Icons.close, size: 16, tooltip: data.label('close', 'Fechar'), onTap: host.close),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: switch (_settings.mode) {
              'd' => _DayView(data: data, day: anchor, onOpen: () => host.open('open', anchor, 'd')),
              'w' => _GridView(data: data, first: anchor, weeks: 1, today: _today, month: null, onOpen: (day) => host.open('open', day, 'd')),
              _ => _GridView(
                data: data,
                first: data.weekStart(anchor),
                weeks: data.weekStart(anchor).add(const Duration(days: 35)).month == anchor.month ? 6 : 5,
                today: _today,
                month: anchor,
                onOpen: (day) => host.open('open', day, 'd'),
              ),
            },
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: _MiniColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: content),
          ..._ResizeEdges.build(host),
        ],
      ),
    );
  }
}

/// Thin strips along the edges and corners: the resize cursors, and pressing one resizes the window.
abstract final class _ResizeEdges {
  static const _edge = 5.0;
  static const _corner = 12.0;

  static List<Widget> build(MiniHost host) {
    Widget grip(MiniEdge edge, MouseCursor cursor) => MouseRegion(
      cursor: cursor,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (e.buttons == kPrimaryButton) host.startResize(edge);
        },
      ),
    );
    return [
      Positioned(left: _corner, right: _corner, top: 0, height: _edge, child: grip(MiniEdge.top, SystemMouseCursors.resizeUpDown)),
      Positioned(left: _corner, right: _corner, bottom: 0, height: _edge, child: grip(MiniEdge.bottom, SystemMouseCursors.resizeUpDown)),
      Positioned(top: _corner, bottom: _corner, left: 0, width: _edge, child: grip(MiniEdge.left, SystemMouseCursors.resizeLeftRight)),
      Positioned(top: _corner, bottom: _corner, right: 0, width: _edge, child: grip(MiniEdge.right, SystemMouseCursors.resizeLeftRight)),
      Positioned(left: 0, top: 0, width: _corner, height: _edge, child: grip(MiniEdge.topLeft, SystemMouseCursors.resizeUpLeftDownRight)),
      Positioned(right: 0, top: 0, width: _corner, height: _edge, child: grip(MiniEdge.topRight, SystemMouseCursors.resizeUpRightDownLeft)),
      Positioned(left: 0, bottom: 0, width: _corner, height: _corner, child: grip(MiniEdge.bottomLeft, SystemMouseCursors.resizeUpRightDownLeft)),
      Positioned(right: 0, bottom: 0, width: _corner, height: _corner, child: grip(MiniEdge.bottomRight, SystemMouseCursors.resizeUpLeftDownRight)),
    ];
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.onTap, this.size = 20, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
    icon: Icon(icon, size: size, color: _MiniColors.secondary),
    onPressed: onTap,
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _MiniColors.primary,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: const SizedBox(width: 38, height: 28, child: Icon(Icons.add, size: 20, color: Colors.white)),
    ),
  );
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _MiniColors.pill : Colors.transparent,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(label, style: const TextStyle(color: _MiniColors.text, fontSize: 12)),
      ),
    ),
  );
}

/// The pin: "Por cima das janelas", "Normal" or "Na área de trabalho".
class _LayerMenu extends StatelessWidget {
  const _LayerMenu({required this.data, required this.layer, required this.onChanged});

  final MiniCalendarData data;
  final MiniLayer layer;
  final ValueChanged<MiniLayer> onChanged;

  String _label(MiniLayer l) => switch (l) {
    MiniLayer.top => data.label('layerTop', 'Por cima das janelas'),
    MiniLayer.normal => data.label('layerNormal', 'Normal'),
    MiniLayer.desktop => data.label('layerDesktop', 'Na área de trabalho'),
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 30,
    child: PopupMenuButton<MiniLayer>(
      tooltip: _label(layer),
      padding: EdgeInsets.zero,
      iconSize: 18,
      icon: Icon(switch (layer) {
        MiniLayer.top => Icons.push_pin,
        MiniLayer.normal => Icons.push_pin_outlined,
        MiniLayer.desktop => Icons.desktop_windows_outlined,
      }, color: layer == MiniLayer.top ? _MiniColors.primary : _MiniColors.secondary),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final l in MiniLayer.values)
          PopupMenuItem(
            value: l,
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 22, child: l == layer ? const Icon(Icons.check, size: 16) : null),
                Flexible(
                  child: Text(_label(l), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// The day as a timeline: each entry as tall as it lasts, sharing the room the window has (and a
/// little for a free hour between two); a list that scrolls when they don't all fit.
class _DayView extends StatelessWidget {
  const _DayView({required this.data, required this.day, required this.onOpen});

  final MiniCalendarData data;
  final DateTime day;
  final VoidCallback onOpen;

  static const _line = 30.0;
  static const _end = 14.0;
  static const _gap = 6.0;

  static double _minHeight(MiniEntry e) => e.halfHours > 1 ? _line + _end : _line;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries(day);
    if (entries.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(data.label('empty', 'Nada neste dia'), style: const TextStyle(color: _MiniColors.tertiary, fontSize: 13)),
        ),
      );
    }
    // Entries and the free hours between them: (entry or null for a gap, weight).
    final pieces = <(MiniEntry?, int)>[];
    var cursor = -1;
    for (final e in entries) {
      if (!e.allDay && cursor >= 0 && e.start - cursor >= 60) pieces.add((null, e.start - cursor >= 180 ? 2 : 1));
      pieces.add((e, e.halfHours));
      if (!e.allDay) cursor = math.max(cursor, e.end > e.start ? e.end : e.start + 30);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final need = pieces.fold(0.0, (sum, x) => sum + (x.$1 == null ? _gap : _minHeight(x.$1!)));
        if (need > constraints.maxHeight) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [for (final e in entries) _EntryLine(entry: e, height: _minHeight(e), onTap: onOpen)],
          );
        }
        // A little under the room, so rounding never overflows it.
        final extra = math.max(0.0, constraints.maxHeight - need - 1);
        final weights = pieces.fold(0, (sum, x) => sum + x.$2);
        return Column(
          children: [
            for (final (e, weight) in pieces)
              e == null
                  ? SizedBox(height: _gap + extra * weight / weights)
                  : _EntryLine(entry: e, height: _minHeight(e) + extra * weight / weights, onTap: onOpen),
          ],
        );
      },
    );
  }
}

/// An entry of the day: its start (and end, from an hour on) beside a box in its color.
class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.entry, required this.height, required this.onTap});

  final MiniEntry entry;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    entry.allDay ? '' : _time(entry.start),
                    maxLines: 1,
                    style: const TextStyle(color: _MiniColors.secondary, fontSize: 12),
                  ),
                ),
                if (entry.halfHours > 1) Text(_time(entry.end), maxLines: 1, style: const TextStyle(color: _MiniColors.tertiary, fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: entry.done ? 0.5 : 1,
              child: Material(
                color: entry.color,
                borderRadius: BorderRadius.circular(4),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A week (one row) or a month (five or six): the weekdays, then each day's number and as many of
/// its entries as fit, "+N" for the rest.
class _GridView extends StatelessWidget {
  const _GridView({required this.data, required this.first, required this.weeks, required this.today, required this.month, required this.onOpen});

  final MiniCalendarData data;
  final DateTime first;
  final int weeks;
  final DateTime today;

  /// The month shown (its days are brighter); null for a week.
  final DateTime? month;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  data.weekday(DateTime(first.year, first.month, first.day + i).weekday),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _MiniColors.secondary, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
      for (var w = 0; w < weeks; w++)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var d = 0; d < 7; d++)
                if (DateTime(first.year, first.month, first.day + w * 7 + d) case final day)
                  Expanded(
                    child: _DayCell(
                      data: data,
                      day: day,
                      today: day == today,
                      dim: month != null && day.month != month!.month,
                      onTap: () => onOpen(day),
                    ),
                  ),
            ],
          ),
        ),
    ],
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.data, required this.day, required this.today, required this.dim, required this.onTap});

  final MiniCalendarData data;
  final DateTime day;
  final bool today;
  final bool dim;
  final VoidCallback onTap;

  static const _number = 24.0;
  static const _chip = 17.0;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries(day);
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: _MiniColors.line, width: 0.5),
            left: BorderSide(color: _MiniColors.line, width: 0.5),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fit = math.max(0, ((constraints.maxHeight - _number - 4) / _chip).floor());
            final shown = entries.length > fit ? math.max(0, fit - 1) : entries.length;
            // Never scrolls: it only keeps a cell too short for its number from overflowing.
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 2),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: today ? const BoxDecoration(color: _MiniColors.primary, shape: BoxShape.circle) : null,
                    child: Text('${day.day}', style: TextStyle(color: dim ? _MiniColors.tertiary : _MiniColors.text, fontSize: 12)),
                  ),
                  for (final e in entries.take(shown))
                    Opacity(
                      opacity: e.done || dim ? 0.5 : 1,
                      child: Container(
                        height: _chip - 2,
                        margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(3)),
                        child: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.1),
                        ),
                      ),
                    ),
                  if (shown < entries.length) Text('+${entries.length - shown}', style: const TextStyle(color: _MiniColors.secondary, fontSize: 9)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
