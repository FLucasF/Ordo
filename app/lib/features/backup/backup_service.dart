import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../data/attachment_store.dart';
import '../../data/db/database.dart';

/// Thrown when a file is not a backup of this app.
class InvalidBackup implements Exception {
  const InvalidBackup(this.reason);
  final String reason;
  @override
  String toString() => 'InvalidBackup: $reason';
}

/// Backup = zip with the SQLite database and the attachment files (Fase 1).
class BackupService {
  BackupService(this._db, {required this.tempDir, this.attachments, this.folders = const {}});

  final AppDatabase _db;
  final Directory tempDir;
  final AttachmentStore? attachments;

  /// Other folders that go in the backup, by their prefix in the zip (countdown pictures, downloaded
  /// calendars, background pictures). Importing replaces their files.
  final Map<String, Directory> folders;

  static const _attachmentsPrefix = 'attachments/';

  static const _dbEntry = 'tasks.sqlite';
  static const _manifestEntry = 'manifest.txt';

  /// A consistent copy of the database (`VACUUM INTO`) zipped with a small manifest.
  /// [withFiles] false leaves the attachments and the other folders out (the daily automatic
  /// backups); restoring such a backup keeps the files that are there.
  Future<Uint8List> export({bool withFiles = true}) async {
    final copy = File(p.join(tempDir.path, 'backup_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    try {
      await _db.customStatement('VACUUM INTO ?', [copy.path]);
      final bytes = await copy.readAsBytes();
      final archive = Archive()
        ..addFile(ArchiveFile.bytes(_dbEntry, bytes))
        ..addFile(ArchiveFile.string(_manifestEntry, 'app=tarefas\nschema=${_db.schemaVersion}\n${withFiles ? '' : 'files=0\n'}'));
      if (!withFiles) return Uint8List.fromList(ZipEncoder().encode(archive));
      for (final (reference, file) in attachments?.all() ?? const <(String, File)>[]) {
        archive.addFile(ArchiveFile.bytes('$_attachmentsPrefix$reference', await file.readAsBytes()));
      }
      for (final MapEntry(key: prefix, value: dir) in folders.entries) {
        if (!dir.existsSync()) continue;
        for (final file in dir.listSync().whereType<File>()) {
          archive.addFile(ArchiveFile.bytes('$prefix${p.basename(file.path)}', await file.readAsBytes()));
        }
      }
      return Uint8List.fromList(ZipEncoder().encode(archive));
    } finally {
      if (copy.existsSync()) await copy.delete();
    }
  }

  /// Replaces every row of the current database with the backup's rows, in one transaction.
  Future<void> import(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final manifest = archive.findFile(_manifestEntry);
    final dbFile = archive.findFile(_dbEntry);
    if (manifest == null || dbFile == null) throw const InvalidBackup('missing entries');
    final manifestText = String.fromCharCodes(manifest.content);
    final schema = RegExp(r'schema=(\d+)').firstMatch(manifestText)?.group(1);
    final withFiles = !manifestText.contains('files=0');
    if (schema == null || int.parse(schema) > _db.schemaVersion) throw const InvalidBackup('newer or unknown schema');

    final file = File(p.join(tempDir.path, 'import_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    await file.writeAsBytes(dbFile.content);
    final source = AppDatabase(NativeDatabase(file));
    try {
      final folders = await source.select(source.folders).get();
      final lists = await source.select(source.lists).get();
      final sections = await source.select(source.sections).get();
      final tasks = await source.select(source.tasks).get();
      final items = await source.select(source.checklistItems).get();
      final tags = await source.select(source.tags).get();
      final taskTags = await source.select(source.taskTags).get();
      final prefs = await source.select(source.preferences).get();
      final reminders = await source.select(source.taskReminders).get();
      final templates = await source.select(source.templates).get();
      final comments = await source.select(source.comments).get();
      final countdowns = await source.select(source.countdowns).get();
      final focusRecords = await source.select(source.focusRecords).get();
      final habits = await source.select(source.habits).get();
      final habitCheckins = await source.select(source.habitCheckins).get();
      final filters = await source.select(source.filters).get();
      final activities = await source.select(source.activities).get();
      final finCategories = await source.select(source.finCategories).get();
      final finCards = await source.select(source.finCards).get();
      final finRecurrings = await source.select(source.finRecurrings).get();
      final finEntries = await source.select(source.finEntries).get();
      final finCardPayments = await source.select(source.finCardPayments).get();
      final loans = await source.select(source.loans).get();
      final loanPayments = await source.select(source.loanPayments).get();
      final finGoals = await source.select(source.finGoals).get();
      final finGoalMoves = await source.select(source.finGoalMoves).get();
      final dietFoods = await source.select(source.dietFoods).get();
      final dietEntries = await source.select(source.dietEntries).get();
      final dietMeals = await source.select(source.dietMeals).get();
      final dietFoodMeasures = await source.select(source.dietFoodMeasures).get();
      final dietPlanItems = await source.select(source.dietPlanItems).get();
      final journalEntries = await source.select(source.journalEntries).get();
      await _db.transaction(() async {
        // Children first, then parents (foreign keys).
        for (final table in <TableInfo<Table, Object?>>[
          _db.activities,
          _db.filters,
          _db.habitCheckins,
          _db.habits,
          _db.comments,
          _db.taskReminders,
          _db.taskTags,
          _db.checklistItems,
          _db.tasks,
          _db.sections,
          _db.tags,
          _db.lists,
          _db.folders,
          _db.preferences,
          _db.templates,
          _db.countdowns,
          _db.focusRecords,
          _db.loanPayments,
          _db.loans,
          _db.finGoalMoves,
          _db.finGoals,
          _db.finCardPayments,
          _db.finEntries,
          _db.finRecurrings,
          _db.finCards,
          _db.finCategories,
          _db.dietEntries,
          _db.dietFoods,
          _db.dietMeals,
          _db.dietFoodMeasures,
          _db.dietPlanItems,
          _db.journalEntries,
        ]) {
          await _db.delete(table).go();
        }
        await _db.batch((b) {
          b.insertAll(_db.folders, folders);
          // Sublists point at their parent list (schema v20).
          b.insertAll(_db.lists, _parentsFirst(lists, (l) => l.id, (l) => l.parentId));
          b.insertAll(_db.sections, sections);
          b.insertAll(_db.tags, _parentsFirst(tags, (t) => t.id, (t) => t.parentId));
          b.insertAll(_db.tasks, _parentsFirst(tasks, (t) => t.id, (t) => t.parentId));
          b.insertAll(_db.checklistItems, items);
          b.insertAll(_db.taskTags, taskTags);
          b.insertAll(_db.preferences, prefs);
          b.insertAll(_db.taskReminders, reminders);
          b.insertAll(_db.templates, templates);
          b.insertAll(_db.comments, comments);
          b.insertAll(_db.countdowns, countdowns);
          b.insertAll(_db.focusRecords, focusRecords);
          b.insertAll(_db.habits, habits);
          b.insertAll(_db.habitCheckins, habitCheckins);
          b.insertAll(_db.filters, filters);
          b.insertAll(_db.activities, activities);
          b.insertAll(_db.finCategories, finCategories);
          b.insertAll(_db.finCards, finCards);
          b.insertAll(_db.finRecurrings, finRecurrings);
          b.insertAll(_db.finEntries, finEntries);
          b.insertAll(_db.finCardPayments, finCardPayments);
          b.insertAll(_db.loans, loans);
          b.insertAll(_db.loanPayments, loanPayments);
          b.insertAll(_db.finGoals, finGoals);
          b.insertAll(_db.finGoalMoves, finGoalMoves);
          b.insertAll(_db.dietFoods, dietFoods);
          b.insertAll(_db.dietEntries, dietEntries);
          b.insertAll(_db.dietMeals, dietMeals);
          b.insertAll(_db.dietFoodMeasures, dietFoodMeasures);
          b.insertAll(_db.dietPlanItems, dietPlanItems);
          b.insertAll(_db.journalEntries, journalEntries);
        });
      });
    } finally {
      await source.close();
      if (file.existsSync()) await file.delete();
    }
    // A backup without files (automatic) keeps the current ones.
    if (!withFiles) return;
    // The backup's attachments replace the current ones.
    final store = attachments;
    if (store != null) {
      await store.clear();
      for (final entry in archive.files.where((f) => f.isFile && f.name.startsWith(_attachmentsPrefix))) {
        await store.restore(entry.name.substring(_attachmentsPrefix.length), entry.content);
      }
    }
    for (final MapEntry(key: prefix, value: dir) in folders.entries) {
      if (dir.existsSync()) {
        for (final file in dir.listSync().whereType<File>()) {
          await file.delete();
        }
      }
      for (final entry in archive.files.where((f) => f.isFile && f.name.startsWith(prefix))) {
        final name = p.basename(entry.name.substring(prefix.length));
        if (name.isEmpty) continue;
        await dir.create(recursive: true);
        await File(p.join(dir.path, name)).writeAsBytes(entry.content);
      }
    }
  }

  /// Orders self-referencing rows so a parent is always inserted before its children.
  static List<T> _parentsFirst<T>(List<T> rows, String Function(T) id, String? Function(T) parent) {
    final byId = {for (final r in rows) id(r): r};
    final done = <String>{};
    final result = <T>[];
    void visit(T r) {
      if (done.contains(id(r))) return;
      final pid = parent(r);
      if (pid != null && byId[pid] != null) visit(byId[pid] as T);
      done.add(id(r));
      result.add(r);
    }

    rows.forEach(visit);
    return result;
  }
}
