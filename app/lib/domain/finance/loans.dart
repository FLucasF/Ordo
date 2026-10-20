import '../../data/db/database.dart';
import 'finance.dart';
import 'money.dart';

/// "Em dia", "Atrasado" (an installment past its day with something left) or "Quitado".
enum LoanStatus { onTime, overdue, paid }

/// A loan with its payments: what came back, what is left and the profit.
class LoanSummary {
  LoanSummary({required this.loan, required this.payments, required DateTime today})
    : received = payments.fold(0, (sum, p) => sum + p.amount),
      _today = DateTime(today.year, today.month, today.day);

  final Loan loan;

  /// Newest first.
  final List<LoanPayment> payments;
  final int received;
  final DateTime _today;

  /// The profit agreed: what comes back minus what was lent.
  int get interest => loan.total - loan.principal;

  /// The rate agreed, in hundredths of a percent (1000 = 10%).
  int get rate => loan.principal == 0 ? 0 : (interest * 10000 / loan.principal).round();

  int get balance => loan.total - received < 0 ? 0 : loan.total - received;

  /// The profit already in hand. Each payment is part loan, part profit, in the same proportion as
  /// the total (R$ 130 of a R$ 1.300 loan of R$ 1.000 brings R$ 30 of profit); what comes beyond
  /// the total is all profit.
  int get interestReceived => interestIn(loan, received);

  /// The installments (one, on the due day, when paid at once) with what each has received.
  late final List<LoanInstallment> installments = loanSchedule(loan, payments, _today);

  /// Overdue when an installment is past its day with something left.
  LoanStatus get status => balance <= 0
      ? LoanStatus.paid
      : installments.any((i) => i.status == InstallmentStatus.overdue)
      ? LoanStatus.overdue
      : LoanStatus.onTime;

  /// Days past the oldest overdue installment's day (0 when not overdue).
  int get daysLate => switch (installments.where((i) => i.status == InstallmentStatus.overdue).firstOrNull) {
    final i? => _today.difference(i.due).inDays,
    null => 0,
  };

  /// What is left of the installments already past their day.
  int get overdueAmount => installments.where((i) => i.status == InstallmentStatus.overdue).fold(0, (sum, i) => sum + i.open);

  /// The first installment not fully paid ("Receber parcela"); null when paid off.
  LoanInstallment? get next => installments.where((i) => i.status != InstallmentStatus.paid).firstOrNull;

  /// The day that matters now: the next installment's, or the last one's when paid off.
  DateTime get nextDue => next?.due ?? installments.lastOrNull?.due ?? finDay(loan.dueOn);
}

/// An installment "Paga", "Em aberto" (its day not past yet, perhaps partly paid) or "Atrasada".
enum InstallmentStatus { paid, open, overdue }

/// One installment of a loan: its [number] of [count], day and amount, and how much of it the
/// payments cover.
class LoanInstallment {
  const LoanInstallment({
    required this.number,
    required this.count,
    required this.due,
    required this.amount,
    required this.paid,
    required this.status,
    this.paidOn,
  });

  final int number;
  final int count;
  final DateTime due;
  final int amount;
  final int paid;
  final InstallmentStatus status;

  /// The day of the payment that completed it.
  final DateTime? paidOn;

  int get open => amount - paid;
}

/// The amounts of [loan]'s installments, adding up to its total: [Loan.installmentAmount] each when
/// set (the last one takes what is left over), else the total split evenly. Empty installments (a
/// total smaller than the agreed ones) are left out.
List<int> installmentAmounts(Loan loan) {
  final count = loan.installments < 1 ? 1 : loan.installments;
  final each = loan.installmentAmount;
  if (count == 1 || each == null || each <= 0) {
    return [
      for (final a in splitCents(loan.total, count))
        if (a > 0) a,
    ];
  }
  var left = loan.total;
  final amounts = <int>[];
  for (var i = 0; i < count && left > 0; i++) {
    final amount = i == count - 1 ? left : (each < left ? each : left);
    amounts.add(amount);
    left -= amount;
  }
  return amounts;
}

/// The day of the installment [index] (0 = the first, on [Loan.dueOn]): monthly on the due day's
/// date, on the month's last day when it is shorter.
DateTime installmentDue(Loan loan, int index) {
  final first = finDay(loan.dueOn);
  return clampedDay(first.year, first.month + index, first.day);
}

/// The installments of [loan] as [payments] (any order) cover them: payments go to the installments
/// in order, oldest payment first, so paying more or early lowers the next ones.
List<LoanInstallment> loanSchedule(Loan loan, List<LoanPayment> payments, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  final sorted = [...payments]..sort((a, b) => a.date != b.date ? a.date.compareTo(b.date) : a.createdAt.compareTo(b.createdAt));
  final received = sorted.fold(0, (sum, p) => sum + p.amount);
  final amounts = installmentAmounts(loan);
  final schedule = <LoanInstallment>[];
  var before = 0;
  for (final (i, amount) in amounts.indexed) {
    final covered = (received - before).clamp(0, amount);
    final due = installmentDue(loan, i);
    DateTime? paidOn;
    if (covered >= amount) {
      // The payment that took the running total past this installment's end.
      var running = 0;
      for (final p in sorted) {
        running += p.amount;
        if (running >= before + amount) {
          paidOn = finDay(p.date);
          break;
        }
      }
    }
    schedule.add(
      LoanInstallment(
        number: i + 1,
        count: amounts.length,
        due: due,
        amount: amount,
        paid: covered,
        status: covered >= amount
            ? InstallmentStatus.paid
            : day.isAfter(due)
            ? InstallmentStatus.overdue
            : InstallmentStatus.open,
        paidOn: paidOn,
      ),
    );
    before += amount;
  }
  return schedule;
}

/// The profit within [received] of [loan] (see [LoanSummary.interestReceived]).
int interestIn(Loan loan, int received) {
  if (loan.total <= 0) return 0;
  final within = received > loan.total ? loan.total : received;
  return (within * (loan.total - loan.principal) / loan.total).round() + (received - within);
}

/// The profit of the loans received in each month (keyed by its first day): each payment brings
/// what it adds to [interestIn], oldest payment first, so a loan's months add up to its profit received.
/// Installments don't change it: they add up to the total, and the profit is a share of each payment.
Map<DateTime, int> loanInterestByMonth(FinanceSnapshot s) {
  final loans = {for (final l in s.loans) l.id: l};
  final payments = [
    for (final p in s.loanPayments)
      if (loans.containsKey(p.loanId)) p,
  ]..sort((a, b) => a.date != b.date ? a.date.compareTo(b.date) : a.createdAt.compareTo(b.createdAt));
  final received = <String, int>{};
  final months = <DateTime, int>{};
  for (final p in payments) {
    final loan = loans[p.loanId]!;
    final before = received[loan.id] ?? 0, after = before + p.amount;
    received[loan.id] = after;
    final month = monthOf(finDay(p.date));
    months[month] = (months[month] ?? 0) + interestIn(loan, after) - interestIn(loan, before);
  }
  return months;
}

List<LoanSummary> loanSummaries(FinanceSnapshot s, DateTime today) {
  final byLoan = <String, List<LoanPayment>>{};
  for (final p in s.loanPayments) {
    byLoan.putIfAbsent(p.loanId, () => []).add(p);
  }
  return [for (final l in s.loans) LoanSummary(loan: l, payments: (byLoan[l.id] ?? [])..sort((a, b) => b.date.compareTo(a.date)), today: today)];
}

/// "Resumo dos empréstimos": lent and still out, to receive, profit received, overdue and the
/// profit still to come.
class LoansOverview {
  const LoansOverview({
    required this.lentOpen,
    required this.lentTotal,
    required this.toReceive,
    required this.interestReceived,
    required this.overdue,
    required this.interestToCome,
    required this.open,
    required this.overdueCount,
  });

  final int lentOpen;
  final int lentTotal;
  final int toReceive;
  final int interestReceived;
  final int overdue;
  final int interestToCome;
  final int open;
  final int overdueCount;
}

LoansOverview loansOverview(List<LoanSummary> loans) {
  var lentOpen = 0, lentTotal = 0, toReceive = 0, interestReceived = 0, overdue = 0, interestToCome = 0, open = 0, overdueCount = 0;
  for (final l in loans) {
    lentTotal += l.loan.principal;
    interestReceived += l.interestReceived;
    if (l.status == LoanStatus.paid) continue;
    open++;
    lentOpen += l.loan.principal;
    toReceive += l.balance;
    interestToCome += l.interest - l.interestReceived < 0 ? 0 : l.interest - l.interestReceived;
    if (l.status == LoanStatus.overdue) {
      // Only the installments already late; the ones still to come are not.
      overdue += l.overdueAmount;
      overdueCount++;
    }
  }
  return LoansOverview(
    lentOpen: lentOpen,
    lentTotal: lentTotal,
    toReceive: toReceive,
    interestReceived: interestReceived,
    overdue: overdue,
    interestToCome: interestToCome,
    open: open,
    overdueCount: overdueCount,
  );
}

/// Loans in months: by the month of the day that matters now (the next installment's; soonest
/// first) or by the month they were lent (latest first).
List<({DateTime month, List<LoanSummary> loans})> loansByMonth(List<LoanSummary> loans, {required bool byDue}) {
  final months = <DateTime, List<LoanSummary>>{};
  for (final l in loans) {
    final day = byDue ? l.nextDue : finDay(l.loan.lentOn);
    months.putIfAbsent(DateTime(day.year, day.month), () => []).add(l);
  }
  final keys = months.keys.toList()..sort((a, b) => byDue ? a.compareTo(b) : b.compareTo(a));
  return [
    for (final m in keys)
      (month: m, loans: months[m]!..sort((a, b) => byDue ? a.nextDue.compareTo(b.nextDue) : b.loan.lentOn.compareTo(a.loan.lentOn))),
  ];
}
