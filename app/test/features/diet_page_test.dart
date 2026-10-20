import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/diet_repository.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/domain/diet/diet.dart';
import 'package:task_manager/domain/diet/targets.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/diet/diet_page.dart';
import 'package:task_manager/features/finance/finance_widgets.dart' show FinChip;

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

  /// "arroz integral cozido" picked in the open entry or plan form, [quantity] of its default measure.
  Future<void> pickRice(WidgetTester tester, {String quantity = '4'}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Buscar alimento (ex.: arroz, banana, frango)').last, 'arroz integral cozido');
    // In the form: the page behind may show the food too.
    final result = find.descendant(of: find.byType(Dialog), matching: find.text('Arroz, integral, cozido'));
    await waitFor(tester, result);
    await tester.tap(result.first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), quantity);
    await tester.pumpAndSettle();
  }

  /// Types [time] in the open "Hora" dialog and confirms it.
  Future<void> typeTime(WidgetTester tester, String time) async {
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), time);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('meals: renaming a built-in one, "+ Refeição" with a time, the time suggests the meal, archiving keeps the entries', (tester) async {
    await pumpApp(tester, '/diet');
    final repo = DietRepository(db, clock: clock);

    // A click on the meal's name edits it.
    await tester.tap(find.text('Café da manhã'));
    await tester.pumpAndSettle();
    expect(find.text('Editar refeição'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Desjejum');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Desjejum'), findsOneWidget);
    expect(find.text('Café da manhã'), findsNothing);

    // "+ Refeição" at 12:15, placed before lunch.
    await tester.tap(find.text('Refeição'));
    await tester.pumpAndSettle();
    expect(find.text('Nova refeição'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Pré-almoço');
    await tester.tap(find.text('Sem horário'));
    await tester.pumpAndSettle();
    await typeTime(tester, '12:15');
    expect(find.text('12:15'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    var s = (await tester.runAsync(repo.load))!;
    final pre = s.activeMeals.firstWhere((m) => m.name == 'Pré-almoço');
    final order = [for (final m in s.activeMeals) m.id];
    expect(pre.time, 735);
    expect(order.indexOf(pre.id), order.indexOf('lunch') - 1);
    expect(find.text('Pré-almoço'), findsOneWidget);

    // Lunch moved to 13:00: at 12:30 the new meal is the one suggested.
    await tester.tap(find.text('Almoço'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('12:30')));
    await tester.pumpAndSettle();
    await typeTime(tester, '13:00');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect((await tester.runAsync(repo.load))!.meal('lunch')?.time, 780);
    await tester.tap(find.widgetWithText(CreateButton, 'Adicionar alimento'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(DropdownButtonFormField<String>), matching: find.text('Pré-almoço')), findsOneWidget);
    await pickRice(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    s = (await tester.runAsync(repo.load))!;
    expect(s.entries.single.meal, pre.id);

    // ⋯ › Arquivar (it has food): it leaves the meals in use but its day still shows it.
    await tester.tap(find.descendant(of: find.byKey(ValueKey('meal-${pre.id}')), matching: find.byType(RowMenuButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arquivar'));
    await settle(tester);
    expect(find.text('Refeição arquivada'), findsOneWidget);
    expect(find.textContaining('· arquivada'), findsOneWidget);
    expect(find.text('Arroz, integral, cozido'), findsOneWidget);
    expect((await tester.runAsync(repo.load))!.meal(pre.id)?.archivedAt, isNotNull);
    // "Refeições arquivadas" › Restaurar.
    await tester.tap(find.text('Refeições arquivadas (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurar'));
    await settle(tester);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(repo.load))!.meal(pre.id)?.archivedAt, isNull);
    expect(find.textContaining('· arquivada'), findsNothing);

    // A meal with nothing in it is deleted, with undo.
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('meal-supper')), matching: find.byType(RowMenuButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Ceia'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Ceia'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets("⚙ Metas: the day's totals against the targets, red above 110%; calories from the macros", (tester) async {
    await pumpApp(tester, '/diet');
    await tester.tap(find.byTooltip('Metas'));
    await tester.pumpAndSettle();
    expect(find.text('Metas diárias'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Calorias'), '2000');
    await tester.enterText(find.widgetWithText(TextField, 'Proteínas'), '2');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('0 / 2.000 kcal'), findsOneWidget);
    expect(find.text('0 / 2 g'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    await tester.tap(find.widgetWithText(CreateButton, 'Adicionar alimento'));
    await tester.pumpAndSettle();
    await pickRice(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    // 124 kcal of 2000: below, the app's blue; 2,6 g of 2 g: over 110%, red and full.
    expect(find.text('124 / 2.000 kcal'), findsOneWidget);
    expect(find.text('2,6 / 2 g'), findsOneWidget);
    final bars = tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).toList();
    expect(bars.last.color, isNot(bars.first.color));
    expect(bars.last.value, 1);
    expect(tester.widget<Text>(find.text('2,6 / 2 g')).style?.color, bars.last.color);

    // The calories from the macros: 2 g of protein = 8 kcal.
    await tester.tap(find.byTooltip('Metas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcular as calorias pelos macros (P×4 + C×4 + G×9)'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('8')), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('124 / 8 kcal'), findsOneWidget);
    final prefs = await tester.runAsync(() => db.select(db.preferences).get());
    expect(prefs!.where((p) => p.name == 'diet.targets').single.value, contains('"fromMacros":true'));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Plano: an item on Fridays, the weekday filter, "Importar plano do dia" once, the adherence', (tester) async {
    await pumpApp(tester, '/diet/plan');
    final repo = DietRepository(db, clock: clock);
    expect(find.text('Seu plano está vazio. Monte o cardápio prescrito com + Adicionar ao plano.'), findsOneWidget);

    await tester.tap(find.widgetWithText(CreateButton, 'Adicionar ao plano'));
    await tester.pumpAndSettle();
    expect(find.text('Dias da semana (nenhum marcado = todos os dias)'), findsOneWidget);
    // 9/10/2026 is a Friday.
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Sex')));
    await tester.pumpAndSettle();
    await pickRice(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final item = (await tester.runAsync(repo.load))!.plan.single;
    expect((item.weekdays, item.meal, item.grams), ('5', 'lunch', 100.0));
    expect(find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'), findsOneWidget);
    expect(find.textContaining('Total do plano: 124 kcal'), findsOneWidget);
    // Saturday's plan hasn't it; all of them has.
    await tester.tap(find.widgetWithText(FinChip, 'Sáb'));
    await settle(tester);
    expect(find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'), findsNothing);
    await tester.tap(find.widgetWithText(FinChip, 'Todos'));
    await settle(tester);
    expect(find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'), findsOneWidget);

    // The diary imports it once.
    await tester.tap(find.descendant(of: find.byType(ShellTabs<DietTab>), matching: find.text('Diário')));
    await settle(tester);
    await tester.tap(find.text('Importar plano do dia'));
    await settle(tester);
    expect(find.text('1 alimento importado do plano'), findsOneWidget);
    expect(find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'), findsOneWidget);
    expect(find.text('Adesão do dia: 100%'), findsOneWidget);
    await tester.tap(find.text('Importar plano do dia'));
    await settle(tester);
    expect(find.text('O plano do dia já está no diário'), findsOneWidget);
    expect((await tester.runAsync(repo.load))!.entries.single.planItemId, item.id);

    // Eating half of it: changed, 50%.
    await tester.tap(find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '2');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Adesão do dia: 50%'), findsOneWidget);

    // Plano: the last 7 days and the month, and the heat map; a day opens the diary.
    await tester.tap(find.descendant(of: find.byType(ShellTabs<DietTab>), matching: find.text('Plano')));
    await settle(tester);
    expect(find.text('ÚLTIMOS 7 DIAS'), findsOneWidget);
    expect(find.text('50%'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('adherence-9')));
    await settle(tester);
    expect(find.text('Adesão do dia: 50%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets("measures: the user's on a TACO food, many on an own food, each with its bin", (tester) async {
    await pumpApp(tester, '/diet/foods');
    final repo = DietRepository(db, clock: clock);
    await tester.enterText(find.byType(TextField).first, 'arroz integral cozido');
    await waitFor(tester, find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'));
    await tester.tap(find.descendant(of: find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'), matching: find.byType(RowMenuButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medidas caseiras'));
    await tester.pumpAndSettle();
    expect(find.text('Da tabela TACO'), findsOneWidget);
    expect(find.text('colher de sopa cheia'), findsOneWidget);
    await tester.tap(find.text('Medida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Medida (ex.: colher de sopa)'), 'concha');
    await tester.enterText(find.widgetWithText(TextField, 'Gramas'), '90');
    await tester.tap(find.text('Adicionar'));
    await settle(tester);
    expect(find.text('concha'), findsOneWidget);
    expect((await tester.runAsync(repo.load))!.userMeasuresOf('taco:1').single.grams, 90);
    // The bin: the toast is under the dialog, so the line keeps a "Desfazer" of its own.
    await tester.tap(find.byTooltip('Deletar'));
    await settle(tester);
    expect((await tester.runAsync(repo.load))!.userMeasuresOf('taco:1'), isEmpty);
    expect(find.byTooltip('Deletar'), findsNothing);
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Desfazer')));
    await settle(tester);
    expect(find.byTooltip('Deletar'), findsOneWidget);
    expect((await tester.runAsync(repo.load))!.userMeasuresOf('taco:1'), hasLength(1));
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    // The entry form offers it with the table's, and its "+" adds another one there.
    await tester.tap(find.widgetWithText(AgendaLine, 'Arroz, integral, cozido'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('concha (90 g)').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('= 90 g'), findsOneWidget);
    await tester.tap(find.byTooltip('Nova medida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Medida (ex.: colher de sopa)'), 'prato');
    await tester.enterText(find.widgetWithText(TextField, 'Gramas'), '200');
    await tester.tap(find.text('Adicionar'));
    await settle(tester);
    expect(find.textContaining('= 200 g'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // An own food with measures; the bin takes one out.
    await tester.tap(find.widgetWithText(CreateButton, 'Novo alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Pão caseiro');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Medida'));
      await tester.pumpAndSettle();
    }
    final names = find.widgetWithText(TextField, 'Medida (ex.: colher de sopa)');
    final grams = find.widgetWithText(TextField, 'Gramas');
    await tester.enterText(names.at(0), 'fatia');
    await tester.enterText(grams.at(0), '30');
    await tester.enterText(names.at(1), 'unidade');
    await tester.enterText(grams.at(1), '50');
    await tester.enterText(names.at(2), 'errada');
    await tester.enterText(grams.at(2), '1');
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.byTooltip('Deletar')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final s = (await tester.runAsync(repo.load))!;
    expect([for (final m in s.customFoods.single.measures) (m.name, m.grams)], [('fatia', 30.0), ('unidade', 50.0)]);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('phone: the diary with targets, an archived meal and the plan, and the Plano tab, fit', (tester) async {
    final repo = DietRepository(db, clock: clock);
    await tester.runAsync(() async {
      const rice = Food(id: 'taco:1', name: 'Arroz, integral, cozido', per100g: Nutrients(kcal: 123.5, protein: 2.59, carbs: 25.81, fat: 1));
      final meal = await repo.createMeal(name: 'Lanche pós-treino com um nome comprido demais', time: 17 * 60);
      await repo.addPlanItem(meal: meal, food: rice, quantity: 150, weekdays: '1,3,5');
      await repo.addPlanItem(meal: 'lunch', food: rice, quantity: 100);
      await repo.importPlan(DateTime(2026, 10, 9));
      await repo.archiveMeal(meal);
      await PreferencesRepository(db).setDietTargets(const DietTargets(kcal: 2000, protein: 150, carbs: 250, fat: 70));
    });
    await pumpApp(tester, '/diet', size: const Size(360, 780));
    expect(find.text('Importar plano do dia'), findsOneWidget);
    expect(find.textContaining('/ 2.000 kcal'), findsOneWidget);
    await tester.dragUntilVisible(find.textContaining('· arquivada'), find.byType(ListView).last, const Offset(0, -200));
    await settle(tester);
    expect(find.textContaining('· arquivada'), findsOneWidget);
    // The tabs scroll sideways when they don't fit (the test font is wide).
    final planTab = find.descendant(of: find.byType(ShellTabs<DietTab>), matching: find.text('Plano'));
    await tester.ensureVisible(planTab);
    await tester.pumpAndSettle();
    await tester.tap(planTab);
    await settle(tester);
    expect(find.text('ÚLTIMOS 7 DIAS'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await settle(tester);
    expect(tester.takeException(), isNull);

    // The forms on the whole screen: a plan item (with the days and a food), the targets.
    await tester.tap(find.byTooltip('Adicionar ao plano'));
    await tester.pumpAndSettle();
    await pickRice(tester);
    expect(find.text('Dias da semana (nenhum marcado = todos os dias)'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Metas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcular as calorias pelos macros (P×4 + C×4 + G×9)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
}
