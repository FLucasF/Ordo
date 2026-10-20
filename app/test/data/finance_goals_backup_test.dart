import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/attachment_store.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/features/backup/backup_service.dart';

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('tarefas_test_'));
  tearDown(() => temp.deleteSync(recursive: true));

  test('a backup carries the Caixinhas, their moves and the loans in installments', () async {
    final clock = FixedClock(DateTime(2026, 9, 25));
    final source = AppDatabase(NativeDatabase.memory());
    final a = FinanceRepository(source, clock: clock);
    final trip = await a.createGoal(name: 'Viagem', target: 500000, icon: '✈️', color: '#4CA1FF', dueOn: DateTime(2027, 6, 1), note: 'Japão');
    await a.addGoalMove(goalId: trip, amount: 50000, date: DateTime(2026, 9, 6));
    await a.addGoalMove(goalId: trip, amount: -10000, date: DateTime(2026, 9, 7), note: 'passagem');
    final old = await a.createGoal(name: 'Antiga', target: 1000);
    await a.archiveGoal(old, archived: true);
    await a.createLoan(
      borrower: 'João',
      principal: 100000,
      total: 135000,
      lentOn: DateTime(2026, 9, 1),
      dueOn: DateTime(2026, 10, 1),
      installments: 3,
      installmentAmount: 45000,
    );
    final bytes = await BackupService(
      source,
      tempDir: temp,
      attachments: AttachmentStore(Directory(p.join(temp.path, 'a'))),
    ).export(withFiles: false);
    await source.close();

    final target = AppDatabase(NativeDatabase.memory());
    final b = FinanceRepository(target, clock: clock);
    // Something already there is replaced.
    await b.createGoal(name: 'Some', target: 1);
    await BackupService(target, tempDir: temp, attachments: AttachmentStore(Directory(p.join(temp.path, 'b')))).import(bytes);
    final s = await b.load();
    expect(s.goals.map((g) => g.name), ['Viagem', 'Antiga']);
    final goal = s.goals.first;
    expect((goal.icon, goal.color, goal.target, goal.note, goal.dueOn), ('✈️', '#4CA1FF', 500000, 'Japão', DateTime.utc(2027, 6, 1)));
    expect(s.goals.last.archivedAt, isNotNull);
    expect(s.goalMoves.map((m) => m.amount).toSet(), {50000, -10000});
    expect(s.goalMoves.every((m) => m.goalId == trip), isTrue);
    final loan = s.loans.single;
    expect((loan.installments, loan.installmentAmount), (3, 45000));
    await target.close();
  });
}
