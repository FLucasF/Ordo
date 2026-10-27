import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../core/sort_order.dart';
import '../domain/finance/finance.dart';
import '../domain/finance/finance_enums.dart';
import '../domain/finance/money.dart';
import 'db/database.dart';

/// A default category: name, emoji and kind.
typedef DefaultCategory = ({String name, String icon, FinKind kind});

/// Every write of Finanças. Kept apart from [Repository]: finance changes don't reload the tasks,
/// nor the other way round.
class FinanceRepository {
  FinanceRepository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  // ------------------------------------------------------------------ reading

  /// A fresh snapshot on every change to a finance table. The query text must differ from the
  /// tasks' `SELECT 1`: drift shares one stream between identical queries, whatever tables they read.
  Stream<FinanceSnapshot> watch() => _db
      .customSelect(
        'SELECT 1 AS finance',
        readsFrom: {
          _db.finCategories,
          _db.finCards,
          _db.finRecurrings,
          _db.finEntries,
          _db.finCardPayments,
          _db.loans,
          _db.loanPayments,
          _db.finGoals,
          _db.finGoalMoves,
        },
      )
      .watch()
      .asyncMap((_) => load());

  Future<FinanceSnapshot> load() => _db.transaction(() async {
    final categories =
        await (_db.select(_db.finCategories)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
            .get();
    final cards =
        await (_db.select(_db.finCards)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
            .get();
    final recurrings =
        await (_db.select(_db.finRecurrings)
              ..where((r) => r.deletedAt.isNull())
              ..orderBy([(r) => OrderingTerm(expression: r.sortOrder)]))
            .get();
    final entries =
        await (_db.select(_db.finEntries)
              ..where((e) => e.deletedAt.isNull())
              // Newest day first; within a day the order dragged (a new entry on top), then the newest.
              ..orderBy([(e) => OrderingTerm.desc(e.date), (e) => OrderingTerm(expression: e.sortOrder), (e) => OrderingTerm.desc(e.createdAt)]))
            .get();
    final cardPayments = await (_db.select(_db.finCardPayments)..where((p) => p.deletedAt.isNull())).get();
    final loans =
        await (_db.select(_db.loans)
              ..where((l) => l.deletedAt.isNull())
              ..orderBy([(l) => OrderingTerm(expression: l.dueOn)]))
            .get();
    final loanPayments = await (_db.select(_db.loanPayments)..where((p) => p.deletedAt.isNull())).get();
    final goals =
        await (_db.select(_db.finGoals)
              ..where((g) => g.deletedAt.isNull())
              ..orderBy([(g) => OrderingTerm(expression: g.sortOrder)]))
            .get();
    final goalMoves = await (_db.select(_db.finGoalMoves)..where((m) => m.deletedAt.isNull())).get();
    return FinanceSnapshot(
      categories: categories,
      cards: cards,
      recurrings: recurrings,
      entries: entries,
      cardPayments: cardPayments,
      loans: loans,
      loanPayments: loanPayments,
      goals: goals,
      goalMoves: goalMoves,
    );
  });

  // ------------------------------------------------------------------ categories

  /// The default categories, created when there are none yet (the first time Finanças opens).
  Future<void> seedCategories(List<DefaultCategory> defaults) => _db.transaction(() async {
    final any = await (_db.select(_db.finCategories)..limit(1)).getSingleOrNull();
    if (any != null) return;
    for (final c in defaults) {
      await createCategory(name: c.name, kind: c.kind, icon: c.icon);
    }
  });

  Future<String> createCategory({required String name, required FinKind kind, String icon = '', String? color, int? monthlyLimit}) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.finCategories,
    )..addColumns([_db.finCategories.sortOrder.max()])).map((r) => r.read(_db.finCategories.sortOrder.max())).getSingle();
    await _db
        .into(_db.finCategories)
        .insert(
          FinCategoriesCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: name.trim(),
            kind: kind,
            icon: Value(icon),
            color: Value(color),
            monthlyLimit: Value(kind == FinKind.expense ? monthlyLimit : null),
            sortOrder: SortOrder.after(last),
          ),
        );
    return id;
  }

  Future<void> updateCategory(String id, {required String name, required String icon, String? color, int? monthlyLimit}) =>
      (_db.update(_db.finCategories)..where((c) => c.id.equals(id))).write(
        FinCategoriesCompanion(
          name: Value(name.trim()),
          icon: Value(icon),
          color: Value(color),
          monthlyLimit: Value(monthlyLimit),
          updatedAt: Value(_now),
        ),
      );

  /// Deletes a category; its entries and recurring bills are left "Sem categoria".
  Future<void> deleteCategory(String id) => _db.transaction(() async {
    await (_db.update(
      _db.finEntries,
    )..where((e) => e.categoryId.equals(id))).write(FinEntriesCompanion(categoryId: const Value(null), updatedAt: Value(_now)));
    await (_db.update(
      _db.finRecurrings,
    )..where((r) => r.categoryId.equals(id))).write(FinRecurringsCompanion(categoryId: const Value(null), updatedAt: Value(_now)));
    await (_db.delete(_db.finCategories)..where((c) => c.id.equals(id))).go();
  });

  // ------------------------------------------------------------------ entries

  /// "Novo lançamento". A card purchase goes to the invoice of [date], or is split in [installments]
  /// over the invoices that follow ("1/3", "2/3"…). Returns the ids created.
  Future<List<String>> addEntry({
    required FinKind kind,
    required int amount,
    required DateTime date,
    String description = '',
    String? categoryId,
    String? cardId,
    int installments = 1,
    String note = '',
    String? recurringId,
    DateTime? recurringDue,
  }) => _db.transaction(() async {
    final card = cardId == null ? null : await (_db.select(_db.finCards)..where((c) => c.id.equals(cardId))).getSingleOrNull();
    final count = card == null ? 1 : installments.clamp(1, 99);
    final group = count > 1 ? newId() : null;
    final first = card == null ? null : invoiceMonthFor(card, date);
    // A new entry goes on top of its day.
    final top = await (_db.selectOnly(_db.finEntries)..addColumns([_db.finEntries.sortOrder.min()]))
        .map((r) => r.read(_db.finEntries.sortOrder.min()))
        .getSingle();
    final ids = <String>[];
    for (final (i, part) in splitCents(amount, count).indexed) {
      final id = newId();
      ids.add(id);
      await _db
          .into(_db.finEntries)
          .insert(
            FinEntriesCompanion.insert(
              id: id,
              createdAt: _now,
              updatedAt: _now,
              kind: kind,
              amount: part,
              date: storedDay(date),
              description: Value(description.trim()),
              categoryId: Value(categoryId),
              cardId: Value(card?.id),
              invoiceMonth: Value(first == null ? null : storedDay(DateTime(first.year, first.month + i))),
              installmentGroup: Value(group),
              installmentIndex: Value(group == null ? null : i + 1),
              installmentCount: Value(group == null ? null : count),
              recurringId: Value(recurringId),
              recurringDue: Value(recurringDue == null ? null : storedDay(recurringDue)),
              note: Value(note.trim()),
              sortOrder: Value(SortOrder.before(top)),
            ),
          );
    }
    return ids;
  });

  /// New orders for categories dragged into place ({category id: order}).
  Future<void> reorderCategories(Map<String, int> orders) => _db.transaction(() async {
    for (final MapEntry(key: id, value: order) in orders.entries) {
      await (_db.update(_db.finCategories)..where((c) => c.id.equals(id))).write(FinCategoriesCompanion(sortOrder: Value(order), updatedAt: Value(_now)));
    }
  });

  /// New orders for entries dragged into place within their day ({entry id: order}).
  Future<void> reorderEntries(Map<String, int> orders) => _db.transaction(() async {
    for (final MapEntry(key: id, value: order) in orders.entries) {
      await (_db.update(_db.finEntries)..where((e) => e.id.equals(id))).write(FinEntriesCompanion(sortOrder: Value(order), updatedAt: Value(_now)));
    }
  });

  /// Edits one entry. A card purchase moves to the invoice of its new day (or card).
  Future<void> updateEntry(
    String id, {
    required FinKind kind,
    required int amount,
    required DateTime date,
    required String description,
    required String? categoryId,
    required String? cardId,
    required String note,
  }) => _db.transaction(() async {
    final card = cardId == null ? null : await (_db.select(_db.finCards)..where((c) => c.id.equals(cardId))).getSingleOrNull();
    final entry = await (_db.select(_db.finEntries)..where((e) => e.id.equals(id))).getSingle();
    // An installment keeps its place in the series: the n-th invoice after the purchase's.
    final offset = (entry.installmentIndex ?? 1) - 1;
    final first = card == null ? null : invoiceMonthFor(card, date);
    await (_db.update(_db.finEntries)..where((e) => e.id.equals(id))).write(
      FinEntriesCompanion(
        kind: Value(kind),
        amount: Value(amount),
        date: Value(storedDay(date)),
        description: Value(description.trim()),
        categoryId: Value(categoryId),
        cardId: Value(card?.id),
        invoiceMonth: Value(first == null ? null : storedDay(DateTime(first.year, first.month + offset))),
        note: Value(note.trim()),
        updatedAt: Value(_now),
      ),
    );
  });

  /// Deletes entries (to the "Desfazer" of the toast: [restoreEntries]).
  Future<void> deleteEntries(Iterable<String> ids) =>
      (_db.update(_db.finEntries)..where((e) => e.id.isIn(ids))).write(FinEntriesCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));

  Future<void> restoreEntries(Iterable<String> ids) =>
      (_db.update(_db.finEntries)..where((e) => e.id.isIn(ids))).write(FinEntriesCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));

  /// The installments of a card purchase, in order.
  Future<List<String>> installmentIds(String group) async => [
    for (final e
        in await (_db.select(_db.finEntries)
              ..where((e) => e.installmentGroup.equals(group) & e.deletedAt.isNull())
              ..orderBy([(e) => OrderingTerm(expression: e.installmentIndex)]))
            .get())
      e.id,
  ];

  // ------------------------------------------------------------------ cards

  Future<String> createCard({required String name, required int closingDay, required int dueDay, int? creditLimit, String? color}) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.finCards,
    )..addColumns([_db.finCards.sortOrder.max()])).map((r) => r.read(_db.finCards.sortOrder.max())).getSingle();
    await _db
        .into(_db.finCards)
        .insert(
          FinCardsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: name.trim(),
            color: Value(color),
            closingDay: closingDay.clamp(1, 31),
            dueDay: dueDay.clamp(1, 31),
            creditLimit: Value(creditLimit),
            sortOrder: SortOrder.after(last),
          ),
        );
    return id;
  }

  /// Edits a card. Changing its closing or due day moves its purchases to the invoices of the new
  /// days (installments keep their order).
  Future<void> updateCard(String id, {required String name, required int closingDay, required int dueDay, int? creditLimit}) =>
      _db.transaction(() async {
        final before = await (_db.select(_db.finCards)..where((c) => c.id.equals(id))).getSingle();
        await (_db.update(_db.finCards)..where((c) => c.id.equals(id))).write(
          FinCardsCompanion(
            name: Value(name.trim()),
            closingDay: Value(closingDay.clamp(1, 31)),
            dueDay: Value(dueDay.clamp(1, 31)),
            creditLimit: Value(creditLimit),
            updatedAt: Value(_now),
          ),
        );
        if (before.closingDay == closingDay && before.dueDay == dueDay) return;
        final card = await (_db.select(_db.finCards)..where((c) => c.id.equals(id))).getSingle();
        final purchases = await (_db.select(_db.finEntries)..where((e) => e.cardId.equals(id) & e.deletedAt.isNull())).get();
        for (final e in purchases) {
          final first = invoiceMonthFor(card, finDay(e.date));
          final offset = (e.installmentIndex ?? 1) - 1;
          await (_db.update(_db.finEntries)..where((x) => x.id.equals(e.id))).write(
            FinEntriesCompanion(invoiceMonth: Value(storedDay(DateTime(first.year, first.month + offset))), updatedAt: Value(_now)),
          );
        }
      });

  /// "Arquivar": the card leaves the forms; its invoices stay in the history.
  Future<void> archiveCard(String id, {required bool archived}) => (_db.update(
    _db.finCards,
  )..where((c) => c.id.equals(id))).write(FinCardsCompanion(archivedAt: Value(archived ? _now : null), updatedAt: Value(_now)));

  /// Deletes a card with no purchases nor payments; false (and nothing done) otherwise.
  Future<bool> deleteCard(String id) => _db.transaction(() async {
    final used =
        await (_db.select(_db.finEntries)
              ..where((e) => e.cardId.equals(id))
              ..limit(1))
            .getSingleOrNull() !=
        null;
    final paid =
        await (_db.select(_db.finCardPayments)
              ..where((p) => p.cardId.equals(id))
              ..limit(1))
            .getSingleOrNull() !=
        null;
    if (used || paid) return false;
    await (_db.update(
      _db.finRecurrings,
    )..where((r) => r.cardId.equals(id))).write(FinRecurringsCompanion(cardId: const Value(null), updatedAt: Value(_now)));
    await (_db.delete(_db.finCards)..where((c) => c.id.equals(id))).go();
    return true;
  });

  /// "Pagar fatura": not an expense (the purchases are).
  Future<String> payInvoice({required String cardId, required DateTime invoiceMonth, required int amount, required DateTime date}) async {
    final id = newId();
    await _db
        .into(_db.finCardPayments)
        .insert(
          FinCardPaymentsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            cardId: cardId,
            invoiceMonth: storedDay(DateTime(invoiceMonth.year, invoiceMonth.month)),
            amount: amount,
            date: storedDay(date),
          ),
        );
    return id;
  }

  /// Changes a payment of an invoice: its amount and day.
  Future<void> updateCardPayment(String id, {required int amount, required DateTime date}) => (_db.update(
    _db.finCardPayments,
  )..where((p) => p.id.equals(id))).write(FinCardPaymentsCompanion(amount: Value(amount), date: Value(storedDay(date)), updatedAt: Value(_now)));

  Future<void> deleteCardPayment(String id, {bool restore = false}) => (_db.update(
    _db.finCardPayments,
  )..where((p) => p.id.equals(id))).write(FinCardPaymentsCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ recurring bills

  Future<String> createRecurring(FinRecurringsCompanion r) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.finRecurrings,
    )..addColumns([_db.finRecurrings.sortOrder.max()])).map((r) => r.read(_db.finRecurrings.sortOrder.max())).getSingle();
    await _db
        .into(_db.finRecurrings)
        .insert(r.copyWith(id: Value(id), sortOrder: Value(SortOrder.after(last)), createdAt: Value(_now), updatedAt: Value(_now)));
    return id;
  }

  Future<void> updateRecurring(String id, FinRecurringsCompanion changes) =>
      (_db.update(_db.finRecurrings)..where((r) => r.id.equals(id))).write(changes.copyWith(updatedAt: Value(_now)));

  /// Deletes a recurring bill; the entries it created stay, as ordinary ones.
  Future<void> deleteRecurring(String id) => _db.transaction(() async {
    await (_db.update(_db.finEntries)..where((e) => e.recurringId.equals(id))).write(
      FinEntriesCompanion(recurringId: const Value(null), recurringDue: const Value(null), updatedAt: Value(_now)),
    );
    await (_db.delete(_db.finRecurrings)..where((r) => r.id.equals(id))).go();
  });

  // ------------------------------------------------------------------ loans

  Future<String> createLoan({
    required String borrower,
    required int principal,
    required int total,
    required DateTime lentOn,
    required DateTime dueOn,
    String note = '',
    bool remind = true,
    int installments = 1,
    int? installmentAmount,
  }) async {
    final id = newId();
    await _db
        .into(_db.loans)
        .insert(
          LoansCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            borrower: borrower.trim(),
            principal: principal,
            total: total,
            lentOn: storedDay(lentOn),
            dueOn: storedDay(dueOn),
            note: Value(note.trim()),
            remind: Value(remind),
            installments: Value(installments < 1 ? 1 : installments),
            installmentAmount: Value(installments > 1 ? installmentAmount : null),
          ),
        );
    return id;
  }

  Future<void> updateLoan(
    String id, {
    required String borrower,
    required int principal,
    required int total,
    required DateTime lentOn,
    required DateTime dueOn,
    required String note,
    required bool remind,
    int installments = 1,
    int? installmentAmount,
  }) => (_db.update(_db.loans)..where((l) => l.id.equals(id))).write(
    LoansCompanion(
      borrower: Value(borrower.trim()),
      principal: Value(principal),
      total: Value(total),
      lentOn: Value(storedDay(lentOn)),
      dueOn: Value(storedDay(dueOn)),
      note: Value(note.trim()),
      remind: Value(remind),
      installments: Value(installments < 1 ? 1 : installments),
      installmentAmount: Value(installments > 1 ? installmentAmount : null),
      updatedAt: Value(_now),
    ),
  );

  /// Deletes a loan and its payments (to the "Desfazer" of the toast: [restoreLoan]).
  Future<void> deleteLoan(String id) => _db.transaction(() async {
    await (_db.update(
      _db.loanPayments,
    )..where((p) => p.loanId.equals(id) & p.deletedAt.isNull())).write(LoanPaymentsCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
    await (_db.update(_db.loans)..where((l) => l.id.equals(id))).write(LoansCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
  });

  Future<void> restoreLoan(String id) => _db.transaction(() async {
    final loan = await (_db.select(_db.loans)..where((l) => l.id.equals(id))).getSingle();
    final deletedAt = loan.deletedAt;
    if (deletedAt == null) return;
    // The payments deleted with it (not the ones deleted before).
    await (_db.update(_db.loanPayments)..where((p) => p.loanId.equals(id) & p.deletedAt.equals(deletedAt))).write(
      LoanPaymentsCompanion(deletedAt: const Value(null), updatedAt: Value(_now)),
    );
    await (_db.update(_db.loans)..where((l) => l.id.equals(id))).write(LoansCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));
  });

  /// "Registrar pagamento", partial ones included.
  Future<String> addLoanPayment({required String loanId, required int amount, required DateTime date, String note = ''}) async {
    final id = newId();
    await _db
        .into(_db.loanPayments)
        .insert(
          LoanPaymentsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            loanId: loanId,
            amount: amount,
            date: storedDay(date),
            note: Value(note.trim()),
          ),
        );
    return id;
  }

  /// Changes a payment of a loan: its amount, day and note.
  Future<void> updateLoanPayment(String id, {required int amount, required DateTime date, String note = ''}) =>
      (_db.update(_db.loanPayments)..where((p) => p.id.equals(id))).write(
        LoanPaymentsCompanion(amount: Value(amount), date: Value(storedDay(date)), note: Value(note.trim()), updatedAt: Value(_now)),
      );

  Future<void> deleteLoanPayment(String id, {bool restore = false}) => (_db.update(
    _db.loanPayments,
  )..where((p) => p.id.equals(id))).write(LoanPaymentsCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));

  // ------------------------------------------------------------------ goals ("Caixinhas")

  Future<String> createGoal({required String name, required int target, String? icon, String? color, DateTime? dueOn, String note = ''}) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.finGoals,
    )..addColumns([_db.finGoals.sortOrder.max()])).map((r) => r.read(_db.finGoals.sortOrder.max())).getSingle();
    await _db
        .into(_db.finGoals)
        .insert(
          FinGoalsCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: name.trim(),
            icon: Value(icon == null || icon.isEmpty ? null : icon),
            color: Value(color),
            target: target,
            dueOn: Value(dueOn == null ? null : storedDay(dueOn)),
            note: Value(note.trim()),
            sortOrder: SortOrder.after(last),
          ),
        );
    return id;
  }

  Future<void> updateGoal(
    String id, {
    required String name,
    required int target,
    required String? icon,
    required String? color,
    required DateTime? dueOn,
    required String note,
  }) => (_db.update(_db.finGoals)..where((g) => g.id.equals(id))).write(
    FinGoalsCompanion(
      name: Value(name.trim()),
      target: Value(target),
      icon: Value(icon == null || icon.isEmpty ? null : icon),
      color: Value(color),
      dueOn: Value(dueOn == null ? null : storedDay(dueOn)),
      note: Value(note.trim()),
      updatedAt: Value(_now),
    ),
  );

  /// "Arquivar": the goal leaves the list; its money still counts as saved.
  Future<void> archiveGoal(String id, {required bool archived}) => (_db.update(
    _db.finGoals,
  )..where((g) => g.id.equals(id))).write(FinGoalsCompanion(archivedAt: Value(archived ? _now : null), updatedAt: Value(_now)));

  /// Deletes a goal and its moves (to the "Desfazer" of the toast: [restoreGoal]).
  Future<void> deleteGoal(String id) => _db.transaction(() async {
    await (_db.update(
      _db.finGoalMoves,
    )..where((m) => m.goalId.equals(id) & m.deletedAt.isNull())).write(FinGoalMovesCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
    await (_db.update(_db.finGoals)..where((g) => g.id.equals(id))).write(FinGoalsCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));
  });

  Future<void> restoreGoal(String id) => _db.transaction(() async {
    final goal = await (_db.select(_db.finGoals)..where((g) => g.id.equals(id))).getSingle();
    final deletedAt = goal.deletedAt;
    if (deletedAt == null) return;
    // The moves deleted with it (not the ones deleted before).
    await (_db.update(_db.finGoalMoves)..where((m) => m.goalId.equals(id) & m.deletedAt.equals(deletedAt))).write(
      FinGoalMovesCompanion(deletedAt: const Value(null), updatedAt: Value(_now)),
    );
    await (_db.update(_db.finGoals)..where((g) => g.id.equals(id))).write(FinGoalsCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));
  });

  /// "Guardar" ([amount] positive) or "Retirar" (negative). A transfer: neither income nor expense.
  Future<String> addGoalMove({required String goalId, required int amount, required DateTime date, String note = ''}) async {
    final id = newId();
    await _db
        .into(_db.finGoalMoves)
        .insert(
          FinGoalMovesCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            goalId: goalId,
            amount: amount,
            date: storedDay(date),
            note: Value(note.trim()),
          ),
        );
    return id;
  }

  Future<void> updateGoalMove(String id, {required int amount, required DateTime date, String note = ''}) =>
      (_db.update(_db.finGoalMoves)..where((m) => m.id.equals(id))).write(
        FinGoalMovesCompanion(amount: Value(amount), date: Value(storedDay(date)), note: Value(note.trim()), updatedAt: Value(_now)),
      );

  Future<void> deleteGoalMove(String id, {bool restore = false}) => (_db.update(
    _db.finGoalMoves,
  )..where((m) => m.id.equals(id))).write(FinGoalMovesCompanion(deletedAt: Value(restore ? null : _now), updatedAt: Value(_now)));
}
