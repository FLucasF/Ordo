import 'package:drift/drift.dart';

import 'tables.dart';

// Diário, schema v20. Days are the local day at UTC midnight, like Finanças' and Dieta's.

/// One entry per day: [mood] and [energy] from 1 to 5 (null = not told), the day's notes (markdown,
/// as a task's content) and its highlight or gratitude.
@DataClassName('JournalEntry')
class JournalEntries extends Table with SyncedRow {
  DateTimeColumn get day => dateTime()();
  IntColumn get mood => integer().nullable()();
  IntColumn get energy => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get highlight => text().withDefault(const Constant(''))();
}
