import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/features/calendar/calendar_insights_panel.dart';
import 'package:task_manager/features/detail/task_detail_pane.dart';
import 'package:task_manager/features/tasks/batch_pane.dart';
import 'package:task_manager/features/common/shell_widgets.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Thursday, 2026-09-24.
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpCalendar(WidgetTester tester, String location, {bool withPanel = false}) async {
    // Desktop gestures: bars drag at once (touch screens need a long press).
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: TasksApp(initialLocation: location),
      ),
    );
    await settle(tester);
    // These tests measure the grid without Google's side panel; it has a test of its own.
    if (!withPanel && find.byTooltip('Mostrar ou esconder o painel').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Mostrar ou esconder o painel'));
      await settle(tester);
    }
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
    debugDefaultTargetPlatformOverride = null;
  }

  Future<Task> taskNamed(String title) async => (await (db.select(db.tasks)..where((t) => t.title.equals(title))).getSingle());

  /// The Google-style create card: its title field, then Enter saves.
  Future<void> addThroughModal(WidgetTester tester, String title) async {
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Adicionar título'), title);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
  }

  Future<void> mouseDrag(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);
  }

  testWidgets('month: a click on a day creates an all-day task there; a bar dragged to another day moves it', (tester) async {
    await pumpCalendar(tester, '/calendar/m');
    expect(find.text('Setembro 2026'), findsOneWidget);
    await tester.tap(find.text('15'));
    await addThroughModal(tester, 'Dentista');
    final dentist = (await tester.runAsync(() => taskNamed('Dentista')))!;
    expect((dentist.dueDate!.toLocal(), dentist.isAllDay), (DateTime(2026, 9, 15), true));

    await mouseDrag(tester, tester.getCenter(find.text('Dentista')), tester.getCenter(find.text('17')));
    final moved = (await tester.runAsync(() => taskNamed('Dentista')))!;
    expect(moved.dueDate!.toLocal(), DateTime(2026, 9, 17));

    // With Ctrl held, the drop leaves a copy and the task stays.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await mouseDrag(tester, tester.getCenter(find.text('Dentista')), tester.getCenter(find.text('19')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    final all = (await tester.runAsync(() => (db.select(db.tasks)..where((t) => t.title.equals('Dentista'))).get()))!;
    expect(all.map((t) => t.dueDate!.toLocal()).toSet(), {DateTime(2026, 9, 17), DateTime(2026, 9, 19)});
    await finish(tester);
  });

  testWidgets('month: dragging over several days creates a task that spans them', (tester) async {
    await pumpCalendar(tester, '/calendar/m');
    await mouseDrag(tester, tester.getCenter(find.text('8')), tester.getCenter(find.text('10')));
    await addThroughModal(tester, 'Congresso');
    final task = (await tester.runAsync(() => taskNamed('Congresso')))!;
    expect((task.startDate!.toLocal(), task.dueDate!.toLocal(), task.isAllDay), (DateTime(2026, 9, 8), DateTime(2026, 9, 10), true));
    await finish(tester);
  });

  testWidgets('day: a click on the timeline creates a task at that half hour; a block dragged down an hour moves it', (tester) async {
    await tester.runAsync(
      () => repo.createTask(
        listId: inboxListId,
        title: 'Ligação',
        startDate: DateTime(2026, 9, 24, 14),
        dueDate: DateTime(2026, 9, 24, 15),
        isAllDay: false,
      ),
    );
    await pumpCalendar(tester, '/calendar/d');
    final ten = tester.getCenter(find.text('10:00'));
    final hour = tester.getCenter(find.text('11:00')).dy - ten.dy;
    await tester.tapAt(Offset(800, ten.dy + hour / 4));
    await addThroughModal(tester, 'Revisão');
    final review = (await tester.runAsync(() => taskNamed('Revisão')))!;
    // As Google's: a click makes an hour from the half hour clicked (the default duration).
    expect((review.startDate!.toLocal(), review.dueDate!.toLocal(), review.isAllDay), (DateTime(2026, 9, 24, 10), DateTime(2026, 9, 24, 11), false));

    await mouseDrag(tester, tester.getCenter(find.text('Ligação')), tester.getCenter(find.text('Ligação')) + Offset(0, hour));
    final call = (await tester.runAsync(() => taskNamed('Ligação')))!;
    expect((call.startDate!.toLocal(), call.dueDate!.toLocal()), (DateTime(2026, 9, 24, 15), DateTime(2026, 9, 24, 16)));

    // The bottom edge dragged half an hour down: the task ends at 16:30.
    final block = tester.getRect(find.ancestor(of: find.text('Ligação'), matching: find.byType(Container)).first);
    await mouseDrag(tester, Offset(block.center.dx, block.bottom - 1), Offset(block.center.dx, block.bottom - 1 + hour / 2));
    final longer = (await tester.runAsync(() => taskNamed('Ligação')))!;
    expect((longer.startDate!.toLocal(), longer.dueDate!.toLocal()), (DateTime(2026, 9, 24, 15), DateTime(2026, 9, 24, 16, 30)));
    // As Google's "Event saved": "Salvo" with "Desfazer"; Z undoes too.
    expect(find.text('Salvo'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    for (var i = 0; i < 3; i++) {
      await settle(tester);
    }
    final undone = (await tester.runAsync(() => taskNamed('Ligação')))!;
    expect((undone.startDate!.toLocal(), undone.dueDate!.toLocal()), (DateTime(2026, 9, 24, 15), DateTime(2026, 9, 24, 16)));
    await finish(tester);
  });

  testWidgets('week: dragging on the timeline creates a task with that duration; W / M switch modes', (tester) async {
    await pumpCalendar(tester, '/calendar/w');
    expect(find.text('Semana'), findsOneWidget);
    final nine = tester.getCenter(find.text('09:00')).dy;
    final eleven = tester.getCenter(find.text('11:00')).dy;
    // Thursday is the 5th of the 7 columns right of the 56 px hour gutter.
    final x = 50 + 56 + (1600 - 50 - 56) / 7 * 4.5;
    await mouseDrag(tester, Offset(x, nine + 1), Offset(x, eleven + 1));
    await addThroughModal(tester, 'Workshop');
    final workshop = (await tester.runAsync(() => taskNamed('Workshop')))!;
    expect((workshop.startDate!.toLocal(), workshop.dueDate!.toLocal()), (DateTime(2026, 9, 24, 9), DateTime(2026, 9, 24, 11)));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await settle(tester);
    expect(find.text('Mês'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('timeline (V→T): a bar moves by days, its right edge stretches it, an undated task is dropped on the ruler', (tester) async {
    late String list;
    await tester.runAsync(() async {
      list = await repo.createList(name: 'Obra');
      await repo.createTask(listId: list, title: 'Fundação', startDate: DateTime(2026, 9, 22), dueDate: DateTime(2026, 9, 23));
      await repo.createTask(listId: list, title: 'Pintura');
    });
    await pumpCalendar(tester, '/p/$list/tasks');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await settle(tester);
    expect(find.text('Organizar tarefas'), findsOneWidget);

    // Day scale: 64 px a day. The bar's title is the second "Fundação" (the first is the row's name).
    await mouseDrag(tester, tester.getCenter(find.text('Fundação').last), tester.getCenter(find.text('Fundação').last) + const Offset(128, 0));
    var t = (await tester.runAsync(() => taskNamed('Fundação')))!;
    expect((t.startDate!.toLocal(), t.dueDate!.toLocal()), (DateTime(2026, 9, 24), DateTime(2026, 9, 25)));

    final bar = tester.getRect(find.ancestor(of: find.text('Fundação').last, matching: find.byType(Row)).first);
    await mouseDrag(tester, Offset(bar.right - 3, bar.center.dy), Offset(bar.right - 3 + 64, bar.center.dy));
    t = (await tester.runAsync(() => taskNamed('Fundação')))!;
    expect((t.startDate!.toLocal(), t.dueDate!.toLocal()), (DateTime(2026, 9, 24), DateTime(2026, 9, 26)));

    // The bar now starts on the 24th: 64 px further is the 25th.
    await mouseDrag(tester, tester.getCenter(find.text('Pintura')), Offset(bar.left + 64 + 32, bar.center.dy));
    final painting = (await tester.runAsync(() => taskNamed('Pintura')))!;
    expect(painting.dueDate?.toLocal(), DateTime(2026, 9, 25));
    await finish(tester);
  });

  testWidgets('Shift + wheel moves the dates; Ctrl + wheel zooms the hours', (tester) async {
    await pumpCalendar(tester, '/calendar/m');
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendEventToBinding(pointer.hover(const Offset(800, 500)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 100)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);
    expect(find.text('Outubro 2026'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await settle(tester);
    double hour() => tester.getCenter(find.text('11:00')).dy - tester.getCenter(find.text('10:00')).dy;
    final before = hour();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(hour(), greaterThan(before * 1.1));
    await finish(tester);
  });

  testWidgets('Ctrl+click picks tasks; with two, the batch panel opens', (tester) async {
    await tester.runAsync(() async {
      await repo.createTask(listId: inboxListId, title: 'Primeira', dueDate: DateTime(2026, 9, 22));
      await repo.createTask(listId: inboxListId, title: 'Segunda', dueDate: DateTime(2026, 9, 23));
    });
    await pumpCalendar(tester, '/calendar/m');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('Primeira'));
    await tester.pump();
    await tester.tap(find.text('Segunda'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(find.byType(BatchPane), findsOneWidget);
    await finish(tester);
  });

  testWidgets('split view: a task dragged from the calendar to a list moves there with its date', (tester) async {
    late String work;
    await tester.runAsync(() async {
      work = await repo.createList(name: 'Trabalho');
      await repo.createTask(listId: inboxListId, title: 'Relatório', dueDate: DateTime(2026, 9, 22));
    });
    await pumpCalendar(tester, '/calendar/m');
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar listas ao lado'));
    await settle(tester);
    expect(find.text('Trabalho'), findsOneWidget);
    await mouseDrag(tester, tester.getCenter(find.text('Relatório')), tester.getCenter(find.text('Trabalho')));
    final task = (await tester.runAsync(() => taskNamed('Relatório')))!;
    expect((task.listId, task.dueDate!.toLocal()), (work, DateTime(2026, 9, 22)));
    await finish(tester);
  });

  testWidgets('Google Calendar keys and the weekends switch: J/K move, X is the custom days, weekends can hide', (tester) async {
    await pumpCalendar(tester, '/calendar/w');
    // Week of 20–26 set: the header shows SÁB and DOM.
    expect(find.text('SÁB'), findsOneWidget);
    expect(find.text('27'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await settle(tester);
    expect(find.text('27'), findsOneWidget, reason: 'J moves to the next week (27 set – 3 out)');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await settle(tester);
    expect(find.text('20'), findsOneWidget, reason: 'K comes back');

    // "Mostrar fins de semana" in the view menu.
    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrar fins de semana'), findsOneWidget);
    await tester.tap(find.text('Mostrar fins de semana'));
    await settle(tester);
    expect(find.text('SÁB'), findsNothing);
    expect(find.text('DOM'), findsNothing);
    expect(find.text('SEG'), findsOneWidget);

    // X: the custom number of days (Multi-dia).
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await settle(tester);
    expect(find.textContaining('Multi'), findsWidgets);
    await finish(tester);
  });

  testWidgets('side panel: lists as calendars with color checkboxes; unchecking hides their tasks; ☰ hides the panel', (tester) async {
    await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Consulta', dueDate: DateTime(2026, 9, 24)));
    await pumpCalendar(tester, '/calendar/m', withPanel: true);
    expect(find.text('Meus calendários'), findsOneWidget);
    // "+ Nova tarefa" is the top bar's now, not the panel's.
    expect(find.widgetWithText(CreateButton, 'Nova tarefa'), findsOneWidget);
    expect(find.text('Consulta'), findsOneWidget);
    await tester.tap(find.text('Caixa de Entrada').last);
    await settle(tester);
    expect(find.text('Consulta'), findsNothing, reason: 'the list is hidden from the calendar');
    await tester.tap(find.text('Caixa de Entrada').last);
    await settle(tester);
    expect(find.text('Consulta'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar ou esconder o painel'));
    await settle(tester);
    expect(find.text('Meus calendários'), findsNothing);
    await finish(tester);
  });

  testWidgets('create card as Google\'s: kind, list, "Mais opções" opens the full page, which saves', (tester) async {
    await pumpCalendar(tester, '/calendar/m');
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    // The card: title, Tarefa | Nota, the day line, the list, "Mais opções" and "Salvar".
    expect(find.widgetWithText(TextField, 'Adicionar título'), findsOneWidget);
    expect(find.text('Tarefa'), findsOneWidget);
    expect(find.text('Nota'), findsOneWidget);
    expect(find.textContaining('15 de setembro'), findsOneWidget);
    expect(find.text('(Sem título)'), findsOneWidget, reason: 'the provisional block on the grid');
    await tester.enterText(find.widgetWithText(TextField, 'Adicionar título'), 'Revisão do carro');
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();

    // The full page keeps what was typed; Alta priority, then Salvar.
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Revisão do carro'), findsOneWidget);
    await tester.tap(find.text('Nenhuma').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alta').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final task = (await tester.runAsync(() => taskNamed('Revisão do carro')))!;
    expect((task.dueDate!.toLocal(), task.isAllDay, task.priority), (DateTime(2026, 9, 15), true, Priority.high));
    await finish(tester);
  });

  testWidgets('Time Insights: the side panel sums the week by list; "Mais insights" opens the donut, by list, tag or kind', (tester) async {
    await tester.runAsync(() async {
      final work = await repo.createList(name: 'Trabalho', color: '#4772FA');
      final client = await repo.createTag('Cliente');
      await repo.createTask(
        listId: inboxListId,
        title: 'Relatório',
        startDate: DateTime(2026, 9, 24, 9),
        dueDate: DateTime(2026, 9, 24, 11),
        isAllDay: false,
        tagIds: [client],
      );
      await repo.createTask(
        listId: work,
        title: 'Reunião',
        startDate: DateTime(2026, 9, 25, 14),
        dueDate: DateTime(2026, 9, 25, 17),
        isAllDay: false,
      );
      // All-day tasks and tasks at a point in time (drawn at 30 min) have no hours to count, as in Google.
      await repo.createTask(listId: work, title: 'Feriado', dueDate: DateTime(2026, 9, 23));
      await repo.createTask(listId: work, title: 'Ligar', dueDate: DateTime(2026, 9, 24, 16), isAllDay: false);
    });
    await pumpCalendar(tester, '/calendar/w', withPanel: true);
    expect(find.text('Insights de tempo'), findsOneWidget);
    expect(find.text('20 – 26 DE SET. DE 2026'), findsOneWidget);
    // The bar by label; a tap (or the pointer on it) shows each label's hours.
    final bar = find.descendant(of: find.byType(CalendarInsightsSummary), matching: find.byType(ClipRRect));
    await tester.tap(bar);
    await settle(tester);
    expect(find.text('Sem rótulo'), findsOneWidget);
    expect(find.text('5 h'), findsOneWidget);
    await tester.tap(bar);
    await settle(tester);
    expect(find.text('Sem rótulo'), findsNothing);

    await tester.tap(find.text('Mais insights'));
    await settle(tester);
    expect(find.text('Detalhamento do tempo'), findsOneWidget);
    expect(find.text('Horas por dia'), findsOneWidget);
    // By label (Google's default): no task has a color yet.
    expect(find.text('Sem rótulo'), findsOneWidget);
    expect(find.text('5 h'), findsNWidgets(2), reason: 'the total inside the donut and the legend');

    await tester.tap(find.text('Lista'));
    await settle(tester);
    // Legend and the bar of the day.
    expect(find.text('3 h'), findsNWidgets(2), reason: 'Trabalho, on Friday');
    expect(find.text('2 h'), findsNWidgets(2), reason: 'Caixa de Entrada, on Thursday');

    await tester.tap(find.text('Etiqueta'));
    await settle(tester);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Sem etiqueta'), findsOneWidget);

    await tester.tap(find.text('Tipo'));
    await settle(tester);
    expect(find.text('Tarefas'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await settle(tester);
    expect(find.text('Detalhamento do tempo'), findsNothing);
    await finish(tester);
  });

  testWidgets('right click on a task: Google\'s color menu; labels name colors and group Time Insights; Excluir', (tester) async {
    await tester.runAsync(
      () => repo.createTask(
        listId: inboxListId,
        title: 'Relatório',
        startDate: DateTime(2026, 9, 24, 9),
        dueDate: DateTime(2026, 9, 24, 11),
        isAllDay: false,
      ),
    );
    await pumpCalendar(tester, '/calendar/w', withPanel: true);
    Future<void> rightClick(String title) async {
      await tester.tapAt(tester.getCenter(find.text(title)), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
      await settle(tester);
    }

    // A color of the palette: saved at once, with "Salvo" and "Desfazer".
    await rightClick('Relatório');
    expect(find.text('Padrão'), findsOneWidget);
    await tester.tap(find.byTooltip('Pavão'));
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.color, '#4B99D2');
    expect(find.text('Salvo'), findsOneWidget);

    // ✎ names a color: the label shows in the menu and picks its color.
    await rightClick('Relatório');
    await tester.tap(find.byTooltip('Editar rótulos'));
    await settle(tester);
    await tester.tap(find.text('Adicionar rótulo'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Nome do rótulo'), 'TCC');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    await tester.tap(find.text('TCC'));
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.color, '#D85675', reason: 'the first free color of the palette');

    // Time Insights groups by the label.
    await tester.tap(find.text('Mais insights'));
    await settle(tester);
    expect(find.text('TCC'), findsOneWidget);
    expect(find.text('2 h'), findsWidgets);

    // "Padrão" goes back to the list's color; "Excluir" moves the task to the trash.
    await rightClick('Relatório');
    await tester.tap(find.text('Padrão'));
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.color, isNull);
    await rightClick('Relatório');
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.deletedAt, isNotNull);
    expect(find.text('Tarefa excluída'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('"Personalizado…" opens Google\'s custom recurrence: every 2 weeks on Tue and Thu, 13 times', (tester) async {
    await pumpCalendar(tester, '/calendar/m');
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Adicionar título'), 'Academia');
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não se repete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personalizado…'));
    await tester.pumpAndSettle();

    // Weekly on the start's weekday (Tuesday 15) to begin with.
    expect(find.text('Repetição personalizada'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextField)).first, '2');
    await tester.pumpAndSettle();
    expect(find.text('semanas'), findsOneWidget, reason: 'the unit follows the number');
    await tester.tap(find.byTooltip('Quinta-feira'));
    await tester.tap(find.text('Após'));
    await tester.pumpAndSettle();
    expect(find.text('ocorrências'), findsOneWidget);
    await tester.tap(find.text('Concluído'));
    await tester.pumpAndSettle();
    expect(find.text('A cada 2 semanas: terça-feira, quinta-feira, 13 vezes'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final task = (await tester.runAsync(() => taskNamed('Academia')))!;
    expect(task.repeatRule, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;COUNT=13');
    await finish(tester);
  });

  testWidgets('"Mais opções": choosing "Não se repete" again takes the repetition away', (tester) async {
    await pumpCalendar(tester, '/calendar/m');
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Adicionar título'), 'Feira');
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não se repete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diariamente').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diariamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não se repete').last);
    await tester.pumpAndSettle();
    expect(find.text('Não se repete'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Feira')))!.repeatRule, isNull);
    await finish(tester);
  });

  testWidgets('Finanças on the calendar: bills, invoices and loans on their due days; a click opens the tab', (tester) async {
    final finance = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      await finance.createRecurring(
        FinRecurringsCompanion(
          kind: const Value(FinKind.expense),
          description: const Value('Aluguel'),
          amount: const Value(150000),
          frequency: const Value(FinFrequency.monthly),
          day: const Value(5),
          startDate: Value(DateTime.utc(2026, 9)),
        ),
      );
      await finance.createLoan(borrower: 'João', principal: 100000, total: 130000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 9, 28));
    });
    await pumpCalendar(tester, '/calendar/m');
    expect(find.text(r'Aluguel · R$ 1.500,00'), findsOneWidget);
    expect(find.text(r'Cobrar João · R$ 1.300,00'), findsOneWidget);

    // "Opções de visualização" hides them.
    final prefs = PreferencesRepository(db, clock: clock);
    final options = (await tester.runAsync(() => prefs.watch().first))!.calendarOptions;
    await tester.runAsync(() => prefs.setCalendarOptions(options.copyWith(showFinance: false)));
    await settle(tester);
    expect(find.text(r'Aluguel · R$ 1.500,00'), findsNothing);
    await tester.runAsync(() => prefs.setCalendarOptions(options));
    await settle(tester);

    // A click offers a new entry on that day…
    await tester.tap(find.text(r'Cobrar João · R$ 1.300,00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo lançamento neste dia'));
    await tester.pumpAndSettle();
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('28/09/2026'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    // …or opens its tab.
    await tester.tap(find.text(r'Cobrar João · R$ 1.300,00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir em Finanças'));
    await settle(tester);
    expect(find.text('Empréstimos'), findsWidgets);
    expect(find.text(r'Falta R$ 1.300,00'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a click on a task opens Google\'s details popup: when, repetition, reminder, list; done, Editar, ⋮, Delete', (tester) async {
    await tester.runAsync(
      () => repo.createTask(
        listId: inboxListId,
        title: 'Relatório',
        content: 'Números do trimestre',
        startDate: DateTime(2026, 9, 24, 9),
        dueDate: DateTime(2026, 9, 24, 11),
        isAllDay: false,
        priority: Priority.high,
        reminders: const ['-PT30M'],
      ),
    );
    await pumpCalendar(tester, '/calendar/w');
    await tester.tap(find.text('Relatório'));
    await settle(tester);
    expect(find.text('Quinta-feira, 24 de setembro · 09:00 – 11:00'), findsOneWidget);
    expect(find.text('30 minutos antes'), findsOneWidget);
    expect(find.text('Números do trimestre'), findsOneWidget);
    expect(find.text('Prioridade: alta'), findsOneWidget);
    expect(find.text('Caixa de Entrada'), findsOneWidget);

    // "Marcar como concluída" closes the popup with the toast; "Desfazer" reopens.
    await tester.tap(find.text('Marcar como concluída'));
    for (var i = 0; i < 3; i++) {
      await settle(tester);
    }
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.status, TaskStatus.completed);
    expect(find.text('Tarefa concluída'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    for (var i = 0; i < 3; i++) {
      await settle(tester);
    }
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.status, TaskStatus.open);
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);

    // Editar: Google's full page with the task, saved in place.
    await tester.tap(find.text('Relatório'));
    await settle(tester);
    await tester.tap(find.byTooltip('Editar tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Relatório'), 'Relatório final');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final edited = (await tester.runAsync(() => taskNamed('Relatório final')))!;
    expect(
      (edited.startDate!.toLocal(), edited.dueDate!.toLocal(), edited.priority),
      (DateTime(2026, 9, 24, 9), DateTime(2026, 9, 24, 11), Priority.high),
    );
    expect(await tester.runAsync(() => repo.remindersOf(edited.id)), ['-PT30M']);

    // ⋮ → "Abrir detalhes da tarefa": TickTick's detail.
    await tester.tap(find.text('Relatório final'));
    await settle(tester);
    await tester.tap(find.byTooltip('Opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir detalhes da tarefa'));
    await settle(tester);
    expect(find.byType(TaskDetailPane), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);

    // Delete in the popup deletes, as Google's.
    await tester.tap(find.text('Relatório final').first);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Relatório final')))!.deletedAt, isNotNull);
    await finish(tester);
  });

  testWidgets('colors are free: "+" opens the palette, the code typed is the task\'s color and stays in the menu', (tester) async {
    await tester.runAsync(
      () => repo.createTask(
        listId: inboxListId,
        title: 'Relatório',
        startDate: DateTime(2026, 9, 24, 9),
        dueDate: DateTime(2026, 9, 24, 11),
        isAllDay: false,
      ),
    );
    await pumpCalendar(tester, '/calendar/w');
    await tester.tapAt(tester.getCenter(find.text('Relatório')), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
    await settle(tester);
    await tester.tap(find.byTooltip('Cor personalizada').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), '#12AB34');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect((await tester.runAsync(() => taskNamed('Relatório')))!.color, '#12AB34');

    // The color picked is offered again, beside the palette.
    await tester.tapAt(tester.getCenter(find.text('Relatório')), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
    await settle(tester);
    expect(find.byTooltip('Cor personalizada'), findsNWidgets(2));
    await finish(tester);
  });

  testWidgets('Google\'s rest: weekends hide in the month too, short blocks are half an hour tall, the popup goes beside, 🔍 searches', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.createTask(listId: inboxListId, title: 'Feira', dueDate: DateTime(2026, 9, 26));
      await repo.createTask(
        listId: inboxListId,
        title: 'Café',
        startDate: DateTime(2026, 9, 24, 9),
        dueDate: DateTime(2026, 9, 24, 9, 10),
        isAllDay: false,
      );
    });
    await pumpCalendar(tester, '/calendar/m');
    expect(find.text('SÁB'), findsOneWidget);
    expect(find.text('Feira'), findsOneWidget);
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar fins de semana'));
    await settle(tester);
    expect(find.text('SÁB'), findsNothing);
    expect(find.text('DOM'), findsNothing);
    expect(find.text('Feira'), findsNothing, reason: 'a Saturday task hides with the weekend');
    expect(find.text('SEG'), findsOneWidget);

    // A 10-minute task is drawn as half an hour (on by default), and at its size when off.
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dia').last);
    await settle(tester);
    double blockHeight() => tester.getSize(find.ancestor(of: find.textContaining('Café'), matching: find.byType(Positioned)).first).height;
    final hour = tester.getCenter(find.text('11:00')).dy - tester.getCenter(find.text('10:00')).dy;
    expect(blockHeight(), closeTo(hour / 2, 1));
    await tester.runAsync(() async {
      final prefs = PreferencesRepository(db, clock: clock);
      final o = (await prefs.watch().first).calendarOptions;
      await prefs.setCalendarOptions(o.copyWith(shortAs30: false));
    });
    await settle(tester);
    expect(blockHeight(), lessThan(hour / 2 - 1));

    // The popup opens beside the block, not over it (in the week, where there is room).
    await tester.tap(find.text('Dia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semana').last);
    await settle(tester);
    final block = tester.getRect(find.ancestor(of: find.textContaining('Café'), matching: find.byType(Positioned)).first);
    await tester.tap(find.textContaining('Café'));
    await settle(tester);
    final popup = tester.getRect(
      find.ancestor(of: find.text('Marcar como concluída'), matching: find.byWidgetPredicate((w) => w is Material && w.elevation == 6)),
    );
    expect(popup.left >= block.right || popup.right <= block.left, isTrue);
    await tester.tap(find.byTooltip('Fechar'));
    await settle(tester);

    // Right click: Duplicar leaves a copy; Concluir completes.
    await tester.tapAt(tester.getCenter(find.textContaining('Café')), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
    await settle(tester);
    expect(find.text('Abrir'), findsOneWidget);
    await tester.tap(find.text('Duplicar'));
    await settle(tester);
    expect(await tester.runAsync(() async => (await (db.select(db.tasks)..where((t) => t.title.equals('Café'))).get()).length), 2);

    // 🔍: the app's search.
    await tester.tap(find.byTooltip('Buscar').last);
    await settle(tester);
    expect(find.byType(TextField), findsWidgets);
    await finish(tester);
  });

  testWidgets('a repeating task asks as Google\'s: "Somente esta" deletes one occurrence, edits one into a task of its own', (tester) async {
    await tester.runAsync(
      () => repo.createTask(
        listId: inboxListId,
        title: 'Reunião',
        startDate: DateTime(2026, 9, 24, 9),
        dueDate: DateTime(2026, 9, 24, 10),
        isAllDay: false,
        repeatRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH',
      ),
    );
    await pumpCalendar(tester, '/calendar/m');
    expect(find.textContaining('Reunião'), findsNWidgets(2), reason: '24 Sep and 1 Oct in the month grid');

    // Deleting the 1 Oct occurrence: only that one goes.
    await tester.tap(find.textContaining('Reunião').at(1));
    await settle(tester);
    await tester.tap(find.byTooltip('Deletar tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir tarefa repetida'), findsOneWidget);
    expect(find.text('Esta e as seguintes'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.textContaining('Reunião'), findsOneWidget);
    expect((await tester.runAsync(() => taskNamed('Reunião')))!.repeatRule, contains('TT_EXDATE=20261001'));

    // Editing the first one, "Somente esta": a task of its own, and the series goes on without it.
    await tester.tap(find.textContaining('Reunião'));
    await settle(tester);
    await tester.tap(find.byTooltip('Editar tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Reunião'), 'Reunião especial');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar tarefa repetida'), findsOneWidget);
    expect(find.text('Esta e as seguintes'), findsNothing, reason: 'from the first occurrence it would be "Todas"');
    await tester.tap(find.text('OK'));
    await settle(tester);
    final special = (await tester.runAsync(() => taskNamed('Reunião especial')))!;
    expect(
      (special.startDate!.toLocal(), special.dueDate!.toLocal(), special.repeatRule),
      (DateTime(2026, 9, 24, 9), DateTime(2026, 9, 24, 10), null),
    );
    final series = (await tester.runAsync(() => taskNamed('Reunião')))!;
    expect(series.startDate!.toLocal(), DateTime(2026, 10, 8, 9), reason: '1 Oct was taken out before');
    await finish(tester);
  });

  testWidgets('on a phone the create card takes the width, at the top, inside the screen', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: '/calendar/m'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();
    final field = tester.getRect(find.widgetWithText(TextField, 'Adicionar título'));
    expect(field.left, greaterThanOrEqualTo(0));
    expect(field.right, lessThanOrEqualTo(400));
    expect(field.top, lessThan(200), reason: 'at the top, where the keyboard does not reach');
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
