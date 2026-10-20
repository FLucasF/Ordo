import '../reminder_plan.dart';
import 'finance.dart';
import 'loans.dart';
import 'recurring.dart';

/// What a finance notification is about.
enum FinanceAlertKind {
  /// A recurring bill due today.
  billDue,

  /// A recurring bill due in a few days.
  billSoon,

  /// A loan due today.
  loanDue,

  /// A loan past its due day with something left.
  loanLate,
}

class FinanceAlert {
  const FinanceAlert({required this.kind, required this.name, required this.amount, required this.due, this.installment, this.installments = 1});

  final FinanceAlertKind kind;
  final String name;
  final int amount;
  final DateTime due;

  /// A loan's installment ("2/5"); null when paid at once.
  final int? installment;
  final int installments;
}

/// Finance notifications fire at 9:00.
const financeReminderHour = 9;

/// Days after the due day an overdue loan is recalled: the next day, then weekly for a month.
const loanLateDays = [1, 8, 15, 22, 29];

/// The notifications of the next [days]: recurring bills not yet paid ("Lembrete": on the due day
/// or some days before) and loans with something left (each installment on its day and while
/// overdue).
List<PlannedReminder> planFinanceReminders(
  FinanceSnapshot s,
  DateTime now, {
  required String Function(FinanceAlert alert) title,
  required String Function(FinanceAlert alert) body,
  int days = 60,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final planned = <PlannedReminder>[];
  void add(String owner, String key, DateTime day, FinanceAlert alert) {
    final at = DateTime(day.year, day.month, day.day, financeReminderHour);
    if (!at.isAfter(now) || day.isAfter(today.add(Duration(days: days)))) return;
    planned.add(
      PlannedReminder(id: notificationId(owner, key), taskId: owner, at: at, title: title(alert), body: body(alert), due: alert.due, isAllDay: true),
    );
  }

  // The notice can come before the due day: look a week past the window.
  for (final o in occurrences(s, today, today.add(Duration(days: days + 7)), today)) {
    final before = o.recurring.remindDaysBefore;
    if (before == null || o.status == OccurrenceStatus.paid) continue;
    final alert = FinanceAlert(
      kind: before == 0 ? FinanceAlertKind.billDue : FinanceAlertKind.billSoon,
      name: o.recurring.description,
      amount: o.recurring.amount,
      due: o.due,
    );
    add('${financePrefix}recurring:${o.recurring.id}', o.due.toIso8601String(), o.due.subtract(Duration(days: before)), alert);
  }

  for (final l in loanSummaries(s, today)) {
    if (!l.loan.remind || l.status == LoanStatus.paid || l.loan.archivedAt != null) continue;
    final owner = '${financePrefix}loan:${l.loan.id}';
    for (final i in l.installments) {
      if (i.status == InstallmentStatus.paid) continue;
      // Paid at once keeps the keys of before (the notifications already scheduled stay the same).
      final key = i.count == 1 ? '' : '${i.number}_';
      FinanceAlert alert(FinanceAlertKind kind) => FinanceAlert(
        kind: kind,
        name: l.loan.borrower,
        amount: i.open,
        due: i.due,
        installment: i.count == 1 ? null : i.number,
        installments: i.count,
      );
      add(owner, i.count == 1 ? 'due' : 'due${i.number}', i.due, alert(FinanceAlertKind.loanDue));
      for (final after in loanLateDays) {
        add(owner, 'late$key$after', i.due.add(Duration(days: after)), alert(FinanceAlertKind.loanLate));
      }
    }
  }
  return planned;
}

/// Whether a fired finance notification still has something to say: its bill or loan exists.
bool keepsFinanceReminder(FinanceSnapshot s, String owner) {
  if (owner.startsWith('${financePrefix}recurring:')) {
    final id = owner.substring('${financePrefix}recurring:'.length);
    return s.recurrings.any((r) => r.id == id && r.archivedAt == null);
  }
  if (owner.startsWith('${financePrefix}loan:')) {
    final id = owner.substring('${financePrefix}loan:'.length);
    return s.loans.any((l) => l.id == id);
  }
  return false;
}
