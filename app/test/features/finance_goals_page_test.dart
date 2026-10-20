import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/domain/finance/finance.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/finance/finance_page.dart';
import 'package:task_manager/features/finance/goals_tab.dart';

/// Finanças 1.10: the "+" of a day, the Caixinhas and the loans in installments.
void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

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
    await settle(tester, 10);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  Future<void> goTab(WidgetTester tester, String to) async {
    final tab = find.descendant(of: find.byType(ShellTabs<FinanceTab>), matching: find.text(to));
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await settle(tester);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Salvar'));
    await settle(tester);
  }

  Finder inRow(String text) => find.descendant(of: find.byType(GoalRow), matching: find.text(text));

  testWidgets('Lançamentos: the "+" of a day starts an entry on that day', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() => repo.addEntry(kind: FinKind.expense, amount: 700, date: DateTime(2026, 9, 10), description: 'Pão'));
    await pumpApp(tester, '/finance/entries');
    await tester.tap(find.byTooltip('Novo lançamento neste dia'));
    await tester.pumpAndSettle();
    expect(find.text('Novo lançamento'), findsWidgets);
    expect(find.text('10/09/2026'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Leite');
    await save(tester);
    final s = (await tester.runAsync(repo.load))!;
    expect(finDay(s.entries.firstWhere((e) => e.description == 'Leite').date), DateTime(2026, 9, 10));
    // In the same day's block.
    expect(find.byType(AgendaBlock), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('phone: the day with its "+" fits beside the entries', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      await repo.addEntry(kind: FinKind.expense, amount: 700, date: DateTime(2026, 9, 10), description: 'Pão');
      final goal = await repo.createGoal(name: 'Viagem', target: 100000);
      await repo.addGoalMove(goalId: goal, amount: 5000, date: DateTime(2026, 9, 10));
    });
    await pumpApp(tester, '/finance/entries', size: const Size(400, 900));
    expect(find.byTooltip('Novo lançamento neste dia'), findsOneWidget);
    expect(find.widgetWithText(AgendaLine, 'Viagem'), findsOneWidget);
    await tester.tap(find.byTooltip('Novo lançamento neste dia'));
    await tester.pumpAndSettle();
    expect(find.text('10/09/2026'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Caixinhas: a new goal, Guardar and Retirar, its moves edited and deleted; transfers, not income', (tester) async {
    await pumpApp(tester, '/finance/goals');
    expect(find.descendant(of: find.byType(ShellTabs<FinanceTab>), matching: find.text('Caixinhas')), findsOneWidget);
    expect(find.textContaining('Nenhuma caixinha ainda'), findsOneWidget);
    await tester.tap(find.widgetWithText(CreateButton, 'Nova caixinha').first);
    await tester.pumpAndSettle();
    // The name and a target are needed.
    await save(tester);
    expect(find.text('Preencha o nome e uma meta maior que zero.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nome da caixinha'), 'Viagem');
    await tester.enterText(find.widgetWithText(TextField, 'Meta'), '1000');
    await save(tester);
    expect(inRow('Viagem'), findsOneWidget);
    expect(inRow(r'R$ 0,00 de R$ 1.000,00'), findsOneWidget);
    expect(inRow(r'Faltam R$ 1.000,00'), findsOneWidget);
    // Nothing to take out yet.
    expect(inRow('Retirar'), findsNothing);

    await tester.tap(inRow('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Guardar em Viagem'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '300');
    await save(tester);
    expect(inRow(r'R$ 300,00 de R$ 1.000,00'), findsOneWidget);
    await tester.tap(inRow('Retirar'));
    await tester.pumpAndSettle();
    expect(find.text('Retirar de Viagem'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '50');
    await save(tester);
    expect(inRow(r'R$ 250,00 de R$ 1.000,00'), findsOneWidget);
    expect(inRow(r'Faltam R$ 750,00'), findsOneWidget);

    // The detail: the moves; a click edits one, its X deletes it (with Desfazer).
    await tester.tap(inRow('Viagem'));
    await tester.pumpAndSettle();
    expect(find.text('Movimentos'), findsOneWidget);
    expect(find.text(r'+R$ 300,00'), findsOneWidget);
    await tester.tap(find.text(r'-R$ 50,00'));
    await tester.pumpAndSettle();
    expect(find.text('Editar movimento'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '80');
    await save(tester);
    expect(find.text(r'-R$ 80,00'), findsOneWidget);
    await tester.tap(find.descendant(of: find.widgetWithText(ListTile, r'-R$ 80,00'), matching: find.byTooltip('Deletar')));
    await settle(tester);
    expect(find.text(r'-R$ 80,00'), findsNothing);
    expect(find.text('Movimento excluído'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await settle(tester);
    expect(inRow(r'R$ 300,00 de R$ 1.000,00'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(inRow(r'R$ 220,00 de R$ 1.000,00'), findsOneWidget);

    // Lançamentos shows the moves on their day, without touching the figures.
    await goTab(tester, 'Lançamentos');
    expect(find.widgetWithText(AgendaLine, 'Viagem'), findsNWidgets(2));
    expect(find.text('Guardado'), findsOneWidget);
    expect(find.text('Retirado'), findsOneWidget);
    expect(find.text(r'R$ 0,00'), findsNWidgets(3));
    // Relatórios: apart, in a line.
    await goTab(tester, 'Relatórios');
    expect(find.text(r'Guardado nas caixinhas: R$ 220,00 · neste mês +R$ 220,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Caixinhas: how much a month to the target day; edit, archive and delete with Desfazer', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      final goal = await repo.createGoal(name: 'Notebook', target: 100000, icon: '💻', dueOn: DateTime(2026, 12, 31));
      await repo.addGoalMove(goalId: goal, amount: 25000, date: DateTime(2026, 9, 1));
    });
    await pumpApp(tester, '/finance/goals');
    // Sep 24, Oct 24, Nov 24 and Dec 24: R$ 750 in 4.
    expect(inRow(r'Faltam R$ 750,00 · Guarde R$ 187,50 por mês até 31/12/2026'), findsOneWidget);
    expect(find.widgetWithText(PanelNavRow, '💻 Notebook'), findsOneWidget);

    Future<void> menu(String item) async {
      await tester.tap(find.descendant(of: find.byType(GoalRow), matching: find.byType(RowMenuButton)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await settle(tester);
    }

    await menu('Editar');
    expect(find.text('Editar caixinha'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Meta'), '2000');
    await save(tester);
    expect(inRow(r'R$ 250,00 de R$ 2.000,00'), findsOneWidget);

    await menu('Arquivar');
    expect(find.byType(GoalRow), findsNothing);
    expect(find.text('Caixinha arquivada'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.byType(GoalRow), findsOneWidget);

    await menu('Deletar');
    expect(find.textContaining('Excluir a caixinha "Notebook"'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
    await settle(tester);
    expect(find.byType(GoalRow), findsNothing);
    expect(find.text('Caixinha excluída'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(inRow(r'R$ 250,00 de R$ 2.000,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('phone: Caixinhas fits, with Guardar and Retirar under the bar', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      final goal = await repo.createGoal(name: 'Reserva de emergência para o ano todo', target: 1000000, dueOn: DateTime(2027, 6, 30));
      await repo.addGoalMove(goalId: goal, amount: 100000, date: DateTime(2026, 9, 1));
    });
    await pumpApp(tester, '/finance/goals', size: const Size(400, 900));
    expect(find.byType(GoalRow), findsOneWidget);
    expect(inRow('Guardar'), findsOneWidget);
    expect(inRow('Retirar'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nome da caixinha'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Empréstimos parcelado: the installment typed sets the total; "Receber parcela" with one tap', (tester) async {
    await pumpApp(tester, '/finance/loans');
    await tester.tap(find.byType(CreateButton).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Quem pegou emprestado'), 'João');
    await tester.enterText(find.widgetWithText(TextField, 'Valor emprestado'), '1000');
    await tester.enterText(find.widgetWithText(TextField, 'Juros'), '20');
    await tester.pump();
    await tester.tap(find.text('Parcelado'));
    await tester.pumpAndSettle();
    expect(find.text('Vencimento da 1ª parcela'), findsOneWidget);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Número de parcelas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    // Worked out from the total: R$ 1.200 in 3.
    expect(find.text('400,00'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Valor da parcela'), '450');
    await tester.pump();
    expect(find.text(r'3x de R$ 450,00 = R$ 1.350,00'), findsOneWidget);
    expect(find.text(r'Lucro: R$ 350,00'), findsOneWidget);
    await save(tester);

    final line = find.widgetWithText(AgendaLine, 'João');
    expect(find.descendant(of: line, matching: find.text(r'Falta R$ 1.350,00')), findsOneWidget);
    expect(find.descendant(of: line, matching: find.textContaining('parcela 1/3 vence 24/10')), findsOneWidget);

    await tester.tap(find.descendant(of: line, matching: find.text('João')));
    await tester.pumpAndSettle();
    expect(find.text(r'1/3 · 24/10/2026 · R$ 450,00'), findsOneWidget);
    expect(find.text(r'3/3 · 24/12/2026 · R$ 450,00'), findsOneWidget);
    await tester.tap(find.text('Receber parcela'));
    await settle(tester);
    expect(find.text('Parcela 1 recebida'), findsOneWidget);
    expect(find.text('paga em 24/09'), findsOneWidget);
    // The button moves to the next one.
    expect(find.text('Receber parcela'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await settle(tester);

    final s = (await tester.runAsync(FinanceRepository(db, clock: clock).load))!;
    final loan = s.loans.single;
    expect((loan.installments, loan.installmentAmount, loan.total, loan.principal), (3, 45000, 135000, 100000));
    expect((s.loanPayments.single.amount, s.loanPayments.single.note), (45000, 'Parcela 1 de 3'));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
}
