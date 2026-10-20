import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/diet_repository.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/diet/diet_page.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 9, 12, 30));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
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
    // The TACO table is read from the app's assets.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(tester, 10);
  }

  /// The TACO table loads from the assets (slower with other tests running): pumps until [finder] shows.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('Dieta: a TACO food in a household measure, an own food from "Não achei", the sums, deleting with undo', (tester) async {
    await pumpApp(tester, '/diet');
    expect(find.text('Café da manhã'), findsOneWidget);
    expect(find.text('Nada lançado neste dia.'), findsOneWidget);

    // "+ Adicionar alimento": 12:30 is lunch; "arroz integral cozido" without accents found in TACO.
    await tester.tap(find.widgetWithText(CreateButton, 'Adicionar alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Buscar alimento (ex.: arroz, banana, frango)').last, 'arroz integral cozido');
    await waitFor(tester, find.text('Arroz, integral, cozido'));
    await tester.tap(find.text('Arroz, integral, cozido').last);
    await tester.pumpAndSettle();
    // 1 "colher de sopa cheia" (25 g) to begin with; 4 of them are 100 g.
    expect(find.textContaining('= 25 g'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '4');
    await tester.pumpAndSettle();
    expect(find.textContaining('= 100 g · 124 kcal'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Arroz, integral, cozido'), findsOneWidget);
    expect(find.textContaining('4 colher de sopa cheia (100 g)'), findsOneWidget);
    expect(find.text('124 kcal'), findsWidgets);

    // "Não achei": an own food, used at once, in grams.
    await tester.tap(find.widgetWithText(CreateButton, 'Adicionar alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Buscar alimento (ex.: arroz, banana, frango)').last, 'Whey da loja');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não achei: cadastrar alimento'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Nome'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Calorias'), '400');
    await tester.enterText(find.widgetWithText(TextField, 'Proteínas'), '80');
    await tester.tap(find.text('Cadastrar e usar'));
    await settle(tester);
    expect(find.text('Whey da loja'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '30');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    // 124 + 120 kcal; 2,6 + 24 g of protein.
    expect(find.text('244 kcal'), findsWidgets);
    expect(find.text('26,6 g'), findsOneWidget);

    // ⋯ › Deletar, then Desfazer.
    await tester.tap(find.descendant(of: find.widgetWithText(AgendaLine, 'Whey da loja'), matching: find.byType(RowMenuButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Whey da loja'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Whey da loja'), findsOneWidget);

    // Alimentos: the own food is there, with ⋯ to edit or delete it.
    await tester.tap(find.descendant(of: find.byType(ShellTabs<DietTab>), matching: find.text('Alimentos')));
    await settle(tester);
    expect(find.widgetWithText(AgendaLine, 'Whey da loja'), findsOneWidget);
    expect(find.text('400 kcal/100 g'), findsOneWidget);
    // The search goes over TACO too, without accents.
    await tester.enterText(find.byType(TextField).first, 'acucar');
    await waitFor(tester, find.textContaining('Açúcar'));
    expect(find.textContaining('Açúcar'), findsWidgets);
    final s = await tester.runAsync(() => DietRepository(db, clock: clock).load());
    expect(s!.foods.single.name, 'Whey da loja');
    expect(s.entries, hasLength(2));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
  testWidgets('own food: empty calories come from the macros (P×4 + C×4 + G×9)', (tester) async {
    await pumpApp(tester, '/diet');
    await tester.tap(find.descendant(of: find.byType(ShellTabs<DietTab>), matching: find.text('Alimentos')));
    await settle(tester);
    await tester.tap(find.widgetWithText(CreateButton, 'Novo alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Iogurte da casa');
    await tester.enterText(find.widgetWithText(TextField, 'Proteínas'), '10');
    await tester.enterText(find.widgetWithText(TextField, 'Carboidratos'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Gorduras'), '3');
    await tester.pump();
    // 40 + 20 + 27.
    expect(find.text('87'), findsOneWidget);
    expect(find.text('Pelos macros: P×4 + C×4 + G×9'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final s = await tester.runAsync(() => DietRepository(db, clock: clock).load());
    expect(s!.foods.single.kcal, 87);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
}
