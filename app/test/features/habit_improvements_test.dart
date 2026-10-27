import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/habits.dart';
import 'package:task_manager/features/countdown/countdown_form.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/features/habits/habit_form.dart';

void main() {
  late AppDatabase db;
  // Tuesday, 27 October 2026.
  final clock = FixedClock(DateTime(2026, 10, 27, 12));
  final today = DateTime(2026, 10, 27);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Repository repo() => Repository(db, clock: clock);

  Future<void> settle(WidgetTester tester, [int steps = 8]) async {
    for (var i = 0; i < steps; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpApp(WidgetTester tester, String location, {Size size = const Size(1600, 1000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: TasksApp(initialLocation: location),
      ),
    );
    await settle(tester, 10);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  Future<String> habit(WidgetTester tester, String name, {String section = 'others'}) async =>
      (await tester.runAsync(() => repo().createHabit(HabitsCompanion(name: Value(name), section: Value(section), startDate: Value(today)))))!;

  Future<List<Habit>> habits(WidgetTester tester) async => (await tester.runAsync(() => repo().loadSnapshot()))!.habits;

  testWidgets('phone: Hábito stands out at the top of the drawer; a tap beside a habit\'s dot in Hoje stays in Hoje', (tester) async {
    final read = await habit(tester, 'Ler');
    await habit(tester, 'Correr');
    await tester.runAsync(() => repo().checkIn(read, today));
    // The test font is wider than the real one: the Hábito page's top bar needs a little more room.
    await pumpApp(tester, '/q/today/tasks', size: const Size(440, 860));
    // A tap on the name (not the dot) does nothing: no Hábito page.
    await tester.tap(find.text('Correr'));
    await settle(tester);
    expect(find.text('Correr'), findsOneWidget);
    expect(find.text('ÍMPETO'), findsNothing);
    expect(find.text('Visão em lista'), findsNothing);

    // The drawer: Hábito first, with today's progress.
    await tester.tap(find.byIcon(Icons.menu_open).first);
    await settle(tester);
    expect(find.byKey(const ValueKey('drawerHabit')), findsOneWidget);
    expect(find.text('1 de 2 hoje'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drawerHabit')));
    await settle(tester);
    expect(find.text('Visão em lista'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('computer: Hábito in the icon bar is tinted; habits are dragged into order within their section', (tester) async {
    await habit(tester, 'Correr', section: 'Ímpeto');
    await habit(tester, 'Rezar', section: 'Ímpeto');
    await habit(tester, 'Ler', section: 'Ímpeto');
    await pumpApp(tester, '/habit');
    final bar = tester.widget<IconButton>(find.byKey(const ValueKey('iconBarHabit')));
    expect(bar.style?.backgroundColor?.resolve({}), isNotNull);

    // "Ler"'s handle up above "Correr".
    final handles = find.byIcon(Icons.drag_indicator);
    expect(handles, findsNWidgets(3));
    final from = tester.getCenter(handles.at(2));
    final to = tester.getTopLeft(find.text('Correr'));
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset(from.dx, from.dy + (to.dy - 10 - from.dy) * i / 10));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);
    expect([for (final h in await habits(tester)) h.name], ['Ler', 'Correr', 'Rezar']);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('a habit takes tags in its form, shown beside its totals', (tester) async {
    await habit(tester, 'Correr');
    await tester.runAsync(() => repo().createTag('saúde'));
    await pumpApp(tester, '/habit');
    final h = (await habits(tester)).single;
    showHabitForm(tester.element(find.byType(Scaffold).first), editing: h).ignore();
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('habitTags')));
    await tester.tap(find.byKey(const ValueKey('habitTags')));
    await settle(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'saúde'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'saúde'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(habitTagIds((await habits(tester)).single), hasLength(1));
    expect(find.textContaining('#saúde', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Finanças: a day\'s entries are dragged into order', (tester) async {
    final finance = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      await finance.addEntry(kind: FinKind.expense, amount: 1000, date: today, description: 'Almoço');
      await finance.addEntry(kind: FinKind.expense, amount: 500, date: today, description: 'Café');
    });
    await pumpApp(tester, '/finance');
    // The newest on top.
    expect(tester.getTopLeft(find.text('Café')).dy, lessThan(tester.getTopLeft(find.text('Almoço')).dy));
    final handles = find.byIcon(Icons.drag_indicator);
    expect(handles, findsNWidgets(2));
    final from = tester.getCenter(handles.at(1));
    final to = tester.getTopLeft(find.text('Café'));
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset(from.dx, from.dy + (to.dy - 10 - from.dy) * i / 10));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);
    expect(tester.getTopLeft(find.text('Almoço')).dy, lessThan(tester.getTopLeft(find.text('Café')).dy));
    final entries = (await tester.runAsync(finance.load))!.entries;
    expect([for (final e in entries) e.description], ['Almoço', 'Café']);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('a countdown follows a habit\'s streak: no date, a goal of days in a row', (tester) async {
    final id = await habit(tester, 'Sem nicotina');
    await tester.runAsync(() => repo().checkIn(id, today));
    await pumpApp(tester, '/countdown');
    showCountdownForm(tester.element(find.byType(Scaffold).first), type: CountdownType.countdown).ignore();
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '30 dias limpo');
    await tester.tap(find.byKey(const ValueKey('countdownFollow')));
    await settle(tester);
    await tester.tap(find.text('Sem nicotina').last);
    await settle(tester);
    // No date nor reminders now; the goal instead.
    expect(find.text('Data'), findsNothing);
    expect(find.text('Meta (dias seguidos)'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    final c = (await tester.runAsync(() => repo().loadSnapshot()))!.countdowns.singleWhere((c) => c.name == '30 dias limpo');
    expect((c.habitId, c.goalDays, c.reminders), (id, 30, ''));
    expect(find.text('29'), findsWidgets);
    expect(find.text('1 de 30 dias seguidos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
}
