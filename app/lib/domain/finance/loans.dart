import '../../data/db/database.dart';
import 'finance.dart';

/// "Em dia", "Atrasado" (past the due day with something left) or "Quitado".
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

  LoanStatus get status => balance <= 0
      ? LoanStatus.paid
      : _today.isAfter(finDay(loan.dueOn))
      ? LoanStatus.overdue
      : LoanStatus.onTime;

  /// Days past the due day (0 when not overdue).
  int get daysLate => status == LoanStatus.overdue ? _today.difference(finDay(loan.dueOn)).inDays : 0;
}

/// The profit within [received] of [loan] (see [LoanSummary.interestReceived]).
int interestIn(Loan loan, int received) {
  if (loan.total <= 0) return 0;
  final within = received > loan.total ? loan.total : received;
  return (within * (loan.total - loan.principal) / loan.total).round() + (received - within);
}

/// The profit of the loans received in each month (keyed by its first day): each payment brings
/// what it adds to [interestIn], oldest payment first, so a loan's months add up to its profit received.
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
      overdue += l.balance;
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

/// Loans in months: by the due day's month (soonest first) or by the month they were lent (latest
/// first).
List<({DateTime month, List<LoanSummary> loans})> loansByMonth(List<LoanSummary> loans, {required bool byDue}) {
  final months = <DateTime, List<LoanSummary>>{};
  for (final l in loans) {
    final day = finDay(byDue ? l.loan.dueOn : l.loan.lentOn);
    months.putIfAbsent(DateTime(day.year, day.month), () => []).add(l);
  }
  final keys = months.keys.toList()..sort((a, b) => byDue ? a.compareTo(b) : b.compareTo(a));
  return [
    for (final m in keys)
      (month: m, loans: months[m]!..sort((a, b) => byDue ? a.loan.dueOn.compareTo(b.loan.dueOn) : b.loan.lentOn.compareTo(a.loan.lentOn))),
  ];
}
