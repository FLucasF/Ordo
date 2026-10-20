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
import 'package:task_manager/domain/finance/finance.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/finance/finance_page.dart';

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

  Future<void> pick(WidgetTester tester, String field, String option) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, field));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickNumber(WidgetTester tester, String field, String option) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, field));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  /// The tab's "+ Novo …" at the end of the top bar.
  Future<void> create(WidgetTester tester) async {
    await tester.tap(find.byType(CreateButton).first);
    await tester.pumpAndSettle();
  }

  /// The tab [to], among the tabs under the top bar ([from] is the one open).
  Future<void> goTab(WidgetTester tester, String from, String to) async {
    final tabs = find.byType(ShellTabs<FinanceTab>);
    expect(find.descendant(of: tabs, matching: find.text(from)), findsOneWidget);
    await tester.tap(find.descendant(of: tabs, matching: find.text(to)));
    await settle(tester);
  }

  testWidgets('Finanças in the Calendar\'s look: panel, top bar and the entries as the Agenda', (tester) async {
    await pumpApp(tester, '/q/all/tasks');
    await tester.tap(find.byTooltip('Finanças'));
    await settle(tester);
    // The tabs in sight, and the tab's "+ Novo lançamento".
    for (final tab in ['Lançamentos', 'Cartões', 'Contas fixas', 'Empréstimos', 'Relatórios', 'Categorias']) {
      expect(find.descendant(of: find.byType(ShellTabs<FinanceTab>), matching: find.text(tab)), findsOneWidget);
    }
    expect(find.widgetWithText(CreateButton, 'Novo lançamento'), findsOneWidget);
    expect(find.text('Nenhum lançamento neste período.'), findsOneWidget);
    expect(find.text('Setembro 2026'), findsOneWidget);
    expect(find.text('Gastos do mês'), findsOneWidget);
    expect(find.text('Este mês'), findsOneWidget);

    await create(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1.234,5');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Feira do mês');
    await pick(tester, 'Categoria', '🛒 Mercado');
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    expect(find.text('Feira do mês'), findsOneWidget);
    // The line and the Saldo; Despesas without the sign.
    expect(find.text(r'-R$ 1.234,50'), findsNWidgets(2));
    expect(find.text(r'R$ 1.234,50'), findsOneWidget);
    // The day as in the Agenda, and the month's total beside the category in the panel.
    expect(find.text('SET, QUI'), findsOneWidget);
    expect(find.text('1.234,50'), findsOneWidget);

    await goTab(tester, 'Lançamentos', 'Categorias');
    expect(find.text(r'R$ 1.234,50 neste mês'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('a limit warns from 80%; income is green; filters and delete with undo', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    late String market;
    await tester.runAsync(() async {
      market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense, icon: '🛒', monthlyLimit: 10000);
      await repo.createCategory(name: 'Salário', kind: FinKind.income, icon: '💰');
      await repo.addEntry(kind: FinKind.expense, amount: 7000, date: DateTime(2026, 9, 10), description: 'Pão', categoryId: market);
    });
    await pumpApp(tester, '/finance/categories');
    expect(find.text(r'R$ 70,00 de R$ 100,00'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await goTab(tester, 'Categorias', 'Lançamentos');
    await create(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '15');
    await pick(tester, 'Categoria', '🛒 Mercado');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text(r'Mercado: 85% do limite do mês (R$ 85,00 de R$ 100,00).'), findsOneWidget);

    // Income: its own categories.
    await create(tester);
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '3000');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Pagamento');
    await pick(tester, 'Categoria', '💰 Salário');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text(r'+R$ 3.000,00'), findsOneWidget);
    expect(find.text(r'R$ 2.915,00'), findsOneWidget);

    // The top bar's ⋯ › Receitas: only income.
    Finder moreItem(String label) => find.widgetWithText(CheckedPopupMenuItem<Object>, label);
    final topMore = find.descendant(of: find.byType(ShellTopBar), matching: find.byIcon(Icons.more_horiz));
    await tester.tap(topMore);
    await tester.pumpAndSettle();
    await tester.tap(moreItem('Receitas'));
    await settle(tester);
    expect(find.text('Pagamento'), findsOneWidget);
    expect(find.text('Pão'), findsNothing);
    await tester.tap(topMore);
    await tester.pumpAndSettle();
    await tester.tap(moreItem('Receitas e despesas'));
    await settle(tester);

    // The panel's categories: unchecking Mercado hides its entries.
    await tester.tap(find.widgetWithText(PanelCheckRow, '🛒 Mercado'));
    await settle(tester);
    expect(find.text('Pão'), findsNothing);
    await tester.tap(find.widgetWithText(PanelCheckRow, '🛒 Mercado'));
    await settle(tester);

    // Delete, then undo.
    await tester.longPress(find.text('Pão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Pão'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Pão'), findsOneWidget);

    // ‹ of the top bar (the panel's months come first): the month before is empty.
    await tester.tap(find.byIcon(Icons.chevron_left).last);
    await settle(tester);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Nenhum lançamento neste período.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Cartões: a new card, a purchase in 3 installments goes to its invoices, paying the invoice', (tester) async {
    await pumpApp(tester, '/finance/cards');
    expect(find.textContaining('Nenhum cartão ainda'), findsOneWidget);
    await tester.tap(find.widgetWithText(CreateButton, 'Novo cartão').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome do cartão'), 'Nubank');
    await pickNumber(tester, 'Dia do fechamento', '5');
    await pickNumber(tester, 'Dia do vencimento', '12');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    // The 24th is after the closing: October's invoice, still open; the card in the panel.
    expect(find.text('Fatura de Outubro 2026'), findsOneWidget);
    expect(find.widgetWithText(PanelNavRow, 'Nubank'), findsOneWidget);
    expect(find.text('Sem compras'), findsWidgets);

    await create(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '300');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Fone');
    await pick(tester, 'Cartão', 'Nubank');
    await pickNumber(tester, 'Parcelas', r'3x de R$ 100,00');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Aberta'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await settle(tester);
    expect(find.text('Fatura de Novembro 2026'), findsOneWidget);
    expect(find.textContaining('2/3'), findsOneWidget);
    await tester.tap(find.text('Fatura atual'));
    await settle(tester);

    await tester.tap(find.text('Pagar fatura'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Valor pago'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Pagar fatura'), findsNothing);
    expect(find.text('Pagamentos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('everything added can be edited and deleted: the form\'s bin and the line\'s ⋯', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      await repo.addEntry(kind: FinKind.expense, amount: 4590, date: DateTime(2026, 9, 24), description: 'Lanche');
      await repo.createRecurring(
        FinRecurringsCompanion(
          kind: const Value(FinKind.expense),
          description: const Value('Aluguel'),
          amount: const Value(150000),
          frequency: const Value(FinFrequency.monthly),
          day: const Value(5),
          startDate: Value(storedDay(DateTime(2026, 9))),
        ),
      );
      final loan = await repo.createLoan(
        borrower: 'Ana',
        principal: 100000,
        total: 110000,
        lentOn: DateTime(2026, 9, 1),
        dueOn: DateTime(2026, 10, 1),
      );
      await repo.addLoanPayment(loanId: loan, amount: 50000, date: DateTime(2026, 9, 20));
    });
    await pumpApp(tester, '/finance/entries');

    // An entry: its form has the bin, and Desfazer brings it back.
    await tester.tap(find.text('Lanche'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Deletar'));
    await settle(tester);
    expect(find.text('Lanche'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Lanche'), findsOneWidget);
    // Its ⋯ (not only the right click): Editar · Duplicar · Deletar.
    await tester.tap(find.descendant(of: find.widgetWithText(AgendaLine, 'Lanche'), matching: find.byType(RowMenuButton)));
    await tester.pumpAndSettle();
    expect(find.text('Duplicar'), findsOneWidget);
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Lanche'), findsNothing);

    // A fixed bill: its form's bin asks first.
    await goTab(tester, 'Lançamentos', 'Contas fixas');
    await tester.tap(find.widgetWithText(PanelNavRow, 'Aluguel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Deletar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Excluir a conta fixa "Aluguel"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
    await settle(tester);
    expect(find.widgetWithText(PanelNavRow, 'Aluguel'), findsNothing);
    expect(find.textContaining('Nenhuma conta fixa ainda'), findsOneWidget);

    // A loan (its line shows only the name): a click on a payment edits it; the line's ⋯ deletes the loan.
    await goTab(tester, 'Contas fixas', 'Empréstimos');
    await tester.tap(find.descendant(of: find.byType(AgendaLine), matching: find.text('Ana')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, r'R$ 500,00'));
    await tester.pumpAndSettle();
    expect(find.text('Editar pagamento'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Valor pago'), '800');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text(r'Falta R$ 300,00'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.widgetWithText(AgendaLine, 'Ana'), matching: find.byType(RowMenuButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deletar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
    await settle(tester);
    expect(find.descendant(of: find.byType(AgendaLine), matching: find.text('Ana')), findsNothing);
    expect(find.text('Empréstimo excluído'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Contas fixas: a monthly bill due on the 20th is late; paying it makes the entry', (tester) async {
    await pumpApp(tester, '/finance/recurring');
    expect(find.textContaining('Nenhuma conta fixa ainda'), findsOneWidget);
    await create(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Aluguel');
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1500');
    // The menu opens around today (the 24th).
    await pickNumber(tester, 'Dia do vencimento', '20');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    // In the panel with its day; in the body on the 20th, late.
    expect(find.widgetWithText(PanelNavRow, 'Aluguel'), findsOneWidget);
    expect(find.text('Todo dia 20'), findsOneWidget);
    expect(find.text('Vencida'), findsOneWidget);
    expect(find.text('20'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Pagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('pago em 24/09'), findsOneWidget);
    await goTab(tester, 'Contas fixas', 'Lançamentos');
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text(r'-R$ 1.500,00'), findsWidgets);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Empréstimos: the rate fills the total; a partial payment brings profit in proportion', (tester) async {
    await pumpApp(tester, '/finance/loans');
    expect(find.text('Nenhum empréstimo ainda.'), findsOneWidget);
    await create(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Quem pegou emprestado'), 'João');
    await tester.enterText(find.widgetWithText(TextField, 'Valor emprestado'), '1000');
    await tester.enterText(find.widgetWithText(TextField, 'Juros'), '30');
    await tester.pump();
    expect(find.text('1.300,00'), findsOneWidget);
    expect(find.text(r'Lucro: R$ 300,00'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.descendant(of: find.byType(AgendaLine), matching: find.text('João')), findsOneWidget);
    expect(find.text(r'Falta R$ 1.300,00'), findsOneWidget);
    expect(find.text(r'lucro R$ 300,00 (30%)'), findsOneWidget);
    // The line's status and the panel's filter.
    expect(find.text('Em dia'), findsNWidgets(2));

    await tester.tap(find.descendant(of: find.byType(AgendaLine), matching: find.text('João')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar pagamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor pago'), '130');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    // In the detail: received 130, of which 30 of profit; 1.170 left.
    Finder inDetail(String text) => find.descendant(of: find.byType(Dialog), matching: find.text(text));
    // "Recebido" and the payment.
    expect(inDetail(r'R$ 130,00'), findsNWidgets(2));
    expect(inDetail(r'R$ 30,00'), findsOneWidget);
    expect(inDetail(r'R$ 1.170,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await settle(tester);
    await dispose(tester);
  });

  testWidgets('Empréstimos by month: of the due day, or of the day lent (the panel picks)', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      await repo.createLoan(borrower: 'Ana', principal: 100000, total: 110000, lentOn: DateTime(2026, 8, 20), dueOn: DateTime(2026, 11, 5));
      await repo.createLoan(borrower: 'Beto', principal: 50000, total: 60000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 10, 20));
    });
    await pumpApp(tester, '/finance/loans');
    expect(find.text('Outubro 2026'), findsOneWidget);
    expect(find.text('Novembro 2026'), findsOneWidget);
    expect(find.text(r'1 empréstimo · a receber R$ 600,00 · lucro R$ 100,00'), findsOneWidget);
    expect(
      tester.getTopLeft(find.descendant(of: find.byType(AgendaLine), matching: find.text('Beto'))).dy,
      lessThan(tester.getTopLeft(find.descendant(of: find.byType(AgendaLine), matching: find.text('Ana'))).dy),
    );

    await tester.tap(find.widgetWithText(PanelNavRow, 'Por mês do empréstimo'));
    await settle(tester);
    expect(find.text('Setembro 2026'), findsOneWidget);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Outubro 2026'), findsNothing);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Relatórios: by category, income × expenses, comparison and loans', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      final market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense, icon: '🛒');
      await repo.addEntry(kind: FinKind.expense, amount: 40000, date: DateTime(2026, 8, 3), categoryId: market);
      await repo.addEntry(kind: FinKind.expense, amount: 60000, date: DateTime(2026, 9, 3), categoryId: market);
      final salary = await repo.createCategory(name: 'Salário', kind: FinKind.income, icon: '💼');
      await repo.addEntry(kind: FinKind.income, amount: 300000, date: DateTime(2026, 9, 1), categoryId: salary);
      final ana = await repo.createLoan(borrower: 'Ana', principal: 50000, total: 55000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 10, 1));
      // R$ 110 of R$ 550 brings R$ 10 of profit.
      await repo.addLoanPayment(loanId: ana, amount: 11000, date: DateTime(2026, 9, 5));
    });
    await pumpApp(tester, '/finance/reports');
    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('🛒 Mercado'), findsWidgets);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Receitas × despesas'), findsOneWidget);
    // Geral: the income, the loans' profit apart and the expenses of September.
    expect(find.text('Juros de empréstimos'), findsOneWidget);
    expect(find.text(r'R$ 10,00'), findsWidgets);
    expect(find.text(r'R$ 3.000,00'), findsOneWidget);
    expect(find.text('💼 Salário'), findsNothing);
    // Detalhado: what came in and went out by category, the profit still a line of its own.
    await tester.tap(find.text('Detalhado'));
    await settle(tester);
    expect(find.text('Receitas · Setembro 2026'), findsOneWidget);
    expect(find.text('Despesas · Setembro 2026'), findsOneWidget);
    expect(find.text('💼 Salário'), findsOneWidget);
    expect(find.text('Juros de empréstimos'), findsOneWidget);
    expect(find.text('Comparação entre meses'), findsOneWidget);
    // Mercado and the total.
    expect(find.text('+50%'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('A RECEBER'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last,
    );
    expect(find.text(r'R$ 440,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('phone: Finanças is in the drawer; "+" floats in the corner; the form takes the whole screen', (tester) async {
    await pumpApp(tester, '/q/all/tasks', size: const Size(560, 1000));
    await tester.tap(find.byIcon(Icons.menu_open).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finanças'));
    await settle(tester);
    expect(find.descendant(of: find.byType(ShellTabs<FinanceTab>), matching: find.text('Lançamentos')), findsOneWidget);
    expect(find.byType(CreateButton), findsNothing);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Dialog)).width, 560);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await dispose(tester);
  });
}
