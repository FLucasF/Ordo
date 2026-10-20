import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/attachment_store.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/journal_repository.dart';
import 'package:task_manager/features/backup/backup_service.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 10, 20, 21));
  late AppDatabase db;
  late JournalRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = JournalRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  test('one entry per day, written field by field; the day is stored at UTC midnight', () async {
    final day = DateTime(2026, 10, 20, 23, 30);
    await Future.wait([repo.setMood(day, 4), repo.setEnergy(day, 2), repo.setHighlight(day, 'O café com a Ana')]);
    await repo.setNotes(DateTime(2026, 10, 20), '# Dia\n\nchoveu');
    final s = await repo.load();
    final e = s.entries.single;
    expect(e.day, DateTime.utc(2026, 10, 20));
    expect((e.mood, e.energy, e.highlight, e.notes), (4, 2, 'O café com a Ana', '# Dia\n\nchoveu'));
    expect(s.on(DateTime(2026, 10, 20, 8))?.id, e.id);
    expect(s.on(DateTime(2026, 10, 21)), isNull);

    await repo.setMood(day, null);
    expect((await repo.load()).entries.single.mood, isNull);
  });

  test('delete is soft and undone; writing again on a deleted day starts it empty', () async {
    final day = DateTime(2026, 10, 19);
    await repo.setMood(day, 5);
    await repo.setNotes(day, 'antes');
    final id = (await repo.load()).entries.single.id;
    await repo.delete(id);
    expect((await repo.load()).entries, isEmpty);
    await repo.delete(id, restore: true);
    expect((await repo.load()).entries.single.mood, 5);

    await repo.delete(id);
    await repo.setHighlight(day, 'recomeço');
    final e = (await repo.load()).entries.single;
    expect(e.id, id);
    expect((e.mood, e.notes, e.highlight), (null, '', 'recomeço'));
  });

  test("Dieta's calorie target is read defensively from the diet.targets preference", () async {
    Future<void> put(String value) => db
        .into(db.preferences)
        .insertOnConflictUpdate(PreferencesCompanion(name: const Value('diet.targets'), value: Value(value), updatedAt: Value(DateTime.utc(2026))));
    expect(await repo.watchCalorieTarget().first, isNull);
    await put('{"kcal": 2100, "protein": 120}');
    expect(await repo.watchCalorieTarget().first, 2100);
    await put('not json');
    expect(await repo.watchCalorieTarget().first, isNull);
  });

  test('a backup carries the journal; import replaces it', () async {
    final temp = Directory.systemTemp.createTempSync('tarefas_journal_');
    addTearDown(() => temp.deleteSync(recursive: true));
    await repo.setMood(DateTime(2026, 10, 18), 3);
    await repo.setNotes(DateTime(2026, 10, 18), 'Uma nota');
    await repo.setHighlight(DateTime(2026, 10, 19), 'Gratidão');
    final bytes = await BackupService(db, tempDir: temp, attachments: AttachmentStore(Directory(p.join(temp.path, 'a')))).export(withFiles: false);

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    final other = JournalRepository(target, clock: clock);
    await other.setNotes(DateTime(2026, 1, 1), 'some');
    await BackupService(target, tempDir: temp, attachments: AttachmentStore(Directory(p.join(temp.path, 'b')))).import(bytes);
    final s = await other.load();
    expect(
      [for (final e in s.entries) (e.day, e.mood, e.notes, e.highlight)],
      [(DateTime.utc(2026, 10, 18), 3, 'Uma nota', ''), (DateTime.utc(2026, 10, 19), null, '', 'Gratidão')],
    );
  });
}
