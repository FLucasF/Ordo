import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/mini_calendar/mini_calendar.dart';

class _FakeHost implements MiniHost {
  final calls = <String>[];

  @override
  void startDrag() => calls.add('drag');

  @override
  void startResize(MiniEdge edge) => calls.add('resize ${edge.hitTest}');

  @override
  void setLayer(MiniLayer layer) => calls.add('layer ${layer.name}');

  @override
  void close() => calls.add('close');

  @override
  void open(String action, DateTime day, String mode) => calls.add('$action ${day.month}/${day.day} $mode');

  @override
  void save(MiniSettings settings) => calls.add('save ${jsonEncode(settings.toJson())}');
}

Map<String, Object?> _entry(String title, int start, int end, {String color = '#6E77C9'}) => {
  't': title,
  'c': color,
  's': start,
  'e': end,
  'd': false,
};

/// Friday, 2026-10-09: the day of the phone's screenshot, and a busy Saturday.
MiniCalendarData _data({bool busySaturday = false}) => MiniCalendarData({
  'firstWeekday': DateTime.sunday,
  'labels': {
    'day': 'Dia',
    'week': 'Semana',
    'month': 'Mês',
    'empty': 'Nada neste dia',
    'allDay': 'Dia todo',
    'layerTop': 'Por cima das janelas',
    'layerNormal': 'Normal',
    'layerDesktop': 'Na área de trabalho',
    'close': 'Fechar',
    'months': ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'],
    'weekdays': ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  },
  'days': {
    '2026-10-09': [
      _entry('Caminhar', 390, 420, color: '#D4B85A'),
      _entry('Phoebus', 480, 720, color: '#8B0000'),
      _entry('TCC', 780, 810),
      _entry('Álgebra - estudo', 1020, 1050),
      _entry('TCC', 1110, 1140),
    ],
    '2026-10-10': [
      {'t': 'Fim de semana', 'c': '#F5A524', 's': -1, 'e': -1, 'd': false},
      if (busySaturday)
        for (var h = 7; h < 22; h++) _entry('Tarefa $h', h * 60, h * 60 + 30, color: '#2E9E6E'),
    ],
  },
});

void main() {
  final today = DateTime(2026, 10, 9, 15);

  Future<_FakeHost> pump(WidgetTester tester, MiniCalendarData data, {String mode = 'd', Size size = const Size(340, 420)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final host = _FakeHost();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: MiniCalendar(
            data: data,
            today: today,
            host: host,
            settings: MiniSettings(mode: mode),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return host;
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
  }

  testWidgets('the day fills the window: each entry as tall as it lasts, nothing left empty below', (tester) async {
    final host = await pump(tester, _data());
    expect(find.text('Sex, 9 outubro'), findsOneWidget);
    expect(host.calls, ['layer top']);
    // Phoebus, 8:00 to 12:00, shows its end and is much taller than a half-hour entry.
    expect(find.text('12:00'), findsOneWidget);
    final phoebus = tester.getSize(find.ancestor(of: find.text('Phoebus'), matching: find.byType(Material)).first).height;
    final walk = tester.getSize(find.ancestor(of: find.text('Caminhar'), matching: find.byType(Material)).first).height;
    expect(phoebus, greaterThan(walk * 2.5));
    // The last entry ends near the window's bottom.
    expect(tester.getBottomLeft(find.ancestor(of: find.text('Álgebra - estudo'), matching: find.byType(Material)).first).dy, lessThan(420));
    final lastBottom = tester.getBottomLeft(find.ancestor(of: find.text('TCC'), matching: find.byType(Material)).last).dy;
    expect(lastBottom, greaterThan(400));
    await shoot(tester, 'mini_day');

    await tester.tap(find.text('Phoebus'));
    await tester.tap(find.byIcon(Icons.add));
    expect(host.calls.sublist(1), ['open 10/9 d', 'create 10/9 d']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a day that does not fit scrolls; ‹ › move and the title comes back to today', (tester) async {
    final host = await pump(tester, _data(busySaturday: true));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('Sáb, 10 outubro'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Tarefa 21'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa 21'), findsOneWidget);
    await shoot(tester, 'mini_day_scroll');
    await tester.tap(find.text('Sáb, 10 outubro'));
    await tester.pumpAndSettle();
    expect(find.text('Sex, 9 outubro'), findsOneWidget);
    expect(host.calls, ['layer top']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Semana and Mês: the days with their entries, saved; the pin picks the layer; × closes', (tester) async {
    final host = await pump(tester, _data());
    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('4–10 out'), findsOneWidget);
    expect(find.text('Phoebus'), findsOneWidget);
    await shoot(tester, 'mini_week');
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(find.text('Outubro 2026'), findsOneWidget);
    // 9 October is in a cell with its first entry and "+N".
    expect(find.text('9'), findsOneWidget);
    await shoot(tester, 'mini_month');
    await tester.tap(find.text('10'));
    expect(host.calls.last, 'open 10/10 d');

    await tester.tap(find.byIcon(Icons.push_pin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Na área de trabalho'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.desktop_windows_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(host.calls, [
      'layer top',
      'save {"mode":"w","layer":"top"}',
      'save {"mode":"m","layer":"top"}',
      'open 10/10 d',
      'layer desktop',
      'save {"mode":"m","layer":"desktop"}',
      'close',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the edges resize the window; the empty top drags it', (tester) async {
    final host = await pump(tester, _data());
    await tester.tapAt(const Offset(338, 418));
    await tester.tapAt(const Offset(170, 1));
    await tester.drag(find.text('Sex, 9 outubro'), const Offset(40, 20));
    expect(host.calls.sublist(1), ['resize 17', 'resize 12', 'drag']);
  });

  test('settings and data read back what was written, and survive a broken file', () {
    final s = MiniSettings.fromJson({'mode': 'w', 'layer': 'desktop'});
    expect((s.mode, s.layer), ('w', MiniLayer.desktop));
    expect(MiniSettings.fromJson({'mode': 'x'}).mode, 'd');
    expect(MiniCalendarData.parse('{broken').entries(DateTime(2026, 10, 9)), isEmpty);
    final d = _data();
    expect(d.entries(DateTime(2026, 10, 9)).map((e) => e.halfHours), [1, 8, 1, 1, 1]);
    expect(d.weekStart(DateTime(2026, 10, 9)), DateTime(2026, 10, 4));
    expect(d.weekday(DateTime.friday), 'Sex');
  });
}
