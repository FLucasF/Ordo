import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/workbook_repository.dart';
import 'package:task_manager/data/xlsx/xlsx.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/import/imported_task.dart';
import 'package:task_manager/domain/spreadsheet/workbook.dart';
import 'package:task_manager/domain/spreadsheet/workbook_import.dart';
import 'package:task_manager/features/backup/excel_actions.dart';
import 'package:task_manager/l10n/app_localizations.dart';

final pt = L10nWorkbookLabels(lookupAppLocalizations(const Locale('pt')));
final la = L10nWorkbookLabels(lookupAppLocalizations(const Locale('la')));
final clock = FixedClock(DateTime(2026, 9, 24, 12));

/// A table as the reader gives it: the header, then the rows from row 2.
XlsxTable table(String name, List<String> header, List<List<Object?>> rows) =>
    XlsxTable(name, [XlsxRow(1, header), for (final (i, r) in rows.indexed) XlsxRow(i + 2, r)]);

double serial(DateTime local) => excelSerial(local);

/// One of each thing the workbook shows.
Future<void> seed(AppDatabase db) async {
  final repo = Repository(db, clock: clock);
  final folder = await repo.createFolder('Casa');
  final market = await repo.createList(name: 'Mercado', folderId: folder);
  final section = await repo.createSection(market, 'Hortifruti');
  await repo.createTask(
    listId: market,
    sectionId: section,
    title: 'Comprar maçãs',
    content: '**Fuji** e [gala](https://example.com)',
    dueDate: DateTime(2026, 9, 25),
    priority: Priority.high,
    tagIds: [await repo.createTag('feira'), await repo.createTag('casa')],
  );
  final meeting = await repo.createTask(
    listId: inboxListId,
    title: 'Reunião',
    startDate: DateTime(2026, 9, 26, 13),
    dueDate: DateTime(2026, 9, 26, 14, 30),
    isAllDay: false,
    priority: Priority.medium,
  );
  await repo.setImportedState(meeting, status: TaskStatus.completed, completedAt: DateTime(2026, 9, 26, 15));
  final checklist = await repo.createTask(listId: inboxListId, title: 'Mala', kind: TaskKind.checklist);
  await repo.setChecklistItemCompleted(await repo.addChecklistItem(checklist, title: 'escova'), completed: true);
  final gone = await repo.createTask(listId: inboxListId, title: 'Apagada');
  await repo.delete(gone);

  final habit = await repo.createHabit(HabitsCompanion(name: const Value('Ler'), startDate: Value(DateTime.utc(2026, 9, 1))));
  await repo.checkIn(habit, DateTime(2026, 9, 20));

  final fin = FinanceRepository(db, clock: clock);
  final food = await fin.createCategory(name: 'Alimentação', kind: FinKind.expense);
  final salary = await fin.createCategory(name: 'Salário', kind: FinKind.income);
  final card = await fin.createCard(name: 'Nubank', closingDay: 5, dueDay: 12, creditLimit: 500000);
  await fin.addEntry(kind: FinKind.expense, amount: 12345, date: DateTime(2026, 9, 10), description: 'Feira', categoryId: food, note: 'orgânicos');
  await fin.addEntry(kind: FinKind.income, amount: 500000, date: DateTime(2026, 9, 5), description: 'Salário', categoryId: salary);
  await fin.addEntry(
    kind: FinKind.expense,
    amount: 30000,
    date: DateTime(2026, 9, 15),
    description: 'TV',
    categoryId: food,
    cardId: card,
    installments: 3,
  );
  final loan = await fin.createLoan(borrower: 'João', principal: 100000, total: 120000, lentOn: DateTime(2026, 8, 1), dueOn: DateTime(2026, 10, 1));
  await fin.addLoanPayment(loanId: loan, amount: 50000, date: DateTime(2026, 9, 1));

  final now = clock.now().toUtc();
  await db.into(db.finGoals).insert(FinGoalsCompanion.insert(id: 'g1', createdAt: now, updatedAt: now, name: 'Viagem', target: 300000, sortOrder: 0));
  for (final (i, amount) in [100000, -20000].indexed) {
    await db
        .into(db.finGoalMoves)
        .insert(
          FinGoalMovesCompanion.insert(id: 'm$i', createdAt: now, updatedAt: now, goalId: 'g1', amount: amount, date: DateTime.utc(2026, 9, 1 + i)),
        );
  }
  await db
      .into(db.dietEntries)
      .insert(
        DietEntriesCompanion.insert(
          id: 'd1',
          createdAt: now,
          updatedAt: now,
          day: DateTime.utc(2026, 9, 24),
          meal: 'lunch',
          foodId: 'taco:1',
          name: 'Arroz',
          quantity: 2,
          measureName: const Value('colher'),
          grams: 50,
          kcal: const Value(128),
          protein: const Value(2.5),
          sortOrder: 0,
        ),
      );
  await db
      .into(db.journalEntries)
      .insert(
        JournalEntriesCompanion.insert(
          id: 'j1',
          createdAt: now,
          updatedAt: now,
          day: DateTime.utc(2026, 9, 24),
          mood: const Value(4),
          energy: const Value(3),
          notes: const Value('# Bom dia\n**ótimo**'),
          highlight: const Value('praia'),
        ),
      );
}

void main() {
  // Two databases on purpose: the one exported and the one imported into.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase source, target;
  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  Map<String, XlsxTable> exported(List<XlsxTable> tables) => {for (final t in tables) t.name: t};

  test('the export has a sheet per module, with dates as Excel dates and money as numbers', () async {
    await seed(source);
    final bytes = encodeXlsx(buildWorkbook(await loadWorkbookData(source), pt));
    final tables = decodeXlsx(bytes);
    expect(tables.map((t) => t.name), [
      'Tarefas',
      'Hábitos',
      'Lançamentos',
      'Cartões',
      'Faturas pagas',
      'Empréstimos',
      'Recebimentos',
      'Caixinhas',
      'Movimentações',
      'Dieta',
      'Diário',
    ]);
    final sheets = exported(tables);

    final tasks = sheets['Tarefas']!.rows;
    expect(tasks.first.cells, [
      'Pasta',
      'Lista',
      'Seção',
      'Título',
      'Notas',
      'Status',
      'Prioridade',
      'Início',
      'Prazo',
      'Etiquetas',
      'Criada em',
      'Concluída em',
    ]);
    expect(tasks, hasLength(4), reason: 'the deleted task is left out');
    final apples = tasks.firstWhere((r) => r[3] == 'Comprar maçãs');
    expect(apples.cells.sublist(0, 9), [
      'Casa',
      'Mercado',
      'Hortifruti',
      'Comprar maçãs',
      'Fuji e gala',
      'Aberta',
      'Alta',
      null,
      serial(DateTime(2026, 9, 25)),
    ]);
    expect((apples[9]! as String).split(', ').toSet(), {'feira', 'casa'});
    expect(apples[10], serial(DateTime(2026, 9, 24, 12)));
    final meeting = tasks.firstWhere((r) => r[3] == 'Reunião');
    expect(meeting.cells.sublist(0, 2), [null, 'Caixa de Entrada']);
    expect(meeting.cells.sublist(5), [
      'Concluída',
      'Média',
      serial(DateTime(2026, 9, 26, 13)),
      serial(DateTime(2026, 9, 26, 14, 30)),
      null,
      serial(DateTime(2026, 9, 24, 12)),
      serial(DateTime(2026, 9, 26, 15)),
    ]);
    expect(tasks.firstWhere((r) => r[3] == 'Mala')[4], '☑ escova', reason: 'the checklist as text');

    expect(sheets['Hábitos']!.rows[1].cells, ['Ler', serial(DateTime(2026, 9, 20)), 1.0, 1.0, null, 'Concluído']);

    final entries = sheets['Lançamentos']!.rows.skip(1).toList();
    expect(entries.map((r) => r[3]), ['Salário', 'Feira', 'TV', 'TV', 'TV'], reason: 'by date');
    expect(entries[0].cells.sublist(0, 5), [serial(DateTime(2026, 9, 5)), 'Receita', 'Salário', 'Salário', 5000.0]);
    expect(entries[1].cells, [serial(DateTime(2026, 9, 10)), 'Despesa', 'Alimentação', 'Feira', 123.45, null, null, null, 'orgânicos']);
    expect(
      [for (final r in entries.skip(2)) (r[4], r[5], r[6], r[7])],
      [
        (100.0, 'Nubank', serial(DateTime(2026, 10)), '1/3'),
        (100.0, 'Nubank', serial(DateTime(2026, 11)), '2/3'),
        (100.0, 'Nubank', serial(DateTime(2026, 12)), '3/3'),
      ],
    );
    expect(sheets['Cartões']!.rows[1].cells, ['Nubank', 5.0, 12.0, 5000.0]);
    expect(sheets['Empréstimos']!.rows[1].cells.sublist(0, 7), [
      'João',
      serial(DateTime(2026, 8)),
      1000.0,
      1200.0,
      serial(DateTime(2026, 10)),
      1.0,
      500.0,
    ]);
    expect(sheets['Recebimentos']!.rows[1].cells, ['João', serial(DateTime(2026, 9)), 500.0]);
    expect(sheets['Caixinhas']!.rows[1].cells, ['Viagem', 3000.0, 800.0]);
    expect(sheets['Movimentações']!.rows.skip(1).map((r) => r[2]), [1000.0, -200.0]);
    expect(sheets['Dieta']!.rows[1].cells, [serial(DateTime(2026, 9, 24)), 'Almoço', 'Arroz', 2.0, 'colher', 50.0, 64.0, 1.3]);
    expect(sheets['Diário']!.rows[1].cells, [serial(DateTime(2026, 9, 24)), 4.0, 3.0, 'Bom dia\nótimo', 'praia']);
    expect(sheets['Faturas pagas']!.rows, hasLength(1), reason: 'only the header');
  });

  test('round trip: the exported Tarefas and Lançamentos import into another database as they were', () async {
    await seed(source);
    final tables = decodeXlsx(encodeXlsx(buildWorkbook(await loadWorkbookData(source), pt)));
    final preview = readWorkbook(tables, [pt, la], knownCards: await cardNames(target));
    expect(preview.errors, isEmpty);
    expect((preview.tasks.length, preview.entries.length), (3, 5));
    expect(preview.cards.map((c) => (c.name, c.closingDay, c.dueDay, c.creditLimit)), [('Nubank', 5, 12, 500000)]);
    expect(preview.skippedSheets, ['Hábitos', 'Cartões', 'Empréstimos', 'Recebimentos', 'Caixinhas', 'Movimentações', 'Dieta', 'Diário']);

    final result = await importWorkbook(target, preview, clock: clock);
    expect((result.tasks, result.entries), (3, 5));

    final before = Repository(source, clock: clock), after = Repository(target, clock: clock);
    final s0 = await before.loadSnapshot(), s1 = await after.loadSnapshot();
    Task task(Iterable<Task> tasks, String title) => tasks.firstWhere((t) => t.title == title && t.deletedAt == null);
    for (final title in ['Comprar maçãs', 'Reunião']) {
      final a = task(s0.tasks, title), b = task(s1.tasks, title);
      expect(
        (b.dueDate, b.startDate, b.isAllDay, b.priority, b.status, b.completedAt, b.createdAt),
        (a.dueDate, a.startDate, a.isAllDay, a.priority, a.status, a.completedAt, a.createdAt),
        reason: title,
      );
      expect(s1.listById[b.listId]!.name, s0.listById[a.listId]!.name);
    }
    final apples = task(s1.tasks, 'Comprar maçãs');
    expect(apples.content, 'Fuji e gala');
    expect(s1.tagsOf(apples.id).map((t) => t.name).toSet(), {'feira', 'casa'});
    expect(s1.sections.singleWhere((x) => x.id == apples.sectionId).name, 'Hortifruti');
    expect(s1.folderById[s1.listById[apples.listId]!.folderId]!.name, 'Casa');
    expect(task(s1.tasks, 'Reunião').listId, inboxListId);

    final f0 = await FinanceRepository(source).load(), f1 = await FinanceRepository(target).load();
    String describe(FinEntry e, List<FinCategory> categories, List<FinCard> cards) =>
        '${e.kind.code} ${e.amount} ${e.date} ${e.description} ${categories.where((c) => c.id == e.categoryId).firstOrNull?.name} '
        '${cards.where((c) => c.id == e.cardId).firstOrNull?.name} ${e.invoiceMonth} ${e.installmentIndex}/${e.installmentCount} ${e.note}';
    expect(f1.entries.map((e) => describe(e, f1.categories, f1.cards)).toSet(), f0.entries.map((e) => describe(e, f0.categories, f0.cards)).toSet());
    expect(f1.entries.where((e) => e.description == 'TV').map((e) => e.installmentGroup).toSet(), hasLength(1), reason: 'one purchase again');
    expect(f1.cards.single.closingDay, 5);
  });

  test('importing appends: nothing is replaced and names are matched ignoring case and accents', () async {
    await seed(source);
    final tables = decodeXlsx(encodeXlsx(buildWorkbook(await loadWorkbookData(source), pt)));
    final preview = readWorkbook(tables, [pt, la], knownCards: await cardNames(source));
    expect(preview.cards, isEmpty, reason: 'the card exists');
    final tasksBefore = (await Repository(source).loadSnapshot()).tasks.where((t) => t.deletedAt == null).length;
    await importWorkbook(source, preview, clock: clock);
    final s = await Repository(source).loadSnapshot();
    expect(s.tasks.where((t) => t.deletedAt == null), hasLength(tasksBefore + 3));
    expect(s.lists.where((l) => l.name.toLowerCase() == 'mercado'), hasLength(1));
    final f = await FinanceRepository(source).load();
    expect(f.entries, hasLength(10));
    expect(f.categories.map((c) => c.name), ['Alimentação', 'Salário']);
    expect(f.cards, hasLength(1));

    final other = readWorkbook(
      [
        table(
          'Lançamentos',
          ['Data', 'Tipo', 'Categoria', 'Valor'],
          [
            ['01/10/2026', 'despesa', 'ALIMENTACAO', 'R\$ 10,00'],
            ['02/10/2026', 'Despesa', 'Lazer', 25.5],
          ],
        ),
      ],
      [pt],
    );
    await importWorkbook(source, other, clock: clock);
    final g = await FinanceRepository(source).load();
    expect(g.categories.map((c) => c.name), ['Alimentação', 'Salário', 'Lazer'], reason: 'a missing category is created');
    expect(g.entries.where((e) => e.amount == 1000).single.categoryId, g.categories.first.id);
  });

  group('reading rows', () {
    test('malformed rows are listed with their row and reason; the good ones still come', () {
      final preview = readWorkbook(
        [
          table(
            'Tarefas',
            ['Título', 'Lista', 'Status', 'Prioridade', 'Prazo', 'Etiquetas'],
            [
              ['Boa', 'Trabalho', 'concluida', 'alta', '25/09/2026 09:15', '#um; dois'],
              [null, 'Trabalho'],
              ['Data ruim', null, null, null, '31/02/2026'],
              ['Prioridade ruim', null, null, 'urgente'],
              ['Status ruim', null, 'talvez'],
              [42.0, null, null, '3', 46290.0],
            ],
          ),
          table(
            'Lançamentos',
            ['Data', 'Tipo', 'Descrição', 'Valor', 'Cartão', 'Parcela'],
            [
              [46290.0, 'Despesa', 'Café', 'R\$ 1.234,56'],
              ['ontem', 'Despesa', 'x', 1.0],
              [46290.0, 'Despesa', 'sem valor', 'muito'],
              [46290.0, 'Doação', 'tipo', 1.0],
              [46290.0, null, 'negativo', -12.5],
              [46290.0, null, 'positivo', '12'],
              [46290.0, 'Despesa', 'cartão', 10.0, 'Inexistente'],
              [46290.0, 'Despesa', 'parcela', 10.0, null, '2/3'],
            ],
          ),
          table(
            'Hábitos',
            ['Hábito'],
            [
              ['Ler'],
            ],
          ),
          table('Vazia', ['A'], []),
        ],
        [pt, la],
      );
      expect(preview.errors.map((e) => (e.sheet, e.row, e.problem, e.detail)), [
        (WorkbookSheet.tasks, 3, RowProblem.noTitle, ''),
        (WorkbookSheet.tasks, 4, RowProblem.badDate, 'Prazo'),
        (WorkbookSheet.tasks, 5, RowProblem.badPriority, 'urgente'),
        (WorkbookSheet.tasks, 6, RowProblem.badStatus, 'talvez'),
        (WorkbookSheet.entries, 3, RowProblem.badDate, 'Data'),
        (WorkbookSheet.entries, 4, RowProblem.badAmount, 'muito'),
        (WorkbookSheet.entries, 5, RowProblem.badKind, 'Doação'),
        (WorkbookSheet.entries, 8, RowProblem.unknownCard, 'Inexistente'),
      ]);
      final good = preview.tasks.first;
      expect(
        (good.title, good.listName, good.status, good.priority, good.dueDate, good.isAllDay),
        ('Boa', 'Trabalho', ImportedStatus.completed, 5, DateTime(2026, 9, 25, 9, 15), false),
      );
      expect(good.tags, ['um', 'dois']);
      final number = preview.tasks.last;
      expect((number.title, number.priority, number.dueDate, number.isAllDay), ('42', 3, DateTime(2026, 9, 25), true));
      expect(preview.entries.map((e) => (e.description, e.kind, e.amount)), [
        ('Café', FinKind.expense, 123456),
        ('negativo', FinKind.expense, 1250),
        ('positivo', FinKind.income, 1200),
        ('parcela', FinKind.expense, 1000),
      ]);
      expect(preview.entries.last.installmentCount, isNull, reason: 'an installment without a card is a plain entry');
      expect(preview.skippedSheets, ['Hábitos']);
    });

    test('a sheet without its key columns is one error; a lone sheet is told by its columns; Latin names work', () {
      final missing = readWorkbook(
        [
          table(
            'Lançamentos',
            ['Data', 'Descrição'],
            [
              ['01/10/2026', 'x'],
            ],
          ),
          table(
            'Tarefas',
            ['Lista'],
            [
              ['a'],
            ],
          ),
        ],
        [pt],
      );
      expect(missing.errors.map(rowErrorTextPt), ['Tarefas, linha 1: faltam as colunas Título', 'Lançamentos, linha 1: faltam as colunas Valor']);
      expect(missing.isEmpty, isTrue);

      final lone = readWorkbook(
        [
          table(
            'Planilha1',
            ['título', 'PRAZO'],
            [
              ['Sozinha', '2026-10-01'],
            ],
          ),
        ],
        [pt],
      );
      expect((lone.tasks.single.title, lone.tasks.single.dueDate), ('Sozinha', DateTime(2026, 10)));
      expect(lone.skippedSheets, isEmpty);

      final latin = readWorkbook(
        [
          table(
            'Pensa',
            ['Titulus', 'Index', 'Status', 'Prioritas'],
            [
              ['Latine', 'Caixa de Entrada', 'Perfectum', 'Alta'],
            ],
          ),
          table(
            'Inscriptiones',
            ['Dies', 'Genus', 'Summa'],
            [
              ['01/10/2026', 'Impensa', 3.0],
            ],
          ),
        ],
        [pt, la],
      );
      expect(latin.errors, isEmpty);
      expect((latin.tasks.single.listName, latin.tasks.single.status), ('inbox', ImportedStatus.completed));
      expect(latin.entries.single.kind, FinKind.expense);
    });

    test('dates and money in the forms a spreadsheet holds them', () {
      expect(parseCellDate(46290.0), (DateTime(2026, 9, 25), false));
      expect(parseCellDate(46290.5), (DateTime(2026, 9, 25, 12), true));
      expect(parseCellDate('5/9/2026'), (DateTime(2026, 9, 5), false));
      expect(parseCellDate('25/09/2026 7:05:09'), (DateTime(2026, 9, 25, 7, 5, 9), true));
      expect(parseCellDate('2026-09-25T00:00'), (DateTime(2026, 9, 25), true));
      for (final bad in ['29/02/2026', '2026-13-01', '25/09/26', 'amanhã', -1.0, 0.0, null]) {
        expect(parseCellDate(bad), isNull, reason: '$bad');
      }
      expect(parseCellMoney(1234.56), 123456);
      expect(parseCellMoney(-0.1), -10);
      expect(parseCellMoney('R\$ 1.234,56'), 123456);
      expect(parseCellMoney('R\$ -12,50'), -1250);
      expect(parseCellMoney('-R\$ 12,50'), -1250);
      expect(parseCellMoney('(30,00)'), -3000);
      expect(parseCellMoney('1.000'), 100000);
      expect(parseCellMoney('abc'), isNull);
      expect(parseCellMoney(null), isNull);
    });
  });
}

/// The errors as the preview shows them, in Portuguese.
String rowErrorTextPt(RowError e) => rowErrorText(lookupAppLocalizations(const Locale('pt')), e);
