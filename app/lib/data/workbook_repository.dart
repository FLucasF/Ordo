import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../domain/diet/diet.dart' show foldForSearch;
import '../domain/finance/finance.dart';
import '../domain/spreadsheet/workbook.dart';
import '../domain/spreadsheet/workbook_import.dart';
import 'db/database.dart';
import 'finance_repository.dart';
import 'importer.dart';
import 'repository.dart';

/// Every row the Excel export shows, read straight from the tables (the screens of some modules
/// keep their own state; the workbook does not depend on them).
Future<WorkbookData> loadWorkbookData(AppDatabase db) => db.transaction(
  () async => WorkbookData(
    folders: await db.select(db.folders).get(),
    lists: await db.select(db.lists).get(),
    sections: await db.select(db.sections).get(),
    tasks: await db.select(db.tasks).get(),
    checklistItems: await db.select(db.checklistItems).get(),
    tags: await db.select(db.tags).get(),
    taskTags: await db.select(db.taskTags).get(),
    habits: await db.select(db.habits).get(),
    habitCheckins: await db.select(db.habitCheckins).get(),
    categories: await db.select(db.finCategories).get(),
    cards: await db.select(db.finCards).get(),
    entries: await db.select(db.finEntries).get(),
    cardPayments: await db.select(db.finCardPayments).get(),
    loans: await db.select(db.loans).get(),
    loanPayments: await db.select(db.loanPayments).get(),
    goals: await db.select(db.finGoals).get(),
    goalMoves: await db.select(db.finGoalMoves).get(),
    dietMeals: await db.select(db.dietMeals).get(),
    dietEntries: await db.select(db.dietEntries).get(),
    journal: await db.select(db.journalEntries).get(),
  ),
);

/// The names of the cards an imported entry can use.
Future<List<String>> cardNames(AppDatabase db) async => [
  for (final c in await (db.select(db.finCards)..where((c) => c.deletedAt.isNull())).get()) c.name,
];

/// What an Excel import wrote.
class WorkbookImportResult {
  const WorkbookImportResult({required this.tasks, required this.entries});
  final int tasks;
  final int entries;
}

/// Appends the preview's tasks and entries; nothing is replaced. Lists, sections and tags go through
/// the TickTick importer (matched by name, created when missing); categories are matched by name and
/// kind and cards by name, ignoring case and accents, and created when missing.
Future<WorkbookImportResult> importWorkbook(AppDatabase db, WorkbookPreview preview, {Clock clock = const SystemClock()}) async {
  final tasks = preview.tasks.isEmpty ? null : await importTasks(Repository(db, clock: clock), preview.tasks);
  if (preview.entries.isEmpty) return WorkbookImportResult(tasks: tasks?.tasks ?? 0, entries: 0);
  final finance = FinanceRepository(db, clock: clock);
  String key(String name) => foldForSearch(name.trim());
  await db.transaction(() async {
    final now = clock.now().toUtc();
    final categories = {
      for (final c in await (db.select(db.finCategories)..where((c) => c.deletedAt.isNull())).get()) '${c.kind.code}|${key(c.name)}': c.id,
    };
    final cards = {for (final c in await (db.select(db.finCards)..where((c) => c.deletedAt.isNull())).get()) key(c.name): c};
    for (final c in preview.cards) {
      if (cards.containsKey(key(c.name))) continue;
      final id = await finance.createCard(name: c.name, closingDay: c.closingDay, dueDay: c.dueDay, creditLimit: c.creditLimit);
      cards[key(c.name)] = await (db.select(db.finCards)..where((x) => x.id.equals(id))).getSingle();
    }
    // Installments of one purchase (same day, card, description and count) share a group again.
    final groups = <String, String>{};
    for (final e in preview.entries) {
      final categoryName = e.category;
      final categoryId = categoryName == null
          ? null
          : categories['${e.kind.code}|${key(categoryName)}'] ??= await finance.createCategory(name: categoryName, kind: e.kind);
      final card = e.card == null ? null : cards[key(e.card!)];
      final invoice = card == null ? null : (e.invoiceMonth ?? invoiceMonthFor(card, e.date));
      final count = card == null ? null : e.installmentCount;
      final group = count == null ? null : groups['${e.date}|${card!.id}|${key(e.description)}|$count'] ??= newId();
      await db
          .into(db.finEntries)
          .insert(
            FinEntriesCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              kind: e.kind,
              amount: e.amount,
              date: storedDay(e.date),
              description: Value(e.description.trim()),
              categoryId: Value(categoryId),
              cardId: Value(card?.id),
              invoiceMonth: Value(invoice == null ? null : storedDay(invoice)),
              installmentGroup: Value(group),
              installmentIndex: Value(group == null ? null : e.installmentIndex),
              installmentCount: Value(group == null ? null : count),
              note: Value(e.note.trim()),
            ),
          );
    }
  });
  return WorkbookImportResult(tasks: tasks?.tasks ?? 0, entries: preview.entries.length);
}
