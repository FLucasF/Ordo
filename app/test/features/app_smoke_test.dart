import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/color_labels.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/snapshot.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/countdown/countdown_page.dart';
import 'package:task_manager/features/detail/content_editor.dart';
import 'package:task_manager/features/tasks/batch_pane.dart';
import 'package:task_manager/features/tasks/kanban_board.dart';
import 'package:task_manager/features/tasks/task_row.dart';
import 'package:task_manager/features/detail/task_detail_pane.dart';
import 'package:task_manager/features/habits/habit_form.dart';
import 'package:task_manager/features/habits/habit_page.dart';
import 'package:task_manager/features/habits/habit_widgets.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

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
    // The editor's blinking cursor never lets pumpAndSettle settle; advance time in steps instead.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('desktop: task detail shows title and content placeholder', (tester) async {
    final repo = Repository(db, clock: clock);
    final id = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Comprar pão'));
    await pumpApp(tester, '/p/inbox/tasks/$id');
    expect(tester.takeException(), isNull);
    expect(find.text('Comprar pão'), findsWidgets);
    expect(find.text('Caixa de Entrada'), findsWidgets);
    await _dispose(tester);
  });

  testWidgets('detail title: Enter does not break the line; a pasted break becomes a space', (tester) async {
    final repo = Repository(db, clock: clock);
    final id = (await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Ligar')))!;
    await pumpApp(tester, '/p/inbox/tasks/$id', size: const Size(560, 1000));
    final title = find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Ligar');
    await tester.enterText(title, 'Ligar para\no banco');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((await tester.runAsync(() => repo.loadSnapshot()))!.taskById[id]!.title, 'Ligar para o banco');
    await _dispose(tester);
  });

  testWidgets('the ▾ of the add field gives the next task a priority, or makes it a note', (tester) async {
    await pumpApp(tester, '/p/inbox/tasks');
    Future<void> settleBriefly() async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> add(String title) async {
      await tester.enterText(find.byType(TextField).first, title);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleBriefly();
    }

    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Alta'));
    await tester.pumpAndSettle();
    await add('Comprar leite');
    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Converter para nota'));
    await tester.pumpAndSettle();
    await add('Ideias');
    final tasks = (await tester.runAsync(() => db.select(db.tasks).get()))!;
    final milk = tasks.singleWhere((t) => t.title == 'Comprar leite');
    final idea = tasks.singleWhere((t) => t.title == 'Ideias');
    expect((milk.priority, milk.kind), (Priority.high, TaskKind.text));
    expect((idea.priority, idea.kind), (Priority.none, TaskKind.note), reason: 'the choices clear after a task');
    await _dispose(tester);
  });

  Future<void> dragTo(WidgetTester tester, Finder from, Offset to) async {
    final gesture = await tester.startGesture(tester.getCenter(from), kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    final start = tester.getCenter(from);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, to, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('desktop: drag reorders tasks and drop to the right makes a subtask', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      await repo.createTask(listId: inboxListId, title: 'a', atTop: false);
      await repo.createTask(listId: inboxListId, title: 'b', atTop: false);
      await repo.createTask(listId: inboxListId, title: 'c', atTop: false);
    });
    await pumpApp(tester, '/p/inbox/tasks');
    final aRow = tester.getTopLeft(find.text('a').first);
    // Drop "c" on the left part of "a": c goes before a.
    await dragTo(tester, find.text('c').first, Offset(aRow.dx + 5, aRow.dy + 5));
    final s1 = await tester.runAsync(repo.loadSnapshot);
    final order = (s1!.tasks.toList()..sort((x, y) => x.sortOrder.compareTo(y.sortOrder))).map((t) => t.title).toList();
    expect(order, ['c', 'a', 'b']);
    // Drop "b" far to the right of "a": b becomes a's subtask.
    final aNow = tester.getTopLeft(find.text('a').first);
    await dragTo(tester, find.text('b').first, Offset(aNow.dx + 200, aNow.dy + 5));
    final s2 = await tester.runAsync(repo.loadSnapshot);
    final b = s2!.tasks.firstWhere((t) => t.title == 'b');
    expect(s2.taskById[b.parentId]?.title, 'a');
    await _dispose(tester);
  });

  List<String> byOrder(Snapshot s) => [for (final t in s.tasks.toList()..sort((x, y) => x.sortOrder.compareTo(y.sortOrder))) t.title];

  testWidgets('desktop: a drag over the middle of a row reorders (its lower half: after it); Shift makes a subtask', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      for (final title in ['a', 'b', 'c']) {
        await repo.createTask(listId: inboxListId, title: title, atTop: false);
      }
    });
    await pumpApp(tester, '/p/inbox/tasks');
    // "a" straight down onto the lower half of "c", over the middle of the row: after c, not inside it.
    final cRow = tester.getRect(find.ancestor(of: find.text('c').first, matching: find.byType(TaskRowTile)).first);
    await dragTo(tester, find.text('a').first, Offset(tester.getCenter(find.text('a').first).dx + 20, cRow.bottom - 4));
    var s = (await tester.runAsync(repo.loadSnapshot))!;
    expect(byOrder(s), ['b', 'c', 'a']);
    expect(s.tasks.every((t) => t.parentId == null), isTrue);
    // With Shift held, the same kind of drag makes a subtask.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final bRow = tester.getRect(find.ancestor(of: find.text('b').first, matching: find.byType(TaskRowTile)).first);
    await dragTo(tester, find.text('a').first, Offset(tester.getCenter(find.text('a').first).dx, bRow.center.dy));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    s = (await tester.runAsync(repo.loadSnapshot))!;
    expect(s.taskById[s.tasks.firstWhere((t) => t.title == 'a').parentId]?.title, 'b');
    await _dispose(tester);
  });

  testWidgets('phone: a long press and a move reorders; a long press that stays opens the menu', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      for (final title in ['a', 'b', 'c']) {
        await repo.createTask(listId: inboxListId, title: title, atTop: false);
      }
    });
    await pumpApp(tester, '/p/inbox/tasks', size: const Size(412, 900));
    final aRow = tester.getTopLeft(find.text('a').first);
    final gesture = await tester.startGesture(tester.getCenter(find.text('c').first));
    await tester.pump(const Duration(milliseconds: 700));
    final start = tester.getCenter(find.text('c').first);
    final to = Offset(aRow.dx + 5, aRow.dy + 5);
    for (var i = 1; i <= 8; i++) {
      await gesture.moveTo(Offset.lerp(start, to, i / 8)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(byOrder((await tester.runAsync(repo.loadSnapshot))!), ['c', 'a', 'b']);

    final press = await tester.startGesture(tester.getCenter(find.text('b').first));
    await tester.pump(const Duration(milliseconds: 700));
    await press.up();
    await tester.pumpAndSettle();
    expect(find.text('Selecionar'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('Hoje sorted by date: a drag reorders the day and switches to the custom order, kept after reopening', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      for (final title in ['a', 'b', 'c']) {
        await repo.createTask(listId: inboxListId, title: title, dueDate: DateTime(2026, 9, 24), atTop: false);
      }
    });
    await pumpApp(tester, '/q/today/tasks');
    final aRow = tester.getTopLeft(find.text('a').first);
    await dragTo(tester, find.text('c').first, Offset(aRow.dx + 5, aRow.dy + 5));
    expect(byOrder((await tester.runAsync(repo.loadSnapshot))!), ['c', 'a', 'b']);
    expect(find.textContaining('Personalizado'), findsOneWidget);
    // The custom order is saved for Hoje: reopened, the list keeps it.
    await _dispose(tester);
    await pumpApp(tester, '/q/today/tasks');
    expect(tester.getTopLeft(find.text('c').first).dy, lessThan(tester.getTopLeft(find.text('a').first).dy));
    expect(tester.getTopLeft(find.text('a').first).dy, lessThan(tester.getTopLeft(find.text('b').first).dy));
    await _dispose(tester);
  });

  testWidgets('a reminder firing with the app open shows the popup; Adiar snoozes, Concluído completes', (tester) async {
    final movable = FixedClock(DateTime(2026, 9, 24, 12));
    final repo = Repository(db, clock: movable);
    final a = await tester.runAsync(
      () => repo.createTask(
        listId: inboxListId,
        title: 'Ligar para o banco',
        dueDate: DateTime(2026, 9, 24, 12, 1),
        isAllDay: false,
        reminders: ['PT0S'],
      ),
    );
    final b = await tester.runAsync(
      () => repo.createTask(listId: inboxListId, title: 'Pagar boleto', dueDate: DateTime(2026, 9, 24, 12, 2), isAllDay: false, reminders: ['PT0S']),
    );
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(movable)],
        child: const TasksApp(initialLocation: '/q/today/tasks'),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Adiar'), findsNothing);

    movable.time = DateTime(2026, 9, 24, 12, 1, 5);
    await tester.pump(const Duration(minutes: 1, seconds: 2));
    expect(find.text('Adiar'), findsOneWidget);
    await tester.tap(find.text('Adiar'));
    await tester.pump();
    await tester.tap(find.text('15 minutos'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect((await tester.runAsync(() => repo.task(a!)))!.snoozeUntil!.toLocal(), DateTime(2026, 9, 24, 12, 16, 5));
    expect(find.text('Adiar'), findsNothing);

    movable.time = DateTime(2026, 9, 24, 12, 2, 5);
    await tester.pump(const Duration(minutes: 1));
    expect(find.widgetWithText(FilledButton, 'Concluído'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Concluído'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect((await tester.runAsync(() => repo.task(b!)))!.status, TaskStatus.completed);
    await _dispose(tester);
  });

  testWidgets('add field calendar icon: the picked date goes to the new task', (tester) async {
    await pumpApp(tester, '/p/inbox/tasks');
    await tester.tap(find.byIcon(Icons.calendar_today_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Amanhã'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();
    expect(find.text('Amanhã, 25 set'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Com data do seletor');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    final created = tasks!.singleWhere((t) => t.title == 'Com data do seletor');
    expect(created.dueDate!.toLocal(), DateTime(2026, 9, 25));
    expect(created.isAllDay, isTrue);
    await _dispose(tester);
  });

  testWidgets('quick-add token popup: arrows + Enter insert the choice', (tester) async {
    await pumpApp(tester, '/p/inbox/tasks');
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, 'Ler livro !');
    await tester.pump();
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Nenhuma'), findsOneWidget);
    await tester.enterText(field, 'Ler livro !m');
    await tester.pump();
    expect(find.text('Alta'), findsNothing);
    await tester.enterText(field, 'Ler livro !');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'Ler livro !média ');
    expect(find.text('Alta'), findsNothing, reason: 'the popup closes after choosing');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final created = (await tester.runAsync(() => db.select(db.tasks).get()))!.singleWhere((t) => t.title == 'Ler livro');
    expect(created.priority, Priority.medium);
    await _dispose(tester);
  });

  testWidgets('comments: the footer icon opens the field, Enter adds "Comentários 1"', (tester) async {
    final repo = Repository(db, clock: clock);
    final id = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Com comentário'));
    await pumpApp(tester, '/p/inbox/tasks/$id');
    await tester.tap(find.byTooltip('Escrever um comentário'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Falar com o João');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Comentários 1'), findsOneWidget);
    expect(find.text('Falar com o João'), findsOneWidget);
    expect(find.text('Agora mesmo'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('"Mostrar detalhes" also works in a smart list and turns into "Ocultar Detalhes"', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(
      () => repo.createTask(listId: inboxListId, title: 'Relatório', content: 'Primeira linha da nota', dueDate: DateTime(2026, 9, 24)),
    );
    await pumpApp(tester, '/q/today/tasks');
    expect(find.text('Primeira linha da nota'), findsNothing);
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar detalhes'));
    await tester.pumpAndSettle();
    expect(find.text('Primeira linha da nota'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    expect(find.text('Ocultar Detalhes'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('a file dropped on the detail becomes an attachment card at the end of the content', (tester) async {
    final repo = Repository(db, clock: clock);
    final id = (await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Relatório', content: 'Texto')))!;
    final file = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('drop_test');
      return File('${dir.path}${Platform.pathSeparator}notas.txt')..writeAsStringSync('conteúdo');
    }))!;
    await pumpApp(tester, '/p/inbox/tasks/$id');
    // The desktop_drop plugin reports the drag on its channel, in window coordinates.
    Future<void> send(String method, Object arguments) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'desktop_drop',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
    final spot = tester.getCenter(find.byType(ContentEditor));
    await send('entered', [spot.dx, spot.dy]);
    await send('updated', [spot.dx, spot.dy]);
    await tester.pump();
    await send('performOperation', [file.path]);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final content = (await tester.runAsync(() => repo.task(id)))!.content;
    expect(content, matches(RegExp(r'^Texto\n!\[file\]\([^/]+/notas\.txt\)$')));
    await _dispose(tester);
  });

  testWidgets('phone: the habit form stacks its fields and offers chips instead of squeezed segments', (tester) async {
    await pumpApp(tester, '/habit', size: const Size(560, 1000));
    unawaited(showHabitForm(tester.element(find.byType(HabitPage))));
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<HabitFrequency>), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Diariamente'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Conquiste tudo'), findsOneWidget);
    // The label sits above its field: "Frequência" is higher than the chips.
    expect(tester.getRect(find.text('Frequência')).bottom, lessThanOrEqualTo(tester.getRect(find.widgetWithText(ChoiceChip, 'Diariamente')).top));
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('phone: Matriz is in the drawer, shows the 4 quadrants at once; long press drags a task', (tester) async {
    final repo = Repository(db, clock: clock);
    final id = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Pagar conta', priority: Priority.high));
    await pumpApp(tester, '/q/all/tasks', size: const Size(560, 1000));
    await tester.tap(find.byIcon(Icons.menu_open).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matriz de Eisenhower'));
    await tester.pumpAndSettle();
    for (final name in ['Urgente e Importante', 'Não Urgente e Importante', 'Urgente e não importante', 'Não urgente e não importante']) {
      expect(tester.getRect(find.text(name)).right, lessThanOrEqualTo(560), reason: name);
    }
    // Two columns: Q2 is beside Q1, Q3 below it.
    expect(tester.getRect(find.text('Não Urgente e Importante')).left, greaterThan(250));
    expect(tester.getRect(find.text('Urgente e não importante')).top, greaterThan(400));
    expect(tester.takeException(), isNull);

    // A plain drag does not move the task; a long press does.
    await tester.drag(find.text('Pagar conta'), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(() => repo.loadSnapshot()))!.taskById[id]!.priority, Priority.high);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Pagar conta')));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.text('Não Urgente e Importante')) + const Offset(0, 120));
    await tester.pump();
    await gesture.up();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((await tester.runAsync(() => repo.loadSnapshot()))!.taskById[id]!.priority, Priority.medium);

    // Tapping a task opens its detail on the whole screen.
    await tester.tap(find.text('Pagar conta'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Dialog)).width, 560);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await _dispose(tester);
  });

  testWidgets('phone: Kanban shows columns; a long press moves a card, a plain drag scrolls, a tap opens it', (tester) async {
    final repo = Repository(db, clock: clock);
    late String listId, taskId;
    await tester.runAsync(() async {
      listId = await repo.createList(name: 'Obra', viewMode: ViewMode.kanban);
      // New sections go first: the columns are Não Classificado, Fazer, Feito.
      await repo.createSection(listId, 'Feito');
      await repo.createSection(listId, 'Fazer');
      taskId = await repo.createTask(listId: listId, title: 'Comprar cimento');
    });
    Future<String?> sectionName() async {
      final s = (await tester.runAsync(() => repo.loadSnapshot()))!;
      return s.sectionsOf(listId).where((x) => x.id == s.taskById[taskId]!.sectionId).firstOrNull?.name;
    }

    await pumpApp(tester, '/p/$listId/tasks', size: const Size(560, 1000));
    expect(find.byType(KanbanBoard), findsOneWidget);
    expect(find.text('Comprar cimento'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A long press picks the card up and drops it in "Fazer".
    final gesture = await tester.startGesture(tester.getCenter(find.text('Comprar cimento')));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.text('Fazer')) + const Offset(0, 80));
    await tester.pump();
    await gesture.up();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(await sectionName(), 'Fazer');

    // A plain drag on the card scrolls the board sideways; the card stays in its column.
    final before = tester.getTopLeft(find.text('Fazer'));
    await tester.drag(find.text('Comprar cimento'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Fazer')).dx, lessThan(before.dx));
    expect(await sectionName(), 'Fazer');

    // A tap opens the detail on the whole screen.
    await tester.tap(find.text('Comprar cimento'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(KanbanBoard), findsNothing);
    expect(find.byType(TaskDetailPane), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('phone: long press > Selecionar starts a selection; taps add tasks; Editar applies to all; back ends it', (tester) async {
    final repo = Repository(db, clock: clock);
    final ids = <String, String>{};
    await tester.runAsync(() async {
      for (final title in ['Lavar carro', 'Pagar luz', 'Ler livro']) {
        ids[title] = await repo.createTask(listId: inboxListId, title: title);
      }
    });
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> select(String title) async {
      await tester.longPress(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
    }

    await pumpApp(tester, '/p/inbox/tasks', size: const Size(560, 1000));
    await select('Lavar carro');
    expect(find.byType(PhoneSelectionBar), findsOneWidget);
    expect(find.textContaining('Você escolheu 1'), findsOneWidget);
    // While selecting, a tap adds the task instead of opening it.
    await tester.tap(find.text('Pagar luz'));
    await settle();
    expect(find.textContaining('Você escolheu 2'), findsOneWidget);
    expect(find.byType(TaskDetailPane), findsNothing);

    // Editar: the batch panel on the whole screen; Concluído applies to both and ends the selection.
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(BatchPane)).width, 560);
    await tester.tap(find.descendant(of: find.byType(BatchPane), matching: find.text('Concluído')));
    await settle();
    expect(find.byType(BatchPane), findsNothing);
    expect(find.byType(PhoneSelectionBar), findsNothing);
    final snapshot = (await tester.runAsync(() => repo.loadSnapshot()))!;
    expect([for (final title in ids.keys) snapshot.taskById[ids[title]]!.status], [TaskStatus.completed, TaskStatus.completed, TaskStatus.open]);

    // Back ends a selection and stays on the list.
    await select('Ler livro');
    expect(find.byType(PhoneSelectionBar), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(PhoneSelectionBar), findsNothing);
    expect(find.text('Ler livro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('phone back: closes the drawer, goes to Hoje, leaves dialogs to themselves', (tester) async {
    // Narrow layout; wider than a phone only because the test font draws every letter a full em wide.
    await pumpApp(tester, '/countdown', size: const Size(700, 900));
    Future<bool> back() async {
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      return handled;
    }

    // Drawer open: back only closes it.
    await tester.tap(find.byIcon(Icons.menu).first);
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(await back(), isTrue);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(CountdownPage), findsOneWidget);

    // A menu over the page: back closes the menu, the page stays.
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    expect(find.text('Arquivado'), findsOneWidget);
    expect(await back(), isTrue);
    expect(find.text('Arquivado'), findsNothing);
    expect(find.byType(CountdownPage), findsOneWidget);

    // A module: back goes to Hoje; on Hoje, back is left to the system (the app closes).
    expect(await back(), isTrue);
    expect(find.byType(CountdownPage), findsNothing);
    expect(find.text('Hoje'), findsWidgets);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(await tester.binding.handlePopRoute(), isFalse);
    await _dispose(tester);
  });

  testWidgets('countdowns: the defaults show in Hoje; a birthday is created through the form', (tester) async {
    await pumpApp(tester, '/q/today/tasks');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Contagem Regressiva'), findsOneWidget);
    expect(find.text('Use o Tarefas'), findsOneWidget);

    await tester.tap(find.byTooltip('Contagem Regressiva'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('99'), findsOneWidget, reason: 'Dia de Ano Novo');
    // Clicking the number shows weeks, then months.
    await tester.tap(find.text('99'));
    await tester.pump();
    expect(find.text('14 semanas'), findsOneWidget);
    await tester.tap(find.text('14 semanas'));
    await tester.pump();
    expect(find.text('3 meses'), findsOneWidget);
    // "+ Nova contagem" of the top bar asks the kind.
    await tester.tap(find.widgetWithText(CreateButton, 'Nova contagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aniversário').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Aniversário da Ana');
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final created = (await tester.runAsync(() => db.select(db.countdowns).get()))!.singleWhere((c) => c.name == 'Aniversário da Ana');
    expect(created.type, CountdownType.birthday);
    expect(created.repeatRule, startsWith('FREQ=YEARLY'), reason: 'birthdays repeat every year by default');
    expect(find.text('Aniversário da Ana'), findsOneWidget);

    // The panel's "Tipos": unchecking Feriado hides the holidays; each kind has its heading.
    expect(find.widgetWithText(BodyHeading, 'Aniversário'), findsOneWidget);
    await tester.tap(find.widgetWithText(PanelCheckRow, 'Feriado'));
    await tester.pumpAndSettle();
    expect(find.text('Aniversário da Ana'), findsOneWidget);
    expect(find.text('Dia de Ano Novo'), findsNothing);
    await tester.tap(find.widgetWithText(PanelCheckRow, 'Feriado'));
    await tester.pumpAndSettle();
    expect(find.text('Dia de Ano Novo'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('focus: a Pomo runs, ends with "Você tem um Pomo.", records and goes to the break', (tester) async {
    final movable = FixedClock(DateTime(2026, 9, 24, 18, 24));
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(movable)],
        child: const TasksApp(initialLocation: '/focus'),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('25:00'), findsOneWidget);
    await tester.tap(find.text('Começar'));
    await tester.pump();
    movable.time = DateTime(2026, 9, 24, 18, 34);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);

    movable.time = DateTime(2026, 9, 24, 18, 49, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Você tem um Pomo.'), findsOneWidget);
    final records = await tester.runAsync(() => db.select(db.focusRecords).get());
    expect(records!.single.seconds, 25 * 60);
    await tester.pump(const Duration(milliseconds: 200));
    // During the session the right side is the day's timeline; the record list comes back after it.
    expect(find.text('18:24 - 18:49'), findsNothing);

    await tester.tap(find.text('Relaxar'));
    await tester.pump();
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Pausa'), findsOneWidget);
    await tester.tap(find.text('Terminar'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('18:24 - 18:49'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('habits: empty state, create through the form, check in today', (tester) async {
    await pumpApp(tester, '/habit');
    expect(find.text('Desenvolver um hábito'), findsOneWidget);
    await tester.tap(find.widgetWithText(CreateButton, 'Novo hábito'));
    await tester.pumpAndSettle();
    // The gallery first: 15 ready-made habits per category, or "Criar novo".
    expect(find.text('Galeria de hábitos'), findsOneWidget);
    expect(find.text('Arrumar a cama'), findsOneWidget);
    await tester.tap(find.text('Criar novo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Beber água');
    // The color beside the name opens the Calendar's color menu, without the tasks' labels.
    await tester.tap(find.byType(HabitColorButton));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Editar rótulos'), findsNothing);
    await tester.tap(find.byTooltip('Tomate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Beber água'), findsOneWidget);
    expect(find.text('0 dia · 0 dia'), findsOneWidget);
    Future<String?> color() async => (await tester.runAsync(() => db.select(db.habits).getSingle()))!.color;
    expect(await color(), '#DA5234');
    // Right-click › Cor changes it on the spot.
    await tester.tap(find.text('Beber água'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cor'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mirtilo'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(await color(), eventPalette[13]);
    // The last of the 7 dots is today.
    await tester.tap(find.byType(HabitDot).last);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('1 dia · 1 dia'), findsOneWidget);
    expect((await tester.runAsync(() => db.select(db.habitCheckins).get()))!.single.value, 1);
    await _dispose(tester);
  });

  testWidgets('what is added can be undone and deleted where it is edited: a habit, a countdown, a list', (tester) async {
    final repo = Repository(db, clock: clock);
    late String list;
    await tester.runAsync(() async {
      final habit = await repo.createHabit(HabitsCompanion(name: const Value('Ler'), startDate: Value(DateTime.utc(2026, 9, 1))));
      await repo.checkIn(habit, DateTime(2026, 9, 24));
      await repo.createCountdown(name: 'Viagem', date: DateTime(2026, 12, 20));
      list = await repo.createList(name: 'Mercado');
    });
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // A habit: a click on a day done opens its menu, to undo it.
    await pumpApp(tester, '/habit');
    expect(find.text('1 dia · 1 dia'), findsOneWidget);
    await tester.tap(find.byType(HabitDot).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reiniciar hábito'));
    await settle();
    expect(find.text('0 dia · 0 dia'), findsOneWidget);
    // Its ⋯ › Editar: the form has the bin, which asks first.
    await tester.tap(find.byType(RowMenuButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Deletar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Excluir o hábito "Ler"'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
    await settle();
    expect(find.text('Ler'), findsNothing);
    expect(await tester.runAsync(() => db.select(db.habits).get()), isEmpty);

    // A countdown: ⋯ on its card; the form (a click) has the bin.
    await _dispose(tester);
    await pumpApp(tester, '/countdown');
    expect(find.byTooltip('Mais'), findsWidgets);
    await tester.tap(find.text('Viagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Deletar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
    await settle();
    expect(find.text('Viagem'), findsNothing);

    // A list: the open list's ⋯ › Editar lista has the bin; deleting goes back to the Inbox.
    await _dispose(tester);
    await pumpApp(tester, '/p/$list/tasks');
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    expect(find.text('Deletar lista'), findsOneWidget);
    await tester.tap(find.text('Editar lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Deletar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
    await settle();
    expect(find.text('Mercado'), findsNothing);
    final lists = await tester.runAsync(() => (db.select(db.lists)..where((l) => l.id.equals(list))).get());
    expect(lists!.single.deletedAt, isNotNull);
    await _dispose(tester);
  });

  testWidgets('filters: "+" in Filtros opens Adicionar Filtro; Prévia counts; Salvar opens the filter', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      await repo.createTask(listId: inboxListId, title: 'A alta', priority: Priority.high);
      await repo.createTask(listId: inboxListId, title: 'B baixa', priority: Priority.low);
    });
    await pumpApp(tester, '/q/all/tasks');
    final header = find.ancestor(of: find.text('Filtros'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: header, matching: find.byIcon(Icons.add)));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar Filtro'), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first, 'Urgentes');
    // Listas, Tags, Data, Prioridade, Tipo: the 4th "Todas" is Prioridade.
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Todas')).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alta'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prévia'));
    await tester.pump();
    expect(find.text('1 tarefa encontrada'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Urgentes'), findsWidgets);
    expect(find.text('A alta'), findsOneWidget);
    expect(find.text('B baixa'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('filters: Data > Personalizado asks for the first and last day', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      await repo.createTask(listId: inboxListId, title: 'Dentro', dueDate: DateTime(2026, 10, 5));
      await repo.createTask(listId: inboxListId, title: 'Fora', dueDate: DateTime(2026, 10, 20));
    });
    await pumpApp(tester, '/q/all/tasks');
    final header = find.ancestor(of: find.text('Filtros'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: header, matching: find.byIcon(Icons.add)));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first, 'Outubro');
    // Listas, Tags, Data: the 3rd "Todas" is Data.
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Todas')).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personalizado'));
    await tester.pumpAndSettle();
    // Type the days instead of tapping the calendar.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    // The range picker is on top: its two fields are the last ones.
    final fields = find.byType(TextField);
    final count = fields.evaluate().length;
    await tester.enterText(fields.at(count - 2), '01/10/2026');
    await tester.enterText(fields.at(count - 1), '10/10/2026');
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
    expect(find.text('01/10/2026 - 10/10/2026'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('01/10/2026 - 10/10/2026'), findsOneWidget);
    await tester.tap(find.text('Prévia'));
    await tester.pump();
    expect(find.text('1 tarefa encontrada'), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Dentro')), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await _dispose(tester);
  });
}

/// Unmounts the app and lets pending timers (clock ticker, editor debounce, drift streams) finish.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(minutes: 2));
}
