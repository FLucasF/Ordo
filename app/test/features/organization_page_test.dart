import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/features/countdown/project_dashboard.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Thursday, 2026-09-24, noon.
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

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

  Future<T> run<T>(WidgetTester tester, Future<T> Function() action) async => (await tester.runAsync(action)) as T;

  testWidgets('areas: "Nova área" in the sidebar with emoji and color; ⋯ › Deletar keeps the lists, with Desfazer', (tester) async {
    late String gym;
    await run(tester, () async => gym = await repo.createList(name: 'Academia'));
    await pumpApp(tester, '/q/today/tasks');

    // The lists' header: "Nova área" beside the "+".
    await tester.tap(find.byTooltip('Nova área'));
    await tester.pumpAndSettle();
    expect(find.text('Nova área'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, 'Saúde');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
    await settle(tester);
    expect(find.text('Saúde'), findsOneWidget);
    var folder = (await run(tester, () => db.select(db.folders).get())).single;
    expect(folder.name, 'Saúde');

    // The list goes in through its form ("Área").
    await run(tester, () => repo.moveList(gym, folderId: folder.id));
    await run(tester, () => repo.editFolder(folder.id, name: 'Saúde', icon: '💪', color: '#35D870'));
    await settle(tester);
    expect(find.text('💪'), findsOneWidget);

    // ⋯ › Deletar: the area goes, the list stays; "Desfazer" brings it back with the list.
    await tester.longPress(find.text('Saúde'));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsOneWidget);
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Área "Saúde" deletada; as listas ficaram'), findsOneWidget);
    expect(find.text('Saúde'), findsNothing);
    expect(find.text('Academia'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    folder = (await run(tester, () => db.select(db.folders).get())).single;
    expect(folder.deletedAt, isNull);
    expect((await run(tester, () => (db.select(db.lists)..where((l) => l.id.equals(gym))).getSingle())).folderId, folder.id);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('sublists: indented under the parent, folded by the arrow; "Dentro de" in the list form', (tester) async {
    late String uni, calc;
    await run(tester, () async {
      uni = await repo.createList(name: 'Faculdade');
      calc = await repo.createList(name: 'Cálculo', parentId: uni);
      await repo.createTask(listId: calc, title: 'derivadas');
      await repo.createTask(listId: uni, title: 'matrícula');
    });
    await pumpApp(tester, '/p/$uni/tasks');
    expect(tester.getTopLeft(find.text('Cálculo')).dx, greaterThan(tester.getTopLeft(find.text('Faculdade').first).dx));
    // The arrow folds the sublists away (and remembers it).
    await tester.tap(find.byTooltip('Recolher sublistas'));
    await settle(tester);
    expect(find.text('Cálculo'), findsNothing);
    expect((await run(tester, () => PreferencesRepository(db).watch().first)).collapsedLists, {uni});
    await tester.tap(find.byTooltip('Mostrar sublistas'));
    await settle(tester);
    expect(find.text('Cálculo'), findsOneWidget);

    // "Incluir sublistas" in the list's ⋯: the sublist's tasks show, under its name.
    expect(find.text('derivadas'), findsNothing);
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, 'Incluir sublistas'));
    await settle(tester);
    expect(find.text('derivadas'), findsOneWidget);
    expect(find.text('matrícula'), findsOneWidget);
    expect(find.text('Cálculo'), findsNWidgets(3), reason: 'the sidebar, the group header and the task row\'s list');

    // The list form: "Dentro de" names the parent; "Nenhuma (no topo)" takes it out.
    await tester.longPress(find.text('Cálculo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Dentro de'), findsOneWidget);
    await tester.tap(find.text('Faculdade').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nenhuma (no topo)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await settle(tester);
    expect((await run(tester, () => (db.select(db.lists)..where((l) => l.id.equals(calc))).getSingle())).parentId, isNull);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('sidebar: a list dropped on the middle of another becomes its sublist', (tester) async {
    late String alfa, beta;
    await run(tester, () async {
      alfa = await repo.createList(name: 'Alfa');
      beta = await repo.createList(name: 'Beta');
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await pumpApp(tester, '/q/today/tasks');
    final from = tester.getCenter(find.text('Beta'));
    final to = tester.getCenter(find.text('Alfa'));
    final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);
    expect((await run(tester, () => (db.select(db.lists)..where((l) => l.id.equals(beta))).getSingle())).parentId, alfa);
    expect(find.text('"Beta" agora está dentro de "Alfa"'), findsOneWidget);
    await dispose(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a countdown linked to a list: progress on its card, the dashboard, closing with the final report', (tester) async {
    late String list;
    await run(tester, () async {
      list = await repo.createList(name: 'TCC');
      final sec = await repo.createSection(list, 'Escrita');
      Future<void> doneOn(String id, DateTime at) async {
        clock.time = at;
        await repo.complete(id);
        clock.time = DateTime(2026, 9, 24, 12);
      }

      await doneOn(await repo.createTask(listId: list, title: 'Introdução', dueDate: DateTime(2026, 9, 20)), DateTime(2026, 9, 19, 10));
      await doneOn(await repo.createTask(listId: list, title: 'Revisão', dueDate: DateTime(2026, 9, 21)), DateTime(2026, 9, 23, 10));
      await repo.createTask(listId: list, sectionId: sec, title: 'Conclusão', dueDate: DateTime(2026, 9, 22));
      await repo.createTask(listId: list, title: 'Slides', dueDate: DateTime(2026, 9, 30));
      await repo.createCountdown(name: 'Entrega do TCC', date: DateTime(2026, 10, 4), listId: list);
    });
    await pumpApp(tester, '/countdown');
    expect(find.text('2/4'), findsOneWidget);

    // A click opens the dashboard.
    await tester.tap(find.text('Entrega do TCC'));
    await settle(tester);
    expect(find.byType(ProjectDashboard), findsOneWidget);
    expect(find.text('Faltam 10 dias'), findsOneWidget);
    expect(find.text('2 de 4 tarefas'), findsWidgets);
    // Accuracy: on time 100%, late 50%, overdue 0% → 50%.
    expect(find.text('50%'), findsWidgets);
    expect(find.text('1 no prazo · 1 depois · 1 vencidas'), findsOneWidget);
    // Pace: 2 left in 10 days; 2 done in the last 7 days.
    expect(find.text('Faça 0,2 tarefas por dia'), findsOneWidget);
    expect(find.text('Média dos últimos 7 dias: 0,3 por dia'), findsOneWidget);
    expect(find.text('Escrita'), findsOneWidget);
    expect(find.text('Atrasadas'), findsOneWidget);

    // "Encerrar projeto": the report is frozen and shows as the closing card.
    await tester.tap(find.text('Encerrar projeto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Encerrar projeto'));
    await settle(tester);
    expect(find.text('Relatório final'), findsOneWidget);
    expect(find.text('Reabrir projeto'), findsOneWidget);
    final c = (await run(tester, () => db.select(db.countdowns).get())).singleWhere((c) => c.listId == list);
    expect(c.closedAt, isNotNull);
    expect(c.report, contains('"done":2'));

    // Reopened: open again, the report kept.
    await tester.tap(find.text('Reabrir projeto'));
    await settle(tester);
    expect(find.text('Encerrar projeto'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('the countdown form links a project; the dashboard fits a phone', (tester) async {
    late String list;
    await run(tester, () async {
      list = await repo.createList(name: 'Mudança');
      await repo.createTask(listId: list, title: 'Caixas', dueDate: DateTime(2026, 9, 20));
      await repo.createCountdown(name: 'Dia da mudança', date: DateTime(2026, 10, 10));
    });
    await pumpApp(tester, '/countdown');
    // An unlinked countdown opens its form, as before.
    await tester.tap(find.text('Dia da mudança'));
    await tester.pumpAndSettle();
    expect(find.text('Vincular a uma lista ou área'), findsOneWidget);
    await tester.tap(find.text('Nenhuma').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudança').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await settle(tester);
    final c = (await run(tester, () => db.select(db.countdowns).get())).singleWhere((c) => c.name == 'Dia da mudança');
    expect(c.listId, list);
    expect(find.text('0/1'), findsOneWidget);
    await dispose(tester);

    // A phone: the dashboard is a full screen, without overflows.
    await pumpApp(tester, '/countdown', size: const Size(400, 800));
    await tester.tap(find.text('Dia da mudança'));
    await settle(tester);
    expect(find.byType(ProjectDashboard), findsOneWidget);
    expect(find.byTooltip('Encerrar projeto'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
}
