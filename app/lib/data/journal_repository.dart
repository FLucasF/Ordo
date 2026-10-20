import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../domain/journal/day_summary.dart' show journalCalorieTarget;
import '../domain/journal/journal.dart';
import 'db/database.dart';

/// The journal's entries (not deleted ones), one per day.
class JournalSnapshot {
  JournalSnapshot(this.entries) : _byDay = {for (final e in entries) journalDay(e.day): e};

  static final empty = JournalSnapshot(const []);

  /// Oldest day first.
  final List<JournalEntry> entries;
  final Map<DateTime, JournalEntry> _byDay;

  /// The entry of a local [day], if one was written.
  JournalEntry? on(DateTime day) => _byDay[DateTime(day.year, day.month, day.day)];
}

/// Every write of Diário. Kept apart from [Repository], as Dieta: journal changes don't reload the tasks.
class JournalRepository {
  JournalRepository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  /// A fresh snapshot on every change. The query text must differ from the others' (drift shares
  /// one stream between identical queries, whatever tables they read).
  Stream<JournalSnapshot> watch() => _db.customSelect('SELECT 1 AS journal', readsFrom: {_db.journalEntries}).watch().asyncMap((_) => load());

  /// Two devices may each have written a day before a sync: the last written wins (later rows replace
  /// earlier ones in the snapshot's map).
  Future<JournalSnapshot> load() async {
    final rows =
        await (_db.select(_db.journalEntries)
              ..where((e) => e.deletedAt.isNull())
              ..orderBy([(e) => OrderingTerm(expression: e.day), (e) => OrderingTerm(expression: e.updatedAt)]))
            .get();
    return JournalSnapshot(rows);
  }

  /// Dieta's daily calorie target (the `diet.targets` preference), null when it has none. Read raw:
  /// the journal only needs the calories, whatever else Dieta keeps there.
  Stream<double?> watchCalorieTarget() => (_db.select(_db.preferences)..where((p) => p.name.equals('diet.targets'))).watchSingleOrNull().map((row) {
    if (row == null) return null;
    try {
      return journalCalorieTarget(jsonDecode(row.value));
    } on FormatException {
      return null;
    }
  });

  /// Mood of [day] from 1 to 5; null clears it.
  Future<void> setMood(DateTime day, int? mood) => _write(day, JournalEntriesCompanion(mood: Value(mood)));

  /// Energy of [day] from 1 to 5; null clears it.
  Future<void> setEnergy(DateTime day, int? energy) => _write(day, JournalEntriesCompanion(energy: Value(energy)));

  /// The day's notes, markdown as a task's content.
  Future<void> setNotes(DateTime day, String notes) => _write(day, JournalEntriesCompanion(notes: Value(notes)));

  Future<void> setHighlight(DateTime day, String highlight) => _write(day, JournalEntriesCompanion(highlight: Value(highlight)));

  /// Writes [changes] into the entry of [day], creating it on its first change. A day whose entry was
  /// deleted gets it back emptied, so the old mood doesn't come back with a new note. In a transaction:
  /// a mood tapped while the notes save must not make two entries.
  Future<void> _write(DateTime day, JournalEntriesCompanion changes) => _db.transaction(() async {
    final stored = journalStoredDay(day);
    final rows =
        await (_db.select(_db.journalEntries)
              ..where((e) => e.day.equals(stored))
              ..orderBy([(e) => OrderingTerm(expression: e.updatedAt, mode: OrderingMode.desc)]))
            .get();
    final live = rows.where((e) => e.deletedAt == null).firstOrNull;
    final row = live ?? rows.firstOrNull;
    if (row == null) {
      await _db
          .into(_db.journalEntries)
          .insert(changes.copyWith(id: Value(newId()), createdAt: Value(_now), updatedAt: Value(_now), day: Value(stored)));
      return;
    }
    final revived = live == null
        ? const JournalEntriesCompanion(mood: Value(null), energy: Value(null), notes: Value(''), highlight: Value(''), deletedAt: Value(null))
        : const JournalEntriesCompanion();
    await (_db.update(_db.journalEntries)..where((e) => e.id.equals(row.id))).write(
      revived.copyWith(
        mood: changes.mood.present ? changes.mood : revived.mood,
        energy: changes.energy.present ? changes.energy : revived.energy,
        notes: changes.notes.present ? changes.notes : revived.notes,
        highlight: changes.highlight.present ? changes.highlight : revived.highlight,
        updatedAt: Value(_now),
      ),
    );
  });

  /// Deletes an entry; [restore] undoes it (the toast's "Desfazer").
  Future<void> delete(String id, {bool restore = false}) => (_db.update(
    _db.journalEntries,
  )..where((e) => e.id.equals(id))).write(JournalEntriesCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));
}
