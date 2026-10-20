// Renders the main screens with sample data into build/screenshots/*.png for the visual comparison with
// TickTick (docs/conferencia.md). Run with: flutter test test/screenshots --tags screenshots
@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/reminders.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/calendar.dart';
import 'package:task_manager/domain/color_labels.dart';
import 'package:task_manager/features/calendar/calendar_insights_panel.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/filters.dart';
import 'package:task_manager/domain/subscriptions.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/domain/views.dart';
import 'package:task_manager/features/common/shell_widgets.dart';
import 'package:task_manager/features/settings/notification_settings.dart';
import 'package:task_manager/features/settings/settings_dialog.dart';
import 'package:task_manager/features/tasks/task_list_pane.dart';
import 'package:task_manager/features/templates/templates.dart';
import 'package:task_manager/domain/reminder_plan.dart';
import 'package:task_manager/data/diet_repository.dart';
import 'package:task_manager/domain/diet/diet.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    // Real fonts instead of the test font: Segoe UI (the app's font on Windows) and Material icons.
    await _loadFont('Roboto', ['C:/Windows/Fonts/segoeui.ttf', 'C:/Windows/Fonts/seguisb.ttf', 'C:/Windows/Fonts/segoeuib.ttf']);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'J:/dev/flutter';
    await _loadFont('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
  });

  final clock = FixedClock(DateTime(2026, 9, 24, 21));

  Future<Map<String, String>> seed(Repository repo) async {
    final work = await repo.createList(name: 'Trabalho', emoji: '💼', color: '#4CA1FF');
    await repo.createList(name: 'Casa', emoji: '🏠', color: '#35D870');
    final tag = await repo.createTag('clone', color: '#C2DED0');
    final meeting = await repo.createTask(
      listId: inboxListId,
      title: 'Reunião de planejamento',
      priority: Priority.high,
      dueDate: DateTime(2026, 9, 25),
      tagIds: [tag],
    );
    await repo.pinTask(meeting, pinned: true);
    await repo.setReminders(meeting, {'PT9H'});
    await repo.setRepeat(meeting, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=FR');
    await repo.createTask(listId: inboxListId, title: 'Revisar pauta', parentId: meeting);
    await repo.createTask(listId: inboxListId, title: 'Lembrete disparando', dueDate: DateTime(2026, 9, 24, 18, 48), isAllDay: false);
    final pack = await repo.createTask(listId: inboxListId, title: 'Coisas para a viagem', kind: TaskKind.checklist, dueDate: DateTime(2026, 9, 26));
    final a = await repo.addChecklistItem(pack, title: 'Passaporte');
    await repo.addChecklistItem(pack, title: 'Carregador');
    await repo.setChecklistItemCompleted(a, completed: true);
    await repo.createTask(listId: inboxListId, title: 'Comprar pão', priority: Priority.medium, content: 'Integral e francês');
    final done = await repo.createTask(listId: inboxListId, title: 'Pagar conta de luz');
    await repo.complete(done);
    await repo.createTask(listId: work, title: 'Enviar relatório', dueDate: DateTime(2026, 9, 23), priority: Priority.low);
    final doing = await repo.createSection(work, 'Fazendo');
    await repo.createSection(work, 'A fazer');
    await repo.createTask(listId: work, sectionId: doing, title: 'Revisar proposta do cliente', dueDate: DateTime(2026, 9, 25), tagIds: [tag]);
    await repo.createTask(listId: work, sectionId: doing, title: 'Atualizar planilha');
    final water = await repo.createHabit(
      HabitsCompanion(
        name: const Value('Beber água'),
        icon: const Value('💧'),
        color: const Value('#4CA1FF'),
        startDate: Value(DateTime(2026, 9, 18)),
        goal: const Value(HabitGoal.amount),
        goalAmount: const Value(8),
        unit: const Value('copos'),
        section: const Value('morning'),
      ),
    );
    final read = await repo.createHabit(
      HabitsCompanion(
        name: const Value('Ler 20 páginas'),
        icon: const Value('📚'),
        color: const Value('#35D870'),
        startDate: Value(DateTime(2026, 9, 20)),
        section: const Value('evening'),
      ),
    );
    for (final d in [18, 19, 20, 21, 22]) {
      await repo.checkIn(water, DateTime(2026, 9, d), amount: 8);
    }
    await repo.checkIn(water, DateTime(2026, 9, 24), amount: 3);
    for (final d in [20, 21, 23, 24]) {
      await repo.checkIn(read, DateTime(2026, 9, d));
    }
    await repo.createTask(
      listId: work,
      title: 'Workshop de design',
      startDate: DateTime(2026, 9, 22, 9),
      dueDate: DateTime(2026, 9, 22, 12),
      isAllDay: false,
      color: '#DA5234',
    );
    await repo.createTask(
      listId: work,
      title: 'Almoço com cliente',
      startDate: DateTime(2026, 9, 22, 11),
      dueDate: DateTime(2026, 9, 22, 13),
      isAllDay: false,
      color: '#E7BA51',
    );
    await repo.createTask(listId: inboxListId, title: 'Viagem a São Paulo', startDate: DateTime(2026, 9, 28), dueDate: DateTime(2026, 9, 30));
    final urgent = await repo.createFilter(
      'Urgentes',
      const FilterRule(
        conditions: [
          FilterCondition(field: FilterField.priority, values: {'5', '3'}),
        ],
      ),
    );
    // "Estimativa" of 3 Pomos, one of them done.
    await repo.setEstimate(meeting, pomos: 3);
    await repo.addFocusRecord(
      FocusRecordDraft(
        startedAt: DateTime(2026, 9, 24, 8),
        endedAt: DateTime(2026, 9, 24, 8, 25),
        seconds: 25 * 60,
        mode: FocusMode.pomo,
        taskId: meeting,
      ),
    );
    return {'meeting': meeting, 'work': work, 'urgent': urgent, 'pack': pack};
  }

  Future<void> shoot(
    WidgetTester tester,
    String name,
    String location, {
    Size size = const Size(1600, 1000),
    Future<void> Function(WidgetTester tester)? interact,
    Future<void> Function(PreferencesRepository prefs)? configure,
    Future<void> Function(FinanceRepository finance)? finance,
    Future<void> Function(DietRepository diet)? diet,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ids = await tester.runAsync(() => seed(Repository(db, clock: clock)));
    if (configure != null) await tester.runAsync(() => configure(PreferencesRepository(db, clock: clock)));
    if (finance != null) await tester.runAsync(() => finance(FinanceRepository(db, clock: clock)));
    if (diet != null) await tester.runAsync(() => diet(DietRepository(db, clock: clock)));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
          child: TasksApp(initialLocation: ids!.entries.fold(location, (l, e) => l.replaceAll('{${e.key}}', e.value))),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (interact != null) {
      await interact(tester);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('desktop inbox with detail', (tester) => shoot(tester, 'desktop_inbox', '/p/inbox/tasks/{meeting}'));

  // Finanças with a month of sample data.
  Future<void> financeData(FinanceRepository f) async {
    final food = await f.createCategory(name: 'Alimentação', kind: FinKind.expense, icon: '🍽️', monthlyLimit: 80000);
    final market = await f.createCategory(name: 'Mercado', kind: FinKind.expense, icon: '🛒', monthlyLimit: 100000);
    final home = await f.createCategory(name: 'Moradia', kind: FinKind.expense, icon: '🏠');
    final fun = await f.createCategory(name: 'Lazer', kind: FinKind.expense, icon: '🎉');
    final salary = await f.createCategory(name: 'Salário', kind: FinKind.income, icon: '💰');
    final card = await f.createCard(name: 'Nubank', closingDay: 5, dueDay: 12, creditLimit: 500000);
    await f.addEntry(kind: FinKind.income, amount: 650000, date: DateTime(2026, 9, 5), description: 'Salário', categoryId: salary);
    await f.addEntry(kind: FinKind.expense, amount: 4590, date: DateTime(2026, 9, 24), description: 'Lanche', categoryId: food);
    await f.addEntry(kind: FinKind.expense, amount: 68000, date: DateTime(2026, 9, 20), description: 'Feira do mês', categoryId: market);
    await f.addEntry(kind: FinKind.expense, amount: 12000, date: DateTime(2026, 9, 18), description: 'Cinema', categoryId: fun);
    await f.addEntry(kind: FinKind.expense, amount: 2500, date: DateTime(2026, 9, 3), description: 'Café', categoryId: food, cardId: card);
    await f.addEntry(kind: FinKind.expense, amount: 120000, date: DateTime(2026, 9, 10), description: 'Celular', cardId: card, installments: 3);
    await f.addEntry(kind: FinKind.expense, amount: 30000, date: DateTime(2026, 8, 12), description: 'Feira', categoryId: market);
    final rent = await f.createRecurring(
      FinRecurringsCompanion(
        kind: const Value(FinKind.expense),
        description: const Value('Aluguel'),
        amount: const Value(150000),
        frequency: const Value(FinFrequency.monthly),
        day: const Value(5),
        categoryId: Value(home),
        startDate: Value(DateTime.utc(2026, 8)),
        remindDaysBefore: const Value(0),
      ),
    );
    await f.addEntry(
      kind: FinKind.expense,
      amount: 150000,
      date: DateTime(2026, 9, 5),
      description: 'Aluguel',
      categoryId: home,
      recurringId: rent,
      recurringDue: DateTime(2026, 9, 5),
    );
    await f.createRecurring(
      FinRecurringsCompanion(
        kind: const Value(FinKind.expense),
        description: const Value('Internet'),
        amount: const Value(9990),
        frequency: const Value(FinFrequency.monthly),
        day: const Value(28),
        startDate: Value(DateTime.utc(2026, 9)),
        remindDaysBefore: const Value(1),
      ),
    );
    final joao = await f.createLoan(borrower: 'João', principal: 100000, total: 130000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 10, 20));
    await f.addLoanPayment(loanId: joao, amount: 50000, date: DateTime(2026, 9, 20));
    await f.createLoan(borrower: 'Maria', principal: 50000, total: 60000, lentOn: DateTime(2026, 8, 1), dueOn: DateTime(2026, 9, 10));
  }

  for (final tab in ['entries', 'cards', 'recurring', 'loans', 'reports', 'categories']) {
    testWidgets('finance $tab', (tester) => shoot(tester, 'finance_$tab', '/finance/$tab', finance: financeData));
    testWidgets(
      'finance $tab on a phone',
      (tester) => shoot(tester, 'finance_${tab}_phone', '/finance/$tab', size: const Size(412, 915), finance: financeData),
    );
  }

  for (final (name, size) in [('finance_reports_detailed', const Size(1600, 1000)), ('finance_reports_detailed_phone', const Size(412, 915))]) {
    testWidgets(
      name,
      (tester) => shoot(
        tester,
        name,
        '/finance/reports',
        size: size,
        finance: financeData,
        interact: (tester) async {
          await tester.tap(find.text('Detalhado'));
          await tester.pumpAndSettle();
        },
      ),
    );
  }

  /// The TACO table loads from the assets (slower with other tests running): pumps until [finder] shows.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> dietData(DietRepository d) async {
    final taco = parseTaco(File('assets/taco.json').readAsStringSync());
    Food food(String name) => taco.firstWhere((f) => f.name == name);
    final day = DateTime(2026, 9, 24);
    await d.addEntry(
      day: day,
      meal: 'breakfast',
      food: food('Pão, trigo, francês'),
      quantity: 1,
      measure: food('Pão, trigo, francês').defaultMeasure,
    );
    await d.addEntry(day: day, meal: 'breakfast', food: food('Café, infusão 10%'), quantity: 200);
    await d.addEntry(
      day: day,
      meal: 'lunch',
      food: food('Arroz, tipo 1, cozido'),
      quantity: 4,
      measure: food('Arroz, tipo 1, cozido').defaultMeasure,
    );
    await d.addEntry(day: day, meal: 'lunch', food: food('Feijão, carioca, cozido'), quantity: 120);
    final whey = await d.createFood(
      name: 'Whey da loja',
      per100g: const Nutrients(kcal: 400, protein: 80, carbs: 8, fat: 6),
      measures: [(id: null, name: 'scoop', grams: 30)],
    );
    await d.addEntry(
      day: day,
      meal: 'afternoonSnack',
      food: Food(id: whey, name: 'Whey da loja', per100g: const Nutrients(kcal: 400, protein: 80, carbs: 8, fat: 6), custom: true),
      quantity: 1,
      measure: const FoodMeasure(name: 'scoop', grams: 30, isDefault: true),
    );
  }

  testWidgets('diet', (tester) => shoot(tester, 'diet', '/diet', diet: dietData));
  testWidgets('diet phone', (tester) => shoot(tester, 'diet_phone', '/diet', size: const Size(412, 915), diet: dietData));
  testWidgets(
    'diet foods',
    (tester) => shoot(
      tester,
      'diet_foods',
      '/diet/foods',
      diet: dietData,
      interact: (tester) async {
        await tester.enterText(find.byType(TextField).first, 'banana');
        await waitFor(tester, find.textContaining('Banana, prata'));
      },
    ),
  );
  testWidgets(
    'diet add',
    (tester) => shoot(
      tester,
      'diet_add',
      '/diet',
      diet: dietData,
      interact: (tester) async {
        await tester.tap(find.widgetWithText(CreateButton, 'Adicionar alimento'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'frango peito grelhado');
        await waitFor(tester, find.textContaining('Frango, peito, sem pele, grelhado'));
        await tester.tap(find.textContaining('Frango, peito, sem pele, grelhado').last);
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets('calendar week with finance', (tester) => shoot(tester, 'calendar_week_finance', '/calendar/w', finance: financeData));
  testWidgets('desktop today', (tester) => shoot(tester, 'desktop_today', '/q/today/tasks'));
  // The light theme, where colors and contrast go wrong first.
  for (final (name, route) in [
    ('light_today', '/q/today/tasks'),
    ('light_inbox', '/p/inbox/tasks/{meeting}'),
    ('light_calendar', '/calendar/m'),
    ('light_habits', '/habit'),
  ]) {
    testWidgets(name, (tester) => shoot(tester, name, route, configure: (prefs) => prefs.setTheme(ThemeChoice.light)));
  }
  testWidgets('desktop next 7 days', (tester) => shoot(tester, 'desktop_week', '/q/week/tasks'));
  testWidgets(
    'reminder popup',
    (tester) => shoot(
      tester,
      'reminder_popup',
      '/q/today/tasks',
      interact: (tester) async {
        final container = ProviderScope.containerOf(tester.element(find.byType(TasksApp)));
        final at = DateTime(2026, 9, 24, 18, 48);
        container.read(firedRemindersProvider.notifier).add([
          PlannedReminder(id: 1, taskId: 'x', at: at, title: 'Lembrete disparando', due: at, isAllDay: false),
        ]);
        await tester.pump();
        await tester.tap(find.text('Adiar'));
      },
    ),
  );
  testWidgets(
    'custom repeat dialog',
    (tester) => shoot(
      tester,
      'custom_repeat',
      '/p/inbox/tasks/{meeting}',
      interact: (tester) async {
        Future<void> tapText(String text) async {
          await tester.tap(find.text(text).last);
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await tapText('Amanhã, 25 set');
        await tapText('Repetir');
        await tapText('Personalizado');
        await tapText('Semana');
        await tapText('Mês');
      },
    ),
  );
  testWidgets(
    'quick add popup',
    (tester) => shoot(
      tester,
      'quick_add_popup',
      '/p/inbox/tasks',
      interact: (tester) async {
        final field = find.byType(TextField).first;
        await tester.tap(field);
        await tester.pump();
        await tester.enterText(field, 'Revisar contrato ~');
      },
    ),
  );
  testWidgets(
    'date picker duration',
    (tester) => shoot(
      tester,
      'date_picker_duration',
      '/p/inbox/tasks/{meeting}',
      interact: (tester) async {
        Future<void> tapText(String text) async {
          await tester.tap(find.text(text).last);
          for (var i = 0; i < 3; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await tapText('Amanhã, 25 set');
        await tapText('Duração');
        await tapText('26');
        await tapText('29');
      },
    ),
  );
  testWidgets(
    'command palette',
    (tester) => shoot(
      tester,
      'command_palette',
      '/q/today/tasks',
      interact: (tester) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      },
    ),
  );
  testWidgets(
    'quick search',
    (tester) => shoot(
      tester,
      'quick_search',
      '/q/today/tasks',
      interact: (tester) async {
        await tester.sendKeyEvent(LogicalKeyboardKey.slash);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextField).last, 're');
      },
    ),
  );
  testWidgets(
    'quick add modal',
    (tester) => shoot(
      tester,
      'quick_add_modal',
      '/p/inbox/tasks',
      interact: (tester) async {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextField).last, 'Comprar leite amanhã #');
      },
    ),
  );
  testWidgets(
    'batch pane',
    (tester) => shoot(
      tester,
      'batch_pane',
      '/p/inbox/tasks',
      interact: (tester) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(find.text('Comprar pão'));
        await tester.tap(find.text('Lembrete disparando'));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      },
    ),
  );
  testWidgets(
    'mini calendar',
    (tester) => shoot(tester, 'mini_calendar', '/q/today/tasks', configure: (prefs) => prefs.setMiniCalendar(enabled: true)),
  );
  testWidgets(
    'add field detailed',
    (tester) => shoot(tester, 'add_field_detailed', '/p/inbox/tasks', configure: (prefs) => prefs.setAddFieldDetailed(enabled: true)),
  );
  testWidgets(
    'card style',
    (tester) => shoot(tester, 'card_style', '/p/inbox/tasks/{meeting}', configure: (prefs) => prefs.setCardStyle(enabled: true)),
  );
  testWidgets(
    'detail popup',
    (tester) => shoot(tester, 'detail_popup', '/p/inbox/tasks/{meeting}', configure: (prefs) => prefs.setDetailPopup(enabled: true)),
  );
  testWidgets('completed filters', (tester) => shoot(tester, 'completed_filters', '/q/completed/tasks'));
  testWidgets(
    'format bar',
    (tester) => shoot(
      tester,
      'format_bar',
      '/p/inbox/tasks/{meeting}',
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.text_format));
        await tester.pump();
      },
    ),
  );
  testWidgets(
    'immersive writing',
    (tester) => shoot(
      tester,
      'immersive',
      '/p/inbox/tasks/{meeting}',
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.text_format));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.fullscreen));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  );
  testWidgets('checklist detail', (tester) => shoot(tester, 'checklist_detail', '/p/inbox/tasks/{pack}'));
  testWidgets(
    'section menu',
    (tester) => shoot(
      tester,
      'section_menu',
      '/p/{work}/tasks',
      interact: (tester) async {
        final header = find.ancestor(of: find.text('Fazendo'), matching: find.byType(Row)).first;
        await tester.tap(find.descendant(of: header, matching: find.byIcon(Icons.more_horiz)));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  );
  testWidgets(
    'kanban',
    (tester) => shoot(
      tester,
      'kanban',
      '/p/{work}/tasks',
      interact: (tester) async {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    ),
  );
  testWidgets(
    'template picker',
    (tester) => shoot(
      tester,
      'template_picker',
      '/p/inbox/tasks',
      interact: (tester) async {
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        unawaited(pickTemplate(tester.element(find.byType(TaskListPane))));
      },
    ),
  );
  testWidgets('countdown', (tester) => shoot(tester, 'countdown', '/countdown'));
  testWidgets('countdown on a phone', (tester) => shoot(tester, 'countdown_phone', '/countdown', size: const Size(412, 915)));
  // Every main screen at phone width (Android): a layout that overflows fails the test.
  for (final (name, route) in [
    ('today', '/q/today/tasks'),
    ('week', '/q/week/tasks'),
    ('task_detail', '/p/inbox/tasks/{meeting}'),
    ('checklist_detail', '/p/inbox/tasks/{pack}'),
    ('list', '/p/{work}/tasks'),
    ('filter', '/f/{urgent}/tasks'),
    ('completed', '/q/completed/tasks'),
    ('summary', '/q/summary/tasks'),
    ('search', '/s?q=re'),
    ('focus', '/focus'),
    ('habits', '/habit'),
    ('matrix', '/matrix'),
    ('calendar_day', '/calendar/d'),
    ('calendar_week', '/calendar/w'),
    ('calendar_agenda', '/calendar/a'),
    ('calendar_year', '/calendar/y'),
    ('stats_overview', '/statistics/overview'),
    ('stats_task', '/statistics/task'),
    ('stats_focus', '/statistics/pomo'),
  ]) {
    testWidgets('$name on a phone', (tester) => shoot(tester, 'phone_$name', route, size: const Size(412, 915)));
  }
  testWidgets(
    'countdown grouped',
    (tester) => shoot(
      tester,
      'countdown_grouped',
      '/countdown',
      interact: (tester) async {
        // Only the holidays: "⋮ › Mostrar só este" of the panel's Feriado.
        await tester.tap(find.widgetWithText(PanelCheckRow, 'Contagem Regressiva'));
        await tester.tap(find.widgetWithText(PanelCheckRow, 'Data Especial'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets('focus', (tester) => shoot(tester, 'focus', '/focus'));
  testWidgets(
    'focus timers',
    (tester) => shoot(
      tester,
      'focus_timers',
      '/focus',
      configure: (prefs) => prefs.setFocusTimers(const [
        FocusTimer(id: 'a', name: 'Estudo profundo', minutes: 50),
        FocusTimer(id: 'b', name: 'Revisão rápida', mode: FocusMode.stopwatch),
      ]),
    ),
  );
  testWidgets(
    'focus timers running',
    (tester) => shoot(
      tester,
      'focus_timers_running',
      '/focus',
      configure: (prefs) => prefs.setFocusTimers(const [
        FocusTimer(id: 'a', name: 'Estudo profundo', minutes: 50),
        FocusTimer(id: 'b', name: 'Revisão rápida', mode: FocusMode.stopwatch),
      ]),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.play_circle_outline).first);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pump();
      },
    ),
  );
  testWidgets(
    'timer detail',
    (tester) => shoot(
      tester,
      'timer_detail',
      '/focus',
      configure: (prefs) => prefs.setFocusTimers(const [FocusTimer(id: 'a', name: 'Estudo profundo', minutes: 50)]),
      interact: (tester) async {
        await tester.tap(find.text('Estudo profundo'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  );
  testWidgets(
    'focus batch',
    (tester) => shoot(
      tester,
      'focus_batch',
      '/focus',
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.more_horiz).last);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.text('Gestão de Lotes'));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
      },
    ),
  );
  testWidgets('habits', (tester) => shoot(tester, 'habits', '/habit'));
  testWidgets(
    'habit cards',
    (tester) => shoot(
      tester,
      'habit_cards',
      '/habit',
      interact: (tester) async {
        // The top bar's view pill: Lista › Cartões.
        await tester.tap(find.byType(ViewPill<bool>));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckedPopupMenuItem<bool>).last);
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'habit detail',
    (tester) => shoot(
      tester,
      'habit_detail',
      '/habit',
      size: const Size(1600, 1200),
      interact: (tester) async {
        await tester.tap(find.text('Beber água').first);
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  );
  testWidgets('matrix', (tester) => shoot(tester, 'matrix', '/matrix'));
  testWidgets(
    'list dialog',
    (tester) => shoot(
      tester,
      'list_dialog',
      '/p/inbox/tasks',
      interact: (tester) async {
        final header = find.ancestor(of: find.text('Listas'), matching: find.byType(Row)).first;
        await tester.tap(find.descendant(of: header, matching: find.byIcon(Icons.add)));
        await tester.pumpAndSettle();
        await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first, 'Estudos');
        await tester.tap(find.text('Kanban').last);
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'settings imports',
    (tester) => shoot(
      tester,
      'settings_imports',
      '/p/inbox/tasks',
      interact: (tester) async {
        unawaited(showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.imports));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'settings account',
    (tester) => shoot(
      tester,
      'settings_account',
      '/p/inbox/tasks',
      interact: (tester) async {
        unawaited(showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.account));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'settings features',
    (tester) => shoot(
      tester,
      'settings_features',
      '/p/inbox/tasks',
      interact: (tester) async {
        unawaited(showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.features));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'settings smartLists',
    (tester) => shoot(
      tester,
      'settings_smartLists',
      '/p/inbox/tasks',
      interact: (tester) async {
        unawaited(showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.smartLists));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'settings appearance',
    (tester) => shoot(
      tester,
      'settings_appearance',
      '/p/inbox/tasks',
      interact: (tester) async {
        unawaited(showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.appearance));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets('settings notifications', (tester) async {
    debugShowDesktopSettings = true;
    addTearDown(() => debugShowDesktopSettings = false);
    await shoot(
      tester,
      'settings_notifications',
      '/p/inbox/tasks',
      interact: (tester) async {
        unawaited(showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.notifications));
        await tester.pumpAndSettle();
      },
    );
  });
  testWidgets('statistics overview', (tester) => shoot(tester, 'stats_overview', '/statistics/overview', size: const Size(1600, 2200)));
  testWidgets('statistics task', (tester) => shoot(tester, 'stats_task', '/statistics/task', size: const Size(1600, 1200)));
  testWidgets('statistics focus', (tester) => shoot(tester, 'stats_focus', '/statistics/pomo', size: const Size(1600, 2200)));
  testWidgets(
    'matrix menu',
    (tester) => shoot(
      tester,
      'matrix_menu',
      '/matrix',
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.more_horiz).at(1));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets('search page', (tester) => shoot(tester, 'search_page', '/s?q=re'));
  testWidgets(
    'summary',
    (tester) =>
        shoot(tester, 'summary', '/q/summary/tasks', configure: (prefs) => prefs.setSmartListVisibility(SmartList.summary, SmartListVisibility.show)),
  );
  testWidgets('filter view', (tester) => shoot(tester, 'filter_view', '/f/{urgent}/tasks'));
  testWidgets(
    'timeline',
    (tester) => shoot(
      tester,
      'timeline',
      '/p/{work}/tasks',
      interact: (tester) async {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    ),
  );
  testWidgets(
    'task activities',
    (tester) => shoot(
      tester,
      'task_activities',
      '/p/inbox/tasks',
      interact: (tester) async {
        await tester.tap(find.text('Reunião de planejamento').first, buttons: kSecondaryButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Atividades da tarefa'));
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    ),
  );
  testWidgets('calendar month', (tester) => shoot(tester, 'calendar_month', '/calendar/m'));
  testWidgets('calendar week', (tester) => shoot(tester, 'calendar_week', '/calendar/w'));
  testWidgets(
    'calendar holidays',
    (tester) => shoot(
      tester,
      'calendar_holidays',
      '/calendar/m',
      configure: (prefs) => prefs.setSubscriptions(const [
        CalendarSubscription(id: 'br', name: 'Feriados do Brasil', kind: SubscriptionKind.holidays, color: '#35D870'),
      ]),
    ),
  );
  testWidgets(
    'calendar monday 12h',
    (tester) => shoot(
      tester,
      'calendar_monday_12h',
      '/calendar/m',
      configure: (prefs) async {
        await prefs.setFirstWeekday(DateTime.monday);
        await prefs.setUse24h(enabled: false);
        await prefs.setWeekNumbers(enabled: true);
      },
    ),
  );
  testWidgets(
    'calendar week 12h',
    (tester) => shoot(
      tester,
      'calendar_week_12h',
      '/calendar/w',
      configure: (prefs) async {
        await prefs.setFirstWeekday(DateTime.monday);
        await prefs.setUse24h(enabled: false);
      },
    ),
  );
  testWidgets('calendar day', (tester) => shoot(tester, 'calendar_day', '/calendar/d'));
  testWidgets(
    'calendar classic zones',
    (tester) => shoot(
      tester,
      'calendar_classic_zones',
      '/calendar/w',
      configure: (prefs) =>
          prefs.setCalendarOptions(const CalendarOptions(classicStyle: true, showIcons: true, timeZones: ['America/New_York', 'Asia/Kolkata'])),
    ),
  );
  testWidgets('calendar year', (tester) => shoot(tester, 'calendar_year', '/calendar/y'));
  testWidgets('calendar agenda', (tester) => shoot(tester, 'calendar_agenda', '/calendar/a'));
  testWidgets(
    'calendar create card',
    (tester) => shoot(
      tester,
      'calendar_create_card',
      '/calendar/w',
      interact: (tester) async {
        await tester.tapAt(const Offset(760, 560));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    ),
  );
  testWidgets(
    'calendar more options',
    (tester) => shoot(
      tester,
      'calendar_more_options',
      '/calendar/w',
      interact: (tester) async {
        await tester.tapAt(const Offset(760, 560));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Adicionar título'), 'Revisão do carro');
        await tester.tap(find.text('Mais opções'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets('calendar phone', (tester) => shoot(tester, 'calendar_phone', '/calendar/m', size: const Size(400, 800)));
  testWidgets(
    'calendar insights',
    (tester) => shoot(
      tester,
      'calendar_insights',
      '/calendar/w',
      configure: (prefs) => prefs.setColorLabels(const [
        ColorLabel(color: '#DA5234', name: 'TCC + Álgebra'),
        ColorLabel(color: '#E7BA51', name: 'Alimentação'),
        ColorLabel(color: '#668BE1', name: 'Dormir'),
      ]),
      interact: (tester) async {
        await tester.tap(find.text('Mais insights'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'calendar insights card',
    (tester) => shoot(
      tester,
      'calendar_insights_card',
      '/calendar/w',
      configure: (prefs) => prefs.setColorLabels(const [
        ColorLabel(color: '#DA5234', name: 'TCC + Álgebra'),
        ColorLabel(color: '#E7BA51', name: 'Alimentação'),
        ColorLabel(color: '#668BE1', name: 'Dormir'),
      ]),
      interact: (tester) async {
        await tester.tap(find.descendant(of: find.byType(CalendarInsightsSummary), matching: find.byType(ClipRRect)));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'calendar color menu',
    (tester) => shoot(
      tester,
      'calendar_color_menu',
      '/calendar/w',
      configure: (prefs) => prefs.setColorLabels(const [
        ColorLabel(color: '#DA5234', name: 'TCC + Álgebra'),
        ColorLabel(color: '#E7BA51', name: 'Alimentação'),
        ColorLabel(color: '#668BE1', name: 'Dormir'),
      ]),
      interact: (tester) async {
        await tester.tapAt(tester.getCenter(find.text('Almoço com cliente')), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'calendar custom recurrence',
    (tester) => shoot(
      tester,
      'calendar_custom_recurrence',
      '/calendar/w',
      interact: (tester) async {
        await tester.tapAt(const Offset(760, 560));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mais opções'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Não se repete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Personalizado…'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'calendar details popup',
    (tester) => shoot(
      tester,
      'calendar_details_popup',
      '/calendar/w',
      interact: (tester) async {
        await tester.tap(find.text('Almoço com cliente'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'color picker',
    (tester) => shoot(
      tester,
      'color_picker',
      '/calendar/w',
      interact: (tester) async {
        await tester.tapAt(tester.getCenter(find.text('Almoço com cliente')), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Cor personalizada').last);
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'habit color',
    (tester) => shoot(
      tester,
      'habit_color',
      '/habit',
      interact: (tester) async {
        // Right-click › Cor: the Calendar's color menu, without the labels.
        await tester.tapAt(tester.getCenter(find.text('Beber água').first), buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cor'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'calendar insights phone',
    (tester) => shoot(
      tester,
      'calendar_insights_phone',
      '/calendar/w',
      size: const Size(400, 800),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Insights de tempo'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'module drawer phone',
    (tester) => shoot(
      tester,
      'module_drawer_phone',
      '/habit',
      size: const Size(400, 800),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.drag(find.text('Lixeira'), const Offset(0, -400));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'filter dialog',
    (tester) => shoot(
      tester,
      'filter_dialog',
      '/f/{urgent}/tasks',
      interact: (tester) async {
        final header = find.ancestor(of: find.text('Filtros'), matching: find.byType(Row)).first;
        await tester.tap(find.descendant(of: header, matching: find.byIcon(Icons.add)));
        await tester.pumpAndSettle();
        await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first, 'Casa ou atrasadas');
        await tester.tap(find.text('Avançado'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Adicionar condição'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Prévia'));
        await tester.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'date picker',
    (tester) => shoot(tester, 'date_picker', '/p/inbox/tasks/{meeting}', interact: (tester) => tester.tap(find.textContaining('25 set').last)),
  );
}
