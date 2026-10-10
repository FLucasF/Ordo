import '../../data/db/database.dart';
import 'finance_enums.dart';

/// Everything of Finanças, read at once (soft-deleted rows left out). Entries come newest first.
class FinanceSnapshot {
  FinanceSnapshot({
    required this.categories,
    required this.cards,
    required this.recurrings,
    required this.entries,
    required this.cardPayments,
    required this.loans,
    required this.loanPayments,
  }) : categoryById = {for (final c in categories) c.id: c},
       cardById = {for (final c in cards) c.id: c};

  factory FinanceSnapshot.empty() => FinanceSnapshot(
    categories: const [],
    cards: const [],
    recurrings: const [],
    entries: const [],
    cardPayments: const [],
    loans: const [],
    loanPayments: const [],
  );

  final List<FinCategory> categories;
  final List<FinCard> cards;
  final List<FinRecurring> recurrings;
  final List<FinEntry> entries;
  final List<FinCardPayment> cardPayments;
  final List<Loan> loans;
  final List<LoanPayment> loanPayments;

  final Map<String, FinCategory> categoryById;
  final Map<String, FinCard> cardById;

  /// Categories of one kind still in use (not archived), in their order.
  List<FinCategory> categoriesOf(FinKind kind) => [
    for (final c in categories)
      if (c.kind == kind && c.archivedAt == null) c,
  ];
}

// ------------------------------------------------------------------ days

/// A stored day (UTC midnight) as the local calendar day.
DateTime finDay(DateTime stored) => DateTime(stored.year, stored.month, stored.day);

/// A local calendar day as stored (UTC midnight).
DateTime storedDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

/// The first day of [day]'s month.
DateTime monthOf(DateTime day) => DateTime(day.year, day.month);

/// [day] of [year]/[month], or the month's last day when it has fewer days (31 in February).
DateTime clampedDay(int year, int month, int day) {
  final last = DateTime(year, month + 1, 0);
  return DateTime(last.year, last.month, day > last.day ? last.day : day);
}

// ------------------------------------------------------------------ card invoices

/// The invoice a purchase on [day] falls in, named by its due month (its first day). The closing
/// day itself already belongs to the next invoice, as banks do.
DateTime invoiceMonthFor(FinCard card, DateTime day) {
  var closing = clampedDay(day.year, day.month, card.closingDay);
  if (!day.isBefore(closing)) closing = clampedDay(day.year, day.month + 1, card.closingDay);
  // Due after the closing: the same month when the due day comes later in it, else the next one.
  return card.dueDay > card.closingDay ? DateTime(closing.year, closing.month) : DateTime(closing.year, closing.month + 1);
}

/// When the invoice of [invoiceMonth] closes and is due.
DateTime invoiceClosing(FinCard card, DateTime invoiceMonth) => card.dueDay > card.closingDay
    ? clampedDay(invoiceMonth.year, invoiceMonth.month, card.closingDay)
    : clampedDay(invoiceMonth.year, invoiceMonth.month - 1, card.closingDay);

DateTime invoiceDue(FinCard card, DateTime invoiceMonth) => clampedDay(invoiceMonth.year, invoiceMonth.month, card.dueDay);

// ------------------------------------------------------------------ months

/// The day an entry counts on: its own day, or the due day of its invoice for a card purchase (the
/// money leaves when the invoice is paid). Totals, limits and the history's period use it.
DateTime countDay(FinanceSnapshot s, FinEntry e) {
  final card = e.cardId == null ? null : s.cardById[e.cardId];
  final invoice = e.invoiceMonth;
  if (card != null && invoice != null) return invoiceDue(card, finDay(invoice));
  if (invoice != null) return finDay(invoice);
  return finDay(e.date);
}

/// Whether [e] counts in the month starting on [month].
bool countsIn(FinanceSnapshot s, FinEntry e, DateTime month) {
  final day = countDay(s, e);
  return day.year == month.year && day.month == month.month;
}

/// Income, expenses and what is left, in cents.
class FinTotals {
  const FinTotals({this.income = 0, this.expense = 0});

  final int income;
  final int expense;

  int get balance => income - expense;
}

FinTotals totalsOf(Iterable<FinEntry> entries) {
  var income = 0, expense = 0;
  for (final e in entries) {
    if (e.kind == FinKind.income) {
      income += e.amount;
    } else {
      expense += e.amount;
    }
  }
  return FinTotals(income: income, expense: expense);
}

/// The entries counting in [month].
List<FinEntry> entriesOfMonth(FinanceSnapshot s, DateTime month) => [
  for (final e in s.entries)
    if (countsIn(s, e, month)) e,
];

/// Expenses of [month] per category id (null = "Sem categoria").
Map<String?, int> spendingByCategory(FinanceSnapshot s, DateTime month) => amountsByCategory(s, month, FinKind.expense);

/// The entries of [kind] in [month] per category id (null = "Sem categoria").
Map<String?, int> amountsByCategory(FinanceSnapshot s, DateTime month, FinKind kind) {
  final amounts = <String?, int>{};
  for (final e in entriesOfMonth(s, month)) {
    if (e.kind == kind) amounts[e.categoryId] = (amounts[e.categoryId] ?? 0) + e.amount;
  }
  return amounts;
}

// ------------------------------------------------------------------ limits

enum LimitLevel { ok, near, over }

/// A category's month against its limit. "Perto" from 80%; "estourou" above 100%.
class LimitStatus {
  const LimitStatus({required this.category, required this.spent, required this.limit});

  static const nearShare = 0.8;

  final FinCategory category;
  final int spent;
  final int limit;

  double get share => limit == 0 ? 1 : spent / limit;

  LimitLevel get level => spent > limit
      ? LimitLevel.over
      : share >= nearShare
      ? LimitLevel.near
      : LimitLevel.ok;
}

/// The month of every category with a limit.
List<LimitStatus> limitsOfMonth(FinanceSnapshot s, DateTime month) {
  final spent = spendingByCategory(s, month);
  return [
    for (final c in s.categoriesOf(FinKind.expense))
      if (c.monthlyLimit case final limit?) LimitStatus(category: c, spent: spent[c.id] ?? 0, limit: limit),
  ];
}

// ------------------------------------------------------------------ history

/// The history's filters: the days the entries count on (both included), categories (empty = all;
/// '' = "Sem categoria"), kind and words of the description.
class EntryFilter {
  const EntryFilter({required this.from, required this.to, this.categoryIds = const {}, this.kind, this.text = ''});

  final DateTime from;
  final DateTime to;
  final Set<String> categoryIds;
  final FinKind? kind;
  final String text;
}

List<FinEntry> filterEntries(FinanceSnapshot s, EntryFilter f) {
  final words = f.text.trim().toLowerCase();
  return [
    for (final e in s.entries)
      if (!countDay(s, e).isBefore(f.from) &&
          !countDay(s, e).isAfter(f.to) &&
          (f.categoryIds.isEmpty || f.categoryIds.contains(e.categoryId ?? '')) &&
          (f.kind == null || e.kind == f.kind) &&
          (words.isEmpty || e.description.toLowerCase().contains(words) || e.note.toLowerCase().contains(words)))
        e,
  ];
}

/// A block of the history: the entries of one day, or the purchases of one card invoice (on its due
/// day).
class EntryGroup {
  const EntryGroup({required this.day, required this.entries, this.card});

  final DateTime day;
  final FinCard? card;
  final List<FinEntry> entries;

  FinTotals get totals => totalsOf(entries);
}

/// [entries] in blocks, newest first.
List<EntryGroup> groupEntries(FinanceSnapshot s, List<FinEntry> entries) {
  final days = <DateTime, List<FinEntry>>{};
  final invoices = <(String, DateTime), List<FinEntry>>{};
  for (final e in entries) {
    final card = e.cardId == null ? null : s.cardById[e.cardId];
    if (card != null && e.invoiceMonth != null) {
      invoices.putIfAbsent((card.id, countDay(s, e)), () => []).add(e);
    } else {
      days.putIfAbsent(finDay(e.date), () => []).add(e);
    }
  }
  return [
    for (final MapEntry(key: day, value: list) in days.entries) EntryGroup(day: day, entries: list),
    for (final MapEntry(key: (cardId, day), value: list) in invoices.entries) EntryGroup(day: day, entries: list, card: s.cardById[cardId]),
  ]..sort((a, b) {
    final byDay = b.day.compareTo(a.day);
    // On the same day, the invoice comes after the day's own entries.
    return byDay != 0 ? byDay : (a.card == null ? 0 : 1) - (b.card == null ? 0 : 1);
  });
}
