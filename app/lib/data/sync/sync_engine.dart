import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/database.dart';
import 'sync_schema.dart';

/// One row as it travels to the other device: its table, key and columns, or none when it was deleted
/// there. [at] is the row's `updated_at` (or the deletion's time), what a merge compares. A task
/// carries its tags and reminders in [children].
class RowChange {
  const RowChange({required this.table, required this.id, required this.at, this.row, this.children = const {}});

  factory RowChange.fromJson(Map<String, Object?> json) => RowChange(
    table: json['t']! as String,
    id: json['i']! as String,
    at: json['a']! as String,
    row: (json['r'] as Map?)?.cast<String, Object?>(),
    children: {
      for (final MapEntry(:key, :value) in ((json['c'] as Map?) ?? const {}).entries)
        key as String: [for (final r in value as List) (r as Map).cast<String, Object?>()],
    },
  );

  final String table;
  final String id;
  final String at;
  final Map<String, Object?>? row;
  final Map<String, List<Map<String, Object?>>> children;

  bool get deleted => row == null;

  Map<String, Object?> toJson() => {'t': table, 'i': id, 'a': at, 'r': ?row, if (children.isNotEmpty) 'c': children};
}

/// What a merge did, for the sync's status and its tests.
class MergeReport {
  int written = 0;
  int deleted = 0;

  /// Changes older than what this device has (it keeps its own).
  int kept = 0;

  /// Two entries of the same day (Diário) or two check-ins of the same habit and day joined in one.
  int joined = 0;

  /// Rows left pointing to something gone, fixed (a task to the Inbox) or removed.
  int orphans = 0;
}

/// Reads this device's changes and merges the other device's into the database. The rule: each row
/// keeps its most recent version (`updated_at`), a deletion included; on the same instant, the same
/// version wins on both devices.
class SyncEngine {
  SyncEngine(this._db);

  final AppDatabase _db;
  final _columns = <String, Set<String>>{};

  Future<String> deviceId() async => (await _db.customSelect('SELECT device_id FROM sync_state WHERE id = 1').getSingle()).read<String>('device_id');

  /// The last change noted on this device.
  Future<int> lastSeq() async =>
      (await _db.customSelect('SELECT COALESCE(MAX(seq), 0) AS s FROM sync_changes').getSingle()).read<int>('s');

  Future<Set<String>> _columnsOf(String table) async => _columns[table] ??= {
    for (final r in await _db.customSelect('PRAGMA table_info($table)').get()) r.read<String>('name'),
  };

  static final _keys = {for (final (table, key) in syncedTables) table: key};

  /// This device's changes after [seq] (what the other device already confirmed), and the last one
  /// included. The device's own preferences stay here.
  Future<(List<RowChange>, int)> changesSince(int seq) => _db.transaction(() async {
    final upTo = await lastSeq();
    final lines = await _db
        .customSelect('SELECT tbl, row_id, changed_at FROM sync_changes WHERE seq > ? AND seq <= ? ORDER BY seq', variables: [Variable(seq), Variable(upTo)])
        .get();
    final changes = <RowChange>[];
    for (final line in lines) {
      final table = line.read<String>('tbl'), id = line.read<String>('row_id');
      final key = _keys[table];
      if (key == null || (table == 'preferences' && isDevicePreference(id))) continue;
      final row = await _db.customSelect('SELECT * FROM $table WHERE $key = ?', variables: [Variable(id)]).getSingleOrNull();
      if (row == null) {
        changes.add(RowChange(table: table, id: id, at: line.read<String>('changed_at')));
        continue;
      }
      changes.add(
        RowChange(
          table: table,
          id: id,
          at: row.data['updated_at']! as String,
          row: row.data,
          children: table == 'tasks' ? await _childrenOf(id) : const {},
        ),
      );
    }
    return (changes, upTo);
  });

  Future<Map<String, List<Map<String, Object?>>>> _childrenOf(String taskId) async => {
    for (final table in taskChildTables)
      table: [for (final r in await _db.customSelect('SELECT * FROM $table WHERE task_id = ?', variables: [Variable(taskId)]).get()) r.data],
  };

  /// Merges the other device's [changes]. They are written without being noted as this device's own
  /// changes (they don't travel back); the fixes made afterwards are, so both devices agree.
  Future<MergeReport> apply(List<RowChange> changes) async {
    final report = MergeReport();
    // The rows come in any order (a task before its list): the references are checked at the end.
    await _db.customStatement('PRAGMA foreign_keys = OFF');
    try {
      await _db.transaction(() async {
        await _db.customStatement('UPDATE sync_state SET applying = 1 WHERE id = 1');
        for (final change in changes) {
          if (_keys.containsKey(change.table)) await _merge(change, report);
        }
        await _joinDuplicates(report);
        await _db.customStatement('UPDATE sync_state SET applying = 0 WHERE id = 1');
        await _fixOrphans(report);
      });
    } finally {
      await _db.customStatement('PRAGMA foreign_keys = ON');
    }
    // Written by hand: the screens' queries learn of it here.
    if (report.written + report.deleted + report.joined + report.orphans > 0) _db.markTablesUpdated(_db.allTables);
    return report;
  }

  /// Positive when [a] is later than [b] (both `updated_at` texts).
  static int _compareTimes(String a, String b) => DateTime.parse(a).compareTo(DateTime.parse(b));

  Future<void> _merge(RowChange change, MergeReport report) async {
    if (change.table == 'preferences' && isDevicePreference(change.id)) return;
    final key = _keys[change.table]!;
    final local = await _db.customSelect('SELECT * FROM ${change.table} WHERE $key = ?', variables: [Variable(change.id)]).getSingleOrNull();
    final incoming = change.row;
    if (incoming == null) {
      // Deleted there: unless edited here afterwards.
      if (local == null) return;
      if (_compareTimes(local.data['updated_at']! as String, change.at) > 0) {
        report.kept++;
        return;
      }
      await _delete(change.table, key, change.id);
      report.deleted++;
      return;
    }
    if (local != null) {
      final order = _compareTimes(change.at, local.data['updated_at']! as String);
      // The same instant: the same version wins on both sides (the larger, as text).
      final wins = order > 0 || (order == 0 && jsonEncode(incoming).compareTo(jsonEncode(local.data)) > 0);
      if (!wins) {
        if (order != 0 || jsonEncode(incoming) != jsonEncode(local.data)) report.kept++;
        return;
      }
    } else {
      // Gone here: unless it was deleted here after that version.
      final gone = await _db
          .customSelect('SELECT changed_at FROM sync_changes WHERE tbl = ? AND row_id = ?', variables: [Variable(change.table), Variable(change.id)])
          .getSingleOrNull();
      if (gone != null && _compareTimes(gone.read<String>('changed_at'), change.at) > 0) {
        report.kept++;
        return;
      }
    }
    await _upsert(change.table, key, incoming);
    if (change.table == 'tasks') await _replaceChildren(change.id, change.children);
    report.written++;
  }

  /// Writes a row, with the columns this device knows (a newer app may have more).
  Future<void> _upsert(String table, String key, Map<String, Object?> row) async {
    final known = await _columnsOf(table);
    final columns = [for (final c in row.keys) if (known.contains(c)) c];
    final updates = [for (final c in columns) if (c != key) '$c = excluded.$c'];
    await _db.customStatement(
      'INSERT INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT ($key) DO ${updates.isEmpty ? 'NOTHING' : 'UPDATE SET ${updates.join(', ')}'}',
      [for (final c in columns) row[c]],
    );
  }

  Future<void> _replaceChildren(String taskId, Map<String, List<Map<String, Object?>>> children) async {
    for (final table in taskChildTables) {
      await _db.customStatement('DELETE FROM $table WHERE task_id = ?', [taskId]);
      final known = await _columnsOf(table);
      for (final row in children[table] ?? const <Map<String, Object?>>[]) {
        final columns = [for (final c in row.keys) if (known.contains(c)) c];
        await _db.customStatement(
          'INSERT OR IGNORE INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')})',
          [for (final c in columns) row[c]],
        );
      }
    }
  }

  Future<void> _delete(String table, String key, String id) async {
    if (table == 'tasks') {
      for (final child in taskChildTables) {
        await _db.customStatement('DELETE FROM $child WHERE task_id = ?', [id]);
      }
    }
    await _db.customStatement('DELETE FROM $table WHERE $key = ?', [id]);
  }

  /// Diário keeps one entry per day and a habit one check-in per day. When both devices wrote the
  /// same day, the most recent stays and takes what only the other had (the notes go below its own);
  /// the other goes to the trash. Both devices, with the same two rows, end the same.
  Future<void> _joinDuplicates(MergeReport report) async {
    final days = await _db.customSelect('SELECT day FROM journal_entries WHERE deleted_at IS NULL GROUP BY day HAVING COUNT(*) > 1').get();
    for (final d in days) {
      final rows = [
        for (final r in await _db.customSelect('SELECT * FROM journal_entries WHERE deleted_at IS NULL AND day = ?', variables: [Variable(d.data['day'])]).get()) r.data,
      ]..sort(_newestFirst);
      final keep = rows.first;
      final texts = {
        for (final r in rows)
          if ((r['notes'] as String? ?? '').trim().isNotEmpty) (r['notes']! as String).trim(),
      };
      // A text already inside another (joined before, on the other device) isn't repeated.
      final notes = [
        for (final text in texts)
          if (!texts.any((other) => other != text && other.contains(text))) text,
      ].join('\n\n');
      Object? first(String column) => rows.map((r) => r[column]).firstWhere((v) => v != null && v != '', orElse: () => keep[column]);
      await _db.customStatement('UPDATE journal_entries SET notes = ?, highlight = ?, mood = ?, energy = ? WHERE id = ?', [
        notes,
        first('highlight'),
        first('mood'),
        first('energy'),
        keep['id'],
      ]);
      for (final r in rows.skip(1)) {
        await _db.customStatement('UPDATE journal_entries SET deleted_at = ? WHERE id = ?', [keep['updated_at'], r['id']]);
        report.joined++;
      }
    }
    final checkins = await _db
        .customSelect('SELECT habit_id, day FROM habit_checkins WHERE deleted_at IS NULL GROUP BY habit_id, day HAVING COUNT(*) > 1')
        .get();
    for (final c in checkins) {
      final rows = [
        for (final r in await _db
            .customSelect(
              'SELECT * FROM habit_checkins WHERE deleted_at IS NULL AND habit_id = ? AND day = ?',
              variables: [Variable(c.data['habit_id']), Variable(c.data['day'])],
            )
            .get())
          r.data,
      ]..sort(_newestFirst);
      for (final r in rows.skip(1)) {
        await _db.customStatement('UPDATE habit_checkins SET deleted_at = ? WHERE id = ?', [rows.first['updated_at'], r['id']]);
        report.joined++;
      }
    }
  }

  /// Most recent first; on the same instant, the larger id.
  static int _newestFirst(Map<String, Object?> a, Map<String, Object?> b) {
    final order = _compareTimes(b['updated_at']! as String, a['updated_at']! as String);
    return order != 0 ? order : (b['id']! as String).compareTo(a['id']! as String);
  }

  /// Rows whose parent is gone: a task goes to the Inbox, an optional link is cleared, anything else
  /// is removed. These fixes are this device's own changes, so they travel.
  Future<void> _fixOrphans(MergeReport report) async {
    for (final problem in await _db.customSelect('PRAGMA foreign_key_check').get()) {
      final table = problem.read<String>('table'), rowid = problem.read<int>('rowid'), fk = problem.read<int>('fkid');
      final link = (await _db.customSelect('PRAGMA foreign_key_list($table)').get()).firstWhere((l) => l.read<int>('id') == fk);
      final column = link.read<String>('from');
      final nullable = (await _db.customSelect('PRAGMA table_info($table)').get()).any((c) => c.read<String>('name') == column && c.read<int>('notnull') == 0);
      if (table == 'tasks' && column == 'list_id') {
        await _db.customStatement('UPDATE tasks SET list_id = ?, section_id = NULL WHERE rowid = ?', [inboxListId, rowid]);
      } else if (nullable) {
        await _db.customStatement('UPDATE $table SET $column = NULL WHERE rowid = ?', [rowid]);
      } else {
        await _db.customStatement('DELETE FROM $table WHERE rowid = ?', [rowid]);
      }
      report.orphans++;
    }
  }
}
