import 'package:drift/drift.dart';

import '../../domain/finance/finance_enums.dart';
import 'converters.dart';
import 'tables.dart';

// Finanças, schema v18. Money is in cents (a positive `int`; the kind says in or out); days are the
// local day at UTC midnight, like the countdown dates.

/// Categories of income and expenses. [monthlyLimit] (expenses only, cents) warns when a month's
/// spending gets near it; null = no limit.
@DataClassName('FinCategory')
class FinCategories extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get kind => text().map(const TextCodeConverter<FinKind>(FinKind.fromCode))();

  /// Emoji shown before the name.
  TextColumn get icon => text().withDefault(const Constant(''))();
  TextColumn get color => text().nullable()();
  IntColumn get monthlyLimit => integer().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();
}

/// Credit cards. A purchase goes to the invoice ("fatura") that closes on the next [closingDay] and
/// is due on [dueDay]; days past the end of a month fall on its last day.
@DataClassName('FinCard')
class FinCards extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  IntColumn get closingDay => integer()();
  IntColumn get dueDay => integer()();
  IntColumn get creditLimit => integer().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();
}

/// Recurring bills and income ("contas fixas": rent, subscriptions, salary). Each occurrence is due
/// on [day] of every month (or of [month], yearly); confirming it creates a [FinEntries] row.
@DataClassName('FinRecurring')
class FinRecurrings extends Table with SyncedRow {
  TextColumn get kind => text().map(const TextCodeConverter<FinKind>(FinKind.fromCode))();
  TextColumn get description => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().nullable().references(FinCategories, #id)();
  TextColumn get cardId => text().nullable().references(FinCards, #id)();
  TextColumn get frequency => text().map(const TextCodeConverter<FinFrequency>(FinFrequency.fromCode))();
  IntColumn get day => integer()();
  IntColumn get month => integer().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Reminder N days before each due day (0 = on the day); null = none.
  IntColumn get remindDaysBefore => integer().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();
}

/// Income and expenses ("lançamentos"). A card purchase has [cardId] and the [invoiceMonth] it
/// falls in (the first day of the invoice's due month); installments share [installmentGroup].
@DataClassName('FinEntry')
class FinEntries extends Table with SyncedRow {
  TextColumn get kind => text().map(const TextCodeConverter<FinKind>(FinKind.fromCode))();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable().references(FinCategories, #id)();
  TextColumn get cardId => text().nullable().references(FinCards, #id)();
  DateTimeColumn get invoiceMonth => dateTime().nullable()();
  TextColumn get installmentGroup => text().nullable()();
  IntColumn get installmentIndex => integer().nullable()();
  IntColumn get installmentCount => integer().nullable()();

  /// The recurring bill it paid, and which occurrence (its due day).
  TextColumn get recurringId => text().nullable().references(FinRecurrings, #id)();
  DateTimeColumn get recurringDue => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Order among the entries of the same day, dragged by the user (schema v21); lower first.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Payments of a card's invoice. They are not expenses: the purchases already are.
@DataClassName('FinCardPayment')
class FinCardPayments extends Table with SyncedRow {
  TextColumn get cardId => text().references(FinCards, #id)();
  DateTimeColumn get invoiceMonth => dateTime()();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
}

/// Money lent: [principal] on [lentOn], [total] to receive at once on [dueOn] (the profit is the
/// difference). Kept apart from income and expenses.
class Loans extends Table with SyncedRow {
  TextColumn get borrower => text()();
  IntColumn get principal => integer()();
  IntColumn get total => integer()();
  DateTimeColumn get lentOn => dateTime()();
  DateTimeColumn get dueOn => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Notify on the due day and while it is overdue.
  BoolColumn get remind => boolean().withDefault(const Constant(true))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Paid back in [installments] (schema v20; 1 = at once, as before), monthly from [dueOn], each of
  /// [installmentAmount] (null = [total] split evenly).
  IntColumn get installments => integer().withDefault(const Constant(1))();
  IntColumn get installmentAmount => integer().nullable()();
}

/// Payments received for a loan, partial ones included.
class LoanPayments extends Table with SyncedRow {
  TextColumn get loanId => text().references(Loans, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// "Caixinhas" (schema v20): money set aside for a goal of [target] cents, optionally by [dueOn].
@DataClassName('FinGoal')
class FinGoals extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get target => integer()();
  DateTimeColumn get dueOn => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// Money put in a goal (positive) or taken out (negative), in cents, on a day.
@DataClassName('FinGoalMove')
class FinGoalMoves extends Table with SyncedRow {
  TextColumn get goalId => text().references(FinGoals, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
}
