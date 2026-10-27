import 'package:appflowy_editor/appflowy_editor.dart' hide Document;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/journal_repository.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/journal/journal_page.dart';

void main() {
  late AppDatabase db;
  // Tuesday, 20 October 2026.
  final clock = FixedClock(DateTime(2026, 10, 20, 21));
  final today = DateTime(2026, 10, 20);

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

  JournalRepository journal() => JournalRepository(db, clock: clock);
  Future<JournalSnapshot> load(WidgetTester tester) async => (await tester.runAsync(() => journal().load()))!;

  testWidgets('Dia: mood and energy at a tap, highlight and notes saved by themselves, the summary, ‹ › and deleting with undo', (tester) async {
    await tester.runAsync(() async {
      final repo = Repository(db, clock: clock);
      await repo.complete(await repo.createTask(listId: inboxListId, title: 'Relatório'));
      await FinanceRepository(db, clock: clock).addEntry(kind: FinKind.expense, amount: 4590, date: today);
      await journal().setNotes(DateTime(2026, 10, 19), 'Fui à praia');
    });
    await pumpApp(tester, '/journal');
    expect(find.text('Terça-feira, Hoje'), findsOneWidget);
    expect(find.text('Notas do dia'), findsOneWidget);
    // The summary, computed from the other modules.
    expect(find.text('Resumo do dia'), findsOneWidget);
    expect(find.text('1 tarefa concluída'), findsOneWidget);
    expect(find.textContaining('saiu R\$ 45,90'), findsOneWidget);
    expect(find.textContaining('· saldo '), findsOneWidget);
    // The field once called "Destaque / Gratidão".
    expect(find.text('Meta Principal de Amanhã:'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mood4')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('energy3')));
    await settle(tester);
    expect(find.text('Humor · Bom'), findsOneWidget);
    expect(find.text('Energia · 3/5'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('journalHighlight')), 'O café com a Ana');
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
    // The notes, typed into the tasks' editor.
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    await editor.apply(editor.transaction..insertText(editor.getNodeAtPath([0])!, 0, 'Choveu o dia todo'));
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);
    var e = (await load(tester)).on(today)!;
    expect((e.mood, e.energy, e.highlight, e.notes), (4, 3, 'O café com a Ana', 'Choveu o dia todo'));

    // A tap on the picked face clears it.
    await tester.tap(find.byKey(const ValueKey('mood4')));
    await settle(tester);
    expect((await load(tester)).on(today)!.mood, isNull);

    // ‹: yesterday, with its notes in the editor.
    await tester.tap(find.descendant(of: find.byType(ShellArrows), matching: find.byIcon(Icons.chevron_left)));
    await settle(tester);
    expect(find.text('Segunda-feira, Ontem'), findsOneWidget);
    expect(find.text('Fui à praia', findRichText: true), findsOneWidget);
    await tester.tap(find.widgetWithText(TodayPill, 'Hoje'));
    await settle(tester);
    expect(find.text('O café com a Ana'), findsOneWidget);

    // The bin deletes the day's entry; Desfazer brings it back.
    await tester.tap(find.byTooltip('Apagar a entrada deste dia'));
    await settle(tester);
    expect((await load(tester)).on(today), isNull);
    expect(find.text('O café com a Ana'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    e = (await load(tester)).on(today)!;
    expect(e.highlight, 'O café com a Ana');
    expect(find.text('O café com a Ana'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Linha do tempo: newest first, search without accents, filters by mood, ⋯ deletes with undo, a click opens the day', (tester) async {
    await tester.runAsync(() async {
      final j = journal();
      await j.setMood(DateTime(2026, 10, 18), 5);
      await j.setNotes(DateTime(2026, 10, 18), '# Domingo\n\nÁgua de coco na **praia**');
      await j.setMood(DateTime(2026, 10, 19), 2);
      await j.setEnergy(DateTime(2026, 10, 19), 1);
      await j.setHighlight(DateTime(2026, 10, 19), 'Gratidão pela sopa');
      // Cleared entries stay out of the history.
      await j.setMood(DateTime(2026, 10, 17), 3);
      await j.setMood(DateTime(2026, 10, 17), null);
    });
    await pumpApp(tester, '/journal/timeline');
    expect(find.text('Segunda-feira, Ontem'), findsOneWidget);
    expect(find.text('Domingo, 18 outubro'), findsOneWidget);
    expect(find.text('Domingo Água de coco na praia'), findsOneWidget);
    expect(find.text('Gratidão pela sopa'), findsOneWidget);
    expect(find.textContaining('17 outubro'), findsNothing);
    final y = tester.getTopLeft(find.text('Segunda-feira, Ontem')).dy;
    expect(y, lessThan(tester.getTopLeft(find.text('Domingo, 18 outubro')).dy));

    await tester.enterText(find.widgetWithText(TextField, 'Buscar nas notas e destaques'), 'agua praia');
    await settle(tester);
    expect(find.text('Segunda-feira, Ontem'), findsNothing);
    expect(find.text('Domingo, 18 outubro'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    await settle(tester);
    expect(find.text('Segunda-feira, Ontem'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mood2')));
    await settle(tester);
    expect(find.text('Domingo, 18 outubro'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mood2')));
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.ancestor(of: find.text('Domingo, 18 outubro'), matching: find.byType(InkWell)).first,
        matching: find.byType(RowMenuButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Domingo, 18 outubro'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Domingo, 18 outubro'), findsOneWidget);

    await tester.tap(find.text('Segunda-feira, Ontem'));
    await settle(tester);
    expect(find.byType(ShellTabs<JournalTab>), findsOneWidget);
    expect(find.text('Humor · Ruim'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Calendário: days tinted by mood, the mood and energy chart; a day opens it', (tester) async {
    await tester.runAsync(() async {
      final j = journal();
      for (final (d, mood, energy) in [(5, 2, 3), (12, 4, 4), (19, 5, 2)]) {
        await j.setMood(DateTime(2026, 10, d), mood);
        await j.setEnergy(DateTime(2026, 10, d), energy);
      }
    });
    await pumpApp(tester, '/journal/calendar');
    expect(find.text('Outubro 2026'), findsWidgets);
    expect(find.text('Humor e energia'), findsOneWidget);
    expect(find.byKey(const ValueKey('moodDay19')), findsOneWidget);
    // ‹: September has nothing.
    await tester.tap(find.descendant(of: find.byType(ShellArrows), matching: find.byIcon(Icons.chevron_left)));
    await settle(tester);
    expect(find.text('Sem humor nem energia registrados neste mês.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TodayPill, 'Hoje'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('moodDay12')));
    await settle(tester);
    expect(find.text('Segunda-feira, 12 outubro'), findsOneWidget);
    expect(find.text('Humor · Bom'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('on a phone: the day, the calendar dialog, the timeline and the calendar fit', (tester) async {
    await tester.runAsync(() async {
      await journal().setMood(DateTime(2026, 10, 15), 3);
      await journal().setNotes(DateTime(2026, 10, 15), 'Um dia comum com um texto bem comprido para ver se cabe na tela do celular');
    });
    await pumpApp(tester, '/journal', size: const Size(400, 800));
    expect(find.text('Notas do dia'), findsOneWidget);
    await tester.tap(find.byTooltip('Escolher dia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await settle(tester);
    expect(find.text('Quinta-feira, 15 outubro'), findsOneWidget);
    expect(find.text('Humor · Normal'), findsOneWidget);
    // The round "+" writes today.
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('Terça-feira, Hoje'), findsOneWidget);

    await tester.tap(find.text('Linha do tempo'));
    await settle(tester);
    expect(find.text('Quinta-feira, 15 outubro'), findsOneWidget);
    // The tabs scroll sideways on a phone.
    final calendarTab = find.descendant(of: find.byType(ShellTabs<JournalTab>), matching: find.text('Calendário'));
    await tester.ensureVisible(calendarTab);
    await tester.pump();
    await tester.tap(calendarTab);
    await settle(tester);
    expect(find.byKey(const ValueKey('moodDay15')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Funcionalidades turns Diário off: its icon leaves the bar', (tester) async {
    await pumpApp(tester, '/q/today/tasks');
    expect(find.byTooltip('Diário'), findsOneWidget);
    await tester.runAsync(() => PreferencesRepository(db, clock: clock).setFeature(const {}, AppFeature.journal, enabled: false));
    await settle(tester);
    expect(find.byTooltip('Diário'), findsNothing);
    await dispose(tester);
  });
}
