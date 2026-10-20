import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/domain/finance/finance.dart';
import 'package:task_manager/domain/finance/finance_calendar.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/finance/finance_reminders.dart';
import 'package:task_manager/domain/finance/goals.dart';
import 'package:task_manager/domain/finance/loans.dart';
import 'package:task_manager/domain/finance/reports.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  // Friday, 2026-09-25.
  final today = DateTime(2026, 9, 25);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FinanceRepository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
  });
  tearDown(() => db.close());

  Future<LoanSummary> loan(String id, [DateTime? day]) async => loanSummaries(await repo.load(), day ?? today).firstWhere((l) => l.loan.id == id);

  String schedule(LoanSummary l) =>
      [for (final i in l.installments) '${i.number}:${i.due.month}/${i.due.day}:${i.amount}:${i.paid}:${i.status.name}'].join(' ');

  group('loans in installments', () {
    test('the total split evenly, monthly from the due day; payments go in order, early ones lower the next', () async {
      final id = await repo.createLoan(
        borrower: 'João',
        principal: 100000,
        total: 130000,
        lentOn: DateTime(2026, 8, 1),
        dueOn: DateTime(2026, 8, 31),
        installments: 3,
      );
      var l = await loan(id);
      // 31 of August, then the last days of the shorter months.
      expect(schedule(l), '1:8/31:43334:0:overdue 2:9/30:43333:0:open 3:10/31:43333:0:open');
      expect((l.status, l.daysLate, l.overdueAmount, l.nextDue), (LoanStatus.overdue, 25, 43334, DateTime(2026, 8, 31)));

      // Part of the first: still late, with what is left.
      await repo.addLoanPayment(loanId: id, amount: 30000, date: DateTime(2026, 9, 1));
      l = await loan(id);
      expect((l.installments.first.paid, l.installments.first.open, l.status), (30000, 13334, LoanStatus.overdue));
      // More than the rest of the first: the extra lowers the second.
      await repo.addLoanPayment(loanId: id, amount: 20000, date: DateTime(2026, 9, 20));
      l = await loan(id);
      expect(schedule(l), '1:8/31:43334:43334:paid 2:9/30:43333:6666:open 3:10/31:43333:0:open');
      expect(l.installments.first.paidOn, DateTime(2026, 9, 20));
      expect((l.status, l.next!.number, l.next!.open, l.nextDue), (LoanStatus.onTime, 2, 36667, DateTime(2026, 9, 30)));
      // The second is late after its day; the third not yet.
      l = await loan(id, DateTime(2026, 10, 2));
      expect((l.status, l.daysLate, l.overdueAmount), (LoanStatus.overdue, 2, 36667));

      // Paid off early.
      await repo.addLoanPayment(loanId: id, amount: 80000, date: DateTime(2026, 9, 25));
      l = await loan(id);
      expect(l.installments.every((i) => i.status == InstallmentStatus.paid), isTrue);
      expect((l.status, l.balance, l.nextDue), (LoanStatus.paid, 0, DateTime(2026, 10, 31)));
    });

    test('a typed installment: each of it, the last one takes what is left; at once is one installment', () async {
      final each = await repo.createLoan(
        borrower: 'Ana',
        principal: 100000,
        total: 120000,
        lentOn: DateTime(2026, 9, 1),
        dueOn: DateTime(2026, 10, 10),
        installments: 4,
        installmentAmount: 30000,
      );
      expect([for (final i in (await loan(each)).installments) i.amount], [30000, 30000, 30000, 30000]);
      // A total that doesn't match (edited later): it still adds up to the total.
      final uneven = await repo.createLoan(
        borrower: 'Bia',
        principal: 50000,
        total: 70000,
        lentOn: DateTime(2026, 9, 1),
        dueOn: DateTime(2026, 10, 10),
        installments: 3,
        installmentAmount: 30000,
      );
      expect([for (final i in (await loan(uneven)).installments) i.amount], [30000, 30000, 10000]);
      final once = await repo.createLoan(
        borrower: 'Caio',
        principal: 50000,
        total: 60000,
        lentOn: DateTime(2026, 9, 1),
        dueOn: DateTime(2026, 10, 10),
        installmentAmount: 1000,
      );
      final l = await loan(once);
      expect(schedule(l), '1:10/10:60000:0:open');
      expect(l.loan.installmentAmount, isNull);
    });

    test('the profit stays proportional: the months add up to the profit received, installments or not', () async {
      final id = await repo.createLoan(
        borrower: 'João',
        principal: 90000,
        total: 120000,
        lentOn: DateTime(2026, 6, 1),
        dueOn: DateTime(2026, 7, 1),
        installments: 3,
      );
      await repo.addLoanPayment(loanId: id, amount: 40000, date: DateTime(2026, 7, 1));
      await repo.addLoanPayment(loanId: id, amount: 40000, date: DateTime(2026, 8, 3));
      await repo.addLoanPayment(loanId: id, amount: 40000, date: DateTime(2026, 9, 1));
      final s = await repo.load();
      final months = loanInterestByMonth(s);
      // A quarter of each payment is profit.
      expect(months, {DateTime(2026, 7): 10000, DateTime(2026, 8): 10000, DateTime(2026, 9): 10000});
      final l = loanSummaries(s, today).single;
      expect((l.interestReceived, l.status), (30000, LoanStatus.paid));
      expect(monthlyFlows(s, DateTime(2026, 9), 3).map((m) => m.interest), [10000, 10000, 10000]);
    });

    test('the overview counts as late only the installments past their day', () async {
      await repo.createLoan(
        borrower: 'João',
        principal: 100000,
        total: 120000,
        lentOn: DateTime(2026, 8, 1),
        dueOn: DateTime(2026, 9, 10),
        installments: 4,
      );
      final o = loansOverview(loanSummaries(await repo.load(), today));
      expect((o.toReceive, o.overdue, o.overdueCount), (120000, 30000, 1));
    });

    test('loans by due month: by the next installment', () async {
      final a = await repo.createLoan(
        borrower: 'Ana',
        principal: 30000,
        total: 30000,
        lentOn: DateTime(2026, 8, 1),
        dueOn: DateTime(2026, 9, 5),
        installments: 3,
      );
      await repo.addLoanPayment(loanId: a, amount: 10000, date: DateTime(2026, 9, 5));
      await repo.createLoan(borrower: 'Beto', principal: 1000, total: 1000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 10, 20));
      final groups = loansByMonth(loanSummaries(await repo.load(), today), byDue: true);
      expect([for (final g in groups) '${g.month.month}:${g.loans.map((l) => l.loan.borrower).join(',')}'], ['10:Ana,Beto']);
    });

    test('the calendar and the reminders show each installment', () async {
      final id = await repo.createLoan(
        borrower: 'João',
        principal: 90000,
        total: 90000,
        lentOn: DateTime(2026, 9, 1),
        dueOn: DateTime(2026, 9, 20),
        installments: 3,
      );
      await repo.addLoanPayment(loanId: id, amount: 30000, date: DateTime(2026, 9, 20));
      final s = await repo.load();
      final dues = financeDues(s, DateTime(2026, 9), DateTime(2027), today).where((d) => d.kind == FinanceDueKind.loan).toList();
      expect(
        [for (final d in dues) '${d.day.month}/${d.day.day} ${d.installment}/${d.installments} ${d.amount} ${d.done}'],
        ['9/20 1/3 30000 true', '10/20 2/3 30000 false', '11/20 3/3 30000 false'],
      );

      final reminders = planFinanceReminders(
        s,
        DateTime(2026, 9, 25, 10),
        title: (a) => '${a.kind.name} ${a.name} ${a.installment}/${a.installments}',
        body: (a) => '${a.amount}',
      );
      // The paid one says nothing; the next two on their day, then while late.
      expect(reminders.where((r) => r.title.startsWith('loanDue')).map((r) => (r.at, r.title)), [
        (DateTime(2026, 10, 20, 9), 'loanDue João 2/3'),
        (DateTime(2026, 11, 20, 9), 'loanDue João 3/3'),
      ]);
      expect(reminders.where((r) => r.title == 'loanLate João 2/3').first.at, DateTime(2026, 10, 21, 9));
      expect(reminders.map((r) => r.id).toSet(), hasLength(reminders.length));
    });

    test('paid at once keeps the reminders of before', () async {
      await repo.createLoan(borrower: 'Ana', principal: 1000, total: 1000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 10, 1));
      final r = planFinanceReminders(await repo.load(), DateTime(2026, 9, 25, 10), title: (a) => '${a.installment}', body: (a) => '${a.amount}');
      expect(r.first.at, DateTime(2026, 10, 1, 9));
      expect(r.first.title, 'null');
    });
  });

  group('goals', () {
    test('saved, left, progress and how much a month to get there', () {
      final now = DateTime(2026, 9, 25);
      FinGoal goal(int target, DateTime? due) => FinGoal(
        id: 'g',
        createdAt: now,
        updatedAt: now,
        name: 'Viagem',
        target: target,
        dueOn: due == null ? null : storedDay(due),
        note: '',
        sortOrder: 0,
      );
      FinGoalMove move(int amount) =>
          FinGoalMove(id: '$amount', createdAt: now, updatedAt: now, goalId: 'g', amount: amount, date: storedDay(now), note: '');

      var g = GoalSummary(goal: goal(100000, DateTime(2026, 12, 31)), moves: [move(30000), move(-5000)], today: now);
      expect((g.saved, g.left, g.progress, g.reached), (25000, 75000, 0.25, false));
      // Sep 25, Oct 25, Nov 25 and Dec 25: 4 deposits.
      expect((g.monthsLeft, g.perMonth), (4, 18750));
      g = GoalSummary(goal: goal(100000, null), moves: [move(120000)], today: now);
      expect((g.left, g.progress, g.reached, g.perMonth), (0, 1.0, true, null));
      g = GoalSummary(goal: goal(100000, DateTime(2026, 9, 1)), moves: const [], today: now);
      expect((g.pastDue, g.monthsLeft, g.perMonth, g.progress), (true, 0, 100000, 0.0));
      // Rounded up to the cent.
      g = GoalSummary(goal: goal(10000, DateTime(2026, 11, 25)), moves: const [], today: now);
      expect(g.perMonth, 3334);
    });

    test('deposits until a day', () {
      expect(depositsUntil(DateTime(2026, 10, 20), DateTime(2026, 12, 31)), 3);
      expect(depositsUntil(DateTime(2026, 10, 20), DateTime(2026, 11, 15)), 1);
      expect(depositsUntil(DateTime(2026, 10, 20), DateTime(2026, 10, 20)), 1);
      expect(depositsUntil(DateTime(2026, 10, 20), DateTime(2026, 10, 19)), 0);
      // The 31st: February's deposit is on its last day.
      expect(depositsUntil(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 2);
    });

    test('moves are transfers: not in the month totals; the reports keep them apart; archive and delete with undo', () async {
      final trip = await repo.createGoal(name: 'Viagem', target: 500000, icon: '✈️', color: '#4CA1FF', dueOn: DateTime(2027, 6, 1));
      final car = await repo.createGoal(name: 'Carro', target: 3000000);
      await repo.addEntry(kind: FinKind.income, amount: 300000, date: DateTime(2026, 9, 5));
      await repo.addGoalMove(goalId: trip, amount: 50000, date: DateTime(2026, 9, 6));
      final out = await repo.addGoalMove(goalId: trip, amount: -10000, date: DateTime(2026, 9, 7), note: 'passagem');
      await repo.addGoalMove(goalId: car, amount: 20000, date: DateTime(2026, 8, 6));
      var s = await repo.load();
      expect(totalsOf(entriesOfMonth(s, DateTime(2026, 9))).balance, 300000);
      expect(monthlyFlows(s, DateTime(2026, 9), 1).single.totals.balance, 300000);
      expect(goalsSaved(s, DateTime(2026, 9)), (total: 60000, inMonth: 40000));
      final goals = goalSummaries(s, today);
      expect([for (final g in goals) '${g.goal.name}:${g.saved}'], ['Viagem:40000', 'Carro:20000']);
      expect(goals.first.moves.first.note, 'passagem');

      // The history shows the moves on their days, apart from the entries.
      final groups = groupEntries(s, s.entries, moves: s.goalMoves);
      expect(
        [for (final g in groups) '${g.day.month}/${g.day.day}:${g.entries.length}:${g.moves.length}'],
        ['9/7:0:1', '9/6:0:1', '9/5:1:0', '8/6:0:1'],
      );

      await repo.updateGoalMove(out, amount: -20000, date: DateTime(2026, 9, 7));
      await repo.archiveGoal(car, archived: true);
      s = await repo.load();
      expect(goalSummaries(s, today).single.saved, 30000);
      expect(goalSummaries(s, today, archived: true).single.goal.name, 'Carro');
      // Archived money is still set aside.
      expect(goalsSaved(s, DateTime(2026, 9)).total, 50000);

      await repo.deleteGoalMove(out);
      s = await repo.load();
      expect(goalSummaries(s, today).single.saved, 50000);
      await repo.deleteGoalMove(out, restore: true);
      await repo.deleteGoal(trip);
      s = await repo.load();
      expect(s.goals.map((g) => g.name), ['Carro']);
      expect(s.goalMoves.where((m) => m.goalId == trip), isEmpty);
      await repo.restoreGoal(trip);
      s = await repo.load();
      expect(goalSummaries(s, today).single.saved, 30000);
      await repo.updateGoal(trip, name: 'Japão', target: 800000, icon: '', color: null, dueOn: null, note: 'ida e volta');
      s = await repo.load();
      final japan = s.goals.firstWhere((g) => g.id == trip);
      expect((japan.name, japan.target, japan.icon, japan.dueOn, japan.note), ('Japão', 800000, null, null, 'ida e volta'));
    });
  });
}
