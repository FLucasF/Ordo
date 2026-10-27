import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/journal_repository.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/sync/sync_engine.dart';

/// A clock the test moves forward.
class _Clock implements Clock {
  _Clock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

/// One device: its database, repositories and sync engine, and how far the other device got.
class _Device {
  _Device(this.clock) : db = AppDatabase(NativeDatabase.memory()) {
    repo = Repository(db, clock: clock);
    engine = SyncEngine(db);
  }

  final _Clock clock;
  final AppDatabase db;
  late final Repository repo;
  late final SyncEngine engine;

  /// The last of this device's changes the other one has.
  int sent = 0;

  Future<Set<String>> taskTitles() async => {for (final t in (await repo.loadSnapshot()).tasks) if (t.deletedAt == null) t.title};
}

void main() {
  late _Clock clock;
  late _Device pc, phone;

  setUp(() {
    // Now: the database's triggers date a deletion with the real clock.
    clock = _Clock(DateTime.now().toUtc());
    pc = _Device(clock);
    phone = _Device(clock);
  });
  tearDown(() async {
    await pc.db.close();
    await phone.db.close();
  });

  /// [from]'s changes go to [to].
  Future<MergeReport> send(_Device from, _Device to) async {
    final (changes, upTo) = await from.engine.changesSince(from.sent);
    final report = await to.engine.apply(changes);
    from.sent = upTo;
    return report;
  }

  Future<void> sync() async {
    await send(pc, phone);
    await send(phone, pc);
  }

  void later([int seconds = 5]) => clock.value = clock.value.add(Duration(seconds: seconds));

  test('a task made on one device, with its tags and reminders, reaches the other; nothing travels back', () async {
    final tag = await pc.repo.createTag('trabalho');
    final id = await pc.repo.createTask(listId: inboxListId, title: 'Relatório');
    await pc.repo.setTaskTags(id, {tag});
    await pc.repo.setReminders(id, {'0m'});
    await sync();
    final s = await phone.repo.loadSnapshot();
    expect(s.tasks.singleWhere((t) => t.id == id).title, 'Relatório');
    expect([for (final t in s.tagsOf(id)) t.name], ['trabalho']);
    final reminders = await phone.db.customSelect('SELECT "trigger" FROM task_reminders WHERE task_id = ?', variables: [Variable(id)]).get();
    expect([for (final r in reminders) r.read<String>('trigger')], ['0m']);
    // What the phone got isn't its own change: a second round sends nothing back.
    final (back, _) = await phone.engine.changesSince(phone.sent);
    expect(back.where((c) => c.id == id), isEmpty);
  });

  test('the same task edited on both: the most recent edit wins on both devices', () async {
    final id = await pc.repo.createTask(listId: inboxListId, title: 'A');
    await sync();
    later();
    await pc.repo.setTitle(id, 'Do PC');
    later();
    await phone.repo.setTitle(id, 'Do celular');
    await sync();
    expect(await pc.taskTitles(), {'Do celular'});
    expect(await phone.taskTitles(), {'Do celular'});
  });

  test('deleted for good on one device goes on the other, unless edited there afterwards', () async {
    final gone = await pc.repo.createTask(listId: inboxListId, title: 'Some');
    final kept = await pc.repo.createTask(listId: inboxListId, title: 'Fica');
    await sync();
    later();
    for (final id in [gone, kept]) {
      await pc.repo.delete(id);
      await pc.repo.deleteForever(id);
    }
    later();
    // Edited on the phone after the PC deleted it.
    await phone.repo.setTitle(kept, 'Fica, editada');
    await sync();
    expect(await phone.taskTitles(), {'Fica, editada'});
    // The edit, newer, brings it back to the PC.
    await sync();
    expect(await pc.taskTitles(), {'Fica, editada'});
  });

  test('two entries of the same day in Diário become one, with both notes, on both devices', () async {
    final day = DateTime(clock.value.year, clock.value.month, clock.value.day);
    await JournalRepository(pc.db, clock: clock).setNotes(day, 'Corri no parque');
    later();
    await JournalRepository(phone.db, clock: clock).setNotes(day, 'Li dez páginas');
    await sync();
    for (final device in [pc, phone]) {
      final entry = (await JournalRepository(device.db, clock: clock).load()).on(day)!;
      expect(entry.notes, 'Li dez páginas\n\nCorri no parque');
    }
  });

  test('device preferences stay; the others travel', () async {
    final prefs = PreferencesRepository(pc.db, clock: clock);
    await prefs.setMiniCalendar(enabled: true);
    await prefs.setHabitsInToday(enabled: false);
    await sync();
    final names = {for (final r in await phone.db.customSelect('SELECT name FROM preferences').get()) r.read<String>('name')};
    expect(names, contains('habits.inToday'));
    expect(names, isNot(contains('more.miniCalendar')));
  });

  test('a task left in a list deleted on the other device goes to the Inbox', () async {
    final list = await pc.repo.createList(name: 'Viagem');
    await sync();
    final id = await phone.repo.createTask(listId: list, title: 'Passaporte');
    later();
    await pc.db.customStatement('DELETE FROM lists WHERE id = ?', [list]);
    final report = await send(pc, phone);
    expect(report.orphans, 1);
    final task = (await phone.repo.loadSnapshot()).tasks.singleWhere((t) => t.id == id);
    expect(task.listId, inboxListId);
    // The fix is the phone's own change: the PC gets the task in its Inbox.
    await send(phone, pc);
    expect((await pc.repo.loadSnapshot()).tasks.singleWhere((t) => t.id == id).listId, inboxListId);
  });

  test('both devices end with all of each other\'s work', () async {
    for (var i = 0; i < 5; i++) {
      await pc.repo.createTask(listId: inboxListId, title: 'PC $i');
      await phone.repo.createTask(listId: inboxListId, title: 'Celular $i');
      later(1);
    }
    await sync();
    final expected = {for (var i = 0; i < 5; i++) ...{'PC $i', 'Celular $i'}};
    expect(await pc.taskTitles(), expected);
    expect(await phone.taskTitles(), expected);
  });
}
