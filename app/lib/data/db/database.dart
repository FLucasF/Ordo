import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/ids.dart';
import '../../domain/enums.dart';
import '../../domain/finance/finance_enums.dart';
import 'converters.dart';
import 'database.steps.dart';
import 'diet_tables.dart';
import 'finance_tables.dart';
import 'tables.dart';
import '../../core/app_folder.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Folders,
    Lists,
    Sections,
    Tasks,
    ChecklistItems,
    Tags,
    TaskTags,
    Preferences,
    TaskReminders,
    Templates,
    Comments,
    Countdowns,
    FocusRecords,
    Habits,
    HabitCheckins,
    Filters,
    Activities,
    FinCategories,
    FinCards,
    FinRecurrings,
    FinEntries,
    FinCardPayments,
    Loans,
    LoanPayments,
    DietFoods,
    DietEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// Bump on every schema change and run `dart run drift_dev make-migrations` to freeze the new
  /// schema and generate its migration test.
  @override
  int get schemaVersion => 19;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createInbox();
    },
    // One step per schema version; each is covered by test/drift/app/migration_test.dart.
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.addColumn(schema.tasks, schema.tasks.repeatRule);
        await m.addColumn(schema.tasks, schema.tasks.repeatFrom);
        await m.createTable(schema.taskReminders);
      },
      from2To3: (m, schema) async {
        await m.addColumn(schema.tasks, schema.tasks.snoozeUntil);
      },
      from3To4: (m, schema) async {
        await m.addColumn(schema.checklistItems, schema.checklistItems.dueDate);
        await m.addColumn(schema.checklistItems, schema.checklistItems.isAllDay);
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.templates);
      },
      from5To6: (m, schema) async {
        await m.createTable(schema.comments);
      },
      from6To7: (m, schema) async {
        await m.createTable(schema.countdowns);
      },
      from7To8: (m, schema) async {
        await m.createTable(schema.focusRecords);
      },
      from8To9: (m, schema) async {
        await m.createTable(schema.habits);
        await m.createTable(schema.habitCheckins);
      },
      from9To10: (m, schema) async {
        await m.createTable(schema.filters);
      },
      from10To11: (m, schema) async {
        await m.createTable(schema.activities);
      },
      from11To12: (m, schema) async {
        await m.addColumn(schema.countdowns, schema.countdowns.icon);
        await m.addColumn(schema.countdowns, schema.countdowns.image);
      },
      from12To13: (m, schema) async {
        await m.addColumn(schema.tasks, schema.tasks.estimatedPomos);
        await m.addColumn(schema.tasks, schema.tasks.estimatedMinutes);
      },
      from13To14: (m, schema) async {
        await m.addColumn(schema.countdowns, schema.countdowns.countUp);
      },
      from14To15: (m, schema) async {
        await m.addColumn(schema.habits, schema.habits.motto);
      },
      from15To16: (m, schema) async {
        await m.addColumn(schema.countdowns, schema.countdowns.iconColor);
      },
      from16To17: (m, schema) async {
        await m.addColumn(schema.tasks, schema.tasks.color);
      },
      // Finanças.
      from17To18: (m, schema) async {
        for (final table in [
          schema.finCategories,
          schema.finCards,
          schema.finRecurrings,
          schema.finEntries,
          schema.finCardPayments,
          schema.loans,
          schema.loanPayments,
        ]) {
          await m.createTable(table);
        }
      },
      from18To19: (m, schema) async {
        await m.createTable(schema.dietFoods);
        await m.createTable(schema.dietEntries);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // WAL: reads don't block writes and a write survives the app closing midway.
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  /// The Inbox exists from the start with a fixed id (`#p/inbox/tasks`). Its name is a
  /// placeholder; the UI shows the localized name for [inboxListId].
  Future<void> _createInbox() async {
    final now = DateTime.now().toUtc();
    await into(lists).insert(ListsCompanion.insert(id: inboxListId, createdAt: now, updatedAt: now, name: 'Inbox', sortOrder: 0));
  }

  /// `tasks.sqlite` in the app data folder (AppData on Windows, private storage on Android) instead of
  /// the Documents folder, which is drift_flutter's default.
  static QueryExecutor _open() => driftDatabase(
    name: 'tasks',
    native: const DriftNativeOptions(databaseDirectory: appDataDirectory, shareAcrossIsolates: true),
  );
}
